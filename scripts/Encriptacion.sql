/*
====================================================================================
 Archivo		: Encriptacion.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Scripts para protección de datos sensibles de los empleados registrados en la base de datos.
 Autor			: G10
 Fecha entrega	: 2025-07-01
====================================================================================
*/

USE Com2900G10
GO

IF NOT EXISTS (
    SELECT * FROM sys.objects 
    WHERE object_id = OBJECT_ID(N'personal.Empleado') AND type = N'U'
)
BEGIN
    CREATE TABLE personal.Empleado (
        id_empleado INT PRIMARY KEY,
        nombre VARBINARY(MAX),
        apellido VARBINARY(MAX),
        dni VARBINARY(MAX),
        direccion VARBINARY(MAX),
        cuil VARBINARY(MAX),
        email_personal VARBINARY(MAX),
        email_empresarial VARCHAR(255),
        turno VARCHAR(50),
        rol VARCHAR(50),
        area VARCHAR(50)
    );
    PRINT 'Tabla Empleado creada correctamente.';
END
ELSE
BEGIN
    PRINT 'La tabla Empleado ya existe.';
END;
GO


CREATE OR ALTER PROCEDURE personal.alta_empleado_encriptado
    @id_empleado INT,
    @nombre VARCHAR(100),
    @apellido VARCHAR(100),
    @dni INT,
    @direccion VARCHAR(255),
    @cuil VARCHAR(200),
    @email_personal VARCHAR(255),
    @email_empresarial VARCHAR(255),
    @turno VARCHAR(50),
    @rol VARCHAR(50),
    @area VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @passphrase NVARCHAR(128) = 'S0lN0rt3#2025!'; 

    INSERT INTO personal.Empleado (
        id_empleado,
        nombre,
        apellido,
        dni,
        direccion,
        cuil,
        email_personal,
        email_empresarial,
        turno,
        rol,
        area
    )
    VALUES (
        @id_empleado,
        ENCRYPTBYPASSPHRASE(@passphrase, @nombre),
        ENCRYPTBYPASSPHRASE(@passphrase, @apellido),
        ENCRYPTBYPASSPHRASE(@passphrase, CAST(@dni AS VARCHAR(20))),
        ENCRYPTBYPASSPHRASE(@passphrase, @direccion),
        ENCRYPTBYPASSPHRASE(@passphrase, @cuil),
        ENCRYPTBYPASSPHRASE(@passphrase, @email_personal),
        @email_empresarial,
        @turno,
        @rol,
        @area
    );

    PRINT 'Empleado registrado con datos encriptados usando passphrase.';
END;
GO



--ejecutar el SP para insertar un empleado
EXEC personal.alta_empleado_encriptado
    @id_empleado = 101,
    @nombre = 'Martín',
    @apellido = 'Pereyra',
    @dni = 34890123,
    @direccion = 'Av. San Martín 1234',
    @cuil = '20-34890123-9',
    @email_personal = 'martin.p@gmail.com',
    @email_empresarial = 'mpereyra@solnorte.com.ar',
    @turno = 'Mañana',
    @rol = 'Administrativo',
    @area = 'Tesoreria';



DECLARE @passphrase NVARCHAR(128) = 'S0lN0rt3#2025!';

SELECT
    id_empleado,
    CONVERT(VARCHAR(100), DECRYPTBYPASSPHRASE(@passphrase, nombre)) AS nombre,
    CONVERT(VARCHAR(100), DECRYPTBYPASSPHRASE(@passphrase, apellido)) AS apellido,
    CAST(CONVERT(VARCHAR(20), DECRYPTBYPASSPHRASE(@passphrase, dni)) AS INT) AS dni,
    CONVERT(VARCHAR(255), DECRYPTBYPASSPHRASE(@passphrase, direccion)) AS direccion,
    CONVERT(VARCHAR(200), DECRYPTBYPASSPHRASE(@passphrase, cuil)) AS cuil,
    CONVERT(VARCHAR(255), DECRYPTBYPASSPHRASE(@passphrase, email_personal)) AS email_personal,
    email_empresarial,
    turno,
    rol,
    area
FROM personal.Empleado;

