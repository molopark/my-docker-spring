# 1단계: 빌드 환경
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /app
COPY . .
# 실행 권한 부여 및 빌드 수행 (Spring Boot의 경우 bootJar)
RUN chmod +x gradlew && ./gradlew bootJar --no-daemon

# 2단계: 실행 환경 (JRE만 포함하여 가볍게 구성)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]

# 빌드 시점에 Java 설치 및 버전 확인 (로그에 버전 정보가 출력됨)
RUN java -version