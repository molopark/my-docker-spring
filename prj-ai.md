# 프로젝트 환경 및 설정 가이드 (prj-ai)

이 문서는 현재 프로젝트의 개발 환경, 인프라 구성, 그리고 주요 설정 파일(`Dockerfile`, `docker-compose.yml`)에 대한 상세 설명과 변경 가이드를 담고 있습니다.

## 1. 프로젝트 개요 및 개발 환경

*   **프로젝트 유형**: Spring Boot 기반 애플리케이션
*   **개발 OS**: Windows (로컬 호스트)
*   **Java 버전**: JDK 17 (Eclipse Temurin) - **로컬 설치 필수** (IDE 자동완성 및 구문 분석용)
*   **빌드 도구**: Gradle (Wrapper 사용)
*   **컨테이너 전략**:
    *   **개발**: 로컬 IDE(VS Code/IntelliJ)에서 직접 개발 (Dev Container 사용 안 함).
    *   **인프라**: 데이터베이스(PostgreSQL)와 캐시(Redis)는 Docker Compose로 실행. (`spring-boot-docker-compose` 라이브러리를 통해 앱 실행 시 자동 관리됨)
    *   **배포**: Dockerfile을 통해 애플리케이션을 컨테이너 이미지로 빌드.

---

## 2. Dockerfile 구성 및 설정 변경

`Dockerfile`은 **Multi-stage Build** 방식을 사용하여 빌드 환경과 실행 환경을 분리했습니다. 이를 통해 이미지 크기를 줄이고 보안을 강화했습니다.

### 주요 구성 요소

1.  **Build Stage (`build`)**:
    *   베이스 이미지: `eclipse-temurin:17-jdk-alpine` (JDK 포함)
    *   **캐싱 최적화**: 소스 코드 전체를 복사하기 전에 `gradlew`, `build.gradle` 등 설정 파일만 먼저 복사하여 의존성을 다운로드합니다. 소스 코드가 변경되어도 라이브러리 다운로드 과정을 건너뛰어 빌드 속도가 빠릅니다.
2.  **Runtime Stage**:
    *   베이스 이미지: `eclipse-temurin:17-jre-alpine` (JRE만 포함, 가벼움)
    *   실행: 빌드 단계에서 생성된 `app.jar`만 복사하여 실행합니다.

### ⚙️ 설정 변경 가이드

*   **Java 버전 변경 시**:
    *   `FROM eclipse-temurin:17-jdk-alpine` 부분의 숫자 `17`을 원하는 버전(예: `21`)으로 변경하세요. (Build, Runtime 두 곳 모두 변경 필요)
*   **빌드 명령어 변경 시**:
    *   기본은 `./gradlew bootJar`입니다. 다른 태스크가 필요하면 해당 라인을 수정하세요.
*   **JVM 옵션 추가 시**:
    *   `ENTRYPOINT` 라인을 수정하여 옵션을 추가할 수 있습니다.
    *   예: `ENTRYPOINT ["java", "-Xmx512m", "-jar", "app.jar"]`

---

## 3. Docker Compose 구성 및 설정 변경

`docker-compose.yml`은 애플리케이션이 의존하는 외부 서비스(DB, Redis)를 정의합니다.

### 서비스 목록

1.  **db (PostgreSQL)**
    *   이미지: `postgres:15`
    *   포트: 호스트의 `5432` 포트를 컨테이너의 `5432`와 연결.
    *   데이터 저장: `postgres_data`라는 Docker Volume을 사용하여 컨테이너가 삭제되어도 데이터가 유지됩니다.
2.  **redis (Redis)**
    *   이미지: `redis:7-alpine`
    *   포트: 호스트의 `6379` 포트와 연결.
    *   데이터 저장: `redis_data` 볼륨 사용.

### ⚙️ 설정 변경 가이드

*   **DB 비밀번호/사용자 변경**:
    *   `environment` 섹션의 `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` 값을 수정하세요.
    *   **주의**: 이미 볼륨이 생성된 상태에서 비밀번호를 바꾸면 적용되지 않을 수 있습니다. 이 경우 `docker volume rm <볼륨이름>`으로 볼륨을 삭제하고 다시 띄워야 합니다.
