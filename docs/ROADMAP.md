# Feuille de route

Une seule liste pour ce qui reste à faire, par ordre de priorité, avec les
mesures qui la justifient. Les plans détaillés vivent à part
(`ANDROID_RELEASE_PLAN.md`, `docs/superpowers/specs/`). Mise à jour le
2026-11-23.

**Phase actuelle (décidée le 2026-11-23)** : recherche, audits et specs
seulement. Rien n'est codé avant une passe de confirmation avec Fable 5 ;
c'est Fable qui codera ensuite. Les recherches vivent dans `docs/research/`.
Point d'entrée pour Fable : `docs/FABLE.md` (ordre des chantiers, branches,
règles du projet, questions ouvertes).

## Audit de conversion (prod, 2026-11-22)

Détail : `docs/research/audit-2026-11-22.md`. 195 vrais comptes (hors test,
VIP et comptes internes `@mydiandian.app`, exclus des scripts
`backend/scripts/prod-*.sql` depuis le 2026-11-23), 50 actifs par semaine,
84 par mois. Rétention : 19 inscrits sur 100 saisissent encore après J7 —
**le goulot, avant le prix**. 9 achats, tous sur l'App Store : 3 lifetime
(≈ 73 % du revenu), 5 essais annuels (2 convertis), 1 essai mensuel ; achats
dans les 51 h après l'inscription ; personne ne s'abonne sans essai ; les 3
acheteurs du lifetime étaient à la limite des 3 trackers. Android : 0 vente,
faute d'essai gratuit configuré (corrigé le 2026-11-23).

## Mesures (prod, hors comptes test et VIP, 2026-10-15)

Requêtes : `backend/scripts/prod-stats.sql`, `backend/scripts/prod-trackers.sql`.

| Indicateur | Valeur |
|---|---|
| Vrais utilisateurs | 73 (71 gratuits, 2 payants) |
| Ont rempli au moins une case | 39 (53 %) |
| Actifs 30 jours (case remplie) | 18 |
| Ont ouvert l'app sur 30 jours | 34 |
| Inscriptions | 23 en septembre, 16 à mi-octobre |
| Trackers gratuits : possèdent 1 / 2 / 3 / 4+ | 43 / 12 / 15 / 1 |
| Gratuits à la limite de 3 qui en utilisent vraiment 3 (30 j) | 4 sur 16 |
| Actifs gratuits 30 j : utilisent 1 / 2 / 3 trackers | 12 / 1 / 4 |
| Trackers gratuits jamais remplis | 64 sur 118 (54 %), dont 45 encore nommés "My Tracker" |
| Payants | 6,5 trackers en moyenne (un en utilise 4+ sur 30 j) |

## Décisions

- **Limite gratuite : rester à 3 trackers.** Elle mord peu (4 gratuits la
  saturent), personne de visible ne manque d'un 4e, et les deux payants sont
  justement des multi-trackers : elle joue son rôle de déclencheur pour les
  gros utilisateurs. La baisser à 2 toucherait les gratuits les plus engagés
  pour un gain incertain sur un échantillon de 73.
- **Le vrai sujet est l'activation, pas le prix d'entrée** : la moitié des
  comptes ne remplissent jamais une case et gardent le tracker par défaut
  vide.

## À faire, par priorité

### 1. Activation (premier geste) — implémenté, à sortir
Objectif : faire poser le premier point à l'inscription. Spec validé le
2026-10-15 : `docs/superpowers/specs/2026-10-15-activation-first-tracker-design.md`,
plan `docs/superpowers/plans/2026-10-15-activation-first-tracker.md`.
- Backend 1.2.0 : `POST /api/pages` avec légendes et remplacement d'une page
  vide, `bootstrap.activated`, plus de "My Tracker" à l'inscription,
  `cells.created_at`, `scripts/prod-activation.sql`.
- App 1.4.0 : parcours en deux écrans (modèle → point du jour) pour tout
  compte sans case, bouton Aujourd'hui dans le tracker.
