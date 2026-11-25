# Mesure des achats (chantier 0) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le serveur garde chaque événement RevenueCat tel qu'il arrive (essai, prix, devise, environnement, raisons), et chaque événement produit de l'app porte sa plateforme et sa version.

**Architecture:** Une table `subscription_events` à côté de `subscriptions`, qui reste l'état courant. Le webhook enregistre d'abord l'événement brut, puis applique les droits comme aujourd'hui ; la lecture de l'événement devient des fonctions pures testées (`src/lib/rcEvent.ts`). `events` gagne deux colonnes facultatives que l'app remplit.

**Tech Stack:** Node 22, Express 4, drizzle-orm 0.45 / drizzle-kit 0.31, PostgreSQL 16, zod 3 ; Flutter 3.47.5 / Dart 3.13, `package_info_plus` (déjà dans le pubspec).

**Spec:** `docs/research/audit-2026-11-22.md` (« Trous de mesure », points 1 et 2), `docs/CONFIRMATION.md` (point 10, « Une seule release »), `docs/FABLE.md` (chantier 0).

## Global Constraints

- Branche `feat/purchase-measurement`, partie de `master`. Pas de release, pas de déploiement : tout sort dans la release unique.
- Les apps 1.4.0 installées continuent de marcher : rien n'est retiré ni renommé, `POST /api/events` accepte toujours `{ name }` seul.
- Aucune dépendance nouvelle, ni côté serveur ni côté app.
- Un achat ne doit jamais échouer à cause de la mesure : l'enregistrement brut ne bloque pas la mise à jour des droits.
- Le webhook répond 200 à tout événement authentifié qu'il sait lire (RevenueCat rejoue 5 fois tout autre code, sur environ 80 minutes).
- Jamais de faux achat envoyé à la production : les vérifications du webhook dans `smoke.ts` ne tournent pas quand `SMOKE_BASE` est défini.
- Jamais `dart format`. Garde-fous : `make test`, la suite smoke, `git diff --stat`.
- Migration générée par `npx drizzle-kit generate` (fichier SQL + `meta/`), jamais écrite à la main.
- Changelogs : une entrée sous « Unreleased » dans `backend/CHANGELOG.md` et `flutter_app/CHANGELOG.md`, en anglais.

## Review Focus

1. RevenueCat rejoue un événement (même `id`) : une seule ligne brute, les mêmes droits qu'après le premier passage.
2. Un événement pour un compte que le serveur ne connaît pas (compte supprimé, identifiant anonyme, événement de test) : 200, ligne brute sans compte, aucune erreur 500 qui ferait rejouer.
3. Un événement sans `app_user_id` (TRANSFER) ou d'un type inconnu du code : 200 et une ligne brute, au lieu du 400 d'aujourd'hui.
4. Un achat sandbox : reconnaissable (`environment`), et jamais compté comme une vente par le script de lecture.
5. Une plateforme ou une version que le serveur ne reconnaît pas (`macos`, `1.5.0-beta`) : l'événement est compté quand même, avec la colonne vide.

---

### Task 1: Colonnes et migration

**Files:**
- Modify: `backend/src/db/schema.ts`
- Create: `backend/drizzle/0017_purchase_measurement.sql` (généré), `backend/drizzle/meta/*` (générés)

**Interfaces:**
- Produces: `subscriptionEvents` (table drizzle) et le type `NewSubscriptionEvent = typeof subscriptionEvents.$inferInsert` ; `events.platform`, `events.appVersion`.

- [ ] **Step 1: Ajouter la table `subscription_events` et les deux colonnes à `events` dans `schema.ts`**

Colonnes de `subscription_events` (nom SQL · type · contrainte) :

| Colonne | Type | |
|---|---|---|
| `id` | uuid | clé primaire, `defaultRandom()` |
| `rc_event_id` | text | non nul, **unique** (l'`id` de l'événement RevenueCat) |
| `user_id` | uuid | nullable, référence `users.id`, `onDelete: 'cascade'` |
| `type` | text | non nul |
| `environment`, `store`, `product_id`, `period_type`, `currency`, `country_code`, `cancel_reason`, `expiration_reason`, `original_transaction_id` | text | nullable |
| `price_usd`, `price_local` | double precision | nullable |
| `is_trial_conversion` | boolean | nullable |
| `event_at` | timestamptz | non nul |
| `purchased_at`, `expires_at` | timestamptz | nullable |
| `payload` | jsonb | non nul |
| `received_at` | timestamptz | non nul, `defaultNow()` |

