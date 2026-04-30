import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

enum Language { en, fr, zhCN, zhTW }

/// Short labels for each language (used in compact selectors).
const languageShortLabels = {
  Language.en: 'EN',
  Language.fr: 'FR',
  Language.zhCN: '简',
  Language.zhTW: '繁',
};

/// Translation keys for full language names.
const languageNameKeys = {
  Language.en: 'settings.english',
  Language.fr: 'settings.french',
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

  /// Apply settings from server (called after login / session restore).
  void applyServerSettings(String? language) {
    if (language == null) return;
    final newLang = _languageFromName(language);
    if (newLang != _lang) {
      _lang = newLang;
      SharedPreferences.getInstance().then((p) => p.setString(_prefKey, newLang.name));
      notifyListeners();
    }
  }

  Future<void> setLang(Language lang) async {
    _lang = lang;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, lang.name);
    // Sync to server (fire-and-forget)
    ApiService().apiFetch('/api/auth/settings', method: 'PATCH', body: {'language': lang.name}).ignore();
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
      'auth.invalidEmail': 'Adresse email invalide',
      'auth.loginError': 'Erreur de connexion',
      'auth.registerError': "Erreur d'inscription",
      'auth.forgotPassword': 'Mot de passe oublié ?',
      'auth.forgotPasswordBtn': 'Envoyer le code',
      'auth.forgotPasswordSent':
          'Si un compte existe avec cet email, un code à 6 chiffres a été envoyé.',
      'auth.codeLabel': 'Code à 6 chiffres',
      'auth.enterCode': 'Entrez le code envoyé à votre email.',
      'auth.codeInvalid': 'Code invalide ou expiré',
      'auth.tooManyAttempts': 'Trop de tentatives, redemandez un code',
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
      'tracker.addLegendsHint': 'Ajoute des légendes pour commencer',
      'tracker.newTracker': 'Nouveau tracker',
      'tracker.titleHint': 'Nom du tracker',
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
      'settings.legal': 'Mentions légales',

      // Common
      'common.cancel': 'Annuler',
      'common.delete': 'Supprimer',
      'common.yes': 'Oui',
      'common.erase': 'Effacer',
      'common.add': '+ Ajouter',
      'common.ok': 'OK',
      'common.comment': 'Commentaire',
      'common.create': '+ Créer',
      'premium.title': 'Premium',
      'premium.upgrade': 'Passer Premium',
      'premium.restore': 'Restaurer un achat',
      'premium.feature.trackers': 'Trackers illimités',
      'premium.feature.themes': 'Tous les thèmes',
      'premium.feature.cursor': 'Curseur animé',
      'premium.feature.export': 'Exporter en image',
      'premium.feature.stats': 'Statistiques détaillées',
      'premium.feature.noAds': 'Sans publicité',
      'premium.trackerLimit': 'Les comptes gratuits sont limités à 3 trackers',
      'premium.free': 'Gratuit',
      'premium.premium': 'Premium',
      'premium.active': 'Premium actif',
      'premium.manage': 'Gérer',
      'premium.removeAds': 'Supprimer les pubs',
      'premium.downloadApp': 'Téléchargez l\'app pour passer Premium',
      'settings.premium': 'Premium',
      'settings.cursor': 'Curseur',
      'settings.cursorAnimated': 'Curseur animé',
      'cursor.none': 'Aucun',
      'cursor.cat': 'Chat',
      'tracker.export': 'Exporter',
      'onboarding.skip': 'Passer',
      'onboarding.next': 'Suivant',
      'onboarding.start': 'Commencer',
      'onboarding.createTitle': 'Créer un tracker',
      'onboarding.createDesc': 'Chaque tracker est une grille annuelle où vous colorier chaque jour. Suivez vos habitudes, humeur, lectures — tout ce que vous voulez.',
      'onboarding.legendsTitle': 'Ajouter des légendes',
      'onboarding.legendsDesc': 'Définissez ce que chaque couleur signifie. Créez des légendes avec des couleurs et labels personnalisés.',
      'onboarding.colorTitle': 'Colorier vos jours',
      'onboarding.colorDesc': 'Appuyez sur une case pour attribuer une couleur et un commentaire. Regardez votre année se remplir de points colorés !',
      'stats.bestStreak': 'meilleur',
      'stats.distribution': 'Répartition',
      'stats.monthly': 'Progression mensuelle',
      'stats.weekday': 'Jour de la semaine',
      'stats.global': 'Stats globales',
      'stats.thisYear': 'Cette année',
      'stats.allTime': 'Tout',
      'stats.trackers': 'trackers',
      'stats.mostActive': 'Plus actif',
      'stats.perTracker': 'Par tracker',
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
      'auth.invalidEmail': 'Invalid email address',
      'auth.loginError': 'Login error',
      'auth.registerError': 'Sign up error',
      'auth.forgotPassword': 'Forgot password?',
      'auth.forgotPasswordBtn': 'Send code',
      'auth.forgotPasswordSent':
          'If an account exists with this email, a 6-digit code has been sent.',
      'auth.codeLabel': '6-digit code',
      'auth.enterCode': 'Enter the code we sent to your email.',
      'auth.codeInvalid': 'Invalid or expired code',
      'auth.tooManyAttempts': 'Too many attempts, request a new code',
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
      'tracker.addLegendsHint': 'Add legends to get started',
      'tracker.newTracker': 'New tracker',
      'tracker.titleHint': 'Tracker name',
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
      'settings.legal': 'Legal Notice',

      // Common
      'common.cancel': 'Cancel',
      'common.delete': 'Delete',
      'common.yes': 'Yes',
      'common.erase': 'Erase',
      'common.add': '+ Add',
      'common.ok': 'OK',
      'common.comment': 'Comment',
      'common.create': '+ Create',
      'premium.title': 'Premium',
      'premium.upgrade': 'Upgrade to Premium',
      'premium.restore': 'Restore purchase',
      'premium.feature.trackers': 'Unlimited trackers',
      'premium.feature.themes': 'All themes',
      'premium.feature.cursor': 'Animated cursor',
      'premium.feature.export': 'Export as image',
      'premium.feature.stats': 'Detailed statistics',
      'premium.feature.noAds': 'No ads',
      'premium.trackerLimit': 'Free accounts are limited to 3 trackers',
      'premium.free': 'Free',
      'premium.premium': 'Premium',
      'premium.active': 'Premium active',
      'premium.manage': 'Manage',
      'premium.removeAds': 'Remove ads',
      'premium.downloadApp': 'Download the app to unlock Premium',
      'settings.premium': 'Premium',
      'settings.cursor': 'Cursor',
      'settings.cursorAnimated': 'Animated cursor',
      'cursor.none': 'None',
      'cursor.cat': 'Cat',
      'tracker.export': 'Export',
      'onboarding.skip': 'Skip',
      'onboarding.next': 'Next',
      'onboarding.start': 'Start',
      'onboarding.createTitle': 'Create a tracker',
      'onboarding.createDesc': 'Each tracker is a year grid where you can color-code every day. Track habits, mood, reading — anything you want.',
      'onboarding.legendsTitle': 'Add legends',
      'onboarding.legendsDesc': 'Define what each color means. Create legends with custom colors and labels to organize your tracking.',
      'onboarding.colorTitle': 'Color your days',
      'onboarding.colorDesc': 'Tap any cell to assign a color and add a comment. Watch your year fill up with colorful dots!',
      'stats.bestStreak': 'best',
      'stats.distribution': 'Distribution',
      'stats.monthly': 'Monthly progress',
      'stats.weekday': 'Day of the week',
      'stats.global': 'Global Stats',
      'stats.thisYear': 'This year',
      'stats.allTime': 'All time',
      'stats.trackers': 'trackers',
      'stats.mostActive': 'Most active',
      'stats.perTracker': 'Per tracker',
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
      'auth.invalidEmail': '邮箱地址无效',
      'auth.loginError': '登录错误',
      'auth.registerError': '注册错误',
      'auth.forgotPassword': '忘记密码？',
      'auth.forgotPasswordBtn': '发送验证码',
      'auth.forgotPasswordSent': '如果该邮箱存在账号，已发送 6 位验证码。',
      'auth.codeLabel': '6 位验证码',
      'auth.enterCode': '请输入发送到您邮箱的验证码。',
      'auth.codeInvalid': '验证码无效或已过期',
      'auth.tooManyAttempts': '尝试次数过多，请重新申请验证码',
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
      'tracker.addLegendsHint': '添加图例开始使用',
      'tracker.newTracker': '新追踪器',
      'tracker.titleHint': '追踪器名称',
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
      'settings.legal': '法律声明',

      // Common
      'common.cancel': '取消',
      'common.delete': '删除',
      'common.yes': '确定',
      'common.erase': '清除',
      'common.add': '+ 添加',
      'common.ok': 'OK',
      'common.comment': '评论',
      'common.create': '+ 创建',
      'premium.title': '高级版',
      'premium.upgrade': '升级到高级版',
      'premium.restore': '恢复购买',
      'premium.feature.trackers': '无限追踪器',
      'premium.feature.themes': '所有主题',
      'premium.feature.cursor': '动画光标',
      'premium.feature.export': '导出为图片',
      'premium.feature.stats': '详细统计',
      'premium.feature.noAds': '无广告',
      'premium.trackerLimit': '免费账户最多3个追踪器',
      'premium.free': '免费',
      'premium.premium': '高级版',
      'premium.active': '高级版已激活',
      'premium.manage': '管理',
      'premium.removeAds': '移除广告',
      'premium.downloadApp': '下载应用以解锁高级版',
      'settings.premium': '高级版',
      'settings.cursor': '光标',
      'settings.cursorAnimated': '动画光标',
      'cursor.none': '无',
      'cursor.cat': '猫咪',
      'tracker.export': '导出',
      'onboarding.skip': '跳过',
      'onboarding.next': '下一步',
      'onboarding.start': '开始',
      'onboarding.createTitle': '创建追踪器',
      'onboarding.createDesc': '每个追踪器都是一个年度网格，您可以为每一天涂色。追踪习惯、心情、阅读——任何您想要的。',
      'onboarding.legendsTitle': '添加图例',
      'onboarding.legendsDesc': '定义每种颜色的含义。创建带有自定义颜色和标签的图例来组织您的追踪。',
      'onboarding.colorTitle': '为您的日子着色',
      'onboarding.colorDesc': '点击任意格子分配颜色并添加评论。看着您的一年被彩色圆点填满！',
      'stats.bestStreak': '最佳',
      'stats.distribution': '分布',
      'stats.monthly': '月度进展',
      'stats.weekday': '星期分布',
      'stats.global': '全局统计',
      'stats.thisYear': '今年',
      'stats.allTime': '全部',
      'stats.trackers': '追踪器',
      'stats.mostActive': '最活跃',
      'stats.perTracker': '按追踪器',
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
      'auth.invalidEmail': '電子郵件地址無效',
      'auth.loginError': '登入錯誤',
      'auth.registerError': '註冊錯誤',
      'auth.forgotPassword': '忘記密碼？',
      'auth.forgotPasswordBtn': '發送驗證碼',
      'auth.forgotPasswordSent': '如果該信箱存在帳號，已發送 6 位驗證碼。',
      'auth.codeLabel': '6 位驗證碼',
      'auth.enterCode': '請輸入發送到您信箱的驗證碼。',
      'auth.codeInvalid': '驗證碼無效或已過期',
      'auth.tooManyAttempts': '嘗試次數過多，請重新申請驗證碼',
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
      'tracker.addLegendsHint': '新增圖例以開始',
      'tracker.newTracker': '新追蹤器',
      'tracker.titleHint': '追蹤器名稱',
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
      'settings.legal': '法律聲明',

      // Common
      'common.cancel': '取消',
      'common.delete': '刪除',
      'common.yes': '確定',
      'common.erase': '清除',
      'common.add': '+ 新增',
      'common.ok': 'OK',
      'common.comment': '評論',
      'common.create': '+ 建立',
      'premium.title': '進階版',
      'premium.upgrade': '升級到進階版',
      'premium.restore': '恢復購買',
      'premium.feature.trackers': '無限追蹤器',
      'premium.feature.themes': '所有主題',
      'premium.feature.cursor': '動畫游標',
      'premium.feature.export': '匯出為圖片',
      'premium.feature.stats': '詳細統計',
      'premium.feature.noAds': '無廣告',
      'premium.trackerLimit': '免費帳戶最多3個追蹤器',
      'premium.free': '免費',
      'premium.premium': '進階版',
      'premium.active': '進階版已啟用',
      'premium.manage': '管理',
      'premium.removeAds': '移除廣告',
      'premium.downloadApp': '下載應用以解鎖進階版',
      'settings.premium': '進階版',
      'settings.cursor': '游標',
      'settings.cursorAnimated': '動畫游標',
      'cursor.none': '無',
      'cursor.cat': '貓咪',
      'tracker.export': '匯出',
      'onboarding.skip': '跳過',
      'onboarding.next': '下一步',
      'onboarding.start': '開始',
      'onboarding.createTitle': '建立追蹤器',
      'onboarding.createDesc': '每個追蹤器都是一個年度網格，您可以為每一天塗色。追蹤習慣、心情、閱讀——任何您想要的。',
      'onboarding.legendsTitle': '新增圖例',
      'onboarding.legendsDesc': '定義每種顏色的含義。建立帶有自訂顏色和標籤的圖例來組織您的追蹤。',
      'onboarding.colorTitle': '為您的日子著色',
      'onboarding.colorDesc': '點擊任意格子分配顏色並新增評論。看著您的一年被彩色圓點填滿！',
      'stats.bestStreak': '最佳',
      'stats.distribution': '分佈',
      'stats.monthly': '月度進展',
      'stats.weekday': '星期分佈',
      'stats.global': '全局統計',
      'stats.thisYear': '今年',
      'stats.allTime': '全部',
      'stats.trackers': '追蹤器',
      'stats.mostActive': '最活躍',
      'stats.perTracker': '按追蹤器',
    },
  };
}
