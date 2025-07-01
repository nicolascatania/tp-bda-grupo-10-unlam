USE Com2900G10
GO
--=======================================================PRUEBAS PARA ALTA DE GRUPO FAMILIAR=======================================================--
-- 1. alta valida
DECLARE @id_nuevo INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 1, @ID_grupo_familiar = @id_nuevo OUTPUT;
SELECT * FROM solNorte.grupo_familiar WHERE ID_grupo_familiar = @id_nuevo;

-- 2. error por cantidad 0
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 0, @ID_grupo_familiar = @id_nuevo OUTPUT;

--=======================================================PRUEBAS PARA MODIFICAR GRUPO FAMILIAR=======================================================--
-- 1. alta de integrante
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 1, @accion = 'ALTA';

-- 2. baja de integrante
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 1, @accion = 'BAJA';

-- 3. baja invalida si cantidad ya esta en 0
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 99, @accion = 'BAJA';

-- 4. accion invalida
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 1, @accion = 'OTRO';

--=======================================================PRUEBAS PARA BAJA DE GRUPO FAMILIAR=======================================================--
-- 1. dar de baja un grupo existente
EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = 1;

-- 2. grupo ya dado de baja
EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = 1;

-- 3. grupo inexistente
EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = 9999;

--=======================================================PRUEBAS PARA ALTA DE SOCIO=======================================================--
-- 1. alta socio mayor (responsable)
EXEC solNorte.alta_socio
    @nombre = 'Pedro', @apellido = 'Gomez', @fecha_nacimiento = '2000-01-01',
    @DNI = 12345678, @telefono = '1133344555', @telefono_de_emergencia = '1144556677',
    @obra_social = 'OSDE', @nro_obra_social = 'XYZ123',
    @email = 'pedro@mail.com';

-- 2. alta menor con grupo y responsable existente
EXEC solNorte.alta_socio
    @nombre = 'Juan', @apellido = 'Gomez', @fecha_nacimiento = '2015-06-01',
    @DNI = 23456789, @telefono = '1133344555',
    @id_responsable_a_cargo = 1, @id_grupo_familiar = 1;

-- 3. alta de menor sin grupo familiar
EXEC solNorte.alta_socio
    @nombre = 'Tomás', @apellido = 'Pérez', @fecha_nacimiento = '2010-06-01',
    @DNI = 34567890, @telefono = '1133344555';

--=======================================================PRUEBAS PARA MODIFICAR SOCIO=======================================================--
-- 1. modificar nombre, telefono y mail
EXEC solNorte.modificar_socio
    @ID_socio = 1, @nombre = 'Pedro Manuel', @apellido = 'Gomez',
    @fecha_nacimiento = '2000-01-01', @DNI = 12345678, @telefono = '1199988877',
    @email = 'pedronuevo@mail.com';

--socio no existe
EXEC solNorte.modificar_socio @ID_socio = 999, @nombre = 'Juan', ... ;

--2. CAMBIO GRUPO FAMILIAR
--creo grupo origen
DECLARE @grupoA INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 1, @ID_grupo_familiar = @grupoA OUTPUT;

--creo grupo destino
DECLARE @grupoB INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 0, @ID_grupo_familiar = @grupoB OUTPUT;

--alta de socio asignado a grupo origen
EXEC solNorte.alta_socio
    @nombre = 'Carlos', @apellido = 'Sanchez', @fecha_nacimiento = '1985-04-10',
    @DNI = 55555555, @telefono = '1122334455', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = '123',
    @email = 'carlos@mail.com',
    @id_grupo_familiar = @grupoA;

--buscar el ID del socio recien creado
DECLARE @id_socio INT;
SELECT @id_socio = ID_socio FROM solNorte.socio WHERE DNI = 55555555;

--modificar socio cambiandolo a grupo destino
EXEC solNorte.modificar_socio
    @ID_socio = @id_socio,
    @nombre = 'Carlos', @apellido = 'Sanchez',
    @fecha_nacimiento = '1985-04-10', @DNI = 55555555,
    @telefono = '1122334455', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = '123',
    @email = 'carlos@mail.com',
    @id_grupo_familiar = @grupoB;

--verificamos resultado
SELECT ID_grupo_familiar, cantidad_integrantes, borrado FROM solNorte.grupo_familiar
WHERE ID_grupo_familiar IN (@grupoA, @grupoB);


--=======================================================PRUEBAS PARA MODIFICAR SOCIO=======================================================--
-- 1. dar de baja a un socio sin menores
EXEC solNorte.baja_socio @ID_socio = 1;

-- 2. dar de baja a socio responsable único con menores
EXEC solNorte.baja_socio @ID_socio = 2;

-- 3. baja con transferencia de responsabilidad a otro mayor
--alta grupo familiar
DECLARE @grupoC INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 0, @ID_grupo_familiar = @grupoC OUTPUT;

--alta socio mayor (actual responsable)
EXEC solNorte.alta_socio
    @nombre = 'Laura', @apellido = 'Torres', @fecha_nacimiento = '1980-05-01',
    @DNI = 60000001, @telefono = '1111111111', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = 'ABC123',
    @email = 'laura@mail.com',
    @id_grupo_familiar = @grupoC;

--alta socio mayor nuevo en mismo grupo
EXEC solNorte.alta_socio
    @nombre = 'Lucía', @apellido = 'Torres', @fecha_nacimiento = '1982-02-01',
    @DNI = 60000002, @telefono = '1111111112', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = 'ABC124',
    @email = 'lucia@mail.com',
    @id_grupo_familiar = @grupoC;

--bbtener IDs
DECLARE @id_responsable INT, @id_nueva INT;
SELECT @id_responsable = ID_socio FROM solNorte.socio WHERE DNI = 60000001;
SELECT @id_nueva = ID_socio FROM solNorte.socio WHERE DNI = 60000002;

