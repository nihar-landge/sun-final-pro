package com.example.feedbackapp.feedback.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.boot.context.properties.bind.DefaultValue;

/** MinIO object-storage settings (see application.yml under `minio:`). */
@ConfigurationProperties(prefix = "minio")
public record MinioProperties(
        String url,
        String publicUrl,
        String accessKey,
        String secretKey,
        String bucket,
        @DefaultValue("us-east-1") String region) {
}
