# Accounts in comparable tracker, habit and mood apps, and the risks and costs of a device-only, no-account mode

Scope: (A) how 14 comparable apps handle accounts: whether they work without one, where data lives, backup and phone change, when and why they ask for an account, and premium without an account. (B) The documented risks and costs, for a one-developer Flutter app (iOS first, Android too, EU developer, server in France, AdMob + RevenueCat), of keeping data on the device until the user creates an account. Those risks are data loss, the free limit and ads, abuse, consent-free usage measurement under EU rules, features that need a server identity, the cost of two modes, and the prompts that convert guests. All pages were read on **2026-11-25** unless another date is given. A date in square brackets after a source is the page's own date, when it shows one.

Evidence labels:
- [PRIMARY]: a company's own statement about its product: help centre, website, privacy policy, store listing (description, release notes, privacy label, developer replies), or the maintainer of an open-source app.
- [VENDOR]: advice or data from a vendor with a commercial interest.
- [DOCS]: official platform or SDK documentation, including Apple DTS engineers on the Apple Developer Forums.
- [REGULATOR]: law text or regulator guidance.
- [COMMENTARY]: blogs, forums, reviews, law-firm notes, practitioners without data.
- [SEARCH]: known only from a search-result snippet; the page itself was not read.
- [INFERENCE]: my own reasoning.

Method notes:
- Google Play store pages do not render for the fetcher, but the Play "Data safety" pages (`play.google.com/store/apps/datasafety?id=…`) do.
- The Finch help centre (help.finchcare.com) and Mozilla's *Privacy Not Included* returned HTTP 403. Finch facts therefore come from search snippets of Finch's own help pages and are labelled [SEARCH].
- Reddit was not searched (the domain was blocked for this crawler in earlier passes).
- App Store pages show relative dates ("4d ago"). I convert them relative to 25 Nov 2026.

On "Pixels" vs "Year in Pixels (by Teo Vogel)": these are one product. On iOS it is "Pixels: Mood Tracker & Journal" (id1668460700, also titled "Mood Tracker by Pixels" or "Pixels Journal" in some storefronts). On Android it is package `ar.teovogel.yip` ("yip" = year in pixels), listed today as "Mood Tracker & Journal: Pixels". I found no separate "Year in Pixels" app by Teo Vogel, so I merged the two entries. I used the freed slot for **Pixa – My Year in Pixels**, a year-in-pixels app whose free tier is three logs. I also added How We Feel. Reflectly and Moodnotes were not covered (see Gaps).

---

## A. Comparable apps: account, data location, backup, prompts, premium

### Takeaway
Of the 14 apps, 11 can be used at first launch without an account, 2 require one (Bearable, Notion) and 1 is unverified (Pixa). Five have no account system at all: Daylio, Streaks, Loop, Way of Life and HabitKit. These rely on the user's own platform cloud (iCloud, iCloud Drive, Google Drive, Android system backup) or on export files, never on the developer's server. Five more make the account optional and sell it as backup or sync: Pixels ("Pixels Cloud"), Habitify ("Guest"), HabitNow, Finch and How We Feel. Duolingo lets people take a lesson first, then uses dismissable "soft walls" and finally a hard wall.

Device-only apps all leave the same holes. Moving between iOS and Android is manual (an export file), and premium cannot follow the user across platforms automatically: Daylio says buy again, and HabitKit's support transfers it by hand. Each of these apps also documents a "your data will probably be lost" case. The argument used to ask for an account is almost always **"back up / don't lose your data / new phone"**, then **"sync across devices / web"**. No app in the set asks at purchase.

### Summary table

| App | Usable without an account? | Where data lives | Backup / new phone | When an account is asked, and why | Premium without an account |
|---|---|---|---|---|---|
| **Daylio** | Yes. No account exists. | On the phone. Optional backups go to the user's own Google Drive (Android) or iCloud Drive (iOS). | Once switched on, it backs up after every entry and keeps about 100 backups. Same-OS phones restore from the cloud. Cross-platform needs a manually exported backup file. With no backup: "your data will probably be lost". | Never; backups use the user's Google or Apple account. | Store purchase, restored per platform. It cannot move between iOS and Android: buy again. |
| **Pixels** (Teo Vogel; Android `ar.teovogel.yip`) | Yes; the account is optional. | On the phone. An optional free "Pixels Cloud" account (e-mail or Google sign-in) stores data on Google Cloud servers in the US. | Pixels Cloud backup and sync; paid "Cloud+" tier. | The developer pushes it in review replies: "backup your data with a free Pixels Cloud account!" | IAPs: Pixels+ $4.99; Cloud+ $1.99 / $21.99. Restore mechanics not documented. |
| **Pixa – My Year in Pixels** | Unverified. Sign in with Apple was added in 1.4.6; privacy label "Data Not Collected". | Not documented. | Not documented; PDF export. | Unverified. | Free tier is 3 logs. Monthly, annual or lifetime ($39.99). |
| **Habitify** | Yes on the phone ("Start as a Guest"); the web app needs sign-up. | Guest: "stored only locally on a single device and will not sync". Account: Habitify servers, synced across iOS, Android, Mac, Watch and web. | Account sync; `.sqlite` export and import between accounts. | A guest must link e-mail, Google or Apple "to save your data and never lose your account". Needed for multi-device use and the web. | Not documented for guests. |
| **Streaks** | Yes: "There's no sign-up or login." | On the device plus the user's own iCloud. | iCloud sync across Apple devices; "automatic backups"; CSV export and import. | Never. | Paid upfront ($5.99) through the Apple ID; Family Sharing; Apple platforms only. |
| **Loop Habit Tracker** | Yes: "doesn't require … online account registration". | Device only. Play data safety: "No data collected". | Android system backup ("can be unreliable at times"), plus an "Export full backup" file and "Import data". | Never. Sync was prototyped in 2016 and never shipped. | No paid tier seen. |
| **HabitNow** | Yes; Google sign-in is optional. | Free users: "stored only on your device". Premium cloud backups go to a third-party cloud. | Premium cloud backups, switched on manually. | Google sign-in ties purchases and cloud backups to a Google account. | "premium purchase is linked to your Google account"; restore through Google Play or by signing in. |
| **Way of Life** | Yes; no account described. | Device. | Backup "to your preferred cloud storage provider" (free since 4.3.0); CSV, Excel or JSON export; no sync yet. | Never. | Premium (one-off; subscriptions since 2023) through the App Store. |
| **Finch** | Yes; the account is optional [SEARCH]. | "all Finch data is local unless you have a Finch Account" [SEARCH]. | An account turns on automatic Cloud Backups (about every 24 h); there is also a manual backup file [SEARCH]. | Settings › Profile › Create Account. Argument: recover the pet and progress when switching phones [SEARCH]. | Unverified. |
| **Bearable** | No; the account is required. | Encrypted on the device, then backed up to Google Cloud servers in the EU. | Restore through the account; the app restores from the backup at each sign-in. | At first launch. Reasons: to "restore your data in a rare case of data loss", change e-mail, or switch device. The account also records explicit consent for health data. | n/a (there is always an account). |
| **HabitKit** | Yes: "No account. No sign-up. No ads." | Device; "works completely offline". | Daily automatic iCloud backup (iPhone to iPhone, since 1.18.2) or Google Drive backup (Android to Android); export and import files; "does not automatically sync". | Never. | Pro (monthly, yearly or lifetime) through the store and RevenueCat; restore through the store account. Support transfers Pro across platforms by hand, using the "RC ID"s. |
| **How We Feel** | Yes; an account is optional (created in Settings; Google sign-in exists). | "kept on your device unless you opt-in" to research sharing; iCloud sync on iOS. | Optional Google Drive backup on Android (since Jul 2026); CSV export and import; iCloud sync. | An in-app reminder "to sync your data to iCloud to save check-ins". | Free (nonprofit). |
| **Duolingo** | Yes at first: a lesson comes before sign-up. | Duolingo servers. | Account. | Dismissable "soft walls" after the first lesson(s), then a hard wall "after several lessons" (2017 data). Argument: "create a profile to save your progress", and use other devices. | Not researched. |
| **Notion** (contrast) | No. | Notion servers. | Account sync. | At first launch. | Not researched. |

