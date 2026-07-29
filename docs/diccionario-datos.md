# Diccionario de datos — modelo `dis_dominio` (ACT-21)

Generado a partir de los 22 archivos `.entity` reales del modelo (no es una copia manual).

## `Acuatico` -> tabla `DIS_ACUATICO`
> Del caso (sin atributos). Especializacion con datos reales del modo acuatico

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| transporteId | int | @Id @FK(FK_ACU_TRA, Transporte) |  |
| naviera | string | @NotNull @MaxLen(60) |  |
| nombreEmbarcacion | string | @MaxLen(60) |  |
| puertoOrigen | string | @MaxLen(60) |  |
| puertoDestino | string | @MaxLen(60) |  |
| numeroContenedor | string | @MaxLen(20) |  |
| conocimientoEmbarque | string | @MaxLen(30) @Label("Bill of Lading") |  |
| transporte | Transporte | @LinkByFK(FK_ACU_TRA) |  |

*(8 campos, incluyendo links)*

## `Aereo` -> tabla `DIS_AEREO`
> Del caso (sin atributos). Especializacion con datos reales del modo aereo

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| transporteId | int | @Id @FK(FK_AER_TRA, Transporte) |  |
| aerolinea | string | @NotNull @MaxLen(60) |  |
| numeroVuelo | string | @MaxLen(15) |  |
| aeropuertoOrigen | string | @MaxLen(5) @Label("Codigo IATA") |  |
| aeropuertoDestino | string | @MaxLen(5) @Label("Codigo IATA") |  |
| guiaAerea | string | @MaxLen(30) @Label("Air Waybill") |  |
| transporte | Transporte | @LinkByFK(FK_AER_TRA) |  |

*(7 campos, incluyendo links)*

## `CanalComercializacion` -> tabla `DIS_CANAL_COMERCIALIZACION`
> Del caso: "CanalesComercializacion" -> singular

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| codigo | string | @Id @MaxLen(10) | MAYORISTA, PLAZA, EXPORTA, DIRECTO |
| nombre | string | @NotNull @MaxLen(60) |  |
| descripcion | string | @MaxLen(200) |  |
| comisionPorcentaje | decimal | @Size(5,2) @Min(0) @Max(100) @DefaultValue(0) |  |
| requiereFactura | boolean | @NotNull @DefaultValue(true) |  |
| activo | boolean | @NotNull @DefaultValue(true) |  |
| pedidos | Pedido[] | @MappedBy(canal) |  |

*(7 campos, incluyendo links)*

## `CategoriaProducto` -> tabla `DIS_CATEGORIA_PRODUCTO`
> Categoria agricola con parametros de conservacion - resuelve H15

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| nombre | string | @NotNull @MaxLen(40) | FRUTA, HORTALIZA, FLORES, GRANO |
| perecedero | boolean | @NotNull @DefaultValue(true) |  |
| vidaUtilDias | short | @Min(0) |  |
| temperaturaMinC | decimal | @Size(5,2) |  |
| temperaturaMaxC | decimal | @Size(5,2) |  |

*(6 campos, incluyendo links)*

## `Cliente` -> tabla `DIS_CLIENTE`  *(raiz de agregado)*
> Del caso (sin atributos). Enriquecida con identificacion y contacto

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| tipoDocumento | string | @NotNull @MaxLen(5) | NIT, CC, CE |
| numeroDocumento | string | @NotNull @MaxLen(20) @Unique |  |
| razonSocial | string | @NotNull @MaxLen(120) |  |
| nombreComercial | string | @MaxLen(120) |  |
| correo | string | @MaxLen(120) | formato validado en la aplicacion |
| telefono | string | @MaxLen(20) |  |
| fechaRegistro | date | @NotNull @Past |  |
| activo | boolean | @NotNull @DefaultValue(true) |  |
| direcciones | Direccion[] | @MappedBy(cliente) @Cascade(ALL) |  |
| pedidos | Pedido[] | @MappedBy(cliente) |  |

*(11 campos, incluyendo links)*

