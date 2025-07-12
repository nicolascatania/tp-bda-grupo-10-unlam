/*
====================================================================================
 Archivo		: 09_generacionLotesPrueba.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Script para generacion de registros para poblar las tablas utilizadas por los reportes del siguiente script.
 Autor			: G10
 Fecha entrega	: 2025-07-11
====================================================================================
*/

USE Com2900G10;
GO

CREATE OR ALTER PROCEDURE datosParaTest.crearFacturasParaEntradasPileta
AS
BEGIN

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
GO

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
				1209381290, --cae random, no afecta la lógica de nuestro sistema debido al alcance del mismo,
				'PAGADA',
                0.01, -- Se actualizará después, ponemos este valor simbólico ya que establecimos un check para que la factura no pueda tener importe <= 0 
                DATEADD(DAY, 10, @fechaFactura),
                @idSocio
            );
            
            DECLARE @idFactura INT = SCOPE_IDENTITY();
            DECLARE @montoTotal DECIMAL(10,2) = 0;
            
            DECLARE @numActividades INT = 1 + ABS(CHECKSUM(NEWID())) % 3; -- Entre 1 y 3 actividades
            
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
            
        END TRY
        BEGIN CATCH
            PRINT CONCAT('Error procesando mes ', @mes, '/', @anio, ': ', ERROR_MESSAGE());
        END CATCH

		
		SET @contador = @contador + 1;
    END
    

    DROP TABLE #Meses;
    DROP TABLE #SociosRandom;
    DROP TABLE #ActividadesRandom;
    
    PRINT 'Generación de facturación mensual completada.';
END;
GO


EXEC datosParaTest.generarFacturacionMensualRandom;
GO



--======================== generamos facturas mensuales asociadas a socio, algunas vencidas para poder generar el reporte 1 ========================--
CREATE OR ALTER PROCEDURE solNorte.InsertarSociosYFacturasMensuales
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaxIDActual INT;
    SELECT @MaxIDActual = ISNULL(MAX(ID_socio), 0) FROM solNorte.socio;

    SET IDENTITY_INSERT solNorte.socio ON;

    DECLARE @ID_base INT = CASE WHEN @MaxIDActual < 4120 THEN 4120 ELSE @MaxIDActual + 1 END;
    DECLARE @anio INT = 2024;
    DECLARE @mes_base INT = 1;
    DECLARE @nombres TABLE(nombre VARCHAR(50), apellido VARCHAR(50));

    INSERT INTO @nombres(nombre, apellido)
    VALUES 
    ('Juan', 'Pérez'), ('María', 'Gómez'), ('Lucas', 'Rodríguez'), ('Ana', 'Martínez'),
    ('Sofía', 'López'), ('Pedro', 'García'), ('Lucía', 'Fernández'), ('Mateo', 'Ruiz'),
    ('Valentina', 'Morales'), ('Diego', 'Romero'), ('Camila', 'Sánchez'), ('Tomás', 'Ortega'),
    ('Martina', 'Torres'), ('Franco', 'Silva'), ('Renata', 'Flores'), ('Bruno', 'Castro'),
    ('Carla', 'Méndez'), ('Nicolás', 'Herrera'), ('Isabel', 'Vega'), ('Julián', 'Ibáñez'),
    ('Cecilia', 'Aguirre'), ('Felipe', 'Luna'), ('Sol', 'Domínguez'), ('Kevin', 'Mansilla'),
    ('Florencia', 'Acosta');

    DECLARE @i INT = 1;
    WHILE @i <= 25
    BEGIN
        DECLARE @nombre VARCHAR(50), @apellido VARCHAR(50);
        SELECT @nombre = nombre, @apellido = apellido FROM (
            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS rn, * FROM @nombres
        ) AS nombres_indexed WHERE rn = @i;

        DECLARE @id_socio INT = @ID_base + @i - 1;

        INSERT INTO solNorte.socio (
            ID_socio, nombre, apellido, fecha_nacimiento, DNI, telefono,
            telefono_de_emergencia, obra_social, nro_obra_social,
            categoria_socio, es_responsable, email
        )
        VALUES (
            @id_socio, @nombre, @apellido, DATEFROMPARTS(1990 + (@i % 10), 1, 15),
            40000000 + @i, '11234567' + RIGHT('00' + CAST(@i AS VARCHAR), 2),
            NULL, NULL, NULL, 'MAYOR', 1, LOWER(@nombre + '.' + @apellido + '@mail.com')
        );

        -- Los primeros 10 socios van a tener facturas vencidas (algunos más que otros)
        IF @i <= 10
        BEGIN
            DECLARE @cant_facturas INT = 2 + (@i % 6); -- 2 a 7 facturas vencidas

            DECLARE @j INT = 0;
            WHILE @j < @cant_facturas
            BEGIN
                DECLARE @mes_actual INT = ((@mes_base + @j - 1) % 12) + 1;
                DECLARE @fecha DATETIME = DATEFROMPARTS(@anio, @mes_actual, 10);
                DECLARE @nro_factura VARCHAR(30) = 'FAC-' + CAST(@anio AS VARCHAR) + '-' 
                                                    + RIGHT('0' + CAST(@mes_actual AS VARCHAR), 2) + '-' 
                                                    + CAST(@id_socio AS VARCHAR) + '-' + CAST(@j + 1 AS VARCHAR);

                INSERT INTO solNorte.factura (
                    nro_factura, tipo_factura, fecha_emision, CAE,
                    estado, importe_total, vencimiento_CAE, id_socio
                )
                VALUES (
                    @nro_factura, 'A', @fecha, '12345678901234',
                    'VENCIDA', 1000.00, DATEADD(DAY, 30, @fecha), @id_socio
                );

                SET @j += 1;
            END
        END
        ELSE
        BEGIN
            -- Resto con una sola factura PAGADA
            DECLARE @fecha1 DATETIME = DATEFROMPARTS(@anio, 5, 10);
            DECLARE @nro_factura1 VARCHAR(30) = 'FAC-' + CAST(@anio AS VARCHAR) + '-05-' + CAST(@id_socio AS VARCHAR);

            INSERT INTO solNorte.factura (
                nro_factura, tipo_factura, fecha_emision, CAE,
                estado, importe_total, vencimiento_CAE, id_socio
            )
            VALUES (
                @nro_factura1, 'B', @fecha1, '12345678900000',
                'PAGADA', 1000.00, DATEADD(DAY, 30, @fecha1), @id_socio
            );
        END

        SET @i += 1;
    END

    SET IDENTITY_INSERT solNorte.socio OFF;

    DECLARE @NuevoMaxID INT;
    SELECT @NuevoMaxID = MAX(ID_socio) FROM solNorte.socio;
    
    DBCC CHECKIDENT ('solNorte.socio', RESEED, @NuevoMaxID);

    PRINT 'RESEED realizado. Nuevo valor de IDENTITY: ' + CAST(@NuevoMaxID AS VARCHAR);
