# Stats plus utiles — design (2026-11-24)

Chantier 5 de `docs/FABLE.md`, point 10 de `docs/ROADMAP.md`. Brainstormé
du 2026-11-23 au 2026-11-24 avec Charles, sur maquettes ; Charles a validé
les recommandations (« fais comme tu recommandes sur les 4 points »,
2026-11-24). Phase de documentation : à confirmer puis construire plus tard.

Sources :

- recherche : `docs/research/reports/Stats utiles pour trackers génériques.md`
  (et ses notes) ; les seuils ci-dessous en viennent ;
- maquettes : https://claude.ai/artifact/1rF2wxMQx5fMsxf4Rogz3P. **La
  rangée 6 (« Parcours complets ») est la référence** : quatre parcours de
  « + » jusqu'aux stats, un par forme, et le tableau « Ce que les parcours
  font apparaître ». Les rangées 1 à 5 sont les étapes du brainstorm ; là où
  elles diffèrent de la rangée 6 ou de ce texte, ce texte l'emporte (voir
  « Écarts avec les maquettes »). Les textes des maquettes sont indicatifs.

## Pourquoi

Les mots de Charles : même en premium, les stats « n'apportent pas grand-chose ».
Aujourd'hui elles ne font que compter le remplissage : jours, séries, % de
l'année, répartition des couleurs, par mois, par jour de la semaine
(`StatsDetailDialog`, `GlobalStatsDialog`). Rien ne dit ce que les couleurs
veulent dire. Or les stats sont la principale porte d'entrée vers Premium :
les 4 essais depuis le 2026-10-29 ont suivi un mur `stats` ou `global_stats`
(spec de la pop-up premium).

L'app ne sait pas ce que suit un tracker (humeur, sommeil, règles…). Elle
n'a pas besoin de le savoir : elle regarde la **forme** du tracker, et
chaque forme débloque ses calculs. Un modèle arrive avec sa forme réglée et
des phrases écrites pour lui ; un tracker perso règle sa forme en une
question et obtient les mêmes calculs, avec des phrases génériques qui
reprennent son nom et ses libellés.

## Objectifs, non-objectifs, anti-objectifs

**Objectifs** : des stats qui répondent aux questions que les gens se posent
devant leurs données (« qu'est-ce qui a changé ? », « qu'est-ce qui va avec
quoi ? », « quand revient-il ? ») ; une vraie stat gratuite qui donne envie
du reste ; des chiffres toujours honnêtes (comptes, dénominateurs, seuils).