- Mesure de succès : part des nouveaux comptes avec ≥ 1 case à J+1 et J+7
  par cohorte hebdomadaire (aujourd'hui ~53 % à vie). Première lecture de
  référence à la sortie, bilan à huit semaines.

### 2. Mesurer la demande bloquée par la limite — fait (2026-10-16, backend 1.2.0 / app 1.4.0)
`POST /api/events` + table `events` : l'app envoie un événement à chaque mur
premium affiché (`paywall.tracker_limit`, `locked_tracker`, `themes`, …).
Lecture : `backend/scripts/prod-events.sql`. À lire quelques semaines après
la sortie de la 1.4.0, avant de toucher à la limite. Au passage : limite
appliquée côté serveur, et le passage en gratuit laisse choisir les 3
trackers gardés (les plus actifs par défaut).
**Reste (audit du 2026-11-22, « Trous de mesure »)** : la plateforme et la
version de l'app sur les événements ; les étapes du parcours d'achat
(paywall affiché, formule, achat lancé / réussi / annulé) ; le webhook
RevenueCat qui ignore `CANCELLATION` et jette période (essai ou non), prix,
devise, raison d'annulation et environnement (sandbox) — garder chaque
événement brut dans une table à part ; une ouverture d'app.

### 3. Communication — Pinterest en cours (décidé le 2026-10-15)
Plan éditorial : `marketing/pinterest/PLAN.md`. Épingles générées
(`marketing/pinterest/pins.py`, 6 thèmes × en / fr / zh-Hant, 1000 × 1500,
copies dans `pins.csv`). La landing reporte `utm_source` / `utm_campaign`
sur les boutons stores (referrer Play ; App Store via `pt`/`ct`, en prod
depuis le 2026-10-15 avec backend 1.1.1). Compte Business, 6 tableaux et
lot 1 (6 en + 3 fr + 2 zh-Hant) publiés le 2026-10-15. Reste : lire
Pinterest Analytics et App Store Connect → Sources vers le 29 octobre, lot 2
(nouveaux thèmes) ensuite, mesurer à 8 semaines ; puis export PNG
épinglable dans l'app (1.3.x). Ensuite : vidéo courte (TikTok / Reels /
Shorts) avec des outils IA pour éviter le montage.
Lot 1 lu le 2026-11-22 : l'anglais fait ≈ 93 % des clics ; meilleures
épingles Mood (2,3 k impressions, 54 clics) et Sleep (1,2 k, 58 clics) ;
lot 2 surtout en anglais, thème 2027.
**Attribution App Store, à corriger (noté le 2026-11-23)** : aucune ligne
Pinterest n'apparaît dans App Store Connect › Acquisition › Campagnes. La
landing (`storeLinks()` dans `backend/src/routes/landing.ts`) fait
`ct = <source>-<campagne>`, soit un nom par épingle (`pinterest-mood-en`,
`pinterest-sleep-fr`…), et Apple n'affiche un nom qu'à partir de 5 premiers
téléchargements dans les 24 h du clic : les téléchargements Pinterest sont
éparpillés sous le seuil. À faire avec Fable : un `ct` par source (`pinterest`)
ou par source et langue (`pinterest-en`), le détail par épingle restant dans
le referrer Play. En face, ChatGPT cite la landing avec
`utm_source=chatgpt.com`, sans campagne : une seule ligne `chatgptcom`, 34
vues de la page App Store et 10 téléchargements entre mi-octobre et le
22 novembre. La landing n'a pas de journal de visites (Caddy sans log
d'accès) : ses visites ne se comptent pas.
**Compteur de visites du site — spécifié le 2026-11-23**, révisé après la
recherche `docs/research/reports/Mesure de trafic auto hébergée.md` :
`docs/superpowers/specs/2026-11-23-landing-visits-design.md`. Compteur maison
dans le backend (aucun outil open source ne tient sur le VPS en nommant les
robots), sans cookie ni IP gardée : visites, visiteurs uniques du jour, site
d'origine, navigateur intégré, appareil, pays (DB-IP Lite), clics vers
chaque store par `/go/apple` et `/go/play`, robots nommés par famille et
vérifiés par les listes d'IP des opérateurs. Pas de valeur `utm_*` stockée
(la grille CNIL de juillet 2025 exclut la mesure des canaux d'acquisition) :
le détail par épingle se lit dans Pinterest Analytics, App Store Connect et
la Play Console ; option de repli activée (quand le `Referer` manque,
`utm_source` traduit en nom de site d'une liste fermée), car les apps
ChatGPT n'en envoient presque jamais. Pas d'écran : lecture par `prod-landing.sql` (Claude Code ou
scripts). Module autonome ; Fable écrira la fiche du playbook
(`~/Documents/Coding/playbook`). Volet légal : section de la politique de
confidentialité, lien d'opposition, registre. Environ 3 à 4 jours, dans le
même lot que le regroupement du `ct` Apple. L'Install Referrer Android lié
au compte est abandonné (2026-11-23). Fait hors lot et en production le
2026-11-23 (backend 1.2.1) : le site ne montre plus que l'App Store sur
iPhone et Google Play sur Android, les deux quand l'appareil ne se reconnaît
pas.
Images App Store (iOS 27), refaites le 2026-11-23 : en-tête de page produit
= le titre 点点 / Dian Dian avec une semaine de points
(`marketing/header_page.py`, une image pour toutes les langues) ; image des
résultats de recherche = trois trackers, sans logo, par langue
(`marketing/search_results.py`). Une image par emplacement : l'image
universelle 16:9 était recadrée dans la recherche. Reste : les charger,
vérifier l'aperçu iPhone et iPad.

### 4. Engagement : succès, série, notifications (puis avatars, widgets)
Brainstorm du 2026-10-14, en pause ; rappel et précisions du 2026-10-28. But :
faire revenir les gens tous les jours, de façon un peu plus ludique, sans
devenir anxiogène (ton cozy / pixel-art). À reprendre par un spec
(`docs/superpowers/specs/`), aucun code avant.

- **Collection et succès.** Des icônes à collectionner, des succès nommés
  (premier point, une semaine, un mois sans trou, 100 jours, année pleine,
  5 trackers, 50 commentaires, 8 couleurs, saisie après minuit, 1er janvier…).
  Purement symboliques : pas de jours premium gagnés, pas de thèmes vendus
  en premium débloqués (décidé le 14). Couche cosmétique à part : avatars
  de chat (skins), personnels, hors premium.
- **Série (streak).** Règle énoncée par Charles le 2026-10-28 : utiliser
  l'app cinq jours d'affilée = série de 5 ; un jour sans, ça repart à zéro.
  **Rattrapage** (idée du 2026-10-28, à discuter au spec) : plutôt qu'une
  remise à zéro sèche, un système de « sauvetage » — quand la série casse, un
  bouton pour la sauver et la continuer, limité par un stock de rattrapages
  (crédits), qui pourrait être plus petit en gratuit, ou conditionné à une
  pub vidéo de 30 s en gratuit ; en premium, sans pub (jamais de pub en
  premium) et peut-être plus de rattrapages. Point d'attention : la règle
  « récompenses purement symboliques » (pas de valeur économique) tient
  toujours, le rattrapage est une tolérance, pas une monnaie ; et une pub
  récompensée est un nouveau format AdMob à intégrer. La « vie »
  hebdomadaire proposée le 14 (un jour manqué pardonné) est une variante
  plus simple du même besoin. Deux séries distinctes : la série **globale**
  d'engagement (jour où l'utilisateur a saisi quelque chose, quelle que soit
  la date coloriée) et les séries **par tracker**, calendaires, qui existent
  déjà côté client. La série globale doit être **serveur** (multi-appareils,
  widgets, notifications) ; il faut stocker le fuseau horaire de
  l'utilisateur (aucun aujourd'hui, sinon ça casse à minuit UTC). Des
  « pixels » (+1 par jour saisi, bonus aux paliers, ne baissent jamais)
  amortissent la casse d'une série ; pas de niveaux ni d'XP.
