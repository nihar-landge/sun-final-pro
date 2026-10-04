package com.example.feedbackapp.polls.service;

import com.example.feedbackapp.common.error.AlreadyVotedException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.polls.dto.CreatePollRequest;
import com.example.feedbackapp.polls.dto.PollResponse;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import java.time.LocalDateTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Proves the one-person-one-vote guarantee against a real MySQL
 * (composite PK on poll_participation), not just mocks.
 *
 * Gated behind TEST_DOCKER=true because recent Docker Desktop releases
 * reject the docker-java client version Testcontainers pulls with.
 * CI sets TEST_DOCKER=true (standard Docker Engine works fine).
 */
@SpringBootTest
@Testcontainers
@EnabledIfEnvironmentVariable(named = "TEST_DOCKER", matches = "true")
class PollVoteIntegrationTest {

    @Container
    @ServiceConnection
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>("mysql:8.4");

    @Container
    @ServiceConnection
    static final GenericContainer<?> REDIS = new GenericContainer<>("redis:7-alpine")
            .withExposedPorts(6379);

    @Autowired
    private PollService pollService;

    private static final GatewayUser ADMIN = new GatewayUser(1L, "ADMIN", "Admin", "user1@test.in");

    @Test
    void secondVoteBySameUserIsRejectedByTheDatabase() {
        CreatePollRequest request = new CreatePollRequest(
                "Flyover now?", "Traffic is unbearable", LocalDateTime.now(),
                LocalDateTime.now().plusDays(2), true, List.of("Yes, build it", "No, wait"));

        PollResponse created = pollService.createPoll(request, ADMIN);
        Long optionId = created.results().get(0).optionId();

        GatewayUser voter1 = new GatewayUser(50L, "CITIZEN", "A", "user50@test.in");
        GatewayUser voter2 = new GatewayUser(51L, "CITIZEN", "B", "user51@test.in");

        PollResponse afterFirst = pollService.castVote(created.id(), voter1, optionId);
        assertThat(afterFirst.totalVotes()).isEqualTo(1);

        PollResponse afterSecondVoter = pollService.castVote(created.id(), voter2, optionId);
        assertThat(afterSecondVoter.totalVotes()).isEqualTo(2);

        assertThatThrownBy(() -> pollService.castVote(created.id(), voter1, optionId))
                .isInstanceOf(AlreadyVotedException.class);

        PollResponse results = pollService.getResults(created.id());
        assertThat(results.totalVotes()).isEqualTo(2);
        assertThat(results.results().get(0).votes()).isEqualTo(2);
        assertThat(results.results().get(0).percentage()).isEqualTo(100.0);
    }
}
