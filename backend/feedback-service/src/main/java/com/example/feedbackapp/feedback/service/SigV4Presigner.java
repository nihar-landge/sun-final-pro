package com.example.feedbackapp.feedback.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.ZoneOffset;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

/**
 * Manual AWS SigV4 query-string presigner for S3-compatible storage
 * (Cloudflare R2, SeaweedFS, MinIO, AWS S3). Implemented directly instead of
 * via an SDK because presigned-URL signature styles differ between SDK
 * versions and providers — this form (UNSIGNED-PAYLOAD, host-signed,
 * path-style, canonical query string included in the signature,
 * Content-Type signed on uploads) is byte-for-byte the one boto3 emits,
 * which is the form Cloudflare R2 accepts (see scripts/r2-presign-vector.py).
 *
 * Credentials come from configuration; keys are never logged.
 */
@Component
public class SigV4Presigner {

    private static final DateTimeFormatter AMZ_DATE =
            DateTimeFormatter.ofPattern("yyyyMMdd'T'HHmmss'Z'").withZone(ZoneOffset.UTC);
    private static final DateTimeFormatter DATE_SCOPE =
            DateTimeFormatter.ofPattern("yyyyMMdd").withZone(ZoneOffset.UTC);

    private final String endpoint;      // e.g. https://<account>.r2.cloudflarestorage.com
    private final String accessKey;
    private final String secretKey;
    private final String region;        // "auto" for R2

    public SigV4Presigner(@Value("${minio.public-url}") String endpoint,
                          @Value("${minio.access-key}") String accessKey,
                          @Value("${minio.secret-key}") String secretKey,
                          @Value("${minio.region:us-east-1}") String region) {
        this.endpoint = endpoint.endsWith("/") ? endpoint.substring(0, endpoint.length() - 1) : endpoint;
        this.accessKey = accessKey;
        this.secretKey = secretKey;
        this.region = region;
    }

    public record PresignedUrl(String url, String host) {
    }

    /**
     * Presigned PUT URL valid for the given duration. Only the host header is
     * signed: Cloudflare R2 rejects presigned PUTs whose Content-Type is part
     * of the signature (verified against a working boto3 reference), so the
     * Content-Type header must stay unsigned — clients may send it or not.
     */
    public PresignedUrl presignPut(String bucket, String key, int expirySeconds) {
        return presign("PUT", bucket, key, expirySeconds, null, ZonedDateTime.now(ZoneOffset.UTC));
    }

    /** Presigned GET URL valid for the given duration. */
    public PresignedUrl presignGet(String bucket, String key, int expirySeconds) {
        return presign("GET", bucket, key, expirySeconds, null, ZonedDateTime.now(ZoneOffset.UTC));
    }

    PresignedUrl presign(String method, String bucket, String key, int expirySeconds,
                         String contentType, ZonedDateTime now) {
        String amzDate = now.format(AMZ_DATE);
        String dateScope = now.format(DATE_SCOPE);

        String host = URI.create(endpoint).getHost();
        String canonicalUri = "/" + bucket + "/" + encodePath(key);
        String scope = dateScope + "/" + region + "/s3/aws4_request";

        String signedHeaders;
        String canonicalHeaders;
        if (contentType == null) {
            signedHeaders = "host";
            canonicalHeaders = "host:" + host + "\n";
        } else {
            signedHeaders = "content-type;host";
            canonicalHeaders = "content-type:" + contentType.toLowerCase() + "\nhost:" + host + "\n";
        }

        // Every parameter except the signature is part of the signed canonical
        // query string; providers recompute the signature from the URL they
        // receive, so signing an empty query makes every strict SigV4
        // validator (AWS S3, R2) reject the request. Keys are sorted: here
        // Algorithm < Credential < Date < Expires < SignedHeaders.
        String canonicalQuery = String.join("&",
                "X-Amz-Algorithm=AWS4-HMAC-SHA256",
                "X-Amz-Credential=" + urlEncode(accessKey + "/" + scope),
                "X-Amz-Date=" + amzDate,
                "X-Amz-Expires=" + expirySeconds,
                "X-Amz-SignedHeaders=" + urlEncode(signedHeaders));

        String canonicalRequest = String.join("\n",
                method, canonicalUri, canonicalQuery, canonicalHeaders, signedHeaders, "UNSIGNED-PAYLOAD");

        String stringToSign = String.join("\n",
                "AWS4-HMAC-SHA256", amzDate, scope,
                sha256Hex(canonicalRequest));

        byte[] signingKey = hmacChain(secretKey, dateScope, region, "s3");
        String signature = hex(hmac(signingKey, stringToSign));

        return new PresignedUrl(
                endpoint + canonicalUri + "?" + canonicalQuery + "&X-Amz-Signature=" + signature,
                host);
    }

    static String urlEncode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8).replace("+", "%20");
    }

    static String encodePath(String key) {
        String[] segments = key.split("/");
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < segments.length; i++) {
            if (i > 0) sb.append('/');
            sb.append(URLEncoder.encode(segments[i], StandardCharsets.UTF_8).replace("+", "%20"));
        }
        return sb.toString();
    }

    static byte[] hmacChain(String secretKey, String date, String region, String service) {
        byte[] kDate = hmac(("AWS4" + secretKey).getBytes(StandardCharsets.UTF_8), date);
        byte[] kRegion = hmac(kDate, region);
        byte[] kService = hmac(kRegion, service);
        return hmac(kService, "aws4_request");
    }

    static byte[] hmac(byte[] key, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(key, "HmacSHA256"));
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    static String sha256Hex(String data) {
        try {
            java.security.MessageDigest digest = java.security.MessageDigest.getInstance("SHA-256");
            return hex(digest.digest(data.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    static String hex(byte[] bytes) {
        StringBuilder sb = new StringBuilder(bytes.length * 2);
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }
}
