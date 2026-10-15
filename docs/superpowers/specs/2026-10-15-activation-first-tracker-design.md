# Activation : premier tracker guidé — design (2026-10-15)

## Objectif

Faire poser le premier point à l'inscription. Aujourd'hui la moitié des
comptes (`docs/ROADMAP.md`, mesures du 2026-10-15 : 53 % à vie) ne
remplissent jamais une case et gardent le tracker par défaut "My Tracker",
vide et sans légende. Le parcours d'accueil actuel (trois cartes
explicatives) explique sans rien faire faire.

Ce chantier remplace ces cartes par un parcours en deux écrans qui crée un
tracker prêt à l'emploi (titre + légendes d'un modèle) et pose la case du
jour, puis ajoute un bouton "Aujourd'hui" dans le tracker pour que le geste
quotidien reste à un tap.

**Mesure de succès** : part des nouveaux comptes avec au moins une case à
J+1 et J+7, par cohorte hebdomadaire d'inscription, lue avec
`backend/scripts/prod-activation.sql`. Référence : 53 % à vie, à affiner sur
les cohortes d'avant la sortie à la première lecture. Jugement à huit
semaines.

Non-objectifs : événements analytiques dans l'app (point 2 du roadmap,
séparé), récompenses et notifications (point 4), refonte de la liste des
trackers.

## Décisions prises en brainstorming

- Le parcours s'adresse à **tout compte sans aucune case, toutes années et
  pages confondues** : nouveau ou dormant. Le déclencheur vient du serveur
  (`activated` dans le bootstrap), pas d'un drapeau d'appareil. "Plus tard"
  est mémorisé par appareil et par compte.
- La case du jour se pose sur l'écran 2 du parcours, pas dans la vraie
  grille. La grille vient après, avec le point déjà posé.
- Le serveur ne crée plus "My Tracker" à l'inscription. Le tracker vide d'un
  compte dormant est réutilisé (remplacé) par le parcours.
- Un seul appel pour la page et ses légendes (`POST /api/pages` étendu) ;
  la case du jour passe par la route cellules existante, donc par le chemin
  optimiste déjà en place dans l'app.
- Les trois cartes explicatives et le drapeau `onboarding_done` disparaissent.
- Six modèles, dans les quatre langues de l'app ; le titre du tracker est le
  nom du modèle. Après création c'est un tracker ordinaire.
- Backend 1.2.0 déployé avant l'app 1.4.0.

## Modèles

Couleurs prises dans les palettes des épingles Pinterest
(`marketing/common.py` PALETTES) pour que l'app ressemble à ce qu'on
montre. Sport reçoit sa propre palette : dans les maquettes Sport et
Habitudes avaient la même, deux tuiles identiques se distinguent mal.

| Modèle | Légendes dans l'ordre | Couleurs |
|---|---|---|
| Humeur | Génial · Super · Bien · Bof · Mou | `#FFEC99` `#FFD43B` `#8CE99A` `#74C0FC` `#E599F7` |
| Sommeil | 8 h+ · 7–8 h · 6–7 h · 5–6 h · < 5 h | `#1864AB` `#1C7ED6` `#4DABF7` `#A5D8FF` `#D0EBFF` |
| Sport | Fait · Presque · Un peu · Repos · Malade | `#51CF66` `#8CE99A` `#FFD8A8` `#74C0FC` `#FFA8A8` |
| Lecture | 1 h+ · 30 min · Quelques pages · Rien | `#FA5252` `#FF8787` `#FFA8A8` `#FFC9C9` |
| Habitudes | Fait · Presque · Un peu · Repos · Raté | `#20C997` `#63E6BE` `#C3FAE8` `#FFD8A8` `#FFA94D` |
| Autre… | Oui · Un peu · Non (titre libre, 1 à 35 caractères) | `#8CE99A` `#FFEC99` `#FFA8A8` |

Libellés par langue (clés `firstTracker.tpl.<modèle>.title` et
`firstTracker.tpl.<modèle>.<index>` dans `language_provider.dart`) :

