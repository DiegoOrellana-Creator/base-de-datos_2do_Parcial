-- =====================================================================
-- Sistema Web para la Gestión de Citas Médicas — Clínica Santa Cruz
-- Script de consultas para la base de datos «clinica_db» (PostgreSQL)
--
-- Basado en el esquema de clinica_db_postgres.sql (migraciones de Laravel).
-- Las consultas 1 a 8 usan una sola tabla; las consultas 9 a 20 combinan
-- tres o más tablas. Los valores de ejemplo (fechas, CI, identificadores)
-- están marcados con el comentario «-- parámetro» para reemplazarlos.
-- Uso:  psql -U <usuario> -d clinica_db -f clinica_db_consultas.sql
-- =====================================================================


-- =====================================================================
-- CONSULTAS DE UNA TABLA
-- =====================================================================

-- 1. Especialidades activas en orden alfabético (RF04)
SELECT id_especialidad, nombre, descripcion
FROM especialidad
WHERE estado = 'Activo'
ORDER BY nombre;

-- 2. Usuarios activos con su edad calculada a partir de la fecha de nacimiento
SELECT id, ci, nombre || ' ' || apellido AS nombre_completo, email, username,
       DATE_PART('year', AGE(CURRENT_DATE, fecha_nacimiento))::INT AS edad
FROM users
WHERE estado = 'Activo'
ORDER BY apellido, nombre;

-- 3. Citas programadas o confirmadas para el día de hoy, en orden de hora
SELECT codigo, id_medico, id_paciente, hora_inicio, hora_fin, estado
FROM citas
WHERE fecha_cita = CURRENT_DATE
  AND estado IN ('Programada', 'Confirmada')
ORDER BY hora_inicio;

-- 4. Cantidad de citas por estado, con su porcentaje sobre el total (RF10, RF13)
SELECT estado,
       COUNT(*) AS cantidad,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS porcentaje
FROM citas
GROUP BY estado
ORDER BY cantidad DESC;

-- 5. Horarios de atención con su duración total y la cantidad de intervalos que generan (RF05)
SELECT id_horario, id_medico,
       CASE dia_semana WHEN 1 THEN 'Lunes' WHEN 2 THEN 'Martes' WHEN 3 THEN 'Miércoles'
                       WHEN 4 THEN 'Jueves' WHEN 5 THEN 'Viernes' WHEN 6 THEN 'Sábado'
                       ELSE 'Domingo' END AS dia,
       hora_inicio, hora_final, duracion_cita,
       (hora_final - hora_inicio) AS tiempo_atencion,
       FLOOR(EXTRACT(EPOCH FROM (hora_final - hora_inicio)) / 60 / COALESCE(duracion_cita, 30))::INT AS cantidad_intervalos
FROM horario_atencion
ORDER BY id_medico, dia_semana, hora_inicio;

-- 6. Citas canceladas en un período, con su motivo de cancelación (RF09)
SELECT codigo, fecha_cita, hora_inicio, motivo_cancelacion, fecha_cancelacion
FROM citas
WHERE estado = 'Cancelada'
  AND fecha_cita BETWEEN DATE '2026-11-01' AND DATE '2026-11-30'   -- parámetro
ORDER BY fecha_cancelacion DESC;

-- 7. Acciones registradas en la bitácora durante las últimas 24 horas (CU-16)
SELECT fecha_hora, id_usuario, accion, modulo, id_registro, ip
FROM bitacora
WHERE fecha_hora >= NOW() - INTERVAL '24 hours'
ORDER BY fecha_hora DESC;

-- 8. Cantidad de citas registradas por mes y por estado (RF13)
SELECT TO_CHAR(fecha_cita, 'YYYY-MM') AS mes,
       COUNT(*) FILTER (WHERE estado = 'Programada')   AS programadas,
       COUNT(*) FILTER (WHERE estado = 'Confirmada')   AS confirmadas,
       COUNT(*) FILTER (WHERE estado = 'Atendida')     AS atendidas,
       COUNT(*) FILTER (WHERE estado = 'Cancelada')    AS canceladas,
       COUNT(*) FILTER (WHERE estado = 'Inasistencia') AS inasistencias,
       COUNT(*) AS total
FROM citas
GROUP BY TO_CHAR(fecha_cita, 'YYYY-MM')
ORDER BY mes;


-- =====================================================================
-- CONSULTAS DE TRES O MÁS TABLAS
-- =====================================================================

-- 9. Usuarios con sus roles activos (users, usuario_rol, rol) — CU-01, CU-03
SELECT u.username, u.nombre || ' ' || u.apellido AS usuario, r.nombre AS rol,
       ur.fecha_asignacion, u.estado AS estado_cuenta
FROM users u
JOIN usuario_rol ur ON ur.id_usuario = u.id AND ur.estado = 'Activo'
JOIN rol r          ON r.id_rol = ur.id_rol
ORDER BY r.nombre, u.apellido;

