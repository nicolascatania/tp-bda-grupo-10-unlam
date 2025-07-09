/*Este script contiene la creacion de la tabla clima_diario, en ella guardaremos el resultado de consumir la API Open-Meteo.
De esta manera podemos saber para una fecha y ubicacion especifica si llovio o no; esto nos asegura confiabilidad en los datos
y nos permite gestionar los reembolsos correspondiente segun la regla de negocio.*/

EXEC sp_configure 'Ole Automation Procedures';
GO


-- La ejecución de los siguientes SP son necesarios para realizar un llamado a una API
EXEC sp_configure 'show advanced options', 1;	--Este es para poder editar los permisos avanzados.
RECONFIGURE;
GO
EXEC sp_configure 'Ole Automation Procedures', 1;	-- habilitando el controlador OLE permitimos SQL Server interacturar con objetos COM 
RECONFIGURE;
GO

--creamos la tabla donde guardaremos los datos

/*
CREATE TABLE clima_diario (
    fecha DATE NOT NULL,
    ubicacion VARCHAR(100) NOT NULL, --para nuestro caso 'Buenos Aires'
    latitud DECIMAL(8,5),
    longitud DECIMAL(8,5),
    precipitacion_mm DECIMAL(5,2),
    llovio BIT, -- 1 si precipitación > 0
    json_respuesta NVARCHAR(MAX),
    fecha_consulta DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (fecha, ubicacion)
);
GO
*/


-- SP para consultar Open-Meteo y registrar resultado
CREATE OR ALTER PROCEDURE registrar_clima_por_fecha
    @fecha DATE,
    @latitud DECIMAL(8,5),
    @longitud DECIMAL(8,5),
    @ubicacion VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Object INT,
            @ResponseText NVARCHAR(MAX) = '',
            @URL NVARCHAR(1000),
            @precipitacion DECIMAL(5,2),
            @llovio BIT,
            @hr INT,
            @status INT,
            @errorSource VARCHAR(8000),
            @errorDesc VARCHAR(8000);

    -- Construir URL
    SET @URL = 'https://archive-api.open-meteo.com/v1/archive'
                + '?latitude=' + CAST(@latitud AS VARCHAR(20))
                + '&longitude=' + CAST(@longitud AS VARCHAR(20))
                + '&start_date=' + CONVERT(VARCHAR(10), @fecha, 120)
                + '&end_date=' + CONVERT(VARCHAR(10), @fecha, 120)
                + '&daily=precipitation_sum'
                + '&timezone=auto';

    PRINT 'URL: ' + @URL;

    BEGIN TRY
        -- Crear objeto HTTP
        EXEC @hr = sp_OACreate 'MSXML2.ServerXMLHTTP.6.0', @Object OUT;
        EXEC @hr = sp_OAMethod @Object, 'setTimeouts', NULL, 30000, 30000, 30000, 30000;
        EXEC @hr = sp_OAMethod @Object, 'Open', NULL, 'GET', @URL, 'false';
        EXEC @hr = sp_OAMethod @Object, 'Send';
        EXEC @hr = sp_OAGetProperty @Object, 'Status', @status OUT;
        PRINT 'Estado HTTP: ' + CAST(@status AS VARCHAR(10));
        
        -- Obtener respuesta
        DECLARE @responseTable TABLE (response NVARCHAR(MAX));
        INSERT INTO @responseTable (response)
        EXEC @hr = sp_OAMethod @Object, 'responseText';
        SELECT @ResponseText = response FROM @responseTable;
    END TRY
    BEGIN CATCH
        EXEC sp_OAGetErrorInfo @Object, @errorSource OUT, @errorDesc OUT;
        PRINT 'Error OLE: ' + ISNULL(@errorSource, '') + ' - ' + ISNULL(@errorDesc, '');
        PRINT 'Mensaje error: ' + ERROR_MESSAGE();
        
        INSERT INTO clima_diario (fecha, ubicacion, latitud, longitud, precipitacion_mm, llovio, json_respuesta)
        VALUES (@fecha, @ubicacion, @latitud, @longitud, NULL, 0, 'Error: ' + ISNULL(@errorDesc, ''));
        RETURN;
    END CATCH
    FINALLY:
    BEGIN
        IF @Object IS NOT NULL
            EXEC sp_OADestroy @Object;
    END

    -- Extraer precipitación directamente del JSON
    BEGIN TRY
            SELECT TOP 1 @precipitacion = TRY_CAST(value AS DECIMAL(5,2))
            FROM OPENJSON(@ResponseText, '$.daily.precipitation_sum')
            
        PRINT 'Precipitación: ' + ISNULL(CAST(@precipitacion AS VARCHAR(20)), 'NULL');
    END TRY
    BEGIN CATCH
        SET @precipitacion = NULL;
        PRINT 'Error extrayendo precipitación: ' + ERROR_MESSAGE();
    END CATCH


    SET @llovio = CASE WHEN ISNULL(@precipitacion, 0) > 0 THEN 1 ELSE 0 END;

    INSERT INTO clima_diario (fecha, ubicacion, latitud, longitud, precipitacion_mm, llovio, json_respuesta)
    VALUES (@fecha, @ubicacion, @latitud, @longitud, @precipitacion, @llovio, @ResponseText);

    PRINT 'Registro completado exitosamente';
END;
GO
DELETE FROM clima_diario;

EXEC registrar_clima_por_fecha @fecha = '2025-07-07', @latitud = '-34.622', @longitud = '-58.409', @ubicacion = 'Buenos Aires'; -- no debe llover
EXEC registrar_clima_por_fecha @fecha = '2025-05-18', @latitud = '-34.622', @longitud = '-58.409', @ubicacion = 'Buenos Aires'; -- debe llover
EXEC registrar_clima_por_fecha @fecha = '2025-06-14', @latitud = '-34.622', @longitud = '-58.409', @ubicacion = 'Buenos Aires'; -- debe llover
EXEC registrar_clima_por_fecha @fecha = '2025-04-24', @latitud = '-34.622', @longitud = '-58.409', @ubicacion = 'Buenos Aires'; -- debe llover
EXEC registrar_clima_por_fecha @fecha = '2025-07-01', @latitud = '-34.622', @longitud = '-58.409', @ubicacion = 'Buenos Aires'; -- no debe llover
EXEC registrar_clima_por_fecha @fecha = '2024-01-15', @latitud = '-34.622', @longitud = '-58.409', @ubicacion = 'Buenos Aires'; -- no debe llover
-- Ojo con el horario que pueda ver la API
-- debugear el response



SELECT * FROM clima_diario;

