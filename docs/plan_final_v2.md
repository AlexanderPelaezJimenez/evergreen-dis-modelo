# Plan de Implementación del Modelo de Dominio — Macroproceso de Distribución [DIS]
## Caso EverGreen · Propuesta mejorada de entidades de dominio · Implementación en Telosys

| Campo | Valor |
|---|---|
| **Documento** | `plan_final_v2.md` |
| **Versión** | 2.0 — reenfoque total al modelo de dominio |
| **Alcance** | Análisis, mejora e implementación en Telosys de las entidades de dominio de DIS |
| **Fuera de alcance** | Microservicios, APIs externas, cálculo de rutas, costeo de viajes |
| **Herramienta** | Telosys 4.x (CLI o extensión VSCode) |
| **Entregable final** | Modelo Telosys validado (22 entidades) + DDL generado + diagrama de clases generado |
| **Referencia base** | Lámina 7 del caso: *Macroproceso de Distribución [DIS] — Propuesta de entidades de dominio* |

---

## Qué cambia respecto de la versión 1

| Aspecto | v1 | v2 (este documento) |
|---|---|---|
| Foco | Microservicio DIS completo con servicios geoespaciales | **Únicamente el modelo de dominio** |
| Unidad de planeación | Historias de usuario (HU) | **Actividades de ingeniería del modelo (ACT)** |
| Entidades | 9 del caso + 9 de soporte a servicios | **22 entidades derivadas y mejoradas del caso** |
| Criterio de éxito | Endpoints funcionando | **Modelo validado que soporta datos reales sin contradicciones** |
| Uso de Telosys | Generar backend | **Modelar, validar, generar DDL y documentación** |

---

# TABLA DE CONTENIDO

