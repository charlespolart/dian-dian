# Subscription-app market benchmarks: pricing, conversion, iOS vs Android (Health & Fitness / Lifestyle / Productivity)

Research date: 2026-11-22. Main sources and what their samples cover:
- **RevenueCat "State of Subscription Apps" (SOSA) 2026**: 115,000+ apps, $16B+ revenue, 1B+ transactions; covers calendar 2025. Published in two parts, March and May 2026. iOS and Google Play together unless a store is named.
- **SOSA 2025**: 75,000+ apps, $10B+ revenue; covers 2024.
- **SOSA 2024**: 30K+ apps, $6.7B+ revenue; covers 2023 (older data).
- **Adapty "State of In-App Subscriptions 2026"**: 16,000+ apps, $3B+ revenue; covers 2025. Mostly App Store data.
- **Adapty 2025 edition**: 11,000+ apps, $1.9B revenue.

All of these are vendor data: SDK customers, skewed toward apps that actively monetise. RevenueCat's public pages are truncated, so a few figures appear twice with different values. Every such conflict is flagged below.

Dian Dian reference points used in the inferences: yearly plan $8.99 with a 7-day trial, lifetime $22.99, monthly plan with a 7-day trial, freemium model. Observed so far: 2 of 5 yearly trials converted, about 4% of recent users pay, all purchases on iOS.

---

## 1. What prices does the market charge (monthly / annual / lifetime, by category and region)?

### Takeaway
The market median for an annual plan is about $35–40: $34.80 across all apps in 2025 and about $39.99 for Health & Fitness and for North America. Monthly plans have a median around $9.99. Dian Dian's $8.99 a year is roughly a quarter of the category median, which puts it firmly in RevenueCat's "low-priced" tier. Western European prices sit at or above US prices.

### Cited Findings
**RevenueCat SOSA 2026 (2025 data, all categories)**
- Weekly median $5.99; monthly median $10, most common $10 (one section says the monthly median rose from $7 to $8, a conflict); yearly median **$34.80**, up from $31.60, most common $30. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- Yearly median by category: Education highest at $44.99, Travel lowest at $20. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- Health & Fitness: **$9.99 monthly**, $4.99 weekly. The 2026 annual median for H&F was not visible on the public page. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- By region: monthly North America $9.99 (highest) vs IN/SEA $3.75; yearly North America **$39.99** (highest) vs IN/SEA $18.32. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SaaStr's summary of SOSA 2026 gives "median price tiers" of $4.99–$6.99 weekly, $7.99–$9.99 monthly and $29.99–$39.99 annually. — [SaaStr](https://saastr.com/the-top-10-learnings-from-revenuecats-state-of-subscription-apps-how-115000-mobile-apps-deliver-16b-in-revenue-whats-working-whats-quietly-killing-growth)

