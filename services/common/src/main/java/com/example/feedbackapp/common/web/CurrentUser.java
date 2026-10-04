package com.example.feedbackapp.common.web;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

/**
 * Binds a controller parameter to the {@link GatewayUser} resolved from the
 * gateway's trusted identity headers.
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
public @interface CurrentUser {

    /** When false, a missing identity resolves to null instead of 401. */
    boolean required() default true;
}
