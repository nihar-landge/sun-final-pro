# Build stage: unpack the layered Spring Boot jar
FROM eclipse-temurin:21-jre-alpine AS builder
WORKDIR /app
COPY target/*.jar app.jar
RUN java -Djarmode=layertools -jar app.jar extract

# Runtime stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S app && adduser -S app -G app
# uploads dir must exist and be writable by the app user — a fresh named
# volume inherits this ownership
RUN mkdir -p /app/uploads && chown -R app:app /app/uploads
USER app
COPY --from=builder /app/dependencies/ ./
COPY --from=builder /app/spring-boot-loader/ ./
COPY --from=builder /app/snapshot-dependencies/ ./
COPY --from=builder /app/application/ ./
EXPOSE 8083
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]
