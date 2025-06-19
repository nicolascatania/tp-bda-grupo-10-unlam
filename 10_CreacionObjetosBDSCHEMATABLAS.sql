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

--=====================================================TABLA USUARIO=====================================================--	
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

--=====================================================TABLA ROL=====================================================--
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
=======
--==========================================Crear SP ABM socio==========================================--

CREATE OR ALTER PROCEDURE dominio.sp_alta_socio
    @ID_usuario INT,
    @nombre VARCHAR(20),
    @apellido VARCHAR(20),
    @fecha_nacimiento DATE,
    @DNI CHAR(8),
    @telefono CHAR(10),
    @telefono_de_emergencia VARCHAR(23),
    @obra_social VARCHAR(30),
    @nro_obra_social VARCHAR(30),
    @email VARCHAR(30),
    @id_grupo_familiar INT = NULL,
    @id_responsable_a_cargo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --validar si existe usuario
    IF NOT EXISTS (SELECT 1 FROM dominio.usuario WHERE ID_usuario = @ID_usuario)
    BEGIN
        RAISERROR('El usuario especificado no existe.', 16, 1);
        RETURN;
    END

    --calcular edad y asigno categoría
    DECLARE @edad INT = DATEDIFF(YEAR, @fecha_nacimiento, GETDATE());
    DECLARE @categoria CHAR(10);
    IF @edad < 13
        SET @categoria = 'Menor';
    ELSE IF @edad < 18
        SET @categoria = 'Cadete';
    ELSE
        SET @categoria = 'Mayor';

    DECLARE @es_responsable BIT = CASE WHEN @edad >= 18 THEN 1 ELSE 0 END;

    --validar DNI
    IF TRY_CAST(@DNI AS INT) IS NULL OR CAST(@DNI AS INT) <= 0 OR CAST(@DNI AS INT) > 99999999
    BEGIN
        RAISERROR('DNI inválido.', 16, 1);
        RETURN;
    END

    --validar teléfono
    IF LEN(@telefono) <> 10
    BEGIN
        RAISERROR('Teléfono debe tener 10 dígitos.', 16, 1);
        RETURN;
    END

    --validar responsable a cargo si se pasa como param.
    IF @id_responsable_a_cargo IS NOT NULL
    BEGIN
        DECLARE @edad_responsable INT;
        SELECT @edad_responsable = DATEDIFF(YEAR, fecha_nacimiento, GETDATE())
        FROM dominio.socio
        WHERE ID_socio = @id_responsable_a_cargo;

        IF @edad_responsable IS NULL
        BEGIN
            RAISERROR('El responsable no existe.', 16, 1);
            RETURN;
        END

        IF @edad_responsable < 18
        BEGIN
            RAISERROR('El responsable debe ser mayor de edad.', 16, 1);
            RETURN;
        END
    END

    -- Si es responsable y no se pasó grupo_fam, creo uno nuevo
    IF @es_responsable = 1 AND @id_grupo_familiar IS NULL
    BEGIN
        INSERT INTO dominio.grupo_familiar DEFAULT VALUES;
        SET @id_grupo_familiar = SCOPE_IDENTITY();
    END

    --validar si existe grupo familiar y si existe, que no tenga responsable ya asignado
    IF @es_responsable = 1 AND @id_grupo_familiar IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM dominio.socio
            WHERE id_grupo_familiar = @id_grupo_familiar AND es_responsable = 1
        )
        BEGIN
            RAISERROR('Ya existe un responsable en este grupo familiar.', 16, 1);
            RETURN;
        END
    END
	--si quiero dar de alta un menor, debe existir grupo familiar antes. Debo reg. primero al socio o tutor responsable.
    IF @es_responsable = 0
    BEGIN
        IF @id_grupo_familiar IS NULL
        BEGIN
            RAISERROR('Un socio menor debe estar vinculado a un grupo familiar.', 16, 1);
            RETURN;
        END
        IF NOT EXISTS (SELECT 1 FROM dominio.grupo_familiar WHERE id_grupo_familiar = @id_grupo_familiar)
        BEGIN
            RAISERROR('El grupo familiar indicado no existe.', 16, 1);
            RETURN;
        END
    END

    --validar que no se autoasigne como responsable
    IF @id_responsable_a_cargo IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM dominio.socio WHERE ID_socio = @id_responsable_a_cargo AND DNI = @DNI
        )
        BEGIN
            RAISERROR('Un socio no puede ser su propio responsable.', 16, 1);
            RETURN;
        END
    END

    --verificar si el usuario tiene rol Tutor
    DECLARE @es_tutor BIT = 0;
    IF EXISTS (
        SELECT 1
        FROM dominio.rol_usuario ru
        INNER JOIN dominio.rol r ON ru.ID_rol = r.ID_rol
        WHERE ru.ID_usuario = @ID_usuario AND r.nombre_rol = 'Tutor'
    )
        SET @es_tutor = 1;

    --asignar nro_socio solo si NO es tutor
    DECLARE @nro_socio INT = NULL;
    IF @es_tutor = 0
    BEGIN
        SELECT @nro_socio = ISNULL(MAX(nro_socio), 0) + 1 FROM dominio.socio WHERE nro_socio IS NOT NULL;
    END

    --registrar alta socio
    INSERT INTO dominio.socio (
        nombre, apellido, fecha_nacimiento, DNI,
        telefono, telefono_de_emergencia, obra_social, nro_obra_social,
        email, id_grupo_familiar, id_responsable_a_cargo,
        categoria_socio, es_responsable, nro_socio
    )
    VALUES (
        @nombre, @apellido, @fecha_nacimiento, @DNI,
        @telefono, @telefono_de_emergencia, @obra_social, @nro_obra_social,
        @email, @id_grupo_familiar, @id_responsable_a_cargo,
        @categoria, @es_responsable, @nro_socio
    );

    PRINT 'Socio registrado exitosamente.';
