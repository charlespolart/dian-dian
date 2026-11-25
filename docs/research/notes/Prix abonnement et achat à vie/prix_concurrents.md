# Competitor prices: mood, habit, "year in pixels" and journaling apps (Western stores, November 2026)

Method and data provenance (applies to every row below):
- **App Store prices** were scraped on **2026-11-22** from the public web listings `https://apps.apple.com/{us|gb|fr|de|ca|au}/app/id{ID}`, using the "In-App Purchases" block. Apple shows only up to 10 "top" IAPs per app, without the billing period. Many developers name them generically ("Daylio Premium"), and the lists mix current, introductory, discount, legacy and A/B-test price points. **Where the period isn't in the IAP name, I inferred it from price ordering and second sources. Those cases are flagged "(inferred)".**
- **App Store popularity** comes from the iTunes Lookup API on 2026-11-22: `https://itunes.apple.com/lookup?id={ID}&country=us`. Counts are US ratings unless stated otherwise.
- **Google Play** was scraped on 2026-11-22 from `https://play.google.com/store/apps/details?id={pkg}&hl=en_US&gl=US` (also gl=GB/FR/DE). Play's web listing shows **only a min–max IAP range per item**, never per-plan prices. Install counts are the public bucket plus the exact count embedded in the page data, which is the figure that scrapers such as google-play-scraper call "realInstalls".
- Dian Dian reference: $8.99/yr (7-day trial), $22.99 lifetime, US storefront. Free tier is 3 trackers plus a banner ad.

## Q1. Direct competitors: business models and price points

### Takeaway
Most apps in this category are **free + subscription**, and about half also sell a **lifetime** option. The big, VC-style apps (Finch, Day One, Bearable, Me+, Atoms) sell subscriptions only, at **$35–70/yr**. The pixel and habit-grid indie apps cluster much lower, at **$8–20/yr and $20–40 lifetime**, and a few are one-time only (Streaks $5.99, Diarium $14.99, My Wonderful Days $14.99, Pixels+ $4.99). A **3-item free tier** is a common pattern: Habitify gives 3 habits, Pixa 3 logs and Way of Life 3 habits, and HabitKit allows "a few" (4 according to one review).

### Cited Findings

**Master table: US App Store prices (iOS), with GB/EUR/Play where found.** "mo/yr/LT" means monthly / yearly / lifetime. All App Store data is from 2026-11-22 unless stated otherwise.

