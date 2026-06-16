/* ============================================================
   Análisis del desempeño financiero — AdventureWorks 2017
   Herramienta: SQL (PostgreSQL)
   Objetivo: Identificar los mercados más rentables para
             optimizar la inversión en marketing
   Reviewer: Ezequiel Ferrario — Aprobado ✅
   ============================================================ */


/* ------------------------------------------------------------
   PARTE 1: Exploración del esquema
   ------------------------------------------------------------ */

-- 1.1 Transacciones de ventas 2017
SELECT *
FROM ventas_2017
LIMIT 10;

-- 1.2 Catálogo de productos con precio y costo unitario
SELECT *
FROM productos
LIMIT 10;

-- 1.3 Jerarquía de categorías y subcategorías
SELECT *
FROM productos_categorias
LIMIT 10;

-- 1.4 Mapa de territorios: clave → país y continente
SELECT *
FROM territorios
LIMIT 10;

-- 1.5 Gasto de marketing por territorio y campaña
SELECT *
FROM campanas
LIMIT 10;


/* ------------------------------------------------------------
   PARTE 2: Extracción y limpieza de datos
   Se construye una tabla base uniendo ventas, productos,
   categorías y territorios. Los NULLs en precio, costo y
   cantidad se reemplazan con 0 para evitar errores de cálculo.
   ------------------------------------------------------------ */

-- 2.1 Tabla base con columnas de identificación y dimensiones
--     (sin columnas calculadas — exploración inicial)
SELECT
    v.numero_pedido,
    v.clave_producto,
    p.nombre_producto,
    pc.clave_categoria,
    COALESCE(p.precio_producto, 0) AS precio_de_venta,
    COALESCE(v.cantidad_pedido,  0) AS cantidad_pedido,
    COALESCE(p.costo_producto,   0) AS costos,
    t.continente,
    t.pais,
    v.clave_territorio
FROM ventas_2017 AS v
LEFT JOIN productos AS p
    ON v.clave_producto = p.clave_producto
LEFT JOIN productos_categorias AS pc
    ON p.clave_subcategoria = pc.clave_subcategoria
LEFT JOIN territorios AS t
    ON v.clave_territorio = t.clave_territorio
GROUP BY
    v.numero_pedido, v.clave_producto, p.nombre_producto,
    pc.clave_categoria, p.precio_producto, v.cantidad_pedido,
    p.costo_producto, t.pais, t.continente, v.clave_territorio;


-- 2.2 Tabla base con columnas calculadas:
--     ingreso_total = precio × cantidad
--     costo_total   = costo  × cantidad
--     Esta query es la fuente de la vista ventas_clean
SELECT
    v.numero_pedido,
    v.clave_producto,
    p.nombre_producto,
    pc.clave_categoria,
    COALESCE(p.precio_producto, 0) AS precio_producto,
    COALESCE(v.cantidad_pedido,  0) AS cantidad_pedido,
    COALESCE(p.costo_producto,   0) AS costo_producto,
    t.pais,
    t.continente,
    v.clave_territorio,
    SUM(COALESCE(p.precio_producto, 0) * COALESCE(v.cantidad_pedido, 0))::integer AS ingreso_total,
    SUM(COALESCE(p.costo_producto,  0) * COALESCE(v.cantidad_pedido, 0))::integer AS costo_total
FROM ventas_2017 AS v
LEFT JOIN productos AS p
    ON v.clave_producto = p.clave_producto
LEFT JOIN productos_categorias AS pc
    ON p.clave_subcategoria = pc.clave_subcategoria
LEFT JOIN territorios AS t
    ON v.clave_territorio = t.clave_territorio
GROUP BY
    v.numero_pedido, v.clave_producto, p.nombre_producto,
    pc.clave_categoria, p.precio_producto, v.cantidad_pedido,
    p.costo_producto, t.pais, t.continente, v.clave_territorio;


