-- Este script se encarga de generar los objetos necesarios para la persistencia de datos (bd, schemas y tablas)
-- El script está diseñado para que pueda ejecutarse de una, por lotes, con el comando GO, verificando que ninguno de los objetos exista previamente.
IF NOT EXISTS (
    SELECT name 
    FROM sys.databases 
    WHERE name = 'Com2900G10'
)
BEGIN
    CREATE DATABASE Com2900G10;
END

GO


USE Com2900G10;
GO

--Este esquema es para todos los elementos involucrados directamente en los procesos del sistema
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'dominio'
)
BEGIN
    EXEC('CREATE SCHEMA dominio');
END

GO

-- Este esquema es para generar juegos de datos random, nombres, apellidos, fechas, lo que se neceste para generar datos y así realizar pruebas
IF NOT EXISTS (
    SELECT * FROM sys.schemas WHERE name = 'datosRandom'
)
BEGIN
    EXEC('CREATE SCHEMA datosRandom');
END

GO

--=====================================================CREACIONES DE TABLAS=====================================================--

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'usuario' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.usuario (
        ID_usuario INT IDENTITY(1,1) PRIMARY KEY ,
        nombre_usuario VARCHAR(20) NOT NULL,
        contraseña VARCHAR(20) NOT NULL,
        fecha_modificacion_contraseña DATETIME,
        fecha_expiracion_contraseña DATETIME,
        estado_usuario CHAR(15) DEFAULT 'activo',
        CHECK (
            LEN(contraseña) >= 8 AND
            contraseña LIKE '%[0-9]%' AND        -- al menos un número
            contraseña LIKE '%[a-zA-Z]%' AND     -- al menos una letra
            (
			-- para caracteres especiales
                contraseña LIKE '%!%' OR
                contraseña LIKE '%@%' OR
                contraseña LIKE '%#%' OR
                contraseña LIKE '%$%' OR
                contraseña LIKE '%^%' OR
                contraseña LIKE '%&%' OR
                contraseña LIKE '%*%' OR
                contraseña LIKE '%(%' OR
                contraseña LIKE '%)%'
            )
        )
    );
