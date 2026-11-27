# Utiliser l'app sans réseau (chantier 10) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tout ce qui se fait dans les trackers avec du réseau se fait sans : chaque modification s'écrit d'abord dans une copie complète du compte sur le téléphone, attend dans une file, part au retour du réseau, et le serveur l'écarte si l'élément a changé ailleurs entre-temps, en le disant.

**Architecture:** Côté serveur, chaque élément reçoit un numéro de version tiré d'un compteur propre au compte, les suppressions laissent une trace, et deux routes nouvelles : envoyer une suite de modifications (jugées une à une, sans jamais en appliquer une deux fois) et recevoir ce qui a changé depuis un numéro donné. Les routes d'aujourd'hui restent, pour les apps 1.4.0, et numérotent aussi ce qu'elles écrivent. Côté app, une base SQLite par compte tient la copie et la file. Les trois providers gardent leur interface (les écrans ne changent presque pas), mais lisent cette base et écrivent par elle. Un moteur de synchronisation envoie la file, applique ce qui arrive, et réveille l'app quand le réseau revient. Ce chantier apporte aussi la session longue dont le hors-ligne a besoin.

**Tech Stack:** Backend Node 22 / Express 4 / drizzle 0.45 / PostgreSQL 16. App Flutter 3.47.5, paquets nouveaux : `sqflite` (base du téléphone), `sqflite_common_ffi` (tests seulement), `connectivity_plus` (retour du réseau), `uuid` (identifiants créés par l'app). Versions exactes à prendre au moment de la tâche (dernière stable compatible avec Dart 3.13, vérifiée sur pub.dev et dans le changelog).

**Spec:** `docs/superpowers/specs/2026-11-26-offline-sync-design.md` (cas H1 à H29, règles, « Ce que cela touche »), avec ce qu'elle reprend de `docs/superpowers/specs/2026-11-25-account-later-design.md` (règles « Session »). Les cas illustrés : `docs/superpowers/specs/2026-11-26-sans-compte-hors-ligne-stories.html`.

**Estimation :** 12 à 15 jours de construction, plus les essais de Charles sur deux téléphones. C'est la plus grosse pièce de la release.

## Global Constraints

- Branche `feat/offline-sync`, partie de `master` une fois le chantier 3 fusionné. Pas de release.
- **Les apps 1.4.0 continuent de marcher** sur le nouveau serveur : mêmes routes, mêmes réponses, mêmes messages en direct. Toutes leurs écritures sont numérotées comme des changements (spec, « Les anciennes versions »).
- **Le téléphone d'abord** : aucun geste n'attend le réseau ; l'écran lit toujours la copie du téléphone.
- **Une modification et son entrée dans la file s'écrivent dans la même transaction SQLite.**
- **Jamais appliquée deux fois** : chaque modification a un identifiant (UUID v4) ; le serveur garde le résultat 90 jours et le rend tel quel à un renvoi.
- **L'horloge du téléphone ne décide de rien** : l'ordre est celui de la file, les conflits se jugent sur les numéros du serveur.
- **Une modification qui a attendu n'est jamais refusée pour la limite gratuite ni le verrou** (décision de Charles, « pas dramatique »).
- **Un refus de session n'efface jamais la copie ni la file**, sauf compte supprimé à la demande (H24).
- **Jamais `dart format`** dans `flutter_app` ; garde-fous `flutter analyze`, `flutter test`, `git diff --stat`. Migrations par `npx drizzle-kit generate`.
- Textes en quatre langues (`en`, `fr`, `zh-CN`, `zh-TW`) dans `language_provider.dart`, ceux de la spec mot pour mot en français.
- Toute table nouvelle entre au registre (`registre.test.ts` échoue sinon), avec sa durée et sa purge.
- Changelogs : `backend/CHANGELOG.md` et `flutter_app/CHANGELOG.md`, sous « Unreleased ».

## Choix de Fable (la spec les laisse au constructeur ; à valider par Charles)

1. **SQLite par `sqflite`**, un fichier par compte (`dian_<userId>.db`). Une transaction couvre la modification et sa file. Un fichier par compte donne d'office ce que demande H25 : une copie cachée qui attend la reconnexion à ce compte, sans se mélanger à un autre. Écartés : `drift` (génération de code, plus lourd pour notre taille), Hive et Isar (pas de transaction sur deux « tables »).
2. **Le numéro de version.** Un compteur par compte (`users.rev`), incrémenté dans chaque transaction d'écriture (`UPDATE users SET rev = rev + 1 … RETURNING rev`, qui sérialise les écritures d'un même compte). Chaque élément porte deux numéros :
   - `rev`, la dernière fois qu'il a changé, quelle qu'en soit la raison : c'est ce que la synchronisation envoie ;
   - `edit_rev`, la dernière fois qu'il a été modifié directement : c'est ce que le conflit compare. Recolorier une légende change le `rev` de ses jours, pas leur `edit_rev` (H29).

   Les éléments sans ligne propre ont leur numéro dans une colonne : l'ordre des trackers et le choix des trackers ouverts sur `users`, l'ordre des légendes et le contenu d'un tracker (`content_rev` : tout ce qu'il contient, pour la suppression, H21) sur `pages`, chaque réglage (thème, langue, curseur) sur `users`.
