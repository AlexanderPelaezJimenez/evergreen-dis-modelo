# Plan de la Aplicación de Demostración — Modelo de Dominio [DIS]
## Caso EverGreen · App en Python (Streamlit) para ingresar datos y demostrar el modelo en vivo

| Campo | Valor |
|---|---|
| **Documento** | `plan_app.md` |
| **Depende de** | `plan_final_v2.md` (modelo de 22 entidades ya validado, base PostgreSQL corriendo en Docker) |
| **Alcance** | Una aplicación Streamlit que lee y escribe directamente sobre la base `evergreen_dis`, para insertar datos por formulario y demostrar en vivo que el modelo funciona, incluyendo el rechazo de datos inválidos |
| **Fuera de alcance** | Autenticación de usuarios, despliegue en un servidor, edición del modelo Telosys desde la app |
| **Stack** | Python 3.11+, Streamlit, psycopg2 (SQL directo, sin ORM) |
| **Entregable final** | Carpeta `evergreen-dis-modelo/app/` funcional + guion de demostración en vivo (Parte IV de este documento) |

---

# TABLA DE CONTENIDO

1. [Parte I — Objetivo y alcance](#parte-i--objetivo-y-alcance)
2. [Parte II — Arquitectura de la aplicación](#parte-ii--arquitectura-de-la-aplicación)
3. [Parte III — Actividades de implementación](#parte-iii--actividades-de-implementación)
4. [Parte IV — Guion de demostración en vivo](#parte-iv--guion-de-demostración-en-vivo)
5. [Parte V — Cronograma](#parte-v--cronograma)
6. [Anexos](#anexos)

---

# PARTE I — Objetivo y alcance

## 1.1. Por qué esta aplicación

Hasta ahora, la prueba de que el modelo de 22 entidades funciona vive en tres lugares: scripts SQL (`db/init/`, `db/queries/`), comandos de `psql` ejecutados a mano, y documentos (`docs/prueba-escritorio-act13.md`). Eso es suficiente para verificar, pero **no es demostrable en vivo de forma cómoda** frente a un público: requiere escribir SQL en una terminal mientras se explica.

Esta aplicación traduce esas mismas pruebas a una interfaz visual: formularios para insertar datos (que respetan — o intencionalmente violan — las reglas del modelo), y paneles que corren las consultas de negocio y muestran resultados. El objetivo no es construir un sistema de producción; es dar un **instrumento de demostración** que haga tangible, en segundos y sin escribir una sola línea de SQL frente al público, todo lo que se validó en `plan_final_v2.md`.

## 1.2. Principio de diseño

**La aplicación no reemplaza al modelo, lo expone.** No va a tener lógica de negocio propia más allá de la mínima necesaria para armar un formulario (por ejemplo, calcular un subtotal). Las reglas reales — qué es obligatorio, qué referencia a qué, qué se rechaza — las sigue imponiendo PostgreSQL exactamente como quedaron definidas en el DDL generado por Telosys. Si la aplicación tuviera su propia validación duplicada, una demostración de "esto se rechaza" solo probaría que el formulario de Python funciona, no que el modelo de datos es correcto.

Por eso las inserciones se hacen con SQL parametrizado explícito (no un ORM que abstraiga el error), y los errores de PostgreSQL se muestran tal cual en la interfaz.

## 1.3. Qué se puede demostrar al terminar

| Capacidad | Hallazgo/mejora que evidencia |
|---|---|
| Crear un pedido con varias líneas de productos distintos | H05 / M04 (`LineaPedido` resuelve la M:N) |
| Crear tareas de preparación ancladas a un pedido, con su especialización (Empaque o Separación) | H06 / M05 (jerarquía de tareas ya no está huérfana) |
| Agrupar varios pedidos en un mismo envío | H13 / M13 (`Envio`) |
| Registrar una entrega con novedad | H17 / M17 (`Entrega`) |
| Intentar insertar datos inválidos y ver el error real de PostgreSQL | H01, H05, H06, H14 (integridad estructural) |
| Correr las 10 preguntas de negocio y ver resultados | Criterio de éxito de ACT-16 |

---

# PARTE II — Arquitectura de la aplicación

## 2.1. Decisiones de stack (con alternativa descartada)

| Decisión | Alternativa descartada | Por qué |
|---|---|---|
| **Streamlit** para la interfaz | Flask/Django + HTML a mano | Streamlit genera formularios y tablas con muy poco código, y es una herramienta que ya conoces como científico de datos. Para una demo de una sesión, construir vistas HTML a mano es esfuerzo que no se traduce en una mejor demostración. |
| **psycopg2 con SQL explícito** para hablar con la base | Un ORM (SQLAlchemy ORM, Peewee) | El objetivo es demostrar que **PostgreSQL** rechaza datos inválidos, no que una capa de Python los intercepta antes de llegar a la base. Con SQL directo, el mensaje de error que se muestra en pantalla es literalmente el que emite el motor, lo cual es más convincente en una sustentación. |
| **Conexión por variables de entorno** (`.env`, no committeado) | Credenciales hardcodeadas en el código | Mismas buenas prácticas que ya aplicamos en `docker-compose.yml`; además así cada compañero puede apuntar la app a su propio contenedor Docker sin tocar código. |
| La app vive en `evergreen-dis-modelo/app/`, no en un repo aparte | Repositorio separado para la app | La app no tiene sentido sin el modelo y la base que la sustentan; mantenerla en el mismo repo evita que alguien la clone sin el resto del proyecto. |

## 2.2. Estructura de carpetas propuesta

```
evergreen-dis-modelo/
└── app/
    ├── app.py                  # Punto de entrada de Streamlit (navegacion entre paginas)
    ├── db.py                   # Conexion a Postgres + helpers (ejecutar query, ejecutar insert)
    ├── paginas/
    │   ├── catalogos.py        # Ver catalogos cargados (solo lectura)
    │   ├── nuevo_pedido.py     # Formulario: Cliente/Direccion + Pedido + N lineas
    │   ├── tareas.py           # Formulario: Tarea + Empaque/Separacion
    │   ├── envio_entrega.py    # Formulario: Envio (agrupa pedidos) + Entrega
    │   ├── consultas_negocio.py# Las 10 preguntas de negocio, en tablas y graficos simples
    │   └── romper_el_modelo.py # Botones que intentan inserts invalidos a proposito
    ├── requirements.txt
    ├── .env.example            # Plantilla de variables de conexion (se copia a .env, que NO se sube)
    └── README.md                # Como correr la app (2-3 comandos)
```

## 2.3. Conexión a la base de datos

La app se conecta al mismo contenedor Docker que ya existe (`docker-compose.yml`, servicio `db`, puerto `5432`, base `evergreen_dis`, usuario `evergreen`). No se crea infraestructura nueva.

```
# .env.example
DB_HOST=localhost
DB_PORT=5432
DB_NAME=evergreen_dis
DB_USER=evergreen
DB_PASSWORD=evergreen
```

`db.py` centraliza dos funciones nada más: una para `SELECT` (devuelve filas para tablas/formularios) y otra para `INSERT`/`UPDATE` que **no atrapa la excepción de psycopg2** — la deja subir hasta la página de Streamlit correspondiente, que la muestra en pantalla con `st.error(...)`. Esa decisión es a propósito: es la forma más directa de que la demostración de un error de integridad muestre el mensaje real de PostgreSQL.

## 2.4. Relación con lo que ya existe

| Componente ya construido | Cómo lo usa la app |
|---|---|
| `docker-compose.yml` + `db/init/*.sql` | La app asume que la base ya está arriba (`docker compose up -d`) y con los catálogos + escenario de ACT-13 cargados |
| `db/queries/10-preguntas-negocio.sql` | Las 10 consultas se reutilizan tal cual en `paginas/consultas_negocio.py`, no se reescriben |
| Esquema generado por Telosys (`sql/postgresql-create-tables.sql`) | Define exactamente qué columnas y restricciones tienen los formularios que enviar — la app no inventa reglas nuevas |

---

# PARTE III — Actividades de implementación

## ACT-A1 · Preparar el entorno de la app
**Objetivo:** tener Python, Streamlit y el driver de PostgreSQL listos.
**Precondición:** el proyecto `evergreen-dis-modelo` con la base de datos corriendo (`docker compose up -d`).
**Tiempo estimado:** 20 min

**Pasos**
1. Crear un entorno virtual dentro de `app/` (`python -m venv .venv`).
2. `requirements.txt` con: `streamlit`, `psycopg2-binary`, `python-dotenv`, `pandas` (para tablas y el gráfico simple de la pregunta 8).
3. Instalar: `pip install -r requirements.txt`.
4. Copiar `.env.example` a `.env` y ajustar si el puerto de Docker no es el default.

**Verificación**
- [ ] `streamlit hello` corre sin errores (confirma que Streamlit está bien instalado).
- [ ] Un script mínimo de prueba se conecta a `evergreen_dis` con `psycopg2.connect(...)` y hace un `SELECT 1`.

---

## ACT-A2 · Página de catálogos (solo lectura)
**Objetivo:** primera pantalla de la app; confirma visualmente que la base tiene los datos semilla.
**Precondición:** ACT-A1.
**Tiempo estimado:** 30 min

**Contenido**
- Un `st.selectbox` para elegir el catálogo (`UnidadMedida`, `EstadoPedido`, `CategoriaProducto`, `TipoTarea`, `TipoEmpaque`, `CanalComercializacion`).
- Debajo, un `st.dataframe` con el `SELECT * FROM <tabla>` correspondiente.

**Verificación**
- [ ] Los 6 catálogos se pueden consultar y muestran las filas cargadas por `db/init/02-seed-catalogos.sql`.

---

## ACT-A3 · Formulario: nuevo Pedido con líneas ⭐
**Objetivo:** demostrar en vivo la resolución de la relación M:N `Pedido`–`Producto` (H05).
**Precondición:** ACT-A2.
**Tiempo estimado:** 1 h 30 min

Esta es la actividad más importante de la app — es el equivalente en interfaz de lo que `LineaPedido` resuelve en el modelo.

**Pasos**
1. Formulario superior para los datos del `Pedido`: cliente (dropdown poblado desde `dis_cliente`), dirección de entrega (dropdown filtrado por el cliente elegido), canal, fecha de compromiso.
2. Debajo, una sección repetible ("Agregar línea") donde cada línea permite elegir producto, lote (opcional), cantidad, unidad y precio unitario — usando `st.session_state` para mantener la lista de líneas mientras se arma el pedido.
3. Botón "Guardar pedido": inserta primero el `Pedido`, obtiene su `id` con `RETURNING id`, e inserta cada línea con ese `pedido_id`.
4. Mostrar confirmación con el resumen del pedido creado.

**Verificación**
- [ ] Se puede crear un pedido con 2 o más productos distintos en una sola operación desde la interfaz.
- [ ] El pedido y sus líneas aparecen correctamente en `dis_pedido` / `dis_linea_pedido` (verificar con `psql` una vez).

---

## ACT-A4 · Formulario: Tareas de preparación (Empaque / Separación)
**Objetivo:** demostrar que la jerarquía de tareas quedó anclada al pedido (H06) y que la especialización PK=FK funciona con datos reales.
**Precondición:** ACT-A3.
**Tiempo estimado:** 1 h

**Pasos**
1. Dropdown para elegir un pedido existente.
2. Dropdown para el tipo de tarea (`SEPARACION`, `EMPAQUE`, `ROTULADO`, `CARGUE`).
3. Si el tipo es `SEPARACION` o `EMPAQUE`, mostrar dinámicamente los campos adicionales correspondientes (lote+cantidad+unidad, o tipo de empaque+cantidad+tamaño).
4. Al guardar: insertar primero en `dis_tarea` (`RETURNING id`), y con ese `id` insertar en `dis_separacion` o `dis_empaque` según corresponda.

**Verificación**
- [ ] Se puede registrar una tarea de separación y una de empaque sobre el mismo pedido.
- [ ] Intentar guardar una tarea de tipo `EMPAQUE` sin completar el sub-formulario de empaque debe fallar de forma visible (por la restricción `NOT NULL` real de la tabla, no por validación de Python).

---

## ACT-A5 · Formulario: Envío y Entrega
**Objetivo:** demostrar que un envío agrupa varios pedidos (H13) y que existe evidencia de entrega (H17).
**Precondición:** ACT-A3.
**Tiempo estimado:** 45 min

**Pasos**
1. Formulario para crear un `Envio` (transportador/transporte existente, fecha programada).
2. Un multiselect de pedidos sin envío asignado (`WHERE envio_id IS NULL`); al guardar, hace `UPDATE dis_pedido SET envio_id = ...` para cada uno seleccionado.
3. Formulario separado para registrar una `Entrega` sobre un pedido ya despachado, incluyendo el caso "con novedad".

**Verificación**
- [ ] Un mismo envío puede terminar agrupando 2 o más pedidos elegidos en la interfaz.
- [ ] Una entrega con novedad marcada queda visible luego en la página de consultas de negocio (pregunta #9).

---

## ACT-A6 · Panel de consultas de negocio
**Objetivo:** mostrar, con un clic, que el modelo responde las 10 preguntas de negocio de ACT-13/16.
**Precondición:** ACT-A2.
**Tiempo estimado:** 45 min

**Pasos**
1. Reutilizar textualmente las 10 consultas de `db/queries/10-preguntas-negocio.sql` (no reescribirlas).
2. Cada pregunta en su propio `st.expander`, con el enunciado en lenguaje natural arriba y el resultado (`st.dataframe`) debajo.
3. Para la pregunta 8 ("qué transportador mueve más peso"), agregar un `st.bar_chart` simple sobre el resultado — es la única visualización de la app, y sirve para mostrar que los datos recién insertados en ACT-A3/A5 alimentan estas mismas consultas.

**Verificación**
- [ ] Las 10 preguntas corren sin error y reflejan los datos que se vayan insertando durante la demo (no solo el escenario original de ACT-13).

---

## ACT-A7 · Panel "Romper el modelo" (demostración de integridad) ⭐
**Objetivo:** el momento más efectivo de la demo: mostrar que el modelo rechaza datos inválidos, con el error real de PostgreSQL en pantalla.
**Precondición:** ACT-A1.
**Tiempo estimado:** 45 min

Esta página traduce a botones las 4 pruebas que ya se hicieron a mano por `psql` en ACT-16.

**Pasos**
1. Cuatro botones, cada uno con una descripción corta de qué va a intentar:
   - "Insertar una línea de pedido sin unidad de medida" → dispara el `INSERT` sin `unidad_codigo`.
   - "Insertar una tarea sin pedido asociado" → `INSERT` sin `pedido_id`.
   - "Insertar un empaque con una tarea que no existe" → `INSERT` con `tarea_id = 999999`.
   - "Registrar un cliente con un NIT que ya existe" → reutiliza un `numero_documento` ya cargado.
2. Al presionar, la app ejecuta el `INSERT` dentro de un `try/except psycopg2.Error`, y muestra con `st.error()` el mensaje exacto que devuelve PostgreSQL (`null value in column ... violates not-null constraint`, `violates foreign key constraint`, `duplicate key value violates unique constraint`).
3. Justo al lado de cada botón, un texto fijo que conecta el error con el hallazgo del caso original (por ejemplo: "Esto es exactamente el hallazgo H06: en el diagrama del caso, una tarea podía existir sin pedido. Aquí, la base de datos lo impide.").

**Verificación**
- [ ] Los 4 botones muestran el error real de PostgreSQL, no un mensaje inventado por la app.
- [ ] Ningún botón deja datos corruptos a medias en la base (cada intento debe hacer `rollback()` del `INSERT` fallido).

---

## ACT-A8 · Empaquetado y README de la app
**Objetivo:** que cualquiera de tus dos compañeros pueda correr la app con el mismo resultado, sin importar su sistema operativo.
**Precondición:** ACT-A1 a ACT-A7.
**Tiempo estimado:** 30 min

**Pasos**
1. `app/README.md` con los 3 comandos exactos para levantarla (crear entorno virtual, instalar dependencias, `streamlit run app.py`), con la nota de que la base de Docker debe estar arriba primero.
2. Agregar `app/.venv/` y `app/.env` al `.gitignore` raíz (el entorno virtual y las credenciales no se versionan; `.env.example` sí).
3. Actualizar el `README.md` raíz del proyecto con una sección corta "Aplicación de demostración" que enlace a `app/README.md`.

**Verificación**
- [ ] Clonar el repo en una carpeta limpia, seguir solo el README, y lograr correr la app sin ayuda adicional.

---

# PARTE IV — Guion de demostración en vivo

Guion pensado para 8–10 minutos frente a colegas, usando la app como hilo conductor. Cada momento indica qué mostrar, qué decir, y qué hallazgo del caso original respalda.

## Momento 1 (1 min) · Catálogos cargados
Abrir la página de catálogos, mostrar `EstadoPedido` y `TipoTarea`.
> "Estos catálogos no estaban en el diagrama original del caso — los agregamos porque un pedido sin estado no tiene ciclo de vida (hallazgo H08)."

## Momento 2 (2–3 min) · Crear un pedido con dos productos, en vivo
Pedirle a un colega que sugiera dos productos y cantidades. Armar el pedido con esos datos reales frente a todos, usando el formulario de ACT-A3.
> "El diagrama original del caso dibuja `Pedido`–`Producto` como una asociación simple: un pedido, un producto. Eso no es la realidad operativa de ningún negocio de distribución. Acabamos de crear un pedido con dos productos distintos, cada uno con su propia cantidad y precio — eso es `LineaPedido`, la entidad que el caso no tenía."

## Momento 3 (1–2 min) · Anclar una tarea al pedido recién creado
Usando el pedido del Momento 2, registrar una tarea de tipo `EMPAQUE` en la página de ACT-A4.
> "En el caso original, la jerarquía de tareas (`Empaque`, `Separación`) no se conectaba con nada — no había forma de saber a qué pedido pertenecía una tarea. La estamos anclando ahora mismo."

## Momento 4 (2 min) · El momento de romper el modelo
Ir a la página de ACT-A7. Presionar el botón "Insertar una tarea sin pedido asociado" en vivo.
> "Esto es literalmente el hallazgo H06 del análisis del caso, intentado a propósito. Miren el mensaje: es PostgreSQL rechazándolo, no una validación de Python que inventamos — la restricción vive en la base de datos porque así se definió en el modelo Telosys."

Repetir con el botón de FK inexistente o el de NIT duplicado si el tiempo lo permite — cada uno tiene una frase de conexión al hallazgo correspondiente ya escrita en la propia página (ACT-A7, paso 3).

## Momento 5 (1–2 min) · Las preguntas de negocio responden con los datos nuevos
Ir al panel de consultas de negocio (ACT-A6) y abrir la pregunta "¿qué pedidos van en el envío de hoy?" o la de peso total — mostrando que el pedido creado en el Momento 2 ya aparece reflejado.
> "No es una base de datos de ejemplo estática: lo que acabamos de insertar en vivo ya es parte de las respuestas."

## Momento 6 (opcional, si sobra tiempo) · Cerrar el círculo con Telosys
Volver un momento a la terminal y repetir el ejercicio de evolución de `docs/act19-evolucion.md`: agregar un campo al modelo, regenerar el DDL, y mencionar que ese cambio tomaría minutos en propagarse también a esta misma aplicación (habría que agregar la columna al formulario correspondiente).
> "La app no es el modelo — es una ventana sobre él. El modelo sigue siendo los 22 archivos `.entity`; si cambia, cambia también lo que la aplicación puede guardar."

## Checklist antes de la demo

- [ ] `docker compose up -d` corriendo y con los datos de ACT-13 cargados.
- [ ] `streamlit run app.py` arrancando sin errores.
- [ ] Probar los 4 botones de ACT-A7 una vez antes de la sustentación, para confirmar que cada mensaje de error es legible y no demasiado técnico para leer en voz alta.
- [ ] Tener a mano un plan B: si algo falla en vivo, los mismos 4 casos ya están probados y documentados en `docs/lista-chequeo-modelo.md` y la sección de integridad de ACT-16.

---

# PARTE V — Cronograma

| Actividad | Tiempo estimado |
|---|---|
| ACT-A1 · Preparar entorno | 20 min |
| ACT-A2 · Página de catálogos | 30 min |
| ACT-A3 · Formulario de Pedido + líneas ⭐ | 1 h 30 min |
| ACT-A4 · Formulario de Tareas | 1 h |
| ACT-A5 · Formulario de Envío/Entrega | 45 min |
| ACT-A6 · Panel de consultas de negocio | 45 min |
| ACT-A7 · Panel "Romper el modelo" ⭐ | 45 min |
| ACT-A8 · Empaquetado y README | 30 min |
| **Total** | **≈ 6 h** |

Las actividades ACT-A4, ACT-A5, ACT-A6 y ACT-A7 no dependen entre sí una vez completada ACT-A3, y se pueden trabajar en cualquier orden o en paralelo si hay más de una persona construyendo la app.

---

# ANEXOS

## Anexo A — Dependencias de Python

```
streamlit
psycopg2-binary
python-dotenv
pandas
```

`psycopg2-binary` (en vez de `psycopg2`) se elige a propósito: no requiere compilador ni `libpq` instalado en el sistema, lo cual importa porque este proyecto se comparte entre Windows, macOS y Linux.

## Anexo B — Qué NO se versiona de la app

Siguiendo la misma lógica ya aplicada en `.gitignore` para lo que genera Telosys:

- `app/.venv/` (entorno virtual — cada quien crea el suyo)
- `app/.env` (credenciales locales — se versiona solo `.env.example`)
- `app/__pycache__/`, `*.pyc`