-- 10. Permisos efectivos de un usuario según sus roles
--     (users, usuario_rol, rol, rol_permiso, permiso) — CU-01
SELECT DISTINCT u.username, r.nombre AS rol, p.codigo AS permiso, p.nombre AS descripcion
FROM users u
JOIN usuario_rol ur ON ur.id_usuario = u.id AND ur.estado = 'Activo'
JOIN rol r          ON r.id_rol = ur.id_rol
JOIN rol_permiso rp ON rp.id_rol = r.id_rol
JOIN permiso p      ON p.id_permiso = rp.id_permiso
WHERE u.username = 'recepcion01'   -- parámetro
ORDER BY r.nombre, p.codigo;

-- 11. Médicos con todas sus especialidades en una sola fila
--     (users, medico, especialidad_medico, especialidad) — RF03
SELECT m.codigo, m.matricula, u.nombre || ' ' || u.apellido AS medico, u.estado,
       STRING_AGG(e.nombre, ', ' ORDER BY e.nombre) AS especialidades
FROM medico m
JOIN users u                ON u.id = m.id_medico
JOIN especialidad_medico em ON em.id_medico = m.id_medico
JOIN especialidad e         ON e.id_especialidad = em.id_especialidad
GROUP BY m.codigo, m.matricula, u.nombre, u.apellido, u.estado
ORDER BY medico;

-- 12. Agenda de un médico para una fecha (citas, paciente, users, especialidad) — RF11
SELECT c.hora_inicio, c.hora_fin, c.codigo,
       up.nombre || ' ' || up.apellido AS paciente, e.nombre AS especialidad,
       c.estado, c.motivo
FROM citas c
JOIN paciente p     ON p.id_paciente = c.id_paciente
JOIN users up       ON up.id = p.id_paciente
JOIN especialidad e ON e.id_especialidad = c.id_especialidad
WHERE c.id_medico = 3                      -- parámetro
  AND c.fecha_cita = DATE '2026-11-15'     -- parámetro
ORDER BY c.hora_inicio;

-- 13. Historial de citas de un paciente buscado por CI
--     (users, paciente, citas, medico, especialidad) — RF12
SELECT c.fecha_cita, c.hora_inicio, c.codigo,
       um.nombre || ' ' || um.apellido AS medico, e.nombre AS especialidad,
       c.estado, c.fecha_creacion
FROM users up
JOIN paciente p     ON p.id_paciente = up.id
JOIN citas c        ON c.id_paciente = p.id_paciente
JOIN medico m       ON m.id_medico = c.id_medico
JOIN users um       ON um.id = m.id_medico
JOIN especialidad e ON e.id_especialidad = c.id_especialidad
WHERE up.ci = '1234567'                    -- parámetro
ORDER BY c.fecha_cita DESC, c.hora_inicio DESC;

-- 14. Citas por médico y especialidad en un período, con totales por estado
--     (citas, medico, users, especialidad) — RF13
SELECT u.nombre || ' ' || u.apellido AS medico, e.nombre AS especialidad,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE c.estado = 'Atendida')     AS atendidas,
       COUNT(*) FILTER (WHERE c.estado = 'Cancelada')    AS canceladas,
       COUNT(*) FILTER (WHERE c.estado = 'Inasistencia') AS inasistencias
FROM citas c
JOIN medico m       ON m.id_medico = c.id_medico
JOIN users u        ON u.id = m.id_medico
JOIN especialidad e ON e.id_especialidad = c.id_especialidad
WHERE c.fecha_cita BETWEEN DATE '2026-11-01' AND DATE '2026-11-30'   -- parámetro
GROUP BY u.nombre, u.apellido, e.nombre
ORDER BY total DESC;

-- 15. Ranking de médicos por citas atendidas (citas, medico, users)
SELECT RANK() OVER (ORDER BY COUNT(*) DESC) AS posicion,
       u.nombre || ' ' || u.apellido AS medico, m.codigo,
       COUNT(*) AS citas_atendidas
FROM citas c
JOIN medico m ON m.id_medico = c.id_medico
JOIN users u  ON u.id = m.id_medico
WHERE c.estado = 'Atendida'
GROUP BY u.nombre, u.apellido, m.codigo
ORDER BY posicion;

-- 16. Pacientes con dos o más inasistencias (citas, paciente, users) — RF10
SELECT u.ci, u.nombre || ' ' || u.apellido AS paciente, p.nro_ficha, u.telefono,
       COUNT(*) AS inasistencias, MAX(c.fecha_cita) AS ultima_inasistencia
FROM citas c
JOIN paciente p ON p.id_paciente = c.id_paciente
JOIN users u    ON u.id = p.id_paciente
WHERE c.estado = 'Inasistencia'
GROUP BY u.ci, u.nombre, u.apellido, p.nro_ficha, u.telefono
HAVING COUNT(*) >= 2
ORDER BY inasistencias DESC;

