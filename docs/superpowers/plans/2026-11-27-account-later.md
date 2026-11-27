# Entrer sans mur : le compte invisible (chantier 9) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On entre dans l'app et on colorie son premier point sans créer de compte ; le compte reste proposé, jamais exigé, et une session fermée dit toujours pourquoi.

**Architecture:** Le chantier est trop gros pour un seul plan (92 cas, six sous-systèmes). Il se construit en six lots, chacun avec son plan, sa relecture et sa fusion ; ce document donne le découpage et détaille le **lot 1**. Le lot 1 pose ce dont tout le reste dépend : la session qui porte un identifiant, vérifiée à chaque requête et fermée avec sa raison ; le compte invisible (créé avec un identifiant et une clé choisis par le téléphone, rouvert par cette clé) ; l'écran d'accueil à quatre boutons ; les réglages et les messages de fin de session.

**Tech Stack:** Backend Node 22 / Express 4 / drizzle 0.45 / PostgreSQL 16. App Flutter 3.47.5 ; aucun paquet nouveau dans le lot 1 (la clé est rangée par `flutter_secure_storage`, déjà là, dans une entrée propre à l'appareil ; l'entrée synchronisée du trousseau est au lot 5).

**Spec:** `docs/superpowers/specs/2026-11-25-account-later-design.md` (cas 1 à 92, sept principes, règles « Session », « Ce que cela touche ») ; s'appuie sur le chantier 10 (`docs/superpowers/specs/2026-11-26-offline-sync-design.md`, fusionné le 2026-11-27). Cas illustrés : `docs/superpowers/specs/2026-11-26-sans-compte-hors-ligne-stories.html`.

## Les six lots

| Lot | Contenu (cas de la spec) | Dépend de | Ce qu'il faut de Charles |
|---|---|---|---|
| 1 | **Entrer sans compte, et des sessions qui disent pourquoi elles finissent** : session à identifiant vérifiée à chaque requête (règles « Session ») ; fermer les autres appareils (52) ; mot de passe changé (51) ; compte invisible et sa clé (1, 4 à 9, principe 4) ; nature du compte dite par le serveur (principe 5) ; écran d'accueil (1 à 7) ; réglages des deux formes (10, 64, 65, 66) ; messages de fin de session (7, 50 à 53) ; utilisateurs d'aujourd'hui (67 à 69) ; registre et politique | chantier 10 | rien |
| 2 | **L'e-mail par code** : créer et se connecter par code (70 à 74), mot de passe facultatif, format et limite par compte (75, 76, 78), changer d'adresse et réunir (77), relier Apple ou Google après preuve (23, 24), inscription sans code fermée pour toutes les versions | 1 | rien (Resend existe déjà) |
| 3 | **Attacher et rejoindre** : créer mon compte (14), « Ce compte existe déjà » et la règle des doubles (15 à 22), réunir deux comptes, l'invitation (11), la mesure sans identifiant de compte | 1, 2 | rien |
| 4 | **Premium sans compte** : RevenueCat identifié par le compte, le serveur vérifie auprès de RevenueCat, restaurer (31 à 36), après l'achat (12, 13, 29), Premium déplacé, repris, fini (25, 26, 42 à 47, 49), reprendre ses trackers par l'achat (37 à 41), effacements automatiques (61, 62) | 1, 3 | la clé d'API RevenueCat sur le serveur, le réglage « Transfer to new App User ID », l'achat à vie Android « non-consumable », le partage familial dans App Store Connect ; les essais en bac à sable (à la fin, avec les autres essais) |
| 5 | **La clé qui suit, la copie qui revient** : deux entrées du trousseau (règles « Session »), « Mes données » (79), retrouver par la clé (80 à 84, 87, 90 à 92), copie sans clé (85), copies supprimées à la demande (86), sauvegarde Android (88) | 1, 3, 4 | les essais sur appareils (à la fin) |
| 6 | **La clé de restauration Android** (89) | 1 | l'essai sur deux Android (à la fin) ; peut sortir de la release sans emporter le reste (décision 15) |

Chaque lot a son plan dans `docs/superpowers/plans/`, écrit quand le précédent est fusionné, avec ce que le précédent a appris. Les essais sur appareils et en bac à sable se font à la fin de la release (Charles, 2026-11-27) ; la spec dit ce qui sort si l'un échoue (« À vérifier pendant la construction »).

