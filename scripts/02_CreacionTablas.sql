
USE Com2900G10;
GO

--=====================================================CREACIONES DE TABLAS=====================================================--

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'grupo_familiar' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
    CREATE TABLE solNorte.grupo_familiar (
        ID_grupo_familiar INT IDENTITY(1,1) PRIMARY KEY,
        cantidad_integrantes INT,
		borrado BIT NOT NULL DEFAULT 0, --0 -> false no borrado, 1-> true borrado
		fecha_borrado DATETIME
    );
END
GO



IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'socio' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.socio (
		ID_socio INT IDENTITY(1,1) PRIMARY KEY,
		nombre VARCHAR(50) NOT NULL,
		apellido VARCHAR(50) NOT NULL,
		fecha_nacimiento DATE NOT NULL, 
		DNI INT NOT NULL CHECK(DNI > 0 AND DNI <= 99999999),
		telefono CHAR(10),
		telefono_de_emergencia VARCHAR(23),
		obra_social VARCHAR(50),
		nro_obra_social VARCHAR(30),
		categoria_socio CHAR(10),
		es_responsable BIT, -- true si puede tener a cargo menores y es repsonsable de un grupo fliar
		email VARCHAR(100),
		id_grupo_familiar INT,
		id_responsable_a_cargo INT, -- FK autoreferenciada
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		DNI_responsable INT CHECK(DNI_responsable > 0 AND DNI_responsable <= 99999999),
		mail_responsable VARCHAR(100),
		nombre_responsable VARCHAR(50),
		apellido_responsable VARCHAR(50),
		fecha_nacimiento_responsable DATE,
		telefono_responsable CHAR(10),
		parentezco_con_responsable CHAR(15),
		CONSTRAINT FK_Socio_Responsable FOREIGN KEY (id_responsable_a_cargo)
			REFERENCES solNorte.socio(ID_socio),
		CONSTRAINT FK_id_grupo_familiar FOREIGN KEY (id_grupo_familiar) REFERENCES solNorte.grupo_familiar(ID_grupo_familiar)
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'actividad' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
    CREATE TABLE solNorte.actividad (
        ID_actividad INT IDENTITY(1,1) PRIMARY KEY,
        nombre_actividad CHAR(15) NOT NULL CHECK(nombre_actividad IN ('FUTSAL', 'VOLEY', 'TAEKWONDO', 'BAILE ARTISTICO', 'NATACION', 'AJEDREZ')), --al momento de hacer una importacion, pasar todo a uppercase, ignorar tildes y cortar espacios en blanco
		costo_mensual DECIMAL(8,2) NOT NULL CHECK(costo_mensual > 0),
		edad_minima INT CHECK(edad_minima > 0),
		edad_maxima INT CHECK(edad_maxima > 0),
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT CK_edades_validas CHECK (edad_minima <= edad_maxima)
    );
END
GO



IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'horario_de_actividad' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
    CREATE TABLE solNorte.horario_de_actividad (
        ID_horario INT IDENTITY(1,1) PRIMARY KEY,
        dia CHAR(10) NOT NULL CHECK(dia in ('LUNES', 'MARTES', 'MIERCOLES', 'JUEVES', 'VIERNES', 'SABADO', 'DOMINGO')),
		hora_inicio TIME NOT NULL,
		hora_fin TIME NOT NULL,
		id_actividad INT,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		FOREIGN KEY (id_actividad) REFERENCES solNorte.actividad(ID_actividad),
		CONSTRAINT CK_horarios_validos CHECK (hora_inicio <= hora_fin)
    );
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'factura' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
--esta tabla no lleva borrado porque no es legal modificarla
    CREATE TABLE solNorte.factura (
        ID_factura INT IDENTITY(1,1) PRIMARY KEY,
        nro_factura VARCHAR(20) CHECK(nro_factura > 0), 
		tipo_factura CHAR(20),
		fecha_emision DATETIME,
		CAE CHAR(14),  --codigo unico que brinda ARCA para facturaciones electrónicas
		estado CHAR(9) CHECK(estado in ('PENDIENTE', 'PAGADA', 'VENCIDA')), --estado de mayor longitud PENDIENTE -> 9 caracteres, el otro es Pagada
		importe_total DECIMAL(8,2) CHECK (importe_total > 0),
		razon_social_emisor CHAR(30) default ('Institución deportiva Sol Norte'),
		CUIT_emisor BIGINT default (30678912345), --30 porque somos asociación jurídica, después el resto son dígitos random
		vencimiento_CAE DATETIME, -- el cae tiene un vencimiento
		id_socio INT, 
		anulada BIT NOT NULL DEFAULT 0, -- solo como dato interno ante un alta mal hecho o cosas por el estilo
		fecha_anulacion DATETIME,
		FOREIGN KEY (id_socio) REFERENCES solNorte.socio(ID_socio) 
    );
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'inscripcion_actividad' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.inscripcion_actividad (
		ID_inscripcion INT IDENTITY(1,1) PRIMARY KEY,
		fecha_inscripcion DATE NOT NULL,
		id_actividad INT NOT NULL,
		id_socio INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_socio_inscripcion FOREIGN KEY (id_socio) REFERENCES solNorte.socio(ID_socio),
		CONSTRAINT FK_id_actividad_inscripcion FOREIGN KEY (id_actividad) REFERENCES solNorte.actividad(ID_actividad)
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'asistencia' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.asistencia (
		ID_asistencia INT IDENTITY(1,1) PRIMARY KEY,
		fecha DATE NOT NULL,
		presentismo CHAR(1) NOT NULL CHECK(presentismo IN ('P', 'J', 'A')), --validar siempre con uppercase
		id_inscripcion_actividad INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_inscripcion_actividad FOREIGN KEY (id_inscripcion_actividad) 
			REFERENCES solNorte.inscripcion_actividad(ID_inscripcion)
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'cuota_membresia' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.cuota_membresia (
		ID_cuota INT IDENTITY(1,1) PRIMARY KEY,
		mes TINYINT NOT NULL CHECK (mes > 0 AND mes <= 12),
		anio INT NOT NULL,
		monto DECIMAL(8,2) NOT NULL,
		nombre_membresia CHAR(9) NOT NULL CHECK (nombre_membresia IN ('CADETE', 'MAYOR', 'MENOR')), -- Individual es el nombre de mayor longitud de los posibles nombres 
		edad_minima INT CHECK(edad_minima > 0),
		edad_maxima INT CHECK(edad_maxima > 0),
		id_socio INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_socio_cuota_membresia FOREIGN KEY (id_socio) 
			REFERENCES solNorte.socio(ID_socio),
		CONSTRAINT CK_edades_validas_membresia CHECK (edad_minima <= edad_maxima)
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'entrada_pileta' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.entrada_pileta(
		ID_entrada INT IDENTITY(1,1) PRIMARY KEY,
		fecha_entrada DATETIME NOT NULL,
		monto_socio DECIMAL(10,2) CHECK(monto_socio > 0),
		monto_invitado DECIMAL(8,2) CHECK(monto_invitado > 0),
		tipo_entrada_pileta CHAR(8) CHECK(tipo_entrada_pileta IN ('INVITADO', 'SOCIO')), -- Toma como valores socio o invitado 
		fue_reembolsada BIT DEFAULT 0,
		id_socio INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_socio FOREIGN KEY (id_socio) 
			REFERENCES solNorte.socio(ID_socio),
	);
END
GO



IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'reserva_sum' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
    CREATE TABLE solNorte.reserva_sum(
        ID_reserva INT IDENTITY(1,1) PRIMARY KEY,
        fecha_reserva DATETIME NOT NULL,
        hora_desde TIME NOT NULL CHECK(hora_desde >= '00:00:00'),
        hora_hasta TIME NOT NULL CHECK(hora_hasta > '00:00:00'),
        valor_hora DECIMAL(8,2) NOT NULL CHECK (valor_hora > 0),
        id_socio INT NOT NULL,
        borrado BIT NOT NULL DEFAULT 0,
        fecha_borrado DATETIME,
        CONSTRAINT FK_id_socio_reserva FOREIGN KEY (id_socio) 
            REFERENCES solNorte.socio(ID_socio),
        CONSTRAINT CK_horarios_validos_entrada_sum CHECK (
            hora_desde < hora_hasta AND
            DATEDIFF(MINUTE, hora_desde, hora_hasta) > 0
        )
    );
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'detalle_factura' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.detalle_factura(
		ID_detalle_factura INT IDENTITY(1,1) PRIMARY KEY,
		descripcion VARCHAR(70) NOT NULL,
		cantidad INT NOT NULL DEFAULT 1 CHECK(cantidad > 0),
		subtotal DECIMAL (10,2) NOT NULL CHECK(subtotal > 0),
		id_factura INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_factura FOREIGN KEY (id_factura) 
			REFERENCES solNorte.factura(ID_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'descuento' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.descuento(
		ID_descuento INT IDENTITY(1,1) PRIMARY KEY,
		descripcion VARCHAR (70) NOT NULL,
		tipo_descuento CHAR(30) NOT NULL CHECK(tipo_descuento IN ('INSCRIPCION_FAMILIAR', 'DESCUENTO_POR_MAS_DE_UNA_ACTIVIDAD')),  
		porcentaje DECIMAL (3,2) NOT NULL CHECK(porcentaje > 0 AND porcentaje < 1), -- 0,06 0,90 0,50 y asi tomaran los valores
		id_detalle_factura INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_detalle_factura FOREIGN KEY (id_detalle_factura) 
			REFERENCES solNorte.detalle_factura(ID_detalle_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'pago' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.pago(
		ID_pago INT IDENTITY(1,1) PRIMARY KEY,
		fecha_pago DATETIME,
		medio_de_pago CHAR(30) CHECK(medio_de_pago IN ('MASTERCARD', 'VISA', 'TARJETA_NARANJA', 'MERCADOPAGO_TRANSFERENCIA', 'PAGOFACIL', 'RAPIPAGO')),
		monto DECIMAL (8,2) NOT NULL CHECK(monto > 0), 
		estado CHAR (10) NOT NULL CHECK(estado IN ('PAGADO', 'PENDIENTE', 'RECHAZADO')),
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		id_factura INT NOT NULL
		CONSTRAINT FK_id_factura_pago FOREIGN KEY (id_factura) 
			REFERENCES solNorte.factura(ID_factura),
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'reembolso' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.reembolso (
		ID_reembolso INT IDENTITY(1,1) PRIMARY KEY,
		fecha_reembolso DATETIME,
		motivo_reembolso CHAR(30) NOT NULL,
		monto DECIMAL(8,2) NOT NULL CHECK(monto > 0), 
		id_factura INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_factura_reembolso FOREIGN KEY (id_factura) 
			REFERENCES solNorte.factura(ID_factura),
	);
END
GO

IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'deuda' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
	CREATE TABLE solNorte.deuda(
		ID_deuda INT IDENTITY(1,1) PRIMARY KEY,
		recargo_por_vencimiento DECIMAL (3,2) NOT NULL CHECK(recargo_por_vencimiento = 0.15 OR recargo_por_vencimiento = 0.10),
		deuda_acumulada DECIMAL (10,2) NOT NULL CHECK (deuda_acumulada > 0),
		fecha_readmision DATE,
		id_factura INT NOT NULL,
		id_socio INT NOT NULL,
		borrado BIT NOT NULL DEFAULT 0,
		fecha_borrado DATETIME,
		CONSTRAINT FK_id_factura_deuda FOREIGN KEY (id_factura) 
			REFERENCES solNorte.factura(ID_factura),
		CONSTRAINT FK_id_socio_deuda FOREIGN KEY (id_socio)
			REFERENCES solNorte.socio(ID_socio)
	);
END
GO


IF NOT EXISTS (
    SELECT * 
    FROM INFORMATION_SCHEMA.TABLES 
    WHERE TABLE_NAME = 'detalle_factura_actividad' AND TABLE_SCHEMA = 'solNorte'
)
BEGIN
    CREATE TABLE solNorte.detalle_factura_actividad (
        ID_detalle_factura INT,
        ID_actividad INT,
        PRIMARY KEY (ID_detalle_factura, ID_actividad),
        FOREIGN KEY (ID_detalle_factura) REFERENCES solNorte.detalle_factura(ID_detalle_factura),
        FOREIGN KEY (ID_actividad) REFERENCES solNorte.actividad(ID_actividad)
    );
END
GO

