USE Com2900G10;
GO

CREATE OR ALTER PROCEDURE solNorte.CargarSociosResponsables
    @RutaArchivo VARCHAR(255)  
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#temporal_ResponsablesDePago') IS NOT NULL
            DROP TABLE #temporal_ResponsablesDePago;

        CREATE TABLE #temporal_ResponsablesDePago(
            nro_de_socio VARCHAR(10),
            nombre VARCHAR(20),
            apellido VARCHAR(20),
            DNI VARCHAR(10),
            mail VARCHAR(50),
            fecha_nacimiento VARCHAR(10),
            telefono_contacto VARCHAR(20),
            telefono_emergencia VARCHAR(20),
            nombre_obra_social VARCHAR(20),
            nro_obra_social VARCHAR(20),
            telefono_contacto_emergencia VARCHAR(30)
        );

        DECLARE @SqlBulk NVARCHAR(MAX);
        SET @SqlBulk = N'
            BULK INSERT #temporal_ResponsablesDePago
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                FIRSTROW = 2
            );';

        EXEC sp_executesql @SqlBulk;

        -- Habilitamos IDENTITY_INSERT para poder ignorar el autoincremental
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
			LTRIM(RTRIM(LEFT(nombre, 20))),
			LTRIM(RTRIM(LEFT(apellido, 20))),
			TRY_CONVERT(DATE, fecha_nacimiento, 103),
			CASE 
				WHEN DNI NOT LIKE '%[^0-9]%' THEN CAST(SUBSTRING(DNI, 2, 8) AS INT) 
			END,
			LTRIM(RTRIM(LEFT(REPLACE(REPLACE(telefono_contacto, ' ', ''), '-', ''), 10))),
			LTRIM(RTRIM(LEFT(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', ''), 23))),
			NULLIF(LTRIM(RTRIM(nombre_obra_social)), ''),
			NULLIF(LTRIM(RTRIM(nro_obra_social)), ''),
			CASE
				WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 13 THEN 'Menor'
				WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 18 THEN 'Cadete'
				ELSE 'Mayor'
			END,
			0,
			LTRIM(RTRIM(LEFT(mail, 30))),
			0
		FROM #temporal_ResponsablesDePago
		WHERE  
			TRY_CAST(SUBSTRING(DNI, 2, 8) AS INT) IS NOT NULL
			AND LEN(DNI) = 9
			AND DNI NOT LIKE '%[^0-9]%'
			AND TRY_CONVERT(DATE, fecha_nacimiento, 103) IS NOT NULL;


        -- Deshabilitamos IDENTITY_INSERT para que los proximos inserts vuelvan a ser incremental
        SET IDENTITY_INSERT solNorte.socio OFF;

        -- Uso sql dinamico porque en la función de DBCC CHEKCIDENT no me deja pasarle el 3er parametro (ultimo id) como parámetro, debe ser un valor literal, para poder actualizar el último id sobre 
		-- el que debe basarse la tabla para generar nuevos id
		DECLARE @UltimoID INT;
		SELECT @UltimoID = MAX(CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT))
		FROM #temporal_ResponsablesDePago
		WHERE DNI IS NOT NULL;

		DECLARE @SqlReseed NVARCHAR(MAX);
		SET @SqlReseed = 'DBCC CHECKIDENT (''solNorte.socio'', RESEED, ' + CAST(@UltimoID AS VARCHAR) + ');';
		EXEC sp_executesql @SqlReseed;

        -- Limpiamos la tabla temporal de manera manual, buena práctica
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
-- Ejecutar con la ruta del archivo
DECLARE @RutaArchivoRespPago VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\Datos socios.csv';

EXEC solNorte.CargarSociosResponsables 
    @RutaArchivo = @RutaArchivoRespPago;
GO




--SELECT * FROM solNorte.actividad

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
                ('BAILEARTISTICO', 30000),
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



CREATE OR ALTER PROCEDURE solNorte.CargarPresentismo
    @RutaArchivo VARCHAR(255)  
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF OBJECT_ID('tempdb..#temporal_Presentismo') IS NOT NULL
            DROP TABLE #temporal_Presentismo;

        -- Tabla temporal con la estructura correcta del CSV
        CREATE TABLE #temporal_Presentismo(
            nro_socio_completo VARCHAR(10),
            actividad VARCHAR(50),
            fecha_asistencia VARCHAR(10),
            presentismo VARCHAR(10),
            profesor VARCHAR(50)
        );

        -- Cargar datos del archivo
        DECLARE @SqlBulk NVARCHAR(MAX);
        SET @SqlBulk = N'
            BULK INSERT #temporal_Presentismo
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                FIRSTROW = 2
            );';
        
        EXEC sp_executesql @SqlBulk;

        UPDATE #temporal_Presentismo
        SET 
            nro_socio_completo = LTRIM(RTRIM(nro_socio_completo)),
            actividad = UPPER(LTRIM(RTRIM(actividad))),
            fecha_asistencia = LTRIM(RTRIM(fecha_asistencia)),
            presentismo = UPPER(LTRIM(RTRIM(presentismo))),
            profesor = LTRIM(RTRIM(profesor));

        -- Normalizar número de socio (quita "SN-")
        UPDATE #temporal_Presentismo
        SET nro_socio_completo = SUBSTRING(nro_socio_completo, 4, LEN(nro_socio_completo))
        WHERE nro_socio_completo LIKE 'SN-%';

        -- Filtrar registros válidos con JOIN a socio y actividad
   IF OBJECT_ID('tempdb..#RegistrosValidos') IS NOT NULL DROP TABLE #RegistrosValidos;

        SELECT 
            t.*,
            s.ID_socio,
            a.ID_actividad,
            TRY_CONVERT(DATE, t.fecha_asistencia, 103) AS fecha
        INTO #RegistrosValidos
        FROM #temporal_Presentismo t
        INNER JOIN solNorte.socio s ON s.ID_socio = TRY_CAST(t.nro_socio_completo AS INT)
        INNER JOIN solNorte.actividad a 
            ON a.nombre_actividad COLLATE Modern_Spanish_CI_AI = t.actividad COLLATE Modern_Spanish_CI_AI
        WHERE TRY_CONVERT(DATE, t.fecha_asistencia, 103) IS NOT NULL
          AND t.presentismo IN ('P', 'A', 'J');

        -- Insertar inscripciones si no existen
        INSERT INTO solNorte.inscripcion_actividad (fecha_inscripcion, id_actividad, id_socio, borrado)
        SELECT DISTINCT
            MIN(rv.fecha),
            rv.ID_actividad,
            rv.ID_socio,
            0
        FROM #RegistrosValidos rv
        LEFT JOIN solNorte.inscripcion_actividad ia 
            ON ia.id_socio = rv.ID_socio AND ia.id_actividad = rv.ID_actividad AND ia.borrado = 0
        WHERE ia.ID_inscripcion IS NULL
        GROUP BY rv.ID_actividad, rv.ID_socio;

        -- Insertar asistencias válidas
        INSERT INTO solNorte.asistencia (fecha, presentismo, id_inscripcion_actividad, borrado)
        SELECT
            rv.fecha,
            rv.presentismo,
            ia.ID_inscripcion,
            0
        FROM #RegistrosValidos rv
        INNER JOIN solNorte.inscripcion_actividad ia 
            ON ia.id_socio = rv.ID_socio AND ia.id_actividad = rv.ID_actividad AND ia.borrado = 0
        WHERE NOT EXISTS (
            SELECT 1
            FROM solNorte.asistencia a
            WHERE a.fecha = rv.fecha
              AND a.id_inscripcion_actividad = ia.ID_inscripcion
              AND a.borrado = 0
        );

        DROP TABLE #temporal_Presentismo;
        DROP TABLE #RegistrosValidos;

        PRINT 'Carga completada con éxito.';
        RETURN 1;

    END TRY
    BEGIN CATCH
        PRINT 'Error en la carga: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#temporal_Presentismo') IS NOT NULL DROP TABLE #temporal_Presentismo;
        IF OBJECT_ID('tempdb..#RegistrosValidos') IS NOT NULL DROP TABLE #RegistrosValidos;
        RETURN 0;
    END CATCH