3. **Les suppressions laissent une trace** (table `deletions` : compte, genre, clé, numéro, date). Elles sont gardées 24 mois, comme le souvenir des comptes du document du compte, puis purgées.
4. **Le protocole.**
   - `POST /api/sync/mutations` reçoit au plus 100 modifications dans l'ordre, chacune `{id, kind, waited, base, data}`. Le serveur les juge et les applique une à une, chacune dans sa transaction. Il répond pour chacune : `applied` (avec les nouveaux numéros), `changed` (modifiée ailleurs, avec la version du serveur), `deleted` (supprimée ailleurs) ou `rejected` (avec la raison, H12).
   - `GET /api/sync?since=N` rend tout ce dont le `rev` dépasse N, les traces de suppression, les ordres et réglages changés, Premium et le numéro actuel du compte. `since=0`, ou un N plus vieux que la plus vieille trace gardée, rend la copie complète (`full: true`).
   - Un message en direct `sync {rev}` dit aux autres téléphones d'aller chercher la suite. Les messages d'aujourd'hui restent envoyés, pour 1.4.0.
5. **H28 sans mémoire d'appareil.** Le serveur compare seulement `edit_rev` et le `base` reçu. C'est le téléphone qui ne compte jamais ses propres modifications : quand le serveur accuse réception d'une modification de l'élément E, l'app remplace le `base` des modifications suivantes de E par le nouveau numéro. Un renvoi après une réponse perdue reçoit le résultat gardé, et donc le même numéro. Une modification pas encore partie est fusionnée avec la suivante du même élément (seul le dernier état part, avec le `base` de la première) ; une modification déjà partie ne l'est jamais.
6. **« A attendu »** : posé sur une modification quand elle est écrite alors que l'app est hors ligne, ou quand son premier envoi échoue. Une modification partie du premier coup n'a pas attendu : dernier qui écrit gagne (H27).
7. **Retour du réseau** : `connectivity_plus` (changement d'interface), le retour au premier plan, la reconnexion du canal en direct, et un nouvel essai avec un délai qui double de 5 s à 2 min. Joindre le serveur est le seul vrai test.
8. **La session longue.** Jeton de rafraîchissement de 548 jours (18 mois, plus que les 12 mois du document du compte), renouvelé à chaque usage. Un jeton remplacé reste valable tant que son remplaçant n'a jamais servi : une réponse perdue ne déconnecte plus. Un refus porte sa raison (`code` : `session_expired`, `session_revoked`, `account_deleted`). Seul `account_deleted` efface la copie ; les autres mènent à « Reconnectez-vous » en gardant la copie et la file.
9. **Revenir en arrière** (spec, « Ce qui reste incertain ») : le serveur garde les routes d'aujourd'hui, donc une app reconstruite depuis le tag 1.4.0 avec un numéro de version plus grand marche sur le nouveau serveur ; elle ignorerait la base du téléphone et relirait le serveur. C'est la sortie de secours, écrite dans la tâche 12, sans code à double.
10. **Hors de ce chantier, laissé au chantier 9** : l'usage sans compte (H13 s'appuie sur le compte sans identité), envoyer une copie entière au serveur (cas 85), la limite de 1 Mo par demande (elle ne gêne pas des envois de 100 modifications), la vérification de la session à chaque requête. Ce chantier construit la copie et la file pour un compte connecté ; le chantier 9 y branche le compte sans identité.

