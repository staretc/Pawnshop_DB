-- 1.

-- Create NODE tables
CREATE TABLE Person (
  ID INTEGER PRIMARY KEY,
  name VARCHAR(100)
) AS NODE;

CREATE TABLE Restaurant (
  ID INTEGER NOT NULL,
  name VARCHAR(100),
  city VARCHAR(100)
) AS NODE;

CREATE TABLE City (
  ID INTEGER PRIMARY KEY,
  name VARCHAR(100),
  stateName VARCHAR(100)
) AS NODE;

-- Create EDGE tables.
CREATE TABLE likes (rating INTEGER) AS EDGE;
CREATE TABLE friendOf AS EDGE;
CREATE TABLE livesIn AS EDGE;
CREATE TABLE locatedIn AS EDGE;

-- 2.
-- Insert data into node tables. Inserting into a node table is same as inserting into a regular table
INSERT INTO Person (ID, name)
    VALUES (1, 'John')
         , (2, 'Mary')
         , (3, 'Alice')
         , (4, 'Jacob')
         , (5, 'Julie')
         , (6, 'Julie1')
         , (7, 'Julie2')
         , (8, 'Julie3');

INSERT INTO Restaurant (ID, name, city)
    VALUES (1, 'Taco Dell','Bellevue')
         , (2, 'Ginger and Spice','Seattle')
         , (3, 'Noodle Land', 'Redmond')
         , (4, 'Noodle Land1', 'Redmond1')
         , (5, 'Noodle Land2', 'Redmond3')
         , (6, 'Noodle Land3', 'Redmond2');

INSERT INTO City (ID, name, stateName)
    VALUES (1,'Bellevue','WA')
         , (2,'Seattle','WA')
         , (3,'Redmond','WA')
         , (4,'Redmond1','WA')
         , (5,'Redmond2','WA')
         , (6,'Redmond3','WA');

-- Insert into edge table. While inserting into an edge table,
-- you need to provide the $node_id from $from_id and $to_id columns.
/* Insert which restaurants each person likes */
INSERT INTO likes
    VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM Restaurant WHERE ID = 1), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 2), (SELECT $node_id FROM Restaurant WHERE ID = 2), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 3), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 4), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 5), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 6), (SELECT $node_id FROM Restaurant WHERE ID = 4), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 7), (SELECT $node_id FROM Restaurant WHERE ID = 5), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 8), (SELECT $node_id FROM Restaurant WHERE ID = 6), 9);

/* Associate in which city live each person*/
INSERT INTO livesIn
    VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM City WHERE ID = 1))
         , ((SELECT $node_id FROM Person WHERE ID = 2), (SELECT $node_id FROM City WHERE ID = 2))
         , ((SELECT $node_id FROM Person WHERE ID = 3), (SELECT $node_id FROM City WHERE ID = 3))
         , ((SELECT $node_id FROM Person WHERE ID = 4), (SELECT $node_id FROM City WHERE ID = 3))
         , ((SELECT $node_id FROM Person WHERE ID = 5), (SELECT $node_id FROM City WHERE ID = 1))
         , ((SELECT $node_id FROM Person WHERE ID = 6), (SELECT $node_id FROM City WHERE ID = 4))
         , ((SELECT $node_id FROM Person WHERE ID = 7), (SELECT $node_id FROM City WHERE ID = 6))
         , ((SELECT $node_id FROM Person WHERE ID = 8), (SELECT $node_id FROM City WHERE ID = 5));

/* Insert data where the restaurants are located */
INSERT INTO locatedIn
    VALUES ((SELECT $node_id FROM Restaurant WHERE ID = 1), (SELECT $node_id FROM City WHERE ID =1))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 2), (SELECT $node_id FROM City WHERE ID =2))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 3), (SELECT $node_id FROM City WHERE ID =3))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 4), (SELECT $node_id FROM City WHERE ID =6))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 5), (SELECT $node_id FROM City WHERE ID =5))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 6), (SELECT $node_id FROM City WHERE ID =4));

/* Insert data into the friendOf edge */
INSERT INTO friendOf
    VALUES ((SELECT $NODE_ID FROM Person WHERE ID = 1), (SELECT $NODE_ID FROM Person WHERE ID = 2))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 2), (SELECT $NODE_ID FROM Person WHERE ID = 3))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 3), (SELECT $NODE_ID FROM Person WHERE ID = 1))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 4), (SELECT $NODE_ID FROM Person WHERE ID = 2))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 5), (SELECT $NODE_ID FROM Person WHERE ID = 4))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 6), (SELECT $NODE_ID FROM Person WHERE ID = 7))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 7), (SELECT $NODE_ID FROM Person WHERE ID = 8))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 8), (SELECT $NODE_ID FROM Person WHERE ID = 7));