| | fr | en | zh-Hans | zh-Hant |
|---|---|---|---|---|
| Humeur | Humeur / Génial · Super · Bien · Bof · Mou | Mood / Great · Good · Okay · Meh · Low | 心情 / 超棒 · 很好 · 还行 · 一般 · 低落 | 心情 / 超棒 · 很好 · 還行 · 一般 · 低落 |
| Sommeil | Sommeil / 8 h+ · 7–8 h · 6–7 h · 5–6 h · < 5 h | Sleep / 8 h+ · 7–8 h · 6–7 h · 5–6 h · < 5 h | 睡眠 / 8 小时+ · 7–8 小时 · 6–7 小时 · 5–6 小时 · < 5 小时 | 睡眠 / 8 小時+ · 7–8 小時 · 6–7 小時 · 5–6 小時 · < 5 小時 |
| Sport | Sport / Fait · Presque · Un peu · Repos · Malade | Exercise / Done · Almost · A little · Rest · Sick | 运动 / 完成 · 差一点 · 一点点 · 休息 · 生病 | 運動 / 完成 · 差一點 · 一點點 · 休息 · 生病 |
| Lecture | Lecture / 1 h+ · 30 min · Quelques pages · Rien | Reading / 1 h+ · 30 min · A few pages · None | 阅读 / 1 小时+ · 30 分钟 · 几页 · 没读 | 閱讀 / 1 小時+ · 30 分鐘 · 幾頁 · 沒讀 |
| Habitudes | Habitudes / Fait · Presque · Un peu · Repos · Raté | Habits / Done · Almost · A little · Rest · Missed | 习惯 / 完成 · 差一点 · 一点点 · 休息 · 错过 | 習慣 / 完成 · 差一點 · 一點點 · 休息 · 錯過 |
| Autre… | Autre… / Oui · Un peu · Non | Other… / Yes · A little · No | 其他… / 是 · 一点 · 否 | 其他… / 是 · 一點 · 否 |

Les modèles vivent dans un fichier Dart dédié
(`flutter_app/lib/data/first_tracker_templates.dart`) : identifiant,
couleurs, clés de traduction. Pas de modèle côté serveur.

## App (1.4.0)

### Déclenchement

Dans `_startSessionInner` (`main.dart`), après `sync.start` :

1. Si l'instantané disque dit `activated: true`, on atterrit comme
   aujourd'hui, sans attendre le réseau (premier rendu instantané conservé
   pour tout utilisateur actif).
