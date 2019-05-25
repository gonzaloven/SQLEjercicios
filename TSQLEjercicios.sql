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
