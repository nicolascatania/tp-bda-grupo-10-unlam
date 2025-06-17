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
