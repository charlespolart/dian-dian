# Rappels du soir — design (2026-11-23)

Point 4 de `docs/ROADMAP.md` (engagement, volet notifications). Brainstormé
du 2026-11-22 au 2026-11-23, appuyé sur la recherche
`docs/research/reports/Notifications de rappel et fidélisation.md` (notes
dans `docs/research/notes/Notifications de rappel et fidélisation/`) et sur
l'audit `docs/research/audit-2026-11-22.md`. Décisions validées par Charles le
2026-11-23 (« selon les recommandations »). Phase de documentation : à
confirmer puis construire plus tard ; aucun code n'est écrit avec ce spec.

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
- Au plus un rappel par jour, le soir, seulement s'il reste un tracker
  quotidien vide.
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
- plus d'une notification par jour, ou une par tracker ;
- un rappel pour un tracker occasionnel ;
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
  (`desugar_jdk_libs` 2.1.4), Java 17, minSdk 24 (vérifier
  `flutter.minSdkVersion`), Flutter ≥ 3.44 et **Dart ≥ 3.12** (le
  `pubspec.yaml` dit `^3.11.4`). Pour `zonedSchedule` : `timezone` 0.11.2
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

### Trackers quotidiens ou occasionnels (option C, choisie le 2026-11-22)

- Chaque tracker est **quotidien** ou **occasionnel**. Un tracker
  occasionnel (les règles, par exemple) ne déclenche jamais de rappel et
  n'y est jamais nommé. Quelqu'un qui n'a que des trackers occasionnels ne
  reçoit aucun rappel quotidien.
- Le choix se fait **à la création** : `_CreateTrackerDialog`
  (`flutter_app/lib/screens/page_list_screen.dart`) n'a aujourd'hui qu'un
  champ titre et Annuler / Créer ; il gagne un choix à deux options, « Tous
  les jours » (présélectionné) / « De temps en temps ». *Mon choix* : la
  présélection sur « Tous les jours », la majorité des trackers l'étant.
- **Modifiable ensuite** (depuis le tracker et depuis la section Rappels des
  réglages). L'endroit exact dans le tracker est laissé au constructeur.
- *Mon choix* : le parcours d'accueil (`first_tracker_screen.dart`,
  modèles humeur, sommeil, sport, lecture, habitudes, autre) crée des
  trackers quotidiens sans poser la question, pour ne pas ajouter de
  friction au premier geste. Les trackers existants sont quotidiens par
  défaut ; la section Rappels les liste pour corriger.
- **Stockage synchronisé** : c'est une propriété du tracker, donc côté
  serveur. *Mon choix* : colonne `pages.cadence` (`'daily' | 'occasional'`,
  défaut `'daily'`, migration), renvoyée par le bootstrap et les routes
  pages, acceptée par `POST /api/pages` et la mise à jour d'une page ;
  champ `cadence` dans `PageModel`. Le nom exact est laissé au
  constructeur.

### Le rappel

1. **Une seule notification par jour au maximum**, groupée.
2. **Seulement si au moins un tracker quotidien est vide** pour la date du
   jour au moment où l'app programme (voir le cycle). Jamais quand tout est
   rempli : les plus réguliers reçoivent automatiquement moins de messages
   (leçon de Pinterest et Twitter : envoyer moins aux non-répondants ne coûte
   rien).
3. **Heure par défaut 20 h 30**, modifiable dans l'écran de demande et dans
   les réglages, présentée comme un moment (« quand la journée se pose »).
   Pas d'heure magique dans la recherche ; la régularité compte ; Android
   peut retarder d'une heure, et les Focus de sommeil se placent plus tard.
4. **Premier rappel le soir de J1**, pas celui de J0 : le soir de
   l'inscription, la personne vient d'utiliser l'app, et c'est après J1
   qu'on perd la majorité des gens. C'est le rappel le plus important.
5. **Week-end compris.**
6. **Silence après 3 rappels consécutifs sans aucune ouverture de l'app** ;
   toute ouverture remet le compteur à zéro. Le critère est l'ouverture,
   pas la saisie : quelqu'un qui ouvre tous les trois ou quatre jours garde
   son rappel.
