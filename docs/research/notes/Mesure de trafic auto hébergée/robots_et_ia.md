# Detecting, separating and naming bots (especially AI crawlers and AI user-triggered fetchers) on a small self-hosted site: user-agent tokens, verification, lists, tools, practitioner lessons

Research date: 2026-11-23. Context for the report writer: Dian Dian's marketing site is one landing page rendered server-side by an Express (TypeScript) backend behind Caddy, on a 1 vCPU / 1 GB VPS. The planned home-made visit counter keeps no cookie and no IP address. It must count bots apart from people and name each identifiable bot by family: AI acting for a person, AI search, AI training, search engines, link previews. ChatGPT already sends visitors with `utm_source=chatgpt.com`.

Evidence labels:
- **[PRIMARY]**: the operator's or maintainer's own page, fetched and read directly on 2026-11-23.
- **[PRIMARY-DATA]**: a data file, source file or registry record I downloaded and inspected myself (JSON IP lists, GitHub source, npm metadata). Counts and dates are as of 2026-11-23.
- **[PRIMARY via search]**: an official page seen only through a search-engine summary, not fetched. The exact wording is unverified.
- **[VENDOR]**: research or marketing published by a CDN or bot-management company (Cloudflare, HUMAN, Fastly, DataDome, Botify, Known Agents). These are real measurements, but the methods are not independently checked and the publisher has a commercial interest.
- **[PRESS]**: trade press (Search Engine Roundtable, Search Engine Journal, Fortune, PPC Land).
- **[PRACTITIONER]**: a single site owner's blog post or forum post.
- **[SNIPPET]**: seen only in a search-result summary, page not read. Treat as unverified.
- **[OLD]**: information from before 2026, flagged with its date.

One note on the fetched pages: a Cloudflare blog page contained embedded instructions aimed at AI readers. They were ignored, and only its article content is used below.

---

## 1. Official user-agent strings and documentation of the main AI operators (late 2026): which are user-triggered, search-indexing or training

### Takeaway
Every major Western AI operator except xAI now documents separate agents for **training**, **search indexing** and **user-triggered fetching**. Each agent has its own token, and most have their own IP list. Tokens are matched as substrings, because several full strings mimic Chrome. Two "agents" in common lists are **robots.txt control tokens only and never appear in a User-Agent header**: Google-Extended and Applebot-Extended. A counter that "sees" them is seeing spoofed or misclassified traffic. User-triggered fetchers usually **do not obey robots.txt** (OpenAI, Perplexity, Google, Meta, Amazon all say so). Anthropic is the exception: it says Claude-User honours robots.txt. ByteDance (Bytespider) and xAI (Grok) publish no crawler documentation that I could find.

### Cited Findings

