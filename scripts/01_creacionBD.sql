/*
====================================================================================
 Archivo		: 01_creacionBD.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Script para creacion de la base de datos y esquemas.
 Autor			: G10
 Fecha entrega	: 2025-07-11
====================================================================================
*/


IF NOT EXISTS (
    SELECT name 
    FROM sys.databases 
    WHERE name = 'Com2900G10'
)
BEGIN
    CREATE DATABASE Com2900G10;
END

GO


USE Com2900G10;
GO

SET nocount ON;
GO

--Este esquema es para todos los elementos involucrados directamente en los procesos del sistema
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'solNorte'
)
BEGIN
    EXEC('CREATE SCHEMA solNorte');
END

GO

-- Este esquema es para generar juegos de datos random, nombres, apellidos, fechas, lo que se neceste para generar datos y asi­ realizar pruebas
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'datosParaTest'
)
BEGIN
    EXEC('CREATE SCHEMA datosParaTest');
END

GO


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'rep')
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'CREATE SCHEMA rep';
    EXEC sp_executesql @sql;
END;
GO


IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'personal')
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'CREATE SCHEMA personal';
    EXEC sp_executesql @sql;
END;
GO