# What makes self-tracking statistics and insights useful, and what to avoid

Research date: 2026-11-23. Scope: personal informatics (PI) models and what questions people ask of their data; correlation insights on small, sparse, self-reported data (sample sizes, false discoveries, guards, phrasing); visualisations for calendar and categorical daily data; negative effects (rumination, streaks, judgemental framing) and tone; reflection features ("on this day", recaps).

Evidence labels used below:
- **[empirical]**: peer-reviewed study with measured outcomes (sample size given)
- **[qualitative]**: peer-reviewed interview, diary or field study, small N, no measured outcome
- **[conceptual]**: peer-reviewed argument or review, no new data
- **[practitioner]**: an app maker's own help pages or blog (Exist, Bearable, Daylio, Duolingo, Facebook)
- **[press/anecdote]**: press coverage, personal essay, secondary summary
- **[abstract-level]**: I only saw the abstract or a search snippet, not the full text, so details are unconfirmed

Numbers marked "computed" in the Inferences come from standard formulas I ran myself. They are not from a source.

---

## 1. PI models and findings: what questions do people actually want their data to answer?

### Takeaway
The questions people ask of their data fall into six types: **Status, History, Goals, Discrepancies, Context, Factors** (Li et al. 2011). When people are still trying to understand themselves (the "Discovery" phase), they mostly ask History, Context and Factors questions: "how has this changed?", "what else was happening then?" and "what goes with what?". Counts of logging activity answer none of these. Newcomers and curiosity-driven trackers drop out when the data gives no payoff or the views are too abstract. The insights people actually report from their own data are mostly trends, comparisons (often between time periods), correlations, summaries, distributions and outliers. Plain-language "pattern feeds" helped people notice links across data streams that they had not noticed alone.

### Cited Findings

