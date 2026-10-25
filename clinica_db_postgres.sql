-- =====================================================================
-- Sistema Web para la Gestión de Citas Médicas — Clínica Santa Cruz
-- Script PostgreSQL de la base de datos «clinica_db»
--
-- Generado a partir de las migraciones de Laravel del proyecto «2do_Clinica»:
--   0001_01_01_000000_create_users_table.php
--   0001_01_01_000001_create_cache_table.php
--   0001_01_01_000002_create_jobs_table.php
--   2026_10_23_191317_create_clinica_tablas.php
-- Los nombres de restricciones e índices siguen la convención de Laravel.
-- Uso:  psql -U <usuario> -d clinica_db -f clinica_db_postgres.sql
-- =====================================================================

-- Para crear la base de datos desde cero (ejecutar conectado a «postgres»):
-- CREATE DATABASE clinica_db WITH ENCODING 'UTF8';
-- \c clinica_db

BEGIN;

-- ---------------------------------------------------------------------
-- Tabla de control de migraciones de Laravel
-- ---------------------------------------------------------------------
CREATE TABLE migrations (
    id        SERIAL PRIMARY KEY,
    migration VARCHAR(255) NOT NULL,
    batch     INTEGER NOT NULL
);

-- ---------------------------------------------------------------------
-- 0001_01_01_000000_create_users_table
-- ---------------------------------------------------------------------
CREATE TABLE users (
    id               BIGSERIAL PRIMARY KEY,
    ci               VARCHAR(20),
    nombre           VARCHAR(100) NOT NULL,
    apellido         VARCHAR(100) NOT NULL,
    telefono         VARCHAR(20),
    email            VARCHAR(100) NOT NULL,
    estado           VARCHAR(20) NOT NULL DEFAULT 'Activo',
    direccion        TEXT,
    password         VARCHAR(255) NOT NULL,
    sexo             VARCHAR(15),
    fecha_nacimiento DATE,
    username         VARCHAR(50) NOT NULL,
    created_at       TIMESTAMP(0) WITHOUT TIME ZONE,
    updated_at       TIMESTAMP(0) WITHOUT TIME ZONE,
    CONSTRAINT users_ci_unique       UNIQUE (ci),
    CONSTRAINT users_email_unique    UNIQUE (email),
    CONSTRAINT users_username_unique UNIQUE (username)
);

CREATE TABLE password_reset_tokens (
    email      VARCHAR(255) PRIMARY KEY,
    token      VARCHAR(255) NOT NULL,
    created_at TIMESTAMP(0) WITHOUT TIME ZONE
);

CREATE TABLE sessions (
    id            VARCHAR(255) PRIMARY KEY,
    user_id       BIGINT,
    ip_address    VARCHAR(45),
    user_agent    TEXT,
    payload       TEXT NOT NULL,
    last_activity INTEGER NOT NULL
);
CREATE INDEX sessions_user_id_index       ON sessions (user_id);
CREATE INDEX sessions_last_activity_index ON sessions (last_activity);

-- ---------------------------------------------------------------------
-- 0001_01_01_000001_create_cache_table
-- ---------------------------------------------------------------------
CREATE TABLE cache (
    key        VARCHAR(255) PRIMARY KEY,
    value      TEXT NOT NULL,
    expiration INTEGER NOT NULL
);
CREATE INDEX cache_expiration_index ON cache (expiration);

CREATE TABLE cache_locks (
    key        VARCHAR(255) PRIMARY KEY,
    owner      VARCHAR(255) NOT NULL,
    expiration INTEGER NOT NULL
);
CREATE INDEX cache_locks_expiration_index ON cache_locks (expiration);

-- ---------------------------------------------------------------------
-- 0001_01_01_000002_create_jobs_table
-- ---------------------------------------------------------------------
CREATE TABLE jobs (
    id           BIGSERIAL PRIMARY KEY,
    queue        VARCHAR(255) NOT NULL,
    payload      TEXT NOT NULL,
    attempts     SMALLINT NOT NULL,
    reserved_at  INTEGER,
    available_at INTEGER NOT NULL,
    created_at   INTEGER NOT NULL
);
CREATE INDEX jobs_queue_index ON jobs (queue);

