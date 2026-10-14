# Changelog — app

Notable changes to the mobile app, newest first. Versions are cut by
`./release-app.sh` and tagged `app-vX.Y.Z`; the build number is the commit
count of the tagged commit (same on iOS and Android). The backend is
versioned separately (`backend/CHANGELOG.md`).

## [Unreleased]

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
