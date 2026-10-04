package com.example.feedbackapp.common.web;

import com.example.feedbackapp.common.error.UnauthorizedException;
import org.springframework.core.MethodParameter;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;

/**
 * Resolves {@code @CurrentUser GatewayUser} parameters from the identity
 * headers injected by the API gateway.
 */
public class CurrentUserArgumentResolver implements HandlerMethodArgumentResolver {

    private static final String USER_ID_HEADER = "X-User-Id";
    private static final String USER_ROLE_HEADER = "X-User-Role";
    private static final String USER_NAME_HEADER = "X-User-Name";
    private static final String USER_EMAIL_HEADER = "X-User-Email";

    @Override
    public boolean supportsParameter(MethodParameter parameter) {
        return parameter.hasParameterAnnotation(CurrentUser.class)
                && GatewayUser.class.isAssignableFrom(parameter.getParameterType());
    }

    @Override
    public Object resolveArgument(MethodParameter parameter,
                                  ModelAndViewContainer mavContainer,
                                  NativeWebRequest webRequest,
                                  WebDataBinderFactory binderFactory) {
        String userId = webRequest.getHeader(USER_ID_HEADER);
        boolean required = parameter.getParameterAnnotation(CurrentUser.class).required();
        if (userId == null || userId.isBlank()) {
            if (!required) {
                return null;
            }
            throw new UnauthorizedException("Missing authenticated user context — call through the API gateway");
        }
        try {
            return new GatewayUser(
                    Long.valueOf(userId),
                    webRequest.getHeader(USER_ROLE_HEADER),
                    webRequest.getHeader(USER_NAME_HEADER),
                    webRequest.getHeader(USER_EMAIL_HEADER));
        } catch (NumberFormatException e) {
            if (!required) {
                return null;
            }
            throw new UnauthorizedException("Malformed user context");
        }
    }
}
