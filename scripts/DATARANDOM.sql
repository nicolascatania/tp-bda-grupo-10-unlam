USE Com2900G10;
GO

-- =====================================================
-- Generación de datos de prueba para Facturas, Pagos y Entradas de Pileta
-- =====================================================

-- Tabla temporal para almacenar IDs de socios (para evitar hardcodear IDS)
IF OBJECT_ID('tempdb..#SociosActivos') IS NOT NULL DROP TABLE #SociosActivos
CREATE TABLE #SociosActivos (ID_socio INT, ID_grupo_familiar INT, fecha_nac DATETIME, rowNum INT IDENTITY(1,1))

INSERT INTO #SociosActivos
SELECT ID_socio, id_grupo_familiar, fecha_nacimiento 
FROM solNorte.socio 
WHERE borrado = 0 AND es_responsable = 1;
GO

DECLARE @TOTALSOCIOS INT;
SELECT @TOTALSOCIOS = COUNT(*) FROM #SociosActivos;

DECLARE @contador INT = 1;
DECLARE @fechaRandom DATETIME;
DECLARE @diasDiferencia INT;
DECLARE @idSocioRandom INT;
DECLARE @tipoEntrada CHAR(8);
DECLARE @montoSocio DECIMAL(10,2);
DECLARE @montoInvitado DECIMAL(8,2);
DECLARE @feNac DATETIME;
DECLARE @edad INT;

WHILE @contador <= 1000
BEGIN

    SET @diasDiferencia = DATEDIFF(DAY, '2025-01-01', GETDATE());
    SET @fechaRandom = DATEADD(DAY, CAST(RAND() * @diasDiferencia AS INT), '2025-01-01');
    
    SELECT @idSocioRandom = ID_socio, @feNac = fecha_nac
    FROM #SociosActivos 
    WHERE rowNum = CAST(CEILING(RAND() * @TOTALSOCIOS) AS INT);
    
    -- Calcular edad del socio en la fecha de entrada
    SET @edad = DATEDIFF(YEAR, @feNac, @fechaRandom) - 
                CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, @feNac, @fechaRandom), @feNac) > @fechaRandom 
                     THEN 1 ELSE 0 END;

    INSERT INTO solNorte.factura (
        nro_factura,
        tipo_factura,
        fecha_emision,
        CAE,
        estado,
        importe_total,
        vencimiento_CAE,
        id_socio
    )
    VALUES (
        @contador,
        'C',
        CONVERT(VARCHAR, @fechaRandom, 101),
        1029381290,
        'PAGADA',
        0,
        DATEADD(DAY, 5, @fechaRandom),
        @idSocioRandom
    );

    DECLARE @idf INT = SCOPE_IDENTITY();
    DECLARE @montoFinalEP DECIMAL(10,2);

        -- Decidir si es entrada para socio o invitado (50% de probabilidad para cada uno)
        IF CAST(RAND() * 2 AS INT) = 1
        BEGIN
            SET @tipoEntrada = 'SOCIO';
            SET @montoSocio = CASE WHEN @edad < 12 THEN 15000.00 ELSE 25000.00 END;
            SET @montoInvitado = NULL;
            SET @montoFinalEP = @montoSocio;
        END
        ELSE
        BEGIN
            SET @tipoEntrada = 'INVITADO';
            SET @montoInvitado = CASE WHEN @edad < 12 THEN 2000.00 ELSE 30000.00 END;
            SET @montoSocio = NULL;
            SET @montoFinalEP = @montoInvitado;
        END
        
        -- Insertar entrada de pileta
        INSERT INTO solNorte.entrada_pileta (
            fecha_entrada,
            monto_socio,
            monto_invitado,
            tipo_entrada_pileta,
            fue_reembolsada,
            id_socio,
            borrado
        )
        VALUES (
            @fechaRandom,
            @montoSocio,
            @montoInvitado,
            @tipoEntrada,
            0, 
            @idSocioRandom,
            0  
        );

        DECLARE @idEP INT = SCOPE_IDENTITY();

		IF @montoFinalEP < 1
		BEGIN
			PRINT (' ESTA MAL EL MONTO');
		END

        -- generar un detalle factura con la entrada
        INSERT INTO solNorte.detalle_factura(descripcion, cantidad, subtotal, id_factura, es_entrada_pileta, id_item) 
        VALUES ('Entrada pileta', 1, @montoFinalEP, @idf, 1, @idEP);

        DECLARE @idDF INT = SCOPE_IDENTITY();

        
    -- hacer detalle factura a la actividad
    /*
	DECLARE @act VARCHAR(30);
    DECLARE @descr VARCHAR(50);
    
	
    SELECT @act = a.nombre_actividad 
    FROM solNorte.inscripcion_actividad ia 
    JOIN solNorte.actividad a ON ia.id_actividad = a.ID_actividad
    WHERE ia.id_socio = @idSocioRandom;
    
    SET @descr = CONCAT('ACTIVIDAD: ', ISNULL(@act, 'Sin actividad'));
    
    -- generar otro detalle factura para cada actividad del id_socio actual
    INSERT INTO solNorte.detalle_factura (descripcion, cantidad, subtotal, id_factura) 
    VALUES (@descr, 1, CASE WHEN @act IS NOT NULL THEN 10000.00 ELSE 0 END, @idf);

    DECLARE @idDF2 INT = SCOPE_IDENTITY();*/

  
    -- actualizar el monto total de la factura con los subtotales de los detalles
    UPDATE solNorte.factura
    SET importe_total = @montoFinalEP;
    
    -- se genera un pago para la factura
    INSERT INTO solNorte.pago (fecha_pago, medio_de_pago, monto, estado, id_factura) 
    VALUES (CONVERT(VARCHAR, @fechaRandom, 101), 'MERCADOPAGO_TRANSFERENCIA', @montoFinalEP, 'PAGADO', @idf);

    SET @contador = @contador + 1;
END;
GO

DROP TABLE #SociosActivos;

/*


SELECT * FROM solNorte.entrada_pileta;

SELECT * FROM solNorte.entrada_pileta where monto_socio IS NULL AND monto_invitado IS NULL;

SELECT * FROM solNorte.pago;

SELECT * FROM solNorte.detalle_factura;

SELECT * FROM solNorte.factura;

*/


/*

DELETE FROM solNorte.entrada_pileta;

*/