-- 3.
-- Create NODE tables
create table r_City (
    ID INTEGER PRIMARY KEY,
    name VARCHAR(100),
    stateName VARCHAR(100)
)

create table r_Person (
    ID INTEGER PRIMARY KEY,
    name VARCHAR(100),
    CityID int foreign key references r_City(ID)
)

create table r_Restaurant (
    ID INTEGER PRIMARY KEY,
    name VARCHAR(100),
    CityID int foreign key references r_City(ID)
)

create table r_Friends (
    PersonID int foreign key references r_Person(ID),
    FriendID int foreign key references r_Person(ID)
)

create table r_LikesRestaurant (
    rating INTEGER,
    PersonID int foreign key references r_Person(ID),
    RestaurantID int foreign key references r_Restaurant(ID)
)

create table r_LikesCity (
    rating INTEGER,
    PersonID int foreign key references r_Person(ID),
    CityID int foreign key references r_City(ID)
)

-- заполнение
insert into [dbo].[r_City] (ID, name, stateName)
select ID, Name, stateName
from [dbo].[City]

insert into [dbo].[r_Person] (ID, name, CityID)
select p.ID, p.name, rc.ID
from [dbo].[Person] p, [dbo].[City] c, [dbo].[livesIn] li, [dbo].[r_City] rc
where match (p-(li)->c)
and c.ID = rc.ID

insert into [dbo].[r_Restaurant] (ID, name, CityID)
select r.ID, r.name, rc.ID
from [dbo].[Restaurant] r, [dbo].[locatedIn] li, [dbo].[City] c, [dbo].[r_City] rc
where match (r-(li)->c)
and c.ID = rc.ID

insert into [dbo].[r_Friends] (PersonID, FriendID)
select rp1.ID, rp2.ID
from [dbo].[Person] p1, [dbo].[friendOf] fo, [dbo].[Person] p2, [dbo].[r_Person] rp1, [dbo].[r_Person] rp2
where match (p1-(fo)->p2)
and p1.ID = rp1.ID
and p2.ID = rp2.ID

insert into [dbo].[r_LikesRestaurant] (rating, PersonID, RestaurantID)
select l.rating, rp.ID, rr.ID
from [dbo].[Person] p, [dbo].[likes] l, [dbo].[Restaurant] r, [dbo].[r_Person] rp, [dbo].[r_Restaurant] rr
where match (p-(l)->r)
and p.ID = rp.ID
and r.ID = rr.ID

insert into [dbo].[r_LikesCity] (rating, PersonID, CityID)
select l.rating, rp.ID, rc.ID
from [dbo].[Person] p, [dbo].[likes] l, [dbo].[City] c, [dbo].[r_Person] rp, [dbo].[r_City] rc
where match (p-(l)->c)
and p.ID = rp.ID
and c.ID = rc.ID

