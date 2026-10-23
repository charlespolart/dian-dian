import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

/// The "Sons" section of the settings: one tile that switches every sound
/// on or off (its own press is the preview when turning on). Same title
/// and tile as the sections around it.
class SoundsSettings extends StatelessWidget {
  const SoundsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final audio = context.watch<AudioService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang.t('settings.sounds'), style: AppFonts.pixel(fontSize: 13, color: AppColors.subtitle)),
        const SizedBox(height: 8),
        // The tile's own press is the preview: it is pending when the switch
        // flips, so it plays when turning on and is dropped when turning off.
        PressScale(
          onTap: () => audio.setEnabled(!audio.enabled),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: AppColors.shell,
              border: Border.all(color: AppColors.shellBorder),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(lang.t(audio.enabled ? 'settings.soundsOn' : 'settings.soundsOff'),
                    style: AppFonts.dot(fontSize: 14, color: AppColors.text)),
                Text('>', style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
