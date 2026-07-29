-- Datos semilla de catalogos - Anexo E del plan_final_v2.md

INSERT INTO DIS_UNIDAD_MEDIDA (codigo, nombre, factor_a_kg, activo) VALUES
  ('KG',  'Kilogramo', 1.0000,    true),
  ('TON', 'Tonelada',  1000.0000, true),
  ('CAJ', 'Caja',      NULL,      true),
  ('CAN', 'Canastilla',NULL,      true),
  ('SAC', 'Saco',      NULL,      true),
  ('UND', 'Unidad',    NULL,      true),
  ('BUL', 'Bulto',     NULL,      true);

INSERT INTO DIS_ESTADO_PEDIDO (codigo, nombre, orden, es_final) VALUES
  ('REGISTRADO',      'Registrado',       1, false),
  ('EN_PREPARACION',  'En preparacion',   2, false),
  ('LISTO',           'Listo',            3, false),
  ('DESPACHADO',      'Despachado',       4, false),
  ('EN_TRANSITO',     'En transito',      5, false),
  ('ENTREGADO',       'Entregado',        6, true),
  ('CANCELADO',       'Cancelado',        7, true);

INSERT INTO DIS_CATEGORIA_PRODUCTO (nombre, perecedero, vida_util_dias, temperatura_min_c, temperatura_max_c) VALUES
  ('FRUTA',      true,  15, 4.0,  10.0),
  ('HORTALIZA',  true,  10, 4.0,  8.0),
  ('FLORES',     true,  7,  2.0,  6.0),
  ('GRANO',      false, 365, 15.0, 25.0),
  ('TUBERCULO',  true,  30, 10.0, 15.0);

INSERT INTO DIS_TIPO_TAREA (codigo, nombre, orden, requiere_detalle) VALUES
  ('SEPARACION', 'Separacion', 1, true),
  ('EMPAQUE',    'Empaque',    2, true),
  ('ROTULADO',   'Rotulado',   3, false),
  ('CARGUE',     'Cargue',     4, false);

INSERT INTO DIS_TIPO_EMPAQUE (nombre, material, capacidad_kg, tara_kg, reutilizable) VALUES
  ('CAJA CARTON',        'Carton',    20.00, 0.400, false),
  ('CANASTILLA PLASTICA','Plastico',  10.00, 1.200, true),
  ('SACO FIQUE',         'Fique',     50.00, 0.300, false),
  ('GUACAL MADERA',      'Madera',    30.00, 2.500, true),
  ('BOLSA',              'Polietileno', 5.00, 0.010, false);

-- CanalComercializacion es del caso (G2), pero se siembra aqui junto a los demas
-- catalogos porque Pedido depende de el con FK obligatoria
INSERT INTO DIS_CANAL_COMERCIALIZACION (codigo, nombre, descripcion, comision_porcentaje, requiere_factura, activo) VALUES
  ('MAYORISTA', 'Mayorista', 'Venta a distribuidores mayoristas', 3.00, true,  true),
  ('PLAZA',     'Plaza',     'Venta en plaza de mercado',         0.00, false, true),
  ('EXPORTA',   'Exportacion','Venta para exportacion',           5.00, true,  true),
  ('DIRECTO',   'Directo',   'Venta directa al consumidor final', 0.00, true,  true);
