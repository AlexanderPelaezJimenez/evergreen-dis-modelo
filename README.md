# EverGreen · Macroproceso de Distribución [DIS]

Modelo de dominio de 22 entidades del macroproceso de Distribución del caso EverGreen, y
una **aplicación completa generada a partir de él con Telosys 4.3**: base de datos
PostgreSQL, API REST en Spring Boot y aplicación web en Angular.

Ningún archivo de la aplicación está escrito a mano. Lo que se versiona en este
repositorio son las **fuentes del generador** (el modelo, las plantillas y la
configuración); el código se reconstruye con los comandos de esta guía.

> **Este repositorio se comparte entre varios sistemas operativos.** No contiene rutas
> absolutas: los comandos de Telosys se ejecutan **siempre desde la raíz del repositorio**,
> porque las rutas relativas de la configuración se resuelven contra el directorio actual.

## Requisitos previos

| Herramienta | Versión | Para qué |
|---|---|---|
| **JDK** | 17 | Ejecutar el CLI de Telosys y compilar la API |
| **Telosys CLI** | 4.3.0-001 | Validar el modelo (`cm`) y generar (`gen`) |
| **Maven** | 3.9.x | Compilar y ejecutar la API |
| **Node.js** | 20.19+, 22.12+ o 24+ | Compilar y ejecutar la SPA (Angular 21) |
| **Podman** o **Docker** | cualquiera reciente | Levantar PostgreSQL 16 |

