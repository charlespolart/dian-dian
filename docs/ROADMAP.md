# Feuille de route

Une seule liste pour ce qui reste à faire, par ordre de priorité, avec les
mesures qui la justifient. Les plans détaillés vivent à part
(`ANDROID_RELEASE_PLAN.md`, `docs/superpowers/specs/`). Mise à jour le
2026-10-15.

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

### 1. Activation (premier geste)
Objectif : faire poser le premier point à l'inscription.
- Premier tracker guidé : proposer un titre et des légendes prêtes à l'emploi
  (mood, sommeil, sport, lecture — les titres qu'on observe) au lieu d'un
  "My Tracker" vide.
- Onboarding qui se termine par le point d'aujourd'hui posé pour de vrai.
- Mesure de succès : part des nouveaux comptes avec ≥ 1 case à J+1 et J+7
  (aujourd'hui ~53 % à vie).

### 2. Mesurer la demande bloquée par la limite
On ne voit pas les gratuits qui tapent "+" avec 3 trackers et tombent sur le
paywall. Ajouter un compteur côté serveur quand le gate "limite de trackers"
s'affiche (une route `POST /api/events` minimale + un appel dans
`PremiumGateDialog`). Donne la vraie valeur de la limite comme levier de
conversion avant d'y toucher.

### 3. Engagement (récompenses · notifications · avatars · widgets · comm)
Brainstorm du 2026-10-14, en pause, approche proposée non encore validée :
série d'engagement serveur + pixels + succès, notifications locales,
avatars de chat, widgets. À reprendre par un spec (`docs/superpowers/specs/`)
une fois le point 1 livré. Détail des décisions et idées dans la note de
reprise (mémoire de session) ; à recopier ici au moment du spec.

### 4. Grille du tracker en CustomPainter (phase 2 perf)
Un seul paint au lieu de ~2000 widgets par tap. Gain réel sur les
appareils lents, risque visuel : à faire isolément, avec comparaison
pixel-à-pixel.

### 5. Toolchain Android
Remarques Play Console : bannière AdMob sous la navigation 3 boutons à
vérifier, puis AGP 9 / Gradle 9.1 / Kotlin 2.3 + R8 dans une release
dédiée testée sur appareil. Détail : `ANDROID_RELEASE_PLAN.md` §8.

## Fait récemment
- 2026-10-14 : backend 1.1.0 en prod (bootstrap en une requête, store
  client, snapshot disque, fixes décembre / déconnexions / sync légendes),
  outillage de release et de déploiement par script, app 1.3.0 taguée.
