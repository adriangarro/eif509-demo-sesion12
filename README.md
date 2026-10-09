# EIF509 · Demo Sesión 12 — Despliegue de la API en la nube

Repositorio de demostración del curso **EIF509 «Desarrollo de Aplicaciones
Basadas en Web»** (Universidad Nacional, Costa Rica).

Esta demo continúa el proyecto de la
[Sesión 11 (JWT y SPA en React)](https://github.com/adriangarro/eif509-demo-sesion11).
Prepara la API para una **plataforma como servicio** y la publica en internet
con una base de datos PostgreSQL gestionada, **perfiles de configuración** y
**secretos** definidos únicamente en la plataforma. Las demos anteriores de
la serie son:
[Sesión 3](https://github.com/adriangarro/eif509-demo-sesion3) ·
[Sesión 4](https://github.com/adriangarro/eif509-demo-sesion4) ·
[Sesión 5](https://github.com/adriangarro/eif509-demo-sesion5) ·
[Sesión 6](https://github.com/adriangarro/eif509-demo-sesion6) ·
[Sesión 7](https://github.com/adriangarro/eif509-demo-sesion7) ·
[Sesión 8](https://github.com/adriangarro/eif509-demo-sesion8) ·
[Sesión 9](https://github.com/adriangarro/eif509-demo-sesion9) ·
[Sesión 10](https://github.com/adriangarro/eif509-demo-sesion10) ·
[Sesión 11](https://github.com/adriangarro/eif509-demo-sesion11).

## ¿Qué van a construir?

**Parte 1 · El artefacto y la configuración, en su computadora**

1. Un `Dockerfile` en dos etapas: compila con el JDK y ejecuta el JAR con un
   JRE más liviano.
2. La configuración separada en perfiles: `application.yml` (común),
   `application-dev.yml` (Docker Compose) y `application-prod.yml` (la nube).
   Ningún archivo contiene un valor secreto: solo nombres de variables.
3. El puerto se lee de la variable `PORT`, como exige la plataforma.
4. La imagen se construye y se ejecuta **igual que lo hará la plataforma**:
   perfil `prod`, variables de entorno y un puerto asignado. Flyway aplica las
   migraciones y la API responde.
5. Qué pasa cuando falta una variable: el error aparece en los registros de
   arranque.

**Parte 2 · Despliegue en la plataforma como servicio**

1. Crear una base PostgreSQL gestionada y convertir su URL al formato JDBC.
2. Crear el servicio web conectado al repositorio de GitHub (rama `main`,
   construcción con el `Dockerfile`).
3. Configurar las variables de entorno con un secreto JWT nuevo, distinto al
   de desarrollo.
4. Seguir los registros de construcción y de arranque.
5. Abrir la URL pública: Swagger UI, `POST /auth/login` y un `GET` protegido.
6. Un `push` a `main` genera un despliegue automático.

La plataforma de referencia es [Render](https://render.com) (los pasos son
equivalentes en Railway u otra plataforma que construya a partir de un
`Dockerfile`). El código de la API no cambia respecto a la Sesión 11: todo
lo que se agrega es configuración.

### Cómo queda el sistema desplegado

```text
          push a main                     construye el Dockerfile
 GitHub  ───────────────►  Plataforma  ──────────────────────────►  Servicio web (la API)
 (código, sin secretos)    (integración continua: pruebas)          https://<nombre>.onrender.com
                                                                     SPRING_PROFILES_ACTIVE=prod
                                                                     JWT_SECRETO, CORS_ORIGEN, PORT
                                                                        │ DATABASE_URL / USER / PASSWORD
                                                                        ▼
 Navegador ──► Sitio estático (la SPA) ──── CORS ────► API        PostgreSQL gestionado
               VITE_API_URL=https://<api>                         (Flyway aplica V1..V7 al arrancar)
```

Cada variable se configura en **un solo lugar**: la sección de variables de
entorno del servicio en la plataforma. El repositorio y su historial no
contienen ningún valor.

### Variables de entorno (lámina 14)

| Variable | Ejemplo | Para qué se usa |
|---|---|---|
| `SPRING_PROFILES_ACTIVE` | `prod` | Activa `application-prod.yml` |
| `DATABASE_URL` | `jdbc:postgresql://host:5432/eif509` | Conexión a PostgreSQL (formato JDBC) |
| `DATABASE_USER` / `DATABASE_PASSWORD` | Los entrega la plataforma | Credenciales de PostgreSQL |
| `JWT_SECRETO` | 32 o más caracteres aleatorios | Firma y verificación de los tokens |
| `CORS_ORIGEN` | `https://eif509-spa.onrender.com` | Origen autorizado para la SPA |
| `PORT` | Lo asigna la plataforma (en Render, `10000`) | Puerto en el que escucha la API |
| `MONGODB_URI` | `mongodb+srv://usuario:clave@cluster/...` | Solo si el proyecto usa MongoDB (este repositorio no) |
| `VITE_API_URL` (en la SPA) | `https://eif509-demo-sesion12.onrender.com` | URL de la API al construir la SPA |

## Requisitos previos

| Herramienta | Versión mínima | Descarga oficial | Cómo verificar |
|---|---|---|---|
| Docker Desktop | 4.x | [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/) | `docker --version` |
| JDK (Java) | 21 | [adoptium.net](https://adoptium.net/) | `java -version` |
| Git | 2.30 | [git-scm.com/downloads](https://git-scm.com/downloads) | `git --version` |
| Un cliente HTTP | — | `curl` viene con macOS, Linux y Windows 10+ | `curl --version` |
| Cuenta en GitHub | — | [github.com](https://github.com) | Con el repositorio de su proyecto |
| Cuenta en la plataforma | — | [render.com](https://render.com) (iniciar sesión con GitHub) | Para la Parte 2 |

Node.js solo hace falta para ejecutar la SPA en local (Sesión 11). Las
peticiones contra la URL pública también están en
[`peticiones/nube.http`](peticiones/nube.http), para el cliente HTTP de
IntelliJ IDEA o la extensión *REST Client* de VS Code. En macOS con
Homebrew, en cada terminal que usen:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
```

Este repositorio tiene una sola rama, `main`: la versión lista para
desplegar.

## Usuarios de demostración

La migración `V7__usuarios.sql` crea dos usuarios, con la clave guardada
con BCrypt. Son los mismos en local y en la nube, porque Flyway aplica las
mismas migraciones sobre la base gestionada:

| Correo | Clave | Rol | Puede |
|---|---|---|---|
| `admin@demo.cr` | `admin123` | `ADMIN` | Todo: crear productos y ver cualquier pedido |
| `cliente@demo.cr` | `cliente123` | `CLIENTE` | Leer el catálogo y ver solo sus propios pedidos |

## Estructura del proyecto

Lo nuevo respecto a la Sesión 11 está marcado con `←`:

```text
├── Dockerfile                                     ← la imagen en dos etapas (lámina 8)
├── .dockerignore                                  ← lo que no entra en la imagen
├── .github/workflows/ci.yml                       ← nuevo trabajo: construir la imagen
├── docker-compose.yml                                PostgreSQL para el perfil dev
├── peticiones/nube.http                           ← peticiones contra la URL pública
├── spa/                                              la SPA en React (Sesión 11)
└── src/main/resources/
    ├── application.yml                            ← común: server.port=${PORT:8080}, ${JWT_SECRETO}, ${CORS_ORIGEN}
    ├── application-dev.yml                        ← la base del docker-compose.yml
    ├── application-prod.yml                       ← ${DATABASE_URL}, ${DATABASE_USER}, ${DATABASE_PASSWORD}
    ├── application-sin-cors.yml                      perfil de la demostración de CORS (Sesión 11)
    ├── application-sin-manejador.yml                 perfil de la demostración de errores (Sesión 9)
    └── db/migration/V1..V7                           las migraciones que Flyway aplica en la nube
```

## Las demostraciones paso a paso

Sigan estos pasos en orden para ejecutar las dos partes; cada uno tiene el
comando listo para copiar. La explicación de cada paso está en las
secciones detalladas más abajo: el número entre paréntesis indica dónde.

### Antes de empezar

Abran Docker Desktop y esperen a que termine de iniciar. Inicien sesión en
[dashboard.render.com](https://dashboard.render.com) con su cuenta de
GitHub. Abran dos terminales en la carpeta del repositorio clonado:

```bash
git clone https://github.com/adriangarro/eif509-demo-sesion12.git
```

```bash
cd eif509-demo-sesion12
```

En macOS con Homebrew, ejecuten en ambas terminales:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
```

**Despertar el servicio en la nube.** Si ya tienen un servicio desplegado
(el de respaldo), el plan gratuito lo suspende tras 15 minutos sin tráfico
y tarda unos dos minutos en volver a arrancar. Para que responda al
instante durante la Parte 2, abran una **tercera terminal** y dejen este
bucle en ejecución durante toda la clase (una petición cada 5 minutos):

```bash
while true; do curl -s -o /dev/null -w "$(date +%H:%M:%S) -> %{http_code}\n" https://eif509-demo-sesion12.onrender.com/api/v1/productos; sleep 300; done
```

La primera línea puede tardar hasta dos minutos (el servicio está
despertando); a partir de ahí cada línea muestra `401` de inmediato, que
es la respuesta correcta sin token. Al terminar la clase, deténganlo con
`Ctrl+C`. Si prefieren no dejar nada en ejecución, ejecuten una sola
petición al menos dos minutos antes de llegar al paso 12 y repítanla si
pasan más de 15 minutos sin usar la URL:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://eif509-demo-sesion12.onrender.com/api/v1/productos
```

### Ejemplo: comandos en la computadora del profesor (macOS)

Con el repositorio en `~/Documents/Claude/eif509-demo-sesion12`, los
comandos que cambian respecto a esta sección quedan así, listos para copiar.
Los demás pasos son idénticos.

Paso 2, en la terminal 1:

```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home && cd ~/Documents/Claude/eif509-demo-sesion12 && docker compose down -v && docker compose up -d && docker build -t eif509-demo-sesion12 .
```

Paso 3, en la terminal 1:

```bash
docker run --rm --name api-prod -p 10000:10000 -e PORT=10000 -e SPRING_PROFILES_ACTIVE=prod -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/eif509 -e DATABASE_USER=dev -e DATABASE_PASSWORD=dev -e JWT_SECRETO=$(openssl rand -base64 48) -e CORS_ORIGEN=https://eif509-spa.onrender.com eif509-demo-sesion12
```

Paso 4, en la terminal 2:

```bash
cd ~/Documents/Claude/eif509-demo-sesion12 && curl -i http://localhost:10000/api/v1/productos
```

Paso 8, en la terminal 2 (el secreto nuevo para la plataforma):

```bash
openssl rand -base64 48
```

Antes de empezar, en una terminal 3 (mantiene despierto el servicio de
respaldo durante la clase; se detiene con `Ctrl+C` al final):

```bash
while true; do curl -s -o /dev/null -w "$(date +%H:%M:%S) -> %{http_code}\n" https://eif509-demo-sesion12.onrender.com/api/v1/productos; sleep 300; done
```

Al terminar:

```bash
cd ~/Documents/Claude/eif509-demo-sesion12 && docker compose down -v
```

### Parte 1 · El artefacto en su computadora

**1. Revisar los archivos (paso 5).** Abran `Dockerfile`,
`src/main/resources/application.yml` y `application-prod.yml`. Qué
observar: dos etapas en la imagen, `server.port: ${PORT:8080}` y ningún
valor secreto, solo `${NOMBRE}`.

**2. Construir la imagen (paso 6).** En la terminal 1:

```bash
docker compose down -v && docker compose up -d && docker build -t eif509-demo-sesion12 .
```

Tarda unos minutos la primera vez (descarga Gradle y las dependencias).

**3. Ejecutar la imagen como lo hará la plataforma (paso 7).** En la
terminal 1:

```bash
docker run --rm --name api-prod -p 10000:10000 -e PORT=10000 -e SPRING_PROFILES_ACTIVE=prod -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/eif509 -e DATABASE_USER=dev -e DATABASE_PASSWORD=dev -e JWT_SECRETO=$(openssl rand -base64 48) -e CORS_ORIGEN=https://eif509-spa.onrender.com eif509-demo-sesion12
```

Qué observar en los registros: `profile is active: "prod"`,
`Successfully applied 7 migrations` y `Tomcat started on port 10000`.

**4. Probar la API (paso 8).** En la terminal 2:

```bash
curl -i http://localhost:10000/api/v1/productos
```

Responde 401. Inicien sesión y repitan con el token:

```bash
TOKEN=$(curl -s -X POST http://localhost:10000/auth/login -H 'Content-Type: application/json' -d '{"correo": "admin@demo.cr", "clave": "admin123"}' | sed 's/.*"token":"\([^"]*\)".*/\1/')
```

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $TOKEN" http://localhost:10000/api/v1/productos
```

Responde 200. Swagger UI está en `http://localhost:10000/swagger-ui.html`.

**5. Qué pasa si falta una variable (paso 9).** En la terminal 1,
presionen `Ctrl+C` y ejecuten:

```bash
docker run --rm -e SPRING_PROFILES_ACTIVE=prod -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/eif509 -e DATABASE_USER=dev -e DATABASE_PASSWORD=dev eif509-demo-sesion12
```

La aplicación no arranca: `Could not resolve placeholder 'JWT_SECRETO'`.
Es el mismo mensaje que verán en los registros de la plataforma.

### Parte 2 · Despliegue en la plataforma

**6. Crear la base de datos (paso 10).** En el panel de Render:
**New → Postgres**. Nombre `eif509-db`, base `eif509`, usuario `eif509`,
versión **16**, plan **Free**. Al crearse, en la pestaña **Info** copien
**Hostname**, **Port**, **Database**, **Username** y **Password**.

**7. Convertir la URL al formato JDBC (paso 11).** Si copiaron la
**Internal Database URL** (`postgresql://usuario:clave@host/base`), en la
terminal 2:

```bash
python3 -c "import sys, urllib.parse as u; p = u.urlparse(sys.argv[1]); print(f'DATABASE_URL=jdbc:postgresql://{p.hostname}:{p.port or 5432}{p.path}'); print(f'DATABASE_USER={p.username}'); print(f'DATABASE_PASSWORD={p.password}')" 'postgresql://usuario:clave@host/base'
```

Reemplacen el último argumento por la URL copiada (entre comillas simples).

**8. Generar el secreto JWT de producción (paso 13).** En la terminal 2:

```bash
openssl rand -base64 48
```

Es un secreto nuevo: no es el de desarrollo ni está en ningún repositorio.

**9. Crear el servicio web (paso 12).** **New → Web Service → Git
Provider**, elijan el repositorio. Nombre `eif509-demo-sesion12`, rama
`main`, lenguaje **Docker**, misma región que la base, plan **Free**.

**10. Configurar las variables (paso 13).** En **Environment Variables**
del mismo formulario, agreguen `SPRING_PROFILES_ACTIVE=prod`,
`DATABASE_URL`, `DATABASE_USER`, `DATABASE_PASSWORD` (paso 7),
`JWT_SECRETO` (paso 8) y `CORS_ORIGEN=https://eif509-spa.onrender.com`.
Pulsen **Deploy Web Service** (o **Create Web Service**, según la versión
del panel).

**11. Leer los registros (paso 14).** En la pestaña **Logs** del
servicio: Gradle compila, se construye la imagen, arranca Spring con el
perfil `prod`, Flyway aplica las 7 migraciones sobre la base vacía y
Tomcat escucha en el puerto 10000.

**12. Probar la URL pública (paso 15).** Si el servicio lleva más de 15
minutos sin tráfico, está suspendido: la primera petición tarda unos dos
minutos (ver «Despertar el servicio en la nube» en «Antes de empezar»).
Abran `https://eif509-demo-sesion12.onrender.com/swagger-ui.html` (también
desde el teléfono). En la terminal 2, con su URL:

```bash
API=https://eif509-demo-sesion12.onrender.com
```

```bash
curl -i $API/api/v1/productos
```

```bash
TOKEN=$(curl -s -X POST $API/auth/login -H 'Content-Type: application/json' -d '{"correo": "admin@demo.cr", "clave": "admin123"}' | sed 's/.*"token":"\([^"]*\)".*/\1/')
```

```bash
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/v1/productos?page=0&size=3"
```

**13. Un cambio y despliegue automático (paso 16).** Editen la
descripción en `src/main/java/cr/una/eif509/demo/DemoApplication.java`
(por ejemplo, agreguen «Desplegada en la nube en la Sesión 12.») y
publiquen:

```bash
git commit -am "Descripción de la API: desplegada en la nube" && git push
```

En la pestaña **Events** aparece el despliegue nuevo; al terminar,
recarguen Swagger UI.

### Al terminar

En la terminal 1, `Ctrl+C` si la imagen sigue en ejecución, y apaguen la
base local:

```bash
docker compose down -v
```

Detengan con `Ctrl+C` el bucle de la terminal 3. El servicio en la nube
queda en ejecución; en el plan gratuito se suspende tras 15 minutos sin
tráfico y despierta con la siguiente petición (tarda uno o dos minutos).

## Instalación y configuración

### 1. Clonar el repositorio

```bash
git clone https://github.com/adriangarro/eif509-demo-sesion12.git
cd eif509-demo-sesion12
```

### 2. Verificar que Docker Desktop está en ejecución

```bash
docker info
```

Si ven `Cannot connect to the Docker daemon`, abran Docker Desktop y
esperen a que termine de iniciar.

### 3. Levantar PostgreSQL

```bash
docker compose up -d
docker ps
```

Deben ver `eif509-demo-sesion12-db-1` en estado `Up`. Si aparece
`port is already allocated`, otra base del curso ocupa el puerto 5432:
deténganla desde su carpeta (por ejemplo,
`cd ../eif509-demo-sesion11 && docker compose stop`) y reintenten.

### 4. Verificar que todo sigue funcionando en desarrollo

```bash
export JWT_SECRETO=$(openssl rand -base64 48)
./gradlew bootRun
```

Sin `SPRING_PROFILES_ACTIVE`, se usa el perfil `dev`
(`spring.profiles.default: dev` en `application.yml`): la base del Docker
Compose y el puerto 8080. Salida esperada:

```text
cr.una.eif509.demo.DemoApplication       : No active profile set, falling back to 1 default profile: "dev"
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/'
```

Detengan la aplicación con `Ctrl+C`. Los perfiles de las demostraciones
anteriores se combinan con `dev`:
`./gradlew bootRun --args='--spring.profiles.active=dev,sin-cors'`.

## Parte 1 · El artefacto y la configuración, en su computadora

### 5. Revisar el Dockerfile y los perfiles

[`Dockerfile`](Dockerfile) es el de la lámina 8:

```dockerfile
# Etapa 1: compilar
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY . .
RUN ./gradlew bootJar --no-daemon -x test

# Etapa 2: ejecutar
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**Qué observar**: la primera etapa compila con el JDK; la segunda copia
solo el JAR a una imagen con el JRE, más pequeña y sin el código fuente ni
Gradle. Las pruebas se omiten (`-x test`) porque ya se ejecutaron en la
integración continua: lo que llega a `main` ya pasó las pruebas.
[`.dockerignore`](.dockerignore) deja fuera `build/`, `.git/` y la SPA.

[`application.yml`](src/main/resources/application.yml) tiene lo común a
todos los ambientes:

```yaml
server:
  port: ${PORT:8080}
jwt:
  secreto: ${JWT_SECRETO}
cors:
  origenes: ${CORS_ORIGEN:http://localhost:5173}
```

[`application-prod.yml`](src/main/resources/application-prod.yml), solo las
diferencias:

```yaml
spring:
  datasource:
    url: ${DATABASE_URL}
    username: ${DATABASE_USER}
    password: ${DATABASE_PASSWORD}
  jpa:
    show-sql: false
logging:
  level:
    root: INFO
```

**Qué observar**: ningún valor secreto aparece en estos archivos, solo los
nombres de las variables. La plataforma asigna el puerto en `PORT`; si la
aplicación escuchara en un puerto fijo, la plataforma no podría dirigirle
el tráfico y respondería 502. Los registros van a la salida estándar y la
plataforma los recolecta: no se escriben archivos en el contenedor, que se
pierden al reiniciarlo. [`application-dev.yml`](src/main/resources/application-dev.yml)
apunta a la base del Docker Compose con las credenciales `dev`/`dev`, que
no existen en ningún otro lugar.

### 6. Construir la imagen

```bash
docker build -t eif509-demo-sesion12 .
```

Salida esperada al final (la primera vez tarda unos minutos):

```text
 => [build 4/4] RUN ./gradlew bootJar --no-daemon -x test
 => [stage-1 3/3] COPY --from=build /app/build/libs/*.jar app.jar
 => => naming to docker.io/library/eif509-demo-sesion12:latest
```

Es exactamente lo que hará la plataforma en cada `push`. Si la
construcción falla aquí, fallará también allá: por eso el CI de este
repositorio también construye la imagen
([`.github/workflows/ci.yml`](.github/workflows/ci.yml), trabajo `imagen`).

### 7. Ejecutar la imagen como lo hará la plataforma

La base del Docker Compose debe estar en ejecución (paso 3). Arranquen el
contenedor con el perfil `prod`, las variables de la tabla y un puerto
distinto al 8080, como haría la plataforma:

```bash
docker run --rm --name api-prod -p 10000:10000 -e PORT=10000 -e SPRING_PROFILES_ACTIVE=prod -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/eif509 -e DATABASE_USER=dev -e DATABASE_PASSWORD=dev -e JWT_SECRETO=$(openssl rand -base64 48) -e CORS_ORIGEN=https://eif509-spa.onrender.com eif509-demo-sesion12
```

Salida esperada:

```text
cr.una.eif509.demo.DemoApplication       : The following 1 profile is active: "prod"
org.flywaydb.core.FlywayExecutor         : Database: jdbc:postgresql://host.docker.internal:5432/eif509 (PostgreSQL 16.15)
o.f.core.internal.command.DbMigrate      : Successfully applied 7 migrations to schema "public", now at version v7
o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 10000 (http) with context path '/'
cr.una.eif509.demo.DemoApplication       : Started DemoApplication in 1.991 seconds
```

**Qué observar**: el mismo artefacto que corre en desarrollo corre aquí con
otra configuración, recibida completa desde el entorno (factor
«configuración» de los doce factores). `host.docker.internal` es la
dirección con la que un contenedor llega a la computadora anfitriona en
Docker Desktop; en la nube, `DATABASE_URL` apunta a la base gestionada.
En Windows (PowerShell), reemplacen `$(openssl rand -base64 48)` por un
texto de 32 caracteres o más.

### 8. Probar la API en el puerto asignado

Desde la **segunda terminal**:

```bash
curl -i http://localhost:10000/api/v1/productos
```

```text
HTTP/1.1 401
WWW-Authenticate: Bearer
Content-Type: application/problem+json;charset=UTF-8

{"type":"https://api.ejemplo.cr/errores/no-autenticado","title":"No autenticado","status":401,"detail":"Se requiere un token válido en la cabecera Authorization.","instance":"/api/v1/productos"}
```

```bash
TOKEN=$(curl -s -X POST http://localhost:10000/auth/login -H 'Content-Type: application/json' -d '{"correo": "admin@demo.cr", "clave": "admin123"}' | sed 's/.*"token":"\([^"]*\)".*/\1/')
curl -s -o /dev/null -w "%{http_code}\n" -H "Authorization: Bearer $TOKEN" http://localhost:10000/api/v1/productos
```

Salida esperada: `200`. Swagger UI está en
`http://localhost:10000/swagger-ui.html`. Es la misma API de la Sesión 11:
solo cambió el puerto, que ahora viene de `PORT`.

El origen de la SPA también viene del entorno. Una petición previa de CORS
desde el origen configurado recibe 200; desde cualquier otro, 403:

```bash
curl -s -o /dev/null -w "%{http_code}\n" -X OPTIONS http://localhost:10000/api/v1/productos -H "Origin: https://eif509-spa.onrender.com" -H "Access-Control-Request-Method: GET"
curl -s -o /dev/null -w "%{http_code}\n" -X OPTIONS http://localhost:10000/api/v1/productos -H "Origin: http://localhost:5173" -H "Access-Control-Request-Method: GET"
```

### 9. Qué pasa cuando falta una variable

Detengan el contenedor (`Ctrl+C` en la primera terminal) y arránquenlo sin
`JWT_SECRETO`:

```bash
docker run --rm -e SPRING_PROFILES_ACTIVE=prod -e DATABASE_URL=jdbc:postgresql://host.docker.internal:5432/eif509 -e DATABASE_USER=dev -e DATABASE_PASSWORD=dev eif509-demo-sesion12
```

```text
***************************
APPLICATION FAILED TO START
***************************
Caused by: java.lang.IllegalArgumentException: Could not resolve placeholder 'JWT_SECRETO' in value "${JWT_SECRETO}"
```

Y con la URL de la base en el formato que entregan algunas plataformas
(`postgres://usuario:clave@host/base`) en lugar del formato JDBC:

```bash
docker run --rm -e SPRING_PROFILES_ACTIVE=prod -e DATABASE_URL=postgres://dev:dev@host.docker.internal:5432/eif509 -e DATABASE_USER=dev -e DATABASE_PASSWORD=dev -e JWT_SECRETO=$(openssl rand -base64 48) eif509-demo-sesion12
```

```text
Failed to instantiate [com.zaxxer.hikari.HikariDataSource]: Factory method 'dataSource' threw exception with message: URL must start with 'jdbc'
```

**Qué observar**: los registros de arranque son el primer lugar donde se
busca la causa. Si la aplicación no arranca en la nube, suele ser una
variable ausente, una URL con el formato incorrecto o una migración
fallida; el mensaje es el mismo que acaban de ver aquí.

## Parte 2 · Despliegue en la plataforma como servicio

Los pasos usan el panel de [Render](https://dashboard.render.com); el
flujo en Railway es equivalente. Para su propio proyecto, el repositorio
debe ser suyo (en GitHub): la plataforma lo lee directamente.

### 10. Crear la base PostgreSQL gestionada

En el panel, **New → Postgres**:

| Campo | Valor |
|---|---|
| Name | `eif509-db` |
| Database | `eif509` |
| User | `eif509` |
| Region | La misma que usarán para el servicio web (por ejemplo, Oregon) |
| PostgreSQL Version | **16** (la misma del `docker-compose.yml`: paridad entre ambientes) |
| Plan | **Free** |

Pulsen **Create Database**. Cuando el estado sea **Available**, en la
pestaña **Info** están los datos de conexión: **Hostname**, **Port**,
**Database**, **Username**, **Password** y las URL **Internal** y
**External**.

**Qué observar**: la base es un servicio de respaldo; la aplicación solo
necesita su URL y sus credenciales. La URL interna sirve para servicios de
la misma región y cuenta (red privada); la externa, para conectarse desde
su computadora, por ejemplo con `psql`.

El plan gratuito de Render permite **una** base PostgreSQL por cuenta,
con 1 GB, y **expira a los 30 días** de creada (con 14 días de gracia para
pasarla a un plan de pago). Anoten la fecha: para el Laboratorio 6, los
servicios deben seguir disponibles hasta que se publique la calificación.
Si necesitan más tiempo, otros proveedores ofrecen PostgreSQL gestionado
gratuito sin vencimiento (por ejemplo, [Neon](https://neon.tech) o
[Supabase](https://supabase.com)); la aplicación no cambia, solo las tres
variables.

### 11. Convertir la URL al formato JDBC

Spring necesita `jdbc:postgresql://host:5432/base`, con el usuario y la
clave en variables separadas. Hay dos formas de obtener los valores:

- Con los campos de la pestaña **Info**:
  `DATABASE_URL=jdbc:postgresql://<Hostname>:<Port>/<Database>`,
  `DATABASE_USER=<Username>` y `DATABASE_PASSWORD=<Password>`.
- A partir de la **Internal Database URL**
  (`postgresql://usuario:clave@host/base`), con este comando:

```bash
python3 -c "import sys, urllib.parse as u; p = u.urlparse(sys.argv[1]); print(f'DATABASE_URL=jdbc:postgresql://{p.hostname}:{p.port or 5432}{p.path}'); print(f'DATABASE_USER={p.username}'); print(f'DATABASE_PASSWORD={p.password}')" 'postgresql://eif509:AbC123xyz@dpg-abc123-a/eif509'
```

```text
DATABASE_URL=jdbc:postgresql://dpg-abc123-a:5432/eif509
DATABASE_USER=eif509
DATABASE_PASSWORD=AbC123xyz
```

Reemplacen el último argumento por su URL, entre comillas simples. El
comando funciona con `postgres://` y con `postgresql://`, y agrega el
puerto 5432 si la URL no lo trae. Es el error más frecuente al conectar con
la base (paso 9): si la aplicación no logra conectarse, revisen primero
este formato.

### 12. Crear el servicio web

**New → Web Service**, opción **Git Provider**. Si es la primera vez,
autoricen a Render para leer sus repositorios de GitHub y elijan el
repositorio.

| Campo | Valor |
|---|---|
| Name | `eif509-demo-sesion12` (forma parte de la URL: `https://eif509-demo-sesion12.onrender.com`) |
| Region | La misma de la base |
| Branch | `main` |
| Language | **Docker** |
| Instance Type | **Free** |

**Qué observar**: con el lenguaje **Docker**, la plataforma construye la
imagen a partir del `Dockerfile` del repositorio en cada `push` a `main`
(**Auto-Deploy** queda activado por defecto). No hay comando de
construcción ni de arranque que escribir: están en el `Dockerfile`.

### 13. Configurar las variables de entorno

En el mismo formulario, sección **Environment Variables**, agreguen una por
una (**Add Environment Variable**):

| Clave | Valor |
|---|---|
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `DATABASE_URL` | El valor del paso 11 |
| `DATABASE_USER` | El valor del paso 11 |
| `DATABASE_PASSWORD` | El valor del paso 11 |
| `JWT_SECRETO` | Un secreto **nuevo**, generado con `openssl rand -base64 48` |
| `CORS_ORIGEN` | La URL de su SPA; si aún no existe, `https://eif509-spa.onrender.com` |

No agreguen `PORT`: Render la define (`10000`) y la aplicación la lee.
Pulsen **Deploy Web Service** (o **Create Web Service**, según la versión
del panel).

**Qué observar**: aquí, y solo aquí, viven los secretos. El secreto JWT de
producción es distinto al de desarrollo y no está en ningún repositorio.
Si más adelante cambian `JWT_SECRETO`, los tokens emitidos antes dejan de
valer: es el comportamiento esperado.

Para proyectos con MongoDB (subdominio de la Sesión 4), agreguen también
`MONGODB_URI` con la cadena de conexión de
[MongoDB Atlas](https://www.mongodb.com/atlas) (`mongodb+srv://...`) y
declárenla en `application-prod.yml` como
`spring.data.mongodb.uri: ${MONGODB_URI}`. Este repositorio no usa MongoDB.

### 14. Seguir los registros de construcción y de arranque

Al crear el servicio se abre la pestaña **Logs**. Lean con el grupo, en
orden:

1. `==> Cloning from https://github.com/...` y la construcción de la
   imagen: la plataforma ejecuta el `Dockerfile`; Gradle descarga las
   dependencias y compila (`RUN ./gradlew bootJar --no-daemon -x test`).
   Tarda varios minutos la primera vez.
2. El arranque: de Spring, `The following 1 profile is active: "prod"`.
3. De Flyway, `Successfully applied 7 migrations to schema "public"`: la
   base gestionada estaba vacía y ahora tiene las mismas tablas y datos
   semilla que la local.
4. `Tomcat started on port 10000`, `Started DemoApplication` y, de la
   plataforma, `==> Your service is live` y
   `==> Available at your primary URL https://eif509-demo-sesion12.onrender.com`.
   En la instancia gratuita (0.1 CPU) el arranque tarda alrededor de dos
   minutos; mientras tanto la plataforma repite
   `==> No open ports detected, continuing to scan...`, lo cual es normal
   hasta que Tomcat abre el puerto.

**Qué observar**: si algo falla, este es el primer lugar donde se busca la
causa (paso 9). La tabla de
[Solución de problemas](#solución-de-problemas) reúne los casos frecuentes.

### 15. Abrir la URL pública

La URL está en la parte superior de la página del servicio.

**Antes de abrirla, verifiquen que el servicio esté despierto.** En el plan
gratuito, tras 15 minutos sin tráfico la plataforma suspende el servicio y
la siguiente petición lo vuelve a arrancar, lo que tarda alrededor de dos
minutos (el navegador muestra una página de espera de Render mientras
tanto). Para no esperar frente al grupo, ejecuten esto un par de minutos
antes:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://eif509-demo-sesion12.onrender.com/api/v1/productos
```

Si responde `401` de inmediato, el servicio está despierto. Si la petición
se queda esperando, está arrancando: en unos dos minutos responde `401` y
desde ese momento todo es inmediato. Repítanlo si pasan más de 15 minutos
sin usar la URL, o dejen el bucle de «Antes de empezar» en ejecución
durante toda la clase.

Abran `https://eif509-demo-sesion12.onrender.com/swagger-ui.html`: la misma
documentación de la Sesión 9, ahora en internet y con HTTPS, que la
plataforma gestiona. Pueden abrirla desde el teléfono.

Desde la terminal, con su URL:

```bash
API=https://eif509-demo-sesion12.onrender.com
curl -i $API/api/v1/productos
```

Salida esperada: `HTTP/2 401` (la plataforma atiende en HTTP/2 y agrega
`strict-transport-security`) y el mismo Problem Details del paso 8. Inicien sesión y consulten con el token:

```bash
TOKEN=$(curl -s -X POST $API/auth/login -H 'Content-Type: application/json' -d '{"correo": "admin@demo.cr", "clave": "admin123"}' | sed 's/.*"token":"\([^"]*\)".*/\1/')
curl -s -H "Authorization: Bearer $TOKEN" "$API/api/v1/productos?page=0&size=3"
```

Salida esperada: la primera página del catálogo. En Swagger UI, ejecuten
`POST /auth/login`, pulsen **Authorize**, peguen el token y prueben
`GET /api/v1/pedidos`.

**Qué observar**: el token funciona igual que en local porque el flujo es
el mismo; lo único distinto es el secreto con el que se firmó. Si la
primera respuesta tarda uno o dos minutos, el plan gratuito había
suspendido el servicio por inactividad y la aplicación está arrancando de
nuevo; las siguientes son normales. Las
mismas peticiones están en [`peticiones/nube.http`](peticiones/nube.http):
cambien el valor de `@host`.

### 16. Un cambio pequeño y el despliegue automático

Editen la descripción de la API en
[`DemoApplication.java`](src/main/java/cr/una/eif509/demo/DemoApplication.java)
(por ejemplo, agreguen al final «Desplegada en la nube en la Sesión 12.»)
y publiquen el cambio:

```bash
git commit -am "Descripción de la API: desplegada en la nube"
git push
```

En la pestaña **Events** del servicio aparece un despliegue nuevo:
construcción de la imagen, arranque y, al terminar, `Live`. Recarguen
Swagger UI: la descripción cambió.

**Qué observar**: cada `push` a `main` genera una versión nueva sin pasos
manuales. Por eso la integración continua debe ejecutar las pruebas antes:
lo que llega a `main` se publica. En este repositorio, el CI de GitHub
Actions ejecuta las 73 pruebas, la regla de cobertura, la SPA y la
construcción de la imagen en cada `push`; en un equipo, la rama `main` se
protege para que solo reciba cambios con el CI en verde.

## La SPA en producción

La SPA es un sitio estático: `npm run build` genera HTML, CSS y JavaScript
que se publican en un servicio de sitios estáticos. En Render, **New →
Static Site** sobre el mismo repositorio:

| Campo | Valor |
|---|---|
| Name | `eif509-spa` (su URL: `https://eif509-spa.onrender.com`) |
| Root Directory | `spa` |
| Build Command | `npm ci && npm run build` |
| Publish Directory | `dist` |
| Environment Variables | `VITE_API_URL` = la URL de la API (sin `/` al final) |

Después de crearlo, en **Redirects/Rewrites** agreguen la regla
**Source** `/*`, **Destination** `/index.html`, **Action** `Rewrite`, para
que las rutas de la SPA (`/login`) funcionen al recargar la página.

Dos aspectos que deben tener presentes:

- Las variables `VITE_` se incorporan al código al construir la SPA y
  cualquier persona puede verlas en el navegador. Nunca deben contener
  secretos; `VITE_API_URL` es pública y no hay problema.
- `CORS_ORIGEN` en la API debe ser exactamente la URL de la SPA
  (`https://eif509-spa.onrender.com`, sin `/` al final). Si la SPA no
  recibe datos, revisen la consola del navegador (`F12`): el mensaje de
  CORS de la Sesión 11 indica que el origen no coincide.

## Secretos en el historial de Git

Borrar un secreto del código en un commit nuevo no lo elimina: sigue en los
commits anteriores para cualquier persona con acceso al repositorio.
Revisen su proyecto antes de desplegar:

```bash
git log -p | grep -i -E "password|secreto|secret|mongodb\+srv" | head
```

Si aparece un valor real, la medida correcta es **cambiar el secreto**
(generar uno nuevo y configurarlo solo en la plataforma); reescribir el
historial no sustituye el cambio, porque alguien pudo haberlo copiado
antes. En la rúbrica del Laboratorio 6, un secreto en uso en producción
que aparezca en el historial califica el criterio de perfiles y secretos
con cero.

## Comandos útiles

| Acción | Comando |
|---|---|
| Levantar la base local | `docker compose up -d` |
| Arrancar en desarrollo (perfil `dev`) | `export JWT_SECRETO=$(openssl rand -base64 48) && ./gradlew bootRun` |
| Construir la imagen | `docker build -t eif509-demo-sesion12 .` |
| Ejecutar la imagen como la plataforma | El comando del paso 7 |
| Generar un secreto JWT | `openssl rand -base64 48` |
| Despertar el servicio en la nube (tarda hasta dos minutos si estaba suspendido) | `curl -s -o /dev/null -w "%{http_code}\n" https://eif509-demo-sesion12.onrender.com/api/v1/productos` |
| Mantenerlo despierto durante la clase | El bucle de «Antes de empezar» |
| Convertir la URL de la base a JDBC | El comando del paso 11 |
| Ver qué contiene la imagen final | `docker run --rm --entrypoint ls eif509-demo-sesion12 -la /app` |
| Swagger UI en local / en la nube | `http://localhost:8080/swagger-ui.html` / `https://<nombre>.onrender.com/swagger-ui.html` |
| Todas las pruebas y cobertura | `./gradlew test` |
| Reiniciar la demo local desde cero | `docker compose down -v && docker compose up -d` |

## Solución de problemas

| Problema | Causa | Solución |
|---|---|---|
| `Could not resolve placeholder 'JWT_SECRETO'` en los registros | Falta la variable en la plataforma (o en el `docker run`) | Agregarla en **Environment** y volver a desplegar |
| `URL must start with 'jdbc'` | `DATABASE_URL` falta o tiene el formato `postgres://` | Convertirla al formato JDBC (paso 11) con usuario y clave en variables separadas |
| `Connection to host:5432 refused` o `password authentication failed` | Host, usuario o clave incorrectos, o la base en otra región | Copiar de nuevo los valores de la pestaña **Info**; usar la misma región |
| La construcción falla con `Permission denied` en `gradlew` | El archivo perdió el permiso de ejecución en Git | `git update-index --chmod=+x gradlew`, commit y push; o agregar `RUN chmod +x ./gradlew` antes de compilar en el `Dockerfile` |
| La plataforma reporta `No open ports detected` o responde 502 | La aplicación todavía está arrancando (normal durante unos dos minutos en la instancia gratuita) o no escucha en el puerto de `PORT` | Esperar a `Tomcat started on port 10000`; si nunca aparece, verificar `server.port: ${PORT:8080}` en `application.yml` |
| Flyway falla al migrar (`Migration V... failed`) | Un script con error, o una base que quedó a medias | Leer el script y la línea en el mensaje; en la demostración, recrear la base vacía |
| La primera respuesta tarda uno o dos minutos | El plan gratuito suspendió el servicio por inactividad | Es esperable; las siguientes respuestas son normales |
| Los tokens dejan de funcionar tras un despliegue | `JWT_SECRETO` cambió entre despliegues | Mantener el secreto estable en la plataforma |
| La SPA no recibe datos | `CORS_ORIGEN` no coincide con la URL real de la SPA, o `VITE_API_URL` es incorrecta | Revisar la consola del navegador y ambas variables |
| `docker build` falla por falta de espacio o memoria | Imágenes antiguas acumuladas | `docker system prune` y reintentar |
| En Linux, el contenedor no encuentra `host.docker.internal` | Solo Docker Desktop define ese nombre | Agregar `--add-host=host.docker.internal:host-gateway` al `docker run` |
| `Bind for 0.0.0.0:5432 failed: port is already allocated` | Otra base del curso usa el puerto | `docker ps` para ver cuál y `docker compose stop` desde su carpeta |
| `Unable to locate a Java Runtime` | Falta el JDK o `JAVA_HOME` | Ver Requisitos previos |

## Relación con los laboratorios

**Laboratorio 6** (se asigna hoy; entrega el jueves 22 de octubre a las
6:00 p. m.): este repositorio cubre los criterios de **despliegue en la
nube** (2.5 puntos: API y base de datos en servicios gestionados, Flyway en
el arranque y Swagger UI disponible) y de **perfiles y secretos** (1 punto:
perfiles `dev` y `prod`, todos los secretos en variables de entorno de la
plataforma, ninguno en el repositorio ni en su historial, y un secreto JWT
de producción distinto al de desarrollo). En el taller de hoy, creen su
servicio y su base, configuren las variables de su proyecto y dejen la API
en proceso de despliegue; la SPA puede publicarse la próxima semana. Las
URL públicas y las credenciales de los usuarios de prueba se registran en
el aula virtual el día de la entrega.

---

> **Material de referencia del curso.** La configuración de despliegue de
> su laboratorio debe corresponder a su propio proyecto y a sus propios
> servicios; no copien este ejemplo.
