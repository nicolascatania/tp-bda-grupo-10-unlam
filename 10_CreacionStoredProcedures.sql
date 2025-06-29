USE Com2900G10;
GO

--=====================================================CREACIONES DE SP PARA ABM DE CADA TABLA=====================================================--
--==========================================Crear SP ABM grupo_familiar==========================================--

CREATE OR ALTER PROCEDURE solNorte.alta_grupo_familiar
    @cantidad_integrantes INT,
    @ID_grupo_familiar INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    --validacion cantidad_integrantes
    IF @cantidad_integrantes IS NULL OR @cantidad_integrantes <= 0
    BEGIN
        RAISERROR('La cantidad de integrantes debe ser mayor a cero.', 16, 1);
        RETURN;
    END

    --insertar grupo familiar
    INSERT INTO solNorte.grupo_familiar (cantidad_integrantes)
    VALUES (@cantidad_integrantes);

    --obtener el ID grupo familiar insertado
    SET @ID_grupo_familiar = SCOPE_IDENTITY();

    PRINT FORMATMESSAGE('Grupo familiar creado exitosamente. ID: %d', @ID_grupo_familiar);
END;
GO

CREATE OR ALTER PROCEDURE solNorte.modificar_grupo_familiar
    @ID_grupo_familiar INT,
    @accion CHAR(4)  -- 'ALTA' o 'BAJA'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar que el grupo exista y no esté borrado
    IF NOT EXISTS (
        SELECT 1 
        FROM solNorte.grupo_familiar
        WHERE ID_grupo_familiar = @ID_grupo_familiar AND borrado = 0
    )
    BEGIN
        RAISERROR('El grupo familiar con ID %d no existe o está dado de baja.', 16, 1, @ID_grupo_familiar);
        RETURN;
    END

    -- Obtener cantidad_integrantes actual
    DECLARE @actual INT;
    SELECT @actual = cantidad_integrantes
    FROM solNorte.grupo_familiar
    WHERE ID_grupo_familiar = @ID_grupo_familiar;

    -- Necesario ya que con CHAR se completa con espacios a derecha
    DECLARE @accion_normalizada CHAR(4) = UPPER(RTRIM(@accion));

    IF @accion_normalizada = 'ALTA'
    BEGIN
        UPDATE solNorte.grupo_familiar
        SET cantidad_integrantes = cantidad_integrantes + 1
        WHERE ID_grupo_familiar = @ID_grupo_familiar;

        PRINT FORMATMESSAGE('Se incrementó la cantidad de integrantes del grupo familiar con ID %d.', @ID_grupo_familiar);
    END
    ELSE IF @accion_normalizada = 'BAJA'
    BEGIN
        IF @actual <= 0
        BEGIN
            RAISERROR('No se puede reducir la cantidad de integrantes por debajo de cero para el grupo familiar con ID %d.', 16, 1, @ID_grupo_familiar);
            RETURN;
        END

        UPDATE solNorte.grupo_familiar
        SET cantidad_integrantes = cantidad_integrantes - 1
        WHERE ID_grupo_familiar = @ID_grupo_familiar;

        PRINT FORMATMESSAGE('Se redujo la cantidad de integrantes del grupo familiar con ID %d.', @ID_grupo_familiar);
    END
    ELSE
    BEGIN
        RAISERROR('La acción "%s" no es válida. Debe ser "ALTA" o "BAJA".', 16, 1, @accion);
        RETURN;
    END
END;
GO


CREATE OR ALTER PROCEDURE solNorte.baja_grupo_familiar
	@ID_grupo_familiar INT
AS
BEGIN
	SET NOCOUNT ON;

	--validar que el grupo familiar exista y no esté borrado
    IF NOT EXISTS (
        SELECT 1
        FROM solNorte.grupo_familiar
        WHERE ID_grupo_familiar = @ID_grupo_familiar AND borrado = 0
    )
    BEGIN
        RAISERROR('El grupo familiar no existe o está dado de baja. ID: %d', 16, 1, @ID_grupo_familiar);
        RETURN;
    END

	UPDATE solNorte.grupo_familiar
	SET
		borrado = 1,
		fecha_borrado = GETDATE()
		WHERE ID_grupo_familiar = @ID_grupo_familiar;

		PRINT FORMATMESSAGE('El grupo familiar se dio de baja exitosamente. ID: %d', @ID_grupo_familiar);

END;
GO

--==========================================Crear SP ABM socio==========================================--

