USE Com2900G10;
GO

CREATE OR ALTER PROCEDURE datosParaTest.crearFacturasParaEntradasPileta
AS
BEGIN
	-- Tabla temporal para almacenar IDs de socios
	IF OBJECT_ID('tempdb..#SociosActivos') IS NOT NULL 
		DROP TABLE #SociosActivos;

	CREATE TABLE #SociosActivos (
		ID_socio INT, 
		ID_grupo_familiar INT, 
		fecha_nac DATETIME, 
		rowNum INT IDENTITY(1,1)
	);

	INSERT INTO #SociosActivos
	SELECT ID_socio, id_grupo_familiar, fecha_nacimiento 
	FROM solNorte.socio 
	WHERE borrado = 0 AND es_responsable = 1;

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
	DECLARE @montoFinalEP DECIMAL(10,2) = 0;

	WHILE @contador <= 1000
	BEGIN
		BEGIN TRY
			BEGIN TRANSACTION;
        
			SET @diasDiferencia = DATEDIFF(DAY, '2025-01-01', GETDATE());
			SET @fechaRandom = DATEADD(DAY, CAST(RAND() * @diasDiferencia AS INT), '2025-01-01');
        
			SELECT @idSocioRandom = ID_socio, @feNac = fecha_nac
			FROM #SociosActivos 
			WHERE rowNum = CAST(CEILING(RAND() * @TOTALSOCIOS) AS INT);


			SET @montoFinalEP = 0;
        
			IF CAST(RAND() * 2 AS INT) = 1
			BEGIN
				IF CAST(RAND() * 2 AS INT) = 1 -- Socio
				BEGIN
					SET @montoFinalEP = 25000.00;
				END
				ELSE -- Invitado
				BEGIN
					SET @montoFinalEP = 30000.00;
				END
			END

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
				@montoFinalEP, 
				DATEADD(DAY, 5, @fechaRandom),
				@idSocioRandom
			);

			DECLARE @idf INT = SCOPE_IDENTITY();

			IF @montoFinalEP > 0
			BEGIN
				IF @montoFinalEP IN (15000.00, 25000.00) -- Socio
				BEGIN
					SET @tipoEntrada = 'SOCIO';
					SET @montoSocio = @montoFinalEP;
					SET @montoInvitado = NULL;
				END
				ELSE -- Invitado
				BEGIN
					SET @tipoEntrada = 'INVITADO';
					SET @montoInvitado = @montoFinalEP;
					SET @montoSocio = NULL;
				END
            
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

				INSERT INTO solNorte.detalle_factura(
					descripcion, 
					cantidad, 
					subtotal, 
					id_factura, 
					es_entrada_pileta, 
					id_item
				) 
				VALUES (
					'Entrada pileta', 
					1, 
					@montoFinalEP, 
					@idf, 
					1, 
					@idEP
				);
			END

			-- Insertar pago
			INSERT INTO solNorte.pago (
				fecha_pago, 
				medio_de_pago, 
				monto, 
				estado, 
				id_factura
			) 
			VALUES (
				CONVERT(VARCHAR, @fechaRandom, 101), 
				'MERCADOPAGO_TRANSFERENCIA', 
				@montoFinalEP, 
				'PAGADO', 
				@idf
			);

			COMMIT TRANSACTION;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			PRINT 'Error en iteración ' + CAST(@contador AS VARCHAR) + ': ' + ERROR_MESSAGE();
		END CATCH

		SET @contador = @contador + 1;
	END;

	DROP TABLE #SociosActivos;
END;
GO

EXEC datosParaTest.crearFacturasParaEntradasPileta;


/*


SELECT * FROM solNorte.entrada_pileta;

SELECT * FROM solNorte.pago;

SELECT * FROM solNorte.detalle_factura;

SELECT * FROM solNorte.factura;

*/


/*

DELETE FROM solNorte.entrada_pileta;
DELETE FROm solNorte.pago;
DELETE FROM solNorte.detalle_factura;
DELETE FROM solNorte.factura;


*/


SELECT * FROM solNorte.inscripcion_actividad
ORDER BY id_socio, id_actividad;
GO

-- Para cada actividad del socio tomo el mes inicial, y desde ese mes inicial hasta el mes actual, genero facturas para esa actividad
-- y si se puede, hacemos descuento por g familiar, y descuento por si hace mas de una actividad


