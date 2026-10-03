package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.config.MinioProperties;
import com.example.feedbackapp.feedback.entity.Feedback;
import com.example.feedbackapp.feedback.repository.FeedbackImageRepository;
import com.example.feedbackapp.feedback.repository.FeedbackRepository;
import io.minio.MinioClient;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FeedbackImageServiceTest {

    @Mock
    private MinioClient minioClient;
    @Mock
    private SigV4Presigner presigner;
    @Mock
    private FeedbackRepository feedbackRepository;
    @Mock
    private FeedbackImageRepository imageRepository;

    private static final GatewayUser ADMIN = new GatewayUser(1L, "ADMIN", "Admin");

    private FeedbackImageService service(boolean enabled) {
        return new FeedbackImageService(minioClient, presigner,
                new MinioProperties(enabled, "http://localhost:9000", "http://localhost:9000",
                        "key", "secret", "feedback-photos", "us-east-1"),
                feedbackRepository, imageRepository);
    }

    private Feedback feedbackOwnedBy(Long userId) {
        Feedback feedback = new Feedback();
        feedback.setUserId(userId);
        return feedback;
    }

    @Test
    @DisplayName("minio.enabled=false: writes conflict and reads stay empty instead of crashing")
    void disabledStorage() {
        FeedbackImageService service = service(false);

        assertThatThrownBy(() -> service.presignUpload(7L, "image/jpeg", ADMIN))
                .isInstanceOf(ConflictException.class);
        assertThatThrownBy(() -> service.register(7L, "reports/7/a.jpg", ADMIN))
                .isInstanceOf(ConflictException.class);
        assertThat(service.viewUrls(7L)).isEmpty();
        verifyNoInteractions(presigner, imageRepository, feedbackRepository);
    }

    @Test
    @DisplayName("minio.enabled=true: presign uploads return a URL and a reports/ object key")
    void presignEnabled() {
        FeedbackImageService service = service(true);
        when(feedbackRepository.findById(7L)).thenReturn(Optional.of(feedbackOwnedBy(1L)));
        when(imageRepository.countByFeedbackId(7L)).thenReturn(0L);
        when(presigner.presignPut(eq("feedback-photos"), anyString(), eq(600)))
                .thenReturn(new SigV4Presigner.PresignedUrl("https://storage.example/put?sig=x", "host"));

        FeedbackImageService.PresignResult result = service.presignUpload(7L, "image/jpeg", ADMIN);

        assertThat(result.uploadUrl()).isEqualTo("https://storage.example/put?sig=x");
        assertThat(result.objectKey()).startsWith("reports/7/").endsWith(".jpg");
    }

    @Test
    @DisplayName("minio.enabled=true: viewUrls mints read URLs for stored photos")
    void viewUrlsEnabled() {
        FeedbackImageService service = service(true);
        when(imageRepository.findByFeedbackIdOrderByIdAsc(7L)).thenReturn(java.util.List.of(
                new com.example.feedbackapp.feedback.entity.FeedbackImage(7L, "reports/7/a.jpg")));
        when(presigner.presignGet(eq("feedback-photos"), eq("reports/7/a.jpg"), eq(3600)))
                .thenReturn(new SigV4Presigner.PresignedUrl("https://storage.example/get?sig=y", "host"));

        assertThat(service.viewUrls(7L)).containsExactly("https://storage.example/get?sig=y");
    }
}
