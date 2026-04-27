import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

const String _googleGLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 18 18">
<path fill="#4285F4" d="M17.64 9.2c0-.637-.057-1.251-.164-1.84H9v3.481h4.844a4.14 4.14 0 0 1-1.796 2.716v2.259h2.908c1.702-1.567 2.684-3.875 2.684-6.615z"/>
<path fill="#34A853" d="M9 18c2.43 0 4.467-.806 5.956-2.18l-2.908-2.259c-.806.54-1.837.86-3.048.86-2.344 0-4.328-1.584-5.036-3.711H.957v2.332A8.997 8.997 0 0 0 9 18z"/>
<path fill="#FBBC05" d="M3.964 10.71A5.41 5.41 0 0 1 3.682 9c0-.593.102-1.17.282-1.71V4.958H.957A8.996 8.996 0 0 0 0 9c0 1.452.348 2.827.957 4.042l3.007-2.332z"/>
<path fill="#EA4335" d="M9 3.58c1.321 0 2.508.454 3.44 1.345l2.582-2.58C13.463.891 11.426 0 9 0A8.997 8.997 0 0 0 .957 4.958L3.964 7.29C4.672 5.163 6.656 3.58 9 3.58z"/>
</svg>
''';

/// "Sign in with Apple" + "Sign in with Google" stacked buttons.
/// Renders only the buttons that make sense on the current platform.
class OAuthButtons extends StatefulWidget {
  /// Called when an OAuth flow fails (e.g. token rejected by backend).
  final void Function(String message)? onError;

  const OAuthButtons({super.key, this.onError});

  @override
  State<OAuthButtons> createState() => _OAuthButtonsState();
}

class _OAuthButtonsState extends State<OAuthButtons> {
  bool _busy = false;

  bool get _appleAvailable {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  bool get _googleAvailable {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  Future<void> _signInWithApple() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('Apple did not return an identity token');
      if (!mounted) return;
      await context.read<AuthProvider>().oauthSignIn(
        provider: 'apple',
        identityToken: identityToken,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      widget.onError?.call(e.message);
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final signIn = GoogleSignIn.instance;
      // iOS picks up the client id from Info.plist (`GIDClientID`); Android
      // uses the package name + SHA-1 registered with the Cloud project.
      await signIn.initialize();
      final account = await signIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) throw Exception('Google did not return an ID token');
      if (!mounted) return;
      await context.read<AuthProvider>().oauthSignIn(
        provider: 'google',
        identityToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
      widget.onError?.call(e.description ?? e.code.name);
    } catch (e) {
      widget.onError?.call(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_appleAvailable && !_googleAvailable) return const SizedBox.shrink();
    return Stack(
      children: [
        // Buttons stay laid out so the column doesn't jump while busy.
        Opacity(
          opacity: _busy ? 0.4 : 1,
          child: IgnorePointer(
            ignoring: _busy,
            child: Column(
              children: [
                if (_appleAvailable)
                  _tinted(
                    SignInWithAppleButton(
                      onPressed: _signInWithApple,
                      style: SignInWithAppleButtonStyle.whiteOutlined,
                      height: 44,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                if (_appleAvailable && _googleAvailable) const SizedBox(height: 8),
                if (_googleAvailable)
                  _tinted(_GoogleButton(onPressed: _signInWithGoogle)),
                const SizedBox(height: 12),
                _separator(),
                const SizedBox(height: 12),
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
  /// breaking HIG/branding requirements.
  Widget _tinted(Widget child) {
    return Container(
      foregroundDecoration: BoxDecoration(
        color: AppColors.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }

  Widget _separator() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AppColors.shellBorder)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: AppFonts.dot(fontSize: 11, color: AppColors.textMuted)),
        ),
        Expanded(child: Container(height: 1, color: AppColors.shellBorder)),
      ],
    );
  }
}

/// White button matching SignInWithAppleButtonStyle.whiteOutlined silhouette
/// (height, border, label weight) with the official 4-color Google G logo.
class _GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _GoogleButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF000000), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.string(_googleGLogoSvg, width: 18, height: 18),
            const SizedBox(width: 8),
            const Text(
              'Sign in with Google',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: Colors.black,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