/* ------------------------------------------------------------
   PARTE 3: Cálculo de KPIs financieros
   ------------------------------------------------------------ */

-- 3.1 Ingresos y costos totales por país
--     Convierte a INTEGER para mejorar legibilidad de los totales.
--     Ordena de mayor a menor ingreso para priorizar mercados.
SELECT
    pais,
    clave_territorio,
    SUM(ingreso_total)::integer AS ingresos,
    SUM(costo_total)::integer   AS costos
FROM ventas_clean
GROUP BY pais, clave_territorio
ORDER BY ingresos DESC;


-- 3.2 Ingresos, costos y gasto en campañas de marketing por país
--     Se usa LEFT JOIN con campanas para conservar todos los
--     territorios aunque no tengan campaña registrada.
--     COALESCE garantiza que territorios sin campaña muestren 0.
SELECT
    v.pais,
    v.clave_territorio,
    SUM(v.ingreso_total)::integer                  AS ingresos,
    SUM(v.costo_total)::integer                    AS costos,
    COALESCE(SUM(c.costo_campana::integer), 0)     AS costo_campana
FROM ventas_clean AS v
LEFT JOIN campanas AS c
    ON v.clave_territorio = c.clave_territorio::integer
GROUP BY v.pais, v.clave_territorio
ORDER BY ingresos DESC;


-- 3.3 KPIs financieros completos por mercado
--     beneficio_bruto = ingresos - costos operativos
--     margen_pct      = beneficio_bruto / ingresos × 100
--     roi_pct         = beneficio_bruto / costo_campana × 100
--     NULLIF evita división por cero en mercados sin ventas o sin campaña.
SELECT
    p.pais,
    p.clave_territorio,
    SUM(p.ingresos)::integer                                          AS ingresos,
    SUM(p.costos)::integer                                            AS costos,
    COALESCE(SUM(c.costo_campana), 0)::integer                        AS costo_campana,
    (SUM(p.ingresos) - SUM(p.costos))::integer                        AS beneficio_bruto,
    ((SUM(p.ingresos) - SUM(p.costos)) * 100.0)
        / NULLIF(SUM(p.ingresos), 0)                                  AS margen_pct,
    ((SUM(p.ingresos) - SUM(p.costos)) * 100.0)
        / NULLIF(SUM(c.costo_campana), 0)                             AS roi_pct
FROM pais_ingreso_costo AS p
LEFT JOIN pais_campanas AS c
    ON p.clave_territorio = c.clave_territorio
GROUP BY p.pais, p.clave_territorio
ORDER BY p.clave_territorio, ingresos DESC;


/* ------------------------------------------------------------
   PARTE 4: Validación de calidad (QA)
   Objetivo: garantizar que la tabla base no tenga nulos en
   claves críticas ni cantidades o precios no válidos.
   Si cualquier conteo > 0, detener el análisis y revisar.
   ------------------------------------------------------------ */

-- 4.1 Nulos en claves de ventas_2017
--     Resultado esperado: todos los conteos = 0
SELECT
    SUM(CASE WHEN numero_pedido   IS NULL THEN 1 ELSE 0 END) AS nulos_numero_pedido,
    SUM(CASE WHEN clave_producto  IS NULL THEN 1 ELSE 0 END) AS nulos_clave_producto,
    SUM(CASE WHEN clave_territorio IS NULL THEN 1 ELSE 0 END) AS nulos_clave_territorio
FROM ventas_2017;

-- 4.2 Filas con cantidad de pedido inválida (<= 0)
--     Resultado esperado: 0 filas
SELECT COUNT(*) AS filas_cantidad_no_valida
FROM ventas_2017
WHERE cantidad_pedido <= 0;

-- 4.3 Productos con precio negativo
--     Resultado esperado: 0 productos
SELECT COUNT(*) AS productos_precio_no_valido
FROM productos
WHERE precio_producto < 0;
