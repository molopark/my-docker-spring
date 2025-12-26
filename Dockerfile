# 1단계: 빌드 환경
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app

# 빌드 속도 향상을 위해 변경이 적은 설정 파일들을 먼저 복사하여 캐시 활용
COPY gradlew .
COPY gradle gradle
COPY build.gradle .
COPY settings.gradle .
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

COPY . .
RUN ./gradlew bootJar --no-daemon

# 2단계: 실행 환경 (JRE만 포함하여 가볍게 구성)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]