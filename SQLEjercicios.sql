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
		       
--EJERCICIO 13

SELECT p1.prod_detalle AS nombre, 
	   p1.prod_precio AS precio, 
	   SUM(p2.prod_precio*comp_cantidad) AS precio_componentes

FROM Producto p1, Composicion, Producto p2
WHERE p1.prod_codigo=comp_producto
AND p2.prod_codigo=comp_componente
GROUP BY p1.prod_codigo,p1.prod_detalle, p1.prod_precio
HAVING COUNT(*)>=2
ORDER BY COUNT(*) DESC
		       
--EJERCICIO 14

SELECT clie_codigo, 
	   ISNULL(COUNT(DISTINCT(fact_numero)),0) AS cant_compras,
	   (SELECT ISNULL(AVG(fact_total),0) FROM Factura
	   WHERE YEAR(fact_fecha)=(SELECT MAX(YEAR(fact_fecha)) FROM Factura) 
	   AND fact_cliente=clie_codigo) AS promedio_compra,
	   ISNULL(COUNT(DISTINCT(item_producto)),0) AS cant_prod_dist,
	   ISNULL(MAX(fact_total),0) AS mayor_compra

FROM Cliente LEFT JOIN 
(Factura JOIN Item_Factura ON fact_numero = item_numero 
AND fact_sucursal = item_sucursal 
AND fact_tipo = item_tipo) ON clie_codigo = fact_cliente

WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY clie_codigo
ORDER BY cant_compras DESC

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

--Ejercicio 16
				     
SELECT clie_codigo, 
       clie_razon_social, 
	   (SELECT SUM(CASE WHEN comp_producto IS NULL THEN item_cantidad ELSE item_cantidad*comp_cantidad END)
	    FROM Factura JOIN Item_Factura 
	    ON fact_sucursal=item_sucursal 
	    AND fact_numero=item_numero 
	    AND fact_tipo=item_tipo
	    LEFT JOIN Composicion ON item_producto=comp_producto
	    WHERE fact_cliente=clie_codigo 
	    AND YEAR(fact_fecha)=2012) AS cantidad_vendida_total,

	   (SELECT TOP 1 item_producto FROM Item_Factura i2 JOIN Factura ON fact_sucursal=item_sucursal 
	    AND fact_numero=item_numero 
	    AND fact_tipo=item_tipo
	    LEFT JOIN Composicion co ON item_producto=comp_componente
	    WHERE YEAR (fact_fecha)=2012 AND fact_cliente=clie_codigo
	    GROUP BY item_producto, comp_componente,comp_producto,comp_cantidad
	    ORDER BY SUM(i2.item_cantidad) + (CASE WHEN comp_componente is not null THEN 
						 (SELECT SUM(item_cantidad)*co.comp_cantidad 
						  FROM Factura f2 JOIN Item_Factura ON fact_sucursal=item_sucursal 
						  AND fact_numero=item_numero 
						  AND fact_tipo=item_tipo
						  WHERE YEAR(fact_fecha)=2012 
						  AND item_producto=co.comp_producto 
						  AND f2.fact_cliente=clie_codigo) ELSE 0 END) DESC,item_producto ASC)
						  AS producto_mayor_venta
										    
FROM Cliente c, Factura f
WHERE c.clie_codigo = f.fact_cliente
GROUP BY c.clie_codigo, c.clie_domicilio, c.clie_razon_social
HAVING COUNT(*) < 1.00/3 * (SELECT TOP 1 COUNT(*) FROM Factura JOIN Item_Factura ON fact_sucursal=item_sucursal 
			    AND fact_numero=item_numero 
		  	    AND fact_tipo=item_tipo
			    WHERE YEAR(fact_fecha)=2012
			    GROUP BY item_producto
			    ORDER BY COUNT(*) DESC)		     
ORDER BY c.clie_domicilio ASC

--Ejercicio 17

SELECT 
	   (CONCAT(YEAR(fact_fecha),RIGHT(CONCAT('0',MONTH(fact_fecha)),2))) AS Periodo,
	   
	   prod_codigo AS Prod,
	   
	   prod_detalle 'Detalle',
	   
	   SUM(item_cantidad) 'Cantidad Vendida',
	   
	   (SELECT ISNULL(SUM(item_cantidad),0) FROM Item_Factura i1
	   JOIN Factura f1 ON item_numero = fact_numero
	   AND item_sucursal = fact_sucursal
	   AND item_tipo = fact_tipo
	   WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)-1
	   AND MONTH(f1.fact_fecha) = MONTH(f.fact_fecha)) 'Ventas anio anterior',

	   COUNT(*) 'Cantidad Facturas'

FROM Producto p JOIN (Item_Factura JOIN Factura f ON item_numero = fact_numero
					 AND item_sucursal = fact_sucursal
					 AND item_tipo = fact_tipo) ON item_producto = prod_codigo
