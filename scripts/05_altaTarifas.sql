USE Com2900G10;
GO

--cargo tarifas
SELECT * FROM solNorte.actividad;
GO

INSERT INTO solNorte.actividad (nombre_actividad, costo_mensual) 
	VALUES 
            ('FUTSAL', 25000.00),
            ('VOLEY', 30000.00),
            ('TAEKWONDO', 25000.00),
            ('BAILE ARTISTICO', 30000.00),
            ('NATACION', 45000.00),
            ('AJEDREZ', 2000.00);
GO


SELECT * FROM solNorte.actividad;
GO