---

# Lot 1 — Entrer sans compte, et des sessions qui disent pourquoi elles finissent

**Estimation :** 6 à 8 jours.

## Global Constraints

- Branche `feat/account-later`, partie de `master` (chantiers 3 et 10 fusionnés). Pas de release.
- **Les apps 1.4.0 continuent de marcher** : mêmes routes, mêmes réponses ; un jeton d'accès sans identifiant de session (émis avant la mise à jour, ou par une app 1.4.0 qui se renouvelle) reste accepté jusqu'à son expiration (15 minutes) ; une session fermée répond 401 comme aujourd'hui, la raison en plus.
- **Principe 5 : invisible ou attaché, c'est le serveur qui le dit** (`kind`, `methods` dans chaque réponse d'authentification et `/api/auth/me`). L'app ne le déduit jamais de ce qu'elle a gardé.
- **Principe 4 : un compte invisible ne se perd pas par accident technique** : sa clé rouvre une session chaque fois que le jeton de rafraîchissement est refusé (sauf compte supprimé), perdu ou absent.
- **La clé est un secret** : jamais dans un fichier sauvegardé, jamais un identifiant (ni RevenueCat, ni ailleurs), gardée hachée par le serveur.
- **Une session fermée l'est tout de suite** : chaque requête vérifie que sa session existe encore, et le canal en direct de cette session se ferme en même temps.
- **Jamais `dart format`** ; garde-fous `flutter analyze`, `flutter test`, `git diff --stat`. Migrations par `npx drizzle-kit generate`. Une table nouvelle entre au registre (`registre.test.ts`).
- Textes en quatre langues (`en`, `fr`, `zh-CN`, `zh-TW`), ceux de la spec mot pour mot en français.
- Changelogs sous « Unreleased ». Après chaque tâche, les suites : backend `npx tsx --test "src/**/*.test.ts"` et smoke ; app `flutter analyze && flutter test` ; `sync-scenarios.ts` et `integration/backend_e2e_test.dart` restent verts.

## Choix de Fable (laissés au constructeur par la spec ; à valider par Charles)

