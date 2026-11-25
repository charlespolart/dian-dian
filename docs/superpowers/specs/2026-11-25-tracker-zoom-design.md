# Voir un tracker par mois et par semaine — design (2026-11-25)

## Sources

- Demande de Charles le 2026-11-24 (`docs/ROADMAP.md` §11) : pouvoir
  « zoomer » sur un tracker pour voir un mois, voire une semaine, sans
  changer de vue par accident ; puis profiter de la place pour montrer plus,
  les commentaires d'abord.
- Page d'essai interactive, **version 2** :
  https://claude.ai/artifact/TonXNPhgKSxYvDwVet948j. Elle fait foi pour le
  chemin du zoom et le contenu des vues. Elle est en HTML pour sentir le
  geste au doigt ; dans l'app, tout se refait en Flutter. Ses réglages
  « ESSAI » n'existent pas dans l'app : les choix retenus sont écrits ici.
- Retours de Charles :
  - 2026-11-25, sur la version 1 : la vue Mois se fait **une ligne par
    jour**, pas en calendrier (« sinon la place n'est pas du tout
    optimisée ») ; le pincement « trop libre », qui suivait les doigts dans
    tous les sens alors que la cible était déjà choisie, est refusé : « il
    faut que le mouvement de zoom soit fluide du début à la fin. Il ne faut
    pas qu'on puisse bouger dans tous les sens. »
  - 2026-11-25, sur la version 2 : « c'est beaucoup mieux », longueur de
    pincement **Moyen** ; **pas** de barre repliée d'office dans les vues
    zoomées ; en revanche, plier et déplier la barre de gauche **d'un
    glissement**, dans les trois vues. Pas de maquette pour ce geste : il se
    fait directement dans l'app.

## Pourquoi

Un tracker ne se voit qu'à l'année (`TrackerGrid`, 12 colonnes de mois ×
31 jours). Les points sont petits et un commentaire n'apparaît que sous
forme de repère : pour le lire, il faut ouvrir le jour. Une vue plus proche
donne la place de lire ce qui s'est passé, sans perdre la vue d'ensemble
qui fait l'identité de l'app.

## Objectifs

- Trois niveaux : Année, Mois, Semaine.
- Changer de niveau seulement quand on le veut : jamais en coloriant, jamais
  en glissant d'un mois à l'autre.
- Un mouvement lisible et fluide du début à la fin, le même au doigt, au
  sélecteur et à la lettre d'un mois.
- Lire les commentaires : un aperçu par jour en vue Mois, en entier en vue
  Semaine.

## Non-objectifs

- Un zoom libre à n'importe quelle échelle, une vue Jour, un calendrier à
  7 colonnes.
- Des stats dans les vues zoomées (idées pour plus tard, en fin de
  document).
- Changer l'éditeur d'un jour : les vues zoomées ouvrent le même.

## Anti-objectifs

- Une vue qui change alors qu'on voulait colorier ou glisser.
- Une image qui part dans tous les sens pendant le geste.
- Une barre qui se plie ou se déplie toute seule.

## Approches

| Question | Retenu | Écarté, et pourquoi |
|---|---|---|
| Comment zoomer | **Trois niveaux fixes**, et un chemin fixe entre deux niveaux que le geste fait avancer | Zoom libre : on se perd entre deux échelles, et un niveau intermédiaire ne montre rien de plus |
| Quels moyens | **Sélecteur toujours visible + lettre du mois + pincement** en raccourci | Boutons seuls : le pincement est le premier geste qu'on essaie sur une grille. Double toucher : retarde chaque toucher (la grille se colorie au toucher). Appui long : déjà le geste de l'éditeur ailleurs, et lent. Glissement vertical : se confond avec le défilement |
| Le pincement | **Version 2** : les doigts règlent seulement jusqu'où le mouvement avance, sur un chemin fixe | Version 1 : l'image suivait les doigts (déplacement et échelle libres) puis basculait au lâcher ; refusée par Charles |
| La vue Mois | **Une ligne par jour** | Calendrier 7 colonnes : refusé par Charles, trop de place perdue |
| La barre de gauche | **Pliée ou dépliée à la main**, au chevron ou d'un glissement sur la barre, dans les trois vues | Pliée d'office en Mois et Semaine : refusé par Charles |

## Les niveaux et le sélecteur

- **Année** : la grille d'aujourd'hui, inchangée.
- **Mois** : une ligne par jour (section « La vue Mois »).
- **Semaine** : sept lignes hautes, du lundi au dimanche (section « La vue
  Semaine »).

