SET search_path TO "Pawnshop_DB";

-- Представление: Найти все таблицы без PK и UNIQUE
-- Реализация через information_schema:
    -- tables - хранит информацию о таблицах

-- Внутреннее представление: собирает информацию о таблицах
CREATE OR REPLACE VIEW vw_tables_without_uc_pk AS
SELECT 
    t.table_catalog AS database_name,
    t.table_schema  AS schema_name,
    t.table_name    AS table_name
FROM information_schema.tables t
WHERE t.table_type = 'BASE TABLE'
  -- Исключаем системные схемы PostgreSQL
  AND t.table_schema NOT IN ('pg_catalog', 'information_schema')
  AND NOT EXISTS (
      SELECT 1
      FROM information_schema.table_constraints tc
      WHERE tc.table_catalog = t.table_catalog
        AND tc.table_schema = t.table_schema
        AND tc.table_name = t.table_name
        AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
  )
ORDER BY t.table_schema, t.table_name;

-- Внешняя функция: проверяет наличие схемы и возвращает отфильтрованные данные из представления
CREATE OR REPLACE FUNCTION get_tables_without_pk_unique(p_schema_name TEXT)
RETURNS TABLE (
    database_name TEXT,
    schema_name TEXT,
    table_name TEXT
) 
LANGUAGE plpgsql
AS $$
BEGIN
    -- Проверяем существование схемы с явным указанием алиаса таблицы (s.schema_name)
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.schemata s
        WHERE s.schema_name = p_schema_name
    ) THEN
        RAISE EXCEPTION 'Схема "%" не существует в текущей базе данных.', p_schema_name;
    END IF;

    -- Возвращаем результат из представления с явным приведением типов к TEXT
    RETURN QUERY
    SELECT 
        v.database_name::TEXT,
        v.schema_name::TEXT,
        v.table_name::TEXT
    FROM vw_tables_without_uc_pk v
    WHERE v.schema_name = p_schema_name;
END;
$$;

-- Вызов функции
SELECT * FROM get_tables_without_pk_unique('Pawnshop_DB');

-- Тестовая таблица
CREATE TABLE testMetadata (
    test_id INTEGER,
    test_name TEXT
);