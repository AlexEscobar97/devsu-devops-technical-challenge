FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src ./src

RUN mvn clean package -B

FROM eclipse-temurin:17-jre

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system appgroup \
    && useradd --system --gid appgroup appuser \
    && mkdir -p /app/data \
    && chown -R appuser:appgroup /app

COPY --from=build --chown=appuser:appgroup \
    /app/target/demo-0.0.1.jar app.jar

USER appuser

ENV PORT=8000
ENV NAME_DB=jdbc:h2:file:/app/data/test

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=5s \
    --start-period=60s --retries=3 \
    CMD curl --fail --silent --show-error \
    http://localhost:8000/api/actuator/health \
    || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]