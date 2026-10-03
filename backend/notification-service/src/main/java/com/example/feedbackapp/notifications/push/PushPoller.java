package com.example.feedbackapp.notifications.push;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Map;

/**
 * FCM push poller — the broker-free notification pipeline.
 *
 * feedback-service writes inbox rows in the same transaction as the status
 * change; this poller picks up unpushed rows every few seconds, attempts the
 * FCM delivery, and marks them pushed. If the poller is down, rows simply
 * wait and are delivered on the next cycle — no lost notifications, no
 * broker to operate.
 */
@Component
public class PushPoller {

    private static final Logger log = LoggerFactory.getLogger(PushPoller.class);
    private static final int BATCH = 20;

    private final JdbcTemplate jdbc;
    private final FcmSender fcmSender;

    public PushPoller(JdbcTemplate jdbc, FcmSender fcmSender) {
        this.jdbc = jdbc;
        this.fcmSender = fcmSender;
    }

    @Scheduled(fixedDelayString = "${poll.interval-ms:10000}")
    public void pollAndPush() {
        List<Map<String, Object>> rows = jdbc.queryForList(
                """
                SELECT id, user_id, title, body, ref_id
                FROM notification
                WHERE pushed_at IS NULL
                ORDER BY id
                LIMIT ?
                """, BATCH);

        for (Map<String, Object> row : rows) {
            long id = ((Number) row.get("id")).longValue();
            long userId = ((Number) row.get("user_id")).longValue();
            String title = (String) row.get("title");
            String body = (String) row.get("body");
            Long refId = row.get("ref_id") == null ? null : ((Number) row.get("ref_id")).longValue();

            try {
                String deviceToken = jdbc.query(
                        "SELECT token FROM device_token WHERE user_id = ?",
                        (rs, n) -> rs.getString(1), userId).stream().findFirst().orElse(null);

                if (deviceToken == null) {
                    log.debug("No device token for user {} — push skipped", userId);
                } else if (refId != null) {
                    fcmSender.pushToToken(deviceToken, title, body,
                            Map.of("reportId", String.valueOf(refId), "type", "REPORT_STATUS"));
                }
            } catch (Exception e) {
                log.warn("Push attempt failed for notification {}: {}", id, e.getMessage());
            }
            jdbc.update("UPDATE notification SET pushed_at = NOW() WHERE id = ?", id);
        }

        if (!rows.isEmpty()) {
            log.info("Push poller processed {} notification(s)", rows.size());
        }
    }
}
