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
		fecha DATE PRIMARY KEY,
		llovio BIT,
		ubicacion VARCHAR(100)
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
    IF OBJECT_ID('tempdb..#Temporal_importar_clima') IS NOT NULL
        DROP TABLE #Temporal_importar_clima;

    CREATE TABLE #Temporal_importar_clima (
        fecha_str VARCHAR(255),              -- time en formato ISO con 'T'
        temperatura DECIMAL(5,2),           -- temperature_2m (°C)
        lluvia_mm DECIMAL(5,2),             -- rain (mm)
        humedad_relativa INT,               -- relative_humidity_2m (%)
        viento_kmh DECIMAL(5,2)             -- wind_speed_10m (km/h)
    );

    -- 2. BULK INSERT dinámico desde archivo CSV
    DECLARE @sql NVARCHAR(MAX) = '
    BULK INSERT #Temporal_importar_clima
    FROM ''' + @RutaArchivo + '''
    WITH (
        FIRSTROW = 4,  
        FIELDTERMINATOR = '','',
        ROWTERMINATOR = ''0x0a'',
        CODEPAGE = ''65001'',
        TABLOCK
    );'

    EXEC sp_executesql @sql;
    
    -- 3. Insertar en tabla final agrupando por fecha (sin hora)
    INSERT INTO solNorte.clima (
        fecha,
        llovio,
        ubicacion
    )
    SELECT 
        CONVERT(DATE, REPLACE(t.fecha_str, 'T', ' ')),  -- Solo la parte de fecha
        MAX(CASE WHEN t.lluvia_mm > 0 THEN 1 ELSE 0 END), -- Si llovió en algún momento del día
        @ubicacion
    FROM #Temporal_importar_clima t
    WHERE NOT EXISTS (
        SELECT 1 
        FROM solNorte.clima d 
        WHERE d.fecha = CONVERT(DATE, REPLACE(t.fecha_str, 'T', ' '))
    )
    AND t.fecha_str IS NOT NULL
    GROUP BY CONVERT(DATE, REPLACE(t.fecha_str, 'T', ' '));
   
    DROP TABLE #Temporal_importar_clima;

END;
GO


EXEC solNorte.importar_clima
    @RutaArchivo = 'C:\tp-bda-grupo-10-unlam\importacion\open-meteo-buenosaires_2024.csv',
	@ubicacion = 'Buenos Aires'
GO


EXEC solNorte.importar_clima
    @RutaArchivo = 'C:\tp-bda-grupo-10-unlam\importacion\open-meteo-buenosaires_2025.csv',
	@ubicacion = 'Buenos Aires'
GO


SELECT top 100 * FROM solNorte.clima ORDER by fecha DESC; 



/*
DROP TABLE solNorte.clima;
DELETE FROM solNorte.clima;
*/