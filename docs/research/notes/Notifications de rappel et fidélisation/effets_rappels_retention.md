# Measured effect of daily reminder notifications on retention and engagement in self-tracking, habit, mood and health apps

Scope: controlled and large-N evidence from 2009 to 2026 (pre-2012 only where it is the standard reference). Evidence grades used below:
**[RCT]** randomised controlled trial, **[MRT]** micro-randomised trial (within-person randomisation of each notification), **[META]** systematic review or meta-analysis, **[OBS-large]** large observational or log study, **[A/B]** industry online controlled experiment, **[VENDOR/ANECDOTE]** not peer-reviewed, marketing or anecdotal.

---

## Q1. What do RCTs, MRTs and large studies show about reminder/push notifications on engagement and retention?

### Takeaway
A notification reliably raises the chance that the user opens or logs in the next hours. Effects range from about +4% (24 h window, low-salience message) to about 3.5× (1 h window). Across reviews, prompts give a borderline-positive, heterogeneous lift in engagement (pooled RR ≈ 1.27). In mental-health app trials, reminders go with lower attrition. The single best-controlled consumer study (Drink Less MRT) found no effect of daily notifications on how long users stayed before disengaging, so the solid evidence is for short-term, same-day engagement and weak for long-term retention.

### Cited Findings