**Li, Dey & Forlizzi: the stage model (CHI 2010) and the reflection questions (UbiComp 2011)**
- Li et al. 2010 has five stages: preparation, collection, integration (preparing data for reflection), reflection, and action. Barriers in one stage carry over into the next. **[conceptual/empirical]**. Stage definitions as restated by Epstein et al. 2015: [Epstein 2015 PDF](https://my.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Epstein2015.pdf). A 2017 review of 32 mood apps used the same stages and found that the apps support collection and reflection but rarely preparation or action: [Caldeira et al. 2017](https://escholarship.org/uc/item/57z7f4c2).
- Li et al. 2011 interviewed **15 people** who had used PI tools for at least a month, with observation of their tools. **11 of 15** tracked in order to reflect, and the analysis focuses on those 11 **[qualitative]**. It found six types of question: Status, History, Goals, Discrepancies, Context, Factors. [Li et al. 2011 PDF](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf); [publication page](https://ianli.owlstown.net/publications/16-understanding-my-data-myself-supporting-self-reflection-with-ubicomp-technologies)
- **Maintenance phase:** people "mostly ask Status and Discrepancy questions". They already know their goal and which factors matter, and they track only one or a few things. **Discovery phase:** "mostly asking History, Goals, Context, and Factors questions". People move back to Discovery when they cannot reach their goals or have to redefine them. [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)
- **History needs time.** One participant "could not make any significant conclusions regarding her spending trends because she had only been collecting data for a month". Another's sleep software only listed values "on a spreadsheet-like interface", which did not help her see trends. [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)
- **Context** ("what else was happening at the same time?") relied on notes, journals or memory, and "one's memory of events can be unreliable and degrades over time". One participant stopped logging diligently: "I didn't want to become, like, OCD (obsessive-compulsive) about it." [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)
- **Factors** ("what affects this over time?"): no tool let people look at several data types together, and "exploring multiple types of data was confusing and understanding the influences of the factors on their behavior was difficult." [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)
- **Design implications (authors' opinion):** repeating a status that has not changed "may become bothersome", so tools should "reserve alerts for when special circumstances arise". "Telling people that they are doing well can become annoying. Instead, the Ubicomp tool should be there to notify the user if anything unusual happens." The authors suggest automated statements of the form "when you drink coffee at 6pm, you have a hard time sleeping". In Discovery, "user involvement is critical" and "automation can diminish users' engagement with their data". [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)

**Epstein et al.: lived informatics (UbiComp 2015) and the 2020 literature map**
- Surveys of **105, 99 and 83** past and present trackers (physical activity, finances, location) plus **22 interviews** **[empirical survey + qualitative]**. People start tracking for behaviour change, for instrumental reasons (wanting a record), or out of **curiosity**. "Curiosity-driven trackers are motivated by how interesting they find the data they are tracking." Behaviour-change trackers "are bothered by inaccurate logs". [Epstein et al. 2015](https://my.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Epstein2015.pdf)
- People lapse in four ways: forgetting to track, difficulty keeping it up, intentionally skipping entries, and suspending tracking. Open design question: how to resume after a lapse, "including how to use historical data collected before, or even during, the lapse". For some, "the record's support for accountability is more valuable than insights derived." [Epstein et al. 2015](https://my.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Epstein2015.pdf)
- Follow-up on abandonment (CHI 2016): **193 surveyed, 12 interviewed**. It identifies six reasons people stop tracking. **[abstract-level]** [Epstein dissertation record](https://digital.lib.washington.edu/researchworks/items/e42bf659-7059-4e33-8d6e-e72ca7127617/full)
- Mapping review of **523 PI publications**. The field has focused on barriers to collection and reflection, and "some find that tracking reinforces negative behaviors". **55 publications** mention adverse consequences of tracking. **[conceptual review]** [Epstein et al. 2020, IMWUT](https://par.nsf.gov/servlets/purl/10252696)

**Choe et al.: what Quantified Selfers do and find**
- Analysis of **52 Quantified Self meetup talk videos** **[qualitative]**. Pitfalls: "tracking too many things, not tracking triggers and context, and insufficient scientific rigor". Barriers include difficulty integrating and interpreting data. [Choe et al. CHI 2014](https://pubweb.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Choe2014.pdf)
- From **30 QS presentations**, eight types of insight: **detail, self-reflection, trend, comparison, correlation, data summary, distribution, outlier**. [Choe, Lee & schraefel, IEEE CG&A 2015](https://www.microsoft.com/en-us/research/publication/characterizing-visualization-insights-quantified-selfers-personal-data-presentations/)
- A follow-up (Visualized Self, PervasiveHealth 2017) splits **comparison** into "by factor, by time segmentation, against external data, by instance" and **self-reflection** into "external context, contradiction, prediction, confirmation". It defines an insight as "an individual observation about the data accompanied by visual evidence". **[abstract-level; I could not access the full PDF, so per-type counts are missing]** [Choe et al. 2017](https://terpconnect.umd.edu/~choe/download/PervasiveHealth-2017-Choe-VisualizedSelf.pdf)

**Newcomers and casual trackers**
- Rapp & Cena 2016 (IJHCS): **14 participants with no prior self-tracking experience**, diary study **[qualitative]**. They found collecting data burdensome with no clear payoff, and their interest faded despite initial curiosity. Obstacles were apps giving "few suggestions" on how to use the data and "overly abstract visualizations". The authors derive seven design strategies. **[abstract-level]** [Rapp & Cena 2016](https://iris.unito.it/handle/2318/1598508)

**Mood-app users specifically**
- Caldeira et al. 2017 (AMIA) **[qualitative feature + review analysis]**: **32 mood apps** (19 Android, 13 iOS), selected from 249 Play and 493 App Store hits. **29 of 32** offer mood visualisation (bar and pie charts, plus lists, line graphs, calendar view, map view). Only **7 of 32** support the Action stage. Reviewers want "to learn about their mood patterns" and to know "what things contribute to my emotional state". They wish they could "personalize mood options" and "process their data for analysis". [Caldeira et al. 2017](https://escholarship.org/uc/item/57z7f4c2)

**Plain-language pattern feeds and filtering**
- **Health Mashups** (Bentley et al., ACM TOCHI 2013). **Pilot:** 10 participants (Chicago and Stockholm), 2 months, with month 1 sensors only and month 2 with the app. Each night the server computed correlations between data streams and **deviations from the user's usual values**, and kept only statistically significant ones. In month 1 "no participant reported insights that linked sensors or time scales". In month 2 participants understood and related to items that connected data across sensors and time scales. Example phrasings: "You lose weight on weeks when it is warmer"; "Yesterday you walked much less than you normally do on Saturdays." **[qualitative pilot; outcomes self-reported]** [QS blog by the authors](https://quantifiedself.com/blog/health-mashups-helping-people-find-long-term-trends-between-wellbeing-and-activities-in-their-lives/)
- **Main study:** a **90-day trial with 60 participants**. The links between wellbeing and context "differ greatly" from person to person, and the system helped people understand themselves, which "led to more focused behavior". **[abstract-level; significance threshold and minimum data not retrieved]** [Health Mashups record](https://personalinformatics.owlstown.net/publications/526-health-mashups-presenting-statistical-patterns-between-wellbeing-data-and-context-in-natural-language-to-promote-behavior-change)
- **Jones & Kelly 2018** (Human–Computer Interaction journal): **20 participants, 3 months, using Exist** **[empirical field study]**. Raw correlation output caused information overload. Their automated filters cut the number of correlations shown by **about 55%** and raised the share rated *interesting* to **about 81%**, **34 percentage points better than a filter that only required p < .05**. The filters also used Google Trends data as a stand-in for a topic's general interest. [Bath research portal abstract](https://researchportal.bath.ac.uk/en/publications/dealing-with-information-overload-in-multifaceted-personal-inform/)
- Participants reportedly valued **surprisingness, usefulness and positive valence** most. **[abstract-level: from a search summary, not verified in the full text]** The same record says the work shaped the design of the commercial Exist app. [Bath research portal](https://researchportal.bath.ac.uk/en/publications/dealing-with-information-overload-in-multifaceted-personal-inform/); [REF 2021 impact record](https://results2021.ref.ac.uk/outputs/1d618c40-145e-4ed8-9ded-327f704df7d0?page=1)

### Inferences
- Dian Dian's current stats (days filled, streaks, % of year, distribution, per month, per weekday) answer only *Status* about the act of logging. They do not answer the questions people ask about their lives. Dian Dian has no goals, so Goals and Discrepancy questions barely apply. Users are almost certainly in a curiosity or Discovery mode. Useful stats should therefore target **History** (how a tracker's levels shift across months), **Context** (what else was logged or commented on a given day) and **Factors** (what tends to go with what).
- A "year in pixels" user is close to Epstein's **curiosity-driven** and **instrumental (keeping a record)** profiles, not the behaviour-change one. So "interesting" matters more than "actionable", and keeping a record has value of its own. Insights should feel like discoveries. They should not read as coaching.
- Choe's insight types map cleanly onto the features under study. Trend → averages and trends for ordered scales. Comparison by time segment → this month vs last, this year vs last. Correlation → links between trackers. Outlier → unusual months. Data summary and distribution → what already exists. Detail → "on this day". Comparisons between time periods are the cheapest and most robust with sparse data (see question 2).
- Two lessons follow from Health Mashups and Jones & Kelly. A natural-language feed helps people notice cross-tracker patterns. Unfiltered significance-based output overwhelms them and is often uninteresting. So a curated, small set of insights beats a full correlation matrix.

### Gaps
- I could not open the full text of Li et al. 2010 (participant numbers unverified), Jones & Kelly 2018 (the exact list of traits that made a correlation interesting or uninteresting), Choe et al. 2017 (per-type counts) or Rapp & Cena 2016 (the seven strategies).
- I found no peer-reviewed study of Exist.io or Bearable users' question types beyond Jones & Kelly's study of 20 Exist users.
- I found no study of users of a "year in pixels" or bullet-journal-style mood app and what stats they want. Ayobi et al. 2018 (question 3) covers paper bullet journals only.

---

## 2. Correlation insights on small, sparse, self-reported data: sample sizes, false discoveries, guards, phrasing

### Takeaway
Research prototypes and commercial apps guard against spurious links in five ways:
- a **minimum amount of data** (Bearable says at least 7 days with and 7 without a factor; TummyTrials allows 6 days minimum with 12 as default, but in a *randomised* design)
- an **effect-size floor plus a significance test** (SleepExplorer shows only |Spearman ρ| > 0.5 with p < .05)
- an **explicit confidence label kept separate from strength** (Exist's 5-star confidence; Daylio's Low/Medium/High; TummyTrials' strong/possible/weak/no evidence)
- **curation beyond p-values** (Jones & Kelly)
- **causation disclaimers**

Statistically, a few months of sparse daily data supports only large effects. Testing many tracker pairs at different time lags almost guarantees some false "links". Lay readers interpret verbal probability words very inconsistently, so wording should carry counts. Data filled in late is recalled rather than reported in the moment, which adds bias.

### Cited Findings

**How research prototypes set thresholds**
- **SleepExplorer** (Liang et al. 2016, Personal and Ubiquitous Computing): **12 participants, 2-week field study** **[qualitative]**. It used **Spearman** rather than Pearson because the relationships "are not necessarily linear" and the "variables in our study were ordinal". Missing values were removed pairwise. "Only factors with Spearman correlation coefficient that is higher than 0.5 or lower than -0.5 (significance level = 0.05) were rendered." Green and red bubbles showed the direction, with shade showing strength. [Liang et al. 2016](https://people.eng.unimelb.edu.au/baileyj/papers/J6%20PUC%20sleep%20explorer.pdf)
- In the same study, participants explained counterintuitive correlations with **untracked confounders** (pets, trash collectors, partners) or measurement error: "I'm not sure how to interpret that, just because I don't trust all the Fitbit data." One participant noticed that an expected link (afternoon coffee and sleep) did not show up and found that consistent with his own experience. [Liang et al. 2016](https://people.eng.unimelb.edu.au/baileyj/papers/J6%20PUC%20sleep%20explorer.pdf)
- **TummyTrials** (Karkar et al., CHI 2017): **15 people with IBS**, guided **12-day randomised self-experiments** (6 days with the trigger food and 6 without, in random order) **[empirical feasibility study]**. Trials had to be an even number of days, **at least 6**. The authors set "the default to 12 days as a balance between study duration and experimental power". The result was a p-value from a randomisation test, turned into a single sentence: *"Based on the self-trial there is (strong/possible/weak/no) evidence that your (symptom) gets worse when you consume (trigger)."* The cut-offs were **p < .05 = strong, .05–.10 = possible, .10–.20 = weak, > .20 = no evidence**. The authors note they "relaxed" the usual .05 rule. [Karkar et al. 2017](https://people.cs.umass.edu/~rkarkar/pubs/conf-chi2017-tummytrials.pdf)
- TummyTrials also notes that with few observations "Type 2 errors are more likely (i.e., an incorrect conclusion of 'no effect')", and that small effects need more days. It saw "hints of confirmation bias": "participants are prone to glean what they expect to from the data". The authors propose presenting results "to be pathways to the possible next steps", such as re-testing for higher confidence. 12 of 15 reported 100% compliance. [Karkar et al. 2017](https://people.cs.umass.edu/~rkarkar/pubs/conf-chi2017-tummytrials.pdf)
- **Health Mashups** showed only "statistically significant" correlations and deviations. The exact threshold was not retrieved. [QS blog](https://quantifiedself.com/blog/health-mashups-helping-people-find-long-term-trends-between-wellbeing-and-activities-in-their-lives/)
- **Jones & Kelly:** a p < .05-only filter left too much uninteresting output. Their extra filters cut the volume by about 55% and raised the share rated interesting to about 81% (+34 points). [Bath abstract](https://researchportal.bath.ac.uk/en/publications/dealing-with-information-overload-in-multifaceted-personal-inform/)

**How commercial apps do it** **[practitioner]**
- **Exist:** each correlation has a **strength** indicator and a **confidence** rating in stars out of 5. "You might have a very strong relationship between two attributes … with a very low confidence if we don't have much data." "Correlations can't determine the cause of the relationship." The user must consider reverse causation, a third variable or coincidence. [Exist KB: What are correlations?](https://kb.exist.io/article/37-what-are-correlations)
- Exist first checks for links on the same day. If it finds none, it checks consecutive days, so a habit can be linked to the next day's outcome. It advises logging events on the day they happen. [Exist KB: multiple days](https://kb.exist.io/article/55-will-exist-find-correlations-across-multiple-days)
- Exist does not publicly document its statistical method or minimum number of days. I could not find its "How long does it take to find correlations?" article.
- **Bearable:** "Having at least 7 days with, and 7 days without, a single Factor will help." "The more data you have, the more reliable your insights will be." Correlations "are open to interpretation". It "cannot tell you whether that pattern is because the factor *caused* the change". It warns about confounders and that "Outliers can distort correlations". Without time-of-day information, next-day correlations "may be more reliable". [Bearable support](https://bearable.app/support/troubleshooting/my-correlations-are-wrong-dont-make-sense/)
- Older Bearable posts reportedly said at least 3 days with and 3 without, and recommended at least 14 days with a factor before deciding anything, plus a 30-day period for best results. **[abstract-level search summary; this conflicts with the current 7/7 guidance]** [Bearable post](https://bearable.app/?p=19103); [Bearable post](https://bearable.app/?p=6372)
- **Daylio, "Influence on Mood":** compares entries with and without an activity, on the day before, the same day and the day after. Confidence is **Low/Medium/High**. "High confidence means the calculation is based on rich source data and provides significant results." "Low confidence might describe a specific trend, but you should not take it at face value." Good data needs many occurrences of the activity in varied combinations, plus entries without it. No formula or minimum is published. [Daylio FAQ](https://daylio.net/faq/?p=36)

**Statistical background**
- **Sample size for stable correlations** (Schönbrodt & Perugini 2013, J. Research in Personality; Monte Carlo simulation) **[empirical methods]**. Correlation estimates stabilise within ±0.1 of the true value only as **n approaches 250**. There are "few occasions in which it may be justifiable to go below n = 150". This is about between-person samples, but the precision maths applies to days as observations too. [Schönbrodt & Perugini 2013 (open-access PDF)](https://epub.ub.uni-muenchen.de/17968/1/oa_Schoenbrodt_17968.pdf)
- **Autocorrelation inflates false positives.** Two series that each depend on their own recent past (as mood and sleep do) produce spurious associations under standard tests. Cliff et al. report false-positive rates as high as 100% in some settings and recommend adjusting degrees of freedom to the effective sample size. [Cliff et al. 2021 (arXiv 2003.03887)](https://arxiv.org/abs/2003.03887). Lun et al. 2022 report that ignoring autocorrelation inflates the type-1 error of rank-correlation tests. [Lun et al. 2022](https://repositum.tuwien.at/bitstream/20.500.12708/128108/1/Lun-2022-Journal%20of%20Applied%20Statistics-vor.pdf)
- **Late entries are memories, not momentary reports.** Ben-Zeev, Young & Madsen 2009 (Cognition & Emotion) compared experience sampling with retrospective summaries **[empirical]**. Both depressed and control participants **overstated** positive and negative affect in recall. Controls skewed positive. Depressed participants were more inaccurate for negative affect. [Ben-Zeev et al. 2009](https://informahealthcare.com/doi/abs/10.1080/02699930802607937)
- Li et al. 2011 also note that memory of context "can be unreliable and degrades over time". [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)
- **Showing normal variability builds trust.** Kay, Morris, schraefel & Kientz 2013 (UbiComp Best Paper) combined review analysis, a journaling study, expert interviews and a large survey of bathroom-scale users. Users' expectations did not match what scales can do, and understanding day-to-day fluctuation went with more trust in the device. The authors argue for redesigning the display to show that variability. **[abstract-level]** [Kay et al. 2013](https://mucollective.github.io/paper/2013/03/01/weight.html)

**Phrasing uncertainty for lay readers**
- An HBR survey by A. & M. Mauboussin (2018) asked **1,700 people** to put numbers on probability words. "Likely" got a 90% range of **55%–90%** and "real possibility" **20%–80%**. The authors recommend using numbers. **[press/secondary: I did not read the HBR original]** [Jason Collins summary](https://www.jasoncollins.blog/posts/how-likely-is-likely)
- TummyTrials used fixed evidence words (strong/possible/weak/no) tied to p-value buckets. Exist uses stars for confidence. Daylio uses Low/Medium/High. All three keep **strength** and **confidence** as separate signals. [Karkar et al. 2017](https://people.cs.umass.edu/~rkarkar/pubs/conf-chi2017-tummytrials.pdf); [Exist KB](https://kb.exist.io/article/37-what-are-correlations); [Daylio FAQ](https://daylio.net/faq/?p=36)

### Inferences
- **What sparse data can support (computed, standard formulas):**
  - The smallest Pearson/Spearman |r| that reaches p < .05 (two-sided) is about **0.53 at n = 14** paired days, **0.36 at n = 30**, **0.25 at n = 60** and **0.21 at n = 90**.
  - Even an observed r = 0.4 has a 95% confidence interval of about **[0.05, 0.66] at n = 30** and **[0.21, 0.56] at n = 90**.
  - With a few months of sparse data, only large effects can be detected, and their size is very imprecise. SleepExplorer's |ρ| ≥ 0.5 floor is consistent with this.
- **Cost of "twice as often" (computed, Fisher exact test).** Take "mood is Great on 40% of 8 h+ nights vs 20% of other nights":
  - p ≈ **0.63** with 10 nights in each group
  - p ≈ **0.30** with 20
  - p ≈ **0.16** with 30
  - p ≈ **0.049** with 50
  - p ≈ **0.012** with 75

  A "twice as often" sentence is not supported until there are roughly **50 or more paired days in each group**. Most Dian Dian users (a few months of sparse data) will not get there for most pairs.
- **False discoveries (computed).** If no real links exist and each test uses α = .05:
  - 5 trackers give 10 pairs. Testing same-day and next-day makes 20 tests, so P(at least one false "link") ≈ **64%**.
  - With 40 tests it is ≈ **87%**.
  - Comparing level by level (5 mood levels × 4 sleep levels) multiplies the number of tests further.
  - At minimum, the number of tests should be limited (for example, one summary test per pair, at the same lag only) and corrected for multiple comparisons. Benjamini–Hochberg false-discovery-rate control is the standard choice, but it is my suggestion: I did not retrieve a source for it in this session.
- **Measures for ordered scales:** use rank-based statistics (Spearman, or comparing the share of top levels or median level between groups). Do not convert labels to numbers and compute Pearson r. Unordered categories need a co-occurrence or lift comparison with a count floor, not a correlation.
- **Late filling:** 58% of Dian Dian entries are made more than a week after their date. They are recalled, and recall overstates affect (Ben-Zeev). If two trackers for the same day are filled in one sitting, a single remembered impression of that day may drive both values. That could inflate links between them. This is my hypothesis and I did not find a direct test. Possible guards: count only days where both trackers were filled within a few days of their date, or at least avoid lagged (next-day) claims built on backfilled entries.
- **Suggested guard rails for Dian Dian (synthesis, not a validated standard):**
  - require a minimum number of **paired days** (both trackers filled), with **at least ~7–10 days in each compared group** as a floor, matching Bearable's practitioner rule, and more before any ratio claim
  - require an effect-size floor as well as significance
  - limit and correct the number of tests
  - drop trivially related pairs and duplicates
  - show at most a handful of insights, with a way to dismiss each
  - always state the **denominator in counts** ("on 9 of your 14 nights with 8 h+…")
  - add a separate confidence word or meter
  - add a short causation disclaimer
  - hide the insight below the threshold rather than showing a weak one
- **Phrasing patterns that follow from the sources:**
  - descriptive and conditional: "On days when…, … was more often…" (Health Mashups, Li's coffee example)
  - lead with counts, then any ratio ("Great on 8 of 20 nights with 8 h+ sleep, vs 4 of 20 other nights")
  - scope the claim: "in your entries so far" or "this year"
  - give confidence in fixed words linked to fixed rules (TummyTrials-style), never vague probability words alone
  - point to a next step: "keep tracking both to see if it holds"

### Gaps
- I found no published method details or minimum data for Exist, Bearable, Daylio or Gyroscope. Their help pages describe outputs, not algorithms.
- I found no study that measures how backfilled or late self-reports affect correlations *within* one person's tracking data.
- I found no PI study comparing ways of phrasing correlational insights (counts vs ratios vs coefficients vs stars) for lay comprehension. Jones & Kelly tested *which* correlations to show, not *how* to word them.
- I found no source specific to N=1 self-tracking on autocorrelation corrections. The sources above are general time-series methods papers.

---

## 3. Visualisations for calendar and categorical daily data, and evidence on comprehension

### Takeaway
There is **very little controlled evidence** on how well people read calendar heatmaps or year-in-pixels views. Calendar views are common in mood apps and are described as good for spotting patterns over time. One field study of data placed in a personal calendar found people quickly spotted regular patterns and anomalies. The strongest design lessons come from PI prototypes:
- every insight should come with **visual evidence** the user can check
- users should be able to move between a grouped view and the chronological view of the same days
- **show the actual days or entries behind a number**, because raw numbers feel empty
- avoid abstract charts for newcomers

### Cited Findings
- Of 32 mood apps, **29** offer visualisations. The authors write that "calendar view and line graphs can facilitate users to find patterns in time", while pie charts and meters give "an overall view". Reviewers with mood disorders valued graphs as "a great visual aid for sharing mood fluctuations" with clinicians. **[qualitative]** [Caldeira et al. 2017](https://escholarship.org/uc/item/57z7f4c2)
- **On-calendar visualisation** (Huang, Tory & Bartram, Graphics Interface 2016): an **eight-week field study** of fitness data shown inside participants' own calendars suggested people "quickly identify and reason about regular patterns and anomalies". **[abstract-level]** [Huang et al. 2016](https://unpaywall.org/10.20380%2FGI2016.03)
- A 2010 IEEE TVCG study of pixel-based displays (including a calendar-style temperature heatmap) found block size had limited effect on visual search and change detection. **[abstract-level; marginal relevance]** [Pixel-based visualisation study](https://www.um.edu.mt/library/oar//bitstream/123456789/27046/1/Evaluating_the_impact_of_task_demands_and_block_2010.pdf)
- Choe et al. define an insight as "an individual observation about the data accompanied by visual evidence". QS presenters annotated charts differently for each insight type. [Choe et al. 2015](https://www.microsoft.com/en-us/research/publication/characterizing-visualization-insights-quantified-selfers-personal-data-presentations/); [Choe et al. 2017](https://terpconnect.umd.edu/~choe/download/PervasiveHealth-2017-Choe-VisualizedSelf.pdf)
- **TummyTrials** showed symptom severity grouped by condition (trigger vs no trigger) for "a quick and easy visual analysis". A toggle "animates the dots into chronological order", which is "intended to reinforce that the same data is in both views". [Karkar et al. 2017](https://people.cs.umass.edu/~rkarkar/pubs/conf-chi2017-tummytrials.pdf)
- **SleepExplorer** used colour bubbles (green for positive, red for negative, shade for strength) with tooltips explaining each correlation. Participants used it to reason about causes and confounders. [Liang et al. 2016](https://people.eng.unimelb.edu.au/baileyj/papers/J6%20PUC%20sleep%20explorer.pdf)
- **Facebook Memories research (2017)** **[practitioner, "over a dozen" studies, no sample sizes given]**: testers said raw counts ("Friends Made", "Likes Received") "lacked some of the heart and soul", so the feature switched to showing **the actual posts behind the numbers**. The authors recommend focusing "on people and moments rather than statistics". [Facebook Research blog](https://research.facebook.com/blog/2017/09/facebook-memories-the-research-behind-the-products-that-connect-you-with-your-past/)
- **Ayobi et al. 2018** (CHI) on paper bullet journals: people make "personally meaningful visualisations" of habit, mood and symptom trackers and reflect through the act of designing them. Digital tools are "often too rigid" for people's practical and emotional needs. The authors propose "digitally extending analogue self-tracking". **[qualitative; abstract-level, sample size not retrieved]** [Ayobi et al. 2018](https://research-information.bris.ac.uk/en/publications/flexible-and-mindful-self-tracking-design-implications-from-paper/)
- Newcomers were held back by "overly abstract visualizations". [Rapp & Cena 2016](https://iris.unito.it/handle/2318/1598508)
- In Health Mashups, a **plain-language feed** got participants to relate data across sensors and time scales, which they had not done with sensor data alone in month 1. [QS blog](https://quantifiedself.com/blog/health-mashups-helping-people-find-long-term-trends-between-wellbeing-and-activities-in-their-lives/)
- **Colour judgement backfires** (see question 4): red highlighting of "failure" days in a bar chart increased rumination compared with neutral grey or green highlighting of good days. [Loerakker et al. 2023](https://research.chalmers.se/publication/539521/file/539521_Fulltext.pdf)

### Inferences
- Dian Dian's 12×31 grid is already the evidence view. The highest-value pattern is to make every stat or sentence **open its supporting days in the grid**: highlight the matching cells and dim the others, as in TummyTrials' animated transition between views. This also lets users check a claim against their own memory, which SleepExplorer users did spontaneously.
- For distributions over time (per-month share of each level), a stacked 100% bar per month in the user's own colours is the natural companion to the grid. This is design judgement, not evidence. Missing days should appear as an explicit "not filled" segment, or be excluded with the denominator printed ("on 18 filled days"). Spreading missing days across the levels would mislead.
- For ordered scales, a monthly median or "share of top two levels" line is easier to read than a mean of converted label numbers, and it respects ordinal data (SleepExplorer's reasoning for Spearman).
- Dian Dian's colours are user-chosen, so the app should never add its own good/bad colour coding (green/red, arrows, warning icons) on top of them. Loerakker's result (question 4) suggests that layer is what triggers rumination.
- Facebook's switch from counts to posts suggests a recap or insight should show the actual days and comments alongside the numbers.

### Gaps
- I found **no controlled comprehension study** of calendar heatmaps, GitHub-style contribution grids or year-in-pixels layouts for daily categorical data.
- I found no evidence on stacked bars versus alternatives for categorical distributions over time in PI.
- I found no study on how to render missing days in personal calendar views.
- Only the abstracts of Huang et al. 2016 and Ayobi et al. 2018 were reviewed.

---

## 4. Negative effects (rumination, anxiety, obsessive tracking, streaks) and tone guidance

### Takeaway
There is solid recent evidence that **how data is framed changes the emotional response**. In a within-subject study (n = 18), red-highlighted "failure" days raised rumination and lowered self-compassion compared with neutral grey or positive highlighting. Positive framing raised reflection. Conceptual work names **rumination** as the counterpart of reflection in PI. Measurement can reduce enjoyment of an activity (Etkin; contested). **Broken streaks** reduce later engagement, more so when people blame themselves and less when the streak can be repaired. Self-monitoring of mood is not harmful in itself. Trials show it can raise emotional self-awareness and reduce depressive symptoms, and mood analytics aimed at the future outperformed plain monitoring of the past. Guidance: neutral or positive framing, no added value judgements, no "bad/worst month" ranking, avoid highlighting broken streaks, allow repair, give users control.

### Cited Findings

**Rumination and framing**
- **Eikey et al. 2021** (Personal and Ubiquitous Computing 25:601–616) **[conceptual]**: PI research has leaned on self-reflection while overlooking negative thought-and-emotion loops. The paper presents rumination as the counterpart of reflection and explains "how self-tracking technologies may inadvertently lead to rumination" and what that implies for design. As summarised by Loerakker et al., emotion is one of three mechanisms the paper proposes, and increasing self-compassion is a suggested remedy. **[abstract-level: I could not access the full text]** [Eikey et al. 2021](https://link.springer.com/article/10.1007/s00779-021-01573-w); [Loerakker et al. 2023](https://research.chalmers.se/publication/539521/file/539521_Fulltext.pdf)
- **Loerakker, Niess, Bentvelzen & Woźniak 2023** (IMWUT 7(4), article 169) **[empirical, within-subject, n = 18]**. Each participant saw their own screen-time data for 11 days as bar charts against their personal average, in three framings:
  - **positive:** below-average days highlighted green
  - **neutral:** all grey
  - **negative:** above-average days highlighted red

  Each framing was shown with and without per-bar value labels. [Loerakker et al. 2023](https://research.chalmers.se/publication/539521/file/539521_Fulltext.pdf)
- **Results:**
  - Framing had a significant effect on rumination, F(2,102) = 16.81, p < .001.
  - Negative framing produced **higher rumination** than both neutral and positive (p < .001) and **lower self-compassion**.
  - Positive framing produced **higher reflection** than neutral and negative.

  The authors conclude: "PI tools should avoid negative framings and instead opt for positive or neutral framing techniques." The effect of the value labels was mixed, and qualitative attitudes varied, so they recommend letting users choose whether to see them. They also note that framing is itself a bias, so a tool aiming at objectivity might present data in both positive and negative forms. [Loerakker et al. 2023](https://research.chalmers.se/publication/539521/file/539521_Fulltext.pdf)
- Niess et al. 2020, as summarised by Loerakker et al.: visualisations highlighting failure to reach a goal triggered negative affect in fitness-tracker users, compared with more neutral ones. **[secondary]** [Loerakker et al. 2023](https://research.chalmers.se/publication/539521/file/539521_Fulltext.pdf)

**Measurement and enjoyment**
- **Etkin 2016** (Journal of Consumer Research 42(6)) **[empirical, 6 experiments, one with 310 participants]**. Tracking output raised how much people did (walking, reading, colouring) but lowered how much they enjoyed it, and lowered later continuation. When reading was framed as learning rather than fun, the enjoyment cost disappeared. [Etkin 2016 (PDF)](https://marketing.wharton.upenn.edu/wp-content/uploads/2016/10/Etkin-Jordan-11-12-15-Hidden-Cost.pdf); [Duke Fuqua summary](https://www.fuqua.duke.edu/duke-fuqua-insights/etkin-counting-steps)
- A 2021 survey of self-selected cyclists found **94%** said quantification made cycling more enjoyable. This contests the general claim but is not a controlled test. [IJPBA 2021](https://www.graphyonline.com/archives/IJPBA/2021/IJPBA-174/)

**Streaks**
- **Silverman & Barasch 2023** (Journal of Consumer Research 49(6):1095–1117) **[empirical, 7 studies including language-app field data]**:
  - intact streaks shown in a log raise later engagement compared with broken ones, regardless of actual past behaviour
  - people treat keeping a streak as a goal in itself
  - the drop after a break is **amplified when people attribute the break to themselves** and **attenuated when they can "repair" it**
  - in the app data, users who broke a streak tended to switch to a new language rather than rebuild the same streak

  [UD repository record](https://udspace.udel.edu/items/42ce576b-8e1f-429a-8541-e29e48dbcfbb); [CU Boulder summary](https://www.colorado.edu/business/faculty-research/2023/04/19/or-track-how-broken-streaks-affect-consumer-decisions)
- **Duolingo** **[practitioner]**:
  - learners who reach a 7-day streak are **3.6×** more likely to complete their course
  - Streak Freeze lets learners keep a streak through a missed day, with up to two equipped at once
  - separating the daily goal from the streak raised the share of new learners on a streak by **19%** in an A/B test
  - learners at a 7-day streak are **2.4×** more likely to return the next day

  [Duolingo blog: streak and habit](https://blog.duolingo.com/how-duolingo-streak-builds-habit); [Duolingo blog: improving the streak](https://blog.duolingo.com/improving-the-streak)

**Annoyance and obsessive tracking**
- From Li et al. 2011: a participant stopped diligent logging to avoid becoming "OCD about it". "Telling people that they are doing well can become annoying." [Li et al. 2011](https://res.cloudinary.com/owlstown/image/upload/v1501822904/t04gekfq9y2wppuulgbh.pdf)
- From the 2020 literature map: "some find that tracking reinforces negative behaviors", and 55 publications discuss adverse consequences. [Epstein et al. 2020](https://par.nsf.gov/servlets/purl/10252696)

**Mood tracking and mood analytics can help**
- **Kauer et al. 2012** (JMIR) **[RCT, ages 14–24, recruited through GPs]**. Monitoring mood, stress and activities on a phone increased **emotional self-awareness**, which in turn reduced depressive symptoms in young people with mild or worse symptoms. The comparison group monitored activities only. **[abstract-level; sample size not retrieved]** [Kauer et al. 2012](https://www.jmir.org/2012/3/e67/)
- **Hollis et al. 2017** (Human–Computer Interaction 32:208–267) **[empirical: 165 participants, 4,693 logfiles, 65 surveys, 15 interviews]**. The EmotiCal mood *forecasting* system improved mood and emotional self-awareness compared with controls who "simply monitored their past". Positive recording and reflection increased long-term well-being, while negative recording led to more analytic language. **[abstract-level]** [Hollis et al. 2017](https://library.selfresearch.org/research/what-does-all-this-data-mean-for-my-future-mood-actionable-analytics-and-targeted-reflection-for-emotional-well-being/)
- A companion paper reports per-user mood models explaining **61%** of variance from 70 users. **[abstract-level]** [Hollis, Whittaker & Springer, mood modelling](https://alspringer.github.io/assets/moodmodeling.pdf)
- **Bakker & Rickard 2018** (J. Affective Disorders): engagement with the MoodPrism self-monitoring app over 30 days predicted changes in mental health. **[abstract-level; effect sizes not retrieved]** [Bakker & Rickard 2018](https://findanexpert.unimelb.edu.au/scholarlywork/1357306-engagement-in-mobile-phone-app-for-self-monitoring-of-emotional-wellbeing-predicts-changes-in-mental-health--moodprism)

**Noise and trust**
- Understanding normal fluctuation increased trust in a weight scale. The authors argue against presenting single-day changes as meaningful (the title: "There's no such thing as gaining a pound"). **[abstract-level]** [Kay et al. 2013](https://mucollective.github.io/paper/2013/03/01/weight.html)

### Inferences
- **No app-imposed value judgement.**
  - Dian Dian should not add red/green, up/down arrows, "worse/better" or "bad month" labels to the user's own levels. This applies especially to Mood, where a "Low" month is a fact about the person, not a failure.
  - Neutral descriptive sentences ("October had 6 Low days, September 3") are safe.
  - Positive framing is supported by Loerakker et al. but must stay honest. Their own caveat is that framing is a bias.
  - Avoid ranking months as "worst", and avoid "your mood dropped" headlines. Prefer "more Low days than…" with counts. Avoid moralising verbs.
- **Fluctuation, not verdicts.** Following Kay et al., describe month-to-month differences as normal variation unless they are large and backed by enough days. Say "a bit more / about the same / noticeably more" with counts, rather than declaring a trend from two or three entries.
- **Streak and filling stats.**
  - Silverman & Barasch predict that showing broken streaks lowers engagement, especially when users blame themselves. Dian Dian already allows **repair**, because backfilling is possible. That attenuates the effect, so a streak that counts backfilled days is less harmful.
  - Frame filling stats positively ("days kept this year") rather than as gaps or a broken-streak count. Do not shame missing days.
  - Never push a streak-loss notification. See also the sibling notes on streak anxiety (`../Notifications de rappel et fidélisation/series_gamification_anxiete.md`).
- **Give control.** Loerakker et al. found mixed attitudes to added context and recommend customisation. Facebook found control over resurfacing was essential (question 5). Insights on sensitive trackers (Mood) should be easy to hide, and the app should not push them through notifications.
- **Mood stats are not inherently risky.** RCT and field evidence suggest that becoming more aware of one's emotions is beneficial. The risk lies in *judgemental framing* and in repeatedly highlighting negative patterns. Hollis et al. suggest a forward-looking or "what helps" angle beats simply showing the past.

### Gaps
- I found no study specifically on mood "year in pixels" stats and rumination. Loerakker et al. used screen-time data, and extending the result to mood is an inference (stated by the authors as a possibility).
- I could not read Eikey et al.'s full list of design implications.
- I found no peer-reviewed measure of anxiety caused by streaks in journaling or mood apps. Evidence on streaks comes from consumer research and language-learning apps.

---

## 5. Reflection features ("on this day", year in review, recaps): evidence on engagement and wellbeing

### Takeaway
Revisiting one's own past records ("technology-mediated reflection") **improved well-being** in controlled deployments (Echo: 44 users, more than 12,000 recordings and reflections). The effect depends on mood. When a negative mood meets a positive memory, the memory can become "tainted". Large-scale product research at Facebook found people want resurfaced memories of "fun, interesting, and important life moments". Painful content (deaths, accidents, failed ventures, jobs since left) must be filtered, and users need **control** over what resurfaces. Recaps work better as stories of real moments than as bare counts. I found no peer-reviewed evidence on year-in-review recaps specifically.

### Cited Findings
- **Isaacs et al. 2013** (CHI, "Echoes from the past") **[empirical: 3 deployments, 44 users, more than 12,000 recordings and reflections]**. Technology-mediated reflection on one's own past entries **improved well-being on four psychological measures**. [SRI record](https://sri.com/?p=86326)
- Konrad's dissertation describes the design: capturing three experiences a day for a month, then reflecting on them in writing. When reflecting on past negative experiences, participants used more positive-affect and acceptance words ("redemption sequences") and more insight words. A follow-up with Echo (Konrad, Isaacs & Whittaker 2016) observed psychological distancing, measured as fewer first-person pronouns over time. [Konrad dissertation, UCSC](https://escholarship.org/uc/item/4n21504w)
- **Pensieve** (Peesapati et al. 2010) resurfaced past Facebook posts for written reflection. Participants enjoyed it and reported improved mood. **[secondary, via Konrad]** [Konrad dissertation](https://escholarship.org/uc/item/4n21504w)
- **MoodAdaptor** (Konrad dissertation) **[empirical, 1-month study + 3-month follow-up]**. Reflecting on memories of the *opposite* valence to current mood made mood more neutral but "did not impact overall well-being". When negative moods prevailed over positive memories, "memories became negatively tainted". When positive moods prevailed over negative memories, the usual well-being mechanisms appeared. [Konrad dissertation](https://escholarship.org/uc/item/4n21504w)
- **Facebook Memories research (2017)** **[practitioner; "over a dozen" studies including lab sessions, a large survey of people who had just seen a memory, and linguistic analysis; no sample sizes given]**:
  - people see Facebook's role as providing "reminders of fun, interesting, and important life moments"
  - family photos, especially of children growing up, are "memory gold"
  - posts with words like "miss" were shared more
  - food memories were less relevant
  - posts about violence, accidents or failed ventures should not resurface
  - positive posts can turn negative over time ("contamination sequences", e.g. a first day at a job later left)
  - participants said Facebook would cross a line without giving them **control**, which led to filters for specific people and dates
  - monthly or seasonal "recap" stories were added after three rounds of research
  - the authors recommend treating memories "as autobiographical stories, not just data"

  [Facebook Research blog](https://research.facebook.com/blog/2017/09/facebook-memories-the-research-behind-the-products-that-connect-you-with-your-past/)
- Press coverage: memories of a lost job, a loved one's death or self-harm can trigger distress. On This Day lets users exclude people and dates. **[press]** [Daily Dot](https://dailydot.com/?p=140418)
- **Anecdote:** Eric Meyer's 2014 essay "Inadvertent Algorithmic Cruelty" describes Facebook's automatic Year in Review featuring a photo of his daughter, who had died that year. It became the standard cautionary tale for automated recaps. **[anecdote]** [meyerweb.com](https://meyerweb.com/eric/thoughts/2014/12/24/inadvertent-algorithmic-cruelty/)
- Positive recording and reflection increased long-term well-being in EmotiCal, while negative recording led to more analytic language. **[abstract-level]** [Hollis et al. 2017](https://library.selfresearch.org/research/what-does-all-this-data-mean-for-my-future-mood-actionable-analytics-and-targeted-reflection-for-emotional-well-being/)
- Epstein et al. list as an open problem how to use historical data when someone resumes tracking after a lapse. [Epstein et al. 2015](https://my.eng.utah.edu/~cs5540/au16/readings/PersonalInformatics-Epstein2015.pdf)
- Health Mashups compared a day with the user's own usual pattern ("walked much less than you normally do on Saturdays"), a form of comparison against one's own history. [QS blog](https://quantifiedself.com/blog/health-mashups-helping-people-find-long-term-trends-between-wellbeing-and-activities-in-their-lives/)

### Inferences
- **"On this day last year"** is the best-supported reflection feature for Dian Dian: reflection on one's own past records improved well-being in Echo and Pensieve. It needs guard rails:
  - prefer days with a comment (the story, not only a colour)
  - let users hide a tracker, day or period from resurfacing (Facebook's controls)
  - be careful about resurfacing a Low-mood day or a sad comment unprompted, especially on a day the user has logged as Low (Konrad's "tainting" finding)
  - show it when the user opens the app rather than in a push notification
- It may also help bring back users who lapsed: showing last year's entries on return is a gentle way back in (Epstein's open problem). This is a hypothesis, not tested.
- **Year-in-review and monthly recaps:** build them around moments (commented days, longest run of a top level, first and last entries, a few real days in the grid) with counts as support. Avoid a "worst month" slide, and never auto-select painful content. Facebook found bare numbers felt empty, and Meyer's case shows the risk of automatic selection.
- "Compared with your usual" sentences (Health Mashups) suit recaps: "this October had more Great days than your usual October". Use only with enough days, as in question 2.

### Gaps
- I found **no peer-reviewed study** of year-in-review recaps (Spotify Wrapped-style) on engagement or wellbeing. Facebook's research blog gives no figures.
- I found no study of "on this day" in mood or habit trackers specifically. Evidence comes from social media and life-logging (Echo, Pensieve, Facebook).
- A search snippet claimed the Echo well-being benefits were "sustained long-term" (Konrad, Isaacs & Whittaker, TOCHI). I could not confirm this in a primary source, so it is left out of the findings.
