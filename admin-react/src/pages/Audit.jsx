import { useEffect, useState } from 'react';
import api, { unwrap } from '../api/client';
import { StatusChip } from '../components/StatusChip';

/** Every audited status transition, newest first. */
export default function Audit() {
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');

  useEffect(() => {
    unwrap(api.get('/feedback/admin/audit', { params: { limit: 200 } }))
      .then(setRows)
      .catch((e) => setError(e.response?.data?.message || e.message));
  }, []);

  return (
    <div>
      <h1>Audit Log</h1>
      {error && <p className="error">{error}</p>}
      <table className="table">
        <thead>
          <tr><th>When</th><th>Report</th><th>Title</th><th>Transition</th><th>By</th></tr>
        </thead>
        <tbody>
          {rows.map((entry) => (
            <tr key={entry.id}>
              <td>{entry.changedAt?.slice(0, 16).replace('T', ' ')}</td>
              <td>#{entry.feedbackId}</td>
              <td>{entry.reportTitle}</td>
              <td>
                <StatusChip status={entry.oldStatus || '—'} /> →{' '}
                <StatusChip status={entry.newStatus} />
              </td>
              <td>#{entry.changedBy}</td>
            </tr>
          ))}
          {rows.length === 0 && (
            <tr><td colSpan="5" className="muted">No audit entries yet.</td></tr>
          )}
        </tbody>
      </table>
    </div>
  );
}