END;

GO

EXEC solNorte.InsertarSociosYFacturasMensuales;
GO

--======================== asociamos facturas mensuales al detalle que representa una cuota ========================--

CREATE OR ALTER PROCEDURE solNorte.InsertarDetallesYCuotas
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        IF OBJECT_ID('tempdb..#datos_procesados') IS NOT NULL DROP TABLE #datos_procesados;
        IF OBJECT_ID('tempdb..#cuotas_generadas') IS NOT NULL DROP TABLE #cuotas_generadas;

        CREATE TABLE #datos_procesados (
            ID_factura INT,
            id_socio INT,
            mes TINYINT,
            anio INT,
            importe_total DECIMAL(10,2),
            nombre_membresia CHAR(9),
            edad_minima INT,
            edad_maxima INT
        );

        CREATE TABLE #cuotas_generadas (
            ID_cuota INT,
            ID_factura INT
        );

        INSERT INTO #datos_procesados (ID_factura, id_socio, mes, anio, importe_total, nombre_membresia, edad_minima, edad_maxima)
        SELECT
            f.ID_factura,
            f.id_socio,
            MONTH(f.fecha_emision),
            YEAR(f.fecha_emision),
            f.importe_total,
            CASE
                WHEN DATEDIFF(YEAR, s.fecha_nacimiento, f.fecha_emision) < 13 THEN 'MENOR'
                WHEN DATEDIFF(YEAR, s.fecha_nacimiento, f.fecha_emision) BETWEEN 13 AND 17 THEN 'CADETE'
                ELSE 'MAYOR'
            END,
            CASE
                WHEN DATEDIFF(YEAR, s.fecha_nacimiento, f.fecha_emision) < 13 THEN 0
                WHEN DATEDIFF(YEAR, s.fecha_nacimiento, f.fecha_emision) BETWEEN 13 AND 17 THEN 13
                ELSE 18
            END,
            CASE
                WHEN DATEDIFF(YEAR, s.fecha_nacimiento, f.fecha_emision) < 13 THEN 12
                WHEN DATEDIFF(YEAR, s.fecha_nacimiento, f.fecha_emision) BETWEEN 13 AND 17 THEN 17
                ELSE 99
            END
        FROM solNorte.factura f
        INNER JOIN solNorte.socio s ON f.id_socio = s.ID_socio
        WHERE f.anulada = 0 AND s.borrado = 0;

		DECLARE @tmp TABLE (
			ID_cuota INT,
			mes INT,
			anio INT,
			id_socio INT
		);

        -- Agregamos las cuotas membresía, me quedo con ID generado + ID_factura original
       INSERT INTO solNorte.cuota_membresia (
			mes, anio, monto, nombre_membresia, edad_minima, edad_maxima, id_socio
		)
		OUTPUT INSERTED.ID_cuota, INSERTED.mes, INSERTED.anio, INSERTED.id_socio INTO @tmp
		SELECT
			dp.mes, dp.anio, dp.importe_total,
			dp.nombre_membresia, dp.edad_minima, dp.edad_maxima, dp.id_socio
		FROM #datos_procesados dp;

		-- Joins para cruzar los datos procesados en la temporal, obteniendo el id de la factura y la cuota, y asi terminar de generar la cuota memebresia
		INSERT INTO #cuotas_generadas(ID_cuota, ID_factura)
		SELECT
			t.ID_cuota,
			dp.ID_factura
		FROM @tmp t
		INNER JOIN #datos_procesados dp
			ON t.mes = dp.mes
			AND t.anio = dp.anio
			AND t.id_socio = dp.id_socio;

		-- Asocio los detalles a las cuotas membresias pra que figuren como los items
		INSERT INTO solNorte.detalle_factura (
			descripcion, cantidad, subtotal, id_factura,
			es_cuota, es_reserva_sum, es_entrada_pileta, es_actividad,
			id_item
		)
		SELECT
			'Cuota de membresía mes ' + FORMAT(f.fecha_emision, 'MMMM yyyy'),
			1,
			f.importe_total,
			f.ID_factura,
			1, 0, 0, 0,
			c.ID_cuota
		FROM #cuotas_generadas c
		INNER JOIN solNorte.factura f ON f.ID_factura = c.ID_factura;

		PRINT 'Cuotas y detalles generados correctamente.';
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error en InsertarDetallesYCuotas: %s', 16, 1, @msg);
    END CATCH
END;
GO


EXEC solNorte.InsertarDetallesYCuotas;
GO