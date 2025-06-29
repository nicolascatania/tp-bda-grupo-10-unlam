USE Com2900G10;
GO

--Tenemos que usar OPENROWSET para leer .xlsx
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;

SELECT *
INTO #temporal_ResponsablesDePago
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\Importaciones\Datos socios.xlsx;HDR=YES;IMEX=1',
    'SELECT * FROM [Responsables De Pago$]');


--Ojo según como la tengan en sus pc locales, antes de hacer la entrega deberiamos hacer la ruta relativa, que tome como ráíz el directorio del proyecto
DECLARE @RutaArchivoRespPago VARCHAR(255) = 'C:\Users\Nicolas\Desktop\tp-bda-grupo-10-unlam\importacion\Datos socios.xlsx';

-- Ejecutar con la ruta del archivo

EXEC solNorte.sp_CargarSociosResponsables 
    @RutaArchivo = @RutaArchivoRespPago;
GO


CREATE OR ALTER PROCEDURE solNorte.sp_CargarSociosResponsables
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
            1,  -- Todos son responsables
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