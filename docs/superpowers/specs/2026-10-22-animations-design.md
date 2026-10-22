# Animations : transitions et retours visuels — design (2026-10-22)

## Objectif

Rendre l'app plus jolie et plus satisfaisante à manipuler, sans en faire
un spectacle : des transitions courtes partout où quelque chose apparaît,
disparaît ou change, avec une seule règle de timing. Le ton de référence est
la boîte « Nouveautés » (fondu échelonné des puces, `whats_new_dialog.dart`).

Point 7 de `docs/ROADMAP.md`. Chantier séparé de la 1.4.0 : branche
`feat/animations`, livré en app 1.5.0 avec le lot 2 (sons, cadré à part,
voir la fin).

**Mesure de succès** : jugement à l'œil sur appareil (iPhone et Android,
portrait et paysage tablette), pas de métrique. Garde-fous : un tap sur une
case ne rebuild pas plus de widgets qu'aujourd'hui, et tout est instantané
quand le système demande de réduire les animations.

Non-objectifs : grille en `CustomPainter` (point 5 du roadmap), réagencement
animé des cartes à la suppression (`AnimatedGrid`), refonte de la navigation
en routes `Navigator`, retours haptiques, sons (lot 2).

## Décisions prises en brainstorming

- **Périmètre** : ouverture et fermeture du tracker par un vrai morphing
  depuis sa carte ; ouverture et fermeture de tous les pop-ups ; le point qui
  se remplit ; le changement d'année ; les boutons sous le doigt ; la liste
  des trackers (cascade, apparition, suppression).
- **Morphing réel** carte → tracker plutôt qu'un zoom depuis la carte : plus
  de travail et de cas limites, assumés, avec des replis définis pour chacun.
- **Aucune dépendance nouvelle** : tout en Flutter natif.
- **Une seule règle de timing** dans un fichier, et zéro partout quand les
  animations sont réduites.
- Les pop-ups naissent du point tapé quand il y en a un (éditeur de case,
  bouton Edit des légendes), du centre sinon.
- Un seul widget animé pour le pop du point, pas un par cellule : la future
  grille en `CustomPainter` n'aura rien à défaire.

## 1. Règle de timing : `lib/theme/motion.dart`

```dart
class AppMotion {
  static const press  = Duration(milliseconds: 90);   // bouton sous le doigt
  static const quick  = Duration(milliseconds: 160);  // sortie de pop-up, fondus courts
  static const base   = Duration(milliseconds: 220);  // entrée de pop-up, année, cascade
  static const pop    = Duration(milliseconds: 280);  // point qui se remplit
  static const screen = Duration(milliseconds: 320);  // ouverture / fermeture du tracker

  static const enter = Curves.easeOutCubic;  // ce qui arrive décélère
  static const exit  = Curves.easeInCubic;   // ce qui part accélère

  /// Zéro quand le système demande de réduire les animations
  /// (iOS « Réduire les animations », Android échelle d'animation à 0).
  static Duration of(BuildContext context, Duration d) =>
      MediaQuery.disableAnimationsOf(context) ? Duration.zero : d;
  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}
```

Règles : une entrée dure plus longtemps que sa sortie ; aucune durée en dur
ailleurs que dans ce fichier (les 200 ms existants de `AnimatedSwitcher` et
des panneaux du tracker passent sur `base`). Les composants qui animent
lisent `AppMotion.of(context, …)`, jamais la constante brute.

## 2. Liste ↔ tracker : morphing

### Scène : `lib/widgets/screen_stage.dart`

`AppShell` remplace son `AnimatedSwitcher` par `ScreenStage`, une scène à
trois couches : l'écran sortant, l'écran entrant, et pour la paire
liste ↔ tracker une **coque** animée.

```dart
enum StageTransition { fade, slideIn, slideOut, morphOpen, morphClose }

class ScreenStage extends StatefulWidget {
  final Widget child;                 // l'écran courant, avec sa ValueKey
  final StageTransition transition;   // comment on y arrive depuis le précédent
  final MorphAnchors anchors;         // rectangles mesurés (voir plus bas)
  final String? morphPageId;          // carte de départ / d'arrivée du morphing
  final WidgetBuilder? morphCardCopy; // copie figée de la carte, dans la coque
  final VoidCallback? onSettled;      // fin de transition
}
```

Quand la clé de `child` change, la scène joue la transition demandée :