## Review Focus

1. **L'app tuée au milieu d'une écriture, ou d'un envoi** : rien n'est à moitié écrit, rien n'est perdu, rien n'est appliqué deux fois au renvoi.
2. **Deux téléphones, l'un en mode avion** : chaque cas H17 à H29 donne ce que dit la spec, et les deux finissent identiques.
3. **Une app 1.4.0 et une app nouvelle sur le même compte** (H26) : la vieille voit en direct ce que fait la nouvelle, et ses écritures font écarter ce qui a attendu sur la nouvelle.
4. **Des semaines hors ligne** : la session tient, le compteur monte, tout part dans l'ordre au retour, y compris une création de tracker suivie de jours coloriés dedans.
5. **La première ouverture après la mise à jour** (H15), en ligne puis hors ligne : la copie complète arrive, ou l'app le dit avant qu'une modification soit tentée.

---

### Task 1: Numéros de version et traces de suppression (serveur)

**Files:**
- Modify: `backend/src/db/schema.ts`
- Create: `backend/src/lib/revs.ts`, `backend/src/lib/revs.test.ts`; migration `backend/drizzle/0020_sync_revs.sql` (générée)
- Modify: `backend/src/routes/{cells,pages,legends}.ts`, `backend/src/routes/auth.ts` (réglages), `backend/scripts/smoke.ts`

**Interfaces:**
- Produces:
  ```ts
  // schema: users.rev, users.pagesOrderRev, users.keepFreeRev, users.themeRev, users.languageRev, users.cursorRev (bigint, default 0)
  //         pages.rev, pages.editRev, pages.contentRev, pages.legendsOrderRev; legends.rev, legends.editRev; cells.rev, cells.editRev
  //         deletions(userId, kind 'page'|'legend'|'cell', key text, pageId uuid|null, rev bigint, deletedAt) index (userId, rev)
  export async function nextRev(tx: Tx, userId: string): Promise<number>;
  export function cellKey(pageId: string, year: number, month: number, day: number): string; // 'pageId:yyyy-mm-dd'
  ```
- La migration remplit les numéros des lignes existantes à 1 (et `users.rev` à 1) : tout ce qui existe vaut « version 1 ».

- [ ] **Step 1: Tests smoke d'abord** : après chaque écriture des routes d'aujourd'hui, `users.rev` a augmenté et l'élément porte ce numéro (`rev` et `edit_rev`) ; supprimer un jour, une légende, un tracker écrit une trace ; la remise à zéro d'une année et le recoloriage en masse numérotent chaque jour touché (ce sont des changements pour la règle du conflit) ; recolorier ou réordonner les légendes, renommer un tracker, colorier un de ses jours augmentent `pages.content_rev`. Les voir échouer.
- [ ] **Step 2: Colonnes, table `deletions`, migration**, vérifier le SQL généré (ajouts seulement, valeurs par défaut, remplissage à 1).
- [ ] **Step 3: `nextRev` et `cellKey`**, test unitaire de `cellKey` ; puis chaque route d'écriture prend un numéro dans sa transaction et le pose (une route qui n'avait pas de transaction en ouvre une).
- [ ] **Step 4: Smoke vert, `npx tsc --noEmit`, tests unitaires, commit.**

### Task 2: Juger et appliquer une modification (serveur)

**Files:**
- Create: `backend/src/sync/mutations.ts` (types, validation zod, jugement), `backend/src/sync/apply.ts` (application par genre), `backend/src/sync/mutations.test.ts`
- Modify: `backend/src/db/schema.ts` (table `sync_mutations` : id uuid clé, userId, result jsonb, createdAt), migration générée

