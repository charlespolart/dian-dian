# Mandatory sign-up at first launch vs deferred ("guest", "lazy", "gradual engagement") account creation: what is measured, and what turns guests into accounts

Scope: published evidence 2007–2026 on (a) the drop-off at a sign-up/log-in wall, (b) experiments that moved sign-up later or removed it, or that added or kept a wall, (c) platform guidance, (d) prompts that convert guests into account holders. Evidence labels used on every finding:
**[PRIMARY]** original data or a company's own account of its own experiment, **[VENDOR]** data or advice from a party with a commercial interest in the answer, **[DOCS]** official platform or SDK documentation (including App Review rules), **[REGULATOR]** regulators or law text, **[COMMENTARY]** blogs, opinion, practitioners without published data, **[SEARCH]** known only from a search snippet (page not read), **[INFERENCE]** my own reasoning.
All pages marked "read" were read on 2026-11-25; [SEARCH] items were seen as snippets on 2026-11-25. Every finding ends with **Transfer:** a one-line judgment of how far it carries to a small, iOS-first, server-synced tracker app sold by subscription (RevenueCat).

---

## Q1. What drop-off is measured at a mandatory sign-up/log-in screen, and where do the repeated statistics come from?

### Takeaway
I found no public, traceable measurement of the share of new mobile-app users who quit at a first-launch sign-up wall. The figures that get repeated come from three places. Some are stated-intention surveys run or paid for by identity vendors (the "86%", "54%", "68%", "64.5%" and "77%" figures). Some are Baymard's checkout survey, where the "site wanted me to create an account" reason is now **18%** and was 24–37% in older rounds. Others are general retention losses that have nothing to do with sign-up but get pinned to it (the "77% gone in 3 days" figure). The only large behavioural measurement found is a 2013 Microsoft Research log study of web registrations. **68% of registrations that were started were not finished**, and completion depended strongly on how much the person wanted the service at that moment.

### Cited Findings

