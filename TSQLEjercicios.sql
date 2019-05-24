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
