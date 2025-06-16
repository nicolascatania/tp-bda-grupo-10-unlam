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

SET nocount ON;
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
        estado_usuario CHAR(15) DEFAULT 'activo', --estados: activo, inactivo, adeuda
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


--=====================================================CREACIONES DE SP PARA ABM DE CADA TABLA=====================================================--
/**
	El siguiente SP da de alta un usuario
	Valida que la contraseña cumpla los requerimientos marcados en el check de la tabla usuario, para generar un raiserror con una indicación clara del motivo de falla
	Valida que nombre de usuario sea único
	Setea la fecha de creación de contraseña a hoy y la fecha de expiración a dentro de un año
	Encripta la contraseña
	@param	nombre_usuario indica el nombre de usuario a dar de alta
	@param	contraseña	   indica la contraseña a ingresar		
*/
CREATE OR ALTER PROCEDURE dominio.alta_usuario
    @nombre_usuario VARCHAR(20),
    @contraseña VARCHAR(20)
AS
BEGIN
	SET NOCOUNT ON;

    IF LEN(@contraseña) < 8 OR 
       @contraseña NOT LIKE '%[0-9]%' OR
       @contraseña NOT LIKE '%[a-zA-Z]%' OR
       (@contraseña NOT LIKE '%!%' AND
        @contraseña NOT LIKE '%@%' AND
        @contraseña NOT LIKE '%#%' AND
        @contraseña NOT LIKE '%$%' AND
        @contraseña NOT LIKE '%^%' AND
        @contraseña NOT LIKE '%&%' AND
        @contraseña NOT LIKE '%*%' AND
        @contraseña NOT LIKE '%(%' AND
        @contraseña NOT LIKE '%)%')
    BEGIN
        RAISERROR('La contraseña no cumple con los requisitos de seguridad', 16, 1)
        RETURN
    END

    IF EXISTS (SELECT 1 FROM dominio.usuario WHERE nombre_usuario = @nombre_usuario)
    BEGIN
        RAISERROR('El nombre de usuario ya existe', 16, 1)
        RETURN
    END
    INSERT INTO dominio.usuario (
        nombre_usuario, 
        contraseña, 
        fecha_modificacion_contraseña, 
        fecha_expiracion_contraseña,
        estado_usuario
    )
    VALUES (
        @nombre_usuario, 
        @contraseña, 
        GETDATE(),
        DATEADD(YEAR, 1, GETDATE()),
        'activo'
    )
    
    PRINT 'Usuario creado exitosamente'
END
GO


/**
	Este SP borra un usuario de manera lógica (cambia estado a 'inactivo')
	@param	ID_usuario indica el ID del usuario a dar de baja
	@return 0 si éxito, -1 si error
*/
CREATE OR ALTER PROCEDURE dominio.baja_usuario
    @ID_usuario INT
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dominio.usuario WHERE ID_usuario = @ID_usuario)
        BEGIN
            RAISERROR('El usuario con ID %d no existe', 16, 1, @ID_usuario);
            RETURN -1;
        END
        
        IF EXISTS (SELECT 1 FROM dominio.usuario WHERE ID_usuario = @ID_usuario AND estado_usuario = 'inactivo')
        BEGIN
            RAISERROR('El usuario con ID %d ya está inactivo', 16, 1, @ID_usuario);
            RETURN -1;
        END
        
        UPDATE dominio.usuario 
        SET estado_usuario = 'inactivo' WHERE ID_usuario = @ID_usuario;
        
        PRINT 'Usuario dado de baja exitosamente';
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error al dar de baja usuario: %s', 16, 1, @ErrorMessage);
        RETURN -1;
    END CATCH
END
GO


