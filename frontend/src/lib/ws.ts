import { Platform } from 'react-native';
import { getAccessToken } from './api';

const WS_URL = __DEV__
  ? Platform.OS === 'web' ? 'ws://localhost:3001' : 'ws://192.168.1.1:3001'
  : 'wss://mydiandian.app';

type Listener = (event: string, data: any) => void;

let ws: WebSocket | null = null;
let listeners: Listener[] = [];
let reconnectTimer: ReturnType<typeof setTimeout> | null = null;

export function addWsListener(fn: Listener) {
  listeners.push(fn);
  return () => {
    listeners = listeners.filter(l => l !== fn);
  };
}

export function connectWs() {
  const token = getAccessToken();
  if (!token || ws?.readyState === WebSocket.OPEN) return;

  ws = new WebSocket(`${WS_URL}/ws?token=${token}`);

  ws.onmessage = (e) => {
    try {
      const msg = JSON.parse(e.data);
      listeners.forEach(fn => fn(msg.event, msg.data));
    } catch { /* ignore */ }
  };

  ws.onclose = () => {
    ws = null;
    if (reconnectTimer) clearTimeout(reconnectTimer);
    reconnectTimer = setTimeout(connectWs, 3000);
  };

  ws.onerror = () => {
    ws?.close();
  };
}

export function disconnectWs() {
  if (reconnectTimer) {
    clearTimeout(reconnectTimer);
    reconnectTimer = null;
  }
  ws?.close();
  ws = null;
}
