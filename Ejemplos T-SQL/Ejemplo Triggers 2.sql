--EJEMPLO TRIGGERS
--EJ 4 T-SQL

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
