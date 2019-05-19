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

--Ejercicio 7

SELECT prod_detalle, prod_codigo, MAX(prod_precio) AS cant_max, MIN(prod_precio) AS cant_max, 
CASE 
	WHEN MIN(prod_precio) = 0 THEN 0
	ELSE (MAX(prod_precio)/MIN(prod_precio)-1)*100
END diferencia_porcentual
FROM dbo.Producto 
JOIN dbo.STOCK ON prod_codigo = stoc_producto
GROUP BY prod_detalle, prod_codigo
HAVING SUM(ISNULL(stoc_cantidad,0)) > 0;

--Ejercicio 8

SELECT prod_detalle, MAX(stoc_cantidad)
FROM dbo.Producto
JOIN dbo.STOCK ON prod_codigo = stoc_producto
WHERE ISNULL(stoc_cantidad,0) > 0
GROUP BY prod_detalle, prod_codigo
HAVING COUNT(*) = (SELECT COUNT(*) FROM dbo.DEPOSITO);

-- Ejercicio 9

SELECT empl1.empl_jefe AS codigo_jefe, empl1.empl_codigo AS codigo_empleado, empl2.empl_nombre, COUNT(depo_codigo) AS depositos_a_cargo_empl,
(SELECT COUNT(depo_encargado)
 FROM dbo.DEPOSITO
 WHERE depo_encargado = empl1.empl_jefe)AS depositos_a_cargo_jefe
FROM dbo.Empleado empl1
LEFT JOIN dbo.Empleado empl2 ON empl1.empl_jefe = empl2.empl_codigo
LEFT JOIN dbo.DEPOSITO ON depo_encargado = empl1.empl_codigo
GROUP BY empl1.empl_jefe, empl1.empl_codigo, empl2.empl_nombre;

-- Ejercicio 10

SELECT *, (SELECT TOP 1 fact_cliente FROM Factura, Item_Factura WHERE fact_numero = item_numero AND
		   fact_tipo = item_tipo AND fact_sucursal = item_sucursal AND item_producto = prod_codigo
		   GROUP BY fact_cliente
		   ORDER BY SUM(item_cantidad*item_precio) DESC)
FROM Producto
WHERE prod_codigo IN (SELECT TOP 10 p1.prod_codigo FROM Producto p1
				      LEFT JOIN item_factura i1
					  ON i1.item_producto = p1.prod_codigo
					  GROUP BY p1.prod_codigo
					  ORDER BY SUM(i1.item_cantidad) DESC)
OR prod_codigo IN (SELECT TOP 10 p2.prod_codigo FROM Producto p2
				  LEFT JOIN item_factura i2
				  ON i2.item_producto = p2.prod_codigo
				  GROUP BY p2.prod_codigo
			      ORDER BY SUM(i2.item_cantidad) ASC);
		  
--EJERCICIO 11
SELECT fami_detalle, COUNT(DISTINCT(prod_codigo)) AS productos_dif, SUM(item_cantidad * item_precio) AS monto_total
FROM Familia, Producto, Item_Factura
WHERE fami_id = prod_familia
AND prod_codigo = item_producto
GROUP BY fami_detalle, fami_id
HAVING 
		(SELECT SUM(item_cantidad * item_precio) as monto_total_2012
		FROM Producto, Item_Factura, Factura
		WHERE fact_numero = item_numero
		AND fact_sucursal = item_sucursal
		AND fact_tipo = item_tipo
		AND item_producto = prod_codigo
		AND prod_familia = fami_id
		AND YEAR(fact_fecha) = 2012)>20000

ORDER BY productos_dif DESC;

--EJERCICIO 12

SELECT prod_detalle, 
	   COUNT(DISTINCT(clie_codigo)) AS clientes_compradores, 
	   AVG(item_cantidad * item_precio) AS promedio_pagado, 
	   (SELECT COUNT(stoc_deposito) FROM STOCK WHERE stoc_producto = prod_codigo AND ISNULL(stoc_cantidad,0)>0) AS depositos, 
	   (SELECT SUM(ISNULL(stoc_cantidad,0)) FROM STOCK WHERE stoc_producto = prod_codigo) AS stock_tot
FROM Producto, Cliente, Item_Factura, Factura
WHERE prod_codigo = item_producto
AND item_tipo = fact_tipo
AND item_sucursal = fact_sucursal
AND item_numero = fact_numero
AND fact_cliente = clie_codigo
GROUP BY prod_detalle, prod_codigo
HAVING 
		EXISTS(SELECT prod_codigo, f.fact_sucursal, f.fact_numero, f.fact_tipo
			   FROM Factura f, Producto, Item_Factura i
			   WHERE prod_codigo = i.item_producto
			   AND i.item_tipo = fact_tipo
			   AND i.item_sucursal = fact_sucursal
			   AND i.item_numero = fact_numero
			   AND YEAR(f.fact_fecha) = 2012)
ORDER BY SUM(item_cantidad * item_precio) DESC;

-- Ejercicio 15

SELECT p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, COUNT(itf1.item_numero)
FROM Producto p1 JOIN Item_Factura itf1 ON p1.prod_codigo = itf1.item_producto,
Producto p2 JOIN Item_Factura itf2 ON p2.prod_codigo = itf2.item_producto
WHERE itf1.item_numero = itf2.item_numero
AND itf1.item_tipo = itf2.item_tipo
AND itf1.item_sucursal = itf2.item_sucursal
AND p1.prod_codigo > p2.prod_codigo
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
HAVING COUNT(itf1.item_numero)>500;
