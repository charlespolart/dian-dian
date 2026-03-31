import { useCallback, useRef } from 'react';
import { Platform } from 'react-native';
import { Audio } from 'expo-av';

const tapSrc = require('../../assets/dot-tap.mp3');

const SKIP_START = 0.07;
const VOLUME = 0.3;

// ── Web Audio API singleton ──
let ctx: AudioContext | null = null;
let decodedBuffer: AudioBuffer | null = null;
let gainNode: GainNode | null = null;
let unlocked = false;

function getContext(): AudioContext {
  if (!ctx) {
    ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
    gainNode = ctx.createGain();
    gainNode.gain.value = VOLUME;
    gainNode.connect(ctx.destination);
  }
  return ctx;
}

async function loadBuffer(): Promise<void> {
  if (decodedBuffer) return;
  const audioCtx = getContext();
  const src = typeof tapSrc === 'string'
    ? tapSrc
    : (tapSrc as any)?.default ?? (tapSrc as any)?.uri ?? '';
  if (!src) return;
  const response = await fetch(src);
  const arrayBuffer = await response.arrayBuffer();
  decodedBuffer = await audioCtx.decodeAudioData(arrayBuffer);
}

function playBufferWeb(): void {
  if (!ctx || !decodedBuffer || !gainNode) return;
  const source = ctx.createBufferSource();
  source.buffer = decodedBuffer;
  source.connect(gainNode);
  source.start(0, SKIP_START);
}

// ── Unlock: resume AudioContext + play silent buffer inside user gesture ──
if (typeof document !== 'undefined') {
  const unlock = () => {
    if (unlocked) return;
    const audioCtx = getContext();
    audioCtx.resume().then(() => {
      // Play silent buffer to fully prime iOS audio pipeline
      const silent = audioCtx.createBuffer(1, 1, audioCtx.sampleRate);
      const src = audioCtx.createBufferSource();
      src.buffer = silent;
      src.connect(audioCtx.destination);
      src.start();
      unlocked = true;
      // Pre-decode actual sound
      loadBuffer();
      for (const evt of ['touchstart', 'touchend', 'click', 'keydown'] as const) {
        document.removeEventListener(evt, unlock, true);
      }
    }).catch(() => {});
  };
  for (const evt of ['touchstart', 'touchend', 'click', 'keydown'] as const) {
    document.addEventListener(evt, unlock, { capture: true, passive: true } as any);
  }
}

// ── Hook ──
export function useTapSound() {
  const soundRef = useRef<Audio.Sound | null>(null);

  const play = useCallback(async () => {
    try {
      if (Platform.OS === 'web') {
        if (!decodedBuffer) await loadBuffer();
        playBufferWeb();
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
