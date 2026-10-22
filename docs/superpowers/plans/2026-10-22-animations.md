# Animations — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Des transitions courtes et une seule règle de timing partout dans l'app Flutter : morphing carte → tracker, ouverture et fermeture de tous les pop-ups, pop du point qui se remplit, glissement au changement d'année, boutons sous le doigt, cascade et apparition / suppression des cartes.

**Architecture:** Un fichier de durées et de courbes (`AppMotion`) que tout le reste lit, à zéro quand le système réduit les animations. Trois petits widgets réutilisables (`PressScale`, `SlideSwitcher`, `Appear`), une route de dialogue maison (`showAppDialog`), un pop unique dans la grille piloté par `CellsProvider.lastChange`, et une scène d'écrans (`ScreenStage`) qui remplace l'`AnimatedSwitcher` d'`AppShell` et joue le morphing entre les rectangles mesurés par `MorphAnchors`.

**Tech Stack:** Flutter 3.47 (Dart ^3.11), `provider`, `flutter_test`. Aucune dépendance nouvelle.

**Spec:** `docs/superpowers/specs/2026-10-22-animations-design.md`

## Global Constraints

- Branche `feat/animations` ; la 1.4.0 part de `master` sans ce travail. Vérifier `git branch --show-current` avant chaque commit.
- Aucune dépendance ajoutée à `flutter_app/pubspec.yaml`.
- Aucune durée en dur hors `lib/theme/motion.dart` ; chaque animation lit `AppMotion.of(context, …)`.
- Tout est instantané sous `MediaQuery.disableAnimationsOf(context) == true`.
- Un tap sur une case ne rebuild pas plus de widgets qu'aujourd'hui (un seul widget animé dans la grille).
- Code et commentaires en anglais, comme le reste de `flutter_app/lib` ; prose des docs en français.
- Toutes les commandes se lancent depuis `flutter_app/` ; avant chaque commit : `flutter analyze` sans erreur et `flutter test` vert.
- Messages de commit : une ligne « App: … » puis une ligne vide et `Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz`.

## Review Focus

- Une navigation pendant une transition (retour système deux fois, tracker supprimé depuis un autre appareil pendant l'ouverture) : la transition en cours se termine d'un coup et la suivante joue en fondu, sans exception. Test dans la tâche 8.
- Une rotation ou le clavier pendant une transition : la scène saute à la fin, l'écran d'arrivée est entier. Test dans la tâche 8.
- Un tap sur une case refusé par le serveur : le point revient, et le pop ne garde pas la couleur refusée. Test dans la tâche 6.
- Un tap sur une carte pendant qu'elle se rétracte après « Supprimer » : rien ne s'ouvre. Test dans la tâche 7.
- Un pop-up né d'un tap dans un coin de l'écran : l'alignement reste dans l'écran et la boîte finit au centre. Test dans la tâche 3.

---

### Task 1: `AppMotion`, la règle de timing

**Files:**
- Create: `flutter_app/lib/theme/motion.dart`
- Modify: `flutter_app/lib/screens/tracker_screen.dart:435-437`, `:471-472`, `:670-671` (les trois `AnimatedContainer` à 200 ms)
- Modify: `flutter_app/lib/main.dart:423-426`, `:431-434` (les deux `AnimatedSwitcher` à 200 ms, remplacés plus tard par la scène)
- Test: `flutter_app/test/motion_test.dart`

**Interfaces:**
- Produces: `class AppMotion` avec `press`, `quick`, `base`, `pop`, `screen` (`Duration`), `enter`, `exit` (`Curve`), `static Duration of(BuildContext, Duration)`, `static bool reduced(BuildContext)`.

- [ ] **Step 1: Écrire le test qui échoue**

```dart
// flutter_app/test/motion_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';

void main() {
  testWidgets('AppMotion.of is the duration normally and zero when the system reduces animations', (tester) async {
    late Duration normal;
    late Duration reduced;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(),
      child: Builder(builder: (context) {
        normal = AppMotion.of(context, AppMotion.base);
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Builder(builder: (context) {
        reduced = AppMotion.of(context, AppMotion.base);
        return const SizedBox();
      }),
    ));
    expect(normal, AppMotion.base);
    expect(reduced, Duration.zero);
  });

  test('an entrance lasts longer than its exit', () {
    expect(AppMotion.base > AppMotion.quick, isTrue);
    expect(AppMotion.screen > AppMotion.base, isTrue);
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `cd flutter_app && flutter test test/motion_test.dart`
Expected: FAIL, `Target of URI doesn't exist: 'package:dian_dian/theme/motion.dart'`

- [ ] **Step 3: Écrire `motion.dart`**

```dart
// flutter_app/lib/theme/motion.dart
import 'package:flutter/widgets.dart';

/// The app's one timing rule. Every animation reads its duration through
/// [of], which is zero when the system asks for reduced motion (iOS "Reduce
/// Motion", Android animator scale 0). An entrance always lasts longer than
/// its exit; what arrives decelerates ([enter]), what leaves accelerates
/// ([exit]).
class AppMotion {
  AppMotion._();

  /// A button under the finger.
  static const press = Duration(milliseconds: 90);
  /// A dialog leaving, short fades.
  static const quick = Duration(milliseconds: 160);
  /// A dialog arriving, a year change, the list's cascade.
  static const base = Duration(milliseconds: 220);
  /// The dot that fills in.
  static const pop = Duration(milliseconds: 280);
  /// Opening and closing a tracker.
  static const screen = Duration(milliseconds: 320);

  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;

  static bool reduced(BuildContext context) => MediaQuery.disableAnimationsOf(context);

  /// [d], or zero under reduced motion.
  static Duration of(BuildContext context, Duration d) => reduced(context) ? Duration.zero : d;
}
```

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

Run: `cd flutter_app && flutter test test/motion_test.dart`
Expected: PASS (2 tests)

- [ ] **Step 5: Remplacer les durées en dur existantes**

Dans `lib/screens/tracker_screen.dart`, ajouter `import '../theme/motion.dart';` et remplacer les trois `duration: const Duration(milliseconds: 200),` (vers les lignes 436, 472 et 671) par `duration: AppMotion.of(context, AppMotion.base),`.

Dans `lib/main.dart`, ajouter `import 'theme/motion.dart';` et remplacer les deux `duration: const Duration(milliseconds: 200),` des `AnimatedSwitcher` (vers les lignes 424 et 432) par `duration: AppMotion.of(context, AppMotion.base),`.

- [ ] **Step 6: Analyse et tests complets, puis commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!` puis `All tests passed!`

```bash
git add flutter_app/lib/theme/motion.dart flutter_app/lib/screens/tracker_screen.dart flutter_app/lib/main.dart flutter_app/test/motion_test.dart
git commit -m "App: AppMotion, the one timing rule (zero under reduced motion); existing 200 ms animations read it

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 2: `PressScale`, les boutons sous le doigt

**Files:**
- Create: `flutter_app/lib/widgets/press_scale.dart`
- Modify (sites listés à l'étape 5): `confirm_dialog.dart`, `whats_new_dialog.dart`, `page_list_screen.dart`, `settings_screen.dart`, `first_tracker_screen.dart`, `login_screen.dart`, `register_screen.dart`, `forgot_password_screen.dart`, `oauth_buttons.dart`, `tracker_screen.dart`, `cell_editor_dialog.dart`, `legend_editor_dialog.dart`, `premium_gate_dialog.dart`, `custom_paywall_dialog.dart`, `keep_trackers_dialog.dart`, `contact_dialog.dart`, `global_stats_dialog.dart`, `download_app_banner.dart`
- Test: `flutter_app/test/press_scale_test.dart`

**Interfaces:**
- Consumes: `AppMotion.press`, `AppMotion.enter`, `AppMotion.of` (tâche 1).
- Produces: `class PressScale extends StatefulWidget` avec `VoidCallback? onTap`, `ValueChanged<Offset>? onTapAt` (position globale du relâché), `Widget child`, `HitTestBehavior behavior` (défaut `opaque`), `static const double scale = 0.96`. La tâche 4 utilise `onTapAt`.

- [ ] **Step 1: Écrire le test qui échoue**

```dart
// flutter_app/test/press_scale_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/press_scale.dart';

void main() {
  double scaleOf(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

  testWidgets('shrinks under the finger, springs back on release, taps once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: PressScale(onTap: () => taps++, child: const SizedBox(width: 80, height: 40))),
    ));
    expect(scaleOf(tester), 1);

    final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    // The tap recognizer reports the down after its press timeout.
    await tester.pump(const Duration(milliseconds: 150));
    expect(scaleOf(tester), PressScale.scale);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 1);
  });

  testWidgets('a cancelled press springs back without tapping', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: PressScale(onTap: () => taps++, child: const SizedBox(width: 80, height: 40))),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 0);
  });

  testWidgets('onTapAt gets the global position of the release', (tester) async {
    Offset? at;
    await tester.pumpWidget(MaterialApp(
      home: Center(child: PressScale(onTapAt: (p) => at = p, child: const SizedBox(width: 80, height: 40))),
    ));
    final center = tester.getCenter(find.byType(PressScale));
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(at, center);
  });

  testWidgets('disabled (no callback): no feedback', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Center(child: PressScale(child: SizedBox(width: 80, height: 40))),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(PressScale)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(scaleOf(tester), 1);
    await gesture.up();
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `cd flutter_app && flutter test test/press_scale_test.dart`
Expected: FAIL, `Target of URI doesn't exist: 'package:dian_dian/widgets/press_scale.dart'`

- [ ] **Step 3: Écrire `press_scale.dart`**

```dart
// flutter_app/lib/widgets/press_scale.dart
import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Press feedback for the app's hand-drawn buttons: the child shrinks to
/// [scale] under the finger and springs back on release or cancel. It
/// replaces the `GestureDetector(onTap:)` that wrapped the button; any
/// `Semantics(button: true)` stays outside. [onTapAt] receives the global
/// position of the release, for a dialog that should be born there. With
/// neither callback the widget is inert.
class PressScale extends StatefulWidget {
  final VoidCallback? onTap;
  final ValueChanged<Offset>? onTapAt;
  final Widget child;
  final HitTestBehavior behavior;

  static const double scale = 0.96;

  const PressScale({
    super.key,
    this.onTap,
    this.onTapAt,
    required this.child,
    this.behavior = HitTestBehavior.opaque,
  });

  bool get enabled => onTap != null || onTapAt != null;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool pressed) {
    if (_pressed != pressed && mounted) setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled
          ? (details) {
              _set(false);
              widget.onTapAt?.call(details.globalPosition);
            }
          : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? PressScale.scale : 1,
        duration: AppMotion.of(context, AppMotion.press),
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
```

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

Run: `cd flutter_app && flutter test test/press_scale_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 5: Poser `PressScale` sur les boutons à fond et bordure**

Règle : un `GestureDetector(onTap: X, child: C)` dont `C` est un `Container` (ou un `DashedBorder`) dessiné comme un bouton (fond et bordure) devient `PressScale(onTap: X, child: C)`. L'argument `behavior:` éventuel est conservé tel quel. Les liens texte (« Mot de passe oublié », « Annuler » nu, « Gérer »), les croix de fermeture, les flèches, les icônes de barre, les tuiles des sélecteurs de thème / curseur / langue et les points de la grille ne changent pas. Ajouter `import '../widgets/press_scale.dart';` (ou `'press_scale.dart'` depuis `lib/widgets/`) dans chaque fichier touché. Numéros de ligne au début de la tâche :

| Fichier | Site |
|---|---|
| `lib/widgets/confirm_dialog.dart` | `_buildButton`, l. 101 |
| `lib/widgets/whats_new_dialog.dart` | bouton OK du pied, l. 29 (dans le `Semantics`) |
| `lib/screens/page_list_screen.dart` | le « + » flottant, l. 489 ; bouton Créer de `_CreateTrackerDialog`, l. 830 (celui au `Container`) |
| `lib/screens/settings_screen.dart` | `_buildLinkTile`, l. 287 ; `_buildActionButton`, l. 327 ; bouton Supprimer de `_DeleteAccountDialog`, l. 433 |
| `lib/screens/first_tracker_screen.dart` | `_ShellButton` l. 533, `_PrimaryButton` l. 573, `_Tile` l. 616, `_LegendButton` l. 744 |
| `lib/screens/login_screen.dart` | bouton Connexion, l. 203 |
| `lib/screens/register_screen.dart` | bouton Inscription, l. 196 |
| `lib/screens/forgot_password_screen.dart` | bouton d'envoi, l. 274 |
| `lib/widgets/oauth_buttons.dart` | l. 201 |
| `lib/screens/tracker_screen.dart` | Edit des légendes, l. 820 (`DashedBorder`) ; Aujourd'hui, l. 956 (`DashedBorder`, dans le `Semantics`) |
| `lib/widgets/cell_editor_dialog.dart` | bouton « Modifier les légendes » l. 49 ; boutons du pied l. 308, 326, 367, 416 |
| `lib/widgets/legend_editor_dialog.dart` | l. 289 (bouton au `Container`), l. 757 (Ajouter) |
| `lib/widgets/premium_gate_dialog.dart` | `_UpgradeButton` l. 195, `_StoreButton` l. 228 |
| `lib/widgets/custom_paywall_dialog.dart` | bouton Acheter l. 257, tuile de plan l. 535 |
| `lib/widgets/keep_trackers_dialog.dart` | bouton helper l. 147 |
| `lib/widgets/contact_dialog.dart` | l. 254, l. 287 |
| `lib/widgets/global_stats_dialog.dart` | l. 418 |
| `lib/widgets/download_app_banner.dart` | bouton l. 82 |

Exemple, `confirm_dialog.dart` :

```dart
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        // … inchangé
      ),
    );
