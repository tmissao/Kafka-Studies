FROM maven:3.6.1-jdk-8-alpine AS MAVEN_BUILD

COPY . .

RUN mvn clean package

FROM openjdk:8-jre-alpine3.9

COPY --from=MAVEN_BUILD target/kafka-beginners-course-1.0.jar /app.jar
COPY --from=MAVEN_BUILD target/libs /libs

CMD ["java", "-jar", "app.jar"]