--alta menor a cargo de @id_responsable
EXEC solNorte.alta_socio
    @nombre = 'Emilia', @apellido = 'Torres', @fecha_nacimiento = '2015-09-15',
    @DNI = 60000003, @telefono = '1111111113',
    @id_responsable_a_cargo = @id_responsable,
    @id_grupo_familiar = @grupoC;

--baja de socio mayor responsable
EXEC solNorte.baja_socio @ID_socio = @id_responsable;

--verificar si el nuevo mayor asume responsabilidad
SELECT ID_socio, nombre, es_responsable
FROM solNorte.socio
WHERE ID_socio IN (@id_nueva);



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


--Acá voy a subir los lotes de prueba
--======================================================ACTIVIDAD======================================================-- 
-- PRUEBAS PARA solNorte.insertar_actividad
-- Prueba 1: Inserción válida (caso normal)
SELECT * 
FROM solNorte.actividad
-- Esperado: Inserción exitosa
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = 'Natación',
        @costo_mensual = 2500.50,
        @edad_minima = 5,
        @edad_maxima = 60;
    
    PRINT 'Prueba 1: ÉXITO - Inserción válida funcionó correctamente';
    SELECT * 
	FROM solNorte.actividad 
	WHERE nombre_actividad = 'Natación';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - Inserción válida falló: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 2: Nombre de actividad vacío
-- Esperado: Error "El nombre de la actividad no puede estar vacío."
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = '',
        @costo_mensual = 1000,
        @edad_minima = 10,
        @edad_maxima = 50;
    
    PRINT 'Prueba 2: FALLA - Validación de nombre vacío no funcionó';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El nombre de la actividad no puede estar vacío.'
        PRINT 'Prueba 2: ÉXITO - Validación de nombre vacío funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 3: Costo mensual negativo
-- Esperado: Error "El costo mensual no puede ser negativo."
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = 'Yoga',
        @costo_mensual = -500,
        @edad_minima = 15,
        @edad_maxima = 80;
    
    PRINT 'Prueba 3: FALLA - Validación de costo negativo no funcionó';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El costo mensual no puede ser negativo.'
        PRINT 'Prueba 3: ÉXITO - Validación de costo negativo funcionó correctamente';
    ELSE
        PRINT 'Prueba 3: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 4: Edad mínima negativa
-- Esperado: Error "Las edades no pueden ser negativas."
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = 'Fútbol',
        @costo_mensual = 1800,
        @edad_minima = -5,
        @edad_maxima = 40;
    
    PRINT 'Prueba 4: FALLA - Validación de edad negativa no funcionó';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'Las edades no pueden ser negativas.'
        PRINT 'Prueba 4: ÉXITO - Validación de edad negativa funcionó correctamente';
    ELSE
        PRINT 'Prueba 4: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 5: Edad mínima mayor que máxima
-- Esperado: Error "La edad minima no puede ser mayor que la edad maxima."
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = 'Pilates',
        @costo_mensual = 2000,
        @edad_minima = 40,
        @edad_maxima = 18;
    
    PRINT 'Prueba 5: FALLA - Validación de rango de edades no funcionó';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'La edad minima no puede ser mayor que la edad maxima.'
        PRINT 'Prueba 5: ÉXITO - Validación de rango de edades funcionó correctamente';
    ELSE
        PRINT 'Prueba 5: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 6: Nombre con espacios en blanco
-- Esperado: Error "El nombre de la actividad no puede estar vacío."
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = '   ',
        @costo_mensual = 1500,
        @edad_minima = 6,
        @edad_maxima = 12;
    
    PRINT 'Prueba 6: FALLA - Validación de espacios en blanco no funcionó';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El nombre de la actividad no puede estar vacío.'
        PRINT 'Prueba 6: ÉXITO - Validación de espacios en blanco funcionó correctamente';
    ELSE
        PRINT 'Prueba 6: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 7: 
SELECT * 
FROM solNorte.actividad
-- Esperado: Inserción exitosa
BEGIN TRY
    EXEC solNorte.insertar_actividad 
        @nombre_actividad = 'Ajedrez',
        @costo_mensual = 0,  
        @edad_minima = 0,     
        @edad_maxima = 0;     
    
    PRINT 'Prueba 7: ÉXITO - Valores límite (cero) funcionaron correctamente';
    SELECT * 
	FROM solNorte.actividad 
	WHERE nombre_actividad = 'Ajedrez';
END TRY
BEGIN CATCH
    PRINT 'Prueba 7: FALLA - Valores límite fallaron: ' + ERROR_MESSAGE();
END CATCH
GO

-- Limpieza después de las pruebas
-- PRUEBAS PARA solNorte.modificar_actividad

-- Si se borró el registro anteriormente ingresado: 
/*
INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
VALUES ('Natación', 2500.50, 5, 60);
GO
*/
--Obtener el ID
DECLARE @ID_actividad INT = SCOPE_IDENTITY();
-- Prueba 1: Modificación válida (caso normal)
-- Esperado: Modificación exitosa con cambios visibles
BEGIN TRY
    PRINT 'Estado ANTES de la modificación:';
    SELECT * 
	FROM solNorte.actividad 
	WHERE ID_actividad = @ID_actividad;
    
    EXEC solNorte.modificar_actividad 
        @ID_actividad = @ID_actividad,
        @nombre_actividad = 'Natación Avanzada',
        @costo_mensual = 3000.75,
        @edad_minima = 8,
        @edad_maxima = 65;
    
    PRINT 'Estado DESPUÉS de la modificación:';
    SELECT * 
	FROM solNorte.actividad 
	WHERE ID_actividad = @ID_actividad;
    PRINT 'Prueba 1: ÉXITO - Modificación válida funcionó correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - Modificación válida falló: ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 2: Modificación parcial (solo algunos campos)