- `fade` : fondu croisé sur `base` (connexion, inscription, premier
  tracker → tracker, et tout cas de repli).
- `slideIn` / `slideOut` : fondu plus glissement horizontal de 8 % de la
  largeur, sur `base`. `slideIn` pour liste → réglages et tracker →
  réglages, `slideOut` pour réglages → liste.
- `morphOpen` et `morphClose` : décrits ci-dessous, sur `screen`.

Pendant toute transition la scène est sous `IgnorePointer`. Une navigation
demandée en cours de transition (double retour, tap pendant la fermeture)
termine la transition en cours d'un coup, puis enchaîne la nouvelle en
`fade`. Un changement de contraintes en cours de transition (rotation,
clavier) saute à la fin. Avec les animations réduites, la scène échange les
écrans sans frame intermédiaire.

### Ancrages : `MorphAnchors`

Objet détenu par `AppShell` et passé aux deux écrans. Les ancrages ne sont
**pas** des `GlobalKey` : le glissement d'année de la liste (§5) garde deux
grilles vivantes pendant 220 ms, avec les mêmes cartes dans chacune, ce
qu'une `GlobalKey` refuse. À la place, un widget `MorphAnchor` enregistre le
`BuildContext` de son enfant tant qu'il est monté : `MorphAnchor.card(anchors,
pageId, child)` autour de la carte dans la grille uniquement, jamais autour
de la copie du glisser-déposer ; `MorphAnchor.shell(anchors, child)` autour
de la coque du tracker dans `_buildBookShell`, commun au portrait et au
paysage. Le dernier enregistrement l'emporte (la grille de la nouvelle année
prend la main), et un enregistrement n'est retiré que par son propriétaire.

```dart
class MorphAnchors {
  void registerCard(String pageId, BuildContext context);
  void unregisterCard(String pageId, BuildContext context);
  void registerShell(BuildContext context);
  void unregisterShell(BuildContext context);
  Rect? cardRect(String pageId, {RenderBox? ancestor});  // null si pas à l'écran
  Rect? shellRect({RenderBox? ancestor});                // null si le tracker n'a pas peint
}
```

Les rectangles sont lus en coordonnées de la scène (`localToGlobal` avec le
`RenderBox` de la scène pour ancêtre).

La scène elle-même garde un seul arbre stable, une pile à enfants clés sous
un `AnimatedBuilder`, quelle que soit la phase (repos, frame de mesure,
animation) : un écran conserve son élément et son état quand il passe de
courant à sortant. Avant cette règle, chaque transition ré-instanciait les
deux écrans (cascade de la liste rejouée, titre en cours d'édition perdu,
grille posée trois fois).

### Copie de la carte

`_PageCard` devient public `PageCard`, avec un constructeur `PageCard.frozen`
sans poignée, sans croix, sans tap. `AppShell` la construit pour la coque à
partir des providers (page, cellules de l'année, légendes).

### Ouverture (`morphOpen`)

1. `_navigate(tracker, pageId)` lit `anchors.cardRect(pageId)` pendant que la
   liste est encore montée et le garde pour la scène.
2. Frame de mesure : la scène peint la liste normalement et le tracker en
   `Opacity(0)` sous `IgnorePointer`. Après cette frame elle lit
   `anchors.shellRect()`.
3. Sur `screen` (320 ms), avec `t` passé par `enter` :
   - la liste passe de 1 à 0 d'opacité sur `t ∈ [0 ; 0,6]` ;
   - la coque, `Positioned.fromRect(Rect.lerp(carte, coque, t))`, couleur
     `AppColors.shell`, bordure `shellBorder`, rayon 10 → 14 ;
   - dedans, la copie de la carte, rendue à la taille de la carte dans un
     `FittedBox(fit: BoxFit.fitWidth, alignment: topCenter)` sous
     `ClipRRect`, opacité 1 → 0 sur `t ∈ [0 ; 0,4]` ;
   - le tracker, par-dessus, opacité 0 → 1 sur `t ∈ [0,4 ; 1]`. Sa propre
     coque a la même couleur et la même bordure, le raccord ne se voit pas.
4. Fin : la liste et la coque sont retirées, le tracker reçoit les touches.

Replis : `shellRect()` null (le tracker s'est retiré au premier build, page
disparue ou verrouillée) → `fade`. `cardRect` null (création depuis la boîte
Nouveau tracker sans que la carte ait peint, voir §7) → la coque part d'un
rectangle centré de 120 × 260 dp à opacité 0, c'est un zoom-fondu centré.

Le premier tracker et la restauration au lancement n'ont pas de liste
derrière eux : ils restent en `fade`.

### Fermeture (`morphClose`)

Déclenchée par la flèche retour, le retour système et le swipe de bord,
tous via `_navigate(pageList)`.

1. Frame de mesure : le tracker peint normalement, la liste est construite
   en `Opacity(0)` avec `revealPageId` : son `GridView` reçoit un
   `ScrollController` dont l'offset initial met la rangée de la carte dans
   la vue (rangée = index ÷ nombre de colonnes, hauteur de rangée déduite de
   `maxCrossAxisExtent`, du ratio 0,45 et de l'espacement). Après la frame,
   la scène lit `cardRect(pageId)` et `shellRect()`.
2. Sur `screen`, avec `t` passé par `exit` :
   - le tracker, opacité 1 → 0 sur `t ∈ [0 ; 0,4]` ;
   - la coque va du rectangle de la coque à celui de la carte, rayon
     14 → 10 ;
   - la copie de la carte dedans, opacité 0 → 1 sur `t ∈ [0,6 ; 1]` ;
   - la liste dessous, opacité 0 → 1 sur `t ∈ [0,4 ; 1]`.
3. Fin : le tracker et la coque sont retirés, la liste reçoit les touches.
   La liste n'anime pas sa cascade dans ce cas (voir §7).

Replis : `cardRect` null (carte supprimée depuis un autre appareil,
verrouillée, liste vide) → la coque se rétracte vers le rectangle centré de
120 × 260 dp en passant à opacité 0 sur `t ∈ [0,6 ; 1]`. `shellRect` null
(ne devrait pas arriver, le tracker vient de peindre) → `fade`.

### Ce que `AppShell` change

- `_navigate` choisit la transition à partir de la paire (écran courant,
  écran cible) ; `pageId` et le rectangle de la carte sont capturés avant le
  `setState`.
- `PageListScreen` reçoit `anchors`, `revealPageId` et `entrance` (§7).
  `TrackerScreen` reçoit `anchors`.
- La barre d'annulation reste au-dessus de la scène, inchangée.

## 3. Pop-ups : `showAppDialog`

Dans `lib/widgets/app_dialog.dart` :

```dart
Future<T?> showAppDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Offset? origin,  // point global d'où la boîte semble naître ; centre sinon
});
```

Bâti sur une `AppDialogRoute<T> extends RawDialogRoute<T>` qui reprend le
`pageBuilder` de `DialogRoute` (thèmes capturés, `SafeArea`, `Semantics`
opaque, voile `Colors.black54`) et impose :

- `transitionDuration` = `base`, `reverseTransitionDuration` = `quick`
  (surcharge du getter) ; tous deux à zéro en animations réduites ;
- `transitionBuilder` : à l'entrée, échelle 0,92 → 1, opacité 0 → 1 et
  montée de 8 px, courbe `enter` ; à la sortie (`animation.status ==
  reverse`), échelle 1 → 0,96 et opacité 1 → 0, courbe `exit`. Le voile
  suit la même animation (c'est celle de la route).
- `origin` : l'échelle s'applique avec
  `Alignment(origin.dx / largeur × 2 − 1, origin.dy / hauteur × 2 − 1)`
  (fonction pure `originAlignment(Offset, Size)`), ce qui fait naître la
  boîte depuis le point tapé puis la pose au centre.

Les dix-sept appels `showDialog` passent par `showAppDialog`, boîtes imbriquées
comprises (couleur personnalisée dans l'éditeur de légendes, confirmation de
suppression d'une légende, boîte « ajoutez une légende » de l'éditeur de
case). `origin` est renseigné pour l'éditeur de case (position du tap sur le
point, via `onTapUp` : `TrackerGrid.onCellPress` reçoit désormais la
position globale) et pour l'éditeur de légendes ouvert par Edit. La boîte
Nouveautés garde sa cascade de puces, qui part après l'entrée de la boîte.
Rien ne change dans les contenus ni dans `AppDialog`.

## 4. Le point qui se remplit

`CellsProvider` expose le dernier changement **local** :

```dart
class CellChange {
  final String pageId; final int year, month, day;
  final String? color;   // nouvelle couleur ; à l'effacement, l'ancienne
  final bool erased;
  final int seq;         // compteur, pour distinguer deux taps sur la même case
}
CellChange? get lastChange;
```

Renseigné par `setCell` et `deleteCell` avant leur `notifyListeners`. Ni
`recolorCells`, ni les messages WebSocket, ni le bootstrap ne le touchent :
les changements venus d'ailleurs ne font pas de pop.

`TrackerGrid` reçoit `pop: CellChange?` (passé par `_buildGrid` quand page
et année correspondent) et dessine, dans un `Stack` par-dessus la colonne
de rangées, **un seul** widget `DotPop` (public, pour les tests) en `Positioned` au centre de la
cellule (`cellCenter(month, day)`, fonction pure sur `labelColWidth`,
`cellSize`, `rowHeight`), clé `ValueKey(seq)` :

- remplissage : le point à la couleur **courante** de la case (lue par
  `getCellColor` à chaque build : une légende recolorée ou une modification
  venue d'un autre appareil juste après le tap se voit ; une case vidée fait
  disparaître le pop), échelle 0,6 → 1,15 → 1 sur `pop` (séquence 60 % en
  `enter`, 40 % en `exit`), puis il reste posé, identique au point dessous ;
- effacement : le point à son ancienne couleur, échelle 1 → 0 avec fondu,
  sur `quick`.

Marche au pinceau (légende sélectionnée) comme depuis l'éditeur. Le point
dessous change de couleur instantanément, comme aujourd'hui. Le mini-aperçu
des cartes n'est pas concerné.

## 5. Changement d'année : `SlideSwitcher`

`lib/widgets/slide_switcher.dart` :

```dart
class SlideSwitcher extends StatelessWidget {
  final Widget child;     // porte une ValueKey (l'année, l'étape…)
  final int direction;    // +1 : le nouveau arrive de la droite ; −1 : de la gauche ; 0 : fondu seul
  final double distance;  // 24 px par défaut
}
```

Sur `AnimatedSwitcher` avec `transitionBuilder` : le sortant glisse de
`−direction × distance` et s'efface, l'entrant arrive de `+direction ×
distance` et apparaît, sur `base`, courbe `enter`. Le sens est celui du
delta d'année (`_changeYear(delta)`), capturé au moment du changement.

Emplois : la grille du tracker (`_buildGrid`, clé année ; la barre latérale
ne bouge pas), la grille des cartes de la liste (clé année), le libellé
d'année dans `SwipeNav` (clé année, distance 12 px), les deux étapes du
premier tracker (clé étape, direction +1).

## 6. Boutons : `PressScale`

`lib/widgets/press_scale.dart` :

```dart
class PressScale extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final HitTestBehavior behavior; // opaque par défaut
}
```

`GestureDetector` avec `onTapDown` / `onTapUp` / `onTapCancel` autour d'un
`AnimatedScale` : 0,96 sous le doigt, 1 au relâché, sur `press`. `onTap`
null désactive le retour. Les `Semantics(button)` déjà posés restent à
l'extérieur.

Posé sur les boutons à fond et bordure, en remplacement du
`GestureDetector(onTap:)` qui les entoure : pieds de toutes les boîtes
(OK, Annuler, Créer, Supprimer, Enregistrer…), le « + » de la liste, les
lignes des réglages, tuiles et boutons du premier tracker, boutons de
connexion, d'inscription et OAuth, Aujourd'hui, Edit des légendes, bouton
de la bannière de téléchargement. Pas sur les points de la grille, les
flèches d'année, les icônes de barre, les croix de fermeture ni les
légendes-pinceaux : leur réponse est déjà immédiate.

## 7. Liste des trackers

`PageListScreen` reçoit `entrance: ListEntrance.cascade | none`.

- **Cascade** (`cascade`, passé par `AppShell` quand on arrive depuis la
  connexion, les réglages ou le premier tracker ; `none` au retour d'un
  tracker, le morphing suffit) : chaque carte d'index `i < 12` apparaît en
  fondu avec une montée de 10 px sur `base`, décalée de `30 × i` ms
  (`entranceDelay(i)`, fonction pure). Une carte construite plus de 600 ms
  après la création de l'écran (défilement) n'anime pas.
- **Apparition** d'une carte pendant qu'on est sur la liste (annulation de
  suppression, sync d'un autre appareil) : l'écran garde l'ensemble des ids
  vus ; un id nouveau après le premier build apparaît en échelle 0,8 → 1
  avec fondu sur `base`. Une création depuis la boîte Nouveau tracker
  n'anime pas l'apparition : l'écran attend une frame que la carte ait
  peint, puis enchaîne sur `morphOpen` depuis elle (repli centré si elle
  n'a pas peint, carte hors de la vue par exemple).
- **Suppression** : après la confirmation, la carte passe en état
  `_removingId` (tap, croix et poignée inertes), se rétracte à 0,85 et
  s'efface sur `quick` (`AnimatedScale` + `AnimatedOpacity`), puis
  `softDeletePage` est appelé, que la liste soit encore montée ou non (la
  suppression est confirmée, elle ne se perd pas), et elle quitte la grille.
  Les autres cartes se recalent sans animation ; à revoir si ça saute trop à
  l'œil.
- **Changement d'année** : la grille de chaque année est un `GridView`
  neuf sous le `SlideSwitcher` ; une `PageStorageKey` propre à l'instance
  de l'écran garde l'offset de défilement d'une année à l'autre, et un
  écran neuf démarre bien sur sa carte de retour (`revealPageId`).

## 8. Autres écrans

- Réglages : `slideIn` à l'ouverture, `slideOut` au retour (§2).
- Premier tracker : les deux étapes dans un `SlideSwitcher` (§5).
- Connexion, inscription, mot de passe oublié : `fade` sur `base`.
- Inchangés : barre d'annulation, pulsation d'Aujourd'hui, panneaux
  latéraux du tracker (passent juste sur `base`), texte défilant.

## 9. Tests et vérification

Tests widget, dans `flutter_app/test/` :

- `motion_test.dart` : `AppMotion.of` rend zéro sous
  `MediaQuery(disableAnimations: true)`.
- `app_dialog_test.dart` : `showAppDialog` est à échelle < 1 à mi-entrée et
  à 1 une fois posé ; la fermeture prend `quick` ; `originAlignment` sur
  les coins et le centre.
- `press_scale_test.dart` : 0,96 pendant l'appui, 1 après, `onTap` appelé
  une fois.
- `slide_switcher_test.dart` : le décalage de l'entrant a le signe de
  `direction`.
- `tracker_grid_test.dart` : exactement un `DotPop` ; `cellCenter` sur
  (1, 1) et (12, 31) ; un `pop` sur une autre année n'en dessine aucun.
- `screen_stage_test.dart` : `fade` finit sur le nouvel écran ; `morphOpen`
  sans `shellRect` finit en `fade` ; une navigation pendant une transition
  termine et enchaîne ; animations réduites → échange immédiat.
- `page_list_screen_test.dart` : `entranceDelay`, l'offset initial de
  `revealPageId` met la rangée dans la vue.

Sur appareil : iPhone et Android, portrait et paysage tablette, une fois
avec « réduire les animations ». Un relevé DevTools (compteur de rebuild sur
la grille) avant et après confirme qu'un tap sur une case ne rebuild pas
plus qu'aujourd'hui.

## 10. Livraison

- `CHANGELOG.md` (Unreleased, « Changed ») et `docs/changelogs/1.5.0.md`
  dans les quatre langues ; entrée `whats_new.dart` pour la 1.5.0.
- Pas de changement backend.
- La 1.5.0 attend le lot 2 (sons) sauf si celui-ci traîne : les animations
  peuvent partir seules.

## Lot 2 : sons (cadré à part, juste après)

Existant : `AudioService` joue deux sons (`dot-tap.mp3`, `dot-erase.mp3`)
depuis `CellsProvider`. À cadrer dans un brainstorm dédié une fois les
animations sur appareil :

- moments candidats : ouverture et fermeture du tracker, pop-ups, boutons,
  création d'un tracker, changement d'année, légende ajoutée, premier point
  du jour ;
- un réglage « Sons » dans les réglages, par appareil (`SharedPreferences`),
  qui coupe tout ;
- sources libres à explorer : pack UI de Kenney (CC0), freesound (CC0) ;
  cohérence de timbre avec les deux sons existants ;
- les sons se calent sur les durées de `AppMotion` (un son d'ouverture part
  au début de l'entrée, un son de fermeture au début de la sortie).