- **Notifications — spécifié le 2026-11-23** :
  `docs/superpowers/specs/2026-11-23-reminders-design.md`, appuyé sur la
  recherche `docs/research/reports/Notifications de rappel et fidélisation.md`.
  Locales, opt-in. Chaque tracker est quotidien ou occasionnel (choisi à la
  création ; les occasionnels, comme les règles, ne rappellent jamais). Un
  seul rappel groupé par jour au plus, à 20 h 30 par défaut, seulement s'il
  reste un tracker quotidien vide, dès le soir de J1 ; silence après 3
  rappels ignorés, un dernier message à J+10 au plus tous les 60 jours ;
  écran de demande juste après le premier point ; section « Rappels » dans
  les réglages ; noms de trackers masqués sur l'écran verrouillé.
  **Abandonnés** d'après la recherche : « série en danger » et « succès
  débloqué » en notification, et toute promotion ; le rappel de fin d'essai
  aussi (Charles, 2026-11-23 : pas de gain démontré). Décidé le 2026-11-23 : plugin dans sa version la plus récente,
  donc montée en AGP 9 d'abord (point 6).
  Pour la série, la recherche recommande de compter les **jours coloriés**
  (rattraper un jour répare la série) et de ne jamais afficher de remise à
  zéro : à reprendre au spec de la série.
- **Widgets** (iOS WidgetKit, Android) en dernier : point du jour, série,
  mini-grille du mois, avatar.

Détail des décisions et du catalogue dans la note de reprise (mémoire de
session, `handoff_engagement_roadmap`) ; à finir de recopier ici au spec.

