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

--STORED PROCEDURES

--ACTIVIDAD 
--Insertar actividad
CREATE OR ALTER PROCEDURE dominio.insertar_actividad
	@nombre_actividad CHAR(15),
    @costo_mensual DECIMAL(8,2),
    @edad_minima INT,
    @edad_maxima INT
AS
BEGIN
 IF @edad_minima > @edad_maxima
    BEGIN
        RAISERROR('La edad minima no puede ser mayor que la edad maxima.', 16, 1);
        RETURN;
    END

    INSERT INTO dominio.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
    VALUES (@nombre_actividad, @costo_mensual, @edad_minima, @edad_maxima);
END;
GO

--Modificar actividad
CREATE OR ALTER PROCEDURE dominio.modificar_actividad
    @ID_actividad INT,
    @nombre_actividad VARCHAR(15) = NULL,
    @costo_mensual DECIMAL(8,2) = NULL,
    @edad_minima INT = NULL,
    @edad_maxima INT = NULL
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dominio.actividad WHERE ID_actividad = @ID_actividad)
		BEGIN
			RAISERROR('La actividad especificada no existe.', 16, 1);
			RETURN;
		END
    IF @edad_minima > @edad_maxima
		BEGIN
			RAISERROR('La edad minima no puede ser mayor que la edad maxima.', 16, 1);
			RETURN;
		END

    UPDATE dominio.actividad
    SET nombre_actividad = ISNULL(@nombre_actividad, nombre_actividad),
        costo_mensual = ISNULL(@costo_mensual, costo_mensual),
        edad_minima = ISNULL(@edad_minima, edad_minima),
        edad_maxima = ISNULL(@edad_maxima, edad_maxima)
    WHERE ID_actividad = @ID_actividad;
END;
GO

--Borrar actividad
CREATE OR ALTER PROCEDURE dominio.borrar_actividad
	@ID_actividad INT
	AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dominio.actividad WHERE ID_actividad = @ID_actividad)
		BEGIN
			RAISERROR('La actividad especificada no existe.', 16, 1);
			RETURN;
		END
    DELETE FROM dominio.actividad
    WHERE ID_actividad = @ID_actividad;
END;
GO

--HORARIO DE ACTIVIDAD

--Insertar horario de actividad
CREATE OR ALTER PROCEDURE dominio.insertar_horario_de_actividad
    @dia CHAR(10),
    @hora_inicio TIME,
    @hora_fin TIME,
    @id_actividad INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dominio.actividad WHERE ID_actividad = @id_actividad)
		BEGIN
			RAISERROR('La actividad especificada no existe.', 16, 1);
			RETURN;
		END
	IF UPPER(@dia) NOT IN ('LUNES','MARTES','MIÉRCOLES','JUEVES','VIERNES','SÁBADO','DOMINGO')
		BEGIN
			RAISERROR('El día debe ser un día de la semana válido.', 16, 1);
			RETURN;
		END
    IF (@hora_inicio > @hora_fin)
		BEGIN
			RAISERROR('La hora de inicio no puede ser mayor que la hora de fin.', 16, 1);
			RETURN;
		END;
    INSERT INTO dominio.horario_de_actividad (dia, hora_inicio, hora_fin, id_actividad)
    VALUES (@dia, @hora_inicio, @hora_fin, @id_actividad);
END;
GO

--Modificar horario de actividad
CREATE OR ALTER PROCEDURE dominio.modificar_horario_de_actividad
    @ID_horario INT,
    @dia CHAR(10),
    @hora_inicio TIME,
    @hora_fin TIME,
    @id_actividad INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.horario_de_actividad WHERE ID_horario = @ID_horario)
    BEGIN
        RAISERROR('El horario especificado no existe.', 16, 1);
        RETURN;
    END
    IF @hora_inicio > @hora_fin
    BEGIN
        RAISERROR('La hora de inicio no puede ser mayor que la hora de fin.', 16, 1);
        RETURN;
    END;

    UPDATE dominio.horario_de_actividad
    SET dia = ISNULL(@dia, dia),
        hora_inicio = ISNULL(@hora_inicio, hora_inicio),
        hora_fin = ISNULL(@hora_fin, hora_fin),
        id_actividad = ISNULL(@id_actividad, id_actividad)
    WHERE ID_horario = @ID_horario;
END;
GO

--Borrar horario
CREATE OR ALTER PROCEDURE dominio.borrar_horario_de_actividad
@ID_horario INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.horario_de_actividad WHERE ID_horario = @ID_horario)
    BEGIN
        RAISERROR('El horario especificado no existe.', 16, 1);
        RETURN;
    END
    DELETE FROM dominio.horario_de_actividad
    WHERE ID_horario = @ID_horario;
END;
GO

-- INSCRIPCIÓN A ACTIVIDAD

--Insertar inscripcion a una actividad
CREATE OR ALTER PROCEDURE dominio.insertar_inscripcion_actividad
	@fecha_inscripcion DATE,
    @id_actividad INT,
    @id_socio INT
