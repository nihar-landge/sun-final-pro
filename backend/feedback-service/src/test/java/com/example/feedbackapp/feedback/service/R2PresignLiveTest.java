package com.example.feedbackapp.feedback.service;

import io.minio.MinioClient;
import io.minio.StatObjectArgs;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Live round-trip against Cloudflare R2 — run only when credentials are
 * provided, otherwise skipped (CI never sets them):
 *
 * <pre>
 * R2_LIVE_TEST=true \
 * R2_ENDPOINT=https://&lt;accountid&gt;.r2.cloudflarestorage.com \
 * R2_ACCESS_KEY=&lt;access key id&gt; \
 * R2_SECRET_KEY=&lt;secret access key&gt; \
 * R2_BUCKET=&lt;bucket&gt; \
 * ./mvnw -pl feedback-service -am test -Dtest=R2PresignLiveTest
 * </pre>
 *
 * Exercises the exact production path: presigned PUT carrying the signed
 * Content-Type, statObject through the MinIO client (the register step), and
 * a presigned GET (the view-URL step).
 */
@EnabledIfEnvironmentVariable(named = "R2_LIVE_TEST", matches = "true")
class R2PresignLiveTest {

    private static String endpoint;
    private static String accessKey;
    private static String secretKey;
    private static String bucket;

    @BeforeAll
    static void readConfig() {
        endpoint = System.getenv("R2_ENDPOINT");
        accessKey = System.getenv("R2_ACCESS_KEY");
        secretKey = System.getenv("R2_SECRET_KEY");
        bucket = System.getenv("R2_BUCKET");
    }

    private final SigV4Presigner presigner = new SigV4Presigner(endpoint, accessKey, secretKey, "auto");
    private final HttpClient http = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    @Test
    void presignedUploadStatAndDownloadRoundTrip() throws Exception {
        String key = "presign-live-test/" + java.util.UUID.randomUUID() + ".jpg";
        byte[] bytes = "r2-presign-live-test-bytes".getBytes(java.nio.charset.StandardCharsets.UTF_8);

        String putUrl = presigner.presignPut(bucket, key, 600, "image/jpeg").url();
        HttpResponse<String> put = http.send(
                HttpRequest.newBuilder(URI.create(putUrl))
                        .PUT(HttpRequest.BodyPublishers.ofByteArrays(java.util.List.of(bytes)))
                        .header("Content-Type", "image/jpeg")
                        .build(),
                HttpResponse.BodyHandlers.ofString());
        assertThat(put.statusCode())
                .as("presigned PUT with signed Content-Type should be accepted by R2")
                .isEqualTo(200);

        MinioClient client = MinioClient.builder()
                .endpoint(endpoint)
                .credentials(accessKey, secretKey)
                .region("auto")
                .build();
        client.statObject(StatObjectArgs.builder().bucket(bucket).object(key).build());

        String getUrl = presigner.presignGet(bucket, key, 3600).url();
        HttpResponse<byte[]> get = http.send(
                HttpRequest.newBuilder(URI.create(getUrl)).GET().build(),
                HttpResponse.BodyHandlers.ofByteArray());
        assertThat(get.statusCode()).as("presigned GET").isEqualTo(200);
        assertThat(get.body()).isEqualTo(bytes);
    }
}
