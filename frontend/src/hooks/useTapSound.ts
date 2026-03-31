import { useRef, useCallback } from 'react';
import { Platform } from 'react-native';
import { Audio } from 'expo-av';

const tapSrc = require('../../assets/dot-tap.mp3');

export function useTapSound() {
  const soundRef = useRef<Audio.Sound | null>(null);
  const webAudio = useRef<HTMLAudioElement | null>(null);

  const play = useCallback(async () => {
    try {
      if (Platform.OS === 'web') {
        // Web: use HTMLAudioElement for instant playback
        if (!webAudio.current) {
          const src = typeof tapSrc === 'number' ? '' :
            typeof tapSrc === 'string' ? tapSrc :
            (tapSrc as any)?.default ?? (tapSrc as any)?.uri ?? '';
          if (!src) return;
          webAudio.current = new window.Audio(src);
          webAudio.current.volume = 0.3;
        }
        webAudio.current.currentTime = 0.07; // Skip silence at start
        webAudio.current.play().catch(() => {});
      } else {
        // Native: use expo-av
        if (!soundRef.current) {
          const { sound } = await Audio.Sound.createAsync(tapSrc, { volume: 0.3 });
          soundRef.current = sound;
        }
        await soundRef.current.setPositionAsync(0);
        await soundRef.current.playAsync();
      }
    } catch { /* ignore */ }
  }, []);

  return play;
}
