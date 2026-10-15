-- Activation by weekly signup cohort. Read-only. Run against prod from your laptop:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-activation.sql
--
-- Same exclusions as prod-stats.sql: smoke/e2e accounts (@example.com),
-- seed-test accounts (@overridedev.com), the demo account, VIP accounts.
--
-- Columns: comptes = signups that week; j1_pct / j7_pct = share with a first
-- cell within 24 h / 7 days of signup; jamais_pct = share with no cell to date.
-- j7 only means something for cohorts older than 7 days.
--
-- Caveat: cells.created_at exists since backend 1.2.0 and was backfilled
-- from updated_at (last edit). For cells written before that, "first cell"
-- is really "last edit of the oldest surviving cell", so j1 / j7 are
-- UNDER-estimated for older cohorts. Cohorts after the backfill are exact.

\pset format aligned

\echo === Activation par cohorte hebdomadaire (semaine d inscription, 16 dernières) ===
WITH real AS (
  SELECT id, created_at
  FROM users
  WHERE NOT (vip OR email ILIKE '%@example.com' OR email ILIKE '%@overridedev.com' OR email = 'demo@diandian.app')
    AND created_at >= date_trunc('week', now()) - interval '15 weeks'),
first_cell AS (
  SELECT p.user_id, min(c.created_at) AS at
  FROM cells c JOIN pages p ON p.id = c.page_id
  GROUP BY p.user_id),
cohort AS (
  SELECT date_trunc('week', r.created_at)::date                          AS semaine,
         r.id,
         f.at IS NOT NULL                                               AS ever,
         f.at IS NOT NULL AND f.at < r.created_at + interval '1 day'    AS j1,
         f.at IS NOT NULL AND f.at < r.created_at + interval '7 days'   AS j7
  FROM real r LEFT JOIN first_cell f ON f.user_id = r.id)
SELECT coalesce(semaine::text, 'total')                                  AS semaine,
       count(*)                                                           AS comptes,
       round(100.0 * count(*) FILTER (WHERE j1) / nullif(count(*), 0))     AS j1_pct,
       round(100.0 * count(*) FILTER (WHERE j7) / nullif(count(*), 0))     AS j7_pct,
       round(100.0 * count(*) FILTER (WHERE NOT ever) / nullif(count(*), 0)) AS jamais_pct
FROM cohort
GROUP BY ROLLUP (semaine)
ORDER BY semaine NULLS LAST;