-- Esperado: Modificación exitosa solo de los campos especificados
BEGIN TRY
    PRINT 'Estado ANTES de la modificación:';
    SELECT * 
	FROM solNorte.actividad 
	WHERE ID_actividad = @ID_actividad;
    
    EXEC solNorte.modificar_actividad 
        @ID_actividad = @ID_actividad,
        @costo_mensual = 2800.00,
        @edad_maxima = 70;
    
    PRINT 'Estado DESPUÉS de la modificación:';
    SELECT * 
	FROM solNorte.actividad 
	WHERE ID_actividad = @ID_actividad;
    PRINT 'Prueba 2: ÉXITO - Modificación parcial funcionó correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 2: FALLA - Modificación parcial falló: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 3: Nombre de actividad vacío
-- Esperado: Error "El nombre de la actividad no puede estar vacío."
BEGIN TRY
    PRINT 'Estado ANTES del intento (no debería cambiar):';
    SELECT * FROM solNorte.actividad WHERE ID_actividad = @ID_actividad;
    
    EXEC solNorte.modificar_actividad 
        @ID_actividad = @ID_actividad,
        @nombre_actividad = '';
    
    PRINT 'Prueba 3: FALLA - Validación de nombre vacío no funcionó';
END TRY
BEGIN CATCH
    PRINT 'Estado DESPUÉS del intento (no debería cambiar):';
    SELECT * FROM solNorte.actividad WHERE ID_actividad = @ID_actividad;
    
    IF ERROR_MESSAGE() = 'El nombre de la actividad no puede estar vacío.'
        PRINT 'Prueba 3: ÉXITO - Validación de nombre vacío funcionó correctamente';
    ELSE
        PRINT 'Prueba 3: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 4: Costo mensual negativo
-- Esperado: Error "El costo mensual no puede ser negativo."
BEGIN TRY
    PRINT 'Estado ANTES del intento (no debería cambiar):';
    SELECT * 
	FROM solNorte.actividad 
	WHERE ID_actividad = @ID_actividad;
    
    EXEC solNorte.modificar_actividad 
        @ID_actividad = @ID_actividad,
        @costo_mensual = -500;
    
    PRINT 'Prueba 4: FALLA - Validación de costo negativo no funcionó';
END TRY
BEGIN CATCH
    PRINT 'Estado DESPUÉS del intento (no debería cambiar):';
    SELECT * FROM solNorte.actividad WHERE ID_actividad = @ID_actividad;
    
    IF ERROR_MESSAGE() = 'El costo mensual no puede ser negativo.'
        PRINT 'Prueba 4: ÉXITO - Validación de costo negativo funcionó correctamente';
    ELSE
        PRINT 'Prueba 4: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 5: Edad mínima mayor que máxima
-- Esperado: Error "La edad minima no puede ser mayor que la edad maxima."
BEGIN TRY
    PRINT 'Estado ANTES del intento (no debería cambiar):';
    SELECT * FROM solNorte.actividad WHERE ID_actividad = @ID_actividad;
    
    EXEC solNorte.modificar_actividad 
        @ID_actividad = @ID_actividad,
        @edad_minima = 40,
        @edad_maxima = 18;
    
    PRINT 'Prueba 5: FALLA - Validación de rango de edades no funcionó';
END TRY
BEGIN CATCH
    PRINT 'Estado DESPUÉS del intento (no debería cambiar):';
    SELECT * 
	FROM solNorte.actividad 
	WHERE ID_actividad = @ID_actividad;
    
    IF ERROR_MESSAGE() = 'La edad minima no puede ser mayor que la edad maxima.'
        PRINT 'Prueba 5: ÉXITO - Validación de rango de edades funcionó correctamente';
    ELSE
        PRINT 'Prueba 5: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 6: Actividad inexistente
-- Esperado: Error "La actividad especificada no existe."
BEGIN TRY
     EXEC solNorte.modificar_actividad 
        @ID_actividad = 999999, -- ID que no existe
        @nombre_actividad = 'Fútbol';
    
    PRINT 'Prueba 6: FALLA - Validación de actividad inexistente no funcionó';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'La actividad especificada no existe.'
        PRINT 'Prueba 6: ÉXITO - Validación de actividad inexistente funcionó correctamente';
    ELSE
        PRINT 'Prueba 6: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


-- 1. Preparación: Crear datos de prueba
INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
VALUES ('Natación', 2500.50, 5, 60);
GO
-- Obtener ID de actividad creada
DECLARE @ID_actividad INT = SCOPE_IDENTITY();
PRINT 'ID de actividad creada para pruebas: ' + CAST(@ID_actividad AS VARCHAR);
GO
-- 2. Prueba 1: Borrado exitoso
-- Esperado: Elimina correctamente el registro y muestra confirmación
BEGIN TRY
    PRINT 'Estado ANTES del borrado:';
    SELECT * FROM solNorte.actividad WHERE ID_actividad = @ID_actividad;
    
    EXEC solNorte.borrar_actividad @ID_actividad = @ID_actividad;
    
    PRINT 'Estado DESPUÉS del borrado:';
    SELECT * FROM solNorte.actividad WHERE ID_actividad = @ID_actividad;
    
    IF NOT EXISTS (SELECT 1 FROM solNorte.actividad WHERE ID_actividad = @ID_actividad)
        PRINT 'Prueba 1: ÉXITO - Registro eliminado correctamente';
    ELSE
        PRINT 'Prueba 1: FALLA - El registro no fue eliminado';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA INESPERADA - ' + ERROR_MESSAGE();
END CATCH
GO

-- 3. Prueba 2: Intento de borrar actividad inexistente
-- Esperado: Error "La actividad especificada no existe."
BEGIN TRY
    PRINT 'Estado ANTES del intento (no debe cambiar):';
    SELECT COUNT(*) AS TotalActividades FROM solNorte.actividad;
    
    EXEC solNorte.borrar_actividad @ID_actividad = 999999;
    
    PRINT 'Prueba 2: FALLA - No generó error al borrar actividad inexistente';
END TRY
BEGIN CATCH
    PRINT 'Estado DESPUÉS del intento (no debe cambiar):';
    SELECT COUNT(*) AS TotalActividades FROM solNorte.actividad;
    
    IF ERROR_MESSAGE() = 'La actividad especificada no existe.'
        PRINT 'Prueba 2: ÉXITO - Validación de actividad inexistente funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
