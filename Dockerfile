FROM openjdk:11-jre-slim

WORKDIR /app

COPY target/spring-petclinic-2.4.2.war app.war

RUN apt-get update -y && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.war"]