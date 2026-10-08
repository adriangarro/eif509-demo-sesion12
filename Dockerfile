# Imagen de contenedor de la API (Sesión 12, lámina 8): dos etapas.
# La plataforma construye esta imagen en cada push a main.

# Etapa 1: compilar con el JDK. Las pruebas ya se ejecutaron en la
# integración continua antes del despliegue; por eso aquí se omiten (-x test).
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN ./gradlew bootJar --no-daemon -x test

# Etapa 2: ejecutar con un JRE más liviano. La imagen final solo contiene
# el JAR: ni el código fuente ni Gradle.
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