**La période** (« 2026 », « NOVEMBRE 2026 », « 23 – 29 NOV. 2026 ») prend
la place de l'année dans la barre de gauche : même `SwipeNav`, mêmes flèches
‹ ›, même glissement de 40 px sur la ligne, qui passent maintenant à
l'année, au mois ou à la semaine d'avant ou d'après. Sur deux lignes si la
largeur l'exige (barre de 90 px sur téléphone). Barre pliée, la période
s'écrit à la verticale sans flèches, comme l'année aujourd'hui ; on change
alors de mois ou de semaine en glissant sur la grille.

Le **sélecteur** ANNÉE · MOIS · SEMAINE est toujours visible, dans la barre,
sous la période. Barre pliée (32 px), il se réduit à A · M · S. Le niveau
affiché est marqué comme les boutons actifs de l'app. Toucher un niveau lance
le chemin vers ce niveau (section « Le chemin du zoom »).

**Ouvrir un tracker** : il s'ouvre toujours sur l'année, comme aujourd'hui
(l'année choisie dans la liste, `_selectedYear`, ou `last_tracker_year` au
lancement), pour garder l'animation de la carte de la liste vers la grille
(`MorphAnchors.grid`, `screen_stage.dart`), qui atterrit sur la grille de
l'année. Le fermer depuis une vue Mois ou Semaine passe par le fondu qui
existe déjà quand la grille n'est pas là. *Mon choix*, après la relecture :
rouvrir au dernier niveau aurait perdu cette animation, ou demandé une
nouvelle animation de la carte vers le mois.

**L'année suit** : quand un mois ou une semaine passe dans une autre année
(flèches, glissement), l'année de la liste suit, comme avec les flèches
d'année aujourd'hui (`onYearChanged`, `last_tracker_year`).

## Entrer dans une vue, en sortir

| Geste | Vue Année | Vue Mois | Vue Semaine |
|---|---|---|---|
| Toucher une lettre de mois (J, F, M…) | ouvre ce mois | — | — |
| Sélecteur | va au niveau touché | idem | idem |
| Écarter deux doigts | ouvre le mois sous les doigts | ouvre la semaine sous les doigts | rien : « C'est la vue la plus proche » |
| Rapprocher deux doigts | rien : « C'est déjà toute l'année » | revient à l'année | revient au mois |
| Glisser un doigt à gauche ou à droite sur la grille | comme aujourd'hui | mois suivant ou précédent | semaine suivante ou précédente |
| Flèches ‹ › | année | mois | semaine |
| Bouton Aujourd'hui | passe à la période du jour au niveau affiché, puis ouvre l'éditeur du jour (comme aujourd'hui pour l'année) | idem | idem |

Un pincement change d'un seul niveau. Le sélecteur peut en sauter deux
(Année → Semaine) : il enchaîne les deux chemins en passant par le mois.

Le mois ouvert depuis l'année par le sélecteur est le dernier mois ouvert
dans cette année pendant la séance, sinon le mois d'aujourd'hui dans
l'année affichée (novembre 2024 si la liste montre 2024). La semaine ouverte
depuis le mois par le sélecteur est celle d'aujourd'hui si le mois affiché
est le mois en cours, sinon la première semaine du mois.

## Le chemin du zoom

C'est le cœur de la demande. Deux niveaux voisins sont reliés par **un seul
mouvement, toujours le même**, qu'une valeur `t` fait avancer : `t = 0`
montre le niveau large (Année, ou Mois), `t = 1` le niveau proche (Mois, ou
Semaine). Les doigts, le sélecteur et les lettres ne font que déplacer `t`
sur ce chemin.

### Au doigt

- **La cible est choisie au début du geste** et ne change plus : la colonne
  du mois sous le milieu des deux doigts en vue Année, la semaine de la ligne
  sous ce milieu en vue Mois. Elle s'éclaire (fond `accentSoft`, contour
  `accent`) dès que le chemin part vers elle, et cet éclairage s'efface vers
  `t = 0,4`.
- **Seul l'écart des doigts compte.** Le déplacement du milieu des doigts et
  la rotation sont ignorés : l'image ne glisse jamais sous les doigts.
- **Zone morte** : rien ne bouge tant que l'écart n'a pas changé de plus de
  5 %. Le sens (écarter ou rapprocher) se décide en sortant de cette zone.
