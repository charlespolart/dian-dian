import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sync_engine.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';
import '../theme/motion.dart';

/// Around the screens: while the app is offline, a strip under the status
/// bar says so — « Hors ligne · tout est enregistré sur ce téléphone », or
/// « Hors ligne · 3 modifications à envoyer » — and the screens lay out
/// below it (the strip takes the status bar's room, nothing is covered).
/// Nothing shows while all is well.
class SyncBannerFrame extends StatelessWidget {
  const SyncBannerFrame({super.key, required this.status, required this.child});

  /// The session's engine; null without a session (nothing to tell).
  final SyncStatus? status;
  final Widget child;

  /// The texts this file shows (every language has them, see its test).
  static const textKeys = [
    'sync.offline',
    'sync.offlinePending.one',
    'sync.offlinePending.other',
    'sync.done',
    'sync.doneSent.one',
    'sync.doneSent.other',
  ];

  static String offlineText(LanguageProvider lang, int pending) => switch (pending) {
        0 => lang.t('sync.offline'),
        1 => lang.t('sync.offlinePending.one'),
        _ => lang.t('sync.offlinePending.other').replaceAll('{n}', '$pending'),
      };

  @override
  Widget build(BuildContext context) {
    final status = this.status;
    if (status == null) return _frame(context, offline: false, pending: 0);
    return ListenableBuilder(
      listenable: status,
      builder: (context, _) => _frame(context, offline: status.isOffline, pending: status.pendingCount),
    );
  }

  /// The same tree whether the strip shows or not, so that the screens keep
  /// their state when the app goes offline and comes back.
  Widget _frame(BuildContext context, {required bool offline, required int pending}) {
    final media = MediaQuery.of(context);
    return Column(
      children: [
        if (offline)
          Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(16 + media.viewPadding.left, media.viewPadding.top + 5, 16 + media.viewPadding.right, 5),
              decoration: BoxDecoration(
                // Mixed toward the theme's background: readable on every theme.
                color: Color.lerp(AppColors.accent, AppColors.bg, 0.88),
                border: Border(bottom: BorderSide(color: AppColors.shellBorder)),
              ),
              child: Text(
                offlineText(context.watch<LanguageProvider>(), pending),
                style: AppFonts.dot(fontSize: 11, color: AppColors.text),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        Expanded(
          child: MediaQuery(
            data: offline ? media.removePadding(removeTop: true) : media,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// At the bottom, at each return: « Synchronisé », or « Synchronisé · 31
/// modifications envoyées » when changes went; gone by itself after 3
/// seconds. [bottom] is the distance from the screen's bottom edge (the
/// system bar and the ad banner, as for the undo bar); [right], from the
/// right edge (left of the list's + button).
class SyncToast extends StatefulWidget {
  const SyncToast({super.key, required this.status, required this.bottom, this.right = 16});

  final SyncStatus? status;
  final double bottom;
  final double right;

  static const shown = Duration(seconds: 3);

  @override
  State<SyncToast> createState() => _SyncToastState();
}

class _SyncToastState extends State<SyncToast> {
  int _seenReturns = 0;
  // What the toast says (kept through its fade-out); null when gone.
  int? _sent;
  bool _visible = false;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    _seenReturns = widget.status?.returns ?? 0;
    widget.status?.addListener(_onStatus);
  }

  @override
  void didUpdateWidget(SyncToast old) {
    super.didUpdateWidget(old);
    if (!identical(old.status, widget.status)) {
      old.status?.removeListener(_onStatus);
      _seenReturns = widget.status?.returns ?? 0;
      widget.status?.addListener(_onStatus);
    }
  }

  void _onStatus() {
    final status = widget.status;
    if (status == null || status.returns == _seenReturns) return;
    _seenReturns = status.returns;
    _hide?.cancel();
    setState(() {
      _sent = status.returnedSent;
      _visible = true;
    });
    _hide = Timer(SyncToast.shown, () {
      if (!mounted) return;
      setState(() {
        _visible = false;
        // Without motion there is no fade whose end would remove it.
        if (AppMotion.reduced(context)) _sent = null;
      });
    });
  }

  @override
  void dispose() {
    widget.status?.removeListener(_onStatus);
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent;
    if (sent == null) return const SizedBox.shrink();
    final lang = context.watch<LanguageProvider>();
    final text = switch (sent) {
      0 => lang.t('sync.done'),
      1 => lang.t('sync.doneSent.one'),
      _ => lang.t('sync.doneSent.other').replaceAll('{n}', '$sent'),
    };
    return Positioned(
      left: 16,
      right: widget.right,
      bottom: widget.bottom,
      child: IgnorePointer(
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.quick,
          onEnd: () {
            if (!_visible && mounted) setState(() => _sent = null);
          },
          child: Center(
            child: Material(
              key: const Key('sync.toast'),
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.shell,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.shellBorder),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                ),
                child: Text(text, style: AppFonts.dot(fontSize: 12, color: AppColors.text), textAlign: TextAlign.center),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