**Micro-randomised trials (strongest causal evidence for "notification vs no notification")**
- **[MRT] Bell et al. 2023, Drink Less (alcohol-reduction app), JMIR mHealth uHealth 11:e38342.** 350 **new** users were randomised **once a day at 8 PM** for their **first 30 days**: 30% standard message, 30% new message, 40% no message. Receiving a notification raised the probability of opening the app **in the next hour ≈ 3.5-fold (95% CI 2.91–4.25)** versus no notification. Standard and new messages were similarly effective. — [PMC10337295](https://pmc.ncbi.nlm.nih.gov/articles/PMC10337295) / [JMIR](https://mhealth.jmir.org/2023/1/e38342)
- Bell 2023, continued. "The effect of the notification did not change significantly over time" across the 30 days. Critically, **"across the 3 arms, time to disengagement was not significantly different"**, and the authors concluded "further optimization is required to improve the long-term engagement." — [PMC10337295](https://pmc.ncbi.nlm.nih.gov/articles/PMC10337295)
- Bell 2023, continued. An exploratory moderator: being in an already-engaged state lowered the effect of the new message, but not significantly. — [PMC10337295](https://pmc.ncbi.nlm.nih.gov/articles/PMC10337295) (via search summary of the full text)
- **[MRT] Bidargaddi et al. 2018, "To Prompt or Not to Prompt?", JMIR mHealth uHealth 6(11):e10123.** 1,255 users of a commercial **workplace well-being app** over 89 days. Each user was randomised at one of 6 daily time points to receive or not receive a tailored health message by push. The outcome was **self-monitoring of behaviours and feelings within the next 24 h**, the closest analogue to "log your day". A message made users **3.9% more likely to self-monitor in the next 24 h (RR 1.039, 95% CI 1.01–1.08)**. — [JMIR](https://mhealth.jmir.org/2018/11/e10123/)
- Bidargaddi 2018, continued. Weekend effect: **+8.7% (95% CI 1.01–1.17)** versus **+2.5% on weekdays** (CI includes 1). The difference between the two was not significant (P=.18). The best slot was **12:30 pm on weekends: +11.8% (90% CI 1.02–1.13)**. The effect attenuated over the 89 days, but the attenuation was not statistically significant (P=.84). — [JMIR](https://mhealth.jmir.org/2018/11/e10123/); [PMC6293241](https://pmc.ncbi.nlm.nih.gov/articles/PMC6293241)
- **[MRT] Klasnja et al. 2019, HeartSteps, Annals of Behavioral Medicine.** Over 42 days, activity suggestions were randomised at 5 daily decision points. Averaged across the study, a suggestion raised the **30-min step count by 14% (+35 steps over a 253-step mean; p=.06)**. Walking suggestions: **+24% (+59 steps; p=.02)**. Anti-sedentary suggestions: no detectable effect. — [PubMed 30192907](https://pubmed.ncbi.nlm.nih.gov/30192907/); [PMC6401341](https://pmc.ncbi.nlm.nih.gov/articles/PMC6401341)
- HeartSteps, continued. The effect was **largest at the start and decayed with days in study**. Early walking-suggestion effect: **+107% (+271 steps; p<.01)**. Early any-suggestion effect: +66% (+167 steps; p<.01). Decline over time was a pre-registered hypothesis and was confirmed. — [PubMed 30192907](https://pubmed.ncbi.nlm.nih.gov/30192907/); [PMC6401341](https://pmc.ncbi.nlm.nih.gov/articles/PMC6401341)
- Definition used in MRT methodology: habituation is "the reduced level of responsiveness resulting from frequent stimulus exposure … attention to the push stimulus deteriorates, possibly to the point at which the individual no longer notices the stimulus." — [Qian et al., MRT design considerations, arXiv 2005.05880](https://arxiv.org/pdf/2005.05880)

**Randomised trials of frequency and timing**
- **[RCT, exploratory] Morrison et al. 2017, PLOS ONE 12(1):e0169162, Healthy Mind (stress management app).** N=77 randomised to 3 arms: "intelligent" (context-timed) notifications, daily notifications in set windows, or occasional notifications. The **intelligent and daily arms engaged more than the occasional arm**: d ≈ .47 and .44 for viewing notifications, and .50 and .43 for acting on them. **No meaningful difference between intelligent and fixed-window daily timing.** The authors concluded that frequent notifications may increase exposure to content without deterring engagement. Small and exploratory; a correction was published. — [Southampton ePrints 404088](https://eprints.soton.ac.uk/404088); [RePEc record](https://econpapers.repec.org/RePEc:plo:pone00:0169162)
- **[Field study] Mishra et al. 2021, Ally app (physical-activity chatbot), IMWUT.** Machine-learning models that predicted when a user was receptive gave **"up to a 40% improvement in receptivity"** versus random send times. — [doi 10.1145/3463492 / PMC8680205](https://doi.org/10.1145/3463492)
- **[Field study] Künzler et al. 2019, same Ally app.** 189 participants over 6 weeks. Receptivity was associated with user traits (age, personality, device type) and with context (day/time, battery, phone interaction, activity, location). — [doi 10.1145/3369805 / PMC9494762](https://doi.org/10.1145/3369805)

**Systematic reviews / meta-analyses**
- **[META] Alkhaldi et al. 2016, JMIR 18(1):e6.** 14 studies, 8,774 participants, 9 meta-analysed. Technology-based prompts (email, SMS, push) versus no prompt: **RR 1.27 (95% CI 1.01–1.60), I²=71%** for dichotomous engagement. The authors' conclusion: "studies reported **borderline positive effects** … the results have to be interpreted with caution." Only one small study compared prompt characteristics. It found that prompts **promoting new content** and those **sent shortly after the user started** were more likely to engage users. — [JMIR](https://www.jmir.org/2016/1/e6) (full text read via Europe PMC, [PMC4723726](https://pmc.ncbi.nlm.nih.gov/articles/PMC4723726/))
- **[META, older] Fry & Neff 2009, JMIR 11(2):e16.** 19 studies, combined N=15,655. **11 of 19 reported positive findings** for periodic prompts. Frequent prompts combined with personal counsellor contact showed stronger effects. The review could not assess long-term behaviour change because follow-up was lacking. — [PMC2762806](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC2762806/)
- **[META] Linardon & Fuller-Tyszkiewicz 2020, J Consult Clin Psychol, 70 RCTs of smartphone mental-health interventions.** Attrition: 24.1% short-term, 35.5% longer-term. Attrition was **significantly lower in trials that "reminded participants to engage in the intervention"** (also lower with acceptance-based content and monetary compensation; higher with online enrolment). Usage "consistently declined over the course of the trial." — [PubMed 31697093, doi 10.1037/ccp0000459](https://pubmed.ncbi.nlm.nih.gov/31697093/)
- **[META] Liu, Torous, Fuller-Tyszkiewicz et al., JAMA Psychiatry (online 19 Nov 2025), 79 RCTs of depression and anxiety apps.** Uptake ≈92.4%. Adherence ≈61.8%. Attrition 18.6% at posttest and 28.4% at follow-up. **Attrition was lower in trials that used reminders or human support, and in apps *without* gamification.** I could not access the full text; figures come from news coverage. DOI reported as 10.1001/jamapsychiatry.2025.3439. — [AJMC](https://www.ajmc.com/view/addressing-uptake-adherence-and-attrition-in-mental-health-apps); [HCPLive](https://www.hcplive.com/view/mental-health-apps-gain-high-uptake-struggle-adherence-retention)
- Adjacent evidence: a meta-analysis of digital (SMS) appointment reminders covered 21 studies (8,345 notified vs 7,731 not notified patients) and found higher clinic attendance with notifications. This is one-off reminders, not habit apps. — [PMC5093388](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5093388/)

**Large-N log study on how notifications are handled**
- **[OBS-large] Pielot, Vradi & Park 2018, "Dismissed!", MobileHCI.** 794,525 notifications from 278 Android users, about 4 weeks each (2016). Median **56 notifications/day**. Conversion rate (notification led to opening the app): messaging **63.7%**, group messaging **65.8%**, email **15.5%**, social **26.6%**, **"NonSocial" app notifications 16.2%**. NonSocial notifications "tend to be dismissed quickly". The authors suggest the low share of non-messaging notifications may be because "users have begun to disable notifications from these apps." — [PDF](https://www.interruptions.net/literature/Pielot-MobileHCI18.pdf)

**Industry A/B evidence**
- **[A/B, large] Duolingo (Yancey & Settles, KDD 2020).** This optimised *which* reminder text is sent; it did not test reminder versus no reminder. See Q5 for figures. — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)

**Vendor claims (not rigorous, correlational, self-interested)**
- **[VENDOR] Airship 2017 retention study.** 63 million users who first opened an app in September 2016. Reports a "very strong correlation between greater notification frequency and greater mobile app retention." Opted-in users self-select, so this is not causal. — [Airship newsroom 2017](https://www.airship.com/newsroom/urban-airships-mobile-app-retention-study-for-key-industry-verticals/)
- **[VENDOR] Airship 2015.** Average push opt-in rate 43%, down from 45% in 2013. — [Airship newsroom 2015](https://www.airship.com/newsroom/New-Urban-Airship-Study-Finds-Massive-Difference-in-Opt-In-Rates/)
- **[VENDOR] OneSignal 2024 benchmarks.** Publishes D1/D7/D30 retention by category. Example: Business category D1 25.4%, D7 16.9%, D30 6.9%. Useful as a baseline only; not an effect of notifications. — [OneSignal 2024](https://onesignal.com/mobile-app-benchmarks-2024)

### Inferences
- Across designs, the evidence is consistent that a reminder makes *that day's* log more likely. The size depends heavily on the outcome window (1 h vs 24 h) and the baseline. A 3.5× lift in "opened within the next hour" and a +3.9% lift in "logged within 24 h" can both be true for the same kind of intervention.
- The best-matched study for a new-user daily check-in (Drink Less: new users, 1 daily evening push, 30 days) found **no improvement in time to disengagement**. Expect reminders to raise logging among users who are still around. Do not expect them, on their own, to move D7/D30 from ~19% to something much higher.
- Most positive "reminders reduce attrition" findings (Linardon 2020; Liu 2025) are *between-trial* meta-regressions, so they are confounded by everything else that differs between trials. They support reminders as part of a package, not a specific effect size.
- Smart timing beat random timing (Mishra: up to +40% receptivity) but not fixed sensible windows (Morrison: no difference). For a one-per-day local notification, a **user-chosen time** is a reasonable low-cost proxy for "receptive time". This is my inference; no head-to-head trial was found.
- Pielot's ~16% conversion for non-social app notifications is a realistic ceiling to plan around for tap-through on a reminder.

### Gaps
- No RCT or MRT found that measures D1/D7/D30 *retention* (as opposed to proximal engagement) for a single daily reminder versus none in a consumer self-tracking app.
- Absolute open probabilities with and without notification in the Drink Less MRT were not retrieved, only the relative 3.5×.
- Full text of Liu et al. 2025 (JAMA Psychiatry) was not accessed; reminder moderator statistics were not retrieved.
- No large 2024–2026 MRT of daily reminders in a consumer journaling or mood app surfaced in searches.

---

## Q2. Do reminders help form a habit, or do they create dependence on the reminder?

### Takeaway
Time-based reminders raise repetition: people forget less. In the main HCI studies, though, they produced **lower automaticity** than tying the behaviour to an existing daily event (a contextual cue). Reminders can therefore keep the behaviour going without the habit forming. Habit formation itself takes about 2 months on average (median 59–66 days, range 18 to 254+), and missing a single day does not derail it.

### Cited Findings
- **Stawarz, Cox & Blandford 2015, "Beyond Self-Tracking and Reminders", CHI '15 (doi 10.1145/2702123.2702230).** This combined a **4-week study** with a functionality review of **115 habit-formation apps**. Result: **"reminders helped with repetition but slowed habit development"**. **Event-based cues increased automaticity**. Positive reinforcement had little effect. Recommendation: support **contextual cues and implementation intentions** rather than relying on reminders. The app review found existing apps centred on self-tracking and reminders, with little support for event-based cues. — [UCL Discovery 1468224](https://discovery.ucl.ac.uk/id/eprint/1468224/); [Bristol research portal](https://research-information.bris.ac.uk/en/publications/beyond-self-tracking-and-reminders-designing-smartphone-apps-that/)
- Limitation of the 2015 study: a 2015 *Frontiers* abstract notes it measured an **artificial behaviour (texting the researchers) over only 4 weeks** and did not consider location as a cue. — [DOAJ / Frontiers in Public Health 2015](https://doaj.org/article/e295012ca8ba4b9a83d33d8bd5772933)
- **Stawarz, Cox & Blandford 2016 follow-up (Frontiers in Public Health conference abstract, doi 10.3389/conf.FPUBH.2016.01.00066).** 209 recruited, **115 completed**. A **3-month** daily behaviour (1-minute breathing meditation, 56%, or a glass of water, 44%), reported by SMS. Four conditions: no cue, **SMS reminder**, trigger event, trigger event + location. Automaticity was measured with the SRBAI, with a 3-month follow-up. Findings:
  - **Contextual cues supported habit formation better than reminders.**
  - Trigger events and time of day had the greatest impact and kept the behaviour going through routine changes such as holidays.
  - Location cues were ineffective.
  - **"Participants who received reminders forgot less often but reported low automaticity, suggesting the habit did not form."**
  - Recommendation: combine reminders with habit support, using reminders that **reinforce the cue–task link**, e.g. "remember to take your medications with breakfast".

  No numeric SRBAI scores were given in the abstract. — [Frontiers abstract](https://www.frontiersin.org/10.3389/conf.FPUBH.2016.01.00066/event_abstract)
- **Lally et al. 2010, "How are habits formed", European Journal of Social Psychology (doi 10.1002/ejsp.674).** 96 participants chose a daily health behaviour for 84 days. Median time to 95% of the modelled automaticity plateau was **66 days**, with a range of **18 to a projected 254 days**. The 66 days was computed on the subset whose data fitted the model (reported as 39 participants). **Missing one opportunity did not materially affect habit formation**, but very inconsistent performers did not form habits. About half had not reached a high automaticity score by day 84. — [UCL news 2009](https://www.ucl.ac.uk/news/2009/aug/how-long-does-it-take-form-habit); [BPS Research Digest](https://bps.org.uk/research-digest/how-form-habit); [The Behavioral Scientist (critical reading of the 66-day figure)](https://www.thebehavioralscientist.com/articles/how-long-to-form-a-habit)
- **[RCT] Keller et al. 2021, British Journal of Health Psychology 26(3):807–824 (doi 10.1111/bjhp.12504).** N=192 planned a daily nutrition behaviour around either a **routine-based cue** ("after X") or a **time-based cue** ("at 8 pm"), with 84 days of daily questionnaires. **Both increased automaticity and enactment; no between-condition difference.** **Repeated enactment was the key predictor of automaticity.** Those who formed habits took a **median of 59 days** to reach peak automaticity. — [PubMed 33405284](https://pubmed.ncbi.nlm.nih.gov/33405284/)
- **[OBS-large] Buyalskaya et al. 2023, PNAS.** Machine learning over objective data: **>30,000 gym-goers over 4 years, >12M observations**, and **>3,000 hospital workers, >40M handwashing observations**. Habit formation took **months for gym attendance but weeks for handwashing**, so there is no "magic number". More predictable (habitual) gym-goers were **less responsive to an intervention** promoting attendance. — [PMC10151500](https://pmc.ncbi.nlm.nih.gov/articles/PMC10151500); [Caltech news](https://neuroscience.caltech.edu/news/no-magic-number-for-time-it-takes-to-form-habits)

### Inferences
- The risk is not that reminders cause churn. The risk is that the behaviour stays reminder-driven: users who log only when pinged may stop when the reminder is dismissed, muted or removed. This fits Stawarz (repetition up, automaticity down) and Bell (no change in time to disengagement).
- Keller 2021 shows a well-chosen *time* cue can work as well as a routine cue. What matters is consistent pairing with a stable cue and repetition. A practical synthesis for a daily-dot app: at onboarding, have the user anchor logging to an existing routine ("after brushing teeth / in bed"), set the reminder time to match, and word the reminder to restate the anchor ("Bedtime — colour today's dot").
- Because one missed day does not break habit formation (Lally), designs that punish a missed day hard (streak loss) are not supported by the habit literature as necessary. This is an inference; streak effects were not studied here.
- Habit timelines (≈2 months median) far exceed the D1–D7 window where this app loses most users. Reminders' realistic job is to get users through the first weeks of repetition, not to build the habit by themselves.

### Gaps
- Stawarz 2015 and 2016 numeric results (adherence rates, SRBAI means per arm) could not be retrieved; ResearchGate and Cardiff ORCA blocked access.
- No controlled study found that tests **fading out** reminders (gradual withdrawal) as a way to transfer control to the contextual cue in an app context.
- No study found on reminder dependence specifically for mood or journaling apps.

---

## Q3. Effect size of one daily reminder vs none, and diminishing returns / habituation over weeks

### Takeaway
For a single daily reminder, the best estimates are a 3.5× relative lift in opening within the next hour (Drink Less, evening push, new users, 30 days) and +3.9% in self-monitoring within 24 h (well-being app). Response decay is clear in HeartSteps, where a ~107% early effect shrank to a ~24% average. In the daily-reminder MRTs, decay was small or non-significant over 30–89 days. The main known source of decay is **repetition of the same content**: novelty boosts and recency penalties are documented at Duolingo scale.

### Cited Findings
- Single daily push, new users, 30 days: **≈3.5× (95% CI 2.91–4.25)** probability of opening within 1 h, **with no significant change in effect over 30 days** and no effect on time to disengagement. — [Bell et al. 2023, PMC10337295](https://pmc.ncbi.nlm.nih.gov/articles/PMC10337295)
- One randomised send per day across 6 possible slots: **RR 1.039** for self-monitoring within 24 h. Attenuation over 89 days was not significant (P=.84). — [Bidargaddi et al. 2018](https://mhealth.jmir.org/2018/11/e10123/)
- HeartSteps, 5 decision points per day over 42 days: walking-suggestion effect **+107% early → +24% averaged**. The decrease with study day was statistically supported and pre-registered. — [Klasnja et al. 2019](https://pubmed.ncbi.nlm.nih.gov/30192907/)
- Daily vs occasional notifications (stress app, N=77): daily was better than occasional for viewing and acting, d ≈ 0.43–0.44. The authors found no evidence that daily frequency deterred engagement. — [Morrison et al. 2017](https://eprints.soton.ac.uk/404088)
- **Novelty and repetition (Duolingo).** Prior A/B tests showed that new templates "tended to boost notification conversion rates, even when those new templates did not outperform existing templates in the long run". This was attributed to a novelty effect. Reusing the same template, as a bandit without a recency penalty would, **hurt reward by 0.5%**. The authors state that sending the same template day after day "will get repetitive, **desensitize users**, and fail to improve engagement in the long run." — [Yancey & Settles 2020](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- **Kocielnik & Hsieh 2017, "Send Me a Different Message", CSCW.** Repeated exposure to the same message triggers "can lead to boredom, annoyance and decreased engagement". **Diverse messages** were perceived as motivators rather than simple reminders. Numeric effect sizes were not retrieved. — [academia.edu copy](https://www.academia.edu/59633688/Send_Me_a_Different_Message)
- Base rate of attention: median 56 notifications/day per user, and only ~16% of non-social app notifications lead to opening the app. — [Pielot et al. 2018](https://www.interruptions.net/literature/Pielot-MobileHCI18.pdf)
- **Where reminders may backfire or not help:**
  - (a) **Mood-monitoring studies with reminders had lower adherence and higher attrition.** This is confounded by longer, more burdensome protocols; see Q4. — [Astill Wright et al. 2026](https://mental.jmir.org/2026/1/e83765)
  - (b) **No long-term retention gain** from daily notifications in the Drink Less MRT. — [Bell 2023](https://pmc.ncbi.nlm.nih.gov/articles/PMC10337295)
  - (c) Anti-sedentary prompts had **no detectable effect** in HeartSteps; content matters. — [Klasnja 2019](https://pubmed.ncbi.nlm.nih.gov/30192907/)
  - (d) Users likely disable notifications from non-messaging apps (author speculation). — [Pielot 2018](https://www.interruptions.net/literature/Pielot-MobileHCI18.pdf)

### Inferences
- For one notification per day, the risk of rapid habituation appears modest over a month: two daily-reminder MRTs show no significant decay. HeartSteps decayed with 5 prompts per day, which suggests decay grows with dose. This is an inference from two different designs, not a head-to-head comparison.
- The cheapest documented lever against decay is **content rotation**: a pool of varied messages, never the same one on consecutive days, with recently seen messages demoted. Duolingo found the template choice itself moves conversion only by a few percent (±3.4% for 90% of templates), so rotation matters more than finding the one perfect message.
- Relative effects look biggest where the baseline is low (opening the app in a given hour). For a user who already logs every evening by habit, an evening reminder adds little and may irritate. A plausible design is to send the daily reminder only if today's dot is not yet coloured. This is my inference; it is consistent with the non-significant "already-engaged" moderator in Bell 2023.

### Gaps
- No trial isolated "1 reminder/day vs 0" on D7/D30 retention in a consumer tracker.
- No controlled data beyond 89 days on habituation to a single daily reminder.
- No rigorous data found on the rate at which users disable notifications or uninstall in response to a daily reminder. Only Pielot's speculation and vendor reports are available.

---

## Q4. Evidence specific to mood trackers, journaling apps and EMA daily-prompt compliance

### Takeaway
The only meta-analysis that looks at reminders in mood monitoring is Astill Wright, Torous et al. (2026): 77 studies, 17,123 participants with depression or bipolar disorder. It found **studies with reminders had lower adherence (61% vs 78%) and higher attrition (30% vs 27%)**, likely confounded by longer, heavier protocols. EMA research reaches ~79–82% compliance with prompted assessments, but mostly with paid participants in short studies. No peer-reviewed data exist on reminders in consumer mood apps such as Daylio or Bearable.

### Cited Findings
- **[META] Astill Wright, Roe, Guo, Morriss & Torous 2026, "Dropout, Attrition, Adherence, and Compliance in Mood Monitoring and Ambulatory Assessment Studies for Depression and Bipolar Disorder", JMIR Mental Health 13:e83765 (published 12 Jan 2026).** 77 studies, 17,123 participants. Pooled adherence **0.64 (95% CI 0.59–0.70)**. Pooled attrition **0.28 (0.22–0.34)**. Heterogeneity was very high and there is evidence of publication bias. — [JMIR](https://mental.jmir.org/2026/1/e83765); full text read via [PMC12795494](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12795494/)
- Astill Wright 2026, reminders moderator:
  - "Studies with mood monitoring reminders had **lower adherence (0.61, 95% CI 0.54–0.67)** than studies without (0.78, 95% CI 0.69–0.88; between-group Q=11.25; P=.004)."
  - Attrition was **0.30 with reminders vs 0.27 without** (Q=56.80; P<.001).
  - Authors' caveat: "studies with EMA reminders (n=23) reported a longer mean follow-up duration (mean 11.02, SD 8.5 months) than studies without EMA reminders (n=86; mean 7.48, SD 4.22 months)."
  - Possible explanation offered: "a higher number of notifications and reminders increases participant burden and leads to dropout … or … studies with more burdensome protocols also include reminders."
  - Also: financial incentives raised adherence (0.77 vs 0.65). Digital monitoring had lower attrition than analogue (0.28 vs 0.40). Active and passive monitoring did not differ.

  — [PMC12795494](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC12795494/)
- **[META] Mobile EMA compliance in adults (JMIR 2021, e17023).** Pooled compliance **81.9% (95% CI 79.1–84.4)** over 41 nonclinical and 27 clinical samples. Compliance tracked prompts/day and items/prompt **only in nonclinical samples**. Heterogeneity was high. — [PMC7970161](https://pmc.ncbi.nlm.nih.gov/articles/PMC7970161) / [JMIR PDF](https://jmir.org/2021/3/e17023/PDF)
- **[META] EMA in substance users (Addiction 2019).** Pooled compliance **below the recommended 80%**, and **not associated with prompt frequency or assessment duration**. — [PMC6492133](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC6492133/)
- **[META] EMA in borderline personality disorder (JMIR 2023).** Pooled compliance **79%**, with **no significant relationship between design features and compliance**. — [PMC10131785](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC10131785/)
- **[META] Wrzus & Neubauer 2023, "Ecological momentary assessment: a meta-analysis on designs, samples, and compliance across research fields", Assessment 30(3) (doi 10.1177/10731911211067538).** 477 articles, 496 samples, N=677,536. Examines how schedules relate to compliance and dropout. Pooled figures were not retrieved. — [Heidelberg catalogue record](https://heibib.ub.uni-heidelberg.de/search/Record/1839595345)
- **[Small, retrospective] Mood 24/7 (SMS daily mood prompt).** **97.2% (315/324)** reporting adherence over 36 weeks, but only **9 participants**. It cites prior work with electronic diaries at 94% vs 11% for paper. **Source attribution unverified:** these figures came from a search summary covering [JMIR Mental Health 2020;7(5):e16237](https://mental.jmir.org/2020/5/e16237) and [medRxiv 2023.04.05.23288184](https://medrxiv.org/content/10.1101/2023.04.05.23288184v1.full.txt). Both pages blocked fetching, so check which one holds them before citing. Weak evidence either way.
- **[RCT, reminders not isolated] juli depression app.** 908 randomised. The app prompted users daily at a **time of their choosing** to open the app and log; the trial compares full app vs attention placebo, not reminders, and its adherence results were not retrieved. Same unverified attribution as above; likely the [medRxiv 2023 preprint](https://medrxiv.org/content/10.1101/2023.04.05.23288184v1.full.txt).
- The closest consumer-app analogue with a randomised reminder is Bidargaddi 2018 (workplace well-being app, outcome = self-monitoring of behaviours and **feelings**): +3.9% in 24 h. — [JMIR](https://mhealth.jmir.org/2018/11/e10123/)

### Inferences
- The EMA literature (≈80% compliance with prompted check-ins) is not a valid benchmark for a free consumer app. Those participants are recruited, often paid, and in time-limited studies; Astill Wright found that financial incentives raise adherence.
- The 2026 mood-monitoring meta-analysis is the main warning sign. In mood tracking, reminders sit alongside burden, and burden predicts dropout. For a "one dot a day" app, logging takes seconds, so burden is low. The design response is to keep the reminder single, skippable, guilt-free and actionable in one tap. One-tap logging from the notification is an inference, not tested in these studies.
- Mood-specific concern (inference): a reminder to rate your mood on a bad day can be aversive. No controlled study was found on this. It argues for neutral, non-judgemental copy and an easy "snooze / pause reminders" option.

### Gaps
- **No peer-reviewed or published internal data found for Daylio, Bearable, Pixels/"year in pixels" apps or journaling apps (Day One, etc.) on reminder effects.** Any figures circulating for these apps would be vendor or anecdotal.
- Wrzus & Neubauer pooled compliance and schedule moderators were not retrieved; the full text was inaccessible.
- No RCT found comparing daily mood-log reminders vs none in a consumer mood app.

---

## Q5. What Duolingo's published research says about reminder impact

### Takeaway
Duolingo's KDD 2020 paper optimises *which* daily practice-reminder text to send. It does not measure reminder versus no reminder. On top of a baseline already tuned through years of A/B tests, template selection alone gave **+0.5% DAU** and **+2.2% D1 / +2.0% D7 new-user retention**. The two key mechanisms are a **novelty effect** (fresh templates convert better) and **recovery**: a template's effect returns as the user's memory of it fades, modelled with an exponential half-life. The gains were concentrated in **new users**.

### Cited Findings
- **Yancey & Settles 2020, "A Sleeping, Recovering Bandit Algorithm for Optimizing Recurring Notifications", KDD '20 (doi 10.1145/3394486.3403351).** The algorithm (Recovering Difference Softmax) selects among practice-reminder templates for millions of daily reminders. Abstract: it "lead to a **0.5% increase in total daily active users (DAUs)** and a **2% increase in new user retention** over a strong baseline." — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- Two-week online A/B test results (Table 8; * = significant):

  | Metric | Gain |
  |---|---|
  | DAUs | **+0.5%*** |
  | Total lessons completed | **+0.4%*** |
  | Existing-user D1 retention | **+0.5%*** |
  | Existing-user D7 retention | +0.2% (n.s.) |
  | **New-user D1 retention** | **+2.2%*** |
  | **New-user D7 retention** | **+2.0%*** |

  The authors suggest new users "may be more sensitive to these kinds of optimizations, while their daily interaction with the app is still establishing habitual routines." — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- The control was the legacy policy: uniform random choice among eligible templates, already "optimized through years of A/B tests" ("a strong baseline"). Five months after launch, the bandit's rounds had **2.5% higher reward** than a 5% random holdout. — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- Reward definition: a lesson completed **within 2 hours** of the reminder. This was chosen because "a substantial percentage of our completed lessons are organic: many users will complete a lesson whether we send a notification or not." Average reward under the random policy was **≈0.13**: about 13% of reminders were followed by a lesson within 2 h, including organic lessons. — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- **Novelty and recovery.** "Fresh templates (which have not been recently seen) tend to have higher impact." The recency penalty decays as 0.5^(days since last seen / half-life). Without variation the bandit "will converge to using the same template for a given user day after day, which will get repetitive, desensitize users, and fail to improve engagement in the long run." Reusing the last template cost **0.5%** of reward offline. — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- Template effects are small: for well-estimated templates, **90% of arm scores fall within ±3.4%** relative to the average. Offline, the best policy beat random by **+1.9%** in 2-hour conversion. — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- Example templates carry **eligibility conditions** tied to user state (e.g. "You're on fire. Continue your 109 day Spanish streak" requires a 3+ day streak; streak-wager and travel-motivation templates). — [paper PDF](https://research.duolingo.com/papers/yancey.kdd20.pdf)
- Duolingo's blog confirms that reminder wording is drawn from a pool of pre-written messages. Selection was originally random; a rule was later added to demote recently seen reminders. Duolingo has released ~200M practice-reminder examples (35 days) as replication data. — [Duolingo blog "Hi, it's Duo"](https://blog.duolingo.com/hi-its-duo-the-ai-behind-the-meme/); [Duolingo Research](https://research.duolingo.com/)
- **[ANECDOTE]** Duolingo sends a final "These reminders don't seem to be working. We'll stop sending them for now" message after prolonged non-response. It is widely reported as a meme. I found **no official documentation of the trigger rule or its measured effect**, and some users describe it as guilt-inducing. — [inkl meme roundup](https://inkl.com/news/81-hilariously-threatening-duolingo-memes) (search summary)

### Inferences
- The Duolingo numbers are **incremental lifts from message selection on top of an existing reminder**. They are not the effect of introducing reminders, and should not be quoted as "reminders add +2% retention".
- They do show that, at scale, the **first days** are where reminder quality moves retention (new-user D1/D7 +2%, existing users ~0). This matches Alkhaldi's single-study hint that prompts soon after starting work better.
- For a small app, the transferable ideas are cheap: a pool of varied copy, eligibility rules tied to user state (e.g. a "3 days in a row" line only when true), and never the same line two days running. A learning bandit has no statistical power at ~200 accounts: Duolingo needed 1–5 weeks of data from millions of rounds per template.
- Backing off after sustained non-response limits annoyance and uninstall risk. This is a common practice (Duolingo anecdote), but **unmeasured** in the literature found.

### Gaps
- Duolingo has not published (in sources found) the causal effect of sending practice reminders vs not sending them, nor the effect of its "stop sending" rule.
- The newer Duolingo arXiv work (arXiv 2202.08812 appeared in search results) was not reviewed.