- **Avancement** : `q = (|ln s| − ln 1,05) / (ln 2 − ln 1,05)`, borné entre
  0 et 1, où `s` est l'écart actuel divisé par l'écart du début. Le chemin
  est donc complet quand l'écart double (ou est divisé par deux) : c'est la
  longueur « Moyen » retenue par Charles. Au-delà, rien ne bouge plus : pas
  de dépassement.
- **Changer d'avis** : en revenant vers l'écart du début, la vue revient en
  arrière sur le même chemin. Si les doigts dépassent l'écart du début et la
  zone morte dans l'autre sens, le chemin inverse prend le relais, quand il
  existe (vue Mois : de « vers la semaine » à « vers l'année »).
- **Au lâcher** : passé la moitié (`q ≥ 0,5`), la vue finit seule ; sinon
  elle revient. Dans les deux cas elle repart de là où elle est, sans saut,
  en `120 + 280 × (distance restante)` ms, courbe décélérée
  (`Curves.easeOutCubic`).
- **Une étiquette** en haut de la grille dit ce qui va se passer : « Écartez
  encore : novembre » puis, passé la moitié, « Lâchez : novembre » (en
  couleur d'accent) ; « Rapprochez encore : l'année » puis « Lâchez :
  retour à l'année ». Pour la semaine : « semaine du 23 nov. » ; pour
  revenir au mois : « le mois ». Elle disparaît au lâcher.
- **Aux bouts** (écarter en vue Semaine, rapprocher en vue Année) : rien ne
  bouge, l'étiquette dit « C'est la vue la plus proche » ou « C'est déjà
  toute l'année », et reste un instant après le lâcher.
- Un deuxième doigt posé pendant un glissement annule le glissement et
  commence un pincement. Un doigt qui reste après un pincement ne fait rien
  jusqu'à ce que tous soient levés.

### Au sélecteur et à la lettre

Le même chemin, joué seul : `t` de 0 à 1 (ou de 1 à 0) en 440 ms, courbe
accélérée puis décélérée (`Curves.easeInOutCubic`). Deux niveaux d'un coup :
320 ms accélérées vers le mois, puis 320 ms décélérées vers la semaine. La
cible s'éclaire au départ comme au doigt.

### Ce qui bouge, de l'année au mois

Les éléments communs aux deux vues vont d'une place à l'autre ; le reste
s'efface ou apparaît autour d'eux.

- **La colonne du mois** glisse jusqu'à la colonne des points de la liste et
  grandit jusqu'à la hauteur d'une ligne : chaque point de la colonne arrive
  sur le point de son jour dans la liste, à la taille des points de la
  liste.
- **La colonne des numéros de jours** de la grille devient la colonne des
  numéros de la liste.
- **Les autres mois** s'écartent des deux côtés (poussés jusqu'à 60 % de la
  largeur à la fin) et s'effacent avant `t = 0,5`. La lettre du mois
  s'efface avant `t = 0,35`.
- **Les parties propres à la liste** (jour de la semaine, libellé, aperçu du
  commentaire, bandes du week-end et du jour, traits après les dimanches)
  apparaissent de `t = 0,45` à `t = 1`.
- **Les points communs** passent d'une vue à l'autre à la toute fin : ceux de
  la liste, posés au-dessus, apparaissent de 0,75 à 0,95, ceux de la grille
  s'effacent de 0,85 à 1. Pas de creux de couleur au milieu.
- **Les positions** suivent `p = 1 − (1 − t)²`, et les effacements suivent
  `t` : les points sont en place avant que le texte n'apparaisse.

### Ce qui bouge, du mois à la semaine

- **Chaque ligne du mois** va là où son jour se trouve dans la semaine, et
  grandit jusqu'à la taille des points de la semaine. Les lignes hors de la
  semaine continuent le même espacement : elles sortent par le haut et par
  le bas.
- Les lignes hors de la semaine s'effacent avant `t = 0,5` ; le texte des
  lignes de la semaine s'efface avant `t = 0,45`.
- **Les parties propres à la semaine** (jour, date, libellé, commentaire
  entier) apparaissent de 0,45 à 1. Les jours de la semaine qui tombent dans
  un autre mois (le 1ᵉʳ décembre dans la semaine du 30 novembre) n'ont pas
  de ligne de départ : leur point apparaît avec le texte.
- Points communs et positions : comme de l'année au mois.

### Pendant et après

- Les touchers sur la grille sont ignorés pendant qu'un chemin se joue seul
  (après le lâcher, au sélecteur).
- La période et le sélecteur prennent leur nouvelle valeur au moment où le
  changement est acquis : au lâcher passé la moitié, ou au toucher du
  sélecteur. Un pincement qui revient ne les change pas.
- **Réduire les animations** (réglage du système) : un fondu de 160 ms, sans
  déplacement, au doigt comme au bouton.
- *Pour la construction* : un `AnimationController` par chemin, dont le geste
  règle `value` et que le lâcher termine par `animateTo` ; les groupes qui
  bougent (colonnes, lignes) en `Transform`, ou dessinés dans un
  `CustomPainter` si la grille y passe (ROADMAP §5). Laissé au constructeur.

## Glisser d'un mois ou d'une semaine à l'autre

En vue Mois et Semaine, un doigt qui part de côté (plus horizontal que
vertical, au-delà de 9 px) tourne la page :

- la page suit le doigt, et la suivante (ou la précédente) arrive déjà à côté
  sous le doigt ;
- au lâcher, la page tourne si le doigt a parcouru plus de 30 % de la
  largeur, ou plus de 30 px avec un élan de plus de 0,35 px/ms dans ce sens
  (mesuré sur les 100 dernières ms) ; sinon elle revient ;
- pas de limite, comme pour les années aujourd'hui (navigation libre) ;
- un départ plutôt vertical ne fait rien : ni défilement, ni changement de
  vue.

En vue Année, le glissement sur la grille reste ce qu'il est aujourd'hui.

## La vue Mois

Une ligne par jour ; tous les jours du mois remplissent la hauteur de la
grille (hauteur d'une ligne = hauteur de la grille ÷ nombre de jours).

- **Colonnes** : numéro du jour, lettre du jour de la semaine (L M M J V S D,
  traduite), point, libellé de la couleur, aperçu du commentaire sur une
  ligne, coupé par « … ».
- **Repères** : bande `weekend` sur samedi et dimanche, trait pointillé après
  chaque dimanche, bande `accentSoft` sur le jour d'aujourd'hui, jours à
  venir à 45 % d'opacité. Pas de repère de commentaire : le commentaire se
  lit.
- **Tailles** tirées de la hauteur de ligne (page d'essai) : texte
  0,52 × ligne, borné à 9–13,5 px ; point 0,68 × ligne, borné à 9–18 px.
- **Toucher une ligne** fait ce que fait le toucher d'un point de la grille
  aujourd'hui : avec une couleur choisie dans la légende, un jour vide se
  colorie ; sinon l'éditeur du jour s'ouvre. Toute la ligne est la cible. Un
  jour à venir se comporte comme dans la grille aujourd'hui.
- Plier la barre donne sa largeur (58 px sur téléphone en portrait) à
  l'aperçu des commentaires. Charles a choisi de laisser ce choix à la main.

## La largeur

Aujourd'hui la coque (barre + grille) prend sa largeur du rapport 13 × 32
de la grille de l'année (`maxW = gridW + sidebarW + 50` en portrait ; en
paysage, calculée depuis la hauteur). Ce rapport n'a plus de sens pour une
liste. Règles (*mon choix*, après la relecture) :

- **en vue Mois et Semaine**, la coque prend toute la largeur disponible
  (en paysage : tout ce que laisse le panneau de gauche) ;
- **barre pliée en vue Mois ou Semaine**, la coque garde sa largeur et la
  grille gagne celle de la barre ; en vue Année, plier la barre fait ce
  qu'il fait aujourd'hui ;
- **sur le chemin entre l'année et le mois**, la largeur de la coque suit
  `t` (celle de l'année à 0, toute la largeur à 1), comme le reste du
  mouvement. Sur un téléphone en portrait, où la grille de l'année est
  presque toujours limitée par la largeur, l'écart est de quelques pixels.
  Les téléphones restent en portrait (`orientation_policy.dart`) : le
  paysage ne concerne que la tablette et le web.
- Le glissement de la barre pilote sa largeur au doigt : les
  `AnimatedContainer` qui la dimensionnent aujourd'hui laissent la place à
  une valeur suivie par le geste, puis animée au lâcher.

## La vue Semaine

Sept lignes de même hauteur, du lundi au dimanche (*mon choix* : lundi dans
toutes les langues, comme la grille ; à revoir si un utilisateur
anglophone le demande).

- **Par ligne** : jour abrégé (« LUN. ») et date en grand, plus le mois
  abrégé sur la première ligne et sur un 1ᵉʳ du mois ; le point
  (0,28 × hauteur de ligne, borné à 16–26 px) ; le libellé de la couleur en
  police pixel ; le commentaire entier, sur autant de lignes que la hauteur
  le permet.
- **Sans commentaire** : « + commentaire » en gris pour un jour colorié,
  « Toucher pour colorier » pour un jour passé vide, rien pour un jour à
  venir.
- Une semaine à cheval sur deux mois ou deux années se montre entière ; la
  période l'écrit (« 30 NOV. – 6 DÉC. 2026 »).
- Toucher une ligne : comme en vue Mois.

## La barre de gauche

- Elle ne se plie **jamais d'elle-même** (Charles, 2026-11-25). Son état
  passe d'une vue à l'autre. Comme aujourd'hui (`_showLegendLabels`), il
  n'est pas gardé : un tracker se rouvre barre dépliée (*mon choix* : ne pas
  changer ce qui existe ; à garder si Charles le veut).
- **Le chevron** en haut de la barre continue de la plier et de la déplier.
  Pliée, la barre garde ce qu'elle garde aujourd'hui (points de légende
  touchables pour le pinceau, bouton du jour sans libellé, mini-stats en
  icônes), plus A · M · S.
- **Nouveau : un glissement sur la barre elle-même.** Vers la gauche sur la
  barre dépliée, elle se plie ; vers la droite sur la barre pliée, elle se
  déplie. Pareil en Année, Mois et Semaine.
- Même principe que le zoom : la largeur de la barre suit le doigt entre
  dépliée et pliée, rien d'autre ne bouge que la grille qui gagne ou perd la
  place ; au lâcher, passé la moitié ou avec un élan suffisant, elle finit
  seule ; sinon elle revient. Le contenu qui disparaît (légende, boutons,
  stats) s'efface pendant la première moitié du chemin.
- **Pourquoi sur la barre seulement** : sur la grille, le glissement
  horizontal tourne déjà les mois et les semaines.
- **Sauf la ligne de période**, qui garde son propre glissement (changer
  d'année, de mois ou de semaine). Le reste de la barre (légende, boutons,
  stats, espace vide) reçoit le glissement de pliage. La liste de la légende
  défile à la verticale : un départ plus vertical qu'horizontal la fait
  défiler, comme aujourd'hui.
- Le glissement de la barre se décide comme celui de la grille (plus
  horizontal que vertical, au-delà de 9 px) ; un toucher simple sur un
  élément de la barre reste un toucher.
- **Avec le retour par le bord** (`BackSwipe`, `widgets/back_swipe.dart`) :
  aujourd'hui un doigt posé à moins de 24 px du bord gauche et tiré de 60 px
  vers la droite ramène à la liste, sans regarder ce qu'il y a dessous. La
  barre commence à environ 12 px du bord en portrait : sur la barre
  **pliée**, un glissement vers la droite parti entre 12 et 24 px
  déplierait la barre **et** reviendrait à la liste. Règle (*mon choix*) :
  un doigt posé sur la barre pliée la déplie, et le retour par le bord
  l'ignore ; le retour reste possible depuis la marge extérieure, par le
  bouton ‹ et par le retour Android. Sur la barre dépliée, rien ne change :
  plier se fait vers la gauche, le retour vers la droite.
- **Android en navigation par gestes** : le système prend les glissements
  qui partent du bord de l'écran ; le dépliage marche donc depuis
  l'intérieur de la barre pliée. À vérifier sur appareil.
- Pas de maquette (Charles) : les réglages fins (durées, courbes, seuil
  d'élan) sont laissés au constructeur, avec les valeurs du glissement de
  page comme point de départ.

## Sons et vibrations

Pas de nouveau son (*mon choix*) ; on reprend ceux qui existent :

- zoom acquis (au lâcher passé la moitié, ou au sélecteur) : `panelOpen`
  vers un niveau plus proche, `panelClose` vers un niveau plus large ;
- passage de la moitié pendant un pincement, dans un sens ou dans l'autre :
  la vibration légère de `select`, sans son, pour sentir le moment où l'on
  peut lâcher ;
- page tournée (glissement, flèches) : `stepNext` / `stepPrev`, comme les
  années ;
- barre pliée ou dépliée au glissement : `panelClose` / `panelOpen`, comme
  au chevron ;
- « C'est déjà toute l'année », pincement qui revient : rien.

## Les astuces

Le pincement, le glissement d'une page à l'autre et le glissement de la
barre ne se devinent pas. Ils seront montrés une fois, au bon moment, par
les astuces (chantier suivant, brainstorm en cours le 2026-11-25). Cette spec
ne crée pas d'astuce ; elle note seulement chaque usage pour qu'une astuce
ne montre jamais ce qu'on sait déjà faire :

- sur l'appareil, par compte : un compteur par nom dans les préférences,
  clé `features_used_<userId>` (forme exacte dans
  `2026-11-25-feature-tips-design.md`, section « Le relevé ») ;
- noms : `zoom.pinch`, `zoom.selector`, `zoom.letter`, `page.swipe`,
  `page.arrows`, `sidebar.swipe`, `sidebar.chevron`, `view.zoomed` ;
- un nom ne s'enlève jamais. Si les astuces se construisent avant le zoom,
  le zoom reprend leur relevé ; sinon le zoom le crée et les astuces y
  ajoutent leurs noms.

## Données et serveur

Rien sur le serveur. Sur l'appareil : les usages notés pour les astuces
(section précédente). Ni le niveau ni l'état de la barre ne sont gardés.

## Idées pour plus tard

- En vue Semaine, les couleurs des autres trackers le même jour.
- En vue Mois, la stat gratuite du mois (spec des stats, carte « ce mois-ci »).
- La fenêtre du Cycle (spec des stats) sur la vue Mois.
- Chercher dans les commentaires.

## Écarts avec la page d'essai

- La page d'essai met la période et ses flèches au-dessus de la grille et le
  bouton « Aujourd'hui » n'y fait que changer de période ; dans l'app, la
  période prend la place de l'en-tête d'année, et Aujourd'hui ouvre aussi
  l'éditeur du jour, comme aujourd'hui.
- Les réglages « ESSAI » (sélecteur en haut, barre repliée d'office, pincer
  ou glisser désactivés, longueur Court ou Long) ne passent pas dans l'app.
- Le glissement de la barre n'est pas dans la page d'essai.

## Avant de construire

- **Partir de master après la fusion de `feat/comment-badge`** : cette
  branche réécrit le repère de commentaire dans `tracker_grid.dart`, le
  fichier que ce chantier refait, et la page d'essai dessine déjà la
  pastille. Le chemin de l'année au mois efface la pastille, pas l'anneau.
- **Une semaine à cheval sur deux années** : `CellsProvider` et
  `CellEditorDialog` travaillent sur une année à la fois (`getCell(month,
  day)` lit l'année courante du provider). Il faut les étendre, sinon
  toucher le 1ᵉʳ janvier dans la semaine du 29 décembre modifie la mauvaise
  case.
- **Couleurs** : `accentSoft` et `weekend` n'existent pas dans `AppColors` ;
  elles viennent de la page d'essai. Les tirer de chaque thème en mêlant
  l'accent ou le texte vers le fond du thème, jamais vers le blanc ou le
  noir, et vérifier les sept thèmes, clairs et sombres.

## Questions closes

- Niveaux fixes, pas de zoom libre ; vue Mois en lignes ; pincement sur
  chemin fixe, longueur Moyen ; pas de barre pliée d'office ; glissement sur
  la barre dans les trois vues (Charles, 2026-11-24 et 2026-11-25).

## Gratuit

Les vues Mois et Semaine sont gratuites, sans verrou ni aperçu : c'est la
façon de lire son propre tracker ; Premium garde les stats, les thèmes,
l'export (recommandation acceptée par Charles le 2026-11-25, « ça me paraît
pas mal tout ça »).

## Relecture du 2026-11-25

Relecture façon constructeur, faite sur le code. Ce qu'elle a changé : un
tracker s'ouvre toujours sur l'année (l'animation de la carte), l'année de la
liste suit les mois et les semaines, la largeur en vue Mois et Semaine, pas
de limite de navigation, l'état de la barre (pas gardé, la contradiction est
levée), les sons repris de l'existant, la forme du relevé des usages, la
branche de départ, la semaine à cheval sur deux années, les deux couleurs à
tirer des thèmes. La question qui restait (gratuit ou Premium) est close :
gratuit.

## Laissé au constructeur

- La structure des widgets et la tenue à 60 images par seconde sur un
  Android d'entrée de gamme (mesurer sur l'appareil le plus lent dispo).
- Les courbes exactes (celles de Flutter les plus proches des valeurs
  ci-dessus).
- La place exacte du sélecteur et de la période en paysage (tablette, web :
  le panneau de gauche de 240 px y affiche l'année en texte) et sur
  tablette en portrait (barre de 140 px), dans l'esprit de la barre
  actuelle.
