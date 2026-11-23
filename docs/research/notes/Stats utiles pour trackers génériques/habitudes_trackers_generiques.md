# Statistics in habit trackers and generic self-tracking apps: what they compute for user-defined scales and categories, what users value, and the free/premium split

Research date: 2026-11-23. Scope: Loop Habit Tracker, Streaks, HabitKit, Habitify, Way of Life, Daylio, Pixels, Track & Graph, Nomie, Exist, Bearable, Gyroscope, plus a few smaller habit apps that surfaced along the way. Everyday, Productive, Tally and the "Daily Log" type of apps could not be verified in this pass (see Gaps).

Source labels:
- **[P]** primary source read in full: official docs or help page, the app's own site, or open-source code read through the GitHub API.
- **[S]** only seen as a search-result summary or snippet; the page itself was not fetched. Treat with more caution.
- **[3P]** third-party review or article.
- **[U]** a user's own report or analysis.

Dates are given when the source has one. Anything I worked out myself (for example, arithmetic on a formula) is under Inferences, not Cited Findings.

---

## 1. Which stats each app shows (strength or score, completion rate, trends, heatmaps, per-weekday, correlations, year in review, goals)

### Takeaway
Pure habit trackers (Loop, Streaks, HabitKit, Habitify, Way of Life) all show the same core: current and best streak, completion rate over windows (week, 30 days, all time), a calendar or year heatmap, monthly bar charts and sometimes a weekday breakdown. Loop adds a decaying "habit strength" score. Mood and life trackers (Daylio, Exist, Bearable, Gyroscope) go further because their main variable is an ordered scale. They show average mood over time, mood by activity or tag, and correlations. Generic trackers (Track & Graph, Nomie) offer flexible graphs but few ready-made stats. Track & Graph's built-in "statistics" are just "average time between" and "time since last".

### Cited Findings