| # | App (developer) | Model | US iOS mo / yr / LT | GB iOS | FR / DE iOS (EUR) | Google Play (US range, installs) | Free tier / trial | Popularity (US iOS ratings) | Sources |
|---|---|---|---|---|---|---|---|---|---|
| 1 | **Daylio** (Relaxio) – mood + activities, year-in-pixels view | Hybrid (sub + LT) | **$4.99 / $35.99 / $59.99**. Also $17.99 and $23.99 tiers (likely discounted yearly offers, inferred) | £3.99 / £29.99 / £49.99 (also £14.99, £19.99) | 4,99 / 35,99 / 59,99 € both (also 17,99 and 23,99 €). CA $6.99/$47.90/$79.99; AU $7.99/$59.99/$79.99 | $0.99–$79.99 per item; 10M+ (≈19.6M); 465K reviews, 4.7 | Free core (moods, activities, stats, CSV). Premium: advanced stats, PDF export, unlimited goals, more icons/colours. **7-day trial** | 62,592 (4.77) | [App Store US](https://apps.apple.com/us/app/id1194023242), [GB](https://apps.apple.com/gb/app/id1194023242), [FR](https://apps.apple.com/fr/app/id1194023242), [DE](https://apps.apple.com/de/app/id1194023242), [Play](https://play.google.com/store/apps/details?id=net.daylio), [ChoosingTherapy review (upd. 2026-07-29): $4.99/mo, $35.99/yr, 7-day trial](https://www.choosingtherapy.com/daylio-app-review/), [Headway: LT $59.99](https://makeheadway.com/blog/daylio-review/) |
| 2 | **Pixels** (Teo Vogel) – the original "year in pixels" mood app | One-time unlock + optional cloud subscription | **Pixels+ $4.99** (period not stated. AlternativeTo calls it a one-time licence at "$2", likely outdated). Cloud+ $1.99 and $21.99 (probably mo/yr, inferred) | Pixels+ £4.99; Cloud+ £1.99 / £19.99 | Pixels+ 5,99 €; Cloud+ 1,99 / 24,99 € (FR = DE). CA Pixels+ $6.99; AU $7.99 | $1.49–$21.99; **1M+ (≈1.14M)**; 24.4K reviews, 4.6 | "No ads, no tracking" | 45 (Android-centric) | [App Store US](https://apps.apple.com/us/app/id1668460700), [Play](https://play.google.com/store/apps/details?id=ar.teovogel.yip), [AlternativeTo](https://alternativeto.net/software/pixels-mood-and-mental-health/about) |
| 3 | **Pixa – My Year in Pixels** (Tulip Tech) | Hybrid | **$1.99 / $19.99 / $39.99** (also $0.99 mo and $17.99 yr tiers) | £1.99 / £19.99 / £39.99 (also £0.99, £17.99) | FR 1,99 / 22,99 / 44,99 €; DE 1,99 / 22,99 / 39,99 € (also 0,99 and 17,99 €). CA $2.99/$24.99/$49.99; AU $2.99/$29.99/$59.99 | $1.99–$41.99; 100K+ (≈143K); 1.83K reviews | **Free = 3 logs**; monthly, annual and lifetime offered | 2,028 | [App Store US](https://apps.apple.com/us/app/id6480351200) (description: "FREE version … three logs"), [Play](https://play.google.com/store/apps/details?id=com.pixa.app) |
| 4 | **Bearable** – symptom/mood tracker | Subscription only (no LT) | **$6.99 / $34.99** ("often discounted to $18.99"). The App Store also shows $4.49–$49.99 tiers | £6.49 / £31.99 (inferred from tier order) | 7,49 / 37,99 € (inferred) | $4.99–$199.99; 500K+ (≈793K); 10.7K reviews | "Most features free"; 7-day trial per ChoosingTherapy (search snippet, not fetched). No lifetime | 6,762 | [bearable.app/pricing (official)](https://bearable.app/pricing), [App Store US](https://apps.apple.com/us/app/id1482581097), [Play](https://play.google.com/store/apps/details?id=com.bearable), [ChoosingTherapy](https://www.choosingtherapy.com/bearable-app-review/) |
| 5 | **How We Feel** (non-profit) | Free | No IAP on iOS | – | – | Play lists $4.99–$299.99 per item (nature unknown, possibly donations: unverified); 500K+ (≈861K) | Fully free | 30,455 | [App Store US](https://apps.apple.com/us/app/id1562706384), [Play](https://play.google.com/store/apps/details?id=org.howwefeel.moodmeter) |
| 6 | **Finch** – self-care pet | Subscription only | **$9.99 / $69.99** (Finch help center via RecurDash, verified 2026-07-07). The App Store also lists $5.99, $34.99–$59.99 (discount/legacy) | £9.99 / £69.99 (top tiers) | 9,99 / 79,99 € (top tiers). CA $12.99/$99.99; AU $14.99/$99.99 | $1.99–$399.99; **10M+ (≈16.8M)**; 644K reviews, 4.9 | Generous free tier; no lifetime | **778,291** (4.95) | [RecurDash](https://recurdash.com/subscription-pricing/finch), [Adapty paywall library](https://adapty.io/paywall-library/finch/), [App Store US](https://apps.apple.com/us/app/id1528595748), [Play](https://play.google.com/store/apps/details?id=com.finch.finch) |
| 7 | **Moodnotes** (Mosaic) | Subscription | $14.99 / yr tiers $29.99–$89.99 (unclear which is current). Legacy "Pro" $2.99 | £12.99 / £29.49–£79.99 | 14,99 / 32,99–89,99 € | iOS only | Free trial (unspecified) | 10,961. **Stale: last update 2024-10-24** | [App Store US](https://apps.apple.com/us/app/id1019230398) |
| 8 | **Reflectly** – AI journal | Subscription | Generic "Reflectly Premium" tiers $4.99–$59.99. Periods can't be assigned | £4.99–£58.99 | DE has a 99,99 € "Growth Bundle: Yearly" | $7.49–$299.99; 1M+ (≈3.65M); 40.7K reviews | Free trial | 81,673 | [App Store US](https://apps.apple.com/us/app/id1241229134), [Play](https://play.google.com/store/apps/details?id=com.reflectlyApp) |
| 9 | **stoic.** – journal | Hybrid (sub + very high LT) | Premium $6.99 mo / $39.99 yr (also $17.99, $26.99, inferred). AI tier $12.99 mo, $69.99–$99.99 yr. **LT $299.00** | Same numbers in £, LT £299 | Premium 7,99 / 39,99 €; AI 14,99 / 69,99–99,99 €; FR "Lifetime Plan with AI" **449 €** | $6.99–$799.99; 100K+ (≈454K) | Free journaling without Premium | 36,353 | [App Store US](https://apps.apple.com/us/app/id1312926037), [FR](https://apps.apple.com/fr/app/id1312926037), [Play](https://play.google.com/store/apps/details?id=com.stoicroutine.stoic) |
| 10 | **Journey** – diary | Hybrid | **$6.99 / $49.99 / $199** (description: "US$6.99/monthly or US$49.99/year"). Legacy $3.99 mo, $29.99 yr, $17.99 | £6.99 / £49.99 / £199 | 7,99 / 59,99 / 229 € | $0.99–$199.99; 5M+ (≈5.1M); 94.4K reviews | Free + trial "if offered" | 5,067 | [App Store US](https://apps.apple.com/us/app/id1300202543), [Play](https://play.google.com/store/apps/details?id=com.journey.app) |
| 11 | **Day One** – journal | Subscription only | Silver **$8.99 / $49.99**; Gold $74.99/yr | £8.99 / £49.99; Gold £69.99 | 9,99 / 59,99 €; Gold 79,99 € | $2.99–$99.99; 1M+ (≈1.9M) | Free "Basic": unlimited text, 1 photo per entry, 1 device. **1-month trial** | 119,063 | [dayoneapp.com/pricing (official)](https://dayoneapp.com/pricing/), [App Store US](https://apps.apple.com/us/app/id1044867788), [Play](https://play.google.com/store/apps/details?id=com.dayoneapp.dayone) |
| 12 | **DailyBean** (BlueSignum) – one-tap mood journal | Subscription "passes" + cosmetics | **$3.99 mo / $19.99 yr**; 30-day pass $0.99, 100-day $1.99; stickers $0.99–$1.99 | Monthly £2.99/£4.99/£5.99; annual £19.99/£24.99/£34.99 (several tiers) | FR monthly 2,99/4,99 €; annual 14,99–39,99 € | $0.99–$84.99; 1M+ (≈4.3M); 75.9K reviews | Not verified (ads?) | 71,214 | [App Store US](https://apps.apple.com/us/app/id1553223828), [GB](https://apps.apple.com/gb/app/id1553223828), [Play](https://play.google.com/store/apps/details?id=com.bluesignum.bluediary) |
| 13 | **Habitify** | Hybrid, 2 tiers since 2026-04-06 | **Pro $8.99 / $49.99 / $119.99 LT**; **Plus $29.99/yr (annual only)**; Pro family $89.99/yr. A legacy "PRO Lifetime" $59.99 is still listed | Pro £6.99 / £39.99 / £119.99 (also £89.99, £59.99); Plus £21.99 | Pro 7,99 / 39,99 / 129,99 € (also 95,99 and 69,99 €) | $0.99–$99.99; 500K+ (≈686K) | **Free = 3 habits**, 1 reminder each. **7-day Pro trial**. LT hidden during an iOS trial | 7,210 | [App Store US](https://apps.apple.com/us/app/id1111447047), [Help center (2026-08-03)](https://intercom.help/habitify-app/en/articles/6113487-premium-plan-pricing), [Changelog 2026-04-06](https://feedback.habitify.me/changelog/new-tiered-pricing), [old pricing page](https://habitify.me/new-pricing), [Play](https://play.google.com/store/apps/details?id=co.unstatic.habitify) |
| 14 | **HabitKit** (Sebastian Röhl, indie) – GitHub-style habit grid | Hybrid | **Three IAP ladders listed**: $0.99/$5.99/$14.99, **$1.99/$11.99/$29.99**, $4.99/$24.99/$59.99 (mo/yr/LT). Most likely standard = middle ladder (inferred; the others look like discount/price-test ladders) | £1.99 / £11.99 / £29.99 (and £0.79/£4.99/£14.99, £4.99/£24.99) | 1,99 / 12,99 / 34,99 € (and 0,99/5,99/17,99 €, 5,99/29,99/69,99 €). CA $2.99/$14.99/$39.99; AU $2.99/$19.99/$49.99 | $0.99–$37.99; 500K+ (≈777K); 12.3K reviews | Free with "a few habits" (4 per review); **no ads** | 2,619 | [App Store US](https://apps.apple.com/us/app/id6443918070), [Play](https://play.google.com/store/apps/details?id=com.roehl.habitkit), [productivity-apps.com review](https://productivity-apps.com/apps/habitkit-habit-tracker) |
| 15 | **Streaks** (Crunchy Bagel) | **Paid upfront, one-time** | **$5.99** app price, no IAP | £5.99 | 6,99 € | iOS/Apple only | Up to 24 habits; no ads | 27,353 | [App Store US](https://apps.apple.com/us/app/id963034692), iTunes Lookup API |
| 16 | **Productive** (Mosaic) | Subscription | $10.99 mo; yr tiers $19.99–$79.99; weekly $5.99 with free trial; legacy one-time "Upgrade" $3.99 | £9.99; £17.49–£79.99 | 11,99 €; 19,99–89,99 € | Not found on Play | Free trial; premium = unlimited habits | 91,063 | [App Store US](https://apps.apple.com/us/app/id983826477) |
| 17 | **Way of Life** | iOS subscription; Android one-time | iOS "Premium" $4.99, $14.99, $29.99 (periods unlabelled). Macaron says iOS is $4.99/mo with no LT (unofficial) | £4.99 / £14.99 / £29.99 | 5,99 / 17,99 / 34,99 € | **$4.99–$6.49** (Android one-time ≈$6.49 per Macaron); 500K+ (≈744K) | Free = 3 habits (Macaron, unofficial) | 5,349 | [App Store US](https://apps.apple.com/us/app/id393159800), [Play](https://play.google.com/store/apps/details?id=com.wayoflife.app), [Macaron review](https://macaron.im/blog/way-of-life-habit-tracker-review) |
| 18 | **(Not Boring) Habits** | Hybrid + paid skins | **!Habits Plus $14.99/yr, $59.99 LT**; "Super !Boring" bundle $7.99/mo, $29.99/yr; skins $4.99–$9.99 | Same numbers in £ | Plus 17,99 € / LT 69,99 €; Super 8,99 / 34,99 €. CA $19.99/$79.99; AU $22.99/$99.99 | iOS only | No ads | 6,397 | [App Store US](https://apps.apple.com/us/app/id1593891243), [Adapty](https://adapty.io/paywall-library/not-boring-habits/) |
| 19 | **Me+** (Enerjoy) – routine/self-care | Subscription only | **$9.99 / $39.99** (per description); many other tiers $7.99–$69.99 incl. 3-month $19.99/$29.99 | £8.99 / £35.99 … £69.99 | 10,49 € mo; 42,99–69,99 € yr | $7.99–$69.99 (same range as iOS); **10M+ (≈23.9M)**; 866K reviews | Free trial "if offered" | 249,016 | [App Store US](https://apps.apple.com/us/app/id1596403446), [Play](https://play.google.com/store/apps/details?id=daily.planner.routine.habits) |
| 20 | **EMMO** – cute mood diary | Subscription + cosmetics | $4.99 mo; "Plus Annual" $39.99; "EMMO PRO" $149.99 (period unknown, maybe LT); stickers $0.99 | £3.99 / £29.99 / £149.99 | 3,99 / 34,99 / 179,99 € | **$0.99–$16.99** (much lower than iOS); 1M+ (≈2.75M) | – | 29,529 | [App Store US](https://apps.apple.com/us/app/id1508326506), [Play](https://play.google.com/store/apps/details?id=emmo.diary.app) |
| 21 | **Moodflow** – year-in-pixels mood | Subscription (periods unlabelled) | "Moodflow Plus" $3.49, $9.99, $14.99 | £2.99 / £7.99 / £13.49 | 3,49 / 8,99 / 14,99 € | $3.49–$16.99; 100K+ (≈313K) | – | 223 | [App Store US](https://apps.apple.com/us/app/id1450736806), [Play](https://play.google.com/store/apps/details?id=com.moodpixel) |
| 22 | **Moodlight / Mood AI** (Monkey Taps) | Subscription | "Premium Moodlight" $29.99; "Self Growth Essentials" $139.99 | £29.99 / £129.99 | 34,99 / 149,99 € | **single $19.99**; 100K+ (≈223K) | – | 23,821 | [App Store US](https://apps.apple.com/us/app/id6443673361), [Play](https://play.google.com/store/apps/details?id=app.monkeytaps.moodlight) |
| 23 | **Foxtale** (Bearable Ltd, launched Dec 2025) – mood journal | Subscription | **$8.99 / $49.99**; "Early adopter" yearly $24.99; other Plus tiers $24.99/$34.99 | £8.99 / £49.99 | 9,99 / 59,99 € | $8.99–$49.99 (same as iOS); 10K+ (≈27.6K) | – | 3,079 | [App Store US](https://apps.apple.com/us/app/id6742490968), [Play](https://play.google.com/store/apps/details?id=app.bearable.lumifox) |
| 24 | **Habit Tracker** (Inner Grow / "davetech") | Hybrid, **very cheap** | **$4.99 / $7.99 / $19.99 LT**; also "Habit Promo" $14.99, "Enhance Yourself" $9.99, "Lifetime Family" $12.99 | £2.99 / £7.99 / £9.99 LT | 2,99 / 8,99 / 9,99 € LT. CA $3.99/$9.99/$12.99; AU $4.99/$12.99/$14.99 | iOS only (not found on Play) | – | **149,093** | [App Store US](https://apps.apple.com/us/app/id1438388363), [GB](https://apps.apple.com/gb/app/id1438388363) |
| 25 | **Atoms** (Atomic Habits) | Subscription only | **$4.99 / $39.99** | £4.99 / £39.99 | 5,99 / 44,99 € | $4.99–$39.99 (identical); 100K+ (≈237K) | – | 10,820 | [App Store US](https://apps.apple.com/us/app/id6474421906), [Play](https://play.google.com/store/apps/details?id=app.getatoms.android) |
| 26 | **Grit** | Hybrid, several ladders | mo $1.99/$2.99/$9.99; yr $12.99/$29.99; LT $19.99/$24.99/$44.99 | yr £12.99/£29.99; LT £19.99/£24.99 | yr 14,99/19,99/29,99 €; LT 19,99/29,99/49,99 € | iOS only | – | 16,423 | [App Store US](https://apps.apple.com/us/app/id6446997766) |
| 27 | **everyday** – habit grid | Hybrid | **$7.49 / $29.99 / $99.99** (also $49.99 LT) | same numbers in £ | 7,49 / 29,99 / 99,99 € (also 59,99 €) | – | "Free forever" + Premium | 4,558 | [App Store US](https://apps.apple.com/us/app/id1394150432) |
| 28 | **Strides** | Hybrid | "Strides Plus" $4.99–$149.99 (unlabelled; description says monthly, annual, or one-time lifetime) | £4.99–£149.99 | 5,49–179,99 € | $4.99–$29.99; new Android app (1K+) | Free trackers limited | 19,284 | [App Store US](https://apps.apple.com/us/app/id672401817), [Play](https://play.google.com/store/apps/details?id=com.strides.android) |
| 29 | **Grid Diary** | Subscription only | **$4.99 / $29.99** | £4.99 / £29.99 | 5,99 / 34,99 € | – | – | 963 | [App Store US](https://apps.apple.com/us/app/id1392523148) |
| 30 | **My Wonderful Days** – journal | **One-time unlock** + optional supporter sub | **$14.99 unlock**; supporter $9.99 | £14.99 | 17,99 € | – | Free = 14 entries | 7,298 | [App Store US](https://apps.apple.com/us/app/id434356065) |
| 31 | **Habit Pixel** (indie) – pixel-styled streak tracker | Hybrid | **$2.99 / $14.99 / $19.99 or $29.99 LT** | £2.69 / £13.49 / £19.99–£29.99 | FR 2,69 / 12,49 / 22,99–34,99 €; DE 2,39 / 12,49 / 22,99–34,99 €. CA $3.79/$18.99/$26.99–$39.99; AU $4.79/$22.49/$33.99–$49.99 | $2.99–$34.99; 50K+ (≈90K); 918 reviews | – | 26 | [App Store US](https://apps.apple.com/us/app/id6742632433), [Play](https://play.google.com/store/apps/details?id=com.habitpixel.app) |
| 32 | **Loop Habit Tracker** | Free, open source | – | – | – | Optional IAP $0.99–$11.99 (likely donations, inferred); **5M+ (≈8.0M)**; 63.8K reviews, 4.7 | Fully free, no ads | Android only | [Play](https://play.google.com/store/apps/details?id=org.isoron.uhabits) |
| 33 | **HabitNow** | One-time premium (per AlternativeTo, undated) | – | £0.89–£11.99 | 1,09–11,99 € | **$0.99–$11.99**; **5M+ (≈7.3M)**; 93.8K reviews, 4.8 | Free + one-time Premium (≈$11 per AlternativeTo) | Android only | [Play](https://play.google.com/store/apps/details?id=com.habitnow), [AlternativeTo](https://www.alternativeto.net/software/habitnow/about/) |
| 34 | **Diarium** – journal | **One-time** | – | £13.49 | FR 15,99 €; DE 14,99 € | **single $14.99**; 500K+ (≈827K); 23.2K reviews, 4.8 | – | (Android checked) | [Play](https://play.google.com/store/apps/details?id=partl.Diarium) |
| 35 | **Moodpress** – mood diary | Sub/IAP | – | £0.89–£34.99 | 0,99–49,99 € | $0.99–$49.99; 1M+ (≈3.0M); 40.1K reviews | – | Android | [Play](https://play.google.com/store/apps/details?id=com.selfcare.diary.mood.tracker.moodpress) |
| 36 | **Bullet Journal Companion** | Paid upfront | $4.99 | £4.99 | 5,99 € | – | – | 2,008. **Stale: last update 2023-11** | [App Store US](https://apps.apple.com/us/app/id1201419241) |

Other data points:
- Apple's own **Journal** app is free and has 345,475 US ratings. It is a zero-price baseline for basic journaling ([App Store / iTunes Search API](https://apps.apple.com/us/app/id6447391597)).
- Habitify's free tier is "up to 3 active habits, with 1 reminder per habit". Its Pro monthly plan on iOS "requires a 12-month commitment" ([Habitify help center, 2026-08-03](https://intercom.help/habitify-app/en/articles/6113487-premium-plan-pricing)).
- Habitify's older pricing page still shows Premium at $10/mo, $29.99/yr and **$59.99 lifetime** with a 3-habit free plan ([habitify.me/new-pricing](https://habitify.me/new-pricing)). The App Store now lists Pro lifetime at **$119.99** and Plus at $29.99/yr ([App Store US](https://apps.apple.com/us/app/id1111447047)).
- Day One's free "Basic" plan is $0. Silver is $49.99/yr and Gold $74.99/yr, with a "free 1 month trial inside the app" ([dayoneapp.com/pricing](https://dayoneapp.com/pricing/)).
- Bearable: "$34.99 per year, often discounted to $18.99", $6.99 monthly. Users who can't afford it can get a sponsored subscription through the "Bearable Heroes" programme ([bearable.app/pricing](https://bearable.app/pricing)).
- Pixa's description: "The FREE version of the app allows you to create three logs… Pixa Premium offers three options: a monthly subscription, an annual subscription, and a one-time payment for lifetime premium access" ([App Store US](https://apps.apple.com/us/app/id6480351200)).
- HabitKit's description: "free to use with a few habits… Pro unlocks unlimited habits, charts and statistics, home screen widgets… Subscribe monthly or yearly, or pay once and keep Pro forever with the lifetime option. No ads." ([App Store US](https://apps.apple.com/us/app/id6443918070)).

### Inferences
- **Model split (sample of ~30 paid apps):**
  - **Subscription only:** Finch, Day One, Bearable, Foxtale, Me+, Atoms, Grid Diary, Moodnotes, Reflectly, Productive, DailyBean, Moodlight.
  - **Hybrid with lifetime:** Daylio, Pixa, Habitify Pro, HabitKit, Not Boring Habits, Inner Grow Habit Tracker, everyday, Habit Pixel, Grit, Journey, stoic., Strides, probably EMMO.
  - **One-time only:** Streaks, Pixels+, My Wonderful Days, Diarium, HabitNow, Way of Life on Android, Bullet Journal Companion.
  - **Free:** How We Feel, Loop, Apple Journal.
  - Lifetime is the norm among **indie habit / pixel-grid apps**. It is rare among VC-backed or "wellness brand" apps.
- The **closest competitors to Dian Dian** in look and scope are Pixa ($19.99/yr, $39.99 LT, 3 free logs), HabitKit ($11.99/yr, $29.99 LT), Habit Pixel ($14.99/yr, $19.99–29.99 LT), Daylio ($35.99/yr, $59.99 LT), Pixels (≈$5 one-time) and Inner Grow Habit Tracker ($7.99/yr, $19.99 LT). Dian Dian is priced at the bottom of this cluster.
- **Many apps run several price ladders at once.** HabitKit, Grit, DailyBean, Bearable, Finch and Productive each list several yearly prices, which points to discount, win-back or A/B tests. Raising a "list" price while showing discounted intro offers is common.
- Monthly price vs yearly: among the apps with clear monthly and yearly prices, yearly ≈ **4–10× monthly** (median ≈ 5.6×). Examples: Daylio 7.2×, Pixa 10×, Bearable 5×, Finch 7×, Day One 5.6×, Habitify 5.6×, HabitKit 6×, Habit Pixel 5×, Atoms 8×, everyday 4×. Inner Grow is an outlier at 1.6×. Applied to Dian Dian's $8.99/yr, this suggests a **monthly of about $1.49–$1.99**, in line with HabitKit ($1.99) and Pixa ($1.99).
- Local pricing pattern on the App Store: **GBP is usually the same number as USD** (e.g. $29.99 → £29.99 for HabitKit LT, Not Boring, Way of Life), or one tier lower (Daylio $35.99 → £29.99). **EUR is usually the same as USD or one tier higher** (HabitKit $29.99 → 34,99 €; Pixa $19.99 → 22,99 €; Streaks $5.99 → 6,99 €; Daylio $35.99 → 35,99 €). CA and AU are typically 1.3–1.7× the USD number. For Dian Dian's $8.99/$22.99, the market norm would land around **8,99–9,99 € / £7.99–8.99** and **22,99–24,99 € / £19.99–22.99**.

### Gaps
- Apple's web listing doesn't show billing periods or which IAP is the current default on the paywall. Monthly/yearly assignments for Daylio, Finch, Bearable, DailyBean, Moodflow, Reflectly, Stoic, Way of Life, Strides and EMMO are therefore partly inferred.
- **Trial lengths** were found only for Daylio (7 days), Day One (1 month), Habitify Pro (7 days) and Bearable (7 days, secondary source). Pixa, HabitKit, Finch, Stoic, Habit Pixel and others are unknown.
- I didn't verify whether the free tiers show ads for Daylio, DailyBean, EMMO, Pixa or Habit Pixel. Pixels, HabitKit, Not Boring Habits and Streaks state "no ads".
- No public Sensor Tower or AppFigures download/revenue estimates were collected. Popularity uses US iOS rating counts and Play install counts instead.
- I didn't confirm whether Pixels+ ($4.99) is one-time or a subscription. AlternativeTo says one-time, at an outdated price.

## Q2. Do prices differ between the App Store and Google Play for the same app?

### Takeaway
Parity is the stated norm, but in this category **divergence is common, especially for indie apps and lifetime SKUs**. Google Play's web listing only exposes min–max ranges. Of the 17 apps where I could compare both stores, roughly a third show identical ranges, while the rest show different floors or ceilings. A few differ structurally: Way of Life is a subscription on iOS but a one-time purchase on Android, and EMMO's Play ceiling is $16.99 against $149.99 on iOS.

### Cited Findings
- RevenueCat: "most subscription apps have parity in their pricing structures between Android and iOS, but not all", and less-known apps "have more freedom to find the optimal pricing strategy through price testing" ([RevenueCat Android launch guide](https://www.revenuecat.com/blog/growth/android-launch-guide-for-ios-apps)).
- **Identical ranges on both stores:**
  - Atoms: iOS $4.99 / $39.99; Play $4.99–$39.99 ([iOS](https://apps.apple.com/us/app/id6474421906), [Play](https://play.google.com/store/apps/details?id=app.getatoms.android)).
  - Foxtale: iOS $8.99 / $49.99; Play $8.99–$49.99 ([iOS](https://apps.apple.com/us/app/id6742490968), [Play](https://play.google.com/store/apps/details?id=app.bearable.lumifox)).
  - Me+: iOS $7.99–$69.99; Play $7.99–$69.99 ([iOS](https://apps.apple.com/us/app/id1596403446), [Play](https://play.google.com/store/apps/details?id=daily.planner.routine.habits)).
- **Different ranges:**
  - **Daylio:** the top iOS IAP is LT $59.99, but Play shows up to $79.99 ([iOS](https://apps.apple.com/us/app/id1194023242), [Play](https://play.google.com/store/apps/details?id=net.daylio)).
  - **HabitKit:** iOS LT $29.99 (plus a $59.99 "HabitKit Pro" SKU); Play ceiling $37.99 ([iOS](https://apps.apple.com/us/app/id6443918070), [Play](https://play.google.com/store/apps/details?id=com.roehl.habitkit)).
  - **Habit Pixel:** iOS max $29.99; Play max $34.99 ([iOS](https://apps.apple.com/us/app/id6742632433), [Play](https://play.google.com/store/apps/details?id=com.habitpixel.app)).
  - **Pixa:** iOS $0.99–$39.99; Play $1.99–$41.99 ([iOS](https://apps.apple.com/us/app/id6480351200), [Play](https://play.google.com/store/apps/details?id=com.pixa.app)).
  - **Moodflow:** iOS $3.49–$14.99; Play $3.49–$16.99 ([iOS](https://apps.apple.com/us/app/id1450736806), [Play](https://play.google.com/store/apps/details?id=com.moodpixel)).
  - **Pixels:** iOS $1.99–$21.99 (+ Pixels+ $4.99); Play $1.49–$21.99 ([iOS](https://apps.apple.com/us/app/id1668460700), [Play](https://play.google.com/store/apps/details?id=ar.teovogel.yip)).
  - **Habitify:** iOS Pro LT $119.99; Play ceiling $99.99 ([iOS](https://apps.apple.com/us/app/id1111447047), [Play](https://play.google.com/store/apps/details?id=co.unstatic.habitify)).
  - **Moodlight:** iOS "Premium" $29.99; Play only $19.99 ([iOS](https://apps.apple.com/us/app/id6443673361), [Play](https://play.google.com/store/apps/details?id=app.monkeytaps.moodlight)).
  - **EMMO:** iOS up to $149.99 (and $39.99 annual); Play $0.99–$16.99 ([iOS](https://apps.apple.com/us/app/id1508326506), [Play](https://play.google.com/store/apps/details?id=emmo.diary.app)).
  - **Way of Life:** iOS "Premium" $4.99–$29.99; Play $4.99–$6.49, with Android described as a one-time ≈$6.49 ([iOS](https://apps.apple.com/us/app/id393159800), [Play](https://play.google.com/store/apps/details?id=com.wayoflife.app), [Macaron](https://macaron.im/blog/way-of-life-habit-tracker-review)).
  - **stoic.:** iOS LT $299; Play ceiling $799.99 ([iOS](https://apps.apple.com/us/app/id1312926037), [Play](https://play.google.com/store/apps/details?id=com.stoicroutine.stoic)).
  - **Finch:** iOS top IAPs max $69.99; Play ceiling $399.99 ([iOS](https://apps.apple.com/us/app/id1528595748), [Play](https://play.google.com/store/apps/details?id=com.finch.finch)).
- Prices can also differ between the app and the web. Habitify had a help-center article titled "Troubleshooting: why lifetime shows $90 in the app when the website mentions $60". The page now returns 404, so only the URL/title is known ([URL](https://intercom.help/habitify-app/en/articles/12545806-troubleshooting-why-lifetime-shows-90-in-the-app-when-the-website-mentions-60)).
- Google Play charges developers a lower fee than the App Store in a subscriber's first year. One third-party analysis estimates Android keeps ≈21% more per unit of revenue in year one (developer-side economics, not consumer price) ([search summary citing thesocialoutline.com](https://thesocialoutline.com/blog/ios-vs-android-subscription-economics)). This is a weak, secondary source.

### Inferences
- Subscription-first apps run by larger teams (Atoms, Me+, Bearable's Foxtale) keep the same price range on both stores. Indie and hybrid apps often differ, mostly at the **lifetime / top SKU** (Daylio, HabitKit, Habit Pixel, Pixa, Habitify) or in the overall model (Way of Life, EMMO). Android ceilings are not systematically lower: Daylio, HabitKit, Habit Pixel and Pixa are *higher* on Play.
- Shipping identical prices on both stores is the safe default. A different Android price is common enough that it wouldn't stand out.

### Gaps
- Exact per-plan Google Play prices aren't publicly visible, so "same range" doesn't prove the same plan prices, and a different max can come from a legacy or test SKU.
- I found no dataset quantifying how often iOS and Android prices differ across the category. The "roughly a third identical" figure is from this 17-app sample only.

## Q3. Lifetime price as a multiple of yearly; apps adding or removing lifetime

### Takeaway
In this category, **lifetime ≈ 2.5× yearly (median)**, with a range of 1.3× to 7.5×. That is well below the 5–12× rule of thumb RevenueCat gives for subscription businesses. Dian Dian's $22.99 / $8.99 = **2.56×**, right at the category median. I found **no documented case of an app in this niche removing lifetime**. Habitify instead **repriced it upward** ($59.99 → $119.99 for Pro, with a new annual-only Plus tier, April 2026).

### Cited Findings
- **US iOS lifetime ÷ yearly multiples:**

  | App | Lifetime | Yearly | Multiple | Source |
  |---|---|---|---|---|
  | Habit Pixel | $19.99 | $14.99 | 1.33× (2.0× using its $29.99 LT SKU) | [App Store](https://apps.apple.com/us/app/id6742632433) |
  | Daylio | $59.99 | $35.99 | 1.67× | [App Store](https://apps.apple.com/us/app/id1194023242) |
  | Pixa | $39.99 | $19.99 | 2.0× | [App Store](https://apps.apple.com/us/app/id6480351200) |
  | Habitify Pro | $119.99 | $49.99 | 2.4× | [App Store](https://apps.apple.com/us/app/id1111447047) |
  | HabitKit | $29.99 | $11.99 | 2.5× | [App Store](https://apps.apple.com/us/app/id6443918070) |
  | Inner Grow Habit Tracker | $19.99 | $7.99 | 2.5× | [App Store](https://apps.apple.com/us/app/id1438388363) |
  | everyday | $99.99 | $29.99 | 3.3× | [App Store](https://apps.apple.com/us/app/id1394150432) |
  | Journey | $199 | $49.99 | 4.0× | [App Store](https://apps.apple.com/us/app/id1300202543) |
  | Not Boring Habits Plus | $59.99 | $14.99 | 4.0× | [App Store](https://apps.apple.com/us/app/id1593891243) |
  | stoic. | $299 | $39.99 | 7.5× | [App Store](https://apps.apple.com/us/app/id1312926037) |

  Median 2.5×. Most apps are between 2× and 4×.
- RevenueCat (2025-11-12): lifetime is "often" priced at "5–12x the annual subscription", "designed to sit just above your expected" lifetime value. Its examples range from 2.1× to 11.5×: Moonly $28.98 → $59.98 (2.1×), Placify $14.99 → $49.99 (3.3×), Calm $79 → $399 (5.0×), Waking Up $129.99 → $1,500 (11.5×). It says 18–24% of apps offer both subscription and lifetime, advises "going higher rather than lower", warns that too high a share of lifetime revenue can "compromise compounding MRR", and documents no removals ([RevenueCat: lifetime subscriptions](https://www.revenuecat.com/blog/growth/lifetime-subscriptions)).
- RevenueCat also quotes Astropad's CEO saying lifetime users raised ongoing costs ([same article](https://www.revenuecat.com/blog/growth/lifetime-subscriptions)).
- **Habitify (added a tier and raised lifetime):**
  - On 2026-04-06 it split into Free (3 habits), **Plus (annual only, no lifetime)** and **Pro (monthly, annual, lifetime)**. Existing Premium monthly, annual and lifetime users moved to Pro automatically, and anyone who switches or resubscribes after that date pays the new prices. Stated reason: some users "want basic tracking without limits", others advanced tools ([Habitify changelog](https://feedback.habitify.me/changelog/new-tiered-pricing)).
  - The old page shows lifetime $59.99 ([habitify.me/new-pricing](https://habitify.me/new-pricing)). The App Store now lists Pro Lifetime $119.99 alongside legacy "PRO Lifetime $59.99" SKUs ([App Store US](https://apps.apple.com/us/app/id1111447047)).
  - Habitify hides the lifetime option while an iOS user is on a free trial (help-center article title: "why can't I see the lifetime plan while I'm on a free trial (iOS)", [URL](https://intercom.help/habitify-app/en/articles/13903069-troubleshooting-why-can-t-i-see-the-lifetime-plan-while-i-m-on-a-free-trial-ios), seen in search results only).
- **Bearable** has no lifetime plan, and ChoosingTherapy says it is "exploring whether or not a lifetime subscription option would be a possibility" ([search summary of ChoosingTherapy](https://www.choosingtherapy.com/bearable-app-review/); [bearable.app/pricing](https://bearable.app/pricing) lists none).
- **Tiimo:** a user on the Tiimo feedback board reported that "all the subscription plans have changed right when they were about to buy the lifetime plan" ([tiimo.nolt.io/2439](https://tiimo.nolt.io/2439), via search snippet). This is anecdotal.
- **Productive:** an App Store reviewer said the app had "switch[ed] to monthly payment" before they bought the full version. The legacy one-time "Upgrade Productive" $3.99 SKU still sits next to subscriptions up to $79.99/yr ([App Store US](https://apps.apple.com/us/app/id983826477)).
- **Way of Life** seems to sell premium as a one-time purchase on Android (≈$6.49) but as a subscription on iOS (≈$4.99/mo, "no lifetime or one-time option currently available on that platform") ([Macaron review, early-2026 pricing](https://macaron.im/blog/way-of-life-habit-tracker-review)).
- Older one-time apps often add an optional subscription without removing the unlock. My Wonderful Days keeps a $14.99 one-time unlock plus an optional "supporter subscription" that "helps fund ongoing development" ([App Store US](https://apps.apple.com/us/app/id434356065)).

### Inferences
- At 2.56×, Dian Dian's ratio is typical for indie hybrids. Moving lifetime to about 3× yearly ($26.99–$29.99 at $8.99/yr) would still be in line with HabitKit (2.5×), everyday (3.3×) and Not Boring (4×). The recurring pattern is **lifetime $19.99–$39.99 when yearly is $8–20**.
- Apps rarely remove lifetime in this niche. They (a) raise it (Habitify 2×), (b) hide it during trials or behind a higher tier (Habitify: Plus has none, Pro has it), or (c) keep legacy SKUs for grandfathered users.

### Gaps
- No primary-source example was found of an app in this category removing lifetime, or explaining why it did. The evidence is anecdotal (Tiimo, Productive reviewers, Habitty mentioned in search snippets) and unverified.
- No data on what share of revenue lifetime represents for apps in this category.
- The date of Habitify's $59.99 → $119.99 change is unknown. The search summary hinted at "August 2025", but no fetched page confirmed it.

## Q4. Where do $8.99/yr and $22.99 lifetime sit in the category?

### Takeaway
**$8.99/yr is at roughly the 5th percentile** of US yearly prices in this sample (median $35.99). Only Inner Grow's Habit Tracker ($7.99) is cheaper. Even within the indie pixel/habit-grid cluster (median $14.99) it is the second-cheapest. **$22.99 lifetime is at about the 20th percentile** of lifetime prices in hybrid subscription apps (median ≈$50). Among *all* one-time prices, including one-time-only apps (Streaks $5.99, Diarium $14.99, MWD $14.99, Pixels+ $4.99), it sits at about the median.

### Cited Findings
- **US yearly prices (n = 19, best-identified headline annual, App Store US 2026-11-22):**
  - $7.99 Inner Grow
  - $11.99 HabitKit
  - $14.99 Not Boring Habits Plus, Habit Pixel
  - $19.99 Pixa, DailyBean
  - $29.99 everyday, Grid Diary
  - $34.99 Bearable
  - $35.99 Daylio
  - $39.99 stoic., Me+, EMMO, Atoms
  - $49.99 Journey, Day One, Habitify Pro, Foxtale
  - $69.99 Finch

  P25 = $19.99, **median = $35.99**, P75 = $49.99, mean ≈ $34.25. Sources are the App Store listings in the Q1 table, plus [bearable.app/pricing](https://bearable.app/pricing), [dayoneapp.com/pricing](https://dayoneapp.com/pricing/) and [RecurDash/Finch](https://recurdash.com/subscription-pricing/finch).
- **Indie pixel / habit-grid subset:** Inner Grow $7.99, HabitKit $11.99, Habit Pixel $14.99, Not Boring Plus $14.99, Pixa $19.99. Median $14.99. Dian Dian at $8.99 would rank 2nd-cheapest of 6.
- **US lifetime prices in hybrid apps (n = 10):**
  - $19.99 Inner Grow, Habit Pixel (low SKU)
  - $29.99 HabitKit
  - $39.99 Pixa
  - $59.99 Daylio, Not Boring Plus
  - $99.99 everyday
  - $119.99 Habitify Pro
  - $199 Journey
  - $299 stoic.

  **Median ≈ $49.99.** $22.99 is above 2 of 10 (≈20th percentile).
- **One-time-only apps:** Bullet Journal Companion $4.99, Pixels+ $4.99, Streaks $5.99, Way of Life Android ≈$6.49, HabitNow ≈$11, Diarium $14.99, My Wonderful Days $14.99. Pooled with the hybrid lifetimes (n = 17), $22.99 is above 9 → ≈53rd percentile. Sources: [Streaks](https://apps.apple.com/us/app/id963034692), [Pixels](https://apps.apple.com/us/app/id1668460700), [Diarium Play](https://play.google.com/store/apps/details?id=partl.Diarium), [MWD](https://apps.apple.com/us/app/id434356065), [Bullet Journal Companion](https://apps.apple.com/us/app/id1201419241), [HabitNow/AlternativeTo](https://www.alternativeto.net/software/habitnow/about/), [Way of Life/Macaron](https://macaron.im/blog/way-of-life-habit-tracker-review).
- **US monthly prices (n = 19):** median $6.99. Comparable indies: HabitKit $1.99, Pixa $1.99, Habit Pixel $2.99, DailyBean $3.99, Daylio $4.99, Inner Grow $4.99 (App Store listings above).

### Inferences
- Dian Dian is priced like the **cheapest indie trackers** (Inner Grow, HabitKit), not like its feature peers. Daylio ($35.99/$59.99) offers similar premium hooks (stats, export, themes), and Pixa ($19.99/$39.99) has the same 3-item free tier and the same year-in-pixels concept. Against those, there is room to raise yearly to about **$11.99–$19.99** and lifetime to about **$29.99–$39.99** and still sit below the category median ($35.99 / ≈$50).
- Dian Dian's free tier also shows ads. Most indie peers advertise "no ads" (HabitKit, Pixels, Not Boring, Streaks), which makes ad removal a slightly stronger premium hook than at peers.
- A monthly in the **$1.49–$1.99** range would keep the usual yearly ≈ 5–6× monthly ratio at $8.99/yr. If yearly is raised to $14.99–$19.99, the usual ratio points to **$2.99–$3.99/mo**.
- The 7-day trial on yearly is standard (Daylio, Habitify Pro, Bearable). Day One uses 1 month.

### Gaps
- The percentiles are based on a curated sample of 19 yearly and 10 to 17 lifetime price points, not on a market-wide dataset, and the headline-tier choice is partly inferred where Apple's IAP labels are generic.
- No conversion-rate or revenue data links these price points to performance. Rating counts and installs are only rough popularity signals.
- EUR and GBP percentiles weren't computed separately. The EUR and GBP prices in the Q1 table follow the USD ordering closely, so the USD percentiles are probably a fair guide.
