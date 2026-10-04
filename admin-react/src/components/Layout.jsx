import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';

const LINKS = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/reports', label: 'Reports' },
  { to: '/map', label: 'Map' },
  { to: '/polls', label: 'Polls' },
  { to: '/users', label: 'Users' },
  { to: '/audit', label: 'Audit Log' },
];

export default function Layout() {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  function handleLogout() {
    logout();
    navigate('/login');
  }

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand">CivicPulse</div>
        <nav>
          {LINKS.map((link) => (
            <NavLink key={link.to} to={link.to} end={link.end}>
              {link.label}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-footer">
          <div className="who">
            <strong>{user?.name}</strong>
            <span>{user?.email}</span>
          </div>
          <button className="ghost" onClick={handleLogout}>Sign out</button>
        </div>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