GROUP BY prod_codigo, prod_detalle, YEAR(f.fact_fecha), MONTH(f.fact_fecha)
ORDER BY Periodo,Prod

--EJERCICIO 18
					    
SELECT 
	   ISNULL(rubr_detalle, 'Sin nombre') AS DETALLE_RUBRO,
	   
	   ISNULL(SUM(item_cantidad*item_precio),0) AS VENTAS,
	   
	   ISNULL((SELECT TOP 1 prod_codigo FROM Producto p1
	    JOIN Rubro ON prod_rubro = rubr_id
		JOIN Item_Factura i1 ON prod_codigo = item_producto
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad) DESC),'-') AS PROD1,
	   
	   ISNULL((SELECT TOP 1 p2.prod_codigo FROM Producto p2
	    JOIN Rubro ON p2.prod_rubro = rubr_id
		AND p2.prod_codigo != (SELECT TOP 1 p1.prod_codigo FROM Producto p1
								JOIN Rubro ON p1.prod_rubro = rubr_id
								JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto
								GROUP BY p1.prod_codigo
								ORDER BY SUM(i1.item_cantidad) DESC)
	    JOIN Item_Factura i2 ON p2.prod_codigo = item_producto
		GROUP BY p2.prod_codigo
		ORDER BY SUM(i2.item_cantidad) DESC),'-') AS PROD2,

	   ISNULL((SELECT TOP 1 clie_codigo FROM Cliente
		JOIN Factura fc ON clie_codigo = fact_cliente
		JOIN Item_Factura ic ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	    JOIN Producto pc ON prod_codigo = item_producto
	    JOIN Rubro ON prod_rubro = rubr_id
		WHERE fc.fact_fecha > DATEADD(day, -30, (SELECT MAX(fact_fecha) FROM Factura))
		GROUP BY clie_codigo
		ORDER BY COUNT(ic.item_cantidad) DESC),'-') AS CLIENTE

FROM Rubro JOIN Producto ON rubr_id = prod_rubro
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON fact_numero = item_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
GROUP BY rubr_id, rubr_detalle
ORDER BY COUNT(DISTINCT item_producto) DESC

--EJERCICIO 19

SELECT prod_codigo AS Producto,
	   prod_detalle AS Detalle,
	   f1.fami_id AS FamiliaActual,
	   f1.fami_detalle AS FamiliaActualDetalle,
	   f2.fami_id AS FamiliaSugerida,
	   f2.fami_detalle AS FamiliaSugeridaDetalle

FROM Producto, Familia f1, Familia f2, Familia f3
WHERE prod_familia = f1.fami_id
AND SUBSTRING(f1.fami_detalle,1,5) = SUBSTRING(f2.fami_detalle,1,5)
AND SUBSTRING(f3.fami_detalle,1,5) = SUBSTRING(f2.fami_detalle,1,5)
AND f1.fami_detalle != f2.fami_detalle
AND f2.fami_id < f3.fami_id
ORDER BY prod_detalle ASC

--EJERCICIO 20
					  
SELECT TOP 3 

		e1.empl_codigo AS Legajo,
		e1.empl_nombre AS Nombre,
	    e1.empl_apellido AS Apellido,
	    YEAR(e1.empl_ingreso) AS Anio,

		CASE 
				WHEN (SELECT ISNULL(COUNT(*),0) FROM Factura WHERE empl_codigo = fact_vendedor) >= 50 
				THEN (SELECT ISNULL(COUNT(*),0) FROM Factura WHERE empl_codigo = fact_vendedor
															 AND fact_total > 100
															 AND YEAR(fact_fecha) = 2011)
			    WHEN (SELECT ISNULL(COUNT(*),0) FROM Factura WHERE empl_codigo = fact_vendedor) < 10 
				THEN (SELECT ISNULL((COUNT(*) * 0.5),0) FROM Factura WHERE fact_vendedor 
				IN(SELECT empl_codigo FROM Empleado WHERE empl_jefe = e1.empl_codigo)
				AND YEAR(fact_fecha) = 2011)
		END
	    AS PUNTAJE2011,
		CASE 
				WHEN (SELECT ISNULL(COUNT(*),0) FROM Factura WHERE empl_codigo = fact_vendedor) >= 50 
				THEN (SELECT ISNULL(COUNT(*),0) FROM Factura WHERE empl_codigo = fact_vendedor
															 AND fact_total > 100
															 AND YEAR(fact_fecha) = 2012)
			    WHEN (SELECT ISNULL(COUNT(*),0) FROM Factura WHERE empl_codigo = fact_vendedor) < 10 
				THEN (SELECT ISNULL((COUNT(*) * 0.5),0) FROM Factura WHERE fact_vendedor 
				IN(SELECT empl_codigo FROM Empleado WHERE empl_jefe = e1.empl_codigo)
				AND YEAR(fact_fecha) = 2012)
		END
	    AS PUNTAJE2012

FROM Empleado e1
ORDER BY PUNTAJE2012 DESC
