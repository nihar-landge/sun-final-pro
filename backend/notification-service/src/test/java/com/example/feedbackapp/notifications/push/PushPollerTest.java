package com.example.feedbackapp.notifications.push;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class PushPollerTest {

    @Mock
    private JdbcTemplate jdbc;
    @Mock
    private FcmSender fcmSender;

    private PushPoller poller;

    @BeforeEach
    void setUp() {
        poller = new PushPoller(jdbc, fcmSender);
    }

    @Test
    @DisplayName("unpushed rows are marked pushed after delivery")
    void marksRowsPushed() {
        when(jdbc.queryForList(anyString(), eq(20))).thenReturn(List.of(
                Map.of("id", 1L, "user_id", 2L, "title", "T", "body", "B", "ref_id", 7L)));
        when(jdbc.query(anyString(), org.mockito.ArgumentMatchers.any(
                org.springframework.jdbc.core.RowMapper.class), eq(2L)))
                .thenReturn(List.of("device-token-xyz"));

        poller.pollAndPush();

        verify(fcmSender).pushToToken(eq("device-token-xyz"), eq("T"), eq("B"),
                eq(Map.of("reportId", "7", "type", "REPORT_STATUS")));
        verify(jdbc).update("UPDATE notification SET pushed_at = NOW() WHERE id = ?", 1L);
    }

    @Test
    @DisplayName("no unpushed rows — no FCM calls, no errors")
    void noRowsNoCalls() {
        when(jdbc.queryForList(anyString(), eq(20))).thenReturn(List.of());
        poller.pollAndPush();
        verify(fcmSender, org.mockito.Mockito.never())
                .pushToToken(anyString(), anyString(), anyString(), any());
        verify(jdbc, org.mockito.Mockito.never())
                .update(anyString(), org.mockito.ArgumentMatchers.anyLong());
    }

    @Test
    @DisplayName("rows without a device token are marked pushed (skipped)")
    void skipsRowsWithoutToken() {
        when(jdbc.queryForList(anyString(), eq(20))).thenReturn(List.of(
                Map.of("id", 3L, "user_id", 9L, "title", "T", "body", "B", "ref_id", 1L)));
        when(jdbc.query(anyString(), org.mockito.ArgumentMatchers.any(
                org.springframework.jdbc.core.RowMapper.class), eq(9L)))
                .thenReturn(List.of());

        poller.pollAndPush();

        verify(fcmSender, org.mockito.Mockito.never())
                .pushToToken(anyString(), anyString(), anyString(), any());
        verify(jdbc).update("UPDATE notification SET pushed_at = NOW() WHERE id = ?", 3L);
    }
}
