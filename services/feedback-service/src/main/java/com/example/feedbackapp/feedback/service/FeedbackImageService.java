package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ForbiddenException;
import com.example.feedbackapp.common.error.InternalErrorException;
import com.example.feedbackapp.common.error.ValidationFailedException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.entity.Feedback;
import com.example.feedbackapp.feedback.entity.FeedbackImage;
import com.example.feedbackapp.feedback.repository.FeedbackImageRepository;
import com.example.feedbackapp.feedback.repository.FeedbackRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Report photo storage on local disk. The client uploads the bytes in one
 * multipart request; the file lands under {upload.dir}/feedback/{reportId}/
 * and is served back at /uploads/**.
 */
@Service
public class FeedbackImageService {

    private static final Logger log = LoggerFactory.getLogger(FeedbackImageService.class);
    private static final int MAX_IMAGES_PER_REPORT = 3;
    private static final long MAX_FILE_BYTES = 5 * 1024 * 1024;
    private static final Set<String> ALLOWED_CONTENT_TYPES =
            Set.of("image/jpeg", "image/png", "image/webp");

    private final Path uploadDir;
    private final FeedbackRepository feedbackRepository;
    private final FeedbackImageRepository imageRepository;

    public FeedbackImageService(@Value("${app.upload-dir:./uploads}") String uploadDir,
                                FeedbackRepository feedbackRepository,
                                FeedbackImageRepository imageRepository) {
        this.uploadDir = Paths.get(uploadDir);
        this.feedbackRepository = feedbackRepository;
        this.imageRepository = imageRepository;
    }

    /** Stores the uploaded photo on disk and records its relative path. */
    public String store(Long feedbackId, MultipartFile file, GatewayUser user) {
        requireAccess(feedbackId, user);
        if (file == null || file.isEmpty()) {
            throw new ValidationFailedException("Photo file is required");
        }
        if (file.getSize() > MAX_FILE_BYTES) {
            throw new ValidationFailedException("Photo must be 5 MB or smaller");
        }
        String contentType = file.getContentType();
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
        String relativePath = "feedback/%d/%s.%s".formatted(feedbackId, UUID.randomUUID(), ext);
        Path target = uploadDir.resolve(relativePath).normalize();
        if (!target.startsWith(uploadDir.normalize())) {
            throw new ValidationFailedException("Invalid photo path");
        }
        try {
            Files.createDirectories(target.getParent());
            try (var in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
        } catch (IOException e) {
            log.error("Photo write failed for report {}", feedbackId, e);
            throw new InternalErrorException("Could not save the photo");
        }
        imageRepository.save(new FeedbackImage(feedbackId, relativePath));
        log.info("Stored photo {} for report {}", relativePath, feedbackId);
        return relativePath;
    }

    /** Public, gateway-routed URLs for the report's photos. */
    public List<String> viewUrls(Long feedbackId) {
        return imageRepository.findByFeedbackIdOrderByIdAsc(feedbackId).stream()
                .map(image -> "/uploads/" + image.getObjectKey())
                .toList();
    }

    private void requireAccess(Long feedbackId, GatewayUser user) {
        if (user == null) {
            throw new ForbiddenException("Authentication required");
        }
        Feedback feedback = feedbackRepository.findById(feedbackId)
                .orElseThrow(() -> new com.example.feedbackapp.common.error.NotFoundException(
                        "Feedback %d not found".formatted(feedbackId)));
        if (!user.isAdmin() && !feedback.getUserId().equals(user.id())) {
            throw new ForbiddenException("Only the report's author or staff can manage its photos");
        }
    }
}
