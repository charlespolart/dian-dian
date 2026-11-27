import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

const String _googleGLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18">
<path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z"/>
<path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z"/>
<path fill="#FBBC05" d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z"/>
<path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z"/>
</svg>
''';

/// Google **Web** OAuth client id — required by `google_sign_in` on Android as
/// `serverClientId` (the Android client id will NOT work here). It is also what
/// becomes the `aud` of the id_token, so it must stay listed in the backend's
/// `GOOGLE_CLIENT_IDS`. Public value, safe in the binary — the Web client
/// *secret* is the part that stays server-side.
const String _googleWebClientId =
    '1095494651933-rrqbtudlcpuemcu40gaf3l1j61s7rokt.apps.googleusercontent.com';

/// The platform windows of Apple and Google: each gives an identity token,
/// or null when the person closed it (case 4: back, without a message).
/// Anything else that goes wrong is thrown.
class IdentityWindows {
  const IdentityWindows();

  Future<String?> apple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('Apple did not return an identity token');
      return identityToken;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }
  }

  Future<String?> google() async {
    try {
      final signIn = GoogleSignIn.instance;
      // iOS picks up the client id from Info.plist (`GIDClientID`). Android
      // authenticates via package name + SHA-1, but google_sign_in 7.x still
      // requires the Web client id to mint an id_token — without it the plugin
      // throws "serverClientId must be provided on Android". Left unset on iOS
      // so the working flow there is untouched.
      await signIn.initialize(
        serverClientId: defaultTargetPlatform == TargetPlatform.android ? _googleWebClientId : null,
      );
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('Google did not return an ID token');
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }
}

/// One more button of the welcome screen, after Apple and Google.
class AuthChoice {
  final Key key;
  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  const AuthChoice({required this.key, required this.icon, required this.label, required this.onPressed});
}

/// « Continuer avec Apple » (iPhone only) and « Continuer avec Google »,
/// then [trailing] — the welcome screen's other two buttons — all the same
/// size and weight (chantier 9: four buttons, none of them a wall): one
/// text size for the four, the largest at which the longest label shows
/// whole. While a window is open, every button waits.
class OAuthButtons extends StatefulWidget {
  /// Called when an OAuth flow fails (e.g. token rejected by backend).
  final void Function(String message)? onError;

  /// Called before a window opens: true stops it (no network, told).
  final Future<bool> Function()? blocked;

  final List<AuthChoice> trailing;
  final IdentityWindows windows;

  const OAuthButtons({
    super.key,
    this.onError,
    this.blocked,
    this.trailing = const [],
    this.windows = const IdentityWindows(),
  });

  /// Whether Apple's button shows: on the iPhone, as before.
  static bool get appleAvailable => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get googleAvailable =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

  @override
  State<OAuthButtons> createState() => _OAuthButtonsState();
}

class _OAuthButtonsState extends State<OAuthButtons> {
  bool _busy = false;

  Future<void> _signIn(String provider, Future<String?> Function() window) async {
    if (_busy) return;
    if (await (widget.blocked?.call() ?? Future.value(false))) return;
    if (!mounted) return;
    setState(() => _busy = true);
    try {
      final identityToken = await window();
      if (identityToken == null || !mounted) return; // closed by the person (case 4)
      await context.read<AuthProvider>().oauthSignIn(provider: provider, identityToken: identityToken);
    } on SignInWithAppleAuthorizationException catch (e) {
      widget.onError?.call(e.message);
    } on GoogleSignInException catch (e) {
      widget.onError?.call(e.description ?? e.code.name);
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    const logo = AuthButton.baseFontSize;
    final choices = <AuthChoice>[
      if (OAuthButtons.appleAvailable)
        AuthChoice(
          key: const ValueKey('welcome.apple'),
          // Apple's own logo, at the proportions of its standard button
          // (sign_in_with_apple's painter): a custom button as Apple's
          // guidelines allow, so that its label takes the common size.
          icon: SizedBox(
            width: logo * (25 / 31),
            height: logo,
            child: CustomPaint(painter: AppleLogoPainter(color: Colors.black)),
          ),
          label: lang.t('welcome.apple'),
          onPressed: () => _signIn('apple', widget.windows.apple),
        ),
      if (OAuthButtons.googleAvailable)
        AuthChoice(
          key: const ValueKey('welcome.google'),
          icon: SvgPicture.string(_googleGLogoSvg, width: 18, height: 18),
          label: lang.t('welcome.google'),
          onPressed: () => _signIn('google', widget.windows.google),
        ),
      ...widget.trailing,
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = AuthButton.fittingFontSize(context, [for (final c in choices) c.label], constraints.maxWidth);
        final buttons = [
          for (final c in choices)
            _tinted(AuthButton(key: c.key, icon: c.icon, label: c.label, onPressed: c.onPressed, fontSize: fontSize)),
        ];
        return _stack(buttons);
      },
    );
  }

  Widget _stack(List<Widget> buttons) {
    return Stack(
      children: [
        // Buttons stay laid out so the column doesn't jump while busy.
        Opacity(
          opacity: _busy ? 0.4 : 1,
          child: IgnorePointer(
            ignoring: _busy,
            child: Column(
              children: [
                for (var i = 0; i < buttons.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  buttons[i],
                ],
              ],
            ),
          ),
        ),
        if (_busy)
          Positioned.fill(
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Semi-transparent cream overlay so the (mandatory) standard Apple/Google
  /// button styles blend with the app's pixel-art cream palette without
  /// breaking HIG/branding requirements. Every button gets it: same weight.
  Widget _tinted(Widget child) {
    return Container(
      foregroundDecoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }
}

/// A button with the silhouette of Apple's white outlined one: its height,
/// border, corner, and its label's font, at most at its size
/// (sign_in_with_apple's `height * 0.43`), so that the four buttons of the
/// welcome screen weigh the same.
class AuthButton extends StatelessWidget {
  static const double height = 44;
  static const double baseFontSize = height * 0.43;
  static const double _padding = 16;
  static const double _gap = 8;

  final Widget icon;
  final String label;
  final VoidCallback? onPressed;
  final double fontSize;

  const AuthButton({super.key, required this.icon, required this.label, required this.onPressed, this.fontSize = baseFontSize});

  static TextStyle _style(double fontSize) => TextStyle(
        inherit: false,
        fontFamily: '.SF Pro Text',
        fontSize: fontSize,
        color: Colors.black,
        letterSpacing: -0.41,
      );

  /// The largest size, up to [baseFontSize], at which every one of
  /// [labels] shows whole on a button [width] wide (the phone's text size
  /// setting included). Never under 11: past that, the label is cut.
  static double fittingFontSize(BuildContext context, List<String> labels, double width) {
    final room = width - 2 * _padding - baseFontSize - _gap - 2; // the icon's box, and a border on each side
    final scaler = MediaQuery.textScalerOf(context);
    var scale = 1.0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: _style(baseFontSize)),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      if (painter.width > room) scale = scale < room / painter.width ? scale : room / painter.width;
      painter.dispose();
    }
    final size = (baseFontSize * scale * 2).floorToDouble() / 2; // half points: no fraction left to round up
    return size < 11 ? 11 : size;
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF000000), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: baseFontSize, child: Center(child: icon)),
            const SizedBox(width: _gap),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: _style(fontSize)),
            ),
          ],
        ),
      ),
    );
  }
}
