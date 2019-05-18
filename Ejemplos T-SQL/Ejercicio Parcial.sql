CREATE TRIGGER borrar_cliente ON Cliente
INSTEAD OF DELETE
AS

BEGIN TRANSACTION
		DECLARE @COD char(6)
		DECLARE @FACT char(8)
		DECLARE @SUC char(4)
		DECLARE @TIPO char(1)
		DECLARE @PROD char(8)

		DECLARE mi_cursor CURSOR FOR
		SELECT clie_codigo, fact_numero, fact_sucursal, fact_tipo FROM DELETED, Factura, Item_Factura
		WHERE item_tipo = fact_tipo
		AND item_sucursal = fact_sucursal
		AND item_numero = fact_numero
		AND fact_cliente = clie_codigo
		GROUP BY clie_codigo, fact_numero, fact_sucursal, fact_tipo

		OPEN mi_cursor
		FETCH mi_cursor INTO @COD, @FACT, @SUC, @TIPO, @PROD
		WHILE @@FETCH_STATUS = 0
		BEGIN
			DELETE Item_Factura WHERE item_producto = @PROD
			AND item_numero = @FACT
			AND item_sucursal = @SUC
			AND item_tipo = @TIPO

			DELETE FACTURA WHERE fact_numero = @FACT 
			AND fact_tipo = @TIPO
			AND fact_sucursal = @SUC 

			DELETE Cliente WHERE clie_codigo = @COD
			FETCH mi_cursor INTO @COD, @FACT, @SUC, @TIPO, @PROD
		END
		CLOSE mi_cursor
		DEALLOCATE mi_cursor
COMMIT
