# Bitácora de errores — Telosys CLI (ACT-21)

## Errores de `cm` (check model)

**Ninguno.** Cada grupo de entidades (G1 a G7) pasó `cm` sin errores en su propia actividad (ACT-04 a ACT-10), y la validación final sobre las 22 entidades terminó en `Model OK ('dis_dominio' loaded : 22 entities)` a la primera.

La razón es que los dos errores bloqueantes que anticipa el plan (H03 `Separación` con tilde, H04 `tamaño` con `ñ`) se evitaron **desde la creación del archivo**, nombrando directamente `Separacion.entity` y el atributo `tamano`, en vez de escribir el nombre del caso y corregirlo después. Es la misma lección que señala el plan en la nota de la sección 1.2, aplicada de forma preventiva.

Para que quede registrado el tipo de error que *hubiera* ocurrido de no aplicar esa prevención (material útil para la sustentación):

| Error esperado si no se corrige | Causa | Corrección aplicada |
|---|---|---|
| `Separación.entity` no compila | Tilde en el nombre de entidad — Telosys solo admite letras, números y `_` | Se creó como `Separacion` desde el inicio |
| Atributo `tamaño` inválido | `ñ` no permitida en nombre de atributo | Se usó `tamano` desde el inicio |

## Fricciones operativas reales encontradas durante la implementación

Estas no son errores de modelo sino de uso del CLI; se documentan porque cualquiera que repita el proceso las va a encontrar:

| # | Síntoma | Causa | Solución |
|---|---|---|---|
| 1 | `Home directory must be set before using this command!` al ejecutar `ne <Entidad>` en una sesión nueva | El comando `h <ruta>` fija el directorio HOME solo dentro de la sesión interactiva del CLI; no persiste entre invocaciones separadas del binario `telosys` | Encadenar `h <ruta>` + `m dis_dominio` + el resto de comandos en una sola sesión (un solo `printf ... \| telosys`) |
| 2 | `gen * *` termina en "Generation canceled." | El comando `gen` pide confirmación interactiva `[y/n]` antes de generar, y si no se envía una respuesta se cancela | Incluir `y` como línea siguiente en la entrada de la sesión |
| 3 | El bundle "plantuml" que menciona el plan no aparece en `lbd` | Los nombres de bundle del depot cambian con el tiempo (advertencia explícita del propio plan en ACT-14) | Se usó `lbd` para descubrir el catálogo real; el equivalente vigente es `model-doc`, que genera PlantUML, Mermaid y documentación HTML |

## Verificación

- [x] `cm` termina sin errores ni advertencias sobre las 22 entidades.
- [x] Bitácora de errores (y de fricciones operativas) documentada.
