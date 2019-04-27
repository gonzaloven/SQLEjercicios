--Ejercicio 4

SELECT prod_codigo, prod_detalle, isnull(
           (SELECT SUM(comp_cantidad)
            FROM Composicion
            WHERE comp_producto=p.prod_codigo)
            ,0) prod_componentes
FROM Producto p LEFT JOIN STOCK s
ON p.prod_codigo=s.stoc_producto
GROUP BY prod_codigo, prod_detalle
HAVING AVG(isnull(s.stoc_cantidad,0)) > 100


--Ejercicio 5

SELECT prod_codigo, prod_detalle, SUM(i.item_cantidad) AS total_cant
FROM dbo.Producto p, dbo.Item_Factura i, dbo.Factura f
WHERE year(f.fact_fecha) = '2012'
AND i.item_producto = p.prod_codigo
AND f.fact_numero = i.item_numero 
AND f.fact_sucursal = i.item_sucursal
AND f.fact_tipo = i.item_tipo
GROUP BY prod_codigo, prod_detalle
HAVING SUM(i.item_cantidad) >
(SELECT SUM(ISNULL(i2.item_cantidad,0)) 
FROM dbo.Item_Factura i2, dbo.Factura f2
WHERE f2.fact_numero = i2.item_numero
AND year(f2.fact_fecha) = '2011'
AND f2.fact_sucursal = i2.item_sucursal
AND f2.fact_tipo = i2.item_tipo
AND p.prod_codigo = i2.item_producto);

-- Ejercicio 6

SELECT rubr_id, rubr_detalle, COUNT(p.prod_codigo) AS Productos, SUM(ISNULL(s1.stoc_cantidad,0)) AS Total_articulo_rubro
FROM dbo.Rubro, dbo.Producto p, dbo.STOCK s1
WHERE prod_rubro = rubr_id
AND s1.stoc_producto = prod_codigo
AND s1.stoc_cantidad > 
(SELECT SUM(s2.stoc_cantidad) FROM dbo.STOCK s2
WHERE s2.stoc_producto = '00000000'
AND s2.stoc_deposito = '00')
GROUP BY rubr_id, rubr_detalle;


