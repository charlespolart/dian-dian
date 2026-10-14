-- Read-only usage stats. Run against prod from your laptop:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-stats.sql
--
-- Excluded from every count: smoke/e2e accounts (@example.com), seed-test
-- accounts (@overridedev.com), the demo account, and VIP accounts (custom flag
-- for special accounts — never counted as users).

\pset format aligned

\echo === Comptes : total / exclus (test + vip) / vrais ===
WITH t AS (
  SELECT id, vip,
         (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app') AS is_excluded
  FROM users)
SELECT count(*)                                AS total_accounts,
       count(*) FILTER (WHERE is_excluded)     AS excluded_accounts,
       count(*) FILTER (WHERE vip)             AS vip_accounts,
       count(*) FILTER (WHERE NOT is_excluded) AS real_accounts
FROM t;

\echo === Comptes exclus (test + vip) ===
SELECT email, vip FROM users
WHERE vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app'
ORDER BY vip DESC, 1;

\echo === Vrais comptes : inscriptions par mois ===
SELECT to_char(date_trunc('month', created_at), 'YYYY-MM') AS mois, count(*)
FROM users
WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app')
GROUP BY 1 ORDER BY 1;

\echo === Actifs (vrais comptes) : ont rempli >= 1 case, par dernière activité ===
WITH real AS (
  SELECT id FROM users
  WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app')),
act AS (
  SELECT p.user_id, max(c.updated_at) AS last_cell, count(*) AS cells
  FROM cells c JOIN pages p ON p.id = c.page_id JOIN real r ON r.id = p.user_id
  GROUP BY p.user_id)
SELECT count(*)                                                        AS ever_filled,
       count(*) FILTER (WHERE last_cell > now() - interval '7 days')   AS active_7d,
       count(*) FILTER (WHERE last_cell > now() - interval '30 days')  AS active_30d,
       count(*) FILTER (WHERE last_cell > now() - interval '90 days')  AS active_90d,
       count(*) FILTER (WHERE cells >= 30)                             AS with_30plus_cells
FROM act;

\echo === Sessions (vrais comptes) : refresh token émis dans les 7 / 30 jours ===
WITH real AS (
  SELECT id FROM users
  WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app'))
SELECT count(DISTINCT user_id) FILTER (WHERE created_at > now() - interval '7 days')  AS sessions_7d,
       count(DISTINCT user_id) FILTER (WHERE created_at > now() - interval '30 days') AS sessions_30d
FROM refresh_tokens rt JOIN real r ON r.id = rt.user_id;

\echo === Payants (hors vip) : abonnements actifs non expirés ===
SELECT count(DISTINCT s.user_id) AS paying_users, count(*) AS active_subs
FROM subscriptions s JOIN users u ON u.id = s.user_id
WHERE s.active AND (s.expires_at IS NULL OR s.expires_at > now()) AND NOT u.vip;

\echo === Payants (hors vip) par produit / store ===
SELECT s.product_id, s.store, count(DISTINCT s.user_id) AS users
FROM subscriptions s JOIN users u ON u.id = s.user_id
WHERE s.active AND (s.expires_at IS NULL OR s.expires_at > now()) AND NOT u.vip
GROUP BY 1, 2 ORDER BY 3 DESC;

\echo === Historique abonnements (tous, hors vip) ===
SELECT s.active, (s.expires_at IS NOT NULL AND s.expires_at <= now()) AS expired, count(*)
FROM subscriptions s JOIN users u ON u.id = s.user_id
WHERE NOT u.vip
GROUP BY 1, 2 ORDER BY 1, 2;
