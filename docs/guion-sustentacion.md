# Guion de sustentación (ACT-22)

Guion de 12 minutos, con los comandos exactos a ejecutar en vivo (ya probados durante la
implementación) para cada bloque.

**Tesis a defender:** definimos un modelo de dominio y una herramienta (Telosys) generó a
partir de él una aplicación completa y funcionando. No escribimos código de la aplicación.

## Antes de empezar (fuera de tiempo)

Dejar los tres servicios arriba y las ventanas abiertas:

```bash
cd evergreen-dis-modelo && podman compose up -d      # PostgreSQL
cd evergreen-dis-api    && mvn spring-boot:run       # API  :8000
cd evergreen-dis-web    && npm start                 # SPA  :4200
```

Pestañas listas: la SPA en `localhost:4200`, Swagger en
`localhost:8000/swagger-ui/index.html`, y una terminal con el CLI de Telosys en la raíz del
repositorio.

## 0–2 min · El diagrama del caso y los hallazgos bloqueantes

- Mostrar la lámina 7 del caso: 11 elementos, 9 atributos, 0 claves primarias, 0 tipos de dato.
- Énfasis en H03/H04: `Separación` (tilde) y `tamaño` (`ñ`) **no compilan** en Telosys — es
  el hallazgo más concreto porque se puede demostrar, no solo argumentar.
- Referencia: `docs/analisis-caso.md` (17 hallazgos con evidencia).

## 2–4 min · El modelo mejorado

- De 11 elementos y 9 atributos a **22 entidades**, verificadas con `cm`:
  ```
  telosys#(dis_dominio)> cm
  Model OK ('dis_dominio' loaded : 22 entities)
  ```
- Mostrar `docs/matriz-trazabilidad.md`: cada entidad agregada tiene su hallazgo o mejora
  de respaldo, ninguna es gratuita.
- Abrir `Producto.entity` y señalar que **no menciona Java, SQL, TypeScript ni Angular**.
  El modelo describe el dominio; la tecnología la aporta el bundle.

## 4–6 min · Las 3 decisiones fuertes del modelo

1. **`LineaPedido`** resuelve la relación M:N que el caso deja sin resolver (H05) — mostrar
   el archivo `LineaPedido.entity`.
2. **Catálogo frente a ejecución de tareas**: `TipoTarea` (`@ReadOnly`) frente a `Tarea` —
   mostrar cómo `Tarea.pedidoId` ancla la jerarquía huérfana del caso (H06).
3. **Herencia tabla-por-subtipo con PK=FK**: mostrar en el DDL generado que `dis_terrestre`,
   `dis_aereo` y `dis_acuatico` tienen `PRIMARY KEY (transporte_id)` — portable frente a
   cualquier bundle, decisión documentada en `docs/decisiones.md`.

## 6–8 min · Un modelo, cinco generadores

Este es el bloque central: mostrar que **el mismo archivo** produce artefactos en
tecnologías distintas.

```
telosys#(dis_dominio)> lb          -- los bundles instalados
telosys#(dis_dominio)> b front-angular
telosys#(dis_dominio)> gen * * -r -y
```

> "Nueve formatos distintos salen de aquí: `.sql`, `.java`, `.ts`, `.html`, `.scss`,
> `.yml`, `.xml`, `.mermaid`, `.plantuml`. Telosys no conoce ninguno de esos lenguajes:
> Velocity solo sustituye texto. Todo el conocimiento técnico vive en las plantillas, y
> por eso los bundles se descargan por tecnología desde GitHub."

Cifras para citar: **82 + 115 + 179 archivos generados, 0 errores**, a partir de 22 archivos
`.entity` y 56 plantillas.

## 8–10 min · La aplicación funcionando

- Abrir la SPA. Señalar que el menú se agrupa en **Procesos / Detalle / Catálogos** y que
  esos grupos **salen del modelo**: `isAggregateRoot()` y `hasForeignKeys()`, no una lista
  escrita a mano.
- Entrar a Cliente, mostrar que los encabezados de la tabla usan los `@Label` del modelo
  (*"Codigo de negocio"* en lugar de *"identificador"*).
- **Crear un pedido en vivo**, pidiéndole al público el cliente y el canal. Señalar que los
  campos de clave foránea son desplegables poblados desde la API, deducidos de los
  `@LinkByFK` del modelo.
- Mostrar el registro recién creado en la base:
  ```bash
  podman compose exec -T db psql -U evergreen -d evergreen_dis -c "select id, identificador, cliente_id, estado_codigo from dis_pedido order by id desc limit 3;"
  ```
- Correr 2 o 3 de las 10 consultas de negocio y mostrar que el pedido nuevo ya aparece:
  ```bash
  podman compose exec -T db psql -U evergreen -d evergreen_dis < db/queries/10-preguntas-negocio.sql
  ```

## 10–12 min · Cuando el generador se queda corto

El bloque más fuerte del análisis, porque muestra criterio y no solo uso de la herramienta.

> "El bundle del depot no funcionaba tal cual. Tres defectos: 16 de 22 rutas devolvían 500
> por una ambigüedad de mapeo, el navegador bloqueaba todo por falta de CORS, y era
> imposible crear registros porque exigía llenar la clave primaria autogenerada."

