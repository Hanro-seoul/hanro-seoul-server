# syntax=docker/dockerfile:1

################################################################################
# Stage 1: 의존성 해결 (캐시 잘 타게 분리)
FROM eclipse-temurin:21-jdk-jammy AS deps

WORKDIR /build

# gradlew 실행 권한 포함해서 복사
COPY --chmod=0755 gradlew gradlew
COPY gradle/ gradle/

# 빌드 스크립트 복사
COPY build.gradle.kts settings.gradle.kts ./

# 의존성 미리 받기 (빌드 스크립트 안 바뀌면 이 layer 캐시 그대로 재사용)
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew dependencies --no-daemon || true

################################################################################
# Stage 2: 애플리케이션 빌드 (jar 생성)
FROM deps AS package

WORKDIR /build

# 소스 복사 (위 deps 단계 이후에 와야 의존성 캐시 안 깨짐)
COPY src/ src/

# 실행 가능한 jar 빌드. -x test 로 테스트 스킵 (테스트는 CI에서 별도로)
RUN --mount=type=cache,target=/root/.gradle \
    ./gradlew bootJar --no-daemon -x test

################################################################################
# Stage 3: 런타임 (가벼운 JRE 이미지만)
FROM eclipse-temurin:21-jre-jammy AS final

# non-root 유저 생성 (보안 best practice)
ARG UID=10001
RUN adduser \
    --disabled-password \
    --gecos "" \
    --home "/nonexistent" \
    --shell "/sbin/nologin" \
    --no-create-home \
    --uid "${UID}" \
    appuser
USER appuser

WORKDIR /app

# 빌드 단계에서 만든 jar 만 가져오기 (JDK, 소스코드 다 안 가져옴)
COPY --from=package /build/build/libs/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar"]
