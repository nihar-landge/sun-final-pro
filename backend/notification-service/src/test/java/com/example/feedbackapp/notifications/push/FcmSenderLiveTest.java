package com.example.feedbackapp.notifications.push;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.junit.jupiter.api.Assumptions;

import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Live credential check against Google's OAuth2 token endpoint — run only when
 * the Firebase service-account JSON is available, otherwise skipped (CI never
 * has it):
 *
 * <pre>
 * FCM_LIVE_TEST=true \
 * FCM_SERVICE_ACCOUNT=/path/to/service-account.json \
 * ./mvnw -pl notification-service -am test -Dtest=FcmSenderLiveTest
 * </pre>
 *
 * Exercises the exact production credential path: isConfigured() (path exists),
 * then the jjwt JWT-assertion → OAuth2 exchange that pushToToken() performs
 * before every send. Set FCM_TEST_DEVICE_TOKEN (from the app's logs) to also
 * exercise one real send end-to-end; without it that test is skipped.
 */
@EnabledIfEnvironmentVariable(named = "FCM_LIVE_TEST", matches = "true")
class FcmSenderLiveTest {

    private static FcmSender sender() {
        return new FcmSender(System.getenv("FCM_SERVICE_ACCOUNT"),
                System.getenv().getOrDefault("FCM_PROJECT_ID", "feedback-5c79b"));
    }

    @Test
    void serviceAccountFileIsPresentAndDetected() {
        assertThat(sender().isConfigured())
                .as("FCM_SERVICE_ACCOUNT must point at an existing service-account JSON")
                .isTrue();
    }

    @Test
    void mintsAFirebaseMessagingAccessToken() throws Exception {
        String token = sender().accessToken();
        assertThat(token)
                .as("OAuth2 access token from the service-account JWT assertion")
                .isNotBlank()
                .doesNotContain("-----BEGIN");
    }

    @Test
    void acceptsARealDeviceTokenWhenProvided() {
        String deviceToken = System.getenv("FCM_TEST_DEVICE_TOKEN");
        Assumptions.assumeTrue(deviceToken != null && !deviceToken.isBlank(),
                "FCM_TEST_DEVICE_TOKEN not set — send check skipped");
        boolean accepted = sender().pushToToken(deviceToken, "CivicPulse smoke test",
                "Push pipeline verified", Map.of("kind", "smoke-test"));
        assertThat(accepted)
                .as("FCM should accept the message for a live device token")
                .isTrue();
    }
}