Index : `subscription_events_user_id_idx` sur `user_id` ; `subscription_events_type_event_at_idx` sur (`type`, `event_at`).
Sur `events` : `platform` text nullable, `app_version` text nullable.

- [ ] **Step 2: Générer la migration**

Run: `cd backend && npx drizzle-kit generate --name purchase_measurement`
Expected: `drizzle/0017_purchase_measurement.sql` créé, avec `CREATE TABLE "subscription_events"` et deux `ALTER TABLE "events" ADD COLUMN`.

- [ ] **Step 3: L'appliquer à la base locale et vérifier**

Run: `cd backend && npx drizzle-kit migrate && npx tsc --noEmit`
Expected: migration appliquée sans erreur, typecheck propre.

- [ ] **Step 4: Commit** (`schema.ts`, `drizzle/`)

---

### Task 2: Lire un événement RevenueCat (fonctions pures)

**Files:**
- Create: `backend/src/lib/rcEvent.ts`
- Test: `backend/src/lib/rcEvent.test.ts`

**Interfaces:**
- Consumes: `NewSubscriptionEvent` (Task 1).
- Produces:
  - `type RcEvent = Record<string, unknown> & { type: string }`
  - `parseRcEvent(body: unknown): RcEvent | null` — `body.event` s'il a un `type` chaîne non vide, sinon `null`.
  - `rcEventAccountId(event: RcEvent): string | null` — `app_user_id`, ou le premier élément de `transferred_to` pour un TRANSFER ; `null` s'il manque, s'il commence par `$RCAnonymousID:` ou s'il n'a pas la forme d'un uuid.
  - `subscriptionEventRow(event: RcEvent, now: Date): Omit<NewSubscriptionEvent, 'userId'> | null` — `null` si l'événement n'a pas d'`id` chaîne.
  - `type EntitlementAction = { kind: 'upsert'; store: string; productId: string; txId: string; expiresAt: Date | null } | { kind: 'deactivate'; txId: string } | { kind: 'none' }`
  - `entitlementAction(event: RcEvent): EntitlementAction` — le comportement d'aujourd'hui, à l'identique.

- [ ] **Step 1: Écrire les tests qui échouent** (`node:test` + `node:assert/strict`, comme `trackerLock.test.ts`)

Événement d'exemple, repris de la documentation RevenueCat :

```ts
const trial = {
  type: 'INITIAL_PURCHASE', id: 'EVT-1', event_timestamp_ms: 1764000000000,
  app_user_id: '4bedb450-8ef2-41e9-b475-0800200c9a66', environment: 'SANDBOX',
  store: 'APP_STORE', product_id: 'premium_yearly', period_type: 'TRIAL',
  price: 0, price_in_purchased_currency: 0, currency: 'EUR', country_code: 'FR',
  purchased_at_ms: 1764000000000, expiration_at_ms: 1764604800000,
  original_transaction_id: 'TX-1', transaction_id: 'TX-1',
  subscriber_attributes: { $email: { value: 'a@b.c' } },
};
```

Assertions :
- `parseRcEvent({ event: trial })` rend l'événement ; `parseRcEvent({})`, `parseRcEvent({ event: {} })`, `parseRcEvent(null)` rendent `null`.
- `subscriptionEventRow(trial, now)` : `rcEventId 'EVT-1'`, `type 'INITIAL_PURCHASE'`, `environment 'SANDBOX'`, `store 'APP_STORE'`, `productId 'premium_yearly'`, `periodType 'TRIAL'`, `priceUsd 0`, `priceLocal 0`, `currency 'EUR'`, `countryCode 'FR'`, `originalTransactionId 'TX-1'`, `eventAt`, `purchasedAt` et `expiresAt` aux dates des trois `_ms`.
- `payload` est l'événement **sans** `subscriber_attributes` ; l'objet reçu n'est pas modifié.
- Un événement sans `id` rend `null`. Sans `event_timestamp_ms`, `eventAt` vaut `now`.
- Champs absents, `null` ou du mauvais type (`price: 'x'`, `expiration_at_ms: null`) : colonne `null`, pas d'exception.
- Un CANCELLATION garde `cancelReason` ; un EXPIRATION `expirationReason` ; un RENEWAL `isTrialConversion: true`.
- `rcEventAccountId` : l'uuid de `trial` ; `null` pour `'$RCAnonymousID:abc'`, pour `'not-a-uuid'`, pour un événement sans `app_user_id` ; pour `{ type: 'TRANSFER', transferred_to: ['<uuid>'] }`, cet uuid.
- `entitlementAction` : `upsert` (store `'apple'`, `productId`, `txId 'TX-1'`, `expiresAt`) pour INITIAL_PURCHASE, RENEWAL, NON_RENEWING_PURCHASE, PRODUCT_CHANGE, UNCANCELLATION, SUBSCRIPTION_EXTENDED ; `deactivate` pour EXPIRATION, BILLING_ISSUE, SUBSCRIPTION_PAUSED ; `none` pour CANCELLATION, TRANSFER, SUBSCRIBER_ALIAS, TEST, un type inconnu (`'REFUND_REVERSED'`), et pour tout événement sans identifiant de transaction. `store` : `APP_STORE` et `MAC_APP_STORE` → `'apple'`, `PLAY_STORE` → `'google'`, autre → en minuscules, absent → `'unknown'`. `txId` : `original_transaction_id`, sinon `transaction_id`.

