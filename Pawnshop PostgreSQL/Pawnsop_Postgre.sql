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

-- Здесь используем:
-- pg_class — хранит информацию о всех таблицах, индексах, представлениях и последовательностях. Поле relname хранит имя таблицы.
-- pg_attribute — хранит информацию о всех столбцах всех таблиц. Поле attname хранит имя столбца, а attnum — его номер.
-- pg_depend — системный граф зависимостей между объектами (аналог sys.sql_expression_dependencies). Связывает столбец (refobjsubid), таблицу (refobjid) и объекты кода/триггеры.
-- pg_proc — хранит информацию о хранимых функциях и процедурах (включая триггерные функции).
-- pg_trigger — хранит данные о триггерах, привязанных к конкретным таблицам.
-- Системные функции pg_get_functiondef() и pg_get_triggerdef() — извлекают полный T-SQL/PL-pgSQL исходный код функции или определение триггера.

-- C параметризацией

CREATE OR REPLACE FUNCTION find_objects_modifying_column_using(
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
BEGIN
    -- Формируем текст запроса с плейсхолдерами $1 и $2
    v_sql := '
        SELECT DISTINCT
            p.proname::NAME AS object_name,
            ''FUNCTION / TRIGGER''::TEXT AS object_type,
            pg_get_functiondef(p.oid)::TEXT AS code_definition
        FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid
        JOIN pg_depend d ON d.refobjid = c.oid AND d.refobjsubid = a.attnum
        JOIN pg_rewrite r ON r.oid = d.objid
        JOIN pg_depend d2 ON d2.objid = r.oid
        JOIN pg_proc p ON p.oid = d2.refobjid
        WHERE c.relname = $1
          AND a.attname = $2
          AND NOT a.attisdropped
        
        UNION
        
        SELECT DISTINCT
            trg.tgname::NAME AS object_name,
            ''TRIGGER''::TEXT AS object_type,
            pg_get_triggerdef(trg.oid)::TEXT AS code_definition
        FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid
        JOIN pg_trigger trg ON trg.tgrelid = c.oid
        WHERE c.relname = $1
          AND NOT a.attisdropped
          AND a.attname = $2;
    ';

    -- Выполняем динамический SQL с параметрами USING
    RETURN QUERY EXECUTE v_sql USING p_table_name, p_column_name;
END;
$$;

SELECT * FROM find_objects_modifying_column_using('contract', 'sale_info');

-- Без параметризации
CREATE OR REPLACE FUNCTION find_objects_modifying_column_exec(
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
BEGIN
    -- Формируем запрос с явным экранированием через quote_literal
    v_sql := '
        SELECT DISTINCT
            p.proname::NAME AS object_name,
            ''FUNCTION / TRIGGER''::TEXT AS object_type,
            pg_get_functiondef(p.oid)::TEXT AS code_definition
        FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid
        JOIN pg_depend d ON d.refobjid = c.oid AND d.refobjsubid = a.attnum
        JOIN pg_rewrite r ON r.oid = d.objid
        JOIN pg_depend d2 ON d2.objid = r.oid
        JOIN pg_proc p ON p.oid = d2.refobjid
        WHERE c.relname = ' || quote_literal(p_table_name) || '
          AND a.attname = ' || quote_literal(p_column_name) || '
          AND NOT a.attisdropped

        UNION

        SELECT DISTINCT
            trg.tgname::NAME AS object_name,
            ''TRIGGER''::TEXT AS object_type,
            pg_get_triggerdef(trg.oid)::TEXT AS code_definition
        FROM pg_class c
        JOIN pg_attribute a ON a.attrelid = c.oid
        JOIN pg_trigger trg ON trg.tgrelid = c.oid
        WHERE c.relname = ' || quote_literal(p_table_name) || '
          AND NOT a.attisdropped
          AND a.attname = ' || quote_literal(p_column_name) || ';
    ';

    -- Выполняем динамический запрос без параметрического блока
    RETURN QUERY EXECUTE v_sql;
END;
$$;

SELECT * FROM find_objects_modifying_column_exec('item', 'wear');