CREATE OR ALTER PROCEDURE solNorte.alta_socio
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
    @id_responsable_a_cargo INT = NULL,
	@DNI_responsable INT = NULL,
	@email_responsable VARCHAR(30) = NULL,
	@nombre_responsable VARCHAR(20) = NULL,
	@apellido_responsable VARCHAR(20) = NULL,
	@fecha_nacimiento_responsable DATE = NULL,
	@telefono_responsable CHAR(10) = NULL,
	@parentezco_con_responsable CHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --validar si socio ya se encuentra registrado
    IF NOT EXISTS (SELECT 1 FROM solNorte.socio WHERE DNI = @DNI AND borrado = 0)
    BEGIN
        RAISERROR('El socio ya se encuentra registrado. DNI: %d', 16, 1, @DNI);
        RETURN;
    END

    --calcular edad y asigno categori­a
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
        RAISERROR('DNI invalido.', 16, 1);
        RETURN;
    END

    --validar telefono
    IF LEN(@telefono) <> 10
    BEGIN
        RAISERROR('Telefono debe tener 10 digitos.', 16, 1);
        RETURN;
    END

    --validar responsable a cargo si se pasa como param.
    IF @id_responsable_a_cargo IS NOT NULL
    BEGIN
        DECLARE @edad_responsable INT;
        SELECT @edad_responsable = DATEDIFF(YEAR, fecha_nacimiento, GETDATE())
        FROM solNorte.socio
        WHERE ID_socio = @id_responsable_a_cargo;

        IF @edad_responsable IS NULL
        BEGIN
            RAISERROR('El responsable no existe. ID: ', 16, 1, @id_responsable_a_cargo);
            RETURN;
        END

        IF @edad_responsable < 18
        BEGIN
            RAISERROR('El responsable debe ser mayor de edad.', 16, 1);
            RETURN;
        END
    END

    --si es responsable y no se pasa grupo_fam, creo uno nuevo
	IF @es_responsable = 1
	BEGIN
		IF @id_grupo_familiar IS NULL
		BEGIN
			DECLARE @nuevo_grupo INT;
			EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 1, @ID_grupo_familiar = @nuevo_grupo OUTPUT;
			SET @id_grupo_familiar = @nuevo_grupo;
			PRINT 'Nuevo grupo creado con ID: ' + CAST(@nuevo_grupo AS VARCHAR);
		END
		ELSE
		BEGIN
			--sino valido que no haya responsable
			IF EXISTS (
				SELECT 1 FROM solNorte.socio
				WHERE id_grupo_familiar = @id_grupo_familiar AND es_responsable = 1
			)
			BEGIN
				RAISERROR('Ya existe un responsable en este grupo familiar.', 16, 1);
				RETURN;
			END
		END
	END
	--si quiero dar de alta un menor, debe existir grupo familiar antes. Debo reg. primero al socio o tutor responsable.
    IF @edad < 18
    BEGIN
        IF @id_responsable_a_cargo IS NULL
        BEGIN
            RAISERROR('El socio menor debe estar vinculado a un responsable.', 16, 1);
            RETURN;
        END

        --si no se paso grupo, pero tiene responsable, obtener el grupo del responsable
        IF @id_grupo_familiar IS NULL
        BEGIN
            SELECT @id_grupo_familiar = id_grupo_familiar
            FROM solNorte.socio
            WHERE ID_socio = @id_responsable_a_cargo;

            IF @id_grupo_familiar IS NULL
            BEGIN
                RAISERROR('El responsable no tiene grupo familiar asignado.', 16, 1);
                RETURN;
            END
        END
    END

    --validar que no se autoasigne como responsable
    IF @id_responsable_a_cargo IS NOT NULL
    BEGIN
        IF EXISTS (
            SELECT 1 FROM solNorte.socio WHERE ID_socio = @id_responsable_a_cargo AND DNI = @DNI
        )
        BEGIN
            RAISERROR('Un socio no puede ser su propio responsable.', 16, 1);
            RETURN;
        END
    END

    --registrar alta socio
    INSERT INTO solNorte.socio (
        nombre, apellido, fecha_nacimiento, DNI,
        telefono, telefono_de_emergencia, obra_social, nro_obra_social,
        email, id_grupo_familiar, id_responsable_a_cargo,
        categoria_socio, es_responsable,
        DNI_responsable, mail_responsable, nombre_responsable, apellido_responsable,
        fecha_nacimiento_responsable, telefono_responsable, parentezco_con_responsable
    )
    VALUES (
        @nombre, @apellido, @fecha_nacimiento, @DNI,
        @telefono, @telefono_de_emergencia, @obra_social, @nro_obra_social,
        @email, @id_grupo_familiar, @id_responsable_a_cargo,
        @categoria, @es_responsable,
        @DNI_responsable, @email_responsable, @nombre_responsable, @apellido_responsable,
        @fecha_nacimiento_responsable, @telefono_responsable, @parentezco_con_responsable
    );

	DECLARE @nuevo_id_socio INT = SCOPE_IDENTITY();

    --si el grupo ya existe, incremento cantidad_integrantes
    IF @id_grupo_familiar IS NOT NULL
    BEGIN
        EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = @id_grupo_familiar, @accion = 'ALTA';
    END

    PRINT FORMATMESSAGE('Socio registrado exitosamente con ID %d.', @nuevo_id_socio);
END;
GO

