use [Pawnshop_DB]

-- Процедура, которая принимает в качестве параметра имя таблицы и имя поля в этой таблице.
-- Определить какие объекты в БД (процедуры, функции, триггеры) могут изменять содержимое этого поля.

-- обращаемся к:
    -- sys.objects - хранит информацию о созданных в БД таблицах, процедурах, функциях, триггерах и тд
    -- sys.sql_modules - хранит определители и исходный код объекта (CREATE TABLE . . . / CREATE PROCEDURE . . .)
    -- sys.dm_sql_referenced_entities - хранит список всех сущностей (объектов или столбцов), на которые ссылается переданный ей в качестве параметра объект

-- EXEC

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_exec
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX);

    SET @Sql = N'
        SELECT DISTINCT
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            m.definition AS [CodeDefinition]
        FROM sys.objects o
        JOIN sys.sql_modules m 
            ON o.object_id = m.object_id
        CROSS APPLY sys.dm_sql_referenced_entities(
            QUOTENAME(OBJECT_SCHEMA_NAME(o.object_id)) + N''.'' + QUOTENAME(o.name), 
            ''OBJECT''
        ) re
        WHERE o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'')
          AND re.referenced_entity_name = ' + QUOTENAME(@TableName, '''') + '
          AND (
              -- Проверяем, что столбец прямо изменяется (is_updated = 1)
              (re.referenced_minor_name = ' + QUOTENAME(@ColumnName, '''') + ' AND re.is_updated = 1)
              OR 
              -- Если модифицируется вся таблица (например, UPDATE без явной детализации колонок)
              (re.referenced_minor_name IS NULL AND m.definition LIKE ''%' + @ColumnName + '%'' AND m.definition LIKE ''%UPDATE%'')
          );';

    EXECUTE (@Sql);
END;
GO

-- Вызов
EXECUTE FindObjectsModifyingColumn_exec @TableName = N'Contract', @ColumnName = N'Comission';

-- sp_executesql

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_sp
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX);

    SET @Sql = N'
        SELECT DISTINCT
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            m.definition AS [CodeDefinition]
        FROM sys.objects o
        JOIN sys.sql_modules m 
            ON o.object_id = m.object_id
        CROSS APPLY sys.dm_sql_referenced_entities(
            QUOTENAME(OBJECT_SCHEMA_NAME(o.object_id)) + N''.'' + QUOTENAME(o.name), 
            ''OBJECT''
        ) re
        WHERE o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'')
          AND re.referenced_entity_name = @Table
          AND (
              -- Проверяем точный флаг изменения столбца
              (re.referenced_minor_name = @Column AND re.is_updated = 1)
              OR 
              -- Запасной вариант для общих UPDATE-запросов по таблице
              (re.referenced_minor_name IS NULL AND m.definition LIKE ''%'' + @Column + ''%'' AND m.definition LIKE ''%UPDATE%'')
          );';

    EXEC sp_executesql 
        @stmt = @Sql, 
        @params = N'@Table NVARCHAR(128), @Column NVARCHAR(128)', 
        @Table = @TableName, 
        @Column = @ColumnName;
END;
GO

-- Вызов
EXEC FindObjectsModifyingColumn_sp @TableName = N'Contract', @ColumnName = N'Comission';

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