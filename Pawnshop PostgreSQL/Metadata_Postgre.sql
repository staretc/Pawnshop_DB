-- Представление: Найти все таблицы без PK и UNIQUE
-- Реализация через information_schema:
    -- tables - хранит информацию о таблицах

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