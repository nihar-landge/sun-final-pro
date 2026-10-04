package com.example.feedbackapp.notifications.service;

import com.example.feedbackapp.notifications.client.EmailClient;
import com.example.feedbackapp.notifications.repository.NotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import static org.assertj.core.api.Assertions.assertThatCode;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;

class NotificationServiceTest {

    private NotificationRepository repository;
    private EmailClient emailClient;
    private NotificationService service;

    @BeforeEach
    void setUp() {
        repository = Mockito.mock(NotificationRepository.class);
        emailClient = Mockito.mock(EmailClient.class);
        service = new NotificationService(repository, emailClient);
    }

    private NotificationService.ReportStatusEvent event(String email) {
        return new NotificationService.ReportStatusEvent(
                5L, email, "Nihar", 42L, "Pothole on MG Road", "OPEN", "IN_PROGRESS");
    }

    @Test
    @DisplayName("status change saves an inbox row and dispatches the email")
    void createSavesRowAndSendsEmail() {
        service.createReportStatusNotification(event("nihar@example.com"));

        verify(repository).save(any(com.example.feedbackapp.notifications.entity.Notification.class));
        verify(emailClient).sendReportStatusEmail(any(EmailClient.ReportStatusEmail.class));
    }

    @Test
    @DisplayName("email failure never fails the notification")
    void emailFailureIsSwallowed() {
        doThrow(new RuntimeException("SMTP down")).when(emailClient)
                .sendReportStatusEmail(any(EmailClient.ReportStatusEmail.class));

        assertThatCode(() -> service.createReportStatusNotification(event("nihar@example.com")))
                .doesNotThrowAnyException();
    }

    @Test
    @DisplayName("no reporter email means no email attempt but the row is saved")
    void missingEmailSkipsEmail() {
        service.createReportStatusNotification(event(null));

        verify(repository).save(any(com.example.feedbackapp.notifications.entity.Notification.class));
        Mockito.verifyNoInteractions(emailClient);
    }
}
