package com.example.feedbackapp.feedback.config;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationRunner;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * MinIO (S3-compatible) client for report photo storage. The bucket is
 * created on first boot so the environment is self-healing. Disable the
 * whole image feature with minio.enabled=false (e.g. CI without storage).
 */
@Configuration
@ConditionalOnProperty(prefix = "minio", name = "enabled", havingValue = "true", matchIfMissing = true)
public class MinioConfig {

    private static final Logger log = LoggerFactory.getLogger(MinioConfig.class);

    /** Internal client: bucket bootstrap and object existence checks. */
    @Bean
    @org.springframework.context.annotation.Primary
    public MinioClient minioClient(MinioProperties props) {
        return MinioClient.builder()
                .endpoint(props.url())
                .credentials(props.accessKey(), props.secretKey())
                .build();
    }

    @Bean
    public ApplicationRunner bucketBootstrap(
            @org.springframework.beans.factory.annotation.Qualifier("minioClient") MinioClient client,
            MinioProperties props) {
        // Non-fatal: a storage outage or missing credentials must not take the
        // whole service down — only photo uploads fail until storage is ready.
        return args -> {
            try {
                boolean exists = client.bucketExists(
                        BucketExistsArgs.builder().bucket(props.bucket()).build());
                if (!exists) {
                    client.makeBucket(MakeBucketArgs.builder().bucket(props.bucket()).build());
                    log.info("Created storage bucket '{}'", props.bucket());
                }
            } catch (Exception e) {
                log.warn("Storage bucket bootstrap skipped ({}): {}",
                        props.bucket(), e.getMessage());
            }
        };
    }
}
