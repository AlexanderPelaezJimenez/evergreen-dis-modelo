# Convenciones del modelo — dis_dominio

Producido en ACT-03 del `plan_final_v2.md`. Reglas acordadas antes de crear la primera entidad.

## Nombrado

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

## Tipos neutros usados en este modelo

| Tipo | Uso |
|---|---|
| `int` | PK técnicas, FK numéricas, cantidades enteras |
| `short` | Números de secuencia, orden, años |
| `decimal` | Cantidades, pesos, volúmenes, precios, coordenadas |
| `string` | Códigos, nombres, descripciones |
| `boolean` | Banderas (`activo`, `esFinal`, `conNovedad`) |
| `date` | Fechas sin hora (cosecha, vencimiento, compromiso) |
| `datetime` | Fecha con hora (entrada, salida, entrega) |

> Versión instalada: **Telosys CLI 4.3.0-001**. `datetime` está disponible de forma nativa; no se usa `timestamp` (deprecado desde 4.3.0).

## Reglas de anotaciones

- Longitud de texto → `@MaxLen(n)` (**no** `@SizeMax`, deprecada).
- Precisión decimal → `@Size(precision,escala)`, por ejemplo `@Size(12,3)`.
- **Nunca poner coma entre anotaciones** (prohibido desde la versión 4.0).
- Cada definición termina en `;`.

## Verificación

- [x] Documento revisado y aceptado antes de crear entidades.