END;
GO

CREATE OR ALTER PROCEDURE dominio.modificar_socio
    @ID_usuario INT,
    @ID_socio INT,
    @nombre VARCHAR(20),
    @apellido VARCHAR(20),
    @fecha_nacimiento DATE,
    @DNI CHAR(8),
    @telefono CHAR(10),
    @telefono_de_emergencia VARCHAR(23),
    @obra_social VARCHAR(30),
    @nro_obra_social VARCHAR(30),
    @email VARCHAR(30),
    @id_grupo_familiar INT = NULL,
    @id_responsable_a_cargo INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --validar existencia del socio
    IF NOT EXISTS (SELECT 1 FROM dominio.socio WHERE ID_socio = @ID_socio)
    BEGIN
        RAISERROR('El socio a modificar no existe.', 16, 1);
        RETURN;
    END

    --calcular edad y asignar categoría
    DECLARE @edad INT = DATEDIFF(YEAR, @fecha_nacimiento, GETDATE());
    DECLARE @categoria CHAR(10);
    IF @edad < 13
        SET @categoria = 'Menor';
    ELSE IF @edad < 18
        SET @categoria = 'Cadete';
    ELSE
        SET @categoria = 'Mayor';

    DECLARE @es_responsable BIT = CASE WHEN @edad >= 18 THEN 1 ELSE 0 END;

    --validar que no se asigne como su propio responsable
    IF @id_responsable_a_cargo = @ID_socio
    BEGIN
        RAISERROR('Un socio no puede ser su propio responsable.', 16, 1);
        RETURN;
    END

    --validar responsable a cargo
    IF @id_responsable_a_cargo IS NOT NULL
    BEGIN
        DECLARE @edad_responsable INT;
        SELECT @edad_responsable = DATEDIFF(YEAR, fecha_nacimiento, GETDATE())
        FROM dominio.socio
        WHERE ID_socio = @id_responsable_a_cargo;

        IF @edad_responsable IS NULL
        BEGIN
            RAISERROR('El responsable indicado no existe.', 16, 1);
            RETURN;
        END

        IF @edad_responsable < 18
        BEGIN
            RAISERROR('El responsable debe ser mayor de edad.', 16, 1);
            RETURN;
        END
    END

    --si es responsable, validar que no haya otro responsable en el grupo
    IF @es_responsable = 1 AND @id_grupo_familiar IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM dominio.socio
            WHERE id_grupo_familiar = @id_grupo_familiar
              AND es_responsable = 1
              AND ID_socio <> @ID_socio
        )
        BEGIN
            RAISERROR('Ya existe otro responsable mayor en este grupo familiar.', 16, 1);
            RETURN;
        END
    END

    --si es menor, debe tener grupo y responsable
    IF @edad < 18
    BEGIN
        IF @id_grupo_familiar IS NULL OR @id_responsable_a_cargo IS NULL
        BEGIN
            RAISERROR('Un socio menor debe tener grupo familiar y responsable a cargo.', 16, 1);
            RETURN;
        END
    END

    --verificar si tiene rol "Tutor"
    DECLARE @es_tutor BIT = 0;
    IF EXISTS (
        SELECT 1
        FROM dominio.rol_usuario ru
        INNER JOIN dominio.rol r ON ru.ID_rol = r.ID_rol
        WHERE ru.ID_usuario = @ID_usuario AND r.nombre_rol = 'Tutor'
    )
        SET @es_tutor = 1;

    --obtener nro_socio actual
    DECLARE @nro_socio_actual INT;
    SELECT @nro_socio_actual = nro_socio FROM dominio.socio WHERE ID_socio = @ID_socio;

    --si no es tutor y no tiene nro_socio, asignar uno nuevo
    DECLARE @nuevo_nro_socio INT = @nro_socio_actual;
    IF @es_tutor = 0 AND @nro_socio_actual IS NULL
    BEGIN
        SELECT @nuevo_nro_socio = ISNULL(MAX(nro_socio), 0) + 1 FROM dominio.socio WHERE nro_socio IS NOT NULL;
    END

    --actualizar socio
    UPDATE dominio.socio
    SET 
        nombre = @nombre,
        apellido = @apellido,
        fecha_nacimiento = @fecha_nacimiento,
        DNI = @DNI,
        telefono = @telefono,
        telefono_de_emergencia = @telefono_de_emergencia,
        obra_social = @obra_social,
        nro_obra_social = @nro_obra_social,
        email = @email,
        id_grupo_familiar = @id_grupo_familiar,
        id_responsable_a_cargo = @id_responsable_a_cargo,
        categoria_socio = @categoria,
        es_responsable = @es_responsable,
        nro_socio = @nuevo_nro_socio
    WHERE ID_socio = @ID_socio;

    PRINT 'Socio actualizado correctamente.';
