-- Read-only: how many trackers do real users create and actually use?
-- Purpose: judge the free tier limit (3 trackers). Run against prod:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-trackers.sql
--
-- Excluded everywhere: test accounts (@example.com, @overridedev.com,
-- demo@diandian.app) and VIP accounts. "Paying" = active, unexpired
-- subscription. "Used" tracker = at least one cell filled in the window.

\pset format aligned

-- One row per real user: tier, trackers owned, trackers used in the last 30 / 90 days / ever,
-- and when the user last filled anything.
CREATE TEMP TABLE u AS
WITH real AS (
  SELECT id FROM users
  WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app')),
paying AS (
  SELECT DISTINCT user_id FROM subscriptions
  WHERE active AND (expires_at IS NULL OR expires_at > now())),
page_use AS (
  SELECT p.id AS page_id, p.user_id,
         max(c.updated_at) AS last_cell,
         count(c.*) AS cells
  FROM pages p LEFT JOIN cells c ON c.page_id = p.id
  GROUP BY p.id, p.user_id)
SELECT r.id AS user_id,
       (pg.user_id IS NOT NULL) AS paying,
       count(pu.page_id) AS trackers,
       count(pu.page_id) FILTER (WHERE pu.cells > 0) AS trackers_ever_used,
       count(pu.page_id) FILTER (WHERE pu.last_cell > now() - interval '30 days') AS trackers_used_30d,
       count(pu.page_id) FILTER (WHERE pu.last_cell > now() - interval '90 days') AS trackers_used_90d,
       max(pu.last_cell) AS last_activity
FROM real r
LEFT JOIN paying pg ON pg.user_id = r.id
LEFT JOIN page_use pu ON pu.user_id = r.id
GROUP BY r.id, pg.user_id;

\echo === Trackers possédés par compte (tous les vrais comptes) ===
SELECT paying,
       count(*) AS users,
       count(*) FILTER (WHERE trackers = 0) AS "0",
       count(*) FILTER (WHERE trackers = 1) AS "1",
       count(*) FILTER (WHERE trackers = 2) AS "2",
       count(*) FILTER (WHERE trackers = 3) AS "3",
       count(*) FILTER (WHERE trackers >= 4) AS "4+",
       round(avg(trackers), 2) AS avg_trackers
FROM u GROUP BY paying ORDER BY paying;

\echo === Comptes gratuits à la limite (3 trackers) : en utilisent-ils vraiment 3 ? ===
SELECT count(*) AS free_at_cap,
       count(*) FILTER (WHERE trackers_ever_used = 3) AS use_all_3_ever,
       count(*) FILTER (WHERE trackers_used_90d = 3) AS use_all_3_last_90d,
       count(*) FILTER (WHERE trackers_used_30d = 3) AS use_all_3_last_30d,
       count(*) FILTER (WHERE trackers_used_90d <= 1) AS use_1_or_less_last_90d
FROM u WHERE NOT paying AND trackers >= 3;

\echo === Actifs 30 jours (ont rempli une case) : trackers utilisés sur 30 jours ===
SELECT paying,
       count(*) AS active_users,
       count(*) FILTER (WHERE trackers_used_30d = 1) AS "1",
       count(*) FILTER (WHERE trackers_used_30d = 2) AS "2",
       count(*) FILTER (WHERE trackers_used_30d = 3) AS "3",
       count(*) FILTER (WHERE trackers_used_30d >= 4) AS "4+",
       round(avg(trackers_used_30d), 2) AS avg_used,
       round(avg(trackers), 2) AS avg_owned
FROM u WHERE last_activity > now() - interval '30 days'
GROUP BY paying ORDER BY paying;

\echo === Actifs 90 jours : trackers utilisés sur 90 jours ===
SELECT paying,
       count(*) AS active_users,
       count(*) FILTER (WHERE trackers_used_90d = 1) AS "1",
       count(*) FILTER (WHERE trackers_used_90d = 2) AS "2",
       count(*) FILTER (WHERE trackers_used_90d = 3) AS "3",
       count(*) FILTER (WHERE trackers_used_90d >= 4) AS "4+",
       round(avg(trackers_used_90d), 2) AS avg_used
FROM u WHERE last_activity > now() - interval '90 days'
GROUP BY paying ORDER BY paying;

\echo === Trackers jamais remplis (créés puis abandonnés) ===
SELECT paying,
       sum(trackers) AS trackers_total,
       sum(trackers - trackers_ever_used) AS never_filled,
       round(100.0 * sum(trackers - trackers_ever_used) / nullif(sum(trackers), 0), 1) AS pct_never_filled
FROM u GROUP BY paying ORDER BY paying;

\echo === Titres les plus fréquents (ce que les gens suivent) ===
WITH real AS (
  SELECT id FROM users
  WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app'))
SELECT lower(trim(p.title)) AS title, count(*) AS n
FROM pages p JOIN real r ON r.id = p.user_id
GROUP BY 1 HAVING count(*) >= 2 ORDER BY n DESC, title LIMIT 25;

DROP TABLE u;
