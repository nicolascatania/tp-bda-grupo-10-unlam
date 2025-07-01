-- Entrega 7
/*
	Asignar los roles correspondientes segun el area
*/

USE Com2900G10;
GO

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


--------------ENCRIPTACION--------------

-- Agregamos un campo para cada dato cifrado
ALTER TABLE solNorte.socio
ADD 
    dni_encrypt VARBINARY(256),
    direccion_encrypt VARBINARY(256),
    telefono_encrypt VARBINARY(256),
    email_encrypt VARBINARY(256);
GO

-- Para DNI
DECLARE @FraseClaveDNI NVARCHAR(128) = 'ClaveSeguraDNI123!';
UPDATE solNorte.socio
SET dni_encrypt = EncryptByPassPhrase(@FraseClaveDNI, dni, 1, CONVERT(varbinary, id_socio));
GO

-- Para dirección
DECLARE @FraseClaveDireccion NVARCHAR(128) = 'ClaveSeguraDireccion456!';
UPDATE solNorte.socio
SET direccion_encrypt = EncryptByPassPhrase(@FraseClaveDireccion, direccion, 1, CONVERT(varbinary, id_socio));
GO

-- Para teléfono
DECLARE @FraseClaveTelefono NVARCHAR(128) = 'ClaveSeguraTelefono789!';
UPDATE solNorte.socio
SET telefono_encrypt = EncryptByPassPhrase(@FraseClaveTelefono, telefono, 1, CONVERT(varbinary, id_socio));
GO

-- Para email
DECLARE @FraseClaveEmail NVARCHAR(128) = 'ClaveSeguraEmail012!';
UPDATE solNorte.socio
SET email_encrypt = EncryptByPassPhrase(@FraseClaveEmail, email, 1, CONVERT(varbinary, id_socio));
GO