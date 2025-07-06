USE Com2900G10;
GO

CREATE OR ALTER PROCEDURE solNorte.CargarSociosMenores
    @RutaArchivo VARCHAR(255),
    @NombreHoja VARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Verificar que el archivo existe
        DECLARE @FileExists INT
        EXEC master.dbo.xp_fileexist @RutaArchivo, @FileExists OUTPUT
        
        IF @FileExists = 0
        BEGIN
            RAISERROR('El archivo no existe en la ruta especificada', 16, 1);
            RETURN -1;
        END

        IF OBJECT_ID('tempdb..#temporal_GrupoFliar') IS NOT NULL
            DROP TABLE #temporal_GrupoFliar;

        CREATE TABLE #temporal_GrupoFliar(
            nro_de_socio VARCHAR(255),
            nro_responsable VARCHAR(255),
            nombre VARCHAR(255),
            apellido VARCHAR(255),
            DNI BIGINT, -- aca ocurre lo mismo que con telefno y telefono emergencia en la hoja de responsables de pago
            mail VARCHAR(255),
            fecha_nacimiento VARCHAR(255),
            telefono_contacto BIGINT,
            telefono_emergencia BIGINT,
            nombre_obra_social VARCHAR(255),
            nro_obra_social VARCHAR(255),
            telefono_contacto_emergencia VARCHAR(255)
        );

        IF OBJECT_ID('tempdb..#temporal_socio') IS NOT NULL
            DROP TABLE #temporal_socio;

        CREATE TABLE #temporal_socio(
            ID_socio INT,
            nombre VARCHAR(50), 
            apellido VARCHAR(50), 
            fecha_nacimiento DATE, 
            DNI INT, 
            telefono CHAR(10), 
            telefono_de_emergencia VARCHAR(23),
            obra_social VARCHAR(50),
            nro_obra_social VARCHAR(30),
            categoria_socio VARCHAR(10),     
            es_responsable BIT, 
            email VARCHAR(100),
            id_responsable_a_cargo INT,
            nombre_responsable VARCHAR(50),
            apellido_responsable VARCHAR(50),
            DNI_responsable INT,
            mail_responsable VARCHAR(100),
            telefono_responsable CHAR(10),
            fecha_nacimiento_responsable DATE,
            parentezco_con_responsable VARCHAR(15),
            borrado BIT
        );

        DECLARE @sql NVARCHAR(MAX);
        SET @sql = N'
        INSERT INTO #temporal_GrupoFliar
        SELECT *
        FROM OPENROWSET(
            ''Microsoft.ACE.OLEDB.12.0'',
            ''Excel 12.0;HDR=YES;IMEX=1;Database=' + @RutaArchivo + ''',
            ''SELECT * FROM [' + @NombreHoja + '$]''
        );';
        EXEC sp_executesql @sql;

        INSERT INTO #temporal_socio (
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
            borrado
        )
        SELECT
            TRY_CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT),
            LTRIM(RTRIM(LEFT(nombre, 20))),
            LTRIM(RTRIM(LEFT(apellido, 20))),
            TRY_CONVERT(DATE, fecha_nacimiento, 101), -- 101 es formato estadounidense mm/dd/yyyy funciona para m/d/yyyy también, en el archivo fuente, las fechas presentan este formato
            TRY_CAST(DNI AS INT),
            CASE 
                WHEN LEN(REPLACE(REPLACE(telefono_contacto, ' ', ''), '-', '')) = 10 
                THEN REPLACE(REPLACE(telefono_contacto, ' ', ''), '-', '')
                ELSE NULL
            END,
            CASE 
                WHEN LEN(REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', '')) <= 23 
                THEN REPLACE(REPLACE(telefono_emergencia, ' ', ''), '-', '')
                ELSE NULL
            END,
            NULLIF(LTRIM(RTRIM(nombre_obra_social)), ''),
            NULLIF(LTRIM(RTRIM(nro_obra_social)), ''),
            CASE
                WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 101), GETDATE()) < 13 THEN 'MENOR' --en la tabla temporal grupo fliar  siguen siendo varchar, debo castearlas al formato estadounidense para poder trabajar las fechas y determinar categoria
                WHEN DATEDIFF(YEAR, TRY_CONVERT(DATE, fecha_nacimiento, 101), GETDATE()) < 18 THEN 'CADETE'
                ELSE 'MAYOR'
            END,
            0,
            CASE 
                WHEN mail LIKE '%@%.%' THEN LTRIM(RTRIM(mail))
                ELSE NULL
            END,
            TRY_CAST(SUBSTRING(nro_responsable, 4, LEN(nro_responsable)) AS INT), --sanitizo y pongo el nro de responsable como fk 
            0
        FROM #temporal_GrupoFliar
        WHERE  
            TRY_CAST(SUBSTRING(nro_de_socio, 4, LEN(nro_de_socio)) AS INT) IS NOT NULL
            AND TRY_CAST(SUBSTRING(nro_responsable, 4, LEN(nro_responsable)) AS INT) IS NOT NULL
            AND TRY_CAST(DNI AS INT) IS NOT NULL
            AND TRY_CONVERT(DATE, fecha_nacimiento, 101) IS NOT NULL
            AND telefono_emergencia IS NOT NULL;

		-- busco en la tabla socio los socios responsables, para traer los datos necesarios y empezar a armar los registros para los socios menores
        UPDATE ts
        SET 
            nombre_responsable = s.nombre,
            apellido_responsable = s.apellido,
            DNI_responsable = s.DNI,
            mail_responsable = s.email,
            telefono_responsable = s.telefono,
            fecha_nacimiento_responsable = s.fecha_nacimiento,
            parentezco_con_responsable = 'Menor a cargo' 
        FROM #temporal_socio ts
        INNER JOIN solNorte.socio s ON ts.id_responsable_a_cargo = s.ID_socio;

        UPDATE s
        SET es_responsable = 1
        FROM solNorte.socio s
        WHERE s.ID_socio IN (
            SELECT DISTINCT id_responsable_a_cargo 
            FROM #temporal_socio 
            WHERE id_responsable_a_cargo IS NOT NULL
        );


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
            nombre_responsable,
            apellido_responsable,
            DNI_responsable,
            mail_responsable,
            telefono_responsable,
            fecha_nacimiento_responsable,
            parentezco_con_responsable,
            borrado
        FROM #temporal_socio;

        SET IDENTITY_INSERT solNorte.socio OFF;

		--una vez creados los registros, les asigno el ID_socio del responsable que tienen a cargo
		UPDATE s
		SET id_responsable_a_cargo = ts.id_responsable_a_cargo
		FROM solNorte.socio s
		INNER JOIN #temporal_socio ts ON s.ID_socio = ts.ID_socio
		WHERE ts.id_responsable_a_cargo IS NOT NULL;

        -- Reseed de IDENTITY
        DECLARE @UltimoID INT;
        SELECT @UltimoID = MAX(ID_socio)
        FROM #temporal_socio
        WHERE ID_socio IS NOT NULL;


		--Acá comienza la lógica de grupo familiar, busco si existe algun grupo familiar donde esté un socio responsable, si no existe lo creo, añado al responsable y sus menores a cargo
		BEGIN TRANSACTION;

		DECLARE @MinID INT, @MaxID INT;
		DECLARE @CurrentID INT;
		DECLARE @GrupoExistente INT;


		SELECT @MinID = MIN(ID_socio), @MaxID = MAX(ID_socio)
		FROM solNorte.socio
		WHERE es_responsable = 1
		AND ID_socio IN (SELECT DISTINCT id_responsable_a_cargo FROM #temporal_socio WHERE id_responsable_a_cargo IS NOT NULL);

		SET @CurrentID = @MinID;

		WHILE @CurrentID IS NOT NULL AND @CurrentID <= @MaxID
		BEGIN

			IF EXISTS (SELECT 1 FROM solNorte.socio WHERE ID_socio = @CurrentID AND es_responsable = 1)
			BEGIN

				SELECT @GrupoExistente = id_grupo_familiar
				FROM solNorte.socio
				WHERE ID_socio = @CurrentID;
        
				IF @GrupoExistente IS NULL
				BEGIN
					INSERT INTO solNorte.grupo_familiar (cantidad_integrantes, borrado)
					VALUES (1, 0);
            
					SET @GrupoExistente = SCOPE_IDENTITY();

					UPDATE solNorte.socio
					SET id_grupo_familiar = @GrupoExistente
					WHERE ID_socio = @CurrentID;
				END
        
				UPDATE s
				SET id_grupo_familiar = @GrupoExistente
				FROM solNorte.socio s
				INNER JOIN #temporal_socio ts ON s.ID_socio = ts.ID_socio
				WHERE ts.id_responsable_a_cargo = @CurrentID
				AND s.id_grupo_familiar IS NULL;
        

				DECLARE @TotalMiembros INT;
				SELECT @TotalMiembros = COUNT(*)
				FROM solNorte.socio
				WHERE id_grupo_familiar = @GrupoExistente;
        
				UPDATE solNorte.grupo_familiar
				SET cantidad_integrantes = @TotalMiembros
				WHERE ID_grupo_familiar = @GrupoExistente;
			END
    
			SELECT @CurrentID = MIN(ID_socio)
			FROM solNorte.socio
			WHERE es_responsable = 1
			AND ID_socio > @CurrentID
			AND ID_socio IN (SELECT DISTINCT id_responsable_a_cargo FROM #temporal_socio WHERE id_responsable_a_cargo IS NOT NULL);
		END

		COMMIT TRANSACTION;


        IF @UltimoID IS NOT NULL
        BEGIN
            DBCC CHECKIDENT ('solNorte.socio', RESEED, @UltimoID);
            PRINT 'Carga de menores completada exitosamente. Último ID reseedeado a: ' + CAST(@UltimoID AS VARCHAR);
        END
        ELSE
        BEGIN
            PRINT 'Advertencia: No se encontraron registros válidos para insertar.';
        END

        DROP TABLE #temporal_GrupoFliar;
        DROP TABLE #temporal_socio;

        RETURN 1;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();

        IF OBJECT_ID('tempdb..#temporal_GrupoFliar') IS NOT NULL
            DROP TABLE #temporal_GrupoFliar;
            
        IF OBJECT_ID('tempdb..#temporal_socio') IS NOT NULL
            DROP TABLE #temporal_socio;

        RAISERROR('Error durante la carga: %s', @ErrorSeverity, @ErrorState, @ErrorMessage);
        RETURN -1;
    END CATCH;
END;
GO

DECLARE @r VARCHAR(255) = 'C:\tp-bda-grupo-10-unlam\importacion\Datos socios.xlsx';
DECLARE @h VARCHAR(255) = 'Grupo Familiar';
EXEC solNorte.CargarSociosMenores 
    @RutaArchivo = @r,
    @NombreHoja = @h;
GO

--MENORES insertados
SELECT * FROM solNorte.socio s where s.id_responsable_a_cargo IS NOT NULL;
GO

-- Vemos los grupos familiares formados
SELECT 
    s.id_grupo_familiar,
    STRING_AGG(CONCAT(s.nombre, ' ', s.apellido, ' (ID:', s.ID_socio, ')'), ', ') AS miembros,
    COUNT(*) AS cantidad_miembros
FROM solNorte.socio s
WHERE s.id_grupo_familiar IS NOT NULL
GROUP BY s.id_grupo_familiar
ORDER BY s.id_grupo_familiar;
GO

-- podemos ver que hay 2 mayores y 1 solo respnosable.
SELECT * FROM solNorte.socio s WHERE s.id_grupo_familiar = 83;
GO

/*
DELETE FROM solNorte.socio;
DELETE FROM solNorte.grupo_familiar;
*/

