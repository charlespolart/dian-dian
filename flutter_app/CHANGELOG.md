# Changelog — app

Technical log of the mobile app, in English, newest first, in the
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format: what landed on
`master` goes under "Unreleased" as it lands, and `./release-app.sh` dates the
section when it cuts `app-vX.Y.Z`. The notes shown to users on the stores live
in `docs/changelogs/X.Y.Z.md` (four locales, see README "Changelogs"). The
backend is versioned separately (`backend/CHANGELOG.md`).

Each version states the backend it needs. The build number is the commit
count of the tagged commit (same on iOS and Android).

## [Unreleased]

## [1.4.0] - 2026-10-29

Requires backend ≥ 1.2.0.

### Added
- Motion, under one timing rule (`lib/theme/motion.dart`; everything instant when the system asks for reduced motion, iOS "Reduce Motion" included — Flutter reports it apart from `disableAnimations`): the tracker morphs out of its card and back into it as one shared element (frame, inner screen, every dot and the title, drawn at a geometry measured through registered anchors; in landscape the title lands on the panel's title at its fitted size, and a title the panel wraps dissolves into it), then reveals its labels, sidebar and bar in three staggered groups (the landscape panel by steps); the settings slide, other screens fade; every pop-up scales and fades from where it was tapped; the dot that just changed pops and an erase shrinks it; the grid and the year label slide in the swipe's direction; buttons shrink under the finger; the tracker list cascades in, a new card pops, a deleted one shrinks away; the what's-new bullets rise in one after another.
- Sounds: eighteen moments (a dot set or erased, a tracker opened, closed, created or deleted, a pop-up opened or closed, a legend added, an arrow step, a plain button, a choice, the side panel, a drag picked up, hovering a target, dropping), one bubble family synthesised in-house (`tools/sounds/bubble_palette.py`, built by `build.py`, no third-party licence); `AudioService` preloads one player per moment (iOS ambient session, so music keeps playing and the silence switch is honoured; Android sonification without audio focus); one sound per gesture: a button's tic and a pop-up's close yield to a stronger moment of the same gesture, a tracker opening right after its creation stays silent, a deletion sounds on the confirm tap. Settings → "Sons" switch (`sounds_enabled`).
- Vibrations: one per moment through `HapticFeedback` (medium for a dot and the side panel, heavy for a drag, a creation and a deletion, light for a choice and an arrow step, the selection click when hovering a drop target; none for plain buttons, pop-ups and the tracker opening), felt with the sound under the same gesture rules; Settings → "Vibrations" switch (`haptics_enabled`), independent of the sounds.
- Launch screen on both platforms (`tools/launch/render.py`): the loading screen's title block (点点 / Dian Dian) on the app's cream with its dotted background, so the app shows its name from the first frame instead of a blank screen; the dotted grid grows from a dot at the screen's centre so the native image and Flutter's coincide (Android 12+ shows the system splash on the same cream).
- A dot that carries a comment is a ring: a hole of the screen's colour at its centre, a third of the dot, with a 1 px accent line, drawn alike on the grid, under the pop and through the morph.
- Legend editor: each row carries a small pencil, the hint that tapping it opens the legend.
- First-tracker flow for any account without a single cell (new or dormant): pick a ready-made template (Mood, Sleep, Exercise, Reading, Habits, or a custom title), see today's date and set today's dot right there; the tracker then opens with the dot already placed. On the second screen the title is renamed by tapping it (the gesture used in the tracker, taught once). "Later" is remembered per device and account; the flow never runs offline or against a backend older than 1.2.0.
- "Today" button in the tracker sidebar: opens the cell editor on today's date, switching to the current year first (and waiting for it to load) when another one is shown.
- Tracker titles are capped at 35 UTF-16 units in the create dialog and the first-tracker flow, the way the server counts (18 emoji no longer pass the field and fail server-side).
- First-tracker flow: buttons are announced as buttons to screen readers; a page the server committed but whose response was lost (or one made on another device with the same template) is adopted on Retry instead of duplicated; at the free limit a refused replace never creates a locked tracker; a 1.3.0 snapshot with cells lands without waiting for the network; the creation carries an idempotency key, so a response lost after a server-side commit never produces a twin.
- `PagesProvider.createFirstTracker` (page + legends in one request, replacing an empty page when the server allows it), `SyncService.activated` / `snapshotActivated`, `LanguageProvider.longDate`.

- Settings → Contact opens an in-app form (idea, bug or question, reply email prefilled from the account and editable) sent through `POST /api/contact`; the account id, app version, platform and language are appended to the message.
- Phones are locked to portrait (shortest side under 600 dp); tablets keep every orientation.
- Swipe from the left edge to go back from the tracker and the settings (iOS-style, works on both platforms).
- A pencil next to the tracker title (top bar and cover) shows that tapping it renames the tracker.
- "What's new" box once after an update (bullets per version and language in `lib/data/whats_new.dart`; `release-app.sh` requires an entry). Fresh installs and landings on the first-tracker flow only record the version; an account that already has cells but no recorded version (updated from ≤ 1.3.0) sees it.
- Free tier over the limit (a lapsed subscription with more than 3 trackers): the trackers that stay open are the user's choice, asked once in the list with the 3 most active preselected (cells touched in the last 90 days, then last cell date), stored on the server (`PUT /api/pages/keep`) and shared by every device; the choice can be changed from a locked tracker's paywall. Before, the 3 oldest stayed open with no say. Nothing is ever deleted.
- Each premium gate shown is reported to the server (`POST /api/events`, `paywall.<gate>`) so the pull of the free limit can be measured; nothing else is sent.

### Changed
- Tracker sidebar: no dashed line under the Today block any more, which sits right under the legend tools with even room inside its frame; in landscape the title's pencil sits on the title's line and grows with it.
- The new-tracker dialog focuses its field once its entrance is over, not on its first frame (the session's first keyboard no longer froze it as it appeared).

### Fixed
- The undo bar after a deletion spoke English in every language; it uses the app's language.
- Android: the system back button or gesture closed the app from the tracker and the settings (the app swaps screens without routes); it now goes back to the list, and from register / forgot-password to login.
- Dialogs: the action buttons (Back, Cancel, OK, Delete, Send) are pinned under the content and never scroll away or get cut, and so is the paywall's close cross; a dialog grows with its content up to the screen before its body scrolls (the cell editor's legend list was capped at 200 px).
- Legend editor: tapping a legend opens its own editor (label field + color picker) instead of editing the label inline; the drag handle and the delete cross have their own hit zones and never open the editor.

- RevenueCat `logOut` was called for an anonymous SDK user at every cold start and logged an error.
- The server's premium status (fed by the RevenueCat webhook) was never read by the app; it is now reconciled at every session start and when the network comes back, both ways, so a lapsed subscription takes effect on the next launch.
- A tracker locked by the free tier could still be edited: when it was the last one open at launch (restored directly), or when the subscription lapsed while it was open. Both now go back to the list with the paywall. The server also refuses a 4th tracker for a free account.

### Removed
- The three explanatory onboarding cards and the `onboarding_done` device flag: the flow explains by doing.
- The Contact link no longer opens the web page (which only shows the address); the form replaces it.

## [1.3.0] - 2026-10-14

Requires backend ≥ 1.1.0.

### Changed
- Instant tracker list and tracker screens: one request loads everything for a year, opening a tracker or switching to a loaded year costs no request.
- Cold start paints from the last known state on disk, then refreshes silently; the app keeps working offline with cached data.
- Persistent HTTP connection and a single token refresh shared by concurrent requests (no more surprise logouts).
- Changes made on another device appear without reloading, including legend reorder and recolor.
- Global stats "this year" needs no request; "all time" needs one.

### Fixed
- December days could not be saved.
- Legend reorder and recolor did not sync across devices.
- Launching without network showed the login screen instead of the cached trackers.

### Internal
- Plugins upgraded (RevenueCat, Google Mobile Ads, Sign in with Apple, share, secure storage); iOS deployment target 15.

## [1.2.0] - 2026-08-11
- Android release on Google Play.
- RevenueCat purchases (monthly / yearly / lifetime, free trial), custom paywall, AdMob banner for free users.
- Multi-year trackers: one tracker carries from year to year.

## [1.1.0] - 2026-04-27
- Legal page layout fix.

## [1.0.0] - 2026-03-12
- First App Store release.
