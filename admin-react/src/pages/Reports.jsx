import { useCallback, useEffect, useState } from 'react';
import api, { unwrap } from '../api/client';
import { StatusChip } from '../components/StatusChip';

const STATUSES = ['OPEN', 'IN_PROGRESS', 'RESOLVED'];
const CATEGORIES = ['ROADS', 'ELECTRICITY', 'WASTE', 'WATER', 'TRAFFIC', 'PUBLIC_SPACES'];

/** Reports table + filters + the detail drawer for triage. */
export default function Reports() {
  const [rows, setRows] = useState([]);
  const [total, setTotal] = useState(0);
  const [status, setStatus] = useState('');
  const [category, setCategory] = useState('');
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(0);
  const [selected, setSelected] = useState(null);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      const params = { page, size: 20 };
      if (status) params.status = status;
      if (category) params.category = category;
      if (search) params.search = search;
      if (status || search) params.includeHidden = true; // staff view
      const data = await unwrap(api.get('/feedback', { params }));
      setRows(data.content || []);
      setTotal(data.totalElements ?? 0);
    } catch (e) {
      setError(e.response?.data?.message || e.message);
    }
  }, [status, category, search, page]);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <div>
      <h1>Reports</h1>
      <div className="filters">
        <input
          placeholder="Search title / description…"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(0); }}
        />
        <select value={status} onChange={(e) => { setStatus(e.target.value); setPage(0); }}>
          <option value="">All statuses</option>
          {STATUSES.map((s) => <option key={s} value={s}>{s}</option>)}
        </select>
        <select value={category} onChange={(e) => { setCategory(e.target.value); setPage(0); }}>
          <option value="">All categories</option>
          {CATEGORIES.map((c) => <option key={c} value={c}>{c}</option>)}
        </select>
        <span className="muted">{total} reports</span>
      </div>

      {error && <p className="error">{error}</p>}

      <table className="table">
        <thead>
          <tr>
            <th>#</th>
            <th>Title</th>
            <th>Category</th>
            <th>Status</th>
            <th>▲</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((report) => (
            <tr key={report.id} onClick={() => setSelected(report.id)} className="row-link">
              <td>{report.id}</td>
              <td>{report.title}</td>
              <td>{report.category}</td>
              <td><StatusChip status={report.status} /></td>
              <td>{report.upvotes}</td>
              <td>{(report.createdAt || '').slice(0, 10)}</td>
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan="6" className="muted">No reports match the filters.</td></tr>
          )}
        </tbody>
      </table>

      <div className="pager">
        <button disabled={page === 0} onClick={() => setPage(page - 1)}>← Prev</button>
        <span className="muted">Page {page + 1}</span>
        <button disabled={(page + 1) * 20 >= total} onClick={() => setPage(page + 1)}>Next →</button>
      </div>

      {selected && (
        <ReportDrawer reportId={selected} onClose={() => setSelected(null)} onChanged={load} />
      )}
    </div>
  );
}

const ASSIGNEES = ['Amit', 'Priya', 'Rahul'];

/** Slide-in drawer: full report, status/assignment/notes, comments + history. */
function ReportDrawer({ reportId, onClose, onChanged }) {
  const [detail, setDetail] = useState(null);
  const [assignedTo, setAssignedTo] = useState('');
  const [publicNote, setPublicNote] = useState('');
  const [comment, setComment] = useState('');
  const [busy, setBusy] = useState(false);

  async function load() {
    try {
      const data = await unwrap(api.get(`/feedback/${reportId}`));
      setDetail(data);
      setAssignedTo(data.assignedTo || '');
      setPublicNote(data.publicNote || '');
    } catch (e) {
      setDetail({ error: e.response?.data?.message || e.message });
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [reportId]);

  async function patch(body) {
    setBusy(true);
    try {
      await unwrap(api.patch(`/feedback/${reportId}`, body));
      await load();
      onChanged();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    } finally {
      setBusy(false);
    }
  }

  async function changeStatus(newStatus) {
    setBusy(true);
    try {
      await unwrap(api.put(`/feedback/${reportId}/status`, { newStatus }));
      await load();
      onChanged();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    } finally {
      setBusy(false);
    }
  }

  async function addComment() {
    if (!comment.trim()) return;
    setBusy(true);
    try {
      await unwrap(api.post(`/feedback/${reportId}/comments`, { text: comment }));
      setComment('');
      await load();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <div className="drawer-backdrop" onClick={onClose}>
      <aside className="drawer" onClick={(e) => e.stopPropagation()}>
        {!detail ? (
          <p className="muted">Loading…</p>
        ) : detail.error ? (
          <p className="error">{detail.error}</p>
        ) : (
          <>
            <header>
              <h2>#{detail.id} — {detail.title}</h2>
              <button className="ghost" onClick={onClose}>✕</button>
            </header>

            <StatusChip status={detail.status} />
            <p className="muted">{detail.category} · ▲ {detail.upvotes} · reported by #{detail.userId}</p>
            <p>{detail.description}</p>

            {detail.images?.length > 0 && (
              <div className="photos">
                {detail.images.map((src) => (
                  <img key={src} src={src} alt="report" />
                ))}
              </div>
            )}

            <h3>Status</h3>
            <div className="btn-row">
              {STATUSES.map((s) => (
                <button
                  key={s}
                  disabled={busy || s === detail.status}
                  onClick={() => changeStatus(s)}
                >
                  {s}
                </button>
              ))}
            </div>

            <h3>Assignment & notes</h3>
            <label>
              Assigned to
              <select value={assignedTo} onChange={(e) => setAssignedTo(e.target.value)}>
                <option value="">Unassigned</option>
                {ASSIGNEES.map((name) => <option key={name} value={name}>{name}</option>)}
              </select>
            </label>
            <label>
              Public note
              <textarea rows={2} value={publicNote} onChange={(e) => setPublicNote(e.target.value)} />
            </label>
            <button disabled={busy} onClick={() => patch({ assignedTo, publicNote })}>
              Save changes
            </button>

            <h3>Comments</h3>
            <ul className="comments">
              {(detail.comments || []).map((c) => (
                <li key={c.id}><strong>#{c.userId}</strong> {c.text}</li>
              ))}
              {detail.comments?.length === 0 && <li className="muted">No comments yet.</li>}
            </ul>
            <div className="btn-row">
              <input
                placeholder="Add a comment…"
                value={comment}
                onChange={(e) => setComment(e.target.value)}
              />
              <button disabled={busy} onClick={addComment}>Post</button>
            </div>

            <h3>Status history</h3>
            <ul className="history">
              {(detail.history || []).map((h, i) => (
                <li key={i}>
                  {h.oldStatus || '—'} → <strong>{h.newStatus}</strong>{' '}
                  <span className="muted">by #{h.changedBy} at {h.changedAt?.slice(0, 16).replace('T', ' ')}</span>
                </li>
              ))}
            </ul>
          </>
        )}
      </aside>
    </div>
  );
}
