/* Testing para SP de tablas 
-cuota_membresia
-factura
-detalle_factura
-pago
*/

USE Com2900G10;
GO

--======================================== PRUEBAS PARA insertar_cuota_membresia =========================================
-- Inserto socio activo
INSERT INTO solNorte.socio (nombre, apellido, dni, fecha_nacimiento, telefono, borrado)
VALUES ('Juan', 'Perez', '12345678', '1999-08-20', '1111111111', 0)

-- Inserto socio borrado
INSERT INTO solNorte.socio (nombre, apellido, dni, fecha_nacimiento, telefono, borrado)
VALUES ('Camila', 'Gomez', '33345688', '1997-03-02', '1122222222', 1)

--Prueba 1: Insercion valida
DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.cuota_membresia WHERE id_socio = @ID_socio_valido;

    EXEC solNorte.insertar_cuota_membresia
        @mes = 6,
        @anio = 2025,
        @monto = 15000,
        @nombre_membresia = 'Mayor',
        @edad_minima = 18,
        @edad_maxima = 60,
        @id_socio = @ID_socio_valido;

    PRINT 'Estado despues:';
    SELECT * FROM solNorte.cuota_membresia WHERE id_socio = @ID_socio_valido;

    PRINT 'Prueba 1: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO
--Prueba 2: Insercion invalida -> utilizo el id de un socio borrado
DECLARE @ID_socio_invalido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '33345688'); 
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.cuota_membresia WHERE id_socio = @ID_socio_invalido;

    EXEC solNorte.insertar_cuota_membresia
        @mes = 6,
        @anio = 2025,
        @monto = 17000,
        @nombre_membresia = 'Mayor',
        @edad_minima = 18,
        @edad_maxima = 60,
        @id_socio = @ID_socio_invalido;

    PRINT 'Estado despues:';
    SELECT * FROM solNorte.cuota_membresia WHERE id_socio = @ID_socio_invalido;

    PRINT 'Prueba 1: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO
-- Prueba 3: Insercion invalida -> mes invalido
DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
BEGIN TRY
    EXEC solNorte.insertar_cuota_membresia
        @mes = 13,
        @anio = 2025,
        @monto = 15000,
        @nombre_membresia = 'Mayor',
        @edad_minima = 18,
        @edad_maxima = 60,
        @id_socio = @ID_socio_valido;
    PRINT 'Prueba 3: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 3: Falla - Mes invalido';
END CATCH;
GO
-- Prueba 4: Insercion invalida -> año invalido
DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
BEGIN TRY
    EXEC solNorte.insertar_cuota_membresia
        @mes = 5,
        @anio = 2052,
        @monto = 15000,
        @nombre_membresia = 'Mayor',
        @edad_minima = 18,
        @edad_maxima = 60,
        @id_socio = @ID_socio_valido;
    PRINT 'Prueba 4: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 4: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 5:Insercion invalida -> monto invalido
DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
BEGIN TRY
    EXEC solNorte.insertar_cuota_membresia
        @mes = 5,
        @anio = 2025,
        @monto = 0,
        @nombre_membresia = 'Mayor',
        @edad_minima = 18,
        @edad_maxima = 60,
        @id_socio = @ID_socio_valido;
    PRINT 'Prueba 5: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 5: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 6: Insercion invalida -> nombre de membresia invalido
DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
BEGIN TRY
    EXEC solNorte.insertar_cuota_membresia
        @mes = 5,
        @anio = 2025,
        @monto = 10000,
        @nombre_membresia = '  ',
        @edad_minima = 18,
        @edad_maxima = 60,
        @id_socio = @ID_socio_valido;
    PRINT 'Prueba 6: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 6: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 7: Insercion invalida -> edad invalida
DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
BEGIN TRY
    EXEC solNorte.insertar_cuota_membresia
        @mes = 5,
        @anio = 2025,
        @monto = 10000,
        @nombre_membresia = 'Mayor',
        @edad_minima = 50,
        @edad_maxima = 40,
        @id_socio = @ID_socio_valido;
    PRINT 'Prueba 7: Exito - Cuota de membresia insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 7 Falla ' + ERROR_MESSAGE();
