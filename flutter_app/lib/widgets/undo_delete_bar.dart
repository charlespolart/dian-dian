import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'press_scale.dart';

/// Animated undo bar shown after deleting a tracker.
class UndoDeleteBar extends StatefulWidget {
  final String pageName;
  final VoidCallback onUndo;
  final Duration duration;

  const UndoDeleteBar({
    super.key,
    required this.pageName,
    required this.onUndo,
    required this.duration,
  });

  @override
  State<UndoDeleteBar> createState() => _UndoDeleteBarState();
}

class _UndoDeleteBarState extends State<UndoDeleteBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.shell,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.shellBorder),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '"${widget.pageName}" deleted',
                  style: AppFonts.dot(fontSize: 12, color: AppColors.text),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              PressScale(
                onTap: widget.onUndo,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.accent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Undo',
                    style: AppFonts.pixel(
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: 1.0 - _controller.value,
                  minHeight: 3,
                  backgroundColor: AppColors.dotEmpty,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