--======================================================Horario de actividad======================================================-- 
--Insertar horario de actividad
INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
VALUES ('Yoga', 2000.00, 15, 70);
GO

-- Obtener ID de actividad creada
DECLARE @ID_actividad INT;

-- 2. Prueba 1: Inserción válida (caso normal)
-- Esperado: Inserción exitosa con datos correctos
BEGIN TRY
    PRINT 'Estado ANTES de la inserción:';
    SELECT * FROM solNorte.horario_de_actividad WHERE id_actividad = @ID_actividad;
    
    EXEC solNorte.insertar_horario_de_actividad
        @dia = 'Lunes',
        @hora_inicio = '18:00',
        @hora_fin = '19:30',
        @id_actividad = @ID_actividad;
    
    PRINT 'Estado DESPUÉS de la inserción:';
    SELECT * FROM solNorte.horario_de_actividad WHERE id_actividad = @ID_actividad;
    PRINT 'Prueba 1: ÉXITO - Inserción válida funcionó correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- 3. Prueba 2: Actividad inexistente
-- Esperado: Error "La actividad especificada no existe."
BEGIN TRY
    EXEC solNorte.insertar_horario_de_actividad
        @dia = 'Martes',
        @hora_inicio = '10:00',
        @hora_fin = '11:30',
        @id_actividad = 99999; -- ID que no existe
    
    PRINT 'Prueba 2: FALLA - No generó error por actividad inexistente';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'La actividad especificada no existe.'
        PRINT 'Prueba 2: ÉXITO - Validación de actividad inexistente funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

--Modificar horario de actividad
-- Crear actividad
INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
VALUES ('Tenis', 2200.00, 16, 65);

DECLARE @ID_actividad INT = SCOPE_IDENTITY();
PRINT 'ID de actividad creada: ' + CAST(@ID_actividad AS VARCHAR);

-- Crear horario para modificar
INSERT INTO solNorte.horario_de_actividad (dia, hora_inicio, hora_fin, id_actividad)
VALUES ('Lunes', '09:00', '10:30', @ID_actividad);

DECLARE @ID_horario INT = SCOPE_IDENTITY();
PRINT 'ID de horario creado: ' + CAST(@ID_horario AS VARCHAR);

-- Esperado: Modificación exitosa de todos los campos
BEGIN TRY
    PRINT '=== PRUEBA 1: Modificación completa válida ===';
    PRINT 'Estado ANTES de modificación:';
    SELECT * FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario;
    
    EXEC solNorte.modificar_horario_de_actividad
        @ID_horario = @ID_horario,
        @dia = 'Martes',
        @hora_inicio = '18:00',
        @hora_fin = '19:30',
        @id_actividad = @ID_actividad;
    
    PRINT 'Estado DESPUÉS de modificación:';
    SELECT * FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario;
    PRINT 'Prueba 1: ÉXITO - Modificación completa exitosa';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

--Borrar
-- Crear actividad
INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
VALUES ('Yoga', 2000.00, 15, 70);

DECLARE @ID_actividad INT = SCOPE_IDENTITY();
PRINT 'ID de actividad creada: ' + CAST(@ID_actividad AS VARCHAR);

-- Crear horarios para pruebas
INSERT INTO solNorte.horario_de_actividad (dia, hora_inicio, hora_fin, id_actividad)
VALUES ('Lunes', '09:00', '10:30', @ID_actividad),
       ('Martes', '18:00', '19:30', @ID_actividad),
       ('Miércoles', '11:00', '12:30', @ID_actividad);

DECLARE @ID_horario1 INT, @ID_horario2 INT, @ID_horario3 INT;
SELECT @ID_horario1 = ID_horario FROM solNorte.horario_de_actividad WHERE dia = 'Lunes';
SELECT @ID_horario2 = ID_horario FROM solNorte.horario_de_actividad WHERE dia = 'Martes';
SELECT @ID_horario3 = ID_horario FROM solNorte.horario_de_actividad WHERE dia = 'Miércoles';
-- Esperado: Elimina correctamente el registro especificado
BEGIN TRY
    PRINT 'Estado ANTES del borrado:';
    SELECT * FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario1;
    
    EXEC solNorte.borrar_horario_de_actividad @ID_horario = @ID_horario1;
    
    PRINT 'Estado DESPUÉS del borrado:';
    SELECT * FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario1;
    
    IF NOT EXISTS (SELECT 1 FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario1)
        PRINT 'Prueba 1: ÉXITO - Horario eliminado correctamente';
    ELSE
        PRINT 'Prueba 1: FALLA - El horario no fue eliminado';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA INESPERADA - ' + ERROR_MESSAGE();
END CATCH
GO
-- Prueba 2: Horario inexistente
-- Esperado: Error "El horario especificado no existe."
BEGIN TRY
    PRINT 'Cantidad de horarios ANTES del intento:';
    SELECT COUNT(*) AS TotalHorarios FROM solNorte.horario_de_actividad;
    
    EXEC solNorte.borrar_horario_de_actividad @ID_horario = 999999;
    
    PRINT 'Prueba : FALLA - No generó error por horario inexistente';
END TRY

--======================================================Inscripcion_actividad======================================================-- 
-- PRUEBAS PARA inscripcion_actividad

-- 1. Crear datos base para pruebas
-- Insertar actividades
INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima, borrado)
VALUES ('Natación', 2500.50, 5, 60, 0),
       ('Yoga', 1800.00, 15, 80, 0),
       ('Fútbol', 1200.00, 10, 40, 0),
       ('Pilates', 2000.00, 18, 70, 0);

