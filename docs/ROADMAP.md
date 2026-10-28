# Feuille de route

Une seule liste pour ce qui reste à faire, par ordre de priorité, avec les
mesures qui la justifient. Les plans détaillés vivent à part
(`ANDROID_RELEASE_PLAN.md`, `docs/superpowers/specs/`). Mise à jour le
2026-10-22.

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

### 4. Engagement (récompenses · notifications · avatars · widgets)
Brainstorm du 2026-10-14, en pause, approche proposée non encore validée :
série d'engagement serveur + pixels + succès, notifications locales,
avatars de chat, widgets. À reprendre par un spec (`docs/superpowers/specs/`)
une fois le point 1 livré. Détail des décisions et idées dans la note de
reprise (mémoire de session) ; à recopier ici au moment du spec.

### 5. Grille du tracker en CustomPainter (phase 2 perf)
Un seul paint au lieu de ~2000 widgets par tap. Gain réel sur les
appareils lents, risque visuel : à faire isolément, avec comparaison
pixel-à-pixel.

### 6. Toolchain Android
Remarques Play Console : bannière AdMob sous la navigation 3 boutons à
vérifier, puis AGP 9 / Gradle 9.1 / Kotlin 2.3 + R8 dans une release
dédiée testée sur appareil. Détail : `ANDROID_RELEASE_PLAN.md` §8.

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
natif (titre et points, `tools/launch/render.py`). Reste pour la sortie :
notes de version 1.5.0 (CHANGELOG, `flutter_app/docs/changelogs/1.5.0.md`
en quatre langues, encart Nouveautés) **une fois la 1.4.0 taguée** — master
contient maintenant la 1.4.0 non sortie et tout ceci ; pour sortir la 1.4.0
seule, taguer `949e164` (master avant la fusion). Passe Android encore à
faire (sons, vibrations, écran de lancement sur Android 11 et moins).
Lot 3, demandé le 2026-10-22, à faire à la suite : un indicateur discret sur
les points qui portent un commentaire (on ne sait plus lesquels en ont ; le
cercle du jour est déjà pris, trouver autre chose de léger).

### 8. Prix : étude de marché avant de retoucher l'offre (demandé le 2026-10-28)
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

## Fait récemment
- 2026-10-14 : backend 1.1.0 en prod (bootstrap en une requête, store
  client, snapshot disque, fixes décembre / déconnexions / sync légendes),
  outillage de release et de déploiement par script, app 1.3.0 taguée.
