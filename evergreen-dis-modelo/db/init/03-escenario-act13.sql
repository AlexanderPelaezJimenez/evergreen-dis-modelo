-- Escenario de prueba de ACT-13 (finca La Esperanza / aguacate + tomate)
-- Fechas de referencia: jueves = 2026-07-30, viernes = 2026-07-31

-- 1) Transportador y transporte
INSERT INTO DIS_TRANSPORTADOR (nit, razon_social, telefono, activo) VALUES
  ('900987654', 'Transportes del Oriente', '3001234567', true);

INSERT INTO DIS_TRANSPORTE (modalidad, identificacion, descripcion, capacidad_peso_kg, tiene_refrigeracion, activo, transportador_id) VALUES
  ('TERRESTRE', 'ABC123', 'Camion turbo', 4000.000, false, true,
   (SELECT id FROM DIS_TRANSPORTADOR WHERE nit = '900987654'));

INSERT INTO DIS_TERRESTRE (transporte_id, tipo_vehiculo, numero_ejes, conductor) VALUES
  ((SELECT id FROM DIS_TRANSPORTE WHERE identificacion = 'ABC123'), 'TURBO', 2, 'Carlos Gomez');

-- 2) Clientes y direcciones (el principal + los otros dos pedidos del mismo envio)
INSERT INTO DIS_CLIENTE (tipo_documento, numero_documento, razon_social, fecha_registro, activo) VALUES
  ('NIT', '900123456', 'Distribuidora Central',   '2024-01-15', true),
  ('NIT', '800234567', 'Mercado La Plaza',        '2024-03-10', true),
  ('NIT', '900345678', 'Frutas Directo SAS',      '2025-06-01', true);

INSERT INTO DIS_DIRECCION (alias, linea_direccion, ciudad, pais, es_principal, cliente_id) VALUES
  ('Bodega principal', 'Cra 45 # 10-20', 'Medellin', 'Colombia', true,
   (SELECT id FROM DIS_CLIENTE WHERE numero_documento = '900123456')),
  ('Plaza minorista',  'Cl 30 # 5-15',  'Medellin', 'Colombia', true,
   (SELECT id FROM DIS_CLIENTE WHERE numero_documento = '800234567')),
  ('Bodega norte',     'Cra 60 # 80-12','Rionegro', 'Colombia', true,
   (SELECT id FROM DIS_CLIENTE WHERE numero_documento = '900345678'));

-- 3) Productos y lotes
INSERT INTO DIS_PRODUCTO (identificador, nombre, fecha_elaboracion, requiere_cadena_frio, activo, categoria_id, unidad_codigo) VALUES
  ('AGH-001', 'Aguacate Hass',  '2026-07-28', false, true,
   (SELECT id FROM DIS_CATEGORIA_PRODUCTO WHERE nombre = 'FRUTA'), 'KG'),
  ('TOC-001', 'Tomate Chonto',  '2026-07-28', false, true,
   (SELECT id FROM DIS_CATEGORIA_PRODUCTO WHERE nombre = 'HORTALIZA'), 'KG');

INSERT INTO DIS_LOTE (codigo, fecha_cosecha, cantidad_inicial, cantidad_disponible, predio_origen, parcela_origen, producto_id) VALUES
  ('L-2026-045', '2026-07-27', 500.000, 300.000, 'La Esperanza', 'Rionegro',
   (SELECT id FROM DIS_PRODUCTO WHERE identificador = 'AGH-001')),
  ('L-2026-051', '2026-07-27', 200.000, 120.000, 'La Esperanza', 'Rionegro',
   (SELECT id FROM DIS_PRODUCTO WHERE identificador = 'TOC-001'));

-- 4) Envio (agrupa los 3 pedidos)
INSERT INTO DIS_ENVIO (consecutivo, fecha_programada, fecha_salida_real, estado, transporte_id) VALUES
  ('ENV-2026-030', '2026-07-30 14:00', '2026-07-30 14:05', 'DESPACHADO',
   (SELECT id FROM DIS_TRANSPORTE WHERE identificacion = 'ABC123'));

-- 5) Pedidos (el principal + los otros dos que van en el mismo envio)
INSERT INTO DIS_PEDIDO (identificador, fecha_entrada, fecha_salida, fecha_compromiso_entrega, peso_total_kg, moneda, cliente_id, direccion_entrega_id, canal_codigo, estado_codigo, envio_id) VALUES
  ('PED-1045', '2026-07-29 08:00', '2026-07-30 14:00', '2026-07-31', 280.000, 'COP',
   (SELECT id FROM DIS_CLIENTE WHERE numero_documento = '900123456'),
   (SELECT id FROM DIS_DIRECCION WHERE alias = 'Bodega principal'),
   'MAYORISTA', 'DESPACHADO',
   (SELECT id FROM DIS_ENVIO WHERE consecutivo = 'ENV-2026-030')),
  ('PED-1046', '2026-07-29 09:00', '2026-07-30 14:00', '2026-07-31', 150.000, 'COP',
   (SELECT id FROM DIS_CLIENTE WHERE numero_documento = '800234567'),
   (SELECT id FROM DIS_DIRECCION WHERE alias = 'Plaza minorista'),
   'PLAZA', 'ENTREGADO',
   (SELECT id FROM DIS_ENVIO WHERE consecutivo = 'ENV-2026-030')),
  ('PED-1047', '2026-07-29 10:00', '2026-07-30 14:00', '2026-07-31', 90.000, 'COP',
   (SELECT id FROM DIS_CLIENTE WHERE numero_documento = '900345678'),
   (SELECT id FROM DIS_DIRECCION WHERE alias = 'Bodega norte'),
   'DIRECTO', 'DESPACHADO',
   (SELECT id FROM DIS_ENVIO WHERE consecutivo = 'ENV-2026-030'));

