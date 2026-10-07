use [Pawnshop_DB]

-- Представление: вывести все таблицы SQL Server с разными видами триггеров
-- Реализация через:
    -- information_schema - ISO-стандарт, хранящий метаданные об объектах в БД
        -- tables - хранит информацию о таблицах
    -- системные представления sys - каталоги MSSQL, хранящие более детальную информацию (в данном случае - тип триггера)
        -- tables - хранит информацию о таблицах

CREATE OR ALTER VIEW vw_TablesWithTriggerTypes
AS
SELECT 
    t.TABLE_CATALOG AS [DatabaseName],
    t.TABLE_SCHEMA  AS [SchemaName],
    t.TABLE_NAME    AS [TableName],
    -- Названия триггеров по типам
    STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 0 AND OBJECTPROPERTY(tr.object_id, 'ExecIsInsertTrigger') = 1 THEN tr.name END, ', ') AS [After_Insert_Triggers],
    STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 0 AND OBJECTPROPERTY(tr.object_id, 'ExecIsUpdateTrigger') = 1 THEN tr.name END, ', ') AS [After_Update_Triggers],
    STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 0 AND OBJECTPROPERTY(tr.object_id, 'ExecIsDeleteTrigger') = 1 THEN tr.name END, ', ') AS [After_Delete_Triggers],
    STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 1 AND OBJECTPROPERTY(tr.object_id, 'ExecIsInsertTrigger') = 1 THEN tr.name END, ', ') AS [InsteadOf_Insert_Triggers],
    STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 1 AND OBJECTPROPERTY(tr.object_id, 'ExecIsUpdateTrigger') = 1 THEN tr.name END, ', ') AS [InsteadOf_Update_Triggers],
    STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 1 AND OBJECTPROPERTY(tr.object_id, 'ExecIsDeleteTrigger') = 1 THEN tr.name END, ', ') AS [InsteadOf_Delete_Triggers]
FROM INFORMATION_SCHEMA.TABLES t
JOIN sys.tables st 
    ON st.name = t.TABLE_NAME 
   AND st.schema_id = SCHEMA_ID(t.TABLE_SCHEMA)
LEFT JOIN sys.triggers tr 
    ON tr.parent_id = st.object_id
WHERE t.TABLE_TYPE = 'BASE TABLE'
GROUP BY t.TABLE_CATALOG, t.TABLE_SCHEMA, t.TABLE_NAME;
GO

-- Вызов
SELECT * FROM vw_TablesWithTriggerTypes;

-- Хранимая процедура: для указанного объекта, заданного именем и схемой, выводятся все его свойства.
-- В качестве объекта может выступать таблица, представление, ограничение, функция, процедура или триггер.
-- Конкретизация под тип объекта и вывод детальной информации
-- Реализация через системные представления sys:
    -- objects - хранит обзую информацию о кажом объекте БД
    -- schemas - хранит список схем и их владельцев
    -- database_permissions - хранит права доступа к объектам БД
    -- database_principals - хранит информацию о пользователях, ролях, группах, которые могут получать права доступа
    -- columns - хранит информацию о каждом столбце каждой таблицы БД
    -- triggers - хранит подробную информацию о триггерах
    -- partitions - хранит информацию о секциях таблиц и количестве строк таблицы в секции
    -- sql_expression_dependencies - хранит информацию о связях между объектами
    -- parameters - хранит информацию о всех входных и выходных параметрах процедур и функций
    -- sql_modules - хранит исходный код каждого объекта
-- Сначала проверяем тип объекта:
    -- U - таблица
    -- V — представление
    -- P — процедура
    -- FN/IF/TF — функция
    -- TR — триггер
    -- C/F/PK/UQ — ограничение
-- Далее формируем результирующий набор данных 

