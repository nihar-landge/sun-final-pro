package com.example.feedbackapp.feedback.config;

import org.springframework.boot.context.properties.ConfigurationProperties;

/** MinIO object-storage settings (see application.yml under `minio:`). */
@ConfigurationProperties(prefix = "minio")
public record MinioProperties(String url, String publicUrl, String accessKey, String secretKey, String bucket) {
}
