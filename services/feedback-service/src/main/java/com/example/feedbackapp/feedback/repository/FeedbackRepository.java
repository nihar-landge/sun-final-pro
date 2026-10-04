package com.example.feedbackapp.feedback.repository;

import com.example.feedbackapp.feedback.entity.Feedback;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface FeedbackRepository extends JpaRepository<Feedback, Long>, JpaSpecificationExecutor<Feedback> {

    List<Feedback> findByUserIdOrderByIdDesc(Long userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE Feedback f SET f.upvotes = f.upvotes + 1 WHERE f.id = :id")
    void incrementUpvotes(@Param("id") Long id);

    /** MySQL spatial radius query — uses the SPATIAL index on location. */
    @Query(value = """
            SELECT f.id, f.title, f.category, f.status, f.upvotes, f.created_at,
                   ST_Distance_Sphere(f.location, ST_SRID(Point(:lng, :lat), 4326)) AS distance_meters,
                   ST_X(f.location) AS latitude,
                   ST_Y(f.location) AS longitude
            FROM feedback f
            WHERE ST_Distance_Sphere(f.location, ST_SRID(Point(:lng, :lat), 4326)) <= :radiusMeters
              AND f.status = COALESCE(:status, f.status)
            ORDER BY distance_meters ASC
            """, nativeQuery = true)
    List<NearbyFeedbackView> findNearby(@Param("lat") double lat,
                                        @Param("lng") double lng,
                                        @Param("radiusMeters") double radiusMeters,
                                        @Param("status") String status);

    /** Daily submission counts for the admin trend chart (recursive CTE calendar). */
    @Query(value = """
            WITH RECURSIVE d(day) AS (
                SELECT CURDATE() - INTERVAL :days DAY
                UNION ALL
                SELECT day + INTERVAL 1 DAY FROM d WHERE day < CURDATE()
            )
            SELECT DATE_FORMAT(d.day, '%Y-%m-%d') AS day, COUNT(f.id) AS count
            FROM d
            LEFT JOIN feedback f ON DATE(f.created_at) = d.day
            GROUP BY d.day ORDER BY d.day
            """, nativeQuery = true)
    List<Object[]> dailyCounts(@Param("days") int days);

    /** Average hours from submission to first RESOLVED transition (null when none resolved). */
    @Query(value = """
            SELECT AVG(TIMESTAMPDIFF(SECOND, f.created_at, h.changed_at)) / 3600.0
            FROM feedback_status_history h
            JOIN feedback f ON f.id = h.feedback_id
            WHERE h.new_status = 'RESOLVED'
            """, nativeQuery = true)
    Double avgResolutionHours();

    long countByCreatedAtAfter(java.time.LocalDateTime since);
}
