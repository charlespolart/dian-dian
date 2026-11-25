# Rappels — design (2026-11-23, mis à jour le 2026-11-24)

Point 4 de `docs/ROADMAP.md` (engagement, volet notifications). Brainstormé
du 2026-11-22 au 2026-11-23, appuyé sur la recherche
`docs/research/reports/Notifications de rappel et fidélisation.md` (notes
dans `docs/research/notes/Notifications de rappel et fidélisation/`) et sur
l'audit `docs/research/audit-2026-11-22.md`. Décisions validées par Charles le
2026-11-23 (« selon les recommandations »). Phase de documentation : à
confirmer puis construire plus tard ; aucun code n'est écrit avec ce spec.

**Mis à jour le 2026-11-24** (validé par Charles sur les maquettes des
stats, histoire 8 : https://claude.ai/artifact/HVMGhCrPR82sjShMxiht2e).
Charles : une seule heure pour tous ne va pas pour Sommeil, il faut un
réglage par tracker, « mais pas trop complexe ». Chaque tracker choisit
**Non, Matin ou Soir** ; deux heures pour tous (matin 9 h 00, soir
20 h 30) ; **au plus deux rappels par jour**. Le remplissage (« tous les
jours » ou « seulement quand ça arrive ») et le moment du rappel se règlent
à la création et dans les réglages du tracker (spec des stats). Les sections
ci-dessous sont à jour ; le détail des changements est dans « Mise à jour du
2026-11-24 », en fin de document.

## Objectif

L'app n'envoie aucune notification aujourd'hui. Sur 100 inscrits gratuits
(1er septembre – 8 novembre), 19 saisissent encore des points après J7 ; la
plupart partent après le premier jour, et les essais expirés venaient de
gens partis en 1 à 3 jours. Un rappel doux le soir doit faire revenir les
gens pendant ces premiers jours, sans jamais devenir agaçant.

Ce qu'on peut en attendre (recherche) : un rappel fait nettement revenir le
soir même (essai Drink Less, 20 h : ouverture dans l'heure de 3,6 % à ≈ 13 %),
et le maintenir aide un journal à rester à jour (panne des rappels d'un
journal de maux de tête : −11 % de saisies, abandon +32 %). L'effet sur la
rétention à un mois est faible ou non démontré : **quelques points de plus à
J7, pas un doublement**. Le canal s'use : chaque message ignoré entame le
crédit de l'autorisation.

Les mots de Charles : « faut clairement du rappel », mais « pas trop
agressif » ; pas une notification par tracker non rempli ; certains
trackers ne sont pas quotidiens (les règles, par exemple).

## Objectifs, non-objectifs, anti-objectifs

**Objectifs**
- Au plus deux rappels par jour, un le matin et un le soir, chacun
  seulement s'il reste un de ses trackers vide.
- Demander l'autorisation au bon moment, avec un écran de l'app avant le
  dialogue système.
- Se taire quand les rappels sont ignorés, puis un seul dernier message.
- Protéger la vie privée : des noms de trackers comme « Anxiété » ou
  « Règles » ne doivent pas s'afficher n'importe où.

**Non-objectifs**
- Push serveur (Firebase, APNs, cron backend).
- Séries, « série en danger », « succès débloqué » : chantier séparé (point 4
  de la feuille de route), et aucune de ces notifications ne doit exister.
- Heure « intelligente » calculée par l'app ; tests A/B (≈ 200 comptes).
- Relance par e-mail.

**Anti-objectifs** — ce serait un échec même si ça marche :
- plus de deux notifications par jour, ou une par tracker ;
- un rappel que la personne n'a pas choisi pour un tracker « seulement quand
  ça arrive » ;
- un ton culpabilisant : « vous avez oublié », « ne cassez pas »,
  « vous nous manquez », « dernière chance », toute menace de perte ;
- une promotion dans une notification (App Store 4.5.4 : consentement
  explicite exigé ; Google Play : fonctionnalités essentielles seulement) ;
- un nom de tracker sensible sur l'écran verrouillé ;
- harceler pour l'autorisation après un refus ;
- un compteur de série qui retombe à 0.

## Contraintes

- **iOS** : le dialogue système ne s'affiche **qu'une fois** ; pas
  d'autorisation provisoire (silencieuse, inadaptée à un rappel du soir) ;
  niveau d'interruption « Active » ; alerte et son, **sans pastille** ; la
  demande automatique doit être coupée dans `DarwinInitializationSettings`
  pour que l'initialisation du plugin ne grille pas le dialogue unique ;
  64 notifications locales en attente au plus (il en faut 4) ; un écran de
  réglages dans l'app est exigé.
- **Android 13+** : notifications coupées par défaut, `POST_NOTIFICATIONS`
  demandé ; le second refus est définitif ; écran d'explication quand
  `shouldShowRequestPermissionRationale()` est vrai. **Alarmes inexactes**
  (`AndroidScheduleMode.inexactAllowWhileIdle`) : elles peuvent partir
  jusqu'à environ une heure après l'heure demandée. Ne déclarer ni
  `SCHEDULE_EXACT_ALARM` ni `USE_EXACT_ALARM`. Un seul canal. Reprogrammer
  au redémarrage du téléphone. Les surcouches (Huawei, Xiaomi, OnePlus,
  Samsung) peuvent bloquer les notifications programmées : limite acceptée.
- **Plugin** : `flutter_local_notifications` 23.x exige AGP ≥ 9.1.1 ; le
  projet est en AGP 8.11.1 (`flutter_app/android/settings.gradle.kts`) et le
  passage à AGP 9 est prévu dans une release dédiée (point 6 de la feuille
  de route). **Décidé le 2026-11-23** : pas de version ancienne du plugin.
  Le projet monte en AGP 9 (`ANDROID_RELEASE_PLAN.md` §8), même si la mise
  à niveau demande du travail, et on prend la version la plus récente du
  plugin au moment de coder. Ordre : AGP 9 d'abord, puis les rappels.
  Vérifié le 2026-11-23 : la plus récente est la 23.0.4 (publiée le jour
  même ; la 23.0.3 a une régression iOS). Elle demande AGP ≥ 9.1.1, donc
  **Gradle ≥ 9.3.1** (le projet est en 8.14), **compileSdk 37** écrit à la
  main (`flutter.compileSdkVersion` vaut encore 36), le desugaring
  (`desugar_jdk_libs` 2.1.4), Java 17, minSdk 24, Flutter ≥ 3.44 et Dart ≥ 3.12 :
  ces quatre-là sont acquis (vérifié le 2026-11-25 : Java 17, Flutter
  3.47.5, Dart 3.13.4, `flutter.minSdkVersion` = 24). Pour `zonedSchedule` : `timezone` 0.11.2
  et `flutter_timezone` 5.1.1, qui renvoie un `TimezoneInfo` et non plus
  une chaîne depuis la 5.0.
- **Multi-appareils** : la synchro est multi-appareils, les rappels sont
  locaux. Un rappel programmé sur le téléphone peut nommer un tracker déjà
  rempli depuis la tablette. Limite acceptée (voir Approches).
- **Textes figés** à la programmation, et tout changement de texte ou de
  règle demande une mise à jour de l'app : livrer d'emblée une réserve de
  textes généreuse.
- Quatre langues : en-US, fr-FR (**vouvoiement**, comme le reste de l'app),
  zh-Hans, zh-Hant.

## Approches

1. **Notifications locales programmées — retenue.** Tout se passe sur
   l'appareil : à chaque ouverture et à chaque point posé, l'app annule et
   reprogramme ses rappels. Pas d'infrastructure (ni clés APNs, ni Firebase,
   ni jetons à stocker, ni cron par fuseau — on ne stocke d'ailleurs aucun
   fuseau horaire), marche hors ligne, l'état des trackers ne sort pas de
   l'appareil. Surtout, le cycle « trois rappels puis silence » se programme
   d'avance et s'arrête seul, sans savoir si une notification a été vue.
   Coûts : textes et règles livrés avec l'app ; un appareil ignore ce qui a
   été saisi sur un autre.
2. **Push serveur** (FCM / APNs + tâche planifiée côté backend). Connaît
   l'état de tous les appareils, textes et règles modifiables sans mise à
   jour, livraison mesurable. Mais toute une infrastructure nouvelle, des
   fuseaux à stocker, plus de pannes possibles, pour ≈ 200 comptes. La
   feuille de route disait déjà « locales d'abord (pas Firebase) ».
3. **Hybride** : rappels locaux, plus une notification silencieuse du
   serveur pour rafraîchir un appareil quand un autre a saisi. Corrige le
   cas multi-appareils, au prix de toute l'infrastructure du push pour un
   cas marginal.

Choix : **1**. On reconsidère 3 seulement si le cas multi-appareils remonte
dans les retours.

## Décisions

### Le moment du rappel, par tracker (mis à jour le 2026-11-24)

D'abord « quotidien ou occasionnel » (option C, choisie le 2026-11-22) ;
remplacé le 2026-11-24 par deux réglages du tracker, décrits dans la spec
des stats (`2026-11-24-stats-design.md`, « Le modèle » et « Les réglages
du tracker ») :

- **Le remplissage** : « Tous les jours, même les jours sans » ou
  « Seulement les jours où ça arrive » (`pages.cadence`, `'daily' |
  'occasional'`). Demandé à la création, prérempli par un modèle.
- **Le rappel** : **Non, Matin ou Soir** (`pages.reminder`, `'none' |
  'morning' | 'evening'`). Prérempli : Soir pour « tous les jours », Non
  pour « seulement quand », celui du modèle (Sommeil : Matin, puisqu'on
  colorie le jour du réveil ; Cycle : Non).
- Un tracker sur Non ne déclenche jamais de rappel et n'y est jamais
  nommé. Quelqu'un dont aucun tracker n'a de rappel n'en reçoit aucun, et
  ne voit pas l'écran de demande.
- **Modifiable à tout moment** : dans les réglages du tracker (la roue) et
  dans Réglages › Rappels. Le lot 1 des stats construit la question, les
  fiches des modèles et les réglages du tracker avant ce chantier : les
  rappels n'ont pas à toucher `_CreateTrackerDialog` ; ils rendent visible
  la ligne « Rappel », cachée jusque-là.
- Le parcours d'accueil (`first_tracker_screen.dart`) crée des trackers
  depuis des modèles, avec leur rappel, sans poser de question. Les
  trackers existants : Soir, sauf ceux reconnus comme un modèle, qui
  prennent celui du modèle (spec des stats, « Les trackers déjà créés ») ;
  la section Rappels les liste pour corriger.
- **Stockage synchronisé** : ce sont des propriétés du tracker, donc côté
  serveur, renvoyées par le bootstrap et les routes pages, acceptées par
  `POST /api/pages` et la mise à jour d'une page ; champs dans
  `PageModel`. Les colonnes viennent du lot 1 des stats. Noms exacts au
  constructeur.

### Le rappel

1. **Au plus deux notifications par jour**, une par moment (matin, soir),
   chacune regroupant ses trackers. Pas d'heure libre par tracker : avec
   cinq trackers, cela pourrait faire cinq notifications par jour, ce qui
   fait couper les notifications (recherche).
2. **Un moment n'envoie rien si tous ses trackers sont remplis** pour la
   date du jour au moment où l'app programme (voir le cycle). Les plus
   réguliers reçoivent automatiquement moins de messages (leçon de
   Pinterest et Twitter : envoyer moins aux non-répondants ne coûte rien).
3. **Deux heures pour tous** : matin **9 h 00**, soir **20 h 30** par
   défaut, modifiables dans Réglages › Rappels, présentées comme des
   moments (« quand la journée se pose »). Pas d'heure magique dans la
   recherche ; la régularité compte ; Android peut retarder d'une heure, et
   les Focus de sommeil se placent plus tard.
4. **Premier rappel le J1**, au premier moment dû, jamais le jour de
   l'inscription : ce jour-là, la personne vient d'utiliser l'app, et c'est
   après J1 qu'on perd la majorité des gens. C'est le rappel le plus
   important.
5. **Week-end compris.**
6. **Silence après 3 rappels consécutifs sans aucune ouverture de l'app**,
   quel que soit leur moment (*mon choix* : on compte les notifications,
   pas les jours ; avec un tracker le matin et un le soir, le silence vient
   donc au bout d'un jour et demi) ; toute ouverture remet le compteur à
   zéro. Le critère est l'ouverture, pas la saisie : quelqu'un qui ouvre
   tous les trois ou quatre jours garde ses rappels.
7. **Un dernier message, 10 jours après la dernière ouverture**, à l'heure
   du soir (du matin si aucun tracker n'a le soir), avec un texte jamais
   vu : il annonce la pause avec douceur et rappelle que les jours passés
   se colorient encore. **Au plus un tous les 60 jours.** Ensuite plus rien
   jusqu'au retour.
8. **Un tap** ouvre la journée en cours. *Mon choix* : si un seul tracker
   de ce moment est vide, l'ouvrir sur aujourd'hui ; sinon, la liste.
9. **Jamais de promotion**, jamais de « série en danger », jamais de
   « succès débloqué ». Le rappel peut mentionner un fait positif s'il est
   vrai (« 12 jours coloriés ce mois-ci »).

### Le cycle, entièrement local

À chaque ouverture (retour au premier plan compris), après chaque point
posé ou effacé, et après une synchro qui change les points du jour, l'app :

1. annule les notifications de rappel en attente ;
2. si les rappels sont activés et autorisés, programme **les trois
   prochains rappels dus**, dans l'ordre du temps. Un moment (matin ou
   soir d'un jour) est dû si son heure n'est pas passée, que ce n'est pas
   le jour de création du compte, et qu'un de ses trackers est vide ce
   jour-là : aujourd'hui selon les points posés ; les jours suivants, tous
   ses trackers sont vides (textes calculés maintenant). Exemples :
   Sommeil le matin et Humeur le soir, ouverture à 14 h avec Sommeil rempli
   → ce soir, demain matin, demain soir ; seulement Humeur le soir → ce
   soir, demain soir, après-demain soir ;
3. programme le **dernier message** : dernière ouverture + 10 jours, à
   l'heure du soir (ou du matin), si aucun dernier message n'a été envoyé
   depuis 60 jours.

Si la personne ne revient pas, les trois rappels partent, puis le téléphone
se tait de lui-même, le dernier message arrive, puis plus rien. Toute
ouverture relance le cycle. L'app n'a jamais besoin de savoir si une
notification a été vue. Pour la règle des 60 jours : noter localement la
date du dernier message programmé, et le considérer comme envoyé quand
l'app s'ouvre après cette date.

*Mon choix* : écrire ce calcul comme une fonction pure (maintenant, date de
création du compte, dernière ouverture, trackers avec leur moment de rappel
et leurs points du jour, réglages, date du dernier « dernier message ») →
liste de notifications à programmer, testée unitairement ; le plugin ne
fait que programmer la liste.

### Demander l'autorisation

- **Moment** : juste après le premier point posé (fin du parcours
  d'accueil, ou premier point d'un compte sans rappels). Apple décrit
  exactement ce cas (« après que la personne a programmé une première
  tâche ») ; attendre le 3e lancement reviendrait à ne jamais demander à la
  plupart des gens, qui partent après J1.
- **Écran de l'app d'abord**, dans le style pixel (histoire 8 et étape 6
  de l'histoire 1 des maquettes) : « Un petit rappel ? Seulement quand un
  tracker attend encore sa couleur du jour. Jamais quand tout est
  rempli. » ; la liste des trackers qui ont un rappel, avec leur moment
  (« Sommeil — le matin, 9 h 00 », « Humeur — le soir, 20 h 30 ») ;
  « Heures et trackers se changent dans Réglages › Rappels. » ;
  l'interrupteur « Nommer mes trackers » (désactivé, « Sinon : « Une case
  attend sa couleur du jour. » ») ; boutons « Oui, me le rappeler » et
  « Pas maintenant ». Pas de sélecteur d'heure sur cet écran (mis à jour le
  2026-11-24 : il y en aurait deux). Le bouton ne s'appelle pas
  « Autoriser » ; aucune récompense promise (règle 5.1.2(i)). **Seul le
  oui déclenche le dialogue système** : refuser l'écran de l'app ne
  consomme pas le dialogue unique d'iOS ni l'un des deux refus d'Android.
  Si aucun tracker n'a de rappel, l'écran ne s'affiche pas.
  Donner une raison rend l'acceptation 12 % plus probable (Tan et al.) ;
  base réaliste : environ un utilisateur sur deux accepte, davantage en
  contexte.
- **Après « Pas maintenant »** : un seul nouvel écran, au premier point
  d'une session ultérieure, puis plus jamais de fenêtre. L'entrée Rappels
  reste dans les réglages.
- **Android** : `POST_NOTIFICATIONS` seulement après le oui ; après un
  premier refus, le oui suivant passe par un écran d'explication avant le
  second et dernier dialogue.
- **Utilisateurs existants** : le même écran, titré « Nouveau : un petit
  rappel », une seule fois, après leur prochain point, jamais au lancement.
- **Priorité** : cet écran passe avant la pop-up premium
  (`2026-11-23-premium-popup-design.md`) ; jamais deux fenêtres à la suite
  après un même point.

### Réglages : section « Rappels »

Dans `settings_screen.dart`, à côté de Sons et Vibrations
(`SoundsSettings`), même titre de section et même tuile :

- interrupteur des rappels ;
- les deux heures, Matin (09:00) et Soir (20:30) ;
- « Nommer mes trackers » (« sur l'écran verrouillé aussi ») ;
- « Chaque tracker » : la liste des trackers, chacun avec Non / Matin /
  Soir ;
- une ligne : « Au plus deux rappels par jour, chacun seulement si un de
  ses trackers attend encore sa couleur du jour. »

Si le système a refusé, la section le dit en une ligne et propose d'ouvrir
les réglages de notification du téléphone, **seulement sur une action de
l'utilisateur** (`openNotificationSettingsURLString` à partir d'iOS 16,
réglages du canal sur Android). L'app vérifie l'autorisation à chaque retour
au premier plan. *Mon choix* : interrupteur, heures et « nommer » sont
**locaux à l'appareil** (chaque appareil a sa propre autorisation) ; le
moment de chaque tracker et son remplissage sont synchronisés.

### Textes

- **8 à 10 textes par langue**, écrits directement dans chaque langue (la
  traduction change la performance d'un texte, Duolingo) ; jamais le même
  deux jours de suite, de préférence pas dans les deux semaines.
- **Noms des trackers en tête, deux au plus, puis « + N »** : la
  notification repliée d'Android n'affiche qu'environ 40 à 50 caractères.
- Le titre ne reprend pas le nom de l'app. Une phrase peut rappeler la
  routine (« avant de dormir »).
- Exemples (fr, vouvoiement) :

| Situation | Exemple |
|---|---|
| Le matin | « Sommeil attend la couleur de votre nuit. » |
| Deux trackers vides | « Humeur et Énergie attendent leur couleur du jour. » |
| Plus de deux | « Humeur, Lecture + 2 : votre grille garde une place pour ce soir. » |
| Routine | « Avant de dormir, un point pour Humeur ? » |
| Fait positif, s'il est vrai | « 12 jours coloriés ce mois-ci. Humeur attend celui d'aujourd'hui. » |
| Noms masqués / écran verrouillé | « Une case attend sa couleur du jour. » / « Quelques cases attendent leur couleur du jour. » |
| Dernier message (J+10) | « Votre grille vous attend, sans pression. Les rappels sont en pause ; ils reprendront à votre prochain point. Les jours passés se colorient aussi. » |

### Vie privée

- Réglage global « Nommer mes trackers dans le rappel ». **Décidé le
  2026-11-23 après relecture : désactivé par défaut** (voir « Relecture »),
  l'interrupteur étant montré sur l'écran qui propose les rappels pour
  l'activer d'un geste. Première version, remplacée : activé par défaut,
  avec une version générique sur l'écran verrouillé. Vérifié le 2026-11-23 : le plugin ne donne sur Android que la
  visibilité privée (pas de version publique) et sur iOS aucun texte de
  remplacement, alors que les deux API natives existent (`setPublicVersion`,
  `hiddenPreviewsBodyPlaceholder`). *Mon choix* : s'en tenir au masquage du
  système (Android `NotificationVisibility.private`, aperçus masqués d'iOS),
  qui cache déjà le texte sur l'écran verrouillé quand le téléphone le
  demande ; un texte générique maison demanderait du code natif, laissé au
  constructeur s'il est simple.
- Exclusion du nom tracker par tracker (suggérée par la recherche) : laissée
  en option, aucun modèle actuel n'étant sensible.

**Tranché (relecture du 2026-11-23)** : le masquage du système ne cache les
noms que si la personne a déjà choisi de masquer le contenu des
notifications, et par défaut Android montre tout sur l'écran verrouillé ;
« Nommer mes trackers » est donc désactivé par défaut. Voir « Relecture du
2026-11-23 ».

### Rappel de fin d'essai : abandonné

**Décidé le 2026-11-23** : ni sur Android ni sur iOS. Charles ne le voulait
que s'il était statistiquement intéressant ; rien ne montre qu'un rappel de
fin d'essai fasse gagner des ventes (il évite seulement des prélèvements
surprise ; Google Play prévient d'ailleurs déjà par e-mail, Apple ne
documente aucun rappel). Les rappels restent des rappels de saisie, rien
d'autre.

## Mesure

À 200 comptes, aucun test ne tranchera ; quelques compteurs vérifient que
le dispositif se comporte comme prévu. Événements par la route existante
`POST /api/events` (noms en minuscules à points) :

| Événement | Quand |
|---|---|
| `reminder.prompt_shown` / `reminder.prompt_yes` / `reminder.prompt_later` | écran de l'app |
| `reminder.permission_granted` / `reminder.permission_denied` | résultat du dialogue système |
| `reminder.tap.morning` / `reminder.tap.evening` | ouverture par un rappel, selon son moment |
| `reminder.open_2h` | ouverture dans les 2 h suivant l'heure d'un rappel programmé (mesure de Duolingo) |
| `reminder.silence_return` | retour après le silence (les 3 rappels passés sans ouverture) |
| `reminder.final_open_48h` | ouverture dans les 48 h suivant le dernier message |
| `reminder.permission_revoked` | autorisation retirée, détectée au retour au premier plan |
| `reminder.disabled` | interrupteur coupé dans les réglages |

Les événements n'ont pas de plateforme aujourd'hui (voir l'audit, « Trous
de mesure ») : l'ajouter dans la même version. Lecture de la rétention :
cohortes J1 / J7 de `backend/scripts/prod-activation.sql` avant / après,
brouillées par Pinterest et janvier ; un ordre de grandeur seulement.

## Laissé au constructeur

- Livrer les rappels dans la release AGP 9 ou dans la suivante (le plugin
  est pris dans sa version la plus récente, décidé).
- Le schéma des identifiants de notifications, le canal Android (nommé
  « Rappels », importance par défaut, catégorie rappel), le récepteur de
  redémarrage.
- L'écriture finale des textes dans les quatre langues. Le chinois est
  écrit directement en chinois, en phrases courtes ; relu par un natif
  avant la sortie si Charles en a un sous la main, sinon tel quel, comme les
  autres textes chinois de l'app.
- Les tests : la fonction de cycle en unitaire ; le reste à la main sur un
  iPhone et un Android (dont Android 13+ et un redémarrage).

## Questions closes le 2026-11-23

1. **Ordre de sortie** : montée en AGP 9 d'abord, plugin le plus récent ;
   pas de version ancienne compatible AGP 8.
2. « Nommer mes trackers » : d'abord activé par défaut, puis **désactivé
   par défaut** après relecture (voir « Relecture du 2026-11-23 »).
3. Rappel de fin d'essai : **abandonné**, sur Android comme sur iOS.
4. Textes chinois : écrits directement en chinois ; relecture native si
   possible (voir « Laissé au constructeur »).

## Relecture du 2026-11-23

Une relecture « comme un constructeur » a trouvé trois trous.

1. **Trackers abandonnés.** Tous les trackers existants deviennent
   quotidiens ; un tracker qu'on ne remplit plus déclencherait le rappel
   chaque soir, même chez les plus réguliers (54 % des trackers gratuits
   n'ont jamais été remplis ; les payants ont 6,5 trackers en moyenne).
   *Mon choix* : un tracker avec un rappel, sans aucun point depuis 14 jours, ne
   déclenche pas le rappel et n'y est pas nommé (`lastCellAt` du
   `PageModel`) ; il redevient actif à son prochain point. À tester dans la
   fonction de cycle.
2. **Noms sur l'écran verrouillé — décidé (Charles, 2026-11-23) :
   « Nommer mes trackers » désactivé par défaut**, l'interrupteur affiché
   sur l'écran de l'app qui propose les rappels (un geste pour l'activer) et
   dans la section Rappels. Le constat : Le masquage du
   système (Android `private`, aperçus masqués d'iOS) ne s'applique que si
   la personne a déjà choisi de masquer le contenu ; par défaut, Android
   affiche « Humeur, Anxiété… » sur l'écran verrouillé, ce que l'objectif de
   vie privée interdit. Le code natif n'y change rien. Choix : accepter les
   noms ; « Nommer mes trackers » désactivé par défaut ; ou visibilité
   `secret` sur Android (rappel invisible sur l'écran verrouillé).
3. **Deux appareils.** Accord et interrupteur par appareil : quelqu'un qui a
   dit oui sur un iPhone et un iPad reçoit deux rappels. *Mon choix* :
   accepté (accord donné sur chaque appareil, cas rare) ; pas de champ
   serveur en plus.

## Mise à jour du 2026-11-24

Validée par Charles avec les maquettes des stats (« c'est bon pour moi »,
histoire 8 de https://claude.ai/artifact/HVMGhCrPR82sjShMxiht2e). Ce qui
change par rapport à la version du 2026-11-23 :

1. **Un moment par tracker** : Non, Matin ou Soir (`pages.reminder`), au
   lieu de « quotidien ou occasionnel ». Défauts : Soir pour « tous les
   jours », Non pour « seulement quand ça arrive », Matin pour Sommeil.
2. **Deux heures pour tous**, matin 9 h 00 et soir 20 h 30, et **au plus
   deux rappels par jour** au lieu d'un seul à 20 h 30. Pas d'heure libre
   par tracker (trop de notifications possibles).
3. **Le cycle programme les trois prochains rappels dus**, quel que soit
   leur moment, au lieu de trois soirs ; le silence après 3 rappels ignorés
   compte des notifications (*mon choix*).
4. **L'écran de demande** liste les trackers et leur moment, sans
   sélecteur d'heure ; les heures se changent dans Réglages › Rappels.
5. **Où se règle le moment** : à la création (fiche d'un modèle, défauts
   d'un perso), dans les réglages du tracker (la roue, spec des stats) et
   dans Réglages › Rappels. L'interrupteur « Chaque jour » de la légende,
   prévu la veille, n'existe plus.
6. **Limite connue** jusqu'au lot 2 des stats (le filet de sécurité) : un
   tracker « tous les jours » colorié seulement les jours où ça arrive
   reçoit le rappel du soir ; la personne le corrige dans les réglages du
   tracker. La règle des 14 jours sans point (« Relecture », point 1)
   s'applique toujours.

## Passe de confirmation du 2026-11-25

Comparée à `master` (app 1.4.0, backend 1.2.1). Détail :
`docs/CONFIRMATION.md`, points 12 à 16.

1. **La date de création du compte** manque à l'app : ni la session ni le
   bootstrap ne la renvoient. Le bootstrap l'ajoute (côté serveur, avant
   l'app) ; elle sert aussi au délai de la pop-up premium.
2. **Les points du jour.** L'app rouvre le dernier tracker sur sa dernière
   année et ne charge qu'une année à la fois : avant de programmer, le
   cycle s'assure que l'année en cours est chargée, par le chargement à
   part que construit le lot 1 des stats (sans changer l'année affichée).
3. **`lastCellAt`** est la date de la dernière modification d'une case, pas
   le dernier jour colorié ; il ne se met à jour qu'au bootstrap, et
   recolorier une légende le rafraîchit. Cela convient à la règle des
   14 jours ; la fonction de cycle tient compte aussi des points posés sur
   l'appareil depuis le dernier bootstrap.
4. **L'instantané.** Le moment du rappel et le remplissage doivent passer
   par `PageModel.toJson`, sinon un démarrage à froid programme avec des
   valeurs par défaut.
5. **L'ouverture de l'app** (audit, « Trous de mesure », point 4) se
   construit ici : *mon choix*, un événement au plus par jour civil et par
   appareil. La plateforme et la version sur les événements se
   construisent avec le chantier 0 de `docs/FABLE.md`.
6. **Hors ligne**, les rappels se programment, mais un point posé sans
   réseau est annulé (`CellsProvider.setCell`) : limite existante, hors de
   ce chantier.
7. **Outillage** : AGP 8.11.1, Gradle 8.14 et `compileSdk` 36 sont bien
   l'état d'aujourd'hui ; AGP 8.11.1 est le plancher de Flutter 3.47.5, donc
   pas de mise à jour de Flutter avant la montée en AGP 9.
8. **Une seule release** (Charles, 2026-11-25) : les rappels sortent avec
   tout le reste. « Livrer dans la release AGP 9 ou dans la suivante » et
   la « limite connue jusqu'au lot 2 des stats » sont sans objet.