## `Direccion` -> tabla `DIS_DIRECCION`
> A donde se entrega el pedido - resuelve H09

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| alias | string | @NotNull @MaxLen(60) | "Bodega norte", "Plaza mayorista" |
| lineaDireccion | string | @NotNull @MaxLen(200) |  |
| ciudad | string | @NotNull @MaxLen(80) |  |
| departamento | string | @MaxLen(80) |  |
| pais | string | @NotNull @MaxLen(60) @DefaultValue("Colombia") |  |
| codigoPostal | string | @MaxLen(12) |  |
| latitud | decimal | @Size(9,6) @Min(-90)  @Max(90) |  |
| longitud | decimal | @Size(9,6) @Min(-180) @Max(180) |  |
| esPrincipal | boolean | @NotNull @DefaultValue(false) |  |
| clienteId | int | @NotNull @FK(FK_DIR_CLI, Cliente) |  |
| cliente | Cliente | @LinkByFK(FK_DIR_CLI) |  |

*(12 campos, incluyendo links)*

## `Empaque` -> tabla `DIS_EMPAQUE`
> Del caso: tipo, tamaño, cantidad, tiempo / "tipo"   -> FK a TipoEmpaque (normalizado) / "tamaño" -> "tamano" (la ñ no es valida en Telosys) / "tiempo" -> trasladado a Tarea.duracionMinutos

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| tareaId | int | @Id @FK(FK_EMP_TAR, Tarea) | PK = FK: especializacion 1:1 |
| cantidad | int | @NotNull @Min(1) @Label("Numero de empaques generados") | del caso |
| tamano | string | @MaxLen(20) | del caso |
| pesoNetoKg | decimal | @Size(10,3) @Min(0) |  |
| pesoBrutoKg | decimal | @Size(10,3) @Min(0) |  |
| rotulado | boolean | @NotNull @DefaultValue(false) |  |
| tipoEmpaqueId | int | @NotNull @FK(FK_EMP_TIP, TipoEmpaque) |  |
| tarea | Tarea | @LinkByFK(FK_EMP_TAR) |  |
| tipoEmpaque | TipoEmpaque | @LinkByFK(FK_EMP_TIP) |  |

*(9 campos, incluyendo links)*

## `Entrega` -> tabla `DIS_ENTREGA`
> Evidencia de cumplimiento de la entrega - resuelve H17

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| pedidoId | int | @Id @FK(FK_ENT_PED, Pedido) | 1:1 con Pedido |
| fechaEntrega | datetime | @NotNull |  |
| nombreReceptor | string | @NotNull @MaxLen(80) |  |
| documentoReceptor | string | @MaxLen(20) |  |
| cantidadRecibida | decimal | @Size(12,3) @Min(0) |  |
| conNovedad | boolean | @NotNull @DefaultValue(false) |  |
| descripcionNovedad | string | @LongText |  |
| evidenciaUrl | string | @MaxLen(255) |  |
| pedido | Pedido | @LinkByFK(FK_ENT_PED) |  |

*(9 campos, incluyendo links)*

## `Envio` -> tabla `DIS_ENVIO`  *(raiz de agregado)*
> Un viaje agrupa varios pedidos en un transporte - resuelve H13

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| consecutivo | string | @NotNull @MaxLen(20) |  |
| fechaProgramada | datetime | @NotNull |  |
| fechaSalidaReal | datetime |  |  |
| fechaLlegadaReal | datetime |  |  |
| estado | string | @NotNull @MaxLen(15) @DefaultValue("PROGRAMADO") |  |
| pesoCargadoKg | decimal | @Size(12,3) @Min(0) |  |
| observaciones | string | @LongText |  |
| transporteId | int | @NotNull @FK(FK_ENV_TRA, Transporte) |  |
| transporte | Transporte | @LinkByFK(FK_ENV_TRA) |  |
| pedidos | Pedido[] | @MappedBy(envio) |  |

*(11 campos, incluyendo links)*

## `EstadoPedido` -> tabla `DIS_ESTADO_PEDIDO`  *(catalogo de solo lectura)*
> Ciclo de vida del pedido - resuelve H08

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| codigo | string | @Id @MaxLen(15) | REGISTRADO, EN_PREPARACION, LISTO, DESPACHADO, ENTREGADO, CANCELADO |
| nombre | string | @NotNull @MaxLen(40) |  |
| orden | short | @NotNull @Min(1) @Label("Orden en el ciclo de vida") |  |
| esFinal | boolean | @NotNull @DefaultValue(false) @Label("Estado terminal") |  |