**Interfaces:**
- Produces:
  ```ts
  export type MutationKind =
    | 'cell.set' | 'cell.clear'
    | 'page.create' | 'page.update' | 'page.delete' | 'pages.reorder' | 'pages.keep'
    | 'legend.create' | 'legend.update' | 'legend.delete' | 'legends.reorder'
    | 'setting.set';
  export type Mutation = { id: string; kind: MutationKind; waited: boolean; base: number | null; data: Record<string, unknown> };
  export type MutationResult =
    | { id: string; status: 'applied'; revs: Record<string, number> }   // élément, contenu du tracker, compte
    | { id: string; status: 'changed'; current: unknown }               // la version du serveur, pour le message
    | { id: string; status: 'deleted' }
    | { id: string; status: 'rejected'; reason: 'invalid' | 'legend_limit' | 'not_found' };
  /** Pure : le jugement, d'après ce que le serveur a de l'élément. */
  export function judge(m: Mutation, element: { exists: boolean; editRev: number; tombstoned: boolean }): 'apply' | 'changed' | 'deleted';
  export async function applyMutation(tx: Tx, userId: string, m: Mutation): Promise<MutationResult>;
  ```
  `data` par genre : `cell.set {pageId, year, month, day, color, comment}` ; `cell.clear {pageId, year, month, day}` ; `page.create {id, title, palette?, legends?: [{id, color, label}]}` ; `page.update {id, title?, palette?}` ; `page.delete {id}` (base = `content_rev`) ; `pages.reorder {ids}` ; `pages.keep {ids}` ; `legend.create {id, pageId, color, label}` ; `legend.update {id, label?, color?}` (une couleur changée recolorie les jours du tracker sans toucher leur `edit_rev`) ; `legend.delete {id}` ; `legends.reorder {pageId, ids}` ; `setting.set {key: 'theme'|'language'|'cursor', value}`.

- [ ] **Step 1: Tests de `judge`** (purs) : pas attendu → `apply` quoi qu'il en soit ; attendu et `editRev == base` → `apply` ; attendu et différent → `changed` ; élément absent ou sous une trace → `deleted` ; une création → `apply` sauf si son identifiant est sous une trace (`deleted`) ; une modification dans un tracker supprimé → `deleted`.
- [ ] **Step 2: Les voir échouer, écrire `judge`, verts.**
- [ ] **Step 3: `applyMutation` par genre**, avec les règles : les identifiants viennent de l'app (refuser un identifiant déjà pris par un autre compte : `rejected/invalid`) ; jamais de refus pour la limite ou le verrou si `waited` ; en ligne (`waited: false`), mêmes contrôles qu'aujourd'hui (`routes/cells.ts:18`, `routes/pages.ts:102`), qui rendent `rejected` ; 12 légendes au plus (`rejected/legend_limit`) ; chaque application donne un numéro, pose `rev`/`edit_rev`/`content_rev` et les traces, et diffuse en direct `sync {rev}` et l'événement d'aujourd'hui (pour 1.4.0).
- [ ] **Step 4: Tests (base locale, comme `smoke.ts`) par genre** : appliqué, écarté, refusé ; recolorier une légende ne change pas l'`edit_rev` des jours ; une suppression de tracker attendue, quand un de ses jours a changé ailleurs, est écartée (H21).
- [ ] **Step 5: Commit.**

### Task 3: Les routes de synchronisation (serveur)

**Files:**
- Create: `backend/src/routes/sync.ts`, `backend/src/lib/syncStats.ts`
- Modify: `backend/src/index.ts` (route, limite de débit), `backend/src/db/schema.ts` (table `sync_stats` : semaine, genre, nombre ; aucun compte), `backend/src/lib/retention.ts` (purges : `sync_mutations` à 90 jours, `deletions` à 24 mois), `backend/scripts/smoke.ts`

**Interfaces:**
- Produces:
  - `POST /api/sync/mutations` `{mutations: Mutation[]}` (1 à 100) → `{results: MutationResult[], rev}`. Une modification déjà traitée rend le résultat gardé, mot pour mot.
  - `GET /api/sync?since=N` → `{rev, full, pages, legends, cells, deletions, pagesOrder?, keepFree?, legendsOrder?, settings?, premium, vip}` ; les lignes portent `rev` et `editRev` (et `contentRev`, `legendsOrderRev` pour un tracker).

