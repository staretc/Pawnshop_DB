-- Заполнение тестовыми данными
SET IDENTITY_INSERT Item_Type ON;
INSERT INTO Item_Type (ID, Name) VALUES 
(888, N'Isolation'),
(777, N'Isolation')
SET IDENTITY_INSERT Item_Type OFF;

-- Проверка тестовых данных
SELECT * FROM Item_Type WHERE ID > 500 AND ID < 900;

-- Удаление тестовых данных
DELETE FROM Item_Type WHERE ID > 500 AND ID < 900;

ROLLBACK -- Для экстренного отката

-- ТРАНЗАКЦИИ
--=================
-- READ UNCOMMITED
--=================

-- ПОТЕРЯННЫЕ ИЗМЕНЕНИЯ --

-- Шаг 1: Читаем начальное значение
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
DECLARE @initial1 nvarchar(50);
SELECT @initial1 = Name FROM Item_Type WHERE ID = 888;
PRINT 'USER1 Прочитал: ' + @initial1;

-- Шаг 5: Читаем снова
DECLARE @current1 nvarchar(50);
SELECT @current1 = Name FROM Item_Type WHERE ID = 888;
PRINT 'USER1 Прочитал снова: ' + @current1;

-- Шаг 6: Обновляем на основе прочитанного (затрет изменения USER2)
DECLARE @initial1 nvarchar(50);
SELECT @initial1 = Name FROM Item_Type WHERE ID = 888;
UPDATE Item_Type SET Name = @initial1 + N'_USER1' WHERE ID = 888;
PRINT 'USER1 Записал: ' + @initial1 + N'_USER1';

-- Шаг 7: Фиксируем
COMMIT;
PRINT 'USER1 COMMIT';

-- Проверка результата
SELECT 'USER1 RESULT' as Источник, * FROM Item_Type WHERE ID = 888;

-- ГРЯЗНОЕ ЧТЕНИЕ --

-- Шаг 1: Грязное чтение - источник
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
BEGIN TRANSACTION;
UPDATE Item_Type SET Name = N'SOME DATA' WHERE ID = 888;
PRINT 'USER1: Изменено на SOME DATA (не зафиксировано)';

-- Шаг 3: Откатываем
ROLLBACK;
PRINT 'USER1: ROLLBACK';

--===============
-- READ COMMITED
--===============

-- ГРЯЗНОЕ ЧТЕНИЕ --

-- Шаг 1: Грязное чтение - источник
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
UPDATE Item_Type SET Name = N'SOME DATA' WHERE ID = 888;

-- Шаг 3: Откатываем
ROLLBACK;

-- НЕПОВТОРЯЮЩЕЕСЯ ЧТЕНИЕ --

-- Шаг 1: Первое чтение
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;
SELECT 'USER1 Первое чтение' as Этап, * FROM Item_Type WHERE ID = 888;

-- Шаг 3: Второе чтение
SELECT 'USER1 Второе чтение' as Этап, * FROM Item_Type WHERE ID = 888;

COMMIT;

--=================
-- REPEATABLE READ
--=================

-- НЕПОВТОРЯЮЩЕЕСЯ ЧТЕНИЕ --

-- Шаг 1: Первое чтение
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
SELECT 'USER1 Первое чтение' as Этап, * FROM Item_Type WHERE ID = 888;

-- Шаг 3: Второе чтение
SELECT 'USER1 Второе чтение' as Этап, * FROM Item_Type WHERE ID = 888;

COMMIT;

-- ФАНТОМНОЕ ЧТЕНИЕ --

-- Шаг 1: Первый запрос
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;
SELECT 'USER1 Первый запрос' as Этап, COUNT(*) as Количество, Name 
FROM Item_Type WHERE ID > 500 AND ID < 900 GROUP BY Name;

-- Шаг 3: Второй запрос
SELECT 'USER1 Второй запрос' as Этап, COUNT(*) as Количество, Name 
FROM Item_Type WHERE ID > 500 AND ID < 900 GROUP BY Name;

COMMIT;

--==============
-- SERIALIZABLE
--==============

-- ФАНТОМНОЕ ЧТЕНИЕ --

-- Шаг 1: Первый запрос
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;
SELECT 'USER1 Первый запрос' as Этап, COUNT(*) as Количество, Name 
FROM Item_Type WHERE ID > 500 AND ID < 900 GROUP BY Name;

-- Шаг 3: Второй запрос
SELECT 'USER1 Второй запрос' as Этап, COUNT(*) as Количество, Name 
FROM Item_Type WHERE ID > 500 AND ID < 900 GROUP BY Name;

COMMIT;