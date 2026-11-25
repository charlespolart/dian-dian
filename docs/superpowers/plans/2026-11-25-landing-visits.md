# Compteur de visites du site (chantier 1) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le site compte ses visites, ses visiteurs du jour et ses clics vers chaque store, dit d'où viennent les gens dans les limites de l'exemption CNIL, et nomme les robots, sans cookie de mesure et sans garder d'adresse IP.

**Architecture:** Un dossier autonome `backend/src/audience/` : des fonctions pures (lecture du `User-Agent`, table des robots, site d'origine), trois états en mémoire (empreintes du jour, plages d'IP des robots, base des pays) et un compteur qui additionne en mémoire puis écrit des lignes agrégées par jour dans PostgreSQL, hors du chemin de la réponse. Le site (`routes/landing.ts`) l'appelle sur `GET /` et sur deux redirections nouvelles, `/go/apple` et `/go/play`. Rien n'est lu par un écran : `scripts/prod-landing.sql`.

**Tech Stack:** Node 22 (`net.BlockList`, `fetch`, `zlib`), Express 4, drizzle-orm 0.45 / drizzle-kit 0.31, PostgreSQL 16. Deux dépendances nouvelles : `isbot` 5.2 (Unlicense) et `maxmind` 5.1 (MIT). Données : DB-IP IP-to-Country Lite (CC BY 4.0), listes d'IP publiées par les opérateurs de robots.

**Spec:** `docs/superpowers/specs/2026-11-23-landing-visits-design.md` (avec ses sections « Relecture » et « Passe de confirmation ») ; `docs/CONFIRMATION.md`, points 4 à 7 ; `docs/ROADMAP.md` §3 (le `ct` Apple) ; recherche `docs/research/reports/Mesure de trafic auto hébergée.md` et ses notes.

## Global Constraints

