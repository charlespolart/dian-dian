# Animations — morphing v2 (élément partagé), plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remplacer la coque qui grandit par un vrai élément partagé : cadre, écran intérieur, points et titre dessinés par la scène et interpolés entre la carte et le tracker, le tracker réel n'apparaissant qu'à l'arrivée.

**Architecture:** une géométrie de grille partagée (`grid_geometry.dart`) utilisée par la mini-grille, par `TrackerGrid` et par le peintre ; un registre d'ancrages à clés ; un `MorphLayer` (peintre + titre) ; la scène qui le pilote avec une progression `easeInOutCubic` et des fenêtres de fondu aux deux bouts.

**Spec:** `docs/superpowers/specs/2026-10-22-animations-design.md`, section « Élément partagé : `MorphLayer` ».

## Global Constraints
- Mêmes que le plan `2026-10-22-animations.md` (branche `feat/animations`, pas de dépendance, `AppMotion` seul, zéro en animations réduites, analyse et suite vertes avant chaque commit).
- À `t = 0` le calque est identique à la carte, à `t = 1` identique au tracker : vérifié par des tests sur les géométries, pas à l'œil seulement.

## Review Focus
- Un tracker dont le titre est long (marquee) : le titre interpolé reste dans son rectangle, sans débordement.
- Paysage tablette : la coque en `fitWidth`, le calque suit les ancres mesurées, pas une formule.
- Un changement d'année pendant que le morph est mesuré : la grille enregistrée est celle de l'année affichée.
- Thème (couleurs semi-transparentes de `screen`) : le peintre dessine cadre puis écran, comme le tracker, donc même rendu.
- Case vide / pleine : bordure des vides qui apparaît avec `g`, couleur des pleines interpolée depuis `dotEmpty`.

### Task 1: `grid_geometry.dart` — géométries partagées (`MiniGridGeometry`, `TrackerGridGeometry`), `TrackerGrid` et la mini-grille s'en servent. Test: `test/grid_geometry_test.dart`.
### Task 2: `MorphAnchors` à clés + `MorphAnchor(anchors, key, child)` + `registerGrid` ; ancres posées dans la liste (card, cardScreen, cardGrid, cardTitle, cardLegends) et le tracker (shell, screen, grid, barTitle). Tests: `test/morph_anchors_test.dart` mis à jour.
### Task 3: `MorphLayer` + `MorphPainter` (`lib/widgets/morph_layer.dart`) : `MorphEnds` (les rectangles et géométries des deux bouts), `MorphContent` (titre, cellules, couleurs de légende), `g`, fenêtres. Tests: `test/morph_layer_test.dart` (centres des points à g = 0 et g = 1, rectangles du cadre et de l'écran).
### Task 4: scène : `MorphShell` retiré, `MorphLayer` branché, frame de mesure lit toutes les ancres, repli fondu, fenêtres de la spec. Tests: `test/screen_stage_test.dart` mis à jour (`MorphLayer`).
### Task 5: `AppShell` fournit `MorphContent` (titre, cellules de l'année, couleurs de légende) à la place de la copie de carte ; `PageCard.frozen` supprimé s'il n'a plus d'usage. Tests: suite.
### Task 6: relecture indépendante de la branche depuis `949e164`, passe de correction, puis essai sur simulateur par l'utilisateur avec le ralenti.
