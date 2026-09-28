package com.example.feedbackapp.feedback.service;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import java.time.ZoneOffset;
import java.time.ZonedDateTime;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Verifies the presigner against frozen-clock reference URLs minted by
 * boto3/botocore — the implementation that provably worked against Cloudflare
 * R2 when every Java SDK presigner was rejected (see docs/SESSION-HANDOFF.md
 * W14 and scripts/r2-presign-vector.py to regenerate the vectors).
 *
 * Byte-for-byte equality proves the three properties R2 needs: the canonical
 * query string is part of the signature, the region sits in the credential
 * scope, and the Content-Type header is signed on uploads.
 */
class SigV4PresignerTest {

    private static final ZonedDateTime FROZEN =
            ZonedDateTime.of(2013, 5, 24, 0, 0, 0, 0, ZoneOffset.UTC);
    private static final String KEY = "reports/1/2b3f9a5e-8c41-4d67-9a01-c3d5e7f9a0b1.jpg";

    private final SigV4Presigner presigner = new SigV4Presigner(
            "https://exampleaccount.r2.cloudflarestorage.com",
            "AKIAIOSFODNN7EXAMPLE",
            "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
            "auto");

    @Test
    @DisplayName("GET presign matches the boto3 reference byte-for-byte")
    void getMatchesBoto3Vector() {
        String url = presigner.presign("GET", "feedback-photos", KEY, 3600, null, FROZEN).url();
        assertThat(url).isEqualTo("https://exampleaccount.r2.cloudflarestorage.com/feedback-photos/"
                + KEY
                + "?X-Amz-Algorithm=AWS4-HMAC-SHA256"
                + "&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fauto%2Fs3%2Faws4_request"
                + "&X-Amz-Date=20130524T000000Z"
                + "&X-Amz-Expires=3600"
                + "&X-Amz-SignedHeaders=host"
                + "&X-Amz-Signature=f5211bee5790d5701f6d94badf927752ab875bff3abf9b6ef13f15a294f239af");
    }

    @Test
    @DisplayName("PUT presign signs the Content-Type header, matching the boto3 reference")
    void putMatchesBoto3VectorWithSignedContentType() {
        String url = presigner.presign("PUT", "feedback-photos", KEY, 600, "image/jpeg", FROZEN).url();
        assertThat(url).isEqualTo("https://exampleaccount.r2.cloudflarestorage.com/feedback-photos/"
                + KEY
                + "?X-Amz-Algorithm=AWS4-HMAC-SHA256"
                + "&X-Amz-Credential=AKIAIOSFODNN7EXAMPLE%2F20130524%2Fauto%2Fs3%2Faws4_request"
                + "&X-Amz-Date=20130524T000000Z"
                + "&X-Amz-Expires=600"
                + "&X-Amz-SignedHeaders=content-type%3Bhost"
                + "&X-Amz-Signature=7bf540d349361bd0a7eb5d76f2fa4626d67bb9433acd473304ad6a9bc45e0f08");
    }

    @Test
    @DisplayName("no checksum or SDK parameters ride along (the SDK-v2 failure mode from W14)")
    void noChecksumParameters() {
        String url = presigner.presign("PUT", "feedback-photos", KEY, 600, "image/jpeg", FROZEN).url();
        assertThat(url).doesNotContain("X-Amz-Checksum", "x-amz-sdk-checksum", "X-Amz-Meta");
    }

    @Test
    @DisplayName("changing the expiry changes the signature (query params are signed)")
    void expiryIsSigned() {
        String shortExpiry = presigner.presign("GET", "feedback-photos", KEY, 60, null, FROZEN).url();
        String longExpiry = presigner.presign("GET", "feedback-photos", KEY, 3600, null, FROZEN).url();
        String shortSig = shortExpiry.substring(shortExpiry.lastIndexOf('=') + 1);
        String longSig = longExpiry.substring(longExpiry.lastIndexOf('=') + 1);
        assertThat(shortSig).isNotEqualTo(longSig);
    }
}
