# Notification permission opt-in rates and how and when to ask (iOS and Android)

Research date: 2026-11-22. Scope: opt-in benchmarks, priming and soft asks, timing, iOS rules (one-time prompt, provisional, Time Sensitive, Focus), Android rules (POST_NOTIFICATIONS, rationale, channels, exact alarms, standby buckets, OEM killing), and re-asking. All vendor figures are labelled **[vendor]**. Figures from before 2020 are labelled **[old]**.

---

## 1. Opt-in rates on iOS and Android, by vendor and category, and how Android 13 changed them

### Takeaway
Since Android 13 made notification permission opt-in, Android rates have dropped to roughly iOS levels. Airship's 2025 medians are **53.3% on Android and 48.85% on iOS**. On Android, the median fell from 71.3% (2023) to 59.5% (2024) to 53.3% (2025), while iOS stayed flat at about 49%. Category matters more than platform. Utility, productivity and education apps are near the top, and media, gaming and retail near the bottom. Health and fitness is around the middle-to-upper range, but per-platform figures are hard to get.

### Cited Findings
**Airship [vendor]: largest dataset, most often cited**
- **2025 data (Jan–Dec 2025), published 2026:** median opt-in is **Android 53.3% and iOS 48.85%**, "separated by less than five percentage points". The sample covers apps with at least 1,000 active users that sent at least 1,000 pushes in a month, "more than 3 billion app users across thousands of apps and 15 industry verticals". Opt-in is measured as the monthly average over 12 months. Airship attributes the convergence to universal Android 13+ adoption: "the gap has permanently closed, bringing Android and iOS opt-in rates to near parity". — [Airship, Mobile App Push Notification Benchmarks for 2026](https://www.airship.com/mobile-app-push-notification-benchmarks-for-2026/)
- **2025 data, per vertical (90th and 10th percentiles):** Utility & Productivity on Android has the highest 90th percentile, **86.63%**. Education on iOS has the highest iOS 90th percentile, **88.7%**. The cross-industry "low" average is **31–32%**. Floors include Gambling & Gaming on Android at 21.35% and Retail on iOS at 18.1%. The page lists no figures for "Medical, Health & Fitness", lifestyle or media. — [Airship 2026 benchmarks](https://www.airship.com/mobile-app-push-notification-benchmarks-for-2026/)
- **Retail, 2025 data (secondary, via MobiLoud):** median 43.5% on iPhone and 49.95% on Android. Top 10% of retail apps: 63.93% on iPhone and 69.85% on Android. — [MobiLoud, Push notification opt-in rate 2026](https://www.mobiloud.com/blog/push-notification-opt-in-rate/) (secondary; the fetch returned 403, so this figure is from search-result text only)
- **Year-over-year chart in Airship's 2025 report (2023 vs 2024 data; read from the PDF text layer):**
  - **Android:** 90th percentile 88.0% → 79.7%, **median 71.3% → 59.5%**, 10th percentile 42.1% → 37.1%.
  - **iOS:** 90th percentile 73.9% → 74.1%, **median 49.1% → 49.4%**, 10th percentile 27.3% → 27.1%.
  - Airship's takeaway: "While iOS opt-in rates remained steady, Android opt-in rates dropped significantly across all percentiles."
  - [Airship 2025 Mobile App Push Notification Benchmarks (PDF, created 19 Mar 2025)](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0)
- **Same 2025 report, "How to read the data" chart:** this sample chart shows opt-in percentiles for three verticals and does not say which platform. Parsed from the chart labels, **Medical, Health & Fitness** reads about **76.5% at the 90th percentile, 57.1% median and 25.9% at the 10th percentile**. Media reads 60% / 44.5% / 29.8%, and Nonprofit 76.1% / 67.5% / 36%. These values are approximate, because they come from extracting text out of a chart. The per-platform, per-vertical charts in the report are images with no extractable numbers. — [Airship 2025 report PDF](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0)
- **Airship explainer page ("Airship Benchmarks for 2024"):** median **Android 61.4% vs iOS 49.8%**. The iOS range by industry runs from **41.6% (Media) to 76.8% (Education)**. The Android range runs from **49.1% (Social) to 71.4% (Utility & Productivity)**. Apps at the 90th percentile in every vertical and on both OSes exceed 63%. This conflicts slightly with the 2025 PDF's 59.5% / 49.4% for 2024. The two probably use different cuts or data years, and the explainer does not say which. — [Airship, What Are Push Notifications?](https://www.airship.com/explainer/push-notifications-explained/)
- **[old] Airship 2021:** median Android opt-in of 81%, from before Android 13 (cited secondhand in search results). — [MobiLoud statistics](https://www.mobiloud.com/blog/push-notification-statistics/) (secondary, not verified)

**Batch [vendor]**
- **July 2024 to July 2025, 10,000 apps and websites, about 800 billion messages:** app push opt-in on **Android fell from 85% to 67%** in one year, and **iOS from 58% to 56%**. The overall average is 61%. Batch links the Android decline to Android 13 having "aligned its consent policy with Apple's model". No per-industry app opt-in figures are given. — [Batch, benchmark notifications push CRM mobile](https://batch.com/blog/case-studies/benchmark-notifications-push-crm-mobile)

**Pushwoosh [vendor]**
- **2024 data (Q1–Q4), 600+ apps, published 14 Aug 2025:**
  - Per-category values appear only in search-result text, because the charts on the page are images: all-industries iOS average **56.36%**; E-commerce 52.78% iOS / 75.27% Android; Banking 74.62% / 75.79%; Insurance 70.50% / 91.63%; Action games 44.17% / 74.68%; Hypercasual games 23.01% / 69.03%.
  - No health & fitness or productivity category is listed.
  - [Pushwoosh, Push notification benchmarks 2025](https://www.pushwoosh.com/blog/push-notification-benchmarks/)
- **Same study, Android in Pushwoosh's own summary:** the lowest Android opt-in rates are in "Hospitality & Real Estate, Rewards & Loyalty, and Streaming", and the highest in "Business, Insurance, and Services". — [Pushwoosh, increase push opt-in](https://pushwoosh.com/blog/increase-push-notifications-opt-in)

**Business of Apps [aggregator]**
- **2026 report:** Education has the highest iOS opt-in at **76%** and media the lowest at **39%**. On Android, charities and utilities are highest at **64%** and media lowest at **42%**. — [Business of Apps, Push Notifications Statistics (2026)](https://www.businessofapps.com/marketplace/push-notifications/research/push-notifications-statistics/) (the page returned 403 to the fetch, so this comes from search-result text only. The figures look like a repackaging of Airship data.)

**Value of an opt-in [vendor]**
- **Purchases:** opted-in customers make 13% more purchases than opted-out ones, and up to 39% more in top apps. — [Airship 2025 report PDF](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0)
- **[old] Engagement and retention (2016):** opted-in users are "four times more engaged" and retained at "double the rate". — [Airship blog, 6 Sep 2016](https://www.airship.com/blog/mobile-app-marketing-how-to-series-getting-the-opt-in/)

### Inferences
- **A realistic baseline for dian-dian:** about **45–55% on both platforms** with an unprimed or average flow. Well-timed, primed flows in favourable categories reach **65–85%**. Utility, productivity and health & fitness all sit above the media, retail and gaming floors. A daily reminder is user-requested and practical rather than marketing, which is the profile of the high-opt-in verticals.
- **Android no longer gives an opt-in "bonus".** Plan for parity with iOS and treat both platforms as needing the same careful ask.
- **Vendor benchmarks measure the share of the active audience that is opted in.** That is not the same as the conversion rate of a single prompt, so a well-placed system prompt can convert well above these medians.

### Gaps
- **Health & fitness:** I found no reliable per-platform opt-in figure for health & fitness or lifestyle in 2024–2026. Airship's per-vertical charts are images, and the only number recovered, 57.1% median from the example chart, does not state its platform.
- **Productivity:** I found no figure specific to productivity apps, only Airship's combined "Utility & Productivity" bucket.
- **Business of Apps and MobiLoud:** their category numbers could not be checked against the original pages (403 responses).

---

## 2. Effect of a custom pre-permission screen ("priming" or soft ask) before the system dialog, its risks, and what happens if the user declines it

### Takeaway
A soft ask, meaning an in-app screen that explains the benefit before the one-shot system dialog, raises opt-in in every case study found. Reported lifts range from about +12% to +81% relative, and in Cluster's 2014 case from under 40% to 66%. Most of the data is vendor-reported or old.

The main reason to use one is that **declining the in-app pre-prompt does not consume the system prompt**, so you can ask again later. On iOS, one system "Don't Allow" is permanent. On Android, two are.

The risk is a policy grey zone on iOS. Apple's HIG forbids "close/cancel" options on pre-alert screens, but that guidance's listed scope does **not** include notifications.

### Cited Findings
**Effect sizes**
- **[old] Cluster (TechCrunch, 4 Apr 2014), one app on 2014-era iOS:**
  - Explaining the benefit of notifications raised acceptance "from less than 40 percent to 66 percent".
  - A user-triggered "Notify Me" button gave "a 100 percent success rate in iOS push notification permission after tapping 'Notify Me'".
  - With a pre-permission screen for photos, "Only 3 percent of users who clicked 'Give Access' clicked 'Don't Allow'". In addition, "46 percent of people who denied access in a pre-permissions dialog ended up granting access" when asked later.
  - Moving photos to a user-triggered flow raised acceptance "from 67 percent to 89 percent".
  - [TechCrunch, The Right Way To Ask Users For iOS Permissions](https://techcrunch.com/2014/04/04/the-right-way-to-ask-users-for-ios-permissions/)
- **[old] [vendor] NHL app (Airship, 6 Sep 2016):** a "36% increase in notification opt-ins" after adding a soft ask. — [Airship blog](https://www.airship.com/blog/mobile-app-marketing-how-to-series-getting-the-opt-in/)
- **[vendor] Airship 2025 report:**
  - Advice: "Try a 'soft prompt' before sending the system dialogue prompt."
  - Apps running onboarding campaigns see opt-in "as high as 40% above their category average".
  - In-app messages drive "a 14% average increase in opt-in rates among opted-out users".
  - Hawaiian Airlines raised opt-ins by 23%.
  - [Airship 2025 report PDF](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0); [Airship 2026 benchmarks](https://www.airship.com/mobile-app-push-notification-benchmarks-for-2026/)
- **Academic evidence (NN/g, 28 Apr 2019, citing Tan et al., CHI 2014, 15 apps):** users were "12% more likely to grant a permission" when given a reason, even a fairly poor one. In one test, the most compelling reason gave "a whopping 81% lift in granted requests" over the least compelling. The study covered permissions in general, not notifications specifically. — [Nielsen Norman Group, 3 Design Considerations for Effective Mobile-App Permission Requests](https://www.nngroup.com/articles/permission-requests/)
- **Platform guidance:**
  - Android's documentation says research shows "users are much more comfortable with permissions requests if they know why the app needs them". — [Android, Request runtime permissions](https://developer.android.com/training/permissions/requesting)
  - Android also states that context makes users "more likely to grant the notification permission". — [Android, Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)
- **Unsourced vendor and agency claims (treat as noise):**
  - "2–3x higher opt-in": [Plotline](https://www.plotline.so/blog/how-to-improve-push-notification-opt-in-rates).
  - "+15–20 percentage points": various blogs.
  - One agency client went from "under 30% to over 70%" by changing only the timing: [Pykero](https://pykero.com/blog/push-notification-permission-timing).
  - Vendor tables put iOS at 55–65% with a pre-permission screen and 35–45% without, which is not from a controlled study.
  - None of these publish their methodology.
- **[vendor] OneSignal:** small timing and copy changes can shift opt-in "by tens of percentage points" (no baseline given). — [OneSignal docs, Prompt for push permissions](https://documentation.onesignal.com/docs/en/prompt-for-push-permissions)

**What happens if the user declines the pre-prompt**
- **The system attempt is kept.** OneSignal: dismissing the soft prompt "does not consume a system prompt attempt, so you can ask again later". — [OneSignal docs](https://documentation.onesignal.com/docs/en/prompt-for-push-permissions)
- **Cluster's technique** was a first-stage prompt that sets a local flag without using the single system prompt, followed by a later re-ask. — [TechCrunch 2014](https://techcrunch.com/2014/04/04/the-right-way-to-ask-users-for-ios-permissions/)
- **Android's documentation** asks for an escape hatch: "include a 'cancel' or 'no thanks' button that lets the user continue using your app without granting the permission". Its principle is "Don't block the user. Always provide the option to cancel an educational UI flow". — [Android, Request runtime permissions](https://developer.android.com/training/permissions/requesting)
- **Android only requires a rationale screen in one case:** for notifications, "Unless shouldShowRequestPermissionRationale() returns true, your app doesn't need to display the middle screen". Before the first ask, a direct system prompt from a user action, such as tapping a bell button, is acceptable. — [Android, Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)

**Risks and platform rules on iOS**
- **Apple HIG, "Pre-alert screens":**
  - "Include only one button and make it clear that it opens the system alert… Use a term like 'Continue' or 'Next'."
  - "Don't include additional actions in your custom screen or window… don't provide a way for people to leave the screen or window without viewing the system alert — like offering an option to close or cancel."
  - "Don't create a button title that uses 'Allow' or similar terms."
  - **Scope:** "The following guidelines apply to custom views that display before system alerts that request permission to access protected data and resources, including camera, microphone, location, contact, calendar, and tracking." The HIG Privacy page **doesn't mention notifications anywhere**.
  - [Apple HIG, Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)
- **App Store Review Guideline 5.1.1(iv):** "Apps must respect the user's permission settings and not attempt to manipulate, trick, or force people to consent to unnecessary data access." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Guideline 5.1.2(i):** apps "may not require users to enable system functionalities (such as push notifications…) in order to access functionality, content, use the app, or receive monetary or other compensation". This rules out rewarding opt-in, for example with a free tracker. — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Guideline 4.5.4:** "Push Notifications must not be required for the app to function". Promotional pushes need explicit in-app opt-in plus an opt-out. — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Apple HIG, Managing notifications:** "Make sure people can manage their notification settings within your app… you must also provide an in-app settings screen that lets people change their choice." — [Apple HIG, Managing notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)

### Inferences
- **dian-dian's planned flow is a contextual soft ask.** "Shall I remind you each evening?" with a time picker shown after the first dot is the pattern with the strongest evidence. Asking for a time adds commitment and makes the purpose concrete.
- **Use the soft ask to filter, not to persuade.** Only users who say yes see the system dialog. Users who say "not now" keep the one-shot iOS prompt and both Android attempts in reserve.
- **iOS policy is a grey zone.** The HIG's "one button, no cancel" rule is written for protected data and tracking, not notifications, so a "Not now" button on a notification soft ask is not explicitly forbidden and is very common. To stay safe:
  - Do not label the button "Allow". Use "Yes, remind me" or "Continue".
  - Do not show a fake system alert.
  - Do not offer any reward for opting in (guideline 5.1.2(i)).
- **On Android, the wording also matters.** Once the user has denied once, shouldShowRequestPermissionRationale is true and the rationale screen is required by the guidance.

### Gaps
- I found no controlled 2020–2026 A/B test, published by a neutral party, isolating the lift of a notification soft ask on either platform. Every quantified lift is either old (2014, 2016) or vendor-reported without methodology.
- I found no data on whether adding a time picker to the soft ask changes opt-in.
- I found no documented App Review rejection specifically for a "Not now" button on a notification soft ask (rejections reported online concern App Tracking Transparency pre-prompts).

---

## 3. Best moment to ask: at launch, after a value moment, or in context

### Takeaway
Every primary source (Apple, Google, NN/g) and every vendor says **not at first launch, but in context or after a value moment**. Apple's own example fits dian-dian almost exactly: a reminder app should ask "after the person schedules a first task". Given dian-dian's day-1 churn, waiting for the third or fourth launch, which Android's documentation also suggests, would miss most users. Asking in session 1, right after the first dot, follows the contextual pattern.

### Cited Findings
- **Apple:** "Make the request in a context that helps people understand why your app needs authorization. In a task-tracking app that sends reminder notifications, you might make the request after the person schedules a first task. Sending the request in context provides a better experience than automatically requesting authorization on first launch." — [Apple, Asking permission to use notifications](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- **Apple HIG:** "Avoid requesting permission at launch unless the data or resource is required for your app to function." Also: "Ideally, wait to request permission until people actually use an app feature that requires access." — [Apple HIG, Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)
- **Android:**
  - "Before you ask users to grant any permissions, let them familiarize themselves with your app."
  - Good moments to show the prompt include "The user taps an 'alert bell' button", following an account, or submitting a food order.
  - "Alternatively… you might wait until the third or fourth time the user launches your app."
  - Apps targeting API 33+ have "complete control over when the permission dialog is displayed". Apps targeting 12L or lower get the dialog automatically at first activity launch, usually on startup.
  - [Android, Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)
- **Android general principle:** "Ask for a permission in context, when the user starts to interact with the feature that requires it." — [Android, Request runtime permissions](https://developer.android.com/training/permissions/requesting)
- **NN/g (2019):** "Avoid asking for all permissions upfront, when the app is first installed." Also: "Whenever possible, initiate a permission request when the user selects a feature that requires that permission." — [NN/g](https://www.nngroup.com/articles/permission-requests/)
- **[vendor] OneSignal:**
  - Prompting before users understand the app is "the single biggest cause of low opt-in rates".
  - Trigger options, from lowest to highest conversion: on app open, after a set session time (default example: 5 minutes), on a specific user event, or programmatically.
  - Showing the soft prompt right after a user opens or acts on a provisional notification "lifts the 'Allow' rate on the system prompt significantly" (no number given).
  - [OneSignal docs](https://documentation.onesignal.com/docs/en/prompt-for-push-permissions)
- **[vendor] Airship 2025:** "Don't Jump the Gun with a Generic Prompt… Give new customers the space to explore your app's functionality". Airship 2026 adds: time prompts to "high-intent moments" and let users customise notifications "by product category or time of day" to make opting in feel lower-risk. — [Airship 2025 PDF](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0); [Airship 2026](https://www.airship.com/mobile-app-push-notification-benchmarks-for-2026/)
- **[old] Cluster 2014:** user-triggered prompts ("Notify Me") reached about 100% acceptance among users who tapped. — [TechCrunch](https://techcrunch.com/2014/04/04/the-right-way-to-ask-users-for-ios-permissions/)
- **Headspace example (Appcues, undated):** shows a notification prompt at the end of meditation sessions, after the value moment. — [Appcues, Mobile permission priming](https://appcues.com/blog/mobile-permission-priming)
- **Context on churn (Appcues, undated, no primary source given):** roughly 25% of users abandon a new app after one session. — [Appcues](https://appcues.com/blog/mobile-permission-priming)

### Inferences
- **The first-dot moment is the right one.** For dian-dian, it is both a value moment (the user has just seen the year-in-pixels idea work) and a contextual one (the reminder exists to help colour the next dot). The time picker turns it into a user-initiated feature setup rather than a generic ask, close to Apple's "after scheduling a first task".
- **Plan a second contextual trigger for "not now".** Use a natural follow-up moment, for example the second session's first dot ("Want me to nudge you tomorrow?"), or a persistent "Reminders" entry in Settings or on the tracker. Avoid a timed nag.
- **Existing users after the update:**
  - **iOS:** apps that never called requestAuthorization are still `.notDetermined`, so the one-time prompt is available.
  - **Android:** Android's pre-grant on device upgrade covers only apps that already had a notification channel. If dian-dian has never posted notifications, users on Android 13+ will have notifications off.
  - In both cases, trigger the ask in context (for example after their next dot, or from a one-time "new: evening reminders" card) rather than at app launch. See the Android section for the pre-grant rules.

### Gaps
- I found no 2020–2026 dataset comparing first-launch, delayed and contextual timing for notification opt-in with sample sizes. The evidence is platform guidance plus vendor or agency claims.
- I found no data on habit or journaling apps specifically, for example Daylio, Pixels or Finch.

---

## 4. iOS: one-time system prompt, provisional authorization, Time Sensitive notifications and Focus

### Takeaway
On iOS the system prompt is shown **once**. After that, only Settings can change the answer. Provisional authorization grants quiet delivery without a prompt, but the notifications only go to Notification Center history: no banner, no sound, no lock screen. Even tapping "Keep" does **not** give alerts.

That makes provisional a poor fit for an evening reminder whose whole value is being noticed. Developers also report that it can make it hard to obtain banners later.

Time Sensitive is for events "happening now or within an hour" and is not meant for routine daily reminders. Use the default **Active** level, which Focus and Scheduled Summary may hold back.

### Cited Findings
**One-shot prompt**
- "The first time your app makes this authorization request, the system prompts the person to grant or deny the request and records that response. Subsequent authorization requests don't prompt the person." — [Apple, Asking permission to use notifications](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- "Always check your app's authorization status before scheduling local notifications. People can change your app's authorization settings at any time." — [Apple, same page](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)

**Provisional authorization (`.provisional`, introduced in iOS 12)**
- "Use provisional authorization to send notifications on a trial basis."
- "The system delivers provisional notifications quietly — they don't interrupt the person with a sound or banner, or appear on the lock screen. Instead, they only appear in the notification center's history. These notifications also include buttons that prompt the person to keep or turn off the notification."
- "this code doesn't prompt the person… the first time you call this method, it automatically grants authorization… until the person either explicitly keeps or turns off the notification, the authorization status is provisional."
- **What "Keep" does:** the person chooses between "Deliver Immediately" and "Deliver in Scheduled Summary". "Deliver Immediately delivers future notifications quietly. The system authorizes your app to send notifications, but it doesn't give your app permission to show alerts, play sounds, or badge the app icon. Your notification only appears in the notification center history unless they change their notification settings."
- **What "Turn Off" does:** "the system confirms the selection before denying your app authorization".
- [Apple, Asking permission to use notifications](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
- **Developer reports (Apple Developer Forums, June 2023 on iOS 16 and March 2026 on iOS 18):**
  - After Keep → "Deliver Immediately", settings still show "Deliver Quietly", and sound, badge, lock screen and banner all stay off.
  - The suggested workaround is to request only `.provisional` while the status is `.notDetermined`, then request `[.alert, .badge, .sound]` once the status is authorized. That restores badges and sound, but "the Lock screen and Banner settings will still be disabled and I think there is no way to re-request them programmatically". The poster's conclusion: "this makes provisional authorization kind of undesirable for many use cases."
  - No Apple engineer replied.
  - [Apple Developer Forums thread 732230](https://developer.apple.com/forums/thread/732230)
- **Upgrade claims seen elsewhere:**
  - OneSignal says you can show a soft prompt later to convert provisional users, and that the soft prompt after a provisional notification lifts the system "Allow" rate "significantly" (no number). — [OneSignal docs](https://documentation.onesignal.com/docs/en/prompt-for-push-permissions)
  - A 2024 tutorial suggests upgrading through an in-app message that opens Settings (`openSettingsURLString`) rather than through a new prompt. It names the pros (request at launch, no timing problem) and the con ("we will only see our notification in the Notification Center's history"). — [Nil Coalescing, 19 Mar 2024](https://nilcoalescing.com/blog/TrialNotificationsWithProvisionalAuthorizationOnIOS)
  - A developer of a wallpaper app reports that provisional mode "did not improve my opt-in rate". A vendor claim of "8–12% conversion to full authorization" is unsourced. — (search-result summaries of [Medium, Stop asking permission on day one](https://medium.com/@shobhakartiwari/ios-push-notifications-stop-asking-permission-on-day-one-7a2fb2bbe366) and [trtc.io](https://trtc.io/blog/details/push-notification-permission-opt-in-guide); not fetched)
- **Denial carries over:** if a user denies the standard prompt, all notifications for the app are off, provisional ones included. — (OneSignal provisional guide, via search summary: [OneSignal, iOS provisional push](https://documentation.onesignal.com/docs/en/ios-provisional-push-notifications))

**Interruption levels, Time Sensitive and Focus**
- **Four levels:**
  - **Passive:** "Information people can view at their leisure".
  - **Active (default):** "Information people might appreciate knowing about when it arrives".
  - **Time Sensitive:** "requires their immediate attention, like an account security issue or a package delivery".
  - **Critical:** requires an entitlement and is meant for health and safety.
- **When Time Sensitive is appropriate:** "Use the Time Sensitive interruption level only for notifications that are relevant in the moment… make sure the notification is about an event that's happening now or will happen within an hour."
- **The system checks Time Sensitive use:** "The first time a Time Sensitive notification arrives from your app, the system describes how such a notification works and gives people a way to turn it off… the system periodically gives people additional opportunities to evaluate how your Time Sensitive notification is working for them."
- **Focus and Scheduled Summary:** a Focus filters notifications during reserved periods, and "Delivery scheduling lets people choose whether to receive notification alerts immediately or in a summary". "Even though a Focus might delay the delivery of a notification alert, the notification itself is available as soon as it arrives."
- **Honest urgency:** "Build trust by accurately representing the urgency of each notification."
- [Apple HIG, Managing notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)

**Implementation (flutter_local_notifications 23.0.3, pub.dev page as of 2026-11-22)**
- **iOS permission request:** `requestPermissions(alert:, badge:, sound:)` on `IOSFlutterLocalNotificationsPlugin`. Setting the `request*Permission` flags to false in `DarwinInitializationSettings` defers the prompt so it is not shown at init.
- **64-notification cap:** iOS keeps only the 64 most recently scheduled notifications. A single daily repeating notification (`zonedSchedule` with `matchDateTimeComponents`) uses one slot.
- [pub.dev, flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)

### Inferences
- **Do not use provisional as the main path for an evening reminder.**
  - A reminder that only lands silently in Notification Center history will rarely be seen at the moment it matters.
  - "Keep" does not upgrade to banners.
  - Developers report that a provisional-first flow can leave lock-screen and banner delivery off with no programmatic way back.
  - Provisional is better suited to content where users decide later whether they want it. Possible narrow use: users who say "not now" to the soft ask, as a low-pressure trial. Given the forum reports, even that risks locking them into quiet delivery, so test on a device first.
- **Use the default `.active` interruption level.** A daily journaling nudge does not meet the Time Sensitive bar ("happening now or within an hour" and "immediate attention"). Misusing Time Sensitive invites users to switch it off at the system's periodic review. Users with a Sleep or evening Focus may receive the reminder silently or in a summary, which is acceptable.
- **flutter_local_notifications:** turn off `requestAlertPermission`, `requestBadgePermission` and `requestSoundPermission` in `DarwinInitializationSettings` so the plugin's init does not trigger the one-shot prompt at launch. Call `requestPermissions` only after the soft ask's "yes".

### Gaps
- I found no authoritative Apple statement on whether calling `requestAuthorization([.alert, .sound, .badge])` while the status is `.provisional`, before Keep or Turn Off, shows the full system prompt. Sources disagree or stay silent. Test on device before relying on it.
- I found no neutral data on provisional → full conversion rates.
- The pub.dev page summary did not show `provisional` or `critical` parameters for the Darwin permission request. Check the API reference (DarwinFlutterLocalNotificationsPlugin / DarwinInitializationSettings) before relying on them.

---

## 5. Android: POST_NOTIFICATIONS dialog limits, rationale, channels, exact alarms, standby buckets and OEM killing

### Takeaway
On Android 13+, a fresh install has notifications **off by default**. The app can show the POST_NOTIFICATIONS dialog until the user taps "Don't allow" **twice**, after which the denial is permanent. Swiping the dialog away does not count. Show a rationale screen when `shouldShowRequestPermissionRationale()` is true, which is after one denial.

A daily reminder **does not need exact alarms**:
- Inexact alarms fire within about an hour of the requested time on Android 12+ (barring Doze or battery saver).
- `SCHEDULE_EXACT_ALARM` is denied by default for new installs on Android 14+.
- `USE_EXACT_ALARM` is reserved for alarm clock and calendar apps under Play policy.

Further risks: Android 13 puts apps unused for **8 days** in the "restricted" bucket, limited to **one alarm per day** (still enough for one daily reminder). OEM battery killers, Huawei, Xiaomi, OnePlus and Samsung being the worst, can stop scheduled notifications.

### Cited Findings
**POST_NOTIFICATIONS (Android 13 / API 33+)**
- **Fresh installs:** "If a user installs your app on a device that runs Android 13 or higher, your app's notifications are off by default."
- **Who controls the timing:** apps targeting 13+ have "complete control over when the permission dialog is displayed". Apps targeting 12L or lower get the dialog the first time an activity starts after a channel is created, usually on startup. If such an app gets "Don't allow" once, the user isn't prompted again until reinstall or a target-SDK update.
- **User choices:**
  - **Allow:** all channels are enabled.
  - **Don't allow:** all channels are blocked, "similar to… when the user manually turns off all notifications".
  - **Swipe away:** "the state of the notification permission doesn't change."
- **Pre-grant on device upgrade:** "the system automatically pre-grants the permission to all eligible apps when the user upgrades their device to Android 13". To be eligible, the app must "have an existing notification channel and not have its notifications explicitly disabled by the user on a device that runs 12L or lower". This also applies to backup-and-restore onto a new 13+ device.
- **Recommended flow:** a rationale screen ("Get notified!") is only needed when `shouldShowRequestPermissionRationale()` returns true. Check `areNotificationsEnabled()` before sending.
- [Android, Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)
- **Denial limit (Android 11+ rule):** "if the user taps Deny for a specific permission more than once during your app's lifetime of installation on a device, the user will no longer see the system permissions dialog… considered a permanent denial. It is very important to only prompt users for permissions when they need access to a specific feature; otherwise, you might inadvertently lose the ability to re-request permissions." In adb flags, one denial sets `USER_SET`, and "Deny twice" sets `USER_FIXED`. — [Android, Request runtime permissions](https://developer.android.com/training/permissions/requesting)
- **Vendor confirmation:** the system prompt can be shown "twice on Android (Google and Huawei)", and after two denials the user must re-enable in Settings. — [OneSignal docs](https://documentation.onesignal.com/docs/en/prompt-for-push-permissions)
- **Rationale UI:** "If this method returns true, show an educational UI… include a 'cancel' or 'no thanks' button". The app "cannot customize the dialog". — [Android, Request runtime permissions](https://developer.android.com/training/permissions/requesting)

**Notification channels (Android 8+)**
- "all notifications must be assigned to a channel"; "After you create a notification channel, you can't change the notification behaviors. The user has complete control at that point. However, you can still change a channel's name and description."
- **Importance levels:** IMPORTANCE_HIGH (sound plus heads-up), DEFAULT (sound), LOW (no sound), MIN (not in status bar). Consider the system category `CATEGORY_REMINDER`.
- **Deep link to channel settings:** `Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS` with `EXTRA_APP_PACKAGE` and `EXTRA_CHANNEL_ID`.
- **Deleted channels:** the settings screen "displays the number of deleted channels, as a spam prevention mechanism".
- [Android, Create and manage notification channels](https://developer.android.com/develop/ui/views/notifications/channels)

**Exact alarms (Android 12–14+)**
- **Android 14:** `SCHEDULE_EXACT_ALARM` "is no longer being pre-granted to most newly installed apps targeting Android 13 and higher (will be set to denied by default)". It is denied after backup-and-restore too, but pre-granted on device upgrade if the app already had it. Granting it takes a trip to the "Alarms & reminders" special-access settings screen via `ACTION_REQUEST_SCHEDULE_EXACT_ALARM`.
- **USE_EXACT_ALARM:** "Calendar or alarm clock apps… can request the USE_EXACT_ALARM normal permission… Apps will not be able to publish a version of their app with this permission in the manifest unless they qualify based on the policy language."
- **Google's list of cases that don't need exact alarms:** "User-specified action that should happen after a specific time (even if system in idle state): Use an inexact alarm. Specifically, call setAndAllowWhileIdle()."
- [Android 14 behavior change, Schedule exact alarms denied by default](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)
- **Inexact alarm timing:** "On Android 12 (API level 31) and higher, the system invokes the alarm within one hour of the supplied trigger time, unless any battery-saving restrictions are in effect such as battery saver or Doze."
- **Window alarms:** `setWindow` windows under 10 minutes are clipped to 10 minutes.
- **When exact alarms are justified:** "Most apps can schedule tasks and events using inexact alarms. If your app's core functionality depends on a precisely-timed alarm — such as for an alarm clock app or a calendar app — then it's OK to use an exact alarm instead."
- **Reboots:** "By default, all alarms are canceled when a device shuts down". Reschedule on `RECEIVE_BOOT_COMPLETED`.
- [Android, Schedule alarms](https://developer.android.com/develop/background-work/services/alarms/schedule)
- **WorkManager:** periodic work can use a repeat interval plus `flexInterval` (15 minutes minimum). — [Android 14 exact alarms page](https://developer.android.com/about/versions/14/changes/schedule-exact-alarms)

**App Standby Buckets**
- Buckets are active, working set, frequent, rare and restricted. "The bucket determines how frequently the app's jobs run and how often the app can trigger alarms."
- **Restricted bucket on Android 13+:** an app enters it if "The user doesn't interact with your app for a specific number of days… 45 [on 12/12L]. Android 13 reduces the number of days to 8."
- **Restricted bucket limit:** "Your app can invoke one alarm per day. This alarm can be either an exact alarm or an inexact alarm." This applies even while charging.
- **Exemptions** include "Apps with active widgets" and apps holding `USE_EXACT_ALARM`.
- **Tapping a notification** puts the app in the active bucket. Swiping it away does not.
- **Repeated dismissals:** "If the user repeatedly dismisses a notification, the system gives the user the option to block that notification in the future."
- [Android, App Standby Buckets](https://developer.android.com/topic/performance/appstandby)

**OEM battery killing**
- **dontkillmyapp.com ranking (worst first):** Huawei, Xiaomi, OnePlus and Samsung (5/5), then Meizu, Asus, Ulefone/RugOne, Oppo (4/5), and Wiko, Lenovo, Vivo, realme, Motorola, Blackview, Tecno (3/5). AOSP/Pixel, Nokia/HMD and HTC score 0. Samsung's issues are "especially after Android P update". — [dontkillmyapp.com](https://dontkillmyapp.com/)
- **flutter_local_notifications (23.0.3):**
  - "Some OEM Android builds can stop apps running in the background, so scheduled notifications may fail on certain devices". The plugin names Xiaomi and Huawei, cannot fix this itself, and points to dontkillmyapp.com.
  - Samsung reportedly caps scheduled alarms at 500.
  - `RECEIVE_BOOT_COMPLETED` plus `ScheduledNotificationBootReceiver` reschedule after reboot.
  - On Android 13+, call `requestNotificationsPermission()` (target SDK 33 or higher). Exact scheduling requires the exact-alarm permission, via `requestExactAlarmsPermission()` for SCHEDULE_EXACT_ALARM. Without it, the plugin logs an error and a recurring notification is not scheduled.
  - [pub.dev, flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- **Build requirements for 23.0.3:** the pub.dev page lists `compileSdk` 37+, **AGP 9.1.1+**, Java 17 and core library desugaring. — [pub.dev](https://pub.dev/packages/flutter_local_notifications) (as summarised by the fetch tool; check the package changelog)

### Inferences
- **Scheduling for dian-dian:** use the inexact mode, `AndroidScheduleMode.inexactAllowWhileIdle`, which maps to `setAndAllowWhileIdle`. Do not declare `SCHEDULE_EXACT_ALARM` or `USE_EXACT_ALARM`.
  - A reminder at roughly 21:00 does not need second precision, and "within an hour" is the documented Android 12+ bound.
  - A habit or journal reminder does not qualify for USE_EXACT_ALARM, so declaring it risks a Play rejection.
  - SCHEDULE_EXACT_ALARM would add a second, scarier settings trip.
  - Exact mode in flutter_local_notifications fails silently, with no schedule, if the permission is missing.
- **Channels:** create a single dedicated channel, for example "Evening reminder", at IMPORTANCE_DEFAULT with `CATEGORY_REMINDER`. Its name and description show in system settings, so write them in the app's cozy tone.
- **Spend the two Android denials only on users who said "yes" to the soft ask.** On their second visit, show the rationale (when `shouldShowRequestPermissionRationale` is true) before the second and last system dialog.
- **The 8-day restricted bucket is acceptable.** It allows one alarm per day, which is exactly one daily reminder, and tapping the reminder moves the app back to active. A home-screen widget would exempt the app from the restricted bucket entirely, which is a side benefit if a widget is ever built.
- **Existing Android users:** if earlier versions of dian-dian never created a notification channel, no pre-grant applies. Users on Android 13+ need the runtime prompt. Users still on Android 12 or lower get notifications without a prompt.

### Gaps
- I found no 2024–2026 data on the share of scheduled local notifications lost to OEM killing.
- I found no current Android version distribution, the share on 13+ as of late 2026. Not researched in depth.
- I did not fetch the exact wording of the Google Play exact-alarm policy page ([support.google.com/googleplay/android-developer/answer/12253906](https://support.google.com/googleplay/android-developer/answer/12253906)). The Android docs summarise it as calendar and alarm clock apps only.

---

## 6. Re-asking users who declined: settings deep links and doing it without nagging

### Takeaway
Once the system prompt is used up (one denial on iOS, two on Android), the only route is a deep link to the app's notification settings: iOS 16+ `openNotificationSettingsURLString`, Android `ACTION_CHANNEL_NOTIFICATION_SETTINGS`. The app-level `Settings.ACTION_APP_NOTIFICATION_SETTINGS` (API 26+) also exists, but its reference page was not fetched in this session. Google explicitly warns against "persistent nagging".

Good practice:
- Re-offer at natural value moments, not on a timer.
- Cap the number of soft re-asks; Airship's historic rule of thumb is at most 3 asks, 7 days apart.
- Keep a permanent, discoverable "Reminders" setting.
- Show the reminder state honestly (for example "Reminders are off — turn on in Settings").

### Cited Findings
- **Deep link on iOS:** `UIApplication.openNotificationSettingsURLString` is "The URL string you use to deep link to your app's notification settings in the Settings app" and is available from iOS 16.0. — [Apple, openNotificationSettingsURLString](https://developer.apple.com/documentation/uikit/uiapplication/opennotificationsettingsurlstring)
- **Deep link on Android:** `ACTION_CHANNEL_NOTIFICATION_SETTINGS` opens a channel's settings. Google suggests "add an item in your app's settings UI that opens these system settings." — [Android, Notification channels](https://developer.android.com/develop/ui/views/notifications/channels)
- **Google on denial:**
  - "Accept the user's preference: … they should not feel pressured to change their mind… persistent nagging to reconsider is not respectful of their choice."
  - "Don't block the user interface… don't display a full-screen warning message."
  - Be specific about which feature is unavailable and highlight it where it would have appeared.
  - Sample code comment: "respect the user's decision. Don't link to system settings in an effort to convince the user to change their decision."
  - [Android, Request runtime permissions](https://developer.android.com/training/permissions/requesting)
- **Google on usage:** "Users can see the number of daily notifications that your app sends, and they can revoke the permission at any time." — [Android, Notification runtime permission](https://developer.android.com/develop/ui/views/notifications/notification-permission)
- **Apple:** "Make sure people can manage their notification settings within your app… you must also provide an in-app settings screen that lets people change their choice." — [Apple HIG, Managing notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications)
- **[old] [vendor] Airship, 2016:** after "Not Now" or "Remind Me Later", ask "once every 7 days, with no more than 3 prompts total". Trigger the soft ask after a tagged in-app event. — [Airship blog, 6 Sep 2016](https://www.airship.com/blog/mobile-app-marketing-how-to-series-getting-the-opt-in/)
- **[vendor] Airship 2026:** "ask once and re-prompt later" with a contextual in-app message after strong intent signals. In-app messages raise opt-in by 14% on average among opted-out users (2025 report). — [Airship 2026](https://www.airship.com/mobile-app-push-notification-benchmarks-for-2026/); [Airship 2025 PDF](https://growth.airship.com/rs/313-QPJ-195/images/Airship-2025-Push-Notification-Benchmarks-EN.pdf?version=0)
- **[vendor] OneSignal defaults (aggressive):**
  - Soft-prompt frequency "Multiple times (recommended)", max 20 displays with a 2-week gap (about 10 months of re-asking). For lower-engagement apps, a looser 30- or 60-day gap.
  - After the system prompt is exhausted, use `requestPermission(fallbackToSettings: true)` to send users to notification settings, paired with an in-app message explaining the value.
  - [OneSignal docs](https://documentation.onesignal.com/docs/en/prompt-for-push-permissions)
- **[old] Cluster 2014:** "46 percent of people who denied access in a pre-permissions dialog ended up granting access" when asked later at a better time. — [TechCrunch](https://techcrunch.com/2014/04/04/the-right-way-to-ask-users-for-ios-permissions/)
- **Headspace example:** re-offers the notification prompt at the end of meditation sessions, a value moment, instead of forcing it. — [Appcues](https://appcues.com/blog/mobile-permission-priming)
- **Apple HIG Privacy:** the only settings-related line is "People can also view the description — and update their choice — in Settings > Privacy". It gives no rules on re-asking. — [Apple HIG, Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy)

### Inferences
- **Re-ask ladder for dian-dian.** Each rung happens at a value moment, never on app open:
  1. Soft ask after the first dot.
  2. If "not now": one more soft ask after a later dot, for example in session 2 or after the first 3-day streak. Then stop the pop-ups.
  3. Keep a permanent "Evening reminder" toggle and time in Settings. The cozy-toned card can mention it once.
  4. If the system permission is denied (or permanently denied on Android): the toggle opens the system notification settings (iOS 16+ `openNotificationSettingsURLString`, else `openSettingsURLString`; Android app or channel notification settings), with one line explaining why.
- **No pop-up loops.** Airship's old "max 3 asks, 7 days apart" and Google's "no persistent nagging" both argue for this. OneSignal's 20-display default is built for marketing-driven apps and is out of step with dian-dian's cozy tone.
- **Check permission status on resume.** When the user returns from Settings, read the authorization status on iOS or `areNotificationsEnabled()` on Android, schedule the reminder and update the toggle. Users can also revoke the permission silently at any time.

### Gaps
- I found no quantified data (2020–2026) on how many users re-enable notifications through a settings deep link after a system denial.
- I found no neutral data on the best cadence or cap for soft re-asks. The only numbers are Airship's 2016 rule of thumb and OneSignal's defaults, both vendor-set.
