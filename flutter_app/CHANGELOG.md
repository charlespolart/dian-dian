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

Requires backend ≥ 1.2.0.

### Added
- First-tracker flow for any account without a single cell (new or dormant): pick a ready-made template (Mood, Sleep, Exercise, Reading, Habits, or a custom title), see today's date and set today's dot right there; the tracker then opens with the dot already placed. On the second screen the title is renamed by tapping it (the gesture used in the tracker, taught once). "Later" is remembered per device and account; the flow never runs offline or against a backend older than 1.2.0.
- "Today" button in the tracker sidebar: opens the cell editor on today's date, switching to the current year first (and waiting for it to load) when another one is shown.
- Tracker titles are capped at 35 UTF-16 units in the create dialog and the first-tracker flow, the way the server counts (18 emoji no longer pass the field and fail server-side).
- First-tracker flow: buttons are announced as buttons to screen readers; a page the server committed but whose response was lost (or one made on another device with the same template) is adopted on Retry instead of duplicated; at the free limit a refused replace never creates a locked tracker; a 1.3.0 snapshot with cells lands without waiting for the network.
- `PagesProvider.createFirstTracker` (page + legends in one request, replacing an empty page when the server allows it), `SyncService.activated` / `snapshotActivated`, `LanguageProvider.longDate`.

- Settings → Contact opens an in-app form (idea, bug or question, reply email prefilled from the account and editable) sent through `POST /api/contact`; the account id, app version, platform and language are appended to the message.
- Phones are locked to portrait (shortest side under 600 dp); tablets keep every orientation.
- Swipe from the left edge to go back from the tracker and the settings (iOS-style, works on both platforms).
- A pencil next to the tracker title (top bar and cover) shows that tapping it renames the tracker.
- Each premium gate shown is reported to the server (`POST /api/events`, `paywall.<gate>`) so the pull of the free limit can be measured; nothing else is sent.

### Fixed
- Android: the system back button or gesture closed the app from the tracker and the settings (the app swaps screens without routes); it now goes back to the list, and from register / forgot-password to login.
- Dialogs: the action buttons (Back, Cancel, OK, Delete, Send) are pinned under the content and never scroll away or get cut, and so is the paywall's close cross; a dialog grows with its content up to the screen before its body scrolls (the cell editor's legend list was capped at 200 px).
- Legend editor: tapping a legend opens its own editor (label field + color picker) instead of editing the label inline; the drag handle and the delete cross have their own hit zones and never open the editor.

- RevenueCat `logOut` was called for an anonymous SDK user at every cold start and logged an error.

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
