import '../providers/language_provider.dart';

/// What the "what's new" box shows after an update, per version and
/// language: three to six short bullets, the store notes trimmed
/// (`docs/changelogs/<version>.md`). `release-app.sh` refuses to tag a
/// version without an entry here. A version with no entry shows nothing.
const whatsNew = <String, Map<Language, List<String>>>{
  '1.4.0': {
    Language.fr: [
      "Premier tracker guidé : un modèle, le point du jour, c'est parti.",
      'Bouton et point « Aujourd\'hui » dans le tracker.',
      'Réglages → Contact : une idée, un bug ou une question depuis l\'app.',
      'Téléphone en portrait ; glissez depuis le bord gauche pour revenir.',
      'Compte gratuit : vous choisissez les 3 trackers qui restent ouverts.',
    ],
    Language.en: [
      "Guided first tracker: pick a template, set today's dot, done.",
      '"Today" button and dot in the tracker.',
      'Settings → Contact: an idea, a bug or a question from the app.',
      'Phones stay in portrait; swipe from the left edge to go back.',
      'Free account: you choose the 3 trackers that stay open.',
    ],
    Language.zhCN: [
      '引导式首个追踪器：选一个模板，填上今天的点，开始。',
      '追踪器新增「今天」按钮和点。',
      '设置 → 联系我们：在应用内发送想法、bug 或问题。',
      '手机保持竖屏；从左边缘滑动即可返回。',
      '免费账户：由你选择保持开放的 3 个追踪器。',
    ],
    Language.zhTW: [
      '引導式首個追蹤器：選一個模板，填上今天的點，開始。',
      '追蹤器新增「今天」按鈕和點。',
      '設定 → 聯絡我們：在應用程式內傳送想法、bug 或問題。',
      '手機保持直向；從左邊緣滑動即可返回。',
      '免費帳戶：由你選擇保持開放的 3 個追蹤器。',
    ],
  },
};

List<String>? whatsNewFor(String version, Language lang) => whatsNew[version]?[lang];

/// Debug only (never in a release build): show the box at every launch,
/// with the newest entry, whatever the running version says. Flip to false
/// when done looking at it.
const bool debugAlwaysShowWhatsNew = true;

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
