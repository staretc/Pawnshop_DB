use [Pawnshop_DB]

-- Процедура: вывести все таблицы SQL Server с разными видами триггеров
-- Реализация через:
    -- sp_MSforeachdb (системная хранимая процедура) — для итерации и выполнения кода во всех базах данных.
    -- DB_NAME() — функция для получения имени текущей базы данных.
    -- DB_ID() — функция для проверки идентификатора базы данных (исключение системных баз).
    -- OBJECT_ID() — функция для проверки существования объектов.
    -- INFORMATION_SCHEMA.TABLES — ISO-стандартное представление, хранящее информацию о таблицах и представлениях.
    --   - Столбцы: TABLE_CATALOG, TABLE_SCHEMA, TABLE_NAME, TABLE_TYPE.
    -- sys.schemas — системное представление, содержащее список схем базы данных.
    -- sys.tables — системный каталог MSSQL, хранящий детальную информацию о таблицах.
    --   - Столбцы/функции: name, schema_id, SCHEMA_ID().
    -- sys.triggers — системный каталог, хранящий подробную информацию о триггерах.
    --   - Столбцы: object_id, parent_id, is_instead_of_trigger, name.
    -- OBJECTPROPERTY() — функция для проверки свойств объектов (в данном случае: 'ExecIsInsertTrigger', 
      'ExecIsUpdateTrigger', 'ExecIsDeleteTrigger').

CREATE OR ALTER PROCEDURE dGetTablesWithTriggersBySchema
    @SchemaName NVARCHAR(128) = N'dbo' -- Параметр схемы с дефолтным значением dbo
AS
BEGIN
    SET NOCOUNT ON;

    -- Временная таблица для сбора данных со всех баз данных сервера
    CREATE TABLE #AllTablesTriggers (
        [DatabaseName] NVARCHAR(128),
        [SchemaName] NVARCHAR(128),
        [TableName] NVARCHAR(128),
        [After_Insert_Triggers] NVARCHAR(MAX),
        [After_Update_Triggers] NVARCHAR(MAX),
        [After_Delete_Triggers] NVARCHAR(MAX),
        [InsteadOf_Insert_Triggers] NVARCHAR(MAX),
        [InsteadOf_Update_Triggers] NVARCHAR(MAX),
        [InsteadOf_Delete_Triggers] NVARCHAR(MAX)
    );

    -- Шаблон динамического SQL для обхода каждой базы через sp_MSforeachdb
    DECLARE @Command NVARCHAR(MAX);
    
    SET @Command = N'
    USE [?];
    
    -- Пропускаем системные базы данных (опционально, при необходимости можно убрать)
    IF DB_ID() > 4 AND OBJECT_ID(N''sys.tables'') IS NOT NULL
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.schemas WHERE name = N''___SCHEMA___'')
        BEGIN
            INSERT INTO #AllTablesTriggers
            SELECT 
                DB_NAME() AS [DatabaseName],
                t.TABLE_SCHEMA  AS [SchemaName],
                t.TABLE_NAME    AS [TableName],
                STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 0 AND OBJECTPROPERTY(tr.object_id, ''ExecIsInsertTrigger'') = 1 THEN tr.name END, '', '') AS [After_Insert_Triggers],
                STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 0 AND OBJECTPROPERTY(tr.object_id, ''ExecIsUpdateTrigger'') = 1 THEN tr.name END, '', '') AS [After_Update_Triggers],
                STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 0 AND OBJECTPROPERTY(tr.object_id, ''ExecIsDeleteTrigger'') = 1 THEN tr.name END, '', '') AS [After_Delete_Triggers],
                STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 1 AND OBJECTPROPERTY(tr.object_id, ''ExecIsInsertTrigger'') = 1 THEN tr.name END, '', '') AS [InsteadOf_Insert_Triggers],
                STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 1 AND OBJECTPROPERTY(tr.object_id, ''ExecIsUpdateTrigger'') = 1 THEN tr.name END, '', '') AS [InsteadOf_Update_Triggers],
                STRING_AGG(CASE WHEN tr.is_instead_of_trigger = 1 AND OBJECTPROPERTY(tr.object_id, ''ExecIsDeleteTrigger'') = 1 THEN tr.name END, '', '') AS [InsteadOf_Delete_Triggers]
            FROM INFORMATION_SCHEMA.TABLES t
            JOIN sys.tables st 
                ON st.name = t.TABLE_NAME 
               AND st.schema_id = SCHEMA_ID(t.TABLE_SCHEMA)
            LEFT JOIN sys.triggers tr 
                ON tr.parent_id = st.object_id
            WHERE t.TABLE_TYPE = ''BASE TABLE'' 
              AND t.TABLE_SCHEMA = N''___SCHEMA___''
            GROUP BY t.TABLE_SCHEMA, t.TABLE_NAME;
        END
    END';

    -- Подставляем имя схемы в запрос
    SET @Command = REPLACE(@Command, N'___SCHEMA___', @SchemaName);

    -- Выполняем сбор данных по всем базам данных
    EXEC sp_MSforeachdb @Command;

    -- Выводим объединенный результат со всех баз
    SELECT 
        [DatabaseName],
        [SchemaName],
        [TableName],
        [After_Insert_Triggers],
        [After_Update_Triggers],
        [After_Delete_Triggers],
        [InsteadOf_Insert_Triggers],
        [InsteadOf_Update_Triggers],
        [InsteadOf_Delete_Triggers]
    FROM #AllTablesTriggers;

    DROP TABLE #AllTablesTriggers;