**Loop Habit Tracker (Android, free, open source)**
- Loop is GPLv3 and has no in-app purchases: "All features are available to all users." Its README features list the "Habit score", flexible schedules ("3 times per week or every other day") and CSV/SQLite export. Screenshots are labelled "Habit strength" and "Habit history and streaks". — [P] [Loop README](https://github.com/iSoron/uhabits)
- The README pitches the score as forgiving: "A few missed days after a long streak, however, will not completely destroy your progress, unlike many other don't-break-the-chain apps." — [P] [Loop README](https://github.com/iSoron/uhabits)
- Loop supports numerical habits with a target, typed AT_LEAST or AT_MOST. The score is computed against that target. — [P] [ScoreList.kt](https://github.com/iSoron/uhabits/blob/dev/uhabits-core/src/commonMain/kotlin/org/isoron/uhabits/core/models/ScoreList.kt)
- The formula is detailed under question 4.

**Streaks (iOS)**
- The App Store listing promises "current and best streak, and a whole range of other statistics". — [S] [Streaks, App Store](https://apps.apple.com/us/app/-/id963034692)
- A Sweet Setup review describes the per-habit view as showing best streak plus completion % for the last week and the last 30 days. The overview shows best streak, all-time completion %, total completions and history charts. — [S][3P] [The Sweet Setup, best habit tracking app](https://thesweetsetup.com/?p=8256)
- Streaks 6.1 added a stats widget with "horizontal bar charts for the days of the week that you complete the task" and a completion-success line chart over time. — [S][3P] [The Sweet Setup, Streaks 6.1](https://thesweetsetup.com/streaks-6-1-introduces-an-incredibly-useful-stats-widget-for-ios-14/)

**HabitKit (iOS and Android, GitHub-style year grid per habit, the closest habit-app analogue to Dian Dian)**
- Stats are described as "Completions, consistency rates, and streak records, charted month by month", plus "yearly stats with charts". Each habit has current and best streak chips and a full-year tile grid with an editable monthly calendar. A month view shows "a dozen habits side by side". Goals like 3× a week or 20× a month don't break on a missed day if the period total is met. Grids export as themed share cards. The site links a "Wrapped 2026". — [P] [habitkit.app](https://www.habitkit.app/)
- The free tier is capped at 4 habits. Pro is sold monthly, yearly or for life. — [P] [habitkit.app](https://www.habitkit.app/)

**Habitify**
- Mood is logged on a fixed 1–5 scale (Terrible / Bad / Okay / Good / Excellent). The overall mood is the mean of all logs, with the worked example "(3 × 1 + 1 × 4 + 2 × 5) / 6 = 3 (Okay mood)". — [S] [Habitify help, mood chart](https://intercom.help/habitify-app/en/articles/9651488-view-your-mood-chart) (the page returned 404 when fetched, so this rests on the snippet)
- The progress heatmap shades each cell by completion rate rather than done/not done. — [S] [Habitify help, progress screen](https://intercom.help/habitify-app/en/articles/14885639-progress-screen-the-good-habits-report-on-website-desktop)

**Way of Life (iOS)**
- A recent changelog adds a "Frequency Distribution" chart. — [S] [Way of Life, App Store](https://apps.apple.com/us/app/-/id393159800)
- Older listings (version 4.1.4, Dec 2024) describe a free version capped at 3 items and a $3.99 unlock. — [S] [Way of Life, App Store](https://apps.apple.com/app/id393159800)

**Daylio (mood + activities; ships a Year in Pixels)**
- Stats include a monthly mood line graph and an average-daily-mood bar chart. — [S] [Wikipedia, Daylio](https://en.wikipedia.org/wiki/Daylio)
- Daylio's site describes its Year in Pixels as "the full year … in one chart, every dot is a day in your life", exportable as an image. Some listings put it under premium. — [S] [daylio.net](https://daylio.net/)
- Per-mood stats are on the Stats screen ("tap the mood"). — [P] [Daylio FAQ, create and manage moods](https://daylio.net/faq/docs/daylio-faq/tutorials/create-and-manage-moods/)
- App Store reviewers say they value "which activities contribute to certain moods" and the weekly and monthly mood view. — [S][U] [Daylio, App Store](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)

**Pixels (Teo Vogel; a direct "year in pixels" competitor)**
- The listing names "Year in Pixels", "Reports and Statistics", habit tracking and productivity tracking. The in-app purchase is "Pixels+" at USD 4.99. — [S] [Pixels Journal, App Store](https://apps.apple.com/la/app/pixels-journal/id1668460700)
- AppBrain puts it at over 1 million Google Play installs. — [S] [AppBrain, Teo Vogel](https://www.appbrain.com/dev/Teo+Vogel/)

**Track & Graph (Android, free, GPLv3, on-device only)**
- Graph types are line graphs, bar charts, pie charts, time histograms, "statistics" and Lua scripts. — [P] [T&G docs, graphs index](https://github.com/SamAmco/track-and-graph/blob/master/docs/docs/tutorial/graphs/index.md)
- The docs say there are "only a couple of built in supported statistics: 'Average time between' and 'Last Tracked/Time since'", with optional label and value-range filters. Average time between is computed as `(last-first)/(size - 1)`. — [P] [T&G docs, statistics](https://github.com/SamAmco/track-and-graph/blob/master/docs/docs/tutorial/graphs/statistics.md)
- "Functions" are a visual node editor that merges trackers, filters by label or period and transforms values (example: multiply pounds by 0.453592), producing new data sources that work like trackers. — [P] [T&G docs, functions](https://github.com/SamAmco/track-and-graph/blob/master/docs/docs/tutorial/functions.md)
- Community Lua scripts include cumulative bar charts and line graphs, merged and periodic pie charts, "average in duration", "fraction", "total this period" and "last value above/below threshold". — [P] [T&G repo docs tree](https://github.com/SamAmco/track-and-graph/tree/master/docs/docs/lua/community)
- I found no correlation feature in the docs.

**Nomie (discontinued; open source)**
- Each tracker carries a "positivity" score, entered in a dedicated step of the tracker designer. Day views show a positivity bar. — [P] [nomie5 source, step-positivity.svelte](https://github.com/open-nomie/nomie5/blob/master/src/containers/tracker-designer/step-positivity.svelte)
- The author discontinued Nomie and released it as open source (MIT). Early-2023 shutdown; "Daily Nomie" is a fork. — [S] [AlternativeTo, Nomie](https://alternativeto.net/software/nomie/about)

**Exist (web + mobile, paid only)**
- Custom attributes get "averages, long-term trends, and of course … correlations". — [P] [Exist blog, manual tracking (15 Apr 2022)](https://exist.io/blog/manual-tracking/)
- Correlation display is covered under question 3.

**Bearable (health and symptom tracker)**
- Free features include "Trends reports for the past 30 days" and a "Comparison graph for the past 30 days (to find correlations & patterns)", calendar and timeline views. Premium adds the Impacts tab for correlation reports, a correlations grid across outcomes and 60/90/365-day ranges (full split under question 5). — [P] [Bearable, free vs premium](https://bearable.app/support/common-questions/bearable-free-vs-premium-features/)

**Gyroscope (health dashboard)**
- The "Health Score … sums everything up into a grade and simple sentence", with a "signal strength metric" showing how well the score tracks your health (2022 changelog). — [S] [Gyroscope changelog v57](https://about.gyrosco.pe/changelog/v57)
- The same changelog announced an Annual Report for 2022. — [S] [Gyroscope changelog v57](https://about.gyrosco.pe/changelog/v57)

**Smaller habit apps from the same searches**
- An Obsidian "Habits" plugin shows current and best streak, completion rates and "perfect days". Days a habit isn't due don't count against its rate. — [S] [Obsidian community plugin, Habits](https://community.obsidian.md/plugins/habits)
- Another Obsidian tracker shows the rate with its denominator, such as "75% (15/20)". — [S] [Obsidian plugin, tracker-habits-metrics](https://community.obsidian.md/plugins/tracker-habits-metrics)

### Inferences
- The stats Dian Dian has today (days filled, streaks, % of year, legend distribution, monthly fill rate, weekday distribution) are almost exactly what pure habit trackers ship: Streaks, HabitKit, Way of Life. Users do not cite those stats as a reason to pay (see questions 5 and 6).
- What mood and life apps add on top is all conditional on knowing an order or numeric value per option: an average curve, a by-weekday mean, mood by tag, correlations. Daylio is the clearest analogue: a year-in-pixels grid plus ordered moods plus tags. Its premium value sits in those value-based stats, not in fill counts.
- Track & Graph shows the opposite extreme: maximal flexibility, almost no stats out of the box. That suits power users only, which is a warning against making Dian Dian users build their own stats.

### Gaps
- Everyday (Everyday.app), Productive, Tally ("The Anything Tracker") and "Daily Log"-type apps were not covered: there was no time to fetch their listings. Their stats and paywalls are unverified.
- I could not confirm whether Streaks, HabitKit or Way of Life show a per-weekday breakdown in the per-habit view (only the Streaks widget is sourced).
- HabitKit's "Wrapped 2026" year-in-review is only a link on its site; its contents are unknown.
- Daylio's official stats documentation (how average mood is computed, which charts are premium today) was not fetched. Only Wikipedia, App Store snippets and a user analysis cover it.

---

## 2. How generic trackers let users define scales vs categories (numeric value per option, ordinal toggle, good/bad direction, colour meaning); does any app ask whether options are ordered?

### Takeaway
No app found asks "do these options form an ordered scale?" as such. Each one decides order through the data type chosen at creation, and those types fall into four patterns. Some force a fixed ordinal scale: Daylio's 5 mood groups, Habitify's 1–5 mood, Exist's 1–9 "scale" type. Some separate yes/no tags from scales by type (Exist). Some give every entry a raw number with free-text labels (Track & Graph). Some attach a good/bad weight to each tracker or value (Nomie's "positivity"; Loop's AT_LEAST / AT_MOST). Daylio is the most instructive for Dian Dian: users may create unlimited custom moods, but each must sit under one of 5 ordered groups, so averages still work.

### Cited Findings
- **Daylio, forced ordinal with free labels.** It starts with "five default moods", which users can rename and recolour. Users can create unlimited custom moods, but they are "saved under the 5 default mood categories". Custom moods "can be reordered or moved to another category". Deleting a custom mood replaces its entries with the default mood of that category. Archiving hides it from new entries but "it will stay in your past entries". — [P] [Daylio FAQ, create and manage moods](https://daylio.net/faq/docs/daylio-faq/tutorials/create-and-manage-moods/)
- **Daylio's numeric mapping.** A user who exported 1,000+ days mapped awful = 1 to rad = 5 and got a mean of 3.99 and a median of 4. — [U] [Towards Data Science, 1000 days of mood](https://towardsdatascience.com/ive-tracked-my-mood-for-over-1000-days-a-data-analysis-5b0bda76cbf7)
- **Exist, the type is chosen at creation.** Custom attribute types are tags ("restricted to a yes/no value"), quantity ("2 coffees"), duration ("02:15 time in meetings"), a 1–9 scale ("4/9 stress level", suggested for "energy, stress, or anxiety"), decimal, percentage and time of day. Template attributes get "better analysis" than custom ones because custom analysis "has to be more generic". — [P] [Exist blog, manual tracking (15 Apr 2022)](https://exist.io/blog/manual-tracking/)
- **Exist, scale direction.** On a scale, 9 is the maximum of the attribute. — [S] [Exist, manual tracking help](https://exist.io/page/help-manual-tracking/)
- **Habitify, fixed 1–5 labelled mood.** Terrible / Bad / Okay / Good / Excellent are averaged as numbers. — [S] [Habitify help, mood chart](https://intercom.help/habitify-app/en/articles/9651488-view-your-mood-chart)
- **Track & Graph, number + free label.**
  - Each data point has a timestamp, a numeric value, an optional label and a note. Durations are "stored as a number (… total number of seconds)". — [P] [T&G tutorial, tracking](https://samamco.github.io/track-and-graph/tutorial/tracking/)
  - In "Label only" mode, a long press tracks the label "with a value of 1". Labels are for categorising, such as "breakfast/lunch/dinner". — [P] [T&G tutorial, tracking](https://samamco.github.io/track-and-graph/tutorial/tracking/)
  - So order is whatever number the user types. There is no per-option value table: the value is entered or defaulted per tracker.
- **Nomie, good/bad weight per tracker or per value.**
  - In the source code, a tracker has either a fixed `score` or a `score_calc` list of conditions. A condition reads "if value / hour / day-of-month is gt / lt / eq / gte / lte v, then score sc". The first condition that matches gives the score. — [P] [nomie5, score-tracker.js](https://github.com/open-nomie/nomie5/blob/master/src/modules/scoring/score-tracker.js)
  - The default condition is "if value > 1 → +3". — [P] [nomie5, positivity-condition.js](https://github.com/open-nomie/nomie5/blob/master/src/modules/tracker/positivity-condition.js)
  - The tracker-designer step is labelled "positivity". — [P] [nomie5, step-positivity.svelte](https://github.com/open-nomie/nomie5/blob/master/src/containers/tracker-designer/step-positivity.svelte)
- **Loop, direction for numeric habits.** Numerical habits are AT_LEAST or AT_MOST a target. For AT_MOST, completion is `1 - (sum - target)/target`, clamped to 0–1. A skipped day ("SKIP") is excluded from the window. — [P] [ScoreList.kt](https://github.com/iSoron/uhabits/blob/dev/uhabits-core/src/commonMain/kotlin/org/isoron/uhabits/core/models/ScoreList.kt)
- **Bearable, custom scales are premium.** Premium includes "Custom Health Measurements: for custom scales and metrics". — [P] [Bearable, free vs premium](https://bearable.app/support/common-questions/bearable-free-vs-premium-features/)

### Inferences
- Dian Dian's proposed switch ("these colours form a scale, in list order") has no exact precedent I could find. The nearest patterns:
  - Exist: pick "scale" vs "tag" at creation.
  - Daylio: free labels but forced into ordered slots.
  - Nomie: a separate "positivity" step in the tracker designer.
- Reusing the list order Dian Dian already has, with the top option as "best", is simpler than any of these. It resembles Daylio, where the group order is fixed and labels are free.
- Two details from competitors matter for a Dian Dian scale:
  1. **Direction.** Loop's AT_MOST and Exist's "9 is the maximum" both state which end is good. Dian Dian's templates put "best" first (Great, 8 h+, 1 h+, Done), so the switch should say "first = best" or offer an invert option. Otherwise "average" for a pain-style legend reads upside down.
  2. **Equal spacing.** Daylio and Habitify score ordinal labels 1..N and average them. That is the de-facto industry practice even though it treats unequal intervals as equal. Sleep ranges (8 h+/7–8/6–7/5–6/<5) are roughly equally spaced. Reading (1 h+/30 min/a few pages/none) is not.
- "None", "Rest" or "Sick"-style options are a known trap. Loop solves it with an explicit SKIP that leaves the score unchanged, and Track & Graph with label filters. Dian Dian's Exercise template ("Rest", "Sick") would need an "exclude from average" or "not part of the scale" flag per option, or those days distort means.
- Colour is not used as meaning by any app studied. Meaning comes from order, type or score. Daylio lets users recolour moods freely.

### Gaps
- I found no app that literally asks "are these options ordered?" and no published UX research on how users answer such a question.
- I could not verify whether Daylio's average mood uses 1–5 equal spacing officially (only a user's own mapping is sourced).
- Nomie 6's trackable types (Tally, Value, Picker, Range…) were seen only in a Notion-guide snippet ([S] [Nomie 6 custom trackable guide](https://spectacular-collard-13a.notion.site/Creating-a-custom-Trackable-e8acae60b37a456385074e462ba18809)); I could not read whether a picker option carries a value.

---

## 3. Correlation / "what affects what" features (Exist, Bearable, Nomie, Track & Graph): computation, minimum data, phrasing, complaints

### Takeaway
Only Exist and Bearable (and Daylio, in a lighter mood-by-activity form) ship automatic correlations. Neither publishes its statistical method. Both show a strength cue plus some reliability cue: Exist uses confidence stars, Bearable a with/without comparison and data thresholds. Both warn heavily about causation, confounders and obvious results. Bearable needs at least 3 days with and 3 days without a factor and recommends 7/7. Exist says "a few weeks". Track & Graph and Nomie have no automatic correlation. The main complaints are that results are obvious, that there is not enough data, and that the analysis is Pearson-only.

### Cited Findings

**Exist**
- "Correlations describe a relationship between two attributes" without proving cause: either attribute could drive the other, a third variable could affect both, or it could be coincidence. — [P] [Exist KB, what are correlations](https://kb.exist.io/article/37-what-are-correlations)
- Pairs are described as ones that "go up or down on the same days". Strength reflects how consistently they move together: "almost always higher at the same time" is very strong. — [P] [Exist KB](https://kb.exist.io/article/37-what-are-correlations)
- Confidence is shown as stars out of 5. A strong correlation can have low confidence when there is little data. More data can weaken a correlation or keep it stable with higher confidence. Attribute order doesn't matter. — [P] [Exist KB](https://kb.exist.io/article/37-what-are-correlations)
- Correlations for custom attributes come "once you've tracked your new attributes for a few weeks". — [S] [Exist, manual tracking help](https://exist.io/page/help-manual-tracking/)
- Exist also finds correlations "based on when you don't use a tag" (2017). — [S] [Exist blog, custom tracking (2 Aug 2017)](https://exist.io/blog/custom-tracking/)
- Its example questions are whether coffee relates to productivity, mood or activity, and whether napping later affects the following night's sleep, which implies next-day lags. — [P] [Exist blog, manual tracking (2022)](https://exist.io/blog/manual-tracking/)

**Bearable**
- The Factor Effect report "shows you the correlation between a Factor and your Health Outcomes such as Sleep, Symptoms, and Mood". It covers "your average mood on the same day as the Factor was entered and up to … the seven-day window after". — [P] [Bearable, Factor Effect report](https://bearable.app/support/howto/the-factor-effect-report/)
- Bearable "needs three entries with a factor and three entries without before it will appear". A magnifier shows "the effect with and without the Factor". Factors sort by "Best" or "Worst", as improving or worsening. — [P] [Bearable, Factor Effect report](https://bearable.app/support/howto/the-factor-effect-report/)
- It advises "at least 7 days with, and 7 days without, a single Factor". Without time periods, "your correlations the next day may be more reliable". — [P] [Bearable, my correlations are wrong](https://bearable.app/support/troubleshooting/my-correlations-are-wrong-dont-make-sense/)
- Its listed failure modes:
  - Reverse relationships, such as pain medication taken on high-pain days.
  - Confounders, such as caffeine after 3 pm correlating with better sleep, likely because those were more active days.
  - Outliers, flagged with "Significant Events" such as illness.
- Useful correlations can be saved to a "Discoveries" tab. — [P] [Bearable, my correlations are wrong](https://bearable.app/support/troubleshooting/my-correlations-are-wrong-dont-make-sense/)
- Bearable says "Insights … are not medical advice". — [S] [Bearable support](https://bearable.app/?p=6372)

**Daylio**
- The Daylio FAQ cautions that a trend shown with low confidence should not be taken at face value. — [S] [Daylio FAQ](https://daylio.net/faq/?p=36)
- Reviewers credit Daylio with "showing correlations between things that affect mental well-being". — [S][U] [Daylio, App Store](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)

**Track & Graph / Nomie**
- Track & Graph has no correlation stat; its built-in statistics are only "average time between" and "time since last". — [P] [T&G docs, statistics](https://github.com/SamAmco/track-and-graph/blob/master/docs/docs/tutorial/graphs/statistics.md)
- Nomie's scoring is a per-entry positivity weight, not a correlation. — [P] [nomie5, score-tracker.js](https://github.com/open-nomie/nomie5/blob/master/src/modules/scoring/score-tracker.js)

**Complaints and limits**
- An r/QuantifiedSelf poster wanted something beyond basic correlation, noting most such apps "just use Pearson correlation". — [S][U] [r/QuantifiedSelf thread (Sep 2024)](https://libreddit.winscloud.net/r/QuantifiedSelf/comments/1fbz39o/quantified_selftracking_tools)
- A user of OptimizeMe, an older correlation app, often saw no correlations because there was not enough data (2014, **old**). — [S][U] [TechCrunch, OptimizeMe (2014)](https://techcrunch.com/2014/04/28/ios-app-optimizeme-encourages-you-to-make-the-most-of-your-day)
- A JMIR Mental Health interview study of mood-app users (2021) found tracking aided self-awareness. Its main gap was the lack of app-facilitated suggestions on how to interpret one's own data. — [S] [JMIR Mental Health 2021;8:e29368](https://mental.jmir.org/2021/8/e29368/PDF)

### Inferences
- For a ~200-account app where most trackers have a few weeks of data, Bearable's 3-with / 3-without minimum is too low to be meaningful. Its recommended 7/7 is the floor of credibility. With daily ordinal data a single year gives at most 365 pairs, often far fewer because of missing days.
- A Dian Dian "links" feature would likely need:
  - a minimum of overlapping filled days (e.g. ≥ 14–21 pairs);
  - a with/without or by-level comparison, such as "on days Reading = 1 h+, Mood averaged Good; on days Reading = None, Mood averaged Okay";
  - no r values;
  - a confidence cue;
  - a "not proof of cause" line.

  This mirrors Bearable's phrasing and Exist's stars without inventing a method.
- The "obvious correlation" problem (exercise lifts mood) is not necessarily bad. Users seem to like confirmation as long as it is phrased as their own data. The risk is spurious links from small samples, which a minimum-data gate handles.
- For unordered categories (Run/Gym; Happy/Calm/Stressed), "mean of the other tracker on days of category X" is the natural analogue. It needs the other tracker to be a scale. Category × category pairs can only produce co-occurrence ("Stressed days were mostly Gym days").

### Gaps
- Neither Exist nor Bearable publishes its correlation method (Pearson, Spearman, p-value or effect-size threshold). The fetched help pages don't state it.
- Exist's exact UI phrasing ("You're happier on days when…") and its lag handling (the KB article "Will Exist find correlations across multiple days?") could not be fetched (404).
- A "No surprises there" quote about obvious tag–mood links appeared in a search summary, but I could not pin it to a specific URL, so it is excluded.
- No r/habittracker or r/getdisciplined threads on correlation usefulness were found.

---

## 4. Loop Habit Tracker's "habit strength" formula and similar scores: how they work, whether users find them meaningful

### Takeaway
Loop's score is an exponential moving average of the fraction of the target met over a rolling window. The decay is tuned so a perfect daily habit reaches about 80% in a month and 99% in three. It is the best-documented "strength" score and is explicitly designed to forgive short breaks. Other "scores" are simpler or opaque: Habitify's mean mood, Nomie's per-entry positivity points, Gyroscope's Health Score grade. I found no direct user evidence (Reddit or reviews) on whether people find Loop's score meaningful.

### Cited Findings
- **Core update (verbatim):** `multiplier = 0.5.pow(sqrt(frequency) / 13.0)`; `score = previousScore * multiplier + checkmarkValue * (1 - multiplier)`. Frequency is "the number of repetitions divided by the length of the interval", for example 3 in 8 days = 0.375. — [P] [Score.kt](https://github.com/iSoron/uhabits/blob/dev/uhabits-core/src/commonMain/kotlin/org/isoron/uhabits/core/models/Score.kt)
- **What feeds it:** the input is not the raw checkmark. It is `percentageCompleted = min(1.0, rollingSum / numerator)` over a sliding window of `denominator` days.
  - For non-daily boolean habits, numerator and denominator are doubled "to smooth out irregular repetition schedules (for example, weekly habits performed on different days of the week)".
  - SKIP days are not added to the window.
  - Numerical habits use the fraction of the target, inverted for AT_MOST. — [P] [ScoreList.kt](https://github.com/iSoron/uhabits/blob/dev/uhabits-core/src/commonMain/kotlin/org/isoron/uhabits/core/models/ScoreList.kt)
- **Official explanation (FAQ, 28 Dec 2020):** "exponential smoothing", where recent repetitions weigh more but "every repetition counts, even old ones". Low scores rise quickly, and gains shrink as the score rises. A long high score recovers easily after a short break, but frequent breaks hurt. Skips "leave the score unchanged and don't break the streak". — [P] [Loop FAQ, GitHub Discussion #689](https://github.com/iSoron/uhabits/discussions/689)
- **Timescales (same FAQ):**
  - A perfect daily habit reaches 80% after 1 month, 96% after 2 and 99% after 3.
  - An every-other-day habit needs about 2 months to reach 80%.
  - A weekly habit needs about 7 months.

  The discussion had 0 comments when read. — [P] [Loop FAQ](https://github.com/iSoron/uhabits/discussions/689)
- **Habitify mood score:** plain mean of 1–5 labels mapped to a named level ("= 3 (Okay mood)"). — [S] [Habitify help](https://intercom.help/habitify-app/en/articles/9651488-view-your-mood-chart)
- **Nomie positivity:** a fixed or condition-based integer per entry (e.g. +3 if value > 1). — [P] [nomie5 source](https://github.com/open-nomie/nomie5/blob/master/src/modules/scoring/score-tracker.js)
- **Gyroscope Health Score:** a grade plus a simple sentence, with a "signal strength" metric for how well it tracks your health (2022). — [S] [Gyroscope changelog v57](https://about.gyrosco.pe/changelog/v57)

### Inferences
- For a daily habit (frequency 1) the multiplier is 0.5^(1/13), so the score's **half-life is 13 days**. Starting from 0 with every day done gives 1 − 0.5^(t/13): 79.8% at 30 days, 95.9% at 60, 99.2% at 90, matching the FAQ figures. This is my arithmetic, not a source statement.
- Adapting Loop's idea to a Dian Dian scale tracker would mean taking each day's position on the scale (best = 1, worst = 0) as `checkmarkValue`. The result is a smoothed "recent level" curve: a 13-day half-life rolling average of the scale. That is more honest than a "strength %" for mood or sleep, which are not habits to strengthen. For Exercise or Reading templates a strength-like score is plausible.
- Unfilled days need a rule. Loop treats them as 0 (a miss) unless SKIP. For mood or sleep, an unfilled day is missing data, not a bad day, so it should be skipped. Treating it as 0 would conflate "didn't log" with "bad".

### Gaps
- I found no Reddit or review threads in which users say whether Loop's score is meaningful or confusing; the search returned only official material. GitHub issue #1647 surfaced but was not read.
- I found no user research on composite or opaque scores (Gyroscope grade, Nomie positivity) and their perceived usefulness.

---

## 5. Free vs premium split for stats, and free teaser patterns

### Takeaway
There are three patterns:
1. **Everything free.** Loop and Track & Graph: open source, no IAP.
2. **Free basic stats, cap on quantity.** HabitKit (4 habits), Way of Life (3 items, older listing), Progressio (3 habits). The paywall is the number of trackers, not the stats.
3. **Free short-window or basic stats, deep analysis paid.**
   - Bearable: 30-day trends and comparison graph free; correlations ("Impacts"), longer ranges and custom scales paid.
   - Daylio: advanced stats and Year in Pixels paid in some listings.
   - Gyroscope: free shows only today; history and reports paid.
   - Exist: paid only after a 30-day trial.

The clearest teaser patterns are "a free 30-day window, pay for 60/90/365" (Bearable) and a time-boxed "analytics trial" (Progressio, 24 hours).

### Cited Findings

| App | Free | Paid | Price seen |
|---|---|---|---|
| Loop | Everything ("All features are available to all users", no IAP) | — | — [P] [README](https://github.com/iSoron/uhabits) |
| Track & Graph | Everything, open source, on-device | — | — [P] [README](https://github.com/SamAmco/track-and-graph) |
| HabitKit | Up to 4 habits; listing says free includes streaks, statistics, notes, reminders | Unlimited habits, widgets, import/export, archived restore, 3 reminders/habit | Monthly / yearly / lifetime, not shown — [P] [habitkit.app](https://www.habitkit.app/); [S] [App Store](https://apps.apple.com/bb/app/habitkit/id6451414190). A third party lists "detailed statistics" as premium, contradicting the developer — [S][3P] [productivity-apps.com](https://productivity-apps.com/apps/habitkit-habit-tracker) |
| Habitify | Free plan: "Check in daily, build your streaks, and keep basic notes" | Plus (annual only) and Pro; Pro adds image notes, Pomodoro and stopwatch, calendar / Health / Screen Time sync. No analytics row in the plan table | Plans article dated 3 Aug 2026 — [P] [Habitify plans](https://intercom.help/habitify-app/en/articles/6113487-explore-habitify-plans-free-plus-and-pro); tiers introduced 6 Apr 2026 — [S] [Habitify changelog](https://feedback.habitify.me/changelog/new-tiered-pricing); US listing shows $9.99/mo and lifetime $39.99–$89.99 — [S] [App Store](https://apps.apple.com/us/app/habitify-routine-habit-tracker/id1111447047) |
| Way of Life | Free with 3-item cap (Dec 2024 listing) | Unlock / Premium | $3.99 unlock (older); Premium IAP tiers $4.99 / $9.99 / $29.99 — [S] [App Store](https://apps.apple.com/app/id393159800) |
| Daylio | Basic stats | "Advanced stats", Year in Pixels (some listings), backups, PIN lock. Reviewers name the monthly mood overview and mood stability as premium | $4.99/mo, $35.99/yr, $59.99 lifetime (prices vary by region) — [S] [Wikipedia](https://en.wikipedia.org/wiki/Daylio); [S][3P] [Headway review](https://makeheadway.com/blog/daylio-review/) |
| Bearable | Unlimited tracking; "Trends reports for the past 30 days"; "Comparison graph for the past 30 days (to find correlations & patterns)"; calendar, timeline, widgets, CSV export | "Impacts tab" (correlation reports); "Correlations grid"; "60, 90, and 365 days" ranges; unlimited Goals and Experiments; "Custom Health Measurements: for custom scales and metrics"; premium also needed to scroll back through all periods on the correlation graph | Feature split: [P] [Bearable free vs premium](https://bearable.app/support/common-questions/bearable-free-vs-premium-features/), [P] [Factor Effect report](https://bearable.app/support/howto/the-factor-effect-report/) (the official page lists no prices). $34.99/yr or $6.99/mo per a third-party review — [S][3P] [ChoosingTherapy](https://www.choosingtherapy.com/bearable-app-review/) |
| Exist | 30-day free trial only | Everything | US$6.99/mo — [S] [Exist signup](https://jenny.exist.io/signup) |
| Gyroscope | Free users "only see today's data" | "Upgrade to Pro to start storing all your history and see all your reports"; AI coaching | US $12.99/mo or $79.99/yr — [S] [App Store](https://apps.apple.com/us/app/gyroscope/id1104085053) |
| Pixels | Free | "Pixels+" | USD 4.99 — [S] [App Store](https://apps.apple.com/la/app/pixels-journal/id1668460700) |
| Progressio | 3 habits | Analytics; "24-Hour Analytics Trial" | — [S] [App Store](https://apps.apple.com/app/id6740454461) |
| Habit Tracker: Daily Routine | Basic | "Advanced habit analytics" and "yearly progress" | $17.99/yr, $2.99/mo — [S] [App Store](https://apps.apple.com/us/app/habit-tracker-daily-routine/id6476888812) |

### Inferences
- Bearable's split maps cleanly onto Dian Dian:
  - **Free:** the stat on a short window (last 30 days, or the current month).
  - **Premium:** the same stat over the full year or across years, plus the "what affects what" view.
  - The free comparison graph is explicitly pitched as a way to "find correlations & patterns" by eye. It works as a do-it-yourself teaser for the automatic Impacts report.
- Gating history (Gyroscope shows only today for free) is the harshest pattern. It suits a data-hoarding health app, not a year-in-pixels app whose free value is the year grid itself.
- Several habit apps don't gate stats at all and gate the number of trackers instead (HabitKit 4, Way of Life 3, Progressio 3). That matches Dian Dian's current free limit of 3. It is consistent with the view that fill-count stats alone are not what people pay for.
- A "one real insight revealed free" teaser (already in Dian Dian's popup spec) has a precedent only in spirit. Bearable's free 30-day comparison graph and Progressio's 24-hour analytics trial are the closest. I found no app that shows one locked correlation in full for free.

### Gaps
- Streaks' business model (paid upfront, believed to have no subscription) is not verified this session.
- The current Daylio premium list (2026) is not from an official page. Exact Way of Life premium features are unknown.
- Everyday, Productive and Tally paywalls are not covered.

---

## 6. What user reviews and discussions say is genuinely useful vs noise

### Takeaway
Direct user evidence is thin and mostly from store reviews and blog analyses, not Reddit; my Reddit searches returned no on-topic threads. What surfaces:
- People value seeing which activities go with good or bad moods, and their weekly or monthly mood shape.
- Free stats are "enough" for people who don't want deep analysis.
- Habit-count caps frustrate free users more than missing stats do.
- Correlations draw two complaints: they need lots of data, and the analysis is "just Pearson".

Research on mood apps says users want help interpreting their data, not more charts.

### Cited Findings
- **Daylio reviewers** value "showing correlations between things that affect mental well-being". They like seeing "what activities contribute to certain moods, and how their weekly and monthly mood looks". — [S][U] [Daylio, App Store](https://apps.apple.com/us/app/daylio-journal-mood-tracker/id1194023242)
- **Bearable** review: the free version is "really great for those who do not need in-depth statistics and insights". An App Store reviewer says "you can use almost all features for free". — [S][3P] [ChoosingTherapy, Bearable review](https://www.choosingtherapy.com/bearable-app-review/); [S][U] [Bearable, App Store](https://apps.apple.com/app/bearable/id1482581097)
- **HabitKit** users praise its "robust statistics and insights". Some complain that with the free version "you really are limited on tracking every habit you want". — [S][U] [Chrome-stats, HabitKit Android reviews](https://chrome-stats.com/d/com.roehl.habitkit)
- **Streaks 6.1:** The Sweet Setup called the stats widget, with day-of-week bars and a success line, "incredibly useful". — [S][3P] [The Sweet Setup](https://thesweetsetup.com/streaks-6-1-introduces-an-incredibly-useful-stats-widget-for-ios-14/)
- **Self-analysis of 1,000+ days of Daylio** (1–5 mapping): mean 3.99, median 4. The value came from the user's own export-and-analyse work, not in-app stats. — [U] [Towards Data Science](https://towardsdatascience.com/ive-tracked-my-mood-for-over-1000-days-a-data-analysis-5b0bda76cbf7)
- **r/QuantifiedSelf:** a poster asked for analysis beyond basic Pearson correlation, which "most similar apps just use" (Sep 2024). — [S][U] [r/QuantifiedSelf](https://libreddit.winscloud.net/r/QuantifiedSelf/comments/1fbz39o/quantified_selftracking_tools)
- **Not enough data** to see correlations (OptimizeMe user, 2014, **old**). — [S][U] [TechCrunch](https://techcrunch.com/2014/04/28/ios-app-optimizeme-encourages-you-to-make-the-most-of-your-day)
- **Research:** mood-app users reported more self-awareness. The gap they cited was the lack of app-facilitated recommendations on interpreting their data (JMIR Mental Health, 2021). — [S] [JMIR Mental Health 2021](https://mental.jmir.org/2021/8/e29368/PDF)
- **Design cues from habit tools:**
  - Exclude not-due days from completion rates.
  - Show the denominator ("75% (15/20)") so a high rate on few days is visible.
  - Show a short window (7-day rate) next to the lifetime rate. — [S] [Obsidian Habits plugin](https://community.obsidian.md/plugins/habits); [S] [Obsidian tracker-habits-metrics](https://community.obsidian.md/plugins/tracker-habits-metrics); [S] [Toolv habit tracker](https://toolv.com/en/app/habit-tracker)

### Inferences
- The signals that recur all involve values or links: activities vs mood, weekly and monthly mood shape, day-of-week patterns of success. Fill counts alone rarely get praised. That supports the premise that Dian Dian's current premium stats (fill-based) are weak and that an ordered-scale switch is where the value lies.
- "Interpretation in plain words" is the recurring unmet need: the JMIR finding, Gyroscope's "grade and simple sentence", Bearable's "improving/worsening". One-sentence findings ("Your mood was best on Saturdays", "Sleep 7–8 h days were mostly Good mood days") probably beat charts for a small, non-technical audience.
- Noise risks to avoid:
  - Correlations on too few days.
  - Obvious pairs presented as discoveries.
  - Percentages without denominators.
  - Treating unfilled days as bad days.

### Gaps
- No usable Reddit threads (r/habittracker, r/getdisciplined, r/productivity, r/Daylio) ranking stats as useful vs noise were found. Search results were dominated by vendor pages, so the "useful vs noise" picture rests on store reviews, one blog analysis and one academic study.
- No Indie Hackers or developer interviews on which stats drive conversion were found.
- The App Store review quotes come from search summaries, not from reading full review pages. Review counts and dates are unknown.
