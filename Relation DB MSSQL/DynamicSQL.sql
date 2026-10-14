use [Pawnshop_DB]

-- Процедура, которая принимает в качестве параметра имя таблицы и имя поля в этой таблице.
-- Определить какие объекты в БД (процедуры, функции, триггеры) могут изменять содержимое этого поля.

-- обращаемся к:
    -- sys.tables - хранит информацию о таблицах в базе данных (используется для валидации существования таблицы)
    -- sys.schemas - хранит информацию о схемах базы данных (используется для проверки существования схемы и привязки объектов)
    -- sys.columns - хранит информацию о столбцах таблиц (используется для проверки существования запрашиваемого столбца)
    -- sys.objects - хранит информацию о созданных в БД объектах (таблицах, процедурах, функциях, триггерах и т.д.)
    -- sys.sql_modules - хранит определители и исходный код объекта (CREATE TABLE . . . / CREATE PROCEDURE . . .)
    -- sys.dm_sql_referenced_entities - хранит список всех сущностей (объектов или столбцов), на которые ссылается переданный ей в качестве параметра объект
    -- sp_MSforeachdb - системная хранимая процедура для последовательного выполнения SQL-инструкций во всех базах данных экземпляра SQL Server
    -- sp_executesql - системная хранимая процедура для безопасного выполнения динамического T-SQL кода с поддержкой параметров

-- EXEC

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_master_exec
    @SchemaName NVARCHAR(128) = N'dbo',
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #AllResults (
        DatabaseName   NVARCHAR(128),
        SchemaName     NVARCHAR(128),
        ObjectName     NVARCHAR(128),
        ObjectType     NVARCHAR(60),
        CodeDefinition NVARCHAR(MAX)
    );

    DECLARE @Command NVARCHAR(MAX);

    SET @Command = N'
    USE [?];

    IF EXISTS (
        SELECT 1 
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.columns c ON c.object_id = t.object_id
        WHERE s.name = N''' + REPLACE(@SchemaName, '''', '''''') + N'''
          AND t.name = N''' + REPLACE(@TableName, '''', '''''') + N'''
          AND c.name = N''' + REPLACE(@ColumnName, '''', '''''') + N'''
    )
    BEGIN
        INSERT INTO #AllResults (DatabaseName, SchemaName, ObjectName, ObjectType, CodeDefinition)
        SELECT 
            N''?'' AS DatabaseName,
            s.name AS SchemaName,
            o.name AS ObjectName,
            o.type_desc AS ObjectType,
            m.definition AS CodeDefinition
        FROM sys.objects o
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'')
          AND EXISTS (
              -- Заменено с CROSS APPLY на EXISTS во избежание дублирования строк
              SELECT 1 
              FROM sys.dm_sql_referenced_entities(
                  QUOTENAME(s.name) + N''.'' + QUOTENAME(o.name), 
                  ''OBJECT''
              ) re
              WHERE OBJECT_SCHEMA_NAME(re.referenced_id) = N''' + REPLACE(@SchemaName, '''', '''''') + N'''
                AND re.referenced_entity_name = N''' + REPLACE(@TableName, '''', '''''') + N'''
                AND (
                    (re.referenced_minor_name = N''' + REPLACE(@ColumnName, '''', '''''') + N''' AND re.is_updated = 1)
                    OR 
                    (re.referenced_minor_name IS NULL AND m.definition LIKE ''%'' + N''' + REPLACE(@ColumnName, '''', '''''') + N''' + ''%'' AND m.definition LIKE ''%UPDATE%'')
                )
          );
    END';

    EXEC sp_MSforeachdb @Command;

    IF NOT EXISTS (SELECT 1 FROM #AllResults)
    BEGIN
        PRINT N'Информация: Не найдено объектов, изменяющих столбец "' + @ColumnName + N'" в таблице "' + @SchemaName + N'.' + @TableName + N'" ни в одной из баз данных.';
    END
    ELSE
    BEGIN
        SELECT DatabaseName, SchemaName, ObjectName, ObjectType, CodeDefinition FROM #AllResults;
    END

    DROP TABLE #AllResults;
END;
GO

-- Вызов
EXECUTE FindObjectsModifyingColumn_master_exec @TableName = N'Contract', @ColumnName = N'Comission';

-- sp_executesql

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_master_sp
    @SchemaName NVARCHAR(128) = N'dbo',
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #AllResults (
        DatabaseName   NVARCHAR(128),
        SchemaName     NVARCHAR(128),
        ObjectName     NVARCHAR(128),
        ObjectType     NVARCHAR(60),
        CodeDefinition NVARCHAR(MAX)
    );

    DECLARE @InnerSql NVARCHAR(MAX);
    SET @InnerSql = N'
    IF EXISTS (
        SELECT 1 
        FROM sys.tables t
        JOIN sys.schemas s ON t.schema_id = s.schema_id
        JOIN sys.columns c ON c.object_id = t.object_id
        WHERE s.name = @Schema 
          AND t.name = @Table 
          AND c.name = @Column
    )
    BEGIN
        INSERT INTO #AllResults (DatabaseName, SchemaName, ObjectName, ObjectType, CodeDefinition)
        SELECT 
            DB_NAME() AS DatabaseName,
            s.name AS SchemaName,
            o.name AS ObjectName,
            o.type_desc AS ObjectType,
            m.definition AS CodeDefinition
        FROM sys.objects o
        JOIN sys.schemas s ON o.schema_id = s.schema_id
        JOIN sys.sql_modules m ON o.object_id = m.object_id
        WHERE o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'')
          AND EXISTS (
              -- Заменено с CROSS APPLY на EXISTS во избежание дублирования строк
              SELECT 1 
              FROM sys.dm_sql_referenced_entities(
                  QUOTENAME(s.name) + N''.'' + QUOTENAME(o.name), 
                  ''OBJECT''
              ) re
              WHERE OBJECT_SCHEMA_NAME(re.referenced_id) = @Schema
                AND re.referenced_entity_name = @Table
                AND (
                    (re.referenced_minor_name = @Column AND re.is_updated = 1)
                    OR 
                    (re.referenced_minor_name IS NULL AND m.definition LIKE ''%'' + @Column + ''%'' AND m.definition LIKE ''%UPDATE%'')
                )
          );
    END';

    DECLARE @Command NVARCHAR(MAX);
    SET @Command = N'
    USE [?];
    EXEC sp_executesql 
        @stmt = N''' + REPLACE(@InnerSql, '''', '''''') + N''',
        @params = N''@Schema NVARCHAR(128), @Table NVARCHAR(128), @Column NVARCHAR(128)'',
        @Schema = N''' + REPLACE(@SchemaName, '''', '''''') + N''',
        @Table = N''' + REPLACE(@TableName, '''', '''''') + N''',
        @Column = N''' + REPLACE(@ColumnName, '''', '''''') + N''';
    ';

    EXEC sp_MSforeachdb @Command;

    IF NOT EXISTS (SELECT 1 FROM #AllResults)
    BEGIN
        PRINT N'Информация: Не найдено объектов, изменяющих столбец "' + @ColumnName + N'" в таблице "' + @SchemaName + N'.' + @TableName + N'" ни в одной из баз данных.';
    END
    ELSE
    BEGIN
        SELECT DatabaseName, SchemaName, ObjectName, ObjectType, CodeDefinition FROM #AllResults;
    END

    DROP TABLE #AllResults;
END;
GO

-- Вызов
EXEC FindObjectsModifyingColumn_master_sp @TableName = N'Contract', @ColumnName = N'Comission';

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

create database test
use test