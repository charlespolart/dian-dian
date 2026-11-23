# Brief pour Fable

Point d'entrée de la passe de confirmation puis de la construction.
Rédigé le 2026-11-23, à la fin de la phase de préparation (recherches,
audits, specs, sans code — `docs/ROADMAP.md`, en tête).

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

1. Ce fichier.
2. `docs/ROADMAP.md` : la liste des chantiers et leur historique.
3. Les specs de `docs/superpowers/specs/` datées du 2026-11-23 :
   `reminders-design`, `premium-popup-design`, `landing-visits-design`.
4. `docs/PRICING.md` : prix décidés, paywall à refaire (section « Le
   paywall (pour Fable) »).
5. Au besoin, les recherches : `docs/research/reports/` (rapports) et
   `docs/research/notes/` (sources), plus `docs/research/audit-2026-11-22.md`.

## Les branches

| Branche | Contenu | À faire |
|---|---|---|
| `master` | Ce qui est en production : backend **1.2.1** (2026-11-23), app **1.4.0** | Base de travail |
| `docs/conversion-retention` | Toute la préparation : docs, recherches, specs, scripts marketing ; plus `.gitignore` (`marketing/out/`, la même ligne que sur master) | À fusionner dans master (docs seulement, aucun code de l'app ni du backend) |
| `feat/comment-badge` | App : pastille de commentaire à la place de l'anneau troué ; tuiles Sons et Vibrations qui suivent le thème. Testé, analyse propre, entrées dans `flutter_app/CHANGELOG.md` (Unreleased) | À fusionner, sortira avec la prochaine version de l'app ; les notes des stores devront dire que le repère a changé (celles de 1.4.0 parlent d'« un petit anneau ») |
| `feat/landing-store-by-platform` | Déjà fusionnée et en production (1.2.1) | Peut être supprimée |
| `feat/cell-popup-page-list` | Ancien travail en cours, hors de ce brief | — |

## Les chantiers, dans l'ordre

| # | Chantier | Spec | Dépend de | Estimation |
|---|---|---|---|---|
| 1 | Compteur de visites du site, avec le regroupement du `ct` Apple par source | `2026-11-23-landing-visits-design.md`, ROADMAP §3 | rien (backend seul) | 3 à 4 jours |
| 2 | Refonte du paywall et du mur des 3 trackers, événements du parcours d'achat | `docs/PRICING.md` | les prix en stores (Charles, 1er décembre) | à estimer |
| 3 | Outillage Android : AGP 9.1, Gradle ≥ 9.3.1, Kotlin 2.3, `compileSdk = 37` écrit à la main, Dart ≥ 3.12, R8 ; release dédiée testée sur appareil | `ANDROID_RELEASE_PLAN.md` §8 | rien | à estimer |
| 4 | Rappels du soir (notifications locales, cadence quotidien / occasionnel, section Rappels, écran de demande) | `2026-11-23-reminders-design.md` | 3 (le plugin le plus récent exige AGP 9) | à estimer |
| 5 | Stats plus utiles | **pas encore de spec** : recherche `Stats utiles pour trackers génériques.md` et maquettes ; Charles doit dire quelles stats il retient | l'avis de Charles | — |
| 6 | Pop-up premium occasionnelle | `2026-11-23-premium-popup-design.md` | 4 (passe après l'écran des rappels), 5 (l'aperçu montre une vraie stat) | à estimer |
| — | Registre RGPD du projet et politique de confidentialité (événements produit, compteur de visites), en quatre langues | specs du compteur et `docs/PRICING.md` (« Relecture ») | avant ou avec 1 et 2 | ½ jour |

Chaque spec finit par une section « Relecture du 2026-11-23 » : les trous
trouvés en la relisant comme un constructeur, réglés ou laissés à Charles.

Calendrier à garder en tête : les prix changent le **1er décembre** ; le pic
de l'année est le **Nouvel An** (une année en pixels commence le 1er
janvier). Décidé le 2026-11-23 : **avant le Nouvel An**, le compteur de
visites (1), le registre et la politique de confidentialité, puis la
refonte du paywall (2) ; **en janvier**, l'outillage Android (3) puis les
rappels (4) ; pas de bilan de fin d'année en 2026.

## Règles du projet

- **Jamais `dart format`** dans `flutter_app` (pas de `page_width`, lignes
  posées à la main jusqu'à ~140 colonnes). Les garde-fous sont
  `flutter analyze`, les tests et `git diff --stat`.
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
- Backend : `cd backend && npx tsx --test src/lib/*.test.ts` ; la suite
  smoke `npx tsx scripts/smoke.ts` contre un backend local lancé.

## Ce que Charles fait de son côté (hors code)

- Programmer les nouveaux prix dans App Store Connect au plus tard le 28 ou
  le 29 novembre ; Google Play à la main le 1er décembre, pays par pays.
- Charger les nouvelles images App Store (en-tête, recherche), retirer
  l'image universelle ; soumettre le message de résiliation (avec Premium
  Yearly).
- Google Play : bannière d'essai à vérifier sur un téléphone, abonnement à
  renommer « Dian Dian Premium », délai de grâce, packages RevenueCat.
- Demander à Vultr son avenant de traitement des données (DPA).
- Tester le bouton App Store depuis une épingle Pinterest sur iPhone.
- Avant la sortie du paywall refait : mettre à jour les étiquettes de
  confidentialité de l'App Store et la sécurité des données de Google Play
  (événements du parcours d'achat liés au compte).

## Questions encore ouvertes

- Les stats à retenir (chantier 5).
- Le relais des `utm_*` vers les liens stores (en production depuis le
  15 octobre) demande-t-il un avis juridique ? (spec du compteur)

Tranché le 2026-11-23 après les relectures (détail dans chaque spec) :
« Nommer mes trackers » désactivé par défaut ; pas de bilan ni de jalon de
fin d'année pour le Nouvel An 2026 ; pas de lifetime pour les abonnés ni les
essais ; événements du parcours d'achat sous intérêt légitime, avec la
politique de confidentialité ; l'annuel reste présélectionné partout.
