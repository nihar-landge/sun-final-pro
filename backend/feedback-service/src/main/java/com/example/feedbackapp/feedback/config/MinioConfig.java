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

    @Bean
    public MinioClient minioClient(MinioProperties props) {
        return MinioClient.builder()
                .endpoint(props.url())
                .credentials(props.accessKey(), props.secretKey())
                .build();
    }

    @Bean
    public ApplicationRunner bucketBootstrap(MinioClient client, MinioProperties props) {
        return args -> {
            boolean exists = client.bucketExists(
                    BucketExistsArgs.builder().bucket(props.bucket()).build());
            if (!exists) {
                client.makeBucket(MakeBucketArgs.builder().bucket(props.bucket()).build());
                log.info("Created MinIO bucket '{}'", props.bucket());
            }
        };
    }
}