END;
GO

-- Вызов
EXEC dGetTablesWithTriggersBySchema @SchemaName = N'dbo';

-- Хранимая процедура: для указанного объекта, заданного именем и схемой, выводятся все его свойства.
-- В качестве объекта может выступать таблица, представление, ограничение, функция, процедура или триггер.
-- Конкретизация под тип объекта и вывод детальной информации
/*Используемые системные объекты и функции:
    - sp_MSforeachdb — системная хранимая процедура для сканирования всех баз данных.
    - DB_NAME(), DB_ID(), OBJECT_ID() — системные функции.
    - QUOTENAME(), REPLACE() — функции экранирования строк и идентификаторов.
    - sp_executesql — системная хранимая процедура для выполнения динамического SQL.
    - sys.objects — хранит общую информацию об объектах БД (типы: U, V, P, FN, IF, TF, TR, C, F, PK, UQ).
    - sys.schemas — список схем и их владельцев.
    - USER_NAME() — функция для определения имени пользователя/владельца.
    - sys.sql_expression_dependencies — хранит информацию о зависимостях между объектами (связи, ссылки).
    - sys.database_permissions — хранит выданные права доступа (GRANT, DENY, REVOKE).
    - sys.database_principals — информация о пользователях и ролях базы данных.
    - sys.columns — детальная информация о столбцах таблиц/представлений.
    - TYPE_NAME() — функция для получения названия типа данных по его ID.
    - sys.triggers — детальная информация о триггерах и их привязке к родительским объектам.
    - sys.partitions — информация о секциях и количестве строк в таблицах (используется с index_id IN (0, 1)).
    - sys.parameters — параметры хранимых процедур и функций.
    - sys.sql_modules — исходный код (definition) представлений, процедур, функций и триггеров.
    - sys.check_constraints — выражения и определения для CHECK-ограничений.*/
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

    -- Временная таблица для поиска базы данных, в которой находится объект
    CREATE TABLE #FoundObjects (
        [DatabaseName] NVARCHAR(128),
        [ObjectId] INT,
        [ObjectType] CHAR(2)
    );

    -- Формируем запрос для поиска объекта во всех базах данных
    DECLARE @CheckCmd NVARCHAR(MAX);
    SET @CheckCmd = N'
    USE [?];
    IF DB_ID() > 4 AND OBJECT_ID(N''sys.objects'') IS NOT NULL
    BEGIN
        DECLARE @FoundId INT = OBJECT_ID(QUOTENAME(N''' + REPLACE(@SchemaName, '''', '''''') + N''') + N''.'' + QUOTENAME(N''' + REPLACE(@ObjectName, '''', '''''') + N'''));
        IF @FoundId IS NOT NULL
        BEGIN
            INSERT INTO #FoundObjects ([DatabaseName], [ObjectId], [ObjectType])
            SELECT DB_NAME(), @FoundId, [type] FROM sys.objects WHERE [object_id] = @FoundId;
        END
    END';

    -- Запускаем поиск по всем базам
    EXEC sp_MSforeachdb @CheckCmd;

    IF NOT EXISTS (SELECT 1 FROM #FoundObjects)
    BEGIN
        RAISERROR(N'Объект [%s].[%s] не найден ни в одной базе данных сервера.', 16, 1, @SchemaName, @ObjectName);
        DROP TABLE #FoundObjects;
        RETURN;
    END

    -- Курсор для обработки найденных объектов (если имя встречается в нескольких базах)
    DECLARE @TargetDb NVARCHAR(128);
    DECLARE @TargetObjId INT;
    DECLARE @TargetType CHAR(2);

    DECLARE cur CURSOR FAST_FORWARD FOR 
    SELECT [DatabaseName], [ObjectId], [ObjectType] FROM #FoundObjects;

    OPEN cur;
    FETCH NEXT FROM cur INTO @TargetDb, @TargetObjId, @TargetType;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT N'Найдено в базе данных: ' + @TargetDb;

        DECLARE @Sql NVARCHAR(MAX);
        
        -- Базовый скрипт для сбора общих сведений, зависимостей и прав
        SET @Sql = N'
        USE ' + QUOTENAME(@TargetDb) + N';

        -- 1. ОБЩИЕ СВЕДЕНИЯ
        SELECT 
            DB_NAME() AS [DatabaseName],
            o.object_id AS [ObjectId],
            s.name AS [SchemaName],
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            USER_NAME(ISNULL(o.principal_id, s.principal_id)) AS [OwnerName],
            o.create_date AS [CreateDate],
            o.modify_date AS [ModifyDate]
        FROM sys.objects o
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE o.object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';

        -- ОБЩИЕ ЗАВИСИМОСТИ
        SELECT DISTINCT
            s.name AS [ReferencingSchema],
            o.name AS [ReferencingObjectName],
            o.type_desc AS [ReferencingObjectType]
        FROM sys.sql_expression_dependencies d
        JOIN sys.objects o ON d.referencing_id = o.object_id
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        WHERE d.referenced_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';

        -- 2. ПРИВИЛЕГИИ И ЗАПРЕТЫ
        SELECT 
            dp.class_desc AS [PermissionClass],
            grantee.name AS [GranteePrincipal],
            grantor.name AS [GrantorPrincipal],
            dp.permission_name AS [Permission],
            dp.state_desc AS [State]
        FROM sys.database_permissions dp
        JOIN sys.database_principals grantee ON dp.grantee_principal_id = grantee.principal_id
        JOIN sys.database_principals grantor ON dp.grantor_principal_id = grantor.principal_id
        WHERE dp.major_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
        ';

        -- ТАБЛИЦЫ (U) И ПРЕДСТАВЛЕНИЯ (V)[cite: 1]
        IF @TargetType IN ('U', 'V')
        BEGIN
            SET @Sql = @Sql + N'
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
            WHERE c.object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N'
            ORDER BY c.column_id;

            SELECT 
                kc.name AS [ConstraintName],
                kc.type_desc AS [ConstraintType]
            FROM sys.objects kc
            WHERE kc.parent_object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';

            SELECT 
                tr.name AS [TriggerName],
                tr.type_desc AS [TriggerType],
                tr.is_disabled AS [IsDisabled]
            FROM sys.triggers tr
            WHERE tr.parent_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
            ';

            IF @TargetType = 'U'
            BEGIN
                SET @Sql = @Sql + N'
                SELECT SUM(p.rows) AS [TotalRowCount]
                FROM sys.partitions p
                WHERE p.object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N' AND p.index_id IN (0, 1);
                ';
            END

            SET @Sql = @Sql + N'
            SELECT DISTINCT
                o.name AS [ReferencedByObject],
                o.type_desc AS [ObjectType]
            FROM sys.sql_expression_dependencies d
            JOIN sys.objects o ON d.referencing_id = o.object_id
            WHERE d.referenced_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
            ';
        END

        -- ПРОЦЕДУРЫ (P), ФУНКЦИИ (FN, IF, TF)[cite: 1]
        IF @TargetType IN ('P', 'FN', 'IF', 'TF')
        BEGIN
            SET @Sql = @Sql + N'
            SELECT 
                p.parameter_id AS [ParamID],
                p.name AS [ParameterName],
                TYPE_NAME(p.user_type_id) AS [DataType],
                p.max_length AS [MaxLength],
                p.is_output AS [IsOutput]
            FROM sys.parameters p
            WHERE p.object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N'
            ORDER BY p.parameter_id;

            SELECT DISTINCT
                d.referenced_entity_name AS [DependsOnObject],
                o.type_desc AS [ObjectType]
            FROM sys.sql_expression_dependencies d
            LEFT JOIN sys.objects o ON d.referenced_id = o.object_id
            WHERE d.referencing_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';

            SELECT definition AS [CodeDefinition]
            FROM sys.sql_modules
            WHERE object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
            ';
        END

        -- ТРИГГЕРЫ (TR)[cite: 1]
        IF @TargetType = 'TR'
        BEGIN
            SET @Sql = @Sql + N'
            SELECT 
                parent.name AS [AttachedToTable],
                tr.is_instead_of_trigger AS [IsInsteadOf],
                tr.is_disabled AS [IsDisabled]
            FROM sys.triggers tr
            JOIN sys.objects parent ON tr.parent_id = parent.object_id
            WHERE tr.object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';

            SELECT definition AS [CodeDefinition]
            FROM sys.sql_modules
            WHERE object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
            ';
        END

        -- ОГРАНИЧЕНИЯ (C, F, PK, UQ)[cite: 1]
        IF @TargetType IN ('C', 'F', 'PK', 'UQ')
        BEGIN
            SET @Sql = @Sql + N'
            SELECT 
                parent.name AS [ParentTable],
                o.type_desc AS [ConstraintType]
            FROM sys.objects o
            JOIN sys.objects parent ON o.parent_object_id = parent.object_id
            WHERE o.object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
            ';

            IF @TargetType = 'C'
            BEGIN
                SET @Sql = @Sql + N'
                SELECT definition AS [CheckConstraintDefinition]
                FROM sys.check_constraints
                WHERE object_id = ' + CAST(@TargetObjId AS NVARCHAR(20)) + N';
                ';
            END
        END

        -- Выполняем динамический SQL для конкретной найденной базы
        EXEC sp_executesql @Sql;

        FETCH NEXT FROM cur INTO @TargetDb, @TargetObjId, @TargetType;
    END

    CLOSE cur;
    DEALLOCATE cur;
    DROP TABLE #FoundObjects;
END;
GO

-- Вызов
EXEC sp_GetObjectProperties @SchemaName = N'dbo', @ObjectName = N'check_info_conflict';

EXEC sp_GetObjectProperties @SchemaName = N'dbo', @ObjectName = N'ClientsWithNotRedeemedState';

EXEC sp_GetObjectProperties @SchemaName = N'dbo', @ObjectName = N'ClientsWithNotRedeemedState';

create view testview as 
select * from dbo.[ClientsWithNotRedeemedState]()