### 5. Grille du tracker en CustomPainter (phase 2 perf)
Un seul paint au lieu de ~2000 widgets par tap. Gain réel sur les
appareils lents, risque visuel : à faire isolément, avec comparaison
pixel-à-pixel.

### 6. Toolchain Android
Remarques Play Console : bannière AdMob sous la navigation 3 boutons à
vérifier, puis AGP 9.1 / Gradle 9.3.1 (et non 9.1) / Kotlin 2.3 + R8 dans une release
dédiée testée sur appareil. Détail : `ANDROID_RELEASE_PLAN.md` §8.
Prérequis des rappels (point 4), décidé le 2026-11-23 : pas de plugin
ancien, on monte en AGP 9 même si la mise à niveau demande du travail, puis
on prend la version la plus récente de `flutter_local_notifications` (23.x
exige AGP ≥ 9.1.1).

### 7. Esthétique : animations, sons, vibrations, écran de lancement — fusionné sur master le 2026-10-28
Brainstormé et spécifié le 2026-10-22 :
`docs/superpowers/specs/2026-10-22-animations-design.md`, branche
`feat/animations`, livraison en app 1.5.0 après la 1.4.0. Une seule règle de
timing (`lib/theme/motion.dart`), zéro en animations réduites. Périmètre :
morphing carte → tracker à l'ouverture et à la fermeture, ouverture et
fermeture de tous les pop-ups, pop du point qui se remplit, glissement au
changement d'année, boutons sous le doigt, cascade et apparition /
suppression des cartes. Ton de référence : la boîte « Nouveautés », léger,
jamais un spectacle.
Lot 2, brainstormé et spécifié le 2026-10-23 :
`docs/superpowers/specs/2026-10-23-sounds-design.md`, plan
`docs/superpowers/plans/2026-10-23-sounds.md`. Dix moments, trois palettes
à l'essai sur l'appareil (Papeterie / Mixkit, Interface douce / Kenney CC0,
Pixel / synthèse), une seule livrée, réglage « Sons » pour tout couper.
Validé sur l'iPhone et fusionné le 2026-10-28 (70 commits) : morphing,
reveal, dix-huit sons synthétisés (`tools/sounds/cute_palette.py`, famille
bulles / plops / marimba / ding / souffle, plus aucun clic en bois),
réglages « Sons » et « Vibrations », vibrations ciblées, écran de lancement
natif (titre et points, `tools/launch/render.py`). Décidé le 2026-10-29 :
tout sort en **une seule version, la 1.4.0** (jamais publiée) ; ses notes
(CHANGELOG, `docs/changelogs/1.4.0.md`, encart Nouveautés) couvrent
l'activation et tout ceci. Backend 1.2.0 à déployer avant l'app. Passe Android encore à
faire (sons, vibrations, écran de lancement sur Android 11 et moins).
Lot 3, fait le 2026-10-28 : un point qui porte un commentaire est un anneau
(un trou de la couleur de l'écran au centre, un tiers du point), choisi sur
maquettes contre une pastille, une queue de bulle et un trait ; le morphing
fait apparaître le trou avec les points ; rien sur les cartes ni l'export.
Petits points clos le 2026-10-29 : le titre voyage aussi en paysage (ancre
du panneau avec sa taille, centré ; un titre replié se fond dans le bloc),
le crayon du titre en paysage sur sa ligne et à l'échelle ; « Réduire les
animations » marche enfin sur iOS (Flutter livre Reduce Motion comme
`reduceMotion`, jamais dans MediaQuery) et l'encart Nouveautés comme le pop
du point sont instantanés sous l'option ; l'anneau de commentaire a un
liseré accent pour rester visible sur un point de la couleur de l'écran ;
titre long qui défile pendant le morphing : jugé invisible, laissé. Écarté
le 2026-10-29 : avaler le retour
système pendant la fermeture du tracker (deux retours rapides fermaient
l'app sur Android) — décision de Charles, deux appuis rapides sont une
intention de sortir, le correctif a été annulé.

### 8. Prix : étude de marché avant de retoucher l'offre — fait le 2026-11-23
**Livré** : `docs/PRICING.md`, d'après la recherche
`docs/research/reports/Prix abonnement et achat à vie.md` et l'audit.
Abonnement et lifetime gardés ; mensuel 2,99 $ inchangé, annuel 8,99 →
14,99 $, lifetime 22,99 → 29,99 $ (décidé le 2026-11-23) ; en euros 2,99 /
14,99 / 29,99 € (aujourd'hui 1,99 / 9,99 / 24,99 €) ; essai de 7 jours
gardé ; mêmes prix sur Android ; abonnés actuels protégés ; changement le
1er décembre, relecture début mars. Android : offres d'essai
`monthly-free-trial` / `yearly-free-trial` créées le 2026-11-23. Message de
résiliation App Store rédigé (quatre langues). Promotions saisonnières en
pause. Reste : changer les prix le 1er décembre (Charles), vérifications Android,
refonte du paywall (annuel par mois, mensuel en lien, lifetime visible, mur
des 3 trackers centré sur le lifetime).

Demande d'origine (2026-10-28) :
Intuition de départ : les prix actuels (mensuel / annuel / à vie, via
RevenueCat ; les montants vivent dans App Store Connect et la Play Console,
pas dans le code) ne sont « pas forcément adaptés ». Avant d'y toucher, une
recherche approfondie : études déjà publiées sur ce que les gens acceptent de
payer pour un suivi d'habitudes / d'humeur / « année en pixels », abonnement
contre achat unique (part des utilisateurs qui refusent l'abonnement, prix
d'ancrage d'un achat à vie, conversion et rétention typiques des apps de
suivi), benchmarks de prix de l'existant (à lire avec prudence : peu de
téléchargements sur cette catégorie, donc peu probant), et tout ce qui
existe sur le sujet (rapports RevenueCat « State of Subscription Apps »,
Sensor Tower / data.ai, forums d'indés, enquêtes de disposition à payer).
Croiser avec nos propres chiffres : murs premium affichés (point 2,
`backend/scripts/prod-events.sql`) et ventes réelles. Livrable : une note
`docs/PRICING.md` avec les sources, une fourchette recommandée par formule
(mensuel, annuel, à vie), et la question abonnement seul / achat unique seul
/ les deux tranchée avec ses raisons. Ne rien changer dans les stores avant
cette note.

### 9. Pop-up premium occasionnelle — spécifié le 2026-11-23
`docs/superpowers/specs/2026-11-23-premium-popup-design.md`. Après le point
du jour, jamais au lancement ; étapes affichées une seule fois (3 trackers
avec un usage régulier, 7e et 30e jour remplis avec un aperçu des stats,
fin d'année avec l'export) ; rien les premiers jours, une pop-up toutes les
deux semaines au plus, plus rien après 2 refus (définitif), jamais pour les
payants ; réglable à distance par le bootstrap. Décidé le 2026-11-23 : usage
régulier = 5 jours sur 14 ; l'aperçu dévoile gratuitement une vraie stat,
les plus poussées restent premium (voir le point 10). Public encore petit (≈ 16 gratuits
actifs à 3 trackers) : il grandit avec la rétention, donc après les rappels.
**Pop-up promo** (annonces datées pilotées par le serveur, prix barré par un
produit promo) : décrite dans le même spec, **en pause** avec toutes les
promotions.

### 10. Stats plus utiles — à brainstormer (demandé le 2026-11-23)
Charles : même en premium, les stats « n'apportent pas grand-chose ». Une
app dédiée (au suivi des règles, par exemple) va bien plus loin ; Dian Dian
ne peut pas viser un thème précis, mais ses stats peuvent devenir plus
utiles. Idée de fond : une vraie stat dévoilée gratuitement en teaser
(pop-up premium, point 9), les plus intéressantes en premium.
Aujourd'hui : en gratuit, jours remplis, série en cours et % de l'année
(barre latérale du tracker) ; en premium (`StatsDetailDialog`,
`GlobalStatsDialog`), en plus la meilleure série, la répartition des
légendes, le remplissage par mois, la répartition par jour de la semaine,
et des totaux tous trackers (trackers, jours, meilleure série, tracker le
plus actif, cette année ou depuis le début). Que du comptage de
remplissage : presque rien ne parle de ce que les couleurs veulent dire.
Brainstorm en cours, puis un spec avant la passe Fable.

## Fait récemment
- 2026-11-23 : audit de conversion, `docs/PRICING.md`, specs des rappels et
  de la pop-up premium, essais gratuits Android, images App Store ; branche
  `docs/conversion-retention`. Branche `feat/comment-badge` (non fusionnée) :
  pastille de commentaire à la place de l'anneau troué, tuiles Sons et
  Vibrations qui suivent le thème.
- 2026-10-14 : backend 1.1.0 en prod (bootstrap en une requête, store
  client, snapshot disque, fixes décembre / déconnexions / sync légendes),
  outillage de release et de déploiement par script, app 1.3.0 taguée.
