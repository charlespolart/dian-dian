# Registre RGPD et politique de confidentialité — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Le registre dit tout ce que Dian Dian fait des données, la politique de confidentialité dit la même chose en quatre langues, et ce qu'elles promettent est tenu par le code : les événements produit sont effacés à 13 mois.

**Architecture:** Trois petits changements du backend (une purge quotidienne, un drapeau d'opposition sur le compte, les polices du site servies par nous), puis deux textes écrits depuis les faits : `docs/REGISTRE.md` (une fiche par traitement, sur le modèle de la fiche 1) et la politique dans `routes/legal.ts`. Un test garde le registre à jour : toute table du schéma doit y être nommée.

**Tech Stack:** Node 22, Express 4, drizzle-orm 0.45 / drizzle-kit 0.31, PostgreSQL 16, `node:test` par `tsx`. Aucune dépendance nouvelle.

**Spec:** pas de spec propre. Ce lot est décrit par `docs/FABLE.md` (ligne « — » du tableau des chantiers), `docs/PRICING.md` (« Base légale des événements du parcours d'achat », « Conservation »), `docs/CONFIRMATION.md` point 11, l'en-tête de `docs/REGISTRE.md`, et les sections « Légal » des specs des chantiers 9 et 10, qui comptent sur un registre complet avant eux. Référence de méthode : `~/Documents/Coding/playbook/legal/rgpd.md`.

**Estimation :** 1 à 1,5 jour, au lieu du ½ jour de `docs/FABLE.md` : la lecture du code a trouvé plus à écrire et à corriger que prévu (voir « Ce que la lecture a trouvé »).

## Global Constraints

- Branche `feat/rgpd-register`, partie de `master`. Pas de release, pas de déploiement : tout sort dans la release unique.
- Backend et documents seulement, aucun code de l'app. Les apps 1.4.0 installées ne voient aucun changement : `POST /api/events` répond toujours 204.
- Le registre et la politique décrivent **ce qui existe sur `master` aujourd'hui**. Les chantiers suivants (10, 9, 2, 4, 6, 8) y ajoutent leurs lignes dans leur propre plan.
- **Chaque fait du registre a une source** : le code (fichier cité), une lecture sur le VPS (commande et date citées) ou une page d'un fournisseur (adresse et date citées). Ce qui n'a pas pu être vérifié est écrit « à relever par Charles », jamais deviné.
- Un écart est écrit comme un écart. Jamais « validé par la CNIL », jamais « conforme au RGPD » dans un texte.
- La politique existe en quatre langues (`en`, `fr`, `zh-CN`, `zh-TW`) avec les mêmes sections dans chacune. Registre en français ; code, commentaires et changelog en anglais.
- Durée des événements produit : **13 mois** (`docs/PRICING.md`).
- Migration générée par `npx drizzle-kit generate`, jamais écrite à la main.
- Tests d'abord, pour chaque tâche. Garde-fous : `npx tsc --noEmit`, `npx tsx --test "src/**/*.test.ts"`, et la suite smoke `npx tsx scripts/smoke.ts` contre un backend local (Postgres.app, port 5433).
- Changelog : entrées sous « Unreleased » dans `backend/CHANGELOG.md`.

## Ce que la lecture a trouvé (2026-11-26)

La politique actuelle (`backend/src/routes/legal.ts:146`) comparée au code :

| # | Constat | Où | Ce que ce plan en fait |
|---|---|---|---|
| 1 | Rien n'efface `events` ; PRICING promet 13 mois | `db/schema.ts:129` | Tâche 1 |
| 2 | « Aucune donnée personnelle n'est partagée avec des tiers » : faux, quatre sous-traitants en reçoivent (Vultr, Cloudflare, Resend, RevenueCat) et la politique n'en nomme qu'un | `legal.ts` §4 et §7 | Tâche 5 |
| 3 | La connexion par Apple et Google n'est pas dans la politique | `routes/auth.ts:124` | Tâche 5 |
| 4 | Ni base légale, ni droit d'opposition, ni droit de saisir la CNIL (article 13 du RGPD) | `legal.ts` §3 et §9 | Tâche 5 |
| 5 | Chaque page du site charge ses polices chez Google : l'adresse IP de chaque visiteur part chez Google, alors que le compteur de visites se dit « sans outil tiers » | `legal.ts:61`, `landing.ts:286` | Tâche 3 |
| 6 | **Publicité : l'app ne demande aucun consentement** (ni formulaire Google, ni écran ATT) avant d'afficher AdMob. En France la lecture de l'identifiant publicitaire demande un consentement, et depuis 2024 Google ne sert que des annonces limitées en Europe sans formulaire certifié | `ad_banner.dart:61`, `ad_service.dart:33` | Fiche du registre qui le dit ; correction **hors de ce lot** (c'est du code de l'app), voir choix 8 |
| 7 | Supprimer son compte laisse le client chez RevenueCat et, quelques jours, dans les sauvegardes ; la page dit « aucune donnée personnelle n'est conservée » | `auth.ts:272`, `legal.ts:757` | Tâche 5 (texte) ; RevenueCat : chantier 9, voir choix 9 |
| 8 | Les scripts `prod-*.sql` lisent des totaux sur les comptes, dont les titres de trackers portés par au moins deux trackers ; la politique n'en dit rien | `scripts/prod-trackers.sql:101` | Fiche et section de la politique |
| 9 | Des sauvegardes d'avril à août 2026 (ancien format `age`) sont peut-être encore sur le VPS, hors de toute durée annoncée | mémoire du projet | À relever (tâche 4), à supprimer par Charles |
| 10 | Un tracker est un contenu libre : rien n'empêche d'y noter son humeur ou des symptômes, qui sont des données sensibles (article 9) | `cells.comment`, `pages.title` | Écrit au registre comme risque résiduel ; rien n'est tranché |
| 11 | Les connexions refusées écrivent l'adresse IP dans la sortie du conteneur ; personne n'a noté combien de temps Docker la garde | `auth.ts:97`, `middleware/auth.ts:27` | À relever (tâche 4) |

## Choix de Fable (à valider par Charles)

Les choix 4, 5 et 6 élargissent le lot ; chacun peut être rayé, avec ce que cela coûte.

1. **Le registre décrit `master`**, pas la release finie : chaque chantier suivant ajoute sa fiche. Les specs des chantiers 9 et 10 le prévoient déjà.
2. **13 mois « au plus »** : on garde le mois en cours et les 12 précédents, comme le compteur de visites garde 25 mois. Un événement vit donc entre 12 et 13 mois. La purge tourne au démarrage puis une fois par jour.
3. **Les événements d'achat sans compte** (`subscription_events.user_id` vide : achat d'un compte supprimé depuis, identifiant anonyme, événement de test) **suivent la même règle : 13 mois** après leur réception. Ils ne servent qu'à la ligne « écartés » de `prod-purchases.sql` ; une seule durée à annoncer. Ceux d'un compte partent avec lui, comme aujourd'hui.
4. **S'opposer aux événements produit.** L'intérêt légitime (décidé le 2026-11-23) donne un droit d'opposition, et la politique doit dire comment l'exercer : en nous écrivant. Pour pouvoir le tenir, une colonne `users.events_opt_out` que Charles pose à la main sur demande ; le serveur n'écrit alors plus rien pour ce compte et répond 204 comme d'habitude. Pas de réglage dans l'app. *Rayé :* une opposition ne pourrait être tenue qu'en supprimant le compte.
5. **Les polices du site servies par nous** (DotGothic16 et Silkscreen, licence OFL, mêmes fichiers que ceux de Google, même rendu). *Rayé :* la politique doit nommer Google comme destinataire de l'adresse IP de chaque visiteur du site.
6. **La politique est corrigée partout où elle est fausse ou muette**, pas seulement augmentée d'une section sur les événements : données traitées, bases légales, sous-traitants, durées, droits. Sa date est tenue par une constante.
7. **La page « Supprimer votre compte »** dit ce qui reste : les sauvegardes pendant leur durée, et l'historique d'achat chez Apple, Google et RevenueCat.
8. **Publicité : ce lot écrit l'écart, il ne le corrige pas.** Je propose d'ajouter à la release un petit chantier « consentement publicitaire » (le formulaire de Google, déjà dans `google_mobile_ads`, affiché en Europe avant la première bannière) ; à décider par Charles, la politique sera complétée par ce chantier.
9. **Effacer le client chez RevenueCat à la suppression d'un compte** : à construire dans le chantier 9, qui apporte la clé d'API RevenueCat au serveur. Ce lot l'écrit dans `docs/FABLE.md`.
10. **Lectures sur le VPS, en lecture seule**, avec l'accord de Charles (ou lancées par lui) : la liste est dans la tâche 4.
11. **Un registre des violations**, vide, avec la marche à suivre (72 heures), à la fin du registre.
12. **Le test `registre.test.ts`** échoue quand une table du schéma n'est pas nommée dans le registre : les chantiers suivants ne pourront pas l'oublier.

## Review Focus

1. **La purge efface trop.** Un événement d'achat vieux de trois ans mais rattaché à un compte doit rester ; une ligne posée exactement à la limite doit rester. → tâche 1, tests de `keptSince` et suite smoke.
2. **La limite au changement de mois et hors UTC.** Le 31 mars, le 31 janvier, un serveur réglé sur un autre fuseau : la limite est toujours le premier du mois, à minuit UTC, et rien de gardé n'a plus de 13 mois. → tâche 1, test sur chaque jour de quatre années.
3. **La base en panne au démarrage.** La purge échoue : le serveur démarre, l'erreur est journalisée, l'essai suivant a lieu le lendemain ; jamais de rejet non rattrapé. → tâche 1, test de `runRetentionPurge`.
4. **Un compte qui s'est opposé envoie un événement.** L'app ne doit voir aucune erreur (204), rien n'est écrit, et les événements des autres comptes passent. → tâche 2, suite smoke.
5. **Une langue oubliée.** Une section ajoutée en français et pas en chinois, une balise non fermée qui casse la page. → tâche 5 : même nombre de sections dans les quatre langues, chaque sous-traitant nommé dans chacune.

---

### Task 1: Purge des événements à 13 mois

**Files:**
- Create: `backend/src/lib/retention.ts`, `backend/src/lib/retention.test.ts`
- Modify: `backend/src/index.ts` (à côté de `purgeExpiredTokens`), `backend/scripts/smoke.ts`, `backend/scripts/prod-events.sql` (le titre « Total par événement » dit que 13 mois sont gardés)

**Interfaces:**
- Produces:
  ```ts
  export const EVENTS_MONTHS = 13;
  export const UNLINKED_PURCHASE_EVENTS_MONTHS = 13;
  /** Start (UTC) of the month `months - 1` months before the month of `now`: that month and the later ones are kept. */
  export function keptSince(now: Date, months: number): Date;
  /** Deletes `events` created before the limit and `subscription_events` with no account received before it. */
  export function purgeOldRows(db: Db, now: Date): Promise<{ events: number; purchaseEvents: number }>;
  /** `purgeOldRows`, for a timer: a failure is logged ("Retention purge failed:") and never thrown; a run that deleted rows logs the two numbers. */
  export function runRetentionPurge(db: Db, now: Date, log?: Pick<Console, 'log' | 'error'>): Promise<void>;
  ```
  `Db` est le type de `db` (`src/db/index.ts`), comme dans `audience/counter.ts:27`.

- [ ] **Step 1: Écrire les tests de `keptSince` et de `runRetentionPurge`**

`runRetentionPurge` avec une base dont `delete` lève une erreur (`{ delete() { throw new Error('down'); } } as unknown as Db`) : la promesse se résout, `log.error` est appelé une fois avec un message qui commence par `Retention purge failed:`, `log.log` jamais.

```ts
const at = (iso: string) => keptSince(new Date(iso), 13).toISOString();
assert.equal(at('2026-11-26T10:00:00Z'), '2025-11-01T00:00:00.000Z');
assert.equal(at('2026-11-30T23:59:59Z'), '2025-11-01T00:00:00.000Z');
assert.equal(at('2026-12-01T00:00:00Z'), '2025-12-01T00:00:00.000Z');
assert.equal(at('2027-01-31T12:00:00Z'), '2026-01-01T00:00:00.000Z');
assert.equal(at('2026-03-31T23:30:00-05:00'), '2025-04-01T00:00:00.000Z'); // UTC decides the month
```
Et, pour chaque jour à midi UTC du 2026-01-01 au 2029-12-31 : l'âge de la limite, en jours, est `>= 365` et `< 398` (au moins douze mois gardés, jamais plus de treize).

- [ ] **Step 2: Lancer, voir échouer** — `npx tsx --test src/lib/retention.test.ts` → « keptSince is not a function ».
- [ ] **Step 3: Écrire `keptSince` et `runRetentionPurge`**, tests verts.
- [ ] **Step 4: Vérifications smoke de `purgeOldRows`, les voir échouer**

Dans le bloc local de `scripts/smoke.ts` (là où `rollUpOldDays` est vérifié, même import dynamique de `db`), avec `now = new Date()` et `limit = keptSince(now, 13)` :

| Ligne posée | Date | Après `purgeOldRows(db, now)` |
|---|---|---|
| `events`, compte smoke, `smoke.old` | `limit` − 1 ms | effacée |
| `events`, compte smoke, `smoke.edge` | `limit` | gardée |
| `events`, compte smoke, `smoke.recent` | `now` | gardée |
| `subscription_events`, sans compte, `${run}-orphan-old` | `received_at` = `limit` − 1 ms | effacée |
| `subscription_events`, sans compte, `${run}-orphan-edge` | `received_at` = `limit` | gardée |
| `subscription_events`, compte smoke, `${run}-owned-old` | `received_at` = il y a 3 ans | gardée |

Le résultat compte au moins 1 dans chaque champ ; un second appel n'efface aucune de ces lignes. La suite retire ce qu'elle a posé.

- [ ] **Step 5: Écrire `purgeOldRows` et la brancher dans `index.ts`**

Deux `DELETE` ; `subscription_events` : `user_id IS NULL AND received_at < limite`. Dans `index.ts` : `runRetentionPurge(db, new Date())` au démarrage puis toutes les 24 heures (`setInterval(...).unref()`), à côté de `purgeExpiredTokens`. Les nombres journalisés ne portent aucun identifiant.

- [ ] **Step 6: Suite smoke verte, `npx tsc --noEmit`, commit.**

### Task 2: S'opposer aux événements produit

**Files:**
- Modify: `backend/src/db/schema.ts` (`users`), `backend/src/routes/events.ts`, `backend/scripts/smoke.ts`
- Create: `backend/drizzle/0019_events_opt_out.sql` et `backend/drizzle/meta/*` (générés par `npx drizzle-kit generate --name events_opt_out`)

**Interfaces:**
- Produces: `users.eventsOptOut` (`boolean('events_opt_out').notNull().default(false)`), avec un commentaire qui renvoie à la fiche du registre. Aucune route ne le montre ni ne le change.

- [ ] **Step 1: Vérifications smoke d'abord (bloc local), les voir échouer**

- `update users set events_opt_out = true` sur le compte smoke, puis `POST /api/events {"name":"paywall.themes"}` → 204, et aucune ligne `paywall.themes` pour ce compte ;
- avec le drapeau posé, `{"name":"Bad Name!"}` → 400 comme avant (la validation ne change pas) ;
- drapeau retiré, le même envoi → 204 et la ligne existe.

- [ ] **Step 2: Colonne et migration.** Vérifier que le fichier généré est un seul `ALTER TABLE "users" ADD COLUMN "events_opt_out" boolean DEFAULT false NOT NULL;` puis `npm run db:migrate` en local.
- [ ] **Step 3: La route n'écrit rien pour un compte qui s'est opposé** et répond 204 (une requête de plus ou un `INSERT … SELECT … WHERE NOT`, au choix : les événements sont rares).
- [ ] **Step 4: Suite smoke verte, commit.**

### Task 3: Les polices du site servies par nous

**Files:**
- Create: `backend/scripts/fetch-fonts.ts`, `backend/public/fonts/fonts.css`, `backend/public/fonts/*.woff2`, `backend/public/fonts/OFL-DotGothic16.txt`, `backend/public/fonts/OFL-Silkscreen.txt` (ces quatre derniers produits par le script, committés)
- Modify: `backend/src/routes/legal.ts:61-63`, `backend/src/routes/landing.ts:286-288`, `backend/src/index.ts` (CSP et son commentaire), `backend/scripts/smoke.ts`

**Interfaces:**
- Produces: `/fonts/fonts.css`, servie par `express.static` ; les pages la chargent par `<link href="/fonts/fonts.css" rel="stylesheet" />`, sans `preconnect`.

- [ ] **Step 1: Captures d'avant.** Avant de toucher aux pages, backend local lancé : Chrome sans fenêtre, 1280 × 2000, pages `/?lang=fr`, `/?lang=zh-TW` et `/privacy?lang=fr`, rangées dans le dossier de travail de la session.
- [ ] **Step 2: Vérifications smoke d'abord, les voir échouer**

- pour `/`, `/privacy`, `/terms`, `/legal`, `/contact`, `/about`, `/delete-account`, `/privacy/audience` et une page 404 : le corps ne contient ni `googleapis` ni `gstatic`, et l'en-tête `content-security-policy` non plus ;
- `GET /fonts/fonts.css` → 200, `text/css`, au moins une règle `@font-face`, aucune adresse `https://` ;
- chaque `url(/fonts/…)` que la feuille nomme répond 200 avec `font/woff2`.

- [ ] **Step 3: Écrire `scripts/fetch-fonts.ts` et le lancer** (`npx tsx scripts/fetch-fonts.ts`)

Il demande à Google la feuille `css2?family=DotGothic16&family=Silkscreen:wght@400;700&display=swap` avec le `User-Agent` d'un Chrome récent (c'est à lui que Google sert des `woff2` découpés par `unicode-range`), télécharge chaque fichier nommé sous son nom d'origine, récrit la feuille avec `url(/fonts/<nom>)` en gardant famille, graisse, `unicode-range` et `font-display`, et télécharge les deux licences OFL depuis `github.com/google/fonts` (`ofl/dotgothic16/OFL.txt`, `ofl/silkscreen/OFL.txt`). Il s'arrête sans rien écrire si une règle n'a pas de `woff2` ou si l'ensemble dépasse 6 Mo, et affiche le nombre de fichiers et leur poids.