1. **Une session a un identifiant** (`session_id`, gardé d'un jeton de rafraîchissement à son remplaçant) ; le jeton d'accès le porte (`sid`). `requireAuth` vérifie qu'une ligne de `refresh_tokens` porte encore ce `session_id`, avec un cache en mémoire de 10 secondes que chaque fermeture vide (un seul processus serveur). Une session fermée répond `401 {code}`, la raison lue dans `ended_sessions` (qui gagne la colonne `session_id`) : `account_deleted`, `password_changed`, `session_revoked` (déconnecté depuis un autre appareil) ; les lots 2, 3 et 5 ajoutent `merged`, `identity_added`, `joined`, `keys_merged`. Sans raison gardée (expirée, déconnexion volontaire) : `invalid`.
2. **Le compte invisible est créé avec un identifiant et une clé choisis par le téléphone** (`POST /api/auth/invisible {id, key}`, UUID v4 et 32 octets aléatoires en base64url). C'est ce qui fait marcher le cas 5 sans rien inventer : hors ligne, le téléphone ouvre déjà sa copie `dian_<id>.db` sous l'identifiant définitif, la file se remplit, et le compte naît au premier réseau, sous le même identifiant. La même demande rejouée (réponse perdue) rend une session ; un identifiant déjà pris par un autre compte, ou la même avec une autre clé, est refusé (409).
3. **La clé rouvre une session** (`POST /api/auth/key {id, key}`) : c'est le chemin de `ApiService` chaque fois que le renouvellement est refusé pour une autre raison que `account_deleted`, ou impossible faute de jeton. Elle ne change jamais ; le serveur ne garde que son empreinte (`account_keys`, une ligne par compte invisible, partie avec le compte).
4. **`users.email` devient facultatif** (la contrainte d'unicité reste : PostgreSQL y admet plusieurs NULL). Un compte est **attaché** s'il a une identité : une adresse, un mot de passe, une connexion Apple ou Google ; sinon **invisible**. `methods` liste `email`, `password`, `apple`, `google`.
5. **La création de comptes invisibles est limitée par adresse IP** : 30 par heure (un réseau partagé, une école, passe ; un robot non). Au-delà, l'app garde le compte en attente, tout s'écrit sur le téléphone, et la création est retentée plus tard sans rien dire (cas 6).
6. **La date du dernier contact** (`users.last_seen_at`), posée au renouvellement de session et à la lecture de la synchronisation, au plus une fois par heure. Les purges qui s'en servent (cas 61, 62) sont au lot 4, parce qu'elles dépendent de la mémoire des achats portés (principe 4).
7. **« Déconnecter mes autres appareils »** (`POST /api/auth/sessions/close-others`) ferme toutes les sessions du compte sauf celle qui le demande, avec la raison `session_revoked`. **Changer de mot de passe par « mot de passe oublié »** ferme toutes les sessions du compte avec `password_changed` (cas 51 ; le parcours par code du lot 2 reprendra ce même appel).
8. **L'écran d'accueil remplace l'écran de connexion** comme premier écran sans session ; « Continuer avec un e-mail » ouvre, au lot 1, l'écran de connexion et d'inscription d'aujourd'hui (le lot 2 le remplace par le parcours par code). « Créer mon compte » et « J'ai déjà un compte » arrivent au lot 3 : au lot 1, les réglages d'un compte invisible montrent la phrase du cas 10 et « Restaurer les achats », pas encore ces deux boutons.

### Après la relecture des choix (2026-11-27)

Un agent neuf a relu ces huit choix à la demande de Charles ; ses propositions, toutes retenues, priment sur le texte ci-dessus (détail dans le registre d'exécution) :

- **Choix 1 remplacé** : une table `sessions {id, user_id, created_at}` ; `refresh_tokens.session_id` obligatoire, avec suppression en cascade ; `requireAuth` lit `sessions` à chaque requête, **sans cache** ; fermer une session écrit une ligne `ended_sessions` par jeton puis supprime la session ; la déconnexion ferme toute sa session ; la purge horaire supprime les sessions sans jeton. Migration : générée, plus un remplissage (`drizzle-kit generate --custom`, une session par jeton existant), plus la contrainte.
- **Mémoire des comptes supprimés** (`deleted_accounts`, 24 mois) : `/key` répond `account_deleted`, `/invisible` refuse un identifiant supprimé.
- `/key` : clé validée (43 caractères base64url), hachée en SHA-256, comparée en temps constant, sous la limite des connexions ; réponses `account_deleted`, `unknown` (le téléphone garde sa copie et reste dans l'app), `invalid`.
- `/refresh` : un jeton dépensé ou expiré répond `invalid` ; `session_revoked` ne veut plus dire que « déconnecté depuis un autre appareil ».
- `requireAuth` : un jeton d'accès mauvais ou expiré répond 401 sans raison (l'app renouvelle) ; une session disparue répond 401 avec sa raison. L'app ne renouvelle pas pour `account_deleted`, `password_changed`, `session_revoked`.
- Le téléphone marque dans sa copie que le compte invisible est créé ; la clé est écrite et relue avant la première création, jamais refaite ; un 409 sur un compte en attente est une collision : nouvel identifiant, la copie déplacée, rien d'effacé. Un 429, 5xx ou réseau absent sur `/invisible` ou `/key` vaut hors ligne, jamais une fin de session.
- Le canal en direct vérifie la session à l'authentification et ferme les sockets d'une session fermée par `session:ended {code}`, traité dans l'app comme un 401.
- `last_seen_at` obligatoire avec `now()` par défaut, mis à jour au plus une fois par heure dans la requête même ; limite des créations invisibles réglable (`INVISIBLE_PER_HOUR`, 30 par défaut) ; l'adresse prise telle que le serveur la donne (pas d'ancienne gardée).
- Trousseau iOS « propre à l'appareil » : non synchronisé, accessibilité par défaut, jamais `*_this_device`, jamais « tout effacer ».
- Cas 66 : une suppression rejouée après une réponse perdue reçoit `account_deleted` sans le message global du cas 50 ; les réglages disent « Vos données ont été supprimées ».

## Review Focus

1. **Une session fermée, n'importe où** : le téléphone concerné cesse de lire et d'écrire à la requête suivante, son canal en direct se ferme, et il dit la raison ; un téléphone 1.4.0 retombe sur la connexion comme aujourd'hui.
2. **Le compte invisible au premier lancement sans réseau** (cas 5), puis au premier réseau : la copie et sa file, écrites sous l'identifiant du téléphone, partent vers un compte créé sous ce même identifiant, sans perte ni doublon, même si la réponse de création se perd.
3. **Un jeton refusé ou perdu sur un compte invisible** : la clé rouvre la session sans que la personne voie rien ; seul `account_deleted` mène à l'écran d'accueil.
4. **Un compte invisible n'expose jamais sa clé** : ni dans un journal, ni dans une réponse, ni dans un fichier sauvegardé, ni à RevenueCat.
5. **Les comptes d'aujourd'hui** (cas 67 à 69) : connectés, rien ne change ; déconnectés, l'écran d'accueil ; une app 1.4.0 garde ses routes, ses réponses et ses messages.

---

### Task 1: La session a un identifiant, vérifié à chaque requête (serveur)

**Files:**
- Modify: `backend/src/db/schema.ts` (`refresh_tokens.session_id`, `ended_sessions.session_id`), migration générée
- Modify: `backend/src/lib/jwt.ts` (`signAccessToken(userId, sessionId?)`, `verifyAccessToken` rend `{userId, sessionId}`)
- Create: `backend/src/lib/sessions.ts` (`sessionStatus`, cache, `forgetCachedSession`)
- Modify: `backend/src/middleware/auth.ts`, `backend/src/routes/auth.ts` (émission des jetons avec `sid`, rotation qui garde `session_id`), `backend/src/lib/ws.ts` (sockets rattachées à leur session)
- Test: `backend/src/lib/sessions.test.ts`, `backend/scripts/smoke.ts`

**Interfaces:**
- Produces: `verifyAccessToken(token): Promise<{ userId: string; sessionId: string | null }>` ; `sessionStatus(db, sessionId): Promise<'alive' | EndReason>` avec `type EndReason = 'account_deleted' | 'password_changed' | 'session_revoked' | 'invalid'` ; `req.sessionId`.

- [ ] **Step 1: Tests d'abord.** Unitaires (`sessions.test.ts`, sur une fausse base injectée) : une session vivante passe ; une session fermée rend sa raison ; le cache répond sans relire pendant 10 s et se vide par `forgetCachedSession`. Smoke : un jeton d'accès émis à la connexion porte `sid` ; la rotation garde `session_id` ; après une suppression de compte, une requête avec l'ancien jeton d'accès (encore dans ses 15 minutes) répond `401 {code: 'account_deleted'}` au lieu d'une liste vide ; un jeton sans `sid` reste accepté.
- [ ] **Step 2: Les voir échouer, écrire, verts, commit.**

### Task 2: Fermer des sessions, et le dire (serveur)

**Files:**
- Create: `backend/src/lib/closeSessions.ts` (`closeSessions(tx, userId, {except?, reason})` : supprime les jetons, garde `ended_sessions` par session, vide le cache, ferme les sockets)
- Modify: `backend/src/routes/auth.ts` (`POST /api/auth/sessions/close-others`, `reset-password` qui ferme tout avec `password_changed`, suppression de compte par `closeSessions`), `backend/src/lib/ws.ts` (`closeSessionSockets(sessionIds, code)` : envoie `session:ended {code}` puis ferme)
- Test: `backend/scripts/smoke.ts`

- [ ] **Step 1: Smoke d'abord** : deux sessions d'un même compte ; « fermer les autres » depuis la première → la seconde répond `401 {code: 'session_revoked'}` à sa requête suivante, son renouvellement aussi, et son socket reçoit `session:ended` puis se ferme ; la première continue. Mot de passe changé par code → toutes répondent `password_changed`. La purge de `ended_sessions` (548 jours) couvre les nouvelles lignes.
- [ ] **Step 2: Écrire, verts, commit.**

### Task 3: Le compte invisible (serveur)

**Files:**
- Modify: `backend/src/db/schema.ts` (`users.email` facultatif, `users.last_seen_at`, table `account_keys {user_id PK FK cascade, key_hash, created_at}`), migration générée
- Modify: `backend/src/routes/auth.ts` (`POST /invisible`, `POST /key`, `kind` et `methods` dans `login`, `register`, `oauth`, `refresh`, `/me`), `backend/src/index.ts` (limite 30/h sur `/invisible`), `backend/src/routes/sync.ts` et le renouvellement (`last_seen_at`, une fois par heure au plus)
- Modify: `backend/scripts/prod-*.sql` (le filtre des comptes de test ne doit pas écarter un e-mail absent : `coalesce(email, '')`), `docs/REGISTRE.md` (fiche 2 : le compte invisible, `account_keys`, `last_seen_at`)
- Test: `backend/src/lib/accountKind.test.ts` (nature et méthodes d'un compte), `backend/scripts/smoke.ts`, `backend/src/lib/prodScripts.test.ts` (inchangé, reste vert)

**Interfaces:**
- Produces: `POST /api/auth/invisible {id: uuid, key: string(43)}` → `201 {accessToken, refreshToken, userId, kind: 'invisible', methods: [], …profil}` ; rejouée avec la même clé → `200` même forme ; identifiant pris → `409 {code: 'taken'}`. `POST /api/auth/key {id, key}` → `200` session ; clé fausse ou compte attaché → `401 {code: 'invalid'}` ; compte supprimé → `401 {code: 'account_deleted'}`. `accountKind(user, oauthCount): {kind, methods}`.

- [ ] **Step 1: Tests d'abord** : unitaires de `accountKind` (aucun moyen → invisible ; e-mail seul, mot de passe, Apple, Google → attaché avec ses méthodes) ; smoke : créer un compte invisible, rejouer la création (même réponse, un seul compte), une autre clé sur le même identifiant (409), rouvrir par la clé, se servir de la synchronisation comme un compte normal (une modification, une lecture), supprimer le compte (la clé ne rouvre plus rien : `account_deleted`), la 31ᵉ création de l'heure depuis la même adresse (429) ; les profils disent `kind` et `methods` ; les scripts `prod-*.sql` comptent un compte invisible.
- [ ] **Step 2: Écrire, verts, commit.**

### Task 4: La session côté app : sa raison, et la clé qui la rouvre (app)

**Files:**
- Modify: `flutter_app/lib/services/api_service.dart` (raisons lues sur un 401 de n'importe quelle requête, pas seulement au renouvellement ; `KeyStore` pour la clé ; renouvellement refusé ou sans jeton → `/auth/key` ; compte pas encore créé → `/auth/invisible`), `flutter_app/lib/services/storage_service.dart` (entrée `invisible_key_<id>`, propre à l'appareil), `flutter_app/lib/providers/auth_provider.dart` (`continueWithoutAccount()`, `kind`, `methods`, `SessionEnd` étendu : `accountDeleted`, `passwordChanged`, `revoked`, `reconnect`)
- Test: `flutter_app/test/api_service_test.dart`, `flutter_app/test/auth_provider_test.dart`

**Interfaces:**
- Produces: `abstract class KeyStore { Future<String?> invisibleKey(String userId); Future<void> setInvisibleKey(String userId, String key); Future<void> deleteInvisibleKey(String userId); }` (implémenté par `StorageService`) ; `enum SessionEnd { reconnect, accountDeleted, passwordChanged, revoked }` ; `AuthProvider.continueWithoutAccount()` ; `AuthProvider.kind` (`invisible`, `attached`, null tant que le serveur n'a pas répondu) et `methods`.

- [ ] **Step 1: Tests d'abord** (faux serveur `MockClient`) : une requête qui reçoit `401 {code: 'password_changed'}` termine la session avec cette raison sans tenter de renouvellement ; un compte invisible dont le renouvellement est refusé (`invalid`) rouvre sa session par la clé sans que la session se termine ; sans jeton du tout, la clé crée le compte (`/invisible`) puis la requête passe ; `account_deleted` termine toujours ; la clé n'apparaît jamais dans un en-tête ou un journal ; `continueWithoutAccount()` hors ligne rend l'app utilisable tout de suite sous l'identifiant choisi ; une fin de session, quelle qu'elle soit, efface l'adresse gardée dans le coffre du téléphone (un compte invisible ouvert ensuite n'en montre jamais une ancienne, principe 5, cas 68).
- [ ] **Step 2: Écrire, verts, commit.**

### Task 5: L'écran d'accueil (app)

**Files:**
- Create: `flutter_app/lib/screens/welcome_screen.dart`
- Modify: `flutter_app/lib/main.dart` (premier écran sans session ; `AppScreen.welcome` ; le parcours du premier tracker pour tout nouveau compte, invisible compris), `flutter_app/lib/widgets/oauth_buttons.dart` (même taille et même poids que les deux autres boutons), `flutter_app/lib/providers/language_provider.dart`
- Test: `flutter_app/test/welcome_screen_test.dart`, `flutter_app/integration_test/offline_sync_app_test.dart` (le parcours par « Continuer sans compte »)

- [ ] **Step 1: Tests d'abord** : quatre boutons de même taille, Apple seulement sur iOS, la phrase du dessous ; « Continuer sans compte » mène au premier tracker (cas 1), hors ligne aussi (cas 5) ; hors ligne, Apple, Google et e-mail répondent « Il faut une connexion pour se connecter à un compte. Vous pouvez commencer sans compte et le créer plus tard. » ; une fenêtre Apple ou Google annulée revient sans message (cas 4) ; la création refusée pour trop de comptes (429) laisse entrer quand même (cas 6) ; sur le simulateur iOS, le parcours complet sans compte : premier tracker, jour du jour, arrivés sur le serveur sous l'identifiant du téléphone.
- [ ] **Step 2: Écrire, verts, commit.**

### Task 6: Les réglages, la suppression, et les messages de fin de session (app)

**Files:**
- Modify: `flutter_app/lib/screens/settings_screen.dart` (deux formes, cas 10 ; « Restaurer les achats » pour tous ; « Déconnecter mes autres appareils » pour un compte attaché, avec confirmation, cas 52 ; libellés et confirmation de la suppression, cas 65 ; « Suppression impossible pour l'instant, réessayez. » et la réponse perdue, cas 66), `flutter_app/lib/widgets/session_dialogs.dart` (messages des cas 7, 50, 51, 52), `flutter_app/lib/screens/tracker_screen.dart` (cas 53), `flutter_app/lib/main.dart`, `language_provider.dart`
- Test: `flutter_app/test/settings_account_test.dart`, `flutter_app/test/session_end_test.dart`, `flutter_app/test/tracker_screen_test.dart`

- [ ] **Step 1: Tests d'abord** : un compte invisible voit la phrase du cas 10, pas de « Se déconnecter », « Supprimer mes données » ; un compte attaché voit son e-mail, « Se déconnecter », « Déconnecter mes autres appareils », « Supprimer mon compte et mes données » ; la confirmation dit ce qui part, avec ses nombres, et que la suppression vaut partout ; sans réponse du serveur rien ne change ; chaque raison de fin de session a son message (cas 50, 51, 52, et H24/H25 du chantier 10) ; un tracker ouvert supprimé ailleurs le dit (cas 53).
- [ ] **Step 2: Écrire, verts, commit.**

### Task 7: Le légal, les documents, la relecture, la fusion

**Files:**
- Modify: `backend/src/routes/legal.ts` (politique, quatre langues : le compte sans identité, sa clé rangée sur le téléphone, la suppression dans l'app pour un compte créé automatiquement), `docs/REGISTRE.md`, `backend/CHANGELOG.md`, `flutter_app/CHANGELOG.md`, `docs/FABLE.md`, `README.md`
- Test: `backend/scripts/smoke.ts` (phrases de la politique par langue)

- [ ] **Step 1: Smoke d'abord** (les phrases nouvelles de la politique, par langue), puis les textes et documents.
- [ ] **Step 2: Relecture neuve de toute la branche, tout corrigé (mineurs compris), fusion dans master.** Les essais sur appareil de ce lot rejoignent la liste de la fin de la release (`docs/FABLE.md`).

## Hors du lot 1

- Créer son compte depuis un compte invisible, rejoindre un compte, l'invitation : lot 3.
- Le parcours par code, le mot de passe facultatif, le changement d'adresse : lot 2.
- Tout ce qui touche Premium sans compte et RevenueCat, et les deux effacements automatiques : lot 4.
- La clé dans le trousseau synchronisé, « Mes données », les copies restaurées : lot 5.
- La clé de restauration Android : lot 6.
