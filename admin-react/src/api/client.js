import axios from 'axios';

// All admin traffic goes through the API gateway — never direct to services.
export const API_BASE = import.meta.env.VITE_API_BASE || 'http://localhost:8080/api/v1';

const TOKEN_KEY = 'civicpulse_admin_token';

// localStorage can be missing in non-browser environments (tests).
const storage = typeof localStorage !== 'undefined' ? localStorage : null;

export function getToken() {
  return storage ? storage.getItem(TOKEN_KEY) : null;
}

export function setToken(token) {
  if (storage) storage.setItem(TOKEN_KEY, token);
}

export function clearToken() {
  if (storage) storage.removeItem(TOKEN_KEY);
}

const api = axios.create({ baseURL: API_BASE });

// Attach the JWT to every request.
api.interceptors.request.use((config) => {
  const token = getToken();
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

// A 401 means the 24h token expired or is invalid — back to login.
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401 && getToken()) {
      clearToken();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  },
);

/** Pulls `data` out of the backend ApiResponse envelope. */
export async function unwrap(promise) {
  const response = await promise;
  return response.data.data;
}

export default api;
