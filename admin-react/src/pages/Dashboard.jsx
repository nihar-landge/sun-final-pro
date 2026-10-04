import { useEffect, useState } from 'react';
import api, { unwrap } from '../api/client';

/** KPI cards + category bars — straight from the analytics endpoints. */
export default function Dashboard() {
  const [summary, setSummary] = useState(null);
  const [pollStats, setPollStats] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    Promise.all([
      unwrap(api.get('/feedback/analytics/summary')),
      unwrap(api.get('/polls/analytics/summary')),
    ])
      .then(([feedback, polls]) => {
        setSummary(feedback);
        setPollStats(polls);
      })
      .catch((e) => setError(e.response?.data?.message || e.message));
  }, []);

  if (error) return <p className="error">Could not load the dashboard: {error}</p>;
  if (!summary) return <p className="muted">Loading…</p>;

  const byStatus = summary.byStatus || {};
  const cards = [
    { label: 'Total reports', value: summary.totalFeedback },
    { label: 'Open', value: byStatus.OPEN || 0 },
    { label: 'In progress', value: byStatus.IN_PROGRESS || 0 },
    { label: 'Resolved', value: byStatus.RESOLVED || 0 },
    { label: 'New this week', value: summary.submittedLast7Days },
    { label: 'Poll votes', value: pollStats?.totalVotes ?? '—' },
  ];

  const categories = Object.entries(summary.byCategory || {});

  return (
    <div>
      <h1>Dashboard</h1>
      <div className="cards">
        {cards.map((card) => (
          <div className="card" key={card.label}>
            <div className="card-value">{card.value}</div>
            <div className="card-label">{card.label}</div>
          </div>
        ))}
      </div>
      <div className="card wide">
        <div className="card-label">Avg resolution time</div>
        <div className="card-value">
          {summary.avgResolutionHours != null ? `${summary.avgResolutionHours} h` : '—'}
        </div>
      </div>
      <h2>Reports by category</h2>
      <div className="bars">
        {categories.map(([category, count]) => {
          const max = Math.max(...categories.map(([, c]) => c), 1);
          return (
            <div className="bar-row" key={category}>
              <span className="bar-label">{category}</span>
              <div className="bar-track">
                <div className="bar-fill" style={{ width: `${(count * 100) / max}%` }} />
              </div>
              <span className="bar-count">{count}</span>
            </div>
          );
        })}
      </div>
    </div>
  );
}
