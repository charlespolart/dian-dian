# iOS: carrying a 32-byte "device key" across a user's Apple devices without an in-app account (iCloud Keychain, detectability, survival, alternatives, App Review) (state at 2026-11-26)

Context. A small iOS + Android Flutter app creates, on first launch, a long random secret (the "device key") that opens an identity-less space on its server, and keeps a full local copy of the data on the phone. Today the key sits in the iOS keychain with default options: no access group, no iCloud entitlement, deployment target iOS 15.0. The owner wants (a) to make the key a synchronizable iCloud Keychain item, so another device on the same Apple Account finds it, and (c) to show in settings a truthful status of where the data is and whether it will follow to a new phone. These notes cover the Apple platform side only. Android, the Flutter packages, comparable apps and RevenueCat are covered by other researchers. They build on `docs/research/notes/Utiliser l'app sans compte/apps_comparables_risques.md` (section B1). Current OS at the time of writing: iOS 27 (the iPhone User Guide offers "iOS 27 / iOS 26"). The Apple Platform Security guide read is the **August 2026** edition (PDF). Every source was read on 2026-11-26 unless marked [SEARCH].

Evidence labels:
- [PRIMARY]: Apple's own documentation (developer docs, Platform Security guide, Apple Support, App Review Guidelines, App privacy details). An Apple DTS engineer's forum answer is also [PRIMARY], marked "Apple DTS, Developer Forums, not documentation".
- [DOCS]: package documentation (not used here).
- [ISSUE]: a bug report or developer account, quoted.
- [VENDOR]: a company describing its own product.
- [COMMENTARY]: third-party blogs and articles.
- [SEARCH]: known only from a search snippet; the page was not read.
- [INFERENCE]: my own reasoning, naming the sources it rests on.

