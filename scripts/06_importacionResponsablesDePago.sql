--probando ole db

-- deben setearse estas opciones para poder usar objetos OLE, que permiten interactuar con archvios xlsx.
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;



USE Com2900G10;
GO

CREATE OR ALTER PROCEDURE solNorte.CargarActividades
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Insertar solo actividades que no existen todavía (por nombre_actividad)
        INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual)
        SELECT nombre_actividad, costo_mensual
        FROM (
            VALUES 
                ('FUTSAL', 25000),
                ('VOLEY', 30000),
                ('TAEKWONDO', 25000),
                ('BAILE ARTISTICO', 30000),
                ('NATACION', 45000),
                ('AJEDREZ', 2000)
        ) AS base(nombre_actividad, costo_mensual)
        WHERE NOT EXISTS (
            SELECT 1 
            FROM solNorte.actividad a
            WHERE a.nombre_actividad = base.nombre_actividad
        );

        PRINT 'Actividades cargadas correctamente.';
        RETURN 1;
    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar actividades: ' + ERROR_MESSAGE();
        RETURN 0;
    END CATCH
END;
GO

EXEC solNorte.CargarActividades
GO


CREATE OR ALTER PROCEDURE solNorte.CargarSociosResponsables
    @RutaArchivo VARCHAR(255),
    @NombreHoja VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#temporal_ResponsablesDePago') IS NOT NULL
            DROP TABLE #temporal_ResponsablesDePago;

        -- Crear tabla temporal
        CREATE TABLE #temporal_ResponsablesDePago(
            nro_de_socio VARCHAR(255),
            nombre VARCHAR(255),
            apellido VARCHAR(255),
            DNI VARCHAR(255),
            mail VARCHAR(255),
            fecha_nacimiento VARCHAR(255),
            telefono_contacto BIGINT, -- cuando ponía varchar se rompía todo, ocurre porque el objeto ole hace un mapeo con los datos de las columnas, y los telefonos los interpretaba como numeros grandes o floats, generando números cientificos tipo 134+e0009 y ahi rompia
            telefono_emergencia BIGINT,
            nombre_obra_social VARCHAR(255),
            nro_obra_social VARCHAR(255),
            telefono_contacto_emergencia VARCHAR(255)
        );

        -- Usamos OPENROWSET para importar desde la hoja "Responsables de Pago" del Excel
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
        INSERT INTO #temporal_ResponsablesDePago
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [' + @NombreHoja + '$]''
        );';


        EXEC sp_executesql @sql;

        SET IDENTITY_INSERT solNorte.socio ON;

        INSERT INTO solNorte.socio (
            ID_socio,
            nombre, 
            apellido, 
            fecha_nacimiento, 
            DNI, 
            telefono, 
            telefono_de_emergencia,
            obra_social,
            nro_obra_social,
            categoria_socio,     
            es_responsable, 
            email,
            borrado
        )
        SELECT
            CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT),
            LTRIM(RTRIM(nombre)),
            LTRIM(RTRIM(apellido)),
            TRY_CONVERT(DATE, fecha_nacimiento, 103),
            CASE 
                WHEN DNI NOT LIKE '%[^0-9]%' THEN CAST(SUBSTRING(DNI, 2, 8) AS INT)
            END,
			REPLACE(REPLACE(CAST(telefono_contacto AS VARCHAR(10)), ' ', ''), '-', ''),
            REPLACE(REPLACE(CAST(telefono_emergencia AS VARCHAR(23)), ' ', ''), '-', ''),
            NULLIF(LTRIM(RTRIM(nombre_obra_social)), ''),
            NULLIF(LTRIM(RTRIM(nro_obra_social)), ''),
            CASE
                WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 13 THEN 'MENOR'
                WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 18 THEN 'CADETE'
                ELSE 'MAYOR'
            END,
            0,
            REPLACE(LTRIM(RTRIM(mail)), ' ', ''),
            0
        FROM #temporal_ResponsablesDePago
        WHERE  
            DNI NOT LIKE '%[^0-9]%'
            AND TRY_CONVERT(DATE, fecha_nacimiento, 103) IS NOT NULL;

        SET IDENTITY_INSERT solNorte.socio OFF;

        -- Actualizar el identity
        DECLARE @UltimoID INT;
        SELECT @UltimoID = MAX(CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT))
        FROM #temporal_ResponsablesDePago
        WHERE DNI IS NOT NULL;

        DECLARE @SqlReseed NVARCHAR(MAX);
        SET @SqlReseed = 'DBCC CHECKIDENT (''solNorte.socio'', RESEED, ' + CAST(@UltimoID AS VARCHAR) + ');';
        EXEC sp_executesql @SqlReseed;

        DROP TABLE #temporal_ResponsablesDePago;

        PRINT 'Carga completada exitosamente. Último ID reseedeado a: ' + CAST(@UltimoID AS VARCHAR);
        RETURN 1;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();

        IF OBJECT_ID('tempdb..#temporal_ResponsablesDePago') IS NOT NULL
            DROP TABLE #temporal_ResponsablesDePago;

        RAISERROR('Error durante la carga: %s', @ErrorSeverity, 1, @ErrorMessage);
        RETURN -1;
    END CATCH;
END;
GO



DECLARE @RutaArchivo VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\Datos socios.xlsx';
DECLARE @Hoja VARCHAR(255) = 'Responsables de Pago';
EXEC solNorte.CargarSociosResponsables 
    @RutaArchivo = @RutaArchivo,
    @NombreHoja = @Hoja;

SELECT * FROM solNorte.socio;

/*
DELETE FROM solNorte.socio;
DELETE FROM solNorte.grupo_familiar;
*/

