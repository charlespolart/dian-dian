# Changelog — backend

Notable changes to the API, newest first. Versions are cut by
`./release-backend.sh` and tagged `backend-vX.Y.Z`; the mobile app has its
own version in `flutter_app/pubspec.yaml` and is released separately.

Rules: a version never removes or renames what the previous one needs (the
database keeps the newer migrations after a rollback), and installed apps keep
working against the new backend.

## [Unreleased]

### Added
- The site counts its audience (`src/audience/`, migration 0018: `audience_counts`, `audience_totals`, `audience_months`): visits to the home page, visitors of the day, taps on each store button, the site visitors come from, device class, browser family, in-app browser (Pinterest, Instagram, Facebook, TikTok), page language, country, and the robots by family and name. No measurement cookie, no third-party script; no IP address, User-Agent, `utm_*` value or referring URL is written, in the database or in a log — only counts per day. Visitors of the day are fingerprints held in memory under a salt drawn at random each UTC day and never written. Counting happens after the response is sent, in memory, and is written every 5 seconds; nothing it does can fail a page. What a request can write is bounded per day (100 new sites of origin, 200 new robot names, 2 000 new rows; the sites the counter is for — Pinterest, ChatGPT, Google… — are outside those limits), a site that lives on several hosts is counted under one name (`www.pinterest.co.uk` and `fr.pinterest.com` are `pinterest.com`), and daily rows are kept 25 months at most, then rolled up into monthly totals.
- Robots are named from a table of some forty User-Agent tokens (assistants reading a page at a person's request, AI search, AI training, search engines, link previews) with `isbot` for the rest, and checked against the IP ranges fourteen operators publish (OpenAI, Anthropic, Perplexity, Mistral, DuckDuckGo, Google, Apple, Common Crawl): `verified`, `unverified`, or `unverifiable` when the operator publishes none. Countries come from DB-IP's IP-to-Country Lite (CC BY 4.0), held in memory. Both are downloaded a few seconds after start and refreshed daily, in production only (`AUDIENCE_DOWNLOADS=on|off` overrides); a download that fails is tried again every 15 minutes, and meanwhile the site answers as usual, with unknown countries and unverified robots. New dependencies: `isbot`, `maxmind`.
- `GET /go/apple` and `GET /go/play`: the store buttons of the site now point there, with the page's language and the campaign the visitor arrived with. Each counts the tap and redirects (302, `Cache-Control: no-store`) to the store. The buttons open in place (no new tab, which stayed behind empty and which in-app browsers handle badly).
- `GET` and `POST /privacy/audience`: the visitor sees whether they are counted and can stop or resume (cookie `dd_noaudience`, 13 months). Only the site's own form can make the choice: the request's `Sec-Fetch-Site` must be `same-origin`, or, for a browser that does not send it, its `Origin` must be the site's. Browsers sending Global Privacy Control or Do Not Track are never counted. The privacy policy explains the measurement in its four languages; the footer links to the opt-out page and credits DB-IP.
- `scripts/prod-landing.sql`: exact daily totals, then by month the origins (and whether they were read from the Referer or from the `utm_source` fallback), tagged links, in-app browsers, devices, countries, languages, taps by app and origin (cells under ten shown as `<10`), robots, pages read by an AI at a person's request (verified robots only), and the monthly totals of days older than 25 months.
- `public/robots.txt`, which keeps polite robots off `/go/`.
- `docs/REGISTRE.md`: the register of processing activities starts with the audience measurement entry.
- Table `subscription_events` (migration 0017): the RevenueCat webhook keeps every event as it arrives, next to `subscriptions` which stays the current state — type, environment (sandbox or production), store, product, period type (trial or not), price in USD and in the purchase currency, country, cancel and expiration reasons, trial conversion, dates, and the rest of the payload. No field that says who the event is about is kept in the payload (`app_user_id`, `original_app_user_id`, `aliases`, `transferred_from`, `transferred_to`, `subscriber_attributes`): the row's `user_id` does, and the rows of an account go with it when it is deleted. Events that arrive later for a deleted account (deleting an account does not cancel a store subscription) are kept without account and without identifier. One row per RevenueCat event id, so a retried delivery is not counted twice. Reading an event is pure, unit-tested code (`src/lib/rcEvent.ts`).
- `scripts/prod-purchases.sql`: trials started, converted, ended without paying, still running and cancelled (and on which day of the trial), with a conversion rate over the trials that are over; paid sales by product, store and currency; revenue per month — what customers paid, refunds, and RevenueCat's estimate of what is left after taxes and the stores' commission (`tax_percentage`, `commission_percentage`); why subscriptions end. Production events of real accounts only; a section says what was kept and what was left out (sandbox, test accounts, events with no account), with the amounts. Trials whose end date has passed with neither a payment nor an expiration are counted apart (`sans_nouvelles`), not as still running; the revenue columns add up to the net, and the estimate after taxes and commission is shown next to the amount it was computed on. A last section lists the subscriptions changed with no event kept: a row there is an event the webhook applied but could not keep. An empty result is no proof that none is missing — the complete trace is the log line `RC webhook: event not recorded`.
- `POST /api/events` accepts `platform` (`ios`, `android`, `web`) and `appVersion` (`X.Y.Z`), kept in `events.platform` and `events.app_version` (migration 0017). Both optional: apps ≤ 1.4.0 send the name alone, and a value the server does not know is dropped without refusing the event. `scripts/prod-events.sql` gains a section per platform and version.

- Product events are deleted after 13 months, and so are purchase events that name no account (`src/lib/retention.ts`): the current month and the 12 before it are kept (UTC), so a row lives between 12 and 13 months and is deleted within the hour of turning 13 months. Nothing deleted `events` before. The purge runs at boot and then hourly; a run that fails is logged (`Retention purge failed:`) and the next one tries again. A purchase event of an account is never purged: it goes with the account. `scripts/prod-events.sql` says its totals cover the months kept.
- `users.events_opt_out` (migration 0019, false by default): the account objected to product events. `POST /api/events` then writes nothing for it and still answers 204. So does an account deleted while its access token still runs (15 minutes), which got a 500 and a logged database error. Set by hand on a person's request (the two statements are in `docs/REGISTRE.md`, sheet 7); no route shows it or changes it.
- `docs/REGISTRE.md` covers the whole project: an overview, the processors and recipients, how a person's request is answered, eleven sheets (audience, accounts, tracker content, purchases, service emails, contact, product events, internal statistics, advertising, security and logs, backups), what was read on the production server on 2026-11-26, the known gaps with who settles each, and an empty register of data breaches. `src/lib/registre.test.ts` fails when a table is named in no sheet; it reads the tables from the newest migration snapshot, so it sees every schema file and every table a migration creates.
- `scripts/fetch-fonts.ts`: downloads the site's two fonts (DotGothic16, Silkscreen; SIL Open Font License) into `public/fonts/` with the stylesheet that names them. Run only to change a font; what it writes is committed.

### Fixed
- App Store campaign attribution: `ct` is the source alone (`pinterest`), no longer source and campaign (`pinterest-mood-en`). Apple only shows a campaign from 5 first downloads within 24 hours of the tap, and one name per pin kept every one of them under that; Google Play still receives source and campaign in its `referrer`.
- RevenueCat webhook: an event the server can read but has no account for is answered 200 instead of making RevenueCat retry it — a `TRANSFER`, which carries no `app_user_id` (was 400), and a purchase for an account that no longer exists (was 500 on the foreign key).
- RevenueCat webhook, a purchase restored on another account (`TRANSFER`): the subscriptions follow to the account the purchase reaches. Before, the server did nothing, so the new account stayed free on the server while the app showed it premium — its 4th tracker was refused (403). The account reached is the first of `transferred_to` that exists (the first listed may have been deleted since). When the transfer names its store, only the purchases of that store move: an account that also bought in the other store keeps what it bought there. A transfer with no account of ours at one end changes nothing.
- RevenueCat webhook: an event is applied once. RevenueCat delivers an event again, under the same id, when our answer did not reach it — up to 80 minutes later, when the purchase may have been restored back or the subscription may have expired; applying it again moved the purchase away once more, or reopened a subscription that had ended. The event's row and its effect on `subscriptions` are now one transaction: an id already kept changes nothing, and an effect that fails keeps no row, so the delivery RevenueCat retries after our 500 does both again. An event whose row the database refuses for what it holds (a character it cannot store) is still applied, and logged; a failure of the moment (a dropped connection) is answered 500 instead, so the retry keeps and applies it. A timestamp no date can hold is left empty in the kept row when it is only measurement, and refuses the event (500) when it is the end of the period: an unreadable end never becomes a lifetime. To replay an event by hand, delete its row (`rc_event_id`) first.
- RevenueCat webhook, a failed payment (`BILLING_ISSUE`): premium is no longer cut at once. With a grace period, the subscription stays open until the end of that period (`grace_period_expiration_at_ms`); without one, the period paid for runs to its end. The `EXPIRATION` that follows ends it.
- RevenueCat webhook, a paused subscription (`SUBSCRIPTION_PAUSED`, Google Play): premium is no longer cut when the pause is scheduled; it ends at the `EXPIRATION` that starts the pause.
- A subscription belongs to the account its latest purchase event names: a renewal that arrives for another account moves it there. A purchase restored on another account is thus caught up at its next renewal when the `TRANSFER` never reached this server (lost, sent before it handled them, or made through a device that was not logged in).
- Premium is read from a subscription that is open and not past its end, the one that lasts longest (`entitlingSubscription` in `src/lib/premium.ts`), by the session routes, the tracker limit and `GET /api/purchase/status` alike. Before, each took whichever open row came first and checked its date afterwards: a period that had run out could hide a valid purchase made since (a lifetime bought after a failed renewal), and the account was refused its 4th tracker.
- `GET /api/purchase/status` only reads. It used to close a subscription it saw expired, which could undo a renewal or a grace period arriving a moment later; RevenueCat's `EXPIRATION` closes it.

### Changed
- The site serves its own fonts (`/fonts/fonts.css`, 127 woff2 files cut by `unicode-range`, 761 KB) instead of loading them from Google Fonts, which gave Google the IP address of every visitor. Same files and same rules: the pages render as before. The content security policy allows no style, font or image host but the site (images: `'self'` and `data:`, no longer any `https:` address).
- Backups are kept 30 days instead of 7 (`ops/pgbackrest/pgbackrest.conf`, `repo1-retention-full=30`, decided by Charles on 2026-11-26): a problem noticed late can still be repaired, and a deleted row leaves the backups 30 days later, as the policy says. `deploy-prod.sh` already rebuilds the database container when this file changes.
- Logs are kept 6 months at most: the three production containers write to the host's journal (`logging: driver: journald` in `ops/docker-compose.prod.yml`) instead of a file of their own that Docker never rotated, and journald drops an entry 179 days after at the latest (`ops/journald/dian-dian.conf`, which `deploy-prod.sh` now syncs and installs as `/etc/systemd/journald.conf.d/dian-dian.conf`, restarting journald when it changed). The system journal itself had no maximum age. `src/lib/retentionConfig.test.ts` holds these settings to the durations the policy states.
- Privacy policy, in its four languages: thirteen sections that say what the register records — the data processed, why and on which legal basis, who it is entrusted to (Vultr, Cloudflare, Resend, RevenueCat, Microsoft for the contact mailbox; Apple and Google on their own account) and which transfers leave Europe, the copy of the displayed year kept on the phone, product events and usage statistics with the way to object, advertising, storage, how long each thing is kept, the rights and the CNIL. The sentence saying no personal data is shared with third parties is gone. Its date is one constant (`PRIVACY_UPDATED` in `routes/legal.ts`), written out in each language.
- The page `/delete-account` no longer says that no personal data is kept once an account is deleted: it says first that deleting an account does not cancel a store subscription, then names what stays and for how long — the backups (30 days), the server log (6 months at most), the purchase record held by Apple, Google and RevenueCat, the purchase events of a subscription still renewing (13 months, linked to no account), the emails held by Resend (30 days).
- The legal pages in Traditional Chinese have Traditional titles (`隱私權政策`, `刪除帳戶`, `法律聲明`…); they had the Simplified ones.
- An unknown path answers 404 — a page in the site's layout with a link home, JSON `{ "error": "Not found" }` under `/api` — instead of redirecting to the home page: scanners that followed the redirection would have been counted as visits. Apps only call existing `/api` routes and are unaffected.
- The stores see the site (its origin only) as where the visitor comes from: the store buttons carry `referrerpolicy="strict-origin-when-cross-origin"` and `/go/*` answers with that `Referrer-Policy`. The pages themselves keep `no-referrer`, so nothing else they load learns which site the visitor is on.
- A query parameter written with brackets (`?lang[toString]=x`) is ignored instead of answering 500, on the home page, the legal pages, `/go/*` and the 404 page.
- Unit tests run every `*.test.ts` under `src/` (`npx tsx --test "src/**/*.test.ts"`), in `make test` and in the release checks.
- Settings: `AUDIENCE_TAG_FALLBACK=off` turns off the reading of a known `utm_source` as the site of origin when there is no Referer; `AUDIENCE_DOWNLOADS` (see above). Both read `on` / `true` / `1` and `off` / `false` / `0`; any other value keeps the default.
- The requests the smoke suite sends to the site carry `DNT: 1` and are not counted, on production either; locally it also reads the rows the counter writes, exercises the roll-up of old days, and removes what it added. With `AUDIENCE_DOWNLOADS=on` for the server and the suite — as in the release checks — it also checks that a visit forwarded from a known address is counted in the right country, against DB-IP's real file.
- The smoke suite posts sandbox RevenueCat events to the server and reads and writes the database directly, only when both are on this machine: the address of the server under test and the one in `DATABASE_URL` must be `localhost` (`src/lib/loopback.ts`), whatever variables are set, and the suite first checks that this database is the server's. The database address is judged by the hosts its client will connect to (a URL listing several hosts is refused unless all are local). An SSH tunnel on `localhost` cannot be told from a local database: do not run the suite with one open to production. It needs `REVENUECAT_WEBHOOK_SECRET` in its environment as well as the server's (CI sets both), and skips these checks with a message otherwise.
- Every `scripts/prod-*.sql` makes its session read-only (`SET default_transaction_read_only = on`), so a statement that writes, added by mistake, is refused by the database; a unit test holds them to it, and to using no psql command that would leave the guarded session (`\c`, `\i`, `\!`) nor anything that turns the guard off. The guard comes first everywhere but in `prod-trackers.sql`, whose temporary table has to be made before it (a read-only session refuses it); that script no longer drops the table, which goes with the session, and stops at the first error.

## [1.2.1] - 2026-11-23

### Changed
- Landing: the store buttons follow the visitor's device — the App Store only on an iPhone (Safari, Chrome or an in-app browser such as Pinterest's), Google Play only on Android, both when the device can't be told (a computer, an iPad in desktop mode). Read from the `User-Agent` (`src/lib/storePlatform.ts`); the page is sent with `Vary: User-Agent`.

