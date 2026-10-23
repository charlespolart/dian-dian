import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/language_provider.dart';
import '../services/audio_service.dart';
import '../theme/app_theme.dart';
import 'press_scale.dart';

/// The "Sons" and "Vibrations" sections of the settings: one tile each,
/// switching every sound or every vibration on or off, independently. The
/// sounds tile's own press is its preview when turning on; the vibrations
/// tile previews a light one. Same title and tile as the sections around.
class SoundsSettings extends StatelessWidget {
  const SoundsSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final audio = context.watch<AudioService>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(lang.t('settings.sounds')),
        const SizedBox(height: 8),
        _tile(
          key: const Key('settings.sounds'),
          label: lang.t(audio.enabled ? 'settings.soundsOn' : 'settings.soundsOff'),
          onTap: () => audio.setEnabled(!audio.enabled),
        ),
        const SizedBox(height: 24),
        _title(lang.t('settings.haptics')),
        const SizedBox(height: 8),
        _tile(
          key: const Key('settings.haptics'),
          label: lang.t(audio.hapticsEnabled ? 'settings.hapticsOn' : 'settings.hapticsOff'),
          onTap: () async {
            final turningOn = !audio.hapticsEnabled;
            await audio.setHapticsEnabled(turningOn);
            if (turningOn) audio.feel(Haptic.light);
          },
        ),
      ],
    );
  }

  Widget _title(String text) => Text(text, style: AppFonts.pixel(fontSize: 13, color: AppColors.subtitle));

  Widget _tile({required Key key, required String label, required VoidCallback onTap}) {
    return PressScale(
      key: key,
      onTap: onTap,
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
            Text(label, style: AppFonts.dot(fontSize: 14, color: AppColors.text)),
            Text('>', style: AppFonts.pixel(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