*(4 campos, incluyendo links)*

## `LineaPedido` -> tabla `DIS_LINEA_PEDIDO`
> Resuelve la relacion N:M Pedido-Producto del caso - mejora M04

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| numeroLinea | short | @NotNull @Min(1) |  |
| cantidad | decimal | @NotNull @Size(12,3) @Min(0) |  |
| precioUnitario | decimal | @NotNull @Size(14,2) @Min(0) |  |
| descuentoPorcentaje | decimal | @Size(5,2) @Min(0) @Max(100) @DefaultValue(0) |  |
| subtotal | decimal | @NotNull @Size(14,2) @Min(0) |  |
| pesoLineaKg | decimal | @Size(12,3) @Min(0) |  |
| pedidoId | int | @NotNull @FK(FK_LIN_PED, Pedido) |  |
| productoId | int | @NotNull @FK(FK_LIN_PRO, Producto) |  |
| loteId | int | @FK(FK_LIN_LOT, Lote) |  |
| unidadCodigo | string | @NotNull @FK(FK_LIN_UNI, UnidadMedida) |  |
| pedido | Pedido | @LinkByFK(FK_LIN_PED) |  |
| producto | Producto | @LinkByFK(FK_LIN_PRO) |  |
| lote | Lote | @LinkByFK(FK_LIN_LOT) @Optional |  |
| unidad | UnidadMedida | @LinkByFK(FK_LIN_UNI) |  |

*(15 campos, incluyendo links)*

## `Lote` -> tabla `DIS_LOTE`
> Trazabilidad hacia el predio de origen - resuelve H15

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| codigo | string | @NotNull @MaxLen(30) |  |
| fechaCosecha | date | @NotNull |  |
| fechaVencimiento | date |  |  |
| cantidadInicial | decimal | @NotNull @Size(12,3) @Min(0) |  |
| cantidadDisponible | decimal | @NotNull @Size(12,3) @Min(0) |  |
| predioOrigen | string | @MaxLen(120) @Label("Referencia al modulo de Produccion") |  |
| parcelaOrigen | string | @MaxLen(60) |  |
| productoId | int | @NotNull @FK(FK_LOT_PRO, Producto) |  |
| producto | Producto | @LinkByFK(FK_LOT_PRO) |  |

*(10 campos, incluyendo links)*

## `Pedido` -> tabla `DIS_PEDIDO`  *(raiz de agregado)*
> Del caso: identificador, fechaEntrada, fechaSalida. Raiz del agregado

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| identificador | string | @NotNull @MaxLen(30) | del caso |
| fechaEntrada | datetime | @NotNull | del caso |
| fechaSalida | datetime |  | del caso |
| fechaCompromisoEntrega | date | @NotNull |  |
| pesoTotalKg | decimal | @Size(12,3) @Min(0) |  |
| volumenTotalM3 | decimal | @Size(12,4) @Min(0) |  |
| valorTotal | decimal | @Size(14,2) @Min(0) |  |
| moneda | string | @NotNull @MaxLen(3) @DefaultValue("COP") |  |
| requiereCadenaFrio | boolean | @NotNull @DefaultValue(false) |  |
| observaciones | string | @LongText |  |
| prioridad | short | @NotNull @Min(1) @Max(5) @DefaultValue(3) @Label("1=urgente, 5=baja") |  |
| clienteId | int | @NotNull @FK(FK_PED_CLI, Cliente) |  |
| direccionEntregaId | int | @NotNull @FK(FK_PED_DIR, Direccion) |  |
| canalCodigo | string | @NotNull @FK(FK_PED_CAN, CanalComercializacion) |  |
| estadoCodigo | string | @NotNull @FK(FK_PED_EST, EstadoPedido) |  |
| envioId | int | @FK(FK_PED_ENV, Envio) |  |
| cliente | Cliente | @LinkByFK(FK_PED_CLI) |  |
| direccionEntrega | Direccion | @LinkByFK(FK_PED_DIR) |  |
| canal | CanalComercializacion | @LinkByFK(FK_PED_CAN) |  |
| estado | EstadoPedido | @LinkByFK(FK_PED_EST) |  |
| envio | Envio | @LinkByFK(FK_PED_ENV) @Optional |  |
| lineas | LineaPedido[] | @MappedBy(pedido) @Cascade(ALL) |  |
| tareas | Tarea[] | @MappedBy(pedido) @Cascade(ALL) |  |
| entrega | Entrega | @MappedBy(pedido) @OneToOne @Optional |  |