## [1.2.0] - 2026-10-29

### Added
- `POST /api/pages` accepts `legends: [{color, label}]` (≤ 12, created in the same transaction, positions in array order) and `replaces: <pageId>` (an empty page of the account — no legend, no cell — deleted in that transaction, the new page taking its position; 404 if it is not the caller's, 409 if it is not empty, nothing written in both cases). The response and the `page:created` WebSocket event carry `legends` and `replaced`; `page:deleted` is sent for the replaced page, then one `legend:created` per legend so apps ≤ 1.3.0 see them too. The page being replaced is row-locked (`FOR UPDATE`) so the emptiness check and the delete are atomic.
- `GET /api/bootstrap` returns `activated`: the account has at least one cell, on any page, any year.
- `cells.created_at` (migration 0013, backfilled from `updated_at`), returned as `createdAt` by the cell routes.
- `scripts/prod-activation.sql`: activation by weekly signup cohort (first cell within 24 h / 7 days, never).
- `POST /api/events` `{ name }` (auth, 120 / 15 min per IP) and table `events` (migration 0014): the app reports each paywall gate it shows (`paywall.tracker_limit`, …) so the free limit's real pull can be read with `scripts/prod-events.sql`.

- `POST /api/pages` accepts `clientId` (uuid, `pages.client_id`, migration 0016): the same key sent again returns the page already created (200) instead of a twin — the app's first-tracker flow retries with it after a lost response.
- The website's contact page (`/contact`) is a form posting to `POST /api/contact`, with the address kept as a fallback.
- `PUT /api/pages/keep` `{ ids }` (≤ 3) and `pages.keep_free` (migration 0015): which trackers a free account keeps open once it is over the limit, chosen by the user and shared by every device; WebSocket `pages:kept`. The bootstrap also gives each page `recentCells` (cells touched in the last 90 days) and `lastCellAt`, so the app can default to the most active trackers.

### Changed
- `POST /api/pages` refuses a 4th tracker for a free account (403), VIP and active subscriptions excepted; replacing an empty page still works at the limit. Apps ≤ 1.3.0 never send that request (they gate the + button).
- Cell writes (`PUT` / `DELETE /api/cells/:pageId`, recolor, reset) are refused (403) on a tracker the free tier locks — the same set the app shows closed (`src/lib/trackerLock.ts`, unit-tested). Reads stay open. An app ≤ 1.3.0 that still opens such a tracker sees its taps reverted.
- No "My Tracker" page is created at signup (email or OAuth) any more: the app's first-tracker flow (1.4.0) creates the first page with its legends.

### Compatibility
- Apps ≤ 1.3.0 keep working (a new account shows an empty list with the + button). App 1.4.0 requires this version.

## [1.1.1] - 2026-10-15

### Added
- Landing: visitors arriving with `utm_source` / `utm_campaign` get store buttons carrying the campaign (Play `referrer`, App Store `pt`/`ct` when `APPLE_CAMPAIGN_PT` is set) — attribution for Pinterest and other channels.

### Changed
- Contact address is now `contact@diandian.overridedev.com` everywhere: legal pages (privacy, terms, contact, delete-account, all locales), contact form recipient, and the sender of transactional mail (Resend domain `diandian.overridedev.com`). The old `diandian@overridedev.com` keeps being routed for a while.

## [1.1.0] - 2026-10-14

### Added
- `GET /api/bootstrap?year=` — pages + legends + compact cells of one year in a single round-trip.
- `GET /api/stats/days` — every filled date per page, for all-time stats.
- `PUT /api/pages/reorder` (one transaction) + WebSocket event `pages:reordered`.
- `POST /api/auth/refresh` also returns the user profile (no `/me` round-trip on cold start).
- `/api/health` reports the running version.
- Lookup indexes (migration 0012), hourly purge of expired refresh / reset tokens, WebSocket heartbeat.
- `scripts/smoke.ts` end-to-end suite, run by the Release workflow against a throwaway Postgres.

### Fixed
- Cells in December were rejected with 400 (month validated 0..11, the app sends 1..12).
- Day-in-month validation (30 February was accepted).
- Legend and cell recolor run in one transaction.

### Compatibility
- Apps ≤ 1.2.0 keep working unchanged. App 1.3.0 requires this version.

## [1.0.0] - 2026-03-26
- First production backend (deployed by commit SHA, before versioned releases).
