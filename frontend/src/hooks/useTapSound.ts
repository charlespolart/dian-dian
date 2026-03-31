import { useRef, useCallback } from 'react';
import { Platform } from 'react-native';
import { Audio } from 'expo-av';

const tapSrc = require('../../assets/dot-tap.mp3');

const SKIP_START = 0.07;
const VOLUME = 0.3;

let audioCtx: AudioContext | null = null;
let audioBuffer: AudioBuffer | null = null;
let bufferLoading = false;

async function ensureBuffer() {
  // Create AudioContext on first user gesture
  if (!audioCtx) {
    audioCtx = new (window.AudioContext || (window as any).webkitAudioContext)();
  }
  if (audioCtx.state === 'suspended') {
    await audioCtx.resume();
  }
  if (audioBuffer || bufferLoading) return;
  bufferLoading = true;
  try {
    const src = typeof tapSrc === 'string' ? tapSrc :
      (tapSrc as any)?.default ?? (tapSrc as any)?.uri ?? '';
    if (!src) return;
    const response = await fetch(src);
    const arrayBuffer = await response.arrayBuffer();
    audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
  } catch { /* ignore */ }
  bufferLoading = false;
}

export function useTapSound() {
  const soundRef = useRef<Audio.Sound | null>(null);

  const play = useCallback(async () => {
    try {
      if (Platform.OS === 'web') {
        await ensureBuffer();
        if (!audioBuffer || !audioCtx) return;
        const source = audioCtx.createBufferSource();
        source.buffer = audioBuffer;
        const gain = audioCtx.createGain();
        gain.gain.value = VOLUME;
        source.connect(gain);
        gain.connect(audioCtx.destination);
        source.start(0, SKIP_START);
      } else {
        if (!soundRef.current) {
          const { sound } = await Audio.Sound.createAsync(tapSrc, { volume: VOLUME });
          soundRef.current = sound;
        }
        await soundRef.current.setPositionAsync(SKIP_START * 1000);
        await soundRef.current.playAsync();
      }
    } catch { /* ignore */ }
  }, []);

  return play;
}
