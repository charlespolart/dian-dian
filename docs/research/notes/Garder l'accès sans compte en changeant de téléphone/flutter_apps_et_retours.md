# Keeping an anonymous device key across reinstalls and new phones: Flutter packages, comparable apps, RevenueCat and field reports (state at 2026-11-26)

Scope: the package layer and field experience for a 32-byte random "device key" that must survive a reinstall or a new phone without an account. Covered:
- what `flutter_secure_storage` 11.2.0 / `flutter_secure_storage_darwin` 0.4.3 do with `synchronizable`, read from source at the release tags;
- the issue trackers on both platforms;
- Flutter plugins for Block Store, Restore Credentials, iCloud key-value store, CloudKit and iCloud account status;
- how apps word the data status;
- what RevenueCat staff said;
- what developers reported going wrong.

Apple and Google platform docs are left to the other researchers. The earlier notes in `docs/research/notes/Utiliser l'app sans compte/` (RevenueCat §1, comparable apps §A/§B1) are not repeated. All pages read on 2026-11-26.

Code was read from a clone of `github.com/juliansteenbakker/flutter_secure_storage` (HEAD 1012697, 2026-11-01). The darwin package at HEAD equals tag `flutter_secure_storage_darwin-v0.4.3` (`git diff` empty), so the Swift line numbers are those of 0.4.3. Android and Dart line numbers are at tag `flutter_secure_storage-v11.2.0`.

Labels:
- [PRIMARY] the platform owner's own docs or staff answer (Apple, Google); also used, and flagged, for EU law and regulator text.
- [DOCS] package README, CHANGELOG, API docs or source ("source").
- [ISSUE] a bug report or developer account, quoted.
- [VENDOR] a company on its own product (RevenueCat, app help pages, store listings).
- [COMMENTARY] third-party articles.
- [SEARCH] a search snippet only; the page was not read.
- [INFERENCE] my reasoning, naming its sources.

Short links:
- `DARWIN` = https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage_darwin-v0.4.3/flutter_secure_storage_darwin/darwin/flutter_secure_storage_darwin/Sources/flutter_secure_storage_darwin/FlutterSecureStorage.swift
- `DPLUGIN` = the same folder's `FlutterSecureStorageDarwinPlugin.swift`
- `FSS` = https://github.com/juliansteenbakker/flutter_secure_storage
- `ISS#n` = `FSS`/issues/n

---

## Q6. flutter_secure_storage: the iOS `synchronizable` option, its known problems, and the Android side

### Takeaway
`synchronizable` arrived in 4.2.1 (2021-07-29). Its history since:
- **9.x**: it worked, but reads ignored it.
- **10.0.0–10.0.x** (darwin 0.1.0–0.2.0, Jan/Dec 2025 → May 2026): it was **silently dropped**, so items were written as non-synced.
- **darwin 0.3.0 onward** (2026-05-06): honoured again. The project's darwin 0.4.3 has the fix.

In 0.4.3, `read` and `readAll` match **only the exact flag value** passed. A default read cannot see a synced item. `containsKey`, `delete` and `deleteAll` act on **both** sync states. Two things follow:
- A write with the other flag value deletes the synced copy.
- The common "wipe the keychain on first launch after reinstall" workaround (`deleteAll`) deletes the synced key, and with it the key on every device of that Apple Account.

Two silent cases:
- The plugin does not reject `synchronizable: true` combined with a `…_this_device` accessibility.
- It silently drops `synchronizable` when `accessControlFlags` or `useSecureEnclave` is set.