END CATCH;
GO
--======================================== PRUEBAS PARA modificar_cuota_membresia =========================================
-- Prueba 1: Modificacion valida -> solo modifico el monto
DECLARE @ID_cuota_valida INT = (SELECT ID_cuota FROM solNorte.cuota_membresia WHERE id_socio = 
								(SELECT ID_socio FROM solNorte.socio WHERE DNI = '12345678')); -- dni del socio insertado anteriormente
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_valida;

	EXEC solNorte.modificar_cuota_membresia
	@ID_cuota = @ID_cuota_valida,
	@monto = 30000;

	PRINT 'Estado despues:';
    SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_valida;

    PRINT 'Prueba 1: Exito - Modificacióon realizada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 2: Modificacion invalida -> utilizo el id de una cuota que no existe
DECLARE @ID_cuota_invalida INT =  (SELECT ID_cuota FROM solNorte.cuota_membresia WHERE id_socio = 
								(SELECT ID_socio FROM solNorte.socio WHERE DNI = '12345678'));
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_invalida;

	EXEC solNorte.modificar_cuota_membresia
	@ID_cuota = @ID_cuota_invalida,
	@monto = 30000,
	@nombre_membresia = 'Cadete';

	PRINT 'Estado despues:';
    SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_invalida;

    PRINT 'Prueba 1: Exito - Modificacióon realizada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

--======================================== PRUEBAS PARA eliminar_cuota_membresia =========================================
-- Prueba 1: Eliminado valido
DECLARE @ID_cuota_valida INT = (SELECT ID_cuota FROM solNorte.cuota_membresia WHERE id_socio = 
								(SELECT ID_socio FROM solNorte.socio WHERE DNI = '12345678')); -- dni del socio insertado anteriormente
BEGIN TRY
	PRINT 'Estado antes:';
	SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_valida;

	EXEC solNorte.eliminar_cuota_membresia
	@ID_cuota = @ID_cuota_valida;

	PRINT 'Estado despues:';
    SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_valida;

    PRINT 'Prueba 1: Exito - cuota de membresia eliminada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 2: Eliminado invalido -> utilizo el id de una cuota que no existe 
DECLARE @ID_cuota_invalida INT = 0;
BEGIN TRY
	PRINT 'Estado antes:';
	SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_invalida;

	EXEC solNorte.eliminar_cuota_membresia
	@ID_cuota = @ID_cuota_invalida;

	PRINT 'Estado despues:';
    SELECT * FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota_invalida;

    PRINT 'Prueba 2: Exito - cuota de membresia eliminada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO
--======================================== PRUEBAS PARA insertar_factura =========================================
DECLARE @ID_socio_valido INT;
SELECT TOP 1 @ID_socio_valido = ID_socio FROM solNorte.socio WHERE borrado = 0;

-- Prueba 1: Inserción valida
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_valido;
	DECLARE @fecha DATETIME = GETDATE();
	DECLARE @venc DATETIME = DATEADD(DAY, 15, GETDATE());

	EXEC solNorte.insertar_factura
    @nro_factura = '0001',
    @tipo_factura = 'A',
    @fecha_emision = @fecha,
    @CAE = '12345678901234',
    @estado = 'PENDIENTE',
    @importe_total = 25000,
    @razon_social_emisor = 'Sol Norte SA',
    @CUIT_emisor = 20123456789,
    @vencimiento_CAE = @venc,
    @id_socio = @ID_socio_valido;

    PRINT 'Estado despues:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_valido;

    PRINT 'Prueba 1: Exito - Factura insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 2: Insercion invalida -> utilizo el id de un socio inexistente
DECLARE @ID_socio_invalido INT = 0;
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_invalido;
	DECLARE @fecha DATETIME = GETDATE();
	DECLARE @venc DATETIME = DATEADD(DAY, 15, GETDATE());

	EXEC solNorte.insertar_factura
    @nro_factura = '0001',
    @tipo_factura = 'A',
    @fecha_emision = @fecha,
    @CAE = '12345678901234',
    @estado = 'PENDIENTE',
    @importe_total = 25000,
    @razon_social_emisor = 'Sol Norte SA',
    @CUIT_emisor = 20123456789,
    @vencimiento_CAE = @venc,
    @id_socio = @ID_socio_invalido;

    PRINT 'Estado despues:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_invalido;

    PRINT 'Prueba 1: Exito - Factura insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 3: Insercion invalida -> utilizo el id de un socio borrado
