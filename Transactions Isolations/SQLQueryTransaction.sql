use [Pawnshop_DB]

--===========
-- ЗАДАНИЕ 1
--===========

-- Начало транзакции
BEGIN TRANSACTION MainTransaction;

-- Вставка тестового типа предмета
SET IDENTITY_INSERT Item_Type ON;
INSERT INTO Item_Type (ID, Name) VALUES (999, N'TEST');
SET IDENTITY_INSERT Item_Type OFF;

-- ТРАНЗАКЦИЯ
-- Проверка начального состояния
SELECT 'ДО ТРАНЗАКЦИИ' as Этап, COUNT(*) as Количество_предметов 
FROM Item WHERE Type_ID = 999;

    SAVE TRAN Before_Item;

    -- Вставка предмета
    INSERT INTO Item (Wear, Type_ID) VALUES (10, 999);

    -- Проверка: данные видны внутри транзакции
    SELECT 'ПОСЛЕ ВСТАВКИ' as Этап, 
           ID, Wear, Type_ID 
    FROM Item WHERE Type_ID = 999;

    -- Сохраним ID для проверки после отката
    DECLARE @TempTable TABLE (ID int);
    INSERT INTO @TempTable SELECT ID FROM Item WHERE Type_ID = 999;

    -- Полный откат транзакции
    ROLLBACK TRANSACTION Before_Item;

SELECT 'ПОСЛЕ ОТКАТА' as Этап, 
       COUNT(*) as Записей_в_Item,
       CASE WHEN COUNT(*) = 0 THEN 'Данные удалены корректно' ELSE 'ОШИБКА: данные остались!' END as Статус
FROM Item 
WHERE ID IN (SELECT ID FROM @TempTable);

COMMIT;

SELECT * FROM Item_Type

-- Транзакция с фиксацией
BEGIN TRANSACTION FinalTransaction;

    INSERT INTO Item (Wear, Type_ID) VALUES (11, 999);

    -- Проверка перед фиксацией
    SELECT 'ПЕРЕД ФИКСАЦИЕЙ' as Этап, 
           ID, Wear, Type_ID 
    FROM Item WHERE Type_ID = 999;

    -- ФИКСАЦИЯ
    COMMIT TRANSACTION FinalTransaction;

SELECT 'ДАННЫЕ ЗАФИКСИРОВАНЫ' as Этап, 
       ID, Wear, Type_ID
FROM Item 
WHERE Type_ID = 999
ORDER BY ID;
-- КОНЕЦ ТРАНЗАКЦИИ

-- Удаление тестовых предметов
DELETE FROM Item WHERE Type_ID = 999

-- Удаление тестового типа предмета
DELETE FROM Item_Type WHERE ID = 999