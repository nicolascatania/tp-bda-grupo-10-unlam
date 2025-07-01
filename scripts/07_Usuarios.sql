/*
====================================================================================
 Archivo		: Usuarios.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Scripts para los login y usuarios.
 Autor			: G10
 Fecha entrega	: 2025-07-01
====================================================================================
*/
USE Com2900G10
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
go

----------------------------------------------------------------------------------------------------------------

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Jefe_Tesoreria' AND type = 'R')
    CREATE ROLE Jefe_Tesoreria;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Administrativo_Cobranza' AND type = 'R')
    CREATE ROLE Administrativo_Cobranza;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Administrativo_Morosidad' AND type = 'R')
    CREATE ROLE Administrativo_Morosidad;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Administrativo_Facturacion' AND type = 'R')
    CREATE ROLE Administrativo_Facturacion;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Administrativo_Socio' AND type = 'R')
    CREATE ROLE Administrativo_Socio;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Socio_Web' AND type = 'R')
    CREATE ROLE Socio_Web;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Presidente' AND type = 'R')
    CREATE ROLE Presidente;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Vicepresidente' AND type = 'R')
    CREATE ROLE Vicepresidente;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Secretario' AND type = 'R')
    CREATE ROLE Secretario;

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'Vocales' AND type = 'R')
    CREATE ROLE Vocales;

----------------------------------------------
-- ROL: Jefe_Tesoreria
----------------------------------------------
GRANT EXECUTE ON OBJECT::solNorte.insertar_pago				TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::solNorte.modificar_pago			TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::solNorte.eliminar_pago				TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::solNorte.alta_reembolso			TO Jefe_Tesoreria;


----------------------------------------------
-- ROL: Administrativo_Cobranza
----------------------------------------------
GRANT EXECUTE ON OBJECT::solNorte.insertar_pago				TO Administrativo_Cobranza;
GRANT EXECUTE ON OBJECT::solNorte.modificar_pago			TO Administrativo_Cobranza;
GRANT EXECUTE ON OBJECT::solNorte.alta_reembolso			TO Administrativo_Cobranza;

----------------------------------------------
-- ROL: Administrativo_Morosidad
----------------------------------------------
GRANT EXECUTE ON OBJECT::emitirFactura						TO Administrativo_Morosidad;
GRANT EXECUTE ON OBJECT::modificarFactura					TO Administrativo_Morosidad;

----------------------------------------------
-- ROL: Administrativo_Facturacion
----------------------------------------------
GRANT EXECUTE ON OBJECT::solNorte.insertar_factura			TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::solNorte.anular_factura			TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::solNorte.insertar_detalle_factura	TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::modificar_detalle_factura			TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::eliminar_detalle_factura			TO Administrativo_Facturacion;

----------------------------------------------
-- ROL: Administrativo_Socio
----------------------------------------------
GRANT EXECUTE ON OBJECT::solNorte.alta_socio				TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::solNorte.modificar_socio			TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::solNorte.baja_socio				TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::solNorte.alta_grupo_familiar		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::solNorte.modificar_grupo_familiar	TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::solNorte.baja_grupo_familiar		TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::solNorte.insertar_actividad		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::solNorte.modificar_actividad		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::solNorte.borrar_actividad			TO Administrativo_Socio;

----------------------------------------------
-- ROL: Socio_Web
----------------------------------------------
--consultar pagos
--consultar asistencia
--consultar 
----------------------------------------------
-- ROL: Presidente
----------------------------------------------
GRANT EXECUTE ON SCHEMA::solNorte							TO Presidente;
GRANT EXECUTE ON SCHEMA::personal							TO Presidente;

----------------------------------------------
-- ROL: Vicepresidente
----------------------------------------------
GRANT EXECUTE ON SCHEMA::solNorte							TO Presidente;
GRANT EXECUTE ON SCHEMA::personal							TO Presidente;

----------------------------------------------
-- ROL: Secretario
----------------------------------------------
GRANT EXECUTE ON SCHEMA::Rep								TO Secretario;

GRANT EXECUTE ON OBJECT::solNorte.insertar_factura			TO Secretario;
GRANT EXECUTE ON OBJECT::solNorte.anular_factura			TO Secretario;

GRANT EXECUTE ON OBJECT::solNorte.alta_socio				TO Secretario;
GRANT EXECUTE ON OBJECT::solNorte.modificar_socio			TO Secretario;

GRANT EXECUTE ON OBJECT::solNorte.alta_grupo_familiar		TO Secretario;
GRANT EXECUTE ON OBJECT::solNorte.modificar_grupo_familiar	TO Secretario;

GRANT EXECUTE ON OBJECT::solNorte.insertar_actividad		TO Secretario;
GRANT EXECUTE ON OBJECT::solNorte.modificar_actividad		TO Secretario;
GRANT EXECUTE ON OBJECT::solNorte.borrar_actividad			TO Secretario;

----------------------------------------------
-- ROL: Vocales

----------------------------------------------