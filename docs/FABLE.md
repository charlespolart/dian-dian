# Brief pour Fable

Point d'entrée de la passe de confirmation puis de la construction.
Rédigé le 2026-11-23, à la fin de la phase de préparation (recherches,
audits, specs, sans code — `docs/ROADMAP.md`, en tête) ; mis à jour le
2026-11-24 avec la spec des stats (seconde version, validée sur maquettes)
et la mise à jour des rappels et de la pop-up qui en découle ; le
2026-11-25 avec la spec du zoom (mois et semaine) et celle des astuces.

**Passe de confirmation faite le 2026-11-25** : `docs/CONFIRMATION.md`
(les contradictions et les trous trouvés en comparant chaque spec au code,
et ce qui a été tranché). Chaque spec finit par une section « Passe de
confirmation du 2026-11-25 ».

Charles est le propriétaire et le seul développeur. Il écrit en français ;
le code, les identifiants et les libellés de configuration (stores,
RevenueCat) sont en anglais ; les textes de l'app vouvoient.

## Ce qu'on attend de toi

1. **Confirmer** : lire chaque spec, vérifier qu'elle se construit telle
   quelle dans le code d'aujourd'hui, signaler les contradictions et les
   trous. Les décisions marquées « décidé » ou « questions closes » sont
   celles de Charles : ne pas les rouvrir sans raison nouvelle. Les
   « *mon choix* » sont des propositions du rédacteur, à discuter si tu as
   mieux.
2. **Construire**, chantier par chantier, dans l'ordre ci-dessous, avec un
   plan par chantier avant le code.

## À lire, dans l'ordre

1. Ce fichier, puis `docs/CONFIRMATION.md` (la passe de confirmation du
   2026-11-25).
2. `docs/ROADMAP.md` : la liste des chantiers et leur historique.
3. Les specs de `docs/superpowers/specs/` datées du 2026-11-23 et du
   2026-11-24 : `reminders-design`, `premium-popup-design`,
   `landing-visits-design`, `stats-design`, et celles du 2026-11-25,
   `tracker-zoom-design` et `feature-tips-design`. Pour les stats, les
   maquettes :
   https://claude.ai/artifact/HVMGhCrPR82sjShMxiht2e, la référence (le
   principe, les neuf modèles, sept histoires de « + » jusqu'aux stats, les
   rappels, Premium). L'ancienne page
   (https://claude.ai/artifact/1rF2wxMQx5fMsxf4Rogz3P) ne fait plus foi.
4. `docs/PRICING.md` : prix décidés, paywall à refaire (section « Le
   paywall (pour Fable) »).
5. Au besoin, les recherches : `docs/research/reports/` (rapports) et
   `docs/research/notes/` (sources), plus `docs/research/audit-2026-11-22.md`.

## Les branches

| Branche | Contenu | À faire |
|---|---|---|
| `master` | Ce qui est en production : backend **1.2.1** (2026-11-23), app **1.4.0** | Base de travail |
| `docs/conversion-retention` | Toute la préparation : docs, recherches, specs, scripts marketing ; plus `.gitignore` (`marketing/out/`, la même ligne que sur master), `ANDROID_RELEASE_PLAN.md` et quatre scripts de lecture `backend/scripts/prod-*.sql` (filtre des comptes internes). Partie de master avant ses trois derniers commits (backend 1.2.1) : le code qu'on y voit n'est pas celui de la production | À fusionner dans master avant de coder (aucun code de l'app ni du serveur ; fusion sans conflit, vérifiée le 2026-11-25) |
| `feat/comment-badge` | App : pastille de commentaire à la place de l'anneau troué ; tuiles Sons et Vibrations qui suivent le thème. Testé, analyse propre, entrées dans `flutter_app/CHANGELOG.md` (Unreleased) | À pousser (au 2026-11-25 elle n'existe que sur la machine de Charles) et à fusionner ; sortira avec la prochaine version de l'app ; les notes des stores devront dire que le repère a changé (celles de 1.4.0 parlent d'« un petit anneau ») |
| `feat/landing-store-by-platform` | Déjà fusionnée et en production (1.2.1) | Peut être supprimée |
| `feat/cell-popup-page-list` | Ancien travail en cours, hors de ce brief | — |

## Les chantiers, dans l'ordre

