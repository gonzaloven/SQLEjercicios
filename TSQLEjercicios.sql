--EJERCICIO 1 

CREATE FUNCTION estado_del_deposito (@prod_codigo char(8), @depo_codigo char(2))
RETURNS varchar(200)
AS BEGIN
		DECLARE @stoc_disp decimal(12,2)
		DECLARE @stoc_max decimal(12,2)
		DECLARE @respuesta varchar(200)

		SELECT TOP 1 @stoc_disp = ISNULL(stoc_cantidad,0), @stoc_max = ISNULL(stoc_stock_maximo,0)
		FROM STOCK
		WHERE @prod_codigo = stoc_producto
		AND @depo_codigo = stoc_deposito

		IF(@stoc_disp >= @stoc_max)
			SET @respuesta = 'DEPOSITO COMPLETO'
		else
		BEGIN
			 DECLARE @porcentaje int
			 SET @porcentaje = CASE WHEN @stoc_max = 0 THEN 0 ELSE 100 - ((@stoc_disp * 100)/@stoc_max) END
			 SET @respuesta = convert(varchar,CONCAT('OCUPACION DEL DEPOSITO: ',@porcentaje,' %'))
		END
RETURN @respuesta
END
								 
--EJERCICIO 2

CREATE FUNCTION stock_fecha (@prod_codigo char(8), @fecha smalldatetime)
RETURNS int
AS
BEGIN
  DECLARE @stock_actual decimal(12, 2)
  DECLARE @vendidos_intervalo decimal(12, 2)

  SELECT @vendidos_intervalo = SUM(
    CASE
      WHEN @prod_codigo = item_producto THEN item_cantidad
      ELSE item_cantidad * comp_cantidad
    END)
  FROM Item_Factura JOIN Factura ON fact_numero = item_numero
    AND fact_sucursal = item_sucursal
    AND fact_tipo = item_tipo
  JOIN Producto ON item_producto = item_producto
  JOIN Composicion ON comp_producto = item_producto
  WHERE prod_codigo = @prod_codigo
  AND CONVERT(date, fact_fecha) BETWEEN CONVERT(date, @fecha) AND 
					CONVERT(date, GETDATE())

  SELECT @stock_actual = SUM(stoc_cantidad)
  FROM STOCK
  WHERE @prod_codigo = stoc_producto

  RETURN @stock_actual + @vendidos_intervalo
END

--EJERCICIO 3

CREATE PROCEDURE empl_sin_jefe
AS
BEGIN
		DECLARE @jefe_codigo numeric(6,0)
		DECLARE @emps_sin_jefe TABLE(empl_codigo numeric(6,0))
		DECLARE @cant_emps_sin_jefe int

		INSERT INTO @emps_sin_jefe
		SELECT empl_codigo FROM Empleado
		WHERE empl_jefe IS NULL
		ORDER BY empl_salario DESC, empl_ingreso ASC

		SET @cant_emps_sin_jefe = (SELECT COUNT(*) FROM @emps_sin_jefe)

		IF(@cant_emps_sin_jefe >= 1)
			BEGIN 
				 SELECT TOP 1 @jefe_codigo = empl_codigo
				 FROM Empleado

				 UPDATE Empleado
				 SET empl_jefe = @jefe_codigo
				 WHERE empl_codigo != @jefe_codigo
			END

		RETURN @cant_emps_sin_jefe
END
								
--EJERCICIO 4

CREATE TRIGGER ejemplo ON FACTURA /*que tabla*/
AFTER /*el momento*/ INSERT, UPDATE, DELETE /*eventos*/
AS

BEGIN TRANSACTION 
		UPDATE Empleado SET
		empl_comision = empl_comision + (SELECT -1 * SUM(fact_total) FROM DELETED WHERE empl_codigo = fact_vendedor)
		WHERE EXISTS (SELECT 1 FROM DELETED WHERE fact_vendedor = empl_codigo)
		UPDATE Empleado SET empl_comision = empl_comision + (SELECT SUM(fact_total) FROM INSERTED WHERE empl_codigo = fact_vendedor)
		WHERE EXISTS (SELECT 1 FROM INSERTED WHERE fact_vendedor = empl_codigo)
COMMIT	
								 
CREATE PROCEDURE actualizar_comision_empleados
AS
BEGIN
	DECLARE @mayor_vendedor numeric(6,0)

	UPDATE Empleado
	SET empl_comision = isnull((SELECT SUM(f1.fact_total) FROM Factura f1
								WHERE f1.fact_vendedor=empl_codigo AND YEAR(f1.fact_fecha)=YEAR(GETDATE())-1),0)
	
	SET @mayor_vendedor = (SELECT TOP 1 empl_codigo FROM Empleado
						   ORDER BY empl_comision DESC)