The 0.3.x line made existing items unreadable and logged users out (#1158, #1164, #1229). A plugin upgrade alone can make a stored key "vanish".

On Android, the README says to turn Auto Backup off. The maintainer states that a restored file cannot be decrypted on another device (#1240). `resetOnError` has defaulted to true since 10.0.0, so after a restore the data is wiped and `read` returns `null`. Open #1298 describes total loss after a transient Keystore error.

### Cited Findings

**(a) Option surface and defaults**
- [DOCS] (source) `AppleOptions` defaults:
  - `accountName = 'flutter_secure_storage_service'`, `accessibility = KeychainAccessibility.unlocked`, `synchronizable = false`.
  - `toMap()` always sends `'synchronizable': '$synchronizable'`, so the native side gets an explicit true or false.
  - On `useSecureEnclave`: "iCloud Keychain sync (synchronizable) is ignored when using Enclave since keys are device-bound."
  - https://github.com/juliansteenbakker/flutter_secure_storage/blob/flutter_secure_storage-v11.2.0/flutter_secure_storage/lib/options/apple_options.dart L70–73, L89, L199, L211, read 2026-11-26
- [DOCS] (source) Native mapping: `accessGroup: options["groupId"]`, `service: options["accountName"]` (so `accountName` becomes **kSecAttrService**), and `isSynchronizable: (options["synchronizable"] as? String).flatMap { Bool($0) }`. — `DPLUGIN` L168–190, read 2026-11-26
- [DOCS] (source) Accessibility mapping:
  - `passcode` → `WhenPasscodeSetThisDeviceOnly`
  - `unlocked` → `WhenUnlocked`
  - `unlocked_this_device` → `WhenUnlockedThisDeviceOnly`
  - `first_unlock` → `AfterFirstUnlock`
  - `first_unlock_this_device` → `AfterFirstUnlockThisDeviceOnly`
  - anything else → `WhenUnlocked`
  - `DARWIN` L90–99, read 2026-11-26
- [DOCS] The README documents `accessibility` only. It says nothing about `synchronizable`, iCloud Keychain, or keychain items surviving uninstall. — `FSS` README at v11.2.0, L105–120, read 2026-11-26

**(b) Exact semantics in darwin 0.4.3**
- [DOCS] (source) **Query building.** `kSecAttrSynchronizable` is set only when no `SecAccessControl` is built ("Without flags, skip SecAccessControl so kSecAttrSynchronizable is not silently dropped by the Security framework"). With non-empty `accessControlFlags`, or with `useSecureEnclave` (which forces `userPresence`), the query carries `kSecAttrAccessControl` and **omits** the sync flag, with no error. The value is a plain Bool, never `kSecAttrSynchronizableAny`. `kSecAttrAccessGroup` is added only under `#if os(iOS)`. — `DARWIN` L134–147, L265–294, read 2026-11-26
- [DOCS] (source) **read** uses the caller's exact sync value. If nothing is found it falls back, in order:
  1. the pre-0.3.0 "legacy" envelope, whose query removes `kSecAttrSynchronizable`;
  2. every other accessibility level, with the same sync value.

  Not found returns `nil` with a success status. So a default read (sync=false) never returns a synced item, and a sync=true read never returns a non-synced one. — `DARWIN` L163–173, L192–204, L569–599, read 2026-11-26
- [DOCS] (source) **containsKey** "checks both synchronizable and non-synchronizable states": sync=true first, then false. — `DARWIN` L428–477, read 2026-11-26
- [DOCS] (source) **write** (non-Enclave): if `containsKey` is true, it tries `SecItemUpdate` with the caller's exact query; "else { _ = delete(params: params) }"; then `SecItemAdd` with the caller's flags. So update comes first, and delete-then-add is the fallback. — `DARWIN` L680–698, read 2026-11-26
- [DOCS] (source) **delete / deleteAll** go through `performDelete`, which deletes with sync=true and with sync=false after nulling `accessibilityLevel` and `accessControlFlags`. `deleteAll` also clears the key, so it removes every item under the service in **both** sync states. **readAll** returns only the caller's sync state (plus the legacy and cross-accessibility fallbacks). — `DARWIN` L480–566, L778–868, read 2026-11-26
- [DOCS] (source) The 0.4.3 cross-accessibility fallback exists because "kSecAttrAccessible is a strict filter, but keychain uniqueness on account+service+access group ignores it, so an item written under one level becomes unreadable and un-addable after the caller switches `IOSOptions(accessibility:)`". It is skipped for access-control and Enclave items. — `DARWIN` L175–204, read 2026-11-26
- [DOCS] (source) **No validation** rejects `synchronizable: true` with a ThisDeviceOnly level. `validateQueryParameters` only checks match-limit, invisible/negative and persistent-ref combinations. The OSStatus reaches Dart as `PlatformException("Unexpected security result code", "Code: <n>, Message: …")`. — `DARWIN` L411–426; `DPLUGIN` L206–222, read 2026-11-26
- [PRIMARY] (Apple DTS forum, Jul 2025) A developer combined a this-device-only access control with sync=true and got `errSecParam` (-50). Quinn replied: "What's the point of synchronising something if it's limited to this device only?" He also quoted `SecItem.h`: "Persistent references to synchronizable items should be avoided". — https://developer.apple.com/forums/thread/794851, read 2026-11-26

**(c) Version history (CHANGELOGs; publish dates from pub.dev)**
- [DOCS] **4.2.1** (2021-07-29): "Added kSecAttrSynchronizable support by setting IOSOptions.synchronizable [#51]". #51 (opened 2019-04-09) asked that keychain data "can be restored from iCloud after user reinstalling the app". — `FSS` CHANGELOG; `ISS#51`; https://pub.dev/api/packages/flutter_secure_storage, read 2026-11-26
- [DOCS] **10.0.0** (2025-12-10), darwin section:
  - "Remove keys regardless of synchronizable state or accessibility constraints"
  - "Fixed delete and deleteAll when synchronizable is set"
  - "Use accessibility option for all operations"

  Android section: "ResetOnError will now automatically be true, because most errors are unrecoverable due to key storage problems." `encryptedSharedPreferences` is deprecated, with automatic migration (`migrateOnAlgorithmChange: true`). — `FSS` CHANGELOG, read 2026-11-26
- [DOCS] (source and CHANGELOG) **The silent drop.**
  - darwin **0.3.0** and main **10.1.0** (both 2026-05-06): "Fixed `kSecAttrSynchronizable` being silently dropped when no access control flags are set." The fix is commit b3e0147 (2026-04-20).
  - Before it, `createAccessControl` returned a `SecAccessControl` whenever an accessibility level existed. The default `unlocked` always is one, so `kSecAttrSynchronizable` was never set.
  - Affected darwin versions: 0.1.0 (2025-01-10), 0.1.1 (2025-12-02), 0.2.0 (2025-12-10), i.e. 10.0.0-beta.4 to 10.0.x.
  - `git show b3e0147^:…/FlutterSecureStorage.swift` L134–145; https://pub.dev/api/packages/flutter_secure_storage_darwin, read 2026-11-26
- [DOCS] darwin **0.4.1** (2026-09-08): items written before 0.3.0 had become unreadable, "and subsequent writes failing with `errSecDuplicateItem`", because "The 0.3.0 fix for `kSecAttrSynchronizable` being dropped caused `read`, `readAll` and `containsKey` to stop querying the legacy `kSecAttrAccessControl` storage envelope". **0.4.2** (2026-09-11) skips sync queries when the macOS data-protection keychain is off. **0.4.3** (2026-09-16): "find keychain items across accessibility levels (#1269)". — `flutter_secure_storage_darwin/CHANGELOG.md` at v0.4.3, read 2026-11-26
- [DOCS] **11.0.0** (2026-08-06): "Any data saved using deprecated algorithms or features will be unusable after this upgrade. If you used a version prior to v10, upgrade to v10 first". It removes `encryptedSharedPreferences` and `sharedPreferencesName`, and sets minSdk 24. **11.1.0** (2026-09-10) adds `checkUpgradeStatus()` "to report data lost on a direct major upgrade". **11.2.0** (2026-09-16) adds "scope deleteAll to the key prefix instead of clearing the file (#1266)" and the darwin accessibility fix. — `FSS` CHANGELOG, read 2026-11-26

**(d) iOS issues: sync, duplicates, reinstall**
- [ISSUE] **#884** "Synchronizable working incorrectly", opened 2025-02-10, closed as stale 2025-12-03:
  - The reporter, on 9.2.4: "no matter what I set synchronizable to, I am getting the same identical value … Feels like synchronizable is always stuck in false."
  - PlaxXOnline (2025-03-03), with two devices on one Apple ID: "entries set with synchronizable: false are being synchronized across all devices with the same Apple ID". This claim is unverified.
  - vanyasem (2025-04-13): 9.2.4 "always looks up the value of a non-synchronizable value first, and returns the synchronizable value only if it happens to be null"; "I'd also consider this a breaking change".
  - `ISS#884`, read 2026-11-26
- [ISSUE] **#1158** "iOS loses access to stored values after update to … 10.1.0", opened 2026-06-02, closed 2026-07-22:
  - "returns nothing and all our iOS users are logged out."
  - mvollmer-gfos (2026-07-07): "we get a duplicate item error (and can't delete the existing keys since they are neither found in read nor delete). Even uninstalling and reinstalling the app doesn't work, because that does not remove all keychain entries."
  - The maintainer: "I am working on this in my free time".
  - `ISS#1158`, read 2026-11-26
- [ISSUE] **#1164**, opened 2026-06-15, closed 2026-09-14: "`kSecAttrAccessible` in a `SecItemCopyMatching` query acts as a strict filter."
  - gleb-r (2026-08-26) stored "a device-identity key" as `unlocked_this_device`, then switched to `first_unlock_this_device`: "`read` returns `null` for those legacy items".
  - mvollmer-gfos had moved off `WhenUnlocked` "because `WhenUnlocked` mostly threw an exception that the device wasn't unlocked/ready when starting the app".
  - `ISS#1164`, read 2026-11-26
- [ISSUE] **#1229** "Stored value disappears on some iOS devices", opened 2026-08-20, closed 2026-09-14. The reporter suspects "the delete-then-add fallback in `write`" and saw `-25299` `errSecDuplicateItem`; "the plugin's delete is silent". The maintainer: "flutter_secure_storage_darwin 0.4.1 is released, which should fix this issue." — `ISS#1229`, read 2026-11-26
- [ISSUE] **Keychain survives uninstall:**
  - #125 (2020-05-13), mogol: "it's expected behaviour of iOS Keychain".
  - #660 (2023-12-06), closed by the maintainer 2024-08-13: "Since this is still default behavior, i am closing this issue."
  - #897 (2025-03-03, closed 2026-04-06) shows the usual workaround: "a flag stored in shared preferences … to detect whether the app has been reinstalled". Its code calls `logoutUser()` when `hasRunBefore` is missing. A commenter (2025-03-28) calls the persistence "a security risk".
  - #591 (2023-08-01): "i set the kSecAttrSynchronizable to false but still there's data to be backed up and on app run the data is restored". Closed unanswered.
  - `ISS#125`, `ISS#660`, `ISS#897`, `ISS#591`, read 2026-11-26

**(e) Android: backup, restore, Keystore loss**
- [DOCS] README "Disabling Auto Backup": "By default Android backups data on Google Drive. It can cause exception `java.security.InvalidKeyException: Failed to unwrap key`." It advises "Disable autobackup" or "Exclude sharedprefs used by `FlutterSecureStorage`" and shows `android:allowBackup="false"`. It names neither the files nor `dataExtractionRules`. — `FSS` README at v11.2.0, L124–139, read 2026-11-26
- [DOCS] (source) Prefs files: `"FlutterSecureStorage"` (data) and `"FlutterSecureKeyStorage"` (wrapped key), with a `:namespace` suffix if `storageNamespace` is set. — `…/FlutterSecureStorageConfig.java` at v11.2.0, L16, L189–195, read 2026-11-26
- [DOCS] (source) With `resetOnError` defaulting to true (`android_options.dart` L51):
  - `handleStorageError` deletes the key or all data and retries, so `read` returns `null`.
  - `handleKeyMismatch` logs "resetOnError is enabled. Deleting all data and keys to recover."
  - The plugin's outer catch calls `deleteAll()` and answers `result.success("Data has been reset")`.
  - `…/FlutterSecureStorage.java` L1323–1358, L1016–1061; `…/FlutterSecureStoragePlugin.java` L271–283 (v11.2.0), read 2026-11-26
- [ISSUE] Maintainer, **#1240** (2026-09-14): values are "encrypted with an AndroidKeyStore key that's hardware-bound to that specific device, so even if the underlying SharedPreferences file gets included in a backup or device-to-device transfer, the ciphertext can't be decrypted on the new device … That's intentional." For Zero-Tap, "you'd need to integrate that directly in your app rather than relying on this plugin". — `ISS#1240`, read 2026-11-26
- [ISSUE] **#853** (10.0.0-beta2, 2025-01-08 → 2025-01-26): after a backup and restore, read "returns null" and the library "fails to write any other item without throwing any exceptions". The fix added a reset. — `ISS#853`, read 2026-11-26
- [ISSUE] **#887** "Data is lost after app reinstall on Android (even with allowBackup=true)" (2025-02-12, closed as stale); #876 and #817 report the same. **#941** (2025-06-02, closed as stale 2026-04-12): "`read()` sometimes returns "Data has been reset" String instead of returning `null` … happening to 150+ users on Android 13-15". That string path is still in 11.2.0. — `ISS#887`, `ISS#941`, read 2026-11-26
- [ISSUE] **#1298**, **open**, opened 2026-10-25: "transient Keystore error makes `createRSAKeysIfNeeded` replace the RSA pair — all data lost even with `resetOnError: false`". It applies to 11.0.0, 11.2.0 and develop: "every stored value is permanently lost … With `resetOnError: true` the plugin additionally wipes everything after a mere `getCertificate` glitch." — `ISS#1298`, read 2026-11-26
- [ISSUE] (titles only) Open: #1282 "resetOnError recurses until the process dies … (Samsung, after biometric enrollment)" and #1293 (migration skipped). Closed: #1225 "currently silently wipes stored data, no logcat" and #1237 "After upgrade from v9 to v11 data is lost". — `FSS` issues, read 2026-11-26

### Inferences
- [INFERENCE] (from `DARWIN` read / write / performDelete) **Toggling `synchronizable` partly orphans an item.** After a switch to `synchronizable: true`, `read` returns `null` while `containsKey` returns true. An app that treats `null` as "no key" mints a **new identity**. The safe migration is to read with the old options, then write with the new ones: the update misses, both copies are deleted, and a synced copy is added.
- [INFERENCE] **The reverse is destructive across devices.** Suppose any code path writes the same key with sync=false while a synced copy exists, for instance a default `const FlutterSecureStorage()` elsewhere in the app. That write deletes the synced item, and so does `deleteAll()`. Apple deletes a synced item on all devices; the other researchers should confirm this from Apple's docs. So:
  - all calls for the device key must share one options object;
  - the #897 wipe-on-reinstall pattern must exclude it.
- [INFERENCE] **Accessibility for a synced key:** `first_unlock`. `unlocked` fails before first unlock or in background launches (#1164 comment; #743, whose title shows -25308). A `_this_device` level contradicts sync, and the plugin will not catch the mistake. Apple's forum shows -50 for the access-control variant; the plain `kSecAttrAccessible` variant is untested here.
- [INFERENCE] **Pin and test plugin upgrades on iOS.** 10.0.x → 10.1.0 / darwin 0.3.x made keys unreadable (#1158, #1164, #1229). A vanished key looks exactly like a fresh install. The app should not silently mint a new identity when its local data says a key existed.
- [INFERENCE] **On Android this plugin cannot carry a key to a new phone** (#1240, by design). With this app's defaults (no `allowBackup` attribute, so backup is on), its prefs are restored, cannot be decrypted, and are wiped by `resetOnError`. The app then reads `null` and mints a silent new identity. Exclude `FlutterSecureStorage*.xml` from backup, and carry the key with Block Store instead (Q12).

---

## Q12 + Q5 (plugins). Block Store, Restore Credentials, iCloud key-value store, CloudKit, iCloud account status

### Takeaway
No first-party plugin (Google, Apple or flutter.dev) exists for any of these. Every candidate is a small, single-author package.
- **Block Store:** `play_services_block_store` 0.8.0 (Jun 2025) sets `shouldBackupToCloud` only when E2E is available. It does **not** expose `isEndToEndEncryptionAvailable` or that flag to Dart.
- **Restore Credentials:** two plugins from September 2026. Both need a WebAuthn relying party on the server.
- **iCloud key-value store:** `flutter_cloud_preferences` 0.3.0 (19 Nov 2026) targets "survive reinstall / new device" exactly. But it uses "what the app writes first wins" and stores values in plaintext, so it is unfit for a secret identity key as is.
- **CloudKit:** the plugins are stale or very new.
- **iCloud account status:** nothing exposes `ubiquityIdentityToken`; only `cloud_kit` wraps `CKContainer.accountStatus`.

Writing the native code ourselves is small: about 80–150 lines of Kotlin for Block Store, 60–130 lines of Swift for a keychain-sync or KVS helper, plus 30–60 lines of Dart. The estimate rests on the line counts of the plugins below.

### Cited Findings
Metadata from `https://pub.dev/api/packages/<name>` and `/score`, plus GitHub, read 2026-11-26. "Points" are granted/160. "dl30" is downloads over the last 30 days.

| Package | Latest (date) | Publisher | Likes / points / dl30 | Exposes, state |
|---|---|---|---|---|
| `play_services_block_store` | 0.8.0 (2025-06-16) | c-wolf.dev | 1 / 140 / 610 | save/retrieve/delete (String, bytes), deleteAll; 1★, 0 issues, last commit 2025-06-16 |
| `flutter_block_store` | 0.0.2 (2023-07-08) | saddamnur.xyz | 3 / 130 / 51 | abandoned |
| `android_restore_credentials` | 0.1.0 (2026-09-03) | wunderbytes.eu | 7 / 160 / 229 | `createRestoreKey/getRestoreKey/clearRestoreKey`, Android only |
| `zero_tap_easy` | 0.1.1 (2026-09-19) | — | 6 / 150 / 39 | Restore Credentials with `isCloudBackupEnabled` |
| `android_sign_in_kit` | 0.2.0 (2026-10-25) | — | 1 / 150 / 336 | Google Sign-In, passkeys, passwords, restore keys |
| `credential_manager` | 5.1.0 (2026-09-12) | smkwinner.live | 37 / 160 / 4490 | passwords, passkeys, Google ID; no restore-credential code in its repo |
| `flutter_cloud_preferences` | 0.3.0 (2026-11-19; first 2026-10-27) | — | 2 / 160 / 609 | iCloud KVS (iOS/macOS) + Auto Backup (Android) prefs; 0★, commit 2026-11-26 |
| `icloud_kv_storage_spm` | 0.1.1 (2026-07-29) | jha.sh | 0 / 160 / 203 | `writeString/getString/delete`, `setCloudKitUpdateHandler` |
| `icloud_kv_storage` | 0.0.1 (2023-06-07) | — | 5 / 150 / 98 | abandoned; 21★ |
| `cloud_kit` | 1.3.0 (2024-09-14) | manuelschuler.dev | 33 / 140 / 81 | private-DB key/value + `getAccountStatus()`; 18★, 10 open issues |
| `flutter_cloud_kit` | 0.0.3 (2023-09-13) | fuelet.app | 5 / 140 / 212 | stale |
| `icloud_kit_provider` | 1.5.0 (2026-03-19) | — | 1 / 140 / 39 | CloudKit DB |
| `crossvault` | 1.0.1 (2025-11-03) | — | 4 / 140 / 83 | keychain `synchronizable`; Android uses EncryptedSharedPreferences |

- [DOCS] (source) `play_services_block_store`:
  - It uses `com.google.android.gms:play-services-auth-blockstore:16.4.0`, the newest on Google Maven.
  - `saveData` calls `client.isEndToEndEncryptionAvailable()`, then `if (isE2E) { builder.setShouldBackupToCloud(true) }`, then `storeBytes`. Dart gets only `Future<bool>`.
  - The E2E check has no failure listener. If it fails, the Dart future would never complete; that is my reading of the code, not a reported bug.
  - Size: 209 lines of Kotlin, about 60 of them chunking.
  - https://github.com/chris-wolf/play_services_block_store/blob/main/android/src/main/kotlin/dev/cwolf/play_services_block_store/play_services_block_store/PlayServicesBlockStorePlugin.kt L74–122; https://dl.google.com/dl/android/maven2/com/google/android/gms/play-services-auth-blockstore/maven-metadata.xml, read 2026-11-26
- [DOCS] `android_restore_credentials` README and source:
  - "`requestJson` is WebAuthn `PublicKeyCredentialCreationOptionsJSON`".
  - The restore tier runs in `BackupAgent.onRestoreFinished` "**without a Flutter engine**, so the host must do the backend calls in Kotlin".
  - "Credential Manager will **not** delete restore keys on sign-out automatically".
  - It paraphrases Play: "Apps that integrated Block Store on or before **30 September 2026** to restore sign-in state are considered compliant"; "Games are currently out of scope".
  - `createWithE2eeRetry` tries cloud backup, then falls back. Size: 428 lines of Kotlin.
  - https://github.com/wunderbytes/android_restore_credentials (README L80–140; `RestoreCredentialsClient.kt` L44–168), read 2026-11-26
- [DOCS] `zero_tap_easy` README: "### You need a server … **Restore keys are WebAuthn credentials.**"; "**Firebase Auth alone is not enough.** Firebase has no WebAuthn relying party." — https://github.com/arjunpshaji/zero_tap_easy (README L49–58), read 2026-11-26
- [ISSUE] `ankitects/anki#5673` (2026-09-23, open): "Android's Restore Credentials flow requires server-side WebAuthn/passkey-style support". On 2026-11-06 the server team replied that it was "not clear to us what you guys need for us to do". — https://github.com/ankitects/anki/issues/5673, read 2026-11-26
- [DOCS] `flutter_cloud_preferences`:
  - "Key-value preferences that survive reinstalls and new devices". Restored "In the background on the first launch after an install" on iOS, "Before the app first starts after an install" on Android.
  - "**What the app writes first wins.** If the user changes a setting before the iCloud data arrives, the restore leaves that key alone".
  - "Do **not** store secrets (values are not encrypted on the device…)".
  - 0.2.0: "values written before iCloud's first download are written to iCloud again once it arrives, instead of being lost there". `localOnlyKeys` covers "auth tokens and device IDs … never restored".
  - It handles `InitialSyncChange`, `QuotaViolationChange` and `AccountChange`.
  - Size: `CloudStore.swift` 341 lines + plugin 93; Android 257 lines (excluding Pigeon-generated code).
  - https://github.com/nvanderwaal/flutter_cloud_preferences (README, CHANGELOG, `darwin/…/CloudStore.swift` L77, L244–246), read 2026-11-26
- [DOCS] `icloud_kv_storage_spm`: "The callback reports remote or initial-sync changes"; it is meant "for small preferences and app state". 128 Swift lines. — https://github.com/devaryakjha/icloud_kv_storage_spm, read 2026-11-26
- [DOCS] (source) `cloud_kit`:
  - `getAccountStatus()` wraps `CKContainer(identifier:).accountStatus`; data goes to `privateCloudDatabase`. 344 Swift lines.
  - Open issues: #5 "Duplicate records created" (2022-07-23: "calling "save" for multi times, lots of duplicated records were created"), #11 "User is not logged in with iCloud", #3 "Delete hangs".
  - https://github.com/Tutorialwork/cloud_kit (`lib/cloud_kit.dart` L111–119; `GetAccountStatusHandler.swift` L23–30), read 2026-11-26
- [DOCS] (source) `crossvault` advertises "Real-time iCloud Keychain synchronization" and "Automatic backup to Google Drive (Android)". Its Android code uses `EncryptedSharedPreferences` with a Keystore `MasterKey`. — https://github.com/alex-melnyk/crossvault (README L41–42; `crossvault_android` L94–116), read 2026-11-26
- [SEARCH] A pub.dev search for "ubiquityIdentityToken" and "icloud account status" returned no relevant package. — https://pub.dev/api/search?q=ubiquityIdentityToken, read 2026-11-26

### Inferences
- [INFERENCE] **Block Store.** The plugin works for a 32-byte key but hides what the settings screen needs: E2E cloud backup versus device transfer only. A fork or a roughly 100-line Kotlin channel would return `isEndToEndEncryptionAvailable()` and the flag actually used. Basis: its 209 lines minus chunking.
- [INFERENCE] **Restore Credentials** turns the server into a WebAuthn relying party and adds a Kotlin `BackupAgent`. That is much heavier than Block Store for an anonymous key. Whether "Block Store before 30 Sep 2026" counts for Zero-Tap in an app without sign-in is for the Android researcher. Basis: both READMEs and anki#5673.
- [INFERENCE] **iCloud KVS.** `flutter_cloud_preferences` gets initial-sync detection and account change right. For a device key, though, "first write wins" keeps a freshly minted key over the restored one, and its storage is plaintext. A roughly 120-line Swift helper fits better: call `synchronize()`, observe `didChangeExternallyNotification`, expose "initial sync arrived", and never overwrite an existing cloud value. Basis: `icloud_kv_storage_spm`'s 128 lines.
- [INFERENCE] **iCloud Keychain sync needs no new plugin.** flutter_secure_storage 0.4.3 already writes `kSecAttrSynchronizable` (Q6). A 60–100-line Swift helper is only worth it to read with `kSecAttrSynchronizableAny` or to avoid the plugin's cross-sync deletes.
- [INFERENCE] **Account status.** `cloud_kit`'s `getAccountStatus()` is the only packaged option, and the package is stale. A 20–30-line Swift channel can return `FileManager.default.ubiquityIdentityToken != nil` and `CKContainer.default().accountStatus`. I know of no public API for whether iCloud **Keychain** is on; the iOS researcher should confirm. So an honest status can say "signed in to iCloud", not "iCloud Keychain is on".
- [INFERENCE] **`crossvault`'s Android "Auto Backup"** hits the same wall the flutter_secure_storage maintainer describes in #1240: a device-bound Keystore key. Avoid it for this.

---

## Q13. Settings wording in no-account apps; apps and SDKs with an anonymous identity; RevenueCat

### Takeaway
Platform-cloud apps state a **destination plus a date**:
- Apple: "Back Up This [Device]", plus the date and time of the last backup.
- Google: "Backup by Google One", "Backup details".
- Daylio: "Automatic backup", a changing backup date, the toast "Backup created".
- Bear: last sync date and status icons.

Device-only apps state the loss case outright. Signal and WhatsApp spell out the condition for getting data back: same phone number and Apple ID, or the recovery key ("Losing it means losing access to your backup permanently").

I found no named app or Google case study keeping an *anonymous* identity in Block Store or a synced keychain. Visible cases are SDKs whose keychain login outlives uninstall by accident (Firebase Auth on iOS), plus 2026 design issues in small open-source apps.

RevenueCat's docs never mention the keychain or iCloud KVS. In 2022 staff called keychain storage possible "but … not without it's complications. We don't do this internally in the SDK". In June 2026 staff confirmed that a self-supplied ID "will survive reinstalls" but counts as an identified user, so a later log-in transfers instead of merging.

### Cited Findings
**Platform screens** (wording only)
- [PRIMARY] Apple (published 2026-09-24): Settings › your name › iCloud › "iCloud Backup" › "Back Up Now". "Under Back Up Now, you'll see the date and time of your last backup". The automatic setting is "Back Up This [Device]". The string "last successful backup" does not appear on the page. — https://support.apple.com/en-us/108366, read 2026-11-26
- [PRIMARY] Google, "Back up or restore data on your Android device":
  - Labels: "Backup by Google One", "Back up now", "Backup details", "Account storage".
  - "When your data is saved, "On" will be displayed below the data types you selected"; contents include "Apps and app data".
  - "Some data is further encrypted with your device's screen lock."
  - The page shows no "last backup" label.
  - https://support.google.com/android/answer/2819582?hl=en, read 2026-11-26

**Apps** (only what the earlier notes lack)
- [VENDOR] Daylio, "Are my data backed up?" (updated 2024-12-20):
  - "We use Google Drive to backup your data." / "Daylio uses iCloud for backup."
  - "When you turn on the backups, Daylio will automatically backup your data after each entry."
  - Labels: More › Backup and Restore; the toast "Yay! Backup created"; the section "Automatic backup"; the backup date changes.
  - On repeated failure: "we will let you know that error occurred and ask you to backup data manually".
  - https://daylio.net/faq/docs/daylio-faq/backup/are-my-data-backed-up/, read 2026-11-26
- [VENDOR] Bear: "`Bear Preferences` → `Sync`. There you can find the last sync date and the option to temporarily disable sync on that device." A struck-through cloud means "not connected to the internet, or that you have disabled sync"; a red dot means "sync is experiencing other problems"; no icon means "Bear has sync harmony". — https://bear.app/faq/sync-troubleshooting/, read 2026-11-26
- [VENDOR] Signal (2025-09-08): the recovery key "is never shared with Signal's servers"; "Losing it means losing access to your backup permanently, and Signal cannot help you recover it." — https://signal.org/blog/introducing-secure-backups/, read 2026-11-26. The support article returned 403. [SEARCH] "If you disable Secure Backups in your Signal settings, your secure backup archive will automatically be deleted." — https://support.signal.org/hc/en-us/articles/10075139325850-Troubleshooting-Signal-Secure-Backups
- [SEARCH] WhatsApp iOS, via guides; the WhatsApp FAQ was unreadable:
  - Settings › Chats › Chat Backup, with "Back Up Now" and "Auto Backup" (daily, weekly or monthly).
  - "Restore Chat History" needs the same phone number and Apple ID.
  - A 2026-11-18 report says a beta tests an alternative to iCloud.
  - https://www.idownloadblog.com/2022/11/09/how-to-back-up-and-restore-whatsapp-on-iphone/; https://iphoneincanada.ca/2026/11/18/whatsapp-is-testing-its-own-icloud-backup-alternative-on-iphone
- [SEARCH] Loss wording in small habit apps:
  - HabitKeep: "if your data isn't saved to the cloud, it will be lost — data is stored locally on your device" (https://www.habitskeep.com/faq)
  - HabitIt: "if you delete the App, locally stored data is removed" (https://habitit.app/privacy)
  - Habit Tracker: "automatically synced on all your devices connected to the same Apple ID via iCloud" (https://habittrack.app/)
  - Streaks: data "only on user devices and in iCloud" (https://streaksapp.com/privacy.html)
- Already in `apps_comparables_risques.md` §A, not repeated: Habitify guest, HabitKit, HabitNow, Loop, Streaks.

**Identity kept in the keychain or Block Store**
- [ISSUE] FlutterFire **#3660** (2020-09-25, closed): "i delete the app but once i reinstall the app again … it is logged in to the very same account". The maintainer: "seem to remember this being a ios keychain issue?" On 2020-11-23 a developer added that the data "got corrupted resulting in a crash on startup. Users try reinstalling the app but that does not work." — https://github.com/firebase/flutterfire/issues/3660, read 2026-11-26
- [SEARCH] A Firebase team member on Stack Overflow: "We use the keychain for storing credentials, so we're bound to the (undocumented) keychain behavior on this." — https://kiwix.lema.org/stackoverflow.com_en_all_2023-11/questions/43791524/firebase-authentication-persists-across-app-deletion (mirror; stackoverflow.com refused the fetch)
- [DOCS] expo-secure-store:
  - iOS data "**will persist across app uninstallations** if the app is reinstalled with the same bundle ID … this is not guaranteed and you should never rely on this".
  - On Android its prefs are auto-excluded from Auto Backup "as it's impossible to decrypt them after restoring the backup".
  - The page was updated after expo/expo#40662 (2025-10-27 → 2025-11-17).
  - https://github.com/expo/expo/blob/main/docs/pages/versions/unversioned/sdk/securestore.mdx L90–131, read 2026-11-26
- [ISSUE] Design plans, not field results:
  - `look-together#111` (2026-11-04, open): "The key travels in iCloud Keychain on iOS and Google Block Store on Android … A restore without its key shows Try again / Delete them, never failing silently". It uses `react-native-keychain` `cloudSync: true`, "accessible after first unlock only".
  - `bae-fm/bae#390` (2026-11-13, open): a real-device Block Store test meant to settle "whether a false write drops the app's whole cloud copy or one key".
  - `BabyTracker#23` (2026-10-27): "Android Block Store / Restore Credentials, iOS iCloud Keychain. Works within one platform only."
  - https://github.com/shrujancheruku/look-together/issues/111, https://github.com/bae-fm/bae/issues/390, https://github.com/benedictvantrigt/BabyTracker/issues/23, read 2026-11-26
- [SEARCH] No Google case study naming a Block Store app turned up; searches returned only the developer docs. — https://developer.android.com/identity/block-store

**RevenueCat**
- [VENDOR] Jacob Eiting (staff, 2022-08-02): "There isn't a way to persist the app user id between installs. We store it in the app container which gets deleted when you uninstall the app. There are some tricks you can do for storing it in the keychain, but … not without it's complications. We don't do this internally in the SDK." He recommends a restore, since "the receipt will contain the same purchases and we will associate the users with each other." — https://community.revenuecat.com/general-questions-7/can-the-anonymous-revenuecat-id-be-used-to-identify-users-across-multiple-app-versions-and-devices-1871, read 2026-11-26
- [VENDOR] "SUGGESTION: Allow custom ANONYMOUS AppUserIDs":
  - The developer (2026-05-31): "my app can provide a more persistent anonymous identifier than what $RCAnon accomplishes … we refrain from doing so because we get undesirable Transfer Purchases to New App User ID behavior".
  - Tarek (staff, 2026-06-02): "The alias-on-login path only kicks in when the _current_ App User ID is one of our anonymous IDs"; "Any ID you provide yourself is treated as an identified user"; "your persistent ID gets aliased in, and since it is your own value, it will survive reinstalls."; "keep the ID mapping on your side and reconcile on login."
  - https://community.revenuecat.com/sdks-51/suggestion-allow-custom-anonymous-appuserids-7699, read 2026-11-26
- [VENDOR] RevenueCat docs:
  - "using the same App User ID will ensure they still have access to subscriptions previously started without requiring a restore".
  - "**App User IDs should not be guessable** … A non-guessable pseudo-random ID, like a UUID (RFC 4122 version 4), is recommended"; e-mail IDs are not recommended for "guessability, and GDPR compliance".
  - A grep of *Identifying Customers*, *Restoring Purchases* and *Customers* found **no** mention of keychain, iCloud or a key-value store.
  - https://www.revenuecat.com/docs/customers/identifying-customers.md L21, L99, L402–412; https://www.revenuecat.com/docs/getting-started/restoring-purchases.md, read 2026-11-26

### Inferences
- [INFERENCE] A truthful status line has three parts:
  - **where**: "on this iPhone only", "in your iCloud Keychain" or "in your Google account";
  - **when**: a date, only if the app really observed it;
  - **the condition for coming back**: "a new iPhone signed in to the same Apple Account, with iCloud Keychain on".

  The app cannot observe the iCloud Keychain state (Q12), and the Block Store plugin hides the E2E flag. So it may assert only what it measured, e.g. "saved to iCloud Keychain" after a successful synced write. Signal's recovery-key sentence is the model for a manual fallback.
- [INFERENCE] **Do not use the device key as the RevenueCat App User ID.** RevenueCat advises showing the ID in settings and warns that IDs must not be guessable, so the secret would be exposed. A custom ID also turns log-in from alias into transfer. A separate non-secret ID, or Tarek's "mapping on your side", avoids both. Weigh this against the earlier notes §2–3.

---

## Q14. Problems developers reported with this approach

### Takeaway
The documented failures are mundane:
- **Silent disappearance** after a library upgrade or a Keystore glitch (flutter_secure_storage #1158, #1164, #1229 on iOS; #941, #1298 on Android).
- **Sync flags inverted or dropped**: react-native-keychain #800 (`cloudSync: false` synced to iCloud), and flutter_secure_storage 10.0.x dropping `synchronizable`.
- **Keychain logins outliving uninstall**, bringing back an old session or a corrupt state (FlutterFire #3660; flutter_secure_storage #660, #897).

The late-arrival race is real: an Apple engineer acknowledged a delay of about a minute for KVS right after iCloud sign-in. Apple staff say a sync "typically happens shortly after" launch, so minting a key on an empty read forks identities.

For shared Apple Accounts, sold phones, revived deleted accounts and concurrent writes, I found **no post-mortem** specific to anonymous identities. There are only general statements (one Apple ID means no separation) and Apple's sync mechanics.

GDPR names "an online identifier" as a way a person can be identified. The EDPB puts storing or reading the key on the device in ePrivacy Art. 5(3) scope whether or not it is personal data, but not "systematically" requiring consent.

### Cited Findings
**Late arrival or forked identities**
- [PRIMARY] (Apple forum 726593, March 2023)
  - The developer: "I moved to a new device and logged into iCloud settings and if I immediately open our app and query for a value it returns nil. After considerable delay say 1 minute … the proper stored value is returned. We called synchronize(), but it did not help."
  - An Apple Frameworks Engineer: "there might be a delay when trying to fetch data for NSUbiquitousKeyValueStore. That said, when you launch your app, NSUbiquitousKeyValueStore should automatically try to fetch at a higher priority".
  - https://developer.apple.com/forums/thread/726593, read 2026-11-26
- [PRIMARY] (Apple forum 796134, DTS, Aug 2025) "Typically, a synchronization activity happens shortly after a CloudKit app is launched. (`NSUbiquitousKeyValueStore` is based on CloudKit, btw.) If you observe didChangeExternallyNotification, you can expect to get a notification about the remote changes shortly after your app is launched." — https://developer.apple.com/forums/thread/796134, read 2026-11-26
- [DOCS] `flutter_cloud_preferences` (Oct–Nov 2026) shows both halves of the race. It keeps "first write wins", and it had to fix "values written before iCloud's first download … being lost" and restores "not arrived when the app is closed". — https://github.com/nvanderwaal/flutter_cloud_preferences (README, CHANGELOG 0.2.0), read 2026-11-26
- [SEARCH] Apple forum 40603: synced keychain items stopped syncing after a restart until iCloud Keychain was toggled, then appeared "after about a minute". One user's report. — https://developer.apple.com/forums/thread/40603
- [PRIMARY] (Apple DTS forum 788360, Jun 2025) An item without `kSecAttrSynchronizable` "won't be synched to other devices. However, it can still end up moving to a different device by: Encrypted backup and restore, Quick Start. If you don't want that, set `kSecAttrAccessible` to one of the `ThisDeviceOnly` values." — https://developer.apple.com/forums/thread/788360, read 2026-11-26

**Flags misbehaving; silent loss**
- [ISSUE] react-native-keychain **#800** (2026-08-13 → closed 2026-11-04): "`{ cloudSync: false }` produces `kSecAttrSynchronizable = true` … Any app that explicitly passes `cloudSync: false` to keep secrets device-local is instead syncing them to iCloud". It dates to v9.1.0. — https://github.com/oblador/react-native-keychain/issues/800, read 2026-11-26
- [ISSUE] react-native-keychain **#813** (2026-09-08, open): "set* intermittently rejects with errSecDuplicateItem because the SecItemDelete result is ignored … the following `SecItemAdd` sees an item with the same primary key (class, service/server, account, access group, synchronizable)". — https://github.com/oblador/react-native-keychain/issues/813, read 2026-11-26
- [ISSUE] react-native-keychain **#703** (2024-12-11, open): `cloudSync` combined with a biometric access control gives "One or more parameters passed to a function where not valid." — https://github.com/oblador/react-native-keychain/issues/703, read 2026-11-26
- [ISSUE] flutter_secure_storage #1158, #1164, #1229 (iOS) and #941, #1298 (Android), quoted in Q6.

**Identity outliving uninstall; device handed over; shared account**
- [ISSUE] FlutterFire #3660 and flutter_secure_storage #125, #660, #897 (Q6, Q13). The standard fix is a first-run flag that wipes the keychain; #897 calls the persistence "a security risk".
- [SEARCH] 2017 iOS 10.3 threads: keychain items said to be deleted with Development/AdHoc builds but kept with App Store builds. Unverified. — https://developer.apple.com/forums/thread/72271
- [SEARCH] Apple Community on families sharing one Apple ID: "no separation of data, or any private information when everyone uses the same AppleID"; "if you continue to use the same Apple ID all the data will be synchronized again". — https://discussions.apple.com/thread/253267173, https://discussions.apple.com/thread/254908089
- [SEARCH] A Medium post on keychain device IDs recommends the item "not be synchronized to iCloud by default so that two devices don't end up sharing one ID". — https://medium.com/@miguelcma/persistent-cross-install-device-identifier-on-ios-using-keychain-ac9e4f84870f
- [SEARCH] Apple Platform Security: when two devices update the same synced item, one version is chosen. — https://support.apple.com/guide/security/secure-keychain-syncing-sec0a319b35f/web (the platform researcher should quote it)

**Data protection**
- [PRIMARY] (EU law, not a platform owner)
  - GDPR Art. 4(1): a person can be identifiable "by reference to an identifier such as … an online identifier".
  - Recital 30: "Natural persons may be associated with online identifiers provided by their devices, applications, tools and protocols … when combined with unique identifiers and other information received by the servers, may be used to create profiles".
  - https://gdpr-info.eu/art-4-gdpr/, https://gdpr-info.eu/recitals/no-30/, read 2026-11-26
- [PRIMARY] (regulator, not a platform owner) EDPB Guidelines 2/2023 on Art. 5(3) ePrivacy, v2.0, 7 Oct 2024:
  - ¶10 (citing the CJEU): protection applies "to any information stored in such terminal equipment, regardless of whether or not it is personal data".
  - ¶12: information "includes both non-personal data and personal data, regardless of how this data was stored and by whom".
  - ¶56: applicability "does not systematically mean that consent needs to be collected … whether an exemption … could apply".
  - https://www.edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf, read 2026-11-26

### Inferences
- [INFERENCE] **The first-launch race needs an explicit rule.** On iOS, the app must not mint a key just because the keychain and KVS both read empty. The keychain gives no change notification, so the app must re-read. Two acceptable shapes:
  - start locally and attach to a server space later;
  - if a synced key arrives after a local one was minted, the app holds two spaces and must merge or ask, never overwrite silently.

  Basis: threads 726593 and 796134, and flutter_cloud_preferences.
- [INFERENCE] **What follows what.** A synced key follows the **Apple Account**. A non-synced key follows the **device backup or Quick Start** (DTS 788360) and survives uninstall. Consequences:
  - several people on one Apple Account share one space;
  - a phone handed over while signed in, or restored from an old backup, reopens it;
  - deleting only one side (the server space or the keychain item) leaves an orphan.

  "Delete my data" must delete both. Deleting a synced item also removes it from the user's other devices, which is the intended meaning.
- [INFERENCE] **Concurrent writes.** For a write-once key, the only collision is two devices minting before sync. iCloud Keychain keeps one version, and the losing device silently changes space. A server-side check is safer than trusting the keychain to resolve it.
- [INFERENCE] **GDPR.** The key opens a space of a person's daily entries, so it is at least a pseudonymous identifier on the server (Art. 4(1), Recital 30). Storing and reading it on the device falls under ePrivacy 5(3) whatever its nature (EDPB ¶10–12). The strictly-necessary exemption plausibly applies, but EDPB ¶56 says it must be assessed; this is for the register. The developer cannot delete a copy that sits in the user's own iCloud or Google account. Erasure is therefore: delete the server space, which makes the key worthless, and delete the keychain item when the app next runs.

---

## Gaps
- No device tests. The darwin 0.4.3 behaviours (a read missing the synced item, a sync=false write or `deleteAll` deleting the synced copy) are read from code, not run. The platform result of sync=true with a plain `kSecAttrAccessible…ThisDeviceOnly` (no access control) is unverified; the -50 report concerns the access-control variant.
- No field report or post-mortem was found on: family members colliding on one Apple Account; a handed-over phone reopening an anonymous space; a restored backup reviving a deleted account; two devices minting keys at once. These risks are inferred from mechanics.
- No named app or Google case study using Block Store or a synced keychain item for an anonymous identity was found. No game was found documenting keychain-based guest restore.
- No Flutter plugin exposes `ubiquityIdentityToken`, the iCloud Keychain on/off state, or Block Store's E2E flag. Whether iOS has any public API for the Keychain state is left to the iOS researcher.
- Unreadable sources: the WhatsApp FAQ, Signal's support article (403), Stack Overflow (fetch refused). In-app screenshots of Daylio, Streaks and HabitKit settings were not seen.
- RevenueCat: nothing found recommending or warning against iCloud KVS for an App User ID; the keychain statement is from 2022.
- `play_services_block_store`: the possibly unresolved future on an E2E-check failure is my code reading, not a reported bug. What a true→false `shouldBackupToCloud` flip does is open (`bae-fm/bae#390`).
- The ePrivacy strictly-necessary exemption was not analysed; EDPB 2/2023 leaves exemptions aside.