Y la decisión que hay que defender:

> "El defecto de mapeo se podía arreglar quitando los `@LinkByFK` del modelo. Lo medimos:
> el DDL quedaba idéntico, byte por byte, con las mismas 26 restricciones. Pero el diagrama
> de clases perdía cinco asociaciones: `Producto` quedaba sin categoría y sin unidad de
> medida. Un mismo modelo alimenta varios generadores con necesidades opuestas. No
> degradamos el modelo para complacer a uno: corregimos el generador. Dos líneas en una
> plantilla arreglaron las 22 entidades a la vez."

Cerrar con la evolución (ACT-19): agregar un atributo a una entidad, `cm`, regenerar, y
mostrar el cambio propagado. Tiempo real medido: **~40 segundos** (`docs/act19-evolucion.md`).

## Preguntas probables y respuesta preparada

| Pregunta | Respuesta |
|---|---|
| "¿Por qué agregó entidades que no están en el caso?" | Cada una resuelve un hallazgo documentado; sin ellas el diagrama no es implementable — mostrar `docs/matriz-trazabilidad.md`. |
| "¿Por qué no usó `@Extends` para la herencia?" | Depende del bundle usado para generar; tabla-por-subtipo es portable y quedó verificado en el DDL real. Alternativa documentada en `docs/decisiones.md`. |
| "¿Por qué `LineaPedido` si el caso no la tiene?" | Sin ella un pedido solo podría llevar un producto; la relación real es M:N con cantidad, precio y lote propios. |
| "¿Qué pasó con `Empaque.tiempo`?" | Se desambiguó como `Tarea.duracionMinutos`, porque aplica a cualquier tarea — cargado en el escenario con valor real (90 min). |
| "¿Por qué no incluyó rutas ni costos?" | Disciplina de alcance: pertenecen a la capa de servicios o a otros macroprocesos (FIN, MEN, ADM). |
| **"Si modificaron las plantillas, ¿la aplicación sigue siendo generada?"** | Sí. Un generador tiene dos insumos y los dos los escribe una persona: el modelo dice *qué*, la plantilla dice *cómo*. Ningún archivo de la aplicación está escrito a mano. La prueba: escribimos **una** línea de CORS y el generador la aplicó en **22** controladores. |
| **"¿Todo el código sale del modelo?"** | Todo el que varía con el modelo, sí. Quedan 12 archivos de andamiaje del framework (los `tsconfig`, `package.json`, el favicon) que el bundle copia literalmente y que no mencionan ninguna entidad del dominio. Serían idénticos para cualquier proyecto Angular. |
| **"¿Por qué no convirtieron esos 12 a plantillas también?"** | Porque el criterio en MDE no es *plantilla frente a estático*, sino si el artefacto varía con el modelo. Además lo probamos: el favicon es binario y Velocity lo corrompería, y `angular.json` y el interceptor de errores fallan porque contienen `$schema` y `${err.status}`, que Velocity interpreta como variables propias. |
| **"¿La aplicación es segura?"** | No, y está documentado. El bundle genera 44 endpoints con CRUD completo sin autenticación, y no lo advierte. Es un límite conocido del generador, aceptable para una demostración local. |
| "¿Cómo garantizan que el modelo funciona con datos reales?" | Está en PostgreSQL real, con un escenario completo, las 10 preguntas respondidas y registros creados en vivo desde la interfaz. |
| "¿Por qué contenedores y no PostgreSQL nativo?" | El repositorio se comparte entre distintos sistemas operativos; el `docker-compose.yml` reproduce la misma versión de motor con un comando, y funciona igual con Podman o Docker. |

## Anécdota útil si preguntan por integridad

Durante las pruebas se intentó crear un pedido con `canalCodigo: "MAY"`. PostgreSQL lo
rechazó:

```
insert or update on table "dis_pedido" violates foreign key constraint "FK_PED_CAN"
```

Los códigos reales son `MAYORISTA`, `PLAZA`, `EXPORTA`, `DIRECTO`. Fue un error real de
desarrollo, no fabricado para la demostración, y la restricción definida en
`Pedido.entity` lo atajó. Es además el argumento de por qué los desplegables importan:
desde la interfaz ese error es imposible de cometer.

## Checklist antes de sustentar

- [ ] Regenerar todo desde cero siguiendo el README, con el repositorio limpio, y confirmar
      **0 errores de generación** en los tres proyectos.
- [ ] `cm` devuelve `Model OK` (22 entities) en los tres proyectos.
- [ ] `podman compose down -v && podman compose up -d` deja la base con el escenario limpio
      (3 clientes, 3 pedidos) y sin datos de prueba.
- [ ] La API responde en las 22 rutas y Swagger abre.
- [ ] La SPA abre, el menú aparece agrupado, y **crear un registro funciona** (probarlo con
      un clic, no solo con `curl`).
- [ ] Tener a la mano: `docs/analisis-caso.md`, `docs/matriz-trazabilidad.md`,
      `docs/decisiones.md`, y `model-doc/dis_dominio.plantuml` renderizado.
- [ ] Plan B: si algo falla en vivo, los resultados están documentados y el DDL, el diagrama
      y las consultas se pueden mostrar sin necesidad de que los servicios estén arriba.
