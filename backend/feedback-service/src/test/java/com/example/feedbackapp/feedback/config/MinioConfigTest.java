package com.example.feedbackapp.feedback.config;

import io.minio.MinioClient;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.runner.ApplicationContextRunner;

import static org.assertj.core.api.Assertions.assertThat;

class MinioConfigTest {

    private final ApplicationContextRunner runner = new ApplicationContextRunner()
            .withUserConfiguration(MinioConfig.class)
            .withBean(MinioProperties.class,
                    () -> new MinioProperties(false, "http://localhost:9000", "http://localhost:9000",
                            "key", "secret", "feedback-photos", "us-east-1"));

    @Test
    @DisplayName("minio.enabled=false: context still provides the MinioClient bean (photo service can boot)")
    void disabledStillProvidesClient() {
        runner.withPropertyValues("minio.enabled=false").run(context -> {
            assertThat(context).hasSingleBean(MinioClient.class);
            assertThat(context).doesNotHaveBean("bucketBootstrap");
        });
    }

    @Test
    @DisplayName("minio.enabled defaults to true: client + bucket bootstrap are created")
    void enabledByDefault() {
        runner.run(context -> {
            assertThat(context).hasSingleBean(MinioClient.class);
            assertThat(context).hasBean("bucketBootstrap");
        });
    }
}
