/*
====================================================================================
 Archivo		: RquisitosSeguridad.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Scripts para protección de datos sensibles de los empleados registrados en la base de datos.
 Autor			: G10
 Fecha entrega	: 2025-07-01
====================================================================================
*/
USE Com2900G10;
GO

EXEC sp_configure 'remote access'
-- SELECT name from sys.sql_logins	


--	Se crean los usuarios para los desarrolladores.
IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'leonel')
BEGIN
    CREATE LOGIN leonel
    WITH PASSWORD = 'leonel',
         DEFAULT_DATABASE = Com2900G10,
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END
GO

IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'nicolas')
BEGIN
    CREATE LOGIN nicolas
    WITH PASSWORD = 'nicolas',
         DEFAULT_DATABASE = Com2900G10,
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END
GO


IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'iara')
BEGIN
    CREATE LOGIN iara
    WITH PASSWORD = 'iara',
         DEFAULT_DATABASE = Com2900G10,
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END
GO


IF NOT EXISTS (SELECT * FROM sys.sql_logins WHERE name = 'ignacio')
BEGIN
    CREATE LOGIN ignacio
    WITH PASSWORD = 'ignacio',
         DEFAULT_DATABASE = Com2900G10,
         CHECK_POLICY = OFF,
         CHECK_EXPIRATION = OFF;
END
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'leonel')
    CREATE USER leonel FOR LOGIN leonel;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'nicolas')
    CREATE USER nicolas FOR LOGIN nicolas;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'iara')
    CREATE USER iara FOR LOGIN iara;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ignacio')
    CREATE USER ignacio FOR LOGIN ignacio;
GO

ALTER ROLE db_owner ADD MEMBER leonel
ALTER ROLE db_owner ADD MEMBER nicolas
ALTER ROLE db_owner ADD MEMBER iara
ALTER ROLE db_owner ADD MEMBER ignacio
GO

----------------------------------------------------------------------------------------------------------------

--Creacion de Logins y usuarios
CREATE LOGIN jefe_tesoreria WITH PASSWORD = 'T3s0r3r!@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN administrativo_cobranza WITH PASSWORD = 'C0br4nz@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN administrativo_morosidad WITH PASSWORD = 'M0r0s1d@d2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN administrativo_facturacion WITH PASSWORD = 'F4ctur@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN administrativo_socio WITH PASSWORD = 'S0c10s@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN socios_web WITH PASSWORD = 'W3bS0c!@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN presidente WITH PASSWORD = 'Pr3s1d3nt3!2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN vicepresidente WITH PASSWORD = 'V1c3Pr3s!2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN secretario WITH PASSWORD = 'S3cr3t4r!@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;
CREATE LOGIN vocales WITH PASSWORD = 'V0c4l3s!@2025' MUST_CHANGE, CHECK_POLICY = ON, CHECK_EXPIRATION = ON;

--Creacion de roles por area
CREATE ROLE rol_jefe_tesoreria;
CREATE ROLE rol_administrativo_cobranza;
CREATE ROLE rol_administrativo_morosidad;
CREATE ROLE rol_administrativo_facturacion;
CREATE ROLE rol_administrativo_socio;
CREATE ROLE rol_socios_web;
CREATE ROLE rol_presidente;
CREATE ROLE rol_vicepresidente;
CREATE ROLE rol_secretario;
CREATE ROLE rol_vocales;

-- Asignacion de usuarios a roles
CREATE USER user_jefe_tesoreria FOR LOGIN jefe_tesoreria;
ALTER ROLE rol_jefe_tesoreria ADD MEMBER user_jefe_tesoreria;

CREATE USER user_admin_cobranza FOR LOGIN administrativo_cobranza;
ALTER ROLE rol_administrativo_cobranza ADD MEMBER user_administrativo_cobranza;

CREATE USER user_admin_morosidad FOR LOGIN administrativo_morosidad;
ALTER ROLE rol_administrativo_morosidad ADD MEMBER user_administrativo_morosidad;

CREATE USER user_admin_facturacion FOR LOGIN administrativo_facturacion;
ALTER ROLE rol_administrativo_facturacion ADD MEMBER user_administrativo_facturacion;

CREATE USER user_admin_socio FOR LOGIN administrativo_socio;
ALTER ROLE rol_administrativo_socio ADD MEMBER user_admin_socio;

CREATE USER user_socios_web FOR LOGIN socios_web;
ALTER ROLE rol_socios_web ADD MEMBER user_socios_web;

CREATE USER user_presidente FOR LOGIN presidente;
ALTER ROLE rol_presidente ADD MEMBER user_presidente;

CREATE USER user_vicepresidente FOR LOGIN vicepresidente;
ALTER ROLE rol_vicepresidente ADD MEMBER user_vicepresidente;

