-- Offline sync (chantier 10), per week: syncs that sent changes made
-- offline, how many such changes, and how many were set aside and why.
-- Counts only, no account (table sync_stats). Read-only. Run against prod:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-sync.sql
--
-- Kinds: syncs_with_waited, mutations_waited, set_aside_changed (changed on
-- another device meanwhile), set_aside_deleted (deleted on another device),
-- rejected_<reason> (legend_limit, invalid, not_found, locked, tracker_limit).

\pset format aligned
SET default_transaction_read_only = on;

\echo === Par semaine, 16 dernières ===
SELECT week AS semaine, kind, count
FROM sync_stats
WHERE week >= (date_trunc('week', now()) - interval '15 weeks')::date
ORDER BY week, kind;

\echo === Part des modifications faites hors ligne qui ont été écartées, 8 dernières semaines ===
SELECT sum(count) FILTER (WHERE kind = 'mutations_waited') AS faites_hors_ligne,
       sum(count) FILTER (WHERE kind LIKE 'set_aside_%') AS ecartees,
       round(100.0 * sum(count) FILTER (WHERE kind LIKE 'set_aside_%')
             / nullif(sum(count) FILTER (WHERE kind = 'mutations_waited'), 0), 2) AS pourcentage
FROM sync_stats
WHERE week >= (date_trunc('week', now()) - interval '7 weeks')::date;
