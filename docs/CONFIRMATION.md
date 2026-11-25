# Passe de confirmation — 2026-11-25

Étape 1 de `docs/FABLE.md` : chaque spec comparée au code avant de
construire. Faite par Fable le 2026-11-25.

**Verdict** : les six specs se construisent sur le code d'aujourd'hui, et
rien ne bloque le chantier 1. Trente-trois points relevés ; chacun est réglé
ici et reporté dans sa spec (section « Passe de confirmation du
2026-11-25 »), ou laissé au plan de son chantier.

## Ce qui a été comparé

- Lu : `docs/FABLE.md`, `docs/ROADMAP.md`, `docs/PRICING.md`, les six specs
  du 2026-11-23 au 2026-11-25, `ANDROID_RELEASE_PLAN.md` §8, la section
  « Trous de mesure » de l'audit.
- Code : `master` (`326655e`, backend 1.2.1, app 1.4.0) et
  `feat/comment-badge` (`8e7aa72`). Les numéros de ligne cités sont ceux de
  master.
- **Pas fait** : les trois pages de maquettes (stats, zoom, astuces) n'ont
  pas été ouvertes ; les rapports de recherche n'ont pas été relus ; aucun
  test lancé, aucune requête en production. Les faits extérieurs des specs
  (règles des stores, CNIL, versions des plugins) n'ont pas été revérifiés.

## Décisions du 2026-11-25

Sept points demandaient une décision. Charles : « fais selon tes
recommandations ». Ce sont donc des choix de Fable (*mon choix*), à
rediscuter si mieux. Trois recommandations étaient écrites quand Charles a
répondu ; les quatre autres ne l'étaient pas et sont marquées « à relire ».

1. **Chemins inconnus du site : 404** (point 4), au lieu de la redirection
   vers `/`.
2. **Mesure des achats : un chantier à part** (point 10), le chantier 0 de
   `docs/FABLE.md`, backend seul. La recommandation visait une sortie avant
   le 1er décembre, jour du changement de prix ; cette date est tombée le
   même jour, avec la décision d'une seule release. D'ici la release, les
   achats aux nouveaux prix se lisent dans RevenueCat, qui garde son propre
   historique.
3. **« 5 jours sur 14 »** (point 23) : au moins 5 dates coloriées parmi les
   14 derniers jours, aujourd'hui compris, tous trackers confondus. C'est la
   seule lecture que l'app sait calculer : les cases ne portent pas leur
   jour de saisie.
4. **Sport et Habitudes** (point 17) : l'ancienne légende à cinq couleurs
   est une forme du modèle à part entière, avec ses propres places.
   **À relire** : dans la nouvelle légende à quatre couleurs, c'est la
   troisième couleur de l'ancienne qui part (`#FFD8A8` pour Sport,
   `#C3FAE8` pour Habitudes). Sport garde ainsi ses deux verts pour
   l'échelle, et des teintes nettement différentes pour Repos et Malade.
5. **À relire — un seul écran par mur** (point 8) : toucher une fonction
   Premium ouvre directement le paywall, avec la raison en titre
   (« Trackers illimités » pour la limite des 3 trackers), une liste courte
   des avantages, puis les cartes. La fenêtre intermédiaire
   (`PremiumGateDialog`) disparaît. Pourquoi : PRICING veut l'annuel
   présélectionné sur le mur des 3 trackers, donc les cartes sur le mur ;
   une étape de moins avant les prix ; un seul écran à refaire et à
   mesurer. Le lien « choisir les trackers gardés » du mur
   `locked_tracker` reste.
6. **À relire — le glissement tourne aussi les années** (point 24) : en
   vue Année, un doigt qui part de côté sur la grille passe à l'année
   suivante ou précédente, avec les mêmes seuils qu'en vue Mois et Semaine.
   Pourquoi : le même geste dans les trois vues ; et aujourd'hui, barre
   pliée, on ne peut pas changer d'année du tout.