CREATE USER user_secretario FOR LOGIN secretario;
ALTER ROLE rol_secretario ADD MEMBER user_secretario;

CREATE USER user_vocales FOR LOGIN vocales;
ALTER ROLE rol_vocales ADD MEMBER user_vocales;
GO

--Asignacion de permisos a roles
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.factura TO rol_jefe_tesoreria;
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.detalle_factura TO rol_jefe_tesoreria;
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.cuota_membresia TO rol_jefe_tesoreria;
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.deuda TO rol_jefe_tesoreria;
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.pago TO rol_jefe_tesoreria;
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.reembolso TO rol_jefe_tesoreria;
--GRANT EXECUTE ON SCHEMA::tesoreria TO rol_jefe_tesoreria;

GRANT SELECT, INSERT, UPDATE ON solNorte.pago TO rol_administrativo_cobranza;
GRANT SELECT, INSERT, UPDATE ON solNorte.deuda TO rol_administrativo_cobranza;
GRANT SELECT ON solNorte.socio TO rol_administrativo_cobranza;
GRANT SELECT ON solNorte.factura TO rol_administrativo_cobranza;
DENY DELETE ON solNorte.pago TO rol_administrativo_cobranza;
DENY DELETE ON solNorte.deuda TO rol_administrativo_cobranza;

GRANT SELECT, INSERT, UPDATE ON solNorte.pago TO rol_administrativo_cobranza;
GRANT SELECT, INSERT, UPDATE ON solNorte.deuda TO rol_administrativo_cobranza;
GRANT SELECT ON solNorte.socio TO rol_administrativo_cobranza;
GRANT SELECT ON solNorte.factura TO rol_administrativo_cobranza;
DENY DELETE ON solNorte.pago TO rol_administrativo_cobranza;
DENY DELETE ON solNorte.deuda TO rol_administrativo_cobranza;

GRANT SELECT, UPDATE ON solNorte.deuda TO rol_administrativo_morosidad;
GRANT SELECT ON solNorte.socio TO rol_administrativo_morosidad;
GRANT SELECT ON solNorte.factura TO rol_administrativo_morosidad;
GRANT EXECUTE ON solNorte./*AGREGAR SP CORRESPONDIENTE*/ TO rol_administrativo_morosidad;

GRANT SELECT, UPDATE ON solNorte.deuda TO rol_administrativo_morosidad;
GRANT SELECT ON solNorte.socio TO rol_administrativo_morosidad;
GRANT SELECT ON solNorte.factura TO rol_administrativo_morosidad;
GRANT EXECUTE ON solNorte./*AGREGAR SP CORRESPONDIENTE*/ TO rol_administrativo_morosidad;

GRANT SELECT, INSERT, UPDATE ON solNorte.factura TO rol_administrativo_facturacion;
GRANT SELECT, INSERT, UPDATE ON solNorte.detalle_factura TO rol_administrativo_facturacion;
GRANT SELECT ON solNorte.socio TO rol_administrativo_facturacion;
GRANT SELECT ON solNorte.cuota_membresia TO rol_administrativo_facturacion;
GRANT SELECT ON solNorte.descuento TO rol_administrativo_facturacion;
DENY DELETE ON solNorte.factura TO rol_administrativo_facturacion;
DENY DELETE ON solNorte.detalle_factura TO rol_administrativo_facturacion;

GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.socio TO rol_administrativo_socio;
GRANT SELECT, INSERT, UPDATE, DELETE ON solNorte.grupo_familiar TO rol_administrativo_socio;
GRANT SELECT, INSERT, UPDATE ON solNorte.inscripcion_actividad TO rol_administrativo_socio;
GRANT SELECT ON solNorte.actividad TO rol_administrativo_socio;
GRANT SELECT ON solNorte.horario_de_actividad TO rol_administrativo_socio;

-- Presidente: control total (equivalente a dbo)
ALTER ROLE db_owner ADD MEMBER rol_presidente;

-- Vicepresidente: casi control total pero no puede modificar estructura
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::solNorte TO rol_vicepresidente;
DENY ALTER, CONTROL ON SCHEMA::solNorte TO rol_vicepresidente;

-- Secretario y vocales: solo lectura general
GRANT SELECT ON solNorte.socio TO rol_secretario, rol_vocales;
GRANT SELECT ON solNorte.grupo_familiar TO rol_secretario, rol_vocales;
GRANT SELECT ON solNorte.actividad TO rol_secretario, rol_vocales;
GRANT SELECT ON solNorte.horario_de_actividad TO rol_secretario, rol_vocales;
GRANT SELECT ON solNorte.cuota_membresia TO rol_secretario, rol_vocales;
GRANT SELECT ON solNorte.factura TO rol_secretario, rol_vocales;
GO


--======================================Encriptacion======================================--

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