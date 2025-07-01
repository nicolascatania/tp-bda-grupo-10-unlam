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
GRANT EXECUTE ON OBJECT::insertarPago			TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::modificarPago			TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::borrarPago				TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::insertarReembolso		TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::modificarReembolso		TO Jefe_Tesoreria;
GRANT EXECUTE ON OBJECT::borrarReembolso		TO Jefe_Tesoreria;

----------------------------------------------
-- ROL: Administrativo_Cobranza
----------------------------------------------
GRANT EXECUTE ON OBJECT::insertarPago			TO Administrativo_Cobranza;
GRANT EXECUTE ON OBJECT::modificarPago			TO Administrativo_Cobranza;
GRANT EXECUTE ON OBJECT::insertarReembolso		TO Administrativo_Cobranza;
GRANT EXECUTE ON OBJECT::modificarReembolso		TO Administrativo_Cobranza;

----------------------------------------------
-- ROL: Administrativo_Morosidad
----------------------------------------------
GRANT EXECUTE ON OBJECT::emitirFactura			TO Administrativo_Morosidad;
GRANT EXECUTE ON OBJECT::modificarFactura		TO Administrativo_Morosidad;

----------------------------------------------
-- ROL: Administrativo_Facturacion
----------------------------------------------
GRANT EXECUTE ON OBJECT::emitirFactura			TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::modificarFactura		TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::borrarFactura			TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::insertarItem_factura	TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::modificarItem_factura	TO Administrativo_Facturacion;
GRANT EXECUTE ON OBJECT::borrarItem_factura		TO Administrativo_Facturacion;

----------------------------------------------
-- ROL: Administrativo_Socio
----------------------------------------------
GRANT EXECUTE ON OBJECT::insertarSocio			TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::modificarSocio			TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::borrarSocio			TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::insertarInvitado		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::modificarInvitado		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::borrarInvitado			TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::insertarSuscripcion	TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::modificarSuscripcion	TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::borrarSuscripcion		TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::insertarResponsable	TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::modificarResponsable	TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::borrarResponsable		TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::insertarCategoria		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::modificarCategoria		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::borrarCategoria		TO Administrativo_Socio;

GRANT EXECUTE ON OBJECT::insertarActividad		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::modificarActividad		TO Administrativo_Socio;
GRANT EXECUTE ON OBJECT::eliminarActividad		TO Administrativo_Socio;

----------------------------------------------
-- ROL: Socio_Web
----------------------------------------------
GRANT EXECUTE ON OBJECT::insertarReserva

----------------------------------------------
-- ROL: Presidente
----------------------------------------------
GRANT EXECUTE ON SCHEMA::solNorte						TO Presidente;
GRANT EXECUTE ON SCHEMA::personal						TO Presidente;

----------------------------------------------
-- ROL: Vicepresidente
----------------------------------------------
GRANT EXECUTE ON SCHEMA::solNorte						TO Presidente;
GRANT EXECUTE ON SCHEMA::personal						TO Presidente;

----------------------------------------------
-- ROL: Secretario
----------------------------------------------
GRANT EXECUTE ON SCHEMA::Rep						TO Secretario;

GRANT EXECUTE ON OBJECT::emitirFactura			TO Secretario;
GRANT EXECUTE ON OBJECT::insertarItem_factura	TO Secretario;

GRANT EXECUTE ON OBJECT::insertarSocio			TO Secretario;
GRANT EXECUTE ON OBJECT::modificarSocio			TO Secretario;

GRANT EXECUTE ON OBJECT::insertarInvitado		TO Secretario;
GRANT EXECUTE ON OBJECT::modificarInvitado		TO Secretario;

GRANT EXECUTE ON OBJECT::insertarResponsable	TO Secretario;
GRANT EXECUTE ON OBJECT::modificarCategoria		TO Secretario;

GRANT EXECUTE ON OBJECT::insertarCategoria		TO Secretario;
GRANT EXECUTE ON OBJECT::modificarCategoria		TO Secretario;
GRANT EXECUTE ON OBJECT::borrarCategoria		TO Secretario;

GRANT EXECUTE ON OBJECT::insertarActividad		TO Secretario;
GRANT EXECUTE ON OBJECT::modificarActividad		TO Secretario;
GRANT EXECUTE ON OBJECT::eliminarActividad		TO Secretario;

----------------------------------------------
-- ROL: Vocales

----------------------------------------------