END

--EJERCICIO 5
					     
CREATE PROCEDURE migrar_datos_fact_table 
AS
BEGIN 
	 INSERT INTO Fact_table
	 SELECT YEAR(fact_fecha),
			MONTH(fact_fecha), 
			prod_familia, 
			prod_rubro, 
			ISNULL(depo_zona,'-'), 
			clie_codigo, 
			prod_codigo, 
			SUM(item_cantidad), 
			SUM(item_precio)

	 FROM Factura, Producto, STOCK, DEPOSITO, Cliente, Item_Factura
	 WHERE clie_codigo = fact_cliente
	 AND fact_numero = item_numero
	 AND fact_sucursal = item_sucursal
	 AND fact_tipo = item_tipo
	 AND item_producto = prod_codigo
	 AND prod_codigo = stoc_producto
	 AND stoc_deposito = depo_codigo
	 GROUP BY YEAR(fact_fecha),
			  MONTH(fact_fecha),
			  prod_familia,
			  prod_rubro,
			  depo_zona,
			  clie_codigo,
			  prod_codigo
END

--EJERCICIO 10

CREATE TRIGGER verificar_producto_eliminado ON Producto
INSTEAD OF DELETE
AS

BEGIN TRANSACTION
				 
				 DECLARE @stock_total decimal(12,2)
				 DECLARE @prod char(8)

				 SELECT @stock_total = ISNULL(SUM(stoc_cantidad),0) FROM DELETED, STOCK
				 WHERE prod_codigo = stoc_producto

				 DECLARE mi_cursor CURSOR FOR
				 SELECT prod_codigo FROM DELETED

				 OPEN mi_cursor
				 FETCH NEXT FROM mi_cursor INTO @prod

				 WHILE @@FETCH_STATUS = 0
				 BEGIN
					  IF @stock_total <= 0
						BEGIN
							 DELETE FROM Producto WHERE prod_codigo = @prod
							 DELETE FROM Composicion WHERE comp_producto = @prod
							 DELETE FROM STOCK WHERE stoc_producto = @prod
						END
					  ELSE
						BEGIN
							 RAISERROR('No se puede borrar el producto porque tiene stock',1,1)
						END
					  
					  FETCH NEXT FROM mi_cursor INTO @prod
				END

				CLOSE mi_cursor
				DEALLOCATE mi_cursor

COMMIT

--EJERCICIO 11

CREATE FUNCTION empleados_a_cargo (@jefe numeric(6,0))
RETURNS int
AS 

BEGIN
	 
	 DECLARE @empleados_directos int
	 DECLARE @empleados_indirectos int

	 SELECT @empleados_directos = COUNT(empl_codigo) FROM Empleado
	 WHERE @jefe = empl_jefe

	 SELECT @empleados_indirectos = dbo.empleados_a_cargo(empl_codigo) FROM Empleado
	 WHERE @jefe = empl_jefe

	 RETURN ISNULL(@empleados_directos + @empleados_indirectos,0)

END

--EJERCICIO 14
						 
CREATE PROCEDURE get_clientes_pago_menos
AS

BEGIN
	 DECLARE @Clientes_q_pagaron_menos TABLE
	 (
		fecha smalldatetime,
		cliente char(6),
		producto char(8),
		precio decimal(12,2)
	 )
	 DECLARE @fecha smalldatetime
	 DECLARE @cliente char(6)
	 DECLARE @producto char(8)
	 DECLARE @precio decimal(12,2)

	 DECLARE mi_cursor CURSOR LOCAL FAST_FORWARD FOR
	 SELECT fact_fecha, clie_codigo, item_producto, item_precio
	 FROM Cliente JOIN Factura ON fact_cliente = clie_codigo
	 JOIN Item_Factura ON item_numero = fact_numero
	 AND item_sucursal = fact_sucursal
	 AND item_tipo = fact_tipo

	 OPEN mi_cursor
	 FETCH NEXT FROM mi_cursor
	 INTO @fecha, @cliente, @producto, @precio

	 WHILE @@FETCH_STATUS = 0
	 BEGIN
		  IF @precio < (SELECT SUM(comp_cantidad * p2.prod_precio) 
						FROM Composicion JOIN Producto p ON @producto = comp_producto
						JOIN Producto p2 ON p2.prod_codigo = comp_componente
						GROUP BY comp_producto)
			BEGIN
				 INSERT INTO @Clientes_q_pagaron_menos
				 VALUES(@fecha, @cliente, @producto, @precio)
			END

		  IF @precio < (SELECT (SUM(comp_cantidad * p2.prod_precio)/2)
						FROM Composicion JOIN Producto p ON @producto = comp_producto
						JOIN Producto p2 ON p2.prod_codigo = comp_componente
						GROUP BY comp_producto)
			BEGIN
				 RAISERROR('El precio del producto es menor que el precio de la suma de sus partes',1,1)
			END
		  
		  FETCH NEXT FROM mi_cursor
		  INTO @fecha, @cliente, @producto, @precio
	 END

	 SELECT * FROM @Clientes_q_pagaron_menos

	 CLOSE mi_cursor
	 DEALLOCATE mi_cursor