DECLARE @ID_socio_borrado INT;
SELECT TOP 1 @ID_socio_borrado = ID_socio FROM solNorte.socio WHERE borrado = 1;

BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_borrado;
	DECLARE @fecha DATETIME = GETDATE();
	DECLARE @venc DATETIME = DATEADD(DAY, 15, GETDATE());

	EXEC solNorte.insertar_factura
    @nro_factura = '0001',
    @tipo_factura = 'A',
    @fecha_emision = @fecha,
    @CAE = '12345678901234',
    @estado = 'PENDIENTE',
    @importe_total = 25000,
    @razon_social_emisor = 'Sol Norte SA',
    @CUIT_emisor = 20123456789,
    @vencimiento_CAE = @venc,
    @id_socio = @ID_socio_borrado;

    PRINT 'Estado despues:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_borrado;

    PRINT 'Prueba 1: Exito - Factura insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

-- Prueba 4: Insercion invalida -> CUIT invalido
-- Primero inserto otro socio
INSERT INTO solNorte.socio (nombre, apellido, dni, fecha_nacimiento, telefono, borrado)
VALUES ('Carlos', 'Perez', '16665678', '1999-08-20', '1111111111', 0);

DECLARE @ID_socio_valido INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '16665678');

BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_valido;
	DECLARE @fecha DATETIME = GETDATE();
	DECLARE @venc DATETIME = DATEADD(DAY, 15, GETDATE());

	EXEC solNorte.insertar_factura
    @nro_factura = '0004',
    @tipo_factura = 'A',
    @fecha_emision = @fecha,
    @CAE = '12345678901234',
    @estado = 'PENDIENTE',
    @importe_total = 25000,
    @razon_social_emisor = 'Sol Norte SA',
    @CUIT_emisor = 201,
    @vencimiento_CAE = @venc,
    @id_socio = @ID_socio_valido;

    PRINT 'Estado despues:';
    SELECT * FROM solNorte.factura WHERE id_socio = @ID_socio_valido;

    PRINT 'Prueba 1: Exito - Factura insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO

--======================================== PRUEBAS PARA anular_factura =========================================
-- Prueba 1: Anulacion valida
DECLARE @ID_factura_valida INT = (SELECT TOP 1 ID_factura FROM solNorte.factura WHERE anulada = 0) ;
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.factura WHERE ID_factura = @ID_factura_valida;

	EXEC solNorte.anular_factura
	@ID_factura = @ID_factura_valida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.factura WHERE ID_factura = @ID_factura_valida;

PRINT 'Prueba 1: Exito - Factura anulada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO				

-- Prueba 2: Anulacion invalida -> utilizo un id factura que no existe
DECLARE @ID_factura_valida INT = 0 ;
BEGIN TRY
    PRINT 'Estado antes:';
    SELECT * FROM solNorte.factura WHERE ID_factura = @ID_factura_valida;

	EXEC solNorte.anular_factura
	@ID_factura = @ID_factura_valida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.factura WHERE ID_factura = @ID_factura_valida;

PRINT 'Prueba 2: Exito - Factura anulada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO		

--======================================== PRUEBAS PARA insertar_detalle_factura =========================================
-- Prueba 1: Insercion del detalle factura valida

-- Primero vuelvo a insertar una factura
DECLARE @ID_socio_valido INT;
SELECT TOP 1 @ID_socio_valido = ID_socio FROM solNorte.socio WHERE borrado = 0;
DECLARE @fecha DATETIME = GETDATE();	
DECLARE @venc DATETIME = DATEADD(DAY, 15, GETDATE());

	EXEC solNorte.insertar_factura
    @nro_factura = '0001',
    @tipo_factura = 'A',
    @fecha_emision = @fecha,
    @CAE = '12345678901234',
    @estado = 'PENDIENTE',
    @importe_total = 25000,
    @razon_social_emisor = 'Sol Norte SA',
    @CUIT_emisor = 20123456789,
    @vencimiento_CAE = @venc,
    @id_socio = @ID_socio_valido;