END;
GO


/*tenemos que tener los campos eliminado BIT, fecha_baja DATE para el borrado lógico.
por otra parte surge la idea de agregar el campo nro_socio UNIQUE que admita NULL,
de esta manera podemos discriminar de los socios mayores que realizan actividades, de los que solo son responsables.
Aplicado al siguiente sp, con da la posibilidad de que si un socio mayor y resp del grupo_fam quiere darse de baja, pueda hacerlo
para quedar solo como responsable. Sino deberíamos dar de baja los menores a cargo, o dejarlo activo como socio, debienndo abonar membresía.

ALTER TABLE dominio.socio
ADD 
    eliminado BIT NOT NULL DEFAULT 0 WITH VALUES,
    fecha_baja DATE NULL,
    nro_socio INT NULL UNIQUE,
    CONSTRAINT CK_nro_socio_mayor_a_cero CHECK (
        nro_socio IS NULL OR nro_socio > 0
    );
GO
Modificar creación de tabla SOCIO para mantener coherencia desde la creación de objetos.

*/

CREATE OR ALTER PROCEDURE dominio.sp_baja_socio
    @ID_socio INT,
    @usuario_baja NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    --validar que el socio exista y no esté dado de baja
    IF NOT EXISTS (
        SELECT 1 FROM dominio.socio WHERE ID_socio = @ID_socio AND eliminado = 0
    )
    BEGIN
        RAISERROR('El socio no existe o ya fue dado de baja.', 16, 1);
        RETURN;
    END

    --verificar si tiene menores a cargo
    IF EXISTS (
        SELECT 1
        FROM dominio.socio
        WHERE id_responsable_a_cargo = @ID_socio AND eliminado = 0 AND DATEDIFF(YEAR, fecha_nacimiento, GETDATE()) < 18
    )
    BEGIN
        PRINT 'El socio tiene menores a cargo. Será convertido en Tutor.';

        --si teiene menor a cargo deja de ser socio activo y se cambia a rol tutor
        UPDATE dominio.socio
        SET 
            nro_socio = NULL,
            eliminado = 0,
            fecha_baja = GETDATE()
        WHERE ID_socio = @ID_socio;

        --asignar rol Tutor
        DECLARE @id_rol_tutor INT;
        SELECT @id_rol_tutor = ID_rol FROM dominio.rol WHERE nombre_rol = 'Tutor';

        IF NOT EXISTS (
            SELECT 1 FROM dominio.rol_usuario 
            WHERE ID_usuario = @ID_usuario AND ID_rol = @id_rol_tutor
        )
        BEGIN
            INSERT INTO dominio.rol_usuario (ID_usuario, ID_rol)
            VALUES (@ID_usuario, @id_rol_tutor);
        END

        PRINT 'El socio fue dado de baja como activo y ahora es tutor.';
        RETURN;
    END

    --si no tiene menores a cargo, borrado lógico
    UPDATE dominio.socio
    SET 
        eliminado = 1,
        fecha_baja = GETDATE(),
        nro_socio = NULL
    WHERE ID_socio = @ID_socio;

    PRINT 'Socio dado de baja exitosamente.';
