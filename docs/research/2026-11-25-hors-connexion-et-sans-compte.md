# Étude : hors connexion et usage sans compte

Ouverte par Charles le 2026-11-25, pendant la construction du chantier 1.
Rien n'est décidé ; ce document note les questions, ce qui est lancé et
dans quel ordre on y répond. L'implémentation en cours n'est pas arrêtée.

## Les questions de Charles

1. **Le comportement actuel.** Un utilisateur déjà connecté qui n'a plus
   internet peut-il encore utiliser l'app, ou voit-il un message d'erreur ?
2. **Remplir hors connexion.** Serait-il bien de laisser l'utilisateur
   continuer à remplir ses trackers sans réseau, puis de resynchroniser au
   retour de la connexion ? Bonne idée, ou trop de complexité et de bugs
   possibles — par exemple s'il a aussi modifié depuis un autre téléphone
   entre-temps ?
3. **Sa règle de conflit, à évaluer.** Quand une modification locale attend
   d'être synchronisée et que l'état distant a changé : on garde l'état
   distant, la modification locale n'est pas prise en compte.
4. **Sans compte.** Serait-il bien de laisser quelqu'un qui télécharge l'app
   l'utiliser tout de suite, sans créer de compte — pour ne pas perdre ceux
   qui arrivent sur une page de connexion et ne testent même pas l'app, par
   flemme ou parce qu'ils ne veulent pas laisser leur e-mail ? Le compte
   viendrait quand ils veulent passer Premium ou en créer un, et les données
   seraient alors synchronisées vers ce compte.
5. **La fusion.** Si la personne a déjà créé plusieurs trackers et se
   connecte à un compte qui en a aussi : on fusionne, on supprime le local,
   on demande ? À traiter sans perte de données.
6. **La question d'avant toutes les autres.** Est-ce bien de laisser
   utiliser l'app sans internet et sans compte ? Éviter la friction du
   compte au départ est-il bon, ou contre-productif parce que ces
   utilisateurs ne passeront pas Premium ? L'avantage du compte dès le
   début : passer Premium ensuite est plus simple. « Ça, on ne va pas le
   deviner » : chercher des études.

## Comment on y répond

Consigne de Charles : les recherches approfondies sont faites par Opus, qui
écrit les comptes rendus ; Fable reprend ensuite la main pour les analyser.

| Quoi | Qui | Où | État |
|---|---|---|---|
| Comportement actuel de l'app sans réseau, lu dans le code (question 1) | agent de lecture | section « Le comportement actuel » ci-dessous | fait le 2026-11-25 |
| Recherche : attentes des utilisateurs, ce que font les apps comparables, options techniques, règles de conflit (questions 2 et 3) | Opus | `reports/Mode hors connexion et synchronisation.md`, `notes/Mode hors connexion et synchronisation/` | lancé le 2026-11-25 |
| Recherche : mur d'inscription ou compte différé, effet sur l'activation et sur le Premium, règles des stores, achats sans compte chez RevenueCat, fusion des données (questions 4 à 6) | Opus | `reports/Utiliser l'app sans compte.md`, `notes/Utiliser l'app sans compte/` | lancé le 2026-11-25 |
| Analyse des comptes rendus, réponse aux six questions, recommandation avec ses coûts | Fable | à écrire ici, section « Analyse » | après le chantier 1 |
| Si Charles décide d'y aller : spec, puis place dans l'ordre de construction de `docs/FABLE.md` | Fable, avec Charles | `docs/superpowers/specs/` | — |

## Le comportement actuel (question 1), lu dans le code le 2026-11-25

Lecture faite par un agent sur `flutter_app/lib` et `backend/src` ; les
points marqués *déduit* sont un raisonnement à partir du code, pas un essai
sur téléphone.

**En une phrase** : un utilisateur déjà connecté peut ouvrir l'app sans
réseau et voir ses trackers, mais rien de ce qu'il y fait n'est gardé, et
rien ne le lui dit.

Ce qu'il voit :

- L'app s'ouvre sans écran de connexion : la session est gardée quand le
  rafraîchissement du jeton échoue faute de réseau
  (`providers/auth_provider.dart:85-116`, délai de 20 s dans
  `services/api_service.dart:44`). Seul un 401 ou un 403 déconnecte.
