# ---- Stage build ----
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Cache des dependances Maven
COPY pom.xml .
RUN mvn dependency:go-offline -B

# Copie du code source et build
COPY src/ src/
RUN mvn clean package -DskipTests -B

# ---- Stage runtime ----
FROM eclipse-temurin:21-jre-jammy

RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system budget && useradd --system --gid budget budget

WORKDIR /app

RUN mkdir -p logs data/avatars && chown -R budget:budget logs data

COPY --from=build /app/target/api-*.jar app.jar
RUN chown budget:budget app.jar

EXPOSE 8080

# Entrypoint : fix permissions volumes (logs, avatars) puis lance en user budget
ENTRYPOINT ["sh", "-c", "chown -R budget:budget /app/logs /app/data && exec runuser -u budget -- java -jar app.jar"]
