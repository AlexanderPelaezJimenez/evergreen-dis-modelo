# Análisis del caso — 17 hallazgos con evidencia (ACT-21)

Diagnóstico original del diagrama del caso (lámina 7: *Macroproceso de Distribución [DIS]*) y evidencia de cómo quedó resuelto cada hallazgo en el modelo `dis_dominio` realmente implementado (22 entidades, `cm` → Model OK).

| ID | Hallazgo | Severidad | Evidencia de la resolución |
|---|---|---|---|
| H01 | Ninguna entidad declara clave primaria | 🔴 Bloqueante | Las 22 entidades tienen `@Id` — verificado por búsqueda automática sobre los `.entity`, 0 faltantes (ver `docs/lista-chequeo-modelo.md`, punto 1). |
| H02 | Ningún atributo declara tipo de dato | 🔴 Bloqueante | Todos los atributos usan tipos neutros de Telosys (`int`, `short`, `decimal`, `string`, `boolean`, `date`, `datetime`); el DDL generado en `sql/postgresql-create-tables.sql` confirma la traducción a `integer`, `smallint`, `numeric(p,e)`, `varchar(n)`, `boolean`, `date`, `timestamp`. |
| H03 | `Separación` lleva tilde: nombre inválido en Telosys | 🔴 Bloqueante | La entidad se creó directamente como `Separacion` (`Separacion.entity`); búsqueda de caracteres acentuados en nombres de entidad/atributo sobre los 22 archivos: 0 coincidencias. |
| H04 | `tamaño` lleva `ñ`: nombre de atributo inválido | 🔴 Bloqueante | El atributo se implementó como `Empaque.tamano`; misma verificación anterior, 0 coincidencias. |
| H05 | `Pedido`–`Producto` es M:N con datos propios, dibujada como asociación simple | 🔴 Bloqueante | Resuelto con la entidad asociativa `LineaPedido` (`cantidad`, `precioUnitario`, `descuentoPorcentaje`, `subtotal`, `loteId`, `unidadCodigo`). Verificado en la prueba de escritorio (`docs/prueba-escritorio-act13.md`): el pedido PED-1045 tiene 2 líneas con 2 productos distintos. |
| H06 | La jerarquía `TipoTarea` está huérfana, sin conexión a `Pedido` | 🔴 Bloqueante | Se creó `Tarea` con FK obligatoria `pedidoId` (`@NotNull @FK(FK_TAR_PED, Pedido)`). Probado en base de datos real: `INSERT INTO dis_tarea` sin `pedido_id` fue rechazado por `NOT NULL constraint` (ver prueba de integridad de ACT-16). |
| H07 | `TipoTarea` confunde catálogo con ejecución | 🟠 Alta | Se dividió en `TipoTarea` (catálogo `@ReadOnly`, 4 filas semilla: SEPARACION, EMPAQUE, ROTULADO, CARGUE) y `Tarea` (ejecución, con `fechaInicio`, `fechaFin`, `responsable`, `estado`). |
| H08 | `Pedido` no tiene estado ni ciclo de vida | 🟠 Alta | `EstadoPedido` (catálogo ordenado, 7 filas: REGISTRADO→CANCELADO, con `orden` y `esFinal`) + FK obligatoria `Pedido.estadoCodigo`. |
| H09 | No hay dirección de entrega | 🟠 Alta | `Direccion` con FK obligatoria `Pedido.direccionEntregaId`; en el escenario cargado cada uno de los 3 pedidos tiene su dirección propia. |
| H10 | `Empaque.tipo` y `Separacion.lote` son texto libre que debería ser referencia | 🟠 Alta | Normalizados a `Empaque.tipoEmpaqueId → TipoEmpaque` y `Separacion.loteId → Lote`, ambos con FK `@NotNull`. |
| H11 | `Empaque.tiempo` es ambiguo (¿instante, duración, turno?) | 🟠 Alta | Trasladado a `Tarea.duracionMinutos : int`, aplicable a cualquier tipo de tarea, no solo empaque. Cargado en el escenario: 90 minutos para la tarea de empaque de PED-1045 (verificado con la consulta de negocio #4). |
| H12 | Los subtipos de `Transporte` no tienen atributos propios | 🟠 Alta | `Terrestre` (5 campos: tipoVehiculo, numeroEjes, modeloAno, conductor, licenciaConductor), `Aereo` (5 campos) y `Acuatico` (6 campos) — cada uno con datos reales del modo de transporte. |
| H13 | `Transporte` atado 1:1 a `Pedido`, no permite un viaje con varios pedidos | 🟠 Alta | Se introdujo `Envio` (agrupa transporte + fecha) con `Pedido.envioId` como FK opcional. Verificado en el escenario: 3 pedidos (PED-1045/1046/1047) comparten el mismo `ENV-2026-030` (consulta de negocio #3). |
| H14 | No hay unidad de medida ("cantidad 50" no dice si es kg o cajas) | 🟠 Alta | `UnidadMedida` (catálogo con `factorAKg`) referenciado por `LineaPedido.unidadCodigo` y `Separacion.unidadCodigo`, ambos `@NotNull`. |
| H15 | Sin trazabilidad por lote hacia el predio de origen | 🟡 Media | `Lote` con `predioOrigen`/`parcelaOrigen`; verificado con la consulta de negocio #2 ("La Esperanza" / "Rionegro" recuperados a partir de `PED-1045`). |
| H16 | `CanalesComercializacion` en plural rompe la convención de nombrado | 🟡 Media | Renombrada a `CanalComercializacion` (singular). |
| H17 | No hay registro de entrega efectiva | 🟡 Media | `Entrega` (1:1 con `Pedido`, PK=FK) con `nombreReceptor`, `conNovedad`, `descripcionNovedad`. Verificado en el escenario: `PED-1046` tiene una entrega con novedad registrada (consulta de negocio #9). |

## Balance final

| Métrica | Caso original | Modelo implementado |
|---|---|---|
| Entidades | 11 | 22 |
| Claves primarias | 0 | 22 (`cm` → Model OK) |
| Claves foráneas | 0 | 26 (verificadas en el DDL generado: 26 `ALTER TABLE ... ADD CONSTRAINT`) |
| Nombres inválidos en Telosys | 2 (`Separación`, `tamaño`) | 0 |
| Escenario de negocio cargado en base real | No aplicaba | Sí, PostgreSQL vía Docker, 10/10 preguntas de negocio respondidas |