**Behavioural measurement (the only one found)**
- **[PRIMARY] Malheiros & Preibusch, "Sign-Up or Give-Up: Exploring User Drop-Out in Web Service Registration", SOUPS 2013 (Microsoft Research Cambridge).** Data: browsing logs of Internet Explorer users who had consented to recording, Feb–Apr 2013, sampled from >2 billion sessions. 94,992 sessions started a registration for a Microsoft, Google or Yahoo account. Completed vs not: Microsoft 9,300 / 9,702 (1-page form, ≈49% completed); Google 4,155 / 39,424 (phone verification step, ≈9.5%); Yahoo 16,776 / 15,635 (3 pages, ≈52%). Overall ≈31.8% completed (my arithmetic from Table 1). Completion odds varied with the page the person came from. Coming from the Microsoft Office key-activation page gave 3.85× the average odds; coming from plus.google.com gave odds of 0.06. The authors concluded that "users are more likely to complete the registration process when coming from some webpages than others" and that "the more valuable services are more likely to be considered worth the privacy and effort cost". They note that some Google-funnel users may already have had accounts. — [PDF](https://cups.cs.cmu.edu/soups/2013/trustbusters2013/Sign_up_or_Give_up_Malheiros.pdf) (read). **Transfer: medium-low.** It is desktop web from 2013, for big providers, and covers people who had already chosen to start. It does support the mechanism that completion tracks perceived value at that moment, which is exactly what a first-launch wall lacks.

**Stated-intention surveys behind the famous numbers**
- **[VENDOR] Janrain / Blue Research, "Consumer Perceptions of Online Registration and Social Login", October 2011.** Online survey, 619 respondents (616 after quality control), fielded 3–9 Oct 2011. Respondents were screened to be "social media active" and to have bought online or consumed major media online in the past 30 days. Janrain sold social login. — [passwordresearch.com study 114](https://www.passwordresearch.com/stats/study114.html) (read; the findings sit on linked sub-pages, not read). **Transfer: low** (attitudinal, vendor-framed, 2011, web).
- **[SEARCH][VENDOR]** The widely quoted **"86% of users may leave a website when asked to create an account"** is the headline of a Janrain-sponsored infographic. Note "may leave": it is a stated intention, and no methodology is shown on the page. — [Convince & Convert infographic](https://www.convinceandconvert.com/social-media/infographic-86-percent-of-users-may-leave-a-website-when-asked-to-create-an-account/) (snippet). **Transfer: low.**
- **[PRIMARY, citing survey]** The same Blue Research survey is cited by Malheiros & Preibusch: "88% have given incorrect data when registering and 54% may leave if asked to register". Older attitudinal surveys are cited alongside it: Culnan-Milne 2001 (82% have refused to give personal data to a website, 64% decided not to use a website because of the data requested), IFAK 2002 (60% of German users avoided a website over privacy), and Hodder et al. (92% omitted or falsified data). The authors stress that "these studies are all attitudinal surveys; no observation of actual behaviour was conducted." — [PDF](https://cups.cs.cmu.edu/soups/2013/trustbusters2013/Sign_up_or_Give_up_Malheiros.pdf) (read). **Transfer: low** (dated, web, stated).
- **[SEARCH][VENDOR] Identity-vendor surveys, all selling passwordless or social login.**
  - Gigya, 4,000 US consumers: 68% abandoned creating an online account because of complex password requirements.
  - Transmit Security, 600 US consumers: two-thirds would walk away from a complex registration; 64.5% would leave when asked to create a username and password.
  - Ping Identity 2021, five countries: 77% have abandoned or stopped creating an account, citing too much personal information (40%), too much time (33%) or too many security steps (29%).
  - Auth0/YouGov 2021: long login or sign-up forms were a top frustration for 48%.
  
  — [SecureIDNews](https://www.secureidnews.com/news-item/survey-consumers-want-anything-but-passwords/), [IDTechWire](https://idtechwire.com/transmit-survey-shows-consumers-will-abandon-sites-with-bad-password-procedures-033102/), [Business Wire 2021-09-21](https://www.businesswire.com/news/home/20210921005197/en) (403 when fetched) (snippets). **Transfer: low.** These are stated reasons and mostly about password friction. Sign in with Apple and Google already remove most of that friction.

**Baymard's checkout figure (the most-cited "forced registration" number)**
- **[PRIMARY] Baymard, cart-abandonment list (page "Last updated Oct 28, 2026").** Reasons for abandoning during checkout, excluding the "just browsing" segment (42% of US online shoppers say "I was just browsing / not ready to buy"):
  - 40% extra costs
  - 20% delivery too slow
  - 19% didn't trust the site with the card
  - **18% "The site wanted me to create an account"**
  - 17% "Too long / complicated checkout process"
  
  Multiple answers were allowed (the items sum to ≈182%). The page does not give the question wording or sample size; it links to study GC050. — [baymard.com/lists/cart-abandonment-rate](https://baymard.com/lists/cart-abandonment-rate) (read). **Transfer: low.** Shoppers here already intend to buy and have a guest-checkout alternative in mind, and the figure is a stated reason, not a measured drop-off.
- **[PRIMARY] Baymard "How to Reduce Cart Abandonment" (updated 2 Nov 2026):** "18% of users abandon a checkout if they're forced to create an account" — no sample, date or wording given on that page. — [baymard.com/blog/reduce-cart-abandonment](https://baymard.com/blog/reduce-cart-abandonment) (read).
- **[SEARCH]** Earlier values of the same Baymard reason:
  - 19% in a survey of 1,026 US adults (Checkout UX 2025 per snippet; the page I read, updated 3 Nov 2026, no longer shows an account figure).
  - "24 to 26%" in the 2021–22 and later rounds. A blog notes this "comes from Baymard's older survey rounds and is no longer the published figure".
  - 37% in a 2017 Baymard report commissioned by Amazon Pay.
  
  — [Baymard Checkout UX](https://baymard.com/blog/current-state-of-checkout-ux) (read; no account figure present), [clapback.run](https://clapback.run/blog/why-users-abandon-signup) (read, [COMMENTARY]), [Amazon Pay blog](https://pay.amazon.com/blog/the-baymard-report-series-how-forcing-sign-ups-drives-down-sales) (snippet; Amazon Pay sells guest payment, so [VENDOR]). **Transfer: low.** Any "24%", "26%", "28%", "34%" or "37%" quoted today is an older round of the same stated-reason checkout survey.

**Numbers that are misattributed or have no traceable source**
- **[SEARCH] "77% of users abandon an app within 3 days".** The origin is Andrew Chen's blog post (≈2015) using Quettra data: the average Android app with >10k downloads loses 77% of its DAUs within 3 days of install, 90% within 30 days and >95% within 90 days. It is about overall usage decay, **not about sign-up screens**. One 2025 blog attributes it to "App Annie 2025". — [andrewchen.com](https://andrewchen.com/new-data-shows-why-losing-80-of-your-mobile-users-is-normal/) (snippet), [mobileproductstudio.com](https://mobileproductstudio.com/77-app-abandonment-fix-2025-onboarding-now/) (snippet). **Transfer: useful only as a decay baseline.**
- **[SEARCH] No traceable source found for:**
  - "75% of users abandon when required to sign up before seeing value"
  - "60–80% lost during signup"
  - "over 60% of users who start account creation don't finish"
  - "15.6% abandon because of a cumbersome registration"
  - "10–40% email-verification drop-off" (a blog says this range comes from email-verification vendors)
  
  — [clapback.run](https://clapback.run/blog/why-users-abandon-signup) (read), search summaries of [setgreet.com](https://www.setgreet.com/blog/the-75-drop-off-crisis-why-your-mobile-app-is-bleeding-users-at-the-worst-possible-moment), [saasfactor.co](https://www.saasfactor.co/blogs/why-users-drop-off-during-onboarding-and-how-to-fix-it). **Transfer: none** (treat as folklore).
- **[COMMENTARY]** A 2025–26 blog states plainly that no rigorous public study quantifies how many users abandon at the sign-up wall, and that checkout data is only "the closest measured proxy". — [clapback.run](https://clapback.run/blog/why-users-abandon-signup) (read).

### Inferences
- [INFERENCE] The honest answer to "how many people bounce at a login screen" is: unknown in public data for mobile apps, plausibly large, and highly dependent on how much the person already wants the app. Malheiros' 9.5% vs 52% completion by provider, and the 3.85× vs 0.06 odds by referrer, show how wide that range is.
- [INFERENCE] The app can measure its own number instead of borrowing one. Take first-time downloads (App Store Connect / Play Console) over a period and divide accounts created in the same period by them. That gives install→account. Today's "100 free sign-ups" denominator starts *after* the wall, so the wall's cost is currently invisible in the app's funnel.

---

## Q2. Duolingo's deferred sign-up: what exactly was published?

### Takeaway
The only first-hand numbers come from Duolingo's former VP of Growth, Gina Gotthilf, in interviews. The written one is First Round Review (July 2017) and the spoken one is the Inside Intercom podcast (April 2018). Moving the sign-up screen "back a few steps" gave **about +20% DAU**. Later, dismissible "soft walls" placed before an eventual **hard wall after several lessons** gave **+8.2% DAU**. She also said the hard wall performs significantly worse without the soft walls before it. Duolingo did not remove the account requirement; it deferred it, primed it, and still enforces it. The often-repeated "+20% next-day retention" and "12% next-day retention in 2012" figures appear only in secondary blogs. No sample sizes, test dates, confidence intervals or written Duolingo publication were found.

### Cited Findings
- **[PRIMARY — insider interview, no methodology] First Round Review, "The Tenets of A/B Testing from Duolingo's Master Growth Hacker", 17 July 2017.** Gina Gotthilf, VP of Growth, with PM Kai Loh.
  - "Simply moving the sign-up screen back a few steps led to about a 20% increase in DAUs."
  - On the old sign-up screen, "There was a big red button at the bottom of the screen that said 'Discard my progress'". Replacing it with a subtle "Later" button moved the metric (no figure given).
  - That change "introduced 'soft walls' — that is, optional pages that ask users to sign up, but allow them to keep going by hitting 'Later'". There were later three soft walls.
  - "there's a hard wall, after several lessons, that basically says if you want to move forward, you have to sign up."
  - "without those soft walls priming a sign-up as they're ignored, those hard walls perform significantly worse."
  - The soft-wall work "yielded an 8.2% increase in DAUs", run "about three years after the original test, so our user base was much larger."
  - The test dates are not given.
  
  — [review.firstround.com](https://review.firstround.com/the-tenets-of-a-b-testing-from-duolingos-master-growth-hacker/) (read). **Transfer: medium on direction, low on size.** DAU is a company-wide metric for a free app with huge top-of-funnel traffic, and the tested pattern was "defer + prompt + eventually require", not "never require".
- **[PRIMARY — insider podcast] Inside Intercom, "Gina Gotthilf on growing Duolingo to 200 million users", 5 April 2018.**
  - "by letting people actually use Duolingo a little bit without signing up... we got a much better conversion rate."
  - Variants tested: "not making people sign up until a much later period", and "asking them to sign up one time or two times or three times, and letting them dismiss the message".
  - The original prompt was "Do you want to save your progress or discard your progress?"
  - "Just making people see this thing that says 'Hey, want to sign up?' and then, if the answer was no, letting them do it later was super successful."
  - "Daily active users was our non-bullshit metric."
  - No numbers on sign-up in this episode.
  
  — [intercom.com](https://www.intercom.com/blog/podcasts/gina-gotthilf-growth-duolingo/) (read). **Transfer: medium.** It confirms the conversion metric was sign-up conversion, with DAU as the guardrail.
- **[SEARCH] The "+20% next-day retention" version.** A gamification blog says that in 2012 Duolingo's next-day retention was "just 12%", and that moving sign-up after the test lesson produced "a huge 20% jump in next-day user retention". No primary source was found. The primary figure is ≈20% **DAU**. — [StriveCloud](https://www.strivecloud.io/blog/gamification-examples-boost-user-retention-duolingo) (snippet). **Transfer: do not cite as Duolingo data.**
- **[COMMENTARY] Current flow (third-party teardown, published 23 May 2026, updated 8 Jul 2026).**
  - Screen order: goal questions → placement → first lesson → "1-day streak!" celebration → account creation at screen 13.
  - Copy: "Save your progress! Sign up.", with Apple, Google and email options.
  - Whether the step can be skipped is not stated.
  - The same page claims deferring apps see "30-50% better" first-session completion, with no source.
  
  — [gummble.com](https://gummble.com/blog/duolingo-onboarding-flow-analysis) (read). **Transfer: medium** as a pattern reference (the "first lesson" analogue in a tracker is creating a tracker and colouring the first day).
- **[SEARCH] Appcues GoodUX teardown:** "as users complete lessons, they are given periodic prompts to create an account". — [goodux.appcues.com](https://goodux.appcues.com/blog/duolingo-user-onboarding) (snippet).
- **[SEARCH]** Searches of Duolingo's S-1 (2021), its investor pages, von Ahn interviews (Acquired, Eric Ries) and Lenny's Newsletter did not surface any passage on sign-up timing. — [SEC S-1](https://www.sec.gov/Archives/edgar/data/1562088/000162828021013065/duolingos-1.htm) (snippet only), [Acquired](https://www.acquired.fm/acq2-episodes/why-duolingo-worked-with-luis-von-ahn-ceo) (snippet).

### Inferences
- [INFERENCE] "Duolingo proves you should drop the login wall" is an over-reading. What was reported is that a later, primed, dismissible ask beat an immediate one on DAU, and that Duolingo still makes the account mandatory after a few lessons.
- [INFERENCE] The copy finding (a scary "Discard my progress" button vs a soft "Later") suggests that the framing of a prompt can matter about as much as its position.

---

## Q3. Other published tests of moving sign-up later, removing it, or adding/keeping a wall

### Takeaway
Evidence **for deferring** is consistent in direction but thin in rigour. There is Duolingo (Q2), a 2009 e-commerce case where removing forced registration lifted purchases by 45%, and agency or vendor portfolio claims of +15–30%. Evidence **for a wall** also exists. Secret Escapes (via Optimizely, 2015) found that making sign-up mandatory more than doubled sign-ups without hurting reviews, and improved LTV:CAC. Its business runs on e-mailing members. A 2014 Pinterest Engineering post (seen only as a snippet) reported that extra sign-ups pushed by modals retained worse over time. That is a warning that "more sign-ups" and "better users" can diverge. In subscription apps, gating early with a *hard paywall* converts more downloads to paid at day 35, but the cause is partly who installs those apps. No published test was found for Airbnb, Headspace, Calm, Noom, Strava, Fabulous, Tinder or Spotify.

### Cited Findings

**Deferring or removing the wall helped**
- **[PRIMARY, unaudited consultant report] Jared Spool, "The $300 Million Button", 14 Jan 2009.** An unnamed "$25 billion retailer" had a login form with Login/Register before payment. They replaced Register with Continue and the line "You do not need to create an account to make purchases on our site". Results:
  - customers purchasing +45%
  - ≈$15M extra in the first month, ≈$300M in the first year
  - 45% of customers had multiple accounts (some up to 10)
  - ≈160,000 password resets per day
  - 75% of those who requested a password never completed a purchase
  
  — [articles.centercentre.com](https://articles.centercentre.com/three_hund_million_button/) (read). **Transfer: low-medium.** It is checkout with purchase intent, and much of the cost came from forgotten passwords of returning users, which Sign in with Apple and Google largely remove.
- **[COMMENTARY] Twitter 2010, reported by Luke Wroblewski (16 June 2010).** "Though the new sign-up process added one more screen, conversions went up 29%". The added screen was a topic picker shown *after* account creation. This is **not** a deferred-sign-up test, yet it is cited that way. A UX course says "delaying registration can boost signups by 29%" ([SEARCH], [Uxcel](https://app.uxcel.com/courses/mobile-design/onboarding-734/allow-users-to-preview-app-content-before-signing-up-2671)). — [articles.centercentre.com/?p=223](https://articles.centercentre.com/?p=223) (read). **Transfer: none for this question;** it is a misattributed statistic.
- **[SEARCH][COMMENTARY] Agency and vendor claims, no data shown.**
  - Vmobify: "removing a single forced step before value — most often the sign-up wall — moves D1 retention by 15-30% on its own".
  - Opendoor Digital: lazy registration "consistently outperforms upfront registration by 15-25% in conversion rate".
  - Affective: "On products like a gifting platform and a sports second-hand marketplace, deferring login produced higher sign-up rates overall".
  
  — [vmobify.com](https://vmobify.com/blog/app-onboarding-best-practices), [opendoordigital.dev](https://opendoordigital.dev/blog/mobile-app-onboarding-ux), [weareaffective.com](https://weareaffective.com/learning-centre/should-my-app-require-sign-up-before-users-can-explore-features) (snippets). **Transfer: low** (self-reported portfolios, no method).

**Wall kept or added helped (or deferral had a cost)**
- **[VENDOR] Secret Escapes × Optimizely, iOS, 2015.** "A/B tested a mandatory-signup onboarding versus a skippable flow".
  - "The mandatory gate more than doubled signups", with no negative effect on app reviews.
  - It "improved the LTV:CAC ratio to make paid mobile marketing profitable".
  - The GM said: "If the skip button was part of the onboarding flow, we would not be able to do paid marketing on mobile."
  - No raw numbers, sample or duration. The original Optimizely post (URL dated 27 May 2015) returns 404; a mirror was read.
  
  — [casestudies.com mirror](https://www.casestudies.com/company/optimizely/case-study/secret-escapes-increases-mobile-customer-ltv) (read), [original URL](https://www.optimizely.com/2015/05/27/increase-lifetime-value-signup-mobile/) (404). **Transfer: low-medium.** Secret Escapes is a members-only flash-sale travel club whose revenue depends on e-mailing members, so the account *is* the marketing channel. A tracker's revenue depends on in-app use, but the "identity enables re-engagement and attribution" logic partly applies.
- **[SEARCH] Pinterest Engineering, "Lessons in growth and increasing signups" (2014).** Contextual sign-up modals for logged-out visitors were tested. Per the snippet, "signup retention for the modal variants started out close but diverged over time, with the treatment group retaining worse", and early sign-ups in an experiment "are often users who were likely to join … regardless". — [medium.com/@Pinterest_Engineering](https://medium.com/@Pinterest_Engineering/lessons-in-growth-and-increasing-signups-d6e7d8fef479) (403 when fetched; snippet only). **Transfer: medium** as a caution: a variant that wins on sign-ups can lose on retention.
- **[SEARCH] Jeff Chang (Pinterest growth).** Optimising sign-ups alone "produced a large number of duplicate signups"; "every unauth experiment should measure both signup and login changes". — [jeff-chang blog](https://jeff-chang-xbdf.squarespace.com/blog/2018/4/22/scaling-new-growth-opportunities-series-signup-and-login-basics-5rt34) (snippet). **Transfer: medium** (measure returning-user login too, not only new accounts).
- **[PRIMARY] Duolingo's own hard wall after several lessons still exists**, and soft walls make it perform better (see Q2). — [First Round](https://review.firstround.com/the-tenets-of-a-b-testing-from-duolingos-master-growth-hacker/) (read).
- **[SEARCH][VENDOR] RevenueCat State of Subscription Apps (adjacent: the gate is payment, not an account).**
  - 2025 report: hard-paywall apps have a median day-35 download-to-paid of **12.1% vs 2.2%** for freemium.
  - 2026 edition: 10.7% vs 2.1%.
  - Annual-plan retention after a year is similar (27% hard vs 28% freemium).
  - A secondary write-up gives a median refund rate of 5.8% vs 3.4%.
  
  — [RevenueCat SOSA 2025](https://revenuecat.com/state-of-subscription-apps-2025), [RevenueCat 2026 trends](https://revenuecat.com/blog/growth/subscription-app-trends-benchmarks-2026), [airbridge.io](https://www.airbridge.io/en/blog/hard-paywall-vs-freemium-2026) (snippets). **Transfer: low-medium.** It shows that an early gate does not mechanically kill monetisation in subscription apps, but category and audience self-selection are confounded with the gate.
- **[SEARCH][COMMENTARY]** A practitioner reports that requiring an e-mail before a desktop download raised total accounts but not activated or paying users. — [sandydiao.substack.com comments](https://sandydiao.substack.com/p/how-the-ai-growth-funnel-is-changing/comments) (snippet). Another blog warns that guest mode "wins first impressions but can lose long-term retention if you never convert those users". — [gtstu.com](https://gtstu.com/app-login-required-or-guest-mode/) (snippet). **Transfer: low** (anecdotal).

**What apps actually do (descriptive)**
- **[PRIMARY, small descriptive] Lazyweb Research, July 2026.**
  - "Only 38 of 129 onboarding flows include a detected auth screen", from ~800 tracked apps.
  - Of 17 flows with both a paywall and an auth screen, 16 put the paywall after account creation and 1 before.
  - Detection relies on screen labels and "can miss unlabeled auth screens".
  
  — [design.lazyweb.com](https://design.lazyweb.com/blog/do-apps-paywall-before-or-after-account-creation) (read). **Transfer: medium** as market practice. Most captured onboardings contain no account step at all; among apps that ask for both, account usually comes before the paywall.
- **[SEARCH] Calm's flow** (Appcues GoodUX teardown): personalisation questions → sign-up screen → trial. No test published. — [goodux.appcues.com](https://goodux.appcues.com/blog/calm-app-new-user-experience) (snippet).

### Inferences
- [INFERENCE] The pro-wall cases share one feature: the account itself carries the business, through e-mail marketing (Secret Escapes), social graph and spend (Facebook-connected games, Q8), or paid acquisition attribution. The pro-deferral cases share another: the product can show its value in the first minute (Duolingo lesson, shopping). A pixel tracker sits in between. It can show value in seconds (colour today's cell), but the value it stores grows over months, which makes "save your year" a natural reason to create an account later.
- [INFERENCE] Neither direction has a published, controlled result for a small subscription utility. The strongest general warning is the Pinterest/Jeff Chang one: judge any change on install→activation→D7→purchase, not on accounts created.
- [INFERENCE] With ~195 accounts the app cannot power an A/B test on purchases. Detecting install→first-entry going from 50% to 60% needs ≈385 installs per arm (α=.05, power .8). A purchase-rate change of a fraction of a point would need tens of thousands of installs. A before/after comparison of install→account→D7 is the realistic measurement.

---

## Q4. Luke Wroblewski, Nielsen Norman Group, Baymard: what they say, and the transfer limits

### Takeaway
LukeW (2008) coined the "gradual engagement" argument: let people use the service first and make sign-up an outcome of use. He backs it with examples, not controlled data. NN/g (2014) reports, from qualitative usability testing, that users are "rarely … more annoyed" than at a login wall. It says walls are justified for highly personal apps (e-mail, banking) and recommends the reciprocity principle. The study NN/g cites for reciprocity (Gamberini 2007) found that the form-first condition got **more** submissions, while the value-first condition got **more information**. Baymard's checkout research puts forced account creation as an 18% stated reason for abandoning. It recommends offering account creation on the confirmation page, which "performed better" in its qualitative testing. All three are web or checkout research and transfer only partly to a first-launch app screen.

### Cited Findings
- **[COMMENTARY] Luke Wroblewski, "Sign Up Forms Must Die", A List Apart, 5 May 2008** (excerpt of *Web Form Design: Filling in the Blanks*, Rosenfeld Media 2008).
  - Jumpcut example: "you learned what Jumpcut does, and you did it without having to jump through a sign-up form. That's gradual engagement."
  - Other examples: Geni (build a family tree first; "five million profiles in five months") and TripIt (forward an e-mail, get an itinerary, no form).
  - He warns that splitting a form across pages is not gradual engagement.
  - No conversion data.
  
  — [alistapart.com](https://alistapart.com/article/signupforms/) (read); slides "let people use it right away; sign-up as an outcome" — [static.lukew.com PDF](https://static.lukew.com/WebForms_LukeW_101209.pdf) (snippet). **Transfer: medium** as a design principle, **none** as evidence of size.
- **[COMMENTARY — qualitative usability findings, no data published] NN/g, Raluca Budiu, "Login Walls Stop Users in Their Tracks", 2 March 2014.**
  - "In our many usability tests, we rarely have seen users more annoyed than when they come across a login wall."
  - Login walls "require a significant interaction cost".
  - "Applications that are highly personal (such as email or banking apps) are justified in raising login walls".
  - Walls are "a nuisance on sites that people visit only rarely".
  - Section heading: login walls "Don't Belong in the Initial Experience".
  - No sample sizes or statistics.
  
  — [nngroup.com/articles/login-walls](https://www.nngroup.com/articles/login-walls/) (read). **Transfer: medium.** A daily tracker is "highly personal" and used daily, which is the case NN/g itself carves out as more defensible, but the first-run experience is still the weak point.
- **[COMMENTARY] NN/g, Raluca Budiu, "The Reciprocity Principle", 16 Feb 2014.**
  - Apps "require users to cross login walls"; "Starting the initial experience with requests of any kind puts the load onto the user."
  - On Gamberini et al. 2007: "Users gave out more information in the contact form in the reciprocity condition than in the reward condition. They were, however, more likely to submit the form in the reward condition."
  
  — [nngroup.com/articles/reciprocity-principle](https://www.nngroup.com/articles/reciprocity-principle/) (read). NN/g also has a video, "Reciprocation: Why Login Walls Aren't Always 'Better'" ([SEARCH], [nngroup.com/videos/reciprocation-vs-reward](https://www.nngroup.com/videos/reciprocation-vs-reward/)). **Transfer: medium.** The fact that the wall gets more submissions is a genuine counter-point.
- **[PRIMARY] Baymard, "Delayed account creation", Edward Scott, 19 Sep 2023.**
  - "42% of sites ask users to create an account at the beginning of checkout or before users have placed their order."
  - Early interruption "was observed to cause some participants to hesitate and stop their progression".
  - Offering it at the confirmation step "performed better than presenting the invitation at either the outset of or during the checkout process", and "may also increase users' willingness to create an account" because the fields are already filled.
  - No uptake percentages.
  
  — [baymard.com/blog/delayed-account-creation](https://baymard.com/blog/delayed-account-creation) (read). **Transfer: medium** for *where* to ask (right after the user has done the valuable thing), **low** for figures.
- **[PRIMARY] Baymard Checkout UX (published 13 Nov 2024, updated 3 Nov 2026).** 17% have abandoned a checkout in the past 3 months because it was "too long or complex" (survey of "over 1,000 shoppers"). Related-article headings in the page's list read "Save Account Creation for the Confirmation Step (56% Don't)" and "Make 'Guest Checkout' the Most Prominent Option (47% Don't)". — [baymard.com/blog/current-state-of-checkout-ux](https://baymard.com/blog/current-state-of-checkout-ux) (read). Forced-account figure 18% (Oct 2026): see Q1.
- **Transfer limits ([INFERENCE]).**
  - A checkout user already wants the product and only resists the *extra* step, with a known guest alternative.
  - An app first-launch user has invested only a download and does not yet know the value.
  - A web content wall interrupts a reader who arrived for one page.
  - None of these measures a person who installed a tracker on purpose. That person is probably *more* willing than a web visitor but *less* than a shopper with a full cart.

---

## Q5. Platform guidance (Apple, Google/Android, Firebase, RevenueCat SDK)

### Takeaway
Apple is explicit in three places. The HIG says "Delay sign-in for as long as possible" because "people often abandon apps when they're forced to sign in before they can do anything useful". It says to ask for an account "only if your core functionality requires it". For commerce, it says to ask for the account *after* the purchase. App Review rule 5.1.1(v) says: "If your app doesn't include significant account-based features, let people use it without a login." Google's Android onboarding pattern calls authentication "often the most abandoned" journey and says to "show the value of the app before asking … to create an account". Firebase and RevenueCat document the mechanics of guest-then-link, but give no outcome data. A guest who buys before signing in has limits: no cross-platform entitlement, and a new anonymous ID after reinstall.

### Cited Findings

**Apple**
- **[DOCS] Apple HIG, "Managing accounts"** (no change log shown).
  - Ask for an account only when needed: "Ask people to create an account only if your core functionality requires it; otherwise, let people enjoy your app or game without one."
  - Explain why: "**Explain the benefits of creating an account and how to sign up.** If your app or game requires an account, write a brief, friendly description of the reasons for the requirement and its benefits."
  - Delay sign-in: "**Delay sign-in for as long as possible.** People often abandon apps when they're forced to sign in before they can do anything useful. To help avoid this situation, give people a chance to get a sense of what your app or game does before asking them to make a commitment to it. For example, a shopping app might let people browse as much as they want, requiring sign-in only when they're ready to make a purchase."
  - Account deletion is also mandatory, and "Billing for an auto-renewable subscription continues through Apple until people cancel the subscription, regardless of whether they delete their account."
  
  — [developer.apple.com HIG managing-accounts](https://developer.apple.com/design/human-interface-guidelines/managing-accounts) (read as .md). **Transfer: high** (direct platform guidance for this app).
- **[DOCS] Apple HIG, "Sign in with Apple"** (change log: 14 Sep 2022).
  - Sign-in for value: "**Ask people to sign in only in exchange for value.** … you might want to tell people that signing in lets them personalize the app experience, access additional features, or synchronize data."
  - Delay sign-in: "**Delay sign-in as long as possible.** People often abandon apps when they're forced to sign in before doing anything useful. Give them a chance to familiarize themselves with your app before making a commitment."
  - Commerce: "**In a commerce app, wait until after people make a purchase before asking them to create an account.** If you support a guest checkout system, give people a quick way to create an account after the transaction completes."
  - Optional data: "**Give people a chance to engage with your app before asking for optional data.**"
  
  — [developer.apple.com HIG sign-in-with-apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple) (read as .md). **Transfer: high.** "Synchronize data" is named as a legitimate value to sell at sign-in.
- **[DOCS] Apple HIG, "Onboarding"** (change log: 10 June 2024; 21 June 2023).
  - "if onboarding is necessary, design a flow that's fast, fun, and optional."
  - "**Prefer letting people experience your app or game before prompting them for ratings or purchases.**"
  - "**Postpone nonessential setup flows or customization steps.**"
  
  — [developer.apple.com HIG onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding) (read as .md). **Transfer: high.**
- **[DOCS] App Store Review Guidelines.**
  - **5.1.1(v) Account Sign-In:** "If your app doesn't include significant account-based features, let people use it without a login. If your app supports account creation, you must also offer account deletion within the app. Apps may not require users to enter personal information to function, except when directly relevant to the core functionality of the app or required by law."
  - **4.8 Login Services:** apps that use third-party or social login for the primary account must also offer an equivalent login that limits data to name and e-mail, lets users keep their e-mail private, and does not collect interactions for advertising without consent. Sign in with Apple meets this.
  - The page's last-updated date was not in the part read.
  
  — [developer.apple.com/app-store/review/guidelines](https://developer.apple.com/app-store/review/guidelines/) (read). **Transfer: high.** Whether server sync counts as a "significant account-based feature" is a reviewer's call. The app's current wall has apparently passed review.
- **[SEARCH] Rejection wording developers report under 5.1.1:** "Apps cannot require user registration prior to allowing access to app content and features that are not associated specifically to the user." One rejected developer was told that registration for non-account features "must be optional". — [Apple Developer Forums 688899](https://developer.apple.com/forums/thread/688899), [731471](https://developer.apple.com/forums/thread/731471) (snippets). **Transfer: medium.** It shows how reviewers apply the rule, but rejections are case by case.

**Google / Android**
- **[DOCS] Android Developers, "Authentication & Onboarding" pattern (mobile).**
  - "User onboarding and authentication are some of the most common user journeys and often the most abandoned and frustrating for users."
  - "Typically you will need to show the value of the app before asking for device permissions or to create an account. Always follow the value proposition with the action."
  - "Consider if your app needs to register users upfront to use or if they can access a certain level of content and features."
  - The "welcome placement" (everything up front) carries "the higher risk of losing users before they experience the app". Contextual onboarding "is best used when you want to provide a preview to entice sign-ups".
  - "Provide a way to skip and resume later, like caching progress."
  - No date shown.
  
  — [developer.android.com/design/ui/mobile/guides/patterns/onboarding](https://developer.android.com/design/ui/mobile/guides/patterns/onboarding) (read). **Transfer: high.**
- **[DOCS] Android Developers, Identity overview.** "Sign-in can be a major source of confusion and app abandonment." "Streamline your signup process and reduce abandonment rates by integrating Sign in with Google during account creation." No statistics. — [developer.android.com/identity](https://developer.android.com/identity) (read). **Transfer: medium.**
- **[DOCS] Wear OS sign-in guidance.**
  - "**For apps requiring sign-in for all functionality:** Immediately present Credential Manager as the first screen to a signed-out user."
  - "**For apps offering functionality without sign-in:** Delay presenting Credential Manager until necessary. Provide as many features as possible without requiring sign-in. When authentication becomes essential, display a 'sign in' button … If sign-in fails, offer the option to skip authentication."
  - Do: "Provide context by asking for sign-in after the user initiates an action." Don't: "Display sign-in without explaining why sign-in is beneficial."
  
  — [developer.android.com Wear sign-in](https://developer.android.com/design/ui/wear/guides/behaviors-and-patterns/sign-in) (read). **Transfer: medium** (watch-specific, but it is Google's clearest written rule).

**Firebase / RevenueCat (mechanics, no outcome data)**
- **[DOCS] Firebase Authentication, anonymous auth (Flutter).** "You can use Firebase Authentication to create and use temporary anonymous accounts" so that "users who haven't yet signed up to your app" can "work with data protected by security rules". "If an anonymous user decides to sign up to your app, you can link their sign-in credentials to the anonymous account." — [firebase.google.com flutter anonymous-auth](https://firebase.google.com/docs/auth/flutter/anonymous-auth) (read as .md). **Transfer: medium** (pattern only; the app has its own backend).
- **[SEARCH][DOCS] Firebase, other pages.**
  - With Identity Platform, automatic clean-up can delete anonymous accounts older than 30 days unless they are linked.
  - Linking fails with "credential already in use" if the credential already belongs to another user, which is the classic "guest has data, but already has an account" conflict.
  
  — [firebase web anonymous-auth](https://firebase.google.com/docs/auth/web/anonymous-auth), [flutter account-linking](https://firebase.google.com/docs/auth/flutter/account-linking) (snippets). **Transfer: medium** (the edge cases any guest→account design must handle).
- **[DOCS] RevenueCat, "Identifying customers".**
  - Without an ID "RevenueCat will generate a new random App User ID (prefixed with `$RCAnonymousID:`)".
  - "Anonymous App User IDs are not able to share subscription status across apps and platforms."
  - After a reinstall, "a new random anonymous App User ID will be generated"; purchases come back through restore.
  - `logIn` from an anonymous user to a **new** ID, or to an existing ID with no anonymous alias, merges the two ("Anonymous ID and Provided ID have CustomerInfo merged"). If the provided ID already has an anonymous alias, "No merge or purchase transfer occurs."
  
  — [revenuecat.com/docs/customers/identifying-customers](https://www.revenuecat.com/docs/customers/identifying-customers) (read as .md). **Transfer: high.** A guest can buy, but an iOS↔Android entitlement and a clean restore need the account, which is a strong reason to ask for the account at or right after purchase.
- **[SEARCH] RevenueCat community, staff answers.** "Calling login before calling those methods will make sure the correct app user ID is used for purchases." Redemption Links are suggested for buy-before-account flows. — [community.revenuecat.com](https://community.revenuecat.com/general-questions-7/user-id-and-restoring-purchases-from-anonymous-id-3792) (snippet). **Transfer: medium.**

### Inferences
- [INFERENCE] The platform owners agree on direction: delay the account, sell it with a concrete benefit (sync, backup), and ask after the valuable action or the purchase. None of them publishes data. "People often abandon apps…" is an assertion in Apple's text, not a cited number.
- [INFERENCE] For a guest mode, the RevenueCat merge rules mean the app should create the account (or call `logIn`) at the paywall success screen or right after it. If a guest who already had an account elsewhere logs into it, the guest's purchase and data need explicit handling.

---

## Q6. Benchmark and analytics vendors: numbers on onboarding drop-off by step, and at the account step

### Takeaway
None of Mixpanel, Amplitude, Branch, AppsFlyer, Adjust, Localytics, UXCam, Userpilot, Adapty or RevenueCat published a benchmark for drop-off *at an account step* that I could find and read. What exists is vendor or agency blog ranges with no source (20–60% lost at an account step). There are also Google's own case studies showing that one-tap sign-in raises sign-ups. Google sells that sign-in, so those are vendor figures, but they matter because they measure friction *inside* the account step. Lenny's 2022 activation survey lists "removing login gate from initial app interactions" as a tactic respondents used, with no measured effect.

### Cited Findings
- **[SEARCH][VENDOR/COMMENTARY] Blog ranges, unsourced.**
  - semnexus: 25–45% drop-off at the account-creation step; a 40–60% loss "when an account is required before users see value"; a 40%+ completion target for deferred account creation.
  - Another page: "over 60% of users drop off during account creation", with no source.
  - A page cites "an Amplitude report" for 36.4% drop-off after the first onboarding screen. I could not verify it.
  
  — [semnexus.com](https://www.semnexus.com/app-onboarding-flow-benchmarks-where-users-drop-off-2026), [uxcam.com drop-off](https://uxcam.com/blog/drop-off-rates/), [getperspective.ai](https://getperspective.ai/blog/consumer-app-onboarding-drop-off-2026-where-new-users-stall) (snippets). **Transfer: low** (no method; one vendor itself says "there's no universal benchmark").
- **[SEARCH][VENDOR] Appcues** defines gradual engagement ("lazy registration") and says registration "should be postponed for as long as possible, usually until the moment users must register in order to progress further". It also says it "isn't for every use case". No numbers. — [appcues.com/blog/gradual-engagement-mobile-app-first-screen](https://appcues.com/blog/gradual-engagement-mobile-app-first-screen) (snippet). **Transfer: medium** (advice only).
- **[COMMENTARY — self-reported survey] Lenny Rachitsky & Yuriy Timen, "What is a good activation rate", 25 Oct 2022.**
  - Overall activation average 34%, median 25% (SaaS average 36%, median 30%).
  - Under "Reducing onboarding friction", respondents list "Removing login gate from initial app interactions" and "Login immediately after sign-up".
  - The only number is an anonymous 20% gain "from fewer onboarding steps".
  - The denominator is users *who completed sign-up*.
  
  — [lennysnewsletter.com](https://www.lennysnewsletter.com/p/what-is-a-good-activation-rate) (read). **Transfer: low-medium.** Note the activation denominator starts after sign-up, the same blind spot as the app's own funnel.
- **[VENDOR] Google Identity case studies (Google sells Sign in with Google / One Tap).**
  - Pinterest added One Tap: "47% increase in Sign Ups (Web/Mobile Web)", "126% increase in Sign Ups (Android)", and +16% / +34% sign-ins. No date.
  - Reddit ([SEARCH]): the button gave +50% sign-ups and One Tap a further +90%, "almost 2X" conversion.
  
  — [developers.google.com Pinterest case](https://developers.google.com/identity/sign-in/case-studies/pinterest) (read), [Reddit case](https://developers.google.com/identity/sign-in/case-studies/reddit) (snippet). **Transfer: medium.** Friction inside the account step is large and reducible. The app already offers Sign in with Apple and Google, so the remaining loss at its wall is more about *timing* than about form friction.
- **[SEARCH][VENDOR] Adjust:** average day-1 retention ≈25% Android, ≈28% iOS (baseline only). — via [optimizely.com glossary / adjust blog](https://www.adjust.com/blog/how-to-build-a-successful-app-onboarding/) (snippet). **Transfer: baseline only.**
- **[VENDOR] Optimizely (Secret Escapes)** and **Facebook (games)**: see Q3 and Q8. Both vendors sell the tool that made the result possible.

---

## Q7. Academic / HCI research: registration as a barrier, reluctance to give an e-mail, privacy at sign-up, social login vs e-mail

### Takeaway
The strongest causal study found is Hill & Shaw (2020/21): 136 natural experiments in which wikis suddenly required a login. Requiring accounts produced a **small increase in account creation** but **reduced contributions from both registered and unregistered users**, mostly the higher-quality ones. Gamberini et al. (2007) found a trade-off: a form *before* access got more submissions, a form *after* access got more information. Malheiros & Preibusch (2013) measured that most started web registrations are abandoned, more so when the service is valued less. A CHI 2020 experiment found people avoid social login for privacy-sensitive apps. I found no peer-reviewed experiment on a first-launch login wall in a consumer mobile app.

### Cited Findings
- **[PRIMARY, quasi-experimental] Benjamin Mako Hill & Aaron Shaw, "The Hidden Costs of Requiring Accounts: Quasi-Experimental Evidence From Peer Production", *Communication Research* 48(6):771–795 (online 2020), doi 10.1177/0093650220910345.**
  - "longitudinal data from 136 natural experiments where would-be contributors to wikis were suddenly required to log in to contribute."
  - "Requiring accounts leads to a small increase in account creation, but reduces both high- and low-quality contributions from registered and unregistered participants."
  - "Although the change deters a large portion of low-quality participation, the vast majority of deterred contributions are of higher quality."
  
  — [UW ResearchWorks record](https://digital.lib.washington.edu/researchworks/items/6d301c05-678d-42bd-ade7-54fe562b06e7/full) (read). An earlier 2015 presentation reportedly found a 20–40% fall in quality contributions ([SEARCH], [meta.wikimedia.org](https://meta.wikimedia.org/wiki/Research:Value_of_IP_Editing)). **Transfer: medium-low.** It concerns public-goods contribution, not a private tracker, but it is the best causal evidence that a login requirement can raise account counts while lowering activity, even among people who already had accounts.
- **[PRIMARY, small, 2007, web] Gamberini, Petrucci, Spoto & Spagnolli, "Embedded Persuasive Strategies to Obtain Visitors' Data: Comparing Reward and Reciprocity in an Amateur, Knowledge-Based Website", PERSUASIVE 2007, LNCS 4744, pp. 187–198.**
  - Reward condition: contact form first, then access to guidelines for managing multimedia files.
  - Reciprocity condition: access first, then the form.
  - Per NN/g: more information was given under reciprocity, but people "were, however, more likely to submit the form in the reward condition".
  - The abstract (snippet) says reciprocity outperformed on "amount and type" of contact information. Social proof (visitor counters) appeared to hurt compliance under reciprocity and help under reward.
  
  — [Springer chapter](https://link.springer.com/chapter/10.1007/978-3-540-77006-0_24) (snippet), [NN/g summary](https://www.nngroup.com/articles/reciprocity-principle/) (read). **Transfer: medium.** It is the cleanest picture of the trade-off: a wall gets more sign-ups, while value first gets more willing and fuller sign-ups.
- **[PRIMARY] Malheiros & Preibusch 2013** (Q1): 68% of started web registrations were abandoned, with large variation by perceived value of the service. They cite the attitudinal surveys (88% gave incorrect data, 54% may leave, 82% refused data). — [PDF](https://cups.cs.cmu.edu/soups/2013/trustbusters2013/Sign_up_or_Give_up_Malheiros.pdf) (read).
- **[PRIMARY, via university press release] Eugene Cho, S. Shyam Sundar & Jinyoung Kim, CHI 2020 (Penn State).**
  - Online experiment, 364 participants, randomly assigned to sign-up pages for four relationship apps of rising sensitivity (school reunion, serious matchmaking, hook-up, affair).
  - Options were three social single sign-on buttons or e-mail / a new account.
  - People used Facebook login for the reunion and matchmaking apps but avoided it for the affair app. "The tendency to avoid using Facebook ID for affair apps was significantly higher" among those with less faith in online security, because "They seemed to be wary of potential leakage of data from these apps to their social networks."
  - Health apps were not tested.
  
  — [psu.edu news](https://www.psu.edu/news/research/story/privacy-worries-prevent-use-social-media-account-signing-apps) (read). **Transfer: medium.** Mood and sleep data are sensitive. A login that can hide the e-mail (Sign in with Apple private relay) or no login at all may matter more here than for a generic utility.
- **[SEARCH][VENDOR] Janrain/Blue Research 2011:** 77% of consumers favoured social login over traditional registration. — [howstuffworks summary](https://computer.howstuffworks.com/internet/social-networking/networks/facebook-google-single-sign-on.htm) (snippet). **Transfer: low.**
- **[SEARCH] No randomized trial of "mandatory vs optional registration" in a health app or web intervention was found.**
  - The closest is MoodGYM: a randomized test of testimonials on the registration page found ≈45% registration across conditions.
  - Another study compared open-access and trial users of a web activity programme. Median lifetime use was 0 days for open-access registrants vs 290 days for trial participants, but the recruitment routes differ, so registration is not isolated.
  
  — [PubMed 29942614](https://pubmed.ncbi.nlm.nih.gov/29942614), [PMC3838478](https://pmc.ncbi.nlm.nih.gov/articles/PMC3838478/) (snippets). **Transfer: low.**

---

## Q8. Guest-to-account conversion: what share of guests create an account, and what prompts work

### Takeaway
Published numbers are scarce.
- **Duolingo** reports that repeated dismissible "save your progress" prompts, followed by a hard wall after several lessons, beat both the immediate wall and the hard wall alone (+8.2% DAU). It gave no guest-to-account percentage.
- **Facebook's 2013 games data** is the only cross-app set of "share of guests who connected an account", ranging from **15% to 79% of players**. Connected players retained and spent far more, but that is correlational and comes from the vendor selling the login.
- **Apple and Baymard** both say the best moment for commerce is right after the purchase, on the confirmation screen.

I found no published numbers for "back up your data after N entries", "install on a second device" or progress-milestone prompts in utility or tracker apps.

### Cited Findings
- **[PRIMARY — insider interview] Duolingo.**
  - The original prompt was "Do you want to save your progress or discard your progress?"
  - Replacing a big red "Discard my progress" with a subtle "Later" helped.
  - Three soft walls ("Later" allowed) came before a hard wall after several lessons, and the hard wall performs "significantly worse" without them.
  - The soft walls gave +8.2% DAU.
  - Today's copy (third-party teardown): "Save your progress! Sign up." shown after the first lesson and the "1-day streak!" screen.
  
  — [First Round 2017](https://review.firstround.com/the-tenets-of-a-b-testing-from-duolingos-master-growth-hacker/), [Intercom 2018](https://www.intercom.com/blog/podcasts/gina-gotthilf-growth-duolingo/), [gummble.com 2026](https://gummble.com/blog/duolingo-onboarding-flow-analysis) (all read). **Transfer: medium-high** for the prompt pattern (progress framing, dismissible, repeated, then required at a meaningful point). **Low** for figures.
- **[VENDOR, correlational] Facebook for Developers, "The Value of a Facebook Login User for Mobile Games", 24 Jan 2013.** Share of players who connected, in games that also offered guest mode:
  - *Are You Smarter Than a 5th Grader?*: "52% of players are connected to Facebook vs. 48% in guest mode"
  - *Family Feud & Friends*: "63% of daily players connect"
  - *Slots Journey*: "15% of … iOS daily active users"
  - *TopEleven*: 78% Android / 79% iOS
  - *Diamond Dash*: from 28% (Dec 2011) to 70%
  
  Outcomes reported for connected players:
  - *Family Feud*: "retention of Facebook users is double the retention of those who sign in with guest mode"
  - *Slots Journey*: "7-day retention rate is 322% higher"
  - *TopEleven* (iOS): "4.3 times more likely to become payers"
  - *Dragonplay*: "274% more likely to convert to a paying user"
  
  How and when the prompt was shown is not described. — [developers.facebook.com](https://developers.facebook.com/blog/post/2013/01/24/the-value-of-a-facebook-login-user-for-mobile-games/) (read). **Transfer: low-medium.** It shows guest→account rates vary widely with incentive and prompt (15–79%), and that account holders are the engaged, paying minority. Self-selection explains much of the gap: engaged players connect, rather than connecting making them engaged.
- **[SEARCH] Game publishers' help pages** frame guest progress as device-local and the account as how you "save your progress" across devices or on device change (Call of Duty: Mobile, EA FC Mobile). This "save your progress" framing is the industry norm. — [CoD Mobile help](https://activision.helpshift.com/hc/en/3-cod-mobile/faq/233-i-play-on-a-guest-account-do-i-need-to-link-an-account/), [EA help](https://help.ea.com/en/articles/ea-sports-fc/fc-mobile/save-your-progress/) (snippets). **Transfer: medium** (close analogue: a year of pixels is "progress").
- **[DOCS] Apple HIG (commerce):** "wait until after people make a purchase before asking them to create an account … give people a quick way to create an account after the transaction completes." — [HIG Sign in with Apple](https://developer.apple.com/design/human-interface-guidelines/sign-in-with-apple) (read). **[PRIMARY] Baymard:** a confirmation-step invitation "performed better than presenting the invitation at either the outset of or during the checkout process" (qualitative, no uptake %). — [baymard.com](https://baymard.com/blog/delayed-account-creation) (read). **Transfer: high** for the "account at purchase" trigger, given RevenueCat's cross-platform limits for anonymous users.
- **[DOCS] Android:** "Provide a way to skip and resume later, like caching progress. Providing a way to save creates a checkpoint … Always clearly communicate what will happen with any progress to reassure users." — [developer.android.com onboarding pattern](https://developer.android.com/design/ui/mobile/guides/patterns/onboarding) (read). **Transfer: medium.**
- **[SEARCH][VENDOR] E-commerce post-purchase account creation** "30–40% when the invitation is well-positioned", with no traceable source. — search summary of [ecomhint.com](https://ecomhint.com/blog/guest-checkout-vs-account-creation) and similar. **Transfer: low.**

### Inferences
- [INFERENCE] The app's own numbers point to the trigger that is easiest to defend. 8 of 9 purchases happen within 51 hours of sign-up, so purchasers decide early. If guests are allowed, an account prompt at the purchase-success moment would capture almost all buyers, because RevenueCat needs an identified user for iOS↔Android entitlement and clean restores. The remaining non-buyers are the population where a guest mode trades fewer bounces for fewer identities.
- [INFERENCE] For non-buyers, the candidate triggers are untested in public data but follow the documented patterns (Duolingo progress framing, Android "checkpoint", Apple "synchronize data" as the stated benefit):
  - after the first week of entries ("back up your week")
  - when opening the app on a second device
  - before enabling a feature that needs the server (sync, sharing)
  - a gentle recurring "your data lives only on this phone" notice
- [INFERENCE] Owner's question on premium conversion. The evidence that a first-launch wall *raises* premium conversion is weak and comes from different business models: Secret Escapes is e-mail-driven, Facebook connect is correlational, and hard-paywall apps differ in audience. The evidence that it *loses* people before they see value is consistent in direction but not in size. With 19 of 100 free sign-ups still logging after day 7, the people who pass the wall already retain in a normal range. Chen/Quettra put the average Android app at ~23% of DAUs left at day 3, though that metric differs. So the unknown is how many never pass the wall, which is measurable from store download counts (Q1 inference).
- [INFERENCE] A guest mode brings costs that the published "wins" do not show:
  - data loss when a guest deletes the app or changes phone (a severe failure for a year-long tracker)
  - merge conflicts when a guest later signs into an existing account (Firebase "credential already in use"; RevenueCat "no merge" case)
  - smaller identifiable audiences for e-mail re-engagement
  
  Duolingo's eventual hard wall and Secret Escapes' result are consistent with these costs being real.

---

## Gaps / could not verify
- **No public measurement** of the share of new users lost at a first-launch login wall in consumer mobile apps; all mobile-specific percentages found were unsourced vendor or agency blog figures.
- **Duolingo:**
  - No written Duolingo publication (blog, S-1, shareholder letter, research paper) with the sign-up timing result was found.
  - The 20% DAU and 8.2% DAU figures come only from interviews, with no test dates, sample sizes, intervals, or effect on paid conversion.
  - The "+20% next-day retention" and "12% next-day retention in 2012" figures could not be traced to a primary source.
  - A Lenny's Podcast episode with Gina Gotthilf exists, but its transcript was not checked.
- **Pinterest 2014 Engineering post** ("Lessons in growth and increasing signups"): Medium returned 403 and archive.org could not be fetched, so the claim that modal-driven sign-ups retained worse is snippet-only.
- **Secret Escapes / Optimizely:** the original 2015 post is 404; there are no raw numbers (sign-up rates, LTV, sample, duration), only "more than doubled signups" and "improved LTV:CAC".
- **No published A/B tests found** for Airbnb, Headspace, Calm, Noom, Strava, Fabulous, Tinder, Spotify, or any habit, mood or journaling tracker, on moving sign-up later or removing it.
- **No account-step drop-off benchmark** from Mixpanel, Amplitude, Branch, AppsFlyer, Adjust, Localytics, UXCam, Userpilot, Adapty or RevenueCat could be found and read. The "Amplitude 36.4%" figure is unverified.
- **Baymard:**
  - The current 18% figure's question wording, sample size and survey year are not on the page read (study GC050 not accessed).
  - The 19% (1,026 US adults) and 24–26% / 37% historical values are snippet-level.
- **Janrain/Blue Research 2011:** the full report PDF was not read, so the "86%" headline could not be checked against the underlying question.
- **Identity-vendor surveys** (Gigya, Transmit, Ping Identity, Auth0/YouGov) were not read in full; their figures are snippet-level.
- **Gamberini et al. 2007:** exact submission rates and amounts of data per condition were not retrieved (abstract and NN/g summary only).
- **Hill & Shaw:** effect sizes beyond the abstract were not retrieved.
- **Cho, Sundar & Kim CHI 2020:** read via press release only; effect sizes not retrieved.
- **Guest-to-account conversion:** no published share for utility or tracker apps, and no measured effect of "back up your data after N entries", second-device or milestone prompts. The Facebook 2013 game data (15–79% connected) is the only cross-app figure, and it is vendor-reported and old.
- **RevenueCat State of Subscription Apps** hard-paywall vs freemium figures (12.1% / 2.2% in 2025; 10.7% / 2.1% in 2026) were seen only through snippets and secondary write-ups, not on RevenueCat's report pages.
- **App Store Review Guidelines:** the page's last-updated date was not captured. The "cannot require user registration prior to allowing access…" sentence is quoted from developer forum rejection messages, not from the guidelines page.
