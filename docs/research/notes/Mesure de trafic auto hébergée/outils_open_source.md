# Free, open-source, self-hostable web analytics for a 1 vCPU / ~950 MB VPS (state at 2026-11-23)

Context for the report writer: the Dian Dian landing (one page, App Store / Google Play buttons) is rendered server-side by Express (TypeScript) behind Caddy, with PostgreSQL 16, all in Docker on one Debian 12 VPS: 1 vCPU, ~950 MB RAM (~490 MB free today), 8.7 GB free disk. Traffic is tens to a few hundred visits a day. Needs: visits and daily unique visitors; utm_source / utm_campaign (pinterest, chatgpt.com); referring site; device (iPhone / Android / desktop); in-app browser (Pinterest, Instagram, TikTok); country only; App Store / Google Play button clicks; bots, especially AI bots, kept apart and named. No consent banner (CNIL audience-measurement exemption). The tool may be reused for several future sites.

Evidence labels used below:
- [GH-API]: licence, stars, release tags and dates, last commit, read on 2026-11-23 through the GitHub API (`gh api repos/...`). Primary.
- [CODE]: a file in the project's own repository (source, compose file, README), read on 2026-11-23. Primary.
- [DOCS]: the project's official documentation site or blog. Primary.
- [ISSUE]: a GitHub issue or discussion by a user or maintainer. Primary for "someone reported X", anecdotal for the figure itself.
- [3RD]: a third-party article, hosting-provider page or retailer page. Not verified by the project.
- [SNIPPET]: seen only in a search-engine summary; the page itself was not read. Treat as unverified.

Note for the writer: the VPS has ~490 MB free, not 950 MB. Every container added competes with the Express backend, Caddy and the existing Postgres 16 for that headroom.

## Q1. Candidates: licence, activity in 2026, stack, official requirements, reuse of an existing PostgreSQL, Docker, upgrade burden

### Takeaway
The field splits in three. (1) ClickHouse-based tools (Plausible CE, Rybbit, Swetrix, OpenPanel, PostHog) are the most active and feature-rich, but every one of them officially asks for 2 GB RAM or more, which this VPS does not have. (2) Light tools that need no extra database server (GoatCounter, Liwan, Medama, HitKeep, and Umami reusing the existing Postgres) are the only ones that fit in ~490 MB. (3) Several once-popular options are stale or abandoned in 2026 (Fathom Lite, Offen, Vince, Counter.dev self-host, Shynet mostly).

### Cited Findings

Activity and licence snapshot (all [GH-API], read 2026-11-23 unless noted):

| Tool | Licence | Stars | Latest stable release | Last commit | Stack (DB) |
|---|---|---|---|---|---|
| Umami | MIT | 40.3k | v3.5.0, 2026-11-12 | 2026-11-23 | Next.js/Node + PostgreSQL only |
| Plausible CE | AGPL-3.0 | 29.9k | v3.2.2, 2026-11-23 (prev. v3.2.1 2026-05-15, v3.2.0 2026-01-26) | 2026-11-23 | Elixir + PostgreSQL + ClickHouse |
| Matomo | GPL-3.0 | 22.0k | 6.0.0, 2026-11-23 | 2026-11-23 | PHP + MySQL/MariaDB |
| GoatCounter | EUPL-1.2 (slightly modified) | 6.2k | v2.7.0, 2025-12-15 (prev. v2.6.0 2025-06-08) | 2026-09-27 | Go + SQLite or PostgreSQL |
| Rybbit | AGPL-3.0 | 13.4k | v2.9.3, 2026-11-18 | 2026-11-21 | Node + Next.js + ClickHouse + PostgreSQL + Redis |
| Swetrix (CE) | AGPL-3.0 | 1.2k | v5.5.4, 2026-11-15 | 2026-11-15 | NestJS + ClickHouse + Redis (+ nginx) |
| Liwan | Apache-2.0 | 231 | 1.8.x stable; 1.9.0-rc.2 on 2026-11-22 | 2026-11-23 | Rust single binary + embedded DuckDB |
| Shynet | Apache-2.0 | 3.2k | v0.14.0, 2026-03-15 (previous v0.13.1 was 2023-07-28) | 2026-03-15 | Django (Python) |
| Ackee | MIT | 4.7k | v3.7.1, 2026-10-23 | 2026-10-23 | Node + MongoDB |
| Counter.dev | AGPL-3.0 | 1.0k | no GitHub releases | 2026-09-04 (self-host repo: 2023-09-13) | Go + Redis (+ SQL archive) |
| OpenPanel | AGPL-3.0 | 7.3k | v3.30.0, 2026-11-06 (tagged "prerelease" on GitHub) | 2026-11-06 | Redpanda + ClickHouse + PostgreSQL + Redis |
| PostHog | "Other" (MIT core per docs) | 41.0k | continuous | 2026-11-23 | ClickHouse, Kafka, Postgres, Redis… |
| Fathom Lite | MIT | 8.0k | v1.3.1, 2023-01-31 | 2026-03-18 | Go |
| Medama | Apache-2.0 (core, dashboard) + MIT (tracker) | 646 | v0.6.2, 2026-01-18 | 2026-06-28 | Go + SQLite + DuckDB |
| Tianji | Apache-2.0 | 3.1k | v1.34.3, 2026-11-13 | 2026-11-23 | Node + PostgreSQL |
| HitKeep (new, created 2025-11-08) | MIT | 107 | v2.18.1, 2026-11-23 | 2026-11-23 | Go + embedded DuckDB + NSQ |
| Kaunta (new) | MIT | 63 | v0.122.1, 2026-10-02 | 2026-10-02 | Go single binary |
| Vince | AGPL-3.0 | 2.0k | v1.11.8, 2025-09-01 | 2025-09-01 (stale) | Go |
| Offen | Apache-2.0 | 984 | v1.4.2, 2024-05-22 | 2026-03-04 | Go |
| Litlyx | Apache-2.0 | 1.7k | v0.0.19, 2025-12-01 | 2025-12-03 | TypeScript |
| GoAccess (log analyser, not a JS tracker) | MIT | 21.2k | tag v1.12 (~2026-09-16) | 2026-11-20 | C, reads web-server logs |