CREATE TABLE job_batches (
    id             VARCHAR(255) PRIMARY KEY,
    name           VARCHAR(255) NOT NULL,
    total_jobs     INTEGER NOT NULL,
    pending_jobs   INTEGER NOT NULL,
    failed_jobs    INTEGER NOT NULL,
    failed_job_ids TEXT NOT NULL,
    options        TEXT,
    cancelled_at   INTEGER,
    created_at     INTEGER NOT NULL,
    finished_at    INTEGER
);

CREATE TABLE failed_jobs (
    id         BIGSERIAL PRIMARY KEY,
    uuid       VARCHAR(255) NOT NULL,
    connection TEXT NOT NULL,
    queue      TEXT NOT NULL,
    payload    TEXT NOT NULL,
    exception  TEXT NOT NULL,
    failed_at  TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT failed_jobs_uuid_unique UNIQUE (uuid)
);

-- ---------------------------------------------------------------------
-- 2026_10_23_191317_create_clinica_tablas
-- ---------------------------------------------------------------------

-- 1. Tablas independientes
CREATE TABLE rol (
    id_rol      BIGSERIAL PRIMARY KEY,
    nombre      VARCHAR(50) NOT NULL,
    descripcion TEXT
);

CREATE TABLE permiso (
    id_permiso BIGSERIAL PRIMARY KEY,
    codigo     VARCHAR(50) NOT NULL,
    nombre     VARCHAR(100) NOT NULL,
    CONSTRAINT permiso_codigo_unique UNIQUE (codigo)
);

CREATE TABLE especialidad (
    id_especialidad BIGSERIAL PRIMARY KEY,
    nombre          VARCHAR(100) NOT NULL,
    descripcion     TEXT,
    estado          VARCHAR(20) NOT NULL DEFAULT 'Activo'
);

-- 2. Relaciones de usuarios y roles
CREATE TABLE rol_permiso (
    id_rol     BIGINT NOT NULL,
    id_permiso BIGINT NOT NULL,
    CONSTRAINT rol_permiso_pkey PRIMARY KEY (id_rol, id_permiso),
    CONSTRAINT rol_permiso_id_rol_foreign FOREIGN KEY (id_rol)
        REFERENCES rol (id_rol) ON DELETE CASCADE,
    CONSTRAINT rol_permiso_id_permiso_foreign FOREIGN KEY (id_permiso)
        REFERENCES permiso (id_permiso) ON DELETE CASCADE
);

CREATE TABLE usuario_rol (
    id_usuario       BIGINT NOT NULL,
    id_rol           BIGINT NOT NULL,
    fecha_asignacion TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    estado           VARCHAR(20) NOT NULL DEFAULT 'Activo',
    CONSTRAINT usuario_rol_pkey PRIMARY KEY (id_usuario, id_rol),
    CONSTRAINT usuario_rol_id_usuario_foreign FOREIGN KEY (id_usuario)
        REFERENCES users (id) ON DELETE CASCADE,
    CONSTRAINT usuario_rol_id_rol_foreign FOREIGN KEY (id_rol)
        REFERENCES rol (id_rol) ON DELETE CASCADE
);

