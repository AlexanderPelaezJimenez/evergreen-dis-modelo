-- Las 10 preguntas de negocio de ACT-13 / ACT-16, contra el escenario cargado en 03-escenario-act13.sql

-- 1. Cuantos kilos de aguacate se despacharon esta semana
SELECT p.identificador AS producto, SUM(lp.cantidad) AS kilos_despachados
FROM dis_linea_pedido lp
JOIN dis_producto p ON p.id = lp.producto_id
JOIN dis_pedido pe ON pe.id = lp.pedido_id
WHERE p.identificador = 'AGH-001'
  AND pe.fecha_salida >= date_trunc('week', CURRENT_DATE)
GROUP BY p.identificador;

-- 2. De que parcela salio el aguacate del pedido PED-1045
SELECT pe.identificador, pr.nombre AS producto, l.parcela_origen, l.predio_origen
FROM dis_linea_pedido lp
JOIN dis_pedido pe ON pe.id = lp.pedido_id
JOIN dis_producto pr ON pr.id = lp.producto_id
JOIN dis_lote l ON l.id = lp.lote_id
WHERE pe.identificador = 'PED-1045' AND pr.identificador = 'AGH-001';

-- 3. Que pedidos van en el envio del jueves (ENV-2026-030)
SELECT pe.identificador, pe.estado_codigo
FROM dis_pedido pe
JOIN dis_envio e ON e.id = pe.envio_id
WHERE e.consecutivo = 'ENV-2026-030';

-- 4. Cuanto tiempo tomo el empaque del pedido PED-1045
SELECT pe.identificador, t.duracion_minutos
FROM dis_tarea t
JOIN dis_pedido pe ON pe.id = t.pedido_id
WHERE pe.identificador = 'PED-1045' AND t.tipo_tarea_codigo = 'EMPAQUE';

-- 5. Pedidos sin despachar y ya vencidos por fecha de compromiso
SELECT identificador, fecha_compromiso_entrega, estado_codigo
FROM dis_pedido
WHERE fecha_compromiso_entrega < CURRENT_DATE
  AND estado_codigo NOT IN ('DESPACHADO', 'ENTREGADO', 'CANCELADO');

-- 6. Cuantas canastillas se usaron este mes
SELECT SUM(em.cantidad) AS canastillas_usadas
FROM dis_empaque em
JOIN dis_tipo_empaque te ON te.id = em.tipo_empaque_id
JOIN dis_tarea t ON t.id = em.tarea_id
JOIN dis_pedido pe ON pe.id = t.pedido_id
WHERE te.nombre = 'CANASTILLA PLASTICA'
  AND date_trunc('month', pe.fecha_salida) = date_trunc('month', CURRENT_DATE);

-- 7. Que clientes compran por canal mayorista
SELECT DISTINCT c.razon_social
FROM dis_pedido pe
JOIN dis_cliente c ON c.id = pe.cliente_id
WHERE pe.canal_codigo = 'MAYORISTA';

-- 8. Que transportador mueve mas peso
SELECT t2.razon_social AS transportador, SUM(pe.peso_total_kg) AS peso_total
FROM dis_pedido pe
JOIN dis_envio e ON e.id = pe.envio_id
JOIN dis_transporte tr ON tr.id = e.transporte_id
JOIN dis_transportador t2 ON t2.id = tr.transportador_id
GROUP BY t2.razon_social
ORDER BY peso_total DESC;

-- 9. Que pedidos se entregaron con novedad
SELECT pe.identificador, en.nombre_receptor, en.descripcion_novedad
FROM dis_entrega en
JOIN dis_pedido pe ON pe.id = en.pedido_id
WHERE en.con_novedad = true;

-- 10. Que merma tuvo la separacion del lote L-2026-045
SELECT l.codigo AS lote, s.merma_kg
FROM dis_separacion s
JOIN dis_lote l ON l.id = s.lote_id
WHERE l.codigo = 'L-2026-045';
