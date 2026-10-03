package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.error.InternalErrorException;
import com.example.feedbackapp.common.error.ValidationFailedException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.config.MinioProperties;
import com.example.feedbackapp.feedback.entity.Feedback;
import com.example.feedbackapp.feedback.repository.FeedbackImageRepository;
import com.example.feedbackapp.feedback.repository.FeedbackRepository;
import io.minio.MinioClient;
import io.minio.StatObjectArgs;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Report photo storage on MinIO. Uploads are direct-from-client using
 * pre-signed PUT URLs (the service never handles photo bytes); downloads
 * use pre-signed GET URLs minted per detail request.
 */
@Service
public class FeedbackImageService {

    private static final Logger log = LoggerFactory.getLogger(FeedbackImageService.class);
    private static final int MAX_IMAGES_PER_REPORT = 3;
    private static final Set<String> ALLOWED_CONTENT_TYPES =
            Set.of("image/jpeg", "image/png", "image/webp");

    private final MinioClient minioClient;
    private final SigV4Presigner sigV4Presigner;
    private final MinioProperties props;
    private final FeedbackRepository feedbackRepository;
    private final FeedbackImageRepository imageRepository;

    public FeedbackImageService(@org.springframework.beans.factory.annotation.Qualifier("minioClient") MinioClient minioClient,
                                SigV4Presigner sigV4Presigner,
                                MinioProperties props,
                                FeedbackRepository feedbackRepository,
                                FeedbackImageRepository imageRepository) {
        this.minioClient = minioClient;
        this.sigV4Presigner = sigV4Presigner;
        this.props = props;
        this.feedbackRepository = feedbackRepository;
        this.imageRepository = imageRepository;
    }

    public record PresignResult(String uploadUrl, String objectKey) {
    }

    public PresignResult presignUpload(Long feedbackId, String contentType, GatewayUser user) {
        requirePhotoStorageEnabled();
        requireAccess(feedbackId, user);
        if (contentType == null || !ALLOWED_CONTENT_TYPES.contains(contentType)) {
            throw new ValidationFailedException("Only JPEG, PNG or WebP photos are allowed");
        }
        if (imageRepository.countByFeedbackId(feedbackId) >= MAX_IMAGES_PER_REPORT) {
            throw new ConflictException(
                    "A report can carry at most %d photos".formatted(MAX_IMAGES_PER_REPORT));
        }
        String ext = switch (contentType) {
            case "image/png" -> "png";
            case "image/webp" -> "webp";
            default -> "jpg";
        };
        String objectKey = "reports/%d/%s.%s".formatted(feedbackId, UUID.randomUUID(), ext);
        try {
            SigV4Presigner.PresignedUrl presigned =
                    sigV4Presigner.presignPut(props.bucket(), objectKey, 600);
            return new PresignResult(presigned.url(), objectKey);
        } catch (Exception e) {
            log.error("Presign failed for report {}", feedbackId, e);
            throw new InternalErrorException("Could not prepare the photo upload");
        }
    }

    /** Verifies the bytes actually arrived in MinIO, then records the reference. */
    public void register(Long feedbackId, String objectKey, GatewayUser user) {
        requirePhotoStorageEnabled();
        requireAccess(feedbackId, user);
        if (objectKey == null || !objectKey.startsWith("reports/" + feedbackId + "/")) {
            throw new ValidationFailedException("Invalid object key");
        }
        try {
            minioClient.statObject(StatObjectArgs.builder()
                    .bucket(props.bucket()).object(objectKey).build());
        } catch (Exception e) {
            throw new ValidationFailedException("Upload not found — retry the photo upload");
        }
        imageRepository.save(new com.example.feedbackapp.feedback.entity.FeedbackImage(feedbackId, objectKey));
        log.info("Registered image {} for report {}", objectKey, feedbackId);
    }

    /** Pre-signed read URLs (1 h) for the report's photos. */
    public List<String> viewUrls(Long feedbackId) {
        if (!props.enabled()) {
            return List.of();
        }
        return imageRepository.findByFeedbackIdOrderByIdAsc(feedbackId).stream()
                .map(image -> sigV4Presigner.presignGet(props.bucket(), image.getObjectKey(), 3600).url())
                .toList();
    }

    private void requirePhotoStorageEnabled() {
        if (!props.enabled()) {
            throw new ConflictException("Photo storage is disabled on this deployment");
        }
    }

    private void requireAccess(Long feedbackId, GatewayUser user) {
        if (user == null) {
            throw new ForbiddenException("Authentication required");
        }
        Feedback feedback = feedbackRepository.findById(feedbackId)
                .orElseThrow(() -> new com.example.feedbackapp.common.error.NotFoundException(
                        "Feedback %d not found".formatted(feedbackId)));
        boolean staff = user.isAdmin() || "MODERATOR".equals(user.role());
        if (!staff && !feedback.getUserId().equals(user.id())) {
            throw new ForbiddenException("Only the report's author or staff can manage its photos");
        }
    }
}