- [ ] **Step 1: Smoke d'abord** : un envoi rend un résultat par modification, dans l'ordre ; le même envoi rejoué rend les mêmes résultats sans rien réappliquer ; `GET /api/sync?since=0` rend tout le compte, toutes années ; après une modification, `since=<rev d'avant>` ne rend qu'elle ; une suppression arrive comme trace ; un `since` plus vieux que la plus vieille trace rend `full: true` ; une app 1.4.0 (routes d'aujourd'hui) voit son `bootstrap` inchangé.
- [ ] **Step 2: Les routes**, chaque modification dans sa transaction, l'idempotence par `sync_mutations` dans la même transaction que l'effet (comme `keepAndApply` du webhook RevenueCat, `routes/purchase.ts`).
- [ ] **Step 3: La mesure** (spec, « Mesure ») : par semaine, synchronisations qui envoient des modifications qui ont attendu, nombre de modifications, écartées par raison ; `backend/scripts/prod-sync.sql`, en lecture seule (tenu par `prodScripts.test.ts`).
- [ ] **Step 4: Purges et registre** : `retention.ts` purge `sync_mutations` (90 jours) et `deletions` (24 mois), avec leurs tests ; `docs/REGISTRE.md` nomme `sync_mutations`, `deletions`, `sync_stats` (sinon `registre.test.ts` échoue).
- [ ] **Step 5: Smoke et tests verts, commit.**

### Task 4: La session longue (serveur et app)

**Files:**
- Modify: `backend/src/routes/auth.ts` (émission, `/refresh`), `backend/src/db/schema.ts` (`refresh_tokens.replacedBy`, `usedAt`), `backend/src/middleware/auth.ts` (codes de refus), `backend/scripts/smoke.ts`
- Modify: `flutter_app/lib/services/api_service.dart`, `flutter_app/lib/providers/auth_provider.dart`, `flutter_app/test/api_service_test.dart`

**Interfaces:**
- Produces: les refus de session répondent `401 {error, code}` avec `code ∈ {'session_expired','session_revoked','account_deleted','invalid'}`. Côté app :
  ```dart
  enum SessionEnd { reconnect, accountDeleted }
  // AuthProvider: SessionEnd? get sessionEnded; ApiService ne vide plus le stockage sur un refus, sauf accountDeleted.
  ```