-- Insertar socios (con diferentes edades)
INSERT INTO solNorte.socio (nombre, apellido, fecha_nacimiento, borrado)
VALUES ('Juan', 'Bochazo', '1990-05-15', 0),       -- 33 años
       ('María', 'Gómez', '2010-03-20', 0),      -- 13 años
       ('Carlos', 'López', '2005-07-10', 0),     -- 18 años
       ('Lola', 'Mento', '1975-11-30', 0);     -- 48 años (añadido)

-- Insertar facturas
INSERT INTO solNorte.factura (fecha_emision, total, borrado)
VALUES (GETDATE(), 5000.00, 0),
       (GETDATE(), 3500.00, 0),
       (GETDATE(), 4200.00, 0);

-- Obtener IDs de prueba
DECLARE @ID_natacion INT, @ID_yoga INT, @ID_futbol INT, @ID_pilates INT;
DECLARE @ID_socio1 INT, @ID_socio2 INT, @ID_socio3 INT, @ID_socio4 INT; -- Añadido @ID_socio4
DECLARE @ID_factura1 INT, @ID_factura2 INT, @ID_factura3 INT;

SELECT @ID_natacion = ID_actividad FROM solNorte.actividad WHERE nombre_actividad = 'Natación';
SELECT @ID_yoga = ID_actividad FROM solNorte.actividad WHERE nombre_actividad = 'Yoga';
SELECT @ID_futbol = ID_actividad FROM solNorte.actividad WHERE nombre_actividad = 'Fútbol';
SELECT @ID_pilates = ID_actividad FROM solNorte.actividad WHERE nombre_actividad = 'Pilates';

SELECT @ID_socio1 = ID_socio FROM solNorte.socio WHERE nombre = 'Juan' AND apellido = 'Bochazo';
SELECT @ID_socio2 = ID_socio FROM solNorte.socio WHERE nombre = 'María' AND apellido = 'Gómez';
SELECT @ID_socio3 = ID_socio FROM solNorte.socio WHERE nombre = 'Carlos' AND apellido = 'López';
SELECT @ID_socio4 = ID_socio FROM solNorte.socio WHERE nombre = 'Lola' AND apellido = 'Mento'; -- Añadido

SELECT @ID_factura1 = ID_factura FROM solNorte.factura WHERE total = 5000.00;
SELECT @ID_factura2 = ID_factura FROM solNorte.factura WHERE total = 3500.00;
SELECT @ID_factura3 = ID_factura FROM solNorte.factura WHERE total = 4200.00;

GO

-- PRUEBAS PARA insertar_inscripcion_actividad
-- Prueba 1: Inscripción válida
BEGIN TRY
    PRINT 'Estado ANTES de la inscripción:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE id_socio = @ID_socio1 AND id_actividad = @ID_natacion;
    
    EXEC solNorte.insertar_inscripcion_actividad 
        @fecha_inscripcion = '2023-10-01',
        @id_actividad = @ID_natacion,
        @id_socio = @ID_socio1;
    
    PRINT 'Estado DESPUÉS de la inscripción:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE id_socio = @ID_socio1 AND id_actividad = @ID_natacion;
    PRINT 'Prueba 1: ÉXITO - Inscripción válida funcionó correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 2: Socio no cumple requisitos de edad
BEGIN TRY
    EXEC solNorte.insertar_inscripcion_actividad 
        @fecha_inscripcion = '2023-10-01',
        @id_actividad = @ID_yoga,  -- Requiere mínimo 15 años
        @id_socio = @ID_socio2;    -- María tiene 13 años
    
    PRINT 'Prueba 2: FALLA - No generó error por edad inválida';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() LIKE 'El socio no cumple con los requisitos de edad%'
        PRINT 'Prueba 2: ÉXITO - Validación de edad funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- PRUEBAS PARA modificar_inscripcion_actividad
-- Crear una inscripción para modificar
INSERT INTO solNorte.inscripcion_actividad (fecha_inscripcion, id_actividad, id_socio, borrado)
VALUES ('2023-09-15', @ID_futbol, @ID_socio3, 0);
DECLARE @ID_inscripcion_mod INT = SCOPE_IDENTITY();
PRINT 'ID de inscripción creada para modificación: ' + CAST(@ID_inscripcion_mod AS VARCHAR);
GO

-- Prueba 1: Modificación válida
BEGIN TRY
    PRINT 'Estado ANTES de la modificación:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_mod;
    
    EXEC solNorte.modificar_inscripcion_actividad 
        @ID_inscripcion = @ID_inscripcion_mod,
        @fecha_inscripcion = '2023-10-01',
        @id_actividad = @ID_pilates,
        @id_socio = @ID_socio4;  -- Usando @ID_socio4 que ahora existe
    
    PRINT 'Estado DESPUÉS de la modificación:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_mod;
    PRINT 'Prueba 1: ÉXITO - Modificación válida funcionó correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- PRUEBAS PARA borrar_inscripcion_actividad
-- Obtener la inscripción creada en la primera prueba
DECLARE @ID_inscripcion_borrar INT = (SELECT TOP 1 ID_inscripcion FROM solNorte.inscripcion_actividad 
                                     WHERE id_socio = @ID_socio1 AND id_actividad = @ID_natacion AND borrado = 0);

-- Prueba 1: Borrado exitoso (inscripción sin asistencias)
BEGIN TRY
    PRINT 'Estado ANTES del borrado:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_borrar;
    
    EXEC solNorte.borrar_inscripcion_actividad @ID_inscripcion = @ID_inscripcion_borrar;
    
    PRINT 'Estado DESPUÉS del borrado:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_borrar;
    
    DECLARE @borrado BIT = (SELECT borrado FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_borrar);
    
    IF @borrado = 1
        PRINT 'Prueba 1: ÉXITO - Inscripción marcada como borrada correctamente';
    ELSE
        PRINT 'Prueba 1: FALLA - La inscripción no fue marcada como borrada';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA INESPERADA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Preparación para prueba 2: Crear una inscripción con asistencias
INSERT INTO solNorte.inscripcion_actividad (fecha_inscripcion, id_actividad, id_socio, borrado)
VALUES ('2023-10-01', @ID_yoga, @ID_socio3, 0);

