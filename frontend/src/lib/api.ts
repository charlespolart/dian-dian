import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

const API_URL = __DEV__
  ? Platform.OS === 'web' ? 'http://localhost:3001/api' : 'http://192.168.1.1:3001/api'
  : 'https://mydiandian.app/api';

let accessToken: string | null = null;
let onAuthExpired: (() => void) | null = null;

export function setOnAuthExpired(cb: () => void) {
  onAuthExpired = cb;
}

export function setAccessToken(token: string | null) {
  accessToken = token;
}

export function getAccessToken() {
  return accessToken;
}

async function getRefreshToken(): Promise<string | null> {
  if (Platform.OS === 'web') {
    return localStorage.getItem('refreshToken');
  }
  return SecureStore.getItemAsync('refreshToken');
}

async function setRefreshToken(token: string | null) {
  if (Platform.OS === 'web') {
    if (token) localStorage.setItem('refreshToken', token);
    else localStorage.removeItem('refreshToken');
  } else {
    if (token) await SecureStore.setItemAsync('refreshToken', token);
    else await SecureStore.deleteItemAsync('refreshToken');
  }
}

async function refreshAccessToken(): Promise<boolean> {
  const refreshToken = await getRefreshToken();
  if (!refreshToken) return false;

  try {
    const res = await fetch(`${API_URL}/auth/refresh`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ refreshToken }),
    });

    if (!res.ok) {
      await setRefreshToken(null);
      return false;
    }

    const data = await res.json();
    accessToken = data.accessToken;
    await setRefreshToken(data.refreshToken);
    return true;
  } catch {
    return false;
  }
}

export async function apiFetch(path: string, options: RequestInit = {}): Promise<Response> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string> || {}),
  };

  if (accessToken) {
    headers['Authorization'] = `Bearer ${accessToken}`;
  }

  let res = await fetch(`${API_URL}${path}`, { ...options, headers });

  if (res.status === 401 && accessToken) {
    const refreshed = await refreshAccessToken();
    if (refreshed) {
      headers['Authorization'] = `Bearer ${accessToken}`;
      res = await fetch(`${API_URL}${path}`, { ...options, headers });
    } else {
      accessToken = null;
      onAuthExpired?.();
    }
  }

  return res;
}

export async function login(email: string, password: string) {
  const res = await fetch(`${API_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const data = await res.json();
    throw new Error(data.error || 'Erreur de connexion');
  }

  const data = await res.json();
  accessToken = data.accessToken;
  await setRefreshToken(data.refreshToken);
  return data;
}

export async function register(email: string, password: string) {
  const res = await fetch(`${API_URL}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!res.ok) {
    const data = await res.json();
    throw new Error(data.error || "Erreur d'inscription");
  }

  const data = await res.json();
  accessToken = data.accessToken;
  await setRefreshToken(data.refreshToken);
  return data;
}

export async function logout() {
  try {
    await apiFetch('/auth/logout', { method: 'POST' });
  } catch { /* ignore */ }
  accessToken = null;
  await setRefreshToken(null);
}

export async function tryRestoreSession(): Promise<boolean> {
  return refreshAccessToken();
}

export { API_URL };