END

--EJERCICIO 15

CREATE FUNCTION precio_compuesto (@prod char(8))
RETURNS decimal(12,2)
AS

BEGIN
	 DECLARE @precio decimal(12,2)

	 SELECT @precio = SUM(comp_cantidad * dbo.precio_compuesto(comp_componente))
	 FROM Composicion
	 WHERE @prod = comp_producto

	 IF @precio IS NULL
		BEGIN
			 SET @precio = (SELECT prod_precio FROM Producto WHERE @prod = prod_codigo)
		END

	 RETURN @precio
END

--EJERCICIO 16

CREATE TRIGGER actualizar_stock ON Item_Factura
AFTER INSERT
AS

BEGIN TRANSACTION
				 DECLARE @prod char(8)
				 DECLARE @cantidad_comprada decimal(12,2)
				 DECLARE @deposito char(2)
				 DECLARE @stock_actual decimal(12,2)

				 DECLARE mi_cursor CURSOR LOCAL FAST_FORWARD FOR
				 SELECT item_producto, item_cantidad, stoc_deposito, stoc_cantidad
				 FROM INSERTED JOIN Factura 
				 ON item_numero = fact_numero
				 AND item_sucursal = fact_sucursal
				 AND item_tipo = fact_tipo
				 JOIN Producto ON item_producto = prod_codigo
				 JOIN STOCK ON prod_codigo = stoc_producto

				 OPEN mi_cursor
				 FETCH NEXT FROM mi_cursor
				 INTO @prod, @cantidad_comprada, @deposito, @stock_actual

				 WHILE @@FETCH_STATUS = 0
				 BEGIN
					  IF (@stock_actual - @cantidad_comprada) >= 0
						BEGIN
							 UPDATE STOCK
							 SET stoc_cantidad = stoc_cantidad - @cantidad_comprada
							 WHERE @prod = stoc_producto 
							 AND @deposito = stoc_deposito
						END
					  ELSE
						BEGIN
							 FETCH NEXT FROM mi_cursor
							 INTO @prod, @cantidad_comprada, @deposito, @stock_actual

							 IF @@FETCH_STATUS != 0
								BEGIN
									 FETCH PRIOR FROM mi_cursor
									 INTO @prod, @cantidad_comprada, @deposito, @stock_actual

									 UPDATE STOCK
									 SET stoc_cantidad = stoc_cantidad - @cantidad_comprada
									 WHERE @prod = stoc_producto 
									 AND @deposito = stoc_deposito
								END
							 ELSE
								BEGIN
									 FETCH PRIOR FROM mi_cursor
									 INTO @prod, @cantidad_comprada, @deposito, @stock_actual
								END
						END
				 
				 FETCH NEXT FROM mi_cursor
				 INTO @prod, @cantidad_comprada, @deposito, @stock_actual

				 END

				 CLOSE mi_cursor
				 DEALLOCATE mi_cursor

COMMIT

--EJERCICIO 17

CREATE TRIGGER validar_ingreso ON STOCK
INSTEAD OF UPDATE
AS

