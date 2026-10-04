import { useCallback, useEffect, useState } from 'react';
import api, { unwrap } from '../api/client';

/** User list + role management (CITIZEN / ADMIN). */
export default function Users() {
  const [rows, setRows] = useState([]);
  const [search, setSearch] = useState('');
  const [role, setRole] = useState('');
  const [page, setPage] = useState(0);
  const [total, setTotal] = useState(0);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      const params = { page, size: 20 };
      if (search) params.search = search;
      if (role) params.role = role;
      const data = await unwrap(api.get('/auth/admin/users', { params }));
      setRows(data.content || []);
      setTotal(data.totalElements ?? 0);
    } catch (e) {
      setError(e.response?.data?.message || e.message);
    }
  }, [search, role, page]);

  useEffect(() => {
    load();
  }, [load]);

  async function changeRole(userId, newRole) {
    try {
      await unwrap(api.patch(`/auth/admin/users/${userId}/role`, { newRole }));
      await load();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    }
  }

  return (
    <div>
      <h1>Users</h1>
      <div className="filters">
        <input
          placeholder="Search name / email…"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(0); }}
        />
        <select value={role} onChange={(e) => { setRole(e.target.value); setPage(0); }}>
          <option value="">All roles</option>
          <option value="CITIZEN">CITIZEN</option>
          <option value="ADMIN">ADMIN</option>
        </select>
        <span className="muted">{total} users</span>
      </div>

      {error && <p className="error">{error}</p>}

      <table className="table">
        <thead>
          <tr><th>#</th><th>Name</th><th>Email</th><th>Role</th><th>Joined</th></tr>
        </thead>
        <tbody>
          {rows.map((user) => (
            <tr key={user.id}>
              <td>{user.id}</td>
              <td>{user.name}</td>
              <td>{user.email}</td>
              <td>
                <select
                  value={user.role}
                  onChange={(e) => changeRole(user.id, e.target.value)}
                >
                  <option value="CITIZEN">CITIZEN</option>
                  <option value="ADMIN">ADMIN</option>
                </select>
              </td>
              <td>{(user.createdAt || '').slice(0, 10)}</td>
            </tr>
          ))}
          {rows.length === 0 && <tr><td colSpan="5" className="muted">No users found.</td></tr>}
        </tbody>
      </table>

      <div className="pager">
        <button disabled={page === 0} onClick={() => setPage(page - 1)}>← Prev</button>
        <span className="muted">Page {page + 1}</span>
        <button disabled={(page + 1) * 20 >= total} onClick={() => setPage(page + 1)}>Next →</button>
      </div>
    </div>
  );
}
