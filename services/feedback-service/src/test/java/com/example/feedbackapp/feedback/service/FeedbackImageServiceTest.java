package com.example.feedbackapp.feedback.service;

import com.example.feedbackapp.common.error.ConflictException;
import com.example.feedbackapp.common.error.ValidationFailedException;
import com.example.feedbackapp.common.web.GatewayUser;
import com.example.feedbackapp.feedback.entity.Feedback;
import com.example.feedbackapp.feedback.repository.FeedbackImageRepository;
import com.example.feedbackapp.feedback.repository.FeedbackRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.api.io.TempDir;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.mock.web.MockMultipartFile;

import java.lang.reflect.Field;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class FeedbackImageServiceTest {

    @Mock
    private FeedbackRepository feedbackRepository;
    @Mock
    private FeedbackImageRepository imageRepository;

    private static final GatewayUser CITIZEN = new GatewayUser(2L, "CITIZEN", "Nihar", "user2@test.in");
    private static final GatewayUser STRANGER = new GatewayUser(9L, "CITIZEN", "Other", "user9@test.in");

    @TempDir
    Path tempDir;

    private FeedbackImageService service() {
        return new FeedbackImageService(tempDir.toString(), feedbackRepository, imageRepository);
    }

    private void existingReportOwnedBy(Long userId) throws Exception {
        Feedback feedback = new Feedback();
        Field userIdField = Feedback.class.getDeclaredField("userId");
        userIdField.setAccessible(true);
        userIdField.set(feedback, userId);
        when(feedbackRepository.findById(7L)).thenReturn(Optional.of(feedback));
    }

    private MockMultipartFile photo(String contentType, byte[] bytes) {
        return new MockMultipartFile("file", "photo.jpg", contentType, bytes);
    }

    @Test
    @DisplayName("upload writes the file under uploads/feedback/{id}/ and records the path")
    void storeWritesFileAndRecord() throws Exception {
        existingReportOwnedBy(2L);
        when(imageRepository.countByFeedbackId(7L)).thenReturn(0L);

        String path = service().store(7L, photo("image/jpeg", new byte[]{1, 2, 3}), CITIZEN);

        assertThat(path).startsWith("feedback/7/").endsWith(".jpg");
        assertThat(Files.exists(tempDir.resolve(path))).isTrue();
        verify(imageRepository).save(any());
    }

    @Test
    @DisplayName("oversized photos are rejected before touching disk")
    void storeRejectsOversized() throws Exception {
        existingReportOwnedBy(2L);

        byte[] tooBig = new byte[5 * 1024 * 1024 + 1];
        assertThatThrownBy(() -> service().store(7L, photo("image/jpeg", tooBig), CITIZEN))
                .isInstanceOf(ValidationFailedException.class);
    }

    @Test
    @DisplayName("non-image content types are rejected")
    void storeRejectsNonImages() throws Exception {
        existingReportOwnedBy(2L);

        assertThatThrownBy(() -> service().store(7L, photo("application/pdf", new byte[]{1}), CITIZEN))
                .isInstanceOf(ValidationFailedException.class);
    }

    @Test
    @DisplayName("a fourth photo on one report is a conflict")
    void storeEnforcesPhotoLimit() throws Exception {
        existingReportOwnedBy(2L);
        when(imageRepository.countByFeedbackId(7L)).thenReturn(3L);

        assertThatThrownBy(() -> service().store(7L, photo("image/png", new byte[]{1}), CITIZEN))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    @DisplayName("non-admin strangers cannot attach photos to someone else's report")
    void storeRejectsStrangers() {
        when(feedbackRepository.findById(7L)).thenReturn(Optional.of(new Feedback() {{
            try {
                Field f = Feedback.class.getDeclaredField("userId");
                f.setAccessible(true);
                f.set(this, 2L);
            } catch (Exception ignored) {
            }
        }}));

        assertThatThrownBy(() -> service().store(7L, photo("image/png", new byte[]{1}), STRANGER))
                .isInstanceOf(com.example.feedbackapp.common.error.ForbiddenException.class);
    }
}