- [ ] **Step 4: Les deux pages chargent `/fonts/fonts.css` ; la CSP devient** `styleSrc: ["'self'", "'unsafe-inline'"]` et `fontSrc: ["'self'"]`.
- [ ] **Step 5: Captures d'après, comparées à l'œil** avec celles de l'étape 1 : mêmes polices, mêmes retours à la ligne, y compris en chinois ; le journal réseau de Chrome ne montre que `localhost`.
- [ ] **Step 6: Suite smoke verte, commit.**

### Task 4: Le registre complet

**Files:**
- Modify: `docs/REGISTRE.md`
- Create: `backend/src/lib/registre.test.ts`

- [ ] **Step 1: Écrire `registre.test.ts`, le voir échouer**

Pour chaque nom relevé par `pgTable\('([a-z_]+)'` dans `src/db/schema.ts` et `src/audience/schema.ts`, `docs/REGISTRE.md` contient ce nom entre accents graves. Échec attendu : toutes les tables hors `audience_*`.

- [ ] **Step 2: Relever les faits sur le VPS** (lecture seule ; accord de Charles, ou lancé par lui) et noter chaque résultat avec sa date :

| Commande | Ce qu'elle dit |
|---|---|
| `docker inspect -f '{{.HostConfig.LogConfig}}' dian-dian-backend-1` et `cat /etc/docker/daemon.json` | combien de temps la sortie du conteneur (adresses IP des connexions refusées) est gardée |
| `journalctl --disk-usage` et `/etc/systemd/journald.conf` | durée du journal système (sshd, fail2ban) |
| `pgbackrest --stanza=dian-dian info` (dans le conteneur, `--user postgres`) | la plus ancienne sauvegarde : durée réelle |
| `ls -la /srv/dian-dian/backups/` | les anciens fichiers `pg-*.sql.age` sont-ils encore là |
| `psql -tAc "show log_statement; show log_min_duration_statement"` | Postgres n'écrit pas les requêtes dans son journal |

