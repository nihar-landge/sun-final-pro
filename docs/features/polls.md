# Feature: Polls (one-person-one-vote)

Admins create polls (title, description, start/end window validated by a
CHECK constraint, 2+ options); citizens vote on active polls. The
one-person-one-vote guarantee is the composite primary key on
`poll_participation (poll_id, user_id)` — the database rejects a second
vote and the service surfaces 409 Already Voted. Ballots carry no user_id,
so published results cannot be traced back to voters. Vote counts are
denormalized on `poll_options.votes_count` and incremented atomically in
the same transaction as the participation insert. Results are served by
plain REST — mobile detail screens refresh every 5 seconds (WebSocket and
the Redis results cache were removed). Admins close polls early (guarded
against the time-window constraint) and duplicate existing polls.
