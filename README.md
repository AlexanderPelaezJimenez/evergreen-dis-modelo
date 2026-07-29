# EverGreen — Modelo de dominio del macroproceso de Distribución [DIS]

Modelo de dominio (22 entidades) del macroproceso de Distribución del caso EverGreen, implementado y validado en Telosys 4.3, con generación de DDL (PostgreSQL/MySQL/SQLite/SQL Server), diagrama de clases y clases JPA, más una base de datos PostgreSQL de prueba orquestada con Docker.

Ver el plan completo en [`docs/plan_final_v2.md`](docs/plan_final_v2.md) y el resto de la documentación de soporte en [`docs/`](docs/).

> **Este repositorio se comparte entre varios sistemas operativos.** Todos los comandos de esta guía están probados; las diferencias por SO están marcadas explícitamente donde aplican.

## Requisitos previos

| Herramienta | Para qué | Notas por SO |
|---|---|---|
| **Java 17+** (JDK) | Correr el CLI de Telosys | Windows/macOS/Linux: cualquier distribución (Temurin, Homebrew, etc.) sirve. Verificar con `java -version`. |
| **Telosys CLI 4.3.x** | Modelar, validar (`cm`) y generar (`gen`) | Descargar de [telosys.org](https://www.telosys.org/). En macOS/Linux se ejecuta con `./telosys`; en Windows con `telosys.bat`. |
| **Docker Desktop** | Levantar PostgreSQL para probar el modelo con datos reales | En Windows, usar el backend **WSL2** (opción por defecto en instalaciones recientes). En macOS, la versión para Apple Silicon o Intel según corresponda. |

No hace falta instalar PostgreSQL, Maven ni nada más de forma nativa: todo lo demás corre dentro de Docker o se genera con Telosys.

## Estructura del repositorio

```
.
├── docs/                          # Plan, hallazgos, decisiones, diccionario de datos, etc.
└── evergreen-dis-modelo/
    ├── TelosysTools/
    │   ├── models/dis_dominio/    # ← FUENTE DE VERDAD: los 22 archivos .entity
    │   └── templates/             # Bundles de Telosys instalados (versionados para no depender del depot)
    ├── db/
    │   ├── init/                  # Scripts que Postgres corre al arrancar (schema + semilla + escenario)
    │   └── queries/                # Las 10 consultas de negocio de prueba
    ├── docker-compose.yml         # Levanta PostgreSQL 16 con todo precargado
    ├── sql/                       # GENERADO por Telosys — no está en git, se reconstruye (ver abajo)
    ├── model-doc/                 # GENERADO por Telosys — no está en git, se reconstruye
    ├── src/                       # GENERADO por Telosys (clases JPA) — no está en git, se reconstruye
    └── pom.xml                    # GENERADO por Telosys — no está en git, se reconstruye
```

**Por qué el código generado no está en el repo:** es una decisión explícita del proyecto (ver [`docs/decisiones.md`](docs/decisiones.md)). Se versiona el modelo (`TelosysTools/models/`) y los templates instalados (`TelosysTools/templates/`), no sus resultados — así el repo no arrastra artefactos que puedan quedar desincronizados del modelo, y cualquiera los reconstruye idénticos con los comandos de abajo, sin importar su sistema operativo.

## Cómo levantar el proyecto desde cero

### Paso 1 — Clonar y entrar al proyecto del modelo

```bash
git clone <url-del-repo>
cd final_ind_software/evergreen-dis-modelo
```

### Paso 2 — Instalar Telosys CLI

Descomprimir el CLI de Telosys en cualquier carpeta (fuera del repo) y verificar que funciona:

```bash
# macOS / Linux
./telosys ver

# Windows
telosys.bat ver
```

Debe responder con la versión (`4.3.0-...`). El resto de esta guía asume que se ejecuta el CLI **desde dentro de `evergreen-dis-modelo/`**, fijando esa carpeta como HOME de Telosys (`h .`).

### Paso 3 — Regenerar los artefactos del modelo (DDL, diagrama, clases Java)

Abrir el CLI interactivo de Telosys (`./telosys` en macOS/Linux, `telosys.bat` en Windows) parado dentro de `evergreen-dis-modelo/`, y escribir:

```
h .
m dis_dominio
cm
b database-sql-scripts
gen * *
y
b model-doc
gen * *
y
b java-jpa-entities
gen * *
y
```

- `cm` debe responder `Model OK ('dis_dominio' loaded : 22 entities)`.
- Al terminar quedan generados `sql/`, `model-doc/` y `src/` + `pom.xml`.
- Los bundles (`database-sql-scripts`, `model-doc`, `java-jpa-entities`) ya están instalados en `TelosysTools/templates/` (vienen en el repo), así que este paso funciona **sin conexión a internet**.

> Atajo para macOS/Linux (ejecuta lo mismo sin abrir el modo interactivo a mano):
> ```bash
> RUTA_TELOSYS=/ruta/a/telosys-cli/telosys
> printf 'h .\nm dis_dominio\ncm\nb database-sql-scripts\ngen * *\ny\nb model-doc\ngen * *\ny\nb java-jpa-entities\ngen * *\ny\nexit\n' | "$RUTA_TELOSYS"
> ```

### Paso 4 — Levantar la base de datos (requiere el Paso 3 primero)

`docker-compose.yml` monta `sql/postgresql-create-tables.sql`, así que **debe existir antes** de este paso.

```bash
docker compose up -d
```

Esto levanta PostgreSQL 16 y, la primera vez, ejecuta en orden:

1. `sql/postgresql-create-tables.sql` (esquema, 22 tablas)
2. `db/init/02-seed-catalogos.sql` (catálogos: unidades, estados, categorías, tipos de tarea, tipos de empaque, canales)
3. `db/init/03-escenario-act13.sql` (el escenario de prueba de la finca La Esperanza)

### Paso 5 — Probar con las 10 preguntas de negocio

```bash
docker compose exec -T db psql -U evergreen -d evergreen_dis < db/queries/10-preguntas-negocio.sql
```

### Para empezar de cero (borrar los datos y volver a cargar)

```bash
docker compose down -v   # -v borra tambien el volumen de datos
docker compose up -d
```

## Cómo evolucionar el modelo

1. Editar el `.entity` correspondiente en `TelosysTools/models/dis_dominio/`.
2. Validar: `cm` (debe seguir devolviendo `Model OK`).
3. Regenerar (repetir el Paso 3 de arriba, o solo la entidad afectada con `gen <Entidad> *`).
4. Si el cambio afecta el schema, recrear la base: `docker compose down -v && docker compose up -d`.

Ver [`docs/act19-evolucion.md`](docs/act19-evolucion.md) para un ejemplo real cronometrado.

## Convención de commits

```
modelo(<entidad>): <cambio>
```

Ejemplo: `modelo(Pedido): agregar atributo prioridad`

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/plan_final_v2.md`](docs/plan_final_v2.md) | Plan completo de implementación |
| [`docs/analisis-caso.md`](docs/analisis-caso.md) | Los 17 hallazgos del caso original, con evidencia |
| [`docs/diccionario-datos.md`](docs/diccionario-datos.md) | Diccionario de datos de las 22 entidades |
| [`docs/matriz-trazabilidad.md`](docs/matriz-trazabilidad.md) | Caso → modelo → tabla física |
| [`docs/decisiones.md`](docs/decisiones.md) | Decisiones de diseño y su alternativa descartada |
| [`docs/lista-chequeo-modelo.md`](docs/lista-chequeo-modelo.md) | Checklist semántico de 20 puntos |
| [`docs/prueba-escritorio-act13.md`](docs/prueba-escritorio-act13.md) | Escenario de negocio y las 10 preguntas de prueba |
| [`docs/bitacora-errores.md`](docs/bitacora-errores.md) | Errores y fricciones encontradas durante la implementación |
| [`docs/guion-sustentacion.md`](docs/guion-sustentacion.md) | Guion de 12 minutos para la sustentación |