-- 4. инфорация о ваших друзьях любого уровня, проживающих в дргуих гоодах
SELECT
    r_Person.name AS PersonName,
    STRING_AGG(Person2.name, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
    c.[name],c1.name
FROM
    livesIn AS lin,
    livesIn AS lin1,
    friendOf FOR PATH AS fo,
    Person AS r_Person,
    Person FOR PATH  AS Person2,
    City c,
    City c1
WHERE MATCH(SHORTEST_PATH(r_Person(-(fo)->Person2)+))
AND r_Person.name = 'Julie1' and match(r_Person-(lin)->c) and match(LAST_NODE(Person2)-(lin1)->c1) and c.[name] <> c1.[name]


-- 5. информация о наиболее известных ресторанах. о ресторане знает человек, который его посещает и все его друзья первого уровня
WITH PeopleWhoKnow AS (
    -- Группа 1: Люди, которые сами посещают (лайкают) ресторан
    SELECT PersonID, RestaurantID
    FROM r_LikesRestaurant
    
    UNION
    
    -- Группа 2: Друзья тех, кто посещает ресторан (если посетитель записан в PersonID)
    SELECT f.FriendID AS PersonID, lr.RestaurantID
    FROM r_LikesRestaurant lr
    JOIN r_Friends f ON lr.PersonID = f.PersonID
    
    UNION
    
    -- Группа 3: Друзья тех, кто посещает ресторан (если посетитель записан в FriendID)
    SELECT f.PersonID AS PersonID, lr.RestaurantID
    FROM r_LikesRestaurant lr
    JOIN r_Friends f ON lr.PersonID = f.FriendID
),
RestaurantFame AS (
    -- Шаг 2: Группируем по ресторанам и считаем количество уникальных знающих людей
    SELECT RestaurantID, COUNT(DISTINCT PersonID) AS PeopleCount
    FROM PeopleWhoKnow
    GROUP BY RestaurantID
)
-- Шаг 3: Выводим информацию о самых известных ресторанах
SELECT TOP 1 WITH TIES
    r.ID AS RestaurantID,
    r.name AS RestaurantName,
    c.name AS CityName,
    rf.PeopleCount AS TotalPeopleWhoKnow
FROM RestaurantFame rf
JOIN r_Restaurant r ON rf.RestaurantID = r.ID
JOIN r_City c ON r.CityID = c.ID
ORDER BY rf.PeopleCount DESC;

-- 6. Напишите хранимую процедуру или функцию, которая для каждого ресторана выведет список приглашенных. В список попадают персоны, проживающие в том же городе и их друзья первого уровня.
CREATE PROCEDURE GetRestaurantInvitees
AS
BEGIN
    -- Отключаем вывод количества строк для оптимизации производительности
    SET NOCOUNT ON;

    WITH InvitedList AS (
        -- Персоны, которые проживают в том же городе, что и ресторан
        SELECT 
            r.name AS RestaurantName,
            c.name AS CityName,
            p.name AS InviteeName,
            'Resident' AS ConnectionType
        FROM 
            Restaurant r, 
            locatedIn li, 
            City c, 
            livesIn lv, 
            Person p
        WHERE 
            MATCH(r-(li)->c AND p-(lv)->c)

        UNION

        -- Друзья первого уровня тех людей, которые живут в городе ресторана
        SELECT 
            r.name AS RestaurantName,
            c.name AS CityName,
            p2.name AS InviteeName,
            'Friend of Resident' AS ConnectionType
        FROM 
            Restaurant r, 
            locatedIn li, 
            City c, 
            livesIn lv, 
            Person p1, 
            friendOf f, 
            Person p2
        WHERE 
            MATCH(r-(li)->c AND p1-(lv)->c AND p1-(f)->p2)
    )
    SELECT 
        RestaurantName,
        CityName,
        InviteeName,
        ConnectionType
    FROM 
        InvitedList
    ORDER BY 
        RestaurantName, 
        InviteeName;
END;
GO

-- 7. Создайте триггер в реляционной модели, который позволяет лайкать другой город, только после того, как будет поставлен лайк городу в котором он проживает, назначить руководителем сотрудника, который работает в другом отделе.
CREATE TRIGGER trg_CheckCityLike
ON r_LikesCity
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Проверяем, есть ли среди вставленных/измененных записей нарушители правила
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN r_Person p ON i.PersonID = p.ID
        WHERE 
            -- Условие 1: Пользователь лайкает НЕ тот город, в котором живет
            i.CityID <> p.CityID 
            AND 
            -- Условие 2: В таблице лайков отсутствует лайк для его родного города
            NOT EXISTS (
                SELECT 1
                FROM r_LikesCity lc
                WHERE lc.PersonID = i.PersonID
                  AND lc.CityID = p.CityID
            )
    )
    BEGIN
        -- Если нашли хотя бы одну строку-нарушителя, откатываем всю транзакцию
        PRINT 'Операция отменена: вы не можете поставить лайк другому городу, пока не лайкнули город своего проживания.';
        ROLLBACK TRANSACTION;
    END
END;
GO

-- ==========================================
-- ПРЕОБРАЗОВАНИЕ РЕЛЯЦИОННОЙ МОДЕЛИ В JSON ДЛЯ MONGODB
-- ==========================================

SELECT 
    p.ID AS PersonId,
    p.name AS PersonName,
    
    -- Информация о городе проживания
    JSON_QUERY((
        SELECT 
            c.ID AS CityId,
            c.name AS CityName,
            c.stateName AS StateName
        FROM r_City c
        WHERE c.ID = p.ID_city
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )) AS City,
    
    -- Список друзей
    JSON_QUERY((
        SELECT 
            f.ID_person2 AS FriendId,
            p2.name AS FriendName,
            c2.name AS FriendCity
        FROM friendOf1 f
        JOIN r_Person p2 ON f.ID_person2 = p2.ID
        JOIN r_City c2 ON p2.ID_city = c2.ID
        WHERE f.ID_person1 = p.ID
        FOR JSON PATH
    )) AS Friends,
    
    -- Список любимых ресторанов
    JSON_QUERY((
        SELECT 
            r.ID AS RestaurantId,
            r.name AS RestaurantName,
            l.rating AS Rating,
            c3.name AS RestaurantCity
        FROM r_likes l
        JOIN r_Restaurant r ON l.ID_restaurant = r.ID
        JOIN r_City c3 ON r.ID_city = c3.ID
        WHERE l.ID_person = p.ID
        FOR JSON PATH
    )) AS LikedRestaurants,
    
    -- Количество друзей
    (SELECT COUNT(*) FROM friendOf1 WHERE ID_person1 = p.ID) AS FriendsCount,
    
    -- Количество любимых ресторанов
    (SELECT COUNT(*) FROM r_likes WHERE ID_person = p.ID) AS LikedRestaurantsCount

FROM r_Person p
WHERE p.ID IS NOT NULL
FOR JSON PATH;