Source shorthand:
- PSG = Apple Platform Security guide, August 2026, https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf (the same text is on the web, e.g. "Secure keychain syncing" https://support.apple.com/guide/security/secure-keychain-syncing-sec0a319b35f/web).
- Apple developer pages were read through their JSON form (`developer.apple.com/tutorials/data/documentation/<path>.json`), which carries the page text verbatim. The URLs below are the human pages.

---

## Q1. Synchronizable keychain items written by a third-party app: conditions, propagation, conflicts, compatible classes, iPad/Mac, access groups, queries

### Takeaway
An item reaches the user's other devices only when all four of these hold:
- the app wrote it with `kSecAttrSynchronizable = true`;
- its accessibility class does not end in `ThisDeviceOnly`;
- each device is signed in to the same Apple Account, which has two-factor authentication;
- each device has the keychain sync switch on. Today that switch is Settings > [name] > iCloud > Passwords > "Sync this iPhone". In iOS 17 and earlier it was "Passwords and Keychain".

Updates and deletions propagate to all copies. If two devices change the same item, the system keeps one version: "one or the other is chosen, resulting in eventual consistency". There is no merge and no API to influence it.

Sync speed is entirely up to the system. DTS says "There are no API-level controls for this behaviour". A developer measured about 30 s from iOS to iOS on iOS 26, and about 30 min from iOS to macOS. A new device must first join the "syncing circle", by approval from another device or by escrow recovery with a passcode, so an item can be missing at the app's first launch.

The item reaches iPad, Mac (data protection keychain; it is the only keychain for iOS apps on Mac and for Catalyst) and visionOS. It does not reach tvOS. With no access group set, the item lands in the app's default group (Team ID + bundle ID), so only that app sees it. No keychain-sharing entitlement is needed for one app to sync its own items.

### Cited Findings
- [PRIMARY] `kSecAttrSynchronizable`. The value "indicates whether the item in question is synchronized to other devices through iCloud. To add a new synchronizable item, or to obtain synchronizable results from a query, supply this key with a value of kCFBooleanTrue. If the key is not supplied, or has a value of kCFBooleanFalse, then no synchronizable items are added or returned. Use kSecAttrSynchronizableAny to query for both synchronizable and non-synchronizable results." Available iOS 7.0+. — https://developer.apple.com/documentation/security/ksecattrsynchronizable, read 2026-11-26
- [PRIMARY] Same page, list of caveats (verbatim):
  - "You can set the kSecAttrSynchronizable key on tvOS, but tvOS doesn't synchronize your app's keychain items through iCloud."
  - "Updating or deleting items using the kSecAttrSynchronizable key affects all copies of the item, not just the one on your local device."
  - "Starting in iOS 14, macOS 11, and watchOS 7, the keychain synchronizes passwords, certificates, and cryptographic keys. Earlier OS versions synchronize only passwords."
  - "Items stored or obtained using the kSecAttrSynchronizable key may not also specify a kSecAttrAccessible value that is incompatible with syncing (namely, those whose names end with `ThisDeviceOnly`)."
  - "Do not use persistent references to synchronizable items. They cannot be moved between devices, and may not resolve if the item is modified on some other device."
  - "When specifying a query that uses the kSecAttrSynchronizable key, search keys are limited to the item's class and attributes. The only search constant that may be used is kSecMatchLimit".
  - "If a password is intended to be shared between multiple applications, the kSecAttrAccessGroup key must be specified, and each application using this password must have the keychain-access-groups enabled". This applies to sharing between apps only.

  — https://developer.apple.com/documentation/security/ksecattrsynchronizable, read 2026-11-26
- [PRIMARY] `kSecAttrSynchronizableAny` "Specifies that both synchronizable and non-synchronizable results should be returned from a query". It may be used in `SecItemCopyMatching`, `SecItemUpdate` and `SecItemDelete`. — https://developer.apple.com/documentation/security/ksecattrsynchronizableany, read 2026-11-26
- [PRIMARY] `kSecAttrAccessible`, Important box: "For any item marked as synchronizable, the value for the kSecAttrAccessible key may only be one whose name does not end with `ThisDeviceOnly`, as those cannot sync to another device." — https://developer.apple.com/documentation/security/ksecattraccessible, read 2026-11-26
- [PRIMARY] The default accessibility is When Unlocked: "This is the default accessibility when you don't otherwise specify a setting." — https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility, read 2026-11-26
- [PRIMARY] PSG (pp. 148–150):
  - Third-party apps opt in: "by default, keychain items added by third-party apps don't sync. Developers need to set the kSecAttrSynchronizable attribute when adding items to the keychain." Also: "every item that will sync needs to be explicitly marked with the kSecAttrSynchronizable attribute."
  - Two-factor: "When a user turns on iCloud Keychain for the first time on a two-factor authentication account, the device establishes and creates a syncing identity for itself."
  - Joining the circle: "New devices, as they sign into iCloud, join the iCloud Keychain syncing circle in one of two ways: either by pairing with and being sponsored by an existing iCloud Keychain device, or by using iCloud Keychain recovery."
  - **Conflicts**: "They now begin to exchange individual keychain items through CloudKit, or iCloud key-value storage, whichever is most appropriate for the situation. If both circle members have updates to the same item, one or the other is chosen, resulting in eventual consistency."
  - "As new peers are added, each peer syncs with the new one. This is designed to ensure that all members have the same keychain items."

  — https://help.apple.com/pdf/security/en_US/apple-platform-security-guide.pdf, read 2026-11-26
- [PRIMARY] PSG (p. 150): on a two-factor account, recovering an escrowed keychain uses the device passcode: "If two-factor authentication is turned on for the user's account, the device passcode is used to recover an escrowed keychain." — same URL, read 2026-11-26
- [PRIMARY] Apple Support "Set up iCloud Keychain" (Published Date: October 01, 2026):
  - Before you start: "make sure that two-factor authentication is enabled for your Apple Account."
  - Path: "Open the Settings app, tap your name, then tap iCloud. Under Saved to iCloud, tap Passwords. In iOS 17 or earlier, tap Passwords and Keychain. Tap Sync this [Device] to turn on iCloud Passwords & Keychain."
  - On Mac: "Click Passwords. In macOS Sonoma or earlier, click Passwords & Keychain."
  - Approve Later: "If you choose to 'Approve Later' when you sign in to your Apple Account, you need to approve with an old passcode or from another device when prompted."

  — https://support.apple.com/en-us/109016, read 2026-11-26
- [PRIMARY] iCloud User Guide:
  - "You need to set up two-factor authentication before you can turn on iCloud Keychain."
  - "Make sure you're signed in to the same Apple Account on each device. If you're not signed in to your Apple Account on a device, or the device has the iCloud Keychain or iCloud Passwords feature turned off, you won't be able to access your information on the device."

  — https://support.apple.com/guide/icloud/set-up-icloud-keychain-and-icloud-passwords-mmd17774d0a8/icloud, read 2026-11-26
- [PRIMARY] iPhone User Guide (iOS 18 version of the page):
  - "When you turn on iCloud Keychain on an additional device, your other devices using iCloud Keychain receive a notification requesting your approval of the additional device. On one of your other devices, approve the additional device. Your iCloud Keychain automatically begins updating on the additional device."
  - Its iOS 18 path ("See All … Passwords & Keychain") differs from the October 2026 Support article ("Passwords"); labels move between releases.

  — https://support.apple.com/guide/iphone/passwords-devices-iph82d6721b2/ios, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn "The Eskimo!", March 2021: use "kSecAttrSynchronizable if you want the item to synchronise via iCloud (if the user has enabled iCloud Keychain)". — https://developer.apple.com/forums/thread/676891, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, accepted answer, about November 2026 (the page shows "3w").
  - The developer's account [ISSUE]: "macOS → iOS: approximately 30 seconds. iOS → other iOS devices: approximately 30 seconds. iOS → macOS: approximately 30 minutes … Devices are on iOS 26 and macOS 26."
  - Quinn: "There are no API-level controls for this behaviour. You either opt in to synchronisation (`kSecAttrSynchronizable`) or you don't, and once you do the system is in charge of that process. I'm not aware of any specific reason why iOS-to-macOS synchronisation would be slow, but the synchronisation process is complex".

  — https://developer.apple.com/forums/thread/854637, read 2026-11-26
- [PRIMARY] Sharing and access groups: "Xcode automatically prefixes the bundle ID with your team ID … and stores the combined string as the app ID. The system recognizes this app ID as the name of your app's default keychain access group … Any keychain items stored with this access group are private to App One." "If you don't specify any access group when adding an item, keychain services applies your app's default access group". "If you don't specify an access group in the query, the search matches any of your app's groups." — https://developer.apple.com/documentation/security/sharing-access-to-keychain-items-among-a-collection-of-apps, read 2026-11-26
- [PRIMARY] `kSecAttrAccessGroup`: "If you don't explicitly set a group, keychain services defaults to the app's first access group, which is either the first keychain access group, or the app ID when the app has no keychain groups. In the latter case, the item is only accessible to the app creating the item". — https://developer.apple.com/documentation/security/ksecattraccessgroup, read 2026-11-26
- [PRIMARY] PSG (p. 101): "Keychain items can be shared only between apps from the same developer." — PSG PDF, read 2026-11-26
- [PRIMARY] Mac. `kSecUseDataProtectionKeychain`: "Items that you store or have stored in macOS with the kSecAttrSynchronizable attribute set to `true` also behave like iOS keychain items. However, a `true` value for that attribute additionally causes iCloud to synchronize the item across all the user's devices." — https://developer.apple.com/documentation/security/ksecusedataprotectionkeychain, read 2026-11-26
- [PRIMARY] TN3137:
  - It lists "Mac Catalyst apps" and "iOS Apps on Mac": "In these environments you don't need to supply the `kSecUseDataProtectionKeychain` attribute or the `kSecAttrSynchronizable` attribute to target the data protection keychain. It's the default and only option."
  - "macOS 11 and later synchronize all classes; earlier versions synchronize only the password classes."
  - Keychain Access shows the data protection keychain "as either iCloud Keychain or Local Items, depending on whether the user has enabled iCloud Keychain."

  — https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains, read 2026-11-26
- Conflict, resolved: Quinn's retired Dec 2021 post (https://developer.apple.com/forums/thread/696431) said "Only the password items are synchronised". TN3137, which supersedes it, and the `kSecAttrSynchronizable` page say keys and certificates sync too from iOS 14 / macOS 11. Irrelevant for a generic password.
- [ISSUE] The library's `cloudSync: false` flag was sent as `kSecAttrSynchronizable = true` next to biometric `kSecAttrAccessControl`. On the iOS 27.0 Simulator, securityd rejected the save with `error:[-50] "item with kSecAttrAccessControl is not synchronizable"` (Oct 2026, simulator only, "Not checked on a real iPhone yet"). — https://github.com/HyeokjaeChoi/vaultme/issues/243, read 2026-11-26
- [PRIMARY] Apple Support "If iCloud Keychain won't turn on or sync" (Published Date: September 15, 2026): "Did you turn off iCloud Keychain on all your devices? If so, your iCloud Keychain is removed from the cloud." — https://support.apple.com/en-us/102441, read 2026-11-26

### Inferences
- [INFERENCE] Writing while the switch is off, then turning it on later. Apple documents no behaviour for third-party items. Support says that when the switch is off, data "is stored locally on your device" (109016). The PSG says a joining peer syncs so that "all members have the same keychain items". So the item most likely keeps its synchronizable flag and is uploaded when the device (re)joins the circle. **This is unverified**: test it on devices.
- [INFERENCE] **Two first launches before syncing.** Say iPhone A and iPad B each create a different random device key under the same service/account before either has synced. PSG's "one or the other is chosen" means one device will later see its key silently replaced by the other's, pointing to a different server space. The app must handle "the key changed under me". For example, it can keep a non-synced local copy of the key it last used and compare the two on launch. Sources: PSG p. 149; `kSecAttrSynchronizable` ("Updating or deleting … affects all copies").
- [INFERENCE] Same problem in reverse. If the app deletes or rewrites the synchronizable key on one device, say on "reset" or "sign out", the change hits every device: "affects all copies" (`kSecAttrSynchronizable` doc).
- [INFERENCE] On a new device, the item is missing at first launch whenever:
  - the device has not yet been approved into the circle ("Approve Later", or approval pending);
  - Keychain sync has not finished (about 30 s to 30 min in the one 2026 report);
  - Keychain sync is off on that device.

  The app cannot tell these cases apart (see Q2). Sources: iPhone User Guide, Support 109016, forum 854637.
- [INFERENCE] Minimum change for the app: add `kSecAttrSynchronizable: true` to the add, update and query dictionaries, and keep a non-`ThisDeviceOnly` accessibility. `AfterFirstUnlock` is needed if a background task must read the key; otherwise the default `WhenUnlocked` is fine. No entitlement change is needed for single-app use, because the default access group is the app ID. Existing non-synchronizable items must be migrated, since a query with `true` does not see them and one without the attribute does not see the synced item. Use `kSecAttrSynchronizableAny` to find both.

---

## Q2. Detectability: can the app know that iCloud Keychain is on, that the user is signed in to iCloud, or that an item has synced or arrived from another device?

### Takeaway
I found **no supported API** that reports any of these:
- the state of the Keychain sync switch;
- whether an item has been uploaded to iCloud;
- whether an item arrived from another device.

DTS describes sync as something you opt into, after which "the system is in charge of that process". Quinn answered "No." when asked whether an app can check that the account has two-factor authentication. Apple's own Keychain Access app on the Mac shows "iCloud Keychain" or "Local Items", but nothing exposes that to apps.

What an app can learn needs iCloud entitlements, and it is about iCloud in general, not about the Keychain switch:
- `CKContainer.accountStatus()` and `CKAccountChanged` need the CloudKit entitlement and a container.
- `FileManager.ubiquityIdentityToken` is documented as the "iCloud Drive Documents identity". A Q&A says it is nil when iCloud Drive is off for the app or the iCloud capability is missing.
- `NSUbiquitousKeyValueStore` change notifications carry a reason (server change, initial sync, quota, account change). It has no "status" call, and its archived guide calls it "effectively always available".

The PSG says the keys behind end-to-end encrypted CloudKit sync "even if the user chooses not to use iCloud Keychain". So iCloud being "available" says nothing about the Passwords/Keychain switch. A truthful settings line can say "the key is saved for iCloud Keychain sync". It cannot say "your key is in iCloud" or "your new phone will find it".

### Cited Findings
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, Jan 2017, asked "Is there a way to check if a user's iCloud account has two-factor authentication enabled?": "No. IMO it's not your job to nag users about two-factor. … feel free to file an enhancement request". — https://developer.apple.com/forums/thread/70549, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, about Nov 2026: "There are no API-level controls for this behaviour. You either opt in to synchronisation (`kSecAttrSynchronizable`) or you don't, and once you do the system is in charge of that process." — https://developer.apple.com/forums/thread/854637, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, Mar 2021: "iCloud Keychain is a user-level term that refers to the iOS-style keychain when iCloud Keychain is enabled. If the user disables iCloud Keychain this stops being called iCloud Keychain and instead shows up in Keychain Access as Local Items." — https://developer.apple.com/forums/thread/676891, read 2026-11-26
- [PRIMARY] TN3137: Keychain Access displays the data protection keychain "as either iCloud Keychain or Local Items, depending on whether the user has enabled iCloud Keychain". This is an Apple app's UI; no API is named. — https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains, read 2026-11-26
- [PRIMARY] `ubiquityIdentityToken`:
  - "An opaque token that represents the current user's iCloud Drive Documents identity." "In iCloud Drive Documents, when iCloud is available, this property contains an opaque object representing the identity of the current user. If iCloud is unavailable or there is no logged-in user, the value of this property is `nil`."
  - It is usable with `NSUbiquityIdentityDidChange` "to detect when the user logs in or out of iCloud and to detect changes to the active iCloud account."
  - "CloudKit clients should not use this token as a way to identify whether the iCloud account is logged in. Instead, use accountStatus(completionHandler:) or fetchUserRecordID(completionHandler:)."

  — https://developer.apple.com/documentation/foundation/filemanager/ubiquityidentitytoken, read 2026-11-26
- [PRIMARY] Technical Q&A QA1935 (2017-04-11, archived) on why the token is nil: the device has no signed-in iCloud account, or "iCloud Drive is off for your app", or the iCloud capability has not been added in Xcode. — https://developer.apple.com/library/archive/qa/qa1935/_index.html, read 2026-11-26
- [PRIMARY] iCloud Design Guide (archived, updated 2015-12-17, **old**):
  - Key-value storage: "Key-value storage is effectively always available. If a device is not attached to an account, changes created on the device are pushed to iCloud as soon as the device is attached to the account."
  - "If a user signs out of iCloud, such as by turning off Documents & Data in Settings, the value of the `ubiquityIdentityToken` property changes to `nil`."

  — https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html, read 2026-11-26
- [PRIMARY] `accountStatus(completionHandler:)`: "Determines whether the system can access the user's iCloud account. … Call this method before accessing the private database to determine whether that database is available. While your app is running, use the CKAccountChanged notification to detect account changes". — https://developer.apple.com/documentation/cloudkit/ckcontainer/accountstatus(completionhandler:), read 2026-11-26
- [PRIMARY] `CKAccountStatus` values:
  - `.noAccount`: "The device doesn't have an iCloud account."
  - `.restricted`: "due to restrictions that Parental Controls or Mobile Device Management impose".
  - `.temporarilyUnavailable` (iOS 15+): "the user's iCloud account is available, but isn't ready to support CloudKit operations. Don't delete any cached data".
  - `CKAccountChanged`: "Create an instance of CKContainer to receive this notification."

  — https://developer.apple.com/documentation/cloudkit/ckaccountstatus (and the subpages for each case), read 2026-11-26
- [PRIMARY] The iCloud Services entitlement is added by enabling "the iCloud capability and the iCloud Documents or CloudKit service in Xcode". The KVS entitlement `com.apple.developer.ubiquity-kvstore-identifier` is added by enabling "the iCloud capability and 'Key-value storage' service". — https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.icloud-services and …/com.apple.developer.ubiquity-kvstore-identifier, read 2026-11-26
- [PRIMARY] `NSUbiquitousKeyValueStore.didChangeExternallyNotification` reasons: `NSUbiquitousKeyValueStoreServerChange`, `InitialSyncChange`, `QuotaViolationChange`, `AccountChange`.
  - InitialSyncChange: "The system downloads the existing keys and values from iCloud when someone logs into a device using their Apple account. If you try to write a key and value to the iCloud data store while this initial download is in progress, the system generates the didChangeExternallyNotification notification with this key."
  - AccountChange: "When someone changes the Apple account of the current device, the system removes any previous iCloud data and replaces it with data from the new account."
  - `synchronize()` "returns `false` if the app doesn't have the required entitlements".

  — https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/didchangeexternallynotification and the constant pages, read 2026-11-26
- [PRIMARY] PSG (p. 132): "Many Apple services … use end-to-end encryption with a CloudKit service key that's protected in the same way as iCloud Keychain syncing. … These keys are synchronized between a user's devices even if the user chooses not to use iCloud Keychain to sync their passwords, passkeys, and other user data." — PSG PDF, read 2026-11-26
- [COMMENTARY] Michael Tsai's blog (June 9, 2023) quotes the WWDC 2023 CloudKit lounge, via Aaron Pearce: "As of iOS 17 and macOS Sonoma, disabling the iCloud Drive switch will no longer disable syncing in your app. It'll be controlled by the individual switch for your app." It also quotes a pre-iOS 17 Stack Overflow report: "when iCloud drive is disabled, `CKContainer.accountStatus` returns `noAccount`, even though I am signed in." — https://mjtsai.com/blog/2023/06/09/cloudkit-and-the-icloud-drive-switch/, read 2026-11-26
- [SEARCH] Developer reports say that turning off an app's per-app iCloud switch is seen by `NSPersistentCloudKitContainer` as an account change and local mirrored data is removed. The page was not read. — https://crunchybagel.com/nspersistentcloudkitcontainer/
- [PRIMARY] Apple Support "Sign out of your Apple Account and iCloud" (Published Date: November 12, 2026) lists among the services turned off at sign-out: "iCloud Keychain" and "App data for any third-party apps that you've installed that use iCloud". — https://support.apple.com/en-us/104958, read 2026-11-26

### Inferences
- [INFERENCE] I did not find an Apple sentence that literally says "there is no API to tell whether iCloud Keychain is enabled". The conclusion rests on four things:
  - none of the keychain reference pages lists a status attribute or call;
  - Quinn's "the system is in charge" (2026) and "No." on two-factor (2017);
  - TN3137 showing that the state exists only in Apple's own UI;
  - Platform docs separating Keychain sync from other iCloud services (PSG p. 132).

  The other researchers should treat it as "no documented API". It is an absence, not a statement.
- [INFERENCE] Writing a synchronizable item while sync is off or the device is signed out should still succeed locally. Support says the data is "stored locally on your device", and DTS calls sync "if the user has enabled iCloud Keychain". So `SecItemAdd` success proves nothing about the cloud. No Apple page says it returns an error in that case. Verify on a device.
- [INFERENCE] What the app **can** know reliably, without any iCloud entitlement, is whether the key it found was created by this install. Keep a non-synchronizable marker, either a `ThisDeviceOnly` keychain item or a file in Application Support, written when this install creates the key. Then:
  - synced key present, marker present: created here;
  - synced key present, marker absent: arrived from elsewhere, or survived a reinstall, or was restored;
  - no synced key, but a server space known from a local file: the key was lost, or has not synced yet.

  This is a heuristic built on the documented semantics (`ThisDeviceOnly` items do not migrate: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` doc; files do not sync).
- [INFERENCE] Adding CloudKit or KVS entitlements only to detect "signed in to iCloud" would still not answer "is Keychain sync on". A positive `accountStatus` can coexist with the Passwords switch off (PSG p. 132 separates the two). The useful truthful states are:
  - "saved on this iPhone";
  - "set to follow your Apple Account if iCloud Passwords & Keychain is on" (cannot be confirmed by the app);
  - "found a key created on another device" (from the marker heuristic).

---

## Q3. Is iCloud Keychain on by default? Share of users with iCloud Keychain or two-factor authentication

### Takeaway
Apple's current pages describe turning iCloud Keychain on as a step with prerequisites (two-factor, latest software). The iPhone User Guide implies the setup assistant may offer it ("If you didn't set up iCloud Keychain when you first set up your iPhone, you can do so now"). **No Apple page I read says it is on by default** on a new device or new Apple Account in the iOS 17/18/26/27 setup flow.

On two-factor:
- "All new Apple Accounts require two-factor authentication".
- Two-factor "is the default security method for most accounts".
- Apple's last published figure is "more than 95 percent of active iCloud accounts" (December 7, 2022).

I found **no figure from Apple or anyone credible** on the share of users with iCloud Keychain sync on, or with iCloud Backup on.

### Cited Findings
- [PRIMARY] iPhone User Guide (iOS 18 version of the page): "If you didn't set up iCloud Keychain when you first set up your iPhone, you can do so now." — https://support.apple.com/guide/iphone/passwords-devices-iph82d6721b2/ios, read 2026-11-26
- [PRIMARY] Support 109016 (Oct 1, 2026): "Before you turn on iCloud Keychain, make sure your iPhone, iPad, Mac, and Apple Vision Pro have the latest software version, and make sure that two-factor authentication is enabled for your Apple Account." It does not state a default. — https://support.apple.com/en-us/109016, read 2026-11-26
- [PRIMARY] Apple Support "iCloud data security overview" (Published Date: January 05, 2026): "All new Apple Accounts require two-factor authentication to help protect you from fraudulent attempts to gain access to your account. Two-factor authentication is also required for many features across Apple's ecosystem, including end-to-end encryption." — https://support.apple.com/en-us/102651, read 2026-11-26
- [PRIMARY] Apple Support "Two-factor authentication for Apple Account" (Published Date: August 13, 2026):
  - "Two-factor authentication is the default security method for most accounts."
  - "Most accounts already use two-factor authentication."
  - "If your Apple Account was created using two-factor authentication, this extra protection can't be removed."

  — https://support.apple.com/en-us/102660, read 2026-11-26
- [PRIMARY] Apple Newsroom, December 7, 2022: "Apple introduced two-factor authentication for Apple ID in 2015. Today, with more than 95 percent of active iCloud accounts using this protection, it is the most widely used two-factor account security system in the world that we're aware of." — https://www.apple.com/newsroom/2022/12/apple-advances-user-security-with-powerful-new-data-protections/, read 2026-11-26
- [SEARCH] A third-party guide claims the setup assistant asks "if you want to use iCloud Keychain" when you sign in on a new or erased iPhone. It is not Apple, and the page was not read. Search results only.

### Inferences
- [INFERENCE] Two-factor is close to universal: more than 95% in 2022, and mandatory for new accounts. So the binding uncertainty is the **Keychain switch** and whether the user is **signed in at all**, not two-factor. No public number exists for either, so the app should not promise sync.
- [INFERENCE] The setup assistant probably offers Keychain as part of Apple Account sign-in, which the user guide's wording suggests. Whether it is pre-checked, and whether it survives "Set Up Later" for the Apple Account, is undocumented. A hands-on test on a freshly erased device running iOS 27 is the only way to know.

---

## Q4. What survives what: app files and keychain items (ThisDeviceOnly or not; synchronizable or not)

### Takeaway
- **Uninstall.** It deletes the app's files. Keychain items have in practice survived app deletion on every release since iOS 10.3 GM; a 10.3 beta deleted them and was rolled back. Apple calls this an undocumented implementation detail ("don't rely on that"). I found no Apple statement changing it in 2023–2026.
- **Erase All Content and Settings.** It makes everything local cryptographically inaccessible.
- **Sign-out.** It removes iCloud data unless the user keeps a copy. The Keychain prompt is "keep or delete"; it is not documented for third-party items.
- **New iPhone:**
  - Synchronizable items come only through iCloud Keychain sync.
  - Non-synchronizable, non-`ThisDeviceOnly` items move by **encrypted** computer backup and by **Quick Start**, per DTS.
  - Items in an **iCloud Backup** are wrapped with the old device's hardware key. Apple says they can be restored "only to the same device from which it originated", and DTS's test table shows "gone" on a different device.
  - `ThisDeviceOnly` items never move to another device.
- **App files** (Documents, Application Support) move with every full route: iCloud Backup, Quick Start, computer backup. Caches and tmp are excluded from iCloud Backup, and `isExcludedFromBackup` is only a hint.

### Cited Findings
**Uninstall / reinstall**
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn (Dec 2017 post, re-verified):
  - "All versions of iOS prior to 10.3 beta preserve keychain items when an app is deleted. IMPORTANT This was most definitely an implementation detail of the original iOS keychain. Our keychain documentation has never specified what would happen in this case."
  - The 10.3 beta change "was rolled back before 10.3 GM."
  - "preserving keychain items on delete is an obvious privacy concern … I don't think it would surprise anyone if the 10.3 behaviour returned at some point in the future."
  - Mar 2021: "That's expected behaviour (except in some beta releases of 10.3)."
  - The workaround for auto-delete: "entangle it with a random key you store on disk".

  — https://developer.apple.com/forums/thread/36442, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, June 2023, to a developer wanting data to survive deletion without accounts:
  - "Yeah, don't rely on that."
  - "One alternative is to rely on their Apple ID, using services like iCloud Keychain, iCloud key-value store [1], and CloudKit."

  — https://developer.apple.com/forums/thread/730924, read 2026-11-26
- [SEARCH] Reports that keychain items still survive deletion:
  - iOS 17.5 (June 2024, on the forum thread above);
  - an iOS 18.4 **simulator** (Esri community);
  - Expo's issue #40662.

  These pages were not read in full. I found nothing for iOS 26 or 27. — https://community.esri.com/t5/flutter-maps-sdk-questions/ios-credentials-persist-after-app-uninstall/td-p/1611867 ; https://github.com/expo/expo/issues/40662
- [PRIMARY] App files on deletion: Apple's "Delete apps" page does not spell it out (see the earlier notes, B1). `identifierForVendor`: "The value changes when the user deletes all of that vendor's apps from the device and subsequently reinstalls one or more of them." — https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor, read 2026-11-26

**Erase All Content and Settings**
- [PRIMARY] PSG (p. 92): the file-system key is wrapped by "an effaceable key … designed to be quickly erased on demand (by the user with the 'Erase All Content and Settings' option…)". "Important: Erasing the key in this manner renders all files cryptographically inaccessible." Also (p. 101): "The keychain is implemented as a SQLite database, stored on the file system." — PSG PDF, read 2026-11-26

**Sign out of iCloud**
- [PRIMARY] Support 104958 (Nov 12, 2026): "Your iCloud data will be removed from your device unless you choose to keep a copy of that data when prompted." The options are "Erase this [Device] or Sign Out But Don't Erase". — https://support.apple.com/en-us/104958, read 2026-11-26
- [PRIMARY] Support 109016 (Oct 1, 2026):
  - "When you sign out of iCloud on your device while iCloud Keychain is turned on, you're asked to keep or delete your Keychain information."
  - "If you choose to keep the information, your passwords and passkeys are stored locally on your device, but aren't deleted or updated when you make changes on other devices."
  - "If you don't keep the information, your passwords and passkeys aren't available on your device. An encrypted copy of your Keychain data is kept on iCloud servers. If you turn iCloud Keychain back on, your passwords and passkeys will sync to your device again."

  — https://support.apple.com/en-us/109016, read 2026-11-26
- [PRIMARY] Support 122682 "What happens after you choose Sign Out But Don't Erase": "most data stays on your device. This includes: Health, Passwords, Contacts, … Data that hasn't yet synced with iCloud". — https://support.apple.com/en-us/122682, read 2026-11-26

**iCloud Backup restore, encrypted and unencrypted computer backup**
- [PRIMARY] PSG (pp. 137–138, iCloud Backup security): "iCloud Backup is also used to back up the local device keychain, encrypted with a key derived from the Secure Enclave UID root cryptographic key of the device. This key is unique to the device and not known to Apple. This allows the database to be restored only to the same device from which it originated". It also says iCloud Backup "occurs only when the device is locked, connected to a power source, and has Wi-Fi access". — PSG PDF, read 2026-11-26
- [PRIMARY] PSG (p. 95, Backup keybag, Finder/iTunes):
  - "nonmigratory keychain items remain wrapped with the UID-derived key, allowing them to be restored to the device they were originally backed up from but rendering them inaccessible on a different device."
  - "If a user chooses not to encrypt the backup, the files aren't encrypted regardless of their Data Protection class but the keychain remains protected with a UID-derived key. This is why keychain items migrate to a new device only if a backup password is set."

  — PSG PDF, read 2026-11-26
- [PRIMARY] PSG (p. 102): `kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly` items "Don't sync to iCloud Keychain; Aren't backed up; Aren't included in escrow keybags". "Other keychain classes have a 'This device only' counterpart, which is always protected with the UID when being copied from the device during a backup, rendering it useless if it's restored to a different device." — PSG PDF, read 2026-11-26
- [PRIMARY] Developer docs:
  - "If the attribute ends with the string `ThisDeviceOnly`, the item can be restored to the same device that created a backup, but it isn't migrated when restoring another device's backup data." — restricting-keychain-item-accessibility
  - `kSecAttrAccessibleAfterFirstUnlock`: "Items with this attribute migrate to a new device when using encrypted backups."
  - `…AfterFirstUnlockThisDeviceOnly`: "Items with this attribute do not migrate to a new device. Thus, after restoring from a backup of a different device, these items will not be present."

  — https://developer.apple.com/documentation/security/restricting-keychain-item-accessibility ; …/ksecattraccessibleafterfirstunlock ; …/ksecattraccessibleafterfirstunlockthisdeviceonly, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, Dec 2017, corrects himself: "iCloud Backup acts like an iTunes backup without a password: the keychain items _are_ included in the backup but they are wrapped with a device-specific key. Thus, they can only be restored to the device that originally backed them up". His Dec 2018 test table (iOS 12, Xcode 10.1, "I don't think any of these parameters make a difference"):

  | Accessible | Backup | Same device | Different device |
  |---|---|---|---|
  | Normal | iTunes (unencrypted) | restored | gone |
  | Normal | iTunes, encrypted | restored | **restored** |
  | Normal | iCloud | restored | gone |
  | ThisDeviceOnly | any of the three | restored | gone |

  Jan 2023, on Advanced Data Protection: "In theory that means that it'd be reasonable for the backup system to treat ADP iCloud backups like iTunes encrypted backups. I don't know whether we made that change … I have not tried out ADP." A non-Apple poster (Mar 2023, iOS 16.3) reported that ADP did not change the result. — https://developer.apple.com/forums/thread/93373, read 2026-11-26
- [PRIMARY] Support 102441 (Sep 15, 2026): "iCloud Keychain items aren't part of iCloud backup because they regularly sync to iCloud." — https://support.apple.com/en-us/102441, read 2026-11-26
- [ISSUE] A developer reports that an iCloud restore to a **new** phone (Xamarin) lost a `kSecAttrAccessibleAlways` item. The only way they found to make it available was `kSecAttrSynchronizable = true`. No Apple reply (Dec 2017). — https://developer.apple.com/forums/thread/93198, read 2026-11-26
- [ISSUE] A `…ThisDeviceOnly` item with a biometric access-control requirement was missing after Erase All Content plus an iCloud restore on the **same** iPhone (iOS 16.7, TestFlight build). Quinn took it offline; it is unresolved in public (Sep–Oct 2023). — https://developer.apple.com/forums/thread/738597, read 2026-11-26

**Quick Start, device to device**
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, June 2025: "If you don't `kSecAttrSynchronizable` then it defaults to false, meaning that the item won't be synched to other devices. However, it can still end up moving to a different device by: Encrypted backup and restore; Quick Start. If you don't want that, set `kSecAttrAccessible` to one of the `ThisDeviceOnly` values." — https://developer.apple.com/forums/thread/788360, read 2026-11-26
- [PRIMARY] Support "Use Quick Start" (Published Date: November 17, 2026): "If you download from iCloud, your apps and data download in the background so that you can start using your new device right away. If you transfer directly from your previous device, you'll need to wait for the transfer to complete on both devices". It says nothing about the keychain. — https://support.apple.com/en-us/102659, read 2026-11-26
- [PRIMARY] The August 2026 PSG has **no section on device-to-device migration** of the keychain. I searched the full text for "device-to-device", "Quick Start" and "migrat…": the only hits are the backup-keybag lines quoted above and unrelated items. — PSG PDF, read 2026-11-26
- [ISSUE] A Zeus wallet maintainer (PR opened Oct 29, 2026) says `kSecAttrAccessibleAfterFirstUnlock` items "move with encrypted, iCloud and Quick Start transfers". The PR also keeps an "iCloud rescue copy" (synchronizable partition) and flags reinstall survival with a UserDefaults marker. **Conflict**: "iCloud" here contradicts PSG p. 138 and DTS's table for a *different* device, unless the author means a same-device restore. — https://github.com/ZeusLN/zeus/pull/5533, read 2026-11-26

**App files and backups**
- [PRIMARY] "iCloud Backup includes app data for the apps that you've downloaded on your device." "If you turn off iCloud Backup for a device, any backups stored in iCloud are kept for 180 days before being deleted." (Published May 01, 2025.) — https://support.apple.com/en-us/108770, read 2026-11-26
- [PRIMARY] "The app container provides two directories for storing purgeable data: `/tmp`, `/Library/Caches`. The system periodically purges these directories, so iCloud Backup excludes them by default." On `isExcludedFromBackup`: "exists only to provide guidance to the system about which files and directories it can exclude; it's not a mechanism to guarantee those items never appear in a backup or on a restored device." "Because certain file operations can reset resource values, make sure you set an excluded file's resource values each time you save it." — https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup, read 2026-11-26
- [PRIMARY] PSG (p. 137): on restore, the backed-up files "are written as new files to the file system, thus reencrypting them according to their Data Protection class." — PSG PDF, read 2026-11-26

### Synthesis table (route × what the app finds afterwards)
The labels in each cell give the evidence: P = Apple doc or PSG, D = DTS forum, I = inference, ? = undocumented.

| Route | App files (Documents, Application Support) | Keychain, not sync, not ThisDeviceOnly | Keychain, ThisDeviceOnly | Keychain, synchronizable |
|---|---|---|---|---|
| Uninstall, then reinstall, same device | gone (B1 notes; I) | usually still there (D, "don't rely on that") | usually still there (D, same caveat) | still there locally and in iCloud Keychain if sync is on (I) |
| Erase All Content and Settings, set up as new | gone (P) | gone (P, keychain DB is on the erased file system) | gone (P) | comes back once the device rejoins with sync on (P 109016 "will sync to your device again"; I for third-party items) |
| Erase, then restore the iCloud Backup to the same device | restored (P) | restored (D table; P p. 138) | restored (D table); one unresolved report of loss with biometric access control (ISSUE) | via sync, not the backup (P 102441) |
| Sign out, keep a copy | stay (P 122682) | stay (I: they are not iCloud data) | stay (I) | ? Probably kept locally if the user chooses "keep", stops updating (P 109016 for "passwords and passkeys"; third-party items not mentioned) |
| Sign out, delete | stay unless the user chooses Erase (P 104958/122682) | stay (I) | stay (I) | removed from the device, kept on iCloud servers (P 109016, for "Keychain information") |
| New iPhone, Quick Start "transfer directly" | moved (P 102659) | **moved** (D 788360) | not moved (D 788360) | via sync (I) |
| New iPhone, Quick Start "download from iCloud" or iCloud Backup restore | restored (P 108770) | **gone** (P p. 138; D table) unless the Quick Start iCloud path also copies the keychain directly (?) | gone (P) | via sync only, if on (P 102441) |
| New iPhone, encrypted Finder backup | restored (P/I) | **restored** (P p. 95; P AfterFirstUnlock doc; D table) | gone (P) | via sync (I); the backup's handling of sync items is not documented (?) |
| New iPhone, unencrypted Finder backup | restored (I) | gone (P p. 95; D table) | gone (P) | via sync (I) |
| Another device on the same Apple Account (iPad, Mac), no restore | not shared | not shared | not shared | arrives after circle join and sync, 30 s to 30 min in one 2026 report (D 854637); never on tvOS (P) |

### Inferences
- [INFERENCE] For the owner's goal, "the key follows to a new iPhone", the routes compare as follows:
  - A **non-synchronizable, non-`ThisDeviceOnly`** key (today's default with no options) already follows on Quick Start direct transfer and encrypted computer backups. It is lost on an iCloud Backup restore to a new phone, the most common route for people without a computer.
  - Adding **synchronizable** covers every new-device route, but only if the user has iCloud Keychain sync on, which the app cannot check.
  - **Both** routes miss: Keychain sync off together with an iCloud-only restore.

  Sources: table above.
- [INFERENCE] App files and the key can diverge. Say the user restores an iCloud Backup to a new phone with Keychain sync off. The data files come back (Documents is in the backup) but the key does not, so the app opens with local data and no key to the server space. The reverse also happens: with Keychain sync on and a fresh setup (no backup), the key arrives without the local files. The app's settings status, and its recovery flow, need both states.
- [INFERENCE] A "truthful" status cannot rest on uninstall survival of the keychain. DTS calls it undocumented and possibly temporary, and Apple's WWDC 2017 slide says it "Will continue to remove functionality that is being abused to uniquely identify users" (quoted by DTS in thread 36442).

---

## Q5. Platform alternatives to the keychain for a 32-byte secret across the user's devices

### Takeaway
- **iCloud key-value store (`NSUbiquitousKeyValueStore`).** It is easy: one entitlement and a dictionary API, with 1,024 keys, 1 MB, 128-character keys. It works locally when signed out and uploads on sign-in. Apple tells developers **not to put sensitive data in it**: "The system stores the information on disk in an unencrypted format. Store personal or sensitive information in the person's Keychain instead". It is not listed as end-to-end encrypted under either data-protection mode. Sync is "not immediate"; an initial sync of about a minute after sign-in was reported, and a Frameworks engineer acknowledged it. It has no status API, and the "most recent value wins".
- **CloudKit private database.** It gives a detectable account status (`accountStatus`, `CKAccountChanged`). `encryptedValues` (iOS 15+) encrypts fields on device. Apple's user-facing table says third-party CloudKit encrypted fields are end-to-end encrypted only **when Advanced Data Protection is on**, while the developer article says CloudKit uses key material "in the user's iCloud Keychain". It needs a container, a schema and handling of zone-reset errors. It is still "Apple Account available", not "Keychain switch on".
- **iCloud Keychain itself.** It is end-to-end encrypted by default ("Passwords and Keychain: End-to-end / Trusted devices" in both modes), needs no entitlement for single-app use, and is the only one of the three that Apple recommends for secrets. Its state cannot be detected.

### Cited Findings
**NSUbiquitousKeyValueStore**
- [PRIMARY] Overview:
  - It is "An iCloud-based container of key-value pairs you share among instances of your app running on a person's devices."
  - "Important: Don't store personal or sensitive information in the key-value store. The system stores the information on disk in an unencrypted format. Store personal or sensitive information in the person's Keychain instead."
  - "Note: To use this object, you must distribute your app through the App Store or Mac App Store, and you must request the com.apple.developer.ubiquity-kvstore-identifier in your Xcode project."
  - "If the device doesn't have an active Apple account, the changes remain only on the current device. When the person signs into their account, the system forwards any changes to the iCloud server and reconciles the values there with the local ones."
  - Limits: "no more than 1024 keys", "The total amount of available storage space for all values is 1 megabyte", "The maximum length for each key string is 128 characters using the UTF-16 encoding."

  — https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore, read 2026-11-26
- [PRIMARY] `synchronize()`:
  - "Most of the time, you don't need to call this method directly."
  - "Don't rely on keys and values being available on the person's other devices immediately. This method doesn't force the system to write new keys and values to iCloud. … iCloud determines the best time to retrieve those keys and synchronize them with the person's other devices. Typically, iCloud limits updates to several times per minute."
  - "Typically, you call this method only at launch or when your app returns to the foreground."

  — https://developer.apple.com/documentation/foundation/nsubiquitouskeyvaluestore/synchronize(), read 2026-11-26
- [PRIMARY] Archived iCloud Design Guide (2015, old): "The most recent value set for a key wins and is pushed to all devices attached to the same iCloud account." "If your app needs to store passwords, do not use iCloud storage APIs for that. The correct API for storing and managing passwords is Keychain Services". — https://developer.apple.com/library/archive/documentation/General/Conceptual/iCloudDesignGuide/Chapters/iCloudFundametals.html, read 2026-11-26
- [PRIMARY] Apple Frameworks Engineer, Developer Forums, not documentation (Mar 2023). The question was "I moved to a new device and logged into iCloud settings and if I immediately open our app and query for a value it returns nil. After considerable delay say 1 minute … the proper stored value is returned." The answer: "when you first sign in to iCloud, there are a wide variety of subsystems trying to sync their data. As a result, there might be a delay when trying to fetch data for NSUbiquitousKeyValueStore. That said, when you launch your app, NSUbiquitousKeyValueStore should automatically try to fetch at a higher priority". — https://developer.apple.com/forums/thread/726593, read 2026-11-26
- [ISSUE] A developer guessed that KVS data in iCloud is "forever" after app deletion; there was no Apple reply (Jul 2019). — https://developer.apple.com/forums/thread/120256, read 2026-11-26

**CloudKit private database**
- [PRIMARY] `encryptedValues` (iOS 15.0+):
  - "CloudKit encrypts the fields' values on-device before saving them to iCloud, and decrypts the values only after fetching them from the server. When you enable Advanced Data Protection, the encryption keys are available exclusively to the record's owner".
  - "Only encrypt new fields. CloudKit doesn't allow encryption on fields that already exist in your app's schema, or on records that you store in the public database."

  — https://developer.apple.com/documentation/cloudkit/ckrecord/encryptedvalues, read 2026-11-26
- [PRIMARY] "Encrypting User Data":
  - "CloudKit encrypts data with the key material in the user's iCloud Keychain. If the user loses access to iCloud Keychain, CloudKit can't access the key material that it previously used to encrypt the data, so iCloud can't decrypt it."
  - On reset: "CloudKit … returns a zoneNotFound with an entry of CKErrorUserDidResetEncryptedDataKey … When this error occurs, the data becomes permanently lost."
  - "Users can also choose to manually delete their zones … userDeletedZone error."

  — https://developer.apple.com/documentation/cloudkit/encrypting-user-data, read 2026-11-26
- [PRIMARY] PSG (pp. 132–133):
  - "Each container's private database is protected by a key hierarchy, rooted in an asymmetric key called a CloudKit Service key."
  - Service keys are "divided into two categories: end-to-end encrypted and available-after-authentication". The second category covers keys stored in Apple HSMs that "can be accessed by Apple servers without further user interaction".

  — PSG PDF, read 2026-11-26
- [PRIMARY] Support 102651 (Jan 5, 2026): "Third-party app data stored in iCloud is always encrypted in transit and on server. When you turn on Advanced Data Protection, third-party app data stored in iCloud Backup and CloudKit encrypted fields and assets are end-to-end encrypted." Its table: "Passwords and Keychain: End-to-end / Trusted devices" under both Standard and Advanced; "iCloud Backup: In transit & on server / Apple" under Standard. — https://support.apple.com/en-us/102651, read 2026-11-26
- Conflict, minor: the number of end-to-end encrypted categories.
  - [PRIMARY] Support 102651 (Jan 2026) says "15 data categories" by default and "rises to 25" with Advanced Data Protection.
  - [PRIMARY] PSG (Aug 2026, p. 131) says "14 data categories" and "rises to 23".
  - [PRIMARY] The Dec 2022 newsroom says 14 and 23.

  Keychain is end-to-end encrypted in all three; the discrepancy does not affect this question.
- Conflict, material: whether CloudKit `encryptedValues` are end-to-end encrypted under **standard** protection.
  - The developer article ties them to "key material in the user's iCloud Keychain".
  - The `encryptedValues` page and Support 102651 tie exclusive or end-to-end access to **Advanced Data Protection**.

  Unresolved. The safe reading is: end-to-end encrypted only with Advanced Data Protection.

**Keychain (for comparison)**
- [PRIMARY] PSG (p. 148): "Keychain items are transferred from device to device, traveling through Apple servers, but are encrypted end-to-end so that Apple and other devices can't read their contents." — PSG PDF, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation. Quinn, Jan 2023: "iCloud Keychain has always used end-to-end encryption." — https://developer.apple.com/forums/thread/93373, read 2026-11-26

### Inferences
- [INFERENCE] Native Swift work for each option. The API names come from the pages cited; the Flutter bridging is out of scope.
  1. **Keychain sync**: add `kSecAttrSynchronizable: kCFBooleanTrue` to the `SecItemAdd`, `SecItemCopyMatching`, `SecItemUpdate` and `SecItemDelete` dictionaries for a `kSecClassGenericPassword` item. Migrate the old item, using `kSecAttrSynchronizableAny` to find it. No entitlement.
  2. **KVS**: add the iCloud capability with "Key-value storage". `NSUbiquitousKeyValueStore.default.set(data, forKey:)`, call `synchronize()` at launch, observe `didChangeExternallyNotification` and branch on `NSUbiquitousKeyValueStoreChangeReasonKey`.
  3. **CloudKit**: add the iCloud capability with CloudKit and a container. `CKContainer(identifier:).accountStatus()`, observe `CKAccountChanged`, use a fixed record in a custom zone of the `privateCloudDatabase` with the secret in `encryptedValues`. Handle `.temporarilyUnavailable`, `zoneNotFound` with `CKErrorUserDidResetEncryptedDataKey`, and `userDeletedZone`. Promote the schema to production.
- [INFERENCE] For a secret that **opens server data**, KVS is ruled out by Apple's own "Don't store … sensitive information" warning and by the lack of end-to-end encryption. CloudKit adds detectability and work, and is end-to-end encrypted only with ADP by Apple's own table. iCloud Keychain is the only end-to-end encrypted-by-default option with no entitlement, at the price of no status. A possible combination is a synchronizable keychain item for the secret, plus an optional KVS or CloudKit **non-secret** flag ("a key exists for this Apple Account, created on <date>"). That flag would let a new device know it should wait for the Keychain instead of creating a new key. It adds an entitlement and does not reveal the Keychain switch. This design is mine, not Apple's; check it before relying on it.

---

## Q7. App Review and privacy consequences

### Takeaway
- **App Review Guidelines.** Apple says nothing specific about keeping an app-generated secret in iCloud Keychain to restore server access. Guideline 5.1.1(v) pushes toward no-login use ("If your app doesn't include significant account-based features, let people use it without a login"). 5.1.1(i) requires the privacy policy to explain retention and deletion and how to request deletion.
- **Fingerprinting rule.** It forbids deriving data from the device to identify it. A random secret generated by the app and kept in the user's own keychain is not derived from device signals.
- **Privacy manifest.** The keychain (SecItem) and `NSUbiquitousKeyValueStore` are **not** required-reason APIs. The listed categories are File timestamp, System boot time, Disk space, Active keyboards and User defaults.
- **Privacy label.** A server-side identifier that ties stored data to one person fits "User ID" ("assigned user ID … or other user- or account-level ID"), linked to the user, for app functionality. It is "tracking" only if joined with third-party data for ads or shared with a data broker.
- **Apple's sanctioned persistence.** Its tools for state that survives reinstall are DeviceCheck's two bits per device and, per DTS, the user's Apple ID services: iCloud Keychain, KVS, CloudKit. `identifierForVendor` resets when all the vendor's apps are deleted.

### Cited Findings
- [PRIMARY] App Store Review Guidelines (Last Updated: October 16, 2026):
  - 5.1.1(v): "If your app doesn't include significant account-based features, let people use it without a login. If your app supports account creation, you must also offer account deletion within the app."
  - 5.1.1(i): the privacy policy must "Explain its data retention/deletion policies and describe how a user can revoke consent and/or request deletion of the user's data."
  - 5.1.2(iii): "Apps should not attempt to surreptitiously build a user profile based on collected data and may not attempt, facilitate, or encourage others to identify anonymous users".
  - 5.1.2(i): "You must receive explicit permission from users via the App Tracking Transparency APIs to track their activity."

  — https://developer.apple.com/app-store/review/guidelines/, read 2026-11-26
- [PRIMARY] App privacy details:
  - "'Collect' refers to transmitting data off the device in a way that allows you and/or your third-party partners to access it for a period longer than what is necessary to service the transmitted request in real time."
  - User ID: "Such as screen name, handle, account ID, assigned user ID, customer number, or other user- or account-level ID that can be used to identify a particular user or account". Device ID: "Such as the device's advertising identifier, or other device-level ID".
  - Linked: "You'll need to identify whether each data type is linked to the user's identity (via their account, device, or other details)". "'Personal Information' and 'Personal Data', as defined under relevant privacy laws, are considered linked to the user."
  - Tracking: "'Tracking' refers to linking data collected from your app about a particular end-user or device, such as a user ID, device ID, or profile, with Third-Party Data for targeted advertising or advertising measurement purposes, or sharing data collected from your app about a particular end-user or device with a data broker." Not tracking: "When the data is linked solely on the end-user's device and is not sent off the device in a way that can identify the end-user or device."

  — https://developer.apple.com/app-store/app-privacy-details/, read 2026-11-26
- [PRIMARY] User Privacy and Data Use FAQ:
  - "Can I fingerprint or use signals from the device to try to identify the device or a user? No. Per the Apple Developer Program License Agreement, you may not derive data from a device for the purpose of uniquely identifying it. Examples of user or device data include … the user's device and its configuration, the user's location, or the user's network connection."
  - Identifiers governed by ATT include "the device's advertising identifier, session ID, fingerprint IDs, and device graph identifiers" when used "to join data from your app with data from third parties … for purposes of advertising or ad measurement or sharing with a data broker".

  — https://developer.apple.com/app-store/user-privacy-and-data-use/, read 2026-11-26
- [PRIMARY] Required reason API:
  - The categories are `NSPrivacyAccessedAPICategoryFileTimestamp`, `…SystemBootTime`, `…DiskSpace`, `…ActiveKeyboards`, `…UserDefaults`. The page's JSON has no mention of keychain, SecItem or NSUbiquitousKeyValueStore.
  - UserDefaults reason CA92.1: "Declare this reason to access user defaults to read and write information that is only accessible to the app itself."
  - The article: "Regardless of whether a user gives your app permission to track, fingerprinting is not allowed."

  — https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype and https://developer.apple.com/documentation/bundleresources/describing-use-of-required-reason-api, read 2026-11-26
- [PRIMARY] DeviceCheck: "you can get a token that you use on your server to set and query two binary digits of data per device, while maintaining user privacy. For example, you might use this data to identify devices that have already taken advantage of a promotional offer". The query response includes "`last_update_time` … in YYYY-MM format". — https://developer.apple.com/documentation/devicecheck and …/accessing-and-modifying-per-device-data, read 2026-11-26
- [PRIMARY] Apple DTS, Developer Forums, not documentation:
  - On keychain survival: "iOS 11 introduced the DeviceCheck framework, which provides a forward path for one of the most common legitimate use cases of this behaviour". The WWDC 2017 Session 702 slide reads: "Will continue to remove entropy … Will continue to remove functionality that is being abused to uniquely identify users". — https://developer.apple.com/forums/thread/36442, read 2026-11-26
  - Without accounts, "rely on their Apple ID, using services like iCloud Keychain, iCloud key-value store, and CloudKit". — https://developer.apple.com/forums/thread/730924, read 2026-11-26
- [PRIMARY] `identifierForVendor`: "The value changes when the user deletes all of that vendor's apps from the device and subsequently reinstalls one or more of them. … if your app stores the value of this property anywhere, you should gracefully handle situations where the identifier changes." — https://developer.apple.com/documentation/uikit/uidevice/identifierforvendor, read 2026-11-26

### Inferences
- [INFERENCE] I found no guideline, label rule or DTS statement against storing an app-created secret in the user's iCloud Keychain. DTS names iCloud Keychain as the account-free way to persist across devices (730924). The secret is random rather than "derived from a device", so the fingerprinting prohibition does not describe it. It also follows the Apple Account rather than the hardware: it moves to new devices and is wiped by Erase without sync. **Apple says nothing specific**, so this is reasoning from the definitions above.
- [INFERENCE] Labelling. If the server stores data under an identifier derived from or tied to the key, that is "collected" data linked to the user. "User ID" (assigned user ID) is the closer category, not "Device ID". The key follows the person's Apple Account, not the device. Purpose: App Functionality. The same identifier must never reach an ad or attribution SDK, or it becomes "tracking" under ATT.
- [INFERENCE] "Silently restoring access". Nothing in 5.1.x forbids reconnecting a returning user's own data. Two points carry risk:
  - The privacy policy (5.1.1(i)) should say that the access secret is kept in the user's iCloud Keychain when available, and how to delete the server data.
  - Because a synchronizable deletion "affects all copies", an in-app "delete my data / forget this device" must explain that it removes the key on all the user's devices.

  The truthful settings status the owner wants is also the natural disclosure surface.
- [INFERENCE] DeviceCheck is no substitute here. It gives two bits per device, cannot carry a 32-byte secret, does not follow the user to a new phone, and its documented purpose is promotional-offer and fraud flags.

---

## Gaps
- **No Apple statement found that literally says "there is no API to detect iCloud Keychain on/off" or "item has synced".** The conclusion is an absence plus DTS's "the system is in charge". A Developer Forums question to DTS would settle it.
- **Writing a synchronizable item while sync is off, then turning sync on:** not documented for third-party items. Whether `SecItemAdd` returns success when signed out of iCloud: not documented. Test on devices.
- **Sign-out "keep or delete Keychain" prompt for third-party synchronizable items:** Apple documents it only for "passwords and passkeys" and "Keychain information". Whether app items are kept, deleted or hidden is unknown. Test.
- **Quick Start "download from iCloud" path:** no source says whether non-synchronizable keychain items come along. It may behave like an iCloud Backup restore (lost) or partly use the old device. The PSG (Aug 2026) has no device-to-device migration section.
- **Advanced Data Protection and keychain in iCloud Backup to a different device:** DTS did not know (Jan 2023). One non-Apple report says no change (iOS 16.3). Nothing newer.
- **Keychain survival after uninstall on iOS 26/27:** no report found; the latest are iOS 17.5 (forum, search snippet) and an iOS 18.4 simulator.
- **Default state of iCloud Keychain in the iOS 27 setup assistant**, and the **share of users with iCloud Keychain sync on** or with iCloud Backup on: no Apple or credible figure. The latest two-factor figure is ">95% of active iCloud accounts", December 2022.
- **Initial keychain sync delay on a freshly set-up device:** no Apple figure. The only measurements are one 2026 developer report (30 s iOS to iOS, about 30 min iOS to macOS) and one KVS report (about 1 min after sign-in, 2023).
- **Per-app iCloud switch and KVS:** no primary source on whether turning off the app's iCloud switch stops KVS sync, or what the app observes. For CloudKit, only commentary: iOS 17+ per-app switch, pre-iOS 17 iCloud Drive switch giving `noAccount`. Not verified on iOS 26/27.
- **Encrypted Finder backup and synchronizable items:** how the backup treats them (included, skipped, or re-synced) is not documented.
- **CloudKit `encryptedValues` under standard data protection:** whether they are end-to-end encrypted is contradictory between Apple pages (developer article vs `encryptedValues` page and Support 102651). Unresolved.
- **Retention of KVS and CloudKit data after app deletion**, and the user deleting an app's iCloud data via Settings > iCloud > Manage storage: not verified this session.
- **The iOS 27 report that `kSecAttrAccessControl` + `kSecAttrSynchronizable` is rejected** comes from one simulator issue caused by a library bug. Whether biometric access control and sync were ever compatible on devices was not verified in Apple docs.
