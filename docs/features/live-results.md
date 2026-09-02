# Feature: Live Poll Results (WebSocket / STOMP)

Vote counts update on every open screen **without polling**. The phone shows
animated result bars the instant anyone votes anywhere.

## How a vote reaches every screen

```
citizen B votes (REST)
        │
        ▼
PollService.castVote (transaction commits)
        │  publish VoteCommittedEvent(pollId)
        ▼
VoteBroadcastListener  @TransactionalEventListener(AFTER_COMMIT)
        │  re-reads fresh results (getResults)
        │  SimpMessagingTemplate.convertAndSend
        ▼
STOMP broker  /topic/polls/{pollId}
        │
        ├─► citizen A's phone  (subscribed on the poll detail page)
        ├─► citizen C's Chrome tab (subscribed)
        └─► any other subscriber
```

Two design decisions worth knowing:

1. **AFTER_COMMIT** — the broadcast listener runs only after the database
   transaction commits, so no subscriber ever sees uncommitted counts.
2. **Broadcast failures never break voting** — the listener catches broker
   exceptions and logs; the vote is already safely stored.

## Transport path

```
Flutter app (stomp_dart_client)
   ws://<gateway>/ws            ← same host/port as REST; on phones this rides
        │                          the adb reverse / LAN tunnel like HTTP does
        ▼
api-gateway :8080               route `poll-service-ws`: Path=/ws/** → ws://localhost:8082
        │                       /ws/** is PUBLIC at the JWT filter (handshake has
        ▼                       no headers; votes still require JWT via REST)
poll-service :8082              STOMP endpoint /ws (allowed origins: *)
        │                       simple broker: /topic
        ▼
subscribers of /topic/polls/{id}
```

The handshake is public because results are public data; **casting** a vote
still requires a valid JWT through the normal REST path.

## Message payload

The broadcast body is the same JSON as the REST results response
(`PollResponse`): id, title, status, totalVotes, results[] with
votes + percentage. The Flutter client decodes it straight into the
existing `PollModel` — no separate message class.

## Client lifecycle (mobile)

`poll_detail_page.dart`:

- `initState` → `StompClient.activate()` → on connect, `subscribe` to
  `/topic/polls/{id}`; every frame is decoded and pushed into `PollsBloc` as
  a `PollLiveUpdate` event.
- `dispose` → unsubscribe + deactivate.
- `reconnectDelay: 5s` — backgrounding the app or a network blip recovers
  automatically.
- Live frames are user-neutral (`hasVoted: false`), so the page keeps a local
  `_votedLocally` guard and the server-computed flag to decide whether the
  vote form is shown.

## Where the code lives

| Concern | File |
|---|---|
| STOMP endpoint + broker config | `backend/poll-service/.../config/WebSocketConfig.java` |
| AFTER_COMMIT broadcast | `backend/poll-service/.../service/VoteBroadcastListener.java` |
| Gateway ws:// route + public path | `backend/api-gateway/src/main/resources/application.yml` + `JwtAuthGlobalFilter.java` |
| Flutter subscription | `mobile/lib/features/polls/presentation/pages/poll_detail_page.dart` (`_connectLive`) |
| Live update → state | `mobile/lib/features/polls/presentation/bloc/polls_bloc.dart` (`PollLiveUpdate`) |

## Try it

1. Open the same poll on two devices (or phone + Chrome).
2. Vote on one of them.
3. The other screen's bars move within a second — no refresh.

Server-side proof points:
- `GET /ws` with upgrade headers returns **HTTP 101** (handshake completes).
- After a vote, `poll-service` logs:
  `Broadcast results for poll {id} (N votes)`.
