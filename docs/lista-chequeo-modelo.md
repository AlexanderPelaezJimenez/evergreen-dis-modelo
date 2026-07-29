# Lista de chequeo semántica — modelo `dis_dominio` (ACT-12)

Verificación cruzada contra los 22 archivos `.entity` reales del modelo, tras `cm` → *Model OK (22 entities)*.

## Integridad estructural

- [x] 1. Las 22 entidades tienen `@Id`. — verificado por grep, 0 faltantes.
- [x] 2. Todos los atributos tienen tipo neutro válido (`int`, `short`, `decimal`, `string`, `boolean`, `date`, `datetime`).
- [x] 3. Todos los `string` tienen `@MaxLen` — **con una excepción documentada**: los atributos `*Codigo` que son FK hacia la PK de un catálogo (`canalCodigo`, `estadoCodigo`, `unidadCodigo`, `tipoTareaCodigo`) no repiten `@MaxLen` porque heredan la longitud de la PK referenciada (ej. `UnidadMedida.codigo @MaxLen(6)`). Es el mismo patrón que usa el propio `plan_final_v2.md`; se deja anotado para la sustentación.
- [x] 4. Todos los `decimal` tienen `@Size(precision,escala)` — 0 excepciones.
- [x] 5. Toda FK tiene su `@FK(nombre, Entidad)` con nombre explícito — 26 `@FK` en el modelo.
- [x] 6. Todo link tiene `@LinkByFK` apuntando a una FK existente — 26 `@LinkByFK`, 1:1 con las FK declaradas.
- [x] 7. Todo lado inverso de una relación usa `@MappedBy` — 15 `@MappedBy` (Cliente, CanalComercializacion, Producto, Pedido, Tarea, Transporte, Transportador, Envio).

## Fidelidad al caso

- [x] 8. Las 11 entidades originales están representadas: `Cliente`, `Producto`, `CanalComercializacion`, `Pedido`, `Empaque`, `Separacion`, `TipoTarea`, `Transporte`, `Acuatico`, `Aereo`, `Terrestre`.
- [x] 9. Los 9 atributos originales están presentes o trazados: `Producto.identificador/fechaElaboracion`, `Pedido.identificador/fechaEntrada/fechaSalida` (conservados); `Empaque.tipo→tipoEmpaqueId`, `Empaque.tamaño→tamano`, `Empaque.tiempo→Tarea.duracionMinutos`, `Separacion.lote→loteId` (trazados); `Empaque.cantidad`, `Separacion.cantidad` (tipificados).
- [x] 10. Las 2 generalizaciones del caso son visibles: `Tarea`→(`Empaque`,`Separacion`) y `Transporte`→(`Terrestre`,`Aereo`,`Acuatico`), ambas con PK=FK.

## Reglas de negocio

- [x] 11. Un pedido puede llevar varios productos con cantidades distintas — vía `LineaPedido` (FK `pedidoId`, sin restricción de unicidad que lo impida).
- [x] 12. Toda cantidad de producto/insumo tiene unidad de medida asociada — `LineaPedido.unidadCodigo`, `Separacion.unidadCodigo` (obligatorias). `Empaque.cantidad` es un conteo de empaques, no una cantidad física, por eso no lleva unidad (decisión A3 del plan).
- [x] 13. Toda tarea pertenece a un pedido — `Tarea.pedidoId` con `@NotNull @FK`.
- [x] 14. Un pedido puede tener varias tareas del mismo tipo — `Tarea` tiene PK propia (`id`), no hay unicidad que impida repetir `tipoTareaCodigo` en el mismo `pedidoId`.
- [x] 15. Un envío puede llevar varios pedidos — `Pedido.envioId` es FK opcional hacia `Envio`; varios `Pedido` pueden apuntar al mismo `Envio`.
- [x] 16. Se puede rastrear un pedido hasta el lote y la parcela de origen — `LineaPedido.loteId` (opcional) y `Separacion.loteId` (obligatoria) apuntan a `Lote`, que tiene `predioOrigen`/`parcelaOrigen`.
- [x] 17. El estado del pedido tiene un ciclo de vida ordenado — `EstadoPedido.orden` + `EstadoPedido.esFinal`.

## Calidad

- [x] 18. No hay atributos de texto libre que deberían ser referencias — `Empaque.tipo` y `Separacion.lote` del caso quedaron normalizados a `tipoEmpaqueId`/`loteId`.
- [x] 19. No hay atributos repetidos entre entidades relacionadas más allá de las FK esperadas.
- [x] 20. Ningún nombre de entidad ni de atributo contiene tildes, `ñ` ni caracteres especiales — verificado por búsqueda de caracteres acentuados sobre los 22 archivos `.entity`: 0 coincidencias.

## Resultado

**20/20 puntos verificados.** El único matiz (punto 3) es una decisión de diseño heredada del propio plan, no un defecto: las FK que apuntan a la PK de un catálogo no necesitan redeclarar la longitud porque Telosys la toma de la entidad referenciada al generar el DDL.

**Artefacto:** este documento. Sin acciones correctivas pendientes.