2. Sinon (pas d'instantané, ou `activated` absent ou faux), on attend le
   bootstrap réseau (`sync.ensureYear`, déjà dédupliqué avec celui lancé par
   `start`). Sans réponse (hors ligne, délai de l'`ApiService`) : app normale,
   le parcours se représentera au prochain lancement connecté.
3. Avec la réponse : le parcours s'affiche si `activated == false`, si
   l'appareil n'a pas le drapeau `first_tracker_done_<userId>`, et si la
   limite de trackers le permet (`pages.length < premium.maxTrackers`, ou
   une page remplaçable existe, voir plus bas). Sinon, parcours habituel
   (dernier tracker ouvert ou liste).

`SyncService` expose `bool? activated` : valeur du dernier bootstrap réseau,
ou de l'instantané à l'hydratation (`null` si inconnu). L'instantané stocke
le champ avec le reste du corps bootstrap (`_serialize` l'écrit depuis
l'état du service) ; un instantané sans le champ vaut inconnu.

Le drapeau d'appareil `first_tracker_done_<userId>` (SharedPreferences) est
posé sur "Plus tard", sur "Pas aujourd'hui" réussi et sur case du jour
réussie. L'ancien `onboarding_done` n'est plus lu ni écrit. Un appareil qui
l'avait et dont le compte n'a aucune case verra donc le parcours une fois :
c'est voulu.

`AppScreen.onboarding` devient `AppScreen.firstTracker` ;
`onboarding_screen.dart` est remplacé par `first_tracker_screen.dart`.

### Écran 1 — "Que veux-tu suivre ?"

Même habillage que les cartes actuelles (coque `AppColors.shell`, bordure,
police pixel pour les titres, police dot pour le reste, fond pointillé).

- Titre, sous-titre "Votre premier tracker. Tout reste modifiable après."
- Grille de six tuiles (2 colonnes en portrait téléphone, 3 au-delà de
  600 px de large) : nom du modèle et, dessous, ses points de légende dans
  leurs couleurs. La tuile "Autre…" montre trois points vides et "+ Titre".
- Taper une tuile passe à l'écran 2. Taper "Autre…" déplie un champ titre
  sous la tuile (même règles que `_CreateTrackerDialog` : 1 à 35 caractères,
  focus automatique, clavier) avec un bouton "Continuer" actif dès que le
  titre n'est pas vide.
- "Plus tard" en haut à droite : pose le drapeau d'appareil et mène à la
  liste des trackers. C'est la seule sortie qui ne crée rien.
- Pas de bouton retour système à gérer : le parcours est la racine de la
  session.

### Écran 2 — "Et aujourd'hui ?"

- Titre du tracker choisi, date du jour en toutes lettres dans la langue de
  l'app (pas de dépendance `intl` : noms de jours et de mois ajoutés dans
  `language_provider.dart`, clés `date.weekday.1..7` et `date.month.1..12`,
  et un gabarit par langue : fr "jeudi 15 octobre", en "Thursday, October
  15", zh "10月15日 星期四"), gros point vide en pointillés (style `dotEmpty`
  + `dotBorder`), puis les légendes du modèle en boutons (point coloré +
  libellé), empilés.
- Taper une légende :
  1. crée la page avec ses légendes (un appel, section Backend), si ce n'est
     pas déjà fait ;
  2. pointe les providers sur la page créée (`CellsProvider.setContext`,
     `LegendsProvider.setPageId`) et pose la case du jour via
     `CellsProvider.setCell` (année, mois, jour locaux de l'appareil) ;
  3. le gros point prend la couleur, avec l'anneau "aujourd'hui" de la
     grille ; la légende choisie est marquée ; le bouton "Ouvrir mon tracker"
     apparaît.
  Retaper une autre légende avant d'ouvrir change la couleur (même
  `setCell`, la page n'est pas recréée). Pas de bouton retour.
- "Pas aujourd'hui", lien discret sous les légendes : crée la page sans case
  et ouvre le tracker.
- "Ouvrir mon tracker" : pose le drapeau d'appareil, enregistre le tracker
  comme dernier ouvert (`_saveLastTracker(pageId, année du jour)`) et navigue
  vers `AppScreen.tracker` sur l'année du jour.
- Erreur réseau à n'importe quelle étape : message en place sous les
  légendes "Connexion impossible, réessayez" avec un bouton "Réessayer", qui
  rejoue seulement l'étape manquante (la page créée est gardée en mémoire,
  on ne la recrée pas). "Plus tard" reste accessible en haut à droite.
  Rien n'est créé à moitié côté serveur : la page et ses légendes sont une
  transaction ; une case qui échoue laisse un tracker avec légendes, ce qui
  n'est pas le tracker vide qu'on combat.

### Page remplaçable (compte dormant)

Si le compte a déjà des pages, le parcours cherche la première (par
`position`) sans légende dans le store. Comme `activated == false`, aucune
page n'a de case. Cette page est passée dans `replaces`, sans `position` : le
serveur la supprime et crée la nouvelle à sa `position`. Sans page
remplaçable, l'app envoie `position = pages.length`. Si le serveur répond 404 ou
409 sur `replaces` (page disparue ou devenue non vide depuis un autre
appareil), l'app réessaie une fois sans `replaces`.

### Après le parcours

Le tracker créé devient le dernier ouvert ; le prochain lancement retombe
dessus. Les légendes existent, donc le bouton Éditer ne pulse pas.

### Bouton "Aujourd'hui" dans le tracker

Dans la barre latérale de `tracker_screen.dart`, sous Éditer et au-dessus de
l'en-tête Stats, même composant pointillé que Éditer (`DashedBorder`, icône
point plein `Icons.circle` 10 px, libellé `tracker.today` ; icône seule en
mode compact comme Éditer). Au tap :

- si l'année affichée n'est pas celle du jour, passer à l'année du jour
  (même chemin que les flèches : `_changeYear`, qui prévient
  `onYearChanged` et charge l'année) ;
- puis `CellEditorDialog.show(context, month:, day:, year:)` sur la date du
  jour.

Le tap direct sur une case avec un pinceau sélectionné ne change pas. Le
bouton existe quelle que soit la provenance du tracker.

### Code touché (app)

- `lib/screens/first_tracker_screen.dart` (nouveau, remplace
  `onboarding_screen.dart`) : les deux écrans, l'état du parcours (modèle
  choisi, titre, page créée, couleur posée, erreur), les appels providers.
- `lib/data/first_tracker_templates.dart` (nouveau).
- `lib/providers/pages_provider.dart` : `createPage` prend
  `{List<({String color, String label})> legends = const [], String?
  replaces}` et renvoie `CreatedPage(page, legends)` ; retire localement la
  page remplacée.
- `lib/providers/legends_provider.dart` : `setLegends(pageId, list)` pour
  pousser les légendes renvoyées par la création ; gestion WS de
  `page:created` (si `legends` présent, remplace la liste de cette page) et
  `page:deleted` (oublie la page).
- `lib/services/sync_service.dart` : `activated` (réseau et instantané).
- `lib/main.dart` : déclenchement, écran `firstTracker`, navigation de
  sortie.
- `lib/screens/tracker_screen.dart` : bouton Aujourd'hui.
- `lib/providers/language_provider.dart` : clés `firstTracker.*`,
  `date.*`, `tracker.today` dans les quatre langues ; suppression des clés
  `onboarding.*`.

Textes (fr / en / zh-Hans / zh-Hant) :

| Clé | fr | en | zh-Hans | zh-Hant |
|---|---|---|---|---|
| `firstTracker.title` | Que voulez-vous suivre ? | What do you want to track? | 你想追踪什么？ | 你想追蹤什麼？ |
| `firstTracker.subtitle` | Votre premier tracker. Tout reste modifiable après. | Your first tracker. You can change everything later. | 你的第一个追踪器，之后都可以修改。 | 你的第一個追蹤器，之後都可以修改。 |
| `firstTracker.later` | Plus tard | Later | 稍后 | 稍後 |
| `firstTracker.titleField` | Titre | Title | 标题 | 標題 |
| `firstTracker.continue` | Continuer | Continue | 继续 | 繼續 |
| `firstTracker.today` | Et aujourd'hui ? | And today? | 那今天呢？ | 那今天呢？ |
| `firstTracker.notToday` | Pas aujourd'hui | Not today | 今天不填 | 今天不填 |
| `firstTracker.open` | Ouvrir mon tracker | Open my tracker | 打开我的追踪器 | 打開我的追蹤器 |
| `firstTracker.error` | Connexion impossible, réessayez | Can't reach the server, try again | 无法连接，请重试 | 無法連接，請重試 |
| `firstTracker.retry` | Réessayer | Retry | 重试 | 重試 |
| `tracker.today` | Aujourd'hui | Today | 今天 | 今天 |

Le français vouvoie, comme le reste de l'app (les maquettes tutoyaient).

## Backend (1.2.0)

Tout est additif ; les clients 1.3.0 installés continuent de fonctionner.

### `POST /api/pages` étendu

Deux champs optionnels dans le corps :

```json
{
  "title": "Humeur",
  "position": 0,
  "legends": [ { "color": "#FFEC99", "label": "Génial" }, ... ],
  "replaces": "<pageId>"
}
```

- `legends` : 0 à 12 éléments, même validation que la route légendes
  (couleur `#RRGGBB`, libellé 1 à 30 caractères) ; `position` = index.
- `replaces` : uuid. Dans la transaction, le serveur charge la page avec
  `userId` du compte : absente → 404 ; avec au moins une légende ou une case
  (toutes années) → 409 `{ error: 'Page is not empty' }` ; sinon elle est
  supprimée et `position` par défaut devient la sienne.
- Transaction unique : suppression éventuelle, insertion de la page,
  insertion des légendes dans l'ordre. Rien n'est écrit en cas d'erreur.
- Réponse 201 : la page (palette parsée, comme aujourd'hui) plus
  `legends: [...]` (toujours présent, éventuellement vide) et
  `replaced: "<pageId>" | null`.
- WebSocket : `page:deleted { id }` pour la page remplacée, puis
  `page:created` avec le même corps que la réponse (les clients 1.3.0
  ignorent `legends` et `replaced`).

Sans ces champs, comportement inchangé.

### `GET /api/bootstrap`

Ajoute `activated: boolean` : au moins une case sur n'importe quelle page du
compte, toutes années confondues. Une requête `EXISTS` sur `cells` jointe à
`pages` par `user_id`, dans le `Promise.all` existant (index `pages_user_id`
et clé primaire de `cells` qui commence par `page_id`).

### Inscription

`auth.ts` ne crée plus la page "My Tracker", ni à l'inscription par
courriel ni au premier login OAuth. Un client 1.3.0 sur un compte neuf voit
une liste vide avec le bouton +, qu'il gère déjà.

### Migration 0013 — `cells.created_at`

`timestamptz NOT NULL DEFAULT now()`, puis `UPDATE cells SET created_at =
updated_at` pour les lignes existantes. Déclaré dans `schema.ts`. L'upsert
de `cells.ts` ne touche pas `created_at` en cas de conflit (seul l'insert
le pose, par défaut). Rollback-safe : une colonne en plus que 1.1.x ignore.

### Smoke test (`scripts/smoke.ts`)

À adapter et étendre :

- après l'inscription, `GET /api/pages` renvoie `[]` (plus de page par
  défaut) ; `bootstrap.activated === false` ;
- `POST /api/pages` avec 5 légendes → 201, `legends.length === 5` dans
  l'ordre, `replaced === null` ; `GET /api/legends/:id` les renvoie ;
- `POST /api/pages` avec `replaces` sur une page vide → 201, `replaced` =
  son id, la page a disparu de `GET /api/pages`, la nouvelle a sa
  `position` ;
- `POST /api/pages` avec `replaces` sur une page avec une légende → 409 et
  rien de créé ; sur un uuid inconnu → 404 ;
- 13 légendes → 400 ;
- après une `PUT /api/cells`, `bootstrap.activated === true` ;
- la réponse `cells` porte `createdAt`.

## Mesure : `backend/scripts/prod-activation.sql`

Lecture seule, lancé comme `prod-stats.sql` (même en-tête `ssh … psql`),
mêmes exclusions (`@example.com`, `@overridedev.com`, démo, VIP). Par
cohorte hebdomadaire d'inscription (`date_trunc('week', users.created_at)`),
sur les 16 dernières semaines :

| colonne | sens |
|---|---|
| `semaine` | lundi de la semaine d'inscription |
| `comptes` | inscrits cette semaine-là |
| `j1` | part avec `min(cells.created_at) < users.created_at + 24 h` |
| `j7` | idem à 7 jours |
| `jamais` | part sans aucune case à ce jour |

Plus une ligne "total" sur la période. Le script met en garde dans son
en-tête : pour les cases d'avant la migration, `created_at` vaut
`updated_at` (dernière modification), donc `j1`/`j7` des cohortes anciennes
sont sous-estimés. La première lecture après déploiement fixe la référence ;
la cible à huit semaines est un `j7` nettement au-dessus des 53 % à vie.

## Compatibilité et ordre de sortie

1. Backend 1.2.0 : `./release-backend.sh`, puis `./deploy-prod.sh` (migration
   0013 jouée au démarrage comme d'habitude). Les apps 1.3.0 ne voient
   que la disparition de "My Tracker" à l'inscription.
2. App 1.4.0 : nécessite le backend 1.2.0 (champs `legends`, `activated`).
   Avec un backend 1.1.x, `activated` serait absent → inconnu → app normale,
   jamais le parcours : dégradation douce.
3. Rollback backend vers 1.1.1 : la colonne `created_at` reste, l'app 1.4.0
   retombe sur l'app normale.

## Tests

- Backend : smoke test ci-dessus (CI sur Postgres jetable, et à la main
  contre `localhost:3001` avec Postgres.app 5433).
- Flutter : tests unitaires sur `PagesProvider.createPage` (corps envoyé,
  page remplacée retirée, 409 → second appel sans `replaces`),
  `LegendsProvider.setLegends` et `page:created` enrichi,
  `SyncService.activated` (réseau, instantané, absent), et la décision de
  déclenchement extraite dans une fonction pure testable (`activated`,
  drapeau d'appareil, limite de trackers, page remplaçable). `flutter
  analyze` propre.
- Simulateur : compte neuf → parcours → Humeur → Génial → grille avec le
  point du jour et l'anneau ; relance → atterrit sur le tracker, pas de
  parcours ; compte dormant avec "My Tracker" vide → remplacé, un seul
  tracker dans la liste ; mode avion au tap → message + réessayer ; mode
  avion au lancement → app normale ; "Plus tard" → liste, pas reproposé ;
  bouton Aujourd'hui depuis une autre année → saute à l'année en cours et
  ouvre l'éditeur sur la date du jour ; texte agrandi et paysage sans
  débordement.

## Versions et changelogs

- `backend/CHANGELOG.md` 1.2.0 : Added (`POST /api/pages` `legends` /
  `replaces`, `bootstrap.activated`, `cells.created_at`, script
  `prod-activation.sql`), Changed (plus de page par défaut à
  l'inscription), Compatibility (apps 1.3.0 inchangées, app 1.4.0 requiert
  1.2.0).
- `flutter_app/docs/changelogs/1.4.0.md` (quatre langues, ≤ 500 caractères
  par bloc) : premier tracker guidé avec modèles prêts à l'emploi, point du
  jour posé dès l'accueil, bouton Aujourd'hui dans le tracker.
- `docs/ROADMAP.md` : point 1 renvoie vers ce spec ; à la sortie, noter la
  date et la référence mesurée.
