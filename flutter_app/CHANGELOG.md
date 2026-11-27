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

### Added
- Offline (chantier 10, spec `docs/superpowers/specs/2026-11-26-offline-sync-design.md`; needs the backend of the same release). The phone keeps a full copy of the account, every year included, in a SQLite database per account (`lib/data/local_store.dart`, `sqflite`), and every change is written there first with its entry in a queue: colouring, erasing and commenting days, creating, renaming, reordering and deleting trackers, choosing the open trackers, everything about legends, the theme, the language and the cursor — online and offline alike, at once, never undone. Trackers and legends get their ids from the app (`uuid` v4). `SyncEngine` (`lib/data/sync_engine.dart`) sends the queue in order by batches of 100 (a batch stops before a change that depends on an earlier one in it — a second change of one element, a legend of a tracker created in it, a tracker deletion after changes inside that tracker — which leaves once the earlier answers have given it its number; a tracker deleted before its creation ever left is never sent; a day the phone never saw is sent with no number), then reads what changed since the last number it saw; when the network or the app comes back, on the server's `sync` message and after every gesture; retries 5 s then doubling up to 2 min; changes that waited leave after a read, so that a legend recoloured elsewhere recolours them. All-time stats, the first-tracker decision, premium and the settings come from the copy.
- A strip under the status bar while offline (« Hors ligne · tout est enregistré sur ce téléphone », or how many changes wait), the screens below it; back online, « Synchronisé · 31 modifications envoyées » for three seconds above the system bar and the ad banner (`lib/widgets/sync_banner.dart`).
- One message per sync for what the server did not keep — a day changed elsewhere (with the colour and comment not kept), a tracker deleted elsewhere with the days coloured in it, a deletion not applied, a name, a legend, an order or a setting changed elsewhere — and for what it refused, with the reason; shown when the sync ends, or at the next opening (`lib/widgets/sync_outcomes_dialog.dart`). A refusal brings the server's copy back; a refused tracker takes its queued changes with it. What was set aside is stored in the same step as it leaves the queue; whatever is still queued at launch counts as having waited.
- Gestures that need the server — buying or restoring Premium, managing the subscription, signing in or up, resetting a password, deleting the account, writing to support — do not start offline: « Il faut une connexion… Vos trackers restent utilisables. » (`lib/data/network_gate.dart`). The limit wall adds that buying will be possible once back online.
- Signing out sends the queue first; offline with changes waiting, the app asks before losing them. A deleted account (on another device) and a closed session are told with the changes they leave; the copy of a closed session stays hidden for its account, and signing in to another account first warns that those changes will be lost (`lib/widgets/session_dialogs.dart`).
- A tracker deletion still undoable is kept on the phone during its 8 seconds: an app killed meanwhile finds it done when reopened.
- Texts of all the above in French, English, simplified and traditional Chinese.
- Product events say where they come from: `EventsService` sends the platform (`ios`, `android`, `web`) and the installed version with each event, so the iOS and Android funnels can be compared. Needs the backend of the same release to be kept; an older backend ignores them.

- Entering without a wall (chantier 9, lot 1; spec `docs/superpowers/specs/2026-11-25-account-later-design.md`; needs the backend of the same release). The first screen without a session is a welcome screen (`lib/screens/welcome_screen.dart`): « Continuer avec Apple » (iPhone only), « Continuer avec Google », « Continuer avec un e-mail », « Continuer sans compte », four buttons of the same size and weight — one text size for the four, the largest at which the longest label shows whole — and the sentence below. Offline, the three ways into an account say a connection is needed and that one can start without an account; a closed Apple or Google window comes back without a message.
- « Continuer sans compte »: the phone chooses the account's id (UUID v4) and key (32 random bytes, in the secure storage, never synchronized, `lib/services/key_store.dart`), and the app is usable at once, network or not; the copy of a new account starts whole and empty. The account is born on the server at the first network (`/api/auth/invisible`), and its key reopens its session, unseen, after any refusal but a deletion (`/api/auth/key`); too many accounts from one network, or no network, only delay it.
- A session says why it ended, from any request or the live channel: deleted on another device, password changed, signed out from another device, or closed — always said, never a silent return to the first screen; the copy stays for the reconnection unless the account was deleted. A tracker deleted on another device while open says so.
- Settings in two forms, as the server says the account is (`lib/widgets/account_section.dart`): an attached account sees its address, « Se déconnecter », « Déconnecter mes autres appareils » (asked first) and « Supprimer mon compte et mes données »; an invisible one the sentence of case 10 and « Supprimer mes données », and no sign-out; both « Restaurer les achats ». The deletion's confirmation says what goes, with its numbers, that it goes everywhere, and where a subscription is cancelled; without an answer from the server nothing changes, and a retried deletion whose first answer was lost says the data was deleted.
- Texts of all the above in French, English, simplified and traditional Chinese.

