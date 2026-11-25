-- The site's audience (tables audience_*): visits, visitors of the day, taps
-- on the store buttons, where people come from, and the robots. Read-only.
-- Run against prod:
--
--   ssh root@45.76.44.34 "docker exec -i dian-dian-postgres-1 sh -c 'PGPASSWORD=\$POSTGRES_PASSWORD psql -U postgres -d dian_dian -h localhost'" < backend/scripts/prod-landing.sql
--
-- What these tables are: counts, never people (src/audience). A visit is a
-- view of the home page; a tap is a passage through /go/apple or /go/play;
-- downloads are read at Apple and Google, not here. People and robots are
-- counted apart: every section says which it reads. Whoever objects (the
-- opt-out cookie, Global Privacy Control, Do Not Track) is in no number.
--
-- Reading rules:
--   - "visiteurs" is the number of distinct fingerprints of ONE day. It
--     cannot be added across days (the same person on two days is two), and
--     a restart of the server starts the day's count again. An indicator.
--   - The first section gives exact daily totals. The breakdowns by month
--     show "<10" for a cell under ten: a small cell says more about a few
--     people than about the audience.
--   - The site of origin is the domain of the Referer; when the browser sent
--     none, a utm_source of a closed list stands in for it ("repli"). The
--     ChatGPT apps almost never send a Referer: without the fallback their
--     visits would have no origin.
--   - A robot's name is what it says it is; "verified" means its address is
--     in the ranges its operator publishes. Only verified ChatGPT-User,
--     Claude-User… count as "a person asked an AI to read the page".

\pset format aligned
SET default_transaction_read_only = on;

\echo === Par jour, 30 derniers jours : personnes seulement, chiffres exacts ===
SELECT day                                                                 AS jour,
       visits                                                              AS visites,
       visitors                                                            AS visiteurs,
       taps_apple                                                          AS clics_app_store,
       taps_play                                                           AS clics_google_play,
       round(100.0 * (taps_apple + taps_play) / nullif(visits, 0), 1)      AS clics_pct
FROM audience_totals
WHERE day >= (now() AT TIME ZONE 'utc')::date - 29
ORDER BY day;

\echo === Par mois, 12 derniers : personnes seulement ===
\echo (visiteurs_par_jour = moyenne des visiteurs du jour ; les visiteurs ne s additionnent pas d un jour à l autre.)
SELECT to_char(date_trunc('month', day), 'YYYY-MM')                                 AS mois,
       sum(visits)                                                                  AS visites,
       round(avg(visitors), 1)                                                      AS visiteurs_par_jour,
       sum(taps_apple)                                                              AS clics_app_store,
       sum(taps_play)                                                               AS clics_google_play,
       round(100.0 * sum(taps_apple + taps_play) / nullif(sum(visits), 0), 1)       AS clics_pct
FROM audience_totals
WHERE day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '11 months'
GROUP BY 1
ORDER BY 1;

\echo (Dans toutes les sections par mois qui suivent, 6 derniers mois, « <10 » remplace un nombre sous dix.)
\echo === Par mois et site d origine (visites de personnes, 6 derniers mois) ===
\echo (lu_dans : « Referer » = dit par le navigateur ; « repli » = déduit d un utm_source de la liste fermée. « (aucun) » = ni l un ni l autre.)
WITH v AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, origin, origin_from, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'visit' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2, 3)
SELECT mois,
       CASE WHEN origin = '' THEN '(aucun)' ELSE origin END                                  AS site_d_origine,
       CASE origin_from WHEN 'referer' THEN 'Referer' WHEN 'tag' THEN 'repli' ELSE '-' END   AS lu_dans,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END                                          AS visites
FROM v
ORDER BY mois, n DESC, origin;

\echo === Par mois : lien marqué (un utm_source était présent) ou non ===
WITH v AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, tagged, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'visit' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2)
SELECT mois,
       CASE WHEN tagged THEN 'lien marqué' ELSE 'lien nu' END AS lien,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END           AS visites
FROM v
ORDER BY mois, n DESC;

