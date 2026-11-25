# Purchases without an account (RevenueCat) and merging guest data into an account — mechanics, SDK guidance, real-app practice, as of November 2026

Scope: (A) how RevenueCat treats purchases made under an anonymous App User ID (creation, log-in, log-out, restore and transfer, lifetime purchases, webhooks, REST API), quoted from RevenueCat's own docs and staff answers; (B) how auth SDKs, Apple, Google and real apps handle a guest who signs in, especially to an account that already has data, with the merge strategies compared on a concrete "year in pixels" scenario. All pages read on 2026-11-25 unless marked [SEARCH]. RevenueCat doc pages show no "last updated" date; I read their current Markdown versions (the docs serve `.md` next to each page). purchases_flutter current version: 11.0.4 (pub.dev and the GitHub `main` pubspec).

Evidence labels: [DOCS] official platform, SDK or product documentation (including an app's own help centre describing its own behaviour) · [VENDOR] vendor advice with a commercial interest (RevenueCat blog, RevenueCat staff forum answers) · [PRIMARY] original record (incident, code change) · [COMMENTARY] practitioners and forum posters · [SEARCH] known only from a search snippet · [INFERENCE] my own reasoning.

---

## 1. RevenueCat anonymous App User IDs: creation, storage, reinstall, new device

### Takeaway
If the SDK is configured without an App User ID, RevenueCat creates a random `$RCAnonymousID:…` and caches it on the device (UserDefaults on iOS, SharedPreferences on Android). Deleting and reinstalling the app gives a new anonymous ID, and so does a new device. Anonymous IDs cannot share purchases across platforms (iOS ↔ Android). The only links between two anonymous IDs are a store restore (same Apple ID / Google account) or a later log-in. On Android, Auto Backup can bring the cached ID back, and RevenueCat recommends this.

### Cited Findings
- [DOCS] "By default, if you don't provide an App User ID when configuring the Purchases SDK, RevenueCat will generate a new random App User ID (prefixed with `$RCAnonymousID:`) for you, and will cache it on the device." — [RevenueCat: Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] "In the event that the user deletes and reinstalls the app, the cache will be cleared and a new random anonymous App User ID will be generated." — [same](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] "Anonymous App User IDs are **not** able to share subscription status across apps and platforms, but are suitable for many apps that don't require authentication and only support a single platform." — [same](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] Anonymous IDs "are generated when the SDK is first initialized" and also "created on `logOut()`". — [Customers in RevenueCat](https://www.revenuecat.com/docs/customers/user-ids); [Identifying Customers, Advanced Topics](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] Where it is cached: the iOS SDK's `DeviceCache` "Caches data in `UserDefaults`" and reads `_cachedAppUserID` from it. The Android SDK reads it from `SharedPreferences` under the key `"$apiKeyPrefix.new"`. — [purchases-ios DeviceCache.swift](https://github.com/RevenueCat/purchases-ios/blob/main/Sources/Caching/DeviceCache.swift); [purchases-android DeviceCache.kt](https://github.com/RevenueCat/purchases-android/blob/main/purchases/src/main/kotlin/com/revenuecat/purchases/common/caching/DeviceCache.kt)
- [DOCS] Android: RevenueCat recommends backing up its SharedPreferences file "so it is automatically restored when the user reinstalls the app and/or changes devices". Auto Backup is on by default up to 25 MB, but "these backups are not guaranteed to work across all devices". — [Restoring Purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [DOCS] Customers can have several IDs: "Customers may be referenced by multiple App User IDs, also known as aliases. Each grouping of App User IDs is considered to be a single customer in RevenueCat." — [Customers in RevenueCat](https://www.revenuecat.com/docs/customers/user-ids)
- [DOCS] RevenueCat "strongly recommend[s] revealing the App User ID to your customers somewhere within your app", e.g. in settings, for support. — [Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers)

### Inferences
- [INFERENCE] For a guest who never makes an account, the anonymous ID is the only key RevenueCat has. After a reinstall or on a new device, the purchase comes back only through Restore (same store account, §4). A cross-platform move (iPhone → Android) is impossible without an account.
- [INFERENCE] On iOS, UserDefaults are part of device backups. Restoring a whole iPhone from a backup may bring the old anonymous ID back. I did not verify this in Apple's docs (see Gaps).

---

## 2. `logIn()` from an anonymous user, the `created` flag, and `logOut()`

### Takeaway
`logIn(id)` from an anonymous ID **merges (aliases)** the anonymous customer into `id` if `id` is new, **or if `id` exists but has never absorbed an anonymous ID**. If `id` already has an anonymous alias, nothing is merged: the anonymous purchases stay behind on the anonymous ID. RevenueCat staff (June 2026): "login never moves a purchase. That only happens on restore, purchase, or sync." `created` only says whether `id` was new in RevenueCat. `logOut()` makes a fresh anonymous ID and returns an error if the current user is already anonymous.

### Cited Findings
- [DOCS] "If the logged in identity does not already exist in RevenueCat, it will be created automatically. This flow will generate an anonymous App User ID for the user first, then may (*see below*) alias the anonymous App User ID to the provided custom App User ID. In this case if you integrated webhooks, `original_app_user_id` will be the anonymous id and `app_user_id` will be the provided id." — [Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] The alias table, verbatim:

  | Current App User ID | Provided ID already exists? | Provided ID already has an anonymous alias? | Result |
  |---|---|---|---|
  | Anonymous | No | N/A | "Anonymous ID and Provided ID have CustomerInfo merged." |
  | Anonymous | Yes | No | "Anonymous ID and Provided ID have CustomerInfo merged." |
  | Anonymous | Yes | Yes | "Current User ID is logged out, Provided User ID is logged in. No merge or purchase transfer occurs." |
  | Non-anonymous | Any | Any | "Current User ID is logged out, Provided User ID is logged in. No merge or purchase transfer occurs." |

  — [Identifying Customers, "`logIn()` method alias behavior"](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] After a merge: "Looking up any of the merged App User IDs in RevenueCat will return the same `CustomerInfo`, customer history, customer attributes, subscription status, etc." Webhooks list the other IDs "within an array in the `aliases` field". — [same, "Aliases"](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] `created`: the iOS SDK returns "a `Bool` specifying whether the user was created for the first time in the RevenueCat backend". purchases_flutter: "LogInResult holds a [CustomerInfo] object and a bool that can be used to know if a user has just been created for the first time." — [purchases-ios PurchasesType.swift](https://github.com/RevenueCat/purchases-ios/blob/main/Sources/Purchasing/Purchases/PurchasesType.swift); [purchases_flutter `logIn`](https://pub.dev/documentation/purchases_flutter/latest/purchases_flutter/Purchases/logIn.html)
- [DOCS] `logOut()`: "Logs out the Purchases client, clearing the saved appUserID. This will generate a random user id and save it in the cache." It throws "if the method is called while the current user is anonymous". Switching between two known IDs: "it's okay to call the `.logIn()` method directly - you do not need to call `logOut()` first." — [purchases_flutter source](https://github.com/RevenueCat/purchases-flutter/blob/main/lib/purchases_flutter.dart); [Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers)
- [DOCS] Warning from the docs: "Depending on the application's transfer behavior, a provided user's subscription may be transferred to an anonymous ID - which can only be brought back through a restore on the original purchase platform." — [Identifying Customers, Advanced Topics](https://www.revenuecat.com/docs/customers/identifying-customers)
- [VENDOR] RevenueCat staff (Guilherme, Developer Support Engineer, 4 Jun 2026, best answer). Case: a React Native app that recently allowed anonymous purchases. A second anonymous purchase did not follow `logIn()` into an account that already had an earlier anonymous alias. Staff: "login never moves a purchase. That only happens on restore, purchase, or sync." Login-time aliasing is "effectively one-time per account". Fixes: a user-initiated Restore with "Transfer to new App User ID". For background handling, call `syncPurchases()` "right after the first login when the user has no active entitlement, not on every launch". Deleting the customer in the dashboard "won't fix it". — [community.revenuecat.com #7706](https://community.revenuecat.com/sdks-51/login-not-aliasing-anonymous-id-when-account-already-has-a-prior-alias-is-this-expected-7706)
- [DOCS] New and still in **private beta**: RevenueCat "Authentication", where the SDK receives an ID token instead of an App User ID. Its merge rule differs from `logIn()`: "An existing Customer signs in. RevenueCat finds the existing Customer with that identity and merges the two Customers. RevenueCat keeps the older Customer, and the purchases of both Customers stay with it." It is "not broadly available yet". — [RevenueCat: Authentication](https://www.revenuecat.com/docs/customers/customer-authentication)

### Inferences
- [INFERENCE] In a guest-first design, almost every account will be created by `logIn()` from an anonymous ID. Every account therefore gets an anonymous alias at birth, and row 3 of the table becomes the normal case. If the same person later buys as a guest (another device, or after a reinstall) and then logs in, the purchase stays on the new anonymous ID. The app must call `syncPurchases()` (or ask the user to tap Restore) after `logIn()`.
- [INFERENCE] Check how the current app configures the SDK: anonymously at launch then `logIn(accountId)`, or `configure(appUserID: accountId)` after sign-in. Existing accounts created the first way already have an anonymous alias. Accounts created the second way do not, so their first guest-to-account log-in would merge.
- [INFERENCE] `created == false` does not mean "this account has data on our server". It only concerns RevenueCat. The app's own server must say whether the account already has trackers.

---

## 3. Restore / transfer behaviour setting; `restorePurchases` vs `syncPurchases`

### Takeaway
The project setting (Project settings → General) decides what happens when a store receipt already belongs to another **identified** ID. Current options: **Transfer to new App User ID (default)**, **Transfer if there are no active subscriptions**, **Keep with original App User ID** (only for apps that require an account before any purchase), and **Share between App User IDs (legacy)**, which only old projects can keep. Purchases held by an **anonymous** ID are never "kept": they are aliased into the restoring ID. `restorePurchases` is for a user tap (it can show OS sign-in prompts). `syncPurchases` is the programmatic, silent version and carries "a risk of transferring or aliasing an anonymous user".

### Cited Findings
- [DOCS] "If an App User ID tries to restore transactions that are already associated with a different identified App User ID in RevenueCat, you can configure how RevenueCat should respond by changing the dropdown in **Project settings > General**." The setting affects all apps in the project. "Share between App User IDs (legacy)" is "only available for legacy projects with this behavior already enabled, not new projects". A separate sandbox behaviour can be set. — [RevenueCat: Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] It also applies to new purchases: "The configured behavior will also apply if an identified App User ID makes a new purchase and the device receipt is already associated with a different identified App User ID." — [same](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] Anonymous owners are always aliased: "If the purchase is currently associated with an anonymous App User ID, that App User ID will be aliased with the new App User ID instead (ie. the purchase is shared between the App User IDs)." — [same](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] **Transfer to new App User ID — "Default ✅"**: "only one customer at a time can have access. For example, if UserA buys a subscription, then UserB logs into your app on the same device and restores transactions, UserB would now have access to the subscription and it would be revoked from UserA." The page lists three cases:
  - identified ID restores, anonymous owner → "merged (aliased)";
  - anonymous ID restores, identified owner → "transfer the receipt to the anonymous user";
  - anonymous restores, anonymous owner → "merged (aliased)".
  — [same](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] **Transfer if there are no active subscriptions**: transfers "unless they contain an active subscription". "Note that the presence of one-time (non-subscription) purchases does not prevent transfers from happening." — [same](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] **Keep with original App User ID — "Use with caution 🚧"**: returns `RECEIPT_ALREADY_IN_USE` and "is only allowed for apps that require every customer to create an account before purchasing". — [same](https://www.revenuecat.com/docs/projects/restore-behavior); error text: "Indicates there is an identical receipt already in use by another subscriber." — [Error Handling](https://www.revenuecat.com/docs/test-and-launch/errors)
- [DOCS] RevenueCat's own table: an app that "Has an optional login mechanism and / or allows customers to purchase before creating an account" → "**Transfer to new App User ID**. Required to make sure customers that purchase without an account can restore transactions." The same applies to apps with no login at all ("Required to allow customers to restore transactions after uninstalling / reinstalling"). — [same](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] `restorePurchases` "**should not** be triggered programmatically, since it may cause OS level sign-in prompts to appear". Use `syncPurchases` instead, which "will not cause OS level sign-in prompts". "Since this method simulates restoring a purchase, there is a risk of transferring or aliasing an anonymous user." "It is recommended that all apps have some way for users to trigger the `restorePurchases` method, even if you require all customers to create accounts." — [Restoring Purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [DOCS] Caveat when RevenueCat tracks new purchases from server notifications: if `appAccountToken` / `obfuscatedExternalAccountId` don't match the App User ID, "no transfer will occur, and **App User ID B** will never get access to the entitlement" (with some transfer settings). — [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)

### Inferences
- [INFERENCE] Guest purchases rule out "Keep with original App User ID". The default "Transfer to new App User ID" is the only setting RevenueCat documents as compatible. "Transfer if no active subscriptions" does not protect the lifetime product, because one-time purchases still transfer.
- [INFERENCE] The default has a sharp edge in a guest-plus-account app. Say a premium **account** holder signs out (or reinstalls and stays a guest) and taps Restore while anonymous. The purchase is **transferred to the anonymous ID**, and the account loses premium on every device until the person logs in again and restores or syncs. Do not call `syncPurchases()` automatically in guest mode, except right after a log-in as described in §2.

---

## 4. Lifetime (non-consumable) purchase without an account: reinstall, second device, Android

### Takeaway
A non-consumable stays on the Apple ID's receipt / Google account's purchase list. A guest who reinstalls, or uses a second device on the same store account, gets the lifetime back by tapping Restore. RevenueCat then aliases the new anonymous ID with the old one (anonymous owner). Consumables and non-renewing subscriptions cannot be restored this way. On Android the lifetime product must be marked **non-consumable in the RevenueCat dashboard**, or RevenueCat consumes it, and since Billing Client 8 (purchases_flutter ≥ 9.0.0) consumed one-time purchases cannot be queried back. Cross-platform recovery needs an account.

### Cited Findings
- [DOCS] Restoring "reactivat[es] any content that had previously been purchased **from the same store account** (Apple, Google, or Amazon)". — [Restoring Purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [DOCS] "Consumables and non-renewing subscriptions can only be restored by using an account system with custom App User IDs. This is due to these types of in-app purchases not showing up on the underlying store receipt after the transaction is finished." — [same](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [DOCS] Anonymous restore, anonymous owner: "if an anonymous ID restores and the owner of the receipt is also anonymous, the anonymous identifiers will be merged (aliased)". — [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] Google non-consumables: "If you want your customers to be able to purchase a certain One-time product only once (for example, a lifetime purchase), you need to configure the product as a non-consumable when creating it in the RevenueCat dashboard… If you don't configure it as a non-consumable, we will automatically `consume` the purchase and Google will allow the customer to purchase it again." This is supported from Android SDK 7.11.0. — [RevenueCat: Google Play Product Setup](https://www.revenuecat.com/docs/getting-started/entitlements/android-products)
- [DOCS] "Starting on Billing Client 8, Google removed the ability to query consumed one-time purchases". This affects purchases-flutter "9.0.0 and up". It is "problematic" if the app has no account system and relies on anonymous users, and has used consumed one-time products: those purchases "can not be recovered". — [Restoring Purchases](https://www.revenuecat.com/docs/getting-started/restoring-purchases)
- [DOCS] Apple requires a restore path: "you should make sure you have a restore mechanism for any restorable in-app purchases" (Guideline 3.1.1; guidelines page "Last Updated: October 16, 2026"). — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- [INFERENCE] Guest buys lifetime on iPhone A ($RCAnonymousID:A), then installs on iPhone B (same Apple ID, $RCAnonymousID:B) and taps Restore. A and B become one RevenueCat customer, and premium works on B. With a different Apple ID on B, nothing can be restored. On Android it is the same with the Google account. From iOS to Android, only an app account can carry it over.
- [INFERENCE] Two people sharing one Apple ID (common in families) will both "own" the guest lifetime after a Restore. Under the default setting, if one of them has an app account, the purchase follows whoever restored last (§3).
- [INFERENCE] Action item: check that the Android lifetime product is "non-consumable" in the RevenueCat dashboard. This matters more once guests can buy without an account.

---

## 5. What the developer's server can and cannot know about an anonymous purchaser (webhooks, REST API)

### Takeaway
An anonymous purchase sends an `INITIAL_PURCHASE` (subscription or trial) or `NON_RENEWING_PURCHASE` (lifetime) webhook whose `app_user_id` / `original_app_user_id` / `aliases` contain only `$RCAnonymousID:…`. A server keyed by account id cannot match it. When that guest later logs in and RevenueCat **aliases** the IDs, **no webhook is sent**: `SUBSCRIBER_ALIAS` is deprecated and "New projects don't receive this webhook". A subscription will show the new alias on its next event. A **lifetime purchase may never produce another event**. Only a **transfer** sends a webhook (`TRANSFER`, to the destination only, with `transferred_from` / `transferred_to` but no subscriber identity fields). The robust pattern: after log-in / restore / sync, the server pulls `GET /v1/subscribers/{account_id}`, which returns the merged CustomerInfo. RevenueCat recommends this after every webhook anyway.

### Cited Findings
- [DOCS] Event types: "`INITIAL_PURCHASE` — A new subscription was purchased." "`NON_RENEWING_PURCHASE` — A customer has made a purchase that won't auto-renew." Both carry "Subscriber identity" fields. — [RevenueCat: Event Types and Fields](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)
- [DOCS] Subscriber identity fields: `app_user_id` "Last seen App User ID of the subscriber." `original_app_user_id` "The first App User ID used by the subscriber." `aliases` "All App User IDs ever used by the subscriber." All three are "Always" included. "When looking up users from the webhook in your systems, make sure to search both the `original_app_user_id` and the `aliases` array." — [same](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)
- [DOCS] `TRANSFER` — "A transfer of transactions and entitlements was initiated between App User ID(s)." "The webhook is sent only for the destination user, although the event appears in both customer histories. The event body is identical for both users." Applicable fields are only "Common fields · Transfer": `transferred_from` (String[]), `transferred_to` (String[]), optional `store`, `environment`, `subscriber_attributes`. No `aliases`. — [same](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)
- [DOCS] "`SUBSCRIBER_ALIAS` — **Deprecated.** A new App User ID was registered for an existing subscriber. This is a legacy event type. New projects don't receive this webhook." — [same](https://www.revenuecat.com/docs/integrations/webhooks/event-types-and-fields)
- [DOCS] "we recommend calling the `GET /subscribers` REST API endpoint after receiving any webhook. That way, the customer's information is always in the same format and is easily synced to your database." — [RevenueCat: Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [DOCS] REST v1 `GET /subscribers/{app_user_id}` "Gets the latest Customer Info for the customer with the given App User ID, **or creates a new customer if it doesn't exist**." — [API v1: Customers](https://www.revenuecat.com/docs/api-v1/customers)
- [DOCS] REST v2 has `GET …/customers/{customer_id}/aliases` and `POST …/customers/{customer_id}/actions/transfer` ("Transfer customer's subscriptions and one-time purchases to another customer", body `target_customer_id`, optional `app_ids`). It also has `restore_purchase_by_order_id` for Google Play. — [API v2: Customer](https://www.revenuecat.com/docs/api-v2/customer)
- [DOCS] Webhooks "are available on our Pro plan" (legacy plans without webhooks must migrate). — [Webhooks](https://www.revenuecat.com/docs/integrations/webhooks)
- [VENDOR] Staff on anonymous promo-code purchases with a backend keyed on its own IDs (Apr–May 2025): cache the webhook, then call `Purchases.logIn`, then `syncPurchases`, then process the cached webhook "based on the now-linked `app_user_ids`". "This approach isn't ideal, but it's currently the best workaround". "There's no truly elegant way to solve this due to platform limitations." A new install's anonymous ID "will not match the original anonymous ID". — [community.revenuecat.com #6231](https://community.revenuecat.com/general-questions-7/handling-anonymous-promo-code-subscriptions-with-revenuecat-associating-webhooks-with-logged-in-users-in-flutter-6231)
- [VENDOR] Older staff answer (Aug 2021): for purchases made without login, "there won't be a great way to link the user from your backend since they are anonymous". RevenueCat "is designed to be a source of truth for allowing access". "Custom anonymous identifiers are not recommended". A community member (not staff) added that a TRANSFER webhook "contains only transfer data, not subscription status or expiry". — [community.revenuecat.com #254](https://community.revenuecat.com/general-questions-7/how-do-i-link-purchase-made-by-the-user-without-login-in-my-backend-254)

### Inferences
- [INFERENCE] Server handling of an unknown anonymous ID:
  1. Accept and log the webhook (HTTP 200).
  2. Do not create an account for it.
  3. Optionally keep it in an "unclaimed purchase" table keyed by the IDs in `aliases`.
  4. Resolve it only when an account appears in `app_user_id` / `original_app_user_id` / `aliases`, or when the app asks for a refresh.
- [INFERENCE] Attaching the purchase to the account later:
  1. The app runs `logIn(accountId)`, then `syncPurchases()` if needed (§2).
  2. The app calls a server endpoint ("refresh my premium").
  3. The server calls `GET /v1/subscribers/{accountId}` with its secret key and sets premium from the returned entitlements.
  4. Do not wait for a webhook. Aliasing sends none, and a lifetime purchase has no renewals.
- [INFERENCE] `TRANSFER` handling: for each ID in `transferred_from` and `transferred_to` that is a known account, re-pull `GET /subscribers/{id}`. A transfer *away* from an account (§3 edge case) must remove premium on the server, or the server and RevenueCat disagree.
- [INFERENCE] Never grant premium from an anonymous ID that the client sends. Only trust what RevenueCat returns for the account id after the merge. Avoid calling `GET /subscribers` with arbitrary IDs, because it creates customers.
- [INFERENCE] Whether this project still receives `SUBSCRIBER_ALIAS` depends on when it was created ("new projects don't"). Check the webhook log before relying on it either way.

---

## 6. RevenueCat (and Apple) guidance on requiring an account before purchase; known pitfalls

### Takeaway
RevenueCat supports purchasing before an account and documents the setting for it (§3). Its blog cites "you don't even need an account yet" as good freemium practice. Apple's 5.1.1(v) says apps without significant account-based features must let people in without a login. App Review has rejected apps that required registration before buying non-account-based IAPs. The documented pitfalls are support-heavy: purchases left on an anonymous ID after log-in ("most frequent support issue"), purchases moving to anonymous IDs after log-out, and shared Apple IDs.

### Cited Findings
- [DOCS] Guideline 5.1.1(v): "If your app doesn't include significant account-based features, let people use it without a login. If your app supports account creation, you must also offer account deletion within the app. Apps may not require users to enter personal information to function, except when directly relevant to the core functionality of the app or required by law." (page "Last Updated: October 16, 2026") — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [COMMENTARY] A developer quotes a 5.1.1 rejection (Mar 2025): "Apps cannot require user registration prior to allowing access to app content and features…" and "your app requires users to register with personal information to purchase in-app purchase products". RevenueCat staff (Haley Pace, 19 Mar 2025): "we've had devs do this with no issues". She suggested Apple may object to the personal information collected. The app passed after the developer explained its design. — [community.revenuecat.com #6041](https://community.revenuecat.com/sdks-51/handling-apple-app-review-rejection-with-revenuecat-s-keep-with-original-app-user-id-setting-6041)
- [VENDOR] RevenueCat blog (17 Nov 2026), on freemium value before the paywall: "Duolingo is the clearest example: you select a language, and you're doing exercises and translating sentences within 60 seconds. You don't even need an account yet." — [RevenueCat blog: 6 ways to deliver value before the paywall](https://www.revenuecat.com/blog/growth/app-value-paywall)
- [VENDOR]/[COMMENTARY] "Users often lose subscription when logging into an existing account" (Jan 2023). Web-first accounts and anonymous in-app purchases: the developer calls it his "most frequent support issue". Staff (Sharif, Feb 2023) recommend a user-pressed "restore purchases" button. The app could offer a restore when the logged-out anonymous user had purchases and the logged-in user has none. Staff: "I wouldn't recommend calling restore purchases automatically whenever a user logs in". — [community.revenuecat.com #2510](https://community.revenuecat.com/sdks-51/users-often-lose-subscription-when-logging-into-an-existing-account-2510)
- [VENDOR] "App IDs transferring subscriptions to anonymous users" (2022–2023). When a renewal posts while the user is logged out, "the backend is transferring the receipt, to make sure that whoever's currently using the device". "If they're logged out, those purchases will be reassigned to their current anonymous user ID." Fix: "calling syncPurchases right after logIn completes". Staff "usually warn against" blocking restores or transfers, because users could lose access with no recovery path. — [community.revenuecat.com #1171](https://community.revenuecat.com/sdks-51/app-ids-transferring-subscriptions-to-anonymous-users-1171)
- [DOCS] Shared device or Apple ID under the default setting: UserB restoring on UserA's device takes the subscription from UserA. — [Restore Behavior](https://www.revenuecat.com/docs/projects/restore-behavior)
- [DOCS] Do not hardcode App User IDs ("every install will be treated as the same user"). RevenueCat also blocks IDs such as `'anonymous'`, `'guest'`, `'null'`, `'0'`. — [Identifying Customers](https://www.revenuecat.com/docs/customers/identifying-customers)

### Inferences
- [INFERENCE] A sign-up wall at first launch is an App Review risk under 5.1.1(v) only if review decides cross-device sync is not "significant account-based" functionality. Guest mode removes that risk. It replaces it with the support cases above, which a support screen showing the App User ID and a visible Restore button reduce.

---

## 7. Firebase Authentication anonymous accounts and FirebaseUI

### Takeaway
Firebase upgrades an anonymous user in place with `linkWithCredential` (same `uid`, data follows). If the credential already belongs to another user, linking fails with `credential-already-in-use`. Firebase's documented answer is manual: read the anonymous user's data, sign in to the existing account, merge "as appropriate for your app", save, then delete the anonymous user. FirebaseUI automates the upgrade (`autoUpgradeAnonymousUsers`, off by default) and passes the conflict to the app as `firebaseui/anonymous-upgrade-merge-conflict`.

### Cited Findings
- [DOCS] "When an anonymous user signs up to your app, you might want to allow them to continue their work with their new account—for example, you might want to make the items the user added to their shopping cart before they signed up available in their new account's shopping cart." (page "Last updated 2026-11-20 UTC") — [Firebase: Authenticate anonymously (Web)](https://firebase.google.com/docs/auth/web/anonymous-auth)
- [DOCS] Flutter sample error handling: `case "credential-already-in-use"` → "The account corresponding to the credential already exists, or is already linked to a Firebase User." "If the call to `linkWithCredential()` succeeds, the user's new account can access the anonymous account's Firebase data." — [Firebase: Anonymous auth (Flutter)](https://firebase.google.com/docs/auth/flutter/anonymous-auth)
- [DOCS] "Account linking will fail if the credentials are already linked to another user account. In this situation, you must handle merging the accounts and associated data as appropriate for your app." The sample code comments: "Get the data which you will want to merge. This should be done now while the app is still signed in as this user." / "Merge prevUser and currentUser data stored in Firebase. Note: How you handle this is specific to your application" / "Save the merged data to the new user" / "Delete the previous user's Firebase Auth account first". The code then calls `deleteUser(prevUser)`. (Web and iOS pages, "Last updated 2026-11-20 UTC") — [Firebase: Link multiple auth providers (Web)](https://firebase.google.com/docs/auth/web/account-linking); [iOS](https://firebase.google.com/docs/auth/ios/account-linking)
- [DOCS] Optional clean-up with Identity Platform: "anonymous accounts older than 30 days will be automatically deleted." — [Firebase anonymous auth (Web)](https://firebase.google.com/docs/auth/web/anonymous-auth)
- [DOCS] FirebaseUI Web: set `autoUpgradeAnonymousUsers` to `true` ("this option is disabled by default"), and "The user will retain the same `uid`". On conflict: "an error `auth/credential-already-in-use` will be thrown by Firebase Auth as an existing user cannot be linked to another existing user. No two users can share the same credential. In that case, both user data have to be merged before one user is discarded (typically the anonymous user)." The library triggers "`signInFailure` callback with an error code `firebaseui/anonymous-upgrade-merge-conflict`". "This callback is required when `autoUpgradeAnonymousUsers` is enabled." Before `signInWithCredential(error.credential)`, "the data of the anonymous user must be copied and the anonymous user deleted. After sign-in completion, the data has to be copied back to the non-anonymous user." — [FirebaseUI-web README](https://github.com/firebase/firebaseui-web/blob/master/README.md)
- [DOCS] FirebaseUI Android (Compose rewrite) exposes `isAnonymousUpgradeEnabled = true` ("default: false"). Its README does not describe a merge-conflict UI. Conflicts surface as `AuthException.AccountLinkingRequiredException`. — [FirebaseUI-Android auth README](https://github.com/firebase/FirebaseUI-Android/blob/master/auth/README.md)

### Inferences
- [INFERENCE] Firebase splits the work in two. The SDK handles identity, and the merge of app data is always the developer's job: no default strategy, no UI, and the anonymous user is deleted. This is the same split this app would have between "local guest DB" and "server account".

---

## 8. Supabase anonymous sign-ins

### Takeaway
A Supabase anonymous user is a real `auth.users` row (`is_anonymous` claim). It becomes permanent by linking an email/phone (`updateUser`) or OAuth identity (`linkIdentity`, requires "manual linking", beta). If the email belongs to an existing user, the update fails. The docs then describe a manual flow (sign in to the existing account, reassign rows, run your own conflict resolver) and list three strategies: keep the account's, keep the anonymous user's, or merge.

### Cited Findings
- [DOCS] An anonymous user "behaves like a permanent user, except the user can't access their account if they sign out, clear browsing data, or use another device." — [Supabase: Anonymous Sign-Ins](https://supabase.com/docs/guides/auth/auth-anonymous)
- [DOCS] "Converting an anonymous user to a permanent user requires linking an identity to the user. This requires you to enable manual linking in your Supabase project." Email/phone via `updateUser()` ("To add a password for the anonymous user, the user's email or phone number needs to be verified first"). OAuth via `linkIdentity()`. — [same](https://supabase.com/docs/guides/auth/auth-anonymous); [Identity Linking, "Manual linking (beta)"](https://supabase.com/docs/guides/auth/auth-identity-linking)
- [DOCS] "Resolving identity conflicts": when an anonymous user "decide[s] to sign in to an existing account, you will need to decide how you want to resolve data conflicts in the shopping cart: 1. Overwrite the items in the cart with those in the existing account 2. Overwrite the items in the cart with those from the anonymous user 3. Merge the items in the cart together". — [Supabase: Anonymous Sign-Ins](https://supabase.com/docs/guides/auth/auth-anonymous)
- [DOCS] "Linking an anonymous user to an existing account … requires manual handling of potential conflicts". The sample calls `updateUser({ email })`. On error it logs "This email belongs to an existing user. Please sign in to that account." It then signs in with password and runs `.from('your_table').update({ user_id: existingUser.id }).eq('user_id', anonUserId)`. Last it calls `resolveDataConflicts()`: "This could involve ignoring the anonymous user's metadata, overwriting the existing user's metadata, or merging the data". — [same](https://supabase.com/docs/guides/auth/auth-anonymous)
- [DOCS] "Automatic cleanup of anonymous users is currently not available". SQL is given to delete anonymous users older than 30 days. Anonymous sign-ins are IP rate-limited (30/hour), and CAPTCHA is "strongly recommended". — [same](https://supabase.com/docs/guides/auth/auth-anonymous)

---

## 9. Other identity SDKs: Auth0, AWS Cognito identity pools, Appwrite, Realm/Atlas, (RevenueCat Authentication)

### Takeaway
Auth0 links identities but **discards the secondary account's metadata**. Cognito keeps the guest identity ID when a guest first logs in. If the login already belongs to another identity, Cognito merges: one becomes owner and the other is disabled, and the app must update its cached ID. Appwrite's anonymous session is inherited by a *newly created* account. Realm/Atlas Device Sync reached end-of-life in 2025. None of them merge your application data for you.

### Cited Findings
- [DOCS] Auth0 account linking: "The secondary account is removed from the users list". "There is no automatic merging of user profiles with associated identities." "The `user_metadata` and `app_metadata` of the secondary account are discarded". Tenants should "request authentication for both accounts before linking occurs". "Insecurely linking accounts can allow malicious actors to access legitimate user accounts." — [Auth0: User Account Linking](https://auth0.com/docs/manage-users/user-accounts/user-account-linking)
- [DOCS] Cognito, guest → first login: "Amazon Cognito makes sure that an old identity retains the same unique identifier as the new one, and that the profile data is merged automatically. Your application is informed of a profile merge through the IdentityChangedListener interface." (`identityChanged(oldIdentityId, newIdentityId)`) — [Cognito: Switching unauthenticated users to authenticated users](https://docs.aws.amazon.com/cognito/latest/developerguide/switching-identities.html)
- [DOCS] Cognito, login already tied to another identity: "the two identities are merged. Once merged, one identity becomes the parent/owner of all associated logins and the other is disabled. In this case, the identity ID of the parent/owner is returned. You must update your local cache if this value differs." Developer-authenticated identities also allow explicit `MergeDeveloperIdentities`. — [Cognito: Identity pools authentication flow](https://docs.aws.amazon.com/cognito/latest/developerguide/authentication-flow.html)
- [DOCS] Appwrite: "Guest users let you store user information like items in their cart or theme preferences before they create an account… If a user later creates an account, their information will be inherited by the newly created account." It gives no guidance for logging in to an existing account. — [Appwrite: Anonymous login](https://appwrite.io/docs/products/auth/anonymous)
- [SEARCH] MongoDB: "As of September 2024, Atlas Device SDKs are deprecated. Atlas Device SDKs will reach end-of-life and be removed on September 30, 2025." Realm anonymous-user linking is therefore no longer a current reference. — [MongoDB: Atlas Device SDKs Deprecation](https://www.mongodb.com/docs/atlas/device-sdks/deprecation)
- [DOCS] RevenueCat's private-beta Authentication keeps "the older Customer" and both customers' purchases on sign-in to an existing identity (§2). — [RevenueCat: Authentication](https://www.revenuecat.com/docs/customers/customer-authentication)

### Inferences
- [INFERENCE] The SDKs agree: identity merges are automatic, and app data merges are left to the app (Firebase, Supabase, Auth0 explicitly). When an SDK does merge something itself, the older or existing record wins (Cognito owner, RevenueCat Authentication "older Customer", Auth0 primary).

---

## 10. Apple's own patterns: iCloud sign-out and merge prompts

### Takeaway
Apple's current flow (support pages published Sep and Nov 2026) offers "Sign Out But Don't Erase" (data stays on the device) or "Erase this [device]". When someone signs in to a device holding another account's leftover data, Apple asks first, on a screen titled "Merge iCloud data from this [device]?" with **Go back** as the way out. A second screen, "Previous data will be removed from this [device]", is confirmed with **Continue**. Apple warns that data not yet synced is removed at sign-out. For Contacts, turning iCloud on stores all local contacts in iCloud, and Apple keeps a separate article for duplicates after setting up iCloud Contacts. Older "Merge / Cancel" and "Keep on My iPhone / Delete from My iPhone" wordings are known only from forums.

### Cited Findings
- [DOCS] "If you want to sign out of your Apple Account … but plan to keep the device for yourself, you can choose Sign Out But Don't Erase… When you choose this option, most data stays on your device." This covers Health, Passwords, Contacts, Photos, Notes, Calendars and "Data that hasn't yet synced with iCloud". "To remove all of this data from your device when you sign out of your Apple Account, choose 'Erase this [device]' instead." (Published Date: September 14, 2026) — [Apple Support 122682](https://support.apple.com/en-us/122682)
- [DOCS] "In some cases, you might get a warning that data that hasn't yet synced with iCloud will be removed from the device if you choose Sign Out But Don't Erase." — [same](https://support.apple.com/en-us/122682)
- [DOCS] "What happens when you merge iCloud data: If the previous device owner chose to sign out and not erase and you sign in to that device with your Apple Account, data on the device merges with your iCloud data and then syncs to your other devices. If you don't want to merge your iCloud data with the previous device owner's data, on the 'Merge iCloud data from this [device]?' screen, tap Go back. To remove the data left behind from the prior device owner, on the screen labeled 'Previous data will be removed from this [device]', tap Continue." — [same](https://support.apple.com/en-us/122682)
- [DOCS] "You can also choose to sign out, but keep your information on your iPhone, iPad, or Apple Vision Pro." When you sign out, "App data for any third-party apps that you've installed that use iCloud" stops syncing. (Published Date: November 12, 2026) — [Apple Support 104958](https://support.apple.com/en-us/104958)
- [DOCS] Contacts: "go to Settings > [your name] > iCloud. Tap See All (or Show All), then turn on Contacts. All the contacts that you see in the Contacts app are now stored in iCloud." The page links to "If you see duplicate contacts after setting up iCloud Contacts". — [iCloud User Guide: Set up iCloud for Contacts](https://support.apple.com/en-us/101336)
- [DOCS] That article's fix is manual de-duplication: "Make a copy of your contacts… From the Card menu, select Card > Look for Duplicates. When asked, click Merge." (Published August 22, 2023) — [Apple Support 102299](https://support.apple.com/en-us/102299)
- [SEARCH] Forum and press accounts of the classic prompt: "When you're asked if you want to Merge or Cancel, tap Merge". 9to5Mac describes "a prompt asking the user if they would like to merge their contacts to iCloud or cancel the operation". — [Apple Community 255208642](https://discussions.apple.com/thread/255208642); [9to5Mac, Feb 2019](https://9to5mac.com/2019/02/14/merge-contacts-icloud/)

### Inferences
- [INFERENCE] Apple's pattern for personal data: (1) default to merge, (2) ask before merging data that may belong to someone else, (3) always offer a non-destructive way out ("Go back"), (4) warn before removing unsynced data. Even Apple's merge creates duplicates that users must clean up.

---

## 11. Games: Google Play Games guidance and guest-progress dialogs

### Takeaway
Google's Play Games docs (updated 2026-10-06) cover exactly this case. A guest with significant local progress who links to a Player ID with existing cloud progress: the game "shouldn't automatically overwrite any data". Google recommends a message that an existing account with progress was detected, showing both progresses so the player decides. For ordinary save conflicts, Google offers automatic policies (e.g. most recently modified) or a manual merge. Real games show "Current Progress" vs "Available Progress" pickers or simply warn that guest progress is lost.

### Cited Findings
- [DOCS] "If a user has multiple accounts or if there's a conflict between saved game data on their device and in the cloud, you need a conflict resolution policy. Usually, the user decides how to resolve these conflicts." — [Android Developers: Cloud save (Play Games Services)](https://developer.android.com/games/pgs/savedgames)
- [DOCS] "Guest account: When a player on a guest account signs in and links to a Player ID with existing cloud-saved progress, your game might accidentally overwrite significant historical data. If a player has a local guest account with significant progress and a cloud backup of the last played In-Game Account (IGA) linked to Play Games Services, your game shouldn't automatically overwrite any data… it is recommended that the game informs the player of this choice before making it for the player or explicitly ask the player to choose from the options." Options listed:
  - "Option 1: Maintain the current flow where cloud or a local progress is restored. A warning message is displayed to indicate an existing account was detected, and its progress will be used."
  - "Option 2 (Recommended): Display a message informing the player that an existing account with progress was detected. Linking the guest account replaces the cloud progress with the current guest progress. The message displayed for both local and cloud-saved progress so the player can make an informed decision."
  
  (Last updated 2026-10-06 UTC) — [same](https://developer.android.com/games/pgs/savedgames)
- [DOCS] "Note: If your game supports guest mode, player progress is not saved or restored. This limitation occurs because guest mode is tied to a single device." — [same](https://developer.android.com/games/pgs/savedgames)
- [DOCS] Snapshot conflicts: the API "presents both sets of conflicting saved games at read-time". "Your game must decide how to resolve the conflict by picking one of the provided versions or merging the data of the two saved game versions." Sample policy `RESOLUTION_POLICY_MOST_RECENTLY_MODIFIED`. Comment in the sample: "One option is to present a UI to the user to choose which snapshot to resolve." — [Android Developers: Saved games for Android games](https://developer.android.com/games/pgs/android/saved-games)
- [SEARCH] Pixel Gun 3D help (page returned 403): a progress selection screen shows "Current Progress" (the account in use) and "Available Progress" (the one linked to the store profile), with **Stay** / **Proceed**. If the current account "isn't synced with your Game Center/Google Play/HUAWEI ID profile, you'll permanently lose access to it once you switch." — [Pixel Gun 3D support](https://support.pixelgun3d.com/hc/en-us/articles/30614308654621)
- [SEARCH] An Apple Developer Forums post asks whether a dialog may make players either overwrite current progress with the Game Center account's progress or sign out of Game Center to keep it. — [Apple Developer Forums 4902](https://developer.apple.com/forums/thread/4902)

---

## 12. To-do, journal and tracker apps: what they do when a guest or local user logs in to an existing account

### Takeaway
Practice splits into three groups:
- **Ask:** Things asks to "merge all data or just keep a specific set of to-dos".
- **Discard guest data, with a warning in the help centre:** Insight Timer states that guest data "will be permanently deleted and cannot be recovered".
- **No in-place merge:** Habitify guests are local-only and must link before signing in elsewhere. Todoist: "not possible to merge separate Todoist accounts". Daylio can't merge two backups. Day One copies content between accounts with a separate tool and drops unsynced entries at sign-out.

When apps do import into an existing account, they **add** items, so counts add up (Habitify: 2 + 3 = 5 habits).

### Cited Findings
- [DOCS] Things (Cultured Code), "Logging In To Your Things Cloud Account": "What happens if there are already to-dos in Things? If you added anything to Things before connecting to an existing Things Cloud account, we'll ask you how to proceed. Send off your credentials, and you'll see different options to merge all data or just keep a specific set of to-dos." — [Things support 2997514](https://culturedcode.com/things/support/articles/2997514/)
- [DOCS] Insight Timer, "What Happens When I Sign Into an Existing Account From Guest Mode?": guest progress, activity or history "will be permanently deleted and cannot be recovered". Its advice is to "consider creating an account before you start practicing". — [Insight Timer help](https://help-app.insighttimer.com/support/solutions/articles/67000702470-what-happens-when-i-sign-into-an-existing-account-from-guest-mode-)
- [DOCS] Habitify (habit tracker): "A 'Guest' account is stored only locally on a single device and will not sync. … If you are currently using a 'Guest' account, you need to connect it to an email, Google, or Apple ID." "The most common reason for data not appearing on a new device is accidentally creating a second, empty account by choosing a different sign-in method." (Oct 9, 2025) — [Habitify: Log into your account on multiple devices](https://intercom.help/habitify-app/en/articles/9344497-log-into-your-account-on-multiple-platforms-devices); "Using a different method will accidentally create a new, empty account." (Jul 13, 2026) — [Sign In to an Existing Habitify Account](https://intercom.help/habitify-app/en/articles/12540208-sign-in-to-an-existing-habitify-account)
- [DOCS] Habitify import into an existing account: "Habits are ADDED. The import process will add the habits from your backup file to any habits that already exist in the new account. For example, if your new account already has 2 habits, and you import a backup containing 3 different habits, you will end up with 5 habits in total after the import." Same internal ID → "the imported version will overwrite the existing one". (Oct 23, 2025) — [Habitify: How to Transfer Data between Habitify Accounts](https://intercom.help/habitify-app/en/articles/10583732-troubleshooting-transfering-data-between-habitify-accounts)
- [SEARCH] Habitify "does not encourage transferring data among accounts due to privacy concerns and the risk of missing data during the process." Its free plan lists 3 habits. App Store copy says "Habits beyond the basic limit will be view-only". — [Habitify help collection](https://intercom.help/habitify-app/en/collections/3978878-manage-account-data); [Habitify plans](https://intercom.help/habitify-app/en/articles/6113487-explore-habitify-plans-free-plus-and-pro)
- [DOCS] Todoist: "It's not possible to merge separate Todoist accounts." The workaround is CSV export/import per project, and "Your completed tasks, filters, labels not in current use, and Karma progress aren't copied." (updated October 22, 2026) — [Todoist: Set up your Todoist account](https://www.todoist.com/help/articles/can-i-merge-several-todoist-accounts-ybfXqH)
- [DOCS] Day One sign-out: synced entries "are safe". Entries not yet synced "will be removed from the device and cannot be recovered". — [Day One: Sign In/Sign Out with Day One Sync](https://dayoneapp.com/guides/troubleshooting/sign-in-sign-out-with-day-one-sync/)
- [SEARCH] Day One merges two accounts with a separate tool (macOS Settings > Sync). The tool only copies content and leaves the duplicate account in place. Shared journals are not copied. A forum user reports duplicate entries and unfinished sync after merging. — [Day One: Merging Day One Accounts](https://dayoneapp.com/guides/merging-day-one-accounts/); [Day One forum](https://forums.dayoneapp.com/forums/topic/issue-with-synchronization-and-duplicate-entries-after-merging-two-day-one-plus)
- [SEARCH] Daylio (local mood tracker, page 404 when fetched): you cannot restore an old backup and keep current entries. A backup is a snapshot, and merging two backups is not supported. The manual import asks the user to confirm with "Replace". — [Daylio help: restore old backup and keep current entries](https://daylio.helpscoutdocs.com/article/38-i-want-to-restore-old-backup-and-keep-my-current-entries)

---

## 13. What goes wrong, and patterns that avoid it

### Takeaway
Documented failures:
- **silent data loss** (guest data dropped at log-in, unsynced data removed at sign-out);
- **silent unwanted merges** (guest data uploaded into someone else's existing account);
- **partial merges reported as success**;
- **duplicates** (Apple Contacts; Day One merges);
- **counts that add up past a limit** (Habitify import 2 + 3 = 5);
- **"empty second account"** confusion from a different sign-in method, the most common Habitify issue.

The avoidance patterns that recur:
- never overwrite or discard without an explicit choice;
- show both sides with counts;
- keep a recoverable copy of guest data until the server confirms;
- make over-limit items read-only rather than deleting them (Todoist, Habitify).

### Cited Findings
- [PRIMARY] readtrail (small open-source reading tracker, PR merged 27 Sep 2026). "logging into an *existing* account with leftover guest data on the device would silently upload and merge it in". The fix splits flows: log-in "discards local guest data — it belongs to a different identity than the account just logged into", and register "migrates guest data". The change also removed name/author/date duplicate-matching that existed only for that case. — [GitHub alex-sviridov/readtrail#37](https://github.com/alex-sviridov/readtrail/pull/37)
- [PRIMARY] InvTrack (small open-source finance tracker, 2026). Audit findings: "The guest-to-Google merge reported full success while dropping investment fields, expected cash flows and reminders". "After a partial merge, the only copy of the guest data was held in memory". A saved backup "was not tied to an account. It survived sign-out and account deletion, and a later user on the same device could see and share it." Fix: ask before the irreversible sign-in. The dialog is "Some details will not move" with buttons **Cancel** / **Sign in without them**. A per-owner backup file is kept until the merge completes. — [GitHub ravitejakamalapuram/InvTrack#828](https://github.com/ravitejakamalapuram/InvTrack/pull/828)
- [DOCS] Duplicates after a merge-all: Apple keeps a dedicated support article for duplicate contacts after enabling iCloud Contacts. — [Apple Support 102299](https://support.apple.com/en-us/102299)
- [DOCS] Additive import pushes counts up (2 + 3 = 5 habits) — [Habitify](https://intercom.help/habitify-app/en/articles/10583732-troubleshooting-transfering-data-between-habitify-accounts). Wrong sign-in method creates an empty account and is the most common data issue — [Habitify](https://intercom.help/habitify-app/en/articles/12540208-sign-in-to-an-existing-habitify-account)
- [DOCS] Over-limit handling by read-only, not deletion (Todoist, team projects after a downgrade): "the five most recently created projects remain active, while all other older projects become view-only." "With a view-only project, you can see the data, but you can't make any changes." You "still receive task reminders" and can "view these projects, delete them, archive them". (updated November 24, 2026) — [Todoist: What happens when I downgrade my plan?](https://www.todoist.com/help/articles/what-happens-when-i-downgrade-my-plan-dOhlH9qQe). [SEARCH] For personal projects, the snippet says the 5 *oldest* stay editable. — [Todoist usage limits](https://www.todoist.com/help/account-and-billing/plans/usage-limits-in-todoist-e5rcSY)
- [DOCS] Unsynced data removed on sign-out (Day One, Apple warning) — [Day One](https://dayoneapp.com/guides/troubleshooting/sign-in-sign-out-with-day-one-sync/); [Apple 122682](https://support.apple.com/en-us/122682)
- [SEARCH] Khan Academy community thread titled "Lost all progress after prompt to sign in to track progress" (not read). — [Khan Academy community](https://support.khanacademy.org/hc/es/community/posts/31404475008397/comments/31576672635917)
- [VENDOR] Purchases left behind on an anonymous ID after log-in (RevenueCat §2, §6). This is the purchase-side version of the same failure.

### Inferences
- [INFERENCE] Avoidance checklist for this app:
  1. Snapshot the local DB to a file before any log-in.
  2. Never delete it until the server confirms the merge.
  3. Detect "account has data" on the server before deciding.
  4. Never apply a merge silently into an account that already has trackers.
  5. Match trackers on a stable key, not only on name.
  6. For the same tracker and day, apply one explicit rule and log what was overwritten.
  7. Never delete trackers to fit the free limit. Make the extras read-only instead.
  8. Show the RevenueCat App User ID and a Restore button in settings.

---

## 14. Merge strategies compared on a "year in pixels" scenario

### Takeaway
Five strategies, applied to one scenario. Only "ask, with merge as the recommended button and a kept backup" avoids both silent loss and silent pollution of the account. Plain "merge everything" creates duplicates and breaks the 3-tracker free limit. "Keep the account's" loses the guest's work. "Adopt local" (overwrite the account) is the one no reviewed source does by default. The purchase must be settled first (`logIn` → `syncPurchases` if needed → server refresh), because whether the merged account is premium decides whether the free limit applies.

Scenario [INFERENCE], used for every strategy below: the guest has **Mood** (20 days filled, 1–20 Nov) and **Sleep** (20 days). The existing account has **Mood** (200 days, including 8 of the same November days, coloured from another device) and **Water**. The free limit is 3 trackers. Variant A: the account is free and the guest is free. Variant B: the guest bought lifetime as `$RCAnonymousID:G`, and the account was created from an earlier anonymous ID, so it already has an anonymous alias.

### Cited Findings (strategy definitions)
- [DOCS] Supabase names three strategies: overwrite with the existing account's data, overwrite with the anonymous user's, or merge. — [Supabase](https://supabase.com/docs/guides/auth/auth-anonymous)
- [DOCS] Firebase: merge "as appropriate for your app", then delete the anonymous user. — [Firebase](https://firebase.google.com/docs/auth/web/account-linking)
- [DOCS] Google: don't auto-overwrite; recommended to show both progresses and let the player choose. — [Android Developers](https://developer.android.com/games/pgs/savedgames)
- [DOCS] Apple: ask before merging ("Merge iCloud data from this [device]?" / Go back). — [Apple 122682](https://support.apple.com/en-us/122682)
- [DOCS] Things: ask to merge all or keep a specific set. Insight Timer: discard guest data. Habitify: additive import. — [Things](https://culturedcode.com/things/support/articles/2997514/); [Insight Timer](https://help-app.insighttimer.com/support/solutions/articles/67000702470-what-happens-when-i-sign-into-an-existing-account-from-guest-mode-); [Habitify](https://intercom.help/habitify-app/en/articles/10583732-troubleshooting-transfering-data-between-habitify-accounts)

### Inferences (each strategy on the scenario)
- [INFERENCE] **1. Adopt local (replace the account with the device's data).**
  - Result: Mood (20 days), Sleep (20 days). The account's 180 earlier Mood days and Water are destroyed on every device.
  - Destructive and irreversible. No reviewed SDK or app does this by default. Google's "Option 2" replaces cloud progress only after an explicit, informed choice.
- [INFERENCE] **2. Keep the account's, discard local (Insight Timer, readtrail).**
  - Result: Mood (200 days), Water. The guest's Sleep (20 days) and 12 non-overlapping Mood days are lost.
  - Simple and never breaks the limit. Acceptable only with a clear warning before log-in and an export or backup offer. Without them it is the "silent loss" failure.
- [INFERENCE] **3a. Merge both, no matching (append, Habitify-style).**
  - Result: Mood, Mood (duplicate), Sleep, Water = **4 trackers, above the free limit of 3**. Two Mood grids show different colours for the same 8 days.
  - If the app seeds a default tracker at first launch (e.g. "Mood"), every merge will duplicate it.
- [INFERENCE] **3b. Merge both, matched by a stable key (e.g. same name plus compatible value scale).**
  - Result: Mood (merged), Sleep, Water = 3 trackers, which fits the limit.
  - The 8 same-day cells need a rule:
    - *account wins* keeps the server's history stable;
    - *most recently edited wins* needs an `updated_at` per cell;
    - *keep local and move the other value into the note* loses nothing but is noisy.
  - Risk: two "Mood" trackers with different colour scales or value sets must not be merged blindly. Fall back to 3a for them.
  - With one more guest tracker (Mood, Sleep, Energy) the result is 4 > 3 again. Make the extra tracker read-only (Todoist pattern) instead of refusing or deleting. This doubles as an upsell moment.
- [INFERENCE] **4. Keep local as a separate set ("from this phone").**
  - Result: account trackers plus "Mood (this phone)" and "Sleep (this phone)" = 4 trackers, so the same limit problem as 3a.
  - Nothing is lost and the user can delete or merge later. Clutter is the cost.
- [INFERENCE] **5. Ask the user (Things, Google Option 2, Apple).**
  - Show both sides with counts, for example: "This account already has 2 trackers (Mood · 200 days, Water). This phone has 2 trackers (Mood · 20 days, Sleep · 20 days)."
  - Recommended button: "Add this phone's trackers to my account". This runs 3b with a stated same-day rule, and over-limit trackers become read-only.
  - Secondary button: "Use only the account's trackers". This keeps a local backup file for N days and states that this phone's trackers will be removed from the phone.
  - Escape hatch: "Cancel" (stay a guest), mirroring Apple's "Go back".
  - Show the dialog only when the account has data. If the account is empty (new sign-up), migrate silently: same `uid` semantics as Firebase `linkWithCredential` or Appwrite "inherited by the newly created account".
- [INFERENCE] **Variant B (guest bought lifetime).**
  - `logIn(accountId)` does **not** merge (the account already has an anonymous alias, §2 row 3). Premium stays on `$RCAnonymousID:G`.
  - Sequence: (a) before log-in, read `customerInfo` and note the active entitlement; (b) `logIn`; (c) if the entitlement is now missing, call `syncPurchases()`, which aliases or transfers the receipt to the account; (d) call the server, which pulls `GET /v1/subscribers/{accountId}` and marks premium. No webhook arrives for an alias, and a lifetime purchase has no renewal.
  - Only then run the tracker merge. Premium makes the 4-tracker results valid, while the same merge for a free account must apply read-only extras.
  - Run step (c) only when the guest session itself had an entitlement. On a device shared under one Apple ID, a blind sync could pull a purchase away from another person's account (§3).

---

## Gaps / could not verify
- RevenueCat doc pages carry no "last updated" date. I read the live Markdown on 2026-11-25. I did not find a RevenueCat **blog post or doc** specifically on "purchase as guest, then log in". The guidance comes from the docs' tables plus staff forum answers (2021–2026), some of them old.
- I could not confirm from RevenueCat docs whether **aliasing (no transfer)** triggers any webhook other than the deprecated `SUBSCRIBER_ALIAS`. I also could not confirm whether this project, given its creation date, still receives `SUBSCRIBER_ALIAS`. Check the project's webhook history.
- There is a small wording tension between the docs and staff. The Restore Behavior page says an identified restorer with an anonymous owner leads to "merged (aliased)", while staff (2026) describe restore after sign-in as moving the purchase by transfer. The outcome (the account gets access) is the same, but the webhook differs (none vs `TRANSFER`). Test in sandbox.
- Whether restoring an iPhone from an iCloud or device backup brings back the cached RevenueCat anonymous ID (UserDefaults) is not verified in Apple's docs.
- Firebase: the effect of email-enumeration protection on `credential-already-in-use` / `email-already-in-use` during linking was not checked. FirebaseUI-iOS anonymous-upgrade docs could not be located (README paths 404).
- Not researched or not found: Clerk (I found no anonymous-user feature to cite), Supercell ID's exact "load existing village" wording, Duolingo's official guest-to-existing-profile behaviour (no Duolingo help page found, only third-party claims), TickTick, Any.do, Microsoft To Do, Google Keep, Bear (no help-centre source found on guest-to-existing-account merges).
- Pixel Gun 3D, Daylio, Khan Academy and Day One's merge article returned 403/404 or were not fetched. Their content is [SEARCH] only. The old Apple "Keep on My iPhone / Delete from My iPhone" and Contacts "Merge / Cancel" prompt wordings are from forums and press, not current Apple pages. Apple's 2026 pages use "Sign Out But Don't Erase" / "Erase this [device]" and "Merge iCloud data from this [device]?".
- The two GitHub examples (readtrail, InvTrack) are small projects. readtrail's PR was written with an AI coding assistant. Treat them as illustrations of failure modes, not as industry evidence.
- Habitify's free-plan limit is inconsistent: the help centre says 3 habits, while App Store copy says unlimited with view-only extras ([SEARCH]).
- No quantitative data found on how often guest-to-existing-account conflicts happen, or on user preference between "merge" and "ask".