### Cited Findings

**Daylio** (Relaxio / "Habitics" on Play; local-first, no accounts)
- [PRIMARY] iOS listing:
  - Storage: "Your data is stored locally on your phone."
  - Backup: "Safely back up and restore your entries via your private Google Drive", "Your backups are transferred to the iCloud Drive via the secure (encrypted) channels", and "You can optionally schedule backups to your private cloud storage or take your backup file with you anywhere".
  - Export: PDF and CSV.
  - Version 1.79.0 was listed "15h ago" (about 24 Nov 2026).
  - App Privacy shows only **"Data Not Linked to You"**: Analytics (Purchase History, Product Interaction) and App Functionality (Purchase History, Crash/Performance/Other Diagnostic Data).
  - No shown review mentions lost data. — [App Store US](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
- [PRIMARY] Play Data safety: "No data shared with third parties". Collected, all marked *Optional* and for Analytics: device or other IDs, crash logs, diagnostics, app interactions. "The developer doesn't provide a way for you to request that your data be deleted." — [Play Data safety](https://play.google.com/store/apps/datasafety?id=net.daylio&hl=en)
- [PRIMARY] [20 Dec 2024] Backups go to Google Drive (Android) or iCloud (iOS). "When you turn on the backups, Daylio will automatically backup your data after each entry." Failed backups are retried; after several failures the app notifies the user and asks for a manual backup. iOS needs iCloud Drive on and enough iCloud space. — [Daylio FAQ: Are my data backed up?](https://daylio.net/faq/docs/daylio-faq/backup/are-my-data-backed-up/)
- [PRIMARY] [20 Jan 2025] The "Missing entries" article:
  - About 100 recent backups are kept.
  - Being signed into a different Google account or Apple ID hides them.
  - "Android 6+ can automatically backup your phone's data including the app's data" (Daylio is not aware of these). "You can't restore a backup from a higher Android version onto a phone running a lower Android version."
  - An iOS device backup may include Daylio data.
  - Otherwise "your data will probably be lost", because Daylio does not store or have access to user data. — [Daylio FAQ: Missing entries](https://daylio.net/faq/?p=5760)
- [PRIMARY] [20 Dec 2024] New phone on the same OS: restore the backup, then restore purchases. "Purchases cannot be transferred between Google and Apple products … iOS or Android do not allow transferring any purchases between platforms." — [Daylio FAQ: Move Daylio to new phone](https://daylio.net/faq/docs/daylio-faq/tutorials/moving-daylio-to-new-phone/)
- [SEARCH] Cross-platform moves need a backup file exported by hand from Advanced Options: "You cannot use your regular or automatic backup file to transfer data to another platform." — [Daylio FAQ: Move backup between iOS and Android](https://daylio.net/faq/docs/daylio-faq/backup/move-backup-between-ios-and-android/)
- Flag: the FAQ pages are dated Dec 2024 and Jan 2025, so they may predate current app behaviour.

**Pixels** (Teo Vogel; iOS id1668460700, Android `ar.teovogel.yip`)
- [PRIMARY] iOS listing:
  - Version 2.4.2 (12 Nov).
  - The 2.0.x release notes say "More reliable backups & sync".
  - A developer reply to a review: "Don't forget to backup your data with a free Pixels Cloud account!"
  - IAPs: "Pixels Cloud+ $1.99", "Pixels+ $4.99", "Pixels Cloud+ $21.99".
  - App Privacy: **"Data Not Collected"**.
  - The description says "No ads, no tracking", yet the age-rating block says "Contains Advertising". — [App Store](https://apps.apple.com/app/id1668460700)
- [PRIMARY] [6 Dec 2023, may be outdated] The privacy policy lists, among other things:
  - E-mail addresses, and data from social sign-in.
  - "Our servers are located in the United States"; Google Cloud Platform and Google OAuth 2.0.
  - "Google Analytics for Firebase", Crashlytics and AdMob.
  - An "offer wall" that receives a user ID. — [pixelstracker.app/privacy](https://pixelstracker.app/privacy)
- [PRIMARY] Play Data safety: only **e-mail address, Optional, App functionality**; no sharing; encrypted in transit; deletion can be requested. — [Play Data safety](https://play.google.com/store/apps/datasafety?id=ar.teovogel.yip&hl=en)
- [PRIMARY] The developer's page says nothing about accounts or backup; support is support@pixelstracker.app. — [teovogel.me/pixels](https://teovogel.me/pixels/)
- [INFERENCE] The iOS "Data Not Collected" label sits badly with an optional e-mail cloud account, Firebase Analytics and AdMob named in the policy. Either the policy is generic across the developer's apps or the label is out of date. Do not copy the label as a benchmark.

**Pixa – My Year in Pixels** (Tulip Tech AB; added as a close comparable)
- [PRIMARY] 2.1K ratings, 4.6 stars.
  - Free tier: "three logs". Premium is monthly, annual or lifetime ($39.99).
  - 1.4.6 added "Sign up/Log in with Apple!"; 1.6.2 added PDF export.
  - Privacy label: "The developer does not collect any data from this app."
  - Version 1.8.0 (17 Nov).
  - The listing does not say whether sign-in is required, or how backup and sync work. — [App Store US](https://apps.apple.com/us/app/pixa-my-year-in-pixels/id6480351200)

**Habitify** (account-based with a guest mode)
- [SEARCH] "In Habitify, we give you 3 options to start an account: Start as a Guest account – available on the phone app, Use your Gmail to sign up, Use your Apple ID to sign up." On the web you sign up with Google or Apple; no guest option was found. — [Habitify help: Signing up](https://intercom.help/habitify-app/en/articles/8359911-sign-up-for-a-habitify-account)
- [PRIMARY] [9 Oct 2025] On multiple devices you "must have a registered Habitify account".
  - A Guest account is "stored only locally on a single device and will not sync".
  - Signing in with a different method can create a second, empty account. This is the most common reason data "doesn't appear". — [Habitify help: multiple devices](https://intercom.help/habitify-app/en/articles/9344497-log-into-your-account-on-multiple-platforms-devices)
- [PRIMARY] [13 Jul 2026] "To save your data and never lose your account, you can link your guest account with your email and set a password". On Android, "server processing takes about 1 minute" after linking. — [Habitify help: link a guest account](https://intercom.help/habitify-app/en/articles/9342753-link-a-guest-account-with-email-password)
- [PRIMARY] iOS listing:
  - Version 53.0.0 ("6d ago", about 19 Nov 2026): "If signing up with Apple or Google fails during setup, you can keep going and link your account later in Settings."
  - Syncs iPhone, iPad, Mac and Watch; tiers Free, Plus and Pro (Pro Lifetime $119.99).
  - Privacy label: only **"Data Not Linked to You"** (Usage Data, Diagnostics). — [App Store US](https://apps.apple.com/us/app/habitify-habit-tracker/id1111447047)
- [SEARCH] Moving data between accounts uses an exported `.sqlite` backup file. — [Habitify help: transfer data](https://intercom.help/habitify-app/en/articles/10583732-how-to-transfer-data-between-habitify-accounts)

**Streaks** (Crunchy Bagel; paid upfront, Apple-only)
- [PRIMARY]
  - "No. There's no sign-up or login." "Your habits are stored on your device and synced through your own iCloud account, not on our servers."
  - It works offline and syncs later.
  - 11.6.0 ("6d ago") notes "Improvements to automatic backups". CSV export and import came in 11.3.6.
  - Family Sharing; $5.99 one-time.
  - Privacy label: Data Not Linked to You, Crash Data only.
  - No shown review mentions lost data. — [App Store US](https://apps.apple.com/us/app/streaks/id963034692)

**Loop Habit Tracker** (open source, Android)
- [PRIMARY] "Loop doesn't require an Internet connection or online account registration." "Your confidential data is never sent to anyone." Export to CSV or SQLite. — [GitHub README](https://github.com/iSoron/uhabits)
- [PRIMARY] Play Data safety: "No data shared with third parties", "No data collected". — [Play Data safety](https://play.google.com/store/apps/datasafety?id=org.isoron.uhabits&hl=en)
- [PRIMARY] [28 Dec 2020, old] Maintainer FAQ:
  - "Loop supports Android's native backup service"; "it should periodically save a copy of your data in the cloud automatically", but "this backup system can be unreliable at times".
  - "The data will be restored in case you factory-reset your phone or activate a new device."
  - "uninstalling the app will delete all your data, in addition to all the backups stored in the cloud".
  - "Export full backup" writes a file, also copied automatically to the SD card. "Import data" restores it.
  - He recommends a separate backup utility. — [GitHub discussion #689](https://github.com/iSoron/uhabits/discussions/689)
- [PRIMARY] / [COMMENTARY] Sync history:
  - In May 2016 the maintainer required sync to be "completely opt-in" and self-hostable. A Node.js backend on a `feature/sync` branch was "not usable yet".
  - The maintainer has posted nothing since 2016.
  - Commenters say in Feb 2026 that PR #2209 (automatic backup files to a public folder, not sync) was "already merged but not released". In Aug 2026 a commenter says an earlier sync implementation was removed in commit da018fc. — [GitHub discussion #104](https://github.com/iSoron/uhabits/discussions/104)

**HabitNow** (Android-first)
- [PRIMARY] Privacy policy (undated):
  - "Our application offers an optional sign-in feature using your Google account." The e-mail is used "to associate your in-app purchases and cloud backup data with your specific Google account".
  - For non-premium users "your data is stored only on your device, and our team cannot access it".
  - Premium cloud backups are "stored securely in pseudonymous and obfuscated files on a third-party cloud service". "Cloud backups are an optional feature that has to be manually enabled".
  - "Your premium purchase is linked to your Google account."
  - Uses Google Analytics and Firebase Crashlytics. — [habitnow.app/privacy-policy](https://habitnow.app/privacy-policy)
- [PRIMARY] Play Data safety (developer "HabitNow Apps"):
  - E-mail: Optional, for app functionality and account management.
  - User IDs, app interactions, device IDs, crash logs and diagnostics: for analytics, not marked optional.
  - Calendar events: Optional. — [Play Data safety](https://play.google.com/store/apps/datasafety?id=com.habitnow)

**Way of Life** (Way of Life ApS)
- [PRIMARY]
  - No account or sign-in is described; only a passcode or biometric lock.
  - "Cloud backup is now free for everyone", "Back up to your preferred cloud storage provider"; "Backup & Restore is now free for all users" (4.3.0).
  - Export as CSV, Excel or JSON.
  - No sync. A developer reply (21 Mar) says "A major rewrite is happening right now, and sync+iPad are the biggies." A review says "I have tried everything to sync across devices. But, it never works."
  - Premium "simply unlocks unlimited habits"; subscriptions since 4.0.1 (05/03/2023).
  - Label: Data Not Linked to You, including Identifiers (User ID) for analytics and app functionality.
  - Version 4.6.0 (2 Oct). — [App Store US](https://apps.apple.com/us/app/way-of-life-habit-tracker/id393159800)

**Finch** (Finch Care PBC)
- [SEARCH] The help centre says:
  - All Finch data is local unless you have a Finch Account.
  - To create one, open Settings › Profile › Create Account, which "will automatically enable Cloud Backups".
  - "Having a Finch account enables Cloud Backups to keep your data safe, secure, and backed up to our servers. It's the best way to recover your Finch pet and progress in case you switch phones."
  - Login is by phone number or e-mail and password; one account per identifier.
  - "Deleting the app can result in data loss if you do not back up your data first." — [Finch help: Accounts and Cloud Backups](https://help.finchcare.com/hc/en-us/articles/41834952026381-Accounts-and-Cloud-Backups), [Finch help: Data Backup and Recovery](https://help.finchcare.com/hc/en-us/articles/37780313999757-Data-Backup-and-Recovery) (both returned 403 to the fetcher)
- [PRIMARY] iOS listing: version 3.73.240 ("4d ago").
  - Linked to You: Identifiers (User ID, Device ID) for analytics, personalisation and functionality, and User Content (Photos or Videos).
  - Not Linked: e-mail, purchases, usage, diagnostics.
  - The page says nothing about accounts. — [App Store US](https://apps.apple.com/us/app/finch-self-care-pet/id1528595748)

**Bearable** (symptom and mood tracker, account required)
- [PRIMARY] "Currently, we require you to create an account so that we can do the following things": restoring data after a (rare) loss, changing or updating the e-mail address, switching device. — [Bearable support: Why do I need to create an account?](https://bearable.app/support/common-questions/why-do-i-need-to-create-an-account/)
- [PRIMARY] "The most common cause of 'lost data' is that someone has attempted to log into their Bearable account" with the wrong method or e-mail. That creates a new empty account; support then identifies the right one. Data is encrypted and backed up on Google Cloud servers in the EU, and is restored at each sign-in. — [Bearable support: I've lost my data](https://bearable.app/support/troubleshooting/ive-lost-my-data/)
- [SEARCH] The privacy policy says creating the account is how explicit consent to store sensitive data is given. — [bearable.app/privacy](https://bearable.app/privacy)

**HabitKit** (Sebastian Röhl; local, RevenueCat)
- [PRIMARY] iOS listing:
  - "No account. No sign-up. No ads." "Your habit data stays on your device, and the app works completely offline."
  - 1.18.2: "Your habits now back up to iCloud once a day, so a new iPhone never means starting over" and "Setting up a new iPhone? HabitKit finds your backup and brings your habits back in one tap". 1.18.3 made it "more reliable".
  - Export and import are free.
  - Developer replies: in 2024 "currently working on a cross-device sync functionality"; in 2025 "cross-device sync are on the roadmap".
  - Reviews ask to "sync to iCloud … when you get a new device" and to "create our own account so we can sync progress across different devices".
  - Label: Linked to You, Purchases; Not Linked, Coarse Location, Usage and Advertising Data, Diagnostics.
  - Version 1.19.3 ("4d ago"). — [App Store US](https://apps.apple.com/us/app/id6443918070)
- [PRIMARY] The home page says "free for up to four habits". — [habitkit.app](https://www.habitkit.app/)
- [PRIMARY] Help FAQ (Nov 2026):
  - "HabitKit does not automatically sync changes between devices". New phone: restore an iCloud backup (iPhone to iPhone) or a Google Drive backup (Android to Android), or export and import a file.
  - Restore purchases: "confirm you are logged into the same App Store/Google Play account used for the purchase". If that fails, send support the receipt and the "RC ID" from Settings › General › Debug.
  - Cross-platform Pro: "There is currently no fully automatic cross-platform transfer flow … contact support and include the RC ID of your old and new device, and access can be transferred manually." — [habitkit.app/help](https://habitkit.app/help)

**How We Feel** (nonprofit)
- [PRIMARY] iOS listing:
  - "all of your data is kept on your device unless you opt-in to send an anonymized version of your check-ins to be used in research."
  - 1.17.6: "A reminder to sync your data to iCloud to save check-ins". 1.17.4 fixed iCloud Sync. 1.14.13 mentions "logging out of an account" and a data import file.
  - Label: Linked to You, Name, User ID, Other Data; Not Linked, E-mail, Diagnostics.
  - Version 1.17.16 (21 Oct). — [App Store US](https://apps.apple.com/us/app/how-we-feel/id1562706384)
- [PRIMARY] [2 Jul 2026] "Android users can now choose to back up their How We Feel data with Google Drive" to "restore their check-ins if they change devices, reinstall the app"; also "download a CSV of your data and import it into a new device". — [How We Feel Substack](https://howwefeel.substack.com/p/backed-up-tuned-in)
- [SEARCH] Release notes in other storefronts mention "create an account from Settings" and "sign-in with Google". — [App Store listings via search](https://apps.apple.com/app/id1562706384)

**Duolingo** (the reference for delayed sign-up)
- [PRIMARY, 17 Jul 2017, possibly outdated] Interview of Gina Gotthilf, then VP Growth:
  - "Simply moving the sign-up screen back a few steps led to about a 20% increase in DAUs."
  - Soft walls are "optional pages that ask users to sign up, but allow them to keep going by hitting 'Later'"; there were "three of those soft walls"; "there's a hard wall, after several lessons".
  - "without those soft walls priming a sign-up as they're ignored, those hard walls perform significantly worse".
  - The wall changes "have yielded an 8.2% increase in DAUs". — [First Round Review](https://review.firstround.com/the-tenets-of-a-b-testing-from-duolingos-master-growth-hacker)
- [PRIMARY] [2 Dec 2024] "Don't forget to create a profile to save your progress! This will also allow you to access your account on other devices." — [Duolingo blog](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo)

**Notion** (contrast: cloud, account required)
- [PRIMARY] "SYNCS WITH BROWSER, MAC, AND WINDOWS APPS." Label "Data Linked to You": e-mail, name, user content, user ID, usage data. Reviews: "you can't use Notion offline". — [App Store US](https://apps.apple.com/us/app/notion-notes-tasks-ai/id1232780281)
- [SEARCH] A third-party book says you cannot use the app without an account. — [Packt](https://subscription.packtpub.com/book/business-and-other/9781803232089/2/ch02lvl1sec04/creating-an-account)

**Pattern in the privacy labels** [INFERENCE from the listings above]: the device-only apps declare only "Data Not Linked to You" (Daylio, Streaks, Way of Life) or "Data Not Collected" (Pixels, Pixa), yet several still collect install-level analytics IDs (Daylio on Play, Way of Life's "User ID", HabitNow). The account apps declare "Linked to You" (Notion, Finch, How We Feel, HabitKit for purchases). Habitify declares only "Not Linked" despite accounts.

---

## B1. Data loss on uninstall or phone change (and whether OS backups protect a Flutter local database)

### Takeaway
On both platforms, uninstalling deletes the app's local files. The operating system normally carries those files to a **new phone of the same platform**, but only when the user has system backup on: iCloud Backup or a direct iPhone-to-iPhone transfer; Android Auto Backup (on by default for apps targeting API 23+, up to 25 MB, Google Drive) or a device-to-device transfer. Flutter's default database and documents folders sit inside the backed-up areas.

Device-only users still lose data when:
- they delete and reinstall on iOS without restoring a whole-device backup;
- iCloud Backup or Android backup is off, or never ran (Android backs up about once a day, on Wi-Fi, when idle);
- they move from Android to iOS or back. The OS route exists only from Android 16 QPR2, and only if the app opts in;
- they restore an Android backup onto an older Android version.

Keychain items surviving deletion is undocumented and Apple says not to rely on it. Every device-only app above documents a fallback ending in "probably lost". The support load from accounts is real too: Bearable and Habitify say the most common "lost data" case is signing into the wrong account.

### Cited Findings
- [DOCS] [1 May 2025] "iCloud Backup includes app data for the apps that you've downloaded on your device." Data an app keeps in iCloud Drive is stored in iCloud instead of the backup. — [Apple Support: What does iCloud back up?](https://support.apple.com/en-us/108770)
- [DOCS] By default iCloud Backup excludes only `/tmp` and `/Library/Caches`. Excluding other data is a hint ("not a mechanism to guarantee those items never appear in a backup or on a restored device"). Apple's advice: don't exclude user-created data, because "it might be difficult, even impossible, for the user to re-create them on a restored device". — [Apple: Optimizing your app's data for iCloud backup](https://developer.apple.com/documentation/foundation/optimizing-your-app-s-data-for-icloud-backup)
- [DOCS] [17 Nov 2026] Quick Start moves "your apps and data", either downloaded "from iCloud" in the background or "directly from your previous device". — [Apple Support: Quick Start](https://support.apple.com/en-us/102659)
- [DOCS] [14 Sep 2026] Apple's "Delete apps" page does not spell out what happens to local data. It links to "Learn how to delete app data from your iCloud backup", and says "If you delete an app, it doesn't automatically cancel in-app subscriptions". — [Apple Support: Delete apps](https://support.apple.com/en-us/ht207618)
- [SEARCH] Deleting an app "gets rid of the app and all its documents and data". — [Digital Trends](https://www.digitaltrends.com/phones/how-to-delete-apps-on-an-iphone/)
- [DOCS] Keychain after uninstall, from Quinn "The Eskimo!" (Apple DTS), Dec 2017:
  - "All versions of iOS prior to 10.3 beta preserve keychain items when an app is deleted … This was most definitely an implementation detail … Our keychain documentation has never specified what would happen in this case."
  - A 10.3 beta deleted them; that was rolled back. "iOS 11 introduced the DeviceCheck framework, which provides a forward path for one of the most common legitimate use cases".
  - "preserving keychain items on delete is an obvious privacy concern … I don't think it would surprise anyone if the 10.3 behaviour returned." — [Apple Developer Forums #36442](https://developer.apple.com/forums/thread/36442?answerId=281900022#281900022)
- [DOCS] Same engineer, June 2023, to a developer who wanted data to persist without accounts: "Yeah, don't rely on that." The alternatives he gives rely on the Apple ID: iCloud Keychain, the iCloud key-value store (`NSUbiquitousKeyValueStore`) and CloudKit. — [Apple Developer Forums #730924](https://developer.apple.com/forums/thread/730924)
- [DOCS] Android Auto Backup:
  - It "automatically backs up a user's data from apps that target and run on Android 6.0 (API level 23) or higher". Data goes to the user's Google Drive, end-to-end encrypted on Android 9+ with the screen-lock secret. Each app gets up to 25 MB.
  - Included by default: shared preferences, `getFilesDir()` / `getDir()`, `getDatabasePath()`, `getExternalFilesDir()`. Excluded: cache, code cache and no-backup folders.
  - Only the most recent backup is kept. Above 25 MB nothing is backed up.
  - Backups run only if "the user has enabled backup on the device", 24 h have passed, the device is idle and on Wi-Fi. "a device might never back up".
  - "Data is restored whenever the app is installed, whether from the Play Store, during device setup … or by running adb install."
  - `allowBackup` defaults to true. For apps targeting API 31+, `allowBackup="false"` may still allow device-to-device transfer on some manufacturers' devices.
  - From **Android 16 QPR2** the `<cross-platform-transfer platform="ios">` rules let an app opt in to transfers to iOS, given the iOS bundleId and teamId.
  - Google advises excluding per-install identifiers such as FCM registration tokens from backup. — [Android: Back up user data with Auto Backup](https://developer.android.com/identity/data/autobackup)
- Conflict: Loop's maintainer wrote in 2020 that "uninstalling the app will delete all your data, in addition to all the backups stored in the cloud" ([#689](https://github.com/iSoron/uhabits/discussions/689)) [PRIMARY]. Google's current doc says restore happens on every install. Daylio (Jan 2025) says that on reinstall you can restore what was backed up to the Google account with "Automatic restore" on ([Daylio FAQ](https://daylio.net/faq/?p=5760)) [PRIMARY]. Not resolved. Test on a real device.
- [DOCS] Flutter storage locations:
  - sqflite's default database path is "typically `data/data/<package_name>/databases`" on Android and "the Documents directory" on iOS. — [sqflite getDatabasesPath](https://pub.dev/documentation/sqflite/latest/sqflite/getDatabasesPath.html)
  - `getApplicationDocumentsDirectory` maps to `NSDocumentDirectory` on iOS and to "The Flutter engine's `PathUtils.getDataDirectory` API on Android". — [path_provider](https://pub.dev/documentation/path_provider/latest/path_provider/getApplicationDocumentsDirectory.html)
- [INFERENCE] A Flutter local database in either default location is therefore inside iCloud Backup on iOS and inside Auto Backup on Android, unless the app opts out. Check the Android manifest's `allowBackup` and `dataExtractionRules` and the 25 MB cap. A year of pixels is tiny, so the cap only matters for photos or attachments. The OS protects the "new phone of the same platform with backup on" case. It does not protect "deleted the app to fix a bug", "backup off", or "switched platform".
- [PRIMARY] Support material in device-only apps: Daylio's "Missing entries" article ends with "your data will probably be lost" ([Daylio FAQ](https://daylio.net/faq/?p=5760)). Finch's help says deleting the app without a backup "can result in data loss" [SEARCH] ([Finch help](https://help.finchcare.com/hc/en-us/articles/37780313999757-Data-Backup-and-Recovery)).
- [SEARCH] Finch's status page: "apologize for any lost progress you might be experiencing … we can't guarantee it". Trustpilot users report that after a reinstall or reset their e-mail "isn't connected to any account", and that support restored only some items. — [Finch App Status](https://help.finchcare.com/hc/en-us/articles/38284234302989-Finch-App-Status), [Trustpilot](https://www.trustpilot.com/review/finchcare.com)
- [VENDOR] [24 Aug 2026] Appbot analysed 40,294 Finch reviews (7 Aug 2025 to 6 Aug 2026; 1,600 read closely, 1,200 of them negative or mixed). It found "28 reviews explicitly describing lost progress, birds or accounts". One cited one-star review lost a two-year streak after being "suddenly logged out", so this is account-side loss, not device-only. — [Appbot blog](https://appbot.co/blog/finch-app-reviews-emotional-attachment-user-retention-product-loyalty/)
- [PRIMARY] Account apps carry their own loss tickets. Bearable: "The most common cause of 'lost data'" is signing in with the wrong method or e-mail ([Bearable](https://bearable.app/support/troubleshooting/ive-lost-my-data/)). Habitify: signing in with a different method creates a second empty account, the most common reason data doesn't appear ([Habitify](https://intercom.help/habitify-app/en/articles/9344497-log-into-your-account-on-multiple-platforms-devices)).
- [PRIMARY] Demand signal: HabitKit reviews ask for sync "to make it easy when you get a new device". HabitKit's answer was a daily iCloud backup, not an account ("a new iPhone never means starting over"). — [App Store US](https://apps.apple.com/us/app/id6443918070)
- [INFERENCE] None of the App Store review excerpts I could see mention lost data, so I have no count of one-star "lost everything" reviews for the device-only apps. The best quantified figure is Appbot's 28 for Finch, which mixes causes.

---

## B2. Enforcing a free limit and showing ads without an account; abuse

### Takeaway
A free limit (3 trackers) can be enforced locally. Reinstalling to reset it is self-defeating in a device-only mode, because the reinstall wipes the trackers too, and an OS restore brings back both the trackers and the count. Premium without an account works through the store account and RevenueCat anonymous IDs. Its limits are documented: no automatic cross-platform entitlement, a new anonymous ID after reinstall (purchases come back through restore), and aliasing or transfer rules when the user later logs in. AdMob consent (UMP) is handled per device and per install and has nothing to do with accounts, so a guest mode changes nothing there. The real abuse surface appears only if guests get server-side rows (anonymous auth): database bloat and bots, which Supabase and Firebase handle with CAPTCHA, IP rate limits and manual cleanup. To remember something about a device across reinstalls on iOS, the supported tool is DeviceCheck (two bits per device), not the keychain.

### Cited Findings
- [DOCS] RevenueCat anonymous IDs. The SDK will "generate a new random App User ID (prefixed with `$RCAnonymousID:`) for you, and will cache it on the device". When that cache is cleared, "a new random anonymous App User ID will be generated". "Anonymous App User IDs are **not** able to share subscription status across apps and platforms."
- [DOCS] RevenueCat logging in. Calling `logIn` "may alias the anonymous App User ID to the provided custom App User ID", with "CustomerInfo merged". There is an exception: if the provided ID already has an anonymous alias, "No merge or purchase transfer occurs". In webhooks after logIn, "`original_app_user_id` will be the anonymous id and `app_user_id` will be the provided id".
- [DOCS] RevenueCat guidance and warnings. "We strongly recommend revealing the App User ID to your customers somewhere within your app." Hard-coded IDs mean "every install will be treated as the same user". Don't use e-mail addresses as IDs (guessability and GDPR). — [RevenueCat: Identifying customers](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] RevenueCat restore behaviour. The default is **"Transfer to new App User ID"** ("UserB would now have access to the subscription and it would be revoked from UserA"). Purchases owned by an anonymous ID are always aliased: "the anonymous identifiers will be merged (aliased) into the same customer profile". — [RevenueCat: Restore behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] App Review 3.1.1: "you should make sure you have a restore mechanism for any restorable in-app purchases." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [PRIMARY] In practice: Daylio restores per store and has no cross-platform path ([Daylio](https://daylio.net/faq/docs/daylio-faq/tutorials/moving-daylio-to-new-phone/)). HabitKit transfers Pro across platforms by hand from the two "RC ID"s ([HabitKit help](https://habitkit.app/help)).
- [DOCS] DeviceCheck lets a server "set and query two binary digits of data per device, while maintaining user privacy. For example, you might use this data to identify devices that have already taken advantage of a promotional offer … or to flag a device that you've determined to be fraudulent." — [Apple DeviceCheck](https://developer.apple.com/documentation/devicecheck)
- [DOCS] Keychain persistence across deletion is undocumented and "don't rely on that" (see B1). — [Forums #730924](https://developer.apple.com/forums/thread/730924)
- [DOCS] AdMob UMP SDK (Flutter): "You should request an update of the user's consent information at every app launch". It offers a privacy-options entry point so users can "manage their privacy options at any time". The page never mentions user accounts. — [Google: Flutter privacy / UMP](https://developers.google.com/admob/flutter/privacy)
- [INFERENCE] UMP consent is therefore per install and device, not per account. Guest mode leaves the AdMob and UMP flow as it is. Only the "is premium, hide ads" decision must come from the locally cached RevenueCat entitlement instead of from the developer's account record.
- [DOCS] Supabase anonymous sign-ins:
  - The user "can't access their account if they sign out, clear browsing data, or use another device".
  - Bad actors could inflate the database, so it is "strongly recommended to enable invisible CAPTCHA or Cloudflare Turnstile". A default limit of 30 requests per hour per IP applies.
  - "Automatic cleanup of anonymous users is currently not available"; the page gives SQL that deletes anonymous users older than 30 days. — [Supabase: Anonymous sign-ins](https://supabase.com/docs/guides/auth/auth-anonymous)
- [DOCS] Firebase "limits the number of new email/password and anonymous sign-ups" from one IP in a short period. Once linked, the new account "can access the anonymous account's Firebase data". — [Firebase: anonymous auth (Flutter)](https://firebase.google.com/docs/auth/flutter/anonymous-auth)
- [INFERENCE] Two designs:
  - **Pure local guest** (nothing on the server until sign-up): no server abuse surface, and the limit bypass costs the user their data. Several guests on one phone means reinstalling, which wipes the previous guest.
  - **Server-side anonymous account**: brings back sync and backup for guests, but also brings bots, cleanup jobs, CAPTCHA, and the anonymous-to-real merge (B5).
  - Free-trial re-use is governed by store eligibility rules, not by the app's account. Not verified in this pass; see Gaps.

---

## B3. Measuring how many people use the app without an account (EU rules)

### Takeaway
Under the EDPB's 2024 reading, Article 5(3) ePrivacy covers mobile apps. It applies whether or not the information is personal data. An app that generates an identifier, keeps it on the phone and sends it to its own API is "gaining access". So a random install ID sent to the developer's server needs consent unless an exemption applies.

In France the CNIL's consent-exempt audience measurement explicitly names applications. Its conditions:
- the purpose is strictly limited to audience measurement of that one app;
- it produces anonymous statistics only;
- no cross-referencing with other processing;
- no global tracking of the person's browsing;
- recommended tracker lifetime of 13 months and data retention of 25 months, with users informed.

The UK now has a comparable "statistical purposes" exception (an opt-out must be offered).

Under the GDPR, the developer that receives the random ID together with IP address and timestamps is very likely holding pseudonymous personal data. Recital 30 names online identifiers from "applications", and the CJEU in *EDPS v SRB* (2025) judges identifiability from the controller's side. Without any consent or in-app code, the stores give aggregates: App Store Connect (opt-in sample: sessions, active devices, deletions) and Play Console (DAU, rolling-28-day MAU, installed audience, user loss).

### Cited Findings
- [REGULATOR] Article 5(3) wording, as quoted by the EDPB: storage or access "is only allowed on the basis of consent or necessity for specific purposes". Exemption: "This shall not prevent any technical storage or access for the sole purpose of carrying out the transmission of a communication over an electronic communications network, or as strictly necessary in order for the provider of an information society service explicitly requested by the subscriber or user to provide the service." — [EDPB Guidelines 2/2023, v2.0, adopted 7 Oct 2024, §1 and fn. 4](https://www.edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf)
- [REGULATOR] Same guidelines:
  - §6: "the term used is not 'personal data', but 'information'".
  - §12: "the notion of information includes both non-personal data and personal data, regardless of how this data was stored and by whom".
  - §17: terminal equipment includes "smartphones".
  - §33: "That is equally the case when the accessing entity distributes software on the terminal equipment of the user that is stored and will then proactively call an Application Programming Interface ('API') endpoint over the network … Such access clearly falls within the scope of Article 5(3)".
  - §34: an SDK that makes the device send stored information "triggers the applicability of Article 5(3)".
  - §44: local apps using information "strictly inside the terminal" are not accessing it "as long as the information does not leave the device, but when this information or any derivation of this information is accessed, Article 5(3) ePD would apply".
  - §63: "In the context of 'unique identifier' collection on websites or mobile applications … a 'gaining of access' is taking place and Article 5(3) ePD applies".
  - §4, §40 and §56: the guidelines do not analyse the exemptions, and "the applicability of this article does not systematically mean that consent needs to be collected". — [EDPB Guidelines 2/2023](https://www.edpb.europa.eu/system/files/2024-10/edpb_guidelines_202302_technical_scope_art_53_eprivacydirective_v2_en_0.pdf)
- [REGULATOR] [4 Jul 2025] CNIL (art. 82 of the French data protection law). To be exempt, audience-measurement trackers must have a purpose "strictement limitée à la seule mesure de l'audience du site ou de l'application" (strictly limited to measuring the audience of the site or the application) and must "servir à produire des données statistiques anonymes uniquement" (serve only to produce anonymous statistics). They must not "conduire à un recoupement des données avec d'autres traitements" (lead to the data being cross-referenced with other processing) nor "permettre le suivi global de la navigation de la personne" (allow global tracking of the person's browsing). Recommendations: tracker lifetime of 13 months without automatic extension, retention of 25 months at most, and information in "la politique de confidentialité du site ou de l'application mobile" (the privacy policy of the site or mobile app). SDKs are not mentioned. — [CNIL: solutions pour la mesure d'audience](https://www.cnil.fr/fr/cookies-solutions-pour-les-outils-de-mesure-daudience)
- [REGULATOR] [11 Jun 2020] CNIL Sheet 16 (in English) lists these conditions: inform users; let them object; purposes limited to "audience measurement; A/B testing"; no cross-checking with other processing; "limit the scope of the tracer to a single site or application editor"; truncate the last byte of the IP address; tracker lifetime of 13 months. It frames the tools as measuring "a website or mobile application". — [CNIL Sheet n°16](https://www.cnil.fr/en/sheet-ndeg16-use-analytics-your-websites-and-applications)
- [REGULATOR] [24 Sep 2024, updated 8 Apr 2025] CNIL mobile app recommendations: apps "doivent obtenir le consentement pour traiter des données qui ne sont pas nécessaires à leur fonctionnement" (must obtain consent to process data not needed for them to work), e.g. ad targeting. The press page does not discuss the audience-measurement exemption in apps. — [CNIL: applications mobiles](https://cnil.fr/fr/applications-mobiles-la-cnil-publie-ses-recommandations-pour-mieux-proteger-la-vie-privee)
- [SEARCH] The CNIL published a self-assessment tool for the audience-measurement exemption in July 2025. — [CNIL PDF](https://cnil.fr/sites/default/files/2025-07/outil_d_auto-evaluation_mesure_d_audience.pdf)
- [REGULATOR] ICO (UK), "statistical purposes" exception, page undated:
  - It applies when "the sole purpose" is collecting statistical information about use of the service "with a view to making improvements". The output must be "aggregate statistical information that you cannot use to identify people".
  - You must give "clear and comprehensive information" and "a 'simple and free' means to object".
  - An information society service is "such as a website or an app".
  - A third-party provider is allowed but "must be a processor, not a joint controller".
  - It "does not allow you to monitor or track individual visitors to your service"; profiling, advertising and linking with other data need consent. — [ICO: What are the exceptions?](https://ico.org.uk/for-organisations/direct-marketing-and-privacy-and-electronic-communications/guidance-on-the-use-of-storage-and-access-technologies/what-are-the-exceptions/)
- [SEARCH] The Data (Use and Access) Act 2025 exceptions came into force in February 2026. The ICO's final storage-and-access guidance was published on 29 Apr 2026. — [Hunton](https://www.hunton.com/privacy-and-cybersecurity-law-blog/uk-ico-publishes-guidance-on-storage-and-access-technologies)
- [REGULATOR] GDPR Recital 30: "Natural persons may be associated with online identifiers provided by their devices, applications, tools and protocols, such as internet protocol addresses, cookie identifiers or other identifiers … when combined with unique identifiers and other information received by the servers, may be used to create profiles of the natural persons and identify them." — [GDPR Recital 30](https://gdpr-info.eu/recitals/no-30/)
- [COMMENTARY quoting the judgment] CJEU, *EDPS v SRB*, C-413/23 P, 4 Sep 2025:
  - "pseudonymised data must not be regarded as constituting, in all cases and for every person, personal data" (para 86).
  - Identifiability "must be assessed at the time of collection of the data and from the point of view of the controller" (para 111). — [Covington, Inside Privacy](https://www.insideprivacy.com/eu-data-protection/eu-court-of-justice-clarifies-the-concept-of-personal-data-in-the-context-of-a-transfer-of-pseudonymized-data-to-third-parties/)
- [DOCS] App Store Connect. Usage metrics: Installations, Sessions ("used for at least two seconds"), Active Devices, Active Last 30 Days, Deletions (iOS 12.3+, excluding device resets), Crashes. "App usage data is collected only from users who have agreed to share diagnostics and usage information with app developers"; an opt-in-rate history shows the sample size. — [App Store Connect Analytics: App usage](https://developer.apple.com/help/app-store-connect-analytics/engagement/app-usage)
- [DOCS] Play Console:
  - DAU: "The number of users who opened your app on a given day".
  - MAU: "The number of users who opened your app in a rolling 28-day period".
  - Installed audience, user acquisitions, and user loss ("uninstalled your app from all of their devices").
  - Some metrics come from users who "agreed to share their data with developers in aggregate"; Play adjusts for opt-outs. — [Play Console Help: statistics](https://support.google.com/googleplay/android-developer/answer/139628?hl=en)
- [PRIMARY] Device-only apps do measure usage. Daylio's Play listing declares device IDs and app interactions for analytics, marked "Optional" ([Play](https://play.google.com/store/apps/datasafety?id=net.daylio&hl=en)). Way of Life's iOS label declares "Identifiers (User ID)" for analytics, as Not Linked ([App Store](https://apps.apple.com/us/app/way-of-life-habit-tracker/id393159800)).
- [INFERENCE] For a device-only user, the options in order of legal simplicity:
  - **(1) Store aggregates only.** No in-app code and no consent, because the developer neither stores nor reads anything on the device. But Apple's numbers are an opt-in sample and Play's are modelled.
  - **(2) A first-party, self-hosted counter under the CNIL exemption.** A random install ID stored locally, sent to the developer's own server only to count active installs. Conditions: no IP kept beyond truncation, aggregated output, retention of 25 months at most, information in the privacy policy, an opt-out switch, and **never joined to the account if the user signs up later**. Joining would be the "recoupement" (cross-referencing) the CNIL excludes. That ID is still pseudonymous personal data for the developer under GDPR: legitimate interest, privacy-policy entry, register of processing.
  - **(3) Consent through the existing UMP/consent flow.** Anything beyond (2): funnels per user, joins with RevenueCat or AdMob data, third-party analytics that reuse data.
  - Sending even a "ping" with no ID is still access under EDPB §43–44. What makes it lawful without consent is the exemption, not the absence of an ID.

---

## B4. Features that need an identity on the server (and those that don't)

### Takeaway
Sync between devices, a web version, account recovery and e-mail changes, and server-side push all need a server-side identity. So does a durable link between a purchase and a person across platforms. Local reminders, export and import files, the free limit and premium on one platform do not. RevenueCat works with anonymous IDs but sends the server webhooks keyed by those IDs, so the backend must accept events for users who have no account row and reconcile them through `aliases` and `original_app_user_id` at sign-up.

App Review 5.1.1(v) tilts the other way: an app without "significant account-based features" must let people use it without a login. Today's forced sign-up rests on sync being significant enough.

### Cited Findings
- [PRIMARY] Sync: Habitify's guest data "will not sync" ([Habitify](https://intercom.help/habitify-app/en/articles/9344497-log-into-your-account-on-multiple-platforms-devices)). HabitKit "does not automatically sync" ([HabitKit](https://habitkit.app/help)). Streaks gets sync from the user's own iCloud account instead of a developer account ([Streaks](https://apps.apple.com/us/app/streaks/id963034692)).
- [SEARCH] Web: Habitify's web version requires sign-up with Google or Apple; no guest option. — [Habitify help](https://intercom.help/habitify-app/en/articles/8359911-sign-up-for-a-habitify-account)
- [PRIMARY] Account recovery and support: Bearable's reasons for accounts are restoring data, "Changing or updating your email address" and "Switching the device" ([Bearable](https://bearable.app/support/common-questions/why-do-i-need-to-create-an-account/)). Without accounts, HabitKit's support works from the RevenueCat ID shown in Settings › Debug ([HabitKit](https://habitkit.app/help)).
- [DOCS] RevenueCat: "We strongly recommend revealing the App User ID to your customers somewhere within your app." — [RevenueCat](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] Reminders: local notifications are scheduled by the app and "The system handles delivery of notifications based on a time or location that you specify". The framework covers both "Push user-facing notifications to the user's device from a server, or generate them locally from your app". — [Apple: Scheduling a notification locally](https://developer.apple.com/documentation/usernotifications/scheduling-a-notification-locally-from-your-app)
- [DOCS] Android: FCM registration tokens are per install and should be excluded from backup. — [Android Auto Backup](https://developer.android.com/identity/data/autobackup)
- [INFERENCE] Planned local reminders need no identity. Server push would need a per-install token, which is itself an identifier on the server.
- [PRIMARY] Export and import can be fully local: Daylio (PDF, CSV, backup file), Loop (CSV, SQLite), Way of Life (CSV, Excel, JSON), HabitKit, How We Feel (CSV import on a new device). Sources in section A.
- [DOCS] RevenueCat webhooks: after logIn, `original_app_user_id` is the anonymous ID and `app_user_id` the provided one. "When a merge of customers occurs, there will be only one App User ID within the `original_app_user_id` field … the other App User IDs … within an array in the `aliases` field." — [RevenueCat](https://www.revenuecat.com/docs/customers/identifying-customers)
- [INFERENCE] A webhook keyed today by account ID would, in guest mode, receive `$RCAnonymousID:` events with no matching account. Either store entitlements keyed by RevenueCat ID, or skip such events and re-fetch CustomerInfo at sign-up.
- [DOCS] App Review 5.1.1(v): "If your app doesn't include significant account-based features, let people use it without a login. If your app supports account creation, you must also offer account deletion within the app. Apps may not require users to enter personal information to function, except when directly relevant to the core functionality of the app or required by law." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

---

## B5. Cost of maintaining two modes (guest/local and account/synced)

### Takeaway
I found no quantified write-up (hours, bug counts, % of tickets) of running a guest mode beside an account mode. The evidence is qualitative but consistent:
- Sync and merge code is "difficult to write correctly".
- The anonymous-to-real conversion needs an explicit conflict policy, and fails when the e-mail already has an account.
- Identity merges in purchase SDKs have edge cases where "No merge or purchase transfer occurs".
- Migrations must stay runnable from every shipped version, because old clients can't be forced to update.
- Wrong-sign-in support tickets persist either way.

The one-developer apps in the set show the cost from the other direction. Loop (sync prototyped in 2016, never shipped), HabitKit (sync "currently working on" in 2024, still "on the roadmap") and Way of Life ("major rewrite … sync+iPad") struggle to *add* sync to a local-only app. The product starts from the opposite end, already server-first with sync, so the added work is a local source of truth before sign-up plus a one-time upload and merge at sign-up.

### Cited Findings
- [COMMENTARY] [Apr 2019, Kleppmann, Wiggins, van Hardenberg, McGranaghan] "We have seen multiple app development teams writing their own ad-hoc diffing, merging, and conflict resolution algorithms … the resulting data sync solutions are often unreliable and brittle." "This conflict resolution code is difficult to write correctly". "it has been difficult to retrofit offline support to cloud apps". Also: "With data ownership comes responsibility: maintaining backups or other preventative measures against data loss". — [Ink & Switch: Local-first software](https://www.inkandswitch.com/essay/local-first/)
- [DOCS] Supabase: "Data conflicts can arise when an anonymous user is converted to a permanent user". You choose between overwriting with the existing account's data, overwriting with the anonymous data, or merging. If the e-mail already belongs to a user, the update fails: sign in to that account and reassign the anonymous records. — [Supabase](https://supabase.com/docs/guides/auth/auth-anonymous)
- [SEARCH] FirebaseUI issue: migrate before switching accounts, because "if the data migration fails for whatever reason, we would not be able to revert to the anonymous user". — [FirebaseUI-iOS #851](https://github.com/firebase/FirebaseUI-iOS/issues/851)
- [DOCS] RevenueCat merge exception: "No merge or purchase transfer occurs" when the provided ID already has an anonymous alias. — [RevenueCat](https://www.revenuecat.com/docs/customers/identifying-customers)
- [SEARCH] A RevenueCat community thread is titled "users often lose subscription when logging into an existing account". A support answer says a new anonymous purchase won't transfer on `logIn()`, only on restore, purchase or sync. — [RevenueCat community](https://community.revenuecat.com/sdks-51/users-often-lose-subscription-when-logging-into-an-existing-account-2510)
- [SEARCH] WatermelonDB: "You MUST NOT delete old migrations, otherwise it's possible that the app is permanently unable to sync". Convex: "Reasoning about large sets of clients on different versions where the developer can't force them to update is hard." — [WatermelonDB sync docs](https://unpkg.com/@nozbe/watermelondb@0.22.0/docs/Implementation/SyncImpl.html), [Convex: object sync engine](https://stack.convex.dev/object-sync-engine)
- [PRIMARY] Bearable and Habitify both name wrong-method sign-in, which creates an empty second account, as their top "lost data" ticket (B1). An account mode carries that support load whether or not a guest mode exists.
- [PRIMARY] Solo developers adding sync to local apps:
  - Loop: an opt-in sync spec and a "not usable yet" Node backend in 2016, nothing shipped since ([#104](https://github.com/iSoron/uhabits/discussions/104)).
  - HabitKit: "currently working on a cross-device sync functionality" (2024), "on the roadmap" (2025), "does not automatically sync" (Nov 2026) ([App Store](https://apps.apple.com/us/app/id6443918070), [help](https://habitkit.app/help)).
  - Way of Life: "A major rewrite is happening right now, and sync+iPad are the biggies" ([App Store](https://apps.apple.com/us/app/way-of-life-habit-tracker/id393159800)).
- [INFERENCE] What a guest mode adds to a server-first app:
  - a local database that is the source of truth before sign-up, with its own schema migrations;
  - a one-shot upload at sign-up, idempotent and safe to retry, with a conflict rule for "signs into an account that already has trackers";
  - RevenueCat `logIn` aliasing, and webhooks for anonymous IDs;
  - analytics that must not join guest and account IDs (B3);
  - double test paths for every feature that touches data: guest, account, and guest-to-account transition, on two platforms;
  - copy and settings for the "you are not backed up" state.
  If the account mode keeps its own on-device cache, the cheaper design is one local store for everyone, with "account" meaning "this store also syncs". Guest and account then differ only by whether sync is on, not by two data paths.

---

## B6. Prompts that convert guests into accounts

### Takeaway
The apps ask for an account with backup arguments ("save your data", "never lose", "new phone"), and secondarily with multi-device and web access. Placements found:
- Duolingo: dismissable soft walls after first value, then a hard wall.
- Habitify: a link prompt in the guest profile.
- How We Feel: a release-note-driven reminder to turn on iCloud sync.
- Pixels: developer replies to reviews.
- Finch: the account sold as the only automatic backup.
- Daylio: a notification after repeated failed backups.

Only Duolingo has published numbers, and they are from 2017: +20% DAU from moving sign-up later, then +8.2% DAU from the soft/hard-wall changes. I found no app that asks for an account at purchase, nor any published guest-to-account conversion rate for a tracker app.

### Cited Findings
- [PRIMARY] [2017] Duolingo: sign-up moved later gave "about a 20% increase in DAUs". Soft walls ("Later" button), three of them, then "a hard wall, after several lessons". Hard walls without soft walls "perform significantly worse". The wall changes gave "an 8.2% increase in DAUs". Advice: find the point where users have felt the value and "try a soft wall right after it". — [First Round Review](https://review.firstround.com/the-tenets-of-a-b-testing-from-duolingos-master-growth-hacker)
- [PRIMARY] [2024] Duolingo: "Don't forget to create a profile to save your progress! This will also allow you to access your account on other devices." — [Duolingo blog](https://blog.duolingo.com/duolingo-101-how-to-learn-a-language-on-duolingo)
- [PRIMARY] Habitify: "To save your data and never lose your account, you can link your guest account". The link lives under Settings › profile › "Create Account". — [Habitify help](https://intercom.help/habitify-app/en/articles/9342753-link-a-guest-account-with-email-password)
- [PRIMARY] How We Feel 1.17.6: "A reminder to sync your data to iCloud to save check-ins". — [App Store](https://apps.apple.com/us/app/how-we-feel/id1562706384)
- [PRIMARY] Pixels developer reply to a review: "Don't forget to backup your data with a free Pixels Cloud account!" — [App Store](https://apps.apple.com/app/id1668460700)
- [SEARCH] Finch: an account "enables Cloud Backups … It's the best way to recover your Finch pet and progress in case you switch phones". — [Finch help](https://help.finchcare.com/hc/en-us/articles/41834952026381-Accounts-and-Cloud-Backups)
- [PRIMARY] Daylio: after several failed automatic backups, the app notifies the user and asks for a manual backup. — [Daylio FAQ](https://daylio.net/faq/docs/daylio-faq/backup/are-my-data-backed-up/)
- [PRIMARY] HabitKit answers the same need without an account: "Your habits now back up to iCloud once a day, so a new iPhone never means starting over." — [App Store](https://apps.apple.com/us/app/id6443918070)
- [VENDOR]/[SEARCH] The only "guest vs registered" figures found come from e-commerce checkout vendors, and they conflict: registered 64% vs guest 52% in one, 60–90% vs 35–45% unsourced in another, and 19–24% abandonment when forced to register. They are not transferable to a free tracker app. — [Corbado](https://www.corbado.com/blog/guest-checkout-vs-forced-login), [Krepling](https://pay.krepling.com/guest-checkout-vs-account-which-strategy-converts-more-customers-in-2026/), [Glued](https://insights.getglued.co/checkout-optimization/guest-checkout-vs-account-creation/)
- [INFERENCE] Placements fitting a 3-tracker, daily-entry app, by analogy with the above:
  - a soft prompt after the first few days of entries ("back up your N days");
  - a prompt at the first premium purchase or restore ("keep premium on all your devices");
  - a prompt at the second device or a web visit;
  - a passive "not backed up" badge in Settings.
  None of these has published numbers. Measure them with the B3-compliant counter, or with store cohorts.

---

## Gaps / could not verify
- **User reviews of lost data.** Reddit was not searched. The App Store pages show only a few reviews, and none mention data loss. Play reviews could not be rendered. The only count is Appbot's 28 Finch reviews (mixed causes). I found no count of one-star "lost everything" reviews for Daylio, Streaks, Loop or HabitKit.
- **Finch.** The help centre and Mozilla's review returned 403, so all Finch account facts are [SEARCH]. Premium without an account was not verified.
- **Pixa** (is the account required?), **Pixels Cloud** details (what is synced, restore of purchases, cross-platform), and **Habitify guests** (can a guest buy premium; what happens to a guest purchase at linking): not documented in the pages read.
- **HabitNow on iOS** and its sync, and the **Loop** latest release and date: not checked.
- **Reflectly and Moodnotes**: not covered. Reflectly's label lists e-mail, name and user ID for app functionality, which suggests accounts, but the listing says nothing explicit.
- **Uninstall and Android cloud backup**: Loop's maintainer (2020) says uninstall deletes the cloud backups. Google's doc says restore happens on every install. Not resolved; test on a device.
- **Share of users with iCloud Backup or Android backup on**: no source found. That share decides how many device-only users the OS actually protects.
- **Store trial eligibility** (whether an introductory offer or free trial can be re-used after reinstall or under a new app account): not verified here. Apple and Google tie eligibility to the store account, per my understanding, but I read no page confirming this.
- **Art. 5(3) wording**: EUR-Lex did not render, so the article is quoted via EDPB Guidelines 2/2023 (§1, fn. 4).
- **ICO pages**: undated. The February 2026 commencement and the 29 Apr 2026 final guidance are known from law-firm commentary only.
- **CNIL**: no CNIL text found that applies the audience-measurement exemption to a *self-hosted in-app counter with a random install ID* specifically. The 2025 page names "l'application" (the application) but not SDKs or install IDs.
- **No quantified cost** (dev time, bug rate, support share) of running guest and account modes side by side.
- **No published guest-to-account conversion rate** for a tracker or habit app; Duolingo's 2017 DAU figures are the only first-party numbers, and the current wall design may differ.
- **App Store dates are relative** ("4d ago"). Pages may change after 25 Nov 2026. Daylio FAQ (Dec 2024 / Jan 2025), Loop FAQ (2020), the Pixels privacy policy (Dec 2023) and the Duolingo interview (2017) may be outdated.