/**
    El siguiente SP modifica los datos de un usuario existente, puede ser el nombre de usuario o la contraseña
    @param ID_usuario indica el ID del usuario a modificar (obligatorio para encontrar el usuario en cuestión, o terminar si no existe)
    @param nuevo_nombre_usuario nuevo nombre de usuario (opcional), si se indica, se valida que no exista un nombre de usuario como el ingresado, mantenemos la unicidad de los nombres de usuario
    @param nueva_contraseña nueva contraseña (opcional, debe cumplir requisitos) si se indica, se actualizan las fechas de modificado y vencimiento, además se realizan las validaciones correspondientes
    @param nuevo_estado nuevo estado (opcional: 'activo'/'inactivo'/'adeuda')
    @return 0 si éxito, -1 si error
*/
CREATE OR ALTER PROCEDURE dominio.modificar_usuario
    @ID_usuario INT,
    @nuevo_nombre_usuario VARCHAR(20) = NULL,
    @nueva_contraseña VARCHAR(20) = NULL,
    @nuevo_estado VARCHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dominio.usuario WHERE ID_usuario = @ID_usuario)
        BEGIN
            RAISERROR('El usuario con ID %d no existe', 16, 1, @ID_usuario);
            RETURN -1;
        END

        IF @nuevo_nombre_usuario IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM dominio.usuario 
                      WHERE nombre_usuario = @nuevo_nombre_usuario AND ID_usuario <> @ID_usuario)
            BEGIN
                RAISERROR('El nombre de usuario "%s" ya está en uso', 16, 1, @nuevo_nombre_usuario);
                RETURN -1;
            END
            
            UPDATE dominio.usuario 
            SET nombre_usuario = @nuevo_nombre_usuario
            WHERE ID_usuario = @ID_usuario;
        END

        IF @nueva_contraseña IS NOT NULL
        BEGIN
            IF LEN(@nueva_contraseña) < 8 OR 
               @nueva_contraseña NOT LIKE '%[0-9]%' OR
               @nueva_contraseña NOT LIKE '%[a-zA-Z]%' OR
               @nueva_contraseña NOT LIKE '%[!@#$%^&*()]%'
            BEGIN
                RAISERROR('La contraseña debe tener al menos 8 caracteres, incluir números, letras y un caracter especial (!@#$%^&*)', 16, 1);
                RETURN -1;
            END
            
            UPDATE dominio.usuario 
            SET contraseña = @nueva_contraseña,
                fecha_modificacion_contraseña = GETDATE(),
                fecha_expiracion_contraseña = DATEADD(YEAR, 1, GETDATE())
            WHERE ID_usuario = @ID_usuario;
        END

        IF @nuevo_estado IS NOT NULL
        BEGIN
            IF @nuevo_estado NOT IN ('activo', 'inactivo', 'adeuda')
            BEGIN
                RAISERROR('Estado inválido. Valores permitidos: "activo", "inactivo" o "adeuda"', 16, 1);
                RETURN -1;
            END
            
            UPDATE dominio.usuario 
            SET estado_usuario = @nuevo_estado
            WHERE ID_usuario = @ID_usuario;
        END

        IF @nuevo_nombre_usuario IS NULL AND 
           @nueva_contraseña IS NULL AND 
           @nuevo_estado IS NULL
        BEGIN
            RAISERROR('No se proporcionaron datos para modificar', 16, 1);
            RETURN -1;
        END

        PRINT 'Usuario modificado exitosamente';
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error al modificar usuario: %s', 16, 1, @ErrorMessage);
        RETURN -1;
    END CATCH
END
GO


/**
	Da de alta un nuevo rol
	@param nombre_rol	nombre que indica el usuario para crear un nuevo rol
*/
CREATE OR ALTER PROCEDURE dominio.alta_rol
    @nombre_rol VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF LEN(TRIM(@nombre_rol)) = 0
        BEGIN
            RAISERROR('El nombre del rol no puede estar vacío', 16, 1);
            RETURN -1;
        END
        
        IF EXISTS (
            SELECT 1 FROM dominio.rol 
            WHERE nombre_rol = @nombre_rol
        )
        BEGIN
            RAISERROR('El rol "%s" ya existe', 16, 1, @nombre_rol);
            RETURN -1;
        END
        
        INSERT INTO dominio.rol (nombre_rol)
        VALUES (@nombre_rol);
        
        PRINT 'Rol creado exitosamente';
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error al crear rol: %s', 16, 1, @ErrorMessage);
        RETURN -1;
    END CATCH
END
GO

/*
	Modifica el nombre de rol en base a un id de rol dado
	@param ID_rol			id para buscar en la tabla, si no existe, cancela la operación
	@param nuevo_nombre_rol	indica el nuevo nombre a setear
	@return 0 éxito, -1 error
*/
CREATE OR ALTER PROCEDURE dominio.modificar_rol
    @ID_rol INT,
    @nuevo_nombre_rol VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM dominio.rol WHERE ID_rol = @ID_rol)
        BEGIN
            RAISERROR('El rol con ID %d no existe', 16, 1, @ID_rol);
            RETURN -1;
        END

        IF LEN(TRIM(@nuevo_nombre_rol)) = 0
        BEGIN
            RAISERROR('El nombre del rol no puede estar vacío', 16, 1);
            RETURN -1;
        END
        
        IF EXISTS (
            SELECT 1 FROM dominio.rol 
            WHERE nombre_rol = @nuevo_nombre_rol 
            AND ID_rol <> @ID_rol
        )
        BEGIN
            RAISERROR('El nombre de rol "%s" ya está en uso por otro rol', 16, 1, @nuevo_nombre_rol);
            RETURN -1;
        END

        UPDATE dominio.rol 
        SET nombre_rol = @nuevo_nombre_rol
        WHERE ID_rol = @ID_rol;
        
        PRINT 'Rol modificado exitosamente';
        RETURN 0;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error al modificar rol: %s', 16, 1, @ErrorMessage);
        RETURN -1;
    END CATCH
END
GO

/*
	Consideramos que no es eficiente implementar una baja de rol, es preferible cambiar el nombre de ese rol
	ya que rol se relaciona con usuario (N:N) generando la tabla rol_usuario, realizar una baja sería un problema en la lógica de negocios
	Si tenemos muchos usuarios con el rol adeuda (que indica que tienen deudas y no han pagado), y por alguna razón le borramos el rol
	esa persona no queda sin rol o le pone por default activo, concluimos que simplemente es mejor cambiar de nombre el rol por algún otro.
	Además, creemos que no será una operación usada con frecuencia, sumando otro motivo para no realizarla.
*/