7. **Un dernier message, 10 jours après la dernière ouverture**, avec un
   texte jamais vu : il annonce la pause avec douceur et rappelle que les
   jours passés se colorient encore. **Au plus un tous les 60 jours.**
   Ensuite plus rien jusqu'au retour.
8. **Un tap** ouvre la journée en cours. *Mon choix* : s'il n'y a qu'un
   tracker quotidien vide, l'ouvrir sur aujourd'hui ; sinon, la liste.
9. **Jamais de promotion**, jamais de « série en danger », jamais de
   « succès débloqué ». Le rappel peut mentionner un fait positif s'il est
   vrai (« 12 jours coloriés ce mois-ci »).

### Le cycle, entièrement local

À chaque ouverture (retour au premier plan compris), après chaque point
posé ou effacé, et après une synchro qui change les points du jour, l'app :

1. annule les notifications de rappel en attente ;
2. si les rappels sont activés et autorisés :
   - **R1** : ce soir à l'heure choisie si l'heure n'est pas passée et
     qu'un tracker quotidien est vide aujourd'hui, sinon demain ; jamais le
     soir du jour de création du compte ;
   - **R2, R3** : les deux soirs suivants (textes calculés maintenant :
     tous les trackers quotidiens sont vides ces jours-là) ;
   - **dernier message** : dernière ouverture + 10 jours, à l'heure
     choisie, si aucun dernier message n'a été envoyé depuis 60 jours.

Si la personne ne revient pas, R1, R2 et R3 partent, puis le téléphone se
tait de lui-même, le dernier message arrive, puis plus rien. Toute
ouverture relance le cycle. L'app n'a jamais besoin de savoir si une
notification a été vue. Pour la règle des 60 jours : noter localement la
date du dernier message programmé, et le considérer comme envoyé quand
l'app s'ouvre après cette date.

*Mon choix* : écrire ce calcul comme une fonction pure (maintenant, date de
création du compte, dernière ouverture, trackers quotidiens et points du
jour, réglages, date du dernier « dernier message ») → liste de
notifications à programmer, testée unitairement ; le plugin ne fait que
programmer la liste.

### Demander l'autorisation

- **Moment** : juste après le premier point posé (fin du parcours
  d'accueil, ou premier point d'un compte sans rappels). Apple décrit
  exactement ce cas (« après que la personne a programmé une première
  tâche ») ; attendre le 3e lancement reviendrait à ne jamais demander à la
  plupart des gens, qui partent après J1.
- **Écran de l'app d'abord**, dans le style pixel : un petit rappel le soir
  pour colorier sa journée, sélecteur d'heure réglé sur 20 h 30, boutons
  « Oui, à cette heure-là » et « Pas maintenant ». Le bouton ne s'appelle
  pas « Autoriser » ; aucune récompense promise (règle 5.1.2(i)). **Seul le
  oui déclenche le dialogue système** : refuser l'écran de l'app ne
  consomme pas le dialogue unique d'iOS ni l'un des deux refus d'Android.
  Donner une raison rend l'acceptation 12 % plus probable (Tan et al.) ;
  base réaliste : environ un utilisateur sur deux accepte, davantage en
  contexte.
- **Après « Pas maintenant »** : un seul nouvel écran, au premier point
  d'une session ultérieure, puis plus jamais de fenêtre. L'entrée Rappels
  reste dans les réglages.
- **Android** : `POST_NOTIFICATIONS` seulement après le oui ; après un
  premier refus, le oui suivant passe par un écran d'explication avant le
  second et dernier dialogue.
- **Utilisateurs existants** : une carte « Nouveau : un rappel le soir »,
  une seule fois, après leur prochain point, jamais au lancement.
- **Priorité** : cet écran passe avant la pop-up premium
  (`2026-11-23-premium-popup-design.md`) ; jamais deux fenêtres à la suite
  après un même point.

### Réglages : section « Rappels »

Dans `settings_screen.dart`, à côté de Sons et Vibrations
(`SoundsSettings`), même titre de section et même tuile :

- interrupteur des rappels ;
- heure ;
- liste des trackers avec leur cadence (quotidien / occasionnel) ;
- « Nommer mes trackers dans le rappel ».