\echo === Par mois et navigateur intégré d une app (visites de personnes) ===
WITH v AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, in_app, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'visit' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2)
SELECT mois,
       CASE WHEN in_app = '' THEN '(un navigateur)' ELSE in_app END AS app,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END                AS visites
FROM v
ORDER BY mois, n DESC;

\echo === Par mois, appareil et navigateur (visites de personnes) ===
WITH v AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, device, browser, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'visit' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2, 3)
SELECT mois, device AS appareil, browser AS navigateur,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END AS visites
FROM v
ORDER BY mois, n DESC, device, browser;

\echo === Par mois et pays (visites de personnes ; « ?? » = pays inconnu) ===
WITH v AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, country, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'visit' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2)
SELECT mois,
       CASE WHEN country = '' THEN '??' ELSE country END AS pays,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END      AS visites
FROM v
ORDER BY mois, n DESC, country;

\echo === Par mois et langue de la page (visites de personnes) ===
WITH v AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, lang, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'visit' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2)
SELECT mois, lang AS langue,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END AS visites
FROM v
ORDER BY mois, n DESC;

\echo === Clics vers les stores, par mois, store, appareil et app (personnes) ===
\echo (Le bouton App Store s ouvre-t-il depuis le navigateur de Pinterest ou d Instagram ? Comparer aux visites de la même app, plus haut.)
WITH t AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, store, device, in_app, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'store_tap' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2, 3, 4)
SELECT mois, store, device AS appareil,
       CASE WHEN in_app = '' THEN '(un navigateur)' ELSE in_app END AS app,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END                AS clics
FROM t
ORDER BY mois, n DESC, store, device;

\echo === Clics vers les stores, par mois et origine (le clic ne connaît son origine que par le lien marqué) ===
WITH t AS (
  SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois, store, origin, tagged, sum(count) AS n
  FROM audience_counts
  WHERE kind = 'store_tap' AND bot_family = ''
    AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
  GROUP BY 1, 2, 3, 4)
SELECT mois, store,
       CASE WHEN origin <> '' THEN origin WHEN tagged THEN '(lien marqué, hors liste)' ELSE '(lien nu)' END AS origine,
       CASE WHEN n < 10 THEN '<10' ELSE n::text END AS clics
FROM t
ORDER BY mois, n DESC, store;

\echo === Robots par mois, famille, nom et vérification (passages, chiffres exacts) ===
\echo (ai_user = une IA lit la page à la demande d une personne ; ai_search, ai_training ; search = moteurs ; preview = aperçus de lien ; fake = nom impossible.)
SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois,
       bot_family                                   AS famille,
       bot_name                                     AS nom,
       bot_check                                    AS verification,
       sum(count)                                   AS passages,
       sum(count) FILTER (WHERE kind = 'store_tap') AS dont_boutons_store
FROM audience_counts
WHERE bot_family <> ''
  AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '5 months'
GROUP BY 1, 2, 3, 4
ORDER BY 1, 2, 5 DESC, 3;

\echo === Lectures demandées à une IA, par mois : les robots ai_user VÉRIFIÉS seulement ===
\echo (ChatGPT-User est le nom le plus imité : non vérifié, il ne dit rien. Une baisse ne veut pas dire moins d intérêt : ChatGPT répond de plus en plus depuis son index.)
SELECT to_char(date_trunc('month', day), 'YYYY-MM') AS mois,
       bot_name                                     AS nom,
       sum(count)                                   AS lectures
FROM audience_counts
WHERE bot_family = 'ai_user' AND bot_check = 'verified' AND kind = 'visit'
  AND day >= date_trunc('month', now() AT TIME ZONE 'utc')::date - interval '11 months'
GROUP BY 1, 2
ORDER BY 1, 3 DESC;

\echo === Totaux mensuels des jours de plus de 25 mois (le détail par jour a été effacé) ===
SELECT to_char(month, 'YYYY-MM') AS mois,
       visits                    AS visites,
       taps_apple                AS clics_app_store,
       taps_play                 AS clics_google_play,
       bot_hits                  AS passages_de_robots
FROM audience_months
ORDER BY month;