GO
DECLARE @ID_factura_valida INT = (SELECT TOP 1 ID_factura FROM solNorte.factura WHERE anulada = 0);

-- Inserto detalle factura
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.detalle_factura WHERE id_factura =  @ID_factura_valida;

	EXEC solNorte.insertar_detalle_factura
	@descripcion = 'Futsal',
	@cantidad = 1,
	@subtotal = 15000,
	@id_factura = @ID_factura_valida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.detalle_factura WHERE id_factura =  @ID_factura_valida;

PRINT 'Prueba 1: Exito - Detalle de factura insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

-- Prueba 2: Insercion del detalle factura invalida -> utilizo un id factura que no existe
DECLARE @ID_factura_invalida INT=0;
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.detalle_factura WHERE id_factura =  @ID_factura_invalida;

	EXEC solNorte.insertar_detalle_factura
	@descripcion = 'Futsal',
	@cantidad = 1,
	@subtotal = 15000,
	@id_factura = @ID_factura_invalida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.detalle_factura WHERE id_factura =  @ID_factura_invalida;

PRINT 'Prueba 2: Exito - Detalle de factura insertada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

--======================================== PRUEBAS PARA modificar_detalle_factura =========================================
-- Prueba 1: modificacion valida
DECLARE @ID_detalle_factura_valida INT = (SELECT TOP 1 ID_detalle_factura FROM solNorte.detalle_factura WHERE borrado = 0);
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura =  @ID_detalle_factura_valida;

	EXEC solNorte.modificar_detalle_factura
	@descripcion = ' Ajedrez',
	@cantidad = 5,
	@subtotal = 25000,
	@ID_detalle_factura = @ID_detalle_factura_valida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura =  @ID_detalle_factura_valida;

PRINT 'Prueba 1: Exito - Detalle de factura modificada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

-- Prueba 2: modificacion invalida -> uso un id detalle factura invalida
DECLARE @ID_detalle_factura_invalida INT = 0;
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura =  @ID_detalle_factura_invalida;

	EXEC solNorte.modificar_detalle_factura
	@descripcion = ' Ajedrez',
	@cantidad = 5,
	@subtotal = 25000,
	@ID_detalle_factura = @ID_detalle_factura_invalida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura_invalida;

PRINT 'Prueba 1: Exito - Detalle de factura modificada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	
--======================================== PRUEBAS PARA eliminar_detalle_factura =========================================
-- Prueba 1: eliminacion valida
DECLARE @ID_detalle_factura_valida INT = (SELECT TOP 1 ID_detalle_factura FROM solNorte.detalle_factura WHERE borrado = 0);
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura =  @ID_detalle_factura_valida;

	EXEC solNorte.eliminar_detalle_factura
	@ID_detalle_factura = @ID_detalle_factura_valida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura_valida;

PRINT 'Prueba 1: Exito - Detalle de factura eliminada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

-- Prueba 2: eliminacion invalida -> uso un id detalle factura inexistente
DECLARE @ID_detalle_factura_invalida INT = (SELECT TOP 1 ID_detalle_factura FROM solNorte.detalle_factura WHERE borrado = 1);
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura =  @ID_detalle_factura_invalida;

	EXEC solNorte.eliminar_detalle_factura
	@ID_detalle_factura = @ID_detalle_factura_invalida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura_invalida;

PRINT 'Prueba 1: Exito - Detalle de factura eliminada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	
--======================================== PRUEBAS PARA insertar_pago =========================================
-- Primero vuelvo a insertar una factura
DECLARE @ID_socio_valido INT;
SELECT TOP 1 @ID_socio_valido = ID_socio FROM solNorte.socio WHERE borrado = 0;
DECLARE @fecha DATETIME = GETDATE();	
DECLARE @venc DATETIME = DATEADD(DAY, 15, GETDATE());

	EXEC solNorte.insertar_factura
    @nro_factura = '0071',
    @tipo_factura = 'A',
    @fecha_emision = @fecha,
    @CAE = '12345671111234',
    @estado = 'PENDIENTE',
    @importe_total = 15000,
    @razon_social_emisor = 'Sol Norte SA',
    @CUIT_emisor = 20123400789,
    @vencimiento_CAE = @venc,
    @id_socio = @ID_socio_valido;