DECLARE @ID_inscripcion_con_asistencias INT = SCOPE_IDENTITY();

INSERT INTO solNorte.asistencia (fecha, asistio, id_inscripcion_actividad, borrado)
VALUES (GETDATE(), 'A', @ID_inscripcion_con_asistencias, 0);
GO

-- Prueba 2: Inscripción con asistencias (debe fallar)
BEGIN TRY
    PRINT 'Estado ANTES del intento:';
    SELECT * FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_con_asistencias;
    PRINT 'Asistencias relacionadas:';
    SELECT * FROM solNorte.asistencia WHERE id_inscripcion_actividad = @ID_inscripcion_con_asistencias;
    
    EXEC solNorte.borrar_inscripcion_actividad @ID_inscripcion = @ID_inscripcion_con_asistencias;
    
    PRINT 'Prueba 2: FALLA - Permitío borrar inscripción con asistencias';
END TRY
BEGIN CATCH
    PRINT 'Estado DESPUÉS del intento (no debería cambiar):';
    SELECT * FROM solNorte.inscripcion_actividad WHERE ID_inscripcion = @ID_inscripcion_con_asistencias;
    
    IF ERROR_MESSAGE() = 'No se puede borrar la inscripción porque tiene asistencias registradas.'
        PRINT 'Prueba 2: ÉXITO - Validación de asistencias funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

--======================================================Asistencia======================================================-- 

-- Crear inscripción para pruebas
INSERT INTO solNorte.inscripcion_actividad (fecha_inscripcion, id_actividad, id_socio, borrado)
VALUES ('2023-09-01', @ID_natacion, @ID_socio1, 0);

DECLARE @ID_insc_asistencia INT = SCOPE_IDENTITY();
PRINT 'ID de inscripción creada para pruebas de asistencia: ' + CAST(@ID_insc_asistencia AS VARCHAR);
GO

-- PRUEBAS PARA solNorte.insertar_asistencia
-- Prueba 1: Asistencia válida (Asistió)
BEGIN TRY
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.asistencia WHERE id_inscripcion_actividad = @ID_insc_asistencia;
    
    EXEC solNorte.insertar_asistencia 
        @fecha = '2023-10-05',
        @asistio = 'A',
        @id_inscripcion_actividad = @ID_insc_asistencia;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.asistencia WHERE id_inscripcion_actividad = @ID_insc_asistencia;
    PRINT 'Prueba 1: ÉXITO - Asistencia "A" registrada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 2: Asistencia inválida (valor incorrecto)
BEGIN TRY
    EXEC solNorte.insertar_asistencia 
        @fecha = '2023-10-05',
        @asistio = 'S',  -- Valor inválido
        @id_inscripcion_actividad = @ID_insc_asistencia;
    
    PRINT 'Prueba 2: FALLA - Debió fallar por valor inválido';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El valor para asistio debe ser J (Justificado), A (Asistió) o P (No asistió).'
        PRINT 'Prueba 2: ÉXITO - Validación de valor asistio funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 3: Justificado (J)
BEGIN TRY
    EXEC solNorte.insertar_asistencia 
        @fecha = '2023-10-06',
        @asistio = 'J',
        @id_inscripcion_actividad = @ID_insc_asistencia;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.asistencia WHERE id_inscripcion_actividad = @ID_insc_asistencia;
    PRINT 'Prueba 3: ÉXITO - Asistencia "J" registrada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 3: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 4: No asistió (P)
BEGIN TRY
    EXEC solNorte.insertar_asistencia 
        @fecha = '2023-10-07',
        @asistio = 'P',
        @id_inscripcion_actividad = @ID_insc_asistencia;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.asistencia WHERE id_inscripcion_actividad = @ID_insc_asistencia;
    PRINT 'Prueba 4: ÉXITO - Asistencia "P" registrada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 4: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Obtener ID de asistencia creada en Prueba 1
DECLARE @ID_asistencia INT = (SELECT TOP 1 ID_asistencia FROM solNorte.asistencia 
                             WHERE id_inscripcion_actividad = @ID_insc_asistencia 
                             ORDER BY ID_asistencia);

-- Prueba 5: Modificación válida
BEGIN TRY
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia;
    
    EXEC solNorte.modificar_asistencia
        @ID_asistencia = @ID_asistencia,
        @asistio = 'J';  -- Cambiar de A a J
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia;
    PRINT 'Prueba 5: ÉXITO - Modificación válida funcionó correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 5: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- PRUEBAS PARA solNorte.borrar_asistencia
-- Prueba 6: Borrado exitoso
BEGIN TRY
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia;
    
    EXEC solNorte.borrar_asistencia @ID_asistencia = @ID_asistencia;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia;
    
    DECLARE @borrado BIT = (SELECT borrado FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia);
    
    IF @borrado = 1
        PRINT 'Prueba 6: ÉXITO - Asistencia marcada como borrada correctamente';
    ELSE
        PRINT 'Prueba 6: FALLA - La asistencia no fue marcada como borrada';
END TRY
BEGIN CATCH
    PRINT 'Prueba 6: FALLA INESPERADA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 7: Borrado de registro ya borrado
BEGIN TRY
    EXEC solNorte.borrar_asistencia @ID_asistencia = @ID_asistencia;
    
    PRINT 'Prueba 7: FALLA - Debió fallar por registro ya borrado';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El registro de asistencia no existe o ya está dado de baja.'
        PRINT 'Prueba 7: ÉXITO - Validación de registro ya borrado funcionó correctamente';
    ELSE
        PRINT 'Prueba 7: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 8: Borrado de registro inexistente
BEGIN TRY
    EXEC solNorte.borrar_asistencia @ID_asistencia = 999999;
    
    PRINT 'Falla por registro inexistente';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El registro de asistencia no existe o ya está dado de baja.'
        PRINT 'Prueba 8: ÉXITO - Validación de registro inexistente funcionó correctamente';
    ELSE
        PRINT 'Prueba 8: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO
--======================================================Descuento======================================================-- 

-- Crear factura de prueba
INSERT INTO solNorte.factura (fecha_emision, total, borrado)
VALUES (GETDATE(), 10000.00, 0);

DECLARE @ID_factura INT = SCOPE_IDENTITY();

-- Crear detalle de factura para pruebas
INSERT INTO solNorte.detalle_factura (cantidad, precio_unitario, id_factura, borrado)
VALUES (2, 2500.00, @ID_factura, 0),
       (1, 1800.00, @ID_factura, 0);

DECLARE @ID_detalle1 INT, @ID_detalle2 INT;
SELECT @ID_detalle1 = ID_detalle_factura FROM solNorte.detalle_factura WHERE id_factura = @ID_factura AND precio_unitario = 2500.00;
SELECT @ID_detalle2 = ID_detalle_factura FROM solNorte.detalle_factura WHERE id_factura = @ID_factura AND precio_unitario = 1800.00;

GO

-- PRUEBAS PARA solNorte.insertar_descuento
-- Prueba 1: Inserción válida
BEGIN TRY
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.descuento WHERE id_detalle_factura = @ID_detalle1;
    
    EXEC solNorte.insertar_descuento
        @descripcion = 'Descuento por temporada baja',
        @tipo_descuento = 'Promocional',
        @porcentaje = 0.15,
        @id_detalle_factura = @ID_detalle1;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.descuento WHERE id_detalle_factura = @ID_detalle1;
    PRINT 'Descuento insertado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 1: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 2: Detalle de factura inexistente
BEGIN TRY
--Detalle de factura inexistente 
    EXEC solNorte.insertar_descuento
        @descripcion = 'Descuento inválido',
        @tipo_descuento = 'Promocional',
        @porcentaje = 0.10,
        @id_detalle_factura = 999999;
    END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El detalle de factura especificado no existe'
        PRINT 'Validación de detalle factura funcionó correctamente';
    ELSE
        PRINT 'Prueba 2: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO

-- PRUEBAS PARA solNorte.actualizar_descuento
-- Obtener ID del descuento insertado en Prueba 1
DECLARE @ID_descuento INT = (SELECT TOP 1 ID_descuento FROM solNorte.descuento WHERE id_detalle_factura = @ID_detalle1);

-- Prueba 3: Actualización válida (todos los campos)
BEGIN TRY
   --Actualización completa 
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.descuento WHERE ID_descuento = @ID_descuento;
    
    EXEC solNorte.actualizar_descuento
        @ID_descuento = @ID_descuento,
        @descripcion = 'Descuento por lealtad',
        @tipo_descuento = 'Socio vitalicio',
        @porcentaje = 0.20;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.descuento WHERE ID_descuento = @ID_descuento;
    PRINT 'Descuento actualizado correctamente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 3: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 4: Actualización parcial (solo porcentaje)
BEGIN TRY
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.descuento WHERE ID_descuento = @ID_descuento;
    
    EXEC solNorte.actualizar_descuento
        @ID_descuento = @ID_descuento,
        @porcentaje = 0.25;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.descuento WHERE ID_descuento = @ID_descuento;
    PRINT 'Descuento actualizado parcialmente';
END TRY
BEGIN CATCH
    PRINT 'Prueba 4: FALLA - ' + ERROR_MESSAGE();
END CATCH
GO

-- PRUEBAS PARA solNorte.eliminar_descuento
-- Crear descuento para pruebas de borrado
INSERT INTO solNorte.descuento (descripcion, tipo_descuento, porcentaje, id_detalle_factura)
VALUES ('Descuento por pronto pago', 'Pago anticipado', 0.05, @ID_detalle2);

DECLARE @ID_descuento_borrar INT = SCOPE_IDENTITY();
PRINT 'ID de descuento creado para pruebas de borrado: ' + CAST(@ID_descuento_borrar AS VARCHAR);
GO

-- Prueba 5: Borrado exitoso
BEGIN TRY
    PRINT 'Estado ANTES:';
    SELECT * FROM solNorte.descuento WHERE ID_descuento = @ID_descuento_borrar;
    
    EXEC solNorte.eliminar_descuento @ID_descuento = @ID_descuento_borrar;
    
    PRINT 'Estado DESPUÉS:';
    SELECT * FROM solNorte.descuento WHERE ID_descuento = @ID_descuento_borrar;
    
    IF NOT EXISTS (SELECT 1 FROM solNorte.descuento WHERE ID_descuento = @ID_descuento_borrar)
        PRINT 'Descuento eliminado correctamente';
    ELSE
        PRINT 'Prueba 5: FALLA - El descuento no fue eliminado';
END TRY
BEGIN CATCH
    PRINT 'Prueba 5: FALLA INESPERADA - ' + ERROR_MESSAGE();
END CATCH
GO

-- Prueba 7: Borrado de descuento inexistente
BEGIN TRY
    EXEC solNorte.eliminar_descuento @ID_descuento = 123456789;
    
    PRINT 'Prueba 6: FALLA - Debió fallar por descuento inexistente';
END TRY
BEGIN CATCH
    IF ERROR_MESSAGE() = 'El descuento especificado no existe'
        PRINT 'Validación de descuento inexistente funcionó correctamente';
    ELSE
        PRINT 'Prueba 6: FALLA - Mensaje de error inesperado: ' + ERROR_MESSAGE();
END CATCH
GO


--======================================================Deuda======================================================-- 

-- PRUEBAS PARA solNorte.insertar_deuda
-- Prueba 1: Deuda válida
--Inserto socio activo
INSERT INTO solNorte.socio (nombre, apellido, dni, fecha_nacimiento, borrado)
VALUES ('Lucas', 'Modric', '12345678', '1996-08-01', 0)

--Inserto socio borrado
INSERT INTO solNorte.socio (nombre, apellido, dni, fecha_nacimiento, borrado)
VALUES ('Lucas', 'Rodriguez', '98765432', '1998-10-22', 1)