CREATE OR ALTER PROCEDURE sp_GetObjectProperties
    @SchemaName NVARCHAR(128) = N'dbo',
    @ObjectName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ObjectId INT = OBJECT_ID(QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@ObjectName));

    IF @ObjectId IS NULL
    BEGIN
        RAISERROR(N'Объект [%s].[%s] не найден в текущей базе данных.', 16, 1, @SchemaName, @ObjectName);
        RETURN;
    END


    -- ОБЩИЕ СВЕДЕНИЯ (Имя, тип, владелец, дата создания и модификации)
    SELECT 
        o.object_id AS [ObjectId],
        s.name AS [SchemaName],
        o.name AS [ObjectName],
        o.type_desc AS [ObjectType],
        USER_NAME(ISNULL(o.principal_id, s.principal_id)) AS [OwnerName],
        o.create_date AS [CreateDate],
        o.modify_date AS [ModifyDate]
    FROM sys.objects o
    JOIN sys.schemas s ON o.schema_id = s.schema_id
    WHERE o.object_id = @ObjectId;


    -- ПРИВИЛЕГИИ И ЗАПРЕТЫ (GRANT / DENY / REVOKE)
    SELECT 
        dp.class_desc AS [PermissionClass],
        grantee.name AS [GranteePrincipal],
        grantor.name AS [GrantorPrincipal],
        dp.permission_name AS [Permission],
        dp.state_desc AS [State] -- GRANT, DENY, REVOKE
    FROM sys.database_permissions dp
    JOIN sys.database_principals grantee ON dp.grantee_principal_id = grantee.principal_id
    JOIN sys.database_principals grantor ON dp.grantor_principal_id = grantor.principal_id
    WHERE dp.major_id = @ObjectId;


    -- СВОЙСТВА, ЗАВИСЯЩИЕ ОТ ТИПА ОБЪЕКТА
    DECLARE @Type NVARCHAR(60) = (SELECT type FROM sys.objects WHERE object_id = @ObjectId);

    -- ТАБЛИЦЫ (U) И ПРЕДСТАВЛЕНИЯ (V)
    IF @Type IN ('U', 'V')
    BEGIN
        -- Список столбцов
        SELECT 
            c.column_id AS [ColumnID],
            c.name AS [ColumnName],
            TYPE_NAME(c.user_type_id) AS [DataType],
            c.max_length AS [MaxLength],
            c.precision AS [Precision],
            c.scale AS [Scale],
            c.is_nullable AS [IsNullable],
            c.is_identity AS [IsIdentity]
        FROM sys.columns c
        WHERE c.object_id = @ObjectId
        ORDER BY c.column_id;

        -- Ограничения (PRIMARY KEY, FOREIGN KEY, CHECK, UNIQUE)
        SELECT 
            kc.name AS [ConstraintName],
            kc.type_desc AS [ConstraintType]
        FROM sys.objects kc
        WHERE kc.parent_object_id = @ObjectId;

        -- Триггеры, привязанные к таблице/представлению
        SELECT 
            tr.name AS [TriggerName],
            tr.type_desc AS [TriggerType],
            tr.is_disabled AS [IsDisabled]
        FROM sys.triggers tr
        WHERE tr.parent_id = @ObjectId;

        -- Количество строк (только для таблиц)
        IF @Type = 'U'
        BEGIN
            SELECT SUM(p.rows) AS [TotalRowCount]
            FROM sys.partitions p
            WHERE p.object_id = @ObjectId AND p.index_id IN (0, 1);
        END

        -- Внешние объекты, ссылающиеся на эту таблицу/представление
        SELECT DISTINCT
            o.name AS [ReferencedByObject],
            o.type_desc AS [ObjectType]
        FROM sys.sql_expression_dependencies d
        JOIN sys.objects o ON d.referencing_id = o.object_id
        WHERE d.referenced_id = @ObjectId;
    END

    -- ПРОЦЕДУРЫ (P), ФУНКЦИИ (FN, IF, TF)
    IF @Type IN ('P', 'FN', 'IF', 'TF')
    BEGIN
        -- Параметры процедуры / функции
        SELECT 
            p.parameter_id AS [ParamID],
            p.name AS [ParameterName],
            TYPE_NAME(p.user_type_id) AS [DataType],
            p.max_length AS [MaxLength],
            p.is_output AS [IsOutput]
        FROM sys.parameters p
        WHERE p.object_id = @ObjectId
        ORDER BY p.parameter_id;

        -- Зависимости (на какие объекты ссылается этот код)
        SELECT DISTINCT
            d.referenced_entity_name AS [DependsOnObject],
            o.type_desc AS [ObjectType]
        FROM sys.sql_expression_dependencies d
        LEFT JOIN sys.objects o ON d.referenced_id = o.object_id
        WHERE d.referencing_id = @ObjectId;

        -- Текст исходного кода
        SELECT definition AS [CodeDefinition]
        FROM sys.sql_modules
        WHERE object_id = @ObjectId;
    END

    -- ТРИГГЕРЫ (TR)
    IF @Type = 'TR'
    BEGIN
        SELECT 
            parent.name AS [AttachedToTable],
            tr.is_instead_of_trigger AS [IsInsteadOf],
            tr.is_disabled AS [IsDisabled]
        FROM sys.triggers tr
        JOIN sys.objects parent ON tr.parent_id = parent.object_id
        WHERE tr.object_id = @ObjectId;

        -- Текст кода триггера
        SELECT definition AS [CodeDefinition]
        FROM sys.sql_modules
        WHERE object_id = @ObjectId;
    END

    -- ОГРАНИЧЕНИЯ (C, F, PK, UQ)
    IF @Type IN ('C', 'F', 'PK', 'UQ')
    BEGIN
        SELECT 
            parent.name AS [ParentTable],
            o.type_desc AS [ConstraintType]
        FROM sys.objects o
        JOIN sys.objects parent ON o.parent_object_id = parent.object_id
        WHERE o.object_id = @ObjectId;
    END
END;
GO

-- Вызов
EXEC sp_GetObjectProperties @SchemaName = N'dbo', @ObjectName = N'Contract';