Si le système a refusé, la section le dit en une ligne et propose d'ouvrir
les réglages de notification du téléphone, **seulement sur une action de
l'utilisateur** (`openNotificationSettingsURLString` à partir d'iOS 16,
réglages du canal sur Android). L'app vérifie l'autorisation à chaque retour
au premier plan. *Mon choix* : interrupteur, heure et « nommer » sont
**locaux à l'appareil** (chaque appareil a sa propre autorisation) ; seule
la cadence est synchronisée.

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
| Deux trackers vides | « Humeur et Sommeil attendent leur couleur du jour. » |
| Plus de deux | « Humeur, Lecture + 2 : votre grille garde une place pour ce soir. » |
| Routine | « Avant de dormir, un point pour Humeur ? » |
| Fait positif, s'il est vrai | « 12 jours coloriés ce mois-ci. Humeur attend celui d'aujourd'hui. » |
| Noms masqués / écran verrouillé | « Quelques cases attendent leur couleur du jour. » |
| Dernier message (J+10) | « Votre grille vous attend, sans pression. Les rappels sont en pause ; ils reprendront à votre prochain point. Les jours passés se colorient aussi. » |

### Vie privée

- Réglage global « Nommer mes trackers dans le rappel ». **Décidé** :
  activé par défaut (nommer aide), avec une version générique sur l'écran
  verrouillé. Vérifié le 2026-11-23 : le plugin ne donne sur Android que la
  visibilité privée (pas de version publique) et sur iOS aucun texte de
  remplacement, alors que les deux API natives existent (`setPublicVersion`,
  `hiddenPreviewsBodyPlaceholder`). *Mon choix* : s'en tenir au masquage du
  système (Android `NotificationVisibility.private`, aperçus masqués d'iOS),
  qui cache déjà le texte sur l'écran verrouillé quand le téléphone le
  demande ; un texte générique maison demanderait du code natif, laissé au
  constructeur s'il est simple.
- Exclusion du nom tracker par tracker (suggérée par la recherche) : laissée
  en option, aucun modèle actuel n'étant sensible.

**À trancher (relecture du 2026-11-23)** : le masquage du système ne cache
les noms que si la personne a déjà choisi de masquer le contenu des
notifications. Par défaut, Android montre tout sur l'écran verrouillé. Voir
« Relecture du 2026-11-23 ».

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
| `reminder.tap` | ouverture par un rappel |
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
  « Rappel du soir », importance par défaut, catégorie rappel), le
  récepteur de redémarrage.
- L'interface du choix de cadence dans `_CreateTrackerDialog` et l'endroit
  où la modifier dans le tracker.
- L'écriture finale des textes dans les quatre langues. Le chinois est
  écrit directement en chinois, en phrases courtes ; relu par un natif
  avant la sortie si Charles en a un sous la main, sinon tel quel, comme les
  autres textes chinois de l'app.
- Les tests : la fonction de cycle en unitaire ; le reste à la main sur un
  iPhone et un Android (dont Android 13+ et un redémarrage).

## Questions closes le 2026-11-23

1. **Ordre de sortie** : montée en AGP 9 d'abord, plugin le plus récent ;
   pas de version ancienne compatible AGP 8.
2. « Nommer mes trackers » **activé par défaut**, avec la version générique
   sur l'écran verrouillé.
3. Rappel de fin d'essai : **abandonné**, sur Android comme sur iOS.
4. Textes chinois : écrits directement en chinois ; relecture native si
   possible (voir « Laissé au constructeur »).

## Relecture du 2026-11-23

Une relecture « comme un constructeur » a trouvé trois trous.

1. **Trackers abandonnés.** Tous les trackers existants deviennent
   quotidiens ; un tracker qu'on ne remplit plus déclencherait le rappel
   chaque soir, même chez les plus réguliers (54 % des trackers gratuits
   n'ont jamais été remplis ; les payants ont 6,5 trackers en moyenne).
   *Mon choix* : un tracker quotidien sans aucun point depuis 14 jours ne
   déclenche pas le rappel et n'y est pas nommé (`lastCellAt` du
   `PageModel`) ; il redevient actif à son prochain point. À tester dans la
   fonction de cycle.
2. **Noms sur l'écran verrouillé : à trancher par Charles.** Le masquage du
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