| # | Chantier | Spec | Dépend de | Estimation |
|---|---|---|---|---|
| 0 | Mesure des achats : table brute du webhook RevenueCat (chaque événement, avec la période d'essai, le prix, la devise, l'environnement et les raisons), plateforme et version de l'app acceptées sur `events` | audit, « Trous de mesure » 1 et 2 ; `docs/CONFIRMATION.md`, point 10 | rien (backend seul) | ½ à 1 jour |
| 1 | Compteur de visites du site, avec le regroupement du `ct` Apple par source | `2026-11-23-landing-visits-design.md`, ROADMAP §3 | rien (backend seul) | 3 à 4 jours |
| 2 | Refonte du paywall et du mur des 3 trackers (un seul écran par mur, essai affiché selon l'éligibilité), événements du parcours d'achat ; dans la même version de l'app, le correctif des jours invalides de l'éditeur de jour (`docs/CONFIRMATION.md`, point 27) | `docs/PRICING.md` | les prix en stores (Charles, 1er décembre) | à estimer |
| 3 | Outillage Android : AGP 9.1, Gradle ≥ 9.3.1, Kotlin 2.3, `compileSdk = 37` écrit à la main, R8 (Dart ≥ 3.12 est acquis : Flutter 3.47.5, Dart 3.13.4) ; fait tôt et testé sur appareil avant d'empiler le reste (plus de release dédiée, voir « Une seule release ») | `ANDROID_RELEASE_PLAN.md` §8 | rien | à estimer |
| 4 | Rappels (notifications locales, matin et soir, section Rappels, écran de demande) | `2026-11-23-reminders-design.md` | 3 (le plugin le plus récent exige AGP 9) ; 5, lot 1 (le remplissage et le moment du rappel se règlent à la création et dans les réglages du tracker) ; la date de création du compte dans le bootstrap (backend, avant l'app) | à estimer |
| 5 | Stats plus utiles, en trois lots : réglages et création, avec le chargement de l'année précédente (lot 1), page Stats (lot 2), estimation et liens (lot 3) | `2026-11-24-stats-design.md` | lot 1 : rien ; lots 2 et 3 : le lot 1 | à estimer |
| 6 | Pop-up premium occasionnelle | `2026-11-23-premium-popup-design.md` | 4 (passe après l'écran des rappels), 5 lot 2 (`stats_ready` dévoile une stat Premium prête) et lot 3 (`link_found`) | à estimer |
| 7 | Voir un tracker par mois et par semaine (zoom), et plier la barre d'un glissement | `2026-11-25-tracker-zoom-design.md` ; page d'essai https://claude.ai/artifact/TonXNPhgKSxYvDwVet948j (version 2) | la fusion de `feat/comment-badge` (même fichier, `tracker_grid.dart`) ; après la pop-up (6), *mon choix* du 2026-11-25 | à estimer |
| 8 | Astuces : les fonctions cachées montrées une à une, carnet d'astuces, événements | `2026-11-25-feature-tips-design.md` ; maquettes https://claude.ai/artifact/3HsujtgXLrre5FbtaViGmE | lot 1 : deux champs du bootstrap (backend, avant l'app) ; 5 lot 1 si déjà là (la roue des réglages pour l'astuce 8) ; lot 2 (astuces du zoom) : 7 ; les événements avec le registre RGPD ; le lot 1 juste après les rappels (4), *mon choix* du 2026-11-25 | à estimer |
| — | Registre RGPD du projet et politique de confidentialité (événements produit, compteur de visites), en quatre langues ; purge des événements produit au-delà de 13 mois (rien ne les efface aujourd'hui) | specs du compteur et `docs/PRICING.md` (« Relecture ») | avant ou avec 1 et 2 | ½ jour |

Chaque spec finit par une section « Relecture » (du 2026-11-23, ou du
2026-11-24 pour les stats) : les trous trouvés en la relisant comme un
constructeur, réglés ou laissés à Charles.

Calendrier à garder en tête : les prix changent le **1er décembre** ; le pic
de l'année est le **Nouvel An** (une année en pixels commence le 1er
janvier). Décidé le 2026-11-23 : **avant le Nouvel An**, le compteur de
visites (1), le registre et la politique de confidentialité, puis la
refonte du paywall (2) ; **en janvier**, l'outillage Android (3) puis les
rappels (4) ; pas de bilan de fin d'année en 2026. Ajusté le 2026-11-24
(décidé par Charles, voir la spec des stats) : le lot 1 des stats
passe entre l'outillage Android et les rappels, et sort avec eux ou juste
avant ; puis les lots 2 et 3 des stats, puis la pop-up (6).

**Une seule release (décidé par Charles le 2026-11-25).** Tous les
chantiers du tableau se construisent, puis sortent ensemble : une release
du backend, puis une version de l'app. Pas de release intermédiaire. Le
calendrier ci-dessus ne dit donc plus quand chaque chantier sort ; il ne
reste qu'un ordre de construction (*mon choix*, Fable) : 0, 1 et le
registre, qui sont du backend ; 3, l'outillage Android, tôt, pour que
tout le reste soit testé dessus ; puis 2, 5 lot 1, 4, 8 lot 1, 5 lots 2
et 3, 6, 7, 8 lot 2. Ce que cela change dans les specs est dans
`docs/CONFIRMATION.md`, « Une seule release ». `master` avance sans
release ; un correctif urgent de la production part du tag.

## Règles du projet

- **Jamais `dart format`** dans `flutter_app` (pas de `page_width`, lignes
  posées à la main jusqu'à ~140 colonnes). Les garde-fous sont
  `flutter analyze`, les tests et `git diff --stat`.
- **Ne pas mettre Flutter à jour avant le chantier 3** : AGP 8.11.1 est le
  plancher de Flutter 3.47.5 (la version de la CI et de la machine de
  Charles) ; un Flutter plus récent risque de refuser de construire l'app
  Android.
- **Aucun déploiement automatique.** Backend : `./release-backend.sh
  patch|minor|major` puis `./deploy-prod.sh` (interactifs, lancés par
  Charles dans un terminal), `./rollback-prod.sh` en secours. App :
  `./release-app.sh` puis `make prod-ios` / `make prod-android` depuis le
  tag. Numéro de build = nombre de commits. La CI teste et construit les
  images, elle ne touche jamais au serveur.
- **Changelogs** : `CHANGELOG.md` technique (section Unreleased, datée par le
  script de release) ; notes des stores dans
  `flutter_app/docs/changelogs/X.Y.Z.md`, quatre langues, ≤ 500 caractères.
- **VIP** : uniquement à la main, jamais par SQL, même pour tester.
- **Base de prod** : lecture seule (`SET default_transaction_read_only = on;`
  en tête), avec le filtre des comptes de test et internes des scripts
  `backend/scripts/prod-*.sql`.
- **Commits** : seulement quand Charles le demande ; vérifier
  `git branch --show-current` avant (il se met sur des tags pour les builds).
- **Couleurs dérivées** : toujours calculées depuis le thème (mélange vers
  la couleur d'écran du thème, jamais vers le blanc ou le noir) ; vérifier
  un thème clair et un sombre (Default, Midnight, Noir).
- **Visuels générés** : les regarder soi-même avant de les montrer.
- **Base locale** : Postgres.app sur le port 5433 ; le conflit de port de
  `make db` est normal.
- **Playbook** : `~/Documents/Coding/playbook`, base de connaissances
  commune à tous les projets. À consulter avant d'intégrer un service tiers ;
  un ajout se propose à Charles, ne se fait pas en cachette. Le compteur de
  visites doit y laisser une fiche (voir sa spec).

## Vérifier

- App : `make test` (analyse Flutter + tests + typecheck du backend).
- Backend : `cd backend && npx tsx --test "src/**/*.test.ts"` ; la suite
  smoke `npx tsx scripts/smoke.ts` contre un backend local lancé.

## Ce que Charles fait de son côté (hors code)

- Programmer les nouveaux prix dans App Store Connect au plus tard le 28 ou
  le 29 novembre ; Google Play à la main le 1er décembre, pays par pays.
- Charger les nouvelles images App Store (en-tête, recherche), retirer
  l'image universelle ; soumettre le message de résiliation (avec Premium
  Yearly).
- Google Play : bannière d'essai à vérifier sur un téléphone, abonnement à
  renommer « Dian Dian Premium », délai de grâce, packages RevenueCat.
- Demander à Vultr son avenant de traitement des données (DPA), puis le
  citer avec sa date dans `docs/REGISTRE.md` (fiche 1, « Hébergement »).
- Tester le bouton App Store depuis une épingle Pinterest sur iPhone, et
  depuis Safari : depuis le chantier 1 il passe par `/go/apple` et s'ouvre
  dans le même onglet (plus de nouvel onglet).
- Vérifier les adresses du site saisies dans App Store Connect et la Play
  Console (assistance, marketing, confidentialité) : un chemin inconnu
  répond maintenant 404 au lieu de renvoyer à l'accueil.
- Décider si le changement de la politique de confidentialité (mesure
  d'audience du site, puis événements produit avec le lot « registre »)
  demande l'e-mail que sa section « Modifications » promet pour les
  changements importants.
- Compteur de visites, après le déploiement de la release : porter la date
  de mise en service dans `docs/REGISTRE.md` ; une semaine plus tard, lancer
  `backend/scripts/prod-landing.sql` et vérifier que plusieurs pays
  apparaissent (un seul pays, ou « ?? » partout, voudrait dire que le
  serveur ne voit pas l'adresse des visiteurs ou n'a pas pu charger la base
  des pays) ; chaque trimestre, relire la table des robots
  (`backend/src/audience/bots.ts`) face aux listes citées dans son en-tête.
- Avant la sortie du paywall refait : mettre à jour les étiquettes de
  confidentialité de l'App Store et la sécurité des données de Google Play
  (événements du parcours d'achat liés au compte).

## Questions encore ouvertes

- Le relais des `utm_*` vers les liens stores (en production depuis le
  15 octobre) demande-t-il un avis juridique ? (spec du compteur)

Tranché le 2026-11-23 après les relectures (détail dans chaque spec) :
« Nommer mes trackers » désactivé par défaut ; pas de bilan ni de jalon de
fin d'année pour le Nouvel An 2026 ; pas de lifetime pour les abonnés ni les
essais ; événements du parcours d'achat sous intérêt légitime, avec la
politique de confidentialité ; l'annuel reste présélectionné partout.

Tranché le 2026-11-24 (spec des stats, seconde version, validée par
Charles sur maquettes) : une seule couleur par case ; à la création, une
seule question, sur l'habitude (« Vous allez le colorier… » tous les jours /
seulement quand ça arrive), et l'ordre des couleurs demandé dans la
légende, à la 2ᵉ couleur ; des libellés de modèles sans ambiguïté (Sommeil
en heures, Dépenses sans chevauchement, Cycle en intensités) ; **rien n'est
définitif** : des réglages du tracker où tout se change, un modèle qui
garde ses phrases tant que sa légende garde sa forme et les retrouve si
elle la retrouve, une estimation qui ne dépend pas du modèle ; un filet de
sécurité pour les trackers « tous les jours » coloriés seulement quand ça
arrive ; les trackers existants reconnus quand ils viennent d'un modèle,
sinon une question une fois sur la page Stats ; l'essai proposé dès le
premier jour, avec des cartes d'exemple ; rappels Non / Matin / Soir par
tracker, au plus deux par jour ; la pop-up « stats prêtes » à la place des
jalons de 7 et 30 jours.

Ajouté le 2026-11-25 : voir un tracker par mois et par semaine, en plus de
l'année (`2026-11-25-tracker-zoom-design.md`, `docs/ROADMAP.md` §11),
spécifié après deux versions d'une page d'essai, gratuit ; et les astuces
qui montrent une à une les fonctions cachées
(`2026-11-25-feature-tips-design.md`, `docs/ROADMAP.md` §12), validées sur
maquettes.

Tranché le 2026-11-25 (passe de confirmation, `docs/CONFIRMATION.md` ;
Charles : « fais selon tes recommandations », donc des *mon choix* de
Fable, à rediscuter si mieux) : les chemins inconnus du site répondent 404 ;
la mesure des achats devient le chantier 0 ; « 5 jours
sur 14 » veut dire 5 dates coloriées parmi les 14 derniers jours ;
l'ancienne légende de Sport et d'Habitudes est une forme à part, et sa
troisième couleur part dans la nouvelle ; un seul écran par mur Premium,
le paywall, sans fenêtre intermédiaire ; le glissement d'une page à l'autre
tourne aussi les années ; le lot 1 des astuces après les rappels, le zoom
après la pop-up. Le même jour, Charles a décidé qu'il n'y aurait qu'une
seule release (voir « Les chantiers, dans l'ordre »).
