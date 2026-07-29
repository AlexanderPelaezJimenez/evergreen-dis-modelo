# ACT-19 — Prueba de evolución del modelo

## Cambio realizado

Se agregó `prioridad : short` a `Pedido` (valores 1=urgente a 5=baja, `@NotNull @Min(1) @Max(5) @DefaultValue(3)`), editando únicamente `Pedido.entity`.

## Pasos ejecutados

1. `ee Pedido` (edición directa del archivo `.entity`) → se agregó el atributo.
2. `cm` → modelo validado sin errores.
3. Regeneración de los tres artefactos con Telosys:
   - `b database-sql-scripts` → `gen Pedido *`
   - `b model-doc` → `gen * *`
   - `b java-jpa-entities` → `gen Pedido *`
4. Verificación del cambio en cada artefacto, sin edición manual posterior.

## Resultado en cada artefacto

| Artefacto | Evidencia |
|---|---|
| DDL (`sql/postgresql-create-tables.sql`) | `prioridad smallint NOT NULL DEFAULT 3,` |
| Diagrama (`model-doc/dis_dominio.plantuml`) | `prioridad : short (NN)` dentro de la entidad `Pedido` |
| Clase Java (`src/main/java/org/demo/entities/Pedido.java`) | Campo `private short prioridad`, getter/setter y entrada en `toString()` |

## Tiempo cronometrado

**≈ 40 segundos** desde la edición del `.entity` hasta tener los tres artefactos regenerados (medido con timestamps de shell entre el inicio de la edición y el fin de la última generación). Muy por debajo del "menos de 5 minutos" que estima el plan — el tiempo real dominante es el de escribir los comandos, no el de generación (cada `gen` toma menos de 1 segundo).

## Verificación

- [x] El atributo aparece en el DDL, en el diagrama y en las clases.
- [x] Tiempo total registrado: ~40 s.

> Este es el argumento central del enfoque MDD: un cambio de una línea en el modelo se propaga a tres artefactos distintos sin escribir SQL, UML ni Java a mano.
