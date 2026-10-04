import { useCallback, useEffect, useState } from 'react';
import api, { unwrap } from '../api/client';

const now = () => new Date().toISOString().slice(0, 16);
const inDays = (days) => new Date(Date.now() + days * 86400000).toISOString().slice(0, 16);

/** Poll management: list, create, close, duplicate, results bars. */
export default function Polls() {
  const [polls, setPolls] = useState([]);
  const [filter, setFilter] = useState('all');
  const [showCreate, setShowCreate] = useState(false);
  const [error, setError] = useState('');

  const load = useCallback(async () => {
    try {
      setPolls(await unwrap(api.get('/polls', { params: { status: filter } })));
    } catch (e) {
      setError(e.response?.data?.message || e.message);
    }
  }, [filter]);

  useEffect(() => {
    load();
  }, [load]);

  async function closePoll(id) {
    try {
      await unwrap(api.post(`/polls/${id}/close`));
      await load();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    }
  }

  async function duplicate(poll) {
    const title = window.prompt('New poll title', `${poll.title} (copy)`);
    if (!title) return;
    try {
      await unwrap(api.post('/polls', {
        title,
        description: poll.description || '',
        startTime: now(),
        endTime: inDays(7),
        isAnonymous: true,
        options: poll.results.map((r) => r.text),
      }));
      await load();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    }
  }

  return (
    <div>
      <h1>Polls</h1>
      <div className="filters">
        <select value={filter} onChange={(e) => setFilter(e.target.value)}>
          {['all', 'active', 'scheduled', 'closed'].map((f) => (
            <option key={f} value={f}>{f}</option>
          ))}
        </select>
        <button onClick={() => setShowCreate(!showCreate)}>
          {showCreate ? 'Cancel' : '+ Create poll'}
        </button>
      </div>

      {error && <p className="error">{error}</p>}
      {showCreate && <CreatePoll onDone={() => { setShowCreate(false); load(); }} />}

      {polls.map((poll) => (
        <div className="card wide" key={poll.id}>
          <header className="poll-head">
            <strong>#{poll.id} — {poll.title}</strong>
            <span className="muted">{poll.status} · {poll.totalVotes} votes</span>
            <span className="btn-row">
              {poll.status === 'ACTIVE' && (
                <button onClick={() => closePoll(poll.id)}>Close</button>
              )}
              <button onClick={() => duplicate(poll)}>Duplicate</button>
            </span>
          </header>
          {poll.results.map((option) => {
            const pct = poll.totalVotes === 0 ? 0 : (option.votes * 100) / poll.totalVotes;
            return (
              <div className="bar-row" key={option.optionId}>
                <span className="bar-label">{option.text}</span>
                <div className="bar-track">
                  <div className="bar-fill" style={{ width: `${pct}%` }} />
                </div>
                <span className="bar-count">{option.votes} ({pct.toFixed(0)}%)</span>
              </div>
            );
          })}
        </div>
      ))}
    </div>
  );
}

function CreatePoll({ onDone }) {
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [startTime, setStartTime] = useState(now());
  const [endTime, setEndTime] = useState(inDays(7));
  const [options, setOptions] = useState(['', '']);
  const [busy, setBusy] = useState(false);

  function setOption(index, value) {
    setOptions(options.map((o, i) => (i === index ? value : o)));
  }

  async function submit(event) {
    event.preventDefault();
    setBusy(true);
    try {
      await unwrap(api.post('/polls', {
        title,
        description,
        startTime,
        endTime,
        isAnonymous: true,
        options: options.filter((o) => o.trim()),
      }));
      onDone();
    } catch (e) {
      alert(e.response?.data?.message || e.message);
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="card wide create-poll" onSubmit={submit}>
      <label>
        Title
        <input value={title} onChange={(e) => setTitle(e.target.value)} required maxLength={200} />
      </label>
      <label>
        Description
        <textarea rows={2} value={description} onChange={(e) => setDescription(e.target.value)} />
      </label>
      <div className="btn-row">
        <label>
          Starts
          <input type="datetime-local" value={startTime} onChange={(e) => setStartTime(e.target.value)} required />
        </label>
        <label>
          Ends
          <input type="datetime-local" value={endTime} onChange={(e) => setEndTime(e.target.value)} required />
        </label>
      </div>
      {options.map((option, index) => (
        <input
          key={index}
          placeholder={`Option ${index + 1}`}
          value={option}
          onChange={(e) => setOption(index, e.target.value)}
          required={index < 2}
          maxLength={200}
        />
      ))}
      <div className="btn-row">
        <button type="button" onClick={() => setOptions([...options, ''])}>+ Option</button>
        <button type="submit" disabled={busy}>{busy ? 'Creating…' : 'Create poll'}</button>
      </div>
    </form>
  );
}
