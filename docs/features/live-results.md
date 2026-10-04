# Poll results (REST polling)

Live poll results are delivered by plain REST: clients refresh
`GET /api/v1/polls/{id}/results` every 5 seconds while the detail screen is
open. The earlier WebSocket/STOMP broadcast and the Redis results cache were
removed in the final architecture — at this scale a 5-second poll is simpler
to explain and just as fresh. (The WebSocket variant is preserved on the
`advanced` branch.)
