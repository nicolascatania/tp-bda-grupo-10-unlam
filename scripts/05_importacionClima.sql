/*
====================================================================================
 Archivo		: Importacion.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Scripts para importar datos a las tablas desde csv.
 Autor			: G10
 Fecha entrega	: 2025-07-01
====================================================================================
*/

USE Com2900G10
GO

/*
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'import')
BEGIN
    DECLARE @sql NVARCHAR(MAX);
    SET @sql = 'CREATE SCHEMA import';
    EXEC sp_executesql @sql;
END;
GO */

IF NOT EXISTS(SELECT * FROM INFORMATION_SCHEMA.TABLES 
			WHERE TABLE_SCHEMA = 'solNorte' AND TABLE_NAME = 'clima')
BEGIN
	CREATE TABLE solNorte.clima(
		fecha_hora VARCHAR(20) PRIMARY KEY,
		temperatura DECIMAL(5,2),
		lluvia_mm DECIMAL(5,2),
		humedad_relativa INT,
		viento_kmh DECIMAL(5,2),
		llovio BIT,
		ubicacion VARCHAR(100),
		fuente_csv NVARCHAR(255),
		fecha_importacion DATETIME DEFAULT GETDATE()
);
END
GO


CREATE OR ALTER PROCEDURE solNorte.importar_clima
    @RutaArchivo NVARCHAR(500),
	@ubicacion VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Crear staging temporal
    IF OBJECT_ID('tempdb..##Temporal_importar_clima') IS NOT NULL
        DROP TABLE ##Temporal_importar_clima;

    CREATE TABLE ##Temporal_importar_clima (
        fecha_str VARCHAR(20),              -- time en formato ISO con 'T'
        temperatura DECIMAL(5,2),           -- temperature_2m (°C)
        lluvia_mm DECIMAL(5,2),             -- rain (mm)
        humedad_relativa INT,               -- relative_humidity_2m (%)
        viento_kmh DECIMAL(5,2)             -- wind_speed_10m (km/h)
    );

    -- 2. BULK INSERT dinámico desde archivo CSV
 
        DECLARE @sql NVARCHAR(MAX) = '
        BULK INSERT ##Temporal_importar_clima
        FROM ''' + @RutaArchivo + '''
        WITH (
            FIRSTROW = 4,
            FIELDTERMINATOR = '','',
            ROWTERMINATOR = ''\n'',
            CODEPAGE = ''65001''
        );'

        EXEC sp_executesql @sql;

    
    -- 3. Insertar en tabla final sin duplicados
    INSERT INTO solNorte.clima (
        fecha_hora, temperatura, lluvia_mm,
        humedad_relativa, viento_kmh,
        llovio,ubicacion, fuente_csv
    )
    SELECT
        CONVERT(DATETIME, REPLACE(t.fecha_str, 'T', ' ')),  -- ISO8601 a DATETIME
        t.temperatura,
        t.lluvia_mm,
        t.humedad_relativa,
        t.viento_kmh,
        CASE WHEN t.lluvia_mm > 0 THEN 1 ELSE 0 END,
		@ubicacion,
        @RutaArchivo
    FROM ##Temporal_importar_clima t
    WHERE NOT EXISTS (
        SELECT 1
        FROM solNorte.clima d
        WHERE d.fecha_hora = CONVERT(DATETIME, REPLACE(t.fecha_str, 'T', ' '))
    );

    PRINT 'Archivo procesado correctamente.';
END;
GO




EXEC solNorte.importar_clima
    @RutaArchivo = 'C:\tp-bda-grupo-10-unlam\importacion\open-meteo-buenosaires_2025.csv',
	@ubicacion = 'Buenos Aires'
GO

EXEC solNorte.importar_clima
    @RutaArchivo = 'C:\tp-bda-grupo-10-unlam\importacion\open-meteo-buenosaires_2024.csv',
	@ubicacion = 'Buenos Aires'
GO

SELECT * FROM solNorte.clima

SELECT servicename, service_account
FROM sys.dm_server_services;