- [ ] **Step 2: Lancer, vérifier l'échec**

Run: `cd backend && npx tsx --test src/lib/rcEvent.test.ts`
Expected: FAIL (module introuvable).

- [ ] **Step 3: Écrire `rcEvent.ts`** — fonctions sans accès à la base ; lecteurs tolérants (`typeof` avant d'utiliser une valeur).

- [ ] **Step 4: Relancer** — Expected: PASS, et `npx tsc --noEmit` propre.

- [ ] **Step 5: Commit**

---

### Task 3: Le webhook enregistre tout

**Files:**
- Modify: `backend/src/routes/purchase.ts`, `backend/scripts/smoke.ts`, `.github/workflows/release.yml` (bloc `env` : `REVENUECAT_WEBHOOK_SECRET: release-checks-webhook-secret`)

**Interfaces:**
- Consumes: `parseRcEvent`, `rcEventAccountId`, `subscriptionEventRow`, `entitlementAction` (Task 2) ; `subscriptionEvents` (Task 1).

- [ ] **Step 1: Écrire les vérifications smoke qui échouent**

En tête de `smoke.ts` : `import 'dotenv/config'`. Le bloc ne tourne que si `SMOKE_BASE` n'est pas défini et que `REVENUECAT_WEBHOOK_SECRET` existe ; sinon il écrit `webhook checks skipped`. Sous `process.env.CI` sans `SMOKE_BASE`, l'absence du secret est une erreur. Placé avant le nettoyage du compte, avec `userId` du compte de test et des `id` d'événement uniques (`smoke-${Date.now()}-n`), tous en `environment: 'SANDBOX'` :

- sans en-tête `Authorization` → 401 ;
- INITIAL_PURCHASE (essai, `expiration_at_ms` dans 7 jours) → 200, puis `GET /api/purchase/status` → `premium: true` ;
- le même événement rejoué → 200 ;
- CANCELLATION → 200, toujours `premium: true` ;
- `{ type: 'TRANSFER', id, transferred_from: [uuid], transferred_to: [uuid] }` sans `app_user_id`, entre deux uuid tirés au hasard (aucun compte) → **200** (400 aujourd'hui) ;
- INITIAL_PURCHASE pour un uuid tiré au hasard → **200** (500 aujourd'hui) ;
- un type inconnu `'REFUND_REVERSED'`, avec l'`app_user_id` du compte de test → 200 ;
- EXPIRATION → 200, puis `premium: false` ;
- lecture directe de la base (`postgres(process.env.DATABASE_URL)`) : pour ce compte, 4 lignes dans `subscription_events` (achat, résiliation, `REFUND_REVERSED`, expiration : l'achat rejoué n'en fait qu'une), dont une `period_type = 'TRIAL'` et `environment = 'SANDBOX'` ; 2 lignes `user_id IS NULL` portant les `id` du TRANSFER et de l'achat du compte inconnu (supprimées en fin de bloc, le compte de test emportant les siennes).

- [ ] **Step 2: Lancer contre le serveur local, vérifier l'échec**

Run (deux terminaux, même variable) : `cd backend && REVENUECAT_WEBHOOK_SECRET=local-smoke npm run dev` puis `cd backend && REVENUECAT_WEBHOOK_SECRET=local-smoke npx tsx scripts/smoke.ts`
Expected: FAIL sur le TRANSFER (400).

- [ ] **Step 3: Réécrire le traitement du webhook dans `purchase.ts`**

Ordre : authentification (inchangée) → `parseRcEvent` (400 si `null`) → compte : `rcEventAccountId`, gardé seulement s'il existe dans `users` → ligne brute : `subscriptionEventRow`, insérée avec `onConflictDoNothing` sur `rc_event_id`, dans son propre `try/catch` (une erreur est journalisée, jamais renvoyée) → droits : `entitlementAction`, appliquée par `upsertSubscription` / `deactivateByTransaction` existants ; un `upsert` sans compte connu ne fait rien → 200 `{ ok: true }`. Les types locaux `RcEventType` / `RcEvent` et `handleRcEvent` disparaissent au profit de `rcEvent.ts`.

- [ ] **Step 4: Relancer la suite smoke** — Expected: PASS de bout en bout ; `npx tsc --noEmit` et `npx tsx --test src/lib/*.test.ts` propres.

- [ ] **Step 5: Commit**

---

### Task 4: `POST /api/events` accepte la plateforme et la version

**Files:**
- Modify: `backend/src/routes/events.ts`, `backend/scripts/smoke.ts`

**Interfaces:**
- Produces: le corps `{ name, platform?, appVersion? }` ; `platform` ∈ `ios` | `android` | `web` ; `appVersion` au format `^\d{1,3}\.\d{1,3}\.\d{1,3}$`.

- [ ] **Step 1: Vérifications smoke qui échouent** (à la suite du bloc « events » existant)

- `{ name: 'paywall.stats', platform: 'ios', appVersion: '1.5.0' }` → 204 ;
- `{ name: 'paywall.stats', platform: 'macos', appVersion: '1.5.0-beta' }` → **204** ;
- `{ name: 'paywall.stats' }` seul → 204 (déjà vrai : l'app 1.4.0) ;
- hors `SMOKE_BASE`, lecture directe : la première ligne a `platform = 'ios'` et `app_version = '1.5.0'`, la deuxième a les deux colonnes `NULL`.

- [ ] **Step 2: Lancer, vérifier l'échec** (les colonnes restent `NULL`).

- [ ] **Step 3: Étendre `eventSchema` et l'insertion** — les deux champs sont `.optional().catch(undefined)` : une valeur invalide devient absente, elle ne fait jamais un 400.

- [ ] **Step 4: Relancer** — Expected: PASS.

- [ ] **Step 5: Commit**

---

### Task 5: L'app envoie sa plateforme et sa version

**Files:**
- Modify: `flutter_app/lib/services/events_service.dart`
- Test: `flutter_app/test/events_service_test.dart`

**Interfaces:**
- Consumes: le corps de la Task 4.
- Produces: `EventsService({ApiService? api, String? platform, Future<String?> Function()? appVersion})` ; `static String? EventsService.currentPlatform()` (`'web'` si `kIsWeb`, `'ios'` ou `'android'` d'après `defaultTargetPlatform`, sinon `null`). `track(String name)` garde sa signature.

- [ ] **Step 1: Tests qui échouent**

- avec `platform: 'ios'` et `appVersion: () async => '1.5.0'`, le corps envoyé est exactement `{'name': 'paywall.tracker_limit', 'platform': 'ios', 'appVersion': '1.5.0'}` ;
- avec `platform: null` et une `appVersion` qui lève, le corps est `{'name': 'paywall.tracker_limit'}` et `track` se termine sans erreur ;
- le test « a network failure is swallowed » reste vert.

- [ ] **Step 2: Lancer, vérifier l'échec**

Run: `cd flutter_app && flutter test test/events_service_test.dart`

- [ ] **Step 3: Implémenter** — par défaut, `platform` vaut `currentPlatform()` et `appVersion` lit `PackageInfo.fromPlatform()` une fois (future statique, erreur avalée → `null`). Les clés absentes ne sont pas envoyées.

- [ ] **Step 4: `cd flutter_app && flutter analyze && flutter test`** — Expected: aucun avertissement, tous les tests verts.

- [ ] **Step 5: Commit**

---

### Task 6: Lecture et journal des changements

**Files:**
- Create: `backend/scripts/prod-purchases.sql`
- Modify: `backend/scripts/prod-events.sql`, `backend/CHANGELOG.md`, `flutter_app/CHANGELOG.md`, `README.md` (ligne des scripts), `docs/ROADMAP.md` (§2 : « fait »)

- [ ] **Step 1: Écrire `prod-purchases.sql`**, en lecture seule, même en-tête que `prod-events.sql` (commande ssh, exclusions). Toutes les sections filtrent `environment = 'PRODUCTION'` et les comptes exclus (le filtre de `prod-stats.sql`, recopié tel quel) ; les lignes sans compte sont comptées à part. Sections :
  1. événements par semaine et par type, 16 dernières semaines ;
  2. essais : démarrés (INITIAL_PURCHASE en `TRIAL`), convertis (RENEWAL avec `is_trial_conversion`), résiliés pendant l'essai (CANCELLATION en `TRIAL`), avec le délai en jours entre l'achat et la résiliation ;
  3. ventes payées (INITIAL_PURCHASE, RENEWAL, NON_RENEWING_PURCHASE avec `price_usd > 0`) par produit, store et devise : nombre, somme en USD, prix local médian ;
  4. remboursements (`price_usd < 0`) et raisons d'annulation et d'expiration ;
  5. sandbox et lignes sans compte : simples comptes, pour vérifier que rien n'y part par erreur.

- [ ] **Step 2: Ajouter à `prod-events.sql`** une section « par plateforme et version », 8 dernières semaines (`platform` vide = app 1.4.0).

- [ ] **Step 3: Les lancer sur la base locale**

Run: `psql -h localhost -p 5433 -U postgres -d dian_dian -v ON_ERROR_STOP=1 -f backend/scripts/prod-purchases.sql` (puis `prod-events.sql`)
Expected: aucune erreur SQL (tableaux vides acceptés).

- [ ] **Step 4: Changelogs, README, ROADMAP ; `make test` ; commit.**

---

### Task 7 (à valider par Charles) : les droits suivent RevenueCat

Hors de la mesure, mais dans le même fichier, trois écarts trouvés en lisant la documentation RevenueCat du 2026-11-25. Sans validation, cette tâche ne se fait pas.

1. **TRANSFER** : quand quelqu'un restaure son achat sur un autre compte, RevenueCat déplace le droit ; le serveur ne fait rien (et répondait 400). Le nouveau compte reste « gratuit » côté serveur : le 4ᵉ tracker lui est refusé (403) alors que l'app le dit Premium.
2. **BILLING_ISSUE** : le serveur coupe Premium dès l'échec de paiement, alors que la personne garde ses droits pendant le délai de grâce — celui que Charles doit activer sur Google Play (`docs/FABLE.md`).
3. **SUBSCRIPTION_PAUSED** : le serveur coupe Premium à la mise en pause, alors que l'accès ne s'arrête qu'à l'EXPIRATION.

**Files:** `backend/src/lib/rcEvent.ts`, `backend/src/lib/rcEvent.test.ts`, `backend/src/routes/purchase.ts`, `backend/scripts/smoke.ts`, `backend/CHANGELOG.md`

**Interfaces:**
- Produces: `EntitlementAction` gagne `{ kind: 'extend'; txId: string; until: Date }` et `{ kind: 'transfer'; from: string[]; to: string }`.

- [ ] **Step 1: Changer les tests de `entitlementAction`** : BILLING_ISSUE avec `grace_period_expiration_at_ms` → `extend` jusqu'à cette date, sans → `none` ; SUBSCRIPTION_PAUSED → `none` ; TRANSFER → `transfer` avec les uuid de `transferred_from` et le premier uuid de `transferred_to`, `none` si l'un des deux est vide.
- [ ] **Step 2: Vérifier l'échec, puis implémenter.** Dans la route : `extend` met `expires_at` à la date ; `transfer` rattache au compte d'arrivée, s'il existe, les abonnements des comptes de départ.
- [ ] **Step 3: Smoke** : un second compte jetable ; après un TRANSFER du premier vers le second, `GET /api/purchase/status` dit `premium: true` pour le second et `false` pour le premier ; BILLING_ISSUE avec un délai de grâce dans 3 jours → toujours `premium: true`.
- [ ] **Step 4: Suite complète verte ; changelog ; commit.**

---

## Hors périmètre

- La ligne du registre RGPD et de la politique de confidentialité pour `subscription_events` : chantier du registre.
- Les événements du parcours d'achat et l'ouverture de l'app : chantiers 2 et 4.
- Le remboursement d'un achat à vie (CANCELLATION `CUSTOMER_SUPPORT` sans EXPIRATION ?) : la documentation lue ne tranche pas ; la table brute montrera ce que RevenueCat envoie.
- La signature facultative `X-RevenueCat-Webhook-Signature`, que la documentation mentionne aujourd'hui et que le playbook dit inexistante : à proposer à Charles pour le playbook, pas dans ce lot.