- Les trackers affichés viennent d'une copie sur le téléphone
  (`services/snapshot_store.dart`, fichier `snapshot_v1.json`) : les
  trackers, leurs légendes, et les points d'**une seule année**, la dernière
  regardée. Les autres années apparaissent vides. Cette copie est écrite
  après chaque chargement réussi et quand l'app passe en arrière-plan ; son
  commentaire dit « a first-paint accelerator, never a source of truth ».
- Les stats d'un tracker et l'export en image marchent (calculés sur le
  téléphone) ; les stats « depuis toujours » sont vides.
- Aucun indicateur « hors connexion » n'existe à l'écran.

Ce qui se passe quand il agit :

| Geste | Résultat sans réseau |
|---|---|
| Colorier ou effacer un point | Le point change, puis revient à son état d'avant, sans message (`providers/cells_provider.dart:183-266`) |
| Modifier un commentaire | La fenêtre ouverte montre le nouveau texte, qui a disparu à la réouverture (*déduit*, `widgets/cell_editor_dialog.dart:333-341`) |
| Créer un tracker | Une attente, puis la fenêtre se ferme : rien n'est créé (`providers/pages_provider.dart:71-98`) |
| Renommer, réordonner, supprimer un tracker | Rien, ou l'ancien état revient (`providers/pages_provider.dart:182-325`) |
| Créer, renommer, supprimer une légende | Rien ; le libellé tapé est effacé (`providers/legends_provider.dart:146-194`) |
| Thème, langue, curseur | Appliqués sur le téléphone ; l'envoi au serveur n'est pas retenté, et le prochain lancement en ligne remet l'ancienne valeur du serveur (*déduit*) |

Il n'y a aucune file d'attente : tout ce qui est fait sans réseau est perdu.
Le seul message d'erreur réseau de l'app est dans le parcours du premier
tracker (« Connexion impossible, réessayez »).

Au retour du réseau, l'app recharge l'année affichée depuis le serveur, qui
gagne toujours (`services/sync_service.dart:196-229`). Si l'utilisateur est
resté plus de 7 jours sans se connecter, son jeton a expiré : il est
déconnecté et doit se reconnecter (`backend/src/routes/auth.ts:42`) ; ses
données sont toujours sur le serveur.

Sans compte : rien n'est utilisable avant de s'inscrire ou de se connecter
(`main.dart:482-488`). Inscription par e-mail et mot de passe, Apple (iOS)
ou Google. Aucune notion d'invité dans le code.

### Ce que cela demanderait de changer

**Pour remplir hors connexion** :

- Les écritures des points, des trackers et des légendes s'annulent ou
  attendent le serveur : il faut les garder dans une file sur le téléphone.
- La copie locale ne garde qu'une année et aucune modification en attente.
- Les trackers et les légendes reçoivent leur identifiant du serveur : hors
  connexion, c'est le téléphone qui doit le créer (seul le premier tracker
  le fait aujourd'hui, avec un `clientId`).
- Le serveur n'a pas de quoi détecter un conflit : pas de version ni de
  `updated_at` sur les trackers et les légendes, aucune trace d'un point
  supprimé, et la dernière écriture arrivée gagne. Rejouer une création de
  légende ou de tracker en fait un double.
- Le rechargement remplace tout par la version du serveur, et la
  déconnexion efface la copie locale, donc aussi ce qui attendrait d'être
  envoyé.
- La limite gratuite est vérifiée à l'arrivée de l'écriture : une écriture
  en attente peut être refusée plus tard.
- Rien ne dit à l'utilisateur qu'il est hors connexion ni ce qui attend.

**Pour un usage sans compte** :

- L'app ne laisse passer que les écrans de connexion quand il n'y a pas de
  compte, et toute la session est attachée à un identifiant de compte.
- Toutes les routes de données du serveur exigent un compte, et un compte
  exige un e-mail. Il n'existe aucune route pour importer ou fusionner des
  données.
- Les achats : RevenueCat démarre déjà en anonyme, mais le serveur ne
  rattache un achat anonyme à personne.