*(25 campos, incluyendo links)*

## `Producto` -> tabla `DIS_PRODUCTO`  *(raiz de agregado)*
> Del caso: identificador + fechaElaboracion. Enriquecido para contexto agro

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| identificador | string | @NotNull @MaxLen(30) @Label("Codigo de negocio") | del caso |
| nombre | string | @NotNull @MaxLen(120) |  |
| descripcion | string | @LongText |  |
| fechaElaboracion | date | @NotNull | del caso |
| pesoUnitarioKg | decimal | @Size(10,3) @Min(0) |  |
| requiereCadenaFrio | boolean | @NotNull @DefaultValue(false) |  |
| activo | boolean | @NotNull @DefaultValue(true) |  |
| categoriaId | int | @NotNull @FK(FK_PRO_CAT, CategoriaProducto) |  |
| unidadCodigo | string | @NotNull @FK(FK_PRO_UNI, UnidadMedida) |  |
| categoria | CategoriaProducto | @LinkByFK(FK_PRO_CAT) |  |
| unidad | UnidadMedida | @LinkByFK(FK_PRO_UNI) |  |
| lotes | Lote[] | @MappedBy(producto) |  |

*(13 campos, incluyendo links)*

## `Separacion` -> tabla `DIS_SEPARACION`
> Del caso: "Separación" (con tilde: nombre invalido en Telosys) -> "Separacion" / "lote" -> FK a Lote (normalizado)

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| tareaId | int | @Id @FK(FK_SEP_TAR, Tarea) | PK = FK: especializacion 1:1 |
| cantidad | decimal | @NotNull @Size(12,3) @Min(0) | del caso |
| ubicacionOrigen | string | @MaxLen(60) @Label("Bodega o area de separacion") |  |
| mermaKg | decimal | @Size(10,3) @Min(0) @DefaultValue(0) |  |
| loteId | int | @NotNull @FK(FK_SEP_LOT, Lote) | el "lote" del caso |
| unidadCodigo | string | @NotNull @FK(FK_SEP_UNI, UnidadMedida) |  |
| tarea | Tarea | @LinkByFK(FK_SEP_TAR) |  |
| lote | Lote | @LinkByFK(FK_SEP_LOT) |  |
| unidad | UnidadMedida | @LinkByFK(FK_SEP_UNI) |  |

*(9 campos, incluyendo links)*

## `Tarea` -> tabla `DIS_TAREA`
> Ejecucion de una tarea de preparacion sobre un pedido - resuelve H06 y H07

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| secuencia | short | @NotNull @Min(1) |  |
| estado | string | @NotNull @MaxLen(15) @DefaultValue("PENDIENTE") |  |
| fechaPlanificada | datetime |  |  |
| fechaInicio | datetime |  |  |
| fechaFin | datetime |  |  |
| duracionMinutos | int | @Min(0) @Label("Tiempo de ejecucion") | el "tiempo" del caso |
| responsable | string | @MaxLen(80) |  |
| observaciones | string | @LongText |  |
| pedidoId | int | @NotNull @FK(FK_TAR_PED, Pedido) |  |
| tipoTareaCodigo | string | @NotNull @FK(FK_TAR_TIP, TipoTarea) |  |
| pedido | Pedido | @LinkByFK(FK_TAR_PED) |  |
| tipoTarea | TipoTarea | @LinkByFK(FK_TAR_TIP) |  |
| empaque | Empaque | @MappedBy(tarea) @OneToOne @Optional |  |
| separacion | Separacion | @MappedBy(tarea) @OneToOne @Optional |  |

*(15 campos, incluyendo links)*