- [ ] **Step 1: Smoke d'abord** : un jeton de rafraîchissement dure 548 jours ; présenter l'ancien jeton après une rotation dont le nouveau n'a jamais servi rend une nouvelle paire (réponse perdue) ; une fois le nouveau utilisé, l'ancien est refusé avec `session_revoked` ; un compte supprimé rend `account_deleted`.
- [ ] **Step 2: Serveur**, puis smoke vert.
- [ ] **Step 3: Tests de l'app d'abord** (`api_service_test.dart`) : un refus `session_revoked` ne supprime ni la copie ni le jeton tant que l'utilisateur ne s'est pas reconnecté, et met `AuthProvider.sessionEnded = reconnect` ; `account_deleted` met `accountDeleted` ; une panne réseau pendant un renouvellement ne déconnecte pas (comme aujourd'hui, `RefreshOutcome.offline`).
- [ ] **Step 4: App**, tests verts, commit.

### Task 5: La base du téléphone et la file (app)

**Files:**
- Create: `flutter_app/lib/data/local_store.dart`, `flutter_app/lib/data/mutation_queue.dart`, `flutter_app/lib/data/mutation.dart`, `flutter_app/test/local_store_test.dart`, `flutter_app/test/mutation_queue_test.dart`
- Modify: `flutter_app/pubspec.yaml` (`sqflite`, `uuid` ; `sqflite_common_ffi` en dev), `flutter_app/test/helpers.dart` (une base en mémoire pour les tests)

**Interfaces:**
- Produces:
  ```dart
  class LocalStore {
    static Future<LocalStore> open(String userId, {DatabaseFactory? factory}); // dian_<userId>.db, schéma versionné
    static Future<void> deleteFor(String userId);
    // Lecture : la copie (état affiché, modifications en attente comprises)
    Future<List<PageModel>> pages(); Future<Map<String, List<LegendModel>>> legends(); Future<YearCells?> cells(String pageId, int year);
    Future<Map<int, Set<String>>> allFilledDays(); // stats « depuis toujours »
    Future<int> lastRev(); Future<bool> hasFullCopy();
    /// Écrit l'effet local et l'entrée de file dans la même transaction.
    Future<void> apply(Mutation m, void Function(Transaction tx) localEffect);
    /// Ce qui vient du serveur ; ignore les éléments qui ont une modification en attente.
    Future<void> applyServer(SyncDelta delta);
  }
  class Mutation { final String id; final String kind; final String elementKey; final int? base; final Map<String, dynamic> data; bool waited; bool sent; }
  class MutationQueue {
    Future<List<Mutation>> pending({int limit = 100});
    Future<int> count();
    /// Fusionne avec une modification du même élément pas encore partie (H28).
    Future<void> enqueue(Transaction tx, Mutation m);
    Future<void> markSent(List<String> ids); Future<void> markWaited();
    /// Retire les résultats reçus ; remet à jour le `base` des suivantes du même élément ; rend ce qui a été écarté.
    Future<List<SyncOutcome>> settle(List<MutationResultDto> results);
  }
  ```
  Tables : `pages`, `legends`, `cells` (avec `rev`, `edit_rev`, et pour un tracker `content_rev`, `legends_order_rev`), `meta` (compte, `last_rev`, copie complète faite, numéros des ordres et des réglages, dernier état de Premium), `queue` (ordre, identifiant, genre, clé de l'élément, `base`, données, attendu, parti), `pending_delete` (H14), `outcomes` (le message à montrer, H17, s'il n'a pas encore été vu).

- [ ] **Step 1: Tests d'abord, sur `sqflite_common_ffi` en mémoire** :
  - une modification et son entrée de file existent ensemble ou pas du tout (exception lancée au milieu de la transaction : ni l'une ni l'autre) ;
  - fusion : deux couleurs du même jour pas encore parties → une seule entrée, dernier état, `base` de la première ; si la première est partie, deux entrées ;
  - `settle` : un `applied` sur l'élément E remplace le `base` des suivantes de E par le numéro reçu (H28) ; `changed` / `deleted` retirent l'entrée et la rendent pour le message ; une suppression de tracker écartée retire aussi ses dépendantes (H20) ;
  - `applyServer` met à jour la copie sauf pour un élément qui a une entrée en attente ; une trace de suppression retire l'élément ;
  - une base fermée puis rouverte retrouve la file (H4) ; `deleteFor` efface le fichier.
- [ ] **Step 2: Les voir échouer, écrire, verts, commit.**

### Task 6: Le moteur de synchronisation (app)

**Files:**
- Create: `flutter_app/lib/data/sync_engine.dart`, `flutter_app/lib/data/connectivity.dart`, `flutter_app/test/sync_engine_test.dart`
- Modify: `flutter_app/pubspec.yaml` (`connectivity_plus`)

**Interfaces:**
- Consumes: `LocalStore`, `MutationQueue` (tâche 5), les routes de la tâche 3.
- Produces:
  ```dart
  enum SyncState { online, offline, syncing }
  class SyncEngine extends ChangeNotifier {
    SyncState get state; int get pendingCount; int? get lastSentCount; // « Synchronisé · 31 modifications envoyées »
    List<SyncOutcome> takeOutcomes();                  // le message de H17, une fois par synchronisation
    Future<void> kick();                               // geste, retour du réseau, premier plan, message en direct
    Future<bool> flush({Duration timeout});           // avant une déconnexion ou un geste de compte
  }
  ```
  Boucle : envoyer la file par paquets de 100 → `settle` → `GET /api/sync?since=lastRev` → `applyServer` → recommencer s'il reste de la file. Une panne réseau arrête l'envoi, marque la file « a attendu » et programme un nouvel essai (5 s, doublé jusqu'à 2 min) ; un refus de session arrête tout et le dit (tâche 4).

- [ ] **Step 1: Tests d'abord, avec un faux serveur** (`MockClient`) : l'envoi part dans l'ordre et par paquets ; une panne au milieu reprend au même endroit ; une réponse perdue puis un renvoi n'applique rien deux fois (le faux serveur rend le résultat gardé) ; les écartées remontent par `takeOutcomes` une seule fois ; `pendingCount` suit la file ; le retour du réseau (faux `Connectivity`) relance l'envoi sans geste.
- [ ] **Step 2: Les voir échouer, écrire, verts, commit.**

### Task 7: Les providers sur la copie du téléphone (app)

**Files:**
- Modify: `flutter_app/lib/providers/{pages,cells,legends,premium,theme,language}_provider.dart`, `flutter_app/lib/services/sync_service.dart` (remplacé par le moteur : il n'en reste que le démarrage), `flutter_app/lib/main.dart` (démarrage, réglages, refus de session), `flutter_app/lib/data/first_tracker_decision.dart`, `flutter_app/lib/widgets/global_stats_dialog.dart`, `flutter_app/lib/widgets/legend_editor_dialog.dart`
- Modify: les tests de ces providers (`pages_provider_test.dart`, `cells_provider_test.dart`, `legends_provider_test.dart`, `first_tracker_decision_test.dart`…)

**Interfaces:**
- Consumes: `LocalStore`, `SyncEngine`.
- Produces: les providers gardent leurs méthodes publiques d'aujourd'hui (les écrans ne changent pas), mais :
  - chaque écriture construit une `Mutation` (identifiants de tracker et de légende créés par l'app, `uuid` v4), l'écrit par `LocalStore.apply`, met à jour la mémoire et prévient l'écran, puis `SyncEngine.kick()` ; plus aucun retour en arrière sur une panne réseau ;
  - `createPage` et `createFirstTracker` rendent le tracker tout de suite, réseau ou pas ;
  - recolorier une légende est **une** modification (`legend.update` avec la couleur), plus deux demandes (`legend_editor_dialog.dart:359`) ;
  - les réglages (thème, langue, curseur) passent par la file (`setting.set`) ;
  - les messages en direct d'aujourd'hui ne sont plus écoutés : seul `sync {rev}` relance le moteur ;
  - les stats « depuis toujours » se calculent sur `LocalStore.allFilledDays()` (plus d'appel à `/api/stats/days`) ;
  - le premier tracker se décide sur la copie du téléphone ;
  - la limite gratuite et le verrou s'appliquent sur ce que le téléphone sait (H7, H8).

- [ ] **Step 1: Adapter les tests existants des providers** à une base en mémoire et à un faux moteur, et ajouter : une écriture hors ligne reste affichée et compte une modification (H1, H2) ; créer un tracker hors ligne puis colorier un de ses jours fait deux modifications dans cet ordre ; recolorier une légende fait une seule modification ; H9 : au retour, un Premium perdu pendant l'absence garde tout ce qui a été fait hors ligne (trackers au-delà de 3 compris) et ouvre l'écran de choix des trackers ouverts ; un message `sync` relance le moteur ; les stats « depuis toujours » ne font aucune demande au serveur.
- [ ] **Step 2: Les voir échouer, réécrire les providers, verts.**
- [ ] **Step 3: `flutter analyze`, tous les tests, commit.**

### Task 8: La mise à jour depuis 1.4.0 et la suppression qui tient (app)

**Files:**
- Modify: `flutter_app/lib/main.dart`, `flutter_app/lib/providers/pages_provider.dart`, `flutter_app/lib/data/local_store.dart`, `flutter_app/lib/services/snapshot_store.dart` (n'est plus écrit ; supprimé après la copie complète)
- Test: `flutter_app/test/upgrade_test.dart`, `flutter_app/test/pages_provider_test.dart`

- [ ] **Step 1: Tests d'abord** :
  - H15 : une app qui démarre avec le seul fichier de 1.4.0 et du réseau télécharge la copie complète, puis efface ce fichier ; sans réseau, elle s'ouvre sur ce fichier, et une modification tentée affiche « Il faut une connexion pour finir la mise à jour de vos trackers » sans rien écrire ;
  - H14 : une suppression de tracker est écrite dans `pending_delete` ; « Annuler » pendant 8 secondes la retire ; l'app tuée pendant ce délai et rouverte la trouve acquise : le tracker reste supprimé et sa suppression est dans la file.
- [ ] **Step 2: Écrire, verts, commit.**

### Task 9: Dire où en est la synchronisation (app)

**Files:**
- Create: `flutter_app/lib/widgets/sync_banner.dart`, `flutter_app/lib/widgets/sync_outcomes_dialog.dart`, leurs tests
- Modify: `flutter_app/lib/screens/page_list_screen.dart`, `flutter_app/lib/screens/tracker_screen.dart`, `flutter_app/lib/providers/language_provider.dart`

- [ ] **Step 1: Tests d'abord** :
  - le bandeau : hors ligne sans file « Hors ligne · tout est enregistré sur ce téléphone » ; avec 3 en attente « Hors ligne · 3 modifications à envoyer » ; au retour « Synchronisé · 31 modifications envoyées », qui s'efface seul ; rien quand tout va bien ;
  - le message (H17, H20, H21, H22, H23) : un seul par synchronisation, « 2 modifications faites hors ligne n'ont pas été gardées », puis une ligne par élément avec sa raison, et pour un jour ce qui n'a pas été gardé (couleur, commentaire) ; un refus (H12) dit l'élément et la raison ; le message attend l'ouverture suivante si l'app n'est pas à l'écran.
- [ ] **Step 2: Écrire (textes de la spec en français, traduits en anglais et en chinois), verts, commit.** Le bandeau tient compte de la barre système (même règle que la bannière, chantier 3).

### Task 10: Les gestes qui demandent le réseau, la déconnexion, la fin de session (app)

**Files:**
- Modify: `flutter_app/lib/screens/settings_screen.dart`, `flutter_app/lib/widgets/custom_paywall_dialog.dart`, `flutter_app/lib/widgets/premium_gate_dialog.dart`, les écrans de connexion, `flutter_app/lib/providers/auth_provider.dart`, `flutter_app/lib/main.dart`, `language_provider.dart`

- [ ] **Step 1: Tests d'abord** :
  - H6 : acheter, restaurer, se connecter, créer un compte, supprimer ses données, écrire au support, hors ligne → « Il faut une connexion. … Vos trackers restent utilisables. », rien n'est commencé ;
  - H7 : le mur de la limite hors ligne ajoute « L'achat sera possible au retour du réseau. » ;
  - H10 : se déconnecter hors ligne avec 3 modifications en attente → la question de la spec, « Rester connecté » / « Me déconnecter quand même » ; en ligne, la file part d'abord (`flush`), puis la déconnexion efface la base du compte ;
  - H24 : `account_deleted` → écran d'accueil avec le message de la spec, base du compte effacée ;
  - H25 : `session_revoked` ou `session_expired` → « Reconnectez-vous : vos 4 modifications en attente seront envoyées. » ; se reconnecter au même compte rouvre sa base et la file part ; se connecter à un autre compte prévient qu'elles seront perdues et laisse renoncer.
- [ ] **Step 2: Écrire, verts, commit.**

### Task 11: Les cas à deux téléphones, de bout en bout (serveur)

**Files:**
- Create: `backend/scripts/sync-scenarios.ts` (lancé comme `smoke.ts`, contre un serveur local)

- [ ] **Step 1: Un scénario par cas**, avec deux « téléphones » simulés (deux files, deux `since`) sur un même compte, et une app 1.4.0 simulée par les routes d'aujourd'hui : H17, H18, H19, H20, H21, H22 (nom, légende, ordre, réglage), H23, H26, H27, H28 (y compris réponse perdue puis renvoi), H29. Chaque scénario vérifie ce que la spec annonce, et que les deux téléphones finissent avec la même copie.
- [ ] **Step 2: Vert, commit.**

### Task 12: Documents, légal, retour en arrière

**Files:**
- Modify: `backend/src/routes/legal.ts` (politique §9 et §10, quatre langues : la copie de tous les trackers sur le téléphone, la file, ce qu'il en advient à la déconnexion et dans les sauvegardes du téléphone), `docs/REGISTRE.md` (fiche 3 : la copie complète ; tables nouvelles ; durées), `backend/CHANGELOG.md`, `flutter_app/CHANGELOG.md`, `docs/FABLE.md`, `docs/ROADMAP.md`, `README.md`

- [ ] **Step 1: Smoke** : la politique des quatre langues dit la copie complète (phrase vérifiée par langue, comme au lot registre).
- [ ] **Step 2: Textes et documents**, dont la sortie de secours (choix 9) dans `docs/FABLE.md` : comment reconstruire l'app depuis `app-v1.4.0` avec un numéro plus grand si la nouvelle couche de données devait être retirée après la sortie.
- [ ] **Step 3: Essais de Charles**, deux téléphones réels, l'un en mode avion : H1 à H29 (la liste à cocher est dans la page des cas illustrés), plus une mise à jour depuis 1.4.0 hors ligne puis en ligne.
- [ ] **Step 4: Relecture neuve de toute la branche, tout corrigé (mineurs compris), fusion et push.**

## Hors périmètre

- Tout ce qui est au chantier 9 (choix 10).
- Fusionner deux versions d'un même élément, l'historique, l'annulation au-delà des 8 secondes de la suppression (non-objectifs de la spec).
- Chiffrer la base du téléphone au-delà de ce que fait le système.
- Le web : l'app web n'est pas servie ; `sqflite` ne la gère pas.