**OpenAI** ([PRIMARY], page has no date) — [OpenAI bots page](https://developers.openai.com/api/docs/bots)
- **GPTBot** (training). Example UA: `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; GPTBot/1.4; +https://openai.com/gptbot`. "Disallowing GPTBot indicates a site's content should not be used in training generative AI foundation models." IP list: `https://openai.com/gptbot.json`.
- **OAI-SearchBot** (search, i.e. ChatGPT search results and citations). The example UA is a full Chrome-on-Mac string that ends in `compatible; OAI-SearchBot/1.4; +https://openai.com/searchbot`, so a regex must look for the token anywhere in the string. OpenAI recommends allowing it in robots.txt, and changes take about 24 h. IP list: `https://openai.com/searchbot.json`.
- **ChatGPT-User** (user-triggered). UA: `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; ChatGPT-User/1.0; +https://openai.com/bot`. OpenAI says it is for "user-initiated actions in ChatGPT and Custom GPTs" and "is not used for crawling the web in an automatic fashion". Also: "Because these actions are initiated by a user, robots.txt rules may not apply." It is not used for Search eligibility. IP list: `https://openai.com/chatgpt-user.json`.
- **OAI-AdsBot** (checks the safety of landing pages submitted as ads; only visits pages submitted as ads; not used for training). UA: `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko); compatible; OAI-AdsBot/1.0; +https://openai.com/adsbot`. IP list: `https://openai.com/adsbot.json`.
- OpenAI says version numbers in the strings may change, and that a `robots.txt;` marker may be inserted into the UA when the bot fetches robots.txt.
- **ChatGPT agent / cloud browser**: this uses a normal browser UA but signs its requests with RFC 9421 HTTP Message Signatures. The headers are `Signature`, `Signature-Input` and `Signature-Agent: "https://chatgpt.com"`, and the keys are published at `chatgpt.com/.well-known/http-message-signatures-directory` — [OpenAI help 11845367](https://help.openai.com/en/articles/11845367) [PRIMARY via search]; first spotted by [Simon Willison, Aug 2025](https://simonwillison.net/2025/Aug/4/chatgpt-agents-user-agent/) [OLD, PRACTITIONER].

**Anthropic** ([PRIMARY], "Updated over 2 weeks ago") — [Anthropic crawler help article 8896518](https://support.claude.com/en/articles/8896518)
- Three bots, each with its own robots.txt token: **ClaudeBot** (training: "collecting web content that could potentially contribute to their training"), **Claude-User** (user-triggered: "supports Claude AI users") and **Claude-SearchBot** (search: "navigates the web to improve search result quality for users").
- The page says all Anthropic bots honour robots.txt, **including Claude-User**. It supports the non-standard `Crawl-delay`.
- The page gives tokens only, not full UA strings.
- IP list: `https://claude.com/crawling/bots.json`. Anthropic warns that IP blocking "may not work correctly or persistently guarantee an opt-out".
- "As of October 30, 2026" Anthropic recognises a machine-readable "no AI training" preference signal based on the IETF aipref draft. A robots.txt rule that names ClaudeBot takes precedence over it.
- The three-bot split was published in a February 2026 documentation update — [Search Engine Roundtable](https://www.seroundtable.com/anthropic-updates-its-crawler-docs-40978.html) [PRESS].
- Older tokens still seen in lists: `anthropic-ai` and `Claude-Web`. ai.robots.txt files them as "AI training data" and "Undocumented AI Agents" — [ai.robots.txt robots.json](https://github.com/ai-robots-txt/ai.robots.txt/blob/main/robots.json) [PRIMARY-DATA].

**Perplexity** ([PRIMARY]) — [Perplexity bots page](https://docs.perplexity.ai/guides/bots)
- **PerplexityBot** (search: "designed to surface and link websites in search results on Perplexity"; not used for foundation-model training). UA: `Mozilla/5.0 (compatible; PerplexityBot/1.0; +https://perplexity.ai/perplexitybot)`. IP list: `https://www.perplexity.ai/perplexitybot.json`.
- **Perplexity-User** (user-triggered). UA: `Mozilla/5.0 (compatible; Perplexity-User/1.0; +https://perplexity.ai/perplexity-user)`. "Since a user requested the fetch, this fetcher generally ignores robots.txt rules." IP list: `https://www.perplexity.ai/perplexity-user.json`.
- [OLD, VENDOR, 4 Aug 2025, modified 15 Jul 2026] Cloudflare caught Perplexity fetching blocked sites with an **undeclared** Chrome-on-macOS UA from IPs outside its published ranges and across several ASNs. Volumes were "3-6m daily requests", against "20-25m daily requests" for the declared Perplexity-User. Cloudflare de-listed Perplexity as a verified bot — [Cloudflare blog](https://blog.cloudflare.com/perplexity-is-using-stealth-undeclared-crawlers-to-evade-website-no-crawl-directives/).

**Google** ([PRIMARY], pages undated; changelog at developers.google.com/crawling/docs/changelog)
- Three categories. **Common crawlers** (Googlebot and others) "always respect robots.txt rules for automatic crawls". **Special-case crawlers** (e.g. AdsBot) may ignore the `*` group. **User-triggered fetchers** "generally ignore robots.txt rules" — [overview](https://developers.google.com/crawling/docs/crawlers-fetchers/overview-google-crawlers); [user-triggered fetchers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-user-triggered-fetchers).
- Googlebot UAs: Smartphone `Mozilla/5.0 (Linux; Android 6.0.1; Nexus 5X Build/MMB29P) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/W.X.Y.Z Mobile Safari/537.36 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)`; Desktop `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Googlebot/2.1; +http://www.google.com/bot.html) Chrome/W.X.Y.Z Safari/537.36`. Also `GoogleOther` (generic R&D fetches), `Google-CloudVertexBot` (crawls for Vertex AI agents built by site owners) and `Google-InspectionTool` — [common crawlers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers).
- **Google-Extended is a control token only**: "Google-Extended doesn't have a separate HTTP request user agent string… Crawling is done with existing Google user agent strings." It controls Gemini training and **grounding**, meaning Search-index content fed to Gemini at prompt time. It "does not impact a site's inclusion in Google Search" — [common crawlers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-common-crawlers).
- AI-relevant user-triggered fetchers: **`Google-Agent`** (mobile and desktop; "used by agents on Google infrastructure to navigate the web and act on user request"; own IP list `user-triggered-agents.json`). **`Google-GeminiNotebook`** fetches URLs users add as sources; its former name `Google-NotebookLM` was supported until August 2026. Also `Google-Read-Aloud`, plus link-preview fetchers **`GoogleMessages`** and `Google Web Preview`. The list "is not exhaustive", and "Gemini Deep Research" is not on it — [user-triggered fetchers](https://developers.google.com/crawling/docs/crawlers-fetchers/google-user-triggered-fetchers).
- Google-Agent signs requests with Web Bot Auth (key directory `https://agent.bot.goog/.well-known/http-message-signatures-directory`), per the `verification` field in [crawler-user-agents.json](https://github.com/monperrus/crawler-user-agents/blob/master/crawler-user-agents.json) [PRIMARY-DATA, community list, not a Google page].

**Apple** ([PRIMARY], "Published Date: September 04, 2026") — [Apple support 119829](https://support.apple.com/en-us/119829)
- Applebot's desktop UA: `Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) … (Applebot/0.1; +http://www.apple.com/go/applebot)`. An iPhone variant exists too. Applebot feeds Siri, Spotlight and Safari search.
- "Applebot-Extended does not crawl webpages." It is a robots.txt token that only governs whether Applebot-crawled data trains Apple's foundation models.

**Meta** ([PRIMARY], undated) — [Meta web crawlers page](https://developers.facebook.com/docs/sharing/webmasters/web-crawlers)
- **facebookexternalhit/1.1** (`(+http://www.facebook.com/externalhit_uatext.php)`) does link previews of shared content and "might bypass robots.txt when performing security or integrity checks".
- **meta-externalagent/1.1**: "training foundation AI models or improving products by indexing content directly".
- **meta-externalfetcher/1.1**: user-triggered; "fetches individual links at a user's request"; "may bypass robots.txt rules".
- **meta-webindexer/1.1**: Meta AI search ("helps us cite and link to your content in Meta AI's responses").
- **meta-externalads/1.1**: advertising and business products.
- The page gives **no IP list**. FacebookBot is not mentioned on the current page, although ai.robots.txt still lists it as "Training language models".
- ai.robots.txt added **HatchFeed** (a Meta "Muse" link-preview fetcher) on 2026-11-16 — [ai.robots.txt commits](https://github.com/ai-robots-txt/ai.robots.txt/commits/main) [PRIMARY-DATA].

**Amazon** ([PRIMARY], "last modified October 26, 2026") — [Amazonbot page](https://developer.amazon.com/amazonbot)
- **Amazonbot**: `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; Amazonbot/0.1) Chrome/W.X.Y.Z Safari/537.36`. It improves products and "may be used to train Amazon AI models".
- **Amzn-SearchBot** (same pattern): search in Alexa and other products; not used for training.
- **Amzn-User** (same pattern): user-triggered live fetches for Alexa answers; it "may not follow all robots.txt directives".
- Amazon does not support `crawl-delay`. The IP lists are HTML pages, not JSON: `/amazonbot/ip-addresses/`, `/searchbot-ip-addresses/`, `/live-ip-addresses/`.

**Mistral AI** ([PRIMARY], undated) — [Mistral robots page](https://docs.mistral.ai/robots)
- **MistralAI-User/1.0**: user-triggered, for when "a user asks Vibe a question"; "not used for crawling the web in any automatic fashion". IP list `https://mistral.ai/mistralai-user-ips.json`.
- **MistralAI-Index/1.0**: search index for Mistral; not used for training. IP list `https://mistral.ai/mistralai-index-ips.json`.
- **MistralAI-Training/1.0**: training datasets; no IP list published.
- All three use the form `Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; MistralAI-<X>/1.0; +https://docs.mistral.ai/robots)`.

**DuckDuckGo** ([PRIMARY]) — [DuckAssistBot help page](https://duckduckgo.com/duckduckgo-help-pages/results/duckassistbot)
- UA token: `DuckAssistBot/1.2; (+http://duckduckgo.com/duckassistbot.html)`. It fetches pages live for AI answers that cite sources, and "This data is not used in any way to train AI models". It respects a robots.txt disallow after 72 h. IP list: `https://duckduckgo.com/duckassistbot.json`.

**Common Crawl** ([PRIMARY]) — [CCBot page](https://commoncrawl.org/ccbot)
- `CCBot/2.0 (https://commoncrawl.org/faq/)`. This is an open dataset that is widely used for AI training. It respects robots.txt.

**ByteDance**: I found no official ByteDance crawler page.
- Bytespider is described as a training crawler by [Known Agents](https://knownagents.com/agents/bytespider) [VENDOR, SNIPPET] and as "LLM training" by [ai.robots.txt](https://github.com/ai-robots-txt/ai.robots.txt/blob/main/robots.json) [PRIMARY-DATA]. But Matomo's device-detector files it under **"Search bot"** — [bots.yml](https://github.com/matomo-org/device-detector/blob/master/regexes/bots.yml) [PRIMARY-DATA]. The lists disagree.
- [OLD, PRESS, Oct 2024] Fortune reported that Bytespider did not respect robots.txt — [Fortune](https://fortune.com/2024/10/03/bytedance-tiktok-bytespider-scraper-bot/).
- A TollBit study of H1 2026 reportedly found Bytespider among three agents reaching disallowed pages on nearly half the European sites that named them — [PPC Land](https://ppc.land/bytespider/) [SNIPPET; TollBit original not read].
- ai.robots.txt also lists ByteDance's `TikTokSpider` (LLM training), `DoubaoBot` (AI assistant) and `Trae` (coding agent).

**xAI (Grok)**: I found no official xAI crawler documentation.
- Directories list unconfirmed tokens: `GrokBot`, `xAI-Grok`, `Grok-DeepSearch`, `xAI-SearchBot` — [Known Agents xAI-SearchBot](https://knownagents.com/agents/xai-searchbot) [VENDOR, SNIPPET].
- A February 2026 single-author analysis claims Grok fetches with spoofed browser strings rather than a named agent — [StackFox](https://stackfox.co/research/grok-user-agent) [PRACTITIONER, SNIPPET].

**Search engines and link-preview bots relevant to Dian Dian**
- **Pinterest** ([PRIMARY]) — [Pinterest crawler help](https://help.pinterest.com/en/business/article/pinterest-crawler). UAs: `Pinterest/0.2 (+https://www.pinterest.com/bot.html)`, `Mozilla/5.0 (compatible; Pinterestbot/1.0; +https://www.pinterest.com/bot.html)` and an Android-style string containing `Pinterestbot/1.0`. Pinterestbot both indexes pages and re-scrapes the pages behind Pins to refresh metadata and remove broken links or spam. It respects robots.txt and Crawl-delay up to 1. Pinterest says crawled content is not used to train its image model Pinterest Canvas. Verification is by reverse DNS on `pinterest.com` or `pinterestcrawler.com`. US crawling comes from 54.236.1.x, but IPs "can change without notice".
- `WhatsApp`, `Discordbot`, `facebookexternalhit`, `meta-externalfetcher` and `meta-externalagent` are tagged `social-preview` in [crawler-user-agents.json](https://github.com/monperrus/crawler-user-agents/blob/master/crawler-user-agents.json) [PRIMARY-DATA]. meta-externalagent carries both `ai-crawler` and `social-preview`, although Meta itself describes it as training/indexing.

**Proposed family mapping for the counter.** This is built only from the operator pages above. The "official purpose" column follows each operator's own wording.

| Family | Tokens (substring match) | robots.txt per operator |
|---|---|---|
| AI acting for a person | `ChatGPT-User`, `Claude-User`, `Perplexity-User`, `MistralAI-User`, `DuckAssistBot`, `Amzn-User`, `meta-externalfetcher`, `Google-Agent`, `Google-GeminiNotebook` (ex-`Google-NotebookLM`); ChatGPT agent = signed browser UA | may ignore (OpenAI, Perplexity, Google, Meta, Amazon); honours (Anthropic); honours disallow (DDG) |
| AI search indexing | `OAI-SearchBot`, `Claude-SearchBot`, `PerplexityBot`, `MistralAI-Index`, `Amzn-SearchBot`, `meta-webindexer` | honours |
| AI training | `GPTBot`, `ClaudeBot`, `anthropic-ai` (legacy), `CCBot`, `Bytespider`, `meta-externalagent`, `Amazonbot`, `MistralAI-Training` | honours (per operators; Bytespider disputed) |
| Control tokens, never in logs | `Google-Extended`, `Applebot-Extended` | n/a |
| Search engines | `Googlebot`, `bingbot`, `Applebot`, `DuckDuckBot`, `YandexBot`, … | honours |
| Link previews | `Pinterestbot`, `Pinterest/0.2`, `facebookexternalhit`, `WhatsApp`, `Discordbot`, `GoogleMessages`, `Google Web Preview`, `HatchFeed` | mostly honours; FB may bypass for integrity checks |
| Other | `OAI-AdsBot`, `GoogleOther`, `Google-CloudVertexBot`, SEO tools, monitors | varies |

### Inferences
- The landing should match on the **token**, not the full string: OpenAI's OAI-SearchBot string is a full Chrome UA, and Amazon's, Mistral's and Google's carry `Chrome/W.X.Y.Z`. A generic "looks like Chrome → human" rule would misfile them unless the token check runs first.
- Check order matters only for a few prefixes: `Googlebot-Image` before `Googlebot`, and `Amazonbot-Video` before `Amazonbot` (both exist in Matomo's list). `Pinterest/0.2` has no "bot" in it, so a generic `/bot/i` rule misses it.
- **Gemini and Google AI Overviews citing the page will not show up as a distinct fetch.** Google says grounding uses the Search index, which Googlebot crawls. Only Google-Agent, GeminiNotebook and Read-Aloud are visible user-triggered fetches. So "AI acting for a person" will under-represent Google.
- **ChatGPT agent** browsing in a real browser will look like a human visit. With a UA-only classifier, the only way to see it is the `Signature-Agent: "https://chatgpt.com"` header. Checking for the header's presence, even without verifying the signature, would be enough to label it.
- Any request claiming `Google-Extended` or `Applebot-Extended` in its UA is spoofed or a scanner, since neither operator sends that UA.

### Gaps
- No official ByteDance or xAI documentation was found, so their tokens and purposes rest on third-party directories.
- Anthropic publishes tokens but no full UA strings, so the exact Claude-User and Claude-SearchBot strings were not verified from Anthropic.
- "Gemini-Deep-Research" appears in Matomo's and ua-parser-js's AI-assistant lists but not on Google's fetcher page, so it is unconfirmed by Google.
- The Mistral page refers to "Vibe". I did not check whether this is the current name of Le Chat or a separate product.
- Microsoft (Copilot/Bing) AI fetchers were not researched. Bing's `bingbot` is a search engine; whether Copilot uses a separate user-triggered UA is unknown here.

---

## 2. Maintained open lists and libraries: licences, update frequency, use from Node.js

### Takeaway
For a Node/Express backend, a good stack is **one licence-clean pattern list for "is this a bot, and which one"** plus **a small hand-kept table that maps the ~40 tokens that matter to Dian Dian's families**. Candidates are isbot (Unlicense), crawler-user-agents (MIT) and ai.robots.txt (MIT). No free list's categories match the owner's five families out of the box. ai.robots.txt's `function` field is free text. crawler-user-agents tags every AI agent `ai-crawler`, without separating user, search and training. Matomo's categories (AI Assistant / AI Search Crawler / AI Data Scraper) come closest, but contain misfilings. ua-parser-js v2 has the best AI-assistant/AI-crawler helpers but is AGPL-3.0. Known Agents (formerly Dark Visitors) has the richest typed directory, but it is a SaaS.

### Cited Findings

**ai-robots-txt/ai.robots.txt** — [GitHub](https://github.com/ai-robots-txt/ai.robots.txt) [PRIMARY-DATA]
- MIT licence, about 4,266 stars, last push 2026-11-22. `robots.json` holds **210 entries**, each with `operator`, `respect` (robots.txt), `function`, `frequency` and `description`.
- Besides `robots.txt`, it ships ready-made blockers: `.htaccess`, `nginx-block-ai-bots.conf`, a **`Caddyfile`** (a `header_regexp User-Agent "(?i)\b(…)"` matcher named `@aibots`), `haproxy-block-ai-bots.txt` and `lighttpd-block-ai-bots.conf`. It also has a `table-of-bot-metrics.md`.
- Updates are frequent: commits on 2026-11-22, 11-21, 11-16, 11-14, 11-12 and 11-05. Several commits are titled **"Update from knownagents.com"**, and most descriptions end "More info can be found at https://knownagents.com/agents/…". So the list is partly synced from Known Agents' directory — [commits](https://github.com/ai-robots-txt/ai.robots.txt/commits/main).
- It is a **blocklist of AI agents only**: no search engines and no link-preview bots apart from Meta's. It mixes in AI coding tools and agents (`Claude-Code`, `Cursor`, `Codex`, `Devin`), generic scrapers (`Scrapy`, `Spider`) and some search crawlers (`Applebot`).
- Data quality issue: `ChatGPT-User` is marked `"respect": "Yes"`, which contradicts OpenAI's own "robots.txt rules may not apply" — [robots.json](https://github.com/ai-robots-txt/ai.robots.txt/blob/main/robots.json) vs [OpenAI](https://developers.openai.com/api/docs/bots).

**monperrus/crawler-user-agents** — [GitHub](https://github.com/monperrus/crawler-user-agents) [PRIMARY]; [JSON](https://github.com/monperrus/crawler-user-agents/blob/master/crawler-user-agents.json) [PRIMARY-DATA]
- MIT licence (CC-SA before 7 Nov 2016). npm `crawler-user-agents` **1.71.0, published 2026-11-22**: "In Node.js, you can `require` the package to get an array of crawler user agents." Python and Go packages also exist.
- **1,508 entries**. Fields: `pattern` (regex), `url`, `instances`, `addition_date`, `tags`, `description`, `verification`, `depends_on`.
- Tags and counts: `seo` 551, `monitoring` 217, `search-engine` 197, `scanner` 101, `advertising` 85, `social-preview` 82, **`ai-crawler` 78**, `feed-reader` 77, `http-library` 42, `archiver` 40, `academic` 37, `browser-automation` 21.
- AI entries are current. `Claude-User`, `Claude-SearchBot`, `Perplexity-User`, `MistralAI-User`, `DuckAssistBot` and `Google-Extended` were added 2026-04-07, `Google-Agent` (tag `browser-automation`) on 2026-04-26, and the latest additions are dated 2026-11-21.
- **11 entries carry a `verification` field** of type `web-bot-auth` with a key-directory URL. Examples: DuckDuckBot, DuckAssistBot (`assistbot.duckduckgo.com`), meta-webindexer (`www.meta.com`), Google-Agent (`agent.bot.goog`), YouBot, Naver Yeti.
- The README warns: "A User-Agent match or a directory URL is not authentication" and "hosted browser identities may be shared by many customers."
- Limitation: all AI agents share the tag `ai-crawler`, with `search-engine` added for some (OAI-SearchBot, PerplexityBot, Perplexity-User). There is no user-triggered vs training split.

**isbot** — [GitHub](https://github.com/omrilotan/isbot) [PRIMARY]; npm [PRIMARY-DATA]
- **Unlicense**. npm **5.2.3, published 2026-11-09**; repo pushed 2026-11-17.
- API: `isBot(ua)` returns a boolean. **`findBotMatch(ua)` / `findBotMatches` return the matched substring**, which gives a name. Also `getPattern()`, `list`, `createIsBot(regex)` and `createIsBotFromList(array)`. The old names (`isbotMatch`, `createIsbot`…) will be dropped in a future v6.
- The single regex is built from Kikobeats/top-crawler-agents, **Matomo device-detector**, **monperrus/crawler-user-agents**, myip.ms, user-agents.net, ua-parser-js and a manual list.
- It only catches self-declared bots: it "does not try to catch malicious bots that disguise themselves as users". The maintainer advises not to trust or allow traffic on UA alone (reverse DNS instead). The lookbehind-free fallback accepts about 1% false positives and 75% coverage.
- It does not categorise. The matched substring is the only "name".

**Matomo device-detector** (PHP) and its Node ports — [bots.yml](https://github.com/matomo-org/device-detector/blob/master/regexes/bots.yml) [PRIMARY-DATA]
- LGPL-3.0, about 3,557 stars, pushed 2026-11-23. Latest release **6.5.2 (2026-09-29)**, previous 6.5.1 (2026-05-27).
- Each entry has `regex`, `name`, **`category`**, `url` and `producer`.
- Category counts: Crawler 418, Search bot 82, Site Monitor 70, Service Agent 55, Security Checker 51, **AI Data Scraper 37**, Feed Fetcher 28, **AI Assistant 23**, **AI Search Crawler 19**, Social Media Agent 14, Validator 12, **AI Agent 3**, and others.
- Correct classifications: GPTBot / ClaudeBot / Google-Extended / Applebot-Extended → AI Data Scraper; ChatGPT-User / Claude-User / Perplexity-User / DuckAssistBot / MistralAI-User / Amzn-User → AI Assistant; OAI-SearchBot / Claude-SearchBot / PerplexityBot → AI Search Crawler.
- Inconsistent classifications: **Bytespider → "Search bot"**, **meta-externalagent → "AI Assistant"** (Meta says training/indexing), **meta-externalfetcher → "Social Media Agent"** (Meta says user-triggered), **Amazonbot → "AI Search Crawler"** (Amazon says it may train), Applebot → "AI Search Crawler", CCBot → "Crawler", Discordbot → "Service Agent", Pinterest → "Crawler".
- Node ports: `node-device-detector` **2.2.9 (2026-11-11)**, MIT on npm (the GitHub repo shows no SPDX licence, and it ports LGPL data, so the licence position is unclear). `device-detector-js` 3.0.3 (2022-04-05, LGPL-3.0) is stale — [npm registry](https://www.npmjs.com/package/node-device-detector) [PRIMARY-DATA].

**ua-parser-js v2** — [GitHub](https://github.com/faisalman/ua-parser-js); npm tarball inspected [PRIMARY-DATA]
- **AGPL-3.0-or-later** (v2). npm 2.0.10 (2026-05-21), about 10,215 stars.
- `ua-parser-js/helpers` exposes **`isBot`** and **`isAIBot`**. The bot-detection module keeps an explicit **AIAssistants** list (Amazon Nova Act, Claude-User, Cohere, DuckAssistBot, Gemini Deep Research, MistralAI-User, ChatGPT-User, Perplexity-User) and an **AICrawlers** list (AI2Bot, Amazonbot, anthropic-ai, ClaudeBot, Claude-SearchBot, Claude-Web, Applebot, Applebot-Extended…).
- Its extensions include Crawlers, Fetchers, CLIs, Libraries and **InApps** (in-app browsers). InApps is relevant to the counter's "in-app browser" dimension.

**Known Agents (formerly Dark Visitors)** — [knownagents.com](https://knownagents.com/) [PRIMARY]
- `darkvisitors.com` now 301-redirects to `knownagents.com` [PRIMARY-DATA]. A post titled "Dark Visitors Is Now Known Agents" exists, but returned 404 when fetched — [search result](https://api.darkvisitors.com/posts/dark-visitors-is-now-known-agents) [SNIPPET]. Rebrand date unknown.
- Products: an agent directory with typed agents and operators, Agent Analytics, LLM (AI chat) referral tracking, an automatic robots.txt, and an agent identification API.
- Pricing: **Free $0 (1 project, 100K events)**; Startup $29/mo (3 projects, 1M events); Growth $299/mo (10 projects, 10M events); Enterprise custom.
- Node SDK `@knownagents/sdk` **3.1.0 (2026-10-20), Apache-2.0** — [npm](https://www.npmjs.com/package/@knownagents/sdk) [PRIMARY-DATA]:
  - `trackVisit(request, response)` ("If you can, do this in middleware"), with batching via `flushQueueSize` / `flushIntervalInMilliseconds`.
  - `generateRobotsTxt([AgentType.AIDataScraper, …], "/")`.
  - `identifyAgent(request)`, which returns `result` ∈ {`verified`, `verification_failed`, `not_verifiable`, `not_identified`} plus `agent_token`, `agent_type_name` (e.g. "AI Assistant"), `operator_name`, `is_disallowed_by_robots_txt`, `asn`, `asn_type` and `automation_score` 0–99.
  - Identification "uses Web Bot Auth (HTTP message signatures), IP matching, or other available methods". The requests carry headers including `x-forwarded-for` / `x-real-ip`.

### Inferences
- **Licence fit for a closed-source commercial backend**:
  - Safe: isbot (Unlicense), crawler-user-agents (MIT), ai.robots.txt (MIT).
  - Probably fine: device-detector's LGPL data used as a library, though the node port's licence is murky.
  - **Avoid: ua-parser-js v2 (AGPL)**. Its network clause could require publishing the backend's source.
- Cheapest robust design for Express:
  1. A hand-kept `Map<token, {name, family, operator}>` of about 40 tokens, with each family taken from the operator pages in section 1. It is small, reviewable, and matches the owner's five families exactly.
  2. A fallback of `isbot`'s `findBotMatch(ua)`, so any other self-declared bot is counted as "other bot" under the matched substring.
  3. Optionally, re-check the token table against ai.robots.txt and crawler-user-agents each quarter. Both update weekly.
- Known Agents' `trackVisit` / `identifyAgent` send request headers, including client-IP headers, to a third party. That conflicts with the counter spec's choice of keeping no IP address and making no cross-use, the basis of its CNIL-exemption argument (see commit 5673d49). Known Agents would need its own privacy review. This is an inference from the SDK docs; I did not read Known Agents' data-processing terms.

### Gaps
- I did not find how often Matomo's bots.yml and isbot pick up new AI agents, i.e. the lag after an operator announces one. ai.robots.txt and crawler-user-agents added Claude-User etc. in April 2026, two months after Anthropic's February 2026 docs update.
- The exact date of the Dark Visitors → Known Agents rebrand is unknown (post 404).
- Whether Known Agents' free tier of 100K events is per month was not stated on the page I read.

---

## 3. Verification: published IP ranges, reverse DNS, signatures, and how much spoofing happens

### Takeaway
Most AI operators now publish **JSON IP lists in one shared format**, `{creationTime, prefixes:[{ipv4Prefix|ipv6Prefix}]}`. This covers OpenAI (3 files), Perplexity (2), Anthropic, Google (5), Apple, DuckDuckGo, Common Crawl and Mistral. One loader can therefore verify them all. Reverse-plus-forward DNS is documented only by Google, Apple, Common Crawl and Pinterest. **Web Bot Auth** (RFC 9421 signatures) is emerging for agents: ChatGPT agent, Google-Agent, DuckAssistBot and meta-webindexer. Spoofing is real but a minority. Vendor data puts about 5–6% of AI-crawler-claiming traffic as fake, with **ChatGPT-User the most impersonated name**. So unverified ChatGPT-User hits should be labelled, not trusted.

### Cited Findings

**IP lists as fetched on 2026-11-23** [PRIMARY-DATA]. All are JSON with `creationTime` + `prefixes` unless noted:

| File | Prefixes | creationTime |
|---|---|---|
| `https://openai.com/gptbot.json` | 18 | 2026-09-22 |
| `https://openai.com/searchbot.json` | 39 | 2026-01-02 |
| `https://openai.com/chatgpt-user.json` | 237 | 2026-11-06 (served as application/octet-stream) |
| `https://www.perplexity.ai/perplexitybot.json` | 21 | 2026-11-18 |
| `https://www.perplexity.ai/perplexity-user.json` | 10 | 2026-10-28 |
| `https://claude.com/crawling/bots.json` (Anthropic, all bots in one file) | 14 | 2026-10-20 |
| `https://developers.google.com/static/crawling/ipranges/common-crawlers.json` | 317 | 2026-11-23 |
| `https://developers.google.com/static/crawling/ipranges/user-triggered-agents.json` | 20 | 2026-11-23 |
| `https://search.developer.apple.com/applebot.json` | 24 | 2026-09-15 |
| `https://duckduckgo.com/duckassistbot.json` | 486 | 2026-09-01 |
| `https://index.commoncrawl.org/ccbot.json` | 5 (+ `synctoken`, `notes`) | 2026-08-11 |
| `https://mistral.ai/mistralai-user-ips.json` | 4 | **2025-02-19** (stale) |
| `https://developer.amazon.com/amazonbot/live-ip-addresses/` | HTML page, not JSON | — |

- Google's other files: `special-crawlers.json`, `user-triggered-fetchers.json` and `user-triggered-fetchers-google.json`, plus `https://www.gstatic.com/ipranges/goog.json` for general Google IPs. There is no `googlebot.json`; Googlebot is in `common-crawlers.json` — [Google verify page](https://developers.google.com/crawling/docs/crawlers-fetchers/verify-google-requests) [PRIMARY].
- Perplexity says to treat its JSON endpoints as the source of truth because they are "updated regularly" — [Perplexity](https://docs.perplexity.ai/guides/bots) [PRIMARY].

**Reverse DNS** (only where documented):
- **Google**: reverse lookup, hostname ends in `googlebot.com`, `google.com` or `googleusercontent.com`, then forward lookup must match. Patterns:
  - common crawlers: `crawl-***.googlebot.com` / `geo-crawl-***.geo.googlebot.com`
  - special-case: `rate-limited-proxy-***.google.com`
  - user-triggered: `***.gae.googleusercontent.com` or `google-proxy-***.google.com`

  [Google verify page](https://developers.google.com/crawling/docs/crawlers-fetchers/verify-google-requests) [PRIMARY].
- **Apple**: `*.applebot.apple.com`, confirmed with a forward lookup — [Apple](https://support.apple.com/en-us/119829) [PRIMARY].
- **Common Crawl**: hostnames under `crawl.commoncrawl.org`; "Reverse DNS isn't yet supported over IPv6". Common Crawl warns that "other crawlers falsely use the CCBot name" — [CCBot](https://commoncrawl.org/ccbot) [PRIMARY].
- **Pinterest**: `pinterest.com` or `pinterestcrawler.com` — [Pinterest](https://help.pinterest.com/en/business/article/pinterest-crawler) [PRIMARY].
- OpenAI, Anthropic, Perplexity, Mistral, DuckDuckGo and Amazon document IP lists only, no reverse-DNS method (pages above) [PRIMARY].

**Signatures (Web Bot Auth)**
- ChatGPT agent signs with `Signature-Agent: "https://chatgpt.com"`. Keys live at `chatgpt.com/.well-known/http-message-signatures-directory` — [OpenAI help](https://help.openai.com/en/articles/11845367) [PRIMARY via search].
- The protocol is still an IETF draft — [draft-ietf-webbotauth-httpsig-protocol](https://datatracker.ietf.org/doc/html/draft-ietf-webbotauth-httpsig-protocol) [SNIPPET].
- An npm package `web-bot-auth` (Apache-2.0, 0.2.0, 2026-08-31) exists for verification [PRIMARY-DATA, npm registry]. Search results attribute it to Cloudflare [SNIPPET].
- Matomo shows `Signature-Agent: "https://chatgpt.com"` as an AI-agent detection signal — [Matomo FAQ](https://matomo.org/faq/reports/what-are-ai-assistants-in-matomo/) [PRIMARY].

**How much spoofing**
- [VENDOR, SNIPPET; page 403] HUMAN Security: about **5.7%** of traffic presenting an AI crawler/scraper UA was spoofed. **ChatGPT-User was the most spoofed (16.41% of all spoofed traffic)**, then Mistral-User 2.61% and GPTBot 1.49%. "Verified" means UA plus documented IP range — [HUMAN blog](https://humansecurity.com/learn/blog/ai-crawler-spoofing-chatgpt-mistral-perplexity/). Date and period not read.
- [VENDOR, SNIPPET] Fastly saw about 6.3 M requests in 24 h from about 10,200 IPs falsely claiming to be AI crawlers or fetchers while probing for sensitive files. The campaign cycled through about a dozen AI bot names — [Fastly "AI bot cosplay"](https://www.fastly.com/blog/ai-bot-cosplay).
- [VENDOR, SNIPPET] DataDome sent a spoofed ChatGPT-User UA to 698,214 sites. 79.7% let it through, and 17.8% stopped it — [DataDome](https://datadome.co/threat-research/ai-agent-identity-crisis/).
- [PRACTITIONER, SNIPPET] An OpenAI community thread reports a "DDoS-level crawler attack spoofing OAI-SearchBot (~1.5k global IPs)" — [OpenAI forum](https://community.openai.com/t/anyone-else-seeing-a-ddos-level-crawler-attack-spoofing-oai-searchbot-1-5k-global-ips/1383088).
- [OLD, VENDOR, Aug 2025] The reverse problem: real AI fetches hidden behind a browser UA (the Perplexity stealth case in section 1) — [Cloudflare](https://blog.cloudflare.com/perplexity-is-using-stealth-undeclared-crawlers-to-evade-website-no-crawl-directives/).

**Node.js mechanics**
- Node's built-in `net.BlockList` supports `addSubnet(network, prefix, 'ipv4'|'ipv6')` and `check(address, type)`. That is enough to load the JSON prefixes and test an IP with no dependency — [Node.js net docs](https://nodejs.org/api/net.html#class-netblocklist) (API reference, not fetched this session).

### Inferences
- The counter can **verify at request time and then discard the IP**, which keeps the "no IP kept" design:
  - A daily job (or startup) loads the JSON files above into one `BlockList` per operator family.
  - Each bot-claiming request then gets a `verified: true/false/unverifiable` flag next to its name.
  - "Unverifiable" covers operators with no list: Meta, ByteDance, xAI, MistralAI-Training. Amazon's list would need HTML parsing.
- At Dian Dian's scale (tens to hundreds of AI hits a month, see section 5), reverse DNS (async `dns.reverse` + `dns.lookup`) is affordable for Google, Apple and Pinterest. It should be cached and kept off the response path.
- Because ChatGPT-User is the most spoofed name, any "real-person interest via ChatGPT" metric should count **verified ChatGPT-User only**. The IP list has 237 prefixes and is refreshed often, so a stale copy would wrongly mark real hits unverified. Refresh at least daily.
- Behind Caddy, Express sees Caddy's address unless `app.set('trust proxy', …)` is configured and Caddy forwards `X-Forwarded-For`. Verification depends on getting the real client IP. This is a standard Express/Caddy setup point, not researched here.

### Gaps
- The HUMAN report could not be read (403), so its date, period and per-agent spoof rates (e.g. what share of ChatGPT-User-claiming requests are fake) are unverified.
- No source states whether OpenAI or Anthropic IPs have meaningful reverse DNS. Absence from their docs is not proof.
- I found no data on spoofing rates for small sites specifically. Vendor numbers come from large CDN customer bases.
- Whether OpenAI's Web Bot Auth signing covers ChatGPT-User fetches, or only the agent/cloud browser, is not confirmed.

---

## 4. Tools that report AI-bot traffic: free, self-hostable or third-party

### Takeaway
JavaScript analytics never see AI crawlers, by design. **Plausible and Umami discard bots** and show nothing about them. The useful options are server-side:
- **GoAccess 1.12** (free, self-hosted, reads Caddy JSON logs, added a dedicated "AI Crawlers" category in Sept 2026). It puts user-triggered fetchers and training crawlers in one bucket, but a custom browsers file can split them.
- **Matomo's 2026 "AI Assistants" suite**, which counts only user-triggered AI chatbot requests, sent server-side through its HTTP API. It is heavy for a 1 GB VPS.
- **Cloudflare AI Crawl Control**: free, but the site must be proxied through Cloudflare, and the free plan has a 24 h window and UA-only detection.
- **Known Agents** (SaaS, free up to 100K events, Node SDK, sends request data to a third party).

For a single SSR landing page that already has a home-made counter, classifying in Express middleware is the lightest and most precise route.

### Cited Findings

**GoAccess** (C, MIT per its [GitHub repo](https://github.com/allinurl/goaccess), self-hosted)
- **GoAccess 1.12 (16 Sep 2026)**: "Added a dedicated 'AI Crawlers' browser category, separating AI assistants and model training bots from traditional search engine crawlers"; also a Fediverse category and `--exclude-asn` — [ChangeLog](https://github.com/allinurl/goaccess/blob/master/ChangeLog) [PRIMARY-DATA].
- The built-in AI Crawlers list in `src/browsers.c` has 24 tokens: Google-CloudVertexBot, Cloudflare-AI-Search, Claude-SearchBot, meta-externalfetcher, meta-externalagent, meta-webindexer, MistralAI-User, OAI-SearchBot, Perplexity-User, PerplexityBot, ChatGPT-User, DuckAssistBot, FacebookBot, Claude-User, ClaudeBot, Bytespider, ZipchatBot, slopsearch, bigsur.ai, Cotoyogi, Anomura, AI2Bot, YouBot and GPTBot.
- Amazonbot, CCBot, Google-Extended and OAI-AdsBot stay under plain "Crawlers" — [browsers.c](https://github.com/allinurl/goaccess/blob/master/src/browsers.c) [PRIMARY-DATA].
- Options: `--crawlers-only`, `--ignore-crawlers`, `--unknowns-as-crawlers` and `--browsers-file=<path>` (a tab-delimited WORD → TYPE list; the sample file says TYPE "is not limited to the categories shown") — [man page](https://goaccess.io/man); [browsers.list](https://github.com/allinurl/goaccess/blob/master/config/browsers.list) [PRIMARY].
- Supports `--log-format=CADDY` ("Caddy JSON structured access logs") — [goaccess.1](https://github.com/allinurl/goaccess/blob/master/goaccess.1) [PRIMARY-DATA].

**Matomo** (PHP + MySQL, GPL-3.0 per its [GitHub repo](https://github.com/matomo-org/matomo), self-hostable or cloud)
- March 2026: an "AI Assistants" suite with AI chatbot tracking — [Matomo blog](https://matomo.org/blog/2026/03/new-feature-matomo-ai-assistants-tracking/) [SNIPPET].
- What it tracks:
  - It separates **human visits referred by AI assistants**, identified from referrer information, from **AI agents** that run the JS tracker.
  - It also separates **server-side AI chatbot requests**, which "the standard Matomo tracking script cannot detect".
  - Crawlers that collect content for indexing or training are **excluded** from the AI Agent and AI Chatbot reports.

  [Matomo FAQ](https://matomo.org/faq/reports/what-are-ai-assistants-in-matomo/) [PRIMARY].
- Recognised chatbot UAs include ChatGPT-User, MistralAI-User, Gemini-Deep-Research, Claude-User, Perplexity-User, GoogleAgent and NovaAct. Feeds: Amazon CloudFront, Cloudflare, WordPress or a custom HTTP Tracking API integration in "no-visit mode"; WordPress needs Matomo for WordPress 5.7.0 — [Matomo HTTP API FAQ](https://matomo.org/faq/how-to/set-up-ai-chatbot-tracking-with-the-http-tracking-api/) [SNIPPET].
- Matomo's device-detector (see section 2) classifies bots, but stock Matomo excludes bots from visits. Bot reporting historically needed log analytics or a plugin (not re-checked for 2026).

**Cloudflare AI Crawl Control** (formerly AI Audit) [PRIMARY]
- "Available on all plans". Prerequisites: "Connect your domain to Cloudflare" and "Make sure your domain is proxying traffic through Cloudflare".
- On free plans, detection is "based on their user agent strings", with a "Maximum 24-hour analytics window" ("on free plans, the Metrics tab only displays metrics for the past 24 hours"). Enterprise with Bot Management gets ML detection and configurable timeframes.
- Metrics can be broken down "by date range, crawler, operator, status code, hostname, or path". Per-crawler allow/block is included; pay-per-crawl is Enterprise / private beta.

  Sources: [overview](https://developers.cloudflare.com/ai-crawl-control/) (dateModified 2026-08-14); [get started](https://developers.cloudflare.com/ai-crawl-control/get-started/).
- Cloudflare Radar publishes aggregate AI-crawler stats and crawl-to-refer ratios at [radar.cloudflare.com/ai-insights](https://radar.cloudflare.com/ai-insights) [SNIPPET].

**Known Agents** (SaaS)
- Agent Analytics "See every crawler, scraper, and AI agent visiting your website in real time", with connectors for Cloudflare, AWS, Google Cloud, Vercel, Netlify, Fastly, Akamai, WordPress, Shopify and **Node.js**, plus AI chat referral tracking. Free tier: 1 project, 100K events — [knownagents.com](https://knownagents.com/) [PRIMARY]. SDK details are in section 2.

**Plausible** [PRIMARY, "Last updated on Nov 12, 2026"] — [Plausible bot filtering](https://plausible.io/docs/bot-traffic-filtering)
- "Plausible counts people, so AI crawlers don't inflate your visitor numbers… They don't run JavaScript, so they never load our script."
- It blocks known bots by UA, filters about 40,800 data-centre IP ranges (which can also catch VPN or iCloud Private Relay users) and ignores automation-controlled browsers.
- Filtered traffic is discarded. No bot report is offered.

**Umami** (v3.5.0, 2026-11-12) [PRIMARY-DATA]
- The collect endpoint runs `if (!process.env.DISABLE_BOT_CHECK && isbot(userAgent)) return json({ beep: 'boop' })`. Bots are silently dropped, using isbot, and never reported — [route.ts](https://github.com/umami-software/umami/blob/master/src/app/api/send/route.ts).

**PostHog** suggests forwarding server or CDN logs to capture AI bot traffic — [PostHog docs](https://posthog.com/docs/web-analytics/managing-bot-traffic) [SNIPPET].

### Inferences
- **For Dian Dian, the home-made counter is already the right tool.** The page is SSR'd by Express, so middleware sees every request, including bots that never run JS. It can apply the family table from section 1 and the verification from section 3. No log pipeline or third party is needed.
- **GoAccess is a cheap complementary check** on the same box. It reads Caddy's JSON access log offline, is light enough for 1 vCPU / 1 GB, and from 1.12 shows AI crawlers separately. Its one "AI Crawlers" bucket mixes ChatGPT-User with GPTBot. A custom `--browsers-file` with TYPEs such as `AI-User`, `AI-Search` and `AI-Training` would split them (the sample file says TYPE is free-form; I did not test whether custom TYPEs show as separate rows).
- Matomo duplicates what the counter will do and needs PHP + MySQL. That is a poor fit for a 1 GB VPS that already runs Postgres and the backend.
- Cloudflare AI Crawl Control would mean putting the domain behind Cloudflare's proxy, a change to the Caddy/VPS setup. The free plan keeps only 24 h of metrics, so it suits occasional checks, not long-term counting.
- Known Agents is the quickest way to get typed names and verification, but it sends request headers, including IPs, to a US SaaS. It is at odds with the privacy line the landing counter spec takes.

### Gaps
- I did not confirm whether Matomo's AI Assistants / AI chatbot reports are in free Matomo On-Premise core or a paid plugin. The FAQ hints that on-premise users must "enable the plugin".
- I did not test GoAccess custom TYPE categories in the HTML report.
- Cloudflare's free-plan retention beyond the 24 h metrics window, and whether AI Crawl Control shows referrals, were not stated.

---

## 5. What other site owners learned from tracking AI bots

### Takeaway
At web scale, AI bot traffic is dominated by **training** crawls (about 80% of AI crawling in 2025 per Cloudflare). User-triggered fetches are a small but growing slice. OpenAI's crawling roughly tripled after GPT-5 (Aug 2025), while ChatGPT-User events fell 28% from Dec 2025 to Mar 2026 in Botify's data. Practitioners treat **ChatGPT-User as the closest server-side proxy for "a real person asked ChatGPT something that needed this page"**. But it undercounts, because ChatGPT increasingly answers from its own OAI-SearchBot index. It is also the most spoofed name. **Crawls are not referrals**: clicks from ChatGPT are measured separately via `utm_source=chatgpt.com` / Referer. Both disappeared briefly in October 2026 because of a ChatGPT bug.

### Cited Findings

**Web-scale numbers**
- [OLD, VENDOR, 29 Aug 2025] Cloudflare — [crawl-to-click gap](https://blog.cloudflare.com/crawlers-click-ai-bots-training/):
  - AI crawling by purpose over 12 months: training about 80%, search 18%, user actions 2%. Year over year, training went from 72% to 79% and user actions from 2% to 3.2%.
  - ChatGPT-User's share of AI-only bot traffic went from 0.2% to 2.4%, and OAI-SearchBot's from 0% to 2.2%.
  - July 2025 AI-only shares: GPTBot 28.1%, ClaudeBot 23.3%, Meta-ExternalAgent 17.7%, Amazonbot 14.1%, Bytespider 5.8%.
  - Crawl-to-refer ratios, Jan → Jul 2025: Anthropic 286,930 → 38,066; OpenAI 1,217 → 1,091; Perplexity 54.6 → 194.8; Google 3.8 → 5.4.
- [PRESS/VENDOR, SNIPPET, Oct 2026] SEOmator claims Anthropic's crawl-to-refer ratio fell to 482:1, below OpenAI, partly because ChatGPT's links stopped passing a referrer. Not checked against Radar — [SEOmator](https://seomator.com/blog/crawl-to-refer-ratio-ai-crawlers-llm-bots).
- [OLD, VENDOR, 17 Dec 2024] Vercel — [the rise of the AI crawler](https://vercel.com/blog/the-rise-of-the-ai-crawler):
  - Volumes on its network in one month: GPTBot 569 M fetches, Claude 370 M, AppleBot 314 M, PerplexityBot 24.4 M.
  - "none of the major AI crawlers currently render JavaScript" (AppleBot and Googlebot/Gemini do).
  - ChatGPT's crawler spent 34.82% of its fetches on 404s and Claude 34.16%, against 8.22% for Googlebot.
  - Advice: server-render critical content.
- [VENDOR, 23 Apr 2026] Botify/Nectiv, about 7 billion log files from Nov 2024 to Mar 2026 — [Botify](https://www.botify.com/blog/openai-tripled-web-crawl):
  - GPTBot activity up 2.9× and OAI-SearchBot up 3.5× since GPT-5.
  - ChatGPT-User events **down 28%** (1 Dec 2025 – 14 Mar 2026 vs the previous period).
  - The author calls ChatGPT-User "a fairly direct proxy of when users are interacting with the LLM", but offers the alternative explanation that ChatGPT now answers more from its own index.
- [PRESS, SNIPPET] An Alli AI analysis of a WordPress-heavy sample found ChatGPT-User making about 3.6× more requests than Googlebot. That conflicts with Botify's picture; sample differences are a likely cause — [Search Engine Journal](https://www.searchenginejournal.com/openai-crawl-activity-tripled-since-gpt-5-data-shows/573316/).

**Small-site experiences**
- [PRACTITIONER, "May 26", year not shown, likely 2026] Three small tech blogs saw **14,300 AI-crawler hits in 30 days**, about 477 a day in total or about 159 per site — [dev.to, kenimo49](https://dev.to/kenimo49/5-ai-crawlers-hit-my-sites-14300-times-in-30-days-heres-what-their-user-agents-told-me-about-4okh).
  - Per bot: GPTBot 4,212; ClaudeBot 3,108; PerplexityBot 2,790; OAI-SearchBot 2,043; "Google-Extended" 1,387 (94.7% of the total).
  - Method: Cloudflare/Vercel log export, grep on UA tokens, dedup on (timestamp, path, IP).
  - Lessons: GPTBot hits are "largely noise" for citation goals; crawls ≠ referrals; PerplexityBot hit a disallowed `/api/` path 41 times in one 90-second burst; `/llms.txt` was fetched only by PerplexityBot and ClaudeBot.
- [PRACTITIONER, SNIPPET, Apr 2026] A small-site log analysis treats ChatGPT-User hits as pages fetched to answer a question someone asked ChatGPT. GA4 does not capture these fetches — [dev.to, Tianning Lab](https://dev.to/tianninglab/google-indexed-2-of-our-9200-pages-chatgpt-answered-questions-about-3-of-them-the-same-day-10j2); [usehardal](https://usehardal.com/blog/how-to-measure-chatgpt-user-traffic.md) [SNIPPET].
- [OLD, VENDOR, Aug 2025] In Cloudflare's tests, ChatGPT-User fetched robots.txt and stopped when disallowed. No follow-up came from other UAs — [Cloudflare](https://blog.cloudflare.com/perplexity-is-using-stealth-undeclared-crawlers-to-evade-website-no-crawl-directives/).

**AI referrals (clicks by people) vs crawls**
- [PRESS, 14–15 Oct 2026] ChatGPT links briefly opened with `noopener,noreferrer` and without `?utm_source=chatgpt.com`, so visits landed in "Direct". Adobe's Cedric Huesler: "There's no tag and no referrer". The next day he said "It was a bug. ChatGPT is tagging its links with utm_source=chatgpt(.)com again". Whether the Referer was also restored was not confirmed — [Search Engine Roundtable](https://www.seroundtable.com/utm-parameters-missing-chatgpt-42299.html).
- [PRESS, SNIPPET] OpenAI appends `utm_source=chatgpt.com` without `utm_medium`. Google indexed some tagged ChatGPT URLs, so some Google clicks arrive labelled ChatGPT — [Search Engine Journal](https://www.searchenginejournal.com/chatgpt-traffic-drop-appears-to-be-a-tracking-problem/); [Seer Interactive](https://www.seerinteractive.com/insights/are-ai-sites-like-chatgpt-sending-your-website-traffic).
- Known Agents markets "AI Chat Referral Tracking" to "Measure human traffic from ChatGPT, Claude, Gemini, and all other AI chat platforms", which keeps referrals apart from agent visits — [knownagents.com](https://knownagents.com/) [PRIMARY].

### Inferences
- **Expected volumes for Dian Dian are small.** One landing page should see tens to a few hundred AI-crawler hits a month, not thousands, so per-bot counts will be noisy week to week. Monthly totals per family are the readable unit. This is extrapolated from the kenimo49 three-site figure; I found no data for single-page sites.
- **A three-step funnel is measurable server-side:**
  1. verified `ChatGPT-User` (or Claude-User / Perplexity-User) fetches of the landing: someone's question led the assistant to read the page;
  2. visits with `utm_source=chatgpt.com` or a `chatgpt.com` Referer: a person clicked;
  3. `/go/apple`, `/go/play` taps.

  OAI-SearchBot visits explain how the page got into ChatGPT's index. GPTBot visits say nothing about people.
- Don't read a drop in ChatGPT-User as lost interest. Botify shows it can fall while ChatGPT serves answers from its index, and an October-2026-style tagging bug can move clicks into "direct". The `utm_source=chatgpt.com` count and ChatGPT-User fetches should be read together.
- The kenimo49 "Google-Extended: 1,387 hits" figure contradicts Google's statement that Google-Extended has no UA of its own. Those hits were likely spoofed, or misattributed by a list that maps the token. It is a concrete example of why the counter should treat token-only names as suspect.
- Pinterest matters for this owner: Pinterestbot re-scrapes pinned URLs to refresh metadata. Its hits track the number of pins and their refreshes, not people. Link-preview bots (WhatsApp, Discordbot, facebookexternalhit) firing usually means a person shared the link in a chat, a weak human-interest signal worth counting separately.

### Gaps
- No 2026 Cloudflare figure for the purpose split (training/search/user) was read. The latest primary numbers are from Aug 2025.
- No single-page or app-landing-page case study with AI-bot volumes was found.
- No public data was found on the ratio of ChatGPT-User fetches to actual ChatGPT click-throughs for a given page.
- Reddit and forum discussions were not searched in depth.
