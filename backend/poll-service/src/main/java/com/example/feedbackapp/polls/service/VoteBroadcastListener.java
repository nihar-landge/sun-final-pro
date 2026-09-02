package com.example.feedbackapp.polls.service;

import com.example.feedbackapp.polls.dto.PollResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;

/**
 * Pushes live poll results to STOMP subscribers on /topic/polls/{id}.
 * Listens AFTER_COMMIT so subscribers never see uncommitted counts.
 */
@Component
public class VoteBroadcastListener {

    private static final Logger log = LoggerFactory.getLogger(VoteBroadcastListener.class);
    private static final String TOPIC = "/topic/polls/%d";

    private final SimpMessagingTemplate messagingTemplate;
    private final PollService pollService;

    public VoteBroadcastListener(SimpMessagingTemplate messagingTemplate, PollService pollService) {
        this.messagingTemplate = messagingTemplate;
        this.pollService = pollService;
    }

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)
    public void onVoteCommitted(VoteCommittedEvent event) {
        try {
            PollResponse results = pollService.getResults(event.pollId());
            messagingTemplate.convertAndSend(TOPIC.formatted(event.pollId()), results);
            log.info("Broadcast results for poll {} ({} votes)", event.pollId(), results.totalVotes());
        } catch (Exception e) {
            // A broker hiccup must never break the voting path.
            log.warn("Failed to broadcast results for poll {}", event.pollId(), e);
        }
    }

    /** Internal marker event published when a vote transaction commits. */
    public record VoteCommittedEvent(Long pollId) {
    }
}