CREATE OR ALTER PROCEDURE solNorte.modificar_socio
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
    @id_responsable_a_cargo INT = NULL,
	@DNI_responsable INT = NULL,
    @email_responsable VARCHAR(30) = NULL,
    @nombre_responsable VARCHAR(20) = NULL,
    @apellido_responsable VARCHAR(20) = NULL,
    @fecha_nacimiento_responsable DATE = NULL,
    @telefono_responsable CHAR(10) = NULL,
    @parentezco_con_responsable CHAR(15) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    --validar existencia del socio
    IF NOT EXISTS (SELECT 1 FROM solNorte.socio WHERE ID_socio = @ID_socio AND borrado = 0)
    BEGIN
        RAISERROR('El socio a modificar no existe.', 16, 1);
        RETURN;
    END

	--validar DNI duplicado
    IF EXISTS (
        SELECT 1 FROM solNorte.socio
        WHERE DNI = @DNI AND ID_socio <> @ID_socio AND borrado = 0
    )
    BEGIN
        RAISERROR('El DNI ya está registrado a otro socio.', 16, 1);
        RETURN;
    END

	--validar telefono
	IF LEN(@telefono) <> 10
    BEGIN
        RAISERROR('Teléfono debe tener 10 dígitos.', 16, 1);
        RETURN;
    END

    --calcular edad y asignar categorÃ­a
    DECLARE @edad INT = DATEDIFF(YEAR, @fecha_nacimiento, GETDATE());
    DECLARE @categoria CHAR(10);
    IF @edad < 13
        SET @categoria = 'Menor';
    ELSE IF @edad < 18
        SET @categoria = 'Cadete';
    ELSE
        SET @categoria = 'Mayor';

    DECLARE @es_responsable BIT = CASE WHEN @edad >= 18 THEN 1 ELSE 0 END;

    --validar responsable a cargo
    IF @id_responsable_a_cargo IS NOT NULL
    BEGIN
		--que no se asigne como su propio responsable
		IF @id_responsable_a_cargo = @ID_socio
		BEGIN
			RAISERROR('Un socio no puede ser su propio responsable.', 16, 1);
			RETURN;
		END
		--existencia y edad
        DECLARE @edad_responsable INT;
        SELECT @edad_responsable = DATEDIFF(YEAR, fecha_nacimiento, GETDATE())
        FROM solNorte.socio
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
            FROM solNorte.socio
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

	DECLARE @grupo_anterior INT;
	SELECT @grupo_anterior = id_grupo_familiar FROM solNorte.socio WHERE ID_socio = @ID_socio;

	--realizo la baja
	IF @id_grupo_familiar IS NOT NULL AND @grupo_anterior IS NOT NULL AND @id_grupo_familiar <> @grupo_anterior
	BEGIN
		EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = @grupo_anterior, @accion = 'BAJA';
		--si quedo vacio, dar de baja el grupo
        DECLARE @integrantes_restantes INT;
        SELECT @integrantes_restantes = cantidad_integrantes
        FROM solNorte.grupo_familiar
        WHERE ID_grupo_familiar = @grupo_anterior;

        IF @integrantes_restantes = 0
        BEGIN
            EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = @grupo_anterior;
        END
		--alta en nuevo grupo
		EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = @id_grupo_familiar, @accion = 'ALTA';
	END

    --actualizar socio
    UPDATE solNorte.socio
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
        DNI_responsable = @DNI_responsable,
        mail_responsable = @email_responsable,
        nombre_responsable = @nombre_responsable,
        apellido_responsable = @apellido_responsable,
        fecha_nacimiento_responsable = @fecha_nacimiento_responsable,
        telefono_responsable = @telefono_responsable,
        parentezco_con_responsable = @parentezco_con_responsable
    WHERE ID_socio = @ID_socio;

    PRINT FORMATMESSAGE('Socio (DNI: %d) actualizado correctamente. ID: %d', @DNI, @ID_socio);
END;
GO

CREATE OR ALTER PROCEDURE solNorte.baja_socio
    @ID_socio INT
AS
BEGIN
    SET NOCOUNT ON;

    --validar que el socio exista y no este dado de baja
    IF NOT EXISTS (
        SELECT 1 
        FROM solNorte.socio 
        WHERE ID_socio = @ID_socio AND borrado = 0
    )
    BEGIN
        RAISERROR('El socio no existe o ya fue dado de baja. ID: %d', 16, 1, @ID_socio);
        RETURN;
    END

    --obtener grupo familiar actual
    DECLARE @grupo INT;
    SELECT @grupo = id_grupo_familiar
    FROM solNorte.socio
    WHERE ID_socio = @ID_socio;

    --verificar si tiene menores a cargo
    IF EXISTS (
        SELECT 1
        FROM solNorte.socio
        WHERE id_responsable_a_cargo = @ID_socio 
          AND borrado = 0 
          AND categoria_socio IN ('Menor','Cadete')
    )
    BEGIN
        --buscar otro socio mayor en el grupo
        DECLARE @nuevo_responsable INT;

        SELECT TOP 1 @nuevo_responsable = ID_socio
        FROM solNorte.socio
        WHERE id_grupo_familiar = @grupo
          AND ID_socio <> @ID_socio
          AND borrado = 0
          AND categoria_socio = 'Mayor'
        ORDER BY fecha_nacimiento; --puede ser por criterio alfabético también

        IF @nuevo_responsable IS NULL
        BEGIN
            RAISERROR('No se puede dar de baja al socio porque tiene menores a cargo y es el único mayor del grupo familiar.', 16, 1);
            RETURN;
        END

        --transfiero responsabilidad de los menores al nuevo socio mayor
        UPDATE solNorte.socio
        SET id_responsable_a_cargo = @nuevo_responsable
        WHERE id_responsable_a_cargo = @ID_socio
          AND borrado = 0
          AND categoria_socio IN ('Menor','Cadete');

        --asegurar que el nuevo responsable tenga su campo "responsable" en 1
        UPDATE solNorte.socio
        SET es_responsable = 1
        WHERE ID_socio = @nuevo_responsable;
    END

    --baja logica del socio
    UPDATE solNorte.socio
    SET borrado = 1,
        fecha_borrado = GETDATE()
    WHERE ID_socio = @ID_socio;

    --si pertenece a un grupo, actualizar cantidad_integrantes
    IF @grupo IS NOT NULL
    BEGIN
        EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = @grupo, @accion = 'BAJA';

        --verificar si quedo vacio
        DECLARE @restantes INT;
        SELECT @restantes = cantidad_integrantes
        FROM solNorte.grupo_familiar
        WHERE ID_grupo_familiar = @grupo;

        IF @restantes = 0
        BEGIN
            EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = @grupo;
        END
    END

	--busco el DNI para lograr un print con información útil
	Declare @DNI_socio INT;
	SET @DNI_socio = (SELECT DNI FROM solNorte.socio WHERE ID_socio = @ID_socio);

    PRINT FORMATMESSAGE('Socio (DNI: %d) dado de baja exitosamente. ID: %d', @DNI_socio, @ID_socio);
