import { createContext, useContext, useEffect, useState } from 'react';
import api, { getToken, setToken, clearToken, unwrap } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(Boolean(getToken()));

  // Restore the session on refresh via /auth/me.
  useEffect(() => {
    if (!getToken()) return;
    api
      .get('/auth/me')
      .then((response) => setUser(response.data.data))
      .catch(() => clearToken())
      .finally(() => setChecking(false));
  }, []);

  async function login(email, password) {
    const data = await unwrap(api.post('/auth/login', { email, password }));
    setToken(data.accessToken);
    setUser(data.user);
    return data.user;
  }

  function logout() {
    clearToken();
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, checking, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  return useContext(AuthContext);
}
