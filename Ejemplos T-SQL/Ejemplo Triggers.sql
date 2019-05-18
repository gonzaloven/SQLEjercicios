--Ejemplo Triggers 2

CREATE TRIGGER ejemplo_2 ON Rubro
INSTEAD OF UPDATE
AS
BEGIN TRANSACTION
		UPDATE Rubro SET
		rubr_detalle = 'trigger'
		WHERE rubr_id = '0001'
COMMIT

UPDATE Rubro SET rubr_detalle = 'Update'
SELECT rubr_detalle FROM Rubro