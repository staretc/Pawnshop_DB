use [Pawnshop_DB]

-- Процедура, которая принимает в качестве параметра имя таблицы и имя поля в этой таблице.
-- Определить какие объекты в БД (процедуры, функции, триггеры) могут изменять содержимое этого поля.

-- обращаемся к:
    -- sys.objects - хранит информацию о созданных в БД таблицах, процедурах, функциях, триггерах и тд
    -- sys.sql_modules - хранит определители и исходный код объекта (CREATE TABLE . . . / CREATE PROCEDURE . . .)
    -- sys.dm_sql_referenced_entities - хранит список всех сущностей (объектов или столбцов), на которые ссылается переданный ей в качестве параметра объект

-- EXEC

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_exec
    @SchemaName NVARCHAR(128) = N'dbo',
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Валидация: проверка существования схемы
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = @SchemaName)
    BEGIN
        RAISERROR(N'Ошибка: Схема "%s" не существует в базе данных.', 16, 1, @SchemaName);
        RETURN;
    END

    -- 2. Валидация: проверка существования таблицы в указанной схеме
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = @TableName
    )
    BEGIN
        RAISERROR(N'Ошибка: Таблица "%s.%s" не существует в базе данных.', 16, 1, @SchemaName, @TableName);
        RETURN;
    END

    -- 3. Валидация: проверка существования столбца в таблице
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = @TableName AND c.name = @ColumnName
    )
    BEGIN
        RAISERROR(N'Ошибка: Столбец "%s" не найден в таблице "%s.%s".', 16, 1, @ColumnName, @SchemaName, @TableName);
        RETURN;
    END

    DECLARE @Sql NVARCHAR(MAX);

    -- Формируем динамический SQL с безопасной подстановкой параметров через QUOTENAME
    SET @Sql = N'
        SELECT DISTINCT
            s.name AS [SchemaName],
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            m.definition AS [CodeDefinition]
        FROM sys.objects o
        JOIN sys.schemas s 
            ON o.schema_id = s.schema_id
        JOIN sys.sql_modules m 
            ON o.object_id = m.object_id
        CROSS APPLY sys.dm_sql_referenced_entities(
            QUOTENAME(s.name) + N''.'' + QUOTENAME(o.name), 
            ''OBJECT''
        ) re
        WHERE o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'')
          AND OBJECT_SCHEMA_NAME(re.referenced_id) = ' + QUOTENAME(@SchemaName, '''') + '
          AND re.referenced_entity_name = ' + QUOTENAME(@TableName, '''') + '
          AND (
              -- Прямое изменение столбца
              (re.referenced_minor_name = ' + QUOTENAME(@ColumnName, '''') + ' AND re.is_updated = 1)
              OR 
              -- Модификация всей таблицы в UPDATE (с точным упоминанием столбца в коде)
              (re.referenced_minor_name IS NULL AND m.definition LIKE ''%' + REPLACE(@ColumnName, '''', '''''') + '%'' AND m.definition LIKE ''%UPDATE%'')
          );';

    -- Временная таблица для перехвата результатов и проверки наличия найденных объектов
    CREATE TABLE #Results (
        SchemaName NVARCHAR(128),
        ObjectName NVARCHAR(128),
        ObjectType NVARCHAR(60),
        CodeDefinition NVARCHAR(MAX)
    );

    DECLARE @ExecSql NVARCHAR(MAX);
    SET @ExecSql = N'INSERT INTO #Results (SchemaName, ObjectName, ObjectType, CodeDefinition) ' + @Sql;

    EXECUTE (@ExecSql);

    -- Обработка ситуации, когда никто не изменяет столбец
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'Информация: Не найдено объектов БД, изменяющих столбец "' + @ColumnName + N'" в таблице "' + @SchemaName + N'.' + @TableName + N'".';
    END
    ELSE
    BEGIN
        SELECT SchemaName, ObjectName, ObjectType, CodeDefinition FROM #Results;
    END

    DROP TABLE #Results;
END;
GO

-- Вызов
EXECUTE FindObjectsModifyingColumn_exec @TableName = N'Contract', @ColumnName = N'Sale_info';

-- sp_executesql

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_sp
    @SchemaName NVARCHAR(128) = N'dbo',
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Валидация: проверка существования схемы
    IF NOT EXISTS (SELECT 1 FROM sys.schemas WHERE name = @SchemaName)
    BEGIN
        RAISERROR(N'Ошибка: Схема "%s" не существует в базе данных.', 16, 1, @SchemaName);
        RETURN;
    END

    -- 2. Валидация: проверка существования таблицы в указанной схеме
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = @TableName
    )
    BEGIN
        RAISERROR(N'Ошибка: Таблица "%s.%s" не существует в базе данных.', 16, 1, @SchemaName, @TableName);
        RETURN;
    END

    -- 3. Валидация: проверка существования столбца в таблице
    IF NOT EXISTS (
        SELECT 1 
        FROM sys.columns c
        JOIN sys.tables t ON c.object_id = t.object_id
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        WHERE s.name = @SchemaName AND t.name = @TableName AND c.name = @ColumnName
    )
    BEGIN
        RAISERROR(N'Ошибка: Столбец "%s" не найден в таблице "%s.%s".', 16, 1, @ColumnName, @SchemaName, @TableName);
        RETURN;
    END

    DECLARE @Sql NVARCHAR(MAX);

    -- Используем параметры в sp_executesql, что защищает от инъекций и ошибок экранирования
    SET @Sql = N'
        SELECT 
            s.name AS [SchemaName],
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            m.definition AS [CodeDefinition]
        FROM sys.objects o
        JOIN sys.schemas s 
            ON o.schema_id = s.schema_id
        JOIN sys.sql_modules m 
            ON o.object_id = m.object_id
        CROSS APPLY sys.dm_sql_referenced_entities(
            QUOTENAME(s.name) + N''.'' + QUOTENAME(o.name), 
            ''OBJECT''
        ) re
        WHERE o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'')
          AND OBJECT_SCHEMA_NAME(re.referenced_id) = @Schema
          AND re.referenced_entity_name = @Table
          AND (
              -- 1. Прямое изменение столбца
              (re.referenced_minor_name = @Column AND re.is_updated = 1)
              OR 
              -- 2. Модификация всей таблицы (UPDATE) с упоминанием столбца
              (re.referenced_minor_name IS NULL AND m.definition LIKE ''%'' + @Column + ''%'' AND m.definition LIKE ''%UPDATE%'')
          );';

    CREATE TABLE #Results (
        SchemaName NVARCHAR(128),
        ObjectName NVARCHAR(128),
        ObjectType NVARCHAR(60),
        CodeDefinition NVARCHAR(MAX)
    );

    INSERT INTO #Results (SchemaName, ObjectName, ObjectType, CodeDefinition)
    EXEC sp_executesql 
        @stmt = @Sql, 
        @params = N'@Schema NVARCHAR(128), @Table NVARCHAR(128), @Column NVARCHAR(128)', 
        @Schema = @SchemaName,
        @Table = @TableName, 
        @Column = @ColumnName;

    -- Обработка ситуации, когда никто не изменяет столбец
    IF @@ROWCOUNT = 0
    BEGIN
        PRINT N'Информация: Не найдено объектов БД, изменяющих столбец "' + @ColumnName + N'" в таблице "' + @SchemaName + N'.' + @TableName + N'".';
    END
    ELSE
    BEGIN
        SELECT SchemaName, ObjectName, ObjectType, CodeDefinition FROM #Results;
    END

    DROP TABLE #Results;
END;
GO

-- Вызов
EXEC FindObjectsModifyingColumn_sp @TableName = N'Contract', @ColumnName = N'Sale_info';

-- Тестовые функции для проверки

CREATE OR ALTER PROCEDURE sp_DecreaseCommission
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE [dbo].[Contract]
    SET [Comission] = [Comission] - 10;
END;
GO

-- Вызов
EXEC sp_DecreaseCommission;

CREATE OR ALTER FUNCTION fn_IncreaseCommission
(
    @CurrentCommission MONEY
)
RETURNS MONEY
AS
BEGIN
    RETURN @CurrentCommission + 10;
END;
GO

-- Вызов
UPDATE [dbo].[Contract]
SET [Comission] = dbo.fn_IncreaseCommission([Comission]);