- La limite de trois trackers est vérifiée sur le téléphone **et** sur le
  serveur ; à la fusion, un compte gratuit qui dépasserait trois trackers
  serait refusé ou verrouillé.
- Les événements produit (`paywall.*`) exigent un compte.
- Le parcours du premier tracker dépend d'une réponse du serveur.

## Ce qu'on sait déjà (avant la recherche)

- Aucune mesure n'existe avant l'inscription : on ne sait pas combien de
  personnes installent l'app et s'arrêtent à l'écran de connexion. Les
  stores donnent les téléchargements, le serveur les comptes créés ; l'écart
  entre les deux est la seule estimation possible aujourd'hui.
- Le serveur sait qui est Premium par le webhook RevenueCat, à partir de
  l'identifiant du compte. Un achat fait sans compte arrive sous un
  identifiant anonyme, que le serveur ne rattache à personne : c'est un des
  points laissés ouverts par le chantier 0 (`docs/PRICING.md`, « Trouvé
  pendant le chantier 0 »). Un mode sans compte en fait un cas normal.
- Hors connexion existe déjà dans les specs comme une limite connue : la
  spec de la refonte de synchronisation d'octobre range la « file de
  modifications hors ligne » parmi ses non-objectifs
  (`docs/superpowers/specs/2026-10-14-perf-sync-architecture-design.md:11`),
  et la spec des rappels note qu'« un point posé sans réseau est annulé »
  (`2026-11-23-reminders-design.md:476`).

## Analyse (Fable, 2026-11-25)

Lue à partir des deux comptes rendus d'Opus
(`reports/Mode hors connexion et synchronisation.md`,
`reports/Utiliser l'app sans compte.md`), de la lecture du code ci-dessus et
d'un relevé de production fait le même jour. Ce qui suit est une
recommandation : rien n'est décidé.

### Ce que les recherches établissent, et ce qu'elles n'établissent pas

- **Personne n'a mesuré ce que coûte un compte obligatoire** dans une app à
  abonnement, ni ce que rapporte le hors-connexion pour une app de saisie
  quotidienne. Les pourcentages qui circulent (« 86 % », « +20 % de
  rétention ») viennent de sondages ou de vendeurs. On connaît le sens des
  effets, pas leur taille.
- Les deux seules mesures de terrain sur le compte vont dans le même sens :
  une app de prise de notes dit avoir perdu environ 10 % de ses nouveaux
  utilisateurs avec la connexion en premier écran ; Duolingo a gagné environ
  20 % d'utilisateurs actifs en **reculant** l'inscription de quelques
  écrans, tout en gardant un compte obligatoire ensuite.
- **Le compte ne facilite pas l'achat.** L'achat passe par l'identifiant
  Apple ou le compte Google. Le compte sert après : Premium sur un autre
  appareil ou l'autre plateforme, serveur qui sait qui a payé, retour après
  une réinstallation.
- Onze apps comparables sur quatorze s'ouvrent sans compte et présentent le
  compte comme une sauvegarde. Apple demande de laisser utiliser une app
  sans connexion quand elle n'a pas de « fonctions importantes liées au
  compte » (règle 5.1.1(v)) ; l'app est passée en revue avec son mur
  jusqu'ici, ce qui est une tolérance, pas une garantie.
- Côté hors connexion : les plaintes « il faut Internet » sont rares et
  calmes ; les avis en colère portent sur des **saisies perdues**. Or c'est
  ce que fait l'app aujourd'hui, en silence.
- Les équipes qui ont ajouté le hors-connexion après coup disent que le
  difficile n'est pas le conflit mais l'acheminement : faire passer chaque
  changement une fois, dans l'ordre, et savoir quand abandonner.

### Nos chiffres (production, lecture seule, 2026-11-25)

179 comptes créés en 16 semaines, dont 89 du 2 au 25 novembre (18 à 42 par
semaine récemment). 60 % colorient un premier point dans la journée ; 36 %
n'en colorient jamais (22 à 31 % sur les dernières semaines).

Il manque l'autre moitié : **combien de personnes installent l'app**. Les
« premiers téléchargements » d'App Store Connect et les « nouveaux
utilisateurs » de la Play Console, sur les mêmes semaines, donnent l'écart :
c'est la part qui s'arrête à l'écran de connexion. À ces volumes, c'est
quelques dizaines de personnes par mois : assez pour décider, trop peu pour
un test A/B.