CREATE OR ALTER PROCEDURE datosParaTest.generarFacturacionMensualRandom
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @fechaInicio DATE = '2025-01-01';
    DECLARE @fechaFin DATE = GETDATE();
    DECLARE @mesActual INT = MONTH(@fechaFin);
    DECLARE @anioActual INT = YEAR(@fechaFin);
    
    -- Tabla temporal para meses a procesar
    CREATE TABLE #Meses (
        mes INT,
        anio INT,
        fecha DATE
    );
    
    -- Generar todos los meses desde enero hasta el actual
    WITH Meses AS (
        SELECT 1 AS mes, 2025 AS anio, DATEFROMPARTS(2025, 1, 1) AS fecha
        UNION ALL
        SELECT 
            CASE WHEN mes = 12 THEN 1 ELSE mes + 1 END,
            CASE WHEN mes = 12 THEN anio + 1 ELSE anio END,
            DATEADD(MONTH, 1, fecha)
        FROM Meses
        WHERE (anio < @anioActual) OR (anio = @anioActual AND mes < @mesActual)
    )
    INSERT INTO #Meses
    SELECT mes, anio, fecha FROM Meses
    OPTION (MAXRECURSION 24);
    
    -- Obtener socios responsables aleatorios
    SELECT 
        s.ID_socio,
        s.nombre,
        s.apellido,
        s.id_grupo_familiar
    INTO #SociosRandom
    FROM solNorte.socio s
    WHERE s.es_responsable = 1
    AND s.borrado = 0
    ORDER BY NEWID();
    
    -- Obtener actividades aleatorias
    SELECT 
        a.ID_actividad,
        a.nombre_actividad,
        a.costo_mensual
    INTO #ActividadesRandom
    FROM solNorte.actividad a
    WHERE a.borrado = 0
    ORDER BY NEWID();
    
    -- Para cada mes, generar facturación
    DECLARE @contador INT = 1;
    DECLARE @totalMeses INT = (SELECT COUNT(*) FROM #Meses);
    DECLARE @mes INT, @anio INT, @fechaFactura DATE;
    
    WHILE @contador <= @totalMeses
    BEGIN
        BEGIN TRY
            SELECT 
                @mes = mes,
                @anio = anio,
                @fechaFactura = fecha
            FROM (
                SELECT 
                    mes,
                    anio,
                    fecha,
                    ROW_NUMBER() OVER (ORDER BY anio, mes) AS rn
                FROM #Meses
            ) AS m
            WHERE rn = @contador;
            
            -- Seleccionar socio aleatorio para este mes
            DECLARE @idSocio INT, @nombreSocio VARCHAR(50), @apellidoSocio VARCHAR(50), @idGrupoFamiliar INT;
            
            SELECT TOP 1
                @idSocio = ID_socio,
                @nombreSocio = nombre,
                @apellidoSocio = apellido,
                @idGrupoFamiliar = id_grupo_familiar
            FROM #SociosRandom
            ORDER BY NEWID();
            
            -- Crear factura
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
                CONCAT('FAC-', @anio, '-', FORMAT(@mes, '00'), '-', @idSocio),
                'A',
                @fechaFactura,
                CONCAT('CAE', FORMAT(@fechaFactura, 'yyyyMMdd')),
                0, -- Se actualizará después
                DATEADD(DAY, 10, @fechaFactura),
                @idSocio
            );
            
            DECLARE @idFactura INT = SCOPE_IDENTITY();
            DECLARE @montoTotal DECIMAL(10,2) = 0;
            
            -- Asignar de 1 a 3 actividades aleatorias al socio
            DECLARE @numActividades INT = 1 + ABS(CHECKSUM(NEWID())) % 3; -- Entre 1 y 3 actividades
            
            -- Crear detalles de factura para cada actividad
            DECLARE @actividadCounter INT = 1;
            
            WHILE @actividadCounter <= @numActividades
            BEGIN
                DECLARE @idActividad INT, @nombreActividad VARCHAR(15), @costoMensual DECIMAL(8,2);
                
                SELECT TOP 1
                    @idActividad = ID_actividad,
                    @nombreActividad = nombre_actividad,
                    @costoMensual = costo_mensual
                FROM #ActividadesRandom
                WHERE ID_actividad NOT IN (
                    SELECT id_item 
                    FROM solNorte.detalle_factura 
                    WHERE id_factura = @idFactura AND es_actividad = 1
                )
                ORDER BY NEWID();
                
                -- Aplicar descuentos (10% por grupo familiar, 15% por múltiples actividades)
                DECLARE @subtotal DECIMAL(10,2) = @costoMensual;
                DECLARE @tieneDescuentoFamilia BIT = 0;
                DECLARE @tieneDescuentoMultiActividad BIT = 0;
                
                IF @idGrupoFamiliar IS NOT NULL AND @actividadCounter = 1
                BEGIN
                    SET @subtotal = @subtotal * 0.9; -- 10% descuento
                    SET @tieneDescuentoFamilia = 1;
                END
                
                IF @numActividades > 1 AND @actividadCounter > 1
                BEGIN
                    SET @subtotal = @subtotal * 0.85; -- 15% descuento
                    SET @tieneDescuentoMultiActividad = 1;
                END
                
                -- Crear detalle de factura
                INSERT INTO solNorte.detalle_factura (
                    descripcion,
                    cantidad,
                    subtotal,
                    id_factura,
                    es_actividad,
                    id_item
                )
                VALUES (
                    @nombreActividad,
                    1,
                    @subtotal,
                    @idFactura,
                    1,
                    @idActividad
                );
                
                DECLARE @idDetalleFactura INT = SCOPE_IDENTITY();
                
                -- Vincular actividad con detalle de factura
                INSERT INTO solNorte.detalle_factura_actividad (
                    ID_detalle_factura,
                    ID_actividad
                )
                VALUES (
                    @idDetalleFactura,
                    @idActividad
                );
                
                -- Registrar descuentos si corresponde
                IF @tieneDescuentoFamilia = 1
                BEGIN
                    INSERT INTO solNorte.descuento (
                        descripcion,
                        tipo_descuento,
                        porcentaje,
                        id_detalle_factura
                    )
                    VALUES (
                        'Descuento por grupo familiar',
                        'INSCRIPCION_FAMILIAR',
                        0.10,
                        @idDetalleFactura
                    );
                END
                
                IF @tieneDescuentoMultiActividad = 1
                BEGIN
                    INSERT INTO solNorte.descuento (
                        descripcion,
                        tipo_descuento,
                        porcentaje,
                        id_detalle_factura
                    )
                    VALUES (
                        'Descuento por múltiples actividades',
                        'DESCUENTO_POR_MAS_DE_UNA_ACTIVIDAD',
                        0.15,
                        @idDetalleFactura
                    );
                END
                
                SET @montoTotal = @montoTotal + @subtotal;
                SET @actividadCounter = @actividadCounter + 1;
            END
            
            -- Actualizar monto total de la factura
            UPDATE solNorte.factura
            SET importe_total = @montoTotal
            WHERE ID_factura = @idFactura;
            
            -- Crear pago para la factura
            INSERT INTO solNorte.pago (
                fecha_pago,
                medio_de_pago,
                monto,
                estado,
                id_factura
            )
            VALUES (
                @fechaFactura,
                CASE (ABS(CHECKSUM(NEWID())) % 5)
                    WHEN 0 THEN 'MASTERCARD'
                    WHEN 1 THEN 'VISA'
                    WHEN 2 THEN 'TARJETA_NARANJA'
                    WHEN 3 THEN 'MERCADOPAGO_TRANSFERENCIA'
                    ELSE 'PAGOFACIL'
                END,
                @montoTotal,
                'PAGADO',
                @idFactura
            );
            
            PRINT CONCAT('Factura generada para ', @nombreSocio, ' ', @apellidoSocio, 
                         ' - Mes: ', @mes, '/', @anio, 
                         ' - Actividades: ', @numActividades, 
                         ' - Total: $', @montoTotal);
            
            SET @contador = @contador + 1;
        END TRY
        BEGIN CATCH
            PRINT CONCAT('Error procesando mes ', @mes, '/', @anio, ': ', ERROR_MESSAGE());
        END CATCH
    END
    
    -- Limpiar tablas temporales
    DROP TABLE #Meses;
    DROP TABLE #SociosRandom;
    DROP TABLE #ActividadesRandom;
    
    PRINT 'Generación de facturación mensual completada.';
END;
GO

-- Ejecutar la generación de datos
EXEC datosParaTest.generarFacturacionMensualRandom;