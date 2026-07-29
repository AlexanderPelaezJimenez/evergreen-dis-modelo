# Guion de sustentación (ACT-22)

Guion de 12 minutos, con los comandos exactos a ejecutar en vivo (ya probados durante la implementación) para cada bloque.

## 0–2 min · El diagrama del caso y los hallazgos bloqueantes

- Mostrar la lámina 7 del caso: 11 elementos, 9 atributos, 0 claves primarias, 0 tipos de dato.
- Énfasis en H03/H04: `Separación` (tilde) y `tamaño` (`ñ`) **no compilan** en Telosys — es el hallazgo más concreto porque se puede demostrar, no solo argumentar.
- Referencia: `docs/analisis-caso.md` (17 hallazgos con evidencia).

## 2–4 min · El modelo mejorado

- De 11 elementos y 9 atributos a **22 entidades**, verificadas con `cm`:
  ```
  telosys#(dis_dominio)> cm
  Model OK ('dis_dominio' loaded : 22 entities)
  ```
- Mostrar `docs/matriz-trazabilidad.md`: cada entidad agregada tiene su hallazgo o mejora de respaldo, ninguna es gratuita.

## 4–6 min · Las 3 decisiones fuertes

1. **`LineaPedido`** resuelve la relación M:N que el caso deja sin resolver (H05) — mostrar el archivo `LineaPedido.entity`.
2. **Catálogo vs. ejecución de tareas**: `TipoTarea` (`@ReadOnly`) vs. `Tarea` — mostrar cómo `Tarea.pedidoId` ancla la jerarquía huérfana del caso (H06).
3. **Herencia tabla-por-subtipo con PK=FK**: mostrar en el DDL generado que `dis_terrestre`, `dis_aereo` y `dis_acuatico` tienen `PRIMARY KEY (transporte_id)` — portable frente a cualquier bundle, decisión documentada en `docs/decisiones.md`.

## 6–8 min · Demostración en vivo con Telosys

```
telosys#(dis_dominio)> le          -- lista las 22 entidades
telosys#(dis_dominio)> cm          -- valida el modelo completo
telosys#(dis_dominio)> ee Pedido   -- abrir un .entity y mostrar las anotaciones
```

## 8–10 min · Escenario de negocio en base de datos real

- Base de datos PostgreSQL 16 corriendo en Docker (`docker compose up -d`), cargada con el escenario de la finca La Esperanza (`docs/prueba-escritorio-act13.md`).
- Ejecutar 2 o 3 de las 10 consultas de negocio en vivo:
  ```bash
  docker compose exec -T db psql -U evergreen -d evergreen_dis < db/queries/10-preguntas-negocio.sql
  ```
- Mostrar además una violación de integridad rechazada en vivo (por ejemplo, insertar una `Tarea` sin `pedido_id` y que PostgreSQL la rechace con `NOT NULL constraint`).

## 10–12 min · Evolución en vivo

- Repetir ACT-19: agregar un atributo a `Pedido` (o usar otro campo nuevo a modo de demostración), correr `cm`, regenerar DDL + diagrama + clases Java, y mostrar el cambio propagado en los tres artefactos.
- Mencionar el tiempo real medido: **~40 segundos** de edición a los tres artefactos regenerados (`docs/act19-evolucion.md`).

## Preguntas probables y respuesta preparada

| Pregunta | Respuesta |
|---|---|
| "¿Por qué agregó entidades que no están en el caso?" | Cada una resuelve un hallazgo documentado; sin ellas el diagrama no es implementable — mostrar `docs/matriz-trazabilidad.md`. |
| "¿Por qué no usó `@Extends` para la herencia?" | Depende del bundle usado para generar; tabla-por-subtipo es portable y quedó verificado en el DDL real generado. La alternativa está documentada en `docs/decisiones.md`. |
| "¿Por qué `LineaPedido` si el caso no la tiene?" | Sin ella un pedido solo podría llevar un producto; la relación real es M:N con cantidad, precio y lote propios. |
| "¿Qué pasó con `Empaque.tiempo`?" | Se desambiguó como `Tarea.duracionMinutos`, porque aplica a cualquier tarea, no solo al empaque — cargado en el escenario con valor real (90 min). |
| "¿Por qué no incluyó rutas ni costos?" | Disciplina de alcance: pertenecen a la capa de servicios o a otros macroprocesos (FIN, MEN, ADM), no al modelo de dominio de Distribución. |
| "¿Cómo garantizan que el modelo funciona con datos reales y no solo en el papel?" | Se cargó en PostgreSQL real vía Docker, con un escenario completo y las 10 preguntas de negocio respondidas con SQL — no es solo un diagrama, es una base de datos funcionando. |
| "¿Por qué Docker y no una instalación local de PostgreSQL?" | El repositorio se comparte con compañeros de distintos sistemas operativos; `docker-compose.yml` reproduce la misma versión de motor con un solo comando, sin instrucciones distintas por SO. |

## Checklist antes de sustentar

- [ ] `docker compose up -d` levanta la base sin errores (probar con el volumen limpio: `docker compose down -v && docker compose up -d`).
- [ ] `cm` sigue devolviendo "Model OK" (22 entities).
- [ ] Las 10 consultas de negocio corren sin error.
- [ ] Tener a la mano: `docs/analisis-caso.md`, `docs/matriz-trazabilidad.md`, `docs/decisiones.md`, `model-doc/dis_dominio.plantuml` renderizado.