### Réponses aux six questions

**1. Le comportement actuel.** Voir plus haut : on peut lire, rien de ce
qu'on fait n'est gardé, et rien ne le dit.

**2. Remplir hors connexion : oui, mais seulement les points.** Le défaut
d'aujourd'hui est le pire possible : l'échec ressemble à une réussite (le
point se colorie, le son joue, puis la couleur disparaît). Le geste qui
compte hors connexion est celui de tous les jours : colorier le point du
jour et écrire son commentaire. Il se prête bien à une file d'attente : un
point a une clé naturelle (tracker, date) et l'écrire deux fois ne crée pas
de doublon. Créer, renommer ou supprimer un tracker ou une légende hors
connexion est rare, demande des identifiants créés par le téléphone et
ouvre les vrais cas difficiles : à désactiver hors connexion, avec un
message clair.

Donc deux marches :

| Marche | Ce que voit l'utilisateur | Coût | Serveur |
|---|---|---|---|
| A. Dire la vérité | Un bandeau « hors connexion » ; une saisie qui échoue le dit au lieu de s'annuler en silence ; toutes les années déjà vues restent lisibles | Faible | Rien |
| B. File d'attente pour les points | Le point colorié hors connexion reste, marqué « en attente », et part au retour du réseau | Moyen | Une version par point, une réponse « a changé entre-temps » |

Les moteurs de synchronisation tout faits (PowerSync, Firestore…) sont à
écarter : ils demandent plus de mémoire que le VPS n'en a, ou de remplacer
le backend.

**3. La règle « le distant gagne » : bonne pour la couleur, dangereuse pour
le texte.** Elle a raison quand l'appareil hors connexion rejoue une vieille
file (une tablette restée dans un tiroir ne doit pas écraser une correction
faite depuis). Elle a tort dans un cas précis : un commentaire écrit dans le
train est jeté parce que, pendant ce temps, un simple toucher de couleur ou
un changement de couleur de légende a « modifié » le point sur le serveur.

Ma recommandation : garder la règle, avec un principe en plus, **rien ne
disparaît en silence**. Si le distant a changé, il gagne, mais l'app montre
une fois la saisie écartée (« Votre saisie du 14 mars n'a pas été
appliquée : ce jour avait été modifié sur un autre appareil ») avec un
bouton pour la remettre. Et un commentaire écrit hors connexion est gardé
quand le serveur n'en a pas. Un conflit suppose le même jour du même
tracker modifié sur deux appareils dont un hors connexion : c'est rare,
donc l'écran sera peu vu, mais c'est lui qui évite l'avis à une étoile.

Deux conditions techniques : le serveur n'a aujourd'hui aucun moyen de dire
« ça a changé entre-temps » (il faut une version par point), et le
changement de couleur d'une légende ne doit pas compter comme une
modification de chaque point de cette couleur.

**4. Utiliser l'app sans compte : oui pour essayer, pas (encore) pour
rester.** Trois niveaux, du plus petit au plus gros :

| Niveau | Ce que c'est | Ce que ça demande | Mon avis |
|---|---|---|---|
| Essayer d'abord | Le nouvel arrivant crée et colorie son premier tracker **avant** qu'on lui demande un compte ; le compte est demandé ensuite, pour « garder ce tracker » | Le parcours du premier tracker existe déjà (app 1.4.0) : il faut le faire tourner sur le téléphone seul, puis envoyer le tracker au compte une fois créé | **Recommandé**, si l'écart installations / comptes le justifie |
| Invité durable | On utilise l'app indéfiniment sans compte, le compte est une sauvegarde facultative | Le téléphone devient la source des données (toute la couche de données à refaire), limite gratuite et publicité sans serveur, fusion à la connexion, perte des données à la désinstallation | Pas maintenant |
| Premium sans compte | L'invité peut acheter | L'achat arrive chez RevenueCat sous un identifiant anonyme que le serveur ne voit pas, et se rattache mal à un compte existant | Non : demander le compte avant ou juste après l'achat |