-- 3. Subclases de usuario
CREATE TABLE preferencia_cuenta (
    id_usuario      BIGINT PRIMARY KEY,
    acepta_whatsapp BOOLEAN NOT NULL DEFAULT TRUE,
    acepta_correo   BOOLEAN NOT NULL DEFAULT TRUE,
    privacidad      TEXT,
    CONSTRAINT preferencia_cuenta_id_usuario_foreign FOREIGN KEY (id_usuario)
        REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE paciente (
    id_paciente  BIGINT PRIMARY KEY,
    nro_ficha    VARCHAR(50),
    inasistencia INTEGER NOT NULL DEFAULT 0,
    bloqueado    BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT paciente_nro_ficha_unique UNIQUE (nro_ficha),
    CONSTRAINT paciente_id_paciente_foreign FOREIGN KEY (id_paciente)
        REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE recepcionista (
    id_recepcionista BIGINT PRIMARY KEY,
    codigo           VARCHAR(50),
    CONSTRAINT recepcionista_codigo_unique UNIQUE (codigo),
    CONSTRAINT recepcionista_id_recepcionista_foreign FOREIGN KEY (id_recepcionista)
        REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE administrador (
    id_administrador BIGINT PRIMARY KEY,
    codigo           VARCHAR(50),
    CONSTRAINT administrador_codigo_unique UNIQUE (codigo),
    CONSTRAINT administrador_id_administrador_foreign FOREIGN KEY (id_administrador)
        REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE medico (
    id_medico BIGINT PRIMARY KEY,
    matricula VARCHAR(50),
    codigo    VARCHAR(50),
    CONSTRAINT medico_matricula_unique UNIQUE (matricula),
    CONSTRAINT medico_codigo_unique UNIQUE (codigo),
    CONSTRAINT medico_id_medico_foreign FOREIGN KEY (id_medico)
        REFERENCES users (id) ON DELETE CASCADE
);

-- 4. Dependientes de paciente
CREATE TABLE contacto_emergencia (
    id_contacto BIGSERIAL PRIMARY KEY,
    id_paciente BIGINT NOT NULL,
    nombre      VARCHAR(100) NOT NULL,
    parentesco  VARCHAR(50),
    telefono    VARCHAR(20),
    CONSTRAINT contacto_emergencia_id_paciente_foreign FOREIGN KEY (id_paciente)
        REFERENCES paciente (id_paciente) ON DELETE CASCADE
);

CREATE TABLE informacion_medica (
    id_paciente           BIGINT PRIMARY KEY,
    tipo_sangre           VARCHAR(10),
    alergias              TEXT,
    enfermedades_cronicas TEXT,
    medicamentos          TEXT,
    antecedentes          TEXT,
    CONSTRAINT informacion_medica_id_paciente_foreign FOREIGN KEY (id_paciente)
        REFERENCES paciente (id_paciente) ON DELETE CASCADE
);

CREATE TABLE bloqueo_paciente (
    id_bloqueo               BIGSERIAL PRIMARY KEY,
    id_paciente              BIGINT NOT NULL,
    fecha_bloqueo            TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_desbloqueo         TIMESTAMP(0) WITHOUT TIME ZONE,
    motivo                   TEXT,
    inasistencias_acumuladas INTEGER,
    CONSTRAINT bloqueo_paciente_id_paciente_foreign FOREIGN KEY (id_paciente)
        REFERENCES paciente (id_paciente) ON DELETE CASCADE
);

-- 5. Dependientes de médico
CREATE TABLE especialidad_medico (
    id_medico       BIGINT NOT NULL,
    id_especialidad BIGINT NOT NULL,
    CONSTRAINT especialidad_medico_pkey PRIMARY KEY (id_medico, id_especialidad),
    CONSTRAINT especialidad_medico_id_medico_foreign FOREIGN KEY (id_medico)
        REFERENCES medico (id_medico) ON DELETE CASCADE,
    CONSTRAINT especialidad_medico_id_especialidad_foreign FOREIGN KEY (id_especialidad)
        REFERENCES especialidad (id_especialidad) ON DELETE CASCADE
);

CREATE TABLE horario_atencion (
    id_horario    BIGSERIAL PRIMARY KEY,
    id_medico     BIGINT NOT NULL,
    dia_semana    INTEGER NOT NULL,
    hora_inicio   TIME(0) WITHOUT TIME ZONE NOT NULL,
    hora_final    TIME(0) WITHOUT TIME ZONE NOT NULL,
    duracion_cita INTEGER,
    CONSTRAINT horario_atencion_id_medico_foreign FOREIGN KEY (id_medico)
        REFERENCES medico (id_medico) ON DELETE CASCADE
);

CREATE TABLE bloqueo_agenda (
    id_bloqueo  BIGSERIAL PRIMARY KEY,
    id_medico   BIGINT NOT NULL,
    fecha       DATE NOT NULL,
    hora_inicio TIME(0) WITHOUT TIME ZONE NOT NULL,
    hora_final  TIME(0) WITHOUT TIME ZONE NOT NULL,
    motivo      TEXT,
    CONSTRAINT bloqueo_agenda_id_medico_foreign FOREIGN KEY (id_medico)
        REFERENCES medico (id_medico) ON DELETE CASCADE
);

-- 6. Sistema y citas
CREATE TABLE bitacora (
    id_bitacora BIGSERIAL PRIMARY KEY,
    id_usuario  BIGINT,
    fecha_hora  TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    accion      VARCHAR(100) NOT NULL,
    modulo      VARCHAR(100),
    id_registro INTEGER,
    detalle     TEXT,
    ip          VARCHAR(45),
    CONSTRAINT bitacora_id_usuario_foreign FOREIGN KEY (id_usuario)
        REFERENCES users (id) ON DELETE SET NULL
);

CREATE TABLE notificacion (
    id_notificacion  BIGSERIAL PRIMARY KEY,
    id_usuario       BIGINT NOT NULL,
    tipo             VARCHAR(50),
    mensaje          TEXT NOT NULL,
    canal            VARCHAR(50),
    estado_envio     VARCHAR(20) NOT NULL DEFAULT 'Pendiente',
    fecha_programada TIMESTAMP(0) WITHOUT TIME ZONE,
    fecha_envio      TIMESTAMP(0) WITHOUT TIME ZONE,
    leido            BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT notificacion_id_usuario_foreign FOREIGN KEY (id_usuario)
        REFERENCES users (id) ON DELETE CASCADE
);

CREATE TABLE citas (
    id_cita            BIGSERIAL PRIMARY KEY,
    codigo             VARCHAR(50) NOT NULL,
    id_paciente        BIGINT NOT NULL,
    id_medico          BIGINT NOT NULL,
    id_especialidad    BIGINT NOT NULL,
    fecha_cita         DATE NOT NULL,
    hora_inicio        TIME(0) WITHOUT TIME ZONE NOT NULL,
    hora_fin           TIME(0) WITHOUT TIME ZONE NOT NULL,
    motivo             TEXT,
    estado             VARCHAR(30) NOT NULL DEFAULT 'Programada',
    fecha_creacion     TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo_cancelacion TEXT,
    fecha_cancelacion  TIMESTAMP(0) WITHOUT TIME ZONE,
    cancelado_por      BIGINT,
    CONSTRAINT citas_codigo_unique UNIQUE (codigo),
    CONSTRAINT citas_id_paciente_foreign FOREIGN KEY (id_paciente)
        REFERENCES paciente (id_paciente) ON DELETE CASCADE,
    CONSTRAINT citas_id_medico_foreign FOREIGN KEY (id_medico)
        REFERENCES medico (id_medico) ON DELETE CASCADE,
    CONSTRAINT citas_id_especialidad_foreign FOREIGN KEY (id_especialidad)
        REFERENCES especialidad (id_especialidad) ON DELETE CASCADE,
    CONSTRAINT citas_cancelado_por_foreign FOREIGN KEY (cancelado_por)
        REFERENCES users (id) ON DELETE SET NULL
);

CREATE TABLE historial_estado_cita (
    id_historial    BIGSERIAL PRIMARY KEY,
    id_cita         BIGINT NOT NULL,
    estado_anterior VARCHAR(30),
    estado_nuevo    VARCHAR(30) NOT NULL,
    fecha_hora      TIMESTAMP(0) WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    motivo          TEXT,
    registrado_por  BIGINT,
    CONSTRAINT historial_estado_cita_id_cita_foreign FOREIGN KEY (id_cita)
        REFERENCES citas (id_cita) ON DELETE CASCADE,
    CONSTRAINT historial_estado_cita_registrado_por_foreign FOREIGN KEY (registrado_por)
        REFERENCES users (id) ON DELETE SET NULL
);

CREATE TABLE pago (
    id_pago        BIGSERIAL PRIMARY KEY,
    id_cita        BIGINT NOT NULL,
    monto          NUMERIC(10, 2) NOT NULL,
    metodo_de_pago VARCHAR(50),
    id_transaccion VARCHAR(100),
    estado_pago    VARCHAR(30) NOT NULL DEFAULT 'Pendiente',
    fecha_pago     TIMESTAMP(0) WITHOUT TIME ZONE,
    CONSTRAINT pago_id_cita_foreign FOREIGN KEY (id_cita)
        REFERENCES citas (id_cita) ON DELETE CASCADE
);

-- Registro de las migraciones como ejecutadas (lote 1), igual que «php artisan migrate»
INSERT INTO migrations (migration, batch) VALUES
    ('0001_01_01_000000_create_users_table', 1),
    ('0001_01_01_000001_create_cache_table', 1),
    ('0001_01_01_000002_create_jobs_table', 1),
    ('2026_10_23_191317_create_clinica_tablas', 1);

COMMIT;