*   **포트 충돌 해결**:
    *   로컬에 이미 PostgreSQL이 설치되어 있어 5432 포트가 사용 중이라면, 호스트 포트 부분을 변경하세요.
    *   예: `5433:5432` (로컬의 5433 포트로 접속)
*   **데이터 초기화**:
    *   데이터를 완전히 삭제하고 싶다면 다음 명령어를 사용하세요.
    *   `docker-compose down -v` (컨테이너와 볼륨 모두 삭제)
*   **Spring Boot 자동 실행 (Docker Compose Support)**:
    *   `build.gradle`에 `spring-boot-docker-compose` 의존성이 포함되어 있습니다.
    *   로컬에서 앱을 실행(`bootRun` 등)하면 Spring Boot가 자동으로 `docker-compose.yml`을 읽어 DB와 Redis 컨테이너를 실행하고 연결 정보를 주입합니다.
    *   수동으로 `docker-compose up`을 하지 않아도 개발이 가능합니다.

---

## 4. 주요 명령어 모음

### 인프라(DB, Redis) 실행
개발을 시작할 때 DB와 Redis를 백그라운드에서 실행합니다.
```bash
docker-compose up -d
```

### 인프라 중지
```bash
docker-compose down
```

### 애플리케이션 Docker 이미지 빌드
```bash
docker build -t my-spring-app .
```

### 애플리케이션 컨테이너 실행 (DB와 함께)
만약 `docker-compose.yml`에 앱 서비스까지 추가했다면 `docker-compose up`으로 한 번에 실행 가능하지만, 현재는 DB/Redis만 정의되어 있으므로 앱은 별도로 실행하거나 로컬 IDE에서 실행합니다.

### ⚠️ 주의: 접속 주소 차이
*   **로컬 개발 시**: `localhost:5432`, `localhost:6379`로 접속합니다. (단, `spring-boot-docker-compose` 사용 시 자동 주입되므로 신경 쓰지 않아도 됩니다.)
*   **Docker 배포 시**: `db:5432`, `redis:6379`와 같이 `docker-compose.yml`에 정의된 **서비스 이름**으로 접속해야 합니다.
*   `application.properties` 설정 시 이 차이를 유의해야 합니다.

---

## 5. 로컬 개발 환경 설정 (IDE 자동완성 활성화)

Java 파일 작성 시 자동 `import`와 코드 자동완성 기능을 사용하려면 다음 설정이 필수입니다.

1.  **JDK 17 설치 (Windows)**
    *   Docker 컨테이너와 별개로, 로컬 Windows 환경에도 JDK 17이 설치되어 있어야 IDE가 코드를 분석할 수 있습니다.
    *   **설치 방법 (PowerShell)**: `winget install EclipseAdoptium.Temurin.17.JDK`
    *   또는 Adoptium 웹사이트에서 `.msi` 파일을 다운로드하여 설치하세요.
    *   **설치 팁**: MSI 설치 화면에서 **"Set JAVA_HOME variable"** 기능을 활성화하면 수동 설정이 필요 없습니다.
    *   설치 완료 후 새 터미널에서 `java -version` 및 `echo %JAVA_HOME%` 명령어로 설정을 확인하세요.
2.  **VS Code 확장 프로그램 설치**
    *   프로젝트 루트에 `.vscode/extensions.json` 파일을 추가했습니다. VS Code 실행 시 권장 확장을 설치하세요.
    *   주요 확장: `Extension Pack for Java`, `Spring Boot Extension Pack`
3.  **Gradle 의존성 다운로드**
    *   IDE가 프로젝트를 처음 열 때 의존성 라이브러리를 다운로드합니다. 이 과정이 완료되어야 붉은색 에러 밑줄이 사라지고 자동완성이 작동합니다.

---

*작성일: 2024년*
*작성자: Gemini Code Assist*