END;
GO
--======================================================ACTIVIDAD======================================================-- 
--Insertar actividad
CREATE OR ALTER PROCEDURE solNorte.insertar_actividad
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

    INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual, edad_minima, edad_maxima)
    VALUES (@nombre_actividad, @costo_mensual, @edad_minima, @edad_maxima);
END;
GO

--Modificar actividad
CREATE OR ALTER PROCEDURE solNorte.modificar_actividad
    @ID_actividad INT,
    @nombre_actividad VARCHAR(15) = NULL,
    @costo_mensual DECIMAL(8,2) = NULL,
    @edad_minima INT = NULL,
    @edad_maxima INT = NULL
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.actividad WHERE ID_actividad = @ID_actividad)
		BEGIN
			RAISERROR('La actividad especificada no existe.', 16, 1);
			RETURN;
		END
    IF @edad_minima > @edad_maxima
		BEGIN
			RAISERROR('La edad minima no puede ser mayor que la edad maxima.', 16, 1);
			RETURN;
		END

    UPDATE solNorte.actividad
    SET nombre_actividad = ISNULL(@nombre_actividad, nombre_actividad),
        costo_mensual = ISNULL(@costo_mensual, costo_mensual),
        edad_minima = ISNULL(@edad_minima, edad_minima),
        edad_maxima = ISNULL(@edad_maxima, edad_maxima)
    WHERE ID_actividad = @ID_actividad;
END;
GO

--Borrar actividad
CREATE OR ALTER PROCEDURE solNorte.borrar_actividad
	@ID_actividad INT
	AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.actividad WHERE ID_actividad = @ID_actividad)
		BEGIN
			RAISERROR('La actividad especificada no existe.', 16, 1);
			RETURN;
		END
    DELETE FROM solNorte.actividad
    WHERE ID_actividad = @ID_actividad;
END;
GO

--=====================================================CUOTA MEMBRESIA=====================================================--
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

    IF NOT EXISTS (SELECT 1 FROM solNorte.socio WHERE ID_socio = @id_socio)
        BEGIN RAISERROR('El socio no existe.', 16, 1); RETURN; END

    -- Insercion
    INSERT INTO solNorte.cuota_membresia (
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
    IF NOT EXISTS (SELECT 1 FROM solNorte.cuota_membresia WHERE ID_cuota = @ID_cuota AND borrado = 0)
        BEGIN RAISERROR('La cuota no existe o ya fue eliminada.', 16, 1); RETURN; END

    UPDATE solNorte.cuota_membresia
    SET borrado = 1, fecha_borrado = GETDATE()
    WHERE ID_cuota = @ID_cuota;
END;
GO


-- Este sp permite modificar alguno de los campos (excepto el id)  en caso de algun error en la emisión de la cuota
-- Con COALESCE evitamos que se sobreescriban los valores existentes en caso de no indicar el valor por parámetros
-- Ejemplo, si solo indico un nuevo monto y el resto de parametros no, solo se modificara el monto, el resto sigue igual como está sin cambios
CREATE OR ALTER PROCEDURE solNorte.modificar_cuota_membresia
    @ID_cuota INT,
    @monto DECIMAL(8,2) = NULL,
    @nombre_membresia CHAR(9) = NULL,
    @edad_minima INT = NULL,
    @edad_maxima INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 
        FROM solNorte.cuota_membresia 
        WHERE ID_cuota = @ID_cuota
    )
    BEGIN
        RAISERROR('No existe la cuota con ID %d', 16, 1, @ID_cuota);
        RETURN;
    END

    UPDATE solNorte.cuota_membresia
    SET
        monto = COALESCE(@monto, monto),
        nombre_membresia = COALESCE(@nombre_membresia, nombre_membresia),
        edad_minima = COALESCE(@edad_minima, edad_minima),
        edad_maxima = COALESCE(@edad_maxima, edad_maxima)
    WHERE ID_cuota = @ID_cuota;

    PRINT FORMATMESSAGE('Cuota ID %d modificada correctamente.', @ID_cuota);
END;
;
GO

--======================================================Horario de actividad======================================================-- 

