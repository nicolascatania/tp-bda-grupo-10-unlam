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

        -- Usamos una tabla temporal para poder almacenar los datos, así luego procesarlos (filtrar, evitar duplicados y finalmente limpiar los datos)
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

		--acá tenemos que ver bien donde irá el txt con el log de errores
        DECLARE @SqlBulk NVARCHAR(MAX);
        SET @SqlBulk = N'
            BULK INSERT #temporal_ResponsablesDePago
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = '','',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                FIRSTROW = 2,
                ERRORFILE = ''' + @RutaArchivo + '.ERRORS.txt'' 
            );';
        
        EXEC sp_executesql @SqlBulk;

        INSERT INTO solNorte.socio (
			ID_socio
            nombre, 
            apellido, 
            fecha_nacimiento, 
            DNI, 
            telefono, 
            telefono_de_emergencia,
            obra_social,
            nro_obra_social,
            es_responsable, 
            email,
            borrado
        )
        SELECT
			SUBSTRING(nro_socio, 4, LEN(nro_socio)),
            LEFT(LTRIM(RTRIM(nombre)), 20),
            LEFT(LTRIM(RTRIM(apellido)), 20),
            TRY_CONVERT(DATE, fecha_nacimiento, 103),  -- Formato dd/mm/aaaa
            CASE WHEN DNI NOT LIKE '%[^0-9]%' 
                 AND LEN(DNI) BETWEEN 7 AND 8 
                 THEN CAST(DNI AS INT) END,
            LEFT(REPLACE(REPLACE(telefono_contacto, ' ', ''), '-', ''), 10),
            LEFT(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', ''), 23),
            NULLIF(nombre_obra_social, ''),
            NULLIF(nro_obra_social, ''),
            1,  -- Todos son responsables por ahora, pero deberiamos ver bien segun los grupos familiares, es complicado pq necesitamos el socio para tener el grupo fliar y el grupo fliar para saber quen es responsable
            LEFT(LTRIM(RTRIM(mail)), 30),
            0   -- Valor por defecto para borrado
        FROM #temporal_ResponsablesDePago
        WHERE DNI IS NOT NULL;

		-- Es buena práctica que nosotros limpiemos explícitamente la tabla temporal
        DROP TABLE #temporal_ResponsablesDePago;

        PRINT 'Carga completada exitosamente. Filas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR);
		RETURN 1;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        
        -- Limpiar temporal en caso de error
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
            presentismo CHAR(1),
            profesor VARCHAR(50)
        );

        -- Cargar datos del archivo
        DECLARE @SqlBulk NVARCHAR(MAX);
        SET @SqlBulk = N'
            BULK INSERT #temporal_Presentismo
            FROM ''' + @RutaArchivo + '''
            WITH (
                FIELDTERMINATOR = ''\t'',
                ROWTERMINATOR = ''\n'',
                CODEPAGE = ''65001'',
                FIRSTROW = 2,
                ERRORFILE = ''' + @RutaArchivo + '.ERRORS.txt'' 
            );';
        
        EXEC sp_executesql @SqlBulk;

        -- Extraer solo el número de socio (eliminar "SN-")
        UPDATE #temporal_Presentismo
        SET nro_socio_completo = SUBSTRING(nro_socio_completo, 4, LEN(nro_socio_completo))
        WHERE nro_socio_completo LIKE 'SN-%';

        -- Primero, insertar inscripciones si no existen
        INSERT INTO solNorte.inscripcion_actividad (
            fecha_inscripcion,
            id_actividad,
            id_socio,
            borrado
        )
        SELECT DISTINCT
            MIN(TRY_CONVERT(DATE, P.fecha_asistencia, 103)), -- Primera fecha de asistencia como fecha de inscripción
            A.ID_actividad,
            S.ID_socio,
            0
        FROM #temporal_Presentismo P
        INNER JOIN solNorte.socio S ON S.ID_socio = TRY_CAST(P.nro_socio_completo AS INT)
        INNER JOIN solNorte.actividad A ON A.nombre = P.actividad
        WHERE NOT EXISTS (
            SELECT 1 
            FROM solNorte.inscripcion_actividad IA 
            WHERE IA.id_socio = S.ID_socio 
            AND IA.id_actividad = A.ID_actividad
            AND IA.borrado = 0
        )
        GROUP BY A.ID_actividad, S.ID_socio;

        -- Luego, insertar las asistencias
        INSERT INTO solNorte.asistencia (
            fecha,
			presentismo,
            id_inscripcion_actividad,
            borrado
        )
        SELECT
            TRY_CONVERT(DATE, P.fecha_asistencia, 103),
            UPPER(P.presentismo),
            IA.ID_inscripcion,
            0
        FROM #temporal_Presentismo P
        INNER JOIN solNorte.socio S ON S.ID_socio = TRY_CAST(P.nro_socio_completo AS INT)
        INNER JOIN solNorte.actividad A ON A.nombre = P.actividad
        INNER JOIN solNorte.inscripcion_actividad IA ON IA.id_socio = S.ID_socio 
            AND IA.id_actividad = A.ID_actividad
            AND IA.borrado = 0
        WHERE NOT EXISTS (
            SELECT 1 
            FROM solNorte.asistencia ASIS 
            WHERE ASIS.id_inscripcion_actividad = IA.ID_inscripcion
            AND ASIS.fecha = TRY_CONVERT(DATE, P.fecha_asistencia, 103)
            AND ASIS.borrado = 0
        );

        DROP TABLE #temporal_Presentismo;

        PRINT 'Carga de presentismo completada exitosamente. Filas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR);
        RETURN 1;
    END TRY
    BEGIN CATCH
        PRINT 'Error al cargar presentismo: ' + ERROR_MESSAGE();
        IF OBJECT_ID('tempdb..#temporal_Presentismo') IS NOT NULL
            DROP TABLE #temporal_Presentismo;
        RETURN 0;
    END CATCH
END;
GO

--Ojo según como la tengan en sus pc locales, antes de hacer la entrega deberiamos hacer la ruta relativa, que tome como ráíz el directorio del proyecto
DECLARE @RutaArchivoPresentismo VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\presentismo.csv';
EXEC solNorte.CargarSociosResponsables 
    @RutaArchivo = @RutaArchivoPresentismo;
GO