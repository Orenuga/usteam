FROM tomcat:9.0-jdk11-openjdk-slim

# Remove default Tomcat apps
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the WAR file to Tomcat webapps directory
COPY target/spring-petclinic-2.4.2.war /usr/local/tomcat/webapps/ROOT.war

# Install curl for health checks
RUN apt-get update -y && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Expose port
EXPOSE 8080

# Start Tomcat
ENTRYPOINT ["catalina.sh", "run"]