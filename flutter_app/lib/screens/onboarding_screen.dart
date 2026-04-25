import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;

  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();

  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('onboarding_done') ?? false);
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  static const _totalPages = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await OnboardingScreen.markDone();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _finish,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.shell,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.shellBorder),
                    ),
                    child: Text(
                      lang.t('onboarding.skip'),
                      style: AppFonts.pixel(fontSize: 12, color: AppColors.accent),
                    ),
                  ),
                ),
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _PageCreateTracker(lang: lang),
                  _PageAddLegends(lang: lang),
                  _PageColorCells(lang: lang),
                ],
              ),
            ),
            // Dots + next button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page dots
                  Row(
                    children: List.generate(_totalPages, (i) {
                      return Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _page ? AppColors.accent : AppColors.dotEmpty,
                          border: Border.all(
                            color: i == _page ? AppColors.accent : AppColors.dotBorder,
                            width: 0.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  // Next / Start button
                  GestureDetector(
                    onTap: _next,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.btnAdd,
                        border: Border.all(color: AppColors.btnAddBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _page == _totalPages - 1 ? lang.t('onboarding.start') : lang.t('onboarding.next'),
                        style: AppFonts.pixel(fontSize: 12, color: AppColors.btnAddText),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Page 1: Create a tracker ──

class _PageCreateTracker extends StatelessWidget {
  final LanguageProvider lang;
  const _PageCreateTracker({required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _OnboardingCard(
        illustration: Column(
          children: [
            Text(
              '点点',
              style: AppFonts.pixel(fontSize: 28, color: AppColors.title),
            ),
            const SizedBox(height: 8),
            ...List.generate(4, (row) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(6, (col) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.dotEmpty,
                        border: Border.all(color: AppColors.dotBorder, width: 0.5),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        ),
        title: lang.t('onboarding.createTitle'),
        description: lang.t('onboarding.createDesc'),
      ),
    );
  }
}

// ── Page 2: Add legends ──

class _PageAddLegends extends StatelessWidget {
  final LanguageProvider lang;
  const _PageAddLegends({required this.lang});

  static const _demoLegends = [
    {'color': '#FF9EB8', 'label': 'Great day'},
    {'color': '#74C0FC', 'label': 'Productive'},
    {'color': '#FFE066', 'label': 'Relaxing'},
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _OnboardingCard(
        illustration: Column(
          children: _demoLegends.map((l) {
            final hex = l['color']!;
            final cleaned = hex.replaceFirst('#', '');
            final color = Color(int.parse('FF$cleaned', radix: 16));
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l['label']!,
                    style: AppFonts.dot(fontSize: 14, color: AppColors.text),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
        title: lang.t('onboarding.legendsTitle'),
        description: lang.t('onboarding.legendsDesc'),
      ),
    );
  }
}

// ── Page 3: Color your days ──

class _PageColorCells extends StatelessWidget {
  final LanguageProvider lang;
  const _PageColorCells({required this.lang});

  // Some cells colored for demo
  static const _demoCells = {
    '0,0': '#FF9EB8',
    '0,1': '#FF9EB8',
    '1,0': '#74C0FC',
    '1,2': '#FFE066',
    '2,0': '#FF9EB8',
    '2,1': '#74C0FC',
    '2,2': '#74C0FC',
    '3,1': '#FFE066',
    '3,2': '#FF9EB8',
  };

  @override
  Widget build(BuildContext context) {
    return Center(
      child: _OnboardingCard(
        illustration: Column(
          children: List.generate(5, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(6, (col) {
                  final key = '$row,$col';
                  final hex = _demoCells[key];
                  Color dotColor;
                  if (hex != null) {
                    final cleaned = hex.replaceFirst('#', '');
                    dotColor = Color(int.parse('FF$cleaned', radix: 16));
                  } else {
                    dotColor = AppColors.dotEmpty;
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: hex == null
                          ? Border.all(color: AppColors.dotBorder, width: 0.5)
                          : null,
                    ),
                  );
                }),
              ),
            );
          }),
        ),
        title: lang.t('onboarding.colorTitle'),
        description: lang.t('onboarding.colorDesc'),
      ),
    );
  }
}

/// Shared card layout for onboarding pages.
class _OnboardingCard extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;

  const _OnboardingCard({
    required this.illustration,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Card renders at a natural size based on width budget.
          // FittedBox(scaleDown) shrinks it uniformly if the page is too short
          // (Larger Text, landscape, small phones) — never overflows, no scroll.
          final cardWidth = math.min(400.0, constraints.maxWidth);
          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: SizedBox(
                width: cardWidth,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.shell,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.shellBorder),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      illustration,
                      const SizedBox(height: 28),
                      Text(
                        title,
                        style: AppFonts.pixel(fontSize: 18, color: AppColors.title),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: AppFonts.dot(fontSize: 14, color: AppColors.text),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
