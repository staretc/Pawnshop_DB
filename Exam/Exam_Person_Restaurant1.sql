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


-- Insert data into node tables. Inserting into a node table is same as inserting into a regular table
INSERT INTO Person (ID, name)
    VALUES (1, 'John')
         , (2, 'Mary')
         , (3, 'Alice')
         , (4, 'Jacob')
         , (5, 'Julie');

INSERT INTO Restaurant (ID, name, city)
    VALUES (1, 'Taco Dell','Bellevue')
         , (2, 'Ginger and Spice','Seattle')
         , (3, 'Noodle Land', 'Redmond');

INSERT INTO City (ID, name, stateName)
    VALUES (1,'Bellevue','WA')
         , (2,'Seattle','WA')
         , (3,'Redmond','WA');

-- Insert into edge table. While inserting into an edge table,
-- you need to provide the $node_id from $from_id and $to_id columns.
/* Insert which restaurants each person likes */
INSERT INTO likes
    VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM Restaurant WHERE ID = 1), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 2), (SELECT $node_id FROM Restaurant WHERE ID = 2), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 3), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 4), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9)
         , ((SELECT $node_id FROM Person WHERE ID = 5), (SELECT $node_id FROM Restaurant WHERE ID = 3), 9);

/* Associate in which city live each person*/
INSERT INTO livesIn
    VALUES ((SELECT $node_id FROM Person WHERE ID = 1), (SELECT $node_id FROM City WHERE ID = 1))
         , ((SELECT $node_id FROM Person WHERE ID = 2), (SELECT $node_id FROM City WHERE ID = 2))
         , ((SELECT $node_id FROM Person WHERE ID = 3), (SELECT $node_id FROM City WHERE ID = 3))
         , ((SELECT $node_id FROM Person WHERE ID = 4), (SELECT $node_id FROM City WHERE ID = 3))
         , ((SELECT $node_id FROM Person WHERE ID = 5), (SELECT $node_id FROM City WHERE ID = 1));

/* Insert data where the restaurants are located */
INSERT INTO locatedIn
    VALUES ((SELECT $node_id FROM Restaurant WHERE ID = 1), (SELECT $node_id FROM City WHERE ID =1))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 2), (SELECT $node_id FROM City WHERE ID =2))
         , ((SELECT $node_id FROM Restaurant WHERE ID = 3), (SELECT $node_id FROM City WHERE ID =3));

/* Insert data into the friendOf edge */
INSERT INTO friendOf
    VALUES ((SELECT $NODE_ID FROM Person WHERE ID = 1), (SELECT $NODE_ID FROM Person WHERE ID = 2))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 2), (SELECT $NODE_ID FROM Person WHERE ID = 3))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 3), (SELECT $NODE_ID FROM Person WHERE ID = 1))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 4), (SELECT $NODE_ID FROM Person WHERE ID = 2))
         , ((SELECT $NODE_ID FROM Person WHERE ID = 5), (SELECT $NODE_ID FROM Person WHERE ID = 4));

-- 2. Добавить строки

-- Рёбра
INSERT INTO Person (ID, name)
    VALUES (6, 'Ruslan')
         , (7, 'Egor')
         , (8, 'Valera')

INSERT INTO Restaurant (ID, name, city)
    VALUES (1, 'Vaflya')
         , (2, 'Mnogo Ryby')
         , (3, 'Starik Hinkalych');

INSERT INTO City (ID, name, stateName)
    VALUES (1,'Phoenix','AZ')
         , (2,'Houston','TX')
         , (3,'Los Angeles','CA');

-- 3. Построить реляционную на основе графовой

--таблицы
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

-- 4. Вывести друзей любого уровня, проживающих в других городах