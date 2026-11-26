# syntax=docker/dockerfile:1

FROM maven:3.9-eclipse-temurin-21-noble AS build
ARG SERVICE
WORKDIR /build
COPY ${SERVICE}/pom.xml ./pom.xml
COPY ${SERVICE}/src ./src
RUN --mount=type=cache,target=/root/.m2/repository,sharing=locked \
    mvn --batch-mode --no-transfer-progress package

FROM eclipse-temurin:21-jre-noble
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=build /build/target/*.jar ./service.jar
USER 10001:10001
ENTRYPOINT ["java", "-jar", "/app/service.jar"]
