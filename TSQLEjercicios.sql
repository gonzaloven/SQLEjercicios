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