-- 17. Detección de citas superpuestas de un mismo médico (citas ×2, medico, users) — RF07, RN07
SELECT u.nombre || ' ' || u.apellido AS medico, c1.fecha_cita,
       c1.codigo AS cita_1, c1.hora_inicio AS inicio_1, c1.hora_fin AS fin_1,
       c2.codigo AS cita_2, c2.hora_inicio AS inicio_2, c2.hora_fin AS fin_2
FROM citas c1
JOIN citas c2 ON c2.id_medico = c1.id_medico
             AND c2.fecha_cita = c1.fecha_cita
             AND c2.id_cita > c1.id_cita
             AND c2.hora_inicio < c1.hora_fin
             AND c2.hora_fin > c1.hora_inicio
JOIN medico m ON m.id_medico = c1.id_medico
JOIN users u  ON u.id = m.id_medico
WHERE c1.estado <> 'Cancelada' AND c2.estado <> 'Cancelada'
ORDER BY c1.fecha_cita, c1.hora_inicio;

-- 18. Horarios disponibles de un médico en una fecha
--     (horario_atencion, medico, users, citas) — CU-08
--     Genera los intervalos según la duración configurada y descarta los ocupados.
WITH parametros AS (
    SELECT 3 AS id_medico, DATE '2026-11-16' AS fecha          -- parámetro
),
intervalos AS (
    SELECT h.id_medico, pr.fecha,
           g.inicio::TIME AS hora_inicio,
           (g.inicio + MAKE_INTERVAL(mins => COALESCE(h.duracion_cita, 30)))::TIME AS hora_fin
    FROM parametros pr
    JOIN horario_atencion h ON h.id_medico = pr.id_medico
                           AND h.dia_semana = EXTRACT(ISODOW FROM pr.fecha)
    CROSS JOIN LATERAL GENERATE_SERIES(
        pr.fecha + h.hora_inicio,
        pr.fecha + h.hora_final - MAKE_INTERVAL(mins => COALESCE(h.duracion_cita, 30)),
        MAKE_INTERVAL(mins => COALESCE(h.duracion_cita, 30))
    ) AS g(inicio)
)
SELECT u.nombre || ' ' || u.apellido AS medico, i.fecha, i.hora_inicio, i.hora_fin
FROM intervalos i
JOIN medico m ON m.id_medico = i.id_medico
JOIN users u  ON u.id = m.id_medico AND u.estado = 'Activo'
WHERE i.fecha >= CURRENT_DATE
  AND NOT EXISTS (
        SELECT 1 FROM citas c
        WHERE c.id_medico = i.id_medico
          AND c.fecha_cita = i.fecha
          AND c.estado <> 'Cancelada'
          AND c.hora_inicio < i.hora_fin
          AND c.hora_fin > i.hora_inicio)
ORDER BY i.hora_inicio;

-- 19. Historial de cambios de estado de las citas con el usuario que los registró
--     (historial_estado_cita, citas, users) — RF10
SELECT c.codigo, h.fecha_hora, COALESCE(h.estado_anterior, '(nueva)') AS estado_anterior,
       h.estado_nuevo, h.motivo,
       COALESCE(u.nombre || ' ' || u.apellido, 'Sistema') AS registrado_por
FROM historial_estado_cita h
JOIN citas c      ON c.id_cita = h.id_cita
LEFT JOIN users u ON u.id = h.registrado_por
ORDER BY c.codigo, h.fecha_hora;

-- 20. Actividad de la bitácora por rol y módulo en los últimos 30 días
--     (bitacora, users, usuario_rol, rol) — CU-16
SELECT r.nombre AS rol, b.modulo, b.accion, COUNT(*) AS cantidad,
       MAX(b.fecha_hora) AS ultima_vez
FROM bitacora b
JOIN users u        ON u.id = b.id_usuario
JOIN usuario_rol ur ON ur.id_usuario = u.id
JOIN rol r          ON r.id_rol = ur.id_rol
WHERE b.fecha_hora >= NOW() - INTERVAL '30 days'
GROUP BY r.nombre, b.modulo, b.accion
ORDER BY cantidad DESC;

-- 21. Médicos activos sin horario de atención registrado
--     (medico, users, especialidad_medico, horario_atencion) — CU-07
SELECT m.codigo, u.nombre || ' ' || u.apellido AS medico,
       COUNT(DISTINCT em.id_especialidad) AS especialidades_asignadas
FROM medico m
JOIN users u                     ON u.id = m.id_medico AND u.estado = 'Activo'
LEFT JOIN especialidad_medico em ON em.id_medico = m.id_medico
LEFT JOIN horario_atencion h     ON h.id_medico = m.id_medico
WHERE h.id_horario IS NULL
GROUP BY m.codigo, u.nombre, u.apellido
ORDER BY medico;
