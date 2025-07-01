/*
====================================================================================
 Archivo		: Reportes.sql
 Proyecto		: Institución Deportiva Sol Norte.
 Descripción	: Scripts para generar reportes.
 Autor			: G10
 Fecha entrega	: 2025-07-01
====================================================================================
*/

USE Com2900G10
GO



----------------------------------------------------------------------------------------------------------------
-- REPORTE 1: Socios Morosos
----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'Reporte_SociosMorosos_XML') 
BEGIN
    DROP PROCEDURE rep.Reporte_SociosMorosos_XML;
END;
GO

CREATE OR ALTER PROCEDURE rep.Reporte_SociosMorosos_XML
    @fecha_desde DATE,
    @fecha_hasta DATE
AS
BEGIN
    SET NOCOUNT ON;

    --facturas que no fueron pagadas entre fechas indicadas
    WITH cte_morosidad AS (
        SELECT
            f.id_socio,
            s.nombre,
            s.apellido,
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_incumplido --usar format? es cómo convert? se pierde eficiencia?
        FROM solNorte.factura f										--YEAR(f.fecha_emision) AS anio_incumplido, MONTH(f.fecha_emision) AS mes_incumplido
        INNER JOIN solNorte.socio s ON f.id_socio = s.ID_socio
        WHERE 
            f.fecha_emision BETWEEN @fecha_desde AND @fecha_hasta
            AND f.estado = 'VENCIDA'
            AND f.anulada = 0
            AND s.borrado = 0
    ),
    
    cte_listado AS (
        SELECT 
            id_socio,
            nombre,
            apellido,
            mes_incumplido,
            COUNT(*) OVER (PARTITION BY id_socio) AS total_moras
        FROM cte_morosidad
    )

    -- Resultado final como XML
    SELECT
        'Morosos Recurrentes' AS nombre_reporte,
        @fecha_desde AS periodo_desde,
        @fecha_hasta AS periodo_hasta,
        id_socio,
        nombre + ', ' + apellido AS nombre_apellido,
        mes_incumplido,
        total_moras
    FROM cte_listado
    WHERE total_moras > 2
    ORDER BY total_moras DESC, nombre_apellido
    FOR XML PATH('moroso'), ROOT('MorososRecurrentes'), TYPE;
END;
GO

----------------------------------------------------------------------------------------------------------------
-- REPORTE 2: Ingresos Mensuales
----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'Reporte_IngresosMensuales_XML') 
BEGIN
    DROP PROCEDURE rep.Reporte_IngresosMensuales_XML;
END;
GO

CREATE OR ALTER PROCEDURE rep.Reporte_IngresosMensuales_XML
AS
BEGIN
    SET NOCOUNT ON;

    WITH ingresos AS (
        SELECT
            a.nombre_actividad,
            YEAR(f.fecha_emision) AS anio,
            MONTH(f.fecha_emision) AS mes,
            DATENAME(MONTH, f.fecha_emision) AS nombre_mes,
            SUM(df.subtotal) AS ingreso_mensual
        FROM solNorte.factura f
        INNER JOIN solNorte.detalle_factura df 
            ON f.ID_factura = df.id_factura AND df.borrado = 0
        INNER JOIN solNorte.detalle_factura_actividad dfa 
            ON df.ID_detalle_factura = dfa.ID_detalle_factura
        INNER JOIN solNorte.actividad a 
            ON dfa.ID_actividad = a.ID_actividad AND a.borrado = 0
        WHERE 
            f.estado = 'PAGADA'
            AND f.anulada = 0
            AND f.fecha_emision >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
            AND f.fecha_emision <= GETDATE()
        GROUP BY 
            a.nombre_actividad,
            YEAR(f.fecha_emision),
            MONTH(f.fecha_emision),
            DATENAME(MONTH, f.fecha_emision)
    ),
    acumulado AS (
        SELECT 
            nombre_actividad,
            SUM(ingreso_mensual) AS total_anual
        FROM ingresos
        GROUP BY nombre_actividad
    )
    SELECT 
        i.nombre_actividad,
        i.anio,
        i.mes,
        i.nombre_mes,
        i.ingreso_mensual,
        a.total_anual
    FROM ingresos i
    INNER JOIN acumulado a ON i.nombre_actividad = a.nombre_actividad
    ORDER BY i.nombre_actividad, i.anio, i.mes
    FOR XML PATH('mes'), ROOT('reporte_ingresos'), ELEMENTS;
END;
GO

----------------------------------------------------------------------------------------------------------------
-- REPORTE 3: Inasistencias por Categoria y Actividad
----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'Reporte_Inasistencias_XML')
BEGIN
    DROP PROCEDURE Rep.Reporte_Inasistencias_XML;
END;
GO

CREATE OR ALTER PROCEDURE rep.Reporte_Inasistencias_XML
AS
BEGIN
	SET NOCOUNT ON;

	SELECT s.categoria_socio, a.nombre_actividad,
		   COUNT(*) as cantidad_inasistencias
	FROM solNorte.asistencia asi
	INNER JOIN solNorte.inscripcion_actividad ia ON asi.id_inscripcion_actividad = ia.ID_inscripcion
	INNER JOIN solNorte.socio s ON ia.id_socio = s.ID_socio
	INNER JOIN solNorte.actividad a ON ia.id_actividad = a.ID_actividad
	-- aca hay que usar el campo presentismo
	WHERE asi.presentismo in ('A', 'J')
		AND asi.borrado = 0
		AND s.borrado = 0
		AND a.borrado = 0
	GROUP BY s.categoria_socio, a.nombre_actividad
	ORDER BY cantidad_inasistencias DESC;
	FOR XML PATH('inasistencia'), ROOT('reporte_inasistencias');
END;
GO


----------------------------------------------------------------------------------------------------------------
-- REPORTE 4: Socios con Inasistencias
----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'Reporte_SociosConInasistencias')
BEGIN
    DROP PROCEDURE Rep.Reporte_SociosConInasistencias;
END;
GO

CREATE OR ALTER rep.Reporte_SociosConInasistencias
AS
BEGIN
	SET NOCOUNT ON; -- este a reviar. yo creo que esta bien, alcanza con evaluar una vez asistio = 0

    SELECT
        s.nombre,
        s.apellido,
        DATEDIFF(YEAR, s.fecha_nacimiento, GETDATE()) AS edad,
        s.categoria_socio,
        a.nombre_actividad
    FROM solNorte.asistencia asi
    INNER JOIN solNorte.inscripcion_actividad ia ON asi.id_inscripcion_actividad = ia.ID_inscripcion
    INNER JOIN solNorte.socio s ON ia.id_socio = s.ID_socio
    INNER JOIN solNorte.actividad a ON ia.id_actividad = a.ID_actividad
    WHERE asi.presentismo in ('A', 'J')
        AND asi.borrado = 0
        AND s.borrado = 0
        AND a.borrado = 0
    GROUP BY s.nombre, s.apellido, s.fecha_nacimiento, s.categoria_socio, a.nombre_actividad
    FOR XML PATH('socio'), ROOT('reporte_socios_con_inasistencias');
END;
GO