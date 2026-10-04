package com.example.feedbackapp.polls.repository;

import com.example.feedbackapp.polls.entity.PollOption;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface PollOptionRepository extends JpaRepository<PollOption, Long> {

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("UPDATE PollOption o SET o.votesCount = o.votesCount + 1 WHERE o.id = :optionId")
    void incrementVotes(@Param("optionId") Long optionId);
}