INSERT INTO solNorte.factura (fecha_emision, monto_total, borrado)
VALUES (GETDATE(), 1000.00, 0), (GETDATE(), 2000.00, 0)

DECLARE @id_factura_valida INT = (SELECT ID_factura FROM solNorte.factura WHERE monto_total = 1000.00);
DECLARE @id_factura_valida2 INT = (SELECT ID_factura FROM solNorte.factura WHERE monto_total = 1000.00);

DECLARE @id_socio_deuda INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '12345678');
DECLARE @id_socio_deuda2 INT = (SELECT ID_socio FROM solNorte.socio WHERE dni = '98765432');

BEGIN TRY 
	EXECUTE solNorte.insertar_deuda
		@recargo_por_vencimiento = 0.10,
        @deuda_acumulada = 1500.00,
        @fecha_readmision = DATEADD(DAY, 30, GETDATE()),
        @id_factura = @id_factura_valida,
        @id_socio = @id_socio_deuda;
	PRINT 'Deuda correctamente insertada'
END TRY

--Prueba 2: Deuda Invalida. Factura no existe
BEGIN TRY
    EXEC solNorte.insertar_deuda 
        @recargo_por_vencimiento = 0.10,
        @deuda_acumulada = 1500.00,
        @id_factura = 9999, 
        @id_socio = @id_socio_deuda;
	PRINT 'No se detecto la factura'
END TRY

--Prueba 3: Deuda Invalida. Socio borrado
BEGIN TRY
    EXEC solNorte.insertar_deuda 
        @recargo_por_vencimiento = 0.10,
        @deuda_acumulada = 1500.00,
        @id_factura = @id_factura_valida2, 
        @id_socio = @id_socio_deuda2;
	PRINT 'Socio borrado'
END TRY

-- Prueba 4: Deuda Inválida - Factura borrada
-- Actualizo la factura como borrada
UPDATE solNorte.factura SET borrado = 1 WHERE ID_factura = @id_factura_valida2;

BEGIN TRY
    EXEC solNorte.insertar_deuda 
        @recargo_por_vencimiento = 0.10,
        @deuda_acumulada = 1500.00,
        @id_factura = @id_factura_valida2, 
        @id_socio = @id_socio_deuda;
    PRINT 'Factura borrada';
END TRY

-- Prueba 5: Deuda Invalida. Fecha readmisión anterior a actual
BEGIN TRY
    EXEC solNorte.insertar_deuda 
        @recargo_por_vencimiento = 0.10,
        @deuda_acumulada = 1500.00,
        @fecha_readmision = DATEADD(DAY, -5, GETDATE()),
        @id_factura = @id_factura_valida,
        @id_socio = @id_socio_deuda;
    PRINT 'Error: No se detectó fecha readmisión inválida';
END TRY
BEGIN CATCH
    PRINT 'Exito Prueba 5'  + ERROR_MESSAGE();
END CATCH

-- Prueba 6: Deuda Invalida. Deuda duplicada para misma factura
BEGIN TRY
    -- Primera inserción 
    EXEC solNorte.insertar_deuda 
        @recargo_por_vencimiento = 0.10,
        @deuda_acumulada = 1500.00,
        @id_factura = @id_factura_valida,
        @id_socio = @id_socio_deuda;
    
    -- Segunda inserción para misma factura (debería fallar)
    EXEC solNorte.insertar_deuda 
        @recargo_por_vencimiento = 0.15,
        @deuda_acumulada = 1600.00,
        @id_factura = @id_factura_valida,
        @id_socio = @id_socio_deuda;
    
    PRINT 'Error: No se detectó deuda duplicada';
END TRY
BEGIN CATCH
    PRINT 'Éxito (Prueba 6): ' + ERROR_MESSAGE();
END CATCH

---- PRUEBAS PARA solNorte.modificar_deuda
-- Obtengo ID de deuda insertada
DECLARE @id_deuda_valida INT = (SELECT ID_deuda FROM solNorte.deuda WHERE id_factura = @id_factura_valida);

-- Prueba 7: Modificación exitosa
BEGIN TRY
    EXEC solNorte.modificar_deuda 
        @ID_deuda = @id_deuda_valida,
        @recargo_por_vencimiento = 0.20,
        @deuda_acumulada = 1800.00,
        @fecha_readmision = DATEADD(DAY, 45, GETDATE());
    PRINT 'Deuda modificada correctamente';
END TRY
BEGIN CATCH
    PRINT 'Error (Prueba 7): ' + ERROR_MESSAGE();
END CATCH

-- Prueba 8: Modificación inválida - Deuda no existe
BEGIN TRY
    EXEC solNorte.modificar_deuda 
        @ID_deuda = 99999,
        @deuda_acumulada = 2000.00;
    PRINT 'Error: No se detectó deuda inexistente';
END TRY

-- Prueba 9: Modificación inválida - Factura no existe
BEGIN TRY
    EXEC solNorte.modificar_deuda 
        @ID_deuda = @id_deuda_valida,
        @id_factura = 99999;
    PRINT 'Error: No se detectó factura inexistente';
END TRY

---- PRUEBAS PARA solNorte.eliminar_deuda
SELECT 1 FROM solNorte.deuda WHERE ID_deuda = @id_deuda_valida
BEGIN TRY
    EXEC solNorte.eliminar_deuda @ID_deuda = @id_deuda_valida;    
    IF EXISTS (SELECT 1 FROM solNorte.deuda WHERE ID_deuda = @id_deuda_valida AND borrado = 1)
        PRINT 'Deuda marcada como borrada correctamente';
    ELSE
        PRINT 'Error: La deuda no se marcó como borrada';
END TRY
BEGIN CATCH
    PRINT 'Error (Prueba 11): ' + ERROR_MESSAGE();
END CATCH
--Prueba borrar una deuda invalida
BEGIN TRY 
	EXEC solNorte.eliminar_deuda @ID_deuda = 99999999
	PRINT 'No se encontro la deuda'
END TRY