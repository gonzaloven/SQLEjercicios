 --EJEMPLO CURSORES

BEGIN 
		DECLARE @cod char(4)
		DECLARE @nom char(50)
		DECLARE mi_cursor CURSOR FOR

		SELECT rubr_id, rubr_detalle FROM Rubro
		WHERE rubr_id > '000'
		ORDER BY 1 DESC FOR UPDATE OF rubr_detalle

		OPEN mi_cursor
		FETCH mi_cursor INTO @cod, @nom

		WHILE @@FETCH_STATUS = 0
		
		BEGIN
				IF @cod = '0001' UPDATE Rubro SET rubr_detalle = 'x'
				WHERE CURRENT OF mi_cursor
				SELECT @cod, @nom
				FETCH mi_cursor INTO @cod, @nom
		END
	
		CLOSE mi_cursor
		DEALLOCATE mi_cursor
END