- [ ] **Step 3: Relever les faits des fournisseurs, en ligne**, avec l'adresse de la page et la date : pour Vultr, Cloudflare (R2, acheminement de l'e-mail de contact), Resend, RevenueCat, Google (AdMob, connexion Google), Apple (connexion Apple, App Store) et Microsoft (boîte Outlook de contact) : rôle (sous-traitant ou responsable de son propre traitement), pays, avenant de traitement (DPA), garantie du transfert hors d'Europe (inscription au Data Privacy Framework vérifiée sur son site, ou clauses types), ce qu'il garde et combien de temps.

- [ ] **Step 4: Écrire le registre**

Plan du document, chaque fiche au format de la fiche 1 (finalité, base légale, personnes, données, destinataires, durées, droits, mesures) :

| Partie | Ce qu'elle dit (source) |
|---|---|
| Vue d'ensemble | un tableau : une ligne par fiche, avec finalité, base légale, durée |
| Sous-traitants et destinataires | le tableau de l'étape 3 |
| Hébergement, transferts, sauvegardes | Vultr Paris, base PostgreSQL, sauvegardes chiffrées vers R2 (Europe) ; renvoi depuis chaque fiche |
| Demandes des personnes | réponse sous un mois ; effacement : dans l'app (`auth.ts:272`, cascade) ; accès et copie : à la main, les lignes du compte lues par `psql` (aucun script encore) ; opposition aux événements : les deux requêtes de la fiche 7 |
| Fiche 1 — Mesure d'audience du site | existante ; ses renvois « lot registre » pointent maintenant vers les parties ci-dessus ; après la tâche 3, plus aucune requête vers un tiers depuis le site |
| Fiche 2 — Comptes et connexion | `users`, `oauth_accounts` (identifiant donné par Apple ou Google, rien d'autre du profil), `refresh_tokens` (empreinte, 7 jours), `password_reset_tokens` (empreinte d'un code, 10 minutes, 5 essais), `email_verification_tokens` (table vide : aucun code ne l'écrit) ; mot de passe en Argon2id ; sur le téléphone : jetons dans le stockage sécurisé. Contrat. Vie du compte |
| Fiche 3 — Contenu des trackers | `pages`, `cells`, `legends` ; contenu libre, commentaires compris ; risque résiduel : des données sensibles notées par la personne de sa propre initiative (constat 10), non tranché. Contrat |
| Fiche 4 — Achats et abonnements | `subscriptions`, `subscription_events` et ce que `rcEvent.ts` en retire ; RevenueCat reçoit l'identifiant du compte, jamais l'e-mail (`purchase_service.dart:60`) ; Apple et Google vendent et encaissent. Contrat, et intérêt légitime pour la mesure des ventes. Avec compte : vie du compte ; sans compte : 13 mois (tâche 1). Écart : le client reste chez RevenueCat après suppression (choix 9) |
| Fiche 5 — E-mails de service | Resend : code de réinitialisation (le code figure dans l'objet), confirmation de suppression ; durée chez Resend relevée à l'étape 3. Contrat |
| Fiche 6 — Contact et assistance | formulaire `/api/contact` : nom, adresse, message, rien en base ; envoyé par Resend, acheminé par Cloudflare vers la boîte de l'éditeur ; 5 messages par quart d'heure et par adresse IP. Durée proposée : 3 ans après le dernier échange. Intérêt légitime |
| Fiche 7 — Événements produit | `events` : nom, compte, plateforme, version, date ; aucun contenu. Noms d'aujourd'hui : `paywall.*`. Intérêt légitime (décidé le 2026-11-23). 13 mois (tâche 1). Opposition : `UPDATE users SET events_opt_out = true WHERE email = …` puis `DELETE FROM events WHERE user_id = …` |
| Fiche 8 — Statistiques d'usage internes | les scripts `backend/scripts/prod-*.sql`, en lecture seule, lus par l'éditeur seul par SSH : totaux sur les comptes, et les titres portés par au moins deux trackers (`prod-trackers.sql:101`). Intérêt légitime |
| Fiche 9 — Publicité de la version gratuite | AdMob, bannière pour les comptes non Premium, `AdRequest()` sans réglage, aucun consentement demandé, `app-ads.txt`. Google décide de ses traitements. **Écart** (constat 6) et ce qui le règle (choix 8) |
| Fiche 10 — Sécurité et journaux | limitation par adresse IP, en mémoire, 15 minutes ; lignes `auth: failed login` et `auth: rejected token` avec l'adresse IP dans la sortie du conteneur (durée relevée) ; pas de journal d'accès Caddy ; journal système. Intérêt légitime |
| Fiche 11 — Sauvegardes | pgBackRest vers R2, AES-256, complète chaque nuit, différentielle chaque heure, journaux de transactions ; durée relevée ; un compte supprimé en disparaît après cette durée ; essai de restauration du 2026-08-03 ; anciens fichiers `age` (constat 9) |
| Écarts connus et décisions attendues | un tableau : l'écart, où, ce qui le règle, qui |
| Violations de données | aucune à ce jour ; quoi faire en 72 heures (renvoi au playbook) |

- [ ] **Step 5: `registre.test.ts` vert**, et relecture : chaque fait a sa source, chaque « à relever par Charles » est aussi dans la tâche 6.
- [ ] **Step 6: Commit.**

### Task 5: La politique de confidentialité et la page de suppression

**Files:**
- Modify: `backend/src/routes/legal.ts` (`privacy` et `deleteAccount`, quatre langues ; constante de date), `backend/scripts/smoke.ts`

**Interfaces:**
- Consumes: les durées et les noms relevés à la tâche 4.
- Produces: `PRIVACY_UPDATED` (une date, `'2026-11-26'` ou le jour du dernier changement du texte), affichée dans chaque langue par `Intl.DateTimeFormat(<langue>, { dateStyle: 'long', timeZone: 'UTC' })` ; la section des événements porte `id="events"`.

- [ ] **Step 1: Vérifications smoke d'abord, les voir échouer.** Pour chacune des quatre langues de `/privacy` :

- le même nombre de `<h2>` que les trois autres ;
- les noms `Vultr`, `Cloudflare`, `Resend`, `RevenueCat`, `AdMob`, `Apple` et `Google` ;
- `id="events"`, et « 13 » dans cette section ;
- un lien vers `cnil.fr` ;
- la date de `PRIVACY_UPDATED`, dans la langue ;
- plus la phrase « aucune donnée personnelle n'est partagée » ni ses trois traductions (les quatre phrases d'aujourd'hui sont copiées dans le test) ;
- toujours le lien vers `/privacy/audience?lang=…`.

Et pour `/delete-account`, dans chaque langue : `RevenueCat`, et la durée des sauvegardes.

- [ ] **Step 2: Écrire la politique**, en français d'abord, puis les trois autres langues, section par section :

| Section | Ce qu'elle dit |
|---|---|
| 1. Introduction | inchangée, avec le responsable et l'adresse de contact |
| 2. Données traitées | compte (adresse e-mail ; mot de passe dont seule l'empreinte est gardée ; ou l'identifiant qu'Apple ou Google nous donne) ; contenu des trackers, commentaires compris ; réglages ; achats (formule, store, dates, prix, pays du store ; aucun moyen de paiement) ; événements produit ; adresse IP (limitation des abus, connexions refusées) |
| 3. Pourquoi, sur quelle base | fournir et synchroniser le service, Premium, e-mails de service : contrat ; sécurité, événements produit, statistiques d'usage, mesure d'audience du site : intérêt légitime ; ni vente ni profilage |
| 4. À qui elles sont confiées | Vultr (serveur, France), Cloudflare (sauvegardes chiffrées, e-mail de contact), Resend (envoi des e-mails), RevenueCat (état des achats, sous l'identifiant du compte) ; Apple et Google pour la connexion et les achats, responsables de leurs propres traitements ; transferts hors d'Europe et leur garantie, d'après la tâche 4. Remplace la phrase du constat 2 |
| 5. Cookies | inchangée |
| 6. Mesure d'audience du site | inchangée ; si la tâche 3 est faite : le site ne charge rien chez un tiers |
| 7. Événements produit et statistiques d'usage (nouvelle, `id="events"`) | ce que l'app signale (le nom d'un écran ou d'une action, la plateforme, la version, la date, liés au compte ; jamais un contenu) ; pourquoi ; 13 mois ; jamais partagés ; s'y opposer en nous écrivant : arrêt et effacement. Les statistiques : des totaux calculés sur l'ensemble des comptes, dont les titres de trackers les plus fréquents |
| 8. Publicité | le paragraphe AdMob d'aujourd'hui, déplacé, sans rien promettre de plus |
| 9. Stockage et sécurité | France ; Argon2 ; HTTPS ; sauvegardes chiffrées, gardées la durée relevée |
| 10. Durées | compte et contenu : vie du compte ; événements : 13 mois ; sauvegardes ; journaux ; messages de contact ; mesure d'audience : 25 mois |
| 11. Vos droits | accès, rectification, effacement, copie, limitation, opposition ; réponse sous un mois ; réclamation auprès de la CNIL ou de l'autorité de son pays |
| 12. Modifications, 13. Contact | inchangées |

- [ ] **Step 3: La page « Supprimer votre compte »**, quatre langues : « ce qui est supprimé » inchangé ; « ce qui peut rester » dit les sauvegardes chiffrées (durée relevée), les journaux, et l'historique d'achat tenu par Apple, Google et RevenueCat ; la phrase « aucune donnée personnelle n'est conservée » disparaît.
- [ ] **Step 4: Relire les quatre pages dans un navigateur** (mise en page, liens), suite smoke verte, commit.

### Task 6: Journal et documents

**Files:**
- Modify: `backend/CHANGELOG.md`, `docs/FABLE.md`, `docs/ROADMAP.md`, `docs/PRICING.md` (« Conservation » : construit)

- [ ] **Step 1: Changelog** (Unreleased) : la purge et ses deux durées, la migration 0019 et le drapeau, les polices, la politique et la page de suppression, le registre et son test.
- [ ] **Step 2: `docs/FABLE.md`** : la ligne « — » marquée construite avec ce plan ; « Ce que Charles fait » gagne : accepter ou demander les avenants de Resend, RevenueCat et Cloudflare (Vultr y est déjà) ; supprimer les anciens fichiers `age` du VPS s'ils y sont ; relever dans les tableaux de bord ce que le registre marque « à relever par Charles » (sauvegardes automatiques de Vultr, région et durée des journaux de Resend, réglages européens d'AdMob, étiquettes de confidentialité des deux stores) ; décider du chantier « consentement publicitaire » (choix 8). Le chantier 9 gagne : effacer le client RevenueCat à la suppression d'un compte (choix 9).
- [ ] **Step 3: Propositions pour le playbook**, listées à Charles sans rien y écrire : les polices Google d'un site comptent comme un tiers ; le consentement publicitaire d'une app (AdMob) ; le test qui lie le schéma au registre.
- [ ] **Step 4: Garde-fous sur l'arbre final** : `npx tsc --noEmit`, `npx tsx --test "src/**/*.test.ts"`, suite smoke ; commit. Puis un relecteur neuf sur toute la branche, tout corrigé, mineurs compris, avant la fusion.

## Hors périmètre

- Le formulaire de consentement publicitaire dans l'app (choix 8) et l'effacement du client RevenueCat (choix 9).
- Un script d'export des données d'un compte : la demande d'accès est traitée à la main tant qu'il n'y en a pas eu ; l'écran « Mes données » du chantier 9 pourra le remplacer.
- Un réglage dans l'app pour s'opposer aux événements.
- Ce que les chantiers suivants ajoutent au registre et à la politique : compte sans identité, copie sur le téléphone, rappels, pop-up, astuces.
- Les conditions d'utilisation, les étiquettes de confidentialité des stores (Charles) et l'e-mail annonçant le changement de politique (décision de Charles, déjà dans `docs/FABLE.md`).
