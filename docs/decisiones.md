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

---

# Decisiones sobre la generación de la aplicación (API REST + SPA)

Esta sección documenta la segunda etapa del proyecto: pasar del modelo validado a una
aplicación ejecutable, generada íntegramente con Telosys.

## Decisión estructural: tres proyectos Telosys, un solo modelo

**Decisión adoptada:** tres proyectos Telosys hermanos (`evergreen-dis-modelo`,
`evergreen-dis-api`, `evergreen-dis-web`), cada uno con su `TelosysTools/`, apuntando
todos al **mismo** modelo mediante `SpecificModelsFolder`.

**Alternativa descartada:** un único proyecto con los cinco bundles instalados.

**Por qué se descartó:** el bundle `java-rest-springboot-jpa-basic` genera en
`src/main/java` y el bundle `front-angular` en `src/app`, y ambos escriben archivos de
proyecto en la raíz (`pom.xml` frente a `package.json` y `angular.json`). Conviven sin
sobrescribirse, pero producen un directorio ilegible donde no se distingue el backend del
frontend. Separar en tres proyectos mantiene el modelo como única fuente de verdad
(no se duplica) y deja cada aplicación con su estructura nativa.

**Detalle de portabilidad:** `SpecificModelsFolder` se dejó como ruta **relativa**
(`evergreen-dis-modelo/TelosysTools/models`). Se verificó que Telosys la resuelve contra
el directorio desde el que se lanza el CLI, no contra el proyecto; de ahí la convención
de **lanzar siempre el CLI desde la raíz del repositorio**. Con ruta absoluta el
repositorio solo habría funcionado en la máquina donde se creó.

## Adaptaciones de los bundles del depot

Los bundles se instalaron del depot oficial `github_org:telosys-templates-v4-3` y luego
se adaptaron. **Esto implica que `TelosysTools/templates/` debe estar versionado**: quien
los reinstale con `ib` obtendrá las versiones originales y la aplicación no funcionará.

Cada plantilla modificada lleva un comentario de una línea con el prefijo `EverGreen:`
que identifica la divergencia respecto al depot.

### Correcciones de defectos (sin ellas la aplicación no funciona)

| # | Plantilla | Problema | Corrección |
|---|---|---|---|
| 1 | `GenericService_java.vm` | El modelo declara, por cada FK, el atributo escalar (`unidadCodigo`) y el link (`unidad`, vía `@LinkByFK`). ModelMapper encontraba dos caminos al mismo dato y lanzaba `ConfigurationException`. **16 de 22 rutas GET devolvían HTTP 500.** | `MatchingStrategies.STRICT`, que exige coincidencia exacta de nombres. Una línea que corrige las 22 entidades. |
| 2 | `XxxRestController_java.vm` | El bundle no genera configuración CORS. La SPA (`:4200`) y la API (`:8000`) están en orígenes distintos, así que el navegador bloqueaba toda llamada. | `@CrossOrigin(origins = "http://localhost:4200")`, restringido al servidor de desarrollo en lugar de abrir a `*`. |
| 3 | `{ENT_LC}-form.ts.vm` | A las claves primarias autogeneradas (`@Id @AutoIncremented`) les aplicaba `Validators.required`. Como el usuario no puede llenarlas, **el formulario nunca era válido y el botón de guardar quedaba deshabilitado: era imposible crear registros.** | La PK autogenerada se genera deshabilitada y queda fuera del envío. Se verificó que las PK no autogeneradas (`UnidadMedida.codigo`, `Empaque.tareaId`) siguen editables y obligatorias. |
| 4 | `{ENT_LC}-form.ts.vm` | Los atributos temporales `@NotNull` no recibían validador (el bundle los omite con el comentario *"No Angular validator for Date type"*), permitiendo enviar el formulario sin fecha obligatoria. | Se agrega `Validators.required` a los temporales `@NotNull`. |

### Reclasificación: de recurso estático a plantilla

El bundle `front-angular` distingue plantillas `.vm` (procesadas con el modelo) de
`resources/` (copiados literalmente con la opción `-r`). Cuatro archivos estaban mal
clasificados y se movieron a plantilla:

