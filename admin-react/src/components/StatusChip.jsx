const STATUS_COLORS = {
  OPEN: '#f59e0b',
  IN_PROGRESS: '#3b82f6',
  RESOLVED: '#10b981',
};

export function StatusChip({ status }) {
  return (
    <span
      className="chip"
      style={{ backgroundColor: STATUS_COLORS[status] || '#9ca3af' }}
    >
      {status || '—'}
    </span>
  );
}

export function Upvotes({ count }) {
  return <span title="Upvotes">▲ {count}</span>;
}