Sources for the table: GitHub repos [umami-software/umami](https://github.com/umami-software/umami/releases), [plausible/analytics](https://github.com/plausible/analytics/releases), [matomo-org/matomo](https://github.com/matomo-org/matomo/releases), [arp242/goatcounter](https://github.com/arp242/goatcounter/releases), [rybbit-io/rybbit](https://github.com/rybbit-io/rybbit/releases), [Swetrix/swetrix](https://github.com/Swetrix/swetrix/releases), [explodingcamera/liwan](https://github.com/explodingcamera/liwan/releases), [milesmcc/shynet](https://github.com/milesmcc/shynet/releases), [electerious/Ackee](https://github.com/electerious/Ackee/releases), [ihucos/counter.dev](https://github.com/ihucos/counter.dev) + [counter.dev-selfhost](https://github.com/ihucos/counter.dev-selfhost), [Openpanel-dev/openpanel](https://github.com/Openpanel-dev/openpanel/releases), [PostHog/posthog](https://github.com/PostHog/posthog), [usefathom/fathom](https://github.com/usefathom/fathom/releases), [medama-io/medama](https://github.com/medama-io/medama/releases), [msgbyte/tianji](https://github.com/msgbyte/tianji/releases), [PascaleBeier/hitkeep](https://github.com/PascaleBeier/hitkeep/releases), [seuros/kaunta](https://github.com/seuros/kaunta), [vinceanalytics/vince](https://github.com/vinceanalytics/vince/releases), [offen/offen](https://github.com/offen/offen/releases), [Litlyx/litlyx](https://github.com/Litlyx/litlyx/releases), [allinurl/goaccess](https://github.com/allinurl/goaccess/tags). [GH-API]

Per-tool details:

- **Umami**: README requirements are "Node.js version 20.19+ (22 LTS recommended)" and "A PostgreSQL database version v12.14+"; configured with a single `DATABASE_URL`, so it can point at an existing Postgres; Docker image `ghcr.io/umami-software/umami`; the official compose bundles `postgres:15-alpine`; upgrade = `docker compose pull && docker compose up --force-recreate -d` (migrations run on start). [CODE] — [README](https://github.com/umami-software/umami/blob/HEAD/README.md), [docker-compose.yml](https://github.com/umami-software/umami/blob/HEAD/docker-compose.yml)
- Umami v3.0.0 (2025-11-07) is a breaking release: "Umami v3 no longer supports MySQL as a database option, only PostgreSQL." [GH-API] — [v3.0.0 release notes](https://github.com/umami-software/umami/releases/tag/v3.0.0)
- Umami's `package.json` (v3.5.0) also ships `@clickhouse/client` and `kafkajs`, and the repo has `db/clickhouse` next to `db/postgresql`: ClickHouse is an optional scale-out backend, not required. [CODE] — [package.json](https://github.com/umami-software/umami/blob/HEAD/package.json)
- Umami publishes no official minimum RAM; a retailer page says "no numerical official minimum published". [3RD] — [ZimaSpace](https://shop.zimaspace.com/pages/umami-hardware-requirements)
- **Plausible CE**: README prerequisites: CPU with SSE 4.2 or NEON "(required by ClickHouse)" and "At least **2 GB of RAM** is recommended for running ClickHouse and Plausible without fear of OOMs." [CODE] — [community-edition README](https://github.com/plausible/community-edition/blob/HEAD/README.md)
- Plausible CE compose runs three containers: `postgres:16-alpine`, `clickhouse/clickhouse-server:24.12-alpine` (with bundled `low-resources.xml` tuning files), and `ghcr.io/plausible/community-edition:v3.2.2`. `DATABASE_URL` is configurable (default points at the bundled `plausible_db`). [CODE] — [compose.yml](https://github.com/plausible/community-edition/blob/HEAD/compose.yml); [DOCS] — [CE wiki configuration](https://github.com/plausible/community-edition/wiki/configuration)
- Plausible CE is "published twice per year" as a long-term release, while the cloud is updated "multiple times per week". [DOCS] — [plausible.io/docs/self-hosting](https://plausible.io/docs/self-hosting)
- **Matomo 6.0.0** needs "PHP version 8.1 or newer and database required MySQL 8.0 or newer / MariaDB 10.6 or newer"; PostgreSQL is not mentioned. Minimum recommended for ≤100,000 page views/month on one server: "2 CPUs, 2 GB RAM, and 50 GB SSD". [DOCS] — [Matomo requirements](https://matomo.org/faq/on-premise/matomo-requirements/)
- **GoatCounter**: "The only dependency is somewhere to store a SQLite database file or a PostgreSQL connection"; Docker image `arp242/goatcounter`; `GOATCOUNTER_DB='postgresql+postgresql://…'` points it at an existing Postgres; upgrades may need migrations (`goatcounter serve -automigrate`). The licence is "a slightly modified version of European Union Public License (EUPL) 1.2". [CODE] — [README](https://github.com/arp242/goatcounter/blob/HEAD/README.md), [LICENSE](https://github.com/arp242/goatcounter/blob/HEAD/LICENSE)
- **Rybbit**: docs: "Try to get one with at least 2GB of RAM"; ARM must be ≥ ARMv8.2-A "for ClickHouse support"; the default script assumes a blank VPS and sets up its own Caddy; a manual compose guide exists for an existing reverse proxy. [DOCS] — [rybbit.com/docs/self-hosting](https://rybbit.com/docs/self-hosting)
- Rybbit's compose runs `clickhouse-server:26.3`, `postgres:17.4`, `redis:8.6.4-alpine`, a backend (`CLUSTER_WORKERS` default 4) and a Next.js client; ClickHouse is capped at `max_server_memory_usage_to_ram_ratio` 0.80. Postgres is reached through `POSTGRES_HOST/PORT/DB/USER/PASSWORD` variables. [CODE] — [docker-compose.yml](https://github.com/rybbit-io/rybbit/blob/HEAD/docker-compose.yml)
- **Swetrix CE**: compose runs `swetrix-fe`, `swetrix-api` (v5.5.4), `redis:8.10.3-alpine`, `clickhouse-server:26.8` and `nginx`. No official RAM figure found; a retailer page claims the guide recommends ≥2 GB. [CODE] — [Swetrix/selfhosting compose.yaml](https://github.com/Swetrix/selfhosting/blob/HEAD/compose.yaml); [3RD] — [ZimaSpace](https://shop.zimaspace.com/pages/swetrix-hardware-requirements)
- **Liwan**: "Run Liwan as a single binary or Docker container. The dashboard and database are built in, with no additional services to manage." Cargo dependencies include `duckdb` and `maxminddb`. Docker image `ghcr.io/explodingcamera/liwan:1.8`, port 9042, one `/data` volume, `LIWAN_TRUSTED_PROXIES` for a reverse proxy. [CODE] — [README](https://github.com/explodingcamera/liwan/blob/HEAD/README.md), [crates/liwan/Cargo.toml](https://github.com/explodingcamera/liwan/tree/HEAD/crates); [DOCS] — [liwan.dev/install/docker](https://liwan.dev/install/docker/)
- **Medama**: "Simple, single-binary setup with no external dependencies, capable of running on VMs with 256MB memory for most small websites"; `go.mod` pulls `duckdb-go` and `go-sqlite3`. [CODE] — [README](https://github.com/medama-io/medama/blob/HEAD/README.md), [core/go.mod](https://github.com/medama-io/medama/blob/HEAD/core/go.mod)
- **HitKeep**: "one Go binary with embedded DuckDB and NSQ"; no "separate PostgreSQL, Redis, ClickHouse, Kafka, or queue service is required"; Docker Compose uses "one container and three persistent volumes". No RAM figure on the install page. [DOCS] — [hitkeep.com installation](https://hitkeep.com/guides/installation/)
- **Shynet**: "Shynet can easily run as a single docker container on a single small VPS"; v0.14.0 (March 2026) is mostly security fixes (wildcard `ALLOWED_HOSTS`, stored XSS) and dependency bumps, the first release since July 2023. [CODE] — [README](https://github.com/milesmcc/shynet/blob/HEAD/README.md); [GH-API] — [v0.14.0](https://github.com/milesmcc/shynet/releases/tag/v0.14.0)
- **Ackee**: "Lightweight Node.js and MongoDB architecture"; GraphQL API. [CODE] — [README](https://github.com/electerious/Ackee/blob/HEAD/README.md)
- **Counter.dev**: "a small Go server and static assets. Everything is saved to Redis. A normal SQL database is used for archiving older data"; collects only aggregated data. [CODE] — [README](https://github.com/ihucos/counter.dev/blob/HEAD/README.md)
- **OpenPanel**: recommends "at least 4GB RAM" because "Redpanda, ClickHouse, and Postgres run side by side"; Redis also used; `openpanel init` asks whether to run Postgres/ClickHouse/Redis or use your own; upgrade via `openpanel upgrade`. [DOCS] — [openpanel.dev self-hosting](https://openpanel.dev/docs/self-hosting/self-hosting)
- **PostHog** hobby deploy: "something equivalent to a Hetzner VM with 4 vCPU, 16GB RAM, and more than 30GB storage"; self-hosted deployments are "officially unsupported"; Docker Compose deployment is MIT. [DOCS] — [posthog.com/docs/self-host](https://posthog.com/docs/self-host)
- **Fathom Lite**: "While we are no longer adding features to this Lite version, we will be continuing to maintain it long-term and fix any bugs"; "Older Lite UI", "Bugfixes / maintenance". [CODE] — [README](https://github.com/usefathom/fathom/blob/HEAD/README.md)
- **Tianji**: "Website analytics + Uptime Monitor + Server Status" in one app; compose uses `DATABASE_URL: postgresql://…` with `postgres:15.4-alpine`, so an existing Postgres URL can be given. [CODE] — [README](https://github.com/msgbyte/tianji/blob/HEAD/README.md), [docker-compose.yml](https://github.com/msgbyte/tianji/blob/HEAD/docker-compose.yml)
- **GoAccess**: "real-time web log analyzer and interactive viewer"; reads "Caddy's JSON Structured format"; "Only one dependency" (ncurses), written in C; HTML real-time report with its own WebSocket server; on-disk persistence for incremental processing. [CODE] — [README](https://github.com/allinurl/goaccess/blob/HEAD/README.md)
- Other newer single-binary projects found in a 2026 search: Sparklytics (DuckDB, MIT, 0 stars, last push 2026-05-14), Munin (Go, AGPL, "drop-in replacement for Umami", ~50 MB RSS claim, 0 stars, no GeoIP by default). [GH-API] [SNIPPET] — [Sparklytics](https://github.com/Sparklytics/sparklytics), [Munin](https://github.com/Tdude/munin)

### Inferences
- Only Umami, GoatCounter and Tianji can reuse the existing PostgreSQL 16 as their sole datastore. Plausible CE and Rybbit could point their Postgres part at it, but they still need ClickHouse, which is the heavy part.
- Matomo cannot use the existing Postgres. It needs an extra MySQL 8 / MariaDB 10.6 container plus PHP and an archiving cron.
- Upgrade burden, lowest to highest: single binaries (GoatCounter, Liwan, Medama, HitKeep: replace one image/binary, one volume) < Umami (one image, Prisma migrations on start, depends on the shared Postgres) < Plausible CE (three containers; ClickHouse major versions; CE only twice a year) < Rybbit / Swetrix / OpenPanel (4–6 containers, frequent releases) < PostHog.
- Bus-factor risk: Liwan (231 stars), HitKeep (107 stars, one year old), Kaunta and Medama are small projects, mostly single-maintainer. GoatCounter is also one maintainer, with a slower release cadence (one release in 2025-12, none yet in 2026).
- Counter.dev's self-host repo has not moved since 2023, so it is effectively SaaS-only. Fathom Lite, Offen and Vince are stale. Shynet is on life support. None of these should be picked for a new setup.

### Gaps
- No official RAM figure for Umami, GoatCounter, Liwan, HitKeep, Tianji, Shynet or Ackee; only Medama (256 MB) and the ClickHouse tools publish one.
- Whether Liwan, Medama or HitKeep can use PostgreSQL instead of their embedded store: not found (they appear embedded-only).
- PostHog's repository licence shows as "Other" on GitHub (mixed MIT + `ee/` proprietary); only the docs' "MIT" statement for the Docker Compose deploy was read.
- Counterscale (MIT, 2.2k stars, last commit 2026-10-04) was checked for activity only. Its runtime target was not verified (believed Cloudflare-Workers-only, which would rule it out).

## Q2. Feature coverage against the Dian Dian list

### Takeaway
Nearly all candidates cover visits, cookieless unique visitors, referrers, UTM campaigns, browser/OS/device, country and custom events. The differences lie in three needs. The first is server-side ingestion (bots don't run JS, and Express could send events itself). Umami, Plausible, Rybbit, Matomo, GoatCounter and Liwan have it. The second is in-app browser detection, which no tool clearly documents. The third is named bots (Q3). For the button clicks, Umami v3 "links" (tracked redirect URLs) and GoatCounter/Umami server-side events match the planned `/go/apple` and `/go/play` redirects.

### Cited Findings
- **Umami server-side API**: `POST /api/send` (and `POST /api/batch` with a JSON array); payload has `hostname, url, referrer, title, name, data, language, screen, id, website`, `type` = event / identify / performance / error; "you do not need to send an authentication token"; "you need to send a proper `User-Agent` HTTP header or your request won't be registered." [DOCS] — [docs.umami.is sending stats](https://docs.umami.is/docs/api/sending-stats)
- **Umami GeoIP**: build script downloads `GeoLite2-City` from MaxMind if `MAXMIND_LICENSE_KEY` is set, otherwise from the `GitSquared/node-geolite2-redist` mirror; `GEO_DATABASE_URL` overrides. [CODE] — [scripts/build-geo.js](https://github.com/umami-software/umami/blob/HEAD/scripts/build-geo.js)
- **Umami v3 features**: universal filters, saved segments and cohorts, "Links" ("short URLs that redirect to another URL… to measure how often users are clicking on certain links") and "Pixels"; each has its own stats page. [GH-API] — [v3.0.0 release notes](https://github.com/umami-software/umami/releases/tag/v3.0.0)
- **Umami UTM report** breaks down source, medium, campaign, term and content. CSV export is documented for Umami Cloud (emailed gzipped CSV); a competitor's article claims self-hosted has no official export tool. [DOCS] — [umami.is UTM report](https://umami.is/docs/reports/report-utm), [Cloud export](https://docs.umami.is/docs/cloud/export-data); [3RD, competitor] — [OpenPanel article](https://openpanel.dev/articles/how-to-export-data-from-umami)
- **Plausible events API**: `POST /api/event`; `User-Agent` required, `X-Forwarded-For` should carry the visitor IP when sent from a backend; required body `domain, name, url`, optional `referrer, props, revenue, interactive`; up to 30 custom props; unique visitors are computed from the raw User-Agent + IP + hostname, "The raw value of the IP address is not stored"; forwarding a server/hosting/CDN IP makes "Plausible's bot filtering … drop the event" (HTTP 202 + `x-plausible-dropped: 1`). [DOCS] — [plausible.io/docs/events-api](https://plausible.io/docs/events-api)
- **Plausible CE GeoIP**: bundled DB-IP **country** database (`dbip-country.mmdb.gz`); setting `MAXMIND_LICENSE_KEY` switches to a free GeoLite2 (default edition GeoLite2-City). [DOCS] — [CE wiki configuration](https://github.com/plausible/community-edition/wiki/configuration)
- **GoatCounter ingestion**: three ways: JS script (~3.5K), "HTTP/REST API, for example from your backend server middleware", or "Parse logfiles of nginx, Apache, Caddy, CloudFront…" (`goatcounter import`); a no-JS image tracker also exists. Unique visits "without cookies using a non-identifiable hash". [CODE] — [README](https://github.com/arp242/goatcounter/blob/HEAD/README.md)
- **GoatCounter API**: `POST /api/v0/count` with `Authorization: Bearer`, batching several hits per request; API limit 4 requests/second; CSV export via `POST /api/v0/export` with incremental `start_from_hit_id`. [DOCS] — [goatcounter.com/api](https://www.goatcounter.com/api)
- **GoatCounter campaigns**: "The campaign name is in the `utm_campaign` or `campaign` parameter"; source in `utm_source`, `ref`, `src` or `source`, falling back to the referrer; shown in a Campaigns dashboard widget, created automatically. [DOCS] — [goatcounter.com/help/campaigns](https://www.goatcounter.com/help/campaigns)
- **Liwan**: tracker sends page URL, referrer, UTM values (`utm_source…utm_term` stored separately and individually toggleable; `source`/`ref` aliases), screen-width bucket, event name and custom properties; visitor grouping by hashing IP, user agent, entity ID and a salt that "rotates daily"; country and city from a MaxMind database or trusted proxy headers; browser/platform families and device type from the UA. [DOCS] — [liwan.dev/collected-data](https://liwan.dev/collected-data/)
- Liwan README: "Add a small browser script with one line of HTML, or send events entirely from your server"; SSO (Google Workspace, Entra, OIDC). [CODE] — [README](https://github.com/explodingcamera/liwan/blob/HEAD/README.md)
- **Rybbit server-side API**: `POST /api/track` with `site_id` and `type` (`pageview`, `custom_event`, `outbound`, `button_click`, …), `pathname`, `querystring` (e.g. `?utm_source=newsletter`), `hostname`, `referrer`, `anonymous_id`, `user_id`; with an `ingest:write` API key the visitor's `ip_address` and `user_agent` can be passed; "Otherwise every event shares your server's IP and user agent and counts as one visitor." Unknown fields are rejected with 400. [CODE] — [docs sending-events.mdx](https://github.com/rybbit-io/rybbit/blob/HEAD/docs/content/docs/api/sending-events.mdx)
- Rybbit README lists organisations and unlimited sites, goals and events, funnels, journeys, retention, session replays, public dashboards and an ASN/MaxMind geolocation layer (`server/src/db/geolocation`). [CODE] — [README](https://github.com/rybbit-io/rybbit/blob/HEAD/README.md)
- **Matomo** HTTP tracking API (`matomo.php`, GET with `idsite`, `rec=1`, `ua`, `url`) is usable from a backend; Matomo recommends sending "asynchronously or through a queue". [DOCS] — [Matomo AI chatbot HTTP API FAQ](https://matomo.org/faq/how-to/set-up-ai-chatbot-tracking-with-the-http-tracking-api/)
- Matomo core ships plugins such as `MarketingCampaignsReporting`, `Referrers`, `DevicesDetection`, `UserCountry`, `GeoIp2`, `Goals`, `Events`, `MultiSites`, `QueuedTracking`, `BotTracking`, `AIAgents`, `TrackingSpamPrevention`. [CODE] — [matomo/plugins](https://github.com/matomo-org/matomo/tree/HEAD/plugins)
- **Ackee**: "No unique user tracking"; "Events: Track button clicks, newsletter subscriptions and more"; GraphQL API. [CODE] — [README](https://github.com/electerious/Ackee/blob/HEAD/README.md)
- **Counter.dev** counts unique users with "`sessionStorage` facilities, the browser's cache mechanism and inspecting the referrer"; aggregated data only; its own FAQ says that "all SaaS Web Analytics - including counter.dev - needs consent" under ePrivacy (author's opinion). [CODE] — [README](https://github.com/ihucos/counter.dev/blob/HEAD/README.md)
- **GoAccess** (logs): "UTM Campaign Tracking — Breaks down campaign traffic by medium, source, campaign, content and term, all extracted from the requested URL"; "Metrics per Virtual Host"; country from a configured GeoIP (MaxMind `mmdb`) database; ASN mapping. [CODE] — [README](https://github.com/allinurl/goaccess/blob/HEAD/README.md)
- **HitKeep** README: "goals, funnels, ecommerce revenue, UTM and QR campaigns, Search Console, and Web Vitals"; "REST API, webhooks, share links"; "export your data in open formats". [CODE] — [README](https://github.com/PascaleBeier/hitkeep/blob/HEAD/README.md)
- **Tianji** roadmap ticks "website analysis", "utm track", "openapi", "team collaboration". [CODE] — [README](https://github.com/msgbyte/tianji/blob/HEAD/README.md)

Coverage matrix (✓ = verified above, ~ = partial or workaround, ? = not verified):

| Need | Umami | Plausible CE | Matomo | GoatCounter | Rybbit | Swetrix | Liwan | Medama | HitKeep | GoAccess (logs) |
|---|---|---|---|---|---|---|---|---|---|---|
| Visits + cookieless uniques | ✓ | ✓ | ✓ | ✓ | ✓ | ? | ✓ (daily salt) | ✓ (README) | ? | ~ (log-based) |
| UTM source/campaign | ✓ | ? (not read) | ✓ (plugin) | ✓ | ✓ | ? | ✓ | ? | ✓ | ✓ |
| Referrer | ✓ | ✓ | ✓ | ✓ | ✓ | ? | ✓ | ? | ? | ✓ |
| Device/OS/browser | ✓ | ? | ✓ | ✓ | ✓ | ? | ✓ | ? (go-useragent) | ? | ✓ |
| In-app browser (Pinterest/IG/TikTok) | ? | ? | ? | ? | ? | ? | ? | ? | ? | ? |
| Country (built-in GeoIP) | ✓ GeoLite2-City | ✓ DB-IP country | ✓ GeoIp2 plugin | ? | ✓ MaxMind | ? | ✓ MaxMind | ? | ? | ✓ mmdb |
| Button clicks / events | ✓ events + links | ✓ | ✓ | ✓ | ✓ | ? | ✓ | ? | ✓ | ~ via redirect URLs |
| Server-side ingestion API | ✓ no auth | ✓ | ✓ | ✓ + log import | ✓ API key | ? | ✓ | ✓ OpenAPI | ~ (needs "a real visit") | n/a (reads logs) |
| Multi-site | ✓ | ✓ | ✓ | ✓ | ✓ | ? | ✓ (entities) | ? | ✓ (tenants) | ✓ (vhosts) |
| Export | ~ (cloud documented; SQL on own PG) | ? (not read) | ~ (core API plugin; export not read) | ✓ CSV API | ? | ? | ? | ? | ✓ (README claim) | ~ (HTML report verified; JSON/CSV not checked) |

### Inferences
- For the "store taps" funnel already specced (`/go/apple`, `/go/play` redirects), two patterns fit without client JS: Umami v3 "links" (Umami hosts the redirect), or Express itself sending a server-side event (Umami `/api/send`, GoatCounter `/api/v0/count`, Liwan, Rybbit `/api/track`, Plausible `/api/event`) before issuing the 302. A log analyser like GoAccess would also see the redirect hits in Caddy's log.
- In-app browser detection (Pinterest, Instagram, TikTok webviews) depends on the user-agent parser each tool uses. None of the docs read lists it as a dimension. It is likely shown, at best, as "Instagram"/"Facebook" browser names in some parsers, and otherwise needs a custom event property set by the site (for example Express parsing the UA and passing `in_app=pinterest` as event data).
- Country-only: tools that store city by default (Umami with GeoLite2-City, Liwan, Plausible with MaxMind) may need a setting or to ignore the city column. Plausible CE's default DB-IP database is country-only, and Liwan says "Location detail is adjustable" ([README](https://github.com/explodingcamera/liwan/blob/HEAD/README.md)).

### Gaps
- In-app browser detection: not documented by any candidate read; needs a hands-on test with real Pinterest/Instagram/TikTok UAs.
- GoatCounter's GeoIP source (bundled DB or MaxMind) and its device-type dimension were not verified.
- Swetrix, Medama and Shynet feature details (UTM, server-side API, export) were not read from primary docs.
- Self-hosted Umami data export: only the Cloud export is documented; there is direct SQL access to the shared Postgres anyway.
- Plausible CE's UTM/source and CSV-export pages were not fetched in this pass; they are widely known features but unverified here.

## Q3. Bot handling: filtered, counted, or named? AI crawlers (GPTBot, ChatGPT-User, ClaudeBot, PerplexityBot)?

### Takeaway
Most tools only drop bots silently (Umami, Plausible CE, Liwan, Swetrix). Three go further. **Rybbit** stores blocked bots as bot events and shows them by name, operator and purpose (`ai_training` / `ai_search` / `ai_agent`), and its docs explain how to forward non-JS crawlers from the edge. **Matomo** (core `BotTracking` plugin, 5.8.0+, March 2026) names only *user-triggered* AI assistants (ChatGPT-User, Claude-User, Perplexity-User…), not training crawlers. **GoAccess** classifies AI crawlers separately straight from the Caddy logs. In every JS-based tool, crawlers that don't run JavaScript are invisible unless the server forwards them.

### Cited Findings
- **Umami** `/api/send`: `if (!process.env.DISABLE_BOT_CHECK && isbot(userAgent)) { return json({ beep: 'boop' }); }`, so bots are silently discarded (HTTP 200, nothing stored) and not named; `DISABLE_BOT_CHECK` turns the filter off globally. [CODE] — [src/app/api/send/route.ts](https://github.com/umami-software/umami/blob/HEAD/src/app/api/send/route.ts)
- **Plausible CE**: "Basic bot filtering that targets the most common non-human traffic" (User-Agent + referrer-spam domains); the cloud adds "Advanced bot filtering", excluding "~40,800 data center IP ranges". No bot report. [DOCS] — [plausible.io/docs/self-hosting](https://plausible.io/docs/self-hosting)
- **Liwan**: "Obvious bot traffic is filtered before storage", "bot filtering enabled by default", so bots are not counted. [DOCS] — [liwan.dev/collected-data](https://liwan.dev/collected-data/); [CODE] — [README](https://github.com/explodingcamera/liwan/blob/HEAD/README.md)
- **GoatCounter**: the count handler calls `isbot.Bot(r)`, skips browser prefetches, and stores the backend classification in `hit.Bot` ("Prefer the backend detection"). Bots are therefore flagged by category code, not by name. [CODE] — [handlers/count.go](https://github.com/arp242/goatcounter/blob/HEAD/handlers/count.go)
- **Swetrix CE** `bot-detection.service.ts` uses `isbot` plus reasons `user_agent`, `headless_browser`, `suspicious_headers`, `probe_path` (e.g. `/.env`, `/.git`), `referrer_spam`, `datacenter_ip`, with per-project "BotsProtectionLevel". [CODE] — [community bot-detection.service.ts](https://github.com/Swetrix/swetrix/blob/HEAD/backend/apps/community/src/analytics/bot-detection.service.ts)
- **Rybbit**: per-site "Block Bot Traffic" (on by default). When on, a detected bot "is kept out of your normal analytics and stored as a bot event instead". Bot event records include "route, device, location, ASN, and which detection layers matched". Five layers: UA patterns ("AI crawler and agent user-agents"…), header heuristics, client signals, ASN (curated AI/scanner ASNs), rate/anomaly. [CODE] — [docs bot-detection.mdx](https://github.com/rybbit-io/rybbit/blob/HEAD/docs/content/docs/(docs)/bot-detection.mdx)
- Rybbit bot identity: curated UA matches carry `bot_name` (e.g. `GPTBot`), `bot_operator` (e.g. `OpenAI`) and `bot_purpose`, "which is what the Bots dashboard groups by". Purposes: `ai_training` (GPTBot, ClaudeBot, CCBot, Google-Extended, Bytespider), `ai_search` (OAI-SearchBot, Claude-SearchBot, PerplexityBot), `ai_agent` (ChatGPT-User, Claude-User, Perplexity-User, Google-Agent, Claude Code), plus `search`, `social_preview`, `seo`, `monitoring`, `security`, `scripted`, `headless`. Broad-pattern matches appear as "Unnamed". [CODE] — [same file](https://github.com/rybbit-io/rybbit/blob/HEAD/docs/content/docs/(docs)/bot-detection.mdx)
- Rybbit on non-JS crawlers: "a crawler that fetches your HTML and executes nothing never reaches Rybbit at all. Most AI training crawlers work exactly that way… If you want to see them, report them from the edge (middleware, a worker, or a reverse proxy), forwarding the real request's `user_agent`" to `/api/track` with an `ingest:write` key; with blocking on, it "lands in your bot events with full identity, rather than in your analytics as a phantom visitor". [CODE] — [same file](https://github.com/rybbit-io/rybbit/blob/HEAD/docs/content/docs/(docs)/bot-detection.mdx)
- **Matomo** core `BotTracking` plugin: `BotDetector` matches only `ChatGPT-User`, `MistralAI-User`, `Gemini-Deep-Research`, `Claude-User`, `Perplexity-User`, `Google-GeminiNotebook`/`Google-NotebookLM` (type `ai_chatbot`); training crawlers such as GPTBot, ClaudeBot and PerplexityBot are not in the list. [CODE] — [plugins/BotTracking/BotDetector.php](https://github.com/matomo-org/matomo/blob/HEAD/plugins/BotTracking/BotDetector.php)
- Matomo 5.8.0 (announced 18 March 2026) added an "AI Chatbots" report to the "AI Assistants" suite, next to an existing "AI Agents" report and AI-referral reporting. [DOCS] — [Matomo blog 2026-03](https://matomo.org/blog/2026/03/new-feature-matomo-ai-assistants-tracking/)
- Matomo ingestion for chatbots is server-side: send `matomo.php?idsite=…&rec=1&recMode=1|2&ua=<full UA>&url=…`; `recMode=1` keeps chatbot hits only, `recMode=2` lets Matomo choose bot vs visit; hits are recorded in "no-visit mode" (no visits, sessions or attribution); optional status code, bytes and server time. [DOCS] — [Matomo HTTP API FAQ](https://matomo.org/faq/how-to/set-up-ai-chatbot-tracking-with-the-http-tracking-api/)
- Third-party sources disagree on GPTBot in Matomo: a Silverstripe package says "Crawlers such as GPTBot and ClaudeBot are ignored by Matomo in bot mode", while a WordPress plugin claims it detects GPTBot/ClaudeBot/PerplexityBot (Matomo 5.7+). The core source above sides with "ignored". [SNIPPET] — [packagist silverstripe-matomo-ai-tracking](https://packagist.org/packages/hamaka/silverstripe-matomo-ai-tracking); [Matomo Site Kit](https://bal.wordpress.org/plugins/?p=173603)
- **GoAccess**: "Bot and Crawler Classification — Keeps AI crawlers and Fediverse (ActivityPub) traffic in their own categories, separate from traditional search engine crawlers"; can drop or isolate networks by ASN (`--exclude-asn`, `--include-asn`). [CODE] — [README](https://github.com/allinurl/goaccess/blob/HEAD/README.md)
- **HitKeep** README: "treats AI as a first-class traffic channel: crawler fetches, AI-referred visits, and chatbot outcomes remain distinct". Its install page does not describe how crawler fetches get in. [CODE] — [README](https://github.com/PascaleBeier/hitkeep/blob/HEAD/README.md); [DOCS] — [installation](https://hitkeep.com/guides/installation/)

### Inferences
- For Dian Dian's requirement ("bots separated and named, especially AI"), only Rybbit, GoAccess and (partially) Matomo and HitKeep do it out of the box. With Umami, Plausible, Liwan or GoatCounter, the server would have to log bots itself, for example as a custom event with the bot name as a property sent with a non-bot UA (a hack; Umami would otherwise drop it), or in its own Postgres table. That is what the home-made counter spec already plans.
- Whatever tool is chosen, AI training crawlers (GPTBot, ClaudeBot) will only be seen if Express or Caddy reports them, because they don't execute JS. The bot naming has to happen server-side, in the app or from Caddy's access log.
- GoAccess over Caddy's JSON log is the cheapest way to get named crawler categories with zero code. It can complement a JS tool rather than replace it.

### Gaps
- GoatCounter: whether bot-flagged hits are ever shown in the UI. The code stores `hit.Bot`, but no doc on displaying them was found.
- Swetrix: whether blocked bots are counted/shown anywhere in the dashboard: not verified.
- Exact list of AI crawler names GoAccess recognises, and whether it separates "ai_training" from "user-triggered": not read (would need its `browsers.c` list).
- Matomo's log importer (`import_logs.py`) is believed to have a `--enable-bots` option that records bots with their UA; not re-verified in this pass.
- HitKeep's mechanism for "crawler fetches" (log ingestion, middleware or server API) is undocumented on the pages read.

## Q4. Real-world reports on a 1 GB / 1 vCPU VPS; ClickHouse memory needs

### Takeaway
ClickHouse is officially a 2 GB+ component even when tuned, and every ClickHouse-based tool recommends ≥2 GB (OpenPanel 4 GB, PostHog 16 GB). Reports of Plausible on 1 GB exist but date from 2020–2021, before the current ClickHouse versions. Umami itself is reported at ~270–360 MB RSS in v3 (2026), more than v2, which is a large share of the 490 MB free. Single-binary Go/Rust tools (Medama "256 MB", Munin "~50 MB" claim) are the only ones with a clear margin.

### Cited Findings
- ClickHouse: "The recommended amount of RAM is 32 GB or more"; under 16 GB "you may experience various memory exceptions because default settings do not match"; it can run on "as low as 2 GB" but such setups "require additional tuning and can only ingest at a low rate". Tuning: smaller mark cache (down to ~500 MB), 1 query thread, `max_block_size` 8192 (1024 workable), `max_download_threads` 1, disable parallel parsing/formatting and system log tables. [DOCS] — [ClickHouse usage recommendations](https://clickhouse.com/docs/operations/tips)
- Swetrix ships ClickHouse configs (`preserve-ram-config.xml`, `preserve-ram-user.xml`: `mark_cache_size` 512 MB, `concurrent_threads_soft_limit_num` 1, `max_block_size` 2048) "aimed to reduce the RAM usage on Clickhouse database, to around 250-500 MB depending on the usage… a good starting point for smaller sites (<1M total events)". This is ClickHouse alone, before the API, frontend, Redis and nginx. [CODE] — [Swetrix/selfhosting clickhouse/README.md](https://github.com/Swetrix/selfhosting/tree/HEAD/clickhouse)
- Plausible issue #67 (opened 2021-03-30): a contributor reported (2021-03-31) "an instance running since October with 1vCPU and 1GB RAM and it's chugging along just fine", warned that ClickHouse parts growing past 1 GB could need more memory; in Feb 2022 the same person said "4GB sounds right", and the docs note added in May 2022 cited 4 GB. Dated 2021–2022, pre-ClickHouse 24.x. [ISSUE] — [plausible/docs#67](https://github.com/plausible/docs/issues/67)
- Plausible CE README today: "At least 2 GB of RAM is recommended … without fear of OOMs". [CODE] — [community-edition README](https://github.com/plausible/community-edition/blob/HEAD/README.md)
- A Plausible discussion titled "Very high memory usage #2799" exists (not read). [SNIPPET] — [plausible/analytics#2799](https://github.com/plausible/analytics/discussions/2799)
- Railway's Plausible template advises scaling the ClickHouse service "to at least 1–2 GB RAM to avoid OOM restarts". [SNIPPET, 3RD] — [Railway Plausible](https://railway.com/deploy/plausible.md)
- Umami issue #4498 (opened 2026-08-30, still open): "Out of 15 containers, Umami is using the most RAM. 268MB" (v3, PostgreSQL); a 2026-11-02 comment: "the latest v3 versions use considerably more memory than older v2 versions did … averaging 300-360mb of the Umami container alone, on top of the Postgres instance." [ISSUE] — [umami#4498](https://github.com/umami-software/umami/issues/4498)
- Umami issue #3823 (2025-12-03, "Memory Leak Issue in Umami v3"): memory "keeps growing until the process is killed"; closed as stale without a fix (2026-02-09). Issue #3988 (2026-01-28) reports an OOM kill in a `client_scanner` process inside the container (closed). [ISSUE] — [umami#3823](https://github.com/umami-software/umami/issues/3823), [umami#3988](https://github.com/umami-software/umami/issues/3988)
- Third-party Umami figures vary: ~500 MB on a small Hetzner VPS (vs ~1 GB for Plausible) per one blogger; ~150 MB idle per a hosting provider; Cloudzy calls 1 GB the minimum. [SNIPPET, 3RD] — [DeepakNess](https://deepakness.com/blog/self-hosting-umami-analytics/), [MassiveGrid](https://massivegrid.com/blog/self-host-umami-analytics-ubuntu-vps), [Cloudzy](https://cloudzy.com/blog/best-self-hosted-analytics/)
- Rybbit: official "at least 2GB of RAM"; a hosting template uses an 8 GB / 2 vCPU plan (marketing, not a requirement). [DOCS] — [rybbit.com/docs/self-hosting](https://rybbit.com/docs/self-hosting); [3RD] — [Hostinger](https://www.hostinger.com/ng/vps/docker/rybbit)
- Matomo: "2 CPUs, 2 GB RAM" minimum recommended even for ≤100k page views/month. [DOCS] — [Matomo requirements](https://matomo.org/faq/on-premise/matomo-requirements/)
- Medama: "capable of running on VMs with 256MB memory for most small websites" (project claim). [CODE] — [README](https://github.com/medama-io/medama/blob/HEAD/README.md)
- Counter.dev: the hosted service at "millions of unique visits per month is roughly at 25% on a small VPS that costs 5$ per month" (author's claim, for the SaaS). [CODE] — [README](https://github.com/ihucos/counter.dev/blob/HEAD/README.md)
- Munin: "~22 MB image, ~50 MB RSS regardless of traffic" (README claim, 0 stars). [SNIPPET] — [Tdude/munin](https://github.com/Tdude/munin)

### Inferences
- With ~490 MB free, any ClickHouse stack would at best leave nothing for the existing app. Even Swetrix's tuned ClickHouse (250–500 MB) alone could take all the headroom. Plausible CE, Rybbit, Swetrix, OpenPanel and PostHog are not realistic on this VPS without a RAM upgrade (to 2–4 GB) or a second box.
- Umami at 270–360 MB plus a few MB of extra Postgres load fits on paper, but it would eat 55–75 % of the free memory, with a reported (unfixed, stale-closed) leak pattern. A Docker `mem_limit` and swap would be advisable. This is "possible but tight".
- A Go/Rust single binary (GoatCounter, Liwan, Medama, HitKeep, Kaunta) or a log analyser (GoAccess) leaves real margin. Their DB is a file on the 8.7 GB free disk, which is plenty for this traffic.

### Gaps
- No measured RSS figures from primary sources for GoatCounter, Liwan, HitKeep, Tianji or GoAccess at this traffic level. A quick `docker stats` test on the VPS would settle it.
- No 2025–2026 first-hand report of Plausible CE v3 or Rybbit running on a 1 GB box was found; the only 1 GB Plausible report dates from 2021.

## Q5. Paywalled or cloud-only features in the "open core" tools

### Takeaway
Plausible CE is the most restricted: no funnels, journeys, ecommerce revenue, SSO or sites API; basic bot filtering only; releases twice a year. Rybbit keeps Web Vitals for paid tiers. PostHog self-host gets no paid features and no support. Umami, GoatCounter, Liwan, Matomo core (incl. BotTracking/AIAgents) and Swetrix CE (now with session replay) have no feature paywall in the code read, though Matomo sells many premium plugins (not checked).

### Cited Findings
- Plausible CE: "Marketing funnels, user journeys, ecommerce revenue goals, SSO and sites API are not available"; "The Data Studio Connector is not available"; CE bot filtering is "basic" vs cloud "advanced" (40,800 data-centre IP ranges); CE released twice a year. [DOCS] — [plausible.io/docs/self-hosting](https://plausible.io/docs/self-hosting)
- Rybbit README comparison: "Web Vitals ✅**" with "** Only available on paid tiers", and a "Web Vitals (Cloud only)" screenshot heading; the same table claims "Plausible's Community Edition has very limited features compared to their cloud version" (competitor framing). [CODE] — [README](https://github.com/rybbit-io/rybbit/blob/HEAD/README.md)
- PostHog: "All paid-plan features are Cloud-only"; self-host "officially unsupported". [DOCS] — [posthog.com/docs/self-host](https://posthog.com/docs/self-host)
- Swetrix CE: "Community Edition supports session recording, playback, and MP4 exports with your own private S3-compatible bucket". [CODE] — [Swetrix/selfhosting README](https://github.com/Swetrix/selfhosting/blob/HEAD/README.md)
- GoatCounter: "The source code is completely Open Source/Free Software, and it can be self-hosted without restrictions." [CODE] — [README](https://github.com/arp242/goatcounter/blob/HEAD/README.md)
- Matomo's `BotTracking` and `AIAgents` plugins are in the core GPL repository's `plugins/` folder, so the AI-assistant reports ship free with on-premise Matomo. [CODE] — [matomo/plugins](https://github.com/matomo-org/matomo/tree/HEAD/plugins)
- OpenPanel self-hosting lists no unavailable features; email features need Resend/SMTP, AI features need an OpenAI/Anthropic key. [DOCS] — [openpanel.dev self-hosting](https://openpanel.dev/docs/self-hosting/self-hosting)
- Fathom Lite is the old, frozen open version of the paid Fathom ("Older Lite UI", no live visitors/filters). [CODE] — [README](https://github.com/usefathom/fathom/blob/HEAD/README.md)

### Inferences
- None of the features Dian Dian needs (UTM, referrer, device, country, events, multi-site) is paywalled in Plausible CE or Rybbit. The CE limits (funnels, journeys, revenue) only matter for later e-commerce-style analysis, and Rybbit's limit (Web Vitals) does not matter here.
- Since Umami's Cloud export is documented but self-hosted export is not, the self-hosted owner relies on direct SQL against Postgres. On this VPS that is the existing, backed-up (pgBackRest→R2) database, which is an advantage.

### Gaps
- Umami self-hosted vs Cloud feature differences in v3 (e.g. whether "Boards" or AI insights are Cloud-only) were not checked.
- Matomo premium (paid) plugins relevant here (e.g. funnels, heatmaps) were not inventoried.
- Rybbit: whether the Bots dashboard is fully available self-hosted. The detection code is in the AGPL repo, but no explicit "self-hosted: yes" statement was read.

## Q6. Which tools are realistic on this server (1 vCPU, ~490 MB free, existing Postgres 16 + Caddy)?

### Takeaway
Realistic now: GoatCounter (Postgres or SQLite, server-side API, Caddy log import, campaigns), Liwan (Rust/DuckDB, UTM, server-side events, but bots dropped), Medama or HitKeep (single binaries, young), GoAccess as a zero-code bot/crawler view over Caddy logs, and Umami if one accepts ~300 MB RSS on the shared Postgres (tight). Not realistic without more RAM: Plausible CE, Rybbit, Swetrix, OpenPanel, PostHog (ClickHouse) and Matomo (MySQL + PHP, 2 GB minimum). Rybbit is the best functional match for "named AI bots", but it is the heaviest of the realistic-feature set.

### Cited Findings
- Requirements that exceed the ~490 MB free: Plausible CE "at least 2 GB" ([README](https://github.com/plausible/community-edition/blob/HEAD/README.md)); Rybbit "at least 2GB" ([docs](https://rybbit.com/docs/self-hosting)); OpenPanel "at least 4GB" ([docs](https://openpanel.dev/docs/self-hosting/self-hosting)); PostHog "4 vCPU, 16GB RAM" ([docs](https://posthog.com/docs/self-host)); Matomo "2 CPUs, 2 GB RAM" ([docs](https://matomo.org/faq/on-premise/matomo-requirements/)); ClickHouse "as low as 2 GB" with tuning ([docs](https://clickhouse.com/docs/operations/tips)). [DOCS/CODE]
- Umami: reuses an existing PostgreSQL ≥12.14 via `DATABASE_URL` ([README](https://github.com/umami-software/umami/blob/HEAD/README.md)); reported at 268–360 MB in v3 ([umami#4498](https://github.com/umami-software/umami/issues/4498)). [CODE] [ISSUE]
- GoatCounter: SQLite or PostgreSQL, backend API and Caddy log import ([README](https://github.com/arp242/goatcounter/blob/HEAD/README.md)). [CODE]
- Liwan: single binary, built-in DuckDB, no extra services ([README](https://github.com/explodingcamera/liwan/blob/HEAD/README.md)). Medama: 256 MB claim ([README](https://github.com/medama-io/medama/blob/HEAD/README.md)). HitKeep: one Go binary, no Postgres/Redis/ClickHouse ([docs](https://hitkeep.com/guides/installation/)). GoAccess: C, one dependency, reads Caddy JSON logs, AI crawlers categorised ([README](https://github.com/allinurl/goaccess/blob/HEAD/README.md)). [CODE] [DOCS]

Fit summary for the writer (synthesis of Q1–Q5):

| Tool | Fits ~490 MB? | Reuses PG16? | Server-side API | AI bots named | Maintenance in 2026 | Verdict |
|---|---|---|---|---|---|---|
| GoatCounter | Yes (Go binary) | Yes (or SQLite) | Yes + Caddy log import | No (flag only) | Slow (last release 2025-12) | Realistic |
| Liwan | Yes (Rust + DuckDB) | No (embedded) | Yes | No (dropped) | Active, small project | Realistic |
| Medama | Yes (256 MB claim) | No | OpenAPI server | ? | Last release 2026-01 | Realistic, check bots |
| HitKeep | Likely (Go + DuckDB) | No | Yes (REST) | Claims AI crawler channel | Very active, 1 year old, 107★ | Realistic, young |
| Umami v3 | Tight (~270–360 MB) | Yes | Yes, no auth | No (dropped by isbot) | Very active | Possible with mem limit |
| Tianji | Unknown (Node) | Yes | OpenAPI | ? | Active | Unverified |
| GoAccess (complement) | Yes (C) | n/a | n/a (logs) | Yes (AI crawlers category) | Active | Good bot/crawler add-on |
| Rybbit | No (CH + PG + Redis, 2 GB) | Partly (still needs CH) | Yes | Yes, by name/operator/purpose | Very active | Needs 2 GB+ VPS |
| Plausible CE | No (2 GB) | Partly | Yes | No | Active, CE twice a year | Needs 2 GB+ |
| Swetrix CE | No (CH + Redis) | No | ? | No (reasons only) | Active | Needs ~1.5–2 GB+ |
| Matomo 6 | No (2 GB, MySQL) | No | Yes | User-triggered AI assistants only | Very active | Needs 2 GB+ |
| OpenPanel / PostHog | No (4 GB / 16 GB) | — | Yes | ? | Active | Out |
| Shynet, Ackee, Counter.dev, Fathom Lite, Offen, Vince | — | — | — | — | Stale or low activity (Ackee needs MongoDB) | Not recommended |

### Inferences
- No single tool that fits this VPS covers "AI bots named" plus the rest. The realistic combinations are: (a) a light JS/server-side tool (GoatCounter or Umami, sharing the existing Postgres, or Liwan) for humans and campaigns, plus server-side bot logging (home-made table or GoAccess on Caddy logs) for crawlers; or (b) Rybbit on a separate or upgraded box (≥2 GB), which covers bots natively once Express or Caddy forwards crawler hits.
- For multi-site reuse later, all realistic options support several sites. GoatCounter and Umami are the most proven. Liwan, Medama and HitKeep carry more longevity risk.
- Running everything on the existing Postgres (Umami, GoatCounter-on-PG, or the home-made counter) has one more benefit: it is covered by the existing pgBackRest→R2 backups. DuckDB/SQLite-file tools would need their own backup of a Docker volume.

### Gaps
- No hands-on memory measurement on this exact VPS; recommendation rests on official figures and user reports.
- Whether Rybbit could run with a much smaller external ClickHouse (e.g. on another host) was not explored.
- Licence implications (AGPL for Plausible/Rybbit/Swetrix vs MIT/Apache/EUPL) were not analysed. They are not an issue for unmodified internal use, but they would be if the tool were modified and offered to others.