END


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'rol' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.rol (
		ID_rol INT IDENTITY(1,1) PRIMARY KEY,
		nombre_rol CHAR(15),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'rol_usuario' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.rol_usuario (
        ID_usuario INT,
        ID_rol INT,
        PRIMARY KEY (ID_usuario, ID_rol),
        FOREIGN KEY (ID_usuario) REFERENCES dominio.usuario(ID_usuario),
        FOREIGN KEY (ID_rol) REFERENCES dominio.rol(ID_rol)
    );
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'grupo_familiar' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.grupo_familiar (
        ID_grupo_familiar INT IDENTITY(1,1) PRIMARY KEY,
        cantidad_integrantes INT
    );
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'socio' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.socio (
		ID_socio INT IDENTITY(1,1) PRIMARY KEY,
		nombre VARCHAR(20),
		apellido VARCHAR(20),
		fecha_nacimiento DATE, 
		DNI CHAR(8) CHECK( CAST(DNI AS INT) > 0 AND CAST(DNI AS INT) <= 99999999 ),
		telefono CHAR(10),
		telefono_de_emergencia VARCHAR(23),
		obra_social VARCHAR(30),
		nro_obra_social VARCHAR(30),
		categoria_socio CHAR(10),
		es_responsable BIT, -- true si puede tener a cargo menores y es repsonsable de un grupo fliar
		email VARCHAR(30),
		id_grupo_familiar INT,
		id_responsable_a_cargo INT, -- FK autoreferenciada
		CONSTRAINT FK_Socio_Responsable FOREIGN KEY (id_responsable_a_cargo)
			REFERENCES dominio.socio(ID_socio),
		CONSTRAINT FK_id_grupo_familiar FOREIGN KEY (id_grupo_familiar) REFERENCES dominio.grupo_familiar(ID_grupo_familiar)
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'actividad' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.actividad (
        ID_actividad INT IDENTITY(1,1) PRIMARY KEY,
        nombre_actividad CHAR(15),
		costo_mensual DECIMAL(8,2),
		edad_minima INT,
		edad_maxima INT,
		CONSTRAINT CK_edades_validas CHECK (edad_minima <= edad_maxima)
    );
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'horario_de_actividad' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.horario_de_actividad (
        ID_horario INT IDENTITY(1,1) PRIMARY KEY,
        dia CHAR(10),
		hora_inicio TIME,
		hora_fin TIME,
		id_actividad INT,
		FOREIGN KEY (id_actividad) REFERENCES dominio.actividad(ID_actividad),
		CONSTRAINT CK_horarios_validos CHECK (hora_inicio <= hora_fin)
    );
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'factura' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.factura (
        ID_factura INT IDENTITY(1,1) PRIMARY KEY,
        nro_factura VARCHAR(20), 
		tipo_factura CHAR(20),
		fecha_emision DATETIME,
		CAE CHAR(14), 
		estado CHAR(9), --estado de mayor longitud PENDIENTE -> 9 caracteres, el otro es Pagada
		importe_total DECIMAL(8,2),
		razon_social_emisor CHAR(20),
		CUIT_emisor INT, 
		vencimiento_CAE DATETIME,
		id_socio INT
		FOREIGN KEY (id_socio) REFERENCES dominio.socio(ID_socio) 
    );
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'inscripcion_actividad' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.inscripcion_actividad (
		ID_inscripcion INT IDENTITY(1,1) PRIMARY KEY,
		fecha_inscripcion DATE,
		id_actividad INT NOT NULL,
		id_socio INT NOT NULL,
		CONSTRAINT FK_id_socio_inscripcion FOREIGN KEY (id_socio) REFERENCES dominio.socio(ID_socio),
		CONSTRAINT FK_id_actividad_inscripcion FOREIGN KEY (id_actividad) REFERENCES dominio.actividad(ID_actividad),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'asistencia' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.asistencia (
		ID_asistencia INT IDENTITY(1,1) PRIMARY KEY,
		fecha DATE,
		asistio BIT NOT NULL,
		id_inscripcion_actividad INT NOT NULL,
		CONSTRAINT FK_id_inscripcion_actividad FOREIGN KEY (id_inscripcion_actividad) 
			REFERENCES dominio.actividad(ID_actividad),
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'cuota_membresia' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.cuota_membresia (
		ID_cuota INT IDENTITY(1,1) PRIMARY KEY,
		mes TINYINT NOT NULL CHECK (mes > 0 AND mes <= 12),
		anio INT NOT NULL,
		monto DECIMAL(8,2) NOT NULL,
		nombre_membresia CHAR(9) NOT NULL, -- Individual es el nombre de mayor longitud de los posibles nombres
		edad_minima INT,
		edad_maxima INT,
		id_socio INT NOT NULL,
		CONSTRAINT FK_id_socio_cuota_membresia FOREIGN KEY (id_socio) 
			REFERENCES dominio.socio(ID_socio),
		CONSTRAINT CK_edades_validas_membresia CHECK (edad_minima <= edad_maxima)
	);
END
GO





IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'entrada_pileta' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.entrada_pileta(
		ID_entrada INT IDENTITY(1,1) PRIMARY KEY,
		fecha_entrada DATETIME NOT NULL,
		monto_socio DECIMAL(10,2),
		monto_invitado DECIMAL(8,2),
		tipo_entrada_pileta CHAR(8), -- Toma como valores socio o invitado 
		fue_reembolsada BIT DEFAULT 0,
		id_socio INT NOT NULL,
		CONSTRAINT FK_id_socio FOREIGN KEY (id_socio) 
			REFERENCES dominio.socio(ID_socio),
	);
END
GO



IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'reserva_sum' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.reserva_sum(
		ID_reserva INT IDENTITY(1,1) PRIMARY KEY,
		fecha_reserva DATETIME NOT NULL,
		hora_desde TIME NOT NULL,
		hora_hasta TIME NOT NULL,
		valor_hora DECIMAL(8,2),
		id_socio INT NOT NULL,
		CONSTRAINT FK_id_socio_reserva FOREIGN KEY (id_socio) 
			REFERENCES dominio.socio(ID_socio),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'detalle_factura' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.detalle_factura(
		ID_detalle_factura INT IDENTITY(1,1) PRIMARY KEY,
		descripcion VARCHAR (70),
		cantidad INT DEFAULT 1,
		subtotal DECIMAL (10,2),
		id_factura INT NOT NULL
		CONSTRAINT FK_id_factura FOREIGN KEY (id_factura) 
			REFERENCES dominio.factura(ID_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'descuento' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.descuento(
		ID_descuento INT IDENTITY(1,1) PRIMARY KEY,
		descripcion VARCHAR (70),
		tipo_descuento CHAR(30),
		porcentaje DECIMAL (3,2), -- 0,06 0,90 0,50 y así tomaran los valores
		id_detalle_factura INT NOT NULL
		CONSTRAINT FK_id_detalle_factura FOREIGN KEY (id_detalle_factura) 
			REFERENCES dominio.detalle_factura(ID_detalle_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'pago' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.pago(
		ID_pago INT IDENTITY(1,1) PRIMARY KEY,
		fecha_pago DATETIME,
		medio_de_pago CHAR(30),
		monto DECIMAL (8,2), 
		estado CHAR (10), --'Pagado' 'No Pagado'
		id_factura INT NOT NULL
		CONSTRAINT FK_id_factura_pago FOREIGN KEY (id_factura) 
			REFERENCES dominio.factura(ID_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'reembolso' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.reembolso (
		ID_reembolso INT IDENTITY(1,1) PRIMARY KEY,
		fecha_reembolso DATETIME,
		motivo_reembolso CHAR(30),
		monto DECIMAL (8,2), 
		id_factura INT NOT NULL
		CONSTRAINT FK_id_factura_reembolso FOREIGN KEY (id_factura) 
			REFERENCES dominio.factura(ID_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'deuda' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
	CREATE TABLE dominio.deuda(
		ID_deuda INT IDENTITY(1,1) PRIMARY KEY,
		recargo_por_vencimiento DECIMAL (3,2),
		deuda_acumulada DECIMAL (10,2),
		fecha_readmision DATE,
		id_factura INT NOT NULL,
		id_socio INT NOT NULL,
		CONSTRAINT FK_id_factura_deuda FOREIGN KEY (id_factura) 
			REFERENCES dominio.factura(ID_factura),
		CONSTRAINT FK_id_socio_deuda FOREIGN KEY (id_socio)
			REFERENCES dominio.socio(ID_socio)
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'detalle_factura_actividad' AND TABLE_SCHEMA = 'dominio'
)
BEGIN
    CREATE TABLE dominio.detalle_factura_actividad (
        ID_detalle_factura INT,
        ID_actividad INT,
        PRIMARY KEY (ID_detalle_factura, ID_actividad),
        FOREIGN KEY (ID_detalle_factura) REFERENCES dominio.detalle_factura(ID_detalle_factura),
        FOREIGN KEY (ID_actividad) REFERENCES dominio.actividad(ID_actividad)
    );
END
GO

--=====================================================CUOTA MEMBRESIA=====================================================--
---------------SP DE CUOTA_MEMBRESIA, FACTURA, DETALLE_FACURA Y PAGO------------------------------------------------
ALTER TABLE dominio.cuota_membresia
ADD activo NOT NULL BIT DEFAULT 1; -- 1 = activo, 0 = borrado logico
GO

CREATE OR ALTER PROCEDURE insertar_cuota_membresia
    @mes TINYINT,
    @anio INT,
    @monto DECIMAL(8,2),
    @nombre_membresia CHAR(9),
    @edad_minima INT,
    @edad_maxima INT,
    @id_socio INT
AS
BEGIN
	SET NOCOUNT ON
    -- Validaciones
    IF @mes < 1 OR @mes > 12
        BEGIN RAISERROR('Mes invalido.', 16, 1); RETURN; END

    IF @anio < 1900 OR @anio > YEAR(GETDATE()) + 1
        BEGIN RAISERROR('Año invalido.', 16, 1); RETURN; END

    IF @monto <= 0
        BEGIN RAISERROR('Monto invalido.', 16, 1); RETURN; END

    IF LEN(RTRIM(@nombre_membresia)) = 0
        BEGIN RAISERROR('Agregar nombre de membresia.', 16, 1); RETURN; END

    IF @edad_minima IS NOT NULL AND @edad_maxima IS NOT NULL AND @edad_minima > @edad_maxima
        BEGIN RAISERROR('Edad invalida.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM dominio.socio WHERE ID_socio = @id_socio)
        BEGIN RAISERROR('El socio no existe.', 16, 1); RETURN; END

    -- Insercion
    INSERT INTO dominio.cuota_membresia (
        mes, anio, monto, nombre_membresia, edad_minima, edad_maxima, id_socio
    ) VALUES (
        @mes, @anio, @monto, @nombre_membresia, @edad_minima, @edad_maxima, @id_socio
    );
END;
GO

CREATE OR ALTER PROCEDURE eliminar_cuota_membresia -- eliminado logico
    @ID_cuota INT
AS
BEGIN
	SET NOCOUNT ON
    IF NOT EXISTS (SELECT 1 FROM dominio.cuota_membresia WHERE ID_cuota = @ID_cuota AND activo = 1)
        BEGIN RAISERROR('La cuota no existe o ya fue eliminada.', 16, 1); RETURN; END

    UPDATE dominio.cuota_membresia
    SET activo = 0
    WHERE ID_cuota = @ID_cuota;
END;
GO

CREATE OR ALTER PROCEDURE modificar_cuota_membresia
    @ID_cuota INT,
    @mes TINYINT,
    @anio INT,
    @monto DECIMAL(8,2),
    @nombre_membresia CHAR(9),
    @edad_minima INT,
    @edad_maxima INT
AS
BEGIN
	SET NOCOUNT ON
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dominio.cuota_membresia WHERE ID_cuota = @ID_cuota AND activo = 1)
        BEGIN RAISERROR('La cuota no existe o fue eliminada.', 16, 1); RETURN; END

    IF @mes < 1 OR @mes > 12
        BEGIN RAISERROR('Mes invalido.', 16, 1); RETURN; END

    IF @anio < 1900 OR @anio > YEAR(GETDATE()) + 1
        BEGIN RAISERROR('Año invalido.', 16, 1); RETURN; END

    IF @monto <= 0
        BEGIN RAISERROR('El monto debe ser mayor a cero.', 16, 1); RETURN; END

    IF LEN(RTRIM(@nombre_membresia)) = 0
        BEGIN RAISERROR('Agregar nombre de membresia.', 16, 1); RETURN; END

    IF @edad_minima IS NOT NULL AND @edad_maxima IS NOT NULL AND @edad_minima > @edad_maxima
        BEGIN RAISERROR('Edad invalida.', 16, 1); RETURN; END

    UPDATE dominio.cuota_membresia
    SET mes = @mes,
        anio = @anio,
        monto = @monto,
        nombre_membresia = @nombre_membresia,
        edad_minima = @edad_minima,
        edad_maxima = @edad_maxima
    WHERE ID_cuota = @ID_cuota;
END;
GO

--=====================================================FACTURA=====================================================--
CREATE OR ALTER PROCEDURE insertar_factura
    @nro_factura VARCHAR(20),
    @tipo_factura CHAR(20),
    @fecha_emision DATETIME,
    @CAE CHAR(14),
    @estado CHAR(9),
    @importe_total DECIMAL(8,2),
    @razon_social_emisor CHAR(20),
    @CUIT_emisor INT,
    @vencimiento_CAE DATETIME,
    @id_socio INT
AS
BEGIN
	SET NOCOUNT ON
     -- Validaciones
    IF @nro_factura IS NULL OR LEN(@nro_factura) = 0
        BEGIN RAISERROR('El numero de factura es obligatorio.', 16, 1); RETURN; END

    IF LEN(@tipo_factura) = 0 OR LEN(@tipo_factura) > 20
        BEGIN RAISERROR('Tipo de factura invalida.', 16, 1); RETURN; END

	IF @fecha_emision IS NULL OR @vencimiento_CAE IS NULL OR @vencimiento_CAE < @fecha_emision	
	BEGIN RAISERROR('Fecha invalida.', 16, 1); RETURN; END

    IF LEN(@CAE) != 14
        BEGIN RAISERROR('El CAE debe tener 14 caracteres.', 16, 1); RETURN; END

    IF @estado NOT IN ('Pendiente', 'Pagada')
        BEGIN RAISERROR('Estado debe ser "Pendiente" o "Pagada".', 16, 1); RETURN; END

    IF @importe_total <= 0
        BEGIN RAISERROR('El importe total invalido.', 16, 1); RETURN; END

	IF @razon_social_emisor IS NULL OR LEN(RTRIM(@razon_social_emisor)) = 0
        BEGIN RAISERROR('Agregar razón social.', 16, 1); RETURN; END

    IF LEN(CAST(@CUIT_emisor AS VARCHAR)) != 11
        BEGIN RAISERROR('CUIT invalido.', 16, 1); RETURN; END

    IF @vencimiento_CAE < @fecha_emision
        BEGIN RAISERROR('La fecha de vencimiento CAE invalida.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM dominio.socio WHERE ID_socio = @id_socio)
        BEGIN RAISERROR('El socio no existe.', 16, 1); RETURN; END

    -- Insercion
    INSERT INTO dominio.factura (
        nro_factura, tipo_factura, fecha_emision, CAE, estado,
        importe_total, razon_social_emisor, CUIT_emisor, vencimiento_CAE, id_socio
    )
    VALUES (
        @nro_factura, @tipo_factura, @fecha_emision, @CAE, @estado,
        @importe_total, @razon_social_emisor, @CUIT_emisor, @vencimiento_CAE, @id_socio
    );

END;
GO

-- Al ser un documento legal, la factura no se puede modificar ni borrar
--=====================================================DETALLE FACTURA=====================================================--
ALTER TABLE dominio.detalle_factura
ADD activo BIT NOT NULL DEFAULT 1;
GO

CREATE OR ALTER PROCEDURE insertar_detalle_factura
	@descripcion VARCHAR (70),
	@cantidad INT,
	@subtotal DECIMAL (10,2),
	@id_factura INT 
AS
BEGIN 
	SET NOCOUNT ON
	-- Validaciones
	IF LEN(RTRIM(@descripcion)) = 0
        BEGIN RAISERROR('Agregar descripcion.', 16, 1); RETURN; END

    IF @cantidad IS NULL OR @cantidad <= 0
        BEGIN RAISERROR('Cantidad invalida.', 16, 1); RETURN; END

    IF @subtotal IS NULL OR @subtotal < 0
        BEGIN RAISERROR('Subtotal invalido.', 16, 1); RETURN; END

    IF NOT EXISTS (SELECT 1 FROM dominio.factura WHERE ID_factura = @id_factura)
        BEGIN RAISERROR('La factura no existe.', 16, 1); RETURN; END

    -- Insercion
    INSERT INTO dominio.detalle_factura (
        descripcion, cantidad, subtotal, id_factura
    ) VALUES (
        @descripcion, @cantidad, @subtotal, @id_factura
    );
END;
GO

CREATE OR ALTER PROCEDURE modificar_detalle_factura
    @ID_detalle_factura INT,
    @descripcion VARCHAR(70),
    @cantidad INT,
    @subtotal DECIMAL(10,2)
AS
BEGIN
	SET NOCOUNT ON
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dominio.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura)
        BEGIN RAISERROR('El detalle de factura no existe.', 16, 1); RETURN; END

    IF LEN(RTRIM(@descripcion)) = 0
        BEGIN RAISERROR('Agregar descipcion.', 16, 1); RETURN; END

    IF @cantidad IS NULL OR @cantidad <= 0
        BEGIN RAISERROR('Cantidad invalida.', 16, 1); RETURN; END

    IF @subtotal IS NULL OR @subtotal < 0
        BEGIN RAISERROR('Subtotal invalido.', 16, 1); RETURN; END

    UPDATE dominio.detalle_factura
    SET descripcion = @descripcion,
        cantidad = @cantidad,
        subtotal = @subtotal
    WHERE ID_detalle_factura = @ID_detalle_factura;
END;
GO

CREATE PROCEDURE eliminar_detalle_factura -- eliminado logico
    @ID_detalle_factura INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura AND activo = 1)
    BEGIN
        RAISERROR('El detalle de factura no existe o ya esta eliminado.', 16, 1);
        RETURN;
    END

    UPDATE dominio.detalle_factura
    SET activo = 0
    WHERE ID_detalle_factura = @ID_detalle_factura;
END;
GO

ALTER TABLE dominio.pago
ADD activo BIT NOT NULL DEFAULT 1;
GO

--=====================================================PAGO=====================================================--
CREATE OR ALTER PROCEDURE insertar_pago
    @fecha_pago DATETIME,
    @medio_de_pago CHAR(30),
    @monto DECIMAL(8,2),
    @estado CHAR(10),
    @id_factura INT
AS
BEGIN
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM dominio.factura WHERE ID_factura = @id_factura)
    BEGIN
        RAISERROR('La factura no existe.', 16, 1);
        RETURN;
    END

    IF @monto <= 0
    BEGIN
        RAISERROR('Monto invalido.', 16, 1);
        RETURN;
    END

	IF RTRIM(@estado) NOT IN ('Pagado', 'No pagado')
    BEGIN
        RAISERROR('Estado invalido".', 16, 1);
        RETURN;
    END

    IF LEN(RTRIM(@medio_de_pago)) = 0
    BEGIN
        RAISERROR('Medio de pago invalido.', 16, 1);
        RETURN;
    END

    INSERT INTO dominio.pago (fecha_pago, medio_de_pago, monto, estado, id_factura) 
		VALUES (@fecha_pago, @medio_de_pago, @monto, @estado, @id_factura);
END;
GO

CREATE OR ALTER PROCEDURE modificar_pago
    @ID_pago INT,
    @fecha_pago DATETIME,
    @medio_de_pago CHAR(30),
    @monto DECIMAL(8,2),
    @estado CHAR(10)
AS
BEGIN
	SET NOCOUNT ON
    IF NOT EXISTS (SELECT 1 FROM dominio.pago WHERE ID_pago = @ID_pago AND activo = 1)
    BEGIN
        RAISERROR('El pago no existe o está eliminado.', 16, 1);
        RETURN;
    END

	IF EXISTS (SELECT 1 FROM dominio.pago
        WHERE ID_pago = @ID_pago AND estado = 'Pagado')
    BEGIN
        RAISERROR('No se puede modificar un pago con estado "Pagado".', 16, 1);
        RETURN;
	END
    
    IF @monto <= 0
    BEGIN
        RAISERROR('El monto debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    IF LEN(RTRIM(@medio_de_pago)) = 0
    BEGIN
        RAISERROR('Medio de pago invalido.', 16, 1);
        RETURN;
    END

    UPDATE dominio.pago
    SET fecha_pago = @fecha_pago,
        medio_de_pago = @medio_de_pago,
        monto = @monto,
        estado = @estado
    WHERE ID_pago = @ID_pago;
END;
GO

CREATE OR ALTER PROCEDURE eliminar_pago
    @ID_pago INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.pago WHERE ID_pago = @ID_pago AND activo = 1)
    BEGIN
        RAISERROR('El pago no existe o ya está eliminado.', 16, 1);
        RETURN;
    END
	IF EXISTS (SELECT 1 FROM dominio.pago
        WHERE ID_pago = @ID_pago AND estado = 'Pagado')
    BEGIN
        RAISERROR('No se puede eliminar un pago con estado "Pagado".', 16, 1);
        RETURN;
    END
    UPDATE dominio.pago
    SET activo = 0
    WHERE ID_pago = @ID_pago;
END;
GO