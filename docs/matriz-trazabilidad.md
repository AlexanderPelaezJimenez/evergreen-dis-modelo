# Matriz de trazabilidad: caso → modelo → tabla (ACT-21)

Cada fila conecta el diagrama original del caso con la entidad Telosys y la tabla física realmente generada en `sql/postgresql-create-tables.sql` y creada en PostgreSQL (`\dt` → 22 tablas).

| Elemento del caso | Entidad en `dis_dominio` | Tabla física | Tratamiento |
|---|---|---|---|
| `Cliente` | `Cliente` | `dis_cliente` | Enriquecida (identificación, contacto, `@Unique` en `numeroDocumento`) |
| `Producto.identificador` | `Producto.identificador` | `dis_producto.identificador` | Conservado como código de negocio, no PK |
| `Producto.fechaElaboracion` | `Producto.fechaElaboracion` | `dis_producto.fecha_elaboracion` | Tipificado `date` |
| `CanalesComercializacion` | `CanalComercializacion` | `dis_canal_comercializacion` | Renombrada a singular |
| `Pedido.identificador` | `Pedido.identificador` | `dis_pedido.identificador` | Conservado |
| `Pedido.fechaEntrada` | `Pedido.fechaEntrada` | `dis_pedido.fecha_entrada` | Tipificado `datetime` → `timestamp` |
| `Pedido.fechaSalida` | `Pedido.fechaSalida` | `dis_pedido.fecha_salida` | Tipificado `datetime`, opcional |
| `Empaque.tipo` | `Empaque.tipoEmpaqueId` → `TipoEmpaque` | `dis_empaque.tipo_empaque_id` (FK) | Normalizado: era texto libre, ahora catálogo |
| `Empaque.tamaño` | `Empaque.tamano` | `dis_empaque.tamano` | Renombrado (la `ñ` no es válida en Telosys) |
| `Empaque.cantidad` | `Empaque.cantidad` | `dis_empaque.cantidad` (`integer`) | Tipificado: número de empaques generados |
| `Empaque.tiempo` | `Tarea.duracionMinutos` | `dis_tarea.duracion_minutos` | Trasladado: aplica a toda tarea |
| `Separación` | `Separacion` | `dis_separacion` | Renombrada (tilde inválida en Telosys) |
| `Separación.lote` | `Separacion.loteId` → `Lote` | `dis_separacion.lote_id` (FK) | Normalizado: habilita trazabilidad |
| `Separación.cantidad` | `Separacion.cantidad` | `dis_separacion.cantidad` (`numeric(12,3)`) | Tipificado |
| `TipoTarea` | `TipoTarea` (catálogo) + `Tarea` (ejecución) | `dis_tipo_tarea` + `dis_tarea` | Dividida en catálogo y transacción |
| `Transporte` | `Transporte` | `dis_transporte` | Enriquecida: capacidad, identificación, discriminador `modalidad` |
| `Terrestre` | `Terrestre` | `dis_terrestre` | Enriquecida: 5 atributos propios |
| `Aereo` | `Aereo` | `dis_aereo` | Enriquecida: 5 atributos propios |
| `Acuatico` | `Acuatico` | `dis_acuatico` | Enriquecida: 6 atributos propios |
| *(sin equivalente)* | `UnidadMedida`, `EstadoPedido`, `CategoriaProducto`, `TipoEmpaque` | `dis_unidad_medida`, `dis_estado_pedido`, `dis_categoria_producto`, `dis_tipo_empaque` | Agregadas: catálogos (M14, M07, M15, M09) |
| *(sin equivalente)* | `Direccion` | `dis_direccion` | Agregada: el pedido debe saber a dónde va (H09) |
| *(sin equivalente)* | `Lote` | `dis_lote` | Agregada: trazabilidad agro (H15) |
| *(sin equivalente)* | `LineaPedido` | `dis_linea_pedido` | Agregada: resuelve la relación M:N (H05) |
| *(sin equivalente)* | `Tarea` | `dis_tarea` | Agregada: ancla la jerarquía de tareas al pedido (H06) |
| *(sin equivalente)* | `Transportador` | `dis_transportador` | Agregada: quién presta el servicio (H13) |
| *(sin equivalente)* | `Envio` | `dis_envio` | Agregada: viaje con varios pedidos (H13) |
| *(sin equivalente)* | `Entrega` | `dis_entrega` | Agregada: evidencia de entrega (H17) |

## Verificación cruzada

- **11 elementos del caso** → los 11 aparecen en la columna "Entidad en `dis_dominio`", ninguno se perdió (principio P1).
- **11 entidades agregadas** → cada una tiene su hallazgo (H0x) o mejora (M0x) de respaldo; ninguna es gratuita.
- **22 tablas físicas** confirmadas con `\dt` contra la base PostgreSQL real levantada en ACT-16.
