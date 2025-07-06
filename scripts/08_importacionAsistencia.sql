USE Com2900G10;
GO

CREATE OR ALTER PROCEDURE solNorte.CargarPresentismo
    @RutaArchivo VARCHAR(255),
    @NombreHoja VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @FileExists INT
        EXEC master.dbo.xp_fileexist @RutaArchivo, @FileExists OUTPUT
        
        IF @FileExists = 0
        BEGIN
            RAISERROR('El archivo no existe en la ruta especificada', 16, 1);
            RETURN -1;
        END

        IF OBJECT_ID('tempdb..#temporal_presentismo') IS NOT NULL
            DROP TABLE #temporal_presentismo;

        CREATE TABLE #temporal_presentismo(
            nro_de_socio VARCHAR(255),
			nombre_actividad VARCHAR(255),
            fecha_asistencia VARCHAR(255),
            presentismo VARCHAR(255),
            profesor VARCHAR(255)
        );

      
		DECLARE @sql NVARCHAR(MAX);
		SET @sql = N'
		INSERT INTO #temporal_presentismo (
			nro_de_socio,
			nombre_actividad,
			fecha_asistencia,
			presentismo,
			profesor
		)
		SELECT 
			[Nro de Socio],
			[Actividad],
			[fecha de asistencia],
			[Asistencia],
			[Profesor]
		FROM OPENROWSET(
			''Microsoft.ACE.OLEDB.12.0'',
			''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
			''SELECT * FROM [' + @NombreHoja + '$]''
		);';

        EXEC sp_executesql @sql;

        IF OBJECT_ID('tempdb..#temporal_primeraInscripcionPersonaXActividad') IS NOT NULL
            DROP TABLE #temporal_primeraInscripcionPersonaXActividad;

        CREATE TABLE #temporal_primeraInscripcionPersonaXActividad(
            id_socio INT,
            id_actividad INT,
            fecha_inscripcion DATE
        );

        -- Para cada socio y cada actividad que figure que el socio realiza en el excel
		-- se carga como inscripcion a la actividad (y asistencia por supuesto) la fecha más antigua encontrada
		-- valida que exista el socio
		INSERT INTO solNorte.inscripcion_actividad (
			fecha_inscripcion,
			id_actividad,
			id_socio,
			borrado,
			fecha_borrado
		)
		SELECT
			MIN(TRY_CONVERT(DATE, p.fecha_asistencia, 103)) AS fecha_inscripcion,
			a.ID_actividad,
			CAST(SUBSTRING(p.nro_de_socio, 4, LEN(p.nro_de_socio)) AS INT) AS id_socio,
			0,
			NULL
		FROM #temporal_presentismo p
		INNER JOIN solNorte.actividad a 
			ON p.nombre_actividad = a.nombre_actividad
		INNER JOIN solNorte.socio s
			ON s.ID_socio = CAST(SUBSTRING(p.nro_de_socio, 4, LEN(p.nro_de_socio)) AS INT)
		WHERE TRY_CONVERT(DATE, p.fecha_asistencia, 101) IS NOT NULL
		GROUP BY 
			CAST(SUBSTRING(p.nro_de_socio, 4, LEN(p.nro_de_socio)) AS INT), 
			a.ID_actividad;


		-- Ahora si inserto las asistencias, primero necesitaba tener las inscripciones de actividad para poder usar los id de estos registros como FK en asistencia
		INSERT INTO solNorte.asistencia (fecha, presentismo, id_inscripcion_actividad)
		SELECT 
			TRY_CONVERT(DATE, p.fecha_asistencia, 101),
			UPPER(p.presentismo),
			ia.ID_inscripcion
		FROM #temporal_presentismo p
		INNER JOIN solNorte.actividad a 
			ON p.nombre_actividad = a.nombre_actividad
		INNER JOIN solNorte.inscripcion_actividad ia 
			ON ia.id_actividad = a.ID_actividad
			AND ia.id_socio = CAST(SUBSTRING(p.nro_de_socio, 4, LEN(p.nro_de_socio)) AS INT)
		WHERE 
			LEN(p.presentismo) = 1
			AND TRY_CONVERT(DATE, p.fecha_asistencia, 101) IS NOT NULL;


        DROP TABLE #temporal_presentismo;
		DROP TABLE #temporal_primeraInscripcionPersonaXActividad
        RETURN 1;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

            
        IF OBJECT_ID('tempdb..#temporal_presentismo') IS NOT NULL
            DROP TABLE #temporal_presentismo;
		
		IF OBJECT_ID('tempdb..#temporal_primeraInscripcionPersonaXActividad') IS NOT NULL
            DROP TABLE #temporal_primeraInscripcionPersonaXActividad;

        RAISERROR('Error durante la carga: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
        RETURN -1;
    END CATCH;
END;
GO

DECLARE @r VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\Datos socios.xlsx';
DECLARE @h VARCHAR(255) = 'presentismo_actividades';
EXEC solNorte.CargarPresentismo
    @RutaArchivo = @r,
    @NombreHoja = @h;
GO



SELECT * FROM solNorte.inscripcion_actividad;


SELECT * FROM solNorte.asistencia;


/**
DELETE FROM solNorte.asistencia;
DELETE FROM solNorte.inscripcion_actividad;

*/