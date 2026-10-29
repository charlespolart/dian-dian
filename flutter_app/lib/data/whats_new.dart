import '../providers/language_provider.dart';

/// What the "what's new" box shows after an update, per version and
/// language: three to six short bullets that matter to people (not the
/// plumbing), the store notes trimmed
/// (`docs/changelogs/<version>.md`). `release-app.sh` refuses to tag a
/// version without an entry here. A version with no entry shows nothing.
const whatsNew = <String, Map<Language, List<String>>>{
  '1.4.0': {
    Language.fr: [
      "Premier tracker guidé : un modèle, le point du jour, c'est parti.",
      "L'app bouge : les trackers s'ouvrent depuis leur carte, les points bondissent.",
      'De petites bulles sonores et une légère vibration à chaque geste ; les deux se coupent dans les Réglages.',
      'Un petit anneau sur les points qui portent une note.',
      "Bouton « Aujourd'hui » : un tap ouvre la journée en cours.",
      "Réglages → Contact : une idée, un bug ou une question depuis l'app.",
    ],
    Language.en: [
      "Guided first tracker: pick a template, set today's dot, done.",
      'The app moves: trackers open out of their card, dots pop.',
      'Soft bubble sounds and a light vibration at each gesture; both switch off in Settings.',
      'A small ring on the dots that carry a note.',
      '"Today" button: one tap opens today\'s day.',
      'Settings → Contact: an idea, a bug or a question from the app.',
    ],
    Language.zhCN: [
      '引导式首个追踪器：选一个模板，填上今天的点，开始。',
      '应用会动了：追踪器从卡片中展开，点会轻轻一跳。',
      '每个手势都有轻柔的泡泡音效和轻微震动；两者都可在设置中关闭。',
      '带有备注的点会显示一个小圆环。',
      '「今天」按钮：一键打开今天。',
      '设置 → 联系我们：在应用内发送想法、bug 或问题。',
    ],
    Language.zhTW: [
      '引導式首個追蹤器：選一個模板，填上今天的點，開始。',
      '應用程式會動了：追蹤器從卡片中展開，點會輕輕一跳。',
      '每個手勢都有輕柔的泡泡音效和輕微震動；兩者都可在設定中關閉。',
      '帶有備註的點會顯示一個小圓環。',
      '「今天」按鈕：一鍵打開今天。',
      '設定 → 聯絡我們：在應用程式內傳送想法、bug 或問題。',
    ],
  },
};

List<String>? whatsNewFor(String version, Language lang) => whatsNew[version]?[lang];

/// Debug only (never in a release build): show the box at every launch,
/// with the newest entry, whatever the running version says. Flip to false
/// when done looking at it.
const bool debugAlwaysShowWhatsNew = false;

/// The newest version that has an entry (what the debug flag shows).
String whatsNewLatestVersion() {
  final versions = whatsNew.keys.toList()
    ..sort((a, b) {
      final pa = a.split('.').map(int.parse).toList();
      final pb = b.split('.').map(int.parse).toList();
      for (var i = 0; i < 3; i++) {
        final c = pa[i].compareTo(pb[i]);
        if (c != 0) return c;
      }
      return 0;
    });
  return versions.last;
}

/// Show the box once after an update: never twice for the same version,
/// never for a version without notes. With nothing recorded yet, a fresh
/// install shows nothing (the first-tracker flow has the stage) while an
/// account that already has cells is an update from a version without the
/// box (≤ 1.3.0) and sees it.
bool shouldShowWhatsNew({
  required String? seenVersion,
  required String currentVersion,
  required bool hasNotes,
  required bool existingUser,
}) {
  if (!hasNotes) return false;
  if (seenVersion == null) return existingUser;
  return seenVersion != currentVersion;
}
