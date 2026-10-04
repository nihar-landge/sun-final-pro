package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.dto.NearbyFeedbackResponse;
import com.example.feedbackapp.feedback.dto.SubmitFeedbackRequest;
import com.example.feedbackapp.feedback.entity.FeedbackCategory;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.testcontainers.service.connection.ServiceConnection;
import org.testcontainers.containers.MySQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

/**
 * Exercises the real MySQL spatial column (POINT SRID 4326): submit two
 * geo-tagged items and verify the near-me query orders them by distance,
 * plus the upvote uniqueness constraint. Runs in CI (TEST_DOCKER=true);
 * locally the same guarantees are covered by the live E2E checks against
 * the compose MySQL.
 */
@SpringBootTest
@Testcontainers
@EnabledIfEnvironmentVariable(named = "TEST_DOCKER", matches = "true")
class FeedbackNearbyIntegrationTest {

    @Container
    @ServiceConnection
    static final MySQLContainer<?> MYSQL = new MySQLContainer<>(DockerImageName.parse("mysql:8.4"));

    @Autowired
    private FeedbackService feedbackService;

    private static final GatewayUser CITIZEN = new GatewayUser(2L, "CITIZEN", "Nihar", "user2@test.in");

    @Test
    void nearMeOrdersByRealDistanceAndUpvotesAreUnique() {
        // Pune city centre: submit one ~1.1 km NE and one ~4.6 km NW of the query point.
        submit("Pothole on MG Road", 18.5290, 73.8620);     // nearer
        submit("Water logging in Aundh", 18.5630, 73.8070); // farther

        List<NearbyFeedbackResponse> nearby = feedbackService.nearMe(18.5204, 73.8567, 10.0, null);

        assertThat(nearby).hasSizeGreaterThanOrEqualTo(2);
        assertThat(nearby.get(0).title()).isEqualTo("Pothole on MG Road");
        assertThat(nearby.get(0).distanceMeters())
                .isLessThan(nearby.get(1).distanceMeters());

        Long id = nearby.get(0).id();
        feedbackService.upvote(id, CITIZEN);
        assertThatThrownBy(() -> feedbackService.upvote(id, CITIZEN))
                .isInstanceOf(ConflictException.class);

        var detail = feedbackService.getDetail(id, CITIZEN);
        assertThat(detail.upvotes()).isEqualTo(1);
    }

    private void submit(String title, double lat, double lng) {
        feedbackService.submit(new SubmitFeedbackRequest(
                title, "description for " + title, FeedbackCategory.ROADS, lat, lng), CITIZEN);
    }
}
