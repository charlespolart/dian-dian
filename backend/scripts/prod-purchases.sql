-- Purchases as RevenueCat reported them (table subscription_events): trials
-- started, converted and cancelled, what was sold and at what price, refunds,
-- why subscriptions end. Read-only. Run against prod:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-purchases.sql
--
-- Every section but the last two reads PRODUCTION events of real accounts
-- only: same exclusions as prod-stats.sql (test accounts, demo, internal
-- @mydiandian.app, VIP), and no sandbox purchase (TestFlight, Play test
-- tracks). The section before last says what was kept and what was left
-- out, with the amounts; the last one is a check on the webhook itself: a
-- row there is a purchase event that was not kept (an empty result is no
-- proof that none is missing, see its comment).
--
-- The table starts with the backend release that created it: nothing before.
-- A subscription is followed by its original_transaction_id, which stays the
-- same from the trial to every renewal. price_usd is RevenueCat's conversion
-- to US dollars (0 for a trial start, negative for a refund); price_local is
-- in the purchase currency. Both are what the customer paid: the stores take
-- their commission and the taxes out of it. RevenueCat estimates the two
-- shares on each event (tax_percentage and commission_percentage, fractions
-- of the price paid, kept in payload), and what is left is
-- price x (1 - tax_percentage - commission_percentage).

\pset format aligned
SET default_transaction_read_only = on;

\echo === Événements par semaine et par type, 16 dernières semaines ===
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app'))
SELECT date_trunc('week', event_at)::date AS semaine,
       type,
       coalesce(period_type, '-') AS periode,
       count(*)                   AS evenements,
       count(DISTINCT user_id)    AS comptes
FROM e
WHERE event_at >= date_trunc('week', now()) - interval '15 weeks'
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

\echo === Essais par mois de départ : démarrés, convertis, terminés sans payer, encore en cours, sans nouvelles ===
\echo (Un essai résilié court jusqu au bout : il est en cours, puis sans conversion. sans_nouvelles = la date de fin est passée et rien n est arrivé,)
\echo (ni paiement ni expiration : un événement perdu ou arrivé sous un autre compte. conversion_pct ne compte que les essais dont on connaît la fin.)
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app')),
trials AS (
  SELECT original_transaction_id AS tx, min(event_at) AS started_at, max(expires_at) AS ends_at, min(store) AS store, min(product_id) AS product_id
  FROM e
  WHERE type = 'INITIAL_PURCHASE' AND period_type = 'TRIAL' AND original_transaction_id IS NOT NULL
  GROUP BY 1),
outcome AS (
  SELECT t.*,
         (SELECT min(c.event_at) FROM e c
          WHERE c.original_transaction_id = t.tx AND c.type = 'CANCELLATION' AND c.period_type = 'TRIAL') AS cancelled_at,
         EXISTS (SELECT 1 FROM e r
                 WHERE r.original_transaction_id = t.tx AND r.type = 'RENEWAL' AND r.is_trial_conversion) AS converted,
         EXISTS (SELECT 1 FROM e x
                 WHERE x.original_transaction_id = t.tx AND x.type = 'EXPIRATION') AS expired
  FROM trials t)
SELECT to_char(date_trunc('month', started_at), 'YYYY-MM') AS mois,
       store,
       product_id,
       count(*)                                              AS essais,
       count(*) FILTER (WHERE converted)                     AS convertis,
       count(*) FILTER (WHERE NOT converted AND expired)     AS sans_conversion,
       count(*) FILTER (WHERE NOT converted AND NOT expired AND ends_at >= now())                 AS en_cours,
       count(*) FILTER (WHERE NOT converted AND NOT expired AND (ends_at IS NULL OR ends_at < now())) AS sans_nouvelles,
       round(100.0 * count(*) FILTER (WHERE converted) / nullif(count(*) FILTER (WHERE converted OR expired), 0), 1) AS conversion_pct,
       count(*) FILTER (WHERE cancelled_at IS NOT NULL)      AS resilies_pendant_essai,
       round(avg(extract(epoch FROM cancelled_at - started_at) / 86400)::numeric, 1) AS jours_avant_resiliation
FROM outcome
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

\echo === Essais résiliés : quel jour de l essai (0 = le jour même) ===
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app')),
trials AS (
  SELECT original_transaction_id AS tx, min(event_at) AS started_at
  FROM e
  WHERE type = 'INITIAL_PURCHASE' AND period_type = 'TRIAL' AND original_transaction_id IS NOT NULL
  GROUP BY 1),
cancelled AS (
  SELECT t.tx, t.started_at, min(c.event_at) AS cancelled_at
  FROM trials t JOIN e c ON c.original_transaction_id = t.tx AND c.type = 'CANCELLATION' AND c.period_type = 'TRIAL'
  GROUP BY 1, 2)
SELECT floor(extract(epoch FROM cancelled_at - started_at) / 86400)::int AS jour,
       count(*) AS essais_resilies
FROM cancelled
GROUP BY 1
ORDER BY 1;

\echo === Ventes payées par produit, store et devise ===
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app'))
SELECT product_id,
       store,
       type,
       coalesce(currency, '-')           AS devise,
       count(*)                          AS ventes,
       count(DISTINCT user_id)           AS comptes,
       round(sum(price_usd)::numeric, 2) AS total_usd,
       round((percentile_cont(0.5) WITHIN GROUP (ORDER BY price_local))::numeric, 2) AS prix_local_median
FROM e
WHERE type IN ('INITIAL_PURCHASE', 'RENEWAL', 'NON_RENEWING_PURCHASE') AND price_usd > 0
GROUP BY 1, 2, 3, 4
ORDER BY total_usd DESC;

