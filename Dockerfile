# ---- Stage build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Cache des dependances Maven
COPY api/pom.xml api/pom.xml
RUN cd api && mvn dependency:go-offline -B

# Copie du code source et build
COPY api/src api/src
RUN cd api && mvn clean package -DskipTests -B

# ---- Stage runtime ----
FROM eclipse-temurin:21-jre-jammy

RUN groupadd --system budget && useradd --system --gid budget budget

WORKDIR /app

# Repertoire pour les logs logback prod
RUN mkdir logs && chown budget:budget logs

COPY --from=build /app/api/target/api-*.jar app.jar
RUN chown budget:budget app.jar

USER budget

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -f http://localhost:8080/api/actuator/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar", "--spring.profiles.active=prod"]
