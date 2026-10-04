import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom';
import { AuthProvider, useAuth } from './auth/AuthContext';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';
import MapPage from './pages/MapPage';
import Polls from './pages/Polls';
import Reports from './pages/Reports';
import Users from './pages/Users';
import Audit from './pages/Audit';
import './styles.css';

/** Gate: only signed-in admins reach the shell; only ADMIN role is allowed. */
function RequireAdmin({ children }) {
  const { user, checking } = useAuth();
  if (checking) return <p className="muted" style={{ padding: 24 }}>Restoring session…</p>;
  if (!user) return <Navigate to="/login" replace />;
  if (user.role !== 'ADMIN') {
    return <p className="error" style={{ padding: 24 }}>Access denied — this console is for administrators.</p>;
  }
  return children;
}

function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={(
              <RequireAdmin>
                <Layout />
              </RequireAdmin>
            )}
          >
            <Route index element={<Dashboard />} />
            <Route path="reports" element={<Reports />} />
            <Route path="map" element={<MapPage />} />
            <Route path="polls" element={<Polls />} />
            <Route path="users" element={<Users />} />
            <Route path="audit" element={<Audit />} />
          </Route>
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