-- 6) Lineas del pedido principal (200 kg aguacate + 80 kg tomate)
INSERT INTO DIS_LINEA_PEDIDO (numero_linea, cantidad, precio_unitario, subtotal, pedido_id, producto_id, lote_id, unidad_codigo) VALUES
  (1, 200.000, 4500.00, 900000.00,
   (SELECT id FROM DIS_PEDIDO WHERE identificador = 'PED-1045'),
   (SELECT id FROM DIS_PRODUCTO WHERE identificador = 'AGH-001'),
   (SELECT id FROM DIS_LOTE WHERE codigo = 'L-2026-045'), 'KG'),
  (2, 80.000, 2200.00, 176000.00,
   (SELECT id FROM DIS_PEDIDO WHERE identificador = 'PED-1045'),
   (SELECT id FROM DIS_PRODUCTO WHERE identificador = 'TOC-001'),
   (SELECT id FROM DIS_LOTE WHERE codigo = 'L-2026-051'), 'KG');

-- 7) Tareas de preparacion del pedido principal: 2 separaciones + 1 empaque
WITH t1 AS (
  INSERT INTO DIS_TAREA (secuencia, estado, fecha_planificada, fecha_inicio, fecha_fin, duracion_minutos, responsable, pedido_id, tipo_tarea_codigo)
  VALUES (1, 'COMPLETADA', '2026-07-30 06:00', '2026-07-30 06:00', '2026-07-30 06:40', 40, 'Operario 1',
    (SELECT id FROM DIS_PEDIDO WHERE identificador = 'PED-1045'), 'SEPARACION')
  RETURNING id
)
INSERT INTO DIS_SEPARACION (tarea_id, cantidad, ubicacion_origen, merma_kg, lote_id, unidad_codigo)
SELECT id, 200.000, 'Bodega de separacion', 1.500,
  (SELECT id FROM DIS_LOTE WHERE codigo = 'L-2026-045'), 'KG'
FROM t1;

WITH t2 AS (
  INSERT INTO DIS_TAREA (secuencia, estado, fecha_planificada, fecha_inicio, fecha_fin, duracion_minutos, responsable, pedido_id, tipo_tarea_codigo)
  VALUES (2, 'COMPLETADA', '2026-07-30 06:00', '2026-07-30 06:40', '2026-07-30 07:00', 20, 'Operario 1',
    (SELECT id FROM DIS_PEDIDO WHERE identificador = 'PED-1045'), 'SEPARACION')
  RETURNING id
)
INSERT INTO DIS_SEPARACION (tarea_id, cantidad, ubicacion_origen, merma_kg, lote_id, unidad_codigo)
SELECT id, 80.000, 'Bodega de separacion', 0.800,
  (SELECT id FROM DIS_LOTE WHERE codigo = 'L-2026-051'), 'KG'
FROM t2;

WITH t3 AS (
  INSERT INTO DIS_TAREA (secuencia, estado, fecha_planificada, fecha_inicio, fecha_fin, duracion_minutos, responsable, pedido_id, tipo_tarea_codigo)
  VALUES (3, 'COMPLETADA', '2026-07-30 07:00', '2026-07-30 07:00', '2026-07-30 08:30', 90, 'Operario 2',
    (SELECT id FROM DIS_PEDIDO WHERE identificador = 'PED-1045'), 'EMPAQUE')
  RETURNING id
)
INSERT INTO DIS_EMPAQUE (tarea_id, cantidad, tamano, rotulado, tipo_empaque_id)
SELECT id, 20, 'MEDIANO', true,
  (SELECT id FROM DIS_TIPO_EMPAQUE WHERE nombre = 'CANASTILLA PLASTICA')
FROM t3;

-- 8) Entrega con novedad para PED-1046 (para la pregunta de negocio #9)
INSERT INTO DIS_ENTREGA (pedido_id, fecha_entrega, nombre_receptor, con_novedad, descripcion_novedad) VALUES
  ((SELECT id FROM DIS_PEDIDO WHERE identificador = 'PED-1046'),
   '2026-07-31 09:15', 'Ana Ruiz', true, 'Una canastilla llego golpeada');