7. **À relire — la place du zoom et des astuces** : le lot 1 des astuces
   juste après les rappels (les deux servent la première semaine, le
   goulot mesuré par l'audit), avant les lots 2 et 3 des stats ; le zoom
   après la pop-up premium (il est gratuit, et les stats sont la porte
   d'entrée vers Premium), avec le lot 2 des astuces. L'ordre complet est
   dans la section suivante.

## Une seule release (Charles, 2026-11-25)

Après la passe, Charles a décidé : tous les chantiers se construisent, puis
sortent ensemble, sans release intermédiaire. Une release du backend, puis
une version de l'app.

**L'ordre de construction** (*mon choix*) : 0, 1 et le registre, qui sont
du backend ; 3, l'outillage Android, tôt ; puis 2, 5 lot 1, 4, 8 lot 1,
5 lots 2 et 3, 6, 7, 8 lot 2. L'outillage passe avant le paywall pour que
RevenueCat, la pub et la connexion Google soient testés sur le nouvel
outillage pendant tout le reste de la construction : c'est ce qui remplace
la « release dédiée » de `ANDROID_RELEASE_PLAN.md` §8.

**Ce qui tombe** :
- la date du chantier 0 (avant le 1er décembre) et le calendrier « avant le
  Nouvel An / en janvier » : le pic du Nouvel An se passera avec l'app
  1.4.0, sauf si tout est prêt avant ;
- la release Android à part ;
- ce que le lot 1 des stats devait cacher en sortant seul (ligne « Rappel »,
  encadré « Ses stats », estimation) et la limite connue entre ses lots 1
  et 2 ;
- les formes d'attente des astuces (l'astuce 8 sur Éditer, la phrase
  « avant le zoom » de l'astuce 4).

**Ce qui reste vrai** :
- le backend se déploie avant l'app, et doit rester compatible avec les
  apps 1.4.0 encore installées ;
- un plan par chantier avant le code, et des tests à chaque chantier ;
- `master` avance sans release ; un correctif urgent de la production part
  du tag.

**À surveiller** : le jour de la mise à jour, un compte existant croise
beaucoup de nouveautés d'un coup (encart des nouveautés, écran des rappels,
puis « stats prêtes », astuces). Les règles de priorité des specs les
espacent déjà ; à tester ensemble sur un compte ancien avant de sortir. Les
notes des stores tiennent en 500 caractères par langue : il faudra choisir
quoi annoncer.

## Les points, par chantier

« Réglé » dit ce qui a été écrit dans la spec ; « au plan » ce qui se
décide dans le plan du chantier.

### Branches

1. **À savoir.** `docs/conversion-retention` est partie de master avant ses
   trois derniers commits : `backend/src/lib/storePlatform.ts` n'y existe
   pas. Le code qu'on y voit n'est pas celui de la production. Les deux
   fusions (cette branche et `feat/comment-badge` vers master) passent sans
   conflit (`git merge-tree`, rien n'a été modifié). Réglé : FABLE le dit ;
   fusionner avant de coder.
2. **Contradiction.** FABLE disait « docs seulement » ; la branche modifie
   aussi quatre scripts de lecture `backend/scripts/prod-*.sql`, deux
   scripts marketing et `ANDROID_RELEASE_PLAN.md`. Sans risque. Réglé :
   FABLE corrigé.
3. **Trou.** `feat/comment-badge` n'existe que sur la machine de Charles
   (jamais poussée), alors que le zoom en dépend. Réglé : FABLE demande de
   la pousser.

### 1. Compteur de visites

4. **Trou.** `backend/src/index.ts:203` redirige toute URL inconnue vers
   `/`. Les scanners (`/wp-login.php`, `/.env`) qui suivent la redirection
   deviendraient des visites, et ceux qui se présentent comme un navigateur
   des personnes. Réglé : 404 (décision 1).
5. **Trou.** La mise à jour mensuelle de DB-IP n'a nulle part où écrire :
   l'image tourne sous l'utilisateur `node`, sans volume ni tâche planifiée
   (`backend/Dockerfile:30`, `ops/docker-compose.prod.yml`). Réglé : le
   fichier est téléchargé au démarrage du serveur et gardé en mémoire, puis
   rafraîchi par une minuterie du processus, comme la purge des jetons ;
   « pays inconnu » tant qu'il manque.
6. **Contradiction mineure.** La relecture disait que `/go/*` ne reçoit
   jamais de `Referer` ; avec la `Referrer-Policy` qu'elle propose, il
   reçoit l'adresse de la landing, `utm_*` compris. Réglé : ne pas la
   garder, et ne jamais compter le site lui-même comme site d'origine (les
   liens de langue rechargent `/`).
7. **À savoir.** Les tests smoke cherchent `apps.apple.com` et
   `referrer=` dans la page (`backend/scripts/smoke.ts`) : à réécrire avec
   `/go/*`, dans le même lot. Le `ct` Apple : par source (la spec), pas par
   source et langue (ROADMAP §3). Réglé.

### 2. Paywall, registre RGPD

8. **Trou.** Chaque mur a deux étapes : `PremiumGateDialog`, qui envoie
   `paywall.<mur>` (`premium_gate_dialog.dart:29`), puis
   `CustomPaywallDialog`. PRICING ne disait pas ce que devient la première,
   ni quel écran compte comme « paywall affiché ». Réglé : un seul écran
   (décision 5).
9. **Trou.** L'essai s'affiche même à quelqu'un qui l'a déjà utilisé sur
   iOS : `custom_paywall_dialog.dart:422` lit `introductoryPrice`, qui
   décrit le produit, pas le droit de la personne. « 7 jours gratuits »
   écrit dans la carte serait faux pour elle. Réglé dans PRICING : demander
   l'éligibilité à RevenueCat avant d'afficher l'essai.
10. **Trou.** Trois trous de mesure de l'audit n'appartenaient à aucun
    chantier : la table brute du webhook RevenueCat, la plateforme et la
    version sur `events`, l'ouverture de l'app. Réglé : les deux premiers
    dans le chantier 0 (décision 2), l'ouverture avec les rappels. Le
    fuseau horaire attend la spec de la série.
11. **Trou.** Rien ne purge la table `events`, alors que PRICING promet
    13 mois de conservation. Réglé : la purge entre dans le lot du registre.
- **Au plan.** `PurchaseService.purchasePackage` ne renvoie qu'un booléen
  (`purchase_service.dart:83`) : annulation et erreur ne se distinguent
  pas, il faut un résultat à trois issues pour les événements. Le prix
  « par mois » de l'annuel se calcule (prix ÷ 12, devise du store) ; le
  projet n'a pas le paquet `intl`.

### 3. Outillage Android

12. **Spec dépassée.** « Dart ≥ 3.12 » est acquis : le projet tourne en
    Flutter 3.47.5 et Dart 3.13.4 (machine de Charles, CI,
    `pubspec.lock`). Le reste est exact : AGP 8.11.1, Gradle 8.14, Kotlin
    2.2.20, `compileSdk` 36 et `minSdk` 24 fixés par Flutter. Réglé.
13. **À savoir.** AGP 8.11.1 est le plancher exact de Flutter 3.47.5
    (`DependencyVersionChecker`, avertissement sous 9.0.1). Une version
    plus récente de Flutter risque de refuser de construire l'app Android.
    Réglé : règle ajoutée à FABLE.

### 4. Rappels

14. **Trou.** L'app ne connaît pas la date de création du compte : ni
    `profileOf` (`backend/src/routes/auth.ts:25`) ni le bootstrap ne la
    renvoient. Le cycle (« jamais le jour de l'inscription ») et la pop-up
    (J+3) en ont besoin. Réglé : un champ du bootstrap, côté serveur avant
    l'app.
15. **Trou.** Les points du jour peuvent ne pas être chargés : l'app
    rouvre le dernier tracker sur sa dernière année (`main.dart:212`) et ne
    charge qu'une année à la fois. Réglé : le cycle s'assure que l'année en
    cours est chargée (voir le point 33).
16. **À savoir.** `lastCellAt` est la dernière modification d'une case,
    pas le dernier jour colorié ; recolorier une légende le remet à jour,
    et il ne bouge qu'au bootstrap. Cela convient à la règle des 14 jours.
    Au plan : tenir compte aussi des points posés sur l'appareil depuis.
- **Au plan.** Les nouveaux champs du tracker doivent passer par
  l'instantané (`PageModel.toJson`), sinon un démarrage à froid programme
  les rappels avec des valeurs par défaut. Un point posé hors ligne est
  annulé (`CellsProvider.setCell` revient en arrière quand le serveur ne
  répond pas) : limite existante.

### 5. Stats

17. **Contradiction.** Sport et Habitudes ont cinq couleurs aujourd'hui
    (`first_tracker_templates.dart:39-41`), quatre dans la spec ; la
    correspondance « Presque → Un peu » laissait l'ancien « Un peu » sans
    place, et rien ne disait quelle couleur part. Réglé (décision 4).
18. **Contradiction.** La reconnaissance « par une fonction appelée par
    une migration » ne tient pas : les migrations sont des fichiers SQL
    lancés par `drizzle-kit migrate` (`deploy-prod.sh:168`). Réglé : un
    rattrapage que le serveur lance à son démarrage, sans effet la seconde
    fois.
19. **Imprécision.** Le « + » de l'app 1.4.0 n'envoie qu'un titre
    (`pages_provider.dart:71`) ; seul son parcours du premier tracker
    arrive avec une légende à reconnaître. Réglé.
20. **Trou.** Le lot 1 a besoin de l'année précédente, que la spec ne
    chargeait qu'au lot 2 : il sort en janvier, où « depuis X j » serait
    vide et où une Migraine parlerait en « jours ». Réglé : le chargement
    à part arrive au lot 1.
21. **Trou.** L'éditeur accepte bien deux couleurs identiques
    (`legend_editor_dialog.dart:353`) ; la spec l'interdit pour la suite
    sans rien dire des trackers qui en ont déjà. Réglé : elles comptent
    comme une seule couleur, celle de la première légende, et l'éditeur le
    signale ; à compter en production avant le lot 1.
22. **Confirmé.** Une app 1.4.0 ne peut pas remettre les nouveaux champs à
    zéro : les champs inconnus sont ignorés (zod), les mises à jour sont
    partielles, les légendes sont modifiées en place. Le gratuit tombe
    bien sur le mur `stats` aujourd'hui (`tracker_screen.dart:210`).

### 6. Pop-up premium

23. **Ambiguïté.** « 5 jours sur 14 » avait deux lectures. Réglé
    (décision 3).
- **Au plan.** Il n'existe qu'un paywall : « paywall des stats » et
  « paywall de l'export » sont ce même écran avec un autre titre, et pour
  les stats les cartes d'exemple du lot 2.

### 7. Zoom

24. **Contradiction.** En vue Année, le glissement sur la grille restait
    « comme aujourd'hui », or il n'existe pas : l'année ne change que par
    la ligne de la barre (`tracker_screen.dart:883`). Réglé (décision 6).
25. **Trou.** Chaque point a son propre toucher (`tracker_grid.dart:166`,
    372 cibles). Deux doigts posés puis levés dans la zone morte
    colorieraient deux cases. Réglé : un second doigt annule les touchers
    en cours.
26. **Contradiction.** La spec voulait un fondu de 160 ms sous « Réduire
    les animations » ; la règle de l'app est zéro
    (`lib/theme/motion.dart:47`). Réglé : zéro, et les nouvelles durées
    vivent dans `motion.dart`.
27. **Bug existant.** La navigation de l'éditeur de jour passe par des
    jours qui n'existent pas (31 février, 31 avril) et boucle de janvier à
    décembre dans la même année (`cell_editor_dialog.dart:130`) ; le
    serveur refuse la case et l'app l'annule. Réglé : les jours invalides
    se corrigent tôt, avec le chantier du paywall ; le passage d'une année
    à l'autre avec le zoom, qui étend déjà l'éditeur.
28. **Trou.** Tourner la page de décembre à janvier montrerait une page
    vide tant que l'autre année n'est pas chargée. Réglé : l'année voisine
    se charge d'avance (point 33).
29. **À vérifier.** La barre fait 90 px en portrait et est déjà pleine
    (chevron, année, légende, Éditer, Aujourd'hui, trois stats).
    « ANNÉE · MOIS · SEMAINE » n'y tient pas sur une ligne, « A · M · S »
    non plus dans 32 px. Au plan : sélecteur empilé, à essayer sur le plus
    petit téléphone.
- **À savoir.** Les lettres des mois ne se touchent pas aujourd'hui (toute
  la couche des libellés est sous `IgnorePointer`) et ce sont douze
  initiales anglaises ; `SwipeNav` et `BackSwipe` écoutent les doigts sans
  passer par l'arbitrage des gestes, donc le glissement de la barre doit
  les écarter explicitement. Les autres faits cités par la spec sont
  exacts.

### 8. Astuces

30. **Trou.** `okText` n'existe pas dans le thème. Réglé : à tirer de
    chaque thème, comme `accentSoft` et `weekend`.
31. **Imprécision.** « Cinq jours coloriés dans le compte » s'appuie sur
    `cells_total`, qui compte des cases : trois trackers remplis deux
    jours font six. Réglé : la spec dit « cases ».
32. **Lié au 27.** L'astuce `date_swipe` montre le geste de l'éditeur de
    jour : son correctif se construit avant elle.

### Transversal

33. Les points 15, 20 et 28 demandent la même fonction : charger une année
    sans en faire l'année active (`SyncService.ensureYear` change l'année
    active, `sync_service.dart:103`). À construire une fois, au lot 1 des
    stats, le premier chantier qui en a besoin.

## Ce que le serveur doit livrer avant l'app

Les ajouts côté serveur sont dispersés dans les specs ; les voici réunis.
Ils partent dans une seule release du backend, déployée avant la version de
l'app.

| Champ ou table | Pour | Chantier |
|---|---|---|
| table brute du webhook, `events.platform`, `events.app_version` | mesure des achats | 0 |
| compteur de visites, `/go/*`, 404 | site | 1 |
| purge des événements à 13 mois | registre | registre |
| colonnes des trackers et des légendes, reconnaissance | stats | 5, lot 1 |
| date de création du compte | rappels, pop-up | 4 |
| `cells_total`, `has_comment` | astuces | 8, lot 1 |
| bloc `upsell` et historique des pop-ups | pop-up | 6 |