GO

-- Prueba 1: insercion valida
DECLARE @ID_factura_valida INT = (SELECT TOP 1 ID_factura FROM solNorte.factura WHERE anulada = 0);
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE id_factura =  @ID_factura_valida;

	EXEC solNorte.insertar_pago
	@fecha_pago = @fechap,
	@medio_de_pago = 'VISA',
    @monto = 15000,
    @estado = 'PENDIENTE',
    @id_factura = @ID_factura_valida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE id_factura =  @ID_factura_valida;

PRINT 'Prueba 1: Exito - Pago insertado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

-- Prueba 2: insercion invalida -> uso id factura invalida
DECLARE @ID_factura_invalida INT = 0;
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE id_factura =  @ID_factura_invalida;

	EXEC solNorte.insertar_pago
	@fecha_pago = @fechap,
	@medio_de_pago = 'VISA',
    @monto = 15000,
    @estado = 'PENDIENTE',
    @id_factura = @ID_factura_invalida;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE id_factura =  @ID_factura_invalida;

PRINT 'Prueba 1: Exito - Pago insertado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

--======================================== PRUEBAS PARA modificar_pago =========================================
-- Prueba 1: modificacion valida
DECLARE @ID_pago_valido INT = (SELECT TOP 1 ID_pago FROM solNorte.pago WHERE borrado = 0);
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_valido;

	EXEC solNorte.modificar_pago
	@ID_pago = @ID_pago_valido,
    @fecha_pago = @fechap,
    @medio_de_pago = 'MASTERCARD',
    @monto = 15000,
    @estado = 'PAGADO';

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_valido;

PRINT 'Prueba 1: Exito - Pago modificado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	

-- Prueba 2: modificacion invalida -> uso un id pago inexistente
DECLARE @ID_pago_invalido INT = 0;
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_invalido;

	EXEC solNorte.modificar_pago
	@ID_pago = @ID_pago_invalido,
    @fecha_pago = @fechap,
    @medio_de_pago = 'MASTERCARD',
    @monto = 15000,
    @estado = 'PAGADO';

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_invalido;

PRINT 'Prueba 2: Exito - Pago modificado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	
--======================================== PRUEBAS PARA eliminar_pago =========================================
-- Primero inserto otro pago
DECLARE @ID_factura_valida INT = (SELECT TOP 1 ID_factura FROM solNorte.factura WHERE anulada = 0);
DECLARE @fecha DATETIME = GETDATE();
EXEC solNorte.insertar_pago
	@fecha_pago = @fecha,
	@medio_de_pago = 'VISA',
    @monto = 15000,
    @estado = 'PENDIENTE',
    @id_factura = @ID_factura_valida;


-- Prueba 1: Eliminado logico valido - solo para pagos en estado 'PENDIENTE'
DECLARE @ID_pago_valido INT = (SELECT TOP 1 ID_pago FROM solNorte.pago WHERE estado = 'PENDIENTE');
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_valido;

	EXEC solNorte.eliminar_pago
	@ID_pago = @ID_pago_valido;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_valido;

PRINT 'Prueba 1: Exito - Pago eliminado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO	
-- Prueba 2: Eliminado logico invalido - intento eliminar un pago con estado 'PAGADO'
DECLARE @ID_pagado INT = (SELECT TOP 1 ID_pago FROM solNorte.pago WHERE estado = 'PAGADO');
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pagado;

	EXEC solNorte.eliminar_pago
	@ID_pago = @ID_pagado;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pagado;

PRINT 'Prueba 2: Exito - Pago eliminado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO
-- Prueba 3: Eliminado logico invalido - uso un id pago inexistente
DECLARE @ID_pago_invalido INT = 0;
DECLARE @fechap DATETIME = GETDATE();
BEGIN TRY
    PRINT 'Estado antes:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_invalido;

	EXEC solNorte.eliminar_pago
	@ID_pago = @ID_pago_invalido;

	PRINT 'Estado despues:';
	SELECT * FROM solNorte.pago WHERE ID_pago =  @ID_pago_invalido;

PRINT 'Prueba 3: Exito - Pago eliminado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 3: Falla - ' + ERROR_MESSAGE();
END CATCH;
GO