END;
GO


--Ojo según como la tengan en sus pc locales, antes de hacer la entrega deberiamos hacer la ruta relativa, que tome como ráíz el directorio del proyecto
DECLARE @RutaArchivoPresentismo VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\presentismo.csv';
EXEC solNorte.CargarPresentismo
    @RutaArchivo = @RutaArchivoPresentismo;
GO

SELECT TOP 10 *
FROM solNorte.inscripcion_actividad
ORDER BY fecha_inscripcion DESC;

SELECT TOP 10 *
FROM solNorte.asistencia

GO


CREATE OR ALTER PROCEDURE solNorte.CargarSociosMenores
    @RutaArchivo VARCHAR(255)  
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#temporal_GrupoFliar') IS NOT NULL
            DROP TABLE #temporal_GrupoFliar;

        CREATE TABLE #temporal_GrupoFliar(
            nro_de_socio VARCHAR(10),
            nro_responsable VARCHAR(10),
            nombre VARCHAR(20),
            apellido VARCHAR(20),
            DNI VARCHAR(10),
            mail VARCHAR(50),
            fecha_nacimiento VARCHAR(10),
            telefono_contacto VARCHAR(20),
            telefono_emergencia VARCHAR(20),
            nombre_obra_social VARCHAR(20),
            nro_obra_social VARCHAR(20),
            telefono_contacto_emergencia VARCHAR(30),

            -- Campos extra para datos del responsable
            nombre_responsable VARCHAR(20) NULL,
            apellido_responsable VARCHAR(20) NULL,
            DNI_responsable INT NULL,
            email_responsable VARCHAR(50) NULL,
			telefono_responsable VARCHAR(30),
			fecha_nacimiento_responsable VARCHAR(30)
        );

        -- Cargar datos del archivo CSV
        DECLARE @SqlBulk NVARCHAR(MAX);
        SET @SqlBulk = N'
            BULK INSERT #temporal_GrupoFliar
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = '';'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                FIRSTROW = 2
            );';
        EXEC sp_executesql @SqlBulk;

        -- Enriquecer con datos del socio responsable
		UPDATE TF
		SET 
			nombre_responsable = S.nombre,
			apellido_responsable = S.apellido,
			DNI_responsable = S.DNI,
			email_responsable = S.email,
			nro_responsable = S.ID_socio,
			telefono_responsable = S.telefono,
			fecha_nacimiento_responsable = S.fecha_nacimiento
		FROM #temporal_GrupoFliar TF
		INNER JOIN solNorte.socio S 
			ON S.ID_socio = TRY_CAST(SUBSTRING(TF.nro_responsable, 4, LEN(TF.nro_responsable)) AS INT);


        -- Marcar responsables como tales
        UPDATE S
        SET es_responsable = 1
        FROM solNorte.socio S
        WHERE S.ID_socio IN (
            SELECT DISTINCT CAST(SUBSTRING(nro_responsable, 4, LEN(nro_responsable)) AS INT)
            FROM #temporal_GrupoFliar
        );

        -- Insertar menores con todos los datos
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
			id_responsable_a_cargo,
			nombre_responsable,
			apellido_responsable,
			DNI_responsable,
			mail_responsable,
			telefono_responsable,
			fecha_nacimiento_responsable,
			parentezco_con_responsable,
			borrado
		)
		SELECT
			TRY_CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT),
			LTRIM(RTRIM(LEFT(nombre, 20))),
			LTRIM(RTRIM(LEFT(apellido, 20))),
			TRY_CONVERT(DATE, fecha_nacimiento, 103),
			TRY_CAST(DNI AS INT),
			LTRIM(RTRIM(LEFT(REPLACE(REPLACE(telefono_contacto, ' ', ''), '-', ''), 10))),
			LTRIM(RTRIM(LEFT(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', ''), 23))),
			NULLIF(LTRIM(RTRIM(nombre_obra_social)), ''),
			NULLIF(LTRIM(RTRIM(nro_obra_social)), ''),
			CASE
				WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 13 THEN 'Menor'
				WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 18 THEN 'Cadete'
				ELSE 'Mayor'
			END,
			0,
			LTRIM(RTRIM(LEFT(mail, 30))),
			TRY_CAST(SUBSTRING(nro_responsable, 4, LEN(nro_responsable)) AS INT),
			nombre_responsable,
			apellido_responsable,
			DNI_responsable,
			email_responsable,
			telefono_responsable,
			fecha_nacimiento_responsable,
			' ',
			0
		FROM #temporal_GrupoFliar
		WHERE  
			TRY_CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT) IS NOT NULL
			AND TRY_CAST(SUBSTRING(nro_responsable, 4, LEN(nro_responsable)) AS INT) IS NOT NULL
			AND TRY_CAST(DNI AS INT) IS NOT NULL
			AND TRY_CONVERT(DATE, fecha_nacimiento, 103) IS NOT NULL;


		SELECT * FROM #temporal_GrupoFliar;

        SET IDENTITY_INSERT solNorte.socio OFF;

        -- Reseed de IDENTITY
        DECLARE @UltimoID INT;
        SELECT @UltimoID = MAX(CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT))
        FROM #temporal_GrupoFliar
        WHERE DNI IS NOT NULL;

        DECLARE @SqlReseed NVARCHAR(MAX);
        SET @SqlReseed = 'DBCC CHECKIDENT (''solNorte.socio'', RESEED, ' + CAST(@UltimoID AS VARCHAR) + ');';
        EXEC sp_executesql @SqlReseed;

        DROP TABLE #temporal_GrupoFliar;

        PRINT 'Carga de menores completada exitosamente. Último ID reseedeado a: ' + CAST(@UltimoID AS VARCHAR);
        RETURN 1;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();

        IF OBJECT_ID('tempdb..#temporal_GrupoFliar') IS NOT NULL
            DROP TABLE #temporal_GrupoFliar;

        RAISERROR('Error durante la carga: %s', @ErrorSeverity, 1, @ErrorMessage);
        RETURN -1;
    END CATCH;
END;
GO

--Ojo según como la tengan en sus pc locales, antes de hacer la entrega deberiamos hacer la ruta relativa, que tome como ráíz el directorio del proyecto
DECLARE @RutaArchivoSociosMenores VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\Grupo Familiar.csv';
EXEC solNorte.CargarSociosMenores 
    @RutaArchivo = @RutaArchivoSociosMenores;
GO


SELECT * FROM solNorte.socio;