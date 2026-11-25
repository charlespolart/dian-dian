# Statistics and insight features in mood, journal and "year in pixels" apps (inventory, free vs paid, presentation, user verdicts)

Context for the report writer: Dian Dian is an indie "year in pixels" app (~200 accounts). Each tracker is a 12×31 grid, one colour per day, with a user-defined ordered legend (colour + label). Templates are Mood (Great→Low), Sleep (8 h+ → <5 h) and Reading (1 h+ → None). Users also build generic trackers: study, exercise (Done/Almost/Rest/Sick), crying, pill, periods, money ranges, chores. Today's stats only count filling (days filled, streaks, % of year, legend distribution, monthly fill rate, weekday distribution). The owner finds them nearly useless. The goal is useful stats for generic trackers, with one real stat free as a teaser.

Evidence labels used below:
- [PRIMARY]: the developer's own help centre, blog or website.
- [STORE]: App Store listing (description, IAP list, release notes or shown reviews), read November 2026.
- [REVIEW]: an editorial review site or press article.
- [USER]: a single long-term user's blog, or a quoted app-store or Reddit review.
- [EST]: third-party revenue or download estimate (Adapty, Screensdesign, AppGoblin, AppBrain).
- [COMPETITOR]: written by a rival app's maker, so commercially biased.
- [SNIPPET]: seen only in a search-result snippet; the page itself could not be fetched or was not read. Treat it as unverified.

Reddit itself could not be fetched or searched directly (the domain is blocked for this crawler). Reddit sentiment below comes only from an aggregator (GummySearch) and from blogs.

## Q1. Which statistics and insights does each app offer?

### Takeaway
Almost every leading app has the same core. There is one ordered "anchor" scale (mood, 5 levels) shown as a line chart over time, a distribution bar or donut, a weekday average and a year-in-pixels grid. Unordered tags (activities, icons, factors) are then analysed against that anchor: counts, co-occurrence ("Often together"), best/worst days, and average mood with vs without the tag. Differentiation comes from depth: per-tag deep dives, time-lagged effects, sleep and exercise modules, period-vs-previous comparisons, and AI weekly reviews. Word clouds and note search are rare or absent in what I could verify.

### Cited Findings

