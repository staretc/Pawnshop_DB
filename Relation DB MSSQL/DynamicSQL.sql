use [Pawnshop_DB]

-- Процедура, которая принимает в качестве параметра имя таблицы и имя поля в этой таблице.
-- Определить какие объекты в БД (процедуры, функции, триггеры) могут изменять содержимое этого поля.

-- обращаемся к:
    -- sys.sql_expression_dependencies - хранит связи [процедура/функция/триггер] -> [таблица] / [поле таблицы]
    -- sys.objects - хранит информацию о созданных в БД таблицах, процедурах, функциях, триггерах и тд
    -- sys.sql_modules - хранит определители и исходный код объекта (CREATE TABLE . . . / CREATE PROCEDURE . . .)
    -- sys.columns - хранит информацию обо всех столбцах всех таблиц БД

-- EXEC

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_exec
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX);

    -- Формируем запрос с экранированием входных значений при помощи QUOTENAME
    SET @Sql = N'
        SELECT DISTINCT
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            m.definition AS [CodeDefinition]
        FROM sys.sql_expression_dependencies d
        JOIN sys.objects o 
            ON d.referencing_id = o.object_id
        JOIN sys.sql_modules m 
            ON o.object_id = m.object_id
        JOIN sys.columns c 
            ON d.referenced_minor_id = c.column_id 
           AND d.referenced_id = c.object_id
        WHERE d.referenced_id = OBJECT_ID(' + QUOTENAME(@TableName, '''') + ')
          AND c.name = ' + QUOTENAME(@ColumnName, '''') + '
          AND o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'');'; -- смотрим только на процедуры, функции, триггеры

    EXECUTE (@Sql);
END;
GO

-- sp_executesql

CREATE OR ALTER PROCEDURE FindObjectsModifyingColumn_sp
    @TableName NVARCHAR(128),
    @ColumnName NVARCHAR(128)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Sql NVARCHAR(MAX);

    -- Формируем динамический запрос с параметрами @Table и @Column
    SET @Sql = N'
        SELECT DISTINCT
            o.name AS [ObjectName],
            o.type_desc AS [ObjectType],
            m.definition AS [CodeDefinition]
        FROM sys.sql_expression_dependencies d
        JOIN sys.objects o 
            ON d.referencing_id = o.object_id
        JOIN sys.sql_modules m 
            ON o.object_id = m.object_id
        JOIN sys.columns c 
            ON d.referenced_minor_id = c.column_id 
           AND d.referenced_id = c.object_id
        WHERE d.referenced_id = OBJECT_ID(@Table)
          AND c.name = @Column
          AND o.type IN (''P'', ''FN'', ''IF'', ''TF'', ''TR'');';

    EXEC sp_executesql 
        @stmt = @Sql, 
        @params = N'@Table NVARCHAR(128), @Column NVARCHAR(128)', 
        @Table = @TableName, 
        @Column = @ColumnName;
END;
GO