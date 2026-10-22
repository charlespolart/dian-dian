import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../providers/premium_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'app_dialog.dart';
import 'premium_gate_dialog.dart';

Future<void> showThemePickerDialog(BuildContext context) {
  return showAppDialog(
    context: context,
    builder: (_) => const _ThemePickerDialog(),
  );
}

class _ThemePickerDialog extends StatelessWidget {
  const _ThemePickerDialog();

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final themeProv = context.watch<ThemeProvider>();
    final premium = context.watch<PremiumProvider>();

    return AppDialog(
      maxWidth: 420,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.t('settings.theme'),
              style: AppFonts.pixel(fontSize: 16, color: AppColors.title),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: AppThemeType.values.map((type) {
                final isActive = themeProv.currentTheme == type;
                final isLocked = type != AppThemeType.defaultTheme && !premium.isPremium;

                return GestureDetector(
                  onTap: () {
                    if (isLocked) {
                      Navigator.of(context).pop();
                      PremiumGateDialog.show(context, feature: lang.t('premium.feature.themes'), event: 'themes');
                      return;
                    }
                    themeProv.setTheme(type);
                    Navigator.of(context).pop();
                  },
                  child: _ThemeMiniPreview(
                    type: type,
                    isActive: isActive,
                    isLocked: isLocked,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini tracker preview card for a theme.
class _ThemeMiniPreview extends StatelessWidget {
  final AppThemeType type;
  final bool isActive;
  final bool isLocked;

  const _ThemeMiniPreview({
    required this.type,
    required this.isActive,
    required this.isLocked,
  });

  // Some cells colored for the preview
  static const _demoColors = ['#FF9EB8', '#74C0FC', '#FFE066'];
  static const _filledCells = {
    '0,0': 0, '0,2': 1, '1,1': 2, '1,3': 0,
    '2,0': 1, '2,4': 2, '3,2': 0, '3,3': 1,
    '4,1': 2, '4,4': 0,
  };

  @override
  Widget build(BuildContext context) {
    final c = AppColors.colorsFor(type);

    return SizedBox(
      width: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 80,
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? c.accent : c.shellBorder,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          // Background dots
          Positioned.fill(
            child: CustomPaint(
              painter: _DotBgPainter(dotColor: c.bgDot),
            ),
          ),
          // Mini tracker shell
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // Mini sidebar
                Container(
                  width: 20,
                  decoration: BoxDecoration(
                    color: c.screen,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: c.screenBorder, width: 0.5),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _miniDot(c.accent, 4),
                      const SizedBox(height: 2),
                      _miniDot(c.title, 4),
                      const SizedBox(height: 2),
                      _miniDot(c.subtitle, 4),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                // Mini grid
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.screen,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: c.screenBorder, width: 0.5),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (row) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 1.5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (col) {
                              final key = '$row,$col';
                              final colorIdx = _filledCells[key];
                              Color dotColor;
                              if (colorIdx != null) {
                                final hex = _demoColors[colorIdx].replaceFirst('#', '');
                                dotColor = Color(int.parse('FF$hex', radix: 16));
                              } else {
                                dotColor = c.dotEmpty;
                              }
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dotColor,
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lock icon
          if (isLocked)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.lock, size: 10, color: c.textMuted),
            ),
          // Check mark
          if (isActive)
            Positioned(
              top: 4,
              right: 4,
              child: Icon(Icons.check_circle, size: 12, color: c.accent),
            ),
        ],
      ),
          ),
          // Theme name below
          const SizedBox(height: 4),
          Text(
            appThemeNames[type]!,
            textAlign: TextAlign.center,
            style: AppFonts.pixel(
              fontSize: 9,
              color: isActive ? AppColors.accent : AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

/// Paints a subtle dot grid background for the theme preview.
class _DotBgPainter extends CustomPainter {
  final Color dotColor;

  _DotBgPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = dotColor;
    const spacing = 10.0;
    const radius = 0.8;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotBgPainter old) => old.dotColor != dotColor;
}
