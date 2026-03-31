import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import * as api from '../lib/api';
import { connectWs, disconnectWs } from '../lib/ws';

interface AuthState {
  isLoading: boolean;
  isAuthenticated: boolean;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
}

const AuthContext = createContext<AuthState>({
  isLoading: true,
  isAuthenticated: false,
  login: async () => {},
  register: async () => {},
  logout: async () => {},
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [isLoading, setIsLoading] = useState(true);
  const [isAuthenticated, setIsAuthenticated] = useState(false);

  useEffect(() => {
    api.setOnAuthExpired(() => {
      setIsAuthenticated(false);
      disconnectWs();
    });

    api.tryRestoreSession().then((ok) => {
      setIsAuthenticated(ok);
      if (ok) connectWs();
      setIsLoading(false);
    });
  }, []);

  const loginFn = useCallback(async (email: string, password: string) => {
    await api.login(email, password);
    setIsAuthenticated(true);
    connectWs();
  }, []);

  const registerFn = useCallback(async (email: string, password: string) => {
    await api.register(email, password);
    setIsAuthenticated(true);
    connectWs();
  }, []);

  const logoutFn = useCallback(async () => {
    await api.logout();
    setIsAuthenticated(false);
    disconnectWs();
  }, []);

  return (
    <AuthContext.Provider value={{
      isLoading, isAuthenticated,
      login: loginFn, register: registerFn, logout: logoutFn,
    }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