- Branche `feat/landing-visits`, partie de `master`. Pas de release, pas de déploiement : tout sort dans la release unique.
- **Jamais gardé, ni en base ni dans un journal** : une adresse IP, un `User-Agent` complet, une valeur `utm_*`, une URL de provenance entière. La base ne reçoit que des comptes.
- **Aucun cookie de mesure, aucun script tiers.** Le seul cookie ajouté est celui de l'opposition, posé à la demande du visiteur.
- **Le comptage ne coûte rien à la page** : il ne retarde pas la réponse et ne peut pas la faire échouer. Base en panne, liste introuvable, valeur imprévue : la page et les redirections répondent comme si le compteur n'existait pas.
- Le sel du jour et les empreintes vivent en mémoire seulement ; le sel est tiré au hasard, jamais dérivé d'un secret ni de la date, jamais écrit.
- Le dossier `audience/` ne dépend de Dian Dian que par la connexion à la base (`Db`, le type de `db` dans `src/db/index.ts`) et par une configuration passée à sa création (domaine, sites d'origine connus, réglage du repli).
- Le VPS a environ 490 Mo libres. Mesuré le 2026-11-25 (tâche 7) : la base des pays occupe 21 Mo une fois dépliée (4 Mo téléchargés), et le processus grossit d'environ 60 Mo au chargement ; pendant le rechargement mensuel, l'ancienne et la nouvelle coexistent un instant. Toutes les autres structures en mémoire ont un plafond.
- Pas `ua-parser-js` (AGPL), pas MaxMind GeoLite.
- Migration générée par `npx drizzle-kit generate`, jamais écrite à la main.
- Les apps 1.4.0 installées ne voient aucun changement (elles n'appellent que `/api/*`).
- Tests d'abord, pour chaque tâche. Les fonctions qui dépendent du réseau ou de l'horloge reçoivent `fetch` et `now` en paramètres, pour être testées sans réseau.
- Jamais « validé par la CNIL » dans un texte.
- Changelog : une entrée sous « Unreleased » dans `backend/CHANGELOG.md`, en anglais.

## Choix de Fable (validés par Charles le 2026-11-25)

La spec laisse ces points au constructeur. Charles a validé le plan et ces choix (« oui go »), avec un changement au point 9 : la fiche du playbook s'écrit directement dans le playbook (« pour le playbook tu peux modifier »).

1. **Opposition : la visite n'est pas comptée du tout.** Cookie d'opposition, en-tête `Sec-GPC: 1` ou `DNT: 1` : aucune ligne, pas même un total. Coût : les totaux sont un peu sous le vrai (les navigateurs qui envoient ces signaux par défaut, Brave et Firefox en navigation privée surtout).
2. **Les robots sont comptés à part, sans détail.** Une ligne par jour, famille, nom et vérification ; pas d'appareil, de pays ni d'origine pour eux.
3. **Un `ChatGPT-User` hors des plages d'OpenAI garde son nom, marqué « non vérifié »**, et le script ne compte que les vérifiés dans « lectures demandées à une IA ».
4. **Valeurs bornées.** Le site d'origine et le nom d'un robot viennent d'en-têtes que n'importe qui écrit. Au-delà de 300 combinaisons nouvelles dans une journée, le reste part dans une ligne « autre » : personne ne peut remplir la table.
5. **Écriture toutes les 5 secondes.** Les comptes s'additionnent en mémoire et partent en une requête. Un redémarrage du serveur perd au plus 5 secondes de visites (et recommence les visiteurs uniques du jour, déjà accepté par la spec).
6. **Chemins inconnus : une page 404 pour le site, du JSON 404 pour `/api/*`.**
7. **Page d'opposition : `/privacy/audience`**, un bouton qui pose ou retire le cookie (`dd_noaudience`, 13 mois).
8. **Le registre commence ici** : `docs/REGISTRE.md` avec la seule fiche « Mesure d'audience du site » ; le lot suivant (registre complet) ajoute les autres.
9. **La fiche du playbook est écrite directement dans le playbook** (`~/Documents/Coding/playbook/infrastructure/mesure-audience.md`, avec un renvoi depuis `legal/rgpd.md` et l'index du `README.md`), laissée non committée là-bas et signalée à Charles.
10. **Conservation** : lignes du jour gardées 25 mois, puis remplacées par un total par mois (visites, clics par store, passages de robots). Les visiteurs uniques ne s'additionnent pas d'un jour à l'autre : ils ne sont pas repris dans le total mensuel.

## Review Focus

1. **Des en-têtes hostiles** : un `Referer` différent à chaque requête, un `User-Agent` de 10 000 caractères ou vide, un nom de robot inventé. La table reste bornée (choix 4), rien n'est copié tel quel en base.
2. **Des adresses IP sous toutes leurs formes** : IPv4, IPv6, IPv4 écrite en IPv6 (`::ffff:203.0.113.7`), valeur absente ou illisible. Le pays et la vérification répondent « inconnu » / « non vérifié », jamais une exception.
3. **Le réseau qui manque** : liste d'IP introuvable, JSON invalide, fichier des pays tronqué ou énorme, délai dépassé, au démarrage comme au rafraîchissement. Le site répond, les données précédentes restent en service.
4. **Minuit UTC et les redémarrages** : une visite à 23:59:59 et une à 00:00:01, une écriture à cheval sur deux jours, un serveur relancé à midi. Chaque visite tombe dans son jour, le sel change à minuit.
5. **La base en panne pendant une écriture** : la page répond, les comptes en attente sont réessayés, et la mémoire reste bornée si la panne dure.

---

### Task 1: Tables et migration

**Files:**
- Create: `backend/src/audience/schema.ts`
- Modify: `backend/drizzle.config.ts` (`schema: ['./src/db/schema.ts', './src/audience/schema.ts']`), `backend/src/db/index.ts` (le schéma du compteur ajouté à `drizzle(client, { schema })`)
- Create: `backend/drizzle/0018_landing_visits.sql` et `backend/drizzle/meta/*` (générés)

**Interfaces:**
- Produces: `audienceCounts`, `audienceTotals`, `audienceMonths` (tables drizzle).

- [ ] **Step 1: Écrire les trois tables dans `audience/schema.ts`**

`audience_counts` — une ligne par jour et par combinaison, incrémentée. Toutes les dimensions sont `text NOT NULL DEFAULT ''` (la chaîne vide veut dire « sans objet » : une clé primaire ne compare pas les `NULL`).

| Colonne | Valeurs |
|---|---|
| `day` | `date`, jour UTC |
| `kind` | `visit` · `store_tap` |
| `store` | `apple` · `play` · `''` |
| `origin` | nom de domaine du site d'origine, `other`, ou `''` |
| `origin_from` | `referer` · `tag` (repli `utm_source`) · `''` |
| `tagged` | `boolean NOT NULL DEFAULT false` : un `utm_source` était présent |
| `device` | `iphone` · `ipad` · `android` · `desktop` · `other` · `''` (robot) |
| `browser` | `safari` · `chrome` · `firefox` · `edge` · `samsung` · `opera` · `other` · `''` |
| `in_app` | `pinterest` · `instagram` · `facebook` · `tiktok` · `''` |
| `lang` | `en` · `fr` · `zh-CN` · `zh-TW` · `''` |
| `country` | code ISO à deux lettres, `''` si inconnu |
| `bot_family` | `''` (une personne) · `ai_user` · `ai_search` · `ai_training` · `search` · `preview` · `other` · `fake` |
| `bot_name` | nom du robot, `other`, ou `''` |
| `bot_check` | `verified` · `unverified` · `unverifiable` · `''` |
| `count` | `integer NOT NULL` |

Clé primaire : toutes les colonnes sauf `count`. Index sur `day`.

`audience_totals` — une ligne par jour, les personnes seulement : `day date PRIMARY KEY`, `visits`, `visitors`, `taps_apple`, `taps_play` (`integer NOT NULL DEFAULT 0`).

`audience_months` — ce qui reste après 25 mois : `month date PRIMARY KEY` (premier jour du mois), `visits`, `taps_apple`, `taps_play`, `bot_hits` (`integer NOT NULL DEFAULT 0`).

- [ ] **Step 2: Générer et appliquer la migration**

Run: `cd backend && npx drizzle-kit generate --name landing_visits && npx drizzle-kit migrate`
Expected: `drizzle/0018_landing_visits.sql` contient trois `CREATE TABLE` et rien d'autre ; `psql` montre les trois tables.

- [ ] **Step 3: Typecheck, puis commit**

Run: `cd backend && npx tsc --noEmit` — Expected: aucune erreur.

### Task 2: Lire un `User-Agent` (fonctions pures)

**Files:**
- Create: `backend/src/audience/classify.ts`, `backend/src/audience/classify.test.ts`
- Modify: `Makefile` et `.github/workflows/release.yml` (les tests deviennent `npx tsx --test "src/**/*.test.ts"`), `README.md` et `docs/FABLE.md` (la même commande)

**Interfaces:**
- Produces:
  ```ts
  export type Device = 'iphone' | 'ipad' | 'android' | 'desktop' | 'other';
  export type Browser = 'safari' | 'chrome' | 'firefox' | 'edge' | 'samsung' | 'opera' | 'other';
  export type InApp = 'pinterest' | 'instagram' | 'facebook' | 'tiktok' | '';
  export function classifyClient(userAgent: string | undefined): { device: Device; browser: Browser; inApp: InApp };
  ```

- [ ] **Step 1: Écrire les tests, avec de vrais `User-Agent`**

Un cas par ligne, la chaîne complète dans le test :

| `User-Agent` | Attendu |
|---|---|
| Safari sur iPhone (`… iPhone OS 18_6 … Version/18.6 Mobile/15E148 Safari/604.1`) | `iphone`, `safari`, `''` |
| Chrome sur iPhone (`… CriOS/138.0 …`) | `iphone`, `chrome`, `''` |
| Chrome sur Android (`… Android 15; Pixel 8 … Chrome/138.0.0.0 Mobile Safari/537.36`) | `android`, `chrome`, `''` |
| Samsung Internet (`… SamsungBrowser/27.0 …`) | `android`, `samsung`, `''` |
| Safari sur iPad qui se dit iPad | `ipad`, `safari`, `''` |
| Safari sur Mac (aussi l'iPad en mode bureau) | `desktop`, `safari`, `''` |
| Edge sur Windows (`… Chrome/138 … Edg/138 …`) | `desktop`, `edge`, `''` |
| Firefox sur Linux, Opera (`OPR/`) sur Windows | `desktop`, `firefox` ; `desktop`, `opera` |
| App Pinterest sur iPhone (`… Mobile/15E148 [Pinterest/iOS]`) | `iphone`, `other`, `pinterest` |
| App Pinterest sur Android (`… ; wv) … Chrome/… [Pinterest/Android]`) | `android`, `other`, `pinterest` |
| App Instagram sur iPhone (`… Mobile/15E148 Instagram 339.0.3.12.91 (iPhone15,2; …)`) | `iphone`, `other`, `instagram` |
| App Facebook (`… [FBAN/FBIOS;FBAV/470.0 …]`, et `FB_IAB/FB4A` sur Android) | `other`, `facebook` |
| App TikTok (`… musical_ly_34.5.0 … BytedanceWebview/…`) | `other`, `tiktok` |
| `undefined`, `''`, `curl/8.7.1`, une chaîne de 10 000 `a` | `other`, `other`, `''`, sans exception et en moins de 5 ms |

Dans une app, le navigateur est `other` : c'est la colonne `in_app` qui parle.

- [ ] **Step 2: Lancer les tests, les voir échouer**

Run: `cd backend && npx tsx --test src/audience/classify.test.ts` — Expected: FAIL (`classifyClient` n'existe pas).

- [ ] **Step 3: Écrire `classifyClient`**

Expressions maison, dans cet ordre : app intégrée, puis appareil (Android avant Apple, comme `lib/storePlatform.ts`), puis navigateur (Edge, Opera et Samsung avant Chrome ; Chrome et Firefox avant Safari). La chaîne est coupée à 512 caractères avant toute expression.

- [ ] **Step 4: Tests verts, la commande de tests élargie, commit**

Run: `make test` — Expected: les tests de `src/lib` et de `src/audience` passent.

### Task 3: Reconnaître les robots (fonctions pures)

**Files:**
- Create: `backend/src/audience/bots.ts`, `backend/src/audience/bots.test.ts`
- Modify: `backend/package.json` (`isbot`)

**Interfaces:**
- Produces:
  ```ts
  export type BotFamily = 'ai_user' | 'ai_search' | 'ai_training' | 'search' | 'preview' | 'other' | 'fake';
  /** `ranges` : le nom de la liste d'IP qui couvre ce robot (une clé de `RANGE_SOURCES`, Task 6), quand son opérateur en publie une. */
  export type Bot = { family: BotFamily; name: string; ranges: string | null };
  export function detectBot(userAgent: string | undefined, signatureAgent: string | undefined): Bot | null;
  ```

- [ ] **Step 1: Écrire les tests**

La table de la spec, jeton par jeton (famille · liste d'IP) :

| Famille | Jetons |
|---|---|
| `ai_user` | ChatGPT-User · Claude-User · Perplexity-User · MistralAI-User · DuckAssistBot · Google-Agent (toutes vérifiables) ; Amzn-User · meta-externalfetcher · Google-GeminiNotebook (sans liste) ; l'en-tête `Signature-Agent: "https://chatgpt.com"` → `ChatGPT-Agent` |
| `ai_search` | OAI-SearchBot · Claude-SearchBot · PerplexityBot · MistralAI-Index (vérifiables) ; Amzn-SearchBot · meta-webindexer |
| `ai_training` | GPTBot · ClaudeBot · anthropic-ai · CCBot (vérifiables) ; Bytespider · meta-externalagent · Amazonbot · MistralAI-Training |
| `search` | Googlebot · Applebot (vérifiables) ; bingbot · DuckDuckBot · YandexBot |
| `preview` | Pinterestbot · `Pinterest/0.2` · facebookexternalhit · WhatsApp · Discordbot · Twitterbot · Slackbot · TelegramBot · GoogleMessages |
| `other` | OAI-AdsBot (vérifiable) · GoogleOther · Google-CloudVertexBot ; puis ce que `isbot` reconnaît, sous le nom trouvé |
| `fake` | Google-Extended ou Applebot-Extended dans un `User-Agent` |

Cas qui piègent, chacun avec son test :
- la chaîne Chrome complète d'OAI-SearchBot → `ai_search`, pas une personne ;
- `Pinterest/0.2 (+http://www.pinterest.com/bot.html)` → robot ; `… [Pinterest/iOS]` → `null` (une personne dans l'app) ;
- `Applebot-Extended` → `fake`, pas `search` ; `meta-externalagent` → `ai_training`, pas `meta-externalfetcher` ;
- un robot que seul `isbot` connaît (`AhrefsBot/7.0`) → `other`, nom `AhrefsBot` ;
- un nom trouvé par `isbot` est réduit à `[A-Za-z0-9._-]`, 40 caractères au plus ; vide après nettoyage → `other` ;
- un vrai Safari, `undefined`, `''` → `null` ;
- une majuscule de différence (`chatgpt-user`) est reconnue.

- [ ] **Step 2: Voir les tests échouer** — Run: `npx tsx --test src/audience/bots.test.ts` — Expected: FAIL.

- [ ] **Step 3: Écrire la table et `detectBot`**

La table est une liste `{ token, family, name, ranges }` cherchée n'importe où dans la chaîne, sans tenir compte de la casse, les jetons les plus longs d'abord. `isbot` (`isbotMatch`) ne sert qu'après la table. Un commentaire en tête dit que la table se relit chaque trimestre face à `ai.robots.txt` et `crawler-user-agents`.

- [ ] **Step 4: Tests verts, commit.**

### Task 4: Le site d'origine (fonction pure)

**Files:**
- Create: `backend/src/audience/origin.ts`, `backend/src/audience/origin.test.ts`

**Interfaces:**
- Produces:
  ```ts
  export type Origin = { site: string; from: 'referer' | 'tag' | ''; tagged: boolean };
  export function originOf(input: {
    referer: string | undefined;        // l'en-tête Referer
    utmSource: unknown;                 // req.query.utm_source
    ownHost: string;                    // 'diandian.overridedev.com'
    knownSites: Record<string, string>; // utm_source nettoyé → nom de site
    tagFallback: boolean;
  }): Origin;
  export const KNOWN_SITES: Record<string, string>;
  ```

- [ ] **Step 1: Écrire les tests**

| Entrée | Attendu |
|---|---|
| `Referer: https://www.pinterest.com/pin/123/?x=1` | `{ site: 'pinterest.com', from: 'referer', tagged: false }` |
| `Referer: https://chatgpt.com/`, `utm_source=chatgpt.com` | `chatgpt.com`, `referer`, `tagged: true` (le `Referer` passe avant) |
| pas de `Referer`, `utm_source=chatgpt.com` | `chatgpt.com`, `tag`, `true` |
| pas de `Referer`, `utm_source=pinterest` | `pinterest.com`, `tag`, `true` |
| pas de `Referer`, `utm_source=newsletter-42` | `''`, `''`, `true` (hors liste : seul le drapeau reste) |
| le même, `tagFallback: false`, avec `utm_source=pinterest` | `''`, `''`, `true` |
| `Referer: https://diandian.overridedev.com/?lang=fr&utm_source=x` | `''`, `''`, `false` (le site n'est jamais sa propre origine) |
| `Referer: android-app://com.pinterest/` | `''` (pas un site) |
| `Referer: not a url`, `Referer` de 5 000 caractères, `utm_source` tableau ou objet | `''`, sans exception |
| `Referer: https://M.Facebook.com/` | `facebook.com` (`www.`, `m.`, `l.`, `lm.` retirés, minuscules) |
| un nom d'hôte de plus de 60 caractères, ou une adresse IP | `other` |

`KNOWN_SITES` de départ : `pinterest` et `pinterest.com` → `pinterest.com` ; `chatgpt.com`, `chatgpt`, `openai` → `chatgpt.com` ; `instagram`, `facebook`, `tiktok`, `youtube`, `reddit`, `x`, `twitter` → `x.com` pour les deux derniers ; `perplexity`, `claude`, `gemini`, `copilot` vers leur domaine. Les clés sont comparées après le même nettoyage que `campaignParam` de `landing.ts`.

- [ ] **Step 2: Voir échouer.** — [ ] **Step 3: Écrire `originOf`.** — [ ] **Step 4: Tests verts, commit.**

### Task 5: Les visiteurs du jour (en mémoire)

**Files:**
- Create: `backend/src/audience/visitors.ts`, `backend/src/audience/visitors.test.ts`

**Interfaces:**
- Produces:
  ```ts
  export function createVisitors(deps: { now: () => Date; randomBytes: (n: number) => Buffer; max?: number }): {
    /** Vrai la première fois de la journée (UTC) pour ce domaine, cette IP et ce User-Agent. */
    isNew(domain: string, ip: string, userAgent: string): boolean;
  };
  ```

- [ ] **Step 1: Écrire les tests** (horloge et hasard injectés)

- même IP et même `User-Agent` deux fois le même jour → `true` puis `false` ;
- autre IP, ou autre `User-Agent`, ou autre domaine → `true` ;
- 23:59:59 puis 00:00:01 UTC, même visiteur → `true` deux fois, et `randomBytes` a été appelé une seconde fois (nouveau sel) ;
- deux instances avec des sels différents ne donnent pas la même empreinte (l'empreinte dépend du sel) ;
- au-delà de `max` empreintes (200 000 par défaut, 3 dans le test), `isNew` répond `false` sans grossir : la mémoire est bornée.

- [ ] **Step 2: Voir échouer.** — [ ] **Step 3: Écrire `createVisitors`** : `SHA-256(sel ‖ domaine ‖ IP ‖ User-Agent)` dans un `Set`, sel de 32 octets tiré à la première visite de chaque jour UTC. — [ ] **Step 4: Tests verts, commit.**

### Task 6: Vérifier un robot par son adresse

**Files:**
- Create: `backend/src/audience/ipRanges.ts`, `backend/src/audience/ipRanges.test.ts`

**Interfaces:**
- Consumes: `Bot.ranges` (Task 3).
- Produces:
  ```ts
  export type BotCheck = 'verified' | 'unverified' | 'unverifiable';
  export const RANGE_SOURCES: Record<string, string>; // nom de liste → URL
  export function createIpRanges(deps: { fetch: typeof fetch; sources?: Record<string, string> }): {
    refresh(): Promise<void>;                       // recharge chaque liste ; une liste en échec garde sa version précédente
    check(ranges: string | null, ip: string | undefined): BotCheck;
  };
  ```

`RANGE_SOURCES` : les quatorze fichiers relevés dans `docs/research/notes/Mesure de trafic auto hébergée/robots_et_ia.md` (OpenAI ×4, Perplexity ×2, Anthropic, Google ×2, Apple, DuckDuckGo, Common Crawl, Mistral ×2 ; la spec en comptait onze, avant OAI-AdsBot, Google-Agent et MistralAI-Index), format commun `{ prefixes: [{ ipv4Prefix } | { ipv6Prefix }] }`.

- [ ] **Step 1: Écrire les tests** (faux `fetch`)

- une IP dans une plage IPv4 de la liste → `verified` ; hors plage → `unverified` ; une plage IPv6 aussi ;
- `::ffff:203.0.113.7` est lue comme `203.0.113.7` ;
- `ranges: null` → `unverifiable`, quelle que soit l'IP ;
- avant tout `refresh`, ou IP `undefined` / illisible → `unverified` ;
- un `fetch` qui échoue, répond 500, renvoie du HTML, un JSON sans `prefixes`, ou un préfixe invalide parmi des bons : aucune exception, la liste précédente reste en service (les bons préfixes d'un fichier partiellement invalide sont pris) ;
- une réponse de plus de 2 Mo est refusée.

- [ ] **Step 2: Voir échouer.** — [ ] **Step 3: Écrire `createIpRanges`** : un `net.BlockList` par liste, reconstruit puis échangé d'un coup ; délai de 10 s par fichier (`AbortSignal.timeout`). — [ ] **Step 4: Tests verts.**

- [ ] **Step 5: Vérifier une fois les vraies listes, puis commit**

Run: un script jetable qui appelle `refresh()` avec le vrai `fetch` et compte les préfixes par liste.
Expected: quatorze listes chargées, des nombres proches des notes de recherche (237 pour `chatgpt-user`, 317 pour les robots courants de Google). Un écart se note dans le registre de la tâche et, s'il vient du format, se corrige ici.

### Task 7: Le pays

**Files:**
- Create: `backend/src/audience/country.ts`, `backend/src/audience/country.test.ts`
- Modify: `backend/package.json` (`maxmind`)

**Interfaces:**
- Produces:
  ```ts
  export function countryDatabaseUrl(now: Date): string; // https://download.db-ip.com/free/dbip-country-lite-YYYY-MM.mmdb.gz
  export function createCountries(deps: { fetch: typeof fetch; now: () => Date }): {
    refresh(): Promise<void>;                 // le fichier du mois, sinon celui du mois précédent ; en échec, l'ancien reste
    countryOf(ip: string | undefined): string; // 'FR', ou '' si inconnu
  };
  ```

- [ ] **Step 1: Écrire les tests** (faux `fetch`, un petit fichier MMDB de test construit par le test)

- `countryDatabaseUrl(2026-11-25)` → `…/dbip-country-lite-2026-11.mmdb.gz` ; `2027-01-01` → `…-2027-01…` ;
- avant tout `refresh` → `''` ; IP `undefined`, `'abc'`, IP privée → `''` ;
- le fichier du mois répond 404 (le 1er du mois, avant sa publication) → celui du mois précédent est demandé ;
- un fichier tronqué, non compressé, ou de plus de 64 Mo une fois décompressé → aucune exception, l'ancien reste ;
- `::ffff:` devant une IPv4 est retiré.

- [ ] **Step 2: Voir échouer.** — [ ] **Step 3: Écrire `createCountries`** : `zlib.gunzip` avec une taille maximale, `new Reader(buffer)` du paquet `maxmind`, lecture de `country.iso_code`. — [ ] **Step 4: Tests verts.**

- [ ] **Step 5: Vérifier une fois le vrai fichier, puis commit**

Run: un script jetable : `refresh()` avec le vrai `fetch`, puis `countryOf` sur l'adresse du VPS et sur `8.8.8.8`.
Expected: `FR` et `US`. La spec demandait de vérifier que `maxmind` lit bien le fichier de DB-IP : c'est ici. S'il ne le lit pas, arrêt et question à Charles (le paquet `mmdb-lib` seul, ou une autre base).

### Task 8: Le compteur (additionner, écrire, purger)

**Files:**
- Create: `backend/src/audience/counter.ts`, `backend/src/audience/counter.test.ts`

**Interfaces:**
- Consumes: les tables de la Task 1.
- Produces:
  ```ts
  export type Hit = {
    kind: 'visit' | 'store_tap'; store: '' | 'apple' | 'play';
    origin: string; originFrom: 'referer' | 'tag' | ''; tagged: boolean;
    device: string; browser: string; inApp: string; lang: string; country: string;
    botFamily: string; botName: string; botCheck: string;
  };
  export function createCounter(deps: { write: (batch: Batch) => Promise<void>; now: () => Date; maxNewPerDay?: number }): {
    add(hit: Hit, newVisitor: boolean): void; // ne lève jamais, ne fait aucune entrée-sortie
    flush(): Promise<void>;                   // écrit ce qui attend ; en échec, le garde pour la fois suivante
  };
  export type Batch = { counts: Array<Hit & { day: string; count: number }>; totals: Array<{ day: string; visits: number; visitors: number; tapsApple: number; tapsPlay: number }> };
  export function writeBatch(db: Db): (batch: Batch) => Promise<void>; // les deux upserts, en une transaction
  export function rollUpOldDays(db: Db, now: Date): Promise<void>;      // au-delà de 25 mois : total du mois, puis suppression
  ```

- [ ] **Step 1: Écrire les tests de l'addition** (faux `write`, horloge injectée)

- trois visites identiques → une ligne `count: 3` ; une visite différente → une seconde ligne ;
- une personne compte dans `totals` (`visits`, et `visitors` si `newVisitor`) ; un robot ne compte pas dans `totals` ; un clic d'une personne compte dans `taps_apple` ou `taps_play`, celui d'un robot non ;
- deux visites de part et d'autre de minuit UTC → deux jours ;
- `write` qui échoue → rien n'est perdu, le `flush` suivant écrit le tout ; après 10 échecs de suite, ce qui attend est abandonné et l'abandon journalisé une fois (mémoire bornée) ;
- la 301ᵉ combinaison nouvelle du jour (4ᵉ dans le test) est repliée : origine `other` pour une personne, nom `other` pour un robot, et les autres dimensions gardées ;
- `flush` sans rien en attente n'appelle pas `write`.

- [ ] **Step 2: Voir échouer.** — [ ] **Step 3: Écrire `createCounter`.** — [ ] **Step 4: Tests verts.**

- [ ] **Step 5: Écrire `writeBatch` et `rollUpOldDays`, vérifiés par la suite smoke (Task 10)**

`writeBatch` : `INSERT … ON CONFLICT (clé) DO UPDATE SET count = audience_counts.count + EXCLUDED.count`, de même pour les totaux. `rollUpOldDays` : dans une transaction, somme par mois des jours de plus de 25 mois vers `audience_months`, puis suppression de ces jours dans les deux tables.

- [ ] **Step 6: Commit.**

### Task 9: Assembler le module

**Files:**
- Create: `backend/src/audience/index.ts`, `backend/src/audience/index.test.ts`

**Interfaces:**
- Consumes: Tasks 2 à 8.
- Produces:
  ```ts
  export type AudienceConfig = { domain: string; knownSites: Record<string, string>; tagFallback: boolean };
  export type AudienceRequest = { method: string; ip: string | undefined; headers: Record<string, string | string[] | undefined>; query: Record<string, unknown>; cookies?: Record<string, string> };
  export function createAudience(config: AudienceConfig, deps: { counter; visitors; ipRanges; countries }): {
    visit(req: AudienceRequest, lang: string): void;
    storeTap(req: AudienceRequest, store: 'apple' | 'play', lang: string): void;
    objects(req: AudienceRequest): boolean; // cookie d'opposition, Sec-GPC: 1 ou DNT: 1
  };
  export const OPT_OUT_COOKIE = 'dd_noaudience';
  export function startAudience(config: AudienceConfig, db: Db): ReturnType<typeof createAudience>; // crée le tout et lance les minuteries
  ```

- [ ] **Step 1: Écrire les tests** (dépendances factices, on regarde les `Hit` reçus par le compteur)

- une visite d'une personne → un `Hit` avec ses dimensions, `botFamily: ''` ;
- cookie `dd_noaudience=1`, ou `Sec-GPC: 1`, ou `DNT: 1` → aucun `Hit`, et ni l'IP ni le `User-Agent` ne sont lus ;
- une requête `HEAD`, ou avec `Sec-Purpose: prefetch`, `Purpose: prefetch` ou `X-Moz: prefetch` → aucun `Hit` ;
- un robot → un `Hit` avec famille, nom, vérification, et rien d'autre (appareil, navigateur, pays, origine, langue vides) ;
- un clic store → `kind: 'store_tap'`, l'origine ne vient que du repli `utm_source` (jamais du `Referer`, qui est la page du site elle-même) ;
- une dépendance qui lève (compteur, pays, vérification) → `visit` ne lève pas.

- [ ] **Step 2: Voir échouer.** — [ ] **Step 3: Écrire `createAudience` et `startAudience`**

Minuteries de `startAudience`, toutes `unref()` : écriture toutes les 5 s ; listes d'IP au démarrage puis chaque jour ; base des pays au démarrage puis chaque jour (le fichier ne change qu'une fois par mois, la demande quotidienne ne fait que rattraper un échec ou un nouveau mois) ; purge à 25 mois au démarrage puis chaque jour. Aucun démarrage n'attend le réseau.

- [ ] **Step 4: Tests verts, commit.**

### Task 10: Le site : `/go/*`, le `ct` par source, la politique de provenance, les 404

**Files:**
- Modify: `backend/src/routes/landing.ts`, `backend/src/index.ts`, `backend/src/lib/env.ts` (`AUDIENCE_TAG_FALLBACK`, activé sauf `off`), `backend/scripts/smoke.ts`
- Create: `backend/public/robots.txt`

**Interfaces:**
- Consumes: `startAudience`, `KNOWN_SITES` (Tasks 4 et 9).

- [ ] **Step 1: Réécrire les vérifications du site dans `smoke.ts`, les voir échouer**

- la page reçue avec `?utm_source=pinterest&utm_campaign=mood-en` porte un lien `/go/play?utm_source=pinterest&utm_campaign=mood-en` et un lien `/go/apple?…`, et plus aucun `apps.apple.com` ni `play.google.com` ; sans campagne, `/go/apple` et `/go/play` nus ; iPhone → `/go/apple` seul, Android → `/go/play` seul ;
- `GET /go/play?utm_source=pinterest&utm_campaign=mood-en` (sans suivre) → 302, `Location` contient `referrer=utm_source%3Dpinterest%26utm_campaign%3Dmood-en`, `Cache-Control: no-store` ;
- `GET /go/apple?utm_source=pinterest&utm_campaign=mood-en` → 302 vers `apps.apple.com/app/id6761432329` ; quand le serveur a `APPLE_CAMPAIGN_PT`, `ct=pinterest` (la source seule, plus `pinterest-mood-en`) ;
- `GET /` et `GET /go/play` répondent avec `Referrer-Policy: strict-origin-when-cross-origin` ; `GET /privacy` garde `no-referrer` ;
- `GET /wp-login.php` → 404 avec une page qui lie vers `/` ; `GET /api/nope` → 404 JSON ; `GET /privacy`, `/terms`, `/legal`, `/contact`, `/app-ads.txt`, `/favicon.png` → 200 comme avant ;
- en local seulement (serveur et base sur cette machine) : une visite avec `Referer: https://smoke-<run>.example/` et un `User-Agent` d'iPhone, puis une avec `ChatGPT-User`, puis un clic `/go/apple` ; dans les 8 secondes, la base montre une ligne `visit` d'origine `smoke-<run>.example`, appareil `iphone`, `count: 1`, une ligne robot `ai_user` / `ChatGPT-User` / `unverified`, une ligne `store_tap` / `apple` ; la même visite refaite après cette écriture porte la ligne à `count: 2` (une écriture s'ajoute à la précédente, comme après un redémarrage) ; avec `DNT: 1`, rien ne s'ajoute ; puis les lignes de ce passage sont effacées.

- [ ] **Step 2: Brancher le compteur et les routes**

- `landing.ts` : les boutons pointent vers `/go/apple` et `/go/play` (avec `utm_source` et `utm_campaign` nettoyés, `rel="nofollow noopener"`) ; les deux routes comptent puis redirigent en 302 vers le lien que `storeLinks()` construit ; `ct` = la source seule.
- `Referrer-Policy: strict-origin-when-cross-origin` sur `/` et `/go/*` seulement.
- `index.ts` : la redirection de tout chemin inconnu vers `/` devient une 404 (page dans le style du site, quatre langues, lien vers l'accueil ; JSON pour `/api/*`). Avant de la retirer, relever chaque adresse du site que le serveur ou l'app fabrique (`grep` de `diandian.overridedev.com` et de `APP_URL` dans `backend/src` et `flutter_app/lib`) et vérifier que chacune est une vraie route. Vu le 2026-11-25 : la seule adresse sans route est `/verify-email`, dans `sendVerificationEmail` (`lib/email.ts`), que rien n'appelle.
- `robots.txt` : `Disallow: /go/` (les robots polis ne suivent pas les boutons).
- `GET /` appelle `audience.visit` après avoir envoyé la page ; l'IP est `req.ip`.

- [ ] **Step 3: Suite smoke verte en local ; vérifier `req.ip` en dev**

Run: la suite smoke. Expected: `smoke: OK`. Puis une requête avec `X-Forwarded-For: 203.0.113.9` vers le serveur local : `req.ip` vaut `203.0.113.9` (`trust proxy 1`). La même vérification en production est sur la liste de Charles (après le déploiement : `prod-landing.sql` doit montrer plusieurs pays, pas un seul).

- [ ] **Step 4: Commit.**

### Task 11: Lecture — `scripts/prod-landing.sql`

**Files:**
- Create: `backend/scripts/prod-landing.sql`
- Modify: `README.md` (la ligne des scripts)

- [ ] **Step 1: Écrire le script** (le test `prodScripts.test.ts` le tient déjà en lecture seule)

Sections : totaux par jour sur 30 jours, exacts (visites, visiteurs, clics App Store, clics Google Play, taux de clic) ; par mois et par dimension, une section chacune — site d'origine (avec la part venue du repli), app intégrée, appareil, pays, lien marqué —, les cellules sous 10 affichées `<10` ; clics store par app intégrée (le bouton App Store s'ouvre-t-il depuis Pinterest ?) ; robots par famille et par nom, vérifiés à part ; « lectures demandées à une IA » = `ai_user` vérifiés seulement ; totaux mensuels anciens (`audience_months`).

- [ ] **Step 2: Le lancer sur des lignes d'essai** (transaction annulée, comme pour `prod-purchases.sql`) et relire chaque section. — [ ] **Step 3: Commit.**

### Task 12: Volet légal et opposition

**Files:**
- Modify: `backend/src/routes/legal.ts` (politique de confidentialité ×4 langues, page `/privacy/audience`), `backend/src/routes/landing.ts` (pied de page), `backend/scripts/smoke.ts`
- Create: `docs/REGISTRE.md`

- [ ] **Step 1: Vérifications smoke d'abord, les voir échouer**

- `GET /privacy?lang=fr` contient la section « Mesure d'audience du site », un lien vers `/privacy/audience` et ne dit plus « aucun autre outil d'analyse » ; les quatre langues ont la section ;
- `GET /privacy/audience` → 200 ; `POST /privacy/audience` avec `choice=out` pose `dd_noaudience=1` (13 mois, `HttpOnly`, `SameSite=Lax`) ; avec `choice=in`, le retire ; une visite avec ce cookie n'est pas comptée ;
- le pied de page du site porte le lien « IP Geolocation by DB-IP » (demandé par la licence) et une ligne « Mesure d'audience sans cookie », liée à `/privacy/audience`, dans la langue de la page.

- [ ] **Step 2: Écrire les textes et la page**

La section dit, dans chaque langue : ce qui est compté (visites, clics vers les stores, site d'origine, appareil, pays), ce qui ne l'est pas (pas de cookie de mesure, pas d'adresse IP ni de `User-Agent` gardés, rien de relié à un compte), la durée (25 mois, puis des totaux par mois), l'hébergement (France), le droit de s'y opposer (le lien, et les signaux GPC et DNT respectés). La section « Cookies » mentionne le cookie d'opposition.

- [ ] **Step 3: Écrire `docs/REGISTRE.md`** : la fiche « Mesure d'audience du site » au format du modèle simplifié de la CNIL (finalité, données, durées, destinataires, hébergeur et son avenant, mesures), avec le risque résiduel du repli `utm_source` et sa justification, mot pour mot depuis la spec.

- [ ] **Step 4: Suite smoke verte, commit.**

### Task 13: Journal, documents, brouillon du playbook

**Files:**
- Modify: `backend/CHANGELOG.md`, `README.md`, `docs/ROADMAP.md` §3, `docs/FABLE.md` (« Ce que Charles fait »)
- Create (hors de ce dépôt) : `~/Documents/Coding/playbook/infrastructure/mesure-audience.md` ; modifier là-bas `legal/rgpd.md` et `README.md` (renvois)

- [ ] **Step 1: Changelog et documents.** Ce que Charles fait après le déploiement : demander à Vultr son avenant de traitement et le citer au registre ; lancer `prod-landing.sql` une semaine après et vérifier que les pays sont variés ; relire la table des robots chaque trimestre.
- [ ] **Step 2: La fiche du playbook** : liste de contrôle CNIL, texte de politique de confidentialité, forme des tables, règles du classifieur de robots, rafraîchissement des listes et de la base des pays, script de lecture.
- [ ] **Step 3: `make test` et la suite smoke sur l'arbre final, commit.**

## Hors périmètre

- Le registre complet du projet, la politique de confidentialité des événements produit et leur purge à 13 mois : le lot suivant.
- Un écran, un tableau de bord, une alerte.
- La vérification des robots par DNS inverse (Pinterest, Bing) et par signature HTTP (Web Bot Auth) : ils restent « invérifiables ».
- L'attribution d'une installation à une visite (interdite par Apple) et l'Install Referrer Android (abandonné le 2026-11-23).
- Un paquet partagé : seulement quand un deuxième projet adopte le compteur.