## `Terrestre` -> tabla `DIS_TERRESTRE`
> Del caso (sin atributos). Especializacion con datos reales del modo terrestre

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| transporteId | int | @Id @FK(FK_TER_TRA, Transporte) |  |
| tipoVehiculo | string | @NotNull @MaxLen(30) | CAMION, TURBO, TRACTOMULA, CAMIONETA |
| numeroEjes | short | @Min(2) |  |
| modeloAno | short | @Min(1950) |  |
| conductor | string | @MaxLen(80) |  |
| licenciaConductor | string | @MaxLen(20) |  |
| transporte | Transporte | @LinkByFK(FK_TER_TRA) |  |

*(7 campos, incluyendo links)*

## `TipoEmpaque` -> tabla `DIS_TIPO_EMPAQUE`
> Normaliza el atributo "tipo" de Empaque - resuelve H10

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| nombre | string | @NotNull @MaxLen(40) | CAJA, CANASTILLA, SACO, GUACAL |
| material | string | @MaxLen(30) |  |
| capacidadKg | decimal | @Size(8,2) @Min(0) |  |
| taraKg | decimal | @Size(8,3) @Min(0) @Label("Peso del empaque vacio") |  |
| reutilizable | boolean | @NotNull @DefaultValue(false) |  |

*(6 campos, incluyendo links)*

## `TipoTarea` -> tabla `DIS_TIPO_TAREA`  *(catalogo de solo lectura)*
> Catalogo de tipos de tarea de preparacion - del caso, ahora como catalogo

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| codigo | string | @Id @MaxLen(15) | SEPARACION, EMPAQUE, ROTULADO, CARGUE |
| nombre | string | @NotNull @MaxLen(40) |  |
| orden | short | @NotNull @Min(1) @Label("Orden sugerido de ejecucion") |  |
| requiereDetalle | boolean | @NotNull @DefaultValue(false) @Label("Tiene entidad especializada") |  |

*(4 campos, incluyendo links)*

## `Transportador` -> tabla `DIS_TRANSPORTADOR`
> Quien presta el servicio de transporte

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| nit | string | @NotNull @MaxLen(20) |  |
| razonSocial | string | @NotNull @MaxLen(120) |  |
| telefono | string | @MaxLen(20) |  |
| correo | string | @MaxLen(120) |  |
| activo | boolean | @NotNull @DefaultValue(true) |  |
| transportes | Transporte[] | @MappedBy(transportador) |  |

*(7 campos, incluyendo links)*

## `Transporte` -> tabla `DIS_TRANSPORTE`  *(raiz de agregado)*
> Del caso (sin atributos). Base de la jerarquia con discriminador de modalidad

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| id | int | @Id @AutoIncremented |  |
| modalidad | string | @NotNull @MaxLen(10) @Label("TERRESTRE|AEREO|ACUATICO") |  |
| identificacion | string | @NotNull @MaxLen(20) @Label("Placa o matricula") |  |
| descripcion | string | @MaxLen(120) |  |
| capacidadPesoKg | decimal | @NotNull @Size(12,3) @Min(0) |  |
| capacidadVolumenM3 | decimal | @Size(12,4) @Min(0) |  |
| tieneRefrigeracion | boolean | @NotNull @DefaultValue(false) |  |
| activo | boolean | @NotNull @DefaultValue(true) |  |
| transportadorId | int | @NotNull @FK(FK_TRA_TDR, Transportador) |  |
| transportador | Transportador | @LinkByFK(FK_TRA_TDR) |  |
| terrestre | Terrestre | @MappedBy(transporte) @OneToOne @Optional |  |
| aereo | Aereo | @MappedBy(transporte) @OneToOne @Optional |  |
| acuatico | Acuatico | @MappedBy(transporte) @OneToOne @Optional |  |
| envios | Envio[] | @MappedBy(transporte) |  |

*(14 campos, incluyendo links)*

## `UnidadMedida` -> tabla `DIS_UNIDAD_MEDIDA`  *(catalogo de solo lectura)*
> Catalogo de unidades de medida - resuelve H14

| Atributo | Tipo | Restricciones | Notas |
|---|---|---|---|
| codigo | string | @Id @MaxLen(6) @Label("Codigo") | KG, TON, CAJ, UND, BUL |
| nombre | string | @NotNull @MaxLen(40) |  |
| factorAKg | decimal | @Size(12,4) @Min(0) @Label("Factor de conversion a kilogramos") |  |
| activo | boolean | @NotNull @DefaultValue(true) |  |

*(4 campos, incluyendo links)*