**RevenueCat SOSA 2025 (2024 data)**, via a secondary source
- Health & Fitness medians: weekly $4.99, monthly $9.70, **annual $39.99**. Education $5.99 / $8.38 / $44.99; Business $6.15 / $7.58 / $37.50; Gaming $4.99 / $4.99 / $20.55. — [Airbridge, citing SOSA 2025](https://www.airbridge.io/en/blog/subscription-app-pricing-by-category-2026-benchmark). I could not confirm these on RevenueCat's own page, where they appear only in charts.
- Median price for apps on RevenueCat's own paywalls: $29.99, with the upper quartile nearly 3x higher. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)

**RevenueCat SOSA 2024 (2023 data, older)**
- Most common price points: 1 week $4.99, 1 month $9.99, 1 year $29.99+.
- Average monthly price rose from $7.05 to $8.01; average yearly fell slightly from $32.94 to $32.53. — [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)

**Adapty**
- 2025 edition (averages, not medians): annual US **$44.6**, Europe $42; monthly US $15.2, Europe $13.3; Lifestyle monthly averages $18. Health & Fitness and Education annual plans cost about 5x the weekly price. — [Adapty 2025 summary](https://adapty.io/blog/state-of-in-app-subscriptions-2025-in-10-minutes/)
- 2026 edition: European subscription prices rose 18% year on year and run up to 40% above North America. The median annual plan costs about 3x the monthly plan, a 75% saving. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- 2026 price index (US = 1.0): UK, France, Germany, Italy and Spain 1.2; Canada 0.9; Australia 0.8. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- 2026 edition: the Health & Fitness annual price in Germany is 4.4x the price in Turkey. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

**Independent paywall survey**
- PaywallPro analysed about 1,200 fitness paywalls (not vendor SDK data): annual plans $39.99–$79.99, monthly $8.99–$39.99. — [PaywallPro on DEV](https://dev.to/paywallpro/how-top-fitness-apps-price-convert-insights-from-1200-paywalls-2p1d), as quoted in search results; I did not open the page.

### Inferences
- At $8.99 a year, Dian Dian charges about 26% of the overall median ($34.80) and about 22% of the Health & Fitness and North American median ($39.99). It sits well inside RevenueCat's low-priced tier.
- At $22.99, the lifetime price is about 2.6x Dian Dian's own annual price. It is still below the market's median annual price, so it is low in absolute terms.
- Because Adapty finds European prices at about 1.2x US prices, matching US pricing in France and the rest of the EU is not aggressive. Setting EU prices below US prices would go against the market.

### Gaps
- The 2026 Health & Fitness annual median, and Productivity and Lifestyle price medians in either edition: these appear only in RevenueCat charts or the 330-page PDF, which I could not open.
- RevenueCat's exact thresholds for its low, mid and high price tiers were not found.
- No benchmark found for lifetime price levels, or for the ratio of lifetime price to annual price.

---

## 2. Conversion funnel: download-to-trial, download-to-paid, trial-to-paid, effect of trial length

### Takeaway
For Health & Fitness, the medians are about 7% download-to-trial, about 38–40% trial-to-paid and about 2.9% download-to-paid by day 35. For freemium apps of all categories, download-to-paid is only about 2.1%. Trials of 5–9 days convert at a median of about 37%; trials of 4 days or less convert at about 25%.

### Cited Findings
**Download-to-trial (by day 30, SOSA 2026)**
- By category: Business 9.1%, Health & Fitness **6.9%**, Education 6.5%, Utilities 6.5%.
- By region: North America 7.1%, Western Europe 5.0%.
- By price tier: high 8.9%, mid 5.4%, **low 4.4%**.
- Source: [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)

**Download-to-trial, other editions and vendors**
- SOSA 2025: median trial start rate 6.2%, top 10% 20.3%. High-priced apps 9.8% vs low-priced 4.3%. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2024: Health & Fitness trial start rate 6.7%. — [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)
- Adapty 2026: install-to-trial 11.2% overall, 14.5% in North America vs 7.6–10.2% elsewhere. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

**Download-to-paid (by day 35, SOSA 2026)**
- By category: Health & Fitness **2.9%**, Business 2.6%.
- By region: global 2.0%; North America 2.6% or 2.8% (sections conflict); Western Europe 2.0%.
- By price tier: high 2.8%, mid 2.0%, **low 1.4%**.
- Freemium **2.1%** (top quartile 4.5%) vs hard paywall 10.7% (top quartile 20.0%).
- Source: [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)

**Download-to-paid, other editions**
- SOSA 2025: Health & Fitness P90 is 12.1%. North America upper quartile 5.5%, P90 10.5%. High-priced apps 2.66% vs low-priced 1.49%. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2024 (2023 data, first 30 days): overall 1.7%, lower quartile 0.6%, upper quartile 4.2%. — [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)

**Trial-to-paid, SOSA 2026**
- By trial length: ≤4 days **25.5%** (top quartile 38.5%); 5–9 days **37.4%** (top quartile 52.8%); 17–32 days **42.5%** (top quartile 59.4%).
- By category: Health & Fitness **37.7%**, Travel 43.5%.
- By region: North America 34.2%, Western Europe 29.7%.
- Source: [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)

**Trial-to-paid, earlier editions**
- SOSA 2025: Health & Fitness median **39.9%**, top 10% 68.3%. Trials of 17–32 days 45.7% vs short trials 26.8%. Lower-priced apps **47.8%** vs high-priced 28.4%. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2024 (2023 data): overall 37.3%; ≤4 days 31.2%, longer trials up to 44.9%; Health & Fitness 44.5%. — [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)

**Trial cancellations and timing**
- Share of trial cancellations on day 0, by trial length: 3-day 55.4%, **7-day 39.8%**, 14-day 35.7%, 30-day 31.1%. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- Mix of trial lengths: ≤4 days 46.5% (up from 42.1%), 5–9 days 39.9% (down from 43.5%), 17–32 days 5.0%. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- 82% of trial starts happen on install day. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- 90% of trial starts and 44.5% of purchases happen on day 0. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

**Adapty benchmark funnel (2026)**
- Install to trial 11.2%; trial to paid **27.8%**; first renewal 59.2%; second 45.1%; third 37.1%. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- One search summary swapped these numbers ("install-to-trial 27.8%, trial-to-paid 59.2%"). The report page itself gives the order above.

**Trial vs direct purchase (Adapty)**
- 2025 edition: install-to-paid without a trial reaches 18–38%, "especially Lifestyle and Productivity". The base for this figure is unclear. — [Adapty 2025 summary](https://adapty.io/blog/state-of-in-app-subscriptions-2025-in-10-minutes/)
- 2026 edition: in Lifestyle, trial users are about 21% less valuable than direct buyers. In Productivity, one-year LTV is $56.95 for direct buyers vs $49.13 for trial users. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

### Inferences
- Dian Dian's yearly trial conversion (2 of 5, 40%) matches the Health & Fitness median (37.7–39.9%) and the 5–9 day trial median (37.4%). It is also below what the low-price tier would predict (47.8% in SOSA 2025). With 5 trials, though, the 95% interval runs from about 5% to 85%, so this is not evidence of anything yet.
- "About 4% of recent users pay" would be roughly twice the freemium download-to-paid median (2.1%), close to the freemium top quartile (4.5%), and above the Health & Fitness median (2.9%). Two caveats limit the comparison. "Recent users" is not the same as installs measured at day 35. A tiny denominator makes the figure unstable.
- A 7-day trial follows the market's mainstream choice (the 5–9 day bucket). The data favours longer trials (17–32 days: +5 points of trial-to-paid). Shortening to 3 days would be expected to cut trial-to-paid by about 12 points.

### Gaps
- No published Health & Fitness × trial-length cross-tabulation.
- Download-to-paid at day 35 for Productivity and Lifestyle, and trial-to-paid for those categories, were not visible publicly.

---

## 3. Revenue mix (annual / monthly / lifetime), revenue per install, LTV

### Takeaway
Health & Fitness is an annual-plan category: about 59–61% of its revenue comes from annual plans. Lifetime and other one-time purchases make up about 10% of subscription-app revenue, and about a quarter of apps sell a lifetime plan alongside subscriptions. Low-priced apps earn far less per payer: about $11 in year 1 vs about $62 for high-priced apps.

### Cited Findings
**Plan and revenue mix**
- SOSA 2026, all apps: 42% of subscriptions sold are monthly and 34% yearly. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SOSA 2026, Health & Fitness: **59% of revenue from annual plans**. Plan mix is given as "68% annual" in one section and "68% monthly" in another, a conflict. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SOSA 2025: 67% of Health & Fitness subscriptions are yearly. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2026, Productivity: the report gives both "77% yearly" and "77% monthly" for plan mix. Revenue share is "91% from monthly" in one place and 77% in another. Unreliable, so check the PDF. — [RevenueCat SOSA 2026 Productivity](https://www.revenuecat.com/state-of-subscription-apps-2026-productivity)
- Adapty: annual plans made up 61% of Health & Fitness subscription revenue in 2025 (via search summary), and Health & Fitness is "the only category where annual plans dominate (60.6%)". — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions/), via search results

**Monetisation model and lifetime**
- SOSA 2026, share of apps by model:
  - subscriptions only 63.5%;
  - subscriptions + lifetime **23.2%**;
  - subscriptions + consumables 10.7%;
  - all three 2.5%.
  - Source: [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SOSA 2025: 39.4% of Social & Lifestyle apps are hybrid (subscriptions plus consumables or lifetime). — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- Adapty: one-time purchases, including lifetime, grew from 6.4% of revenue in 2023 to **10.3% in 2025**. Weekly plans make up 55.6% of all revenue. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

**Revenue per install (RPI)**
- SOSA 2026, medians:
  - All apps: D14 $0.23, D60 $0.34.
  - Health & Fitness: D14 **$0.48**, D60 **$0.66**.
  - By region at D60: North America $0.55, Europe $0.33.
  - By price tier at D60: high $0.94, **low $0.11**.
  - By access model at D60: freemium **$0.38** vs hard paywall $3.09.
  - Source: [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SOSA 2026, by dominant plan (D14 / D60): yearly $0.36 / $0.46; monthly $0.18 / $0.29; **lifetime $0.19 / $0.24**. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SOSA 2025: Health & Fitness D60 RPI $0.63 median, P90 $4.19. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)

**Realized LTV per payer (RLTV)**
- SOSA 2026, year 1, by category: Health & Fitness **$35.64**, Productivity $24.95. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- SOSA 2026, year 1, by price tier: high $62.19; mid $28.75 or $26.07 (sections conflict); **low $10.69**. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/); [RevenueCat insights](https://www.revenuecat.com/sosa-26-insights)
- SOSA 2026, year 1, by region: North America $32 (or $26.07), Western Europe $25 (or $26.64). — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- Adapty 2026, median one-year LTV per install: Health & Fitness **$1.21**, Productivity $1.10, **Lifestyle $0.70**. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Adapty 2026: high-priced apps earn about 3x the LTV of low-priced apps; in Health & Fitness, expensive annual plans earn 4.5x more. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Adapty 2026, median one-year LTV by country: UK $23.6, Australia $21.5, Canada $20.9, US $19.9. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Adapty 2026: Lifestyle has the most concentrated revenue, with 97.9% earned by the top 10% of apps. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

### Inferences
- A yearly payer at $8.99 grosses $8.99 in year 1, about $7.64 after a 15% store fee. That is consistent with RevenueCat's low-tier year-1 RLTV of $10.69. It is about a quarter of the Health & Fitness median payer value ($35.64).
- At $22.99, a lifetime purchase brings in more cash up front than about 2.5 years of the yearly plan, even before annual churn. With yearly retention of 28–44% (section 4), the expected revenue from a yearly subscriber probably stays below $22.99. At these prices, lifetime is therefore not cannibalising the yearly plan in revenue terms.
- The sources do not measure this directly.

### Gaps
- No public source gives the lifetime share of revenue for Health & Fitness or Lifestyle specifically.
- No public source gives the conversion impact of adding a lifetime option to a paywall.

---

## 4. Annual-plan renewal and retention; refunds

### Takeaway
Roughly 30–45% of annual subscribers remain after year 1, and about 60% of those reaching the first renewal renew. Definitions differ between editions. Health & Fitness refund rates are among the highest, at about 4.7%. Freemium apps and low-priced apps see fewer refunds, at about 2–3.5%.

### Cited Findings
**Annual retention and renewal**
- SOSA 2025, share of subscribers retained after year 1:
  - Yearly plans 44.1% (prior period 47.1%).
  - Monthly 17.0%; weekly 3.4%.
  - Yearly low-priced plans **53.7%** vs high-priced 48.3%.
  - Monthly: low 22.5%, mid 16.4%, high 12.2%.
  - Source: [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2025, annual renewals:
  - First renewal 61.7% (prior period 64.9%); second 53.4%.
  - Third renewal above 77%, and above 79% in North America and Western Europe.
  - Source: [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2026, annual cancellations:
  - Year-1 cancellation is **about 72%, up from about 56% in 2025**.
  - Month 1 accounts for **35% of annual cancellations**.
  - Source: [RevenueCat blog, 2026 trends](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026.md)
- SOSA 2026, one-year retention:
  - Yearly subscribers: freemium 28% vs hard paywall 27%. — [RevenueCat blog, 2026 trends](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026.md)
  - By price: low-priced apps **36%** vs high-priced 23%. — [RevenueCat insights](https://www.revenuecat.com/sosa-26-insights)
- SOSA 2024 (2023 data):
  - Median annual first renewal 35.3%, down from 40.4% in 2022.
  - Social & Lifestyle had the lowest median first renewal (49%) across plan types.
  - North America year-1 retention: annual 27%, monthly 15%, weekly 4%.
  - Source: [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)
- **Conflicting definitions:** first-renewal figures range from 35.3% (2024 edition) to 61.7% (2025 edition) to 59.2% (Adapty 2026). These likely differ in base (trial conversions counted or not, which cohort is measured), so compare within one edition only.
- Annual reactivation after cancelling: about 5% (4.58% in SOSA 2025), about four times lower than for monthly plans. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025); [9to5Mac on SOSA 2026 part 2](https://9to5mac.com/2026/05/27/new-report-shows-annual-app-subscribers-rarely-return-after-they-cancel/)

**Refunds**
- SOSA 2025 (refund rate, % of payers):
  - By category: Education 4.86%, **Health & Fitness 4.71%**, Gaming and Business 2.67–2.88%, Travel 1.51%.
  - Western Europe and APAC below 3.0%.
  - Low-priced apps **2.2%**.
  - Hard paywall 5.8% vs **freemium 3.4%**.
  - Source: [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- Adapty 2025 edition: annual plans 4.2%, weekly 2.6%; US and LATAM above 3%, Europe about 2.3%. — [Adapty 2025 summary](https://adapty.io/blog/state-of-in-app-subscriptions-2025-in-10-minutes/)
- Adapty 2026 edition: "benchmark refund rate 8.3%", with up to 14% of revenue lost. The definition is unclear and the figure is much higher than RevenueCat's, so treat it with caution. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

### Inferences
- Dian Dian is freemium, low-priced, and sold mostly in North America and Western Europe. Expect refunds at the low end (about 2–3.5%) and above-median annual retention (low-priced yearly plans retained 53.7% after year 1 in SOSA 2025).
- One in three annual cancellations happens in month 1, so the 3 cancelled trials out of 5 match a normal pattern of day-0 or early auto-renew switch-offs. They do not necessarily signal price resistance.

### Gaps
- No public split of refund rates by store (iOS vs Android).
- No Health & Fitness-specific annual renewal rate in the public pages.

---

## 5. Effect of price on conversion, and published price tests

### Takeaway
Higher-priced apps convert fewer trials to paid (28% vs 48%) but start more trials. Their download-to-paid rate is about twice that of low-priced apps, and their revenue per payer and per install is far higher. Published A/B tests mostly show that raising the price cuts conversion by less than the price increase, so net revenue per user rises.

### Cited Findings
**Price tier vs funnel (RevenueCat)**
- SOSA 2025:
  - Trial-to-paid: low-priced apps **47.8%** vs high-priced 28.4%.
  - Download-to-trial: high-priced 9.8% vs low-priced 4.3%.
  - Download-to-paid (D35): high 2.66% vs low 1.49%.
  - Year-1 RLTV: high-priced $55.21 vs **low-priced $8.08**.
  - Source: [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2026, by tier (high / mid / low):

  | Metric | High | Mid | Low |
  |---|---|---|---|
  | Download-to-trial | 8.9% | 5.4% | 4.4% |
  | Download-to-paid (D35) | 2.8% | 2.0% | 1.4% |
  | RPI at D60 | $0.94 | n/a | $0.11 |
  | RLTV, year 1 | $62.19 | n/a | $10.69 |

  Low-priced apps keep more users (36% vs 23% one-year retention). — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/); [RevenueCat insights](https://www.revenuecat.com/sosa-26-insights)
- Possible reverse causality: high-priced apps may be better products or better marketed. These are correlations across apps, not price experiments.

**Adapty**
- Monthly conversion falls about 53% from low to mid-range prices. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Price tests win on conversion 28.3% of the time but win on LTV 45.5% of the time. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Median prices grew 7–10% from 2023 to 2025 (expert commentary). — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

**Published A/B tests (Superwall case studies: vendor marketing, no sample sizes or confidence intervals)**
- BuyBye, a budgeting app: yearly price +50% (both arms with trial) gave conversions **−19%** and proceeds per user **+25%**. — [Superwall BuyBye](https://superwall.com/case-studies/buybye.md)
- PropGPT: weekly price $6.99 → $9.99 (+43%) raised proceeds per user by "almost half". — [Superwall case studies (search results)](https://superwall.com/case-studies/propgpt.md)
- SellRaze: annual price $59.99 → $44.99 (a cut) raised ARPU by +10%. — [Superwall SellRaze](https://superwall.com/case-studies/sellraze)

**Platform-side evidence (older data)**
- SOSA 2024: price increases caused only 0.1% of all subscription expirations (2023 data). — [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)

### Inferences
- Dian Dian's yearly plan sits far below even the low tier's typical range. Market data and published tests point the same way: a moderate yearly increase (for example toward $14.99–$19.99) would probably lower trial-to-paid somewhat but raise revenue per user. This needs a local A/B test; the vendor case studies are not transferable as-is.
- One caveat cuts the other way. Low prices are associated with higher trial-to-paid, better retention and fewer refunds. With a tiny user base, price changes will take a long time to read statistically.

### Gaps
- No published price test specific to a habit or mood tracker.
- No published test on how a lifetime price change affects subscription uptake.

---

## 6. iOS vs Android: conversion, prices, revenue per install, trials, refunds; the gap in Western markets

### Takeaway
The App Store converts downloads to paying users about 3x better than Google Play: 2.6% vs 0.9% by day 35 (SOSA 2026). Trial-to-paid is at parity, at about 32.5% on both stores. In North America the revenue-per-install gap narrows to about 1.9x ($0.66 vs $0.35 at D60, SOSA 2025). Most apps earn at least 80% of their revenue from iOS, so zero Android purchases at a small scale is normal.

### Cited Findings
**RevenueCat**
- SOSA 2026, median D35 download-to-paid: **Android 0.9% vs iOS 2.6%**. — [RevenueCat blog, "Android paywall gap", 2026-03-25](https://www.revenuecat.com/blog/engineering/android-paywall-gap)
- SOSA 2026, trial-to-paid: **Android 32.5% vs iOS 32.6%**. RevenueCat suggests Android trial starters are more filtered. — [RevenueCat blog, "Android paywall gap"](https://www.revenuecat.com/blog/engineering/android-paywall-gap)
- SOSA 2025, median D60 revenue per install: global App Store **$0.38** vs Google Play **$0.14** (2.7x); North America **$0.66 vs $0.35** (1.9x). — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2025, download-to-paid: higher on the App Store in every category, with the largest gaps in Business, **Health & Fitness** and Education. No figures given. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- Secondary write-up of SOSA 2025: Health & Fitness conversion is about 2x higher on iOS than on Android. — [Athletech News](https://athletechnews.com/fitness-apps-monetizable-winner-take-all-or-most/), as quoted in search results
- SOSA 2025, revenue concentration: in every region, over 67% of apps earn at least 80% of their revenue from iOS; 10–14% of apps earn all their revenue from Android. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2025, prices: "Annual prices are generally higher on the App Store except in North America." No figures given. — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2025, offers: 17.6% of App Store users use an offer vs 7.3% on Google Play. Google Play leads on first-month renewal (no figure given). — [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- Involuntary churn (billing failures) as a share of cancellations: Google Play **31% vs App Store 14%** in SOSA 2026; 28.2% vs 15.1% in SOSA 2025. Search results also cite 32.2% vs 15.2%. — [RevenueCat blog, 2026 trends](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026.md); [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)
- SOSA 2024 (2023 data): trial conversion App Store 39.0% vs Google Play 28.5%. This gap closed to parity by SOSA 2026. — [RevenueCat SOSA 2024](https://revenuecat.com/state-of-subscription-apps-2024/)

**Adapty**
- Adapty 2026: iOS accounts for **85%** of subscription revenue, about 5.6x Android. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Adapty 2026: install-to-paid on iOS is about 3x Android overall and **3.6x for annual plans**. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Adapty 2026: Android weekly-plan LTV is 18% lower than iOS. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)
- Adapty blog (first published 2023, updated January 2026, methodology not stated, lower quality):
  - iOS RPI $2.12 vs Android $0.85.
  - iOS share of subscription revenue 73% vs Android 27%.
  - iOS user share: US 58–59%, UK 49%, Western Europe 32%.
  - Source: [Adapty, iPhone vs Android users](https://adapty.io/blog/iphone-vs-android-users/)

### Inferences
- Take the SOSA 2026 ratio (0.9% vs 2.6%). With Android download-to-paid at a third of iOS, and France and the rest of Western Europe being majority-Android markets, an app with a small Android base can easily show zero Android purchases. For example, about 100 Android installs × 0.9% gives about one expected payer.
- There is no evidence that the market prices lower on Android in North America. RevenueCat says annual prices are generally higher on the App Store except in North America. A lower Android price would therefore be a deliberate choice, not market practice.
- Trial-to-paid is at parity across stores, so the Android gap lies at the top of the funnel: paywall exposure and trial or offer uptake. Worth checking:
  - whether Android users actually see the trial (Google Play offers and base plans configured correctly);
  - whether billing-failure grace periods are on, given Google Play's 31% involuntary churn.

### Gaps
- No public iOS vs Android split of refund rates or of median prices by category.
- A secondary blog ([The Social Outline](https://thesocialoutline.com/blog/ios-vs-android-subscription-economics), October 2026) reportedly gives D60 RPI of $0.42 (App Store) vs $0.16 (Google Play) for SOSA 2026 data. I did not open it, so the figure is unverified.

---

## 7. Hard paywall vs freemium (relevant to Dian Dian's freemium model)

### Takeaway
Hard paywalls convert about 5x more downloads to paid (10.7% vs 2.1% by D35) and earn about 8x more per install. Yearly retention is the same for both models (27% vs 28%), and freemium apps see fewer refunds.

### Cited Findings
**RevenueCat SOSA 2026**
- D35 download-to-paid: hard paywall **10.7%** (top quartile 20.0%; top 10% 38.7%) vs freemium **2.1%** (top quartile 4.5%). — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/); [SaaStr](https://saastr.com/the-top-10-learnings-from-revenuecats-state-of-subscription-apps-how-115000-mobile-apps-deliver-16b-in-revenue-whats-working-whats-quietly-killing-growth)
- RPI: hard paywall $2.32 at D14 and $3.09 at D60 vs freemium $0.27 and $0.38. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- Yearly subscriber retention after 1 year: freemium **28%** vs hard paywall **27%**. — [RevenueCat blog, 2026 trends](https://www.revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026.md)

**RevenueCat SOSA 2025**
- D35 download-to-paid: hard 12.11% vs freemium 2.18%.
- Monthly-plan year-1 retention: 12.8% (hard) vs 9.3% (freemium).
- Refunds: 5.8% (hard) vs **3.4% (freemium)**.
- Source: [RevenueCat SOSA 2025](https://www.revenuecat.com/state-of-subscription-apps-2025)

**Adapty 2026**
- Hard paywalls produce about 21% higher LTV. Separately, "soft paywall conversion [is] nearly 50% higher than hard". The direction is ambiguous on the page and may mean conversion among users who see a paywall. — [Adapty SOIAS 2026](https://adapty.io/state-of-in-app-subscriptions-report/)

### Inferences
- The freemium median of 2.1% download-to-paid (top quartile 4.5%) is the right yardstick for Dian Dian, not the hard-paywall 10.7%.
- If the "about 4% of recent users pay" figure holds on a larger sample, Dian Dian is near the freemium top quartile. That would suggest the binding constraint is price per payer, not conversion.

### Gaps
- No category-specific (Health & Fitness, Lifestyle) split of hard paywall vs freemium in the public pages.
- No freemium benchmark specifically for apps whose free tier is capped by a usage limit, such as Dian Dian's limit of 3 trackers.

---

## Other context (market size)
- Sensor Tower: global Health & Fitness app downloads reached 3.6 billion in 2024 (+6%); January 2025 in-app revenue was $385M (+10% year on year). The United States accounted for more than half of global Health & Fitness consumer spending in 2024, and the UK was second with 8%. — [Sensor Tower, State of Mobile Health & Fitness 2025](https://sensortower.com/blog/state-of-mobile-health-and-fitness-in-2025)
- Secondary sources citing Sensor Tower put 2025 Health & Fitness in-app revenue at about $4.5B (+13%) and installs at 3.96B. I did not verify this at the primary source. — via search results ([Mobile Marketing Reads](https://mobilemarketingreads.com/?p=50285))
- No Sensor Tower or data.ai split between the App Store and Google Play for this category was found publicly.
- RevenueCat SOSA 2026: median monthly revenue one year after launch is about $72; 17.3% of new apps reach $1K a month within 2 years. — [RevenueCat SOSA 2026](https://www.revenuecat.com/state-of-subscription-apps-2026/)
- Purchasely and data.ai benchmarks: not reviewed. No accessible public numbers surfaced in the searches.
