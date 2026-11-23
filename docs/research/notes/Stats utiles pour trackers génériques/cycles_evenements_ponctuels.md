# Rhythm statistics for period/cycle trackers and occasional-event trackers, and how a generic one-colour-per-day tracker could offer them responsibly

Research date: 2026-11-23. Context: Dian Dian is a "year in pixels" app. Each tracker is a 12×31 grid with one colour per day, and the user defines the colour + label legend. The app cannot know what a tracker is about. The idea under study: for an "occasional" tracker or a chosen colour, compute episodes (runs of consecutive days with that colour), then days since the last episode, the average gap between episode starts, average episode length, variability, and an estimated next date.

Evidence labels:
- **[PRIMARY]**: page or source code fetched and read directly.
- **[PRIMARY via search]**: an official page that blocked direct fetching (HTTP 403 or a JS-only page). The content comes from the search engine's summary of that page, so the exact wording is not verified.
- **[PEER]**: peer-reviewed paper or preprint.
- **[STORE]**: App Store or Google Play listing.
- **[VENDOR]**: marketing or case study from the company or its contractor.
- **[NEWS]**: press coverage.
- **[OLD]**: information from before 2023, flagged with its date.

Reddit was not reachable: the search tool refuses reddit.com, so no Reddit thread was read. See the gaps under question 5.

---

## 1. Which stats and predictions do dedicated cycle apps show (Clue, Flo, Stardust, Period Tracker / Period Calendar, drip, Euki, Apple Health), and what is free vs paid?

### Takeaway
Every dedicated app shows the same core: average cycle length, average period length, the next period, and (most of them) a fertile window. The better ones add variability (shortest/longest, standard deviation or "variation"), a per-cycle history, an option to exclude an atypical cycle, and symptom patterns by cycle phase. The averages and the basic predictions are free almost everywhere. Paid tiers (Clue Plus, Flo Premium) gate the deeper analysis: variability, trends, symptom patterns, longer prediction horizons and doctor reports.

### Cited Findings
**Apple Health – Cycle Tracking (free, built into iOS/watchOS)**
- Period predictions "are based on data that you've logged about your previous periods and cycle length". They "begin after you enter your last period", and logging each day of the period "helps improve prediction calculations". At setup the user enters the last period's start date, its typical length and the typical cycle length. — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]
- Fertile window: a 6-day window calculated "by subtracting 13 days (the luteal phase) from the estimated next cycle start date". A positive ovulation test shifts the window. Heart-rate data and Apple Watch wrist temperature (Series 8 or later, Ultra) can refine the predictions and give a retrospective ovulation estimate (ovulation estimates only in some regions). — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]
- "Cycle Deviation Detection" can flag "a pattern of irregular cycles, infrequent periods, prolonged periods, or persistent spotting" from the previous six months of logged history. Users 40 and over may get a notice about possible perimenopause. Detection pauses when a cycle factor is logged. The user can export a PDF of the last 12 months of history. — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]
- Deviation thresholds as summarised from Apple's HealthKit developer docs (the pages render only with JavaScript, so this is not verified verbatim):
  - irregular: the shortest and longest cycles differ by 17 days or more within 6 months;
  - prolonged: bleeding for 10 days or more, at least twice in 6 months;
  - infrequent: only 1–2 periods in 6 months;
  - persistent spotting: spotting in at least 2 cycles in 6 months.

  Sources: [irregularMenstrualCycles](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/irregularmenstrualcycles), [infrequentMenstrualCycles](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/infrequentmenstrualcycles), [prolongedMenstrualPeriods](https://developer.apple.com/documentation/healthkit/hkcategorytypeidentifier/prolongedmenstrualperiods) [PRIMARY via search]
- Apple's disclaimers: "Cycle Tracking should not be used as a form of birth control." "Data from Cycle Tracking should not be used to diagnose a health condition." — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]
- Apple does not publish its exact period-prediction formula. Only the fertile-window rule (next start − 13 days) is documented. — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]