1. [Parte I — Análisis del modelo de dominio del caso](#parte-i--análisis-del-modelo-de-dominio-del-caso)
2. [Parte II — Propuesta mejorada del modelo](#parte-ii--propuesta-mejorada-del-modelo)
3. [Parte III — Actividades de implementación en Telosys](#parte-iii--actividades-de-implementación-en-telosys)
4. [Parte IV — Cronograma y control](#parte-iv--cronograma-y-control)
5. [Anexos](#anexos)

---

# PARTE I — Análisis del modelo de dominio del caso

## 1.1. Inventario literal del diagrama (lámina 7)

Esto es exactamente lo que el caso propone, sin interpretación:

| # | Entidad | Atributos declarados | Relación mostrada |
|---|---|---|---|
| 1 | `Cliente` | *(ninguno)* | Asociación con `Pedido` |
| 2 | `Producto` | `identificador`, `fechaElaboracion` | Asociación con `Pedido` |
| 3 | `CanalesComercializacion` | *(ninguno)* | Asociación con `Pedido` |
| 4 | `Pedido` | `identificador`, `fechaEntrada`, `fechaSalida` | Centro del modelo |
| 5 | `Empaque` | `tipo`, `tamaño`, `cantidad`, `tiempo` | **Generalización** hacia `TipoTarea` |
| 6 | `Separación` | `lote`, `cantidad` | **Generalización** hacia `TipoTarea` |
| 7 | `TipoTarea` | *(ninguno)* | Superclase de `Empaque` y `Separación` |
| 8 | `Transporte` | *(ninguno)* | Asociación con `Pedido` |
| 9 | `Acuatico` | *(ninguno)* | **Generalización** hacia `Transporte` |
| 10 | `Aereo` | *(ninguno)* | **Generalización** hacia `Transporte` |
| 11 | `Terrestre` | *(ninguno)* | **Generalización** hacia `Transporte` |

**Balance:** 11 elementos, **9 atributos en total**, **2 jerarquías de generalización**, cero claves primarias, cero tipos de dato, cero cardinalidades explícitas.

Es exactamente lo que debe ser: un **boceto conceptual** que marca el terreno. La tarea de este plan es convertirlo en un modelo implementable sin traicionar su intención.

## 1.2. Diagnóstico: 17 hallazgos

| ID | Hallazgo | Severidad | Elemento afectado |
|---|---|---|---|
| **H01** | Ninguna entidad declara clave primaria | 🔴 Bloqueante | Todas |
| **H02** | Ningún atributo declara tipo de dato | 🔴 Bloqueante | Los 9 atributos |
| **H03** | `Separación` lleva tilde: **nombre inválido** en Telosys (solo letras, números y `_`) | 🔴 Bloqueante | `Separación` |
| **H04** | `tamaño` lleva `ñ`: **nombre de atributo inválido** en Telosys | 🔴 Bloqueante | `Empaque.tamaño` |
| **H05** | La relación `Pedido`–`Producto` es en realidad **muchos a muchos con datos propios** (cantidad, precio); dibujada como asociación simple es irrealizable | 🔴 Bloqueante | `Pedido`, `Producto` |
| **H06** | La jerarquía `TipoTarea` está **huérfana**: no se conecta con `Pedido` ni con nada. Las tareas no tienen a qué aplicarse | 🔴 Bloqueante | `TipoTarea`, `Empaque`, `Separacion` |
| **H07** | `TipoTarea` confunde **catálogo** (qué tipos de tarea existen) con **ejecución** (qué tarea se hizo, cuándo y quién) | 🟠 Alta | Jerarquía de tareas |
| **H08** | `Pedido` no tiene **estado**: no hay ciclo de vida ni forma de saber si se entregó | 🟠 Alta | `Pedido` |
| **H09** | No hay **dirección de entrega**: el pedido no sabe a dónde va | 🟠 Alta | `Pedido`, `Cliente` |
| **H10** | `Empaque.tipo` y `Separacion.lote` son texto libre donde deberían ser **referencias a entidades** | 🟠 Alta | `Empaque`, `Separacion` |
| **H11** | `Empaque.tiempo` es **ambiguo**: ¿instante, duración, turno? | 🟠 Alta | `Empaque` |
| **H12** | Los tres subtipos de `Transporte` **no tienen ni un atributo propio**: la jerarquía no se justifica | 🟠 Alta | `Acuatico`, `Aereo`, `Terrestre` |
| **H13** | `Transporte` se ata directamente a `Pedido`: no permite **un viaje con varios pedidos**, que es la operación normal | 🟠 Alta | `Transporte`, `Pedido` |
| **H14** | No hay **unidad de medida**: "cantidad 50" no dice si son kilos, cajas o toneladas | 🟠 Alta | `Empaque`, `Separacion` |
| **H15** | Sin **trazabilidad por lote** hacia el origen (predio/parcela), inaceptable en cadena agroalimentaria | 🟡 Media | `Producto` |
| **H16** | `CanalesComercializacion` en plural rompe la convención de nombrado (una instancia = un canal) | 🟡 Media | `CanalesComercializacion` |
| **H17** | No hay registro de **entrega efectiva** (quién recibió, cuándo, con qué novedad) | 🟡 Media | `Pedido` |

> **H03 y H04 son el hallazgo más práctico de todos.** La documentación de Telosys es explícita: el nombre de una entidad puede contener únicamente letras, números y guion bajo, y debe coincidir exactamente con el nombre del archivo `.entity`; las mismas reglas aplican a los nombres de atributo. `Separación.entity` y el atributo `tamaño` **no compilan**. Es el tipo de detalle que solo aparece cuando de verdad se intenta implementar el diagrama, y vale la pena mencionarlo en la sustentación.

## 1.3. Ambigüedades que exigen una decisión explícita

| # | Ambigüedad del diagrama | Decisión adoptada | Justificación |
|---|---|---|---|
| A1 | ¿`TipoTarea` es catálogo o tarea ejecutada? | **Ambas cosas, separadas**: `TipoTarea` (catálogo) + `Tarea` (ejecución) | Un pedido puede requerir dos empaques distintos; con una sola entidad eso es imposible de registrar |
| A2 | ¿`Empaque.tiempo` qué mide? | **Duración en minutos**, y se traslada a `Tarea.duracionMinutos` | Aplica a toda tarea, no solo al empaque |
| A3 | ¿`Empaque.cantidad` cuenta unidades de empaque o producto? | **Número de empaques generados** (`int`) | `Separacion.cantidad` sí es cantidad de producto (`decimal`) |
| A4 | ¿`Producto.identificador` es la PK? | **No**: se conserva como código de negocio; la PK es técnica | Permite que el código cambie sin romper las referencias |
| A5 | ¿Un pedido lleva un solo producto? | **No**: relación muchos a muchos vía `LineaPedido` | Es la realidad operativa de cualquier pedido |
| A6 | ¿Un transporte atiende un solo pedido? | **No**: se introduce `Envio` que agrupa pedidos | Un camión sale con varios pedidos |
| A7 | ¿`Separacion.lote` es texto o entidad? | **Entidad `Lote`** | Habilita trazabilidad real hacia el predio de origen |

---

# PARTE II — Propuesta mejorada del modelo

## 2.1. Principios de diseño aplicados

| # | Principio | Aplicación concreta |
|---|---|---|
| P1 | **Nada del caso se pierde** | Los 11 elementos y los 9 atributos originales sobreviven, tipificados o normalizados |
| P2 | **Toda relación M:N se resuelve con entidad asociativa** | `LineaPedido` |
| P3 | **Catálogo ≠ transacción** | `TipoTarea` (catálogo) vs `Tarea` (transacción) |
| P4 | **Toda jerarquía debe justificarse con atributos propios** | Los subtipos de `Transporte` reciben atributos reales del negocio |
| P5 | **Texto libre que representa una entidad se normaliza** | `Empaque.tipo` → `TipoEmpaque`; `Separacion.lote` → `Lote` |
| P6 | **Toda cantidad va acompañada de su unidad** | FK a `UnidadMedida` |
| P7 | **PK técnica + código de negocio** | `id` interno + `identificador`/`codigo` del caso |
| P8 | **Nombres válidos en Telosys** | Sin tildes, sin `ñ`, singular, `PascalCase` para entidades y `camelCase` para atributos |
| P9 | **Disciplina de alcance** | No se agrega nada que pertenezca a otro macroproceso |

## 2.2. Las 22 entidades del modelo mejorado

| Grupo | Entidades | Origen |
|---|---|---|
| **G1 · Catálogos** (5) | `UnidadMedida`, `EstadoPedido`, `CategoriaProducto`, `TipoTarea`, `TipoEmpaque` | 1 del caso · 4 nuevas |
| **G2 · Cliente** (3) | `Cliente`, `Direccion`, `CanalComercializacion` | 2 del caso · 1 nueva |
| **G3 · Producto** (2) | `Producto`, `Lote` | 1 del caso · 1 nueva |
| **G4 · Pedido** (2) | `Pedido`, `LineaPedido` | 1 del caso · 1 nueva |
| **G5 · Tareas** (3) | `Tarea`, `Empaque`, `Separacion` | 2 del caso · 1 nueva |
| **G6 · Transporte** (5) | `Transportador`, `Transporte`, `Terrestre`, `Aereo`, `Acuatico` | 4 del caso · 1 nueva |
| **G7 · Operación** (2) | `Envio`, `Entrega` | 2 nuevas |

**Total: 22 entidades** — 11 provienen del caso, 11 son extensiones justificadas.

## 2.3. Las 17 mejoras, una por hallazgo

| ID | Mejora | Resuelve |
|---|---|---|
| **M01** | Clave primaria explícita (`@Id`) en las 22 entidades | H01 |
| **M02** | Tipo neutro + restricciones (`@NotNull`, `@MaxLen`, `@Size`, `@Min`, `@Max`) en cada atributo | H02 |
| **M03** | Nombres normalizados: `Separación`→`Separacion`, `tamaño`→`tamano`, `CanalesComercializacion`→`CanalComercializacion` | H03, H04, H16 |
| **M04** | `LineaPedido` resuelve la relación M:N `Pedido`–`Producto` con cantidad, precio, lote y unidad | H05 |
| **M05** | `Tarea` ancla la jerarquía de tareas al `Pedido` mediante FK obligatoria | H06 |
| **M06** | `TipoTarea` queda como catálogo de solo lectura; `Tarea` registra la ejecución | H07 |
| **M07** | `EstadoPedido` como catálogo ordenado con marca de estado final | H08 |
| **M08** | `Direccion` con alias, ciudad, país y coordenadas opcionales | H09 |
| **M09** | `TipoEmpaque` normaliza `Empaque.tipo` (material, capacidad, tara, reutilizable) | H10 |
| **M10** | `Lote` normaliza `Separacion.lote` y aporta trazabilidad | H10, H15 |
| **M11** | `Empaque.tiempo` se desambigua como `Tarea.duracionMinutos` (`int`) | H11 |
| **M12** | Los subtipos de `Transporte` reciben atributos propios reales (placa/ejes, guía aérea/IATA, contenedor/BL) | H12 |
| **M13** | `Envio` agrupa varios pedidos en un mismo viaje de un transporte | H13 |
| **M14** | `UnidadMedida` como catálogo con factor de conversión a kilogramos | H14 |
| **M15** | `CategoriaProducto` con perecibilidad, vida útil y rango de temperatura (cadena de frío) | H15 |
| **M16** | `Transportador` identifica a quién presta el servicio de transporte | H13 |
| **M17** | `Entrega` registra la evidencia de cumplimiento (receptor, fecha real, novedad) | H17 |

### Lo que deliberadamente NO se agregó

Para mantener la disciplina de alcance, el modelo **no** incluye: rutas ni geometrías, tarifas ni costos de viaje, matrices de distancia, usuarios ni roles (pertenecen a `ADM`), facturación (pertenece a `FIN`) ni notificaciones (pertenecen a `MEN`). Cada una de esas exclusiones es defendible señalando el módulo dueño en el diagrama de módulos del caso.

## 2.4. Estrategia de herencia (decisión clave)

El caso plantea dos generalizaciones. Telosys ofrece `@Abstract` (marca una entidad como abstracta, desde 4.0.0) y `@Extends(...)` (define la superclase, desde 4.0.0), ambas con ámbito de entidad. Sin embargo, la interpretación de esas anotaciones depende de las plantillas del bundle que se use para generar.

**Decisión: herencia por tabla-por-subtipo con clave primaria compartida.**

```
        Transporte (tabla base, atributos comunes)
        id  ← PK
        modalidad (discriminador: TERRESTRE | AEREO | ACUATICO)
             ▲            ▲            ▲
             │            │            │
        Terrestre      Aereo       Acuatico
        transporteId   transporteId  transporteId   ← PK = FK hacia Transporte
        (atributos propios de cada modalidad)
```

En Telosys esto se expresa poniendo `@Id` y `@FK(...)` **sobre el mismo atributo** en la entidad hija:

```
transporteId : int { @Id @FK(FK_TER_TRA, Transporte) } ;
```

| Ventaja | Detalle |
|---|---|
| Portable | Funciona con cualquier bundle, sin depender de que interprete `@Extends` |
| Fiel al caso | La generalización es visible y verificable en el diagrama generado |
| Normalizado | Los atributos propios de cada modalidad no ensucian la tabla base |
| Verificable | El discriminador `modalidad` permite validar la coherencia con SQL |

El mismo patrón se aplica a `Tarea` → `Empaque` / `Separacion`.

> **Alternativa documentada:** si se prefiere demostrar el soporte nativo, se marca `Transporte` con `@Abstract` y cada hija con `@Extends(Transporte)`. Conviene probarlo en una rama aparte y verificar qué produce el bundle antes de comprometerse.

## 2.5. Matriz de relaciones del modelo mejorado

| Origen | Destino | Cardinalidad | Obligatoria | Semántica |
|---|---|---|---|---|
| `Direccion` | `Cliente` | N : 1 | Sí | Un cliente tiene varias direcciones |
| `Pedido` | `Cliente` | N : 1 | Sí | Quién compra |
| `Pedido` | `Direccion` | N : 1 | Sí | A dónde se entrega |
| `Pedido` | `CanalComercializacion` | N : 1 | Sí | Por qué canal se vendió |
| `Pedido` | `EstadoPedido` | N : 1 | Sí | En qué punto del ciclo está |
| `Pedido` | `Envio` | N : 1 | No | En qué viaje sale (nulo mientras no se despacha) |
| `LineaPedido` | `Pedido` | N : 1 | Sí | Composición: la línea no existe sin el pedido |
| `LineaPedido` | `Producto` | N : 1 | Sí | Qué producto |
| `LineaPedido` | `Lote` | N : 1 | No | De qué lote salió (trazabilidad) |
| `LineaPedido` | `UnidadMedida` | N : 1 | Sí | En qué unidad se expresa la cantidad |
| `Lote` | `Producto` | N : 1 | Sí | Un producto tiene muchos lotes |
| `Producto` | `CategoriaProducto` | N : 1 | Sí | Fruta / hortaliza / flores |
| `Producto` | `UnidadMedida` | N : 1 | Sí | Unidad base de comercialización |
| `Tarea` | `Pedido` | N : 1 | Sí | Composición: tarea de preparación del pedido |
| `Tarea` | `TipoTarea` | N : 1 | Sí | Qué clase de tarea es |
| `Empaque` | `Tarea` | 1 : 1 | Sí | Especialización (PK = FK) |
| `Empaque` | `TipoEmpaque` | N : 1 | Sí | Caja, canastilla, saco… |
| `Separacion` | `Tarea` | 1 : 1 | Sí | Especialización (PK = FK) |
| `Separacion` | `Lote` | N : 1 | Sí | De qué lote se separó |
| `Terrestre` / `Aereo` / `Acuatico` | `Transporte` | 1 : 1 | Sí | Especialización (PK = FK) |
| `Transporte` | `Transportador` | N : 1 | Sí | Quién presta el servicio |
| `Envio` | `Transporte` | N : 1 | Sí | En qué vehículo va el viaje |
| `Entrega` | `Pedido` | 1 : 1 | Sí | Evidencia de entrega (PK = FK) |

**Total: 23 relaciones**, todas con cardinalidad y obligatoriedad explícitas — frente a las 7 asociaciones sin cardinalidad del diagrama original.

## 2.6. Orden de construcción (importante)

Telosys valida las referencias entre entidades al ejecutar `cm` (check model). Si una entidad referencia otra que aún no existe, el chequeo falla. Por eso el orden de creación **no es arbitrario**:

```
G1 Catálogos  →  G2 Cliente  →  G3 Producto  →  G4 Pedido  →  G5 Tareas
                                                    ↑              │
                              G6 Transporte  →  G7 Envio ──────────┘
```

Regla práctica: **crear siempre primero lo que es referenciado y después lo que referencia.** La única dependencia circular aparente (`Pedido` ↔ `Envio`) se resuelve creando `Envio` antes que la FK opcional de `Pedido`, o creando los archivos vacíos primero y llenándolos después (Telosys solo exige que el archivo de la entidad referenciada exista).

---

# PARTE III — Actividades de implementación en Telosys

**Formato de cada actividad:** objetivo · precondición · pasos · artefacto · verificación · tiempo estimado.

---

## FASE 0 — Preparación del entorno

### ACT-01 · Instalar Telosys y verificar la versión
**Objetivo:** disponer de Telosys operativo y saber exactamente con qué versión se trabaja.
**Precondición:** Java instalado (Telosys CLI se ejecuta sobre JVM).
**Tiempo:** 30 min

**Pasos**
1. Descargar Telosys CLI desde `telosys.org` (o instalar la extensión de VSCode).
2. Descomprimir en la carpeta de trabajo y ejecutar el script `tt` (`.sh` o `.bat`).
3. Ejecutar `ver` y **anotar la versión exacta** en la bitácora del proyecto.
4. Ejecutar `?` para ver el listado completo de comandos disponibles.
5. Configurar el editor externo en `telosys-cli.cfg` (VSCode, Notepad++, etc.).

**Artefacto:** entorno Telosys funcionando + versión registrada.

**Verificación**
- [ ] `ver` responde con la versión.
- [ ] `?` lista los grupos de comandos (General, Project, Model, Entity, Bundle, Template, Generation).

> **Por qué importa la versión:** el tipo `datetime` existe desde 4.3.0 y `timestamp` quedó deprecado en esa misma versión. Si la versión instalada es anterior, hay que usar `timestamp`. Anotar esto ahora evita perder una tarde después.

---

### ACT-02 · Inicializar el proyecto y crear el modelo
**Objetivo:** tener la carpeta del modelo lista para recibir las entidades.
**Precondición:** ACT-01.
**Tiempo:** 20 min

**Pasos**
1. Crear la carpeta del proyecto: `evergreen-dis-modelo`.
2. En Telosys CLI: `h .` para fijar el directorio HOME.
3. `init` → crea la estructura `TelosysTools/`.
4. `cfg` → verificar las rutas de modelos y plantillas.
5. `nm dis_dominio` → crear el modelo.
6. `m dis_dominio` → fijarlo como modelo actual (aparece entre paréntesis en el prompt: `telosys#(dis_dominio)>`).
7. `em` → editar `model.yaml` y completar título, versión y descripción **usando únicamente las claves que Telosys generó**.

**Estructura resultante**
```
evergreen-dis-modelo/
└── TelosysTools/
    ├── telosys-tools.cfg
    └── models/
        └── dis_dominio/
            └── model.yaml
```

**Verificación**
- [ ] `lm` lista `dis_dominio`.
- [ ] El prompt muestra el modelo actual.
- [ ] `le` responde (lista vacía, sin error).

---

### ACT-03 · Fijar las convenciones del modelo
**Objetivo:** acordar por escrito las reglas de nombrado y tipificación **antes** de escribir la primera entidad.
**Precondición:** ACT-02.
**Tiempo:** 40 min

**Convenciones adoptadas**

| Elemento | Convención | Ejemplo | Regla de Telosys |
|---|---|---|---|
| Entidad | `PascalCase`, singular, sin tildes | `LineaPedido` | Solo letras, números y `_`; debe coincidir con el nombre del archivo |
| Atributo | `camelCase`, sin tildes ni `ñ` | `fechaEntrada`, `tamano` | Solo letras, números y `_`; empieza en minúscula |
| PK técnica | `id` | `id : int { @Id @AutoIncremented }` | — |
| PK de catálogo | `codigo` (natural, tipo `string`) | `codigo : string { @Id @MaxLen(6) }` | Telosys admite PK no numérica |
| FK | `<entidad>Id` o `<entidad>Codigo` | `clienteId`, `estadoCodigo` | — |
| Nombre de FK | `FK_<ORIGEN3>_<DESTINO3>` | `FK_PED_CLI` | Máx. recomendado 30 caracteres |
| Link "a uno" | nombre de la entidad en minúscula | `cliente : Cliente` | — |
| Link "a muchos" | plural + `[]` | `lineas : LineaPedido[]` | — |
| Tabla | `DIS_<NOMBRE>` vía `@DbTable` | `@DbTable(DIS_PEDIDO)` | — |
| Comentarios | solo de una línea con `//` | `// del caso` | No existen comentarios multilínea |

**Tipos neutros que se usarán**

| Tipo | Uso en este modelo |
|---|---|
| `int` | PK técnicas, FK numéricas, cantidades enteras |
| `short` | Números de secuencia, orden, años |
| `long` | *(no se usa en este modelo)* |
| `decimal` | Cantidades, pesos, volúmenes, precios, coordenadas |
| `string` | Códigos, nombres, descripciones |
| `boolean` | Banderas (`activo`, `esFinal`, `conNovedad`) |
| `date` | Fechas sin hora (cosecha, vencimiento, compromiso) |
| `datetime` | Fecha con hora (entrada, salida, entrega) — **usar `timestamp` si la versión es < 4.3.0** |

**Regla de anotaciones**
- Longitud de texto → `@MaxLen(n)` (**no** `@SizeMax`, deprecada).
- Precisión decimal → `@Size(precision,escala)`, por ejemplo `@Size(12,3)`.
- **Nunca poner coma entre anotaciones** (prohibido desde la versión 4.0).
- Cada definición termina en `;`.

**Artefacto:** `docs/convenciones-modelo.md`.

**Verificación**
- [ ] Documento revisado y aceptado antes de crear entidades.

---

## FASE 1 — Implementación de las entidades

> En cada actividad: crear el archivo con `ne <Entidad>`, editarlo con `ee <Entidad>` (o directamente en el IDE), y ejecutar `cm` al terminar el grupo.

---

### ACT-04 · Grupo G1 — Catálogos base (5 entidades)
**Objetivo:** crear las entidades que todas las demás referencian.
**Precondición:** ACT-03.
**Tiempo:** 1 h 30 min
**Entidades:** `UnidadMedida`, `EstadoPedido`, `CategoriaProducto`, `TipoTarea`, `TipoEmpaque`

**Pasos**
1. `ne UnidadMedida` … `ne TipoEmpaque` (crear los cinco archivos).
2. Editar cada uno con el contenido siguiente.
3. `cm` → debe terminar sin errores antes de continuar.

**`UnidadMedida.entity`**
```
// Catalogo de unidades de medida - resuelve H14
@ReadOnly
@DbTable(DIS_UNIDAD_MEDIDA)
UnidadMedida {
  codigo    : string  { @Id @MaxLen(6) @Label("Codigo") } ;   // KG, TON, CAJ, UND, BUL
  nombre    : string  { @NotNull @MaxLen(40) } ;
  factorAKg : decimal { @Size(12,4) @Min(0) @Label("Factor de conversion a kilogramos") } ;
  activo    : boolean { @NotNull @DefaultValue(true) } ;
}
```

**`EstadoPedido.entity`**
```
// Ciclo de vida del pedido - resuelve H08
@ReadOnly
@DbTable(DIS_ESTADO_PEDIDO)
EstadoPedido {
  codigo  : string  { @Id @MaxLen(15) } ;   // REGISTRADO, EN_PREPARACION, LISTO, DESPACHADO, ENTREGADO, CANCELADO
  nombre  : string  { @NotNull @MaxLen(40) } ;
  orden   : short   { @NotNull @Min(1) @Label("Orden en el ciclo de vida") } ;
  esFinal : boolean { @NotNull @DefaultValue(false) @Label("Estado terminal") } ;
}
```

**`CategoriaProducto.entity`**
```
// Categoria agricola con parametros de conservacion - resuelve H15
@DbTable(DIS_CATEGORIA_PRODUCTO)
CategoriaProducto {
  id              : int     { @Id @AutoIncremented } ;
  nombre          : string  { @NotNull @MaxLen(40) } ;   // FRUTA, HORTALIZA, FLORES, GRANO
  perecedero      : boolean { @NotNull @DefaultValue(true) } ;
  vidaUtilDias    : short   { @Min(0) } ;
  temperaturaMinC : decimal { @Size(5,2) } ;
  temperaturaMaxC : decimal { @Size(5,2) } ;
}
```

**`TipoTarea.entity`** — entidad del caso, convertida en catálogo (H07)
```
// Catalogo de tipos de tarea de preparacion - del caso, ahora como catalogo
@ReadOnly
@DbTable(DIS_TIPO_TAREA)
TipoTarea {
  codigo          : string  { @Id @MaxLen(15) } ;   // SEPARACION, EMPAQUE, ROTULADO, CARGUE
  nombre          : string  { @NotNull @MaxLen(40) } ;
  orden           : short   { @NotNull @Min(1) @Label("Orden sugerido de ejecucion") } ;
  requiereDetalle : boolean { @NotNull @DefaultValue(false) @Label("Tiene entidad especializada") } ;
}
```

**`TipoEmpaque.entity`** — normaliza `Empaque.tipo` (H10)
```
// Normaliza el atributo "tipo" de Empaque - resuelve H10
@DbTable(DIS_TIPO_EMPAQUE)
TipoEmpaque {
  id           : int     { @Id @AutoIncremented } ;
  nombre       : string  { @NotNull @MaxLen(40) } ;   // CAJA, CANASTILLA, SACO, GUACAL
  material     : string  { @MaxLen(30) } ;
  capacidadKg  : decimal { @Size(8,2) @Min(0) } ;
  taraKg       : decimal { @Size(8,3) @Min(0) @Label("Peso del empaque vacio") } ;
  reutilizable : boolean { @NotNull @DefaultValue(false) } ;
}
```

**Verificación**
- [ ] `le` lista las 5 entidades.
- [ ] `cm` termina sin errores.
- [ ] Las tres entidades marcadas `@ReadOnly` corresponden a catálogos que no se editan en operación.

---

### ACT-05 · Grupo G2 — Cliente, dirección y canal (3 entidades)
**Objetivo:** modelar el destinatario del pedido y el canal por el que se comercializa.
**Precondición:** ACT-04.
**Tiempo:** 1 h
**Entidades:** `Cliente`, `Direccion`, `CanalComercializacion`

**`Cliente.entity`** — entidad del caso, ahora con contenido
```
// Del caso (sin atributos). Enriquecida con identificacion y contacto
@AggregateRoot
@DbTable(DIS_CLIENTE)
Cliente {
  id              : int     { @Id @AutoIncremented } ;
  tipoDocumento   : string  { @NotNull @MaxLen(5) } ;    // NIT, CC, CE
  numeroDocumento : string  { @NotNull @MaxLen(20) @Unique } ;
  razonSocial     : string  { @NotNull @MaxLen(120) } ;
  nombreComercial : string  { @MaxLen(120) } ;
  correo          : string  { @MaxLen(120) } ;           // formato validado en la aplicacion
  telefono        : string  { @MaxLen(20) } ;
  fechaRegistro   : date    { @NotNull @Past } ;
  activo          : boolean { @NotNull @DefaultValue(true) } ;

  // Links
  direcciones : Direccion[] { @MappedBy(cliente) @Cascade(ALL) } ;
  pedidos     : Pedido[]    { @MappedBy(cliente) } ;
}
```
> `@Unique` está marcada como **experimental** desde la versión 4.0. Si el DDL generado no incluye la restricción, agregarla manualmente al script y dejarlo anotado en la bitácora.

**`Direccion.entity`** — nueva, resuelve H09
```
// A donde se entrega el pedido - resuelve H09
@DbTable(DIS_DIRECCION)
Direccion {
  id             : int     { @Id @AutoIncremented } ;
  alias          : string  { @NotNull @MaxLen(60) } ;    // "Bodega norte", "Plaza mayorista"
  lineaDireccion : string  { @NotNull @MaxLen(200) } ;
  ciudad         : string  { @NotNull @MaxLen(80) } ;
  departamento   : string  { @MaxLen(80) } ;
  pais           : string  { @NotNull @MaxLen(60) @DefaultValue("Colombia") } ;
  codigoPostal   : string  { @MaxLen(12) } ;
  latitud        : decimal { @Size(9,6) @Min(-90)  @Max(90) } ;
  longitud       : decimal { @Size(9,6) @Min(-180) @Max(180) } ;
  esPrincipal    : boolean { @NotNull @DefaultValue(false) } ;

  clienteId : int { @NotNull @FK(FK_DIR_CLI, Cliente) } ;
  cliente   : Cliente { @LinkByFK(FK_DIR_CLI) } ;
}
```

**`CanalComercializacion.entity`** — del caso, nombre normalizado (H16)
```
// Del caso: "CanalesComercializacion" -> singular
@DbTable(DIS_CANAL_COMERCIALIZACION)
CanalComercializacion {
  codigo             : string  { @Id @MaxLen(10) } ;   // MAYORISTA, PLAZA, EXPORTA, DIRECTO
  nombre             : string  { @NotNull @MaxLen(60) } ;
  descripcion        : string  { @MaxLen(200) } ;
  comisionPorcentaje : decimal { @Size(5,2) @Min(0) @Max(100) @DefaultValue(0) } ;
  requiereFactura    : boolean { @NotNull @DefaultValue(true) } ;
  activo             : boolean { @NotNull @DefaultValue(true) } ;

  pedidos : Pedido[] { @MappedBy(canal) } ;
}
```

**Verificación**
- [ ] `cm` sin errores (los links hacia `Pedido` reportarán error hasta ACT-07: es esperado, se resuelve al crear `Pedido`).
- [ ] `Direccion` tiene FK obligatoria hacia `Cliente`.

> **Nota de secuencia:** si prefieres tener `cm` limpio en todo momento, crea primero los archivos vacíos de `Pedido`, `Envio` y `Tarea` con `ne`, y complétalos en su actividad. Telosys solo exige que el archivo de la entidad referenciada exista.

---

### ACT-06 · Grupo G3 — Producto y trazabilidad (2 entidades)
**Objetivo:** completar `Producto` y habilitar trazabilidad por lote.
**Precondición:** ACT-04.
**Tiempo:** 45 min
**Entidades:** `Producto`, `Lote`

**`Producto.entity`** — del caso, tipificado y enriquecido
```
// Del caso: identificador + fechaElaboracion. Enriquecido para contexto agro
@AggregateRoot
@DbTable(DIS_PRODUCTO)
Producto {
  id                 : int     { @Id @AutoIncremented } ;
  identificador      : string  { @NotNull @MaxLen(30) @Label("Codigo de negocio") } ;  // del caso
  nombre             : string  { @NotNull @MaxLen(120) } ;
  descripcion        : string  { @LongText } ;
  fechaElaboracion   : date    { @NotNull } ;                                          // del caso
  pesoUnitarioKg     : decimal { @Size(10,3) @Min(0) } ;
  requiereCadenaFrio : boolean { @NotNull @DefaultValue(false) } ;
  activo             : boolean { @NotNull @DefaultValue(true) } ;

  categoriaId  : int    { @NotNull @FK(FK_PRO_CAT, CategoriaProducto) } ;
  unidadCodigo : string { @NotNull @FK(FK_PRO_UNI, UnidadMedida) } ;

  categoria : CategoriaProducto { @LinkByFK(FK_PRO_CAT) } ;
  unidad    : UnidadMedida      { @LinkByFK(FK_PRO_UNI) } ;
  lotes     : Lote[]            { @MappedBy(producto) } ;
}
```

**`Lote.entity`** — nueva, resuelve H15 y normaliza `Separacion.lote`
```
// Trazabilidad hacia el predio de origen - resuelve H15
@DbTable(DIS_LOTE)
Lote {
  id                 : int     { @Id @AutoIncremented } ;
  codigo             : string  { @NotNull @MaxLen(30) } ;
  fechaCosecha       : date    { @NotNull } ;
  fechaVencimiento   : date ;
  cantidadInicial    : decimal { @NotNull @Size(12,3) @Min(0) } ;
  cantidadDisponible : decimal { @NotNull @Size(12,3) @Min(0) } ;
  predioOrigen       : string  { @MaxLen(120) @Label("Referencia al modulo de Produccion") } ;
  parcelaOrigen      : string  { @MaxLen(60) } ;

  productoId : int { @NotNull @FK(FK_LOT_PRO, Producto) } ;
  producto   : Producto { @LinkByFK(FK_LOT_PRO) } ;
}
```

**Verificación**
- [ ] Todo `Producto` tiene categoría y unidad de medida obligatorias.
- [ ] `Lote` permite responder "¿de qué parcela salió este producto?".

---

### ACT-07 · Grupo G4 — Pedido y línea de pedido (2 entidades) ⭐
**Objetivo:** implementar el núcleo del modelo y **resolver la relación muchos a muchos** que el caso deja sin resolver.
**Precondición:** ACT-04, ACT-05, ACT-06.
**Tiempo:** 1 h 30 min
**Entidades:** `Pedido`, `LineaPedido`

Esta es la actividad más importante del plan: `LineaPedido` es la mejora M04 y el argumento central de la propuesta.

**`Pedido.entity`** — entidad central del caso
```
// Del caso: identificador, fechaEntrada, fechaSalida. Raiz del agregado
@AggregateRoot
@DbTable(DIS_PEDIDO)
Pedido {
  id                     : int      { @Id @AutoIncremented } ;
  identificador          : string   { @NotNull @MaxLen(30) } ;   // del caso
  fechaEntrada           : datetime { @NotNull } ;               // del caso
  fechaSalida            : datetime ;                            // del caso
  fechaCompromisoEntrega : date     { @NotNull } ;
  pesoTotalKg            : decimal  { @Size(12,3) @Min(0) } ;
  volumenTotalM3         : decimal  { @Size(12,4) @Min(0) } ;
  valorTotal             : decimal  { @Size(14,2) @Min(0) } ;
  moneda                 : string   { @NotNull @MaxLen(3) @DefaultValue("COP") } ;
  requiereCadenaFrio     : boolean  { @NotNull @DefaultValue(false) } ;
  observaciones          : string   { @LongText } ;

  // --- Foreign Keys ---
  clienteId          : int    { @NotNull @FK(FK_PED_CLI, Cliente) } ;
  direccionEntregaId : int    { @NotNull @FK(FK_PED_DIR, Direccion) } ;
  canalCodigo        : string { @NotNull @FK(FK_PED_CAN, CanalComercializacion) } ;
  estadoCodigo       : string { @NotNull @FK(FK_PED_EST, EstadoPedido) } ;
  envioId            : int    {          @FK(FK_PED_ENV, Envio) } ;

  // --- Links ---
  cliente          : Cliente               { @LinkByFK(FK_PED_CLI) } ;
  direccionEntrega : Direccion             { @LinkByFK(FK_PED_DIR) } ;
  canal            : CanalComercializacion { @LinkByFK(FK_PED_CAN) } ;
  estado           : EstadoPedido          { @LinkByFK(FK_PED_EST) } ;
  envio            : Envio                 { @LinkByFK(FK_PED_ENV) @Optional } ;
  lineas           : LineaPedido[]         { @MappedBy(pedido) @Cascade(ALL) } ;
  tareas           : Tarea[]               { @MappedBy(pedido) @Cascade(ALL) } ;
  entrega          : Entrega               { @MappedBy(pedido) @OneToOne @Optional } ;
}
```

**`LineaPedido.entity`** — ⭐ la entidad asociativa que el caso no tiene
```
// Resuelve la relacion N:M Pedido-Producto del caso - mejora M04
@DbTable(DIS_LINEA_PEDIDO)
LineaPedido {
  id                  : int     { @Id @AutoIncremented } ;
  numeroLinea         : short   { @NotNull @Min(1) } ;
  cantidad            : decimal { @NotNull @Size(12,3) @Min(0) } ;
  precioUnitario      : decimal { @NotNull @Size(14,2) @Min(0) } ;
  descuentoPorcentaje : decimal { @Size(5,2) @Min(0) @Max(100) @DefaultValue(0) } ;
  subtotal            : decimal { @NotNull @Size(14,2) @Min(0) } ;
  pesoLineaKg         : decimal { @Size(12,3) @Min(0) } ;

  pedidoId     : int    { @NotNull @FK(FK_LIN_PED, Pedido) } ;
  productoId   : int    { @NotNull @FK(FK_LIN_PRO, Producto) } ;
  loteId       : int    {          @FK(FK_LIN_LOT, Lote) } ;
  unidadCodigo : string { @NotNull @FK(FK_LIN_UNI, UnidadMedida) } ;

  pedido   : Pedido       { @LinkByFK(FK_LIN_PED) } ;
  producto : Producto     { @LinkByFK(FK_LIN_PRO) } ;
  lote     : Lote         { @LinkByFK(FK_LIN_LOT) @Optional } ;
  unidad   : UnidadMedida { @LinkByFK(FK_LIN_UNI) } ;
}
```

> **Variante con clave primaria compuesta.** Telosys soporta PK compuesta poniendo `@Id` en varios atributos. Si se quiere demostrar esa capacidad, `LineaPedido` puede identificarse por `(pedidoId, numeroLinea)`:
> ```
> pedidoId    : int   { @Id @FK(FK_LIN_PED, Pedido) } ;
> numeroLinea : short { @Id @Min(1) } ;
> ```
> Es más purista, pero complica las FK entrantes. Se documenta como alternativa y se conserva la PK técnica.

**Verificación**
- [ ] Un pedido admite N productos y un producto aparece en N pedidos.
- [ ] La cantidad de cada línea tiene unidad de medida obligatoria.
- [ ] Al borrar un pedido se borran sus líneas (`@Cascade(ALL)`).

---

### ACT-08 · Grupo G5 — Tareas de preparación (3 entidades) ⭐
**Objetivo:** rescatar la jerarquía `TipoTarea` del caso, **anclarla al pedido** y darle semántica de ejecución.
**Precondición:** ACT-04, ACT-07.
**Tiempo:** 1 h 30 min
**Entidades:** `Tarea`, `Empaque`, `Separacion`

Segunda actividad crítica: aquí se corrige el hallazgo H06 (jerarquía huérfana) y se implementa la herencia por tabla-por-subtipo.

**`Tarea.entity`** — nueva: la ejecución que faltaba
```
// Ejecucion de una tarea de preparacion sobre un pedido - resuelve H06 y H07
@DbTable(DIS_TAREA)
Tarea {
  id               : int      { @Id @AutoIncremented } ;
  secuencia        : short    { @NotNull @Min(1) } ;
  estado           : string   { @NotNull @MaxLen(15) @DefaultValue("PENDIENTE") } ;
  fechaPlanificada : datetime ;
  fechaInicio      : datetime ;
  fechaFin         : datetime ;
  duracionMinutos  : int      { @Min(0) @Label("Tiempo de ejecucion") } ;   // el "tiempo" del caso
  responsable      : string   { @MaxLen(80) } ;
  observaciones    : string   { @LongText } ;

  pedidoId        : int    { @NotNull @FK(FK_TAR_PED, Pedido) } ;
  tipoTareaCodigo : string { @NotNull @FK(FK_TAR_TIP, TipoTarea) } ;

  pedido     : Pedido     { @LinkByFK(FK_TAR_PED) } ;
  tipoTarea  : TipoTarea  { @LinkByFK(FK_TAR_TIP) } ;
  empaque    : Empaque    { @MappedBy(tarea) @OneToOne @Optional } ;
  separacion : Separacion { @MappedBy(tarea) @OneToOne @Optional } ;
}
```

**`Empaque.entity`** — del caso, como especialización con PK = FK
```
// Del caso: tipo, tamaño, cantidad, tiempo
// "tipo"   -> FK a TipoEmpaque (normalizado)
// "tamaño" -> "tamano" (la ñ no es valida en Telosys)
// "tiempo" -> trasladado a Tarea.duracionMinutos
@DbTable(DIS_EMPAQUE)
Empaque {
  tareaId      : int     { @Id @FK(FK_EMP_TAR, Tarea) } ;   // PK = FK: especializacion 1:1
  cantidad     : int     { @NotNull @Min(1) @Label("Numero de empaques generados") } ;  // del caso
  tamano       : string  { @MaxLen(20) } ;                                              // del caso
  pesoNetoKg   : decimal { @Size(10,3) @Min(0) } ;
  pesoBrutoKg  : decimal { @Size(10,3) @Min(0) } ;
  rotulado     : boolean { @NotNull @DefaultValue(false) } ;

  tipoEmpaqueId : int { @NotNull @FK(FK_EMP_TIP, TipoEmpaque) } ;

  tarea       : Tarea       { @LinkByFK(FK_EMP_TAR) } ;
  tipoEmpaque : TipoEmpaque { @LinkByFK(FK_EMP_TIP) } ;
}
```

**`Separacion.entity`** — del caso, con el nombre corregido
```
// Del caso: "Separación" (con tilde: nombre invalido en Telosys) -> "Separacion"
// "lote" -> FK a Lote (normalizado)
@DbTable(DIS_SEPARACION)
Separacion {
  tareaId         : int     { @Id @FK(FK_SEP_TAR, Tarea) } ;   // PK = FK: especializacion 1:1
  cantidad        : decimal { @NotNull @Size(12,3) @Min(0) } ;  // del caso
  ubicacionOrigen : string  { @MaxLen(60) @Label("Bodega o area de separacion") } ;
  mermaKg         : decimal { @Size(10,3) @Min(0) @DefaultValue(0) } ;

  loteId       : int    { @NotNull @FK(FK_SEP_LOT, Lote) } ;          // el "lote" del caso
  unidadCodigo : string { @NotNull @FK(FK_SEP_UNI, UnidadMedida) } ;

  tarea  : Tarea        { @LinkByFK(FK_SEP_TAR) } ;
  lote   : Lote         { @LinkByFK(FK_SEP_LOT) } ;
  unidad : UnidadMedida { @LinkByFK(FK_SEP_UNI) } ;
}
```

**Verificación**
- [ ] Toda tarea pertenece obligatoriamente a un pedido (H06 resuelto).
- [ ] Un pedido puede tener varias tareas del mismo tipo.
- [ ] `Empaque` y `Separacion` no pueden existir sin su `Tarea` (PK = FK).
- [ ] Los 6 atributos originales de `Empaque` y `Separacion` están presentes o trazados a su nueva ubicación.

---

### ACT-09 · Grupo G6 — Transporte y sus modalidades (5 entidades) ⭐
**Objetivo:** implementar la segunda jerarquía del caso dándole a cada subtipo atributos que la justifiquen.
**Precondición:** ACT-04.
**Tiempo:** 1 h 30 min
**Entidades:** `Transportador`, `Transporte`, `Terrestre`, `Aereo`, `Acuatico`

**`Transportador.entity`** — nueva (M16)
```
// Quien presta el servicio de transporte
@DbTable(DIS_TRANSPORTADOR)
Transportador {
  id          : int     { @Id @AutoIncremented } ;
  nit         : string  { @NotNull @MaxLen(20) } ;
  razonSocial : string  { @NotNull @MaxLen(120) } ;
  telefono    : string  { @MaxLen(20) } ;
  correo      : string  { @MaxLen(120) } ;
  activo      : boolean { @NotNull @DefaultValue(true) } ;

  transportes : Transporte[] { @MappedBy(transportador) } ;
}
```

**`Transporte.entity`** — del caso, base de la jerarquía
```
// Del caso (sin atributos). Base de la jerarquia con discriminador de modalidad
@AggregateRoot
@DbTable(DIS_TRANSPORTE)
Transporte {
  id                 : int     { @Id @AutoIncremented } ;
  modalidad          : string  { @NotNull @MaxLen(10) @Label("TERRESTRE|AEREO|ACUATICO") } ;
  identificacion     : string  { @NotNull @MaxLen(20) @Label("Placa o matricula") } ;
  descripcion        : string  { @MaxLen(120) } ;
  capacidadPesoKg    : decimal { @NotNull @Size(12,3) @Min(0) } ;
  capacidadVolumenM3 : decimal { @Size(12,4) @Min(0) } ;
  tieneRefrigeracion : boolean { @NotNull @DefaultValue(false) } ;
  activo             : boolean { @NotNull @DefaultValue(true) } ;

  transportadorId : int { @NotNull @FK(FK_TRA_TDR, Transportador) } ;

  transportador : Transportador { @LinkByFK(FK_TRA_TDR) } ;
  terrestre     : Terrestre { @MappedBy(transporte) @OneToOne @Optional } ;
  aereo         : Aereo     { @MappedBy(transporte) @OneToOne @Optional } ;
  acuatico      : Acuatico  { @MappedBy(transporte) @OneToOne @Optional } ;
  envios        : Envio[]   { @MappedBy(transporte) } ;
}
```

**`Terrestre.entity`** — del caso, ahora con atributos propios
```
// Del caso (sin atributos). Especializacion con datos reales del modo terrestre
@DbTable(DIS_TERRESTRE)
Terrestre {
  transporteId      : int    { @Id @FK(FK_TER_TRA, Transporte) } ;
  tipoVehiculo      : string { @NotNull @MaxLen(30) } ;   // CAMION, TURBO, TRACTOMULA, CAMIONETA
  numeroEjes        : short  { @Min(2) } ;
  modeloAno         : short  { @Min(1950) } ;
  conductor         : string { @MaxLen(80) } ;
  licenciaConductor : string { @MaxLen(20) } ;

  transporte : Transporte { @LinkByFK(FK_TER_TRA) } ;
}
```

**`Aereo.entity`**
```
// Del caso (sin atributos). Especializacion con datos reales del modo aereo
@DbTable(DIS_AEREO)
Aereo {
  transporteId     : int    { @Id @FK(FK_AER_TRA, Transporte) } ;
  aerolinea        : string { @NotNull @MaxLen(60) } ;
  numeroVuelo      : string { @MaxLen(15) } ;
  aeropuertoOrigen : string { @MaxLen(5) @Label("Codigo IATA") } ;
  aeropuertoDestino: string { @MaxLen(5) @Label("Codigo IATA") } ;
  guiaAerea        : string { @MaxLen(30) @Label("Air Waybill") } ;

  transporte : Transporte { @LinkByFK(FK_AER_TRA) } ;
}
```

**`Acuatico.entity`**
```
// Del caso (sin atributos). Especializacion con datos reales del modo acuatico
@DbTable(DIS_ACUATICO)
Acuatico {
  transporteId         : int    { @Id @FK(FK_ACU_TRA, Transporte) } ;
  naviera              : string { @NotNull @MaxLen(60) } ;
  nombreEmbarcacion    : string { @MaxLen(60) } ;
  puertoOrigen         : string { @MaxLen(60) } ;
  puertoDestino        : string { @MaxLen(60) } ;
  numeroContenedor     : string { @MaxLen(20) } ;
  conocimientoEmbarque : string { @MaxLen(30) @Label("Bill of Lading") } ;

  transporte : Transporte { @LinkByFK(FK_ACU_TRA) } ;
}
```

**Verificación**
- [ ] Cada subtipo aporta al menos 4 atributos propios (H12 resuelto).
- [ ] Un transporte no puede tener dos especializaciones simultáneas (regla a validar por aplicación o por *check constraint*).
- [ ] `modalidad` y la especialización existente deben ser coherentes.

---

### ACT-10 · Grupo G7 — Envío y entrega (2 entidades)
**Objetivo:** permitir que un viaje agrupe varios pedidos y registrar la evidencia de entrega.
**Precondición:** ACT-07, ACT-09.
**Tiempo:** 45 min
**Entidades:** `Envio`, `Entrega`

**`Envio.entity`** — nueva (M13)
```
// Un viaje agrupa varios pedidos en un transporte - resuelve H13
@AggregateRoot
@DbTable(DIS_ENVIO)
Envio {
  id               : int      { @Id @AutoIncremented } ;
  consecutivo      : string   { @NotNull @MaxLen(20) } ;
  fechaProgramada  : datetime { @NotNull } ;
  fechaSalidaReal  : datetime ;
  fechaLlegadaReal : datetime ;
  estado           : string   { @NotNull @MaxLen(15) @DefaultValue("PROGRAMADO") } ;
  pesoCargadoKg    : decimal  { @Size(12,3) @Min(0) } ;
  observaciones    : string   { @LongText } ;

  transporteId : int { @NotNull @FK(FK_ENV_TRA, Transporte) } ;

  transporte : Transporte { @LinkByFK(FK_ENV_TRA) } ;
  pedidos    : Pedido[]   { @MappedBy(envio) } ;
}
```

**`Entrega.entity`** — nueva (M17)
```
// Evidencia de cumplimiento de la entrega - resuelve H17
@DbTable(DIS_ENTREGA)
Entrega {
  pedidoId           : int      { @Id @FK(FK_ENT_PED, Pedido) } ;   // 1:1 con Pedido
  fechaEntrega       : datetime { @NotNull } ;
  nombreReceptor     : string   { @NotNull @MaxLen(80) } ;
  documentoReceptor  : string   { @MaxLen(20) } ;
  cantidadRecibida   : decimal  { @Size(12,3) @Min(0) } ;
  conNovedad         : boolean  { @NotNull @DefaultValue(false) } ;
  descripcionNovedad : string   { @LongText } ;
  evidenciaUrl       : string   { @MaxLen(255) } ;

  pedido : Pedido { @LinkByFK(FK_ENT_PED) } ;
}
```

**Verificación**
- [ ] Un envío puede llevar varios pedidos; un pedido va en un solo envío.
- [ ] `Entrega` no puede existir sin `Pedido`.
- [ ] `le` lista ahora **22 entidades**.

---

## FASE 2 — Validación del modelo

### ACT-11 · Validación sintáctica con `cm`
**Objetivo:** dejar el modelo sin un solo error de sintaxis o de referencia.
**Precondición:** ACT-10.
**Tiempo:** 1 h (incluye corrección)

**Pasos**
1. `cm` sobre el modelo completo.
2. Corregir los errores en orden: nombres → tipos → anotaciones → referencias.
3. Repetir hasta obtener cero errores.
4. Registrar en la bitácora cada error encontrado y su causa (material valioso para la sustentación).

**Errores frecuentes y su causa** (ver también Anexo C)

| Mensaje / síntoma | Causa | Corrección |
|---|---|---|
| Nombre de entidad no coincide con el archivo | Se renombró el archivo pero no el bloque interno | Igualar ambos |
| Carácter no permitido en el nombre | Tilde o `ñ` (`Separación`, `tamaño`) | Quitar tildes y `ñ` |
| Error de parseo en el bloque de anotaciones | Coma entre anotaciones | Eliminar la coma (prohibida desde 4.0) |
| Entidad referenciada no encontrada | La entidad destino aún no existe | Crear primero lo referenciado |
| Falta `;` | Definición sin terminar | Agregar `;` |
| Anotación desconocida | `@SizeMax` / `@SizeMin` (deprecadas) | Usar `@MaxLen` / `@MinLen` |
| Tipo desconocido | `timestamp` en versión ≥ 4.3 o `datetime` en versión < 4.3 | Ajustar al tipo válido de la versión |

**Verificación**
- [ ] `cm` termina sin errores ni advertencias.
- [ ] Bitácora de errores documentada.

---

### ACT-12 · Validación semántica con lista de chequeo
**Objetivo:** verificar que el modelo es correcto como **modelo de negocio**, no solo como sintaxis.
**Precondición:** ACT-11.
**Tiempo:** 1 h

**Lista de chequeo (20 puntos)**

*Integridad estructural*
- [ ] 1. Las 22 entidades tienen `@Id`.
- [ ] 2. Todos los atributos tienen tipo neutro válido.
- [ ] 3. Todos los `string` tienen `@MaxLen`.
- [ ] 4. Todos los `decimal` tienen `@Size(precision,escala)`.
- [ ] 5. Toda FK tiene su `@FK(nombre, Entidad)` con nombre explícito.
- [ ] 6. Todo link tiene `@LinkByFK` apuntando a una FK existente.
- [ ] 7. Todo lado inverso de una relación usa `@MappedBy`.

*Fidelidad al caso*
- [ ] 8. Las 11 entidades originales están representadas.
- [ ] 9. Los 9 atributos originales están presentes o trazados a su nueva ubicación.
- [ ] 10. Las 2 generalizaciones del caso son visibles en el modelo.

*Reglas de negocio*
- [ ] 11. Un pedido puede llevar varios productos con cantidades distintas.
- [ ] 12. Toda cantidad tiene unidad de medida asociada.
- [ ] 13. Toda tarea pertenece a un pedido.
- [ ] 14. Un pedido puede tener varias tareas del mismo tipo.
- [ ] 15. Un envío puede llevar varios pedidos.
- [ ] 16. Se puede rastrear un pedido hasta el lote y la parcela de origen.
- [ ] 17. El estado del pedido tiene un ciclo de vida ordenado.

*Calidad*
- [ ] 18. No hay atributos de texto libre que deberían ser referencias.
- [ ] 19. No hay atributos repetidos entre entidades relacionadas.
- [ ] 20. Ningún nombre contiene tildes, `ñ` ni caracteres especiales.

**Artefacto:** lista de chequeo firmada + acciones correctivas.

---

### ACT-13 · Prueba de escritorio con datos reales
**Objetivo:** demostrar que el modelo soporta un caso de negocio completo sin contradicciones. **Esta es la mejor validación que existe.**
**Precondición:** ACT-12.
**Tiempo:** 1 h

**Escenario de prueba**

> *La finca La Esperanza (Rionegro) despacha 200 kg de aguacate hass del lote L-2026-045 y 80 kg de tomate chonto del lote L-2026-051 al cliente Distribuidora Central (NIT 900123456), canal MAYORISTA, con entrega comprometida el viernes. La separación se hace el jueves a las 6 a.m., el empaque en 20 canastillas plásticas de 10 kg, y el despacho sale el jueves 2 p.m. en el camión de placa ABC123 de Transportes del Oriente, junto con otros dos pedidos.*

**Pasos**
1. Escribir el escenario en filas concretas por entidad.
2. Verificar que **cada dato** del escenario tiene dónde guardarse.
3. Marcar todo dato que no encuentre lugar → indica una carencia del modelo.
4. Formular 10 preguntas de negocio y verificar que el modelo permite responderlas:
   - ¿Cuántos kilos de aguacate se despacharon esta semana?
   - ¿De qué parcela salió el aguacate del pedido 1045?
   - ¿Qué pedidos van en el envío del jueves?
   - ¿Cuánto tiempo tomó el empaque del pedido 1045?
   - ¿Qué pedidos están sin despachar y ya pasaron su fecha de compromiso?
   - ¿Cuántas canastillas se usaron este mes?
   - ¿Qué clientes compran por canal mayorista?
   - ¿Qué transportador mueve más peso?
   - ¿Qué pedidos se entregaron con novedad?
   - ¿Qué merma tuvo la separación del lote L-2026-045?
5. Documentar los ajustes que resulten.

**Verificación**
- [ ] El escenario se representa completo, sin campos "sobrantes" ni datos sin lugar.
- [ ] Las 10 preguntas son respondibles con las relaciones existentes.

> Si alguna pregunta no se puede responder, **el modelo tiene un vacío real** y hay que volver a la fase de implementación. Es preferible descubrirlo aquí que después de generar el código.

---

## FASE 3 — Generación y verificación con Telosys

### ACT-14 · Instalación de bundles de plantillas
**Objetivo:** disponer de las plantillas para generar DDL y documentación.
**Precondición:** ACT-13.
**Tiempo:** 30 min

**Pasos**
1. `lbd` → listar los bundles disponibles en el depot.
2. `lbd sql` y `lbd plantuml` → filtrar por nombre.
3. `ib <bundle-sql> plantuml` → instalar.
4. `lb` → confirmar los bundles instalados.
5. `b <bundle>` → fijar el bundle actual.
6. `lt` → listar sus plantillas para saber qué produce cada una.

> Los nombres exactos de los bundles cambian con el tiempo: **descúbrelos con `lbd`** en lugar de asumirlos. `ib` acepta una parte del nombre, así que `ib plantuml` basta.

**Verificación**
- [ ] `lb` muestra al menos dos bundles instalados.
- [ ] `lt` lista plantillas del bundle actual.

---

### ACT-15 · Generación del esquema de base de datos (DDL)
**Objetivo:** obtener el script SQL del modelo — la prueba objetiva de que el modelo es implementable.
**Precondición:** ACT-14.
**Tiempo:** 45 min

**Pasos**
1. `b <bundle-sql>` → fijar el bundle SQL.
2. `gen * *` → generar para todas las entidades.
3. Revisar el script generado: 22 tablas, PK, FK y tipos SQL.
4. Verificar puntualmente que:
   - Las PK compartidas (`Empaque`, `Separacion`, `Terrestre`, `Aereo`, `Acuatico`, `Entrega`) se generaron como PK **y** FK.
   - Los `decimal` conservan precisión y escala (`NUMERIC(12,3)`).
   - Los `string` con `@MaxLen` produjeron `VARCHAR(n)`.
   - Los `@LongText` produjeron un tipo de texto largo.
5. Registrar cualquier restricción que Telosys no genere (por ejemplo `@Unique` experimental) para añadirla a mano.

**Verificación**
- [ ] El script contiene 22 sentencias `CREATE TABLE`.
- [ ] Hay 23 restricciones de clave foránea.

---

### ACT-16 · Ejecución del DDL y carga de datos de prueba
**Objetivo:** llevar el modelo a una base de datos real y probarlo con los datos del escenario de ACT-13.
**Precondición:** ACT-15.
**Tiempo:** 1 h 30 min

**Pasos**
1. Levantar PostgreSQL (local o en contenedor).
2. Ejecutar el DDL generado. **Si falla, el modelo tiene un problema** — corregir el modelo, no el script.
3. Insertar los catálogos: unidades, estados, categorías, tipos de tarea, tipos de empaque.
4. Insertar el escenario completo de ACT-13.
5. Escribir y ejecutar las 10 consultas SQL de las preguntas de negocio.
6. Probar las restricciones: intentar insertar una línea sin unidad, una tarea sin pedido, un empaque sin tarea → deben ser rechazados.

**Verificación**
- [ ] El DDL se ejecuta sin errores en base vacía.
- [ ] Las 10 consultas devuelven resultados correctos.
- [ ] Las violaciones de integridad son efectivamente rechazadas.

> **Este es el criterio de éxito del proyecto.** Un modelo que carga datos reales y responde preguntas reales está validado; uno que solo se ve bonito en un diagrama, no.

---

### ACT-17 · Generación del diagrama de clases y contraste con el caso
**Objetivo:** producir el diagrama desde el modelo (no dibujarlo a mano) y compararlo con la lámina 7.
**Precondición:** ACT-15.
**Tiempo:** 45 min

**Pasos**
1. `b plantuml` → fijar el bundle.
2. `gen * *` → generar los archivos `.puml`.
3. Renderizar el diagrama (PlantUML local o en línea).
4. Colocar lado a lado el diagrama del caso y el generado.
5. Marcar con colores: **conservado** / **tipificado** / **normalizado** / **agregado**.
6. Redactar un párrafo de justificación por cada elemento agregado.

**Verificación**
- [ ] El diagrama se generó desde el modelo, sin edición manual.
- [ ] Las 11 entidades del caso se identifican visualmente en el diagrama nuevo.
- [ ] Las 2 generalizaciones del caso siguen siendo reconocibles.

> Comparación lado a lado del diagrama original contra el generado: es la lámina más contundente que puedes llevar a la sustentación.

---

### ACT-18 · Generación de clases en un lenguaje objetivo
**Objetivo:** comprobar que el modelo genera código compilable, cerrando el ciclo MDD.
**Precondición:** ACT-15.
**Tiempo:** 1 h

**Pasos**
1. `lbd java` → explorar los bundles de Java disponibles.
2. Instalar un bundle de entidades/dominio y fijarlo con `b`.
3. `gen * *`.
4. Compilar el código generado.
5. Verificar la conversión de tipos neutros al lenguaje destino (`decimal` → `BigDecimal`, `datetime` → tipo temporal correspondiente, etc.).

**Verificación**
- [ ] El código generado compila sin errores.
- [ ] Las 22 clases existen con sus atributos y relaciones.

---

## FASE 4 — Evolución y entrega

### ACT-19 · Prueba de evolución del modelo
**Objetivo:** demostrar el valor real del MDD: **cambiar el modelo y propagar el cambio sin editar código**.
**Precondición:** ACT-18.
**Tiempo:** 30 min

**Pasos**
1. Elegir un cambio realista: agregar `prioridad : short` a `Pedido`.
2. `ee Pedido` → agregar el atributo.
3. `cm` → validar.
4. Regenerar DDL, diagrama y clases.
5. Verificar que el cambio aparece en **los tres artefactos** sin haberlos tocado.
6. **Cronometrar el ejercicio completo** y anotar el tiempo.

**Verificación**
- [ ] El atributo aparece en el DDL, en el diagrama y en las clases.
- [ ] Tiempo total registrado (típicamente menos de 5 minutos).

> Este es *el* argumento del enfoque: un cambio de modelo que se propaga a tres artefactos en minutos. Compáralo con lo que costaría hacerlo a mano en 22 entidades y tendrás la justificación completa de por qué se usó Telosys.

---

### ACT-20 · Versionado del modelo en Git
**Objetivo:** tratar el modelo como el artefacto de primera clase que es.
**Precondición:** ACT-19.
**Tiempo:** 30 min

**Pasos**
1. Inicializar el repositorio (si no existe).
2. **Versionar siempre:** `TelosysTools/models/`, `TelosysTools/templates/`, `telosys-tools.cfg`.
3. **Excluir:** código generado, artefactos de compilación, credenciales.
4. Convención de commits: `modelo(<entidad>): <cambio>` — por ejemplo `modelo(Pedido): agregar atributo prioridad`.
5. Etiquetar la versión validada: `v1.0-modelo-dis`.
6. Escribir un `README.md` que explique cómo regenerar todo desde cero.

**Verificación**
- [ ] Un clon limpio permite regenerar los tres artefactos.
- [ ] El historial de Git cuenta la evolución del modelo de forma legible.

> **Decisión:** el código generado **no** se versiona. Se versiona lo que lo produce (modelo + plantillas). Si alguien necesita el código, lo regenera.

---

### ACT-21 · Documentación y matriz de trazabilidad
**Objetivo:** demostrar que cada elemento del modelo se justifica desde el caso.
**Precondición:** ACT-20.
**Tiempo:** 1 h 30 min

**Documentos a producir**

| Documento | Contenido |
|---|---|
| `docs/analisis-caso.md` | Los 17 hallazgos con evidencia |
| `docs/diccionario-datos.md` | Entidad, atributo, tipo, restricciones, descripción, origen |
| `docs/matriz-trazabilidad.md` | Caso → modelo → tabla (ver Anexo A) |
| `docs/decisiones.md` | Decisiones de diseño con su alternativa descartada |
| `docs/convenciones-modelo.md` | Producido en ACT-03 |
| `docs/bitacora-errores.md` | Errores de `cm` y sus causas |

**Verificación**
- [ ] Todo elemento agregado tiene su justificación escrita.
- [ ] Todo elemento del caso aparece en la matriz de trazabilidad.

---

### ACT-22 · Preparación de la sustentación
**Objetivo:** poder defender el modelo con evidencia, no con opiniones.
**Precondición:** ACT-21.
**Tiempo:** 1 h

**Guion sugerido (12 minutos)**

| Min | Contenido |
|---|---|
| 0–2 | Diagrama del caso + los 4 hallazgos bloqueantes (con énfasis en `Separación` y `tamaño`: no compilan) |
| 2–4 | Modelo mejorado: de 11 elementos y 9 atributos a 22 entidades y 23 relaciones |
| 4–6 | Las 3 decisiones fuertes: `LineaPedido`, catálogo vs. ejecución de tareas, herencia por tabla-por-subtipo |
| 6–8 | Demostración en vivo: `le`, `cm`, abrir un `.entity` |
| 8–10 | Escenario de ACT-13 en la base de datos + 3 consultas de negocio |
| 10–12 | **Evolución en vivo:** agregar un atributo, regenerar los 3 artefactos, mostrar el cronómetro |

**Preguntas probables y respuesta preparada**

| Pregunta | Respuesta |
|---|---|
| "¿Por qué agregó entidades que no están en el caso?" | Cada una resuelve un hallazgo documentado; sin ellas el diagrama no es implementable (mostrar la matriz H→M) |
| "¿Por qué no usó `@Extends` para la herencia?" | La interpretación depende del bundle; tabla-por-subtipo es portable y verificable. La alternativa está documentada |
| "¿Por qué `LineaPedido` si el caso no la tiene?" | Sin ella un pedido solo podría llevar un producto: la relación es M:N con atributos propios |
| "¿Qué pasó con `Empaque.tiempo`?" | Se desambiguó como `Tarea.duracionMinutos`, porque aplica a cualquier tarea, no solo al empaque |
| "¿Por qué no incluyó rutas ni costos?" | Disciplina de alcance: pertenecen a la capa de servicios, no al modelo de dominio |

---

# PARTE IV — Cronograma y control

## 4.1. Resumen de actividades

| Fase | Actividades | Tiempo estimado |
|---|---|---|
| **F0 · Preparación** | ACT-01 → ACT-03 | 1 h 30 min |
| **F1 · Implementación** | ACT-04 → ACT-10 | 8 h 30 min |
| **F2 · Validación** | ACT-11 → ACT-13 | 3 h |
| **F3 · Generación** | ACT-14 → ACT-18 | 4 h 30 min |
| **F4 · Evolución y entrega** | ACT-19 → ACT-22 | 3 h 30 min |
| | **Total** | **≈ 21 h** |

## 4.2. Ruta crítica

```
ACT-01 → ACT-02 → ACT-03 → ACT-04 → ACT-07 → ACT-08 → ACT-11 → ACT-15 → ACT-16
```

`ACT-05`, `ACT-06`, `ACT-09` y `ACT-10` pueden avanzar en paralelo una vez terminada `ACT-04`.

## 4.3. Distribución sugerida en 4 sesiones

| Sesión | Actividades | Resultado visible al terminar |
|---|---|---|
| **1** (3 h) | ACT-01 → ACT-04 | Los 5 catálogos creados y `cm` limpio |
| **2** (5 h) | ACT-05 → ACT-10 | Las 22 entidades escritas |
| **3** (5 h) | ACT-11 → ACT-16 | Modelo validado + base de datos cargada con datos reales |
| **4** (4 h) | ACT-17 → ACT-22 | Diagrama, clases, documentación y sustentación lista |

## 4.4. Criterio de terminado (DoD del modelo)

- [ ] 22 entidades implementadas y `cm` sin errores.
- [ ] Lista de chequeo de 20 puntos completa.
- [ ] Escenario de negocio cargado en base de datos real.
- [ ] Las 10 preguntas de negocio respondidas con SQL.
- [ ] DDL, diagrama de clases y clases generados desde el modelo.
- [ ] Prueba de evolución ejecutada y cronometrada.
- [ ] Los 6 documentos de `docs/` completos.
- [ ] Modelo versionado y etiquetado en Git.

---

# ANEXOS

## Anexo A — Matriz de trazabilidad: caso → modelo mejorado

| Elemento del caso | Destino en el modelo | Tratamiento | Justificación |
|---|---|---|---|
| `Cliente` | `Cliente` | Enriquecida | Se agregan identificación y contacto |
| `Producto.identificador` | `Producto.identificador` | Conservado | Código de negocio, no PK |
| `Producto.fechaElaboracion` | `Producto.fechaElaboracion` | Tipificado como `date` | — |
| `CanalesComercializacion` | `CanalComercializacion` | Renombrada a singular | Convención de nombrado |
| `Pedido.identificador` | `Pedido.identificador` | Conservado | Código de negocio |
| `Pedido.fechaEntrada` | `Pedido.fechaEntrada` | Tipificado como `datetime` | Requiere hora |
| `Pedido.fechaSalida` | `Pedido.fechaSalida` | Tipificado como `datetime` | Opcional (nulo hasta despacho) |
| `Empaque.tipo` | `Empaque.tipoEmpaqueId` → `TipoEmpaque` | **Normalizado** | Era texto libre; ahora catálogo |
| `Empaque.tamaño` | `Empaque.tamano` | **Renombrado** | La `ñ` no es válida en Telosys |
| `Empaque.cantidad` | `Empaque.cantidad` (`int`) | Tipificado | Número de empaques generados |
| `Empaque.tiempo` | `Tarea.duracionMinutos` | **Trasladado** | Aplica a toda tarea, no solo al empaque |
| `Separación` | `Separacion` | **Renombrada** | La tilde no es válida en Telosys |
| `Separación.lote` | `Separacion.loteId` → `Lote` | **Normalizado** | Habilita trazabilidad |
| `Separación.cantidad` | `Separacion.cantidad` (`decimal`) | Tipificado | Cantidad de producto |
| `TipoTarea` | `TipoTarea` (catálogo) + `Tarea` (ejecución) | **Dividida** | Separa el qué del cuándo/quién |
| `Transporte` | `Transporte` | Enriquecida | Capacidad, identificación, discriminador |
| `Terrestre` | `Terrestre` | Enriquecida | 5 atributos propios |
| `Aereo` | `Aereo` | Enriquecida | 5 atributos propios |
| `Acuatico` | `Acuatico` | Enriquecida | 6 atributos propios |
| — | `UnidadMedida`, `EstadoPedido`, `CategoriaProducto`, `TipoEmpaque` | **Agregadas** | Catálogos (M14, M07, M15, M09) |
| — | `Direccion` | **Agregada** | El pedido debe saber a dónde va |
| — | `Lote` | **Agregada** | Trazabilidad agro |
| — | `LineaPedido` | **Agregada** | Resuelve la relación M:N |
| — | `Tarea` | **Agregada** | Ancla la jerarquía de tareas al pedido |
| — | `Transportador` | **Agregada** | Quién presta el servicio |
| — | `Envio`, `Entrega` | **Agregadas** | Viaje con varios pedidos y evidencia de entrega |

## Anexo B — Resumen del modelo en números

| Métrica | Caso original | Modelo mejorado |
|---|---|---|
| Entidades | 11 | **22** |
| Atributos | 9 | **≈ 150** |
| Claves primarias | 0 | **22** |
| Claves foráneas | 0 | **23** |
| Relaciones con cardinalidad | 0 | **23** |
| Jerarquías | 2 (sin atributos) | **2 (con atributos propios)** |
| Catálogos | 0 | **5** |
| Restricciones de validación | 0 | **> 100** |
| Nombres inválidos en Telosys | 2 | **0** |

## Anexo C — Reglas de sintaxis Telosys (referencia rápida)

```
// ---- Estructura de una entidad ----
NombreEntidad {                       // debe coincidir con NombreEntidad.entity
   atributo : tipo { anotaciones y tags } ;   // termina en ';'
   link     : OtraEntidad   { ... } ;         // "a uno"
   links    : OtraEntidad[] { ... } ;         // "a muchos"
}

// ---- Reglas de nombrado ----
Entidad  : letras, numeros, "_"     (por convencion inicia en mayuscula)
Atributo : letras, numeros, "_"     (por convencion inicia en minuscula)
PROHIBIDO: tildes, ñ, espacios, #, +, -, $

// ---- Tipos neutros ----
string
byte  short  int  long  float  double  decimal
date  time   datetime  datetimetz  timetz     (timestamp deprecado desde 4.3.0)
boolean  uuid  binary

// ---- Anotaciones mas usadas ----
Entidad:   @AggregateRoot  @DbTable(X)  @ReadOnly  @Abstract  @Extends(X)  @Package(X)
Atributo:  @Id  @AutoIncremented  @GeneratedValue(AUTO|IDENTITY|SEQUENCE|TABLE)
           @NotNull  @NotEmpty  @NotBlank  @MaxLen(n)  @MinLen(n)
           @Size(p,e)  @Min(n)  @Max(n)  @DefaultValue(v)  @Label(t)
           @LongText  @Unique (experimental)  @Past  @Future  @FK(nombre, Entidad)
Link:      @LinkByFK(nombreFK)  @LinkByAttr(attr)  @MappedBy(attr)
           @OneToOne  @ManyToMany  @Optional  @Cascade(ALL|MERGE|PERSIST|REFRESH|REMOVE)
           @FetchTypeLazy  @FetchTypeEager  @OrphanRemoval

// ---- Prohibiciones ----
NO comas entre anotaciones          (prohibido desde 4.0)
NO comentarios multilinea           (solo // hasta fin de linea)
NO @SizeMax / @SizeMin              (deprecadas -> @MaxLen / @MinLen)
```

## Anexo D — Comandos Telosys usados en este plan

```bash
# Proyecto
h .            # fijar directorio HOME
init           # inicializar TelosysTools
cfg            # ver configuracion
ver            # version de Telosys
?              # ayuda general
? cm           # ayuda de un comando

# Modelo
nm dis_dominio # crear modelo
m  dis_dominio # fijar modelo actual
lm             # listar modelos
em             # editar model.yaml
cm             # CHECK MODEL  <- el comando mas importante

# Entidades
ne Pedido      # crear entidad
ee Pedido      # editar entidad
le             # listar entidades
de Pedido      # eliminar entidad

# Bundles
lbd            # listar bundles del depot
lbd plantuml   # filtrar por nombre
ib plantuml    # instalar
lb             # listar instalados
b  plantuml    # fijar bundle actual
lt             # listar plantillas del bundle

# Generacion
gen * *        # generar todo
gen Pedido *   # generar solo una entidad
genb           # generacion por lotes
```

## Anexo E — Catálogo de datos semilla sugerido

| Catálogo | Valores |
|---|---|
| `UnidadMedida` | KG (1.0), TON (1000.0), CAJ, CAN, SAC, UND, BUL |
| `EstadoPedido` | REGISTRADO (1) · EN_PREPARACION (2) · LISTO (3) · DESPACHADO (4) · EN_TRANSITO (5) · ENTREGADO (6, final) · CANCELADO (7, final) |
| `CategoriaProducto` | FRUTA · HORTALIZA · FLORES · GRANO · TUBERCULO |
| `TipoTarea` | SEPARACION (1, con detalle) · EMPAQUE (2, con detalle) · ROTULADO (3) · CARGUE (4) |
| `TipoEmpaque` | CAJA CARTON · CANASTILLA PLASTICA · SACO FIQUE · GUACAL MADERA · BOLSA |

Las tres primeras categorías de producto coinciden deliberadamente con las especializaciones de `Sembrado` (Fruta, Hortaliza, Flores) que el caso define en el macroproceso de **Producción [PRO]**: es la costura natural entre los dos módulos y conviene señalarla.

---

*Plan de implementación del modelo de dominio del macroproceso de Distribución [DIS] — caso de estudio EverGreen (Juan Bernardo Quintero). Sintaxis del DSL, tipos neutros, anotaciones y comandos verificados contra la documentación oficial de Telosys 4.x (doc.telosys.org). Versión 2.0 — julio de 2026.*
