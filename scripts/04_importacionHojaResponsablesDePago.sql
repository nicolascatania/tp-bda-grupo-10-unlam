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
            nro_de_socio VARCHAR(255),
            nombre VARCHAR(255),
            apellido VARCHAR(255),
            DNI VARCHAR(255),
            mail VARCHAR(255),
            fecha_nacimiento VARCHAR(255),
            telefono_contacto VARCHAR(255),
            telefono_emergencia VARCHAR(255),
            nombre_obra_social VARCHAR(255),
            nro_obra_social VARCHAR(255),
            telefono_contacto_emergencia VARCHAR(255)
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
			LTRIM(RTRIM(nombre)),
			LTRIM(RTRIM(apellido)),
			TRY_CONVERT(DATE, fecha_nacimiento, 103),
			CASE 
				WHEN DNI NOT LIKE '%[^0-9]%' THEN CAST(SUBSTRING(DNI, 2, 8) AS INT) -- en el csv todos los DNI tiene 9 digitos, todos comienzan con el 2, asumimos que es un error de ingreso y debe omitirse el 2 (primer dígito)
			END,
			LTRIM(RTRIM(REPLACE(REPLACE(telefono_contacto, ' ', ''), '-', ''))), 
			LTRIM(RTRIM(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', ''))), 
			NULLIF(LTRIM(RTRIM(nombre_obra_social)), ''),
			NULLIF(LTRIM(RTRIM(nro_obra_social)), ''),
			CASE
				WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 13 THEN 'MENOR'
				WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 103), GETDATE()) < 18 THEN 'CADETE'
				ELSE 'MAYOR'
			END,
			0,
			REPLACE(LTRIM(RTRIM(mail)), ' ', ''), --limpio espacios entre medio, por ejemplo, Fila 19 del excel CARNERO_ SILVIA VIVIANA @email.com tiene espacios entre medio, los elimino, asumo que no deben incluirse otros _ o hacer otra cosa, simplemente deben limpiarse esos espacios, es un problema de quien haya armado el archivo base
			0
		FROM #temporal_ResponsablesDePago
		WHERE  
			DNI NOT LIKE '%[^0-9]%'
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


DECLARE @RutaArchivoRespPago VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\Datos socios.csv';

EXEC solNorte.CargarSociosResponsables 
    @RutaArchivo = @RutaArchivoRespPago;
GO


SELECT * FROM solNorte.socio;



/*
DELETE FROM solNorte.socio;
DELETE FROM solNorte.grupo_familiar;
*/