« Essayer d'abord » capte l'essentiel de ce que les preuves soutiennent (on
demande le compte une fois la valeur vue, comme Duolingo) pour une fraction
du coût : l'état d'invité dure quelques minutes, tient en un tracker, sans
achat, sans publicité à régler, sans mesure d'audience à repenser. L'invité
durable est un autre produit : c'est lui qui oblige à tout stocker sur le
téléphone. Il contient le mode hors connexion complet : si on y va un jour,
la marche B ci-dessus se refait autrement. C'est la raison de trancher la
question du compte avant d'aller plus loin que la marche A.

**5. La fusion.** Avec « essayer d'abord », elle devient petite :

- compte neuf : le tracker fait sur le téléphone devient le premier tracker
  du compte, sans question ;
- compte existant (la personne avait déjà un compte) : le tracker du
  téléphone s'ajoute au compte s'il reste de la place sous la limite
  gratuite ; sinon l'app demande (le garder à la place d'un autre, ou ne pas
  le garder). Jamais de fusion ni de suppression silencieuse : ce sont les
  deux échecs documentés partout.

Pour un invité durable, la seule stratégie sans perte est de demander, en
montrant les deux côtés ; c'est un écran et des règles de plus (jours en
commun, trackers au-delà de la limite en lecture seule).

**6. La friction du compte : l'éviter au départ n'est pas
contre-productif pour le Premium, à une condition.** Rien ne soutient l'idée
qu'un compte pris tôt aide à vendre ; nos essais se jouent le jour de
l'installation (audit du 22 novembre), donc tout ce qui empêche d'arriver
dans l'app ce jour-là coûte des essais. La condition : que le compte existe
au moment de l'achat, parce que c'est lui qui permet au serveur de savoir
qui est Premium. « Essayer d'abord » la remplit, puisque le compte est créé
avant le premier mur Premium.

### Ce que je recommande, dans l'ordre

1. **Mesurer le mur, cette semaine, sans rien construire.** Charles relève
   les premiers téléchargements iOS et Android des huit dernières semaines ;
   je les mets en face des comptes créés. En dessous de 10 à 15 % de perte,
   « essayer d'abord » ne vaut pas son coût ; au-dessus de 25 à 30 %, c'est
   probablement le chantier le plus rentable de toute la liste.
2. **La marche A (dire la vérité hors connexion) dans la release en
   cours** : petite, sans serveur, et elle supprime la perte silencieuse.
   À placer après l'outillage Android.
3. **La marche B (file d'attente des points) et « essayer d'abord » après
   la release**, comme deux chantiers avec leur spec, dans l'ordre que la
   mesure du point 1 donnera. Les faire entrer dans la release en cours la
   retarderait de plusieurs semaines et toucherait la couche de données
   juste avant le pic du Nouvel An.
4. **Pas d'invité durable ni de Premium sans compte** pour l'instant. À
   rouvrir si la mesure montre un mur très coûteux malgré « essayer
   d'abord ».

### À vérifier dès maintenant, quelle que soit la décision

- **L'achat à vie sur Android doit être déclaré « non-consumable » dans le
  tableau de bord RevenueCat.** Sa documentation dit que, sans cela, le SDK
  « consomme » l'achat : Google laisse alors le client le racheter, et
  depuis Billing Client 8 (`purchases-flutter` 9 et suivants, l'app est en
  10) un achat consommé ne peut plus être retrouvé par « Restaurer ». À
  regarder par Charles dans RevenueCat (produit à vie Android). Source :
  `reports/Utiliser l'app sans compte.md`, section RevenueCat, « L'achat à
  vie revient par le store ».

### Ce qui reste incertain

- La taille de tous les effets : aucune étude ne la donne, et nos volumes
  ne permettent pas de la mesurer finement.
- La fréquence réelle des conflits entre deux appareils : jugée rare,
  mesurée nulle part.
- Le comportement de RevenueCat quand un invité qui a acheté se connecte à
  un compte existant : le rapport relève une contradiction dans sa
  documentation, à vérifier en bac à sable avant tout Premium sans compte.
- Les points marqués *déduit* dans la lecture du code n'ont pas été essayés
  sur un téléphone.
