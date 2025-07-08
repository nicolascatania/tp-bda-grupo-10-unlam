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

    WITH facturas_morosas AS (
        SELECT 
            f.id_socio,
            s.nombre,
            s.apellido,
            FORMAT(f.fecha_emision, 'yyyy-MM') AS mes_incumplido
        FROM solNorte.factura f
        INNER JOIN solNorte.socio s ON f.id_socio = s.ID_socio
        WHERE 
            f.fecha_emision BETWEEN @fecha_desde AND @fecha_hasta
            AND f.estado = 'VENCIDA'
            AND f.anulada = 0
            AND s.borrado = 0
    ),
    morosidad_con_ranking AS (
        SELECT 
            *,
            COUNT(*) OVER (PARTITION BY id_socio) AS ranking_morosidad
        FROM facturas_morosas
    ),
    morosos_filtrados AS (
        SELECT DISTINCT 
            id_socio,
            nombre,
            apellido,
            mes_incumplido,
            ranking_morosidad
        FROM morosidad_con_ranking
        WHERE ranking_morosidad > 2
    )
    SELECT
        @fecha_desde AS periodo_desde,
        @fecha_hasta AS periodo_hasta,
        id_socio,
        nombre + ', ' + apellido AS nombre_apellido,
        mes_incumplido,
        ranking_morosidad
    FROM morosos_filtrados
    ORDER BY ranking_morosidad DESC, nombre_apellido, mes_incumplido
    FOR XML PATH('moroso'), ROOT('MorososRecurrentes'), TYPE;
END;
GO

DECLARE @fd DATE = '2024-01-01';
DECLARE @fh DATE = '2024-12-31';
EXEC rep.Reporte_SociosMorosos_XML
    @fecha_desde = @fd,
    @fecha_hasta = @fh;
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
    SET LANGUAGE Spanish;

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
    )
    SELECT 
        anio,
        mes,
        nombre_mes,
        (
            SELECT 
                RTRIM(nombre_actividad),
                ingreso_mensual
            FROM ingresos i2
            WHERE i2.anio = i1.anio AND i2.mes = i1.mes
            FOR XML PATH('actividad'), TYPE
        ) AS actividades
    FROM ingresos i1
    GROUP BY anio, mes, nombre_mes
    ORDER BY anio, mes
    FOR XML PATH('mes'), ROOT('reporte_ingresos'), ELEMENTS;
END;
GO


EXEC rep.Reporte_IngresosMensuales_XML;
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

    SELECT 
        RTRIM(s.categoria_socio) AS categoria_socio, 
        RTRIM(a.nombre_actividad) AS nombre_actividad,
        COUNT(*) AS cantidad_inasistencias
    FROM solNorte.asistencia asi
    INNER JOIN solNorte.inscripcion_actividad ia ON asi.id_inscripcion_actividad = ia.ID_inscripcion
    INNER JOIN solNorte.socio s ON ia.id_socio = s.ID_socio
    INNER JOIN solNorte.actividad a ON ia.id_actividad = a.ID_actividad
    WHERE asi.presentismo IN ('A', 'J') 
        AND asi.borrado = 0
        AND s.borrado = 0
        AND a.borrado = 0
    GROUP BY RTRIM(s.categoria_socio), RTRIM(a.nombre_actividad)
    ORDER BY cantidad_inasistencias DESC
    FOR XML PATH('inasistencia'), ROOT('reporte_inasistencias');
END;
GO

EXEC rep.Reporte_Inasistencias_XML;
GO
----------------------------------------------------------------------------------------------------------------
-- REPORTE 4: Socios con Inasistencias
----------------------------------------------------------------------------------------------------------------

IF EXISTS (SELECT * FROM sys.procedures WHERE name = 'Reporte_SociosConInasistencias')
BEGIN
    DROP PROCEDURE rep.Reporte_SociosConInasistencias;
END;
GO

CREATE OR ALTER PROCEDURE rep.Reporte_SociosConInasistencias
AS
BEGIN
	SET NOCOUNT ON; 

    SELECT
        s.nombre,
        s.apellido,
        DATEDIFF(YEAR, s.fecha_nacimiento, GETDATE()) AS edad,
        RTRIM(s.categoria_socio) AS categoria_socio,
        RTRIM(a.nombre_actividad) AS nombre_actividad
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


EXEC rep.Reporte_SociosConInasistencias;
GO