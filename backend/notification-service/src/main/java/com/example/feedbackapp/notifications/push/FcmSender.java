package com.example.feedbackapp.notifications.push;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import io.jsonwebtoken.Jwts;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.spec.PKCS8EncodedKeySpec;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.Map;
import java.util.Optional;

/**
 * FCM HTTP v1 sender. Authenticates with the Firebase service-account JSON
 * (JWT → OAuth2 exchange, cached for its lifetime) using the jjwt dependency
 * already in the platform — no heavyweight Admin SDK.
 *
 * Disabled gracefully when fcm.service-account is not configured.
 */
@Service
public class FcmSender {

    private static final Logger log = LoggerFactory.getLogger(FcmSender.class);
    private static final String SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
    private static final String TOKEN_URL = "https://oauth2.googleapis.com/token";

    private final ObjectMapper mapper = new ObjectMapper();
    private final RestTemplate http = new RestTemplate();
    private final String serviceAccountPath;
    private final String projectId;

    private PrivateKey privateKey;
    private String clientEmail;
    private String cachedAccessToken;
    private Instant tokenExpiry = Instant.EPOCH;

    public FcmSender(@Value("${fcm.service-account:}") String serviceAccountPath,
                     @Value("${fcm.project-id:}") String projectId) {
        this.serviceAccountPath = serviceAccountPath;
        this.projectId = projectId;
    }

    public boolean isConfigured() {
        return serviceAccountPath != null && !serviceAccountPath.isBlank()
                && java.nio.file.Files.exists(java.nio.file.Path.of(serviceAccountPath));
    }

    /** Returns true when FCM accepted the message; false when skipped/failed (never throws into the event flow). */
    public boolean pushToToken(String deviceToken, String title, String body, Map<String, String> data) {
        if (!isConfigured()) {
            log.debug("FCM not configured — push skipped ({})", title);
            return false;
        }
        try {
            String accessToken = accessToken();
            String url = "https://fcm.googleapis.com/v1/projects/%s/messages:send".formatted(projectId);
            HttpHeaders headers = new HttpHeaders();
            headers.setBearerAuth(accessToken);
            headers.setContentType(MediaType.APPLICATION_JSON);
            Map<String, Object> payload = Map.of("message", Map.of(
                    "token", deviceToken,
                    "notification", Map.of("title", title, "body", body),
                    "data", data));
            ResponseEntity<String> response = http.postForEntity(url,
                    new HttpEntity<>(mapper.writeValueAsString(payload), headers), String.class);
            log.info("FCM push sent: {} ({})", title, response.getStatusCode());
            return response.getStatusCode().is2xxSuccessful();
        } catch (Exception e) {
            log.warn("FCM push failed for '{}': {}", title, e.getMessage());
            return false;
        }
    }

    /** JWT assertion → OAuth2 access token, cached until near expiry (package-private: asserted by FcmSenderLiveTest). */
    synchronized String accessToken() throws Exception {
        loadAccountIfNeeded();
        if (Instant.now().isBefore(tokenExpiry.minusSeconds(60))) {
            return cachedAccessToken;
        }
        Instant now = Instant.now();
        String jwt = Jwts.builder()
                .issuer(clientEmail)
                // Google rejects an array-valued aud ("Failed audience check") — single() emits a JSON string.
                .audience().single(TOKEN_URL)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plusSeconds(3600)))
                .claim("scope", SCOPE)
                .signWith(privateKey)
                .compact();

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
        String form = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=" + jwt;
        ResponseEntity<String> response = http.postForEntity(TOKEN_URL,
                new HttpEntity<>(form, headers), String.class);
        JsonNode json = mapper.readTree(response.getBody());
        cachedAccessToken = json.get("access_token").asText();
        tokenExpiry = Instant.now().plusSeconds(json.get("expires_in").asLong());
        return cachedAccessToken;
    }

    private synchronized void loadAccountIfNeeded() throws Exception {
        if (privateKey != null) {
            return;
        }
        JsonNode account = mapper.readTree(java.nio.file.Path.of(serviceAccountPath).toFile());
        clientEmail = account.get("client_email").asText();
        String pk = account.get("private_key").asText()
                .replace("-----BEGIN PRIVATE KEY-----", "")
                .replace("-----END PRIVATE KEY-----", "")
                .replaceAll("\\s", "");
        byte[] decoded = Base64.getDecoder().decode(pk);
        privateKey = KeyFactory.getInstance("RSA")
                .generatePrivate(new PKCS8EncodedKeySpec(decoded));
        log.info("FCM service account loaded for {}", clientEmail);
    }
}
