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
	)
END

