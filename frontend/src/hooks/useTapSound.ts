import { useCallback, useRef } from 'react';
import { Platform } from 'react-native';
import { Audio } from 'expo-av';

const tapSrc = require('../../assets/dot-tap.mp3');
const eraseSrc = require('../../assets/dot-erase.mp3');

const SKIP_START_TAP = 0;
const SKIP_START_ERASE = 0;
const VOLUME = 0.3;

// ── Web Audio API singleton ──
let ctx: AudioContext | null = null;
let tapBuffer: AudioBuffer | null = null;
let eraseBuffer: AudioBuffer | null = null;
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

async function loadWebBuffer(url: string): Promise<AudioBuffer> {
  const audioCtx = getContext();
  const response = await fetch(url);
  const arrayBuffer = await response.arrayBuffer();
  return audioCtx.decodeAudioData(arrayBuffer);
}

async function loadBuffers(): Promise<void> {
  if (tapBuffer && eraseBuffer) return;
  const [tap, erase] = await Promise.all([
    tapBuffer ? tapBuffer : loadWebBuffer('/dot-tap.mp3'),
    eraseBuffer ? eraseBuffer : loadWebBuffer('/dot-erase.mp3'),
  ]);
  tapBuffer = tap;
  eraseBuffer = erase;
}

function playWeb(buffer: AudioBuffer, offset: number): void {
  if (!ctx || !gainNode) return;
  const source = ctx.createBufferSource();
  source.buffer = buffer;
  source.connect(gainNode);
  source.start(0, offset);
}

// ── Unlock ──
if (typeof document !== 'undefined') {
  const unlock = () => {
    if (unlocked) return;
    const audioCtx = getContext();
    audioCtx.resume().then(() => {
      const silent = audioCtx.createBuffer(1, 1, audioCtx.sampleRate);
      const src = audioCtx.createBufferSource();
      src.buffer = silent;
      src.connect(audioCtx.destination);
      src.start();
      unlocked = true;
      loadBuffers();
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
  const tapRef = useRef<Audio.Sound | null>(null);
  const eraseRef = useRef<Audio.Sound | null>(null);

  const playTap = useCallback(async () => {
    try {
      if (Platform.OS === 'web') {
        if (!tapBuffer) await loadBuffers();
        if (tapBuffer) playWeb(tapBuffer, SKIP_START_TAP);
      } else {
        if (!tapRef.current) {
          const { sound } = await Audio.Sound.createAsync(tapSrc, { volume: VOLUME });
          tapRef.current = sound;
        }
        await tapRef.current.setPositionAsync(SKIP_START_TAP * 1000);
        await tapRef.current.playAsync();
      }
    } catch { /* ignore */ }
  }, []);

  const playErase = useCallback(async () => {
    try {
      if (Platform.OS === 'web') {
        if (!eraseBuffer) await loadBuffers();
        if (eraseBuffer) playWeb(eraseBuffer, SKIP_START_ERASE);
      } else {
        if (!eraseRef.current) {
          const { sound } = await Audio.Sound.createAsync(eraseSrc, { volume: VOLUME });
          eraseRef.current = sound;
        }
        await eraseRef.current.setPositionAsync(SKIP_START_ERASE * 1000);
        await eraseRef.current.playAsync();
      }
    } catch { /* ignore */ }
  }, []);

  return { playTap, playErase };
}