**Clue (freemium; Clue Plus is paid)**
- Predictions use the user's last 12 cycles. Averages use the last 6 cycles. This applies to cycle length, period length, PMS length and PMS timing. — [Clue support: How are my predictions and averages calculated?](https://support.helloclue.com/hc/en-us/articles/214434406-How-are-my-predictions-and-averages-calculated) [PRIMARY via search]
- The user can hide an unusual cycle (Analysis > Your Cycle History > "Hide this cycle"). It is then greyed out and left out of the averages. — [Clue support: atypical cycle](https://support.helloclue.com/hc/en-us/articles/215935083-What-if-an-unusual-cycle-is-making-my-Clue-estimates-inaccurate-) [PRIMARY via search]
- The Clue Plus Analysis Tab includes:
  - "See your average cycle length and variability at the top of your screen";
  - a period flow graph ("average period length and flow levels");
  - tracking insights (cramps, feelings, sleep, basal body temperature, Oura temperature);
  - a cycle history to "compare cycles side-by-side to spot recurring symptoms, such as headaches or mood changes";
  - "a visual breakdown of your most common symptoms" by phase.

  The page is dated 26 Feb 2025. — [Clue: How to use Clue Plus](https://helloclue.com/articles/how-to-use-clue/how-to-use-clue-plus) [PRIMARY]
- "With Clue Plus, you can see predictions up to 12 cycles in advance, compared to three cycles with Clue Basic." — [Clue: How to use Clue Plus](https://helloclue.com/articles/how-to-use-clue/how-to-use-clue-plus) [PRIMARY]
- Clue lets users turn predictions off for irregular cycles, where "regular predictions are no longer useful". With predictions off, the forecasts leave the main cycle view and the "Your Averages" section leaves the History view. — [Clue, Nov 2017](https://helloclue.com/articles/about-clue/new-in-clue-turning-off-predictions-for-irregular-cycles) [PRIMARY] [OLD: 2017]

**Flo (freemium; Flo Premium is paid)**
- Flo's comparison page lists as free: "Period and ovulation predictions", symptom tracking, calendar, cycle history, anonymous mode. It lists as Premium only: "Symptom patterns and predictions", "Cycle trends", a personalised doctor's report, Health Assistant, daily insight stories, Flo for Partners and detailed pregnancy tracking. — [flo.health/premium](https://flo.health/premium) [PRIMARY via search; undated]
- The App Store listing says some content that was free "is now available only to our premium subscribers". Reviewers complained in 2025. — [Flo App Store listing](https://apps.apple.com/us/app/flo-cycle-period-tracker/id1038369065) [STORE via search]
- Flo's contractor claims its neural network cut the prediction error for irregular cycles from about 5.6 days (the old average-based formula) to about 2.6 days ("up to 54.2%"). — [InData Labs case study](https://indatalabs.com/resources/neural-network-implementation-in-healthcare-app) [VENDOR; not independently evaluated; the error metric is not stated]

**drip (free, open source, non-profit; data on device only)**. Verified in the source code, `main` branch, last commit 2026-11-16.
- Stats screen: "Average cycle", "Shortest", "Longest", "Standard deviation" (the corrected sample SD), "All cycles" (count), and a per-cycle table (start date, length, bleeding days). — [drip stats/index.js](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/components/stats/index.js), [lib/cycle-length.js](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/lib/cycle-length.js), [i18n en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]
- Stats need at least one completed cycle ("At least one completed cycle is needed to display stats"). Predictions need 3: "As soon as you have tracked 3 menstrual cycles, drip will make predictions for the next ones." — [drip en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]
- Predictions are a user setting ("Period predictions", on/off) and cover the next 3 periods. A period reminder is available only when predictions are on. — [drip en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]
- drip also implements the sympto-thermal method (temperature + cervical mucus) for fertility status. It does not use calendar dates for that. — [drip en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]

**Euki (free, privacy-first, no account)**
- The store listing mentions a cycle summary with average cycle length and period duration, and predictions that improve as more data is logged. No account, email or phone number is needed. A PIN lock is optional. — [Euki App Store listing](https://apps.apple.com/app/id1469213846) [STORE via search]
- Mozilla's review found no third-party collection in core tracking, and the data did not seem to leave the device. The privacy options (PIN, auto-delete, decoy screens) only work if the user turns them on. — [Mozilla privacy review: Euki](https://www.mozillafoundation.org/en/nothing-personal/euki-privacy-review/) [via search]

**Stardust**
- It frames the cycle through astrology, moon phases and horoscopes, and has social "compatibility" features. Mozilla reports that it sends data to third-party tracking services even before anything is entered. TechCrunch found that its "end-to-end encryption" was standard TLS plus server-side encryption. — [Mozilla privacy review: Stardust](https://www.mozillafoundation.org/en/nothing-personal/stardust-privacy-review/) [via search]

**"Period Tracker" (GP Apps / GP International) and "My Calendar – Period Tracker" (SimpleInnovation)**
- GP Apps' Period Tracker "calculates the average of your past 3 months' menstrual cycles to predict the start date of your next period". It has charts for weight, temperature, symptoms, period length and cycle length, an 8-day fertile window, and a "Calendar Year View" (added in v11.7). Disclaimer: forecasts "may not be accurate and should not be used to prevent unwanted pregnancy". Free with ads; an annual "Patron" tier costs $9.99. — [Period Tracker, App Store id330376830](https://apps.apple.com/us/app/id330376830) [STORE, PRIMARY]
- SimpleInnovation's calendar marks non-fertile, fertile, ovulation, expected period and actual period days. Ovulation/fertility display can be turned off in Settings. Paid tiers are "Premium features and no ads". — [My Calendar – Period Tracker, id1032267351](https://apps.apple.com/us/app/-/id1032267351) [STORE via search]

### Inferences
- The common baseline that users expect from a cycle app is: average cycle length, average period length, the last N cycles as a list, the next date, and "day X of cycle". Variability (min/max, SD, "variation") and the per-cycle history are what separate "good" apps. Clue puts variability behind Plus. drip shows it free.
- The fertile window in Apple Health and in calendar apps such as GP Apps and SimpleInnovation is a pure calendar rule (next start − ~13 days). This is the part that is both inaccurate (see question 2) and regulatory-sensitive (see question 4). A generic tracker should never reproduce it.
- Several respected apps let users switch off predictions (drip, Clue) or exclude an atypical cycle (Clue). Both are cheap features that a generic tracker can copy: "ignore this gap" and "show estimate: on/off".

### Gaps
- Clue's support pages return 403 to the fetcher. The "last 12 / last 6 cycles" rule and the "hide this cycle" path are from search summaries, not verbatim. Clue's formula for "variability" was not found.
- Flo's premium page is undated. The exact list of what moved behind the paywall in 2025 was not found. No independent evaluation of Flo's accuracy was found.
- Stardust's paid tier, its stats and its prediction method were not found.
- The "Period Calendar / Period Tracker" app by Simple Design Ltd (Android, `com.popularapp.periodcalendar`) did not render on Google Play, so its features are unverified.
- Euki's prediction method (how many cycles, what window) was not found.
- Apple's HealthKit deviation thresholds (17 days, 10 days, 1–2 periods, 2 cycles) were not read verbatim.

---

## 2. How do simple apps compute next-period predictions, and how accurate are calendar-based methods?

### Takeaway
Simple apps take the mean of the past cycle lengths (all cycles, the last 3, or the last 12) and add it to the last start date. Some show a window of ±1–2 days. On real self-tracked data, that mean predicts the next cycle about as well as neural networks on day 0 (RMSE about 7.5 days). Regular users get a median error of about 1.5 days. The error grows sharply with irregularity and with forgotten logging, which shows up as false "double-length" cycles. Calendar-only estimates of ovulation or the fertile window are documented as inaccurate. Cycle variability is large and normal: only about 13% of cycles are 28 days long.

### Cited Findings
**Concrete simple algorithms**
- drip's code:
  - a cycle is the number of days between consecutive period starts, and cycles over 99 days are ignored;
  - a period is a run of bleeding days, and a break of up to 1 day without bleeding still counts as the same period;
  - the predicted start is `round(mean)` days after the last start;
  - the window is ±1 day if the SD is below 1.5 (the code comment says "threshold is chosen a little arbitrarily"), otherwise ±2 days;
  - no prediction at all if the windows would overlap (`mean − 5 < variation`);
  - at least 3 cycles are required.

  — [drip lib/cycle.js](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/lib/cycle.js) [PRIMARY]
- drip's user-facing explanation: "Based on the standard deviation of the length of all your tracked cycles, drip calculates a range for the start day of the next 3 cycles. The range is 3 days if your standard deviation is less than 1.5 and 5 days if …". The prediction is worded: "Your next period is likely to start in {{start}} to {{end}} days." After the fact: "Based on your documented data, your period was likely to start between {{start}} and {{end}}." — [drip en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]
- GP Apps' Period Tracker uses the average of the last 3 cycles. — [App Store id330376830](https://apps.apple.com/us/app/id330376830) [STORE]
- Clue uses its last 12 cycles for predictions and the last 6 for averages. — [Clue support](https://support.helloclue.com/hc/en-us/articles/214434406-How-are-my-predictions-and-averages-calculated) [PRIMARY via search]
- Apple uses the logged period and cycle history plus optional sensor data. Its formula is unpublished. — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]
- Another indie app, cycle.log, describes the same approach: it adjusts the average cycle length automatically and computes the standard deviation of cycle length. — [cycle.log App Store listing](https://apps.apple.com/us/app/cyclelog/id1141567309?l=en) [STORE via search]

**Accuracy of the simple mean (the key number for Dian Dian)**
- Li, Urteaga et al. trained on the first 10 cycles of 186,108 Clue users (2,047,166 cycles) and predicted the 11th.
  - On day 0 of the next cycle, the RMSE was 7.50 days for the "mean of the user's past cycles" baseline, 7.49 for the median, 7.40 for an LSTM and 7.38 for their generative model. Sophisticated models barely beat the plain mean at the moment of prediction.
  - On day 40 of an ongoing cycle (that is, when the period is late), the mean baseline's RMSE was 21.9 days against 11.8 for their model, which explicitly models skipped/unlogged cycles.

  — [arXiv 2102.12439, Tables 1–3](https://arxiv.org/pdf/2102.12439v2) [PEER: preprint, extended NeurIPS 2020 ML4MH workshop paper; co-authors employed by Clue]
- Same paper: "for users with very consistent cycle lengths (i.e., a median CLD of 0), the median absolute error … is as low as 1.5 days, despite the RMSE for this group being 6.15". Outliers from skipped logging drive the RMSE. The absolute error rises steadily with the user's variability (median CLD). — [arXiv 2102.12439](https://arxiv.org/pdf/2102.12439v2) [PEER]
- A journal version of this work appears to be [PMC8714275](https://pmc.ncbi.nlm.nih.gov/articles/PMC8714275) (it was not fetched, because PMC returned a captcha).

**Cycle variability in large datasets**
- Bull et al. 2019, *npj Digital Medicine* 2:83:
  - 612,613 ovulatory cycles from 124,648 Natural Cycles users (data Sep 2016 to Feb 2019);
  - mean cycle length 29.3 days; "only around 13% of cycles are 28 days in length"; 65% of women had cycles of 25–30 days;
  - mean follicular phase 16.9 days (95% CI 10–30), mean luteal phase 12.4 days (95% CI 7–17);
  - cycle length fell by 0.18 days per year of age from 25 to 45;
  - cycle-length variation was 0.4 days (14%) higher with BMI over 35.

  — [PubMed 31482137](https://pubmed.ncbi.nlm.nih.gov/31482137/), [ScienceDaily/UCL release](https://www.sciencedaily.com/releases/2019/08/190826191924.htm) [PEER] [OLD: 2019; funded by Natural Cycles]
- Bull et al. (via the UCL release): "Apps giving predictions of fertile days based solely on cycle dates could completely miss the fertile window." Co-author J. Harper: "cycle dates alone are not informative". — [ScienceDaily](https://www.sciencedaily.com/releases/2019/08/190826191924.htm) [PEER/NEWS]
- Li et al. 2020, *npj Digital Medicine* (Clue data):
  - 378,694 users, 4,881,697 natural cycles, data 2015–2018;
  - cycle length mean 29.73 days (SD 5.73), median 29; period length mean 4.08 days (SD 1.76), median 4;
  - variability metric "cycle length difference" (CLD) = |length_n − length_(n−1)|; 7.68% of users have a median CLD over 9 days ("consistently highly variable").

  — [ar5iv 1909.11211](https://ar5iv.labs.arxiv.org/html/1909.11211), [npj DOI](https://doi.org/10.1038/S41746-020-0269-8) [PEER] [OLD: 2020]
- Li et al. 2020 on self-tracking artifacts:
  - forgetting to log a period makes a 30-day cycle look like 60 days;
  - the histogram of per-user maximum CLD has peaks near 30 and 60 days;
  - 42% of users had at least one flagged atypical cycle (about 1.59 per affected user);
  - in 89.18% of the excluded cycles there was no bleeding-related logging at all in the expected interval;
  - the study excluded cycles over 90 days, users with only 2 cycles, and "atypically long" cycles (CLD at least 10 days above the user's median CLD);
  - a period was defined as consecutive bleeding that may be broken by at most one day of spotting or no bleeding.

  — [ar5iv 1909.11211](https://ar5iv.labs.arxiv.org/html/1909.11211) [PEER]
- Apple Women's Health Study (Mahalingaiah et al. 2023, *npj Digital Medicine*):
  - 165,668 cycles from 12,608 US participants;
  - within-person variability was lowest at age 35–39;
  - it was 46% higher under 20, 45% higher at 45–49, and about 200% higher over 50;
  - it was higher for Asian and Hispanic participants and with obesity.

  — [PubMed 37248288](https://pubmed.ncbi.nlm.nih.gov/37248288/) [PEER]
- A Harvard page reports average within-person SDs of 5.33 days (under 20), 3.79 days (35–39) and 11.19 days (50 and over). Which publication the table comes from was not confirmed. — [Harvard Apple Women's Health Study page](https://hsph.harvard.edu/research/apple-womens-health-study/publications) [via search; attribution unverified]

**Accuracy of calendar-based ovulation and fertile-window predictions**
- Johnson, Marriott & Zinaman 2018 (*Curr Med Res Opin* 34(9):1587–94; 949 UK women, urinary LH):
  - in 28-day cycles the most common ovulation day was day 16, in only about 21% of cycles;
  - app accuracy at predicting the ovulation day was "no better than 21%";
  - because ovulation varies so much for a given cycle length, calendar and app methods based on cycle length alone cannot predict it accurately.

  — [Tandfonline DOI 10.1080/03007995.2018.1475348](https://www.tandfonline.com/doi/10.1080/03007995.2018.1475348) [PEER] [OLD: 2018; funded by SPD, a Clearblue-related company]
- Worsfold, Marriott, Johnson & Harper 2021 (*Women's Health*, 9 Oct 2021):
  - 10 apps (including Clue, Flo, Glow and Maya) were tested with 5 virtual cycle profiles;
  - the apps gave conflicting period dates, ovulation days and fertile windows;
  - all were right for the regular profile (woman 1), but the predictions diverged for the irregular profiles;
  - the authors conclude that ovulation and the fertile window can only be predicted with a marker (BBT, LH sticks, mucus).

  — [PMC8504278](https://pmc.ncbi.nlm.nih.gov/articles/PMC8504278), [DOAJ record](https://doaj.org/article/0563b418834e4303aa94e4550e410ba1) [PEER, via search] [OLD: 2021]

### Inferences
- A mean of past intervals plus a ±1–2-day window (drip's method) is a defensible, industry-standard way to estimate the next start for regular rhythms. For a regular user, a typical error of about 1.5 days is realistic. Above roughly 9 days of cycle-to-cycle swing, the estimate is mostly noise.
- **The biggest risk for Dian Dian is missing data, not the algorithm.** In a pixel grid, an empty day is "not logged", not "no event". If a user skips logging during an episode, the gap doubles (the 30 → 60 day artifact in Clue). Dian Dian therefore needs:
  1. a minimum number of intervals before showing an average or an estimate (3, as in drip);
  2. a robust centre (the median of intervals rather than the mean), because the mean of the gaps between starts equals (last start − first start)/(n − 1) and is very sensitive to a single missed episode;
  3. a cap or flag for outlier gaps (drip ignores gaps over 99 days; Li et al. excluded cycles over 90 days and those at least 10 days above the user's usual swing);
  4. a "this gap doesn't count" option (Clue's "hide this cycle");
  5. optionally, ignoring or flagging gaps that contain many unfilled days.
- Episode definition: drip and Clue both treat a 1-day break as the same episode. A generic tracker could merge runs separated by a single unlogged day. It should not merge runs separated by a day explicitly filled with another colour. This choice should be documented.
- An "irregularity" gate is useful. Apple's 17-day spread over 6 months, Clue's 9-day median CLD and drip's overlap rule are all ways of saying "don't predict". A generic tracker could hide the estimate when the spread between the shortest and longest recent gaps is large, and show only "days since last" and "typical gap: X–Y days".
- Showing a range (shortest–longest or interquartile range of recent gaps) is more honest than showing a single date. drip's wording "likely to start in X to Y days" is a good template.

### Gaps
- Within-woman variability numbers from Bull et al. 2019 (for example the share of women whose cycles vary by 7 days or more) could not be retrieved, because PMC and UCL blocked the fetch.
- No independent, published accuracy figure for Flo, Clue or Apple's live prediction engines was found. Only vendor claims (Flo) and research models (Clue data) were.
- The JMIR mHealth 2026 paper ([mhealth.jmir.org/2026/1/e92968](https://mhealth.jmir.org/2026/1/e92968/PDF)) that a search summary described as linking inaccurate predictions in irregular cycles to frustration, anxiety and attrition could not be read. Treat that claim as unverified.

---

## 3. How do Migraine Buddy and other symptom/medication trackers present frequency, intervals, durations and triggers?

### Takeaway
Symptom and migraine apps lead with counts per month (attack days per month, medication days per month), duration, severity mix and trigger/time-of-day breakdowns, often as a doctor-facing report. They do not predict the date of the next attack. Migraine Buddy's AI "prediction" is about when the current attack will end. Clinical day-count thresholds exist (≥15 headache days/month means chronic migraine; ≥10 or ≥15 medication days/month means a medication-overuse risk), and careful apps show them only as reference points, with explicit "not a diagnosis" wording.

### Cited Findings
- Migraine Buddy's listing says its reports cover "frequency and duration, pain intensity, pain location, migraine triggers, migraine medications, migraine symptoms". It offers an easy-to-read summary report for a doctor, employer or insurer. The premium tier (MBplus) adds "Advanced Features, Detailed Reports, Actionable Programs", including AI "end of attack prediction" and suggestions of symptoms and triggers. US pricing seen: $9.99/month and $69.99/year (another listing shows $12.99/month). — [Migraine Buddy App Store listing](https://apps.apple.com/us/app/migraine-buddy-track-headache/id975074413) [STORE via search]
- MigraineBot's premium tier includes graphs of attack days, average monthly pain and medication use. — [MigraineBot App Store](https://apps.apple.com/lu/app/migrainebot/id1568904180) [STORE via search]
- The Aiding Migraine app (small, third-party) documents its analytics:
  - "Frequency Trend": migraine days per month, one point per month;
  - "Pain Level Distribution": mild/moderate/severe doughnut;
  - "Time of Day Patterns": attack starts in 4-hour blocks;
  - "Day of Week Patterns";
  - a "Reference Numbers Clinicians Often Mention" table: 4 migraine days per month is "often where preventive medication discussions begin"; 8 is moderate; 15 sustained 3+ months is chronic; 10+ medication days per month (triptans, combination analgesics, opioids) or 15+ (simple analgesics/NSAIDs) is an "MOH risk zone".
  - Its wording: the charts are "a summary of your own diary entries" and "don't diagnose anything, and they aren't medical advice". The app "does not use these to label or diagnose you".
  - It cites ICHD-3 as the classification source.

  — [Aiding Migraine help: analytics](http://app.aidingmigraine.com/help/analytics.html) [PRIMARY]
- ICHD-3 criteria:
  - chronic migraine = headache on ≥15 days/month for >3 months, with migraine features on ≥8 days/month;
  - medication-overuse headache = headache on ≥15 days/month with regular overuse for >3 months, where overuse means ≥10 days/month of ergotamine, triptans, opioids or combination analgesics, or ≥15 days/month of simple analgesics;
  - the 10 and 15-day thresholds rest on expert opinion.

  — [PMC8728549](https://pmc.ncbi.nlm.nih.gov/articles/PMC8728549), [PMC6043466](https://pmc.ncbi.nlm.nih.gov/articles/PMC6043466), [J Headache Pain table](https://thejournalofheadacheandpain.biomedcentral.com/articles/10.1007/s10194-011-0393-6/tables/4) [PEER, via search]
- Bearable's "Advanced Symptom reports" show "a breakdown of the frequency, trend, average occurrence and the average severity of individual symptoms". Its support suggests logging "Migraine Severity", "Migraine Count" and "Migraine Duration" as separate measures. Full insights are premium, with a 7-day trial. — [Bearable support archive](https://bearable.app/support-archive/), [ChoosingTherapy review](https://www.choosingtherapy.com/bearable-app-review/) [PRIMARY via search / review]
- Clue Plus's cycle history is pitched to "spot recurring symptoms, such as headaches or mood changes" across cycles. Flo Premium gates "Symptom patterns and predictions". — [Clue Plus](https://helloclue.com/articles/how-to-use-clue/how-to-use-clue-plus) [PRIMARY]; [flo.health/premium](https://flo.health/premium) [PRIMARY via search]

### Inferences
- For occasional, non-periodic events (migraine, crying, sickness, a pill taken as needed), the stats users and clinicians actually use are:
  1. event days per month, as a trend;
  2. number of episodes per month;
  3. average and longest episode length;
  4. days since the last episode;
  5. the longest event-free stretch;
  6. day-of-week patterns.

  The "average gap" and "estimated next date" make sense only for rhythms that really are periodic (cycles, a scheduled pill). For random events they can mislead. A generic app should show the next-date estimate only when the gaps are regular enough (see the irregularity gate in question 2), and otherwise show only frequency and "days since".
- Because Dian Dian cannot know whether a colour means "migraine" or "period", it should never show clinical thresholds or labels ("chronic", "irregular", "overuse"). Counts per month are neutral and still let the user carry a meaningful number to a doctor.
- A "days with this colour per month" bar chart, plus "episodes" and "days since last", maps directly onto what Migraine Buddy and MigraineBot show, using only one colour per day.

### Gaps
- Migraine Buddy's help centre and its exact in-app report layout (whether it shows the interval between attacks or days since the last attack) were not found. Only store-listing descriptions were available.
- No dedicated medication-adherence app (for example a pill tracker's "missed doses" stats) was researched.

---

## 4. Regulatory and ethical caveats: Apple, Google Play, EU MDR, privacy, disclaimers

### Takeaway
What decides regulatory status is the claim (intended purpose), not the maths. Showing "your gaps averaged X days; next likely between A and B" is wellness or self-tracking. Claiming contraception, a fertile or safe window, or a diagnosis makes the app a medical device: class IIb under EU MDR Rule 15 for contraception. Apple requires a "check with a doctor" reminder and scrutinises medical-accuracy claims. Google Play requires every app to file a Health apps declaration, and health-feature apps that are not medical devices must carry a "not a medical device…" disclaimer. Period data has been the subject of major privacy enforcement (Flo/FTC 2021; Meta jury verdict 2025).

### Cited Findings
**Apple App Store Review Guidelines (fetched 2026-11-23)**
- 1.4.1: "Medical apps that could provide inaccurate data or information, or that could be used for diagnosing or treating patients may be reviewed with greater scrutiny." "Apps must clearly disclose data and methodology to support accuracy claims relating to health measurements…" "Apps should remind users to check with a doctor in addition to using the app and before making medical decisions." — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) [PRIMARY]
- 5.1.3: health, fitness and medical data are especially sensitive.
  - (i) No use or disclosure to third parties for advertising, marketing or use-based data mining.
  - (ii) No false data written into HealthKit, and apps "may not store personal health information in iCloud".
  - 5.1.2(vi): HealthKit data may not be used for marketing or advertising.
  - The guidelines do not mention menstrual data specifically.

  — [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) [PRIMARY]

**Google Play Health apps policy (fetched 2026-11-23)**
- Health apps that are not regulated medical devices must state in the description that the app is "not a medical device and does not diagnose, treat, cure, or prevent any medical condition", and must remind users to consult a healthcare professional. — [Play Console Help 16679511](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en) [PRIMARY]
- An app that "is not primarily a health app, but… has health-related features and accesses health data… is still in scope of the Health App policy". — [Play Console Help 16679511](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en) [PRIMARY]
- All developers must complete the Health apps declaration (Play Console > App content), including for testing tracks. — [Play Console Help 16679511](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en) [PRIMARY]; [Play Console Help 14738291](https://support.google.com/googleplay/android-developer/answer/14738291) [via search]
- Regulated medical-device apps must provide proof of clearance on request and are labelled "Medical Device" on Google Play. — [Play Console Help 16555673](https://support.google.com/googleplay/android-developer/answer/16555673) [via search]

**EU MDR (Medical Device Regulation)**
- Logging cycles and predicting periods without a medical purpose is not a medical device. Recommending the software for contraception or for conception support gives it a medical purpose. Regulators look at the overall impression of the marketing, including influencer claims. — [DLA Piper, "The legal landscape of femtech", Mar 2026](https://www.dlapiper.com/en/insights/publications/2026/03/the-legal-landscape-of-femtech); [Bristows](https://inquisitiveminds.bristows.com/post/102lqmm/dont-get-lost-how-femtech-can-navigate-the-eu-medical-device-and-ai-rules) [law-firm commentary, via search]
- MDCG 2019-11 places contraception software under Rule 15, which makes it class IIb. A Swiss Federal Administrative Court ruling relied on this to confirm that a fertility-tracker app is a medical device. — [Mondaq: Swiss court fertility tracker](https://www.mondaq.com/life-sciences-biotechnology-nanotechnology/1246458/software-as-a-medical-device-swiss-federal-administrative-court-confirms-fertility-tracker-app-is-a-medical-device) [via search]
- The cycle app Ovy obtained MDR class IIb certification as a contraceptive device (April 2025). — [FemTech Insider, 29 Apr 2025](https://femtechinsider.com/german-cycle-tracking-app-receives-mdr-certification-as-contraceptive-medical-device/) [NEWS, via search]
- The Commission proposed a revised software Rule 11 in December 2025. Its adoption status was not confirmed. — [COCIR position paper](https://www.cocir.org/wp-content/uploads/COCIR-Position-Paper-EU-MDR-Targeted-Revision-Classification-Rule-11_FINAL-.pdf) [via search; unverified status]

**Privacy enforcement on period data**
- FTC v. Flo Health. On 13 Jan 2021 the FTC announced a proposed settlement: Flo had promised to keep health data private but disclosed it (for example pregnancy status, as "app events") to marketing and analytics third parties, including Facebook's analytics. The order required:
  - an independent privacy review;
  - notifying users;
  - having third parties delete the data;
  - affirmative consent before sharing (order finalised on 22 Jun 2021).

  — [FTC press release, Jan 2021](https://www.ftc.gov/news-events/news/press-releases/2021/01/developer-popular-womens-fertility-tracking-app-settles-ftc-allegations-it-misled-consumers-about), [FTC staff analysis](https://www.ftc.gov/system/files/documents/cases/flo_health_analysis.pdf) [PRIMARY via search] [OLD: 2021]
- *Frasco v. Flo Health* (N.D. Cal., No. 3:21-cv-00757): on 1 Aug 2025 a jury found Meta liable under the California Invasion of Privacy Act for collecting Flo users' data through its SDK. Flo settled on 31 July. Google and Flurry settled before trial. A judge refused to overturn the verdict in September 2025. — [TechCrunch, 5 Aug 2025](https://techcrunch.com/2025/08/05/jury-rules-meta-violated-california-privacy-laws-by-collecting-menstrual-health-data-from-flo); [HIPAA Journal](https://www.hipaajournal.com/jury-trial-meta-flo-health-consumer-privacy/) [NEWS]
- Privacy-first apps market "data on device only". drip: "We do not collect, retain, or share any usage data or personal information… All menstrual health data is stored only on your device". — [drip en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]. Euki: no account; Mozilla found no third-party collection in core tracking. — [Mozilla: Euki](https://www.mozillafoundation.org/en/nothing-personal/euki-privacy-review/) [via search]

**Disclaimer wording in use (verbatim examples)**
- Apple: "Cycle Tracking should not be used as a form of birth control." / "Data from Cycle Tracking should not be used to diagnose a health condition." — [Apple Support 120356](https://support.apple.com/en-us/120356) [PRIMARY]
- GP Apps: forecasts "may not be accurate and should not be used to prevent unwanted pregnancy". — [App Store id330376830](https://apps.apple.com/us/app/id330376830) [STORE]
- drip: "this app is made by humans, and humans make mistakes. Always think for yourself"; predictions are worded "likely to start in X to Y days". — [drip en.json](https://gitlab.com/bloodyhealth/drip/-/blob/main/src/i18n/en.json) [PRIMARY]
- Aiding Migraine: "a summary of your own diary entries… don't diagnose anything, and they aren't medical advice". — [Aiding Migraine help](http://app.aidingmigraine.com/help/analytics.html) [PRIMARY]
- Google Play's required wording: "not a medical device and does not diagnose, treat, cure, or prevent any medical condition". — [Play Console Help 16679511](https://support.google.com/googleplay/android-developer/answer/16679511?hl=en) [PRIMARY]

### Inferences
- **Safe framing for Dian Dian:** describe the feature as a summary of the user's own squares ("rhythm of this colour"), with no domain words. That means no "period", "cycle", "ovulation", "fertile", "safe days", "late", "irregular", "chronic", "overuse", "symptom" or "diagnosis" in the app UI or the store copy for this feature. The user's own label (for example "Règles") may appear because it is user data. The app's own sentences should stay generic: "Depuis la dernière fois : 12 j", "Écart habituel : 26–31 j", "Prochaine fois probable : entre le 3 et le 8 déc., d'après tes cases". Keep "probable" plus a date range, never a single date. Add a short in-screen note on the lines of "Calcul fait sur tes cases ; ce n'est pas un avis médical ni une méthode de contraception". The contraception mention is the one Apple, GP Apps and others make explicit for anything that could be read as cycle-related.
- **Never compute or show a fertile window or ovulation day.** This is both inaccurate from dates alone (question 2) and the trigger for medical-device status in the EU (Rule 15, class IIb).
- **Store listing:** if the store copy or screenshots advertise this feature with period examples, the app moves toward Google Play's "health-related features" scope and Apple's 1.4.1 scrutiny. Neutral examples ("sport", "migraine", "a colour") are lower-risk. The Health apps declaration must be filed anyway (Google requires it from all apps). Whether to tick health features there is a judgement call for the owner.
- **Privacy:** Dian Dian syncs trackers to its own backend. If users log periods, that backend holds reproductive-health data that users entered themselves. The Flo cases show the main risk is third-party SDKs (analytics, ads) seeing it. Keep any analytics events for this feature free of tracker labels and colour meanings (log only "rhythm card viewed"). Apple 5.1.3(ii) forbids storing personal health information in iCloud. That rule matters only if iCloud were ever used.
- Clue's and drip's "turn predictions off" toggle doubles as an ethical feature: some users (for example those trying to conceive, or with irregular cycles) may find estimates stressful.

### Gaps
- The text of MDCG 2019-11 and of MDR Rule 15 was not read directly. The EU points come from law-firm commentary.
- US FDA "general wellness" policy and FDA clearance of contraceptive apps were not researched in this pass.
- GDPR Article 9 (special-category health data) and whether user-entered, generic-labelled pixels count as health data were not researched. Legal advice would be needed.
- Whether the Apple Review Guidelines have a 2026 revision touching health data was not checked: the fetched page showed no update date.

---

## 5. Do generic trackers (Daylio, Bearable, pixel apps, Track & Graph) compute intervals or rhythm between occurrences of a value, and how do users react?

### Takeaway
Among generic trackers, only Track & Graph documents interval statistics: "Time since last" and "Average time between" occurrences matching a label or value filter. Bearable offers frequency and "average occurrence" of symptoms. Daylio offers period charts and frequency, and no documented "days since". No pixel or "year in pixels" app with rhythm or interval stats was found, which leaves room for Dian Dian. The many single-purpose "time since I last…" apps on the App Store show that "days since last" is a valued stat on its own. Direct evidence of user reactions (Reddit) could not be collected.

### Cited Findings
- Track & Graph's "Average time between" is defined as "(last-first)/(size - 1)" over the data points matching all filters (optional label and value-range filters). "Time since last" "shows the last data point matching all filters and also the time since that data point was tracked". Custom statistics are possible with Lua graphs. — [Track & Graph docs: statistics](https://samamco.github.io/track-and-graph/tutorial/graphs/statistics) [PRIMARY]
- Bearable: "Advanced Symptom reports show you a breakdown of the frequency, trend, average occurrence and the average severity of individual symptoms". This is premium, with a 7-day trial. — [Bearable support](https://bearable.app/support-archive/), [ChoosingTherapy](https://www.choosingtherapy.com/bearable-app-review/) [via search]
- Daylio: statistics on weekly, monthly or yearly charts, a calendar, and per-mood, per-activity and per-group statistics. A "days since" or interval feature was not found. — [Daylio App Store listing](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242) [STORE via search]
- A whole category of single-purpose apps exists around "time since last time": TimeSince, "Last: Track Time Passed Since", LastTime Logger, TheLastTime and others. — [TimeSince](https://apps.apple.com/us/app/id1082136952), [Last: Track Time Passed Since](https://apps.apple.com/us/app/-/id1092307625), [LastTIme Logger](https://apps.apple.com/ca/app/lasttime-logger/id6756869213) [STORE]
- User sentiment in dedicated apps: one App Store reviewer values drip's stats tab because "you can see your average cycle deviation". — [drip App Store listing](https://apps.apple.com/us/app/drip/id1584564949?l=en) [STORE review via search; anecdote]
- Researchers note that apps' predictions ignore stress or diet changes and do not let users correct the app or mark why a cycle was irregular. Accuracy for irregular users "can be so bad that an app's predictions are meaningless". — [Digital Trends](https://www.digitaltrends.com/phones/the-problems-and-promises-of-period-tracking-apps/), [STAT News, 2017](https://www.statnews.com/2017/05/02/period-tracking-apps-flaws/) [NEWS, via search] [OLD: 2017 for STAT]

### Inferences
- Track & Graph's formula equals the mean of the intervals. Applied per data point, it would count each day of a multi-day episode, so on a pixel grid it must be applied to episode starts only. This confirms that Dian Dian's "episode = run of consecutive days" step is essential.
- Dian Dian would be the first "year in pixels" app with episode-based rhythm stats. The stats map naturally onto the grid: the days since last, typical gap and typical episode length can be drawn as markers on the same 12×31 view, and an estimated window can be shown as faint outlined squares, like Clue's light-pink predicted days.
- Expected reaction, extrapolated from dedicated apps:
  - regular users value the averages and the "deviation";
  - irregular users are frustrated by wrong predictions.

  Therefore show the estimate only when the rhythm is regular enough, offer an off switch, and allow ignoring an outlier gap.
- A low-risk, high-value starter set for any colour, without needing a theme: days since last; episodes this month or year; days with this colour per month; median gap between starts with shortest–longest; median episode length; longest stretch without this colour. Add "next probably between A and B" only when there are at least 3 gaps and the spread is small.

### Gaps
- Reddit (r/TwoXChromosomes, r/Periods, r/migraine) was not accessible to the search tool, so there is no first-hand evidence of which stats users find useful or how they react to rhythm/interval stats in generic apps.
- No documentation was found for the "Pixels" / "Year in Pixels" family of apps. Whether any of them offers interval stats is unknown (none was surfaced).
- User reactions to Track & Graph's interval statistics (reviews, issues) were not collected.
