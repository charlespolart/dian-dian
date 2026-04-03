import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Language { fr, en, zhCN, zhTW }

/// Short labels for each language (used in compact selectors).
const languageShortLabels = {
  Language.fr: 'FR',
  Language.en: 'EN',
  Language.zhCN: '简',
  Language.zhTW: '繁',
};

/// Translation keys for full language names.
const languageNameKeys = {
  Language.fr: 'settings.french',
  Language.en: 'settings.english',
  Language.zhCN: 'settings.chineseSimplified',
  Language.zhTW: 'settings.chineseTraditional',
};

class LanguageProvider extends ChangeNotifier {
  static const _prefKey = 'app_language';

  Language _lang = Language.en;

  Language get lang => _lang;

  LanguageProvider() {
    _init();
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  Future<void> setLang(Language lang) async {
    _lang = lang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.name);
  }

  /// Returns the translated string for the given [key].
  /// Falls back to the English translation, then to the raw key.
  String t(String key) {
    return _translations[_lang]?[key] ??
        _translations[Language.en]?[key] ??
        key;
  }

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);

    if (saved != null) {
      _lang = _languageFromName(saved);
    } else {
      _lang = _detectDeviceLanguage();
    }

    notifyListeners();
  }

  Language _detectDeviceLanguage() {
    final locale = PlatformDispatcher.instance.locale;
    final languageCode = locale.languageCode;
    final countryCode = locale.countryCode;

    if (languageCode == 'zh') {
      // Distinguish Simplified vs Traditional Chinese
      if (countryCode == 'TW' || countryCode == 'HK' || countryCode == 'MO') {
        return Language.zhTW;
      }
      return Language.zhCN;
    }

    if (languageCode == 'fr') return Language.fr;

    return Language.en;
  }

  Language _languageFromName(String name) {
    switch (name) {
      case 'fr':
        return Language.fr;
      case 'zhCN':
        return Language.zhCN;
      case 'zhTW':
        return Language.zhTW;
      case 'en':
      default:
        return Language.en;
    }
  }

  // ---------------------------------------------------------------------------
  // Translations
  // ---------------------------------------------------------------------------

  static const Map<Language, Map<String, String>> _translations = {
    Language.fr: {
      // Auth
      'auth.login': 'Connexion',
      'auth.register': 'Inscription',
      'auth.email': 'Email',
      'auth.password': 'Mot de passe',
      'auth.confirmPassword': 'Confirmer le mot de passe',
      'auth.loginBtn': 'Se connecter',
      'auth.registerBtn': "S'inscrire",
      'auth.switchToRegister': "Pas encore de compte ? S'inscrire",
      'auth.switchToLogin': 'Déjà un compte ? Se connecter',
      'auth.passwordMismatch': 'Les mots de passe ne correspondent pas',
      'auth.passwordMin': 'Le mot de passe doit faire au moins 8 caractères',
      'auth.loginError': 'Erreur de connexion',
      'auth.registerError': "Erreur d'inscription",
      'auth.forgotPassword': 'Mot de passe oublié ?',
      'auth.forgotPasswordBtn': 'Envoyer le lien',
      'auth.forgotPasswordSent':
          'Si un compte existe avec cet email, un lien de réinitialisation a été envoyé.',
      'auth.resetPassword': 'Nouveau mot de passe',
      'auth.resetPasswordBtn': 'Réinitialiser',
      'auth.resetPasswordSuccess':
          'Mot de passe modifié ! Vous pouvez vous connecter.',
      'auth.backToLogin': 'Retour à la connexion',

      // Tracker
      'tracker.colors': 'Couleurs',
      'tracker.legend': 'Legende',
      'tracker.legendPlaceholder': 'ex: 1-5 pages',
      'tracker.stats': 'Stats',
      'tracker.statDays': 'jours',
      'tracker.statStreak': 'serie',
      'tracker.statYear': 'annee',
      'tracker.eraser': 'Gomme',
      'tracker.editLegends': 'Éditer',
      'tracker.pickColor': 'Choisir une couleur',
      'tracker.noLegends': 'Aucune légende',
      'tracker.noTrackers': 'Aucun tracker',
      'tracker.deleteLegendConfirmSimple': 'Supprimer cette légende ?',
      'tracker.resetAll': 'Tout effacer',
      'tracker.resetConfirm': 'Effacer toutes les cases ?',
      'tracker.deletePageConfirm': 'Supprimer cette page ?',
      'tracker.deleteLegendConfirm':
          'Supprimer cette légende et tous les points associés ?',
      'tracker.settings': 'Paramètres',
      'tracker.loading': 'Chargement...',
      'tracker.pages': 'Pages',

      // Palette
      'palette.title': 'Modifier la palette',
      'palette.edit': 'Modifier',
      'palette.addRow': '+ Ajouter une ligne',
      'palette.deleteRow': 'Supprimer la ligne',
      'palette.deleteRowBlocked':
          'Impossible de supprimer : des couleurs de cette ligne sont utilisées dans la grille ou les légendes.',
      'palette.save': 'Enregistrer',
      'palette.reset': 'Réinitialiser',

      // Settings
      'settings.title': 'Paramètres',
      'settings.language': 'Langue',
      'settings.french': 'Français',
      'settings.english': 'English',
      'settings.chineseSimplified': '简体中文',
      'settings.chineseTraditional': '繁體中文',
      'settings.account': 'Compte',
      'settings.logout': 'Déconnexion',
      'settings.logoutConfirm': 'Se déconnecter ?',
      'settings.deleteAccount': 'Supprimer mon compte',
      'settings.deleteAccountConfirm':
          'Supprimer définitivement votre compte et toutes vos données ? Cette action est irréversible.',
      'settings.typeDelete': 'Tapez DELETE pour confirmer',
      'settings.typeEmail': 'Tapez votre email pour confirmer',
      'settings.deleteAccountSuccess': 'Compte supprimé.',
      'settings.back': 'Retour',
      'settings.comingSoon': 'Bientôt disponible',
      'settings.theme': 'Thème',
      'settings.subscription': 'Abonnement',
      'settings.version': 'Version',
      'settings.about': 'À propos',
      'settings.contact': 'Contact',
      'settings.privacy': 'Politique de confidentialité',
      'settings.terms': "Conditions d'utilisation",

      // Common
      'common.cancel': 'Annuler',
      'common.delete': 'Supprimer',
      'common.yes': 'Oui',
      'common.erase': 'Effacer',
      'common.add': '+ Ajouter',
    },
    Language.en: {
      // Auth
      'auth.login': 'Login',
      'auth.register': 'Sign up',
      'auth.email': 'Email',
      'auth.password': 'Password',
      'auth.confirmPassword': 'Confirm password',
      'auth.loginBtn': 'Log in',
      'auth.registerBtn': 'Sign up',
      'auth.switchToRegister': "Don't have an account? Sign up",
      'auth.switchToLogin': 'Already have an account? Log in',
      'auth.passwordMismatch': "Passwords don't match",
      'auth.passwordMin': 'Password must be at least 8 characters',
      'auth.loginError': 'Login error',
      'auth.registerError': 'Sign up error',
      'auth.forgotPassword': 'Forgot password?',
      'auth.forgotPasswordBtn': 'Send reset link',
      'auth.forgotPasswordSent':
          'If an account exists with this email, a reset link has been sent.',
      'auth.resetPassword': 'New password',
      'auth.resetPasswordBtn': 'Reset password',
      'auth.resetPasswordSuccess': 'Password changed! You can now log in.',
      'auth.backToLogin': 'Back to login',

      // Tracker
      'tracker.colors': 'Colors',
      'tracker.legend': 'Legend',
      'tracker.legendPlaceholder': 'e.g. 1-5 pages',
      'tracker.stats': 'Stats',
      'tracker.statDays': 'days',
      'tracker.statStreak': 'streak',
      'tracker.statYear': 'year',
      'tracker.eraser': 'Eraser',
      'tracker.editLegends': 'Edit',
      'tracker.pickColor': 'Pick a color',
      'tracker.noLegends': 'No legends',
      'tracker.noTrackers': 'No trackers',
      'tracker.deleteLegendConfirmSimple': 'Delete this legend?',
      'tracker.resetAll': 'Clear all',
      'tracker.resetConfirm': 'Clear all cells?',
      'tracker.deletePageConfirm': 'Delete this page?',
      'tracker.deleteLegendConfirm':
          'Delete this legend and all associated dots?',
      'tracker.settings': 'Settings',
      'tracker.loading': 'Loading...',
      'tracker.pages': 'Pages',

      // Palette
      'palette.title': 'Edit Palette',
      'palette.edit': 'Edit',
      'palette.addRow': '+ Add Row',
      'palette.deleteRow': 'Delete Row',
      'palette.deleteRowBlocked':
          'Cannot delete: colors from this row are used in the grid or legends.',
      'palette.save': 'Save',
      'palette.reset': 'Reset',

      // Settings
      'settings.title': 'Settings',
      'settings.language': 'Language',
      'settings.french': 'Français',
      'settings.english': 'English',
      'settings.chineseSimplified': '简体中文',
      'settings.chineseTraditional': '繁體中文',
      'settings.account': 'Account',
      'settings.logout': 'Log out',
      'settings.logoutConfirm': 'Log out?',
      'settings.deleteAccount': 'Delete my account',
      'settings.deleteAccountConfirm':
          'Permanently delete your account and all data? This cannot be undone.',
      'settings.typeDelete': 'Type DELETE to confirm',
      'settings.typeEmail': 'Type your email to confirm',
      'settings.deleteAccountSuccess': 'Account deleted.',
      'settings.back': 'Back',
      'settings.comingSoon': 'Coming soon',
      'settings.theme': 'Theme',
      'settings.subscription': 'Subscription',
      'settings.version': 'Version',
      'settings.about': 'About',
      'settings.contact': 'Contact',
      'settings.privacy': 'Privacy Policy',
      'settings.terms': 'Terms of Use',

      // Common
      'common.cancel': 'Cancel',
      'common.delete': 'Delete',
      'common.yes': 'Yes',
      'common.erase': 'Erase',
      'common.add': '+ Add',
    },
    Language.zhCN: {
      // Auth
      'auth.login': '登录',
      'auth.register': '注册',
      'auth.email': '邮箱',
      'auth.password': '密码',
      'auth.confirmPassword': '确认密码',
      'auth.loginBtn': '登录',
      'auth.registerBtn': '注册',
      'auth.switchToRegister': '没有账号？注册',
      'auth.switchToLogin': '已有账号？登录',
      'auth.passwordMismatch': '两次密码不一致',
      'auth.passwordMin': '密码至少需要8个字符',
      'auth.loginError': '登录错误',
      'auth.registerError': '注册错误',
      'auth.forgotPassword': '忘记密码？',
      'auth.forgotPasswordBtn': '发送重置链接',
      'auth.forgotPasswordSent': '如果该邮箱存在账号，重置链接已发送。',
      'auth.resetPassword': '新密码',
      'auth.resetPasswordBtn': '重置密码',
      'auth.resetPasswordSuccess': '密码已修改！请登录。',
      'auth.backToLogin': '返回登录',

      // Tracker
      'tracker.colors': '颜色',
      'tracker.legend': '图例',
      'tracker.legendPlaceholder': '例：1-5页',
      'tracker.stats': '统计',
      'tracker.statDays': '天',
      'tracker.statStreak': '连续',
      'tracker.statYear': '年度',
      'tracker.eraser': '橡皮擦',
      'tracker.editLegends': '编辑',
      'tracker.pickColor': '选择颜色',
      'tracker.noLegends': '暂无图例',
      'tracker.noTrackers': '暂无追踪器',
      'tracker.deleteLegendConfirmSimple': '删除此图例？',
      'tracker.resetAll': '全部清除',
      'tracker.resetConfirm': '清除所有格子？',
      'tracker.deletePageConfirm': '删除此页面？',
      'tracker.deleteLegendConfirm': '删除此图例及所有关联的点？',
      'tracker.settings': '设置',
      'tracker.loading': '加载中...',
      'tracker.pages': '页面',

      // Palette
      'palette.title': '编辑调色板',
      'palette.edit': '编辑',
      'palette.addRow': '+ 添加一行',
      'palette.deleteRow': '删除行',
      'palette.deleteRowBlocked': '无法删除：此行的颜色已在网格或图例中使用。',
      'palette.save': '保存',
      'palette.reset': '重置',

      // Settings
      'settings.title': '设置',
      'settings.language': '语言',
      'settings.french': 'Français',
      'settings.english': 'English',
      'settings.chineseSimplified': '简体中文',
      'settings.chineseTraditional': '繁體中文',
      'settings.account': '账户',
      'settings.logout': '退出登录',
      'settings.logoutConfirm': '确定退出？',
      'settings.deleteAccount': '删除账户',
      'settings.deleteAccountConfirm': '永久删除您的账户和所有数据？此操作不可撤销。',
      'settings.typeDelete': '输入 DELETE 以确认',
      'settings.typeEmail': '输入您的邮箱以确认',
      'settings.deleteAccountSuccess': '账户已删除。',
      'settings.back': '返回',
      'settings.comingSoon': '即将推出',
      'settings.theme': '主题',
      'settings.subscription': '订阅',
      'settings.version': '版本',
      'settings.about': '关于',
      'settings.contact': '联系我们',
      'settings.privacy': '隐私政策',
      'settings.terms': '使用条款',

      // Common
      'common.cancel': '取消',
      'common.delete': '删除',
      'common.yes': '确定',
      'common.erase': '清除',
      'common.add': '+ 添加',
    },
    Language.zhTW: {
      // Auth
      'auth.login': '登入',
      'auth.register': '註冊',
      'auth.email': '電子郵件',
      'auth.password': '密碼',
      'auth.confirmPassword': '確認密碼',
      'auth.loginBtn': '登入',
      'auth.registerBtn': '註冊',
      'auth.switchToRegister': '沒有帳號？註冊',
      'auth.switchToLogin': '已有帳號？登入',
      'auth.passwordMismatch': '兩次密碼不一致',
      'auth.passwordMin': '密碼至少需要8個字元',
      'auth.loginError': '登入錯誤',
      'auth.registerError': '註冊錯誤',
      'auth.forgotPassword': '忘記密碼？',
      'auth.forgotPasswordBtn': '發送重置連結',
      'auth.forgotPasswordSent': '如果該信箱存在帳號，重置連結已發送。',
      'auth.resetPassword': '新密碼',
      'auth.resetPasswordBtn': '重置密碼',
      'auth.resetPasswordSuccess': '密碼已修改！請登入。',
      'auth.backToLogin': '返回登入',

      // Tracker
      'tracker.colors': '顏色',
      'tracker.legend': '圖例',
      'tracker.legendPlaceholder': '例：1-5頁',
      'tracker.stats': '統計',
      'tracker.statDays': '天',
      'tracker.statStreak': '連續',
      'tracker.statYear': '年度',
      'tracker.eraser': '橡皮擦',
      'tracker.editLegends': '編輯',
      'tracker.pickColor': '選擇顏色',
      'tracker.noLegends': '暫無圖例',
      'tracker.noTrackers': '暫無追蹤器',
      'tracker.deleteLegendConfirmSimple': '刪除此圖例？',
      'tracker.resetAll': '全部清除',
      'tracker.resetConfirm': '清除所有格子？',
      'tracker.deletePageConfirm': '刪除此頁面？',
      'tracker.deleteLegendConfirm': '刪除此圖例及所有關聯的點？',
      'tracker.settings': '設定',
      'tracker.loading': '載入中...',
      'tracker.pages': '頁面',

      // Palette
      'palette.title': '編輯調色盤',
      'palette.edit': '編輯',
      'palette.addRow': '+ 新增一列',
      'palette.deleteRow': '刪除列',
      'palette.deleteRowBlocked': '無法刪除：此列的顏色已在網格或圖例中使用。',
      'palette.save': '儲存',
      'palette.reset': '重置',

      // Settings
      'settings.title': '設定',
      'settings.language': '語言',
      'settings.french': 'Français',
      'settings.english': 'English',
      'settings.chineseSimplified': '简体中文',
      'settings.chineseTraditional': '繁體中文',
      'settings.account': '帳戶',
      'settings.logout': '登出',
      'settings.logoutConfirm': '確定登出？',
      'settings.deleteAccount': '刪除帳戶',
      'settings.deleteAccountConfirm': '永久刪除您的帳戶和所有資料？此操作不可撤銷。',
      'settings.typeDelete': '輸入 DELETE 以確認',
      'settings.typeEmail': '輸入您的電子郵件以確認',
      'settings.deleteAccountSuccess': '帳戶已刪除。',
      'settings.back': '返回',
      'settings.comingSoon': '即將推出',
      'settings.theme': '主題',
      'settings.subscription': '訂閱',
      'settings.version': '版本',
      'settings.about': '關於',
      'settings.contact': '聯絡我們',
      'settings.privacy': '隱私權政策',
      'settings.terms': '使用條款',

      // Common
      'common.cancel': '取消',
      'common.delete': '刪除',
      'common.yes': '確定',
      'common.erase': '清除',
      'common.add': '+ 新增',
    },
  };
}
