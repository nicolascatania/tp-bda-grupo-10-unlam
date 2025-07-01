USE Com2900G10
GO
--=======================================================PRUEBAS PARA ALTA DE GRUPO FAMILIAR=======================================================--
-- 1. alta valida
DECLARE @id_nuevo INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 1, @ID_grupo_familiar = @id_nuevo OUTPUT;
SELECT * FROM solNorte.grupo_familiar WHERE ID_grupo_familiar = @id_nuevo;

-- 2. error por cantidad 0
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 0, @ID_grupo_familiar = @id_nuevo OUTPUT;

--=======================================================PRUEBAS PARA MODIFICAR GRUPO FAMILIAR=======================================================--
-- 1. alta de integrante
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 1, @accion = 'ALTA';

-- 2. baja de integrante
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 1, @accion = 'BAJA';

-- 3. baja invalida si cantidad ya esta en 0
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 99, @accion = 'BAJA';

-- 4. accion invalida
EXEC solNorte.modificar_grupo_familiar @ID_grupo_familiar = 1, @accion = 'OTRO';

--=======================================================PRUEBAS PARA BAJA DE GRUPO FAMILIAR=======================================================--
-- 1. dar de baja un grupo existente
EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = 1;

-- 2. grupo ya dado de baja
EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = 1;

-- 3. grupo inexistente
EXEC solNorte.baja_grupo_familiar @ID_grupo_familiar = 9999;

--=======================================================PRUEBAS PARA ALTA DE SOCIO=======================================================--
-- 1. alta socio mayor (responsable)
EXEC solNorte.alta_socio
    @nombre = 'Pedro', @apellido = 'Gomez', @fecha_nacimiento = '2000-01-01',
    @DNI = 12345678, @telefono = '1133344555', @telefono_de_emergencia = '1144556677',
    @obra_social = 'OSDE', @nro_obra_social = 'XYZ123',
    @email = 'pedro@mail.com';

-- 2. alta menor con grupo y responsable existente
EXEC solNorte.alta_socio
    @nombre = 'Juan', @apellido = 'Gomez', @fecha_nacimiento = '2015-06-01',
    @DNI = 23456789, @telefono = '1133344555',
    @id_responsable_a_cargo = 1, @id_grupo_familiar = 1;

-- 3. alta de menor sin grupo familiar
EXEC solNorte.alta_socio
    @nombre = 'Tomás', @apellido = 'Pérez', @fecha_nacimiento = '2010-06-01',
    @DNI = 34567890, @telefono = '1133344555';

--=======================================================PRUEBAS PARA MODIFICAR SOCIO=======================================================--
-- 1. modificar nombre, telefono y mail
EXEC solNorte.modificar_socio
    @ID_socio = 1, @nombre = 'Pedro Manuel', @apellido = 'Gomez',
    @fecha_nacimiento = '2000-01-01', @DNI = 12345678, @telefono = '1199988877',
    @email = 'pedronuevo@mail.com';

--socio no existe
EXEC solNorte.modificar_socio @ID_socio = 999, @nombre = 'Juan', ... ;

--2. CAMBIO GRUPO FAMILIAR
--creo grupo origen
DECLARE @grupoA INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 1, @ID_grupo_familiar = @grupoA OUTPUT;

--creo grupo destino
DECLARE @grupoB INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 0, @ID_grupo_familiar = @grupoB OUTPUT;

--alta de socio asignado a grupo origen
EXEC solNorte.alta_socio
    @nombre = 'Carlos', @apellido = 'Sanchez', @fecha_nacimiento = '1985-04-10',
    @DNI = 55555555, @telefono = '1122334455', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = '123',
    @email = 'carlos@mail.com',
    @id_grupo_familiar = @grupoA;

--buscar el ID del socio recien creado
DECLARE @id_socio INT;
SELECT @id_socio = ID_socio FROM solNorte.socio WHERE DNI = 55555555;

--modificar socio cambiandolo a grupo destino
EXEC solNorte.modificar_socio
    @ID_socio = @id_socio,
    @nombre = 'Carlos', @apellido = 'Sanchez',
    @fecha_nacimiento = '1985-04-10', @DNI = 55555555,
    @telefono = '1122334455', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = '123',
    @email = 'carlos@mail.com',
    @id_grupo_familiar = @grupoB;

--verificamos resultado
SELECT ID_grupo_familiar, cantidad_integrantes, borrado FROM solNorte.grupo_familiar
WHERE ID_grupo_familiar IN (@grupoA, @grupoB);


--=======================================================PRUEBAS PARA MODIFICAR SOCIO=======================================================--
-- 1. dar de baja a un socio sin menores
EXEC solNorte.baja_socio @ID_socio = 1;

-- 2. dar de baja a socio responsable único con menores
EXEC solNorte.baja_socio @ID_socio = 2;

-- 3. baja con transferencia de responsabilidad a otro mayor
--alta grupo familiar
DECLARE @grupoC INT;
EXEC solNorte.alta_grupo_familiar @cantidad_integrantes = 0, @ID_grupo_familiar = @grupoC OUTPUT;

--alta socio mayor (actual responsable)
EXEC solNorte.alta_socio
    @nombre = 'Laura', @apellido = 'Torres', @fecha_nacimiento = '1980-05-01',
    @DNI = 60000001, @telefono = '1111111111', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = 'ABC123',
    @email = 'laura@mail.com',
    @id_grupo_familiar = @grupoC;

--alta socio mayor nuevo en mismo grupo
EXEC solNorte.alta_socio
    @nombre = 'Lucía', @apellido = 'Torres', @fecha_nacimiento = '1982-02-01',
    @DNI = 60000002, @telefono = '1111111112', @telefono_de_emergencia = '1122334455',
    @obra_social = 'OSDE', @nro_obra_social = 'ABC124',
    @email = 'lucia@mail.com',
    @id_grupo_familiar = @grupoC;

--bbtener IDs
DECLARE @id_responsable INT, @id_nueva INT;
SELECT @id_responsable = ID_socio FROM solNorte.socio WHERE DNI = 60000001;
SELECT @id_nueva = ID_socio FROM solNorte.socio WHERE DNI = 60000002;

--alta menor a cargo de @id_responsable
EXEC solNorte.alta_socio
    @nombre = 'Emilia', @apellido = 'Torres', @fecha_nacimiento = '2015-09-15',
    @DNI = 60000003, @telefono = '1111111113',
    @id_responsable_a_cargo = @id_responsable,
    @id_grupo_familiar = @grupoC;

--baja de socio mayor responsable
EXEC solNorte.baja_socio @ID_socio = @id_responsable;

--verificar si el nuevo mayor asume responsabilidad
SELECT ID_socio, nombre, es_responsable
FROM solNorte.socio
WHERE ID_socio IN (@id_nueva);