No hace falta instalar PostgreSQL de forma nativa. Telosys CLI se descarga de
[telosys.org](https://www.telosys.org/) y se ejecuta con `./telosys` en macOS/Linux o
`telosys.bat` en Windows.

Verificación rápida: `java -version`, `mvn -version`, `node --version`,
`podman --version` (o `docker --version`).

## Estructura del repositorio

```
.
├── docs/                              Análisis del caso, decisiones, trazabilidad, guion
├── evergreen-dis-modelo/              PROYECTO 1 · el modelo y sus artefactos
│   ├── TelosysTools/
│   │   ├── models/dis_dominio/        ← FUENTE DE VERDAD: los 22 archivos .entity
│   │   └── templates/                 database-sql-scripts, model-doc, java-jpa-entities
│   ├── db/                            Semilla y consultas SQL (escritas a mano)
│   └── docker-compose.yml             PostgreSQL 16 (compatible con Podman y Docker)
├── evergreen-dis-api/                 PROYECTO 2 · API REST
│   └── TelosysTools/                  Configuración + bundle java-rest-springboot-jpa-basic
└── evergreen-dis-web/                 PROYECTO 3 · aplicación web
    └── TelosysTools/                  Configuración + bundle front-angular
```

Los tres proyectos comparten **un solo modelo**: los proyectos 2 y 3 apuntan al del
proyecto 1 mediante `SpecificModelsFolder`, así que el modelo no se duplica. La
justificación de esta separación está en [`docs/decisiones.md`](docs/decisiones.md).

**Lo que no está en el repositorio:** el código generado (`sql/`, `model-doc/`, `src/`,
`pom.xml`, `package.json`, `angular.json`, `target/`, `node_modules/`). Es una decisión
explícita del proyecto: se versiona el modelo y las plantillas, no sus resultados. Ver
[`docs/decisiones.md`](docs/decisiones.md).

## Reproducir la aplicación desde cero

### Camino corto: `deploy.sh`

El script `deploy.sh` en la raíz automatiza todo el pipeline:

```bash
./deploy.sh check        # verifica las herramientas
./deploy.sh all          # limpia, genera los 3 proyectos y levanta la base
./deploy.sh api          # API en :8000   (en su propia terminal)
./deploy.sh web          # SPA en :4200   (en otra terminal)
./deploy.sh verify       # comprueba que base, API, Swagger y SPA responden
```

Otros comandos: `generate`, `db`, `clean` (borra el código generado sin tocar el modelo ni
las plantillas) y `reset-db` (recrea la base perdiendo los datos).

Si el CLI de Telosys no está en `~/tools/telosys-cli/telosys`, indicar la ruta:
`TELOSYS_CLI=/ruta/al/telosys ./deploy.sh all`.

El script detecta solo si usar Podman o Docker. `api` y `web` quedan en primer plano a
propósito, para poder ver sus logs.

Las secciones siguientes explican los mismos pasos a mano, que es lo que conviene entender
antes de confiar en el script.

### Paso 1 · Generar los tres proyectos

Abrir el CLI de Telosys **parado en la raíz del repositorio** y ejecutar:

```
h evergreen-dis-modelo
m dis_dominio
cm
b database-sql-scripts
gen * * -y
b model-doc
gen * * -y
b java-jpa-entities
gen * * -y

h evergreen-dis-api
m dis_dominio
cm
b java-rest-springboot-jpa-basic
gen * * -y

h evergreen-dis-web
m dis_dominio
cm
b front-angular
gen * * -r -y
```

`cm` debe responder `Model OK ('dis_dominio' loaded : 22 entities)` en los tres proyectos.
Al terminar quedan generados **82 + 115 + 179 archivos, sin errores**.

Dos detalles que no son opcionales:

- **El `-r` del frontend es obligatorio.** Copia los recursos estáticos
  (`package.json`, `angular.json`, los `tsconfig`, `public/`). Sin él se generan los
  archivos de código pero el proyecto Angular no compila porque falta `package.json`.
- **No ejecutar `ib`.** Los bundles ya están en el repositorio y **dos de ellos tienen
  plantillas adaptadas**. Reinstalarlos desde el depot traería las versiones originales y
  la aplicación dejaría de funcionar (ver la sección de adaptaciones más abajo).

> Atajo para macOS/Linux, sin abrir el modo interactivo:
> ```bash
> CLI=/ruta/a/telosys-cli/telosys
> printf 'h evergreen-dis-modelo\nm dis_dominio\ncm\nb database-sql-scripts\ngen * * -y\nb model-doc\ngen * * -y\nb java-jpa-entities\ngen * * -y\nh evergreen-dis-api\nm dis_dominio\nb java-rest-springboot-jpa-basic\ngen * * -y\nh evergreen-dis-web\nm dis_dominio\nb front-angular\ngen * * -r -y\nexit\n' | "$CLI"
> ```

### Paso 2 · Levantar PostgreSQL

Requiere el Paso 1: el `docker-compose.yml` monta el DDL generado.

```bash
cd evergreen-dis-modelo
podman compose up -d          # o: docker compose up -d
```

La primera vez ejecuta en orden el esquema generado por Telosys (22 tablas, 26 FKs), los
catálogos y el escenario de prueba de la finca La Esperanza.

Con Podman, si la máquina virtual está apagada: `podman machine start`.

### Paso 3 · API REST

```bash
cd evergreen-dis-api
mvn spring-boot:run
```

Queda en `http://localhost:8000` con 44 endpoints (CRUD de las 22 entidades) y Swagger UI
en `http://localhost:8000/swagger-ui/index.html`.

### Paso 4 · Aplicación web

```bash
cd evergreen-dis-web
npm install
npm start
```

Queda en `http://localhost:4200`.

Si el CLI de Angular pide consentimiento de telemetría y bloquea el arranque:
`npx ng analytics disable --global`.

**El orden importa.** Sin la base la API no arranca; sin la API la web carga pero no
muestra ni guarda datos, y el síntoma es confuso.

### Para empezar de cero con los datos

```bash
cd evergreen-dis-modelo
podman compose down -v && podman compose up -d    # -v borra el volumen de datos
```

## Qué se genera a partir del modelo

| Proyecto | Bundle | Salida |
|---|---|---|
| modelo | `database-sql-scripts` | DDL para PostgreSQL, MySQL, SQLite y SQL Server |
| modelo | `model-doc` | Diagrama de clases (Mermaid y PlantUML) y documentación HTML |
| modelo | `java-jpa-entities` | 22 entidades JPA con sus pruebas |
| api | `java-rest-springboot-jpa-basic` | Entidades JPA, repositorios Spring Data, DTOs, servicios, 22 controladores REST, `application.yml`, `pom.xml` |
| web | `front-angular` | Por entidad: listado, formulario, servicio HTTP, rutas y modelo TypeScript; más el layout, la portada y el proyecto Angular |

## Cómo evolucionar el modelo

1. Editar el `.entity` en `evergreen-dis-modelo/TelosysTools/models/dis_dominio/`.
2. Validar con `cm` (debe seguir devolviendo `Model OK`).
3. Repetir el Paso 1 en los proyectos afectados.
4. Si cambió el esquema, recrear la base: `podman compose down -v && podman compose up -d`.

Ver [`docs/act19-evolucion.md`](docs/act19-evolucion.md) para un ejemplo cronometrado.

**Nunca editar el código generado.** Un cambio ahí se pierde en la siguiente generación.
Según el caso, la corrección va en el modelo, en una plantilla o en `telosys-tools.cfg`.

## Bundles adaptados

Los bundles vienen del depot oficial `github_org:telosys-templates-v4-3` y **fueron
modificados**: 12 plantillas y 2 recursos estáticos. Cada cambio lleva un comentario de una
línea con el prefijo `EverGreen:` que identifica la divergencia.

Sin esas adapt3aciones la aplicación no funciona: 16 de las 22 rutas GET devolvían HTTP 500,
el navegador bloqueaba todas las llamadas por CORS, y era imposible crear registros porque
el botón de guardar quedaba deshabilitado.

El detalle completo, con el problema y la corrección de cada una, está en
[`docs/decisiones.md`](docs/decisiones.md). Por eso `TelosysTools/templates/` está
versionado y por eso no se debe ejecutar `ib`.

## Limitaciones conocidas

- **La API generada no tiene autenticación.** Expone CRUD completo, incluidos DELETE, sin
  ninguna capa de seguridad. Sirve para una demostración local; no debe exponerse en red.
- **Los errores de integridad llegan como HTTP 500** en lugar de 400 o 409, porque el
  bundle no genera manejo de excepciones. La integridad sí se cumple: PostgreSQL rechaza
  el dato y no queda basura.

## Convención de commits

```
modelo(<entidad>): <cambio>          para el modelo
plantilla(<bundle>): <cambio>        para las adaptaciones de bundles
```

Ejemplos: `modelo(Pedido): agregar atributo prioridad`,
`plantilla(front-angular): desplegables para claves foraneas`

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/plan_final_v2.md`](docs/plan_final_v2.md) | Plan de implementación del modelo |
| [`docs/analisis-caso.md`](docs/analisis-caso.md) | Los 17 hallazgos del caso original, con evidencia |
| [`docs/diccionario-datos.md`](docs/diccionario-datos.md) | Diccionario de datos de las 22 entidades |
| [`docs/matriz-trazabilidad.md`](docs/matriz-trazabilidad.md) | Caso → modelo → tabla física |
| [`docs/decisiones.md`](docs/decisiones.md) | Decisiones de diseño y adaptaciones de bundles |
| [`docs/lista-chequeo-modelo.md`](docs/lista-chequeo-modelo.md) | Checklist semántico de 20 puntos |
| [`docs/prueba-escritorio-act13.md`](docs/prueba-escritorio-act13.md) | Escenario de negocio y las 10 preguntas de prueba |
| [`docs/bitacora-errores.md`](docs/bitacora-errores.md) | Errores y fricciones encontradas |
| [`docs/guion-sustentacion.md`](docs/guion-sustentacion.md) | Guion de sustentación |
| [`docs/act19-evolucion.md`](docs/act19-evolucion.md) | Ejercicio de evolución del modelo |
