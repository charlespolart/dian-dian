-- Product events (roadmap #2): how often each paywall gate shows, per week,
-- and how many distinct accounts hit it. Read-only. Run against prod:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-events.sql
--
-- Same exclusions as prod-stats.sql (test accounts, demo, VIP).
-- Names: paywall.tracker_limit (the + button at 3 trackers), paywall.locked_tracker
-- (a locked 4th+ tracker opened), paywall.themes / cursor / export / stats /
-- global_stats / no_ads (a premium feature tapped), paywall.list_upgrade /
-- settings_upgrade (the voluntary upgrade buttons).

\pset format aligned

\echo === Événements par semaine, 16 dernières : occurrences et comptes distincts ===
SELECT date_trunc('week', e.created_at)::date AS semaine,
       e.name,
       count(*)                 AS occurrences,
       count(DISTINCT e.user_id) AS comptes
FROM events e JOIN users u ON u.id = e.user_id
WHERE NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app')
  AND e.created_at >= date_trunc('week', now()) - interval '15 weeks'
GROUP BY 1, 2
ORDER BY 1, 2;

\echo === Total par événement ===
SELECT e.name, count(*) AS occurrences, count(DISTINCT e.user_id) AS comptes
FROM events e JOIN users u ON u.id = e.user_id
WHERE NOT (u.vip OR u.email ILIKE '%@example.com' OR u.email ILIKE '%@overridedev.com' OR u.email = 'demo@diandian.app')
GROUP BY 1 ORDER BY 2 DESC;