**Daylio** (Relaxio s.r.o., the category leader; claims "20M+ users")
- [PRIMARY] The website describes charts from "simple mood lines" to "superior correlation stats". It also lists "monthly or yearly statistics created from your logs", "advanced statistics for every mood, activity or group", Year in Pixels ("whole year in one chart", exportable as an image), goals, "habits and achievements", and sharing stats with friends. Streaks are not named on the site — [daylio.net](https://daylio.net/)
- [STORE] Daylio's iOS description promises "exciting statistics about your life on weekly, monthly or yearly charts", "Deep dive into advanced statistics for every mood, activity or group" and "See your whole year in 'Year in Pixels'". A release note says "Keeping your streak alive is a little easier now". Latest version is 1.78.1 (5 Nov). Rated 4.8 from about 63K ratings — [App Store US](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
- [SNIPPET] Wikipedia describes Daylio's stats as several charts, "such as a monthly mood line graph and an average daily mood bar chart". It lists the Year in Pixels display among the basic features — [Wikipedia](https://en.wikipedia.org/wiki/Daylio)
- [USER, 2020] The Stats screen shows "Mood Count", "Average Monthly Mood", "Average Activity Count", "Average Daily Mood" and "(Activities that are) Often Together", described as "activities and moods that often appear together in entries" — [3 Years with Daylio](https://hyphenizedchango.wordpress.com/2020/06/19/3-years-with-daylio-app/)
- [SNIPPET] An Android release note quoted on the 4PDA forum says a version added the "Average Daily Mood" and "Often Together" charts — [4PDA](https://4pda.to/forum/index.php?showtopic=759562)
- [STORE review, 2021] The weekly report shows "average mood and activities", activities per mood, the week's photos, and mood stability "only if you have premium" — [App Store US](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
- [REVIEW, updated 29 Jul 2026] The free Stats hub shows the logging streak, a mood chart showing "which activities influenced your mood on a given day", achievements, mood count, goal days and activity count. Premium "advanced stats" show how often things like "good sleep" or "fast food" influence your mood — [ChoosingTherapy](https://www.choosingtherapy.com/daylio-app-review/)
- [USER, 2017] Daylio's stats were windowed per month ("all of the data was windowed at the month-level"). "Often Together" shows only same-entry co-occurrence: no before/after (lagged) effects, no tag-to-tag relationships, and hard-to-see multi-month trends. The author exported CSV and did this analysis himself — [napsterinblue blog](https://napsterinblue.github.io/blog/2017/09/15/hey-hows-it-going-empirically/)

**Pixels** (Teo Vogel, indie; Android "Mood Tracker & Journal: Pixels", iOS "Pixels Journal")
- [STORE] The listing claims "Detailed stats and charts", spotting "emotional patterns across weeks and months" and watching the year fill pixel by pixel. Release 2.4.x (2.4.2 dated 12 Nov) redesigned reports with new charts, added **comparing any period with the period before it**, and lets users export pixels, months and charts as images with gradient backgrounds and chosen aspect ratios. The iOS app has only 45 ratings (4.8) — [App Store](https://apps.apple.com/app/id1668460700)
- [SNIPPET] The Google Play description says "see your average mood by tag and by weekday", with weekly and monthly patterns. It also lets users create custom tags for "activities, habits, medications, or anything you'd like" — [Google Play](https://play.google.com/store/apps/details?id=ar.teovogel.yip&hl=en_US&gl=US)
- [PRIMARY] The developer's page only says "Gain insights with statistics and beautifully crafted graphs that provide a bird's eye view of your mood patterns" — [teovogel.me/pixels](https://teovogel.me/pixels/)
- [EST] On Android Pixels has 1M+ installs and a 4.57 rating from about 24K ratings — [AppBrain](https://www.appbrain.com/dev/Teo+Vogel/) ([SNIPPET])

**DailyBean** (Bluesignum; 4.8 from about 71K iOS ratings)
- [PRIMARY, 12 Mar 2026] The Report covers a selected month or year. Its sections:
  - Monthly/Yearly View: calendar-style.
  - Mood Flow: a line graph of mood through the month.
  - Mood Bar: the share of each mood, as a bar.
  - Frequently Recorded: the most-logged activity and emotion icons, as a ranked list.
  - Best & Worst: activities linked to the happiest and lowest days.
  - Icon Deep Dive: how average mood changed when a given icon was recorded; it needs at least 3 logs of that icon.
  - Sleep Analysis, Moods by Sleep (the effect of sleep duration on mood), Exercise Analysis, and Favorite Exercise.
  - A special year-end "Recap".
  - Reports are available after 1 day of logging — [DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)
- [STORE] DailyBean promises "easy-to-read charts" relating habits and activities to mood, plus a year-in-pixels view. Version 4.13.0 added step and music analyses to the report page. Health, sleep and weather data can sync automatically. A reviewer says of sleep hours, "It will tell you if that's healthy or not" — [App Store US](https://apps.apple.com/us/app/id1553223828)

**How We Feel** (nonprofit, built with Yale's Center for Emotional Intelligence; 4.9 from about 30K ratings, Editors' Choice)
- [STORE] The app reads HealthKit sleep, exercise and health data to "spot patterns over time". It has a Weekly Review/weekly insights, with a feedback screen added in 1.15.5 (02/12/2025), and a "new way to interact with charts" (1.17.7, for select users). Analytics are available in Spanish, and check-in tags can include body sensations. A reviewer praises "all the data collected from all possible angles", including weather, time of day and exercise minutes — [App Store US](https://apps.apple.com/us/app/how-we-feel/id1562706384)
- [SNIPPET] Version 1.14.1 introduced an "AI-powered weekly review" that helps users "notice patterns and draw connections between your check-ins". Users can add water, caffeine and alcohol intake to "correlate your emotional history with more lifestyle habits" — [App Store](https://apps.apple.com/app/id1562706384), [App Store CA](https://apps.apple.com/ca/app/id1562706384)

**Bearable** (symptom and mood tracker)
- [PRIMARY] Insights include:
  - Trends reports.
  - A Comparison Graph that overlays a factor on mood, symptoms, sleep or energy.
  - An **Impacts tab** with correlation reports.
  - A **Correlations grid** comparing factors across several outcomes.
  - Calendar and Timeline views.
  - Goals and Experiments.
  - CSV export "for manual analysis or AI tools".

  — [Bearable free vs premium](https://bearable.app/support/common-questions/bearable-free-vs-premium-features/)
- [PRIMARY] The Factor Effect Report shows "the correlation between a Factor and your Health Outcomes". It comes in mood, symptom score, individual symptom and sleep versions, with factors sortable by "Best" or "Worst". The time window can be set from the same day up to "the seven-day window after the factor was entered", to show a delayed effect. A magnifier icon gives "a comparison between the effect with and without the Factor" — [Bearable Factor Effect Report](https://bearable.app/support/howto/the-factor-effect-report/)

**eMoods** (Yottaram, bipolar-focused, on-device; 4.8 from about 4.3K ratings)
- [STORE] eMoods charts daily highs and lows, sleep, medications and symptoms, with in-app graphs (monthly and 30-day). Medication changes are marked on the graphs. A **printable monthly PDF report** can be emailed to a doctor or therapist. Latest version 1.3.28 (12/07/2025) — [App Store US](https://apps.apple.com/us/app/id1184456130)

**Moodnotes** (CBT-based, Mosaic S.r.l.; 4.6 from about 11K ratings)
- [STORE] Moodnotes offers "personal statistics and mood insights", a "Notable insights" section and thinking-trap detection ("overgeneralising", "emotional reasoning"). Version 3.8.0 "improved the stats section to show what affects mood". Latest version is 3.14.8 (24 Oct 2024), so the app looks barely maintained — [App Store](https://apps.apple.com/app/id1019230398)

**Reflectly** (AI journal; 4.5 from about 18K UK ratings)
- [STORE] Reflectly uses AI to show "mood correlations and graphs", with daily, weekly and monthly overviews and "personalised insights" — [App Store UK](https://apps.apple.com/gb/app/id1241229134?l=en-gb)

**stoic.** (journal)
- [SNIPPET] A "Trends" feature "visualizes metrics that matter to you including mood, emotions, sleep, health, writing". A US reviewer asked for a **word cloud** of most-used words next to the mood trend, which implies there was none at the time — [App Store](https://apps.apple.com/app/id1312926037)

**MoodKit** (A Two Lab) [COMPETITOR source]
- MoodKit puts Year in Pixels inside its statistics scopes, plus "ranked mood drivers, activity combinations, weekday rhythms, and self-experiments", and a large iOS widget. The same article judges Pixels' stats "descriptive only" and Daylio's analysis "shallow". The article is dated 4 Aug 2026 and updated 30 Oct 2026 — [MoodKit blog](https://moodkit.co/blog/year-in-pixels-apps/)

**Finch, Mood Balance**
- [SNIPPET] Finch Plus gives "additional customisation options for birds, more in-depth habit tracking and removes adverts". No source described Finch's mood charts — [Internet Matters](https://www.internetmatters.org/advice/apps-and-platforms/wellbeing/finch/)

### Inferences
- The shared "stats menu" across Daylio, DailyBean and Pixels has five parts:
  1. A trend line of the ordered scale.
  2. Its distribution.
  3. An average by weekday.
  4. Tag frequency.
  5. "Average anchor value when tag X is present", shown as best/worst, often together, or a deep dive.

  Dian Dian already has parts 2 and 3 (distribution, weekday), but over one tracker only. Its stats lack an anchor, so part 5, the one users credit for "insight", is impossible today.
- Newer differentiators are period-vs-previous comparison (Pixels 2.4), lagged windows (Bearable, up to 7 days after), a year-end recap (DailyBean) and AI weekly reviews (How We Feel). All of them can be built from data that a pixel grid already holds.
- A word cloud and note search appear as user requests (stoic.) rather than shipped features in the apps I could verify. That is an inference from absence, not proof that no app has them.

### Gaps
- I found no official Daylio help page listing the exact stat cards and their tier. Daylio's card list above is rebuilt from user blogs, reviews and snippets.
- I could not fetch Pixels' current Google Play description (the page came back truncated twice), so the "average mood by tag and weekday" wording is snippet-only.
- I did not verify whether Daylio, DailyBean or Pixels offer full-text note search or word clouds.
- No primary source on Finch's or Mood Balance's stats was found.
- How We Feel's "Analyze" tab layout and time-of-day breakdown are not documented on pages I could read.

## Q2. What is free and what is premium in each app? Is there a free teaser of a premium stat?

### Takeaway
Gating strategies vary widely:
- **Metric gating**: counts free, averages, stability and per-tag deep dives paid (Daylio, DailyBean).
- **History gating**: the last 30 days free, longer ranges and correlation reports paid (Bearable).
- **Everything free**: premium sells storage or customisation (Pixels per its newest Play listing, eMoods, How We Feel).
- **Stats fully paid**: Moodnotes, Reflectly.

The clearest "free teaser → premium depth" pair is DailyBean's free **Best & Worst** (activities linked to the happiest and worst days) versus its premium **Icon Deep Dive** (average mood per icon).

### Cited Findings
- **DailyBean** [PRIMARY]:
  - Free: Monthly/Yearly, Mood Flow, Mood Bar, Frequently Recorded, Best & Worst.
  - Premium only: Icon Deep Dive, Sleep Analysis, Moods by Sleep, Exercise Analysis, Favorite Exercise.

  — [DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights). Prices [STORE]: Monthly Pass $3.99–5.99, Annual Pass $19.99–49.99 (tiers unlabelled). The free app shows ads and sells "clovers" — [App Store US](https://apps.apple.com/us/app/id1553223828)
- **Daylio** (the split is not documented by the developer, and sources conflict):
  - [REVIEW, Apr 2025] "The free version offers mood count, level and activity count statistics. The paid one will show you your average mood, mood stability and many other things" — [moodtrackers.org](https://moodtrackers.org/daylio-app-review/)
  - [REVIEW, Jul 2026] Free: streak, mood chart with influencing activities, mood count, activity count, goal days. Premium: advanced stats (how often "good sleep" or "fast food" influences mood), full-colour PDF export, more icons and colour schemes, unlimited goals — [ChoosingTherapy](https://www.choosingtherapy.com/daylio-app-review/)
  - [SNIPPET, 2026] One source lists "Advanced stats, Year in Pixels, automatic cloud backup, PIN lock" as premium — [makeheadway](https://makeheadway.com/blog/daylio-review/) (404 when fetched). This contradicts Wikipedia, which lists Year in Pixels among basic features — [Wikipedia](https://en.wikipedia.org/wiki/Daylio).
  - [STORE reviews] "mood stability ... only if you have premium" (2021). Another reviewer upgraded "to unlock unlimited moods and activities" (2022) — [App Store US](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
  - [STORE] IAPs listed: Daylio Premium $4.99 (monthly), $17.99 / $23.99 / $35.99 (yearly variants), Lifetime Premium $59.99 — [App Store US](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
- **Bearable** [PRIMARY]:
  - Free: Trends reports and the Comparison Graph for the **past 30 days only**, Calendar/Timeline, widgets, CSV export, limited Goals/Experiments.
  - Premium: Impacts tab (correlation reports), correlations grid, 60/90/365-day ranges, unlimited Goals/Experiments, custom health measurements.

  — [Bearable free vs premium](https://bearable.app/support/common-questions/bearable-free-vs-premium-features/). The correlation graph needs premium "to scroll back through all time periods" — [Factor Effect Report](https://bearable.app/support/howto/the-factor-effect-report/). Price [SNIPPET]: $34.99/yr or $6.99/mo with a 7-day trial — [ChoosingTherapy Bearable](https://www.choosingtherapy.com/bearable-app-review/)
- **Pixels**:
  - [SNIPPET] The newest Google Play listing says "Premium: add up to 3 HD photos to each pixel. Every feature for your mental well-being is free; Premium only adds photo storage" — [Google Play](https://play.google.com/store/apps/details?id=ar.teovogel.yip&hl=en_US&gl=US)
  - [STORE] iOS IAPs: Pixels+ $4.99, Pixels Cloud+ $1.99 / $21.99. A reviewer says "This app does have a premium for the full features, but an understandable one" — [App Store](https://apps.apple.com/app/id1668460700)
  - [EST] AppGoblin estimates Android revenue under $10K a month, 55% from ads and 45% from IAP — [AppGoblin](https://appgoblin.info/apps/ar.teovogel.yip) ([SNIPPET])
- **eMoods** [STORE]: the core tracker, graphs, monthly PDF reports and notes are free. Pro ($1.99/mo or $9.99/yr) adds custom symptoms and multiple timestamped notes per day — [App Store US](https://apps.apple.com/us/app/id1184456130). A vendor PDF instead quotes "Enhanced" at $50/yr and "Pro" at $100/yr for a cloud "eMoods Insights" version. This conflicts with the store and may describe a different product — [IntuitionLabs PDF](https://intuitionlabs.ai/software/pdfs/emoods.pdf) ([SNIPPET])
- **How We Feel** [STORE]: completely free, funded by donations, with no IAP tiers listed — [App Store US](https://apps.apple.com/us/app/how-we-feel/id1562706384)
- **Moodnotes** [STORE]: premium unlocks "unlimited entries per day, personal statistics and mood insights, notes on entries", "Notable insights" and more articles. Prices: Premium 1 Month $14.99, 1 Year $29.99–89.99 — [App Store](https://apps.apple.com/app/id1019230398)
- **Reflectly** [STORE]: premium adds "advanced statistics, actionable insights, and much more". A 2020 reviewer: "you have to write seven stories before unlocking your stats", then found they had to pay. UK prices run from £4.99 to £58.99 — [App Store UK](https://apps.apple.com/gb/app/id1241229134?l=en-gb)
- **MoodKit** [COMPETITOR]: "Logging is free. Insight cards are Premium". $39.99/yr (1-week trial) or $79.99 lifetime — [MoodKit blog](https://moodkit.co/blog/year-in-pixels-apps/)
- **Pixa** (micro year-in-pixels app) [EST]: $0.99–1.99/mo, $17.99–19.99/yr, $39.99 lifetime. Estimated revenue is under $1K a month (Oct 2026). Its premium contents are not described — [Adapty paywall library](https://adapty.io/paywall-library/pixa/)

### Inferences
- The free-teaser patterns seen in the wild, in rough order of how well they match Dian Dian's "one real stat free":
  1. **Shallow free version of the same insight, deep version paid.** DailyBean: Best & Worst is free, Icon Deep Dive is paid. The free stat is already a real association, not a count.
  2. **Recent window free, full history paid.** Bearable gives 30 days free; ranges and correlation reports are paid.
  3. **Counts free, averages paid.** Daylio. This is close to what Dian Dian has now, which the owner calls useless. It suggests counts alone do not feel like a "real stat".
  4. **Locked card visible inside a free report.** A Daylio reviewer saw "mood stability ... only if you have premium" inside the weekly report. This implies the locked stat is shown in context, though the exact UI is not verified.
- Effort gates before stats ("write 7 stories to unlock") followed by a paywall drew complaints for Reflectly. That suggests "unlock stats after N days" should not end in a surprise paywall.
- Pixels moved toward "all wellbeing features free". It earns mostly from ads on Android (estimated) and a one-time unlock, which is a different model from Dian Dian's freemium-with-stats.

### Gaps
- No primary Daylio table of free vs premium stat cards, and sources conflict on whether Year in Pixels is free.
- What exactly Pixels+ unlocked on iOS before the "photo storage only" change, and when the change happened.
- DailyBean's per-tier prices are unlabelled in the store.
- No screenshots or text of how locked stats are teased (blurred card, sample data, lock icon) for any app could be read. Adapty and Screensdesign pages hold screenshots but no readable text.

## Q3. How do apps handle ordered scales vs unordered categories, and how do they phrase insights in plain language?

### Takeaway
In every app reviewed, one ordered scale (mood, or a set of numeric outcomes in Bearable) is mapped to numbers and averaged. Unordered things (activities, icons, factors, tags) are never averaged themselves: they are counted, and their effect is expressed through the ordered scale ("average mood when X", "with vs without X", "best & worst days"). Plain-language phrasing is short and label-like ("Often together", "Best & Worst", "Notable insights", "Moods by Sleep"). Bearable explicitly frames results as correlation and tells users to "be critical".

### Cited Findings
- **Ordered scale → numeric charts.** Daylio shows "a monthly mood line graph and an average daily mood bar chart" ([SNIPPET] [Wikipedia](https://en.wikipedia.org/wiki/Daylio)) and, in premium, "average mood, mood stability" ([moodtrackers.org](https://moodtrackers.org/daylio-app-review/)). DailyBean shows its 5-level mood as a "Mood Flow" curve and a "Mood Bar" share ([DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)). Pixels shows "average mood by tag and by weekday" ([SNIPPET] [Google Play](https://play.google.com/store/apps/details?id=ar.teovogel.yip&hl=en_US&gl=US)).
- **Unordered tags → counts and co-occurrence.** Daylio's "Often Together" shows "activities and moods that often appear together in entries" ([3 Years with Daylio](https://hyphenizedchango.wordpress.com/2020/06/19/3-years-with-daylio-app/)). DailyBean's "Frequently Recorded" ranks the most-logged icons ([DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)).
- **Unordered tag → effect on the ordered scale.** DailyBean's "Icon Deep Dive" shows "how your average mood changed when you recorded a specific icon", with a minimum of 3 logs. "Best & Worst" lists "activities linked to your happiest and lowest days" ([DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)). Bearable gives "a comparison between the effect with and without the Factor", sorted by "Best" or "Worst", over the same day up to 7 days after ([Bearable](https://bearable.app/support/howto/the-factor-effect-report/)).
- **Ordered input → ordered outcome.** DailyBean's "Moods by Sleep" analyses "the specific impact your sleep duration has on your mood" (premium) ([DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)). This is the closest analogue to two Dian Dian trackers with ordered legends (Sleep × Mood).
- **Minimum-data thresholds.**
  - Bearable needs "three entries with a factor and three entries without" before a factor appears ([Bearable](https://bearable.app/support/howto/the-factor-effect-report/)).
  - DailyBean needs 3 logs for Icon Deep Dive ([DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)).
- **Correlation caveats in the copy.** Bearable: the report "shows you the correlation", users should be "critical of the results", and if something "doesn't seem right it's important to question why" ([Bearable](https://bearable.app/support/howto/the-factor-effect-report/)).
- **Plain-language verdicts.** A DailyBean reviewer says of sleep hours: "It will tell you if that's healthy or not" ([App Store US](https://apps.apple.com/us/app/id1553223828)). Moodnotes names thinking traps in everyday words ("overgeneralising", "emotional reasoning") and has a "Notable insights" section ([App Store](https://apps.apple.com/app/id1019230398)). How We Feel uses an AI weekly review to "draw connections between your check-ins" ([SNIPPET] [App Store](https://apps.apple.com/app/id1562706384)). MoodKit uses "ranked mood drivers" ([COMPETITOR] [MoodKit blog](https://moodkit.co/blog/year-in-pixels-apps/)).
- **Limits of averaging an ordered scale.**
  - [USER, Oct 2024] A 5-year Daylio user found her yearly average was skewed toward the middle by logging three times a day. On her daughter's birth day, the extremes "cancel each other out" ([Good Enough Job, Substack](https://goodenoughjob.substack.com/p/5-years-of-mood-tracking-and-what)).
  - [REVIEW, Aug 2025] "Five mood options can't capture the full range", and activity checkboxes don't show how meaningful or draining an activity was ([Android Police](https://www.androidpolice.com/i-used-daylio-track-moods-for-month/)).
- [SNIPPET] Because the user chooses which activities to tag on which day, activity-influence stats depend on how consistently entries are tagged ([valthinks Substack](https://valthinks.substack.com/p/mood-tracking)).

### Inferences
- Dian Dian's legend order is the natural ordinal scale. For legends where order means "better→worse" or "more→less" (Mood, Sleep, Reading, money ranges, exercise Done→Sick), the app can compute averages, trends and "with vs without" effects, as Daylio and DailyBean do for mood. Unordered or binary legends (pill taken/not, periods, crying yes/no, chores) should only get counts, gaps and "days since", runs (current/longest run of a given colour, cycle length) and co-occurrence. This argues for an "ordered" flag on a tracker, or a sensible default per template, rather than treating every legend as categorical.
- With multiple trackers per user, the DailyBean "Moods by Sleep" pattern generalises to "Tracker B's average level on days when tracker A = X". This is the cross-tracker analogue of "Icon Deep Dive" and "Best & Worst", and it needs a minimum count (3 per side seems to be the industry floor).
- Phrasing in the category is short and hedged. Copy such as "On days marked *Done*, your Mood was more often Great/Good (8 of 11) than on other days (5 of 19)" fits observed norms better than causal language. Showing the raw counts follows Bearable's "be critical" stance.

### Gaps
- No source showed the exact sentence templates Daylio or DailyBean use inside their cards. Card names were found, but not their body copy.
- Whether Daylio's "Often Together" is a raw count or a percentage was not documented in any source found.
- Three search snippets could not be traced to a specific page, so they are left out of the findings:
  - a Daylio reviewer saying patterns become clear only after about a month of data;
  - a Bearable support page recommending at least 14 days with a factor before deciding on its impact;
  - a Bearable help article warning that symptoms can look "worse with more exercise and also less exercise", meaning exercise "probably didn't really have any effect".
- No app found handles fully user-defined, non-mood ordinal legends (e.g. "money ranges") explicitly. Bearable's "custom health measurements" (premium) is the closest, but its analysis was not documented.

## Q4. What do users say is genuinely useful vs gimmicky? Is there a feature people specifically pay for?

### Takeaway
Users credit the "this activity goes with better or worse days" view (correlations, often together, best & worst) and the year or month view of cycles. Those confirm hunches and trigger small experiments, and seasonal patterns stand out. Long-term users say charts become "beautiful" but non-actionable, averages hide extremes, and month-windowed stats miss lagged effects. Paid conversion is tied to Daylio's overall depth and to exports for clinicians (PDF), not clearly to one stat. Clinical trackers (eMoods) are valued for monthly reports to share with a doctor.

### Cited Findings
- **Useful: confirming hunches and running experiments.** [REVIEW, Aug 2025] Daylio "automatically generates graphs of your moods over time, along with correlations between moods and activities". "Seeing them stacked in charts made me realize these were not just hunches". The author saw "Days with exercise usually get logged as good or rad" and then moved walks and hard tasks around — [Android Police](https://www.androidpolice.com/i-used-daylio-track-moods-for-month/)
- **Useful: activity–mood links (Reddit, via aggregator).**
  - "look at the stats for how they affect your mood"
  - a correlation like "rainy weather is linked to sadness"
  - Bipolar UK: "has a graph for the month so I can see the cycles"
  - eMoods: "the best for tracking sleep"
  - DailyBean helps "see what triggers an episode or what helps me manage better"

  Communities include r/bipolar, r/bipolar2, r/PMDD and r/androidapps (275 Reddit reviews, 45 posts) — [GummySearch](https://gummysearch.com/tools/best-products/mood-tracker-app/)
- **Useful: seasonal and recurring patterns over years.** [USER, Oct 2024] The yearly logs "look like maps of a heartbeat". September and October are recurrently hard, and June and January good for writing. But "there is no such thing as a baseline year" — [Good Enough Job](https://goodenoughjob.substack.com/p/5-years-of-mood-tracking-and-what)
- **Gimmicky: charts without action.** [SNIPPET] A 5.5-year user said the habit became a mindless daily ritual that produces "beautiful charts but zero actionable wisdom" — [Medium](https://medium.com/@k4m1tsuki/5-5-years-of-mood-tracking-why-data-doesnt-equal-insight-67b624050b8b) (403 when fetched)
- **Missing: lagged and multi-month analysis.** [USER, 2017] Stats were "windowed at the month-level". He wanted the before/after effects of tags (e.g. does drinking follow rough days), tag-to-tag relations and multi-month trends, so he exported CSV — [napsterinblue](https://napsterinblue.github.io/blog/2017/09/15/hey-hows-it-going-empirically/). Bearable's same-day-to-7-day window addresses exactly this — [Bearable](https://bearable.app/support/howto/the-factor-effect-report/)
- **Risk: obsessing over data.** [REVIEW] There is "the danger of obsessing over the data", and Daylio "can feel oversimplified at times" — [Android Police](https://www.androidpolice.com/i-used-daylio-track-moods-for-month/)
- **Paying for depth or export.**
  - [Reddit via GummySearch] "I pay for daylio its worth it"; one user planned a lifetime plan; "I use Reflectly and paid for it, don't love it" — [GummySearch](https://gummysearch.com/tools/best-products/mood-tracker-app/)
  - [STORE review, 2024] The continued updates "have made it worth buying the premium version" — [App Store US](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
  - [REVIEW] Premium advanced stats are "very helpful" for pinpointing causes of anxiety, but the verdict is that most of what you need is free and premium is worth it mainly for PDF export. Therapy users value the PDF — [ChoosingTherapy](https://www.choosingtherapy.com/daylio-app-review/)
- **Clinical value of reports.** eMoods reviewers: "print the info in reports that you can share with your doctor"; "graphs your responses and allows you to grasp a full picture"; "There's enough content in the free version that you don't need to subscribe unless you wanna add your own symptom tracking points" — [App Store US](https://apps.apple.com/us/app/id1184456130). A How We Feel reviewer uses it to remember "how many depressive/anxious episodes I've had" for therapy and psychiatry visits — [App Store US](https://apps.apple.com/us/app/how-we-feel/id1562706384)
- **Complaints about presentation and paywall.**
  - A Moodnotes reviewer cites flaws in "displaying data effectively" and "the price of the subscription" — [App Store](https://apps.apple.com/app/id1019230398)
  - Reflectly reviewers resented stats locked after 7 stories, then paid ("at the price, you're better just using that money to see a therapist!") — [App Store UK](https://apps.apple.com/gb/app/id1241229134?l=en-gb)
  - A stoic. reviewer asked for a word cloud ([SNIPPET] [App Store](https://apps.apple.com/app/id1312926037))
- **Year in Pixels as an emotional artefact.** [REVIEW] Daylio's Year in Pixels "looks very nice" and gives a good yearly summary; the Stats section is where Daylio "shines" — [moodtrackers.org](https://moodtrackers.org/daylio-app-review/). [COMPETITOR] MoodKit likes "the grid paired with explanations" and criticises grid-only micro-apps for having little beyond the grid — [MoodKit blog](https://moodkit.co/blog/year-in-pixels-apps/). Pixels 2.4 made pixels, months and charts exportable as styled images — [App Store](https://apps.apple.com/app/id1668460700)

### Inferences
- "Insight" in user language means a relation between one thing they did and how the day went, confirmed by counts they can check. Pure filling stats (counts, fill rate) are not cited as valuable anywhere, which matches the owner's view.
- The features that stay valuable for years are the long-horizon ones: seasonality, month-over-month or period-vs-previous comparison, and "how many episodes since…". Day-to-day ones are not. For generic trackers (periods, pill, crying, exercise), "days since last X", "average gap between X" and "this month vs last month" fit this profile and need no mood anchor.
- Shareable and exportable outputs (PDF for a therapist, styled year image) are a recurring paid or valued item, distinct from on-screen stats.

### Gaps
- No direct Reddit threads could be read, so subreddit-specific nuance (r/Daylio, r/bulletjournal, r/QuantifiedSelf) is missing beyond the aggregator.
- No user evidence was found specifically about year-in-pixels apps' statistics (Pixels, Pixa) beyond store reviews with few ratings. Pixels iOS has only 45 ratings.

## Q5. Any public numbers about stats or insights driving premium conversion in these apps?

### Takeaway
I found no public number tying stats or insights to premium conversion for any of these apps. The available figures are third-party revenue estimates, and they disagree with each other.

### Cited Findings
- Daylio:
  - [PRIMARY] Daylio claims "20M+ users" and has existed since 2015 — [daylio.net](https://daylio.net/)
  - [EST] About $50K monthly revenue and 5K+ monthly downloads (Oct 2026) — [Adapty paywall library](https://adapty.io/paywall-library/daylio-journal/). This is contradicted by [EST] $100K a month and 40K installs a month (undated) — [Screensdesign](https://screensdesign.com/discover/apps/daylio-journal-daily-diary/)
- Pixels Android [EST]: under $10K a month, 55% ads / 45% IAP, 1.1M installs — [AppGoblin](https://appgoblin.info/apps/ar.teovogel.yip) ([SNIPPET])
- Pixa [EST]: under $1K a month and under 1K downloads a month (Oct 2026) — [Adapty](https://adapty.io/paywall-library/pixa/)
- DailyBean ships its free-vs-premium report table in a marketing blog post (Mar 2026). That implies the developer treats report depth as a selling point, but no conversion data is published — [DailyBean blog](https://dailybean.app/en/blog/dailybean-report-recap-trends-insights)

### Inferences
- In every app with a stated premium list, stats appear as a headline premium item: Daylio's "advanced stats", DailyBean's Icon Deep Dive, Sleep and Exercise, Bearable's Impacts, Moodnotes' "personal statistics", Reflectly's "advanced statistics", and MoodKit's "insight cards". That is strong revealed preference from developers, even without published conversion numbers.

### Gaps
- No founder interview, Indie Hackers post or developer blog with conversion attribution to stats was found for Daylio (Relaxio), Pixels (Teo Vogel), DailyBean (Bluesignum) or Bearable.
- The Daylio revenue estimates conflict by a factor of 2 and should be cited only as orders of magnitude.
