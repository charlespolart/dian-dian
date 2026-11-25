-- Purchases as RevenueCat reported them (table subscription_events): trials
-- started, converted and cancelled, what was sold and at what price, refunds,
-- why subscriptions end. Read-only. Run against prod:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-purchases.sql
--
-- Every section but the last reads PRODUCTION events of real accounts only:
-- same exclusions as prod-stats.sql (test accounts, demo, internal
-- @mydiandian.app, VIP), and no sandbox purchase (TestFlight, Play test
-- tracks). The last section counts what was left out.
--
-- The table starts with the backend release that created it: nothing before.
-- A subscription is followed by its original_transaction_id, which stays the
-- same from the trial to every renewal. price_usd is RevenueCat's conversion
-- to US dollars (0 for a trial start, negative for a refund); price_local is
-- in the purchase currency.

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

\echo === Essais par mois de départ : démarrés, convertis, résiliés pendant l essai ===
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app')),
trials AS (
  SELECT original_transaction_id AS tx, min(event_at) AS started_at, min(store) AS store, min(product_id) AS product_id
  FROM e
  WHERE type = 'INITIAL_PURCHASE' AND period_type = 'TRIAL' AND original_transaction_id IS NOT NULL
  GROUP BY 1),
outcome AS (
  SELECT t.*,
         (SELECT min(c.event_at) FROM e c
          WHERE c.original_transaction_id = t.tx AND c.type = 'CANCELLATION' AND c.period_type = 'TRIAL') AS cancelled_at,
         EXISTS (SELECT 1 FROM e r
                 WHERE r.original_transaction_id = t.tx AND r.type = 'RENEWAL' AND r.is_trial_conversion) AS converted
  FROM trials t)
SELECT to_char(date_trunc('month', started_at), 'YYYY-MM') AS mois,
       store,
       product_id,
       count(*)                                         AS essais,
       count(*) FILTER (WHERE converted)                AS convertis,
       count(*) FILTER (WHERE cancelled_at IS NOT NULL) AS resilies_pendant_essai,
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

\echo === Revenu par mois : abonnements, achats uniques, remboursements (USD) ===
WITH e AS (
  SELECT se.* FROM subscription_events se JOIN users u ON u.id = se.user_id
  WHERE se.environment = 'PRODUCTION'
    AND NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app'))
SELECT to_char(date_trunc('month', event_at), 'YYYY-MM') AS mois,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd > 0 AND type IN ('INITIAL_PURCHASE', 'RENEWAL')), 0)::numeric, 2) AS abonnements_usd,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd > 0 AND type = 'NON_RENEWING_PURCHASE'), 0)::numeric, 2)          AS achats_uniques_usd,
       round(coalesce(sum(price_usd) FILTER (WHERE price_usd < 0), 0)::numeric, 2)                                           AS remboursements_usd
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

\echo === Laissé de côté par les sections ci-dessus (à surveiller : rien ne devrait y partir par erreur) ===
SELECT coalesce(se.environment, '-') AS environnement,
       CASE
         WHEN se.user_id IS NULL THEN 'sans compte (anonyme, supprimé, test)'
         WHEN (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app' OR u.email ILIKE '%@mydiandian.app') THEN 'compte exclu (test, démo, interne, VIP)'
         ELSE 'vrai compte'
       END AS compte,
       count(*)           AS evenements,
       min(se.event_at)::date AS premier,
       max(se.event_at)::date AS dernier
FROM subscription_events se LEFT JOIN users u ON u.id = se.user_id
GROUP BY 1, 2
ORDER BY 1, 2;