```

Un `onTap` conditionnel (`_busy ? null : _create`, `enabled ? onTap : null`) reste tel quel : `PressScale` est inerte quand il reçoit `null`.

- [ ] **Step 6: Analyse et tests complets, puis commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/lib flutter_app/test/press_scale_test.dart
git commit -m "App: PressScale, buttons shrink to 0.96 under the finger (90 ms) and spring back; applied to every bordered button

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 3: `showAppDialog`, ouverture et fermeture de tous les pop-ups

**Files:**
- Modify: `flutter_app/lib/widgets/app_dialog.dart` (ajout de `originAlignment`, `showAppDialog`, `AppDialogRoute`)
- Modify (rename `showDialog` → `showAppDialog`, 17 sites): `settings_screen.dart:369`, `page_list_screen.dart:109`, `keep_trackers_dialog.dart:21`, `custom_paywall_dialog.dart:25`, `legend_editor_dialog.dart:21` et `:400`, `cursor_picker_dialog.dart:42`, `contact_dialog.dart:55`, `whats_new_dialog.dart:17`, `global_stats_dialog.dart:30`, `stats_detail_dialog.dart:30`, `cell_editor_dialog.dart:35` et `:75`, `theme_picker_dialog.dart:12`, `language_picker_dialog.dart:9`, `confirm_dialog.dart:34`, `premium_gate_dialog.dart:29`
- Test: `flutter_app/test/app_dialog_test.dart`

**Interfaces:**
- Consumes: `AppMotion` (tâche 1).
- Produces: `Alignment originAlignment(Offset origin, Size size)` ; `Future<T?> showAppDialog<T>({required BuildContext context, required WidgetBuilder builder, bool barrierDismissible = true, Offset? origin})` ; `class AppDialogRoute<T> extends RawDialogRoute<T>`. La tâche 4 passe `origin`.

- [ ] **Step 1: Écrire le test qui échoue**

```dart
// flutter_app/test/app_dialog_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/app_dialog.dart';

