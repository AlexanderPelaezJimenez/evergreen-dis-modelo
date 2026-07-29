# Decisiones de diseño con su alternativa descartada (ACT-21)

## Decisiones sobre ambigüedades del caso original

| # | Ambigüedad | Decisión adoptada | Alternativa descartada | Por qué se descartó |
|---|---|---|---|---|
| A1 | ¿`TipoTarea` es catálogo o tarea ejecutada? | Ambas cosas, separadas: `TipoTarea` (catálogo) + `Tarea` (ejecución) | Una sola entidad `TipoTarea` con campos de ejecución mezclados | Un pedido puede requerir dos empaques distintos; con una sola entidad no hay forma de registrar dos ejecuciones del mismo tipo de tarea |
| A2 | ¿Qué mide `Empaque.tiempo`? | Duración en minutos, trasladada a `Tarea.duracionMinutos` | Dejarlo como `Empaque.tiempo` | El concepto de duración aplica a cualquier tarea (separación, rotulado, cargue), no solo al empaque; dejarlo en `Empaque` habría obligado a duplicar el campo en `Separacion` |
| A3 | ¿`Empaque.cantidad` cuenta empaques o producto? | Número de empaques generados (`int`) | Cantidad de producto (`decimal`), igual que en `Separacion` | `Separacion.cantidad` sí es cantidad física de producto; unificar ambos significados en un solo nombre habría ocultado que son magnitudes distintas |
| A4 | ¿`Producto.identificador` es la PK? | No: se conserva como código de negocio; la PK es técnica (`id`) | Usar `identificador` como PK | Permite que el código de negocio cambie (ej. por una recodificación comercial) sin romper las FK que ya apuntan al producto |
| A5 | ¿Un pedido lleva un solo producto? | No: relación M:N vía `LineaPedido` | Mantener la asociación simple `Pedido`–`Producto` del diagrama | Es la realidad operativa de cualquier pedido de distribución; la asociación simple del caso es irrealizable en la práctica (hallazgo H05) |
| A6 | ¿Un transporte atiende un solo pedido? | No: se introduce `Envio` que agrupa pedidos | Mantener `Transporte`–`Pedido` 1:1 | Un camión sale con varios pedidos en el mismo viaje; forzar 1:1 obligaría a un vehículo por pedido, contrario a cómo opera EverGreen |
| A7 | ¿`Separacion.lote` es texto o entidad? | Entidad `Lote` | Dejarlo como `string` libre | Sin una entidad `Lote` no hay forma de conectar la separación con el predio/parcela de origen (trazabilidad agroalimentaria, hallazgo H15) |

## Decisión de herencia (Parte 2.4 del plan)

**Decisión adoptada:** tabla-por-subtipo con clave primaria compartida (PK = FK) para las dos jerarquías del caso (`Transporte`→`Terrestre`/`Aereo`/`Acuatico` y `Tarea`→`Empaque`/`Separacion`), usando `@Id @FK(...)` sobre el mismo atributo en la entidad hija.

**Alternativa descartada:** usar las anotaciones nativas de Telosys `@Abstract` en la superclase y `@Extends(...)` en cada hija.

**Por qué se descartó:** la interpretación de `@Extends` depende de las plantillas del bundle usado para generar, y no hay garantía de que todo bundle (SQL, Java, documentación) la soporte igual. El patrón tabla-por-subtipo con PK=FK es portable frente a cualquier bundle, y quedó **verificado en la práctica**: el DDL generado (`sql/postgresql-create-tables.sql`) muestra `PRIMARY KEY (transporte_id)` en `dis_terrestre`/`dis_aereo`/`dis_acuatico`, y las 26 restricciones de FK generadas confirman la relación sin ambigüedad.

## Decisiones tomadas durante la implementación (no estaban en el plan original)

| Decisión | Alternativa descartada | Por qué |
|---|---|---|
| Usar el bundle `model-doc` para diagrama de clases y documentación HTML | Buscar un bundle llamado "plantuml" (como sugería el plan) | Ese nombre ya no existe en el depot de plantillas v4.3; `lbd` mostró que el bundle vigente es `model-doc`, que además entrega Mermaid y HTML sin costo adicional |
| Levantar PostgreSQL con Docker (`docker-compose.yml`) | Instalar PostgreSQL nativo vía Homebrew | El proyecto se va a compartir en un repositorio con compañeros de distintos sistemas operativos; Docker garantiza la misma versión de motor para todos con un solo comando, evitando instrucciones distintas por SO |
| Generar clases Java con `java-jpa-entities` | `java-domain-example` (también disponible en el depot) | `java-jpa-entities` genera directamente entidades anotadas con JPA/Jakarta Persistence, más cercano a un dominio persistente real, además de `pom.xml` y tests listos |
