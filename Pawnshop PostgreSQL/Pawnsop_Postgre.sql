SET search_path TO "Pawnshop_DB";

-- Создание таблиц
CREATE TABLE Item_Type (
    ID SERIAL PRIMARY KEY,
    Name VARCHAR(50) NOT NULL
);

CREATE TABLE Item (
    ID SERIAL PRIMARY KEY,
    Wear INT NOT NULL CHECK (Wear >= 0 AND Wear <= 100),
    Type_ID INT NOT NULL REFERENCES Item_Type(ID) ON UPDATE CASCADE
);

CREATE TABLE Material (
    Periodic_Table_Name VARCHAR(15) PRIMARY KEY,
    Cost_Per_Gramm MONEY NOT NULL
);

CREATE TABLE Client (
    SNILS INT PRIMARY KEY,
    Fullname VARCHAR(50) NOT NULL,
    Address VARCHAR(50) NOT NULL,
    Passport_Series SMALLINT NOT NULL,
    Passport_ID INT NOT NULL,
    UNIQUE (Passport_Series, Passport_ID)
);

CREATE TABLE Item_Contains_Material (
    ID SERIAL PRIMARY KEY,
    Item_ID INT NOT NULL REFERENCES Item(ID) ON UPDATE CASCADE,
    Material_Name VARCHAR(15) NOT NULL REFERENCES Material(Periodic_Table_Name) ON UPDATE CASCADE,
    Weight DOUBLE PRECISION NOT NULL
);

CREATE TABLE Contract (
    Number SERIAL PRIMARY KEY,
    Date DATE NOT NULL,
    Date_Of_Redemption DATE NOT NULL,
    Comission MONEY NOT NULL,
    Redemption_Info VARCHAR(15) NOT NULL,
    Sale_Info VARCHAR(15) NOT NULL,
    Client_SNILS INT NOT NULL REFERENCES Client(SNILS) ON UPDATE CASCADE,
    Item_ID INT NOT NULL REFERENCES Item(ID) ON UPDATE CASCADE,
    CONSTRAINT Check_Redemption_Date CHECK (Date_Of_Redemption >= Date),
    CONSTRAINT check_redemption_info CHECK (Redemption_Info IN ('Not redeemed', 'Redeemed')),
    CONSTRAINT check_sale_info CHECK (Sale_Info IN ('Not on sale', 'On sale', 'Sold')),
    CONSTRAINT check_info_conflict CHECK (
        (Redemption_Info = 'Redeemed' AND Sale_Info != 'On sale') OR 
        (Redemption_Info = 'Redeemed' AND Sale_Info != 'Sold') OR 
        (Redemption_Info = 'Not redeemed')
    )
);

-- Процедура, которая принимает в качестве параметра имя таблицы и имя поля в этой таблице.
-- Определить какие объекты в БД (процедуры, функции, триггеры) могут изменять содержимое этого поля.

-- Здесь используем:
    -- pg_class — хранит информацию о всех таблицах, индексах, представлениях и последовательностях. Поле relname хранит имя таблицы.
    -- pg_attribute — хранит информацию о всех столбцах всех таблиц. Поле attname хранит имя столбца, а attnum — его номер.
    -- pg_depend — системный граф зависимостей между объектами (аналог sys.sql_expression_dependencies). Связывает столбец (refobjsubid), таблицу (refobjid) и объекты кода/триггеры.
    -- pg_proc — хранит информацию о хранимых функциях и процедурах (включая триггерные функции).
    -- pg_trigger — хранит данные о триггерах, привязанных к конкретным таблицам.
    -- pg_get_functiondef() и pg_get_triggerdef() — извлекают полный T-SQL/PL-pgSQL исходный код функции или определение триггера.

-- C параметризацией

-- 1. Функция с параметризацией (аналог sp_executesql)
CREATE OR REPLACE FUNCTION find_objects_modifying_column_using(
    p_schema_name VARCHAR,
    p_table_name VARCHAR,
    p_column_name VARCHAR
)
RETURNS TABLE (
    object_name NAME,
    object_type TEXT,
    code_definition TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql TEXT;
    v_count INT;
BEGIN
    -- 1. Валидация существования схемы
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = p_schema_name) THEN
        RAISE EXCEPTION 'Схема "%" не найдена в базе данных.', p_schema_name;
    END IF;

    -- 2. Валидация существования таблицы в указанной схеме
    IF NOT EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema_name 
          AND c.relname = p_table_name 
          AND c.relkind = 'r'
    ) THEN
        RAISE EXCEPTION 'Таблица "%" не найдена в схеме "%".', p_table_name, p_schema_name;
    END IF;

    -- 3. Валидация существования столбца в таблице
    IF NOT EXISTS (
        SELECT 1 FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema_name 
          AND c.relname = p_table_name 
          AND a.attname = p_column_name 
          AND NOT a.attisdropped
    ) THEN
        RAISE EXCEPTION 'Столбец "%" не найден в таблице "%"."%".', p_column_name, p_schema_name, p_table_name;
    END IF;

    -- 4. Формирование динамического запроса с параметрами ($1 = схема, $2 = таблица, $3 = столбец)
    v_sql := $sql$
        SELECT DISTINCT
            p.proname::NAME AS object_name,
            CASE p.prokind
                WHEN 'p' THEN 'PROCEDURE'
                ELSE 'FUNCTION'
            END::TEXT AS object_type,
            pg_get_functiondef(p.oid)::TEXT AS code_definition
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = $1
          AND pg_get_functiondef(p.oid) ILIKE '%' || $2 || '%'
          AND pg_get_functiondef(p.oid) ILIKE '%' || $3 || '%'
          AND (
              pg_get_functiondef(p.oid) ILIKE '%UPDATE%' 
              OR pg_get_functiondef(p.oid) ILIKE '%INSERT%'
          )

        UNION

        SELECT DISTINCT
            trg.tgname::NAME AS object_name,
            'TRIGGER'::TEXT AS object_type,
            pg_get_triggerdef(trg.oid)::TEXT AS code_definition
        FROM pg_trigger trg
        JOIN pg_class c ON c.oid = trg.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = $1
          AND c.relname = $2
          AND NOT trg.tgisinternal
          AND (
              -- INSERT триггеры срабатывают на всю таблицу
              (trg.tgtype & 4 <> 0)
              OR
              -- UPDATE триггеры: либо табличные (tgattr пустой), либо строго для данного столбца
              (trg.tgtype & 16 <> 0 AND (
                  trg.tgattr::text = '' 
                  OR (
                      SELECT a.attnum::text 
                      FROM pg_attribute a 
                      WHERE a.attrelid = c.oid 
                        AND a.attname = $3 
                        AND NOT a.attisdropped
                    ) = ANY(string_to_array(trg.tgattr::text, ' '))
              ))
          );
    $sql$;

    -- Выполнение запроса
    RETURN QUERY EXECUTE v_sql USING p_schema_name, p_table_name, p_column_name;

    -- Обработка ситуации, если ничего не найдено
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        RAISE NOTICE 'Не найдено процедур, функций или триггеров, изменяющих столбец "%" в таблице "%"."%".', p_column_name, p_schema_name, p_table_name;
    END IF;