| # | Archivo | Por qué estaba mal clasificado |
|---|---|---|
| 5 | `environment.development.ts.vm` | Tenía la URL de la API escrita a mano (`http://localhost:8000`). No varía con el modelo, pero **sí varía con la configuración**, y al ser copia literal obligaba a que la API se ajustara a ese valor mediante una convención tácita no declarada. Ahora deriva de `REST_URL_ROOT` + `REST_API_ROOT`. |
| 6 | `environment.ts.vm` | Igual que el anterior, para el perfil de build. |
| 7 | `home.component.html.vm` | Era un texto fijo de dos líneas. Convertido en plantilla, es un panel con una tarjeta por entidad y el conteo real (`${model.entities.size()}`): si el modelo crece, la portada crece con él. |
| 8 | `home.component.ts.vm` | Debió convertirse porque la nueva portada usa `routerLink` y el componente necesita importarlo. |

Se usó `#using(...)` en los dos `environment` a propósito: si las variables no están
definidas, la generación **falla** en lugar de emitir una URL silenciosamente incorrecta.

### Mejoras que aprovechan información del modelo ya existente

| # | Plantilla | Mejora |
|---|---|---|
| 9 | `{ENT_LC}-list.html.vm` | Los encabezados de tabla usan el `@Label` del modelo cuando existe (los 19 `@Label` estaban sin aprovechar; el bundle solo capitalizaba el nombre del atributo). |
| 10 | `{ENT_LC}-form.html.vm` | Los atributos `isFKSimple()` se generan como desplegable poblado desde la entidad referenciada, en lugar de pedir un identificador numérico. El campo visible se elige en cascada: tag `Display` del modelo, nombre convencional, primer texto, y por último la clave. |
| 11 | `{ENT_LC}-form.ts.vm` | Inyecta únicamente los servicios de las entidades referenciadas, deducidos del modelo con `$attribute.referencedEntityName`. |
| 12 | `layout.component.ts.vm` | El menú se agrupa en Procesos / Detalle / Catálogos usando `isAggregateRoot()` y `hasForeignKeys()`. **Los grupos salen del modelo, no de una lista escrita a mano**: los 5 `@AggregateRoot` definen el primer grupo. Incluye buscador. |
| 13 | `layout.component.html.vm`, `styles.scss.vm` | Se eliminan los emojis del bundle (cohete, corazón, casa y un círculo por entidad), cabecera clara con borde, tablas en tarjeta, resaltado de la sección activa. |

También se modificaron dos recursos estáticos (`layout.component.scss` y
`home.component.scss`), que sí corresponden a `resources/` porque son estilos invariantes
respecto al modelo.

## Decisión: qué NO se convirtió a plantilla

**Decisión adoptada:** dejar los 12 archivos restantes de `resources/` como copia literal.

**Alternativa descartada:** convertir todo a plantillas para que "el 100% pase por el
generador".

**Por qué se descartó:** se comprobó empíricamente que no aporta y en algunos casos rompe.
El criterio correcto en MDE no es *plantilla frente a estático*, sino **si el artefacto
varía con el modelo**. Ninguno de esos 12 archivos menciona una entidad del dominio
(verificado). Además:

- `public/favicon.ico` es binario: Velocity lo corrompería.
- `angular.json` contiene `"$schema"` y `errors.interceptor.ts` usa template literals de
  TypeScript (`${err.status}`). Velocity los interpreta como sus propias variables:
  ambos casos fallaron con `Invalid reference` en la prueba.
- Los 9 restantes (los `tsconfig`, `package.json`, `.editorconfig`, `.gitignore`, estilos)
  se pueden convertir, pero producirían un archivo idéntico: es una indirección sin
  información.

## Limitaciones conocidas de la aplicación generada

Se documentan porque son límites del generador, no defectos del modelo:

1. **La API no tiene autenticación.** El bundle expone 44 endpoints con CRUD completo,
   incluidos DELETE, sin ninguna capa de seguridad, y no lo advierte en su README. Es
   aceptable para una demostración local; no debe exponerse en red sin autenticación.
2. **Los errores de integridad se reportan como HTTP 500.** El bundle no genera manejo de
   excepciones, así que una violación de FK o de unicidad llega como error interno en
   lugar de 400 o 409. La integridad **sí** se cumple: PostgreSQL rechaza el dato y no
   queda basura, verificado. Solo la traducción a códigos HTTP queda pendiente. Sería una
   adaptación adicional del bundle.
3. **El bundle genera métodos de ejemplo sin relación con el modelo** (`findByTitle`,
   `findByPrice` en los servicios), heredados del ejemplo original del depot.