### Changed
- The e-mail screen (sign-in, sign-up behind it) is reached from the welcome screen and goes back to it; Apple and Google are on the welcome screen only. Every session end clears the address kept on the phone; the address and the account's kind are taken exactly as the server sends them.
- The first launch after the update from 1.4.0 shows what 1.4.0 kept on disk (`snapshot_v1.json`, now only read) until the full copy arrives, then erases it; until then a change is refused with « Il faut une connexion pour finir la mise à jour de vos trackers ».
- The live messages of today are no longer listened to; only `sync` starts a sync. `SyncService` opens and binds the account's copy (`ChangeSink`); the providers no longer call the data routes and no longer revert on a network failure.
- A session lasts 548 days and survives a renewal whose answer was lost; a refusal says why, and only a sign-out or a deleted account erases the copy. A launch shows the app at once only on a session still held (account id and renewal token); an expired token that cannot be renewed for lack of network is no network (`ApiUnreachable`), not a refused session.
- `ConfirmDialog` stacks its two buttons when their labels do not fit side by side.
- Android build tooling follows Flutter 3.47.5's own app template: Android Gradle Plugin 9.1.1 (was 8.11.1), Gradle 9.3.1 (was 8.14), Kotlin Gradle Plugin 2.4.0 (was 2.2.20); the app module no longer applies `kotlin-android` (the Flutter Gradle Plugin does) and sets the JVM target through `kotlin.compilerOptions`. `compileSdk` is 37, set by hand until Flutter sets it (the reminders' notification plugin needs it); `targetSdk` stays Flutter's 36, `minSdk` 24. AGP 9's built-in Kotlin and new DSL stay off, as in Flutter's template (`purchases_ui_flutter` still applies the Kotlin plugin itself). R8 needed no change: Flutter has always minified, obfuscated and shrunk release builds, and the bundle carries its mapping for the Play Console; it now runs R8 9.1 (bundle 69.9 MB, was 70.4 MB).
- The ad banner sits above the system bar instead of under it: the screens draw edge to edge, and the banner was pinned to the very bottom, under Android's three-button navigation bar and, on iPhone, partly under the home indicator (`AdBannerFrame` in `lib/widgets/ad_banner.dart`, from `MediaQuery.viewPaddingOf`). Everything measured from the bottom follows: the list's + button, the list's last row of cards (and the card brought back into view when returning from a tracker), and the undo bar after a deletion, which now sits above the banner and ends left of the + button instead of covering the ad and its close button. On a tracker in portrait, a free account's grid ends above the banner (`AdBannerWidget.reservedHeight`, kept whether or not an ad loads): the banner no longer hides the 31st row, which it did on phones without a system bar. The tracker reads the system bar live (`viewPadding`) instead of a value captured once when it opened, which was short when it opened while a keyboard was still closing (creating a tracker); its banner no longer drops behind a keyboard opened for the title.
- A dot that carries a comment wears a small badge astride its top-right edge instead of the ring with a hole, which read as a button and, across a year, as a field of holes: the dot's own colour mixed 45 % into the screen's, ringed by the screen colour, so it stays quieter than the dot on light and dark themes alike; drawn the same on the grid (again over the today ring, which would cut it), under the pop and through the morph (`CommentBadge` in `lib/widgets/grid_geometry.dart`).

### Fixed
- Settings: deleting the account signs out only once the server confirms it; a deletion that failed (a server error) signed out as if the account were gone.
- Settings: after a theme change, the Sons and Vibrations tiles kept the old theme's colours until touched or reopened. The screen holds that section as a const, so its rebuild skipped it; the section now watches the theme itself.

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