END;
$$;

-- Вызов
SELECT * FROM find_objects_modifying_column_using('Pawnshop_DB', 'contract', 'comission');

-- Без параметризации
CREATE OR REPLACE FUNCTION find_objects_modifying_column_exec(
    p_schema_name VARCHAR,
    p_table_name VARCHAR,
    p_column_name VARCHAR
)
RETURNS TABLE (
    object_name NAME,
    object_type TEXT,
    code_definition TEXT
) 
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql TEXT;
    v_count INT;
BEGIN
    -- 1. Валидация существования схемы
    IF NOT EXISTS (SELECT 1 FROM pg_namespace WHERE nspname = p_schema_name) THEN
        RAISE EXCEPTION 'Схема "%" не найдена в базе данных.', p_schema_name;
    END IF;

    -- 2. Валидация существования таблицы
    IF NOT EXISTS (
        SELECT 1 FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema_name 
          AND c.relname = p_table_name 
          AND c.relkind = 'r'
    ) THEN
        RAISE EXCEPTION 'Таблица "%" не найдена в схеме "%".', p_table_name, p_schema_name;
    END IF;

    -- 3. Валидация существования столбца
    IF NOT EXISTS (
        SELECT 1 FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = p_schema_name 
          AND c.relname = p_table_name 
          AND a.attname = p_column_name 
          AND NOT a.attisdropped
    ) THEN
        RAISE EXCEPTION 'Столбец "%" не найден в таблице "%"."%".', p_column_name, p_schema_name, p_table_name;
    END IF;

    -- 4. Формирование динамического запроса без параметризации (интерполяция через %L)
    v_sql := format('
        SELECT DISTINCT
            p.proname::NAME AS object_name,
            CASE p.prokind
                WHEN ''p'' THEN ''PROCEDURE''
                ELSE ''FUNCTION''
            END::TEXT AS object_type,
            pg_get_functiondef(p.oid)::TEXT AS code_definition
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = %1$L
          AND pg_get_functiondef(p.oid) ILIKE ''%%'' || %2$L || ''%%''
          AND pg_get_functiondef(p.oid) ILIKE ''%%'' || %3$L || ''%%''
          AND (
              pg_get_functiondef(p.oid) ILIKE ''%%UPDATE%%'' 
              OR pg_get_functiondef(p.oid) ILIKE ''%%INSERT%%''
          )

        UNION

        SELECT DISTINCT
            trg.tgname::NAME AS object_name,
            ''TRIGGER''::TEXT AS object_type,
            pg_get_triggerdef(trg.oid)::TEXT AS code_definition
        FROM pg_trigger trg
        JOIN pg_class c ON c.oid = trg.tgrelid
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE n.nspname = %1$L
          AND c.relname = %2$L
          AND NOT trg.tgisinternal
          AND (
              (trg.tgtype & 4 <> 0)
              OR
              (trg.tgtype & 16 <> 0 AND (
                  trg.tgattr::text = '' 
                  OR (
                      SELECT a.attnum::text 
                      FROM pg_attribute a 
                      WHERE a.attrelid = c.oid 
                        AND a.attname = %3$L 
                        AND NOT a.attisdropped
                    ) = ANY(string_to_array(trg.tgattr::text, '' ''))
              ))
          );
    ', p_schema_name, p_table_name, p_column_name);

    -- Выполнение запроса
    RETURN QUERY EXECUTE v_sql;

    -- Обработка ситуации, если ничего не найдено
    GET DIAGNOSTICS v_count = ROW_COUNT;
    IF v_count = 0 THEN
        RAISE NOTICE 'Не найдено процедур, функций или триггеров, изменяющих столбец "%" в таблице "%"."%".', p_column_name, p_schema_name, p_table_name;
    END IF;
END;
$$;

-- Вызов
SELECT * FROM find_objects_modifying_column_exec('Pawnshop_DB', 'contract', 'comission');

-- Тестовая процедура

CREATE OR REPLACE PROCEDURE update_contract_commission(
    p_contract_number INT,
    p_new_commission MONEY
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Contract
    SET Comission = p_new_commission
    WHERE Number = p_contract_number;
END;
$$;