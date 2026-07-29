# Prueba de escritorio con datos reales (ACT-13)

## Escenario

> La finca La Esperanza (Rionegro) despacha 200 kg de aguacate hass del lote L-2026-045 y 80 kg de tomate chonto del lote L-2026-051 al cliente Distribuidora Central (NIT 900123456), canal MAYORISTA, con entrega comprometida el viernes. La separación se hace el jueves a las 6 a.m., el empaque en 20 canastillas plásticas de 10 kg, y el despacho sale el jueves 2 p.m. en el camión de placa ABC123 de Transportes del Oriente, junto con otros dos pedidos.

## Filas por entidad

| Entidad | Fila | Datos |
|---|---|---|
| `Cliente` | 1 | numeroDocumento=900123456, razonSocial="Distribuidora Central" |
| `Direccion` | 1 | clienteId=1, alias="Bodega principal", ciudad="Medellín" |
| `CanalComercializacion` | MAYORISTA | (dato semilla) |
| `CategoriaProducto` | FRUTA, HORTALIZA | (datos semilla) |
| `UnidadMedida` | KG | (dato semilla) |
| `Producto` | 1, 2 | identificador="AGH-001" nombre="Aguacate Hass" categoriaId=FRUTA; identificador="TOC-001" nombre="Tomate Chonto" categoriaId=HORTALIZA |
| `Lote` | 1, 2 | codigo="L-2026-045" productoId=1 predioOrigen="La Esperanza" parcelaOrigen="Rionegro"; codigo="L-2026-051" productoId=2 predioOrigen="La Esperanza" |
| `EstadoPedido` | REGISTRADO…DESPACHADO | (dato semilla) |
| `Pedido` | 1 | clienteId=1, direccionEntregaId=1, canalCodigo=MAYORISTA, fechaCompromisoEntrega=viernes, estadoCodigo=DESPACHADO |
| `LineaPedido` | 1, 2 | pedidoId=1 productoId=1 loteId=1 cantidad=200 unidadCodigo=KG; pedidoId=1 productoId=2 loteId=2 cantidad=80 unidadCodigo=KG |
| `TipoTarea` | SEPARACION, EMPAQUE | (dato semilla) |
| `Tarea` | 1, 2 | pedidoId=1 tipoTareaCodigo=SEPARACION fechaInicio=jueves 06:00; pedidoId=1 tipoTareaCodigo=EMPAQUE |
| `Separacion` | 1 | tareaId=1 loteId=1 cantidad=200 unidadCodigo=KG (una fila por lote separado; se repite análoga para el tomate) |
| `TipoEmpaque` | CANASTILLA PLASTICA | capacidadKg=10 |
| `Empaque` | 1 | tareaId=2 cantidad=20 tipoEmpaqueId=CANASTILLA |
| `Transportador` | 1 | razonSocial="Transportes del Oriente" |
| `Transporte` | 1 | transportadorId=1, modalidad=TERRESTRE, identificacion="ABC123" |
| `Terrestre` | 1 | transporteId=1, tipoVehiculo="CAMION" |
| `Envio` | 1 | transporteId=1, fechaProgramada=jueves 14:00 |
| `Pedido` | 1, +2 más | los tres pedidos con `envioId=1` |
| `Entrega` | — | se crea cuando el pedido llegue (aún no aplica en este corte del escenario) |

**Resultado:** cada dato del escenario tiene dónde guardarse. No quedan campos sobrantes ni datos sin lugar.

## Las 10 preguntas de negocio

| # | Pregunta | Cómo se responde con el modelo |
|---|---|---|
| 1 | ¿Cuántos kilos de aguacate se despacharon esta semana? | `SUM(LineaPedido.cantidad)` filtrando por `Producto.identificador='AGH-001'` y `Pedido.fechaSalida` en el rango de la semana. |
| 2 | ¿De qué parcela salió el aguacate del pedido 1045? | `LineaPedido → Lote.parcelaOrigen` para ese `pedidoId`. |
| 3 | ¿Qué pedidos van en el envío del jueves? | `Pedido` filtrado por `envioId` del `Envio` con `fechaProgramada` = jueves. |
| 4 | ¿Cuánto tiempo tomó el empaque del pedido 1045? | `Tarea.duracionMinutos` donde `tipoTareaCodigo='EMPAQUE'` y `pedidoId=1045`. |
| 5 | ¿Qué pedidos están sin despachar y ya pasaron su fecha de compromiso? | `Pedido` donde `fechaCompromisoEntrega < hoy` y `estadoCodigo` no es DESPACHADO/ENTREGADO. |
| 6 | ¿Cuántas canastillas se usaron este mes? | `SUM(Empaque.cantidad)` join `Tarea→Pedido` filtrando por `TipoEmpaque.nombre='CANASTILLA PLASTICA'` y rango de fecha. |
| 7 | ¿Qué clientes compran por canal mayorista? | `Pedido` join `Cliente` filtrando `canalCodigo='MAYORISTA'`, `DISTINCT cliente`. |
| 8 | ¿Qué transportador mueve más peso? | `SUM(Pedido.pesoTotalKg)` agrupado por `Envio→Transporte→Transportador`. |
| 9 | ¿Qué pedidos se entregaron con novedad? | `Pedido` join `Entrega` donde `conNovedad=true`. |
| 10 | ¿Qué merma tuvo la separación del lote L-2026-045? | `Separacion.mermaKg` donde `loteId` corresponde a `Lote.codigo='L-2026-045'`. |

**Resultado:** las 10 preguntas son respondibles con las relaciones existentes del modelo de 22 entidades. No se detectó ningún vacío que obligue a volver a la fase de implementación.

## Verificación

- [x] El escenario se representa completo, sin campos "sobrantes" ni datos sin lugar.
- [x] Las 10 preguntas son respondibles con las relaciones existentes.

> Esta prueba es conceptual (papel), previa a tener una base de datos real. La ejecución con SQL contra PostgreSQL corresponde a ACT-16, una vez generado el DDL en ACT-15.
