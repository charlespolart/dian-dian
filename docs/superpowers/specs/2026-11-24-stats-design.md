# Stats plus utiles — design (2026-11-24)

Chantier 5 de `docs/FABLE.md`, point 10 de `docs/ROADMAP.md`. Brainstormé
du 2026-11-23 au 2026-11-24 avec Charles, sur maquettes. Une première
version (une question à 3 choix à la création) a été remplacée le même
jour, après les questions de Charles sur les légendes ambiguës, les jours
vides, les rappels et la peur de perdre un réglage. Charles a validé cette
seconde version sur ses maquettes (« c'est bon pour moi », 2026-11-24).
Phase de documentation : à confirmer puis construire plus tard.

Sources :

- recherche : `docs/research/reports/Stats utiles pour trackers génériques.md`
  (et ses notes) ; les seuils viennent de là ;
- **maquettes de référence** : https://claude.ai/artifact/HVMGhCrPR82sjShMxiht2e.
  Partie 1 : le principe, les neuf modèles, le tableau Gratuit / Premium.
  Partie 2 : sept histoires de « + » jusqu'aux stats (1 Sommeil, 2 Lecture,
  3 Énergie, 4 Sport, 5 Migraine, 6 Cycle, 7 Pilule). Partie 3 : les
  rappels (8) et Premium (9). Chaque étape porte une étiquette EXISTE,
  NOUVEAU ou MODIFIÉ. Les textes sont indicatifs ; les chiffres viennent de
  données d'exemple calculées et se recoupent d'un écran à l'autre. Là où
  une maquette et ce texte diffèrent, ce texte l'emporte (voir « Écarts
  avec les maquettes ») ;
- l'ancienne page (https://claude.ai/artifact/1rF2wxMQx5fMsxf4Rogz3P) garde
  le brainstorm et la première version ; elle ne fait plus foi ;
- prod, requête en lecture seule du 2026-11-24 : sur 53 trackers d'au moins
  15 cases, 40 sont remplis presque tous les jours et 8 seulement « quand ça
  arrive » (lecture, livre audio, sport, étirements…) ; 5 de ces 8 n'ont
  aucune couleur « rien ».

## Pourquoi

Les mots de Charles : même en premium, les stats « n'apportent pas grand-chose ».
Aujourd'hui elles ne font que compter le remplissage : jours, séries, % de
l'année, répartition des couleurs, par mois, par jour de la semaine
(`StatsDetailDialog`, `GlobalStatsDialog`). Rien ne dit ce que les couleurs
veulent dire. Or les stats sont la principale porte d'entrée vers Premium :
les 4 essais depuis le 2026-10-29 ont suivi un mur `stats` ou `global_stats`
(spec de la pop-up premium).

L'app ne sait pas ce que suit un tracker (humeur, sommeil, règles…). Elle
n'a pas besoin de le savoir : elle sait **comment on le colorie** et **si
ses couleurs ont un ordre**, et c'est ce qui décide de ses stats. Un modèle
arrive avec ses réglages faits et des phrases écrites pour lui ; un tracker
perso obtient les mêmes calculs, avec des phrases génériques qui reprennent
son nom et ses libellés.

## Objectifs, non-objectifs, anti-objectifs

**Objectifs** : des stats qui répondent aux questions que les gens se posent
devant leurs données (« qu'est-ce qui a changé ? », « qu'est-ce qui va avec
quoi ? », « quand revient-il ? ») ; une vraie stat gratuite qui donne envie
du reste ; des chiffres toujours honnêtes (comptes, dénominateurs, seuils) ;
des questions auxquelles personne n'hésite à répondre ; **aucun choix
définitif** : tout réglage d'un tracker se change après coup (règle de
Charles, 2026-11-24).

