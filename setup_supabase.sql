-- =====================================================
-- SETUP SUPABASE – Taller Hígado Graso
-- Clínica El Castaño
-- Ejecutar en: Supabase Dashboard → SQL Editor
-- =====================================================

-- 1. Tabla de inscripciones
CREATE TABLE IF NOT EXISTS inscripciones (
  id          uuid        DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre      text        NOT NULL,
  dni         text        NOT NULL,
  edad        integer     NOT NULL CHECK (edad > 0 AND edad < 120),
  telefono    text        NOT NULL,
  email       text,
  diagnostico text,
  comentarios text,
  created_at  timestamptz DEFAULT now()
);

-- Evitar que el mismo DNI se inscriba dos veces
ALTER TABLE inscripciones ADD CONSTRAINT unique_dni UNIQUE (dni);

-- 2. Activar Row Level Security (nadie puede leer los datos desde el frontend)
ALTER TABLE inscripciones ENABLE ROW LEVEL SECURITY;

-- 3. Política: solo permite INSERT si hay menos de 30 inscriptos
--    Es el candado final que garantiza el límite aunque haya picos de tráfico.
CREATE POLICY "insert_bajo_limite" ON inscripciones
  FOR INSERT
  TO anon
  WITH CHECK (
    (SELECT COUNT(*) FROM inscripciones) < 30
  );

-- 4. Función pública para obtener el conteo sin exponer datos personales.
--    SECURITY DEFINER: se ejecuta con permisos del owner, no del anon.
CREATE OR REPLACE FUNCTION get_inscripciones_count()
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
AS $$
  SELECT COUNT(*)::integer FROM inscripciones;
$$;