void main() {
  group('originAlignment', () {
    const size = Size(400, 800);
    test('centre, corners, and never outside the screen', () {
      expect(originAlignment(const Offset(200, 400), size), Alignment.center);
      expect(originAlignment(Offset.zero, size), Alignment.topLeft);
      expect(originAlignment(const Offset(400, 800), size), Alignment.bottomRight);
      final a = originAlignment(const Offset(399, 1), size);
      expect(a.x, inInclusiveRange(-1, 1));
      expect(a.y, inInclusiveRange(-1, 1));
    });
  });

  Widget host({Offset? origin, bool reduced = false}) => MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppDialog<void>(
                context: context,
                origin: origin,
                builder: (ctx) => TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('box')),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

  /// Largest scale among the Transforms above the dialog's text (1 when settled).
  double scaleAbove(WidgetTester tester, String text) {
    final transforms = find.ancestor(of: find.text(text), matching: find.byType(Transform));
    var scale = 1.0;
    for (final t in tester.widgetList<Transform>(transforms)) {
      final s = t.transform.getMaxScaleOnAxis();
      if (s < scale) scale = s;
    }
    return scale;
  }

  testWidgets('enters over base (scale under 1 midway, 1 when settled)', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.text('box'), findsOneWidget);
    expect(scaleAbove(tester, 'box'), lessThan(1));
    await tester.pumpAndSettle();
    expect(scaleAbove(tester, 'box'), 1);
  });

  testWidgets('leaves over quick, not longer', (tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('box'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('box'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('box'), findsNothing);
  });

  testWidgets('an origin anchors the scale there (not the centre)', (tester) async {
    await tester.pumpWidget(host(origin: const Offset(10, 10)));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    final transforms = find.ancestor(of: find.text('box'), matching: find.byType(Transform));
    final anchored = tester.widgetList<Transform>(transforms).any((t) => t.alignment != null && t.alignment != Alignment.center);
    expect(anchored, isTrue);
  });

  testWidgets('reduced motion: there at once, gone at once', (tester) async {
    await tester.pumpWidget(host(reduced: true));
    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump();
    expect(find.text('box'), findsOneWidget);
    expect(scaleAbove(tester, 'box'), 1);
    await tester.tap(find.text('box'));
    await tester.pump();
    await tester.pump();
    expect(find.text('box'), findsNothing);
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `cd flutter_app && flutter test test/app_dialog_test.dart`
Expected: FAIL, `The function 'originAlignment' isn't defined` / `showAppDialog`

- [ ] **Step 3: Ajouter la route et la fonction dans `app_dialog.dart`**

En tête de `lib/widgets/app_dialog.dart`, après les imports existants :

```dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Where a dialog's scale is anchored for a tap at [origin] on a screen of
/// [size]: born under the finger, settling at the centre.
Alignment originAlignment(Offset origin, Size size) => Alignment(
      ((origin.dx / size.width) * 2 - 1).clamp(-1.0, 1.0),
      ((origin.dy / size.height) * 2 - 1).clamp(-1.0, 1.0),
    );

/// The app's `showDialog`: same shape, plus the entrance (scale 0.92 → 1,
/// fade, 8 px rise over [AppMotion.base]) and the exit (scale 1 → 0.96 and
/// fade over [AppMotion.quick]). [origin], a global position, makes the box
/// seem to come from the tap. Always on the root navigator.
Future<T?> showAppDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  Offset? origin,
}) {
  final navigator = Navigator.of(context, rootNavigator: true);
  return navigator.push<T>(AppDialogRoute<T>(
    context: context,
    builder: builder,
    themes: InheritedTheme.capture(from: context, to: navigator.context),
    barrierDismissible: barrierDismissible,
    origin: origin,
    reduced: AppMotion.reduced(context),
  ));
}

class AppDialogRoute<T> extends RawDialogRoute<T> {
  final Offset? origin;
  final bool reduced;

  AppDialogRoute({
    required BuildContext context,
    required WidgetBuilder builder,
    required CapturedThemes themes,
    required this.origin,
    required this.reduced,
    super.barrierDismissible,
  }) : super(
          barrierColor: Colors.black54,
          barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
          transitionDuration: reduced ? Duration.zero : AppMotion.base,
          pageBuilder: (buildContext, animation, secondaryAnimation) {
            final child = themes.wrap(Builder(builder: builder));
            // Like DialogRoute: safe area, and taps inside never reach the barrier.
            return Semantics(
              hitTestBehavior: SemanticsHitTestBehavior.opaque,
              child: SafeArea(child: child),
            );
          },
        );

  @override
  Duration get reverseTransitionDuration => reduced ? Duration.zero : AppMotion.quick;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final alignment = origin == null ? Alignment.center : originAlignment(origin!, MediaQuery.sizeOf(context));
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final closing = animation.status == AnimationStatus.reverse;
        // Entering: value 0 → 1 through `enter`. Leaving: value 1 → 0, and
        // `exit` is applied on elapsed time so the box accelerates away.
        final t = closing
            ? 1 - AppMotion.exit.transform(1 - animation.value)
            : AppMotion.enter.transform(animation.value);
        final scale = closing ? lerpDouble(0.96, 1, t)! : lerpDouble(0.92, 1, t)!;
        final rise = closing ? 0.0 : 8 * (1 - t);
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, rise),
            child: Transform.scale(scale: scale, alignment: alignment, child: child),
          ),
        );
      },
    );
  }
}
```

Le reste du fichier (`class AppDialog`) ne change pas.

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

Run: `cd flutter_app && flutter test test/app_dialog_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 5: Faire passer les 17 appels par `showAppDialog`**

Dans chacun des fichiers listés en tête de tâche, remplacer `showDialog(` par `showAppDialog(` et `showDialog<bool>(` / `showDialog<PageModel?>(` par `showAppDialog<bool>(` / `showAppDialog<PageModel?>(`. Les paramètres `context:`, `builder:` et `barrierDismissible:` existants restent tels quels. Ajouter `import 'app_dialog.dart';` dans les widgets qui ne l'importent pas encore (`cursor_picker_dialog.dart`, `theme_picker_dialog.dart`, `custom_paywall_dialog.dart`, `premium_gate_dialog.dart` : vérifier avec `grep -L "app_dialog.dart" lib/widgets/*.dart lib/screens/*.dart`) et `import '../widgets/app_dialog.dart';` dans `settings_screen.dart` si absent.

Vérification : `grep -rn "showDialog(" lib` ne doit plus rien renvoyer en dehors de la définition de `showAppDialog`.

Dans `lib/widgets/whats_new_dialog.dart`, la cascade des puces part après l'entrée de la boîte (spec §3) : ajouter `import '../theme/motion.dart';` et, dans la boucle des puces, remplacer `duration:` et `curve:` par

```dart
                duration: Duration(milliseconds: AppMotion.base.inMilliseconds + 380 + 140 * i),
                curve: Interval(
                  (AppMotion.base.inMilliseconds + 140 * i) / (AppMotion.base.inMilliseconds + 380 + 140 * i),
                  1,
                  curve: AppMotion.enter,
                ),
```

- [ ] **Step 6: Analyse et tests complets, puis commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!` (les tests de dialogues existants font `pumpAndSettle`, qui absorbe les nouvelles durées)

```bash
git add flutter_app/lib flutter_app/test/app_dialog_test.dart
git commit -m "App: showAppDialog, every pop-up scales and fades in over 220 ms and out over 160 ms, optionally from the tap

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 4: Les pop-ups nés du point tapé et du bouton Edit

**Files:**
- Modify: `flutter_app/lib/widgets/tracker_grid.dart:12`, `:18`, `:154`
- Modify: `flutter_app/lib/widgets/cell_editor_dialog.dart:25-78`
- Modify: `flutter_app/lib/widgets/legend_editor_dialog.dart:20-25`
- Modify: `flutter_app/lib/screens/tracker_screen.dart:331-362` (`_buildGrid`), `:818-823` (Edit)
- Test: `flutter_app/test/tracker_grid_test.dart` (créé ici, complété en tâche 6)

**Interfaces:**
- Consumes: `showAppDialog(origin:)` (tâche 3), `PressScale.onTapAt` (tâche 2).
- Produces: `TrackerGrid.onCellPress` devient `void Function(int month, int day, Offset globalPosition)` ; `CellEditorDialog.show(context, {month, day, year, Offset? origin})` ; `LegendEditorDialog.show(context, {pageId, Offset? origin})`.

- [ ] **Step 1: Écrire le test qui échoue**

```dart
// flutter_app/test/tracker_grid_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/tracker_grid.dart';

void main() {
  Widget host({required void Function(int month, int day, Offset at) onPress}) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 260,
            height: 640,
            child: TrackerGrid(year: 2026, getCellColor: (_, __) => null, onCellPress: onPress),
          ),
        ),
      );

  testWidgets('a tap on a day reports month, day and where the finger was', (tester) async {
    final calls = <(int, int, Offset)>[];
    await tester.pumpWidget(host(onPress: (m, d, at) => calls.add((m, d, at))));
    // The first dot in tree order is January 1st (the header row has no detector).
    final jan1 = find.byType(GestureDetector).first;
    final center = tester.getCenter(jan1);
    await tester.tap(jan1);
    expect(calls, [(1, 1, center)]);
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `cd flutter_app && flutter test test/tracker_grid_test.dart`
Expected: FAIL, erreur de type sur `onCellPress` (deux paramètres attendus, trois fournis)

- [ ] **Step 3: Changer la signature de `TrackerGrid`**

Dans `lib/widgets/tracker_grid.dart` :

```dart
  /// Called with the global position of the tap, so the editor can be born
  /// from the dot.
  final void Function(int month, int day, Offset globalPosition) onCellPress;
```

et, dans le `GestureDetector` de chaque point (l. 154) :

```dart
                            child: GestureDetector(
                              onTapUp: valid ? (d) => onCellPress(month, day, d.globalPosition) : null,
```

(`onTap:` est retiré ; `onTapUp` seul suffit pour un tap.)

- [ ] **Step 4: Passer `origin` dans les deux `show`**

`lib/widgets/cell_editor_dialog.dart` :

```dart
  static Future<void> show(
    BuildContext context, {
    required int month,
    required int day,
    required int year,
    Offset? origin,
  }) {
    final legends = context.read<LegendsProvider>().legends;
    if (legends.isEmpty) {
      // … inchangé jusqu'à :
      return showAppDialog(
        context: context,
        origin: origin,
        builder: (ctx) => AppDialog(
        // … inchangé
      );
    }
    return showAppDialog(
      context: context,
      origin: origin,
      builder: (_) => CellEditorDialog(month: month, day: day, year: year),
    );
  }
```

`lib/widgets/legend_editor_dialog.dart` :

```dart
  static Future<void> show(BuildContext context, {required String pageId, Offset? origin}) {
    return showAppDialog(
      context: context,
      origin: origin,
      builder: (_) => LegendEditorDialog(pageId: pageId),
    );
  }
```

- [ ] **Step 5: Brancher le tracker**

`lib/screens/tracker_screen.dart`, `_buildGrid` :

```dart
            onCellPress: (month, day, at) {
              final existingCell = cellsProv.getCell(month, day);
              if (existingCell != null) {
                CellEditorDialog.show(context, month: month, day: day, year: _year, origin: at);
              } else if (_selectedLegendId != null) {
                try {
                  final legend = legends.firstWhere((l) => l.id == _selectedLegendId);
                  cellsProv.setCell(month, day, legend.color);
                } catch (_) {
                  setState(() => _selectedLegendId = null);
                }
              } else {
                CellEditorDialog.show(context, month: month, day: day, year: _year, origin: at);
              }
            },
```

Le bouton Edit (posé en `PressScale` à la tâche 2) :

```dart
                      child: PressScale(
                        onTapAt: (at) => LegendEditorDialog.show(context, pageId: _page.id, origin: at),
                        child: DashedBorder(
```

`_openToday` ne change pas (boîte au centre).

- [ ] **Step 6: Tests, analyse, commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/lib flutter_app/test/tracker_grid_test.dart
git commit -m "App: the cell editor is born from the tapped dot and the legend editor from the Edit button

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 5: `SlideSwitcher`, le changement d'année et les étapes du premier tracker

**Files:**
- Create: `flutter_app/lib/widgets/slide_switcher.dart`
- Modify: `flutter_app/lib/screens/tracker_screen.dart` (`_changeYear` l. 74, `_buildGrid` l. 331, `SwipeNav` l. 703-720)
- Modify: `flutter_app/lib/screens/page_list_screen.dart` (`_changeYear` l. 73, `SwipeNav` l. 210, `GridView.builder` l. 319)
- Modify: `flutter_app/lib/screens/first_tracker_screen.dart:294-296`
- Test: `flutter_app/test/slide_switcher_test.dart`

**Interfaces:**
- Consumes: `AppMotion` (tâche 1).
- Produces: `class SlideSwitcher extends StatelessWidget` avec `Widget child` (porte une `ValueKey`), `int direction` (+1 : le nouveau arrive de la droite, −1 : de la gauche, 0 : fondu seul), `double distance` (24), `bool expand` (false ; `StackFit.expand` pour un `GridView`) ; `static Offset enterFrom(int direction, double distance)`.

- [ ] **Step 1: Écrire le test qui échoue**

```dart
// flutter_app/test/slide_switcher_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/slide_switcher.dart';

class _Host extends StatefulWidget {
  const _Host();
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String label = 'a';
  int direction = 1;

  void show(String next, int dir) => setState(() {
        label = next;
        direction = dir;
      });

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Center(
          child: SlideSwitcher(
            direction: direction,
            child: Text(label, key: ValueKey(label)),
          ),
        ),
      );
}

void main() {
  test('enterFrom has the sign of the direction', () {
    expect(SlideSwitcher.enterFrom(1, 24), const Offset(24, 0));
    expect(SlideSwitcher.enterFrom(-1, 24), const Offset(-24, 0));
    expect(SlideSwitcher.enterFrom(0, 24), Offset.zero);
  });

  double dx(WidgetTester tester, String text) {
    final t = tester.widget<Transform>(find.ancestor(of: find.text(text), matching: find.byType(Transform)).first);
    return t.transform.getTranslation().x;
  }

  testWidgets('the entering child comes from the direction side, the leaving one goes the other way', (tester) async {
    await tester.pumpWidget(const _Host());
    tester.state<_HostState>(find.byType(_Host)).show('b', 1);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(dx(tester, 'b'), greaterThan(0));
    expect(dx(tester, 'a'), lessThan(0));
    await tester.pumpAndSettle();
    expect(find.text('a'), findsNothing);
    expect(dx(tester, 'b'), 0);
  });

  testWidgets('direction -1 mirrors it', (tester) async {
    await tester.pumpWidget(const _Host());
    tester.state<_HostState>(find.byType(_Host)).show('b', -1);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(dx(tester, 'b'), lessThan(0));
    expect(dx(tester, 'a'), greaterThan(0));
  });
}
```

- [ ] **Step 2: Lancer le test, vérifier qu'il échoue**

Run: `cd flutter_app && flutter test test/slide_switcher_test.dart`
Expected: FAIL, `Target of URI doesn't exist: 'package:dian_dian/widgets/slide_switcher.dart'`

- [ ] **Step 3: Écrire `slide_switcher.dart`**

```dart
// flutter_app/lib/widgets/slide_switcher.dart
import 'package:flutter/material.dart';

import '../theme/motion.dart';

/// Swaps [child] (which must carry a key, the year or the step) with a short
/// slide: the leaving child moves [distance] px against [direction] and
/// fades, the entering one arrives from the [direction] side. 0 is a plain
/// cross-fade. [expand] sizes the stage to its parent, for a `GridView`.
class SlideSwitcher extends StatelessWidget {
  final Widget child;
  final int direction;
  final double distance;
  final bool expand;

  const SlideSwitcher({
    super.key,
    required this.child,
    required this.direction,
    this.distance = 24,
    this.expand = false,
  });

  /// Where the entering child starts (and the leaving one ends, mirrored).
  static Offset enterFrom(int direction, double distance) => Offset(direction.sign * distance, 0);

  @override
  Widget build(BuildContext context) {
    final from = enterFrom(direction, distance);
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.base),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      layoutBuilder: (current, previous) => Stack(
        fit: expand ? StackFit.expand : StackFit.loose,
        alignment: Alignment.center,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, animation) {
        // The leaving child's animation runs 1 → 0: the same formula sends it the other way.
        final entering = child.key == this.child.key;
        final start = entering ? from : -from;
        return FadeTransition(
          opacity: animation,
          child: AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) => Transform.translate(
              offset: start * (1 - animation.value),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
```

- [ ] **Step 4: Lancer le test, vérifier qu'il passe**

Run: `cd flutter_app && flutter test test/slide_switcher_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: Le tracker glisse au changement d'année**

`lib/screens/tracker_screen.dart` : ajouter `import '../widgets/slide_switcher.dart';`, un champ `int _yearDirection = 0;` à côté de `late int _year;`, et dans `_changeYear` :

```dart
  void _changeYear(int delta) {
    final newYear = _year + delta;
    setState(() {
      _yearDirection = delta.sign;
      _year = newYear;
    });
```

`_buildGrid` : entourer la grille.

```dart
        child: Center(
          child: SlideSwitcher(
            direction: _yearDirection,
            child: KeyedSubtree(
              key: ValueKey(_year),
              child: TrackerGrid(
                // … inchangé
              ),
            ),
          ),
        ),
```

Le libellé d'année de la barre latérale (l. 703-720), les deux variantes :

```dart
                center: SlideSwitcher(
                  direction: _yearDirection,
                  distance: 12,
                  child: Text(
                    '$_year',
                    key: ValueKey(_year),
                    style: AppFonts.dot(fontSize: 12, color: AppColors.subtitle),
                  ),
                ),
```

et pour la version repliée :

```dart
              RotatedBox(
                quarterTurns: 3,
                child: SlideSwitcher(
                  direction: _yearDirection,
                  distance: 12,
                  child: Text(
                    '$_year',
                    key: ValueKey(_year),
                    style: AppFonts.pixel(fontSize: 9, color: AppColors.subtitle),
                  ),
                ),
              ),
```

- [ ] **Step 6: La liste glisse au changement d'année**

`lib/screens/page_list_screen.dart` : ajouter l'import, un champ `int _yearDirection = 0;`, et dans `_changeYear` :

```dart
  void _changeYear(int delta) {
    setState(() {
      _yearDirection = delta.sign;
      _selectedYear += delta;
    });
```

Le libellé (l. 215) :

```dart
                        center: SlideSwitcher(
                          direction: _yearDirection,
                          distance: 12,
                          child: Text(
                            '$_selectedYear',
                            key: ValueKey(_selectedYear),
                            style: AppFonts.pixel(fontSize: 20, color: AppColors.title),
                          ),
                        ),
```

La grille des cartes : dans le `LayoutBuilder` (l. 314), `return GridView.builder(` devient

```dart
                              return SlideSwitcher(
                                direction: _yearDirection,
                                expand: true,
                                child: KeyedSubtree(
                                  key: ValueKey(_selectedYear),
                                  child: GridView.builder(
                                    // … inchangé
                                  ),
                                ),
                              );
```

- [ ] **Step 7: Les deux étapes du premier tracker**

`lib/screens/first_tracker_screen.dart` l. 294 :

```dart
                        child: SlideSwitcher(
                          direction: 1,
                          child: KeyedSubtree(
                            key: ValueKey(_step),
                            child: _step == _Step.choose ? _buildChoose(lang) : _buildToday(lang),
                          ),
                        ),
```

- [ ] **Step 8: Tests, analyse, commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!` (`first_tracker_screen_test.dart` fait `pumpAndSettle` après chaque étape)

```bash
git add flutter_app/lib flutter_app/test/slide_switcher_test.dart
git commit -m "App: SlideSwitcher, the grid and the year label slide in the swipe's direction; first-tracker steps slide too

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 6: Le point qui se remplit

**Files:**
- Create: `flutter_app/lib/models/cell_change.dart`
- Modify: `flutter_app/lib/providers/cells_provider.dart` (`clear` l. 102, `_revert` l. 175, `setCell` l. 180, `deleteCell` l. 226)
- Modify: `flutter_app/lib/widgets/tracker_grid.dart` (paramètre `pop`, `cellCenter`, `DotPop`)
- Modify: `flutter_app/lib/screens/tracker_screen.dart` (`_buildGrid`)
- Test: `flutter_app/test/cells_provider_test.dart`, `flutter_app/test/tracker_grid_test.dart`

**Interfaces:**
- Consumes: `AppMotion` (tâche 1), `TrackerGrid` à trois paramètres (tâche 4).
- Produces: `class CellChange { String pageId; int year, month, day; String? color; bool erased; int seq; }` ; `CellsProvider.lastChange` (`CellChange?`) ; `TrackerGrid(pop: CellChange?)` ; `static Offset TrackerGrid.cellCenter({month, day, labelColWidth, cellSize, rowHeight})` ; `class DotPop extends StatelessWidget`.

- [ ] **Step 1: Tests du provider qui échouent**

Ajouter à `test/cells_provider_test.dart` (imports déjà présents : `http`, `MockClient`, `ApiService`, `AudioService`, `helpers.dart`) :

```dart
  group('lastChange', () {
    CellsProvider withServer({int status = 200}) {
      final client = MockClient((req) async {
        if (req.method == 'PUT' && req.url.path.startsWith('/api/cells/')) {
          return http.Response(
            '{"pageId":"a","year":2026,"month":1,"day":3,"color":"#111111","updatedAt":""}',
            status,
            headers: const {'content-type': 'application/json; charset=utf-8'},
          );
        }
        if (req.method == 'DELETE') return http.Response('', status == 200 ? 204 : status);
        return http.Response('{}', 404);
      });
      final p = CellsProvider(api: ApiService.custom(client: client, tokens: FakeTokens()), audio: AudioService.silent());
      p.applyBootstrap(2026, {'a': [[1, 1, '#AAAAAA']]});
      p.setContext(pageId: 'a', year: 2026);
      return p;
    }

    test('is null until this device changes a cell, then names the cell and its new colour', () async {
      final p = withServer();
      expect(p.lastChange, isNull);
      await p.setCell(1, 3, '#111111');
      final c = p.lastChange!;
      expect((c.pageId, c.year, c.month, c.day, c.color, c.erased), ('a', 2026, 1, 3, '#111111', false));
    });

    test('seq grows at every change, an erase keeps the old colour', () async {
      final p = withServer();
      await p.setCell(1, 3, '#111111');
      final first = p.lastChange!.seq;
      await p.deleteCell(1, 1);
      final c = p.lastChange!;
      expect(c.seq, greaterThan(first));
      expect((c.month, c.day, c.color, c.erased), (1, 1, '#AAAAAA', true));
    });

    test('a refused change is forgotten with the revert', () async {
      final p = withServer(status: 500);
      await p.setCell(1, 3, '#111111');
      expect(p.getCell(1, 3), isNull);
      expect(p.lastChange, isNull);
    });

    test('a bootstrap, a WS message or clear() never produce a pop', () async {
      final p = withServer();
      p.applyBootstrap(2026, {'a': [[2, 2, '#BBBBBB']]});
      expect(p.lastChange, isNull);
      p.debugHandleWs(const WsMessage(event: 'cell:updated', data: {
        'pageId': 'a', 'year': 2026, 'month': 3, 'day': 3, 'color': '#CCCCCC', 'updatedAt': '',
      }));
      expect(p.lastChange, isNull);
      await p.setCell(1, 3, '#111111');
      p.clear();
      expect(p.lastChange, isNull);
    });
  });
```

- [ ] **Step 2: Lancer, vérifier l'échec**

Run: `cd flutter_app && flutter test test/cells_provider_test.dart`
Expected: FAIL, `The getter 'lastChange' isn't defined`

- [ ] **Step 3: `CellChange` et `lastChange`**

```dart
// flutter_app/lib/models/cell_change.dart
/// The last cell this device changed, for the grid's pop. Never a change
/// from another device, a bootstrap or a recolor.
class CellChange {
  final String pageId;
  final int year;
  final int month;
  final int day;
  /// The new colour; on an erase, the colour that was there.
  final String? color;
  final bool erased;
  /// Grows at every change, so two taps on the same cell are two pops.
  final int seq;

  const CellChange({
    required this.pageId,
    required this.year,
    required this.month,
    required this.day,
    required this.color,
    required this.erased,
    required this.seq,
  });
}
```

Dans `lib/providers/cells_provider.dart` : `import '../models/cell_change.dart';`, puis sous `int _mutationEpoch = 0;` :

```dart
  CellChange? _lastChange;
  int _changeSeq = 0;

  /// The last cell this device changed (for the grid's pop); null after a
  /// revert, a clear, or before any local change.
  CellChange? get lastChange => _lastChange;
```

`clear()` : ajouter `_lastChange = null;` avant `notifyListeners()`.

`_revert` : ajouter `_lastChange = null;` en première ligne.

`setCell`, juste avant le premier `notifyListeners()` :

```dart
    _put(_entry(pageId, year).upsert(optimistic));
    _lastChange = CellChange(pageId: pageId, year: year, month: month, day: day, color: color, erased: false, seq: ++_changeSeq);
    notifyListeners();
```

`deleteCell`, juste avant le premier `notifyListeners()` :

```dart
    _put(_entry(pageId, year).remove(month, day));
    _lastChange = CellChange(pageId: pageId, year: year, month: month, day: day, color: previous.color, erased: true, seq: ++_changeSeq);
    notifyListeners();
```

et dans ses deux branches d'échec (statut refusé, exception), `_lastChange = null;` avant `_put(_entry(pageId, year).upsert(previous));`.

- [ ] **Step 4: Lancer, vérifier que ça passe**

Run: `cd flutter_app && flutter test test/cells_provider_test.dart`
Expected: PASS

- [ ] **Step 5: Tests de la grille qui échouent**

Ajouter à `test/tracker_grid_test.dart` (`import 'package:dian_dian/models/cell_change.dart';`) :

```dart
  group('cellCenter', () {
    test('January 1st and December 31st', () {
      const c = (labelColWidth: 20.0, cellSize: 18.0, rowHeight: 18.0);
      expect(TrackerGrid.cellCenter(month: 1, day: 1, labelColWidth: c.labelColWidth, cellSize: c.cellSize, rowHeight: c.rowHeight),
          const Offset(20 + 9, 18 + 9));
      expect(TrackerGrid.cellCenter(month: 12, day: 31, labelColWidth: c.labelColWidth, cellSize: c.cellSize, rowHeight: c.rowHeight),
          const Offset(20 + 18 * 11 + 9, 18 * 31 + 9));
    });
  });

  Widget popHost(CellChange? pop) => MaterialApp(
        home: Center(
          child: SizedBox(
            width: 260,
            height: 640,
            child: TrackerGrid(year: 2026, getCellColor: (_, __) => null, onCellPress: (_, __, ___) {}, pop: pop),
          ),
        ),
      );

  testWidgets('exactly one DotPop for the changed cell, none without a change', (tester) async {
    await tester.pumpWidget(popHost(null));
    expect(find.byType(DotPop), findsNothing);
    await tester.pumpWidget(popHost(const CellChange(pageId: 'a', year: 2026, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1)));
    await tester.pump();
    expect(find.byType(DotPop), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(DotPop), findsOneWidget);
  });

  testWidgets('a change on another year draws nothing', (tester) async {
    await tester.pumpWidget(popHost(const CellChange(pageId: 'a', year: 2025, month: 2, day: 5, color: '#FF0000', erased: false, seq: 1)));
    expect(find.byType(DotPop), findsNothing);
  });
```

- [ ] **Step 6: Lancer, vérifier l'échec**

Run: `cd flutter_app && flutter test test/tracker_grid_test.dart`
Expected: FAIL, `cellCenter` / `pop` / `DotPop` non définis

- [ ] **Step 7: `pop`, `cellCenter` et `DotPop` dans `tracker_grid.dart`**

Imports : `import '../models/cell_change.dart';` et `import '../theme/motion.dart';`. Champ et constructeur :

```dart
  /// The cell that just changed on this device, drawn once as a [DotPop]
  /// over the grid (null: nothing to pop).
  final CellChange? pop;

  const TrackerGrid({
    super.key,
    required this.year,
    required this.getCellColor,
    required this.onCellPress,
    this.pop,
  });

  /// Centre of the dot of (month, day) in the grid's own coordinates: one
  /// label column on the left, one header row on top.
  static Offset cellCenter({
    required int month,
    required int day,
    required double labelColWidth,
    required double cellSize,
    required double rowHeight,
  }) =>
      Offset(labelColWidth + cellSize * (month - 1) + cellSize / 2, rowHeight * day + rowHeight / 2);
```

Dans `build`, le `return SizedBox(width: gridW, height: gridH, child: Column(` devient

```dart
        final pop = this.pop;
        final popCenter = pop != null && pop.year == year
            ? cellCenter(month: pop.month, day: pop.day, labelColWidth: labelColWidth, cellSize: cellSize, rowHeight: rowHeight)
            : null;

        return SizedBox(
          width: gridW,
          height: gridH,
          child: Stack(
            children: [
              Column(
                // … tout le contenu existant, inchangé
              ),
              if (popCenter != null)
                Positioned(
                  left: popCenter.dx - dotSize / 2,
                  top: popCenter.dy - dotSize / 2,
                  width: dotSize,
                  height: dotSize,
                  child: IgnorePointer(
                    child: DotPop(
                      key: ValueKey(pop!.seq),
                      color: pop.color == null ? AppColors.dotEmpty : _parseColor(pop.color!),
                      erased: pop.erased,
                      size: dotSize,
                    ),
                  ),
                ),
            ],
          ),
        );
```

En fin de fichier :

```dart
/// The one animated widget of the grid: the dot that just changed, at its
/// new colour, 0.6 → 1.15 → 1 over [AppMotion.pop]; an erase shrinks the old
/// colour to nothing over [AppMotion.quick]. Keyed on the change's seq, so a
/// new change restarts it.
class DotPop extends StatelessWidget {
  final Color color;
  final bool erased;
  final double size;

  const DotPop({super.key, required this.color, required this.erased, required this.size});

  static final Animatable<double> fillScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.15).chain(CurveTween(curve: AppMotion.enter)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: AppMotion.exit)), weight: 40),
  ]);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.of(context, erased ? AppMotion.quick : AppMotion.pop),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
      builder: (context, t, child) {
        final scale = erased ? 1 - AppMotion.exit.transform(t) : fillScale.transform(t);
        return Opacity(
          opacity: erased ? 1 - t : 1,
          child: Transform.scale(scale: scale, child: child),
        );
      },
    );
  }
}
```

- [ ] **Step 8: Brancher le tracker**

`lib/screens/tracker_screen.dart`, `_buildGrid` : avant le `return`,

```dart
    final change = cellsProv.lastChange;
    final pop = change != null && change.pageId == _page.id && change.year == _year ? change : null;
```

et `pop: pop,` dans le `TrackerGrid(`.

- [ ] **Step 9: Tests, analyse, commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/lib flutter_app/test/cells_provider_test.dart flutter_app/test/tracker_grid_test.dart
git commit -m "App: the dot that just changed pops (0.6 → 1.15 → 1, 280 ms), an erase shrinks it; one animated widget, driven by CellsProvider.lastChange

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 7: La liste des trackers — carte publique, ancrages, cascade, apparition, suppression

**Files:**
- Create: `flutter_app/lib/widgets/morph_anchors.dart`
- Create: `flutter_app/lib/widgets/appear.dart`
- Modify: `flutter_app/lib/screens/page_list_screen.dart` (`PageListScreen` l. 31-46, état l. 49-70, `_createPage` l. 95-118, `_deletePage` l. 141-153, `GridView.builder` l. 319-331, carte l. 375-385, `_PageCard` l. 503-650)
- Test: `flutter_app/test/morph_anchors_test.dart`, `flutter_app/test/page_list_test.dart`

**Interfaces:**
- Consumes: `AppMotion`, `SlideSwitcher` (tâche 5).
- Produces:
  - `class MorphAnchors { GlobalKey shell; GlobalKey cardKey(String pageId); Rect? cardRect(String pageId, {RenderBox? ancestor}); Rect? shellRect({RenderBox? ancestor}); static Rect? rectOf(GlobalKey? key, {RenderBox? ancestor}); }`
  - `enum ListEntrance { cascade, none }` ; `Duration? entranceDelay(int index)` ; `({int columns, double rowExtent}) gridMetrics(double width)` ; `double revealScrollOffset({required int index, required int columns, required double rowExtent, required double spacing, required double viewportHeight, required double topPadding})` — tous dans `page_list_screen.dart`.
  - `class PageCard` (public, ex-`_PageCard`), `onTap` nullable, constructeur `PageCard.frozen({page, year, cells, legends, isLocked})`.
  - `PageListScreen` reçoit `MorphAnchors? anchors`, `ListEntrance entrance` (défaut `cascade`), `String? revealPageId`.
  - `enum AppearStyle { rise, pop, none }` ; `class Appear extends StatelessWidget` (`style`, `delay`, `child`).

- [ ] **Step 1: Tests des ancrages et des fonctions pures qui échouent**

```dart
// flutter_app/test/morph_anchors_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/widgets/morph_anchors.dart';

void main() {
  testWidgets('rects of laid-out keys, null for a key with no element', (tester) async {
    final anchors = MorphAnchors();
    await tester.pumpWidget(MaterialApp(
      home: Stack(children: [
        Positioned(left: 10, top: 20, child: SizedBox(key: anchors.cardKey('p'), width: 30, height: 40)),
        Positioned(left: 100, top: 200, child: SizedBox(key: anchors.shell, width: 50, height: 60)),
      ]),
    ));
    expect(anchors.cardRect('p'), const Rect.fromLTWH(10, 20, 30, 40));
    expect(anchors.shellRect(), const Rect.fromLTWH(100, 200, 50, 60));
    expect(anchors.cardRect('absent'), isNull);
    expect(anchors.cardKey('p'), same(anchors.cardKey('p')));
  });
}
```

```dart
// flutter_app/test/page_list_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/models/page_model.dart';
import 'package:dian_dian/screens/page_list_screen.dart';

void main() {
  test('entranceDelay: 30 ms per card for the first 12, none after', () {
    expect(entranceDelay(0), Duration.zero);
    expect(entranceDelay(3), const Duration(milliseconds: 90));
    expect(entranceDelay(11), const Duration(milliseconds: 330));
    expect(entranceDelay(12), isNull);
  });

  test('gridMetrics matches SliverGridDelegateWithMaxCrossAxisExtent on a phone', () {
    final m = gridMetrics(360);
    expect(m.columns, 2);
    expect(m.rowExtent, closeTo(368.9, 0.1));
  });

  test('revealScrollOffset: 0 for a row already on screen, just enough otherwise', () {
    expect(revealScrollOffset(index: 1, columns: 2, rowExtent: 300, spacing: 12, viewportHeight: 600, topPadding: 8), 0);
    // Row 2 (index 4) spans 8 + 2 × 312 = 632 → 932; a 600 px viewport must scroll 932 − 600 + 12.
    expect(revealScrollOffset(index: 4, columns: 2, rowExtent: 300, spacing: 12, viewportHeight: 600, topPadding: 8), 344);
  });

  testWidgets('PageCard.frozen has no delete cross and ignores taps', (tester) async {
    final page = PageModel.fromJson({
      'id': 'p', 'userId': 'u', 'title': 'T', 'year': 2026, 'position': 0, 'palette': null,
      'createdAt': '', 'recentCells': 0, 'lastCellAt': null, 'keepFree': false,
    });
    await tester.pumpWidget(MaterialApp(
      home: Center(child: SizedBox(width: 160, height: 350, child: PageCard.frozen(page: page, year: 2026, cells: null, legends: const [], isLocked: false))),
    ));
    expect(find.byIcon(Icons.close), findsNothing);
    await tester.tap(find.byType(PageCard));
    await tester.pump();
    expect(find.text('T'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Lancer, vérifier l'échec**

Run: `cd flutter_app && flutter test test/morph_anchors_test.dart test/page_list_test.dart`
Expected: FAIL, `morph_anchors.dart` absent ; `entranceDelay`, `gridMetrics`, `revealScrollOffset`, `PageCard` non définis

- [ ] **Step 3: `morph_anchors.dart`**

```dart
// flutter_app/lib/widgets/morph_anchors.dart
import 'package:flutter/widgets.dart';

/// The rectangles the card → tracker morph animates between: one key per
/// tracker card in the list (on the card inside the grid only, never on a
/// drag copy) and one on the tracker's book shell. Owned by `AppShell`, which
/// hands it to both screens. Only one list and one tracker live in the stage
/// at a time, so no key is ever mounted twice.
class MorphAnchors {
  final GlobalKey shell = GlobalKey(debugLabel: 'tracker shell');
  final Map<String, GlobalKey> _cards = {};

  GlobalKey cardKey(String pageId) => _cards.putIfAbsent(pageId, () => GlobalKey(debugLabel: 'card $pageId'));

  /// The card's rect in [ancestor]'s coordinates (global without one); null
  /// when the card is not laid out (off screen, deleted, list not shown).
  Rect? cardRect(String pageId, {RenderBox? ancestor}) => rectOf(_cards[pageId], ancestor: ancestor);

  Rect? shellRect({RenderBox? ancestor}) => rectOf(shell, ancestor: ancestor);

  static Rect? rectOf(GlobalKey? key, {RenderBox? ancestor}) {
    final box = key?.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: ancestor) & box.size;
  }
}
```

- [ ] **Step 4: `appear.dart`**

```dart
// flutter_app/lib/widgets/appear.dart
import 'package:flutter/material.dart';

import '../theme/motion.dart';

enum AppearStyle {
  /// Fade in while rising 10 px (the list's cascade).
  rise,
  /// Fade in while growing 0.8 → 1 (a card that just appeared).
  pop,
  none,
}

/// One-shot entrance of [child] over [AppMotion.base], after [delay].
/// The decision to animate is the parent's: the widget plays whatever style
/// it is given on its first build and must keep it (change the style and the
/// animation restarts or vanishes).
class Appear extends StatelessWidget {
  final AppearStyle style;
  final Duration delay;
  final Widget child;

  const Appear({super.key, required this.style, this.delay = Duration.zero, required this.child});

  @override
  Widget build(BuildContext context) {
    if (style == AppearStyle.none || AppMotion.reduced(context)) return child;
    final total = delay + AppMotion.base;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(delay.inMilliseconds / total.inMilliseconds, 1, curve: AppMotion.enter),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: style == AppearStyle.rise
            ? Transform.translate(offset: Offset(0, 10 * (1 - t)), child: child)
            : Transform.scale(scale: 0.8 + 0.2 * t, child: child),
      ),
    );
  }
}
```

- [ ] **Step 5: `PageCard` public et figée**

Dans `page_list_screen.dart`, renommer `_PageCard` → `PageCard` (quatre usages : la définition et trois constructions). Modifier la classe :

```dart
/// A card displaying a page with a full grid preview, legend dots, and title.
/// [PageCard.frozen] is the static copy the card → tracker morph stretches:
/// no handle, no cross, no tap.
class PageCard extends StatelessWidget {
  final PageModel page;
  final int year;
  final YearCells? cells;
  final List<LegendModel> legends;
  final VoidCallback? onTap;
  final VoidCallback onDelete;
  final bool isDragGhost;
  final bool isLocked;
  final Widget? dragHandle;
  final bool frozen;

  const PageCard({
    super.key,
    required this.page,
    required this.year,
    required this.cells,
    required this.legends,
    required this.onTap,
    required this.onDelete,
    this.isDragGhost = false,
    this.isLocked = false,
    this.dragHandle,
  }) : frozen = false;

  const PageCard.frozen({
    super.key,
    required this.page,
    required this.year,
    required this.cells,
    required this.legends,
    required this.isLocked,
  })  : onTap = null,
        onDelete = _noop,
        isDragGhost = false,
        dragHandle = null,
        frozen = true;

  static void _noop() {}
```

Dans `build` : `onTap: isDragGhost || frozen ? null : onTap,` et la croix `if (!isDragGhost && !frozen)`.

- [ ] **Step 6: Les fonctions pures de la liste**

En haut de `page_list_screen.dart`, après les imports (ajouter `import '../theme/motion.dart';`, `import '../widgets/appear.dart';`, `import '../widgets/morph_anchors.dart';`) :

```dart
enum ListEntrance { cascade, none }

/// The cascade: card [index] waits 30 ms per rank; from the 13th on, no animation.
Duration? entranceDelay(int index) => index < 12 ? Duration(milliseconds: 30 * index) : null;

const double _gridSidePadding = 8;
const double _gridTopPadding = 8;
const double _gridSpacing = 12;
const double _cardAspectRatio = 0.45;

/// Columns and card height for a list [width] px wide, computed the way
/// `SliverGridDelegateWithMaxCrossAxisExtent` does (180 px cards under 600,
/// 200 above).
({int columns, double rowExtent}) gridMetrics(double width) {
  final maxExtent = width < 600 ? 180.0 : 200.0;
  final usable = width - 2 * _gridSidePadding;
  final columns = ((usable + _gridSpacing) / (maxExtent + _gridSpacing)).ceil();
  final cardWidth = (usable - (columns - 1) * _gridSpacing) / columns;
  return (columns: columns, rowExtent: cardWidth / _cardAspectRatio);
}

/// Initial scroll offset that puts the row of card [index] in view: 0 when it
/// already is, otherwise just enough, with one spacing of breath.
double revealScrollOffset({
  required int index,
  required int columns,
  required double rowExtent,
  required double spacing,
  required double viewportHeight,
  required double topPadding,
}) {
  final row = index ~/ columns;
  final rowTop = topPadding + row * (rowExtent + spacing);
  final rowBottom = rowTop + rowExtent;
  if (rowBottom <= viewportHeight) return 0;
  return rowBottom - viewportHeight + spacing;
}
```

Remplacer les littéraux du `GridView.builder` par ces constantes : `padding: EdgeInsets.only(left: _gridSidePadding, right: _gridSidePadding, top: _gridTopPadding, bottom: …)`, `mainAxisSpacing: _gridSpacing, crossAxisSpacing: _gridSpacing, childAspectRatio: _cardAspectRatio`.

- [ ] **Step 7: Nouveaux paramètres et état de `PageListScreen`**

```dart
class PageListScreen extends StatefulWidget {
  final void Function(String id, int year) onSelectPage;
  final VoidCallback onOpenSettings;
  final int selectedYear;
  final ValueChanged<int> onYearChanged;
  /// Keys for the card → tracker morph (null in tests).
  final MorphAnchors? anchors;
  /// Cascade on arrival from login / settings; none when coming back from a tracker.
  final ListEntrance entrance;
  /// Coming back from this tracker: the grid opens scrolled so its card is in view.
  final String? revealPageId;

  const PageListScreen({
    super.key,
    required this.onSelectPage,
    required this.onOpenSettings,
    required this.selectedYear,
    required this.onYearChanged,
    this.anchors,
    this.entrance = ListEntrance.cascade,
    this.revealPageId,
  });
```

État, à côté des champs existants :

```dart
  final DateTime _entranceStart = DateTime.now();
  /// Decided once per card id on its first build and kept, so a rebuild
  /// never cuts an entrance short.
  final Map<String, ({AppearStyle style, Duration delay})> _appearance = {};
  late final Set<String> _seenIds;
  bool _firstBuildDone = false;
  String? _removingId;
  ScrollController? _scroll;
```

`initState` : après `_selectedYear = widget.selectedYear;`,

```dart
    _seenIds = context.read<PagesProvider>().pages.map((p) => p.id).toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => _firstBuildDone = true);
```

`dispose` (créer la méthode si absente) : `_scroll?.dispose(); super.dispose();`.

Décision d'apparition, méthode de l'état :

```dart
  ({AppearStyle style, Duration delay}) _appearanceOf(String id, int index) {
    return _appearance.putIfAbsent(id, () {
      if (_firstBuildDone && !_seenIds.contains(id)) {
        _seenIds.add(id);
        return (style: AppearStyle.pop, delay: Duration.zero);
      }
      final delay = entranceDelay(index);
      final fresh = DateTime.now().difference(_entranceStart) < const Duration(milliseconds: 600);
      if (widget.entrance == ListEntrance.cascade && fresh && delay != null) {
        return (style: AppearStyle.rise, delay: delay);
      }
      return (style: AppearStyle.none, delay: Duration.zero);
    });
  }
```

- [ ] **Step 8: Création, suppression, grille**

`_createPage` : la fin devient

```dart
    if (created != null && mounted) {
      // The new card is not an "appearance": the morph opens the tracker from
      // it once it has painted (centred fallback if it is off screen).
      _seenIds.add(created.id);
      _appearance[created.id] = (style: AppearStyle.none, delay: Duration.zero);
      setState(() {});
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      _openTracker(created);
    }
```

`_deletePage` : la fin devient

```dart
    if (confirmed != true || !mounted) return;

    // Shrink and fade first, then leave the grid.
    setState(() => _removingId = page.id);
    await Future<void>.delayed(AppMotion.of(context, AppMotion.quick));
    if (!mounted) return;
    context.read<PagesProvider>().softDeletePage(page);
    _appearance.remove(page.id);
    _seenIds.remove(page.id);
    setState(() => _removingId = null);
```

Le `GridView.builder` reçoit un contrôleur créé une fois, dans le `LayoutBuilder` de la grille (qui donne `constraints`) :

```dart
                            builder: (context, constraints) {
                              final metrics = gridMetrics(constraints.maxWidth);
                              final revealIndex = widget.revealPageId == null
                                  ? -1
                                  : sortedPages.indexWhere((p) => p.id == widget.revealPageId);
                              _scroll ??= ScrollController(
                                initialScrollOffset: revealIndex < 0
                                    ? 0
                                    : revealScrollOffset(
                                        index: revealIndex,
                                        columns: metrics.columns,
                                        rowExtent: metrics.rowExtent,
                                        spacing: _gridSpacing,
                                        viewportHeight: constraints.maxHeight,
                                        topPadding: _gridTopPadding,
                                      ),
                              );
                              final maxExtent = constraints.maxWidth < 600 ? 180.0 : 200.0;
                              return SlideSwitcher(
                                // … (tâche 5)
                                  child: GridView.builder(
                                    controller: _scroll,
```

La carte dans `itemBuilder` (l. 375) :

```dart
                                            final appearance = _appearanceOf(page.id, index);
                                            final removing = _removingId == page.id;
                                            return Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                Appear(
                                                  key: ValueKey('appear_${page.id}'),
                                                  style: appearance.style,
                                                  delay: appearance.delay,
                                                  child: AnimatedScale(
                                                    scale: removing ? 0.85 : 1,
                                                    duration: AppMotion.of(context, AppMotion.quick),
                                                    curve: AppMotion.exit,
                                                    child: AnimatedOpacity(
                                                      opacity: removing ? 0 : 1,
                                                      duration: AppMotion.of(context, AppMotion.quick),
                                                      child: PageCard(
                                                        key: widget.anchors?.cardKey(page.id),
                                                        page: page,
                                                        year: _selectedYear,
                                                        cells: previewCells,
                                                        legends: previewLegends,
                                                        onTap: removing ? null : () => _openTracker(page),
                                                        onDelete: () => _deletePage(page),
                                                        // … isDragGhost, isLocked, dragHandle inchangés
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                // Drop highlight overlay, inchangé
```

(`final appearance = …` et `final removing = …` se placent avant le `return Stack(` du `builder` du `DragTarget`.) La copie du glisser-déposer (`feedback:`) garde `PageCard(` sans clé.

- [ ] **Step 9: Lancer, vérifier que ça passe**

Run: `cd flutter_app && flutter test test/morph_anchors_test.dart test/page_list_test.dart`
Expected: PASS (5 tests)

- [ ] **Step 10: Tests, analyse, commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/lib flutter_app/test/morph_anchors_test.dart flutter_app/test/page_list_test.dart
git commit -m "App: tracker list — cards cascade in on arrival, a new card pops, a deleted one shrinks away; PageCard public with a frozen copy; MorphAnchors and reveal scroll for the morph

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 8: `ScreenStage`, la scène d'écrans et le morphing

**Files:**
- Create: `flutter_app/lib/widgets/screen_stage.dart`
- Test: `flutter_app/test/screen_stage_test.dart`

**Interfaces:**
- Consumes: `MorphAnchors` (tâche 7), `AppMotion`, `AppColors.shell` / `shellBorder`.
- Produces: `enum StageTransition { fade, slideIn, slideOut, morphOpen, morphClose }` ; `class ScreenStage extends StatefulWidget` (`Widget child` à clé, `StageTransition transition`, `MorphAnchors anchors`, `String? morphPageId`, `WidgetBuilder? morphCard`, `VoidCallback? onSettled`) ; `class MorphShell extends StatelessWidget` (la coque, pour les tests) ; `static const Size ScreenStage.fallbackSize = Size(120, 260)`.

- [ ] **Step 1: Écrire les tests qui échouent**

```dart
// flutter_app/test/screen_stage_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/theme/motion.dart';
import 'package:dian_dian/widgets/morph_anchors.dart';
import 'package:dian_dian/widgets/screen_stage.dart';

/// Two fake screens: 'list' holds a card anchored as page 'p', 'tracker'
/// holds a shell; anything else is plain text.
class _Host extends StatefulWidget {
  final MorphAnchors anchors;
  final bool reduced;
  const _Host({required this.anchors, this.reduced = false});
  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String screen = 'list';
  StageTransition transition = StageTransition.fade;
  int settled = 0;

  void go(String next, StageTransition t) => setState(() {
        screen = next;
        transition = t;
      });

  Widget _screen(String name) => switch (name) {
        'list' => Stack(key: const ValueKey('list'), children: [
            Positioned(left: 20, top: 40, child: SizedBox(key: widget.anchors.cardKey('p'), width: 60, height: 120, child: const Text('list'))),
          ]),
        'tracker' => Center(key: const ValueKey('tracker'), child: SizedBox(key: widget.anchors.shell, width: 200, height: 400, child: const Text('tracker'))),
        'bare' => const Center(key: ValueKey('bare'), child: Text('bare')),
        _ => Center(key: ValueKey(name), child: Text(name)),
      };

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQueryData(disableAnimations: widget.reduced),
        child: MaterialApp(
          home: ScreenStage(
            transition: transition,
            anchors: widget.anchors,
            morphPageId: 'p',
            morphCard: (_) => const Text('copy'),
            onSettled: () => settled++,
            child: _screen(screen),
          ),
        ),
      );
}

void main() {
  _HostState state(WidgetTester tester) => tester.state<_HostState>(find.byType(_Host));

  testWidgets('fade: both screens midway, only the new one once settled', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.fade);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.text('list'), findsOneWidget);
    expect(find.text('bare'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
    expect(find.text('bare'), findsOneWidget);
    expect(state(tester).settled, 1);
  });

  testWidgets('morphOpen: a shell between the card and the tracker shell, gone at the end', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump(); // measure frame: tracker laid out invisible
    await tester.pump(); // animation starts
    await tester.pump(AppMotion.screen ~/ 2);
    expect(find.byType(MorphShell), findsOneWidget);
    expect(find.text('copy'), findsOneWidget);
    final shell = tester.getRect(find.byType(MorphShell));
    expect(shell.width, greaterThan(60));
    expect(shell.width, lessThan(200));
    await tester.pumpAndSettle();
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('list'), findsNothing);
    expect(find.text('tracker'), findsOneWidget);
  });

  testWidgets('morphClose ends on the list with no shell left', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pumpAndSettle();
    state(tester).go('list', StageTransition.morphClose);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.screen ~/ 2);
    expect(find.byType(MorphShell), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('tracker'), findsNothing);
    expect(find.text('list'), findsOneWidget);
  });

  testWidgets('morphOpen without a shell to measure falls back to a fade', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.morphOpen);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 2);
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('bare'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('list'), findsNothing);
  });

  testWidgets('a navigation mid-transition ends it and fades to the newest screen', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump();
    await tester.pump();
    await tester.pump(AppMotion.screen ~/ 3);
    state(tester).go('bare', StageTransition.slideIn);
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.byType(MorphShell), findsNothing);
    expect(find.text('bare'), findsOneWidget);
    expect(find.text('tracker'), findsNothing);
    expect(find.text('list'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a resize mid-transition jumps to the end', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_Host(anchors: MorphAnchors()));
    state(tester).go('bare', StageTransition.slideIn);
    await tester.pump();
    await tester.pump(AppMotion.base ~/ 3);
    tester.view.physicalSize = const Size(1200, 800);
    await tester.pump();
    await tester.pump();
    expect(find.text('list'), findsNothing);
    expect(find.text('bare'), findsOneWidget);
  });

  testWidgets('reduced motion: the screen is swapped at once', (tester) async {
    await tester.pumpWidget(_Host(anchors: MorphAnchors(), reduced: true));
    state(tester).go('tracker', StageTransition.morphOpen);
    await tester.pump();
    expect(find.text('list'), findsNothing);
    expect(find.text('tracker'), findsOneWidget);
    expect(find.byType(MorphShell), findsNothing);
  });
}
```

- [ ] **Step 2: Lancer, vérifier l'échec**

Run: `cd flutter_app && flutter test test/screen_stage_test.dart`
Expected: FAIL, `Target of URI doesn't exist: 'package:dian_dian/widgets/screen_stage.dart'`

- [ ] **Step 3: Écrire `screen_stage.dart`**

```dart
// flutter_app/lib/widgets/screen_stage.dart
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/motion.dart';
import 'morph_anchors.dart';

enum StageTransition {
  /// Cross-fade over [AppMotion.base].
  fade,
  /// Fade plus an 8 % slide from the right (into the settings).
  slideIn,
  /// Fade plus an 8 % slide from the left (back from the settings).
  slideOut,
  /// The tracker grows out of its card over [AppMotion.screen].
  morphOpen,
  /// The tracker shrinks back into its card.
  morphClose,
}

/// The app's screen switcher: the previous screen leaves while the new one
/// arrives, the way [transition] says. For the two morphs a [MorphShell]
/// animates between the card's rect and the tracker shell's rect, both
/// measured through [anchors] after one frame where the incoming screen is
/// laid out invisible. A navigation during a transition ends it at once and
/// the next one plays as a fade. A size change (rotation, keyboard) ends it
/// too. Under reduced motion the screens are simply swapped.
class ScreenStage extends StatefulWidget {
  /// The current screen; its key tells one screen from the next.
  final Widget child;
  final StageTransition transition;
  final MorphAnchors anchors;
  /// The card to morph from (open) or to (close).
  final String? morphPageId;
  /// A static copy of that card, stretched inside the shell.
  final WidgetBuilder? morphCard;
  final VoidCallback? onSettled;

  /// Where the shell comes from or goes to when no card rect is known.
  static const Size fallbackSize = Size(120, 260);
  static const double slideFraction = 0.08;

  const ScreenStage({
    super.key,
    required this.child,
    required this.transition,
    required this.anchors,
    this.morphPageId,
    this.morphCard,
    this.onSettled,
  });

  @override
  State<ScreenStage> createState() => _ScreenStageState();
}

class _ScreenStageState extends State<ScreenStage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this)..addStatusListener(_onStatus);

  Widget? _outgoing;
  StageTransition _running = StageTransition.fade;
  /// The frame where the incoming screen is laid out at opacity 0 so its
  /// anchor can be measured.
  bool _measuring = false;
  Rect? _cardRect;
  Rect? _shellRect;
  Size? _lastSize;

  bool get _animating => _outgoing != null;
  bool get _isMorph => _running == StageTransition.morphOpen || _running == StageTransition.morphClose;
  RenderBox? get _box => context.findRenderObject() as RenderBox?;

  @override
  void didUpdateWidget(ScreenStage old) {
    super.didUpdateWidget(old);
    if (widget.child.key == old.child.key) return;
    final interrupted = _animating;
    if (interrupted) _finish(notify: false);
    if (AppMotion.reduced(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onSettled?.call());
      return;
    }
    _start(old.child, interrupted ? StageTransition.fade : widget.transition);
  }

  void _start(Widget outgoing, StageTransition transition) {
    _outgoing = outgoing;
    _running = transition;
    _cardRect = null;
    _shellRect = null;
    if (!_isMorph) {
      _controller.duration = AppMotion.base;
      _controller.forward(from: 0);
      return;
    }
    final pageId = widget.morphPageId;
    if (transition == StageTransition.morphOpen && pageId != null) {
      // The list is still laid out: read the card now.
      _cardRect = widget.anchors.cardRect(pageId, ancestor: _box);
    }
    _measuring = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _afterMeasure());
  }

  void _afterMeasure() {
    if (!mounted || !_measuring) return;
    _measuring = false;
    final pageId = widget.morphPageId;
    _shellRect = widget.anchors.shellRect(ancestor: _box);
    if (_running == StageTransition.morphClose && pageId != null) {
      _cardRect = widget.anchors.cardRect(pageId, ancestor: _box);
    }
    if (_shellRect == null) {
      // Nothing to morph (the tracker left at its first build): a fade.
      _running = StageTransition.fade;
      _controller.duration = AppMotion.base;
    } else {
      _controller.duration = AppMotion.screen;
    }
    setState(() {});
    _controller.forward(from: 0);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish(notify: true);
  }

  void _finish({required bool notify}) {
    _controller.stop();
    _outgoing = null;
    _measuring = false;
    _cardRect = null;
    _shellRect = null;
    if (mounted) setState(() {});
    if (notify) widget.onSettled?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest;
      if (_lastSize != null && _lastSize != size && _animating) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _animating) _finish(notify: true);
        });
      }
      _lastSize = size;

      final outgoing = _outgoing;
      if (outgoing == null) return widget.child;
      if (_measuring) {
        return Stack(fit: StackFit.expand, children: [
          outgoing,
          IgnorePointer(child: Opacity(opacity: 0, child: widget.child)),
        ]);
      }
      return IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Stack(fit: StackFit.expand, children: _layers(outgoing, size)),
        ),
      );
    });
  }

  static double _window(double e, double from, double to) => ((e - from) / (to - from)).clamp(0.0, 1.0);

  List<Widget> _layers(Widget outgoing, Size size) {
    final incoming = widget.child;
    final t = _controller.value;
    switch (_running) {
      case StageTransition.fade:
        final e = AppMotion.enter.transform(t);
        return [Opacity(opacity: 1 - e, child: outgoing), Opacity(opacity: e, child: incoming)];
      case StageTransition.slideIn:
      case StageTransition.slideOut:
        final e = AppMotion.enter.transform(t);
        final sign = _running == StageTransition.slideIn ? 1.0 : -1.0;
        final shift = size.width * ScreenStage.slideFraction;
        return [
          Opacity(
            opacity: 1 - e,
            child: Transform.translate(offset: Offset(-sign * shift * e, 0), child: outgoing),
          ),
          Opacity(
            opacity: e,
            child: Transform.translate(offset: Offset(sign * shift * (1 - e), 0), child: incoming),
          ),
        ];
      case StageTransition.morphOpen:
        final e = AppMotion.enter.transform(t);
        final fallback = _cardRect == null;
        final card = _cardRect ?? _centered(size);
        return [
          Opacity(opacity: 1 - _window(e, 0, 0.6), child: outgoing),
          MorphShell(
            rect: Rect.lerp(card, _shellRect, e)!,
            radius: lerpDouble(10, 14, e)!,
            opacity: fallback ? _window(e, 0, 0.4) : 1,
            cardSize: card.size,
            cardOpacity: 1 - _window(e, 0, 0.4),
            card: widget.morphCard,
          ),
          Opacity(opacity: _window(e, 0.4, 1), child: incoming),
        ];
      case StageTransition.morphClose:
        final e = AppMotion.exit.transform(t);
        final fallback = _cardRect == null;
        final card = _cardRect ?? _centered(size);
        return [
          Opacity(opacity: _window(e, 0.4, 1), child: incoming),
          MorphShell(
            rect: Rect.lerp(_shellRect, card, e)!,
            radius: lerpDouble(14, 10, e)!,
            opacity: fallback ? 1 - _window(e, 0.6, 1) : 1,
            cardSize: card.size,
            cardOpacity: fallback ? 0 : _window(e, 0.6, 1),
            card: widget.morphCard,
          ),
          Opacity(opacity: 1 - _window(e, 0, 0.4), child: outgoing),
        ];
    }
  }

  static Rect _centered(Size size) => Rect.fromCenter(
        center: size.center(Offset.zero),
        width: ScreenStage.fallbackSize.width,
        height: ScreenStage.fallbackSize.height,
      );
}

/// The shell that grows from the card to the tracker (and back): the shell
/// colour and border, the radius in between, and inside it the card's copy
/// stretched to the shell's width.
class MorphShell extends StatelessWidget {
  final Rect rect;
  final double radius;
  final double opacity;
  final Size cardSize;
  final double cardOpacity;
  final WidgetBuilder? card;

  const MorphShell({
    super.key,
    required this.rect,
    required this.radius,
    required this.opacity,
    required this.cardSize,
    required this.cardOpacity,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final card = this.card;
    return Positioned.fromRect(
      rect: rect,
      child: Opacity(
        opacity: opacity,
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.shell,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: AppColors.shellBorder),
          ),
          child: card == null || cardOpacity == 0
              ? null
              : Opacity(
                  opacity: cardOpacity,
                  child: FittedBox(
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    clipBehavior: Clip.hardEdge,
                    child: SizedBox(
                      width: cardSize.width,
                      height: cardSize.height,
                      child: Builder(builder: card),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Lancer, vérifier que ça passe**

Run: `cd flutter_app && flutter test test/screen_stage_test.dart`
Expected: PASS (7 tests). Si le test « resize » ne finit pas, vérifier que le `LayoutBuilder` reçoit bien une taille différente (le `MaterialApp` du hôte prend toute la vue).

- [ ] **Step 5: Analyse et commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/lib/widgets/screen_stage.dart flutter_app/test/screen_stage_test.dart
git commit -m "App: ScreenStage, the screen switcher with fade, slide and the card → tracker morph (measured anchors, fallbacks, interrupt and resize handling)

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 9: Brancher `AppShell` et le tracker sur la scène

**Files:**
- Modify: `flutter_app/lib/main.dart` (`_AppShellState` l. 141-156, `_startSessionInner` l. 181-247, `_onAuthChange` l. 370-381, `_navigate` l. 383-395, `build` l. 420-440, `_buildAppScreen` l. 487-539)
- Modify: `flutter_app/lib/screens/tracker_screen.dart` (`TrackerScreen` l. 27-45, `_buildBookShell` l. 373)
- Test: `flutter_app/test/back_navigation_test.dart`

**Interfaces:**
- Consumes: `ScreenStage`, `StageTransition` (tâche 8) ; `MorphAnchors`, `PageCard.frozen`, `ListEntrance`, `PageListScreen(anchors:, entrance:, revealPageId:)` (tâche 7).
- Produces: `StageTransition transitionFor(AppScreen from, AppScreen to)` (fonction de haut niveau dans `main.dart`) ; `TrackerScreen(anchors: MorphAnchors?)`.

- [ ] **Step 1: Test de `transitionFor` qui échoue**

Ajouter à `test/back_navigation_test.dart` (`import 'package:dian_dian/widgets/screen_stage.dart';`) :

```dart
  group('transitionFor', () {
    test('list ↔ tracker morph, settings slide, everything else fades', () {
      expect(transitionFor(AppScreen.pageList, AppScreen.tracker), StageTransition.morphOpen);
      expect(transitionFor(AppScreen.tracker, AppScreen.pageList), StageTransition.morphClose);
      expect(transitionFor(AppScreen.pageList, AppScreen.settings), StageTransition.slideIn);
      expect(transitionFor(AppScreen.tracker, AppScreen.settings), StageTransition.slideIn);
      expect(transitionFor(AppScreen.settings, AppScreen.pageList), StageTransition.slideOut);
      expect(transitionFor(AppScreen.firstTracker, AppScreen.tracker), StageTransition.fade);
      expect(transitionFor(AppScreen.login, AppScreen.register), StageTransition.fade);
    });
  });
```

- [ ] **Step 2: Lancer, vérifier l'échec**

Run: `cd flutter_app && flutter test test/back_navigation_test.dart`
Expected: FAIL, `The function 'transitionFor' isn't defined`

- [ ] **Step 3: `transitionFor` et l'état de la scène dans `main.dart`**

Imports : `import 'screens/page_list_screen.dart';` existe déjà ; ajouter `import 'widgets/morph_anchors.dart';` et `import 'widgets/screen_stage.dart';`. Sous `systemBackTarget` :

```dart
/// How the stage goes from [from] to [to]: the tracker morphs out of and
/// back into its card, the settings slide in and out, everything else fades.
StageTransition transitionFor(AppScreen from, AppScreen to) => switch ((from, to)) {
      (AppScreen.pageList, AppScreen.tracker) => StageTransition.morphOpen,
      (AppScreen.tracker, AppScreen.pageList) => StageTransition.morphClose,
      (AppScreen.pageList, AppScreen.settings) || (AppScreen.tracker, AppScreen.settings) => StageTransition.slideIn,
      (AppScreen.settings, AppScreen.pageList) => StageTransition.slideOut,
      _ => StageTransition.fade,
    };
```

Champs de `_AppShellState`, après `int _selectedYear = …;` :

```dart
  // The stage: how the next screen arrives, and the card it morphs from or to.
  final MorphAnchors _anchors = MorphAnchors();
  StageTransition _transition = StageTransition.fade;
  String? _morphPageId;
  ListEntrance _listEntrance = ListEntrance.cascade;
  String? _revealPageId;
```

- [ ] **Step 4: `_navigate` choisit la transition**

```dart
  void _navigate(AppScreen screen, {String? pageId}) {
    final from = _screen;
    final leavingPageId = _activePageId;
    final transition = transitionFor(from, screen);
    setState(() {
      _transition = transition;
      _morphPageId = switch (transition) {
        StageTransition.morphOpen => pageId,
        StageTransition.morphClose => leavingPageId,
        _ => null,
      };
      // Back from a tracker: the list opens on its card and skips the cascade.
      _revealPageId = transition == StageTransition.morphClose ? leavingPageId : null;
      _listEntrance = from == AppScreen.tracker ? ListEntrance.none : ListEntrance.cascade;
      _screen = screen;
      if (pageId != null) _activePageId = pageId;
    });
    if (screen == AppScreen.tracker && pageId != null) {
      _saveLastTracker(pageId, _selectedYear);
    } else if (screen == AppScreen.pageList) {
      // User explicitly went back to the list — forget which tracker was open.
      _clearLastTracker();
      _activePageId = null;
    }
  }
```

Les trois `setState` de `_startSessionInner` (premier tracker, tracker restauré, liste) et celui de `_onAuthChange` (retour à la connexion) ajoutent chacun `_transition = StageTransition.fade; _morphPageId = null; _revealPageId = null;` en tête de leur bloc.

- [ ] **Step 5: La scène dans `build`**

Le bloc non authentifié :

```dart
            if (!auth.isAuthenticated) {
              return ScreenStage(
                transition: StageTransition.fade,
                anchors: _anchors,
                child: _buildAuthScreen(),
              );
            }
```

Le premier enfant du `Stack` authentifié :

```dart
                ScreenStage(
                  transition: _transition,
                  anchors: _anchors,
                  morphPageId: _morphPageId,
                  morphCard: _morphPageId == null ? null : (ctx) => _buildCardCopy(ctx, _morphPageId!),
                  child: _buildAppScreen(),
                ),
```

Méthode de l'état :

```dart
  /// The static card the morph shell stretches: the page as the list shows
  /// it, from the providers (nothing if it vanished meanwhile).
  Widget _buildCardCopy(BuildContext ctx, String pageId) {
    final pages = ctx.read<PagesProvider>().pages;
    final page = pages.where((p) => p.id == pageId).firstOrNull;
    if (page == null) return const SizedBox.shrink();
    return PageCard.frozen(
      page: page,
      year: _selectedYear,
      cells: ctx.read<CellsProvider>().cellsFor(pageId, _selectedYear),
      legends: ctx.read<LegendsProvider>().legendsFor(pageId),
      isLocked: ctx.read<PremiumProvider>().lockedTrackerIds(pages).contains(pageId),
    );
  }
```

Dans `_buildAppScreen` : `TrackerScreen(` reçoit `anchors: _anchors,` ; `PageListScreen(` reçoit `anchors: _anchors, entrance: _listEntrance, revealPageId: _revealPageId,`.

- [ ] **Step 6: La coque du tracker porte la clé**

`lib/screens/tracker_screen.dart` : `import '../widgets/morph_anchors.dart';`, champ `final MorphAnchors? anchors;` dans `TrackerScreen` avec `this.anchors,` dans le constructeur, et dans `_buildBookShell` :

```dart
    final content = Container(
      key: widget.anchors?.shell,
      decoration: BoxDecoration(
```

- [ ] **Step 7: Tests, analyse, commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/lib/main.dart flutter_app/lib/screens/tracker_screen.dart flutter_app/test/back_navigation_test.dart
git commit -m "App: AppShell drives ScreenStage — the tracker morphs out of its card and back, settings slide, the list opens on the card it came from

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

---

### Task 10: Vérification sur appareil

**Files:** aucun changement attendu ; corrections éventuelles committées une à une avec le test qui les couvre.

- [ ] **Step 1: Lancer sur un iPhone et sur un Android**

Run: `make run` à la racine (ou `cd flutter_app && flutter run -d <id>` après `flutter devices`).

- [ ] **Step 2: Dérouler la liste, en notant ce qui cloche**

1. Liste → tracker par un tap sur une carte : la coque part de la carte, le tracker apparaît dessus sans saut de couleur. Retour par la flèche, par le retour système, par le swipe de bord : la coque rentre dans la carte.
2. Avec plus de six trackers (compte premium ou VIP de test, jamais en touchant le drapeau VIP en base) : ouvrir la dernière carte, revenir : la liste s'ouvre défilée sur elle.
3. Supprimer le tracker ouvert depuis un autre appareil pendant qu'il est affiché : retour à la liste en fondu, pas d'exception dans la console.
4. Tablette : tourner pendant une ouverture : l'écran d'arrivée est entier.
5. Tous les pop-ups : point (naît du point), Edit (naît du bouton), stats, export, Nouveau tracker, confirmation de suppression, réglages (langue, thème, curseur, contact, déconnexion, suppression de compte), paywall, Nouveautés (`debugAlwaysShowWhatsNew`).
6. Poser un point au pinceau et depuis l'éditeur, l'effacer : pop puis rétraction. Couper le réseau, poser un point : il revient sans garder la couleur.
7. Changer d'année par swipe et par flèche dans la liste et dans le tracker, puis Aujourd'hui depuis une autre année.
8. Appuyer sur chaque type de bouton : il se tasse. Annuler un appui en glissant hors du bouton : il revient sans action.
9. Liste : arrivée depuis la connexion (cascade), depuis les réglages (cascade), depuis un tracker (pas de cascade) ; créer un tracker (morphing direct) ; supprimer puis annuler (rétraction, puis pop au retour).
10. iOS Réglages → Accessibilité → Mouvement → Réduire les animations, et Android Options développeur → échelle d'animation 0 : tout est instantané, rien ne reste invisible.

- [ ] **Step 3: Relevé de performance**

Dans DevTools (`flutter run` puis la touche `v`), onglet Performance, « Track widget rebuilds » : taper une case avant la branche (sur `master`, à titre de référence) et après ; le nombre de widgets rebuildés par tap doit être identique à un près (le `DotPop`).

- [ ] **Step 4: Consigner**

Toute correction : un commit par défaut, avec son test. Si rien ne cloche : rien à committer.

---

### Task 11: Notes de version et bascule sur `master`

**Files:**
- Modify: `flutter_app/CHANGELOG.md` (section `## [Unreleased]`)
- Create: `flutter_app/docs/changelogs/1.5.0.md`
- Modify: `flutter_app/lib/data/whats_new.dart`
- Modify: `flutter_app/test/whats_new_test.dart`

À faire **une fois `app-v1.4.0` taguée sur `master`** (sinon les deux sections `Unreleased` se mélangent au merge) : `git rebase master` sur `feat/animations`, puis :

- [ ] **Step 1: Test des puces 1.5.0 qui échoue**

Dans `test/whats_new_test.dart`, le test `'1.4.0 has three to six bullets in every language'` devient une boucle sur `['1.4.0', '1.5.0']` ; même chose pour le test `vous / tu`.

Run: `cd flutter_app && flutter test test/whats_new_test.dart`
Expected: FAIL, `whatsNewFor('1.5.0', …)` renvoie null

- [ ] **Step 2: L'entrée `whats_new.dart`**

Ajouter avant `'1.4.0': {` :

```dart
  '1.5.0': {
    Language.fr: [
      'Le tracker sort de sa carte et y revient.',
      'Chaque point posé fait un petit bond ; les menus s\'ouvrent et se ferment en douceur.',
      'Les années glissent, les boutons répondent sous le doigt.',
      'Tout reste instantané si « Réduire les animations » est activé.',
    ],
    Language.en: [
      'The tracker grows out of its card and shrinks back into it.',
      'Every dot you set gives a little bounce; menus ease open and closed.',
      'Years slide, buttons answer under your finger.',
      'Everything stays instant with "Reduce Motion" on.',
    ],
    Language.zhCN: [
      '追踪器从卡片中展开，再收回卡片。',
      '每个点都会轻轻一跳；菜单柔和地打开和关闭。',
      '年份滑动切换，按钮在指尖下有回应。',
      '开启「减弱动态效果」后，一切保持即时。',
    ],
    Language.zhTW: [
      '追蹤器從卡片中展開，再收回卡片。',
      '每個點都會輕輕一跳；選單柔和地打開和關閉。',
      '年份滑動切換，按鈕在指尖下有回應。',
      '開啟「減少動態效果」後，一切保持即時。',
    ],
  },
```

Run: `cd flutter_app && flutter test test/whats_new_test.dart`
Expected: PASS

- [ ] **Step 3: Notes des stores**

`flutter_app/docs/changelogs/1.5.0.md`, même structure que `1.4.0.md` (quatre blocs `## en-US`, `## fr-FR`, `## zh-Hans`, `## zh-Hant`, ≤ 500 caractères chacun), avec les mêmes quatre puces que `whats_new.dart`, et un titre `# What's new — 1.5.0`.

- [ ] **Step 4: `CHANGELOG.md`**

Sous `## [Unreleased]` (vide après la 1.4.0), ajouter `Requires backend ≥ 1.2.0.` puis :

```markdown
### Changed
- Motion, with one timing rule (`lib/theme/motion.dart`, zero under the system's reduce-motion setting): the tracker morphs out of its card and back into it (rect-to-rect shell, measured anchors, centred fallback when the card is off screen); every dialog scales and fades in over 220 ms and out over 160 ms, the cell editor from the tapped dot and the legend editor from the Edit button; the dot that just changed pops (one animated widget over the grid, driven by `CellsProvider.lastChange`, cleared on a server revert); the grid, the card grid and the year label slide in the swipe's direction; bordered buttons shrink to 0.96 under the finger; the list's cards cascade in on arrival, a new card pops, a deleted one shrinks away; the settings slide in and out; coming back from a tracker, the list opens scrolled on its card.
- `AppShell` swaps screens through `ScreenStage` instead of an `AnimatedSwitcher`; `TrackerGrid.onCellPress` carries the tap position; `showDialog` is replaced by `showAppDialog` everywhere.
```

- [ ] **Step 5: Analyse, tests, commit**

Run: `cd flutter_app && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`

```bash
git add flutter_app/CHANGELOG.md flutter_app/docs/changelogs/1.5.0.md flutter_app/lib/data/whats_new.dart flutter_app/test/whats_new_test.dart
git commit -m "App: 1.5.0 notes — changelog, store notes, what's-new bullets for the animations

Claude-Session: https://claude.ai/code/session_018mTXYFQzTck4DiZdS8KWyz"
```

La release elle-même (`./release-app.sh`, `make prod-ios` / `make prod-android` depuis le tag) n'est pas dans ce plan : elle attend le lot 2 (sons) ou la décision de sortir les animations seules.