--Insertar horario de actividad
CREATE OR ALTER PROCEDURE solNorte.insertar_horario_de_actividad
    @dia CHAR(10),
    @hora_inicio TIME,
    @hora_fin TIME,
    @id_actividad INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.actividad WHERE ID_actividad = @id_actividad)
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
    INSERT INTO solNorte.horario_de_actividad (dia, hora_inicio, hora_fin, id_actividad)
    VALUES (@dia, @hora_inicio, @hora_fin, @id_actividad);
END;
GO

--Modificar horario de actividad
CREATE OR ALTER PROCEDURE solNorte.modificar_horario_de_actividad
    @ID_horario INT,
    @dia CHAR(10),
    @hora_inicio TIME,
    @hora_fin TIME,
    @id_actividad INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario)
    BEGIN
        RAISERROR('El horario especificado no existe.', 16, 1);
        RETURN;
    END
    IF @hora_inicio > @hora_fin
    BEGIN
        RAISERROR('La hora de inicio no puede ser mayor que la hora de fin.', 16, 1);
        RETURN;
    END;

    UPDATE solNorte.horario_de_actividad
    SET dia = ISNULL(@dia, dia),
        hora_inicio = ISNULL(@hora_inicio, hora_inicio),
        hora_fin = ISNULL(@hora_fin, hora_fin),
        id_actividad = ISNULL(@id_actividad, id_actividad)
    WHERE ID_horario = @ID_horario;
END;
GO

--Borrar horario
CREATE OR ALTER PROCEDURE solNorte.borrar_horario_de_actividad
@ID_horario INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM solNorte.horario_de_actividad WHERE ID_horario = @ID_horario)
    BEGIN
        RAISERROR('El horario especificado no existe.', 16, 1);
        RETURN;
    END
    DELETE FROM solNorte.horario_de_actividad
    WHERE ID_horario = @ID_horario;
END;
GO

--======================================================Inscripcion_actividad======================================================-- 

--Insertar inscripcion a una actividad
CREATE OR ALTER PROCEDURE solNorte.insertar_inscripcion_actividad
	@fecha_inscripcion DATE,
    @id_actividad INT,
    @id_socio INT
AS
BEGIN
    INSERT INTO solNorte.inscripcion_actividad (fecha_inscripcion, id_actividad, id_socio)
    VALUES (@fecha_inscripcion, @id_actividad, @id_socio);
END;
GO

--Modificar inscripcion a una actividad
CREATE PROCEDURE solNorte.modificar_inscripcion_actividad
    @ID_inscripcion INT,
    @fecha_inscripcion DATE,
    @id_actividad INT,
    @id_socio INT
AS
BEGIN
    UPDATE solNorte.inscripcion_actividad
    SET fecha_inscripcion = @fecha_inscripcion,
        id_actividad = @id_actividad,
        id_socio = @id_socio
    WHERE ID_inscripcion = @ID_inscripcion;
END;
GO

-- Borra una inscripcion a una actividad
CREATE PROCEDURE solNorte.borrar_inscripcion_actividad
    @ID_inscripcion INT
AS
BEGIN
    DELETE FROM solNorte.inscripcion_actividad
    WHERE ID_inscripcion = @ID_inscripcion;
END;
GO

--======================================================Asistencia======================================================-- 

--Inserta un registro de asistencia 
CREATE PROCEDURE solNorte.insertar_asistencia
    @fecha DATE,
    @asistio BIT,
    @id_inscripcion_actividad INT = NULL
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM solNorte.actividad WHERE ID_actividad = @id_inscripcion_actividad)
    BEGIN
        RAISERROR('La inscripciï¿½n a actividad especificada no existe.', 16, 1);
        RETURN;
    END
    INSERT INTO solNorte.asistencia (fecha, asistio, id_inscripcion_actividad)
    VALUES (@fecha, @asistio, @id_inscripcion_actividad);
END;
GO

-- Modifica un registro de asistencia
CREATE PROCEDURE solNorte.modificar_asistencia
    @ID_asistencia INT,
    @fecha DATE,
    @asistio BIT,
    @id_inscripcion_actividad INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia)
    BEGIN
        RAISERROR('El registro de asistencia especificado no existe.', 16, 1);
        RETURN;
    END
    UPDATE solNorte.asistencia
    SET fecha = @fecha,
        asistio = @asistio,
        id_inscripcion_actividad = @id_inscripcion_actividad
    WHERE ID_asistencia = @ID_asistencia;
END;
GO


--Borrar un registro de asistencia 
CREATE PROCEDURE solNorte.borrar_asistencia
    @ID_asistencia INT
AS 
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.asistencia WHERE ID_asistencia = @ID_asistencia)
        BEGIN
            RAISERROR('El registro de asistencia especificado no existe', 16, 1);
            RETURN;
        END;
	DELETE FROM solNorte.asistencia
    WHERE ID_asistencia = @ID_asistencia;
END;
GO   

--======================================================Descuento======================================================-- 
--Insertar descuento
CREATE OR ALTER PROCEDURE solNorte.insertar_descuento
    @descripcion VARCHAR(70),
    @tipo_descuento VARCHAR(50),
    @porcentaje DECIMAL(3,2),
    @id_detalle_factura INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.detalle_factura WHERE ID_detalle_factura = @id_detalle_factura)
		BEGIN
			RAISERROR('El detalle de factura especificado no existe', 16, 1);
			RETURN;
		END
	INSERT INTO solNorte.descuento (descripcion, tipo_descuento, porcentaje, id_detalle_factura)
    VALUES (@descripcion, @tipo_descuento, @porcentaje, @id_detalle_factura);
