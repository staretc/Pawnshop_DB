ROLLBACK -- Для экстренного отката

-- ТРАНЗАКЦИИ
--=================
-- READ UNCOMMITED
--=================

-- ПОТЕРЯННЫЕ ИЗМЕНЕНИЯ --

-- Шаг 2: Читаем начальное значение
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
DECLARE @initial2 nvarchar(50);
SELECT @initial2 = Name FROM Item_Type WHERE ID = 888;
PRINT 'USER2 Прочитал: ' + @initial2;

-- Шаг 3: Обновляем первым
DECLARE @initial2 nvarchar(50);
SELECT @initial2 = Name FROM Item_Type WHERE ID = 888;
UPDATE Item_Type SET Name = @initial2 + N'_USER2' WHERE ID = 888;
PRINT 'USER2 Записал: ' + @initial2 + N'_USER2';

-- Шаг 4: Фиксируем раньше USER1
COMMIT;
PRINT 'USER2 COMMIT';

-- Проверка (здесь видим USER2_USER1, но ожидали USER2)
SELECT 'USER2 RESULT' as Источник, * FROM Item_Type WHERE ID = 888;

-- ГРЯЗНОЕ ЧТЕНИЕ --

-- Шаг 2: Читаем во время изменения T1 (грязное)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
SELECT 'USER2 прочитал' as Действие, * FROM Item_Type WHERE ID = 888;
COMMIT;
PRINT 'USER2: Принял решение на основе грязных данных';

-- Шаг 4: Проверка позже - данные уже другие
SELECT 'USER2 проверяет позже' as Действие, * FROM Item_Type WHERE ID = 888;

--===============
-- READ COMMITED
--===============

-- ГРЯЗНОЕ ЧТЕНИЕ --

-- Шаг 2: Читаем во время изменения T1 (грязное)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
SELECT 'USER2 прочитал' as Действие, * FROM Item_Type WHERE ID = 888;
COMMIT;
PRINT 'USER2: Принял решение на основе грязных данных';

-- Шаг 4: Проверка позже - данные уже другие
SELECT 'USER2 проверяет позже' as Действие, * FROM Item_Type WHERE ID = 888;

-- НЕПОВТОРЯЮЩЕЕСЯ ЧТЕНИЕ --

-- Шаг 2: Обновляем
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
UPDATE Item_Type SET Name = N'CHANGED' WHERE ID = 888;
COMMIT;
PRINT 'USER2: Изменение зафиксировано между чтениями T1';

--=================
-- REPEATABLE READ
--=================

-- НЕПОВТОРЯЮЩЕЕСЯ ЧТЕНИЕ --

-- Шаг 2: Обновляем
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
UPDATE Item_Type SET Name = N'CHANGED' WHERE ID = 888;
COMMIT;
PRINT 'USER2: Изменение зафиксировано между чтениями T1';

-- ФАНТОМНОЕ ЧТЕНИЕ --

-- Шаг 2: Вставляем новую строку в диапазон T1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
INSERT INTO Item_Type (ID, Name) VALUES (666, N'Isolation');
COMMIT;

--==============
-- SERIALIZABLE
--==============

-- ФАНТОМНОЕ ЧТЕНИЕ --

-- Шаг 2: Вставляем новую строку в диапазон T1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
INSERT INTO Item_Type (ID, Name) VALUES (666, N'Isolation');
COMMIT;