\echo === Revenu par mois (USD) : payé par les clients, puis ce qui reste après taxes et commission des stores ===
\echo (paye_net_usd = abonnements + achats uniques + autres + remboursements. autres_usd = montants positifs des autres événements, un remboursement annulé par exemple.)
\echo (reste_estime_usd = estimation de RevenueCat, calculée sur les seules lignes qui portent leurs taux : à comparer à paye_avec_taux_usd, pas à paye_net_usd.)
\echo (sans_taux = nombre de lignes sans taux. Une case vide veut dire « aucune ligne avec taux ce mois-là », pas zéro.)
WITH e AS (
  SELECT se.*,
         CASE WHEN jsonb_typeof(se.payload -> 'tax_percentage') = 'number' THEN (se.payload ->> 'tax_percentage')::float8 END               AS tax,
         CASE WHEN jsonb_typeof(se.payload -> 'commission_percentage') = 'number' THEN (se.payload ->> 'commission_percentage')::float8 END AS commission
  FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app'))
SELECT to_char(date_trunc('month', event_at), 'YYYY-MM') AS mois,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd > 0 AND type IN ('INITIAL_PURCHASE', 'RENEWAL')), 0)::numeric, 2) AS abonnements_usd,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd > 0 AND type = 'NON_RENEWING_PURCHASE'), 0)::numeric, 2)          AS achats_uniques_usd,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd > 0 AND type NOT IN ('INITIAL_PURCHASE', 'RENEWAL', 'NON_RENEWING_PURCHASE')), 0)::numeric, 2) AS autres_usd,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd < 0), 0)::numeric, 2)                                           AS remboursements_usd,
       round(sum(price_usd)::numeric, 2)                                                                                     AS paye_net_usd,
       round((sum(price_usd) FILTER (WHERE tax IS NOT NULL AND commission IS NOT NULL))::numeric, 2)                         AS paye_avec_taux_usd,
       round(sum(price_usd * (1 - tax - commission))::numeric, 2)                                                            AS reste_estime_usd,
       count(*) FILTER (WHERE tax IS NULL OR commission IS NULL)                                                             AS sans_taux
FROM e
WHERE price_usd IS NOT NULL AND price_usd <> 0
GROUP BY 1
ORDER BY 1;

\echo === Pourquoi ça s arrête : raisons de résiliation et d expiration ===
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app'))
SELECT type,
       store,
       coalesce(period_type, '-')                      AS periode,
       coalesce(cancel_reason, expiration_reason, '-') AS raison,
       count(*)                                        AS evenements
FROM e
WHERE type IN ('CANCELLATION', 'EXPIRATION', 'BILLING_ISSUE')
GROUP BY 1, 2, 3, 4
ORDER BY 1, 5 DESC;

\echo === Gardé et laissé de côté par les sections ci-dessus, avec les montants (rien ne devrait être laissé par erreur) ===
\echo (positifs_usd et negatifs_usd : la somme des montants de tous les types d événements, pas seulement des ventes.)
WITH sorted AS (
  SELECT se.*,
         coalesce(se.environment, '-') AS environnement,
         CASE
           WHEN se.user_id IS NULL THEN 'sans compte (anonyme, supprimé, test)'
           WHEN (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app') THEN 'compte exclu (test, démo, interne, VIP)'
           ELSE 'vrai compte'
         END AS compte
  FROM subscription_events se LEFT JOIN users u ON u.id = se.user_id)
SELECT CASE WHEN environnement = 'PRODUCTION' AND compte = 'vrai compte' THEN 'gardé' ELSE 'laissé de côté' END AS sort,
       environnement,
       compte,
       count(*)                                                                    AS evenements,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd > 0), 0)::numeric, 2) AS positifs_usd,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd < 0), 0)::numeric, 2) AS negatifs_usd,
       min(event_at)::date AS premier,
       max(event_at)::date AS dernier
FROM sorted
GROUP BY 1, 2, 3
ORDER BY 1, 2, 3;

-- The webhook keeps an event and applies it together. When the database
-- refuses the event's row (a value it cannot store) the event is applied
-- alone, so that a purchase is never lost to measurement, and the backend
-- logs "RC webhook: event not recorded". That can leave a subscription
-- changed at a time when no event of its transaction (or no transfer to its
-- account) was kept: this lists them, since the first event kept — before
-- it, every change is one. A row here means purchases are missing from the
-- sections above.
--
-- An empty result proves nothing: the event is only seen while it is the
-- last change of its subscription (a later event of the same transaction
-- hides it, as does one kept within five minutes), and not at all when it
-- changes no subscription (a cancellation, a purchase with no account). The
-- complete trace is the log line: grep the backend logs for it.
\echo === Abonnements modifiés sans événement gardé (une ligne = un événement d achat non enregistré) ===
\echo (Vide ne prouve pas que rien ne manque : la trace complète est « RC webhook: event not recorded » dans les logs du backend.)
SELECT s.original_transaction_id AS transaction,
       s.store,
       s.product_id,
       s.active,
       s.updated_at
FROM subscriptions s
WHERE s.updated_at >= (SELECT min(received_at) FROM subscription_events)
  AND NOT EXISTS (
    SELECT 1 FROM subscription_events se
    WHERE se.received_at BETWEEN s.updated_at - interval '5 minutes' AND s.updated_at + interval '5 minutes'
      AND (coalesce(se.original_transaction_id, se.payload ->> 'transaction_id') = s.original_transaction_id
           OR (se.type = 'TRANSFER' AND se.user_id = s.user_id)))
ORDER BY s.updated_at DESC
LIMIT 50;