**Non-objectifs** : des stats thématiques (Dian Dian ne devient pas une app
de cycle) ; plusieurs couleurs par case ; des liens décalés dans le temps
(« le lendemain d'une mauvaise nuit… ») ; refaire les stats globales.

**Anti-objectifs** (échec même si ça marche) : une phrase fausse ou qui
s'appuie sur trop peu de jours ; un jour vide compté comme un mauvais jour ;
du rouge, du vert, des flèches ou un « pire mois » (la recherche montre que
ça nourrit la rumination) ; un mot de fertilité ou de contraception ; une
création de tracker plus lourde au point de faire fuir.

## Approches considérées

1. **Stats par modèle** (chaque modèle a ses écrans) : riche pour les
   modèles, rien pour les trackers perso, qui sont la majorité en prod.
   Écartée.
2. **Stats par forme** (retenue) : trois formes, les mêmes calculs pour un
   modèle et un perso ; seuls les mots changent.
3. Pour régler la forme d'un perso : **A**, une question à 3 choix à la
   création (retenue) ; **B**, deux questions (échelle ? chaque jour ?) qui
   couvrent les 4 combinaisons. A est plus léger ; la 4e combinaison (une
   échelle qui arrive de temps en temps, une migraine avec intensité) se
   règle dans la légende, et l'app la propose d'elle-même à la 2e couleur
   (voir « La légende »).

## Le modèle : deux réglages par tracker

Chaque tracker porte deux réglages, plus son modèle d'origine.

| Réglage | Valeurs | Défaut | Effet |
|---|---|---|---|
| Échelle | oui / non | non | oui : les couleurs vont du plus haut (en haut de la liste) au plus bas ; non : des catégories sans ordre |
| Cadence | chaque jour / de temps en temps | chaque jour | chaque jour : rappel du soir, une case vide = « pas noté » ; de temps en temps : jamais de rappel, une case vide = « rien ce jour-là » |
| Hors échelle (par couleur) | dans / hors de l'échelle | dans | une couleur hors échelle (Repos, Malade) est comptée à part, jamais dans un niveau moyen |
| Modèle d'origine | id du modèle ou rien | rien | donne les phrases écrites pour lui |

Les trois formes en découlent :

- **Échelle** : échelle oui, chaque jour (Humeur, Sommeil, Énergie).
- **Catégories** : échelle non, chaque jour (Activité, Émotions).
- **De temps en temps** : cadence de temps en temps, avec ou sans échelle
  (Migraine, Cycle, Pilule oubliée).

La cadence est celle de la spec des rappels (`pages.cadence`) : un seul
réglage pour les deux chantiers. L'ordre de l'échelle est la position dans
la légende (`legends.position`) : la première couleur dans l'échelle est le
niveau le plus haut. « Plus haut » ne veut jamais dire « mieux » : les
phrases disent « monte », « plus haut », jamais « meilleur ».

## La création

`_CreateTrackerDialog` (`flutter_app/lib/screens/page_list_screen.dart`) ne
demande aujourd'hui qu'un nom. Elle devient (rangée 6, parcours 1 à 4) :

1. **Partir d'un modèle** : une rangée de puces (nom et trois points de sa
   palette). Toucher un modèle ouvre sa **fiche** : nom modifiable, légende
   prête (HAUT et BAS marqués si c'est une échelle), une ligne sur la forme,
   le rappel du soir oui / non, et ce que ses stats sauront dire ; boutons
   « ‹ Modèles » et « Créer ». Rien à régler.
2. **Ou un tracker perso** : le champ du nom. Dès qu'un nom est tapé, la
   question apparaît : **« Comment se remplit-il ? »**
   - « Une note chaque jour » (Haute, Bonne, Moyenne… : une échelle) →
     échelle oui, chaque jour ;
   - « Une activité chaque jour » (Course, Muscu, Repos… : des catégories)
     → échelle non, chaque jour ;
   - « Quelque chose qui arrive parfois » (Migraine, Règles, Pilule
     oubliée…) → échelle non, de temps en temps.
   *Mon choix* : rien n'est présélectionné, « Créer » attend une réponse.
   Un encadré résume l'effet : stats, rappel du soir oui / non, ce que veut
   dire une case vide.
3. Si le nom tapé est celui d'un modèle, dans une des quatre langues, sans
   tenir compte de la casse ni des accents (« sommeil »), l'app propose le
   modèle sous le champ.
4. La limite gratuite ne change pas : en gratuit, « + » ouvre le mur du 4e
   tracker au lieu de la fenêtre.

**Après « Créer »**, un modèle ouvre le tracker, légende comprise (comme le
parcours du premier tracker aujourd'hui). Un perso ouvre **directement sa
légende**, avec un départ selon la réponse :

- échelle : 5 niveaux d'une même teinte, « Très haut, Haut, Moyen, Bas,
  Très bas », à renommer ;
- catégories : vide, le champ d'ajout prêt (« Une couleur par activité :
  Course, Muscu, Repos… ») ;
- de temps en temps : une couleur, au nom du tracker.

Aujourd'hui un tracker perso s'ouvre sans légende (« Ajoute des légendes pour
commencer ») et rien ne dit que l'ordre compte.

**Le parcours du premier tracker** (`first_tracker_screen.dart`) ne pose
pas la question, pour ne pas freiner le premier geste : ses modèles portent
leur forme, et « Autre… » (Oui / Un peu / Non) crée une échelle quotidienne
sans modèle d'origine. *Mon choix* : la même liste de modèles qu'avec « + » ;
si la grille de l'accueil ne tient plus sur un petit écran, l'accueil garde
ses six tuiles et les nouveaux modèles n'apparaissent que dans « + ».

### Les modèles

| Modèle | Légende, du haut vers le bas | Forme | Hors échelle |
|---|---|---|---|
| Humeur | Génial, Super, Bien, Bof, Mou | échelle, chaque jour | — |
| Sommeil | 8 h+, 7–8 h, 6–7 h, 5–6 h, < 5 h | échelle, chaque jour | — |
| Sport | Fait, Presque, Un peu, Repos, Malade | échelle, chaque jour | Repos, Malade |
| Lecture | 1 h+, 30 min, Quelques pages, Rien | échelle, chaque jour | — |
| Habitudes | Fait, Presque, Un peu, Repos, Raté | échelle, chaque jour | Repos |
| **Cycle** (nouveau) | Règles, Léger, Douleurs | de temps en temps, sans échelle ; estimation de la prochaine fois activée | — |
| **Études** (nouveau) | 3 h et plus, 2 h, 1 h, 30 min, Rien | échelle, chaque jour | — |
| **Dépenses** (nouveau) | Plus de 100 €, 30 à 100 €, 10 à 30 €, Moins de 10 €, Rien dépensé | échelle, chaque jour | — |
| **Émotions** (nouveau) | Joie, Calme, Fatigue, Stress, Tristesse | catégories, chaque jour | — |

Les nouveaux modèles viennent des trackers que les gens créent eux-mêmes en
prod (Study, Money, Cry, des humeurs en catégories). Leurs libellés sont à
écrire dans les quatre langues de l'app (en, fr, zh-CN, zh-TW) ; « € » suit
la devise de la langue ou devient neutre, au choix du constructeur. Couleurs
des nouveaux modèles en échelle (Études, Dépenses) : une seule teinte du
clair au foncé, pas de vert « bien » ni de rouge « mal » (contrairement à la
maquette de la rangée 5). *Mon choix* : les modèles existants gardent leurs
couleurs (palettes des épingles Pinterest, écran du premier tracker,
visuels marketing). Les stats dessinent avec les couleurs de la légende et
n'ajoutent jamais leur propre rouge ou vert.

## La légende

`LegendEditorDialog` gagne, en haut, les deux réglages, modifiables à tout
moment :

- **Échelle** : « du plus haut (en haut) au plus bas » / « des catégories,
  sans ordre ». Allumée, chaque ligne montre HAUT ou BAS aux extrémités et
  une puce « dans l'échelle » / « hors échelle » ; un bouton **« Inverser
  l'ordre »** retourne la liste. Une échelle rangée à l'envers retournerait
  toutes les phrases (« monte » au lieu de « baisse ») : d'où les repères.
- **Chaque jour** : « rappel du soir · case vide = pas noté » / « de temps
  en temps · case vide = rien ce jour-là ». C'est l'endroit « dans le
  tracker » que la spec des rappels laissait au constructeur.

**La 2e couleur d'un tracker de temps en temps sans échelle** : quand la
légende passe de 1 à 2 couleurs, l'app demande une fois : « Ces couleurs
vont-elles du plus fort au plus léger ? » (Oui, une échelle / Non). Oui
allume l'échelle. C'est ce qui couvre la migraine avec intensité sans
seconde question à la création. Rien à enregistrer : la question ne revient
que si la légende repasse par une seule couleur.

**Modèle modifié** : renommer ou recolorer une couleur garde les phrases du
modèle ; changer l'ordre, l'échelle, la cadence, ou ajouter / supprimer une
couleur fait passer le tracker aux phrases génériques (*mon choix* : le
modèle d'origine est effacé, définitivement).

*À vérifier par le constructeur* : la légende accepte-t-elle deux couleurs
identiques ? Une case ne garde que sa couleur (`cells.color`) ; le lien vers
la légende se fait par la couleur : quand une couleur de légende change, c'est l'app qui
recolore les cases par un appel à part (`CellsProvider.recolorCells`,
diffusé en `cells:recolored`). Deux couleurs identiques rendraient une case
ambiguë, et un recoloriage les fusionnerait sans le dire : à interdire dans
l'éditeur. Une case dont la
couleur n'est plus dans la légende compte comme « sans légende » : visible
dans les comptes de jours remplis, jamais dans un niveau ni un rythme.

## Les trackers déjà créés

Ils n'ont ni forme ni modèle enregistrés. **Décidé (Charles, 2026-11-24)** :

1. **Ceux qui viennent d'un modèle sont reconnus** : même nombre de couleurs
   et mêmes libellés, dans l'ordre, que la légende d'un modèle dans une des
   quatre langues (le titre est ignoré, souvent renommé). Ils reçoivent la
   forme, les couleurs hors échelle et le modèle d'origine. « Autre… »
   (Oui / Un peu / Non) devient une échelle quotidienne sans modèle.
   *Mon choix* : une migration du backend, une fois, avec les libellés des
   modèles copiés depuis l'app ; à défaut, au premier lancement de l'app
   mise à jour. Au constructeur de trancher.
2. **Les autres** gardent les défauts (catégories, chaque jour) et la page
   Stats leur pose **une fois** la question à 3 choix, en haut, avec
   « Plus tard » ; elle ne bloque rien. Une réponse règle le tracker sur le
   serveur ; « Plus tard » est retenu sur l'appareil.
3. *Mon choix* : **vérifier l'ordre avant d'en faire une échelle.** Ces
   légendes n'ont pas été rangées pour une échelle (des listes « 1…5 » avec
   le plus bas en premier, un Repos au milieu). Répondre « Une note chaque
   jour » ouvre la légende avec ses repères HAUT / BAS, les puces « dans /
   hors échelle » et « Inverser l'ordre », sous une ligne « Vérifiez
   l'ordre : en haut, le niveau le plus haut ». Fermer la légende vaut
   confirmation. Même chose quand on allume l'interrupteur « Échelle » d'un
   tracker qui a déjà des cases.

## Les stats

Calculées dans l'app à partir des cases, à la demande ; rien n'est stocké.

### Règles pour toutes les cartes

- Des comptes, toujours avec leur dénominateur (« 19 nuits sur 21 »), plutôt
  que des pourcentages seuls.
- Une case vide n'est jamais un niveau bas. Pour un tracker de chaque jour,
  elle ne compte pas ; pour un tracker de temps en temps, elle veut dire
  « rien ce jour-là ».
- Ni rouge, ni vert, ni flèche, ni classement des mois.
- Chaque phrase ouvre ses jours dans la grille (« Voir ces jours dans la
  grille › ») : la grille met ces jours en avant, les autres s'estompent,
  un bandeau dit lesquels et se ferme.
- **Sous le seuil, une carte dit où elle en est** (« 4 / 7 nuits », « Lien
  avec Sommeil : 5 jours de Migraine sur 10 »), jamais une carte vide.
- **Décidé (Charles, 2026-11-24)** : l'essai reste proposé dès le premier
  jour depuis les stats (c'est par là que viennent les essais). Pour
  quelqu'un qui a accès à Premium (essai ou abonné), une carte Premium pas
  encore prête montre sa progression et, dessous, la même carte remplie de
  données d'exemple, marquée « Exemple ». Le paywall ouvert depuis les stats
  montre aussi des cartes d'exemple. *Mon choix* : elles se construisent
  avec le lot 2 des stats, pas avec la refonte du paywall (chantier 2,
  avant le Nouvel An) ; le mur `global_stats` n'en a pas.
- Aucune stat ne part en notification.
- Les phrases d'un perso ne doivent pas dépendre du genre ni du nombre des
  mots de l'utilisateur, ni de l'élision (« de Sommeil », « d'Énergie ») :
  des tournures du type « Énergie, le dimanche : Haute ou Bonne 11 fois sur
  12 ». Les phrases des maquettes (« Énergie est la plus haute ») sont
  indicatives. Même contrainte en anglais et en chinois.

### Ce que voit chaque forme

Seuils de la recherche (rapport, tableau final). « Jours notés » = cases
remplies du tracker.

| Carte | Formes | Seuil | Accès | Exemple |
|---|---|---|---|---|
| Chiffres du tracker | toutes | aucun | gratuit | chaque jour : jours notés, série, % de l'année ; de temps en temps : « 6 fois · depuis 12 j » |
| Depuis la dernière fois, par couleur | toutes | 1 fois | gratuit | « Course : il y a 8 jours » |
| **Ce mois-ci comparé au mois dernier** (la stat offerte) | toutes | chaque jour : 7 jours notés dans chacun des deux mois (sinon le mois seul) | gratuit | échelle : « 7–8 h ou plus : 19 nuits sur 21 en novembre, contre 14 sur 27 en octobre » ; catégories : les comptes de chaque couleur, mois contre mois ; de temps en temps : « Novembre (jusqu'au 23) : 1 fois. Octobre : 2 fois » |
| Annonce d'un lien | toutes | celui du lien | gratuit (l'existence) | « Un lien apparaît entre Sommeil et Humeur » |
| Ce jour-là, l'an dernier | toutes | un an d'historique | gratuit | — |
| Niveau du mois, avec la répartition | échelle | 7 jours notés dans le mois | Premium | « Novembre : entre 8 h+ et 7–8 h, plus près de 7–8 h · sur 21 nuits » |
| Tendance | échelle | deux mois d'au moins 7 jours notés | Premium | « Depuis septembre, vos nuits rallongent » |
| Barres mois par mois (part de chaque couleur ; « non noté » visible pour les quotidiens) | toutes | aucun | Premium | — |
| Jour de la semaine | toutes | graphique sans seuil ; phrase avec les seuils des liens | Premium | « Course revient surtout le dimanche : 7 de vos 15 Course » |
| Rythme d'une couleur : écart habituel, durée habituelle, plus longue période sans | toutes | 3 écarts (4 fois) | Premium | « Entre deux Course, en général 6 jours (de 1 à 14, 14 écarts) » |
| Intensité habituelle | de temps en temps avec échelle | 3 fois | Premium | « Moyenne (Forte 2, Moyenne 3, Légère 1) » |
| Prochaine fois, probablement | de temps en temps, estimation activée, rythme régulier | voir « Le rythme » | Premium | « Entre le 28 nov. et le 2 déc. » |
| Liens avec les autres trackers | au moins un des deux en échelle | voir « Les liens » | Premium | « Les jours où vos nuits font 7–8 h ou plus, votre Humeur est Génial ou Super 29 fois sur 37 ; les autres jours, 9 fois sur 33. Ce n'est pas une preuve de cause. » |

Le « haut de l'échelle » des phrases (« 7–8 h ou plus », « Haute ou Bonne »)
est la moitié haute des niveaux dans l'échelle, arrondie vers le bas :
2 niveaux sur 5 ou 4, 1 sur 3 ou 2. Les catégories n'ont pas de total
« jours actifs » : l'app ne sait pas que Repos n'est pas une activité.

Le niveau moyen numérote les niveaux de l'échelle (1 en bas) et le dit en
mots, placé entre deux libellés, toujours avec la répartition à côté pour
que les extrêmes ne disparaissent pas. *Mon choix* pour la tendance : une
phrase seulement quand le libellé le plus proche change entre deux mois
d'au moins 7 jours notés chacun ; le constructeur peut durcir la règle.

### Le rythme

*Mon choix*, après la relecture : **le rythme a un sujet**, une couleur ou
le tracker entier (« toutes les couleurs »).

- Tracker de temps en temps : sujet par défaut, le tracker entier (Migraine :
  Forte, Moyenne et Légère comptent ensemble). Modèle Cycle : Règles, sa
  première couleur. La carte a un sélecteur « Rythme de … » (maquette
  « Rythme », rangée 3) ; le sujet choisi est enregistré avec le tracker
  (`pages.rhythm_legend_id`, vide = le tracker entier ; un id de légende,
  pas une couleur, qui change au recoloriage).
- Tracker de chaque jour : le rythme de chaque couleur (Course), dans la
  carte « Chaque couleur » ; jamais le tracker entier, qui ne serait que
  le remplissage.
- **Un épisode du sujet** = des jours du sujet séparés d'au plus un jour
  sans lui (vide ou d'une autre couleur) ; il commence à son premier jour.
  Règles, Léger, Règles font un seul épisode ; un jour de Douleurs seul ne
  démarre rien quand le sujet est Règles.
- Pour un tracker de temps en temps, « N fois » (bandeau, ce mois-ci
  comparé au mois dernier) compte les épisodes du tracker entier, au mois
  de leur début. Avec une échelle, l'intensité d'un épisode est son niveau
  le plus haut.

D'après la recherche (méthode de drip, Li et al.) :

- écart habituel = médiane des six derniers écarts entre débuts d'épisode ;
  il en faut au moins 3 ;
- un écart de plus de 1,7 fois la médiane des autres est grisé (« sans
  doute une case oubliée »), ignoré, avec un bouton « Le compter » ;
- **estimation de la prochaine fois** : seulement si elle est activée
  (interrupteur sur la carte, activé par défaut pour le modèle Cycle,
  désactivé ailleurs), avec au moins 3 écarts retenus et un écart le plus
  long moins l'écart le plus court ≤ un tiers de la médiane. La fenêtre va
  du dernier début plus l'écart le plus court au dernier début plus le plus
  long ; elle s'affiche aussi en contour pointillé dans la grille. Sinon :
  « Pas d'estimation : le rythme est trop irrégulier (de 9 à 22 jours entre
  deux fois). » Mention fixe : ni avis médical ni méthode de contraception.

### La période

*Mon choix* :

- Les cartes du mois et de l'année (chiffres du tracker, niveau du mois,
  ce mois-ci comparé au mois dernier, barres mois par mois) suivent le
  calendrier de l'année affichée. En janvier, « le mois dernier » est
  décembre de l'année d'avant.
- Les cartes de fond (tendance, jour de la semaine, rythme, intensité,
  liens) prennent les **12 derniers mois** jusqu'à aujourd'hui, ou jusqu'au
  31 décembre pour une année passée. Ainsi rien ne retombe sous un seuil le
  1er janvier, au pic de l'année où arrivent les essais.
- L'app charge donc l'année précédente en plus de l'année affichée.
  `SyncService.ensureYear` change aussi l'année active : il faut un
  chargement à part, au constructeur.
- « Voir ces jours dans la grille » met en avant les jours de l'année
  affichée ; le bandeau dit combien sont dans l'autre année.

### Les liens

- Le même jour seulement. Paires : échelle × échelle, couleur × échelle.
- Un lien n'apparaît qu'avec au moins **30 jours notés dans les deux
  trackers** et **10 jours dans chaque groupe comparé**, un test
  significatif après correction pour le nombre de paires testées
  (Benjamini-Hochberg) et une taille d'effet minimale ; trois liens au plus.
  Le choix exact des tests revient au constructeur (repères dans le
  rapport : corrélation de rang pour deux échelles, comparaison de
  proportions pour une couleur).
- La phrase donne les deux comptes et finit par « Ce n'est pas une preuve
  de cause. »
- Les mêmes seuils valent pour la phrase du jour de la semaine (un jour
  contre les autres, corrigé sur les 7 jours).

### Phrases des modèles

Chaque modèle a ses phrases (« vos nuits rallongent », « vous lisez plus »,
« vos jours sans dépense tombent surtout le dimanche ») et parfois une carte
à lui : les nuits de moins de 5 h comptées à part pour Sommeil, la plus
longue suite sans Repos pour Sport et Habitudes, l'estimation pour Cycle.
Les calculs sont ceux de la forme. La liste des phrases, dans les quatre
langues, revient au constructeur.

## Les écrans

- **Page Stats d'un tracker** (remplace `StatsDetailDialog`), ouverte depuis
  le bandeau du tracker, **pour tous** : aujourd'hui le gratuit tombe
  directement sur le mur `stats`. En gratuit : les cartes gratuites,
  l'annonce d'un lien, la liste nommée (pas floutée) de ce que Premium
  ajoute, et le bouton « Voir toutes mes stats » qui ouvre le paywall
  (événement `paywall.stats`, inchangé). Ordre des cartes par forme : celui
  de la rangée 6 (étapes « 3 mois plus tard »).
- **Bandeau du tracker** : inchangé pour un tracker de chaque jour (jours,
  série, % de l'année) ; « N fois · depuis X j » pour un tracker de temps
  en temps, où la série n'a pas de sens.
- **Grille** : mise en avant des jours d'une phrase ; contour de la fenêtre
  probable.
- `GlobalStatsDialog` (mur `global_stats`) : inchangé dans ce chantier.

## Données et serveur

- `pages.cadence` : déjà prévue par la spec des rappels (`'daily' |
  'occasional'`, défaut `'daily'`). Le premier des deux chantiers construits
  l'ajoute.
- `pages.scale` (booléen, défaut faux), `pages.template` (texte, id du
  modèle, nullable), `pages.estimate` (booléen, défaut faux),
  `pages.rhythm_legend_id` (nullable, voir « Le rythme ») ;
  `legends.in_scale` (booléen, défaut vrai). Noms exacts au constructeur.
- Renvoyés par le bootstrap et les routes des pages et des légendes,
  acceptés à la création et à la mise à jour, diffusés par les événements de
  synchro. Les clients 1.4.0 ne connaissent pas ces champs : vérifier qu'ils
  les ignorent et qu'une mise à jour faite par eux (titre, position) ne les
  remet pas à zéro.
- La création depuis un modèle crée le tracker et sa légende comme le
  parcours du premier tracker (idempotence par `clientId`).
- Événements produit (table `events`, nom seul) : *mon choix*
  `tracker_created.template.<id>`, `tracker_created.custom.<scale|categories|occasional>`,
  `stats.form_answered` (trackers existants), pour savoir quels modèles et
  quelles formes servent. Sous le même intérêt légitime que les autres
  événements produit (registre, politique de confidentialité).

## Découpage

*Mon choix* pour l'ordre : le lot 1 passe **avant les rappels** (en
janvier, après l'outillage Android, dont il ne dépend pas), et sort dans la
même version de l'app qu'eux ou juste avant. Les rappels ne construisent
alors ni le choix « Tous les jours / De temps en temps » dans
`_CreateTrackerDialog` ni de réglage dans le tracker : la question de
création et l'interrupteur « Chaque jour » de la légende les remplacent.
Si le lot 1 sort avant les rappels, les lignes « Rappel du soir » restent
cachées.

1. **Lot 1 — forme et création** : colonnes, migration et reconnaissance
   des trackers existants, fenêtre « Nouveau tracker » (modèles, fiche,
   question), légende de départ, réglages dans la légende, question de la
   2e couleur, bandeau selon la forme, les 4 nouveaux modèles.
2. **Lot 2 — page Stats** : cartes gratuites et Premium des trois formes,
   seuils et progression, cartes d'exemple, mise en avant dans la grille,
   question pour les trackers existants.
3. **Lot 3 — rythme avancé et liens** : estimation et contour dans la
   grille, liens entre trackers avec leurs tests.
4. **Plus tard** : le bilan de l'année (carte gratuite à partager, bilan
   complet en Premium ; maquette « Bilan », rangée 4), pour fin 2027 au
   plus tôt (pas de bilan pour le Nouvel An 2026, décidé le 2026-11-23).

La pop-up premium (chantier 6) attend le lot 2 : ses aperçus `days_7` et
`days_30` montrent « ce mois-ci comparé au mois dernier » ou, faute de
seuil, « depuis la dernière fois ».

## Écarts avec les maquettes

- Rangée 4, « Gratuit » : la stat offerte qui change chaque mois est
  remplacée par « ce mois-ci comparé au mois dernier », la règle de la
  recherche (rangée 6).
- Rangée 3, « Catégories » : le total « 11 jours actifs » disparaît (voir
  « Ce que voit chaque forme »).
- Rangée 5, « Modèles » : Dépenses passe à une seule teinte ; l'ordre de sa
  légende est celui du tableau des modèles.
- Rangée 2, « Forme » et « Création » : la question à la création est celle
  de la possibilité A (rangée 5), pas la question de la rangée 2.

## Questions closes

- Stats par forme, mêmes calculs pour un modèle et un perso (Charles,
  2026-11-23).
- **Décidé (Charles, 2026-11-24)**, les quatre points du tableau de la
  rangée 6 :
  1. Une case garde une seule couleur. Course et Muscu le même jour : on
     note l'activité principale, ou on crée une couleur « Course + Muscu ».
  2. Possibilité A, avec la question posée à la 2e couleur d'un tracker de
     temps en temps.
  3. Les trackers existants : reconnus quand ils viennent d'un modèle, sinon
     une question une fois sur la page Stats.
  4. L'essai reste proposé dès le premier jour ; les cartes Premium pas
     encore prêtes montrent un exemple marqué « Exemple ».

## Laissé au constructeur

Les tests statistiques exacts, la règle fine de la tendance, la liste des
phrases et leurs traductions, les données d'exemple, la mise en page et les
animations des cartes, l'endroit exact de la reconnaissance des trackers
existants (migration ou app), les noms des colonnes et des événements.

## Relecture du 2026-11-24

Relue comme un constructeur qui doit planifier sans pouvoir poser de
question. Six trous, tous réglés dans le texte ci-dessus comme *mon choix* :

1. **Ce que compte le rythme** : un sujet par tracker (une couleur ou le
   tracker entier), et une définition de l'épisode qui tient pour Cycle et
   Migraine (« Le rythme »).
2. **La période de chaque carte** : le calendrier pour les cartes du mois,
   12 mois glissants pour les cartes de fond (« La période »).
3. **Un tracker existant qui devient une échelle** passe par une
   vérification de l'ordre dans la légende (« Les trackers déjà créés »).
4. **L'ordre avec les rappels** : le lot 1 des stats avant les rappels, qui
   n'ont plus à construire leur propre choix de cadence (« Découpage » ; la
   spec des rappels et `docs/FABLE.md` sont alignées).
5. **Les cartes d'exemple du paywall** : avec le lot 2 des stats, pas avec
   la refonte du paywall.
6. **Les couleurs des modèles existants** ne changent pas ; la règle d'une
   seule teinte vaut pour les nouveaux modèles en échelle.

Corrigé aussi : le recoloriage des cases est un appel de l'app
(`recolorCells`), pas un effet de `legends:recolored`.
