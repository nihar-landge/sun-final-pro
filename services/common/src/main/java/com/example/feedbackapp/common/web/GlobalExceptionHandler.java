package com.example.feedbackapp.common.web;

import com.example.feedbackapp.common.api.ApiResponse;
import com.example.feedbackapp.common.api.ErrorResponse;
import com.example.feedbackapp.common.error.ErrorCode;
import com.example.feedbackapp.common.error.ServiceException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Shared exception mapping for all servlet-based services: translates
 * ServiceException error codes and validation failures into the common
 * ApiResponse/ErrorResponse envelopes.
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiResponse<Void>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, Object> details = new LinkedHashMap<>();
        ex.getBindingResult().getFieldErrors()
                .forEach(fe -> details.put(fe.getField(), fe.getDefaultMessage()));
        ErrorResponse error = ErrorResponse.of(ErrorCode.VALIDATION_FAILED.value(), "Request validation failed", details);
        return ResponseEntity.badRequest().body(new ApiResponse<>(false, null, error.message(), error.timestamp()));
    }

    @ExceptionHandler(ServiceException.class)
    public ResponseEntity<ApiResponse<Void>> handleService(ServiceException ex) {
        HttpStatus status = switch (ex.errorCode()) {
            case UNAUTHORIZED, OTP_INVALID -> HttpStatus.UNAUTHORIZED;
            case FORBIDDEN -> HttpStatus.FORBIDDEN;
            case OTP_RATE_LIMITED -> HttpStatus.TOO_MANY_REQUESTS;
            case NOT_FOUND -> HttpStatus.NOT_FOUND;
            case CONFLICT, ALREADY_VOTED -> HttpStatus.CONFLICT;
            case VALIDATION_FAILED -> HttpStatus.BAD_REQUEST;
            case INTERNAL_ERROR -> HttpStatus.INTERNAL_SERVER_ERROR;
        };
        ErrorResponse error = ErrorResponse.of(ex.errorCode().value(), ex.getMessage());
        return ResponseEntity.status(status)
                .body(new ApiResponse<>(false, null, error.message(), error.timestamp()));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiResponse<Void>> handleUnexpected(Exception ex) {
        log.error("Unhandled exception", ex);
        ErrorResponse error = ErrorResponse.of(ErrorCode.INTERNAL_ERROR.value(), "Something went wrong");
        return ResponseEntity.internalServerError()
                .body(new ApiResponse<>(false, null, error.message(), error.timestamp()));
    }
}
