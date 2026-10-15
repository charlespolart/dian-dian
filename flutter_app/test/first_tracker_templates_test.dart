import 'package:flutter_test/flutter_test.dart';

import 'package:dian_dian/data/first_tracker_templates.dart';
import 'package:dian_dian/providers/language_provider.dart';

void main() {
  final hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  test('six templates, each with 3 to 12 distinct valid colors', () {
    expect(firstTrackerTemplates.map((t) => t.id), ['mood', 'sleep', 'exercise', 'reading', 'habits', 'other']);
    for (final t in firstTrackerTemplates) {
      expect(t.legendCount, inInclusiveRange(3, 12), reason: t.id);
      for (final c in t.colors) {
        expect(hex.hasMatch(c), isTrue, reason: '${t.id} $c');
      }
      expect(t.colors.toSet().length, t.colors.length, reason: '${t.id}: duplicate color');
    }
    expect(firstTrackerTemplates.where((t) => t.customTitle).single.id, 'other');
  });

  test('every title and label exists in every language and fits the server limits', () {
    for (final lang in Language.values) {
      for (final t in firstTrackerTemplates) {
        final title = LanguageProvider.translationFor(lang, t.titleKey);
        expect(title, isNotNull, reason: '$lang ${t.titleKey}');
        expect(title!.length, inInclusiveRange(1, 35), reason: '$lang ${t.titleKey}');
        for (var i = 0; i < t.legendCount; i++) {
          final label = LanguageProvider.translationFor(lang, t.labelKey(i));
          expect(label, isNotNull, reason: '$lang ${t.labelKey(i)}');
          expect(label!.length, inInclusiveRange(1, 30), reason: '$lang ${t.labelKey(i)}');
        }
        expect(LanguageProvider.translationFor(lang, t.labelKey(t.legendCount)), isNull,
            reason: '${t.id}: a label beyond legendCount would never be shown');
      }
    }
  });

  test('flow, Today and date strings exist in every language', () {
    const keys = [
      'firstTracker.title', 'firstTracker.subtitle', 'firstTracker.later', 'firstTracker.titleField',
      'firstTracker.continue', 'firstTracker.today', 'firstTracker.notToday', 'firstTracker.open',
      'firstTracker.error', 'firstTracker.retry', 'tracker.today',
    ];
    for (final lang in Language.values) {
      for (final k in keys) {
        expect(LanguageProvider.translationFor(lang, k), isNotNull, reason: '$lang $k');
      }
      for (var i = 1; i <= 7; i++) {
        expect(LanguageProvider.translationFor(lang, 'date.weekday.$i'), isNotNull, reason: '$lang weekday $i');
      }
      for (var i = 1; i <= 12; i++) {
        expect(LanguageProvider.translationFor(lang, 'date.month.$i'), isNotNull, reason: '$lang month $i');
      }
    }
  });

  test('French strings say vous, never tu', () {
    final tu = RegExp(r"\b(tu|ton|ta|tes|toi)\b", caseSensitive: false);
    for (final k in ['firstTracker.title', 'firstTracker.subtitle', 'firstTracker.error']) {
      expect(tu.hasMatch(LanguageProvider.translationFor(Language.fr, k)!), isFalse, reason: k);
    }
  });

  test('formatLongDate spells the date per language', () {
    final d = DateTime(2026, 10, 15); // a Thursday
    expect(LanguageProvider.formatLongDate(Language.fr, d), 'jeudi 15 octobre');
    expect(LanguageProvider.formatLongDate(Language.en, d), 'Thursday, October 15');
    expect(LanguageProvider.formatLongDate(Language.zhCN, d), '10月15日 星期四');
    expect(LanguageProvider.formatLongDate(Language.zhTW, d), '10月15日 星期四');
  });

  test('legends() resolves labels in order with the template colors', () {
    final mood = firstTrackerTemplates.first;
    final labels = [for (var i = 0; i < mood.legendCount; i++) LanguageProvider.translationFor(Language.en, mood.labelKey(i))];
    expect(labels, ['Great', 'Good', 'Okay', 'Meh', 'Low']);
  });
}
