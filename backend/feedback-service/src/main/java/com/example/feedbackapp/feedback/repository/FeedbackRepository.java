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

    /** PostGIS radius query — uses the GIST index on location. */
    @Query(value = """
            SELECT f.id, f.title, f.category, f.status, f.upvotes, f.created_at,
                   ST_Distance(f.location, ST_MakePoint(:lng, :lat)::geography) AS distance_meters,
                   ST_Y(f.location::geometry) AS latitude,
                   ST_X(f.location::geometry) AS longitude
            FROM feedback f
            WHERE ST_DWithin(f.location, ST_MakePoint(:lng, :lat)::geography, :radiusMeters)
              AND f.status = COALESCE(:status, f.status::varchar)
            ORDER BY distance_meters ASC
            """, nativeQuery = true)
    List<NearbyFeedbackView> findNearby(@Param("lat") double lat,
                                        @Param("lng") double lng,
                                        @Param("radiusMeters") double radiusMeters,
                                        @Param("status") String status);

    /** Average hours from submission to first RESOLVED transition (null when none resolved). */
    @Query(value = """
            SELECT AVG(EXTRACT(EPOCH FROM (h.changed_at - f.created_at)) / 3600.0)
            FROM feedback_status_history h
            JOIN feedback f ON f.id = h.feedback_id
            WHERE h.new_status = 'RESOLVED'
            """, nativeQuery = true)
    Double avgResolutionHours();

    long countByCreatedAtAfter(java.time.LocalDateTime since);
}