END;
GO

--======================================================ACTIVIDAD======================================================-- 
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

--======================================================Horario de actividad======================================================-- 

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
	IF UPPER(@dia) NOT IN ('LUNES','MARTES','MIERCOLES','JUEVES','VIERNES','SABADO','DOMINGO')
		BEGIN
			RAISERROR('El dia debe ser un dia de la semana valido.', 16, 1);
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

--======================================================Inscripcion_actividad======================================================-- 

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

--======================================================Asistencia======================================================-- 

--Inserta un registro de asistencia 
CREATE OR ALTER PROCEDURE dominio.insertar_asistencia
    @fecha DATE,
    @asistio BIT,
    @id_inscripcion_actividad INT = NULL
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM dominio.actividad WHERE ID_actividad = @id_inscripcion_actividad)
    BEGIN
        RAISERROR('La inscripcion a actividad especificada no existe.', 16, 1);
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

--======================================================Descuento======================================================-- 
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

--======================================================Deuda======================================================-- 
/*

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

*/
--Insertar deudas
CREATE OR ALTER PROCEDURE dominio.insertar_deudas
	@recargo_por_vencimiento DECIMAL(3,2),
    @deuda_acumulada DECIMAL(10,2),
    @fecha_readmision DATE = NULL,
    @id_factura INT,
    @id_socio INT
AS
BEGIN
    -- Validar que la factura exista
    IF NOT EXISTS (SELECT 1 FROM dominio.factura WHERE ID_factura = @id_factura)
    BEGIN
        RAISERROR('La factura especificada no existe.', 16, 1);
        RETURN;
    END
    
    -- Validar que el socio exista
    IF NOT EXISTS (SELECT 1 FROM dominio.socio WHERE ID_socio = @id_socio)
    BEGIN
        RAISERROR('El socio especificado no existe.', 16, 1);
        RETURN;
    END
    INSERT INTO dominio.deuda (
        recargo_por_vencimiento,
        deuda_acumulada,
        fecha_readmision,
        id_factura,
        id_socio
    )
    VALUES (
        @recargo_por_vencimiento,
        @deuda_acumulada,
        @fecha_readmision,
        @id_factura,
        @id_socio
    );
END
GO