END;
GO

--Actualizar descuento 
CREATE OR ALTER PROCEDURE solNorte.actualizar_descuento
    @ID_descuento INT,
    @descripcion VARCHAR(70) = NULL,
    @tipo_descuento CHAR(30) = NULL,
    @porcentaje DECIMAL(3,2) = NULL
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.descuento WHERE ID_descuento = @ID_descuento)
		BEGIN
			RAISERROR('El descuento especificado no existe', 16, 1);
			RETURN;
		END
	UPDATE solNorte.descuento
		SET 
			descripcion = ISNULL(@descripcion, descripcion),
			tipo_descuento = ISNULL(@tipo_descuento, tipo_descuento),
			porcentaje = ISNULL(@porcentaje, porcentaje)
		WHERE ID_descuento = @ID_descuento;
END;
GO	
--Borrar descuento
CREATE OR ALTER PROCEDURE solNorte.eliminar_descuento
    @ID_descuento INT
AS
BEGIN
	IF NOT EXISTS (SELECT 1 FROM solNorte.descuento WHERE ID_descuento = @ID_descuento)
		BEGIN
			RAISERROR('El descuento especificado no existe', 16, 1);
			RETURN;
		END
		DELETE FROM solNorte.descuento
		WHERE ID_descuento = @ID_descuento;
END
GO

--=====================================================FACTURA=====================================================--
CREATE OR ALTER PROCEDURE solNorte.insertar_factura
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

    IF NOT EXISTS (SELECT 1 FROM solNorte.socio WHERE ID_socio = @id_socio)
        BEGIN RAISERROR('El socio no existe.', 16, 1); RETURN; END

    -- Insercion
    INSERT INTO solNorte.factura (
        nro_factura, tipo_factura, fecha_emision, CAE, estado,
        importe_total, razon_social_emisor, CUIT_emisor, vencimiento_CAE, id_socio
    )
    VALUES (
        @nro_factura, @tipo_factura, @fecha_emision, @CAE, @estado,
        @importe_total, @razon_social_emisor, @CUIT_emisor, @vencimiento_CAE, @id_socio
    );

END;
GO

/* ANULACION DE FACTURA, por motivos legales, una factura puede ser anulada para anular su validez, debe hacerse x medio de ARCA (pero queda fuera del alcance del tp), sin embargo, modelamos esto 
	ya que el sistema debe ser capaz de identificar las facturas que deben ser llevadas a hacer el trámite de anulación, derivando en nota de credito o en simple reembolso*/
CREATE OR ALTER PROCEDURE solNorte.anular_factura @ID_factura INT
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (
        SELECT 1 
        FROM solNorte.factura 
        WHERE ID_factura = @ID_factura
    )
    BEGIN
        RAISERROR('No existe la factura buscada', 16, 1);
        RETURN;
    END

    UPDATE solNorte.factura
    SET anulada = 1,
        fecha_anulacion = GETDATE()
    WHERE ID_factura = @ID_factura;
END


-- Al ser un documento legal, la factura no se puede modificar ni borrar
--=====================================================DETALLE FACTURA=====================================================--
ALTER TABLE solNorte.detalle_factura
ADD activo BIT NOT NULL DEFAULT 1;
GO

CREATE OR ALTER PROCEDURE solNorte.insertar_detalle_factura
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

    IF NOT EXISTS (SELECT 1 FROM solNorte.factura WHERE ID_factura = @id_factura)
        BEGIN RAISERROR('La factura no existe. ID: %d', 16, 1, @id_factura); RETURN; END

    -- Insercion
    INSERT INTO solNorte.detalle_factura (
        descripcion, cantidad, subtotal, id_factura
    ) VALUES (
        @descripcion, @cantidad, @subtotal, @id_factura
    );
END;
GO

CREATE OR ALTER PROCEDURE solNorte.modificar_detalle_factura
    @ID_detalle_factura INT,
    @descripcion VARCHAR(70),
    @cantidad INT,
    @subtotal DECIMAL(10,2)
AS
BEGIN
	SET NOCOUNT ON
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM solNorte.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura)
        BEGIN RAISERROR('El detalle de factura no existe. ID: %d', 16, 1, @ID_detalle_factura); RETURN; END

    IF LEN(RTRIM(@descripcion)) = 0
        BEGIN RAISERROR('Agregar descipcion.', 16, 1); RETURN; END

    IF @cantidad IS NULL OR @cantidad <= 0
        BEGIN RAISERROR('Cantidad invalida.', 16, 1); RETURN; END

    IF @subtotal IS NULL OR @subtotal < 0
        BEGIN RAISERROR('Subtotal invalido.', 16, 1); RETURN; END

    UPDATE solNorte.detalle_factura
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
    IF NOT EXISTS (SELECT 1 FROM solNorte.detalle_factura WHERE ID_detalle_factura = @ID_detalle_factura AND borrado = 1)
    BEGIN
        RAISERROR('El detalle de factura no existe o ya esta eliminado. ID: %d', 16, 1, @ID_detalle_factura);
        RETURN;
    END

    UPDATE solNorte.detalle_factura
    SET borrado = 0, fecha_borrado = GETDATE()
    WHERE ID_detalle_factura = @ID_detalle_factura;
END;
GO

--=====================================================PAGO=====================================================--
CREATE OR ALTER PROCEDURE solNorte.insertar_pago
    @fecha_pago DATETIME,
    @medio_de_pago CHAR(30),
    @monto DECIMAL(8,2),
    @estado CHAR(10),
    @id_factura INT
AS
BEGIN
    -- Validaciones
    IF NOT EXISTS (SELECT 1 FROM solNorte.factura WHERE ID_factura = @id_factura)
    BEGIN
        RAISERROR('La factura no existe. ID: %d', 16, 1, @id_factura);
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

    INSERT INTO solNorte.pago (fecha_pago, medio_de_pago, monto, estado, id_factura) 
		VALUES (@fecha_pago, @medio_de_pago, @monto, @estado, @id_factura);
END;
GO

CREATE OR ALTER PROCEDURE solNorte.modificar_pago
    @ID_pago INT,
    @fecha_pago DATETIME,
    @medio_de_pago CHAR(30),
    @monto DECIMAL(8,2),
    @estado CHAR(10)
AS
BEGIN
	SET NOCOUNT ON
    IF NOT EXISTS (SELECT 1 FROM solNorte.pago WHERE ID_pago = @ID_pago AND borrado = 0)
    BEGIN
        RAISERROR('El pago no existe o está eliminado. ID: %d', 16, 1, @ID_pago);
        RETURN;
    END

	IF EXISTS (SELECT 1 FROM solNorte.pago
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

    UPDATE solNorte.pago
    SET fecha_pago = @fecha_pago,
        medio_de_pago = @medio_de_pago,
        monto = @monto,
        estado = @estado
    WHERE ID_pago = @ID_pago;
END
GO

CREATE OR ALTER PROCEDURE solNorte.eliminar_pago
    @ID_pago INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM solNorte.pago WHERE ID_pago = @ID_pago AND borrado = 0)
    BEGIN
        RAISERROR('El pago no existe o ya está eliminado. ID: %d', 16, 1, @ID_pago);
        RETURN;
    END
	IF EXISTS (SELECT 1 FROM solNorte.pago
        WHERE ID_pago = @ID_pago AND estado = 'Pagado')
    BEGIN
        RAISERROR('No se puede eliminar un pago con estado "Pagado".', 16, 1);
        RETURN;
    END
    UPDATE solNorte.pago
    SET borrado = 1
    WHERE ID_pago = @ID_pago;
END
GO


--=====================================================ReservaSUM=====================================================--
/**
	Este sp da de alta una reserva de sum, con parámetros indicados según el usuario. Las validaciones importantes ya son hechas por checks en la tabla solNorte.reserva_sum
	@param	fecha_reserva	fecha para la cual se reserva el sum, no de cuando se efectúa la transacción de la reserva como tal
	@param	hora_desde		hora inicial de la reserva
	@param	hora_hasta		hora donde finaliza la reserva
	@param	valor_hora		valor hora de la reserva de sum
*/
CREATE OR ALTER PROCEDURE solNorte.crear_reserva_sum
    @fecha_reserva DATETIME,
    @hora_desde TIME,
    @hora_hasta TIME,
    @valor_hora DECIMAL(8,2)
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO solNorte.reserva_sum (
        fecha_reserva, 
        hora_desde, 
        hora_hasta, 
        valor_hora
    )
    VALUES (
        @fecha_reserva,
        @hora_desde,
        @hora_hasta,
        @valor_hora
    );
END
GO


/**
	Este sp borra de manera lógica la reserva de sum
	@param	ID_reserva	id que identifica la reserva a borrar
*/
CREATE OR ALTER PROCEDURE solNorte.eliminar_reserva_sum
    @ID_reserva INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE solNorte.reserva_sum
    SET borrado = 1,
       fecha_borrado = GETDATE()
    WHERE ID_reserva = @ID_reserva;
END
GO

/**
	Este sp modifica un registro de reserva_sum
	@param	ID_reserva		id para identificar el registro que se quiere modificar
	@param	fecha_reserva	fecha para la cual se reserva el sum, no de cuando se efectúa la transacción de la reserva como tal
	@param	hora_desde		hora inicial de la reserva
	@param	hora_hasta		hora donde finaliza la reserva
	@param	valor_hora		valor hora de la reserva de sum
	@param	id_socio		por si se desea cambiar el socio a cargo de la reserva por algún motivo
*/
CREATE OR ALTER PROCEDURE solNorte.modificar_reserva_sum
    @ID_reserva INT,
    @fecha_reserva DATETIME,
    @hora_desde TIME,
    @hora_hasta TIME,
    @valor_hora DECIMAL(8,2),
    @id_socio INT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE solNorte.reserva_sum
    SET fecha_reserva = @fecha_reserva,
        hora_desde = @hora_desde,
        hora_hasta = @hora_hasta,
        valor_hora = @valor_hora,
        id_socio = @id_socio
    WHERE ID_reserva = @ID_reserva;
END
GO


--=====================================================Entrada pileta=====================================================--
/**
	Este sp da de alta una entrada de pileta, las validaciones de campos están hechas con checks en la tabla entrada_pileta a la que se hace referencia
	Acá solo validamos que el monto para invitado y socio sean indicados uno sí y el otro no, siempre un monto debe ser indicado, unicamente uno de ellos.
	@param	fecha_entrada			fecha donde se compra la entrada
	@param	monto_socio				opcional, si es indicado, representa el costo de la entrada para un socio, no pueden ser indicados ambos al mismo tiempo.
	@param	monto_invitado			opcional, si es indicado, representa el costo de la entrada para un invitado, no pueden ser indicados ambos al mismo tiempo.
	@param	tipo_entrada_invitado	indica de manera más clara, textual, de si la entrada es emitida para un socio o un invitado.
	@param	id_socio				socio asociado a la entrada, no le vendemos directamente entradas a un invitado, sino siempre a un socio.
*/
CREATE OR ALTER PROCEDURE solNorte.crear_entrada_pileta
    @fecha_entrada DATETIME,
    @monto_socio DECIMAL(10,2),
    @monto_invitado DECIMAL(8,2),
    @tipo_entrada_pileta CHAR(8),
    @id_socio INT
AS
BEGIN
    SET NOCOUNT ON;

	IF (@monto_invitado IS NOT NULL AND @monto_socio IS NOT NULL)
	BEGIN
		RAISERROR('No deben ser indicados ambos montos al mismo tiempo, solo permitimos uno.', 16,1);
	END

	IF(@monto_invitado IS NULL AND @monto_socio IS NULL)
		BEGIN
		RAISERROR('Al menos uno de los montos debe ser establecido.', 16,1);
	END

    INSERT INTO solNorte.entrada_pileta (
        fecha_entrada,
        monto_socio,
        monto_invitado,
        tipo_entrada_pileta,
        id_socio
    )
    VALUES (
        @fecha_entrada,
        @monto_socio,
        @monto_invitado,
        @tipo_entrada_pileta,
        @id_socio
    );
END
GO

/**
	No tiene sentido que una entrada pueda modificarse 
**/

--=====================================================Reembolso=====================================================--
/**
	Da de alta un reembolso 
	Valida que no haya un reembolso existente para la factura dada, ya que en el DER solo permitimos un reembolso para cada factura
	Valida que la factura exista y no esté anulada
	Valida que el monto del reembolso no sobrepase al monto de la factura.
	Valida que la fecha del reembolso no sea anterior a la fecha de emisión de la factura, tampoco que sea una fecha a futuro (mayor a la de HOY)
	@motivo_reembolso		motivo del reembolso
	@monto					monto reembolsado
	@id_factura				factura a la cuál se asociará el reembolso
	@fecha_reembolso		fecha de cuando se realiza dicho reembolso
	@returns				-1 si el reembolso no pudo ser creado, 1 si fue creado exitosamente.
*/
CREATE OR ALTER PROCEDURE solNorte.alta_reembolso 
	@motivo_reembolso CHAR(30), 
	@monto DECIMAL(8,2),
	@id_factura INT,
	@fecha_reembolso DATETIME
AS
BEGIN


	SET NOCOUNT ON;

	IF (@motivo_reembolso IS NULL OR LTRIM(RTRIM(@motivo_reembolso)) = '')
	BEGIN
		RAISERROR('El motivo del reembolso no puede ser nulo ni vacío.', 16, 1);
		RETURN -1;
	END


	DECLARE @fecha_factura DATETIME,
			@monto_factura DECIMAL(8,2),
			@anulada BIT;

	SELECT @fecha_factura = factura.fecha_emision,
		   @monto_factura = factura.importe_total,  
		   @anulada = factura.anulada
	FROM solNorte.factura
	WHERE ID_factura = @id_factura;


	IF (@fecha_factura IS NULL)
	BEGIN
		RAISERROR('ERROR al generar reembolso, no existe factura con ese ID %d.', 16, 1, @id_factura);
		RETURN -1;
	END

	IF EXISTS (SELECT 1 FROM solNorte.reembolso 
				WHERE reembolso.id_factura = @id_factura AND reembolso.borrado = 0)
	BEGIN
		RAISERROR('Error al generar reembolso, ya existe un reembolso asociado a esta factura',16,1);
		RETURN -1;
	END

	IF (@anulada = 1)
	BEGIN
		RAISERROR('Error al generar reembolso, no se pueden hacer reembolsos sobre una factura anulada, la misma no tiene validez!',16,1);
		RETURN -1;
	END

	IF (@monto > @monto_factura)
	BEGIN
		RAISERROR('Error al generar reembolso, monto del reembolso no puede superar el monto total de la factura.', 16, 1);
		RETURN -1;
	END

	IF (@fecha_reembolso < @fecha_factura OR @fecha_reembolso > GETDATE())
	BEGIN
		RAISERROR('Error al generar el reembolso, la fecha del reembolso debe estar entre la fecha de emisión de la factura y hoy.', 16, 1);
		RETURN -1;
	END
	

	INSERT INTO solNorte.reembolso (motivo_reembolso, monto, id_factura, fecha_reembolso)
	VALUES (@motivo_reembolso, @monto, @id_factura, @fecha_reembolso);
	
	RETURN 1;
END