BEGIN TRANSACTION
				 DECLARE @stock_anterior decimal(12,2)
				 DECLARE @stock_nuevo decimal(12,2)
				 DECLARE @ingreso_neto decimal(12,2)
				 DECLARE @limite_maximo decimal(12,2)
				 DECLARE @limite_minimo decimal(12,2)

				 SELECT @stock_anterior = d.stoc_cantidad,
						@stock_nuevo = i.stoc_cantidad,
						@limite_maximo = i.stoc_stock_maximo,
						@limite_minimo = i.stoc_punto_reposicion
				 FROM INSERTED i, DELETED d

				 SET @ingreso_neto = @stock_nuevo - @stock_anterior

				 IF @ingreso_neto > 0
					BEGIN
						 IF @ingreso_neto > @limite_maximo
							BEGIN
								 UPDATE STOCK
								 SET stoc_cantidad = stoc_cantidad + @limite_maximo
							END
						 ELSE IF @ingreso_neto < @limite_minimo
								 BEGIN
									  RAISERROR('No se puede ingresar menos stock que el punto de reposicion',1,1)
								 END
							  ELSE
								 BEGIN
									  UPDATE STOCK
									  SET stoc_cantidad = stoc_cantidad + @ingreso_neto
								 END
					END
				 ELSE
					BEGIN
						 UPDATE STOCK
						 SET stoc_cantidad = stoc_cantidad + @ingreso_neto
					END
COMMIT
								   
--EJERCICIO 18

CREATE TRIGGER validar_ingreso_factura ON Factura
INSTEAD OF INSERT
AS

BEGIN TRANSACTION
				 DECLARE @tipo char(1)
				 DECLARE @sucu char(4)
				 DECLARE @numero char(8)
				 DECLARE @fecha smalldatetime
				 DECLARE @vendedor numeric(6,0)
				 DECLARE @total decimal(12,2)
				 DECLARE @totalimpuesto decimal(12,2)
				 DECLARE @cliente char(6)
				 DECLARE @contadorMonto decimal(12,2)
				 DECLARE @limiteCredito decimal(12,2)
				 DECLARE @contadorFactura char(8)

				 SELECT @tipo = fact_tipo,
						@sucu = fact_sucursal,
						@numero = fact_numero,
						@fecha = fact_fecha,
						@vendedor = fact_vendedor,
						@total = fact_total,
						@totalimpuesto = fact_total_impuestos,
						@cliente = fact_cliente,
						@limiteCredito = clie_limite_credito
				 FROM INSERTED, Cliente
				 WHERE fact_cliente = clie_codigo

				 SET @contadorMonto = @total
				 SET @contadorFactura = @numero

				 WHILE @contadorMonto > 0
					BEGIN
						 
						 IF @contadorMonto >= @limiteCredito
							BEGIN
								 INSERT INTO Factura
								 VALUES (@tipo, @sucu, @contadorFactura, @fecha, @vendedor, @limiteCredito, @totalimpuesto, @cliente)
							END
						 ELSE
							BEGIN
								 INSERT INTO Factura
								 VALUES (@tipo, @sucu, @contadorFactura, @fecha, @vendedor, @contadorMonto, @totalimpuesto, @cliente)
							END

						 SET @contadorMonto = @contadorMonto - @limiteCredito
						 SET @contadorFactura = @contadorFactura + 1

					END
COMMIT
								   
--EJERCICIO 19 (No esta bien del todo, porque hay que suponer muchas cosas que no se dicen en el enunciado)
								   
CREATE TRIGGER validar_jefe ON Empleado
AFTER INSERT
AS

BEGIN TRANSACTION

DECLARE @jefe numeric(6,0)
DECLARE @jefeanterior numeric(6,0)
DECLARE @empleado numeric(6,0)
DECLARE @cant_empleados_a_cargo int
DECLARE @empleados_totales int
DECLARE @antiguedad int
DECLARE @fecha_ingreso smalldatetime

SELECT @jefe = i.empl_jefe
	  ,@empleado = i.empl_codigo
FROM INSERTED i

SELECT @fecha_ingreso = empl_ingreso
	  ,@cant_empleados_a_cargo = dbo.empleados_a_cargo(@jefe)
	  ,@empleados_totales = (SELECT COUNT(empl_codigo) FROM Empleado)
FROM Empleado
WHERE empl_codigo = @jefe

SET @antiguedad = YEAR(GETDATE()) - YEAR(@fecha_ingreso)

IF @cant_empleados_a_cargo != @empleados_totales
	BEGIN
		 IF @cant_empleados_a_cargo > CEILING(@empleados_totales/2) AND @antiguedad < 5
			BEGIN
				UPDATE DEPOSITO
				SET depo_encargado = NULL
				WHERE depo_encargado = @empleado
				
				DELETE FROM Empleado
				WHERE empl_codigo = @empleado

				RAISERROR('No se puede asignar a un empleado un jefe que tenga menos de 5 anios de antiguedad o
						   que tenga mas del 50% de los empleados a su cargo',1,1)
			END
	END

COMMIT