**Non-objectifs** : des stats thématiques (Dian Dian ne devient pas une app
de cycle) ; plusieurs couleurs par case ; des liens décalés dans le temps
(« le lendemain d'une mauvaise nuit… ») ; refaire les stats globales.

**Anti-objectifs** (échec même si ça marche) : une phrase fausse ou qui
s'appuie sur trop peu de jours ; un jour vide compté comme un mauvais jour ;
du rouge, du vert, des flèches ou un « pire mois » (la recherche montre que
ça nourrit la rumination) ; un mot de fertilité ou de contraception ; une
création de tracker plus lourde au point de faire fuir ; une question qui
fait hésiter ; un réglage qu'on ne peut plus défaire.

## Approches considérées

1. **Stats par modèle** (chaque modèle a ses écrans) : riche pour les
   modèles, rien pour les trackers perso, qui sont la majorité en prod.
   Écartée.
2. **Stats par forme** (retenue) : les mêmes calculs pour un modèle et un
   perso ; seuls les mots changent.
3. Pour régler la forme d'un perso :
   - **A**, une question à 3 choix à la création (« Une note chaque jour »,
     « Une activité chaque jour », « Quelque chose qui arrive parfois »).
     Retenue d'abord, puis écartée le 2026-11-24 : elle mêlait deux
     questions (l'ordre des couleurs et l'habitude de remplissage), ses
     exemples orientaient la réponse, et on hésitait sur des cas courants
     (Pilule, Télétravail / Bureau / Congé, Lecture coloriée seulement les
     soirs de lecture) ;
   - **B**, deux questions à la création : trop abstraite avant d'avoir la
     moindre couleur ;
   - **C, retenue** : chaque question au moment où elle devient concrète.
     À la création, une seule, sur une habitude que la personne connaît
     (« Vous allez le colorier… ») ; l'ordre des couleurs, dans la légende,
     à la 2ᵉ couleur, avec ses propres couleurs sous les yeux.

## Le modèle : trois réglages par tracker

Planche « Le principe ».

| Réglage | Valeurs (textes de l'app) | Réglé | Effet |
|---|---|---|---|
| Remplissage | « Tous les jours, même les jours sans » / « Seulement les jours où ça arrive » | à la création ; prérempli par un modèle | tous les jours : une case vide = pas encore noté, elle ne compte jamais ; seulement quand : une case vide = rien ce jour-là, les stats comptent les fois |
| Ordre des couleurs | « Du plus au moins » / « Des sortes différentes » | à la 2ᵉ couleur ; prérempli par un modèle ou une légende prête | du plus au moins : une échelle, le niveau le plus haut en haut de la liste ; sortes différentes : chaque couleur comptée à part |
| Rappel | Non / Matin / Soir | prérempli : Soir pour « tous les jours », Non pour « seulement quand », celui du modèle (Sommeil : Matin) | spec des rappels (`2026-11-23-reminders-design.md`) |

S'y ajoutent :

- **À part** (par couleur, dans un tracker « du plus au moins ») : une
  couleur hors de l'échelle (Repos, Malade) est comptée à part, jamais dans
  un niveau ni dans une intensité.
- **La couleur « rien »** (au plus une par tracker, posée par un modèle :
  Rien, Repos, 0 €). Pour un tracker « tous les jours », elle permet de
  compter les jours « avec » (« 18 jours d'études sur 30 notés ») ; pour un
  tracker « seulement quand », elle compte comme une case vide. Un perso
  n'en a pas : c'est le remplissage « seulement quand » qui joue ce rôle.
- **L'estimation de la prochaine fois** : un interrupteur de tout tracker
  « seulement quand » (voir « Le rythme »).
- **Le modèle d'origine** : donne des phrases écrites pour lui tant que la
  légende garde sa forme (voir « Un modèle qu'on modifie »).

Les quatre combinaisons des deux premiers réglages :

| | Du plus au moins | Des sortes différentes |
|---|---|---|
| **Tous les jours** | niveau du mois, tendance, jours de la semaine, liens (Humeur, Sommeil, Énergie, Dépenses) | combien de fois chaque couleur, son jour préféré, son rythme (Émotions, Télétravail / Bureau / Congé) |
| **Seulement quand** | combien de fois, depuis la dernière fois, rythme, intensité habituelle, estimation (Migraine, Cycle, Lecture les soirs de lecture) | combien de fois, depuis la dernière fois, rythme et jour préféré de chaque couleur (Sport les jours de sport, Ménage) |

Tant que l'ordre n'a pas été demandé (une seule couleur, ou un tracker
ancien qui n'a pas répondu), le tracker est compté comme « des sortes
différentes ». L'ordre de l'échelle est la position dans la légende
(`legends.position`) : la première couleur dans l'échelle est le niveau le
plus haut. « Plus haut » ne veut jamais dire « mieux » : les phrases disent
« monte », « plus haut », jamais « meilleur ».

**Rien n'est définitif** (règle de Charles, 2026-11-24). Chaque réglage se
change à tout moment dans les réglages du tracker, y compris les réponses
données une seule fois (création, 2ᵉ couleur, filet de sécurité, trackers
existants). Les stats se recalculent aussitôt : rien n'est stocké.

## La création

Histoires 1 (Sommeil), 3 (Énergie), 4 (Sport), 5 (Migraine).
`_CreateTrackerDialog` (`flutter_app/lib/screens/page_list_screen.dart`) ne
demande aujourd'hui qu'un nom. Elle devient :

1. **Partir d'un modèle** : une rangée de puces (le nom et trois points de
   sa palette). Toucher un modèle ouvre sa **fiche** :
   - le nom, modifiable ;
   - la légende, prête, avec HAUT, BAS et À PART marqués si ses couleurs
     vont du plus au moins ;
   - une ligne d'usage quand il en faut une (Sommeil : « Arrondi à l'heure
     la plus proche. On colorie le jour du réveil. ») ;
   - « Vous le coloriez… » et « Rappel » (Non / Matin / Soir), préremplis
     et modifiables ; sous le rappel, « Matin 9 h 00, soir 20 h 30 (dans
     Réglages › Rappels) » ;
   - pour Cycle, l'interrupteur « Estimer les prochaines règles », activé ;
   - un encadré « Ses stats : … » ;
   - les boutons « ‹ Modèles » et « Créer ». On peut créer sans rien
     toucher.
2. **Ou un tracker perso** : le champ du nom. Dès qu'un nom est tapé, la
   question apparaît, **« Vous allez le colorier… »** :
   - « Tous les jours, même les jours sans » (« Une case vide = pas encore
     noté · rappel le soir ») ;
   - « Seulement les jours où ça arrive » (« Une case vide = rien ce
     jour-là · pas de rappel »).

   Rien n'est présélectionné ; « Créer » attend une réponse. Dessous :
   « Modifiable à tout moment dans les réglages du tracker. »
3. **Un nom qui est celui d'un modèle**, dans une des quatre langues, sans
   tenir compte de la casse ni des accents (« sport ») : l'app le propose
   sous le champ (« « Sport » est aussi un modèle (Séance, Un peu, Repos,
   Malade). PRENDRE »). La personne peut l'ignorer et garder son perso.
4. La limite gratuite ne change pas : en gratuit, « + » ouvre le mur du 4ᵉ
   tracker au lieu de la fenêtre.

**Après « Créer »**, un modèle ouvre le tracker, légende comprise. Un perso
ouvre **directement sa légende**, vide, avec en haut des légendes **toutes
prêtes, en un geste** : « Oui · Un peu · Non », « Beaucoup · Un peu ·
Rien », « Une seule couleur » (au nom du tracker) ; puis « Ou vos
couleurs » (la palette et le champ d'ajout). Les deux premières vont du plus
au moins sans question. Ce sont des points de départ, pas des modèles : pas
de phrases à elles, pas de couleur « rien ». Aujourd'hui un perso s'ouvre
sans légende (« Ajoute des légendes pour commencer ») et rien ne dit que
l'ordre compte.

**Le parcours du premier tracker** (`first_tracker_screen.dart`) ne pose
pas de question, pour ne pas freiner le premier geste : ses tuiles sont des
modèles (avec leurs nouveaux libellés et leurs réglages), et « Autre… »
(Oui / Un peu / Non) crée un tracker « tous les jours, du plus au moins »,
sans modèle, rappel le soir. *Mon choix* : la même liste de modèles qu'avec
« + » ; si la grille de l'accueil ne tient plus sur un petit écran,
l'accueil garde ses six tuiles et les nouveaux modèles n'apparaissent que
dans « + ».

## Les modèles

Planche « Les neuf modèles ». Des libellés où l'on ne peut pas hésiter :
une heure, un montant, un mot net.

| Modèle | Légende, du haut vers le bas | Remplissage · ordre · rappel | À part | « Rien » | Sur la fiche |
|---|---|---|---|---|---|
| Humeur | Génial, Super, Bien, Bof, Mou | tous les jours · du plus au moins · soir | — | — | — |
| Sommeil (libellés changés) | 9 h et +, 8 h, 7 h, 6 h, 5 h et − | tous les jours · du plus au moins · **matin** | — | — | « Arrondi à l'heure la plus proche. On colorie le jour du réveil. » |
| Sport (changés) | Séance, Un peu, Repos, Malade | tous les jours · du plus au moins · soir | Repos, Malade | Repos | — |
| Lecture (changés) | 1 h et +, 30 min, 15 min, Rien | tous les jours · du plus au moins · soir | — | Rien | « Arrondi au plus proche. » |
| Habitudes (changés) | Fait, À moitié, Repos, Raté | tous les jours · du plus au moins · soir | Repos | Repos | — |
| **Cycle** (nouveau) | Abondantes, Moyennes, Légères | seulement quand · du plus au moins · non ; estimation activée | — | — | « Ni avis médical, ni contraception. » |
| **Études** (nouveau) | 3 h et +, 2 h, 1 h, 30 min, Rien | tous les jours · du plus au moins · soir | — | Rien | « Arrondi au plus proche. » |
| **Dépenses** (nouveau) | 100 € et +, 30–99 €, 10–29 €, 1–9 €, 0 € | tous les jours · du plus au moins · soir | — | 0 € | « Sans les centimes. » |
| **Émotions** (nouveau) | Joie, Calme, Fatigue, Stress, Tristesse | tous les jours · sortes différentes · soir | — | — | — |

Ce qui a changé et pourquoi : avec « 7–8 h » et « 6–7 h », une nuit de 7 h
tombait dans deux cases, et rien ne disait quel jour colorier ; « Presque »
et « Un peu » se confondaient ; 30 € tombait dans deux tranches ; Cycle
mêlait règles et douleurs alors qu'une case n'a qu'une couleur (une case de
Cycle = une intensité de règles ; les douleurs se suivent dans un autre
tracker). Humeur, Émotions et Études passaient sans hésitation.

- Les nouveaux modèles viennent des trackers que les gens créent eux-mêmes
  en prod (Study, Money, Cry, des humeurs en catégories).
- Libellés à écrire dans les quatre langues de l'app (en, fr, zh-CN,
  zh-TW) ; « € » suit la devise de la langue ou devient neutre, au choix du
  constructeur.
- Couleurs : les modèles existants gardent les leurs (épingles Pinterest,
  écran du premier tracker, visuels marketing) ; les nouveaux modèles en
  échelle ont une seule teinte, du clair au foncé, jamais un vert « bien »
  et un rouge « mal ». Les stats dessinent avec les couleurs de la légende
  et n'ajoutent jamais leur propre rouge ou vert.
- Les trackers déjà créés gardent leurs anciens libellés ; ils sont
  reconnus avec les anciens comme avec les nouveaux (voir « Les trackers
  déjà créés »). *Mon choix* : **l'ancienne légende d'un modèle (celle de
  l'app 1.4.0, dans une des quatre langues) est une forme du modèle**, au
  même titre que la nouvelle. Un Sport, des Habitudes ou une Lecture
  reconnus gardent donc « Modèle Sport · ses phrases restent », sans
  avertissement ; l'avertissement n'apparaît que si la légende quitte une
  forme reconnue. Avec une ancienne légende, les phrases qui ont besoin
  d'une valeur parlent en libellés (Sommeil en tranches, « 7–8 h ou
  plus » ; Lecture avec « Quelques pages »). Chaque modèle décrit donc ses
  formes : la nouvelle, et l'ancienne avec la correspondance de ses places
  (Fait → Séance, Presque → Un peu…).
- **Les valeurs des libellés**, pour dire une moyenne dans l'unité du
  modèle : Sommeil 9 h et + = 9 h, 8 h, 7 h, 6 h, 5 h et − = 5 h ; Lecture
  1 h et + = 60 min, 30, 15, Rien = 0 ; Études 3 h et + = 3 h, 2 h, 1 h,
  30 min, Rien = 0. Un « et + » compte pour sa borne : la phrase dit
  « environ ». *Mon choix* : **pas de moyenne en euros pour Dépenses** (des
  tranches de 30 à 99 € pourraient la tromper du simple au double) ; son
  niveau se dit en libellés, avec les comptes, comme un perso, et ses
  phrases à lui portent sur les jours à 0 €.

### Un modèle qu'on modifie

Histoire 6. Tout reste modifiable ; seules les phrases changent, et pas pour
toujours.

- **Renommer ou recolorer une couleur, changer le remplissage, le rappel ou
  l'estimation** : le modèle garde ses phrases. Un Cycle dont « Abondantes »
  devient « Fortes » reste le modèle Cycle.
- **Changer l'ordre** (glisser, « Inverser l'ordre », passer en « sortes
  différentes »), **ajouter ou retirer une couleur**, **mettre une couleur à
  part ou la remettre dans l'échelle** : la légende n'a plus la forme du
  modèle. Un avertissement d'une ligne le dit dans la légende, sans rien
  bloquer : « Cycle n'a plus la légende du modèle : mêmes calculs et même
  estimation, avec des phrases plus générales. Retirer « Traces » ramène
  celles du modèle. » Les calculs ne changent pas ; la page Stats passe au
  badge « Tracker perso, depuis le modèle Cycle ».
- **Réversible** : le modèle d'origine (`pages.template`) n'est jamais
  effacé. Dès que la légende retrouve la forme du modèle, ses phrases
  reviennent.
- *Mon choix* pour reconnaître la forme : chaque couleur créée par un
  modèle garde sa place dans le modèle (`legends.template_slot`) ; la
  légende a la forme du modèle quand elle contient exactement ces places,
  dans cet ordre, avec les mêmes couleurs à part, et le même réglage
  d'ordre. Une couleur supprimée puis recréée n'a plus de place : la forme
  ne revient pas (limite acceptée ; le constructeur peut retrouver la place
  par le libellé).
- L'estimation, la couleur « rien » et les couleurs à part ne dépendent pas
  des phrases : elles restent quand le modèle perd sa forme.

## La légende

Histoires 3 à 7. `LegendEditorDialog` gagne :

- **La question de la 2ᵉ couleur.** Quand la légende a au moins deux
  couleurs et que l'ordre n'a jamais été réglé (`pages.scale` vide), une
  carte s'affiche sous la liste : « Haute, Bonne : ces couleurs vont… »
  (ses deux premiers libellés), « Du plus au moins » (« comme Forte →
  Moyenne → Légère ») ou « Des sortes différentes » (« comme Course, Muscu,
  Yoga »), et « Modifiable à tout moment dans les réglages du tracker. »
  Elle reste là, à chaque ouverture, tant qu'on n'a pas répondu ; une
  réponse la fait disparaître pour de bon. Un modèle ou une légende prête
  ne la posent pas.
- **Du plus au moins** : HAUT sur la première couleur de l'échelle, BAS sur
  la dernière, À PART sur une couleur hors échelle ; sur chaque ligne, une
  puce « dans l'échelle » / « hors échelle » qui se touche pour basculer ;
  on glisse pour ranger ; un bouton **« ⇅ Inverser l'ordre »** retourne la
  liste. Une échelle rangée à l'envers retournerait toutes les phrases
  (« monte » au lieu de « baisse ») : d'où les repères.
- **L'avertissement d'un modèle qui change de forme** (voir « Un modèle
  qu'on modifie »).

*À vérifier par le constructeur* : la légende accepte-t-elle deux couleurs
identiques ? Une case ne garde que sa couleur (`cells.color`) ; le lien vers
la légende se fait par la couleur : quand une couleur de légende change,
c'est l'app qui recolore les cases par un appel à part
(`CellsProvider.recolorCells`, diffusé en `cells:recolored`). Deux couleurs
identiques rendraient une case ambiguë, et un recoloriage les fusionnerait
sans le dire : à interdire dans l'éditeur. Une case dont la couleur n'est
plus dans la légende compte comme « sans légende » : visible dans les
comptes de jours remplis, jamais dans un niveau ni un rythme.

## Les réglages du tracker

Histoires 2, 6 et 7. Un nouveau panneau, ouvert par une roue dans la barre
du haut du tracker (aujourd'hui : retour, titre à toucher pour renommer,
icônes stats et export ; l'emplacement exact revient au constructeur). Dans
l'ordre :

- le badge : « Modèle Lecture · ses phrases restent », « Tracker perso »,
  ou « Tracker perso, depuis le modèle Cycle » ;
- le nom (renommer en touchant le titre reste possible) ;
- la légende : ses pastilles et « Modifier la légende › » ;
- « Vous le coloriez… » : « Tous les jours » / « Seulement quand ça
  arrive », avec dessous « Case vide = pas encore noté » ou « Case vide =
  rien ce jour-là » ;
- « Ses couleurs vont… » : « Du plus au moins » / « Des sortes
  différentes », dès deux couleurs ;
- « Rappel » : Non / Matin / Soir ;
- « Estimer la prochaine fois » (Cycle : « Estimer les prochaines
  règles »), pour un tracker « seulement quand » ;
- « Tout se change à tout moment ; les stats se recalculent aussitôt. »,
  puis « Fermer ».

Règles :

- Passer à « Du plus au moins » un tracker qui a déjà des cases ouvre la
  légende avec la vérification de l'ordre (voir « Les trackers déjà
  créés »).
- *Mon choix* : passer à « Seulement quand ça arrive » met le rappel sur
  Non s'il était réglé (il sonnerait les jours sans) ; le changement se
  voit dans le panneau et se défait d'un geste. Le chemin inverse ne remet
  pas de rappel tout seul.
- Si les rappels ne sont pas encore sortis, la ligne « Rappel » reste
  cachée (voir « Découpage »).

## Le filet de sécurité

Histoire 2 (Lecture). Le cas vu en prod : un modèle prérempli « tous les
jours », ou un perso pour lequel la personne a répondu trop vite, mais
colorié seulement les jours où ça arrive. Sans rien faire, les stats
seraient fausses (« Lecture : le plus souvent 30 min » alors qu'on lit deux
soirs par semaine) et le rappel du soir relancerait chaque soir pour rien.

- **Quand** : un tracker réglé « tous les jours » (pas « jamais demandé » :
  ceux-là ont la carte des trackers existants) qui existe depuis au moins
  21 jours, a au moins 3 cases sur les 21 derniers jours, et reste vide au
  moins 7 de ces jours où la personne colorie un autre tracker. (Le minimum
  de 3 cases écarte un tracker abandonné, qui n'est pas ce cas.)
- **Où** : une carte en haut de la page Stats du tracker, « Une question,
  une fois » : « Lecture reste vide certains jours où vous coloriez Humeur
  (9 jours en 3 semaines). Une case vide sur Lecture, ça veut dire… »
  - « Pas encore noté » (« Je remplirai plus tard : ces jours ne comptent
    pas ») ;
  - « Rien ce jour-là » (« Les stats comptent les fois ») ; un modèle a ses
    mots (Lecture : « Pas lu ce jour-là »).

  « Modifiable à tout moment dans les réglages du tracker. »
- **Effet** : « Rien ce jour-là » passe le tracker en « seulement quand »
  et met son rappel sur Non. « Pas encore noté » ne change rien. Les deux
  réglages se changent ensuite dans les réglages du tracker, où le panneau
  les montre en surbrillance juste après la réponse.
- **Une fois** : la carte reste en haut tant qu'on n'a pas répondu ; une
  réponse, quelle qu'elle soit, ne la fait plus revenir pour ce tracker.
  Elle n'apparaît pas non plus pour un tracker dont le remplissage a déjà
  été confirmé (carte des trackers existants, ou changement dans les
  réglages). La réponse est enregistrée avec le tracker, pour qu'un autre
  appareil ne la repose pas (*mon choix*, voir « Données »).

## Les trackers déjà créés

Histoire 7 (Pilule). Ils n'ont aucun réglage enregistré.

1. **Ceux qui viennent d'un modèle sont reconnus** (décidé, 2026-11-24) :
   même nombre de couleurs et mêmes libellés, dans l'ordre, que la légende
   d'un modèle, anciens ou nouveaux libellés, dans une des quatre langues
   (le titre est ignoré, souvent renommé). Ils reçoivent tout ce que le
   modèle règle : remplissage, ordre, couleurs à part, couleur « rien »,
   rappel (un Sommeil reconnu est rappelé le matin), places du modèle.
   « Autre… » (Oui / Un peu / Non) devient « tous les jours, du plus au
   moins », sans modèle. *Mon choix* : la reconnaissance se fait **sur le
   serveur**, par une seule fonction (les libellés des modèles y sont
   copiés depuis l'app), appelée deux fois : par une migration, une fois,
   pour les trackers existants ; et par `POST /api/pages` quand la
   création arrive sans les nouveaux champs, c'est-à-dire d'une app 1.4.0
   (par « + » ou par le parcours du premier tracker), qui continuera de
   créer des trackers après la mise à jour du serveur.
   Les anciennes légendes sont des formes des modèles (voir « Les
   modèles ») : un tracker reconnu garde ses phrases sans avertissement.
2. **Les autres** gardent un remplissage « jamais demandé »
   (`pages.cadence` vide), compté « tous les jours », un ordre non réglé
   (compté « sortes différentes ») et le rappel du soir. Les trackers créés
   par une app 1.4.0 et non reconnus sont dans le même cas. La page Stats
   leur pose **une fois**, en haut, sans rien bloquer, sous le titre « Pour des stats
   justes » : « Comment coloriez-vous Pilule ? » avec les deux réponses de
   la création, et « Plus tard ». Toucher une réponse la règle sur le
   serveur ; « Plus tard » est retenu sur l'appareil.
3. **Puis l'ordre**, si le tracker a au moins deux couleurs : la même carte
   enchaîne sur la question de la 2ᵉ couleur (« Prise, Oubliée : ces
   couleurs vont… »).
4. **Vérifier l'ordre avant d'en faire une échelle** (décidé, 2026-11-24).
   Ces légendes n'ont pas été rangées pour une échelle (des listes « 1…5 »
   avec le plus bas en premier, un Repos au milieu). Répondre « Du plus au
   moins » ouvre la légende avec ses repères HAUT / BAS, les puces « dans /
   hors échelle » et « Inverser l'ordre », sous une ligne « Vérifiez
   l'ordre : en haut, le niveau le plus haut. Fermer la légende vaut
   accord. » Même chose quand on passe à « Du plus au moins », dans les
   réglages, un tracker qui a déjà des cases.

Avec deux couleurs (Prise / Oubliée), « du plus au moins » et « sortes
différentes » donnent les mêmes comptes : aucune mauvaise réponse possible.

## Les stats

Calculées dans l'app à partir des cases, à la demande ; rien n'est stocké.

### Règles pour toutes les cartes

- Des comptes, toujours avec leur dénominateur (« 19 nuits sur 21 »), plutôt
  que des pourcentages seuls.
- Une case vide n'est jamais un niveau bas. Pour un tracker « tous les
  jours », elle ne compte pas ; pour un tracker « seulement quand », elle
  veut dire « rien ce jour-là », comme la couleur « rien » d'un modèle.
  Les jours d'un tracker « seulement quand » comptent à partir de sa
  création, ou de sa première case si elle est plus ancienne (rattrapages).
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
  données d'exemple fictives (pas celles de la personne), marquée
  « Exemple » (histoire 9). Le paywall ouvert depuis les stats montre aussi
  des cartes d'exemple. *Mon choix* : elles se construisent avec le lot 2
  des stats, pas avec la refonte du paywall (chantier 2, avant le Nouvel
  An) ; le mur `global_stats` n'en a pas.
- Aucune stat ne part en notification.
- Les phrases d'un perso ne doivent pas dépendre du genre ni du nombre des
  mots de l'utilisateur, ni de l'élision (« de Sommeil », « d'Énergie ») :
  des tournures du type « Énergie, le dimanche : Haute ou Bonne 11 fois sur
  12 ». Même contrainte en anglais et en chinois.

### Les cartes

Planche « Gratuit, Premium et seuils ». « Jours notés » = cases remplies du
tracker.

| Carte | Pour | Seuil | Accès | Exemple |
|---|---|---|---|---|
| Chiffres du tracker | tous | aucun | gratuit | tous les jours : jours notés, série, % de l'année ; seulement quand : « 6 fois · depuis 12 j » |
| Depuis la dernière fois | chaque couleur | 1 fois | gratuit | « Course : il y a 8 jours » |
| **Ce mois-ci comparé au mois dernier** (la stat offerte) | tous | tous les jours : 7 jours notés dans chacun des deux mois (sinon le mois seul) ; seulement quand : aucun | gratuit | du plus au moins : « 8 h ou plus : 19 nuits sur 21 en novembre, contre 14 sur 27 en octobre » ; sortes : les comptes de chaque couleur, mois contre mois ; seulement quand : « Novembre (jusqu'au 23) : 16 soirs de lecture. Octobre : 14. » |
| Annonce d'un lien | tous | celui du lien | gratuit (l'existence) | « Un lien apparaît entre Sommeil et Humeur » |
| Ce jour-là, l'an dernier | tous | un an d'historique | gratuit | — |
| Niveau du mois, avec la répartition | tous les jours · du plus au moins | 7 jours notés dans le mois | Premium | perso : « Novembre : entre Haute et Bonne, plus près de Bonne · sur 21 jours » ; Sommeil : « 8 h 10 par nuit en moyenne » |
| Tendance | tous les jours · du plus au moins | deux mois d'au moins 7 jours notés | Premium | « Depuis septembre, vos nuits ont pris 1 h 35 » |
| Combien de fois, et à quel niveau | seulement quand ; tous les jours avec une couleur « rien » | 1 mois | Premium | « 16 soirs de lecture en novembre, sur 23 jours · le plus souvent 15 min (17 fois), puis 30 min (16 fois) » ; Sport : « 2,6 jours de sport par semaine » |
| Intensité habituelle | seulement quand · du plus au moins | 3 fois | Premium | « Moyenne (Forte 2, Moyenne 3, Légère 1) » |
| Mois par mois (barres, part de chaque couleur) | tous | aucun | Premium | « pas noté » visible pour « tous les jours » |
| Jour de la semaine | tous | graphique tout de suite ; phrase : seuils des liens | Premium | « Course revient surtout le dimanche : 7 de vos 15 Course » |
| Rythme : écart habituel, durée habituelle, plus longue période sans | chaque couleur ; le sujet pour « seulement quand » | 3 écarts (4 fois) | Premium | « En général un soir de lecture tous les 2 jours (de 1 à 6 jours, 33 écarts) » |
| Prochaine fois, probablement | seulement quand, estimation activée, rythme régulier | 3 écarts réguliers | Premium | « Entre le 28 nov. et le 3 déc. » |
| Liens avec les autres trackers (le même jour) | au moins un des deux « du plus au moins » | 30 jours en commun, 10 par groupe, test corrigé | Premium | « Les jours où vos nuits font 8 h ou plus, votre Humeur est Génial ou Super 29 fois sur 37 ; les autres jours, 9 fois sur 33. Ce n'est pas une preuve de cause. » |

Le « haut de l'échelle » des phrases (« 8 h ou plus », « Haute ou Bonne »)
est la moitié haute des niveaux dans l'échelle (couleurs à part exclues),
arrondie vers le bas : 2 niveaux sur 5 ou 4, 1 sur 3 ou 2. Les sortes
différentes n'ont pas de total « jours actifs » : l'app ne sait pas que
Repos n'est pas une activité (seul un modèle le sait, par sa couleur
« rien »).

Le niveau moyen numérote les niveaux de l'échelle (1 en bas) et le dit en
mots, placé entre deux libellés, toujours avec la répartition à côté pour
que les extrêmes ne disparaissent pas. Un modèle en heures ou en montants le
dit dans son unité (Sommeil : 9 h et + compte 9, 5 h et − compte 5, arrondi
à 5 minutes : « 8 h 10 »). *Mon choix* pour la tendance : une phrase
seulement quand le libellé le plus proche change entre deux mois d'au moins
7 jours notés chacun ; le constructeur peut durcir la règle.

L'ordre des cartes sur la page Stats, par combinaison : celui des étapes
« 3 mois plus tard » des histoires 1 à 7.

### Le rythme

**Le sujet** du rythme est une couleur ou un groupe de couleurs.

- Tracker « seulement quand » : sujet par défaut, le tracker entier sans ses
  couleurs à part ni sa couleur « rien » (Migraine : Forte, Moyenne et
  Légère ensemble ; Cycle : ses trois intensités ; un Cycle auquel on a
  ajouté « Traces », mise à part : sans Traces). La carte a un sélecteur
  « Rythme de … » ; le sujet choisi est enregistré avec le tracker
  (`pages.rhythm_legend_id`, vide = le défaut ; un id de légende, pas une
  couleur, qui change au recoloriage).
- Tracker « tous les jours » : le rythme de chaque couleur, dans la carte
  « Chaque couleur » ; avec une couleur « rien », aussi celui des jours
  « avec » (Lecture tous les jours : un soir de lecture tous les 2 jours).
  Jamais le tracker entier, qui ne serait que le remplissage.

**Un épisode** du sujet : une suite de jours consécutifs du sujet. *Mon
choix* : un seul jour sans entre deux suites ne coupe pas l'épisode quand
l'écart habituel entre deux suites est d'au moins 6 jours (Cycle,
Migraine : un jour de règles non noté au milieu ne fait pas deux épisodes) ;
en dessous (Lecture, Sport, un jour sur deux ou trois), chaque suite est un
épisode, sinon « un soir sur deux » deviendrait un seul long épisode. (La
première version fusionnait toujours à un jour près : faux pour Lecture.)

**L'unité** : un tracker dont l'écart habituel entre suites est d'au moins
6 jours parle en **fois** (épisodes, comptés au mois de leur début :
« Novembre : 1 fois. Octobre : 2 fois. ») ; les autres parlent en **jours**
(« 16 soirs de lecture », « 41 jours de sport »). Avant 3 écarts, en jours,
sauf le modèle Cycle, toujours en fois. Avec une échelle, l'intensité d'un
épisode est son niveau le plus haut.

D'après la recherche (méthode de drip, Li et al.) :

- écart habituel = médiane des six derniers écarts entre débuts d'épisode ;
  il en faut au moins 3 ;
- un écart de plus de 1,7 fois la médiane des autres est grisé (« sans
  doute un mois non noté »), ignoré, avec un bouton « Le compter » ;
- **estimation de la prochaine fois** : un réglage de **tout** tracker
  « seulement quand » (`pages.estimate`), activé par défaut pour le modèle
  Cycle seulement, dans les réglages du tracker et sur la carte. Elle ne
  dépend pas du modèle : un Cycle devenu perso la garde. Il faut au moins
  3 écarts retenus et un écart le plus long moins l'écart le plus court
  ≤ un tiers de la médiane. La fenêtre va du dernier début plus l'écart le
  plus court au dernier début plus le plus long ; elle s'affiche aussi en
  contour pointillé dans la grille et dans la bande « Les 60 derniers jours
  et la suite » de la carte. Sinon : « Pas d'estimation : le rythme est
  trop irrégulier (de 9 à 22 jours entre deux fois). » Mention fixe : ni
  avis médical ni méthode de contraception.

### La période

*Mon choix* :

- Les cartes du mois et de l'année (chiffres du tracker, niveau du mois,
  ce mois-ci comparé au mois dernier, combien de fois, mois par mois)
  suivent le calendrier de l'année affichée. En janvier, « le mois
  dernier » est décembre de l'année d'avant.
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

- Le même jour seulement. Paires : du plus au moins × du plus au moins, et
  couleur × du plus au moins. Un tracker « seulement quand » compte comme
  une couleur : les jours où il est colorié contre les autres jours (« Les
  jours de sport, Énergie est Haute ou Bonne 31 fois sur 40 ; les autres
  jours, 22 fois sur 51 »).
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

Chaque modèle a ses phrases (« vos nuits ont pris 1 h 35 », « vous lisez
surtout le week-end », « vos jours sans dépense tombent surtout le
dimanche ») et parfois une carte à lui : les nuits de 5 h ou moins comptées
à part pour Sommeil (une moyenne les cacherait), la plus longue suite sans
Repos pour Sport et Habitudes, les prochaines règles pour Cycle. Les calculs
sont ceux de la combinaison. Un modèle a des phrases pour ses deux
remplissages possibles (Lecture « tous les jours » ou « seulement
quand »). La page Stats dit sous son titre d'où viennent les mots : « Modèle
Sommeil · phrases écrites pour lui », « Tracker perso · phrases avec ses
libellés ». La liste des phrases, dans les quatre langues, revient au
constructeur.

## Les écrans

- **Page Stats d'un tracker** (remplace `StatsDetailDialog`), ouverte depuis
  le bandeau du tracker, **pour tous** : aujourd'hui le gratuit tombe
  directement sur le mur `stats`. En gratuit : les cartes gratuites,
  l'annonce d'un lien, la liste nommée (pas floutée) de ce que Premium
  ajoute, sur ses propres données (« Votre nuit moyenne, mois par mois · en
  heures, depuis le 24 août »), et le bouton « Voir toutes mes stats » qui
  ouvre le paywall (événement `paywall.stats`, inchangé). En haut, selon le
  cas : la carte des trackers existants ou le filet de sécurité.
- **Bandeau du tracker** : inchangé pour « tous les jours » (jours, série,
  % de l'année) ; « N fois · depuis X j » pour « seulement quand », où la
  série n'a pas de sens.
- **Barre du haut du tracker** : la roue des réglages.
- **Grille** : mise en avant des jours d'une phrase ; contour de la fenêtre
  probable.
- **Pop-up « stats prêtes »** : la première stat Premium prête, dévoilée
  une fois (chantier 6, `2026-11-23-premium-popup-design.md`) ; elle
  remplace les jalons `days_7` et `days_30`.
- `GlobalStatsDialog` (mur `global_stats`) : inchangé dans ce chantier.

## Données et serveur

Noms exacts au constructeur.

| Champ | Valeurs | Défaut | Rôle |
|---|---|---|---|
| `pages.cadence` | `'daily'` / `'occasional'`, nullable | null pour un tracker ancien ou créé par une app 1.4.0 ; posé à la création par l'app à jour | le remplissage ; partagé avec la spec des rappels ; null = jamais demandé, compté « tous les jours » |
| `pages.scale` | booléen, nullable | null | l'ordre des couleurs ; null = pas encore demandé, compté « sortes différentes » |
| `pages.reminder` | `'none'` / `'morning'` / `'evening'` | selon le remplissage et le modèle | le moment du rappel (spec des rappels) |
| `pages.template` | id du modèle, nullable | null | le modèle d'origine, jamais effacé |
| `pages.estimate` | booléen | faux (vrai pour Cycle) | l'estimation de la prochaine fois |
| `pages.rhythm_legend_id` | id de légende, nullable | null | le sujet du rythme choisi |
| `pages.fill_confirmed_at` | date, nullable | null | le remplissage a été confirmé (carte des trackers existants, filet de sécurité, ou changement dans les réglages) ; pas posé par la création |
| `legends.in_scale` | booléen | vrai | faux = à part |
| `legends.nothing` | booléen | faux | la couleur « rien » d'un modèle, au plus une par tracker |
| `legends.template_slot` | entier, nullable | null | la place de la couleur dans son modèle |

- Renvoyés par le bootstrap et les routes des pages et des légendes,
  acceptés à la création et à la mise à jour, diffusés par les événements de
  synchro. Le bootstrap liste les colonnes des légendes une à une : y
  ajouter les nouvelles. Les clients 1.4.0 ne connaissent pas ces champs : vérifier qu'ils
  les ignorent et qu'une mise à jour faite par eux (titre, position,
  légende) ne les remet pas à zéro.
- La création depuis un modèle crée le tracker et sa légende comme le
  parcours du premier tracker (idempotence par `clientId`).
- Événements produit (table `events`, nom seul) : *mon choix*
  `tracker_created.template.<id>`, `tracker_created.custom.<daily|occasional>`,
  `tracker.order_answered.<scale|kinds>`, `tracker.template_left.<id>` (la
  légende d'un modèle perd sa forme), `stats.form_answered` (trackers
  existants), `stats.safety_net.<daily|occasional>` (réponse au filet de
  sécurité) : pour savoir quels modèles servent, s'ils tiennent, et si le
  filet attrape des cas. Sous le même intérêt légitime que les autres
  événements produit (registre, politique de confidentialité).

## Découpage

**Décidé (Charles, 2026-11-24)** pour l'ordre : le lot 1 passe **avant les
rappels** (en janvier, après l'outillage Android, dont il ne dépend pas), et
sort dans la même version de l'app qu'eux ou juste avant. Les rappels ne
construisent ni question de remplissage ni réglage dans le tracker : la
question de création, la fiche des modèles et les réglages du tracker les
remplacent.

Le lot 1 sortira seul un temps (les lots 2 et 3 viennent après les
rappels). *Mon choix* : rien de ce qu'il montre ne promet ce qui n'existe
pas encore. Restent cachés, avec leur valeur par défaut enregistrée :

- la ligne « Rappel » des fiches et des réglages, jusqu'aux rappels ;
- l'encadré « Ses stats : … » des fiches, jusqu'au lot 2 ;
- l'interrupteur « Estimer la prochaine fois » (fiche de Cycle, réglages),
  et les mots « et même estimation » de l'avertissement, jusqu'au lot 3.

1. **Lot 1 — réglages et création** : colonnes, migration et reconnaissance
   des trackers existants, fenêtre « Nouveau tracker » (modèles, fiches,
   question, proposition d'un modèle au nom tapé), légendes prêtes,
   question de la 2ᵉ couleur, repères HAUT / BAS / À PART et « Inverser
   l'ordre », réglages du tracker (roue), avertissement d'un modèle qui
   change de forme, bandeau selon le remplissage, nouveaux libellés et
   quatre nouveaux modèles. Le bandeau « N fois » a besoin des **épisodes
   et de l'unité** (« Le rythme ») : leur calcul, une fonction pure testée,
   arrive donc dès le lot 1 (sinon un Cycle dirait « 25 fois » pour cinq
   règles).
2. **Lot 2 — page Stats** : cartes gratuites et Premium des quatre
   combinaisons, seuils et progression, cartes d'exemple (page Stats et
   paywall ouvert depuis les stats), mise en avant dans la grille, carte
   des trackers existants, filet de sécurité.
3. **Lot 3 — estimation et liens** : estimation, contour dans la grille et
   bande des 60 jours, liens entre trackers avec leurs tests. Le rythme
   (écart habituel, durée, plus longue période sans) est dans le lot 2.
4. **Plus tard** : le bilan de l'année (carte gratuite à partager, bilan
   complet en Premium ; maquette « Bilan » de l'ancienne page), pour fin
   2027 au plus tôt (pas de bilan pour le Nouvel An 2026, décidé le
   2026-11-23).

Limite connue entre le lot 1 et le lot 2 : sans le filet de sécurité, un
tracker « tous les jours » colorié seulement les jours où ça arrive reçoit
le rappel du soir ; la personne le corrige dans les réglages du tracker.

La pop-up premium (chantier 6) attend le lot 2 : son déclencheur « stats
prêtes » a besoin des cartes ; celui du premier lien attend le lot 3.

## Écarts avec les maquettes

- « Ce jour-là, l'an dernier » n'est pas dessiné ; la carte reste.
- La carte des trackers existants a un « Plus tard », le filet de sécurité
  non : il reste en haut tant qu'on n'a pas répondu (voir ses règles).
- La roue est dessinée en haut à droite du tracker, sans les icônes stats et
  export de l'app : son emplacement revient au constructeur.
- Les phrases dessinées sont indicatives ; les règles de « Les stats » (pas
  de genre ni de nombre pour un perso, des comptes avec leur total)
  l'emportent.

## Questions closes

- Stats par forme, mêmes calculs pour un modèle et un perso (Charles,
  2026-11-23).
- **Décidé (Charles, 2026-11-24), première version, toujours valable** :
  une case garde une seule couleur (Course et Muscu le même jour :
  l'activité principale, ou une couleur « Course + Muscu ») ; les trackers
  existants reconnus quand ils viennent d'un modèle, sinon une question une
  fois sur la page Stats ; l'essai proposé dès le premier jour, avec des
  cartes « Exemple » ; le lot 1 avant les rappels ; et les six réponses de
  la relecture (ci-dessous).
- **Décidé (Charles, 2026-11-24), seconde version** (« fais selon tes
  recommandations », puis « c'est bon pour moi » sur les maquettes) :
  1. à la création, une seule question, sur l'habitude de remplissage ;
     l'ordre des couleurs demandé dans la légende, à la 2ᵉ couleur ;
  2. des libellés de modèles sans ambiguïté (tableau des modèles) ;
  3. le filet de sécurité pour les cases vides ;
  4. tout reste modifiable, rien n'est définitif : les réglages du
     tracker ; un modèle garde ses phrases tant que sa légende garde sa
     forme, et les retrouve si elle la retrouve ;
  5. l'estimation est un réglage de tout tracker « seulement quand » ;
  6. les rappels Non / Matin / Soir par tracker (spec des rappels) ;
  7. la pop-up « stats prêtes » à la place des jalons de jours (spec de la
     pop-up) ;
  8. les légendes prêtes en un geste, la proposition d'un modèle au nom
     tapé, une couleur « rien » par modèle, la même liste de modèles à
     l'accueil et dans « + », le bandeau selon le remplissage, pas de
     total « jours actifs » pour des sortes différentes.

## Laissé au constructeur

Les tests statistiques exacts, la règle fine de la tendance, les seuils
« 6 jours » des épisodes et « 7 sur 21 » du filet s'ils se révèlent mal
choisis, la liste des phrases et leurs traductions, les données d'exemple,
la mise en page et les animations des cartes, l'emplacement de la roue,
l'endroit exact de la reconnaissance des trackers existants (migration ou
app), la façon de retrouver la forme d'un modèle, les noms des colonnes et
des événements.

## Relecture du 2026-11-24

**Première version.** Relue comme un constructeur qui doit planifier sans
pouvoir poser de question. Six trous, réglés ; Charles a validé ces choix le
2026-11-24 (« valide l'ordre, fais comme tu recommandes ») :

1. ce que compte le rythme : un sujet par tracker (« Le rythme ») ;
2. la période de chaque carte : le calendrier pour les cartes du mois,
   12 mois glissants pour les cartes de fond (« La période ») ;
3. un tracker existant qui devient une échelle passe par une vérification
   de l'ordre (« Les trackers déjà créés ») ;
4. le lot 1 des stats avant les rappels (« Découpage ») ;
5. les cartes d'exemple du paywall avec le lot 2 des stats ;
6. les couleurs des modèles existants ne changent pas ; une seule teinte
   pour les nouveaux modèles en échelle.

Corrigé aussi : le recoloriage des cases est un appel de l'app
(`recolorCells`), pas un effet de `legends:recolored`.

**Seconde version**, en la réécrivant. Points réglés par le rédacteur
(*mon choix*, à discuter si mieux) :

1. Le sujet par défaut d'un tracker « seulement quand » exclut ses couleurs
   à part et sa couleur « rien » (Cycle a perdu « Règles » comme première
   couleur : ses trois couleurs sont des intensités).
2. La définition de l'épisode et l'unité (jours ou fois) dépendent de
   l'écart habituel, pour que Lecture et Sport ne deviennent pas un seul
   long épisode.
3. La forme d'un modèle se reconnaît par les places de ses couleurs
   (`legends.template_slot`).
4. Passer en « seulement quand » coupe le rappel, visiblement.
5. Le filet de sécurité ne se déclenche pas sur un tracker abandonné
   (3 cases au moins) ni après une confirmation (`pages.fill_confirmed_at`).
6. Un Sommeil aux anciens libellés parle en tranches.
7. Chaque modèle a des phrases pour ses deux remplissages.
8. Entre le lot 1 et le lot 2, le filet de sécurité manque : limite
   acceptée.

**Relecture de la seconde version**, comme un constructeur (2026-11-24).
Quatre trous, réglés dans le texte (*mon choix*) :

1. **Les lots et les « fois »** : les épisodes et l'unité passent au lot 1,
   pour le bandeau ; ce que le lot 1 montrerait sans pouvoir le tenir
   (estimation, encadré des stats, rappel) reste caché jusqu'à son lot.
2. **« Jamais demandé »** : `pages.cadence` devient nullable, pour
   distinguer un tracker ancien d'un tracker qui a répondu « tous les
   jours » ; la reconnaissance se fait sur le serveur, aussi pour les
   trackers créés par une app 1.4.0 après la mise à jour du serveur.
3. **Les anciennes légendes des modèles** sont des formes des modèles : un
   tracker existant garde ses phrases sans avertissement.
4. **Les valeurs des libellés** pour les moyennes en heures et en minutes ;
   pas de moyenne en euros pour Dépenses.

Vu aussi : l'éditeur de légende accepte aujourd'hui deux couleurs
identiques, et choisir la couleur d'une autre légende fusionne ses cases
sans le dire (`recolorCells`) : à interdire (« La légende »).
