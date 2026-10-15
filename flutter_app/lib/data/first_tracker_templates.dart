import '../providers/language_provider.dart';

/// Ready-made trackers offered by the first-tracker flow (app 1.4.0).
///
/// Colors come from the Pinterest pin palettes (`marketing/common.py`) so the
/// app looks like what we show there. Labels are translation keys resolved
/// through [LanguageProvider.t]; the server stores the resolved strings.
class FirstTrackerTemplate {
  final String id;
  final List<String> colors;

  /// "Other…": the user types the title; legends are Yes / A little / No.
  final bool customTitle;

  const FirstTrackerTemplate({
    required this.id,
    required this.colors,
    this.customTitle = false,
  });

  /// Tracker title, also the tile label (≤ 35 characters in every language).
  String get titleKey => 'firstTracker.tpl.$id.title';

  int get legendCount => colors.length;

  /// Legend label at [index] (≤ 30 characters in every language).
  String labelKey(int index) => 'firstTracker.tpl.$id.$index';

  /// The legends to send to the server, resolved in the current language.
  List<({String color, String label})> legends(LanguageProvider lang) => [
        for (var i = 0; i < colors.length; i++)
          (color: colors[i], label: lang.t(labelKey(i))),
      ];
}

const firstTrackerTemplates = <FirstTrackerTemplate>[
  FirstTrackerTemplate(id: 'mood', colors: ['#FFEC99', '#FFD43B', '#8CE99A', '#74C0FC', '#E599F7']),
  FirstTrackerTemplate(id: 'sleep', colors: ['#1864AB', '#1C7ED6', '#4DABF7', '#A5D8FF', '#D0EBFF']),
  FirstTrackerTemplate(id: 'exercise', colors: ['#51CF66', '#8CE99A', '#FFD8A8', '#74C0FC', '#FFA8A8']),
  FirstTrackerTemplate(id: 'reading', colors: ['#FA5252', '#FF8787', '#FFA8A8', '#FFC9C9']),
  FirstTrackerTemplate(id: 'habits', colors: ['#20C997', '#63E6BE', '#C3FAE8', '#FFD8A8', '#FFA94D']),
  FirstTrackerTemplate(id: 'other', colors: ['#8CE99A', '#FFEC99', '#FFA8A8'], customTitle: true),
];
