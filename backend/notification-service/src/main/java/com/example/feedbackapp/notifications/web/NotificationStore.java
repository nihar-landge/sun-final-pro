package com.example.feedbackapp.notifications.web;

import com.example.feedbackapp.common.event.FeedbackEvent;
import org.springframework.stereotype.Component;

import java.util.ArrayDeque;
import java.util.List;
import java.util.Deque;

/**
 * Bounded in-memory feed of the most recent consumed events (newest first).
 * A database table replaces this when durable notification history lands.
 */
@Component
public class NotificationStore {

    private static final int CAPACITY = 100;

    private final Deque<FeedbackEvent> events = new ArrayDeque<>(CAPACITY);

    public synchronized void add(FeedbackEvent event) {
        if (events.size() >= CAPACITY) {
            events.removeLast();
        }
        events.addFirst(event);
    }

    public synchronized List<FeedbackEvent> recent() {
        return List.copyOf(events);
    }
}