AS
BEGIN
    INSERT INTO dominio.inscripcion_actividad (fecha_inscripcion, id_actividad, id_socio)
    VALUES (@fecha_inscripcion, @id_actividad, @id_socio);
END;
GO

--Modificar inscripcion a una actividad
CREATE OR ALTER PROCEDURE dominio.modificar_inscripcion_actividad
    @ID_inscripcion INT,
    @fecha_inscripcion DATE,
    @id_actividad INT,
    @id_socio INT
AS
BEGIN
    UPDATE dominio.inscripcion_actividad
    SET fecha_inscripcion = @fecha_inscripcion,
        id_actividad = @id_actividad,
        id_socio = @id_socio
    WHERE ID_inscripcion = @ID_inscripcion;
END;
GO

-- Borra una inscripcion a una actividad
CREATE OR ALTER PROCEDURE dominio.borrar_inscripcion_actividad
    @ID_inscripcion INT
AS
BEGIN
    DELETE FROM dominio.inscripcion_actividad
    WHERE ID_inscripcion = @ID_inscripcion;
END;
GO

--ASISTENCIA

--Inserta un registro de asistencia 
CREATE OR ALTER PROCEDURE dominio.insertar_asistencia
    @fecha DATE,
    @asistio BIT,
    @id_inscripcion_actividad INT = NULL
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.actividad WHERE ID_actividad = @id_inscripcion_actividad)
    BEGIN
        RAISERROR('La inscripción a actividad especificada no existe.', 16, 1);
        RETURN;
    END
    INSERT INTO dominio.asistencia (fecha, asistio, id_inscripcion_actividad)
    VALUES (@fecha, @asistio, @id_inscripcion_actividad);
END;
GO

-- Modifica un registro de asistencia
CREATE OR ALTER PROCEDURE dominio.modificar_asistencia
    @ID_asistencia INT,
    @fecha DATE,
    @asistio BIT,
    @id_inscripcion_actividad INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.asistencia WHERE ID_asistencia = @ID_asistencia)
    BEGIN
        RAISERROR('El registro de asistencia especificado no existe.', 16, 1);
        RETURN;
    END
    UPDATE dominio.asistencia
    SET fecha = @fecha,
        asistio = @asistio,
        id_inscripcion_actividad = @id_inscripcion_actividad
    WHERE ID_asistencia = @ID_asistencia;
END;
GO


--Borrar un registro de asistencia 
CREATE OR ALTER PROCEDURE dominio.borrar_asistencia
    @ID_asistencia INT
AS 
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dominio.asistencia WHERE ID_asistencia = @ID_asistencia)
        BEGIN
            RAISERROR('El registro de asistencia especificado no existe', 16, 1);
            RETURN;
        END;
	DELETE FROM dominio.asistencia
    WHERE ID_asistencia = @ID_asistencia;
END;
GO   

--DESCUENTO
--Insertar descuento
CREATE OR ALTER PROCEDURE dominio.insertar_descuento
    @descripcion VARCHAR(70),
    @tipo_descuento VARCHAR(50),
    @porcentaje DECIMAL(3,2),
    @id_detalle_factura INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dominio.detalle_factura WHERE ID_detalle_factura = @id_detalle_factura)
		BEGIN
			RAISERROR('El detalle de factura especificado no existe', 16, 1);
			RETURN;
		END
	INSERT INTO dominio.descuento (descripcion, tipo_descuento, porcentaje, id_detalle_factura)
    VALUES (@descripcion, @tipo_descuento, @porcentaje, @id_detalle_factura);
END;
GO

--Actualizar descuento 
CREATE OR ALTER PROCEDURE dominio.actualizar_descuento
    @ID_descuento INT,
    @descripcion VARCHAR(70) = NULL,
    @tipo_descuento CHAR(30) = NULL,
    @porcentaje DECIMAL(3,2) = NULL
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM dominio.descuento WHERE ID_descuento = @ID_descuento)
		BEGIN
			RAISERROR('El descuento especificado no existe', 16, 1);
			RETURN;
		END
	UPDATE dominio.descuento
		SET 
			descripcion = ISNULL(@descripcion, descripcion),
			tipo_descuento = ISNULL(@tipo_descuento, tipo_descuento),
			porcentaje = ISNULL(@porcentaje, porcentaje)
		WHERE ID_descuento = @ID_descuento;
END;
GO	
--Borrar descuento
CREATE OR ALTER PROCEDURE dominio.eliminar_descuento
    @ID_descuento INT
AS
BEGIN
IF NOT EXISTS (SELECT 1 FROM dominio.descuento WHERE ID_descuento = @ID_descuento)
    BEGIN
        RAISERROR('El descuento especificado no existe', 16, 1);
        RETURN;
    END
    DELETE FROM dominio.descuento
    WHERE ID_descuento = @ID_descuento;
END;
GO
