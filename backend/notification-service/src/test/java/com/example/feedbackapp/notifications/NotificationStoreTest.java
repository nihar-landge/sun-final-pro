package com.example.feedbackapp.notifications.web;

import com.example.feedbackapp.common.event.FeedbackEvent;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class NotificationStoreTest {

    private final NotificationStore store = new NotificationStore();

    private FeedbackEvent event(long id) {
        return new FeedbackEvent(FeedbackEvent.CREATED, id, 2L, "Title " + id,
                "ROADS", null, null, Instant.now());
    }

    @Test
    @DisplayName("events are returned newest-first")
    void newestFirst() {
        store.add(event(1));
        store.add(event(2));
        store.add(event(3));

        List<FeedbackEvent> recent = store.recent();
        assertThat(recent).extracting(FeedbackEvent::feedbackId)
                .containsExactly(3L, 2L, 1L);
    }

    @Test
    @DisplayName("the store is bounded and drops the oldest events")
    void boundedCapacity() {
        for (long i = 1; i <= 150; i++) {
            store.add(event(i));
        }
        List<FeedbackEvent> recent = store.recent();
        assertThat(recent).hasSize(100);
        assertThat(recent.get(0).feedbackId()).isEqualTo(150L);
        assertThat(recent.get(recent.size() - 1).feedbackId()).isEqualTo(51L);
    }
}
