use [Pawnshop_DB]

create table Item_Type(
	ID int identity(1,1) primary key,
	[Name] nvarchar(50) not null
)

create table Item(
	ID int identity(1,1) primary key,
	Wear int not null check (Wear >= 0 and Wear <= 100),
	[Type_ID] int not null foreign key references [dbo].[Item_Type](ID) on update cascade
)

create table Material(
	Periodic_Table_Name nvarchar(15) primary key,
	Cost_Per_Gramm money not null
)

create table Client(
	SNILS int primary key,
	Fullname nvarchar(50) not null,
	[Address] nvarchar(50) not null,
	Passport_Series smallint not null,
	Passport_ID int not null,
	unique(Passport_Series, Passport_ID)
)

create table Item_Contains_Material(
	ID int identity(1,1) primary key,
	Item_ID int not null foreign key references [dbo].[Item](ID) on update cascade,
	Material_Name nvarchar(15) not null foreign key references [dbo].[Material](Periodic_Table_Name) on update cascade,
	[Weight] float(8) not null
)

create table [Contract](
	Number int identity(1,1) primary key,
	[Date] date not null,
	Date_Of_Redemption date not null,
	Comission money not null,
	Redemption_Info nvarchar(15) not null,
	Sale_Info nvarchar(15) not null,
	Client_SNILS int not null foreign key references [dbo].[Client](SNILS) on update cascade,
	Item_ID int not null foreign key references [dbo].[Item](ID) on update cascade,
	constraint Check_Redemption_Date check (Date_Of_Redemption >= [Date])
)

ALTER TABLE [Contract]
ADD CONSTRAINT check_redemption_info CHECK (Redemption_Info in (N'Not redeemed',N'Redeemed'));
ALTER TABLE [Contract]
ADD CONSTRAINT check_sale_info CHECK (Sale_Info in (N'Not on sale',N'On sale',N'Sold'));
ALTER TABLE [Contract]
ADD CONSTRAINT check_info_conflict CHECK (
	(Redemption_Info = N'Redeemed' and Sale_Info != N'On sale') or 
	(Redemption_Info = N'Redeemed' and Sale_Info != N'Sold') or 
	(Redemption_Info = N'Not redeemed')
);

insert into Item_Type (Name)
values
	(N'Кольцо'),
	(N'Цепочка'),
	(N'Часы'),
	(N'Слиток'),
	(N'Монета'),
	(N'Серьги')

insert into Material
values
	(N'Argentum', 1.03),
	(N'Aurum', 93.07),
	(N'Cuprum', 0.01)
	(N'Ferrum', 0.8),
	(N'Iridium', 187.23),
	(N'Palladium', 42.68),
	(N'Platinum', 31.45),
	(N'Rhodium', 438.6),
	(N'Titanium', 0.21),
	(N'Tungsten', 0.09),

insert into Item (Wear, [Type_ID])
values
	(0,1),
	(20,1),
	(1,3),
	(6,5),
	(9,2),
	(69,5),
	(88,4),
	(42,3),
	(14,4),
	(28,2),
	(16,5),
	(14,3),
	(32,5),
	(21,3)
	

insert into Item_Contains_Material (Item_ID, Material_Name, [Weight])
values	
	(1,N'Aurum',5),
	(2,N'Platinum',4),
	(3,N'Aurum',150),
	(3,N'Argentum',100),
	(3,N'Iridium',5),
	(4,N'Cuprum',10),
	(5,N'Platinum',30),
	(6,N'Aurum',8),
	(7,N'Aurum',1000),
	(8,N'Platinum',200),
	(8,N'Aurum',50),
	(9,N'Cuprum',500),
	(10,N'Iridium',50),
	(10,N'Ferrum',55),
	(11,N'Aurum',30),
	(12,N'Titanium',130),
	(13,N'Argentum',25),
	(13,N'Platinum',3),
	(14,N'Cuprum',125),
	(14,N'Aurum',10)

insert into Client
values
	(101,N'Волкова Анастасия Дмитриевна',N'Бабича, 11к5',1001,100001),
	(102,N'Телушкин Роман Александрович',N'Ньютона, 28',1001,100002),
	(103,N'Опарин Егор Александрович',N'Слепнёва, 20',1001,100003),
	(104,N'Немчанинов Руслан Владимирович',N'Родниковая, 11',1001,100004),
	(105,N'Телушкин Иван Александрович',N'Ньютона, 28',1001,100005),
	(106,N'Григорьев Валерий Алексеевич',N'Ярославская, 150',1001,100006),
	(107,N'Руднева Татьяна Алексеевна',N'Слепнёва, 16',1001,100007),
	(108,N'Немчанинов Владимир Витальевич',N'Родниковая, 11',1001,100008),
	(109,N'Латыпов Арсен Айдарович',N'Гагарина, 52',1001,100009),
	(110,N'Энэнов Энэн Энэнович',N'Энэнова, 0',1001,100010),
	(111,N'Зубенко Михаил Петрович',N'Мафиозово, 777',1002,100001)

insert into [Contract] ([Date], Date_Of_Redemption, Comission, Redemption_Info, Sale_Info, Client_SNILS, Item_ID)
values
	('2025-08-31','2025-09-30',200.0,N'Redeemed',N'Not on sale',101,1),
	('2025-08-31','2025-09-30',250.5,N'Not redeemed',N'Not on sale',104,2),
	('2025-04-20','2025-05-20',100.0,N'Not redeemed',N'Sold',102,3),
	('2025-07-31','2025-08-31',200.0,N'Not redeemed',N'On sale',103,4),
	('2025-07-31','2025-09-30',200.0,N'Redeemed',N'Not on sale',103,5),
	('2025-08-10','2025-10-10',250.0,N'Redeemed',N'Not on sale',104,6),
	('2025-08-21','2025-09-21',270.0,N'Redeemed',N'Not on sale',104,7),
	('2025-05-14','2025-07-14',280.0,N'Not redeemed',N'On sale',105,8),
	('2025-06-30','2025-07-30',150.0,N'Redeemed',N'Not on sale',106,9),
	('2024-12-29','2025-01-29',140.0,N'Redeemed',N'Not on sale',107,10),
	('2025-02-28','2025-03-28',190.0,N'Redeemed',N'Not on sale',108,11),
	('2025-04-18','2025-06-18',400.0,N'Not redeemed',N'Sold',109,12),
	('2025-07-23','2025-09-23',340.0,N'Redeemed',N'Not on sale',109,13),
	('2025-03-12','2025-04-12',220.0,N'Not redeemed',N'On sale',110,14)

select *
from Item_Contains_Material
select *
from Material
select *
from Client
select *
from [Contract]
order by Item_ID
select *
from Item
left join Item_Contains_Material on Item.ID = Item_Contains_Material.Item_ID

-- Лаба 3
-- ЧАСТЬ 1
-- 1.
-- 1.1 Таблица [Contract], отсортируем по дате контракта по возрастанию
-- и по дате выкупа по убыванию
-- FIXED --

select *
from [Contract]
order by [Date], Date_Of_Redemption desc

-- 1.2 Таблица [Contract], Условия:
-- FIXED --
-- (1) Выведем контракты, оформленные раньше 1 августа 2025

select *
from [Contract]
where [Date] < '2025-08-01'

-- (2) Вывести контракты, товары в которых были проданы ломбардом

select *
from [Contract]
where Sale_Info = N'Sold'

-- 1.3 Таблица [Contract]
-- (1) Выведем общее количество контрактов с информацией о минимальной, максимальной и средней сумме комиссии

select 
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]

-- (2) Для каждого статуса выкупа выведем общее количество контрактов 
-- с информацией о минимальной, максимальной и средней сумме комиссии

select 
	Redemption_Info,
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]
group by Redemption_Info

-- (3) Для каждой пары статуса выкупа и статуса продажи выведем общее количество контрактов 
-- с информацией о минимальной, максимальной и средней сумме комиссии

select 
	Redemption_Info,
	Sale_Info,
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]
group by Redemption_Info, Sale_Info


-- 1.4 Таблица [Contract]
-- (1) группировка с подытогом (rollup) по Client_SNILS и Sale_Info
-- Подытог будет для каждого Client_SNILS и всей выборки целиком

select 
	isnull(cast (Client_SNILS as nvarchar), N'TOTAL') as Client_SNILS,	-- заполняем TOTAL через isnull
	iif(grouping(Sale_Info) = 1, N'TOTAL', Sale_Info) as Sale_Info,		-- заполняем TOTAL через grouping
	count(Item_ID) as Items
from [Contract]
group by rollup (Client_SNILS, Sale_Info)

-- (2) группировка с подытогом (cube) по СНИЛСу и Инфо о продаже
-- Подытог будет для каждого Sale_Info и каждого Client_SNILS

select 
	isnull(cast (Client_SNILS as nvarchar), N'TOTAL') as Client_SNILS,	-- заполняем TOTAL через isnull
	iif(grouping(Sale_Info) = 1, N'TOTAL', Sale_Info) as Sale_Info,		-- заполняем TOTAL через grouping
	count(Item_ID) as Items
from [Contract]
group by cube (Client_SNILS, Sale_Info)

-- (3) группировка с выборкой всех групп (all), где подсчитываем клиентов, группируя по Sale_Info
-- FIXED --

select
	count(Client_SNILS) as Clients,
	Sale_Info
from [Contract]
where Sale_Info = N'On Sale'	-- делаем выборку только тех, где статус продажи = 'On Sale'
group by all Sale_Info			-- тогда в Clients будут нули везде кроме выбранного Sale_Info

-- 1.5 Таблица Material, вывести названия, где нет последовательности "iu"

select Periodic_Table_Name
from Material
where Periodic_Table_Name not like '%iu%'

-- 2.
-- 2.1 
-- FIXED --
-- (1) Выведем таблицу Item, но вместо ID типа товара выведем название этого типа

select
	Item.ID as ID,
	Item.Wear as Wear,
	Item_Type.[Name] as [Type_Name]
from Item, Item_Type
where Item.[Type_ID] = Item_Type.ID

-- (2) Выведем таблицу контрактов, но вместо СНИЛС клиена выведем его ФИО

select
	[Contract].Number,
	[Contract].[Date],
	[Contract].Date_Of_Redemption,
	[Contract].Comission,
	[Contract].Redemption_Info,
	[Contract].Sale_Info,
	Client.Fullname as Client_Name,
	[Contract].Item_ID
from [Contract], Client
where [Contract].Client_SNILS = Client.SNILS

-- 2.2 Меняем запросы из 2.1 c where на join
-- (1)

select
	Item.ID as ID,
	Item.Wear as Wear,
	Item_Type.[Name] as [Type_Name]
from Item join Item_Type on Item.[Type_ID] = Item_Type.ID

-- (2)
-- FIXED --

select
	[Contract].Number,
	[Contract].[Date],
	[Contract].Date_Of_Redemption,
	[Contract].Comission,
	[Contract].Redemption_Info,
	[Contract].Sale_Info,
	Client.Fullname as Client_Name,
	[Contract].Item_ID
from [Contract] join Client on [Contract].Client_SNILS = Client.SNILS

-- 2.3 
-- (1) Узнаем, какие договоры есть у всех клиентов из базы

select
	Client.SNILS as SNILS,
	isnull(cast([Contract].Number as varchar), 'No Contracts') as Contract_Number
from Client left join [Contract] on Client.SNILS = [Contract].Client_SNILS

-- (2) Узнаем, какие контракты были заключены на изделия всех типов

select
	isnull(cast([Contract].Number as varchar), 'No Contracts') as Contract_Number,
	isnull(cast(Item.ID as varchar), 'No Items') as Item_ID,
	Item_Type.Name as Item_Type
from  Item_Type
left join Item on Item_Type.ID = Item.Type_ID
left join [Contract] on Item.ID = [Contract].Item_ID

-- 2.4 Перепишем запросы из 2.3 на right join
-- (1)

select
	Client.SNILS as SNILS,
	isnull(cast([Contract].Number as varchar), 'No Contracts') as Contract_Number
from [Contract] right join Client on Client.SNILS = [Contract].Client_SNILS

-- (2)

select
	isnull(cast([Contract].Number as varchar), 'No Contracts') as Contract_Number,
	isnull(cast(Item.ID as varchar), 'No Items') as Item_ID,
	Item_Type.Name as Item_Type
from [Contract] 
join Item on Item.ID = [Contract].Item_ID 
right join Item_Type on Item_Type.ID = Item.Type_ID

-- 2.5 
-- FIXED --
-- (1) Посчитаем количество контрактов для каждого клиента

select
	Client.Fullname as [Name],
	count([Contract].Number) as Num_Of_Contracts
from Client 
left join [Contract] on Client.SNILS = [Contract].Client_SNILS
group by Client.Fullname

-- (2) Посчитаем наибольшие комиссионные с одного заказа для каждого клиента

select
	Client.Fullname as Client,
	isnull(cast(max([Contract].Comission) as varchar), 'No Contracts') as Max_Comission
from Client 
left join [Contract] on Client.SNILS = [Contract].Client_SNILS
group by Client.Fullname

-- 2.6 
-- FIXED --
-- (1) Найти клиентов, у которых общая комиссия по всем контрактам превышает 500

select 
    Client.Fullname,
    sum([Contract].Comission) as Total_Commission
from Client
join [Contract] on Client.SNILS = [Contract].Client_SNILS
group by Client.Fullname
having sum([Contract].Comission) > 500

-- (2) Найдём контракты, где общая стоимость материалов в товаре > 800

select 
    [Contract].Number as [Contract],
    round(sum(Material.Cost_Per_Gramm * Item_Contains_Material.[Weight]), 2) as Total_Material_Cost
from [Contract]
join Item on [Contract].Item_ID = Item.ID
join Item_Contains_Material on Item.ID = Item_Contains_Material.Item_ID
join Material on Item_Contains_Material.Material_Name = Material.Periodic_Table_Name
group by [Contract].Number
having sum(Material.Cost_Per_Gramm * Item_Contains_Material.Weight) > 800

-- 2.7 
-- (1) Для каждого клиента найти общую стоимость всех материалов в контрактах
-- FIXED --

select 
    Client.Fullname,
    Client.SNILS,
    round(isnull(total_cost.Total_Material_Cost, 0), 2) AS Total_Material_Cost
from Client
left join (
    select 
        [Contract].Client_SNILS as SNILS,
        sum(Material.Cost_Per_Gramm * Item_Contains_Material.[Weight]) as Total_Material_Cost
    from [Contract]
    join Item on [Contract].Item_ID = Item.ID
    join Item_Contains_Material on Item.ID = Item_Contains_Material.Item_ID
    join Material on Item_Contains_Material.Material_Name = Material.Periodic_Table_Name
    GROUP BY [Contract].Client_SNILS
) as total_cost on Client.SNILS = total_cost.SNILS;

-- (2) Найдём клиентов, у которых нет активных договоров
-- (все контракты имеют Redemption_Info = N'Redeemed' / Sale_Info = N'Sold' / догвооров нет)

select *
from Client
where Client.SNILS not in (
	select distinct
		Client.SNILS as SNILS
	from Client 
	join [Contract] on Client.SNILS = [Contract].Client_SNILS
	where [Contract].Redemption_Info = N'Not redeemed' 
	and [Contract].Sale_Info in (N'Not on sale', N'On Sale')
	)

-- (3)  Изделия, которые содержат хотя бы один материал дороже 90 usd/грамм
-- FIXED --

select 
	Item.ID, 
	Item_Type.[Name] as Item_Type
from Item
join Item_Type on Item.[Type_ID] = Item_Type.ID
where exists (
    select *
    from Item_Contains_Material
    join Material on Item_Contains_Material.Material_Name = Material.Periodic_Table_Name
    where Item_Contains_Material.Item_ID = Item.ID
    and Material.Cost_Per_Gramm > 90
);

-- 3.
-- 3.1 
-- (1) Представление для запроса из 2.5 (1)

create view Count_Contracts_per_Client
as 
	select
		Client.SNILS as SNILS,
		count([Contract].Number) as Num_Of_Contracts
	from Client 
	left join [Contract] on Client.SNILS = [Contract].Client_SNILS
	group by Client.SNILS

-- Проверка таблицы

select *
from Count_Contracts_per_Client

-- (2) Представление для запроса из 2.7 (2)

create view Clients_With_No_Active_Contracts
as
	select *
	from Client
	where Client.SNILS not in (
		select
			Client.SNILS as SNILS
		from Client 
		join [Contract] on Client.SNILS = [Contract].Client_SNILS
		where [Contract].Redemption_Info = N'Not redeemed'
		or [Contract].Sale_Info = N'Sold'
		)

-- Проверка таблицы

select *
from Clients_With_No_Active_Contracts

-- 3.2
-- (1) Найдём максимальные комиссионные среди всех контрактов для каждого типа товара из базы данных

with
item_types_and_comissions as (
	select
		Item_Type.[Name] as [Type],
		[Contract].Comission as Comission
	from [Contract]
	join Item on Item.ID = [Contract].Item_ID
	right join Item_Type on Item_Type.ID = Item.[Type_ID]
	)
select
	item_types_and_comissions.[Type] as [Type],
	isnull(max(item_types_and_comissions.Comission), 0) as Max_Comission
from item_types_and_comissions
group by item_types_and_comissions.[Type]

-- (2) Найдём клиентов, у которых в товарах есть такие материалы,
-- где общий вес со всех товаров > 100

with
clients_and_item_materials as (
	select
		Client.SNILS as SNILS,
		Item_Contains_Material.Material_Name as Material,
		sum(Item_Contains_Material.[Weight]) as Total_Weight
	from Client
	join [Contract] on [Contract].Client_SNILS = Client.SNILS
	join Item on Item.ID = [Contract].Item_ID
	join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
	group by Client.SNILS, Item_Contains_Material.Material_Name
	)
select *
from clients_and_item_materials
where clients_and_item_materials.Total_Weight > 100

-- 4.
-- 4.1
-- (1) По каждому клиенту вывести список материалов, сожержащихся с их товарах

select
	row_number() over (partition by Client.SNILS order by Item_Contains_Material.Material_Name) as Num,
	Client.SNILS as SNILS,
	isnull(Item_Contains_Material.Material_Name, N'NO ITEMS') as Material
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item_Contains_Material.Material_Name

-- (2) Вывести ранжированный список клиентов по весу материалов со всех изделий
-- FIXED --

select
	rank() over(order by sum(Item_Contains_Material.[Weight]) desc) as [Rank],
	Client.SNILS as SNILS,
	isnull(sum(Item_Contains_Material.[Weight]), 0) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS

-- (3) Предыдущий запрос, но ранжированный список без учёта повторяющихся строк
-- Это значит, что при наличии n>1 кандидата на одну и ту же позицию списка, 
-- следующая позиция начнётся со следующего числа (без пропуска n-1 позиций как в rank())
-- FIXED --

select
	dense_rank() over(order by sum(Item_Contains_Material.[Weight]) desc) as [Rank],
	Client.SNILS as SNILS,
	isnull(sum(Item_Contains_Material.[Weight]), 0) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS

-- 5.
-- 5.1
-- FIXED --
-- (1) Найдём тех клиентов, которые сдавали изделия содержащие золото и весом > 10 грамм

select
	Client.SNILS as SNILS,
	Item.ID as Item_ID,
	Item_Contains_Material.Material_Name as Material,
	sum(Item_Contains_Material.[Weight]) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
where Item_Contains_Material.Material_Name = N'Aurum'
group by Client.SNILS, Item.ID, Item_Contains_Material.Material_Name
intersect
select
	Client.SNILS as SNILS,
	Item.ID as Item_ID,
	Item_Contains_Material.Material_Name as Material,
	sum(Item_Contains_Material.[Weight]) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item.ID, Item_Contains_Material.Material_Name
having sum(Item_Contains_Material.[Weight]) > 10

-- (2) Найдём тех клиентов, которые сдавали изделия, содержащие золото
-- или изделия, где вес одного из материалов больше 100 г

select
	Client.SNILS as SNILS,
	Item.ID as Item_ID,
	Item_Contains_Material.Material_Name as Material,
	sum(Item_Contains_Material.[Weight]) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item.ID, Item_Contains_Material.Material_Name
having Item_Contains_Material.Material_Name = N'Aurum'
union 
select
	Client.SNILS as SNILS,
	Item.ID as Item_ID,
	Item_Contains_Material.Material_Name as Material,
	sum(Item_Contains_Material.[Weight]) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item.ID, Item_Contains_Material.Material_Name
having sum(Item_Contains_Material.[Weight]) > 100

-- (3) Найдём тех клиентов, которые сдавали золотые изделия, но не сдавали платиновые изделия

select
	Client.SNILS as SNILS,
	Item.ID as Item_ID
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
where Item_Contains_Material.Material_Name = N'Aurum'
group by Client.SNILS, Item.ID
except 
select
	Client.SNILS as SNILS,
	Item.ID as Item_ID
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
where Item_Contains_Material.Material_Name = N'Platinum'
group by Client.SNILS, Item.ID

-- 6.
-- 6.1
-- (1) Посчитаем для каждого клиента, сколько грамм золота в содержится в его товарах 

select
	Client.SNILS as SNILS,
	sum(case
	when Item_Contains_Material.Material_Name = N'Aurum' then Item_Contains_Material.[Weight]
	else 0
	end) as Aurum_Amount
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS

-- (2) Посчитаем постоянных клиентов (есть два и более контракта, заключённых в разные дни)

select
	Client.SNILS as SNILS,
	(case
	when count(distinct [Contract].[Date]) > 1 then 'regular customer'
	else 'just customer'
	end) Is_Regular
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
group by Client.SNILS

-- 6.2
-- (1) Для каждого клиента выведем, сколько в его товарах золота, серебра и платины

select
	SNILS,
	isnull([Aurum], 0) as Aurum, 
	isnull([Argentum], 0) as Argentum, 
	isnull([Platinum], 0) as Platinum
from (
	select
		Client.SNILS as SNILS,
		Item_Contains_Material.Material_Name as Material,
		Item_Contains_Material.[Weight] as [Weight]
	from Client
	left join [Contract] on [Contract].Client_SNILS = Client.SNILS
	left join Item on Item.ID = [Contract].Item_ID
	left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
	) as materials_and_gramms
pivot (sum(materials_and_gramms.[Weight]) for materials_and_gramms.Material in ([Aurum], [Argentum], [Platinum])) as p

-- (2) Вернём запрос из 6.2 (1) к виду вложенного запроса 
-- (с отличием в виде того, что вместо содержащихся материалов в товарах 
-- всё ещё будет статистика по трём выбранным материалам)

select
	SNILS,
	Material,
	[Weight]
from (
	select
		SNILS,
		isnull([Aurum], 0) as Aurum, 
		isnull([Argentum], 0) as Argentum, 
		isnull([Platinum], 0) as Platinum
	from (
		select
			Client.SNILS as SNILS,
			Item_Contains_Material.Material_Name as Material,
			Item_Contains_Material.[Weight] as [Weight]
		from Client
		left join [Contract] on [Contract].Client_SNILS = Client.SNILS
		left join Item on Item.ID = [Contract].Item_ID
		left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
		) as materials_and_gramms
	pivot (sum(materials_and_gramms.[Weight]) for materials_and_gramms.Material in ([Aurum], [Argentum], [Platinum])) as p
	) as pivoted
unpivot ([Weight] for Material in ([Aurum], [Argentum], [Platinum])) as unp

-- ЧАСТЬ 2
-- (a) Выдать список товаров, выставленных на продажу

select 
	Item.ID,
	Item_Type.[Name]
from [Contract]
join Item on [Contract].Item_ID = Item.Id
join Item_Type on Item_Type.ID = Item.[Type_ID]
where Sale_Info = N'On sale'

-- (b) Выдать список товаров, принятых в залог (дата, вид товара, количество)

select
	[Contract].[Date] as [Date],
	Item_Type.[Name] as [Type],
	count(Item.ID) as [Count]
from [Contract]
join Item on Item.ID = [Contract].Item_ID
join Item_Type on Item_Type.ID = Item.[Type_ID]
where [Contract].Redemption_Info = N'Not redeemed' and [Contract].Sale_Info <> N'Sold'
group by [Contract].[Date], Item_Type.[Name]

-- (c) Найти выручку ломбарда от комиссионных с начала текущего года для каждого вида товара

select
	Item_Type.[Name],
	isnull(counted_comission.Total_Comission, 0) as Total_Comission
from (
	select 
		Item_Type.[Name] as [Type],
		sum([Contract].Comission) as Total_Comission
	from [Contract]
	join Item on Item.ID = [Contract].Item_ID
	join Item_Type on Item_Type.ID = Item.[Type_ID]
	where year([Contract].[Date]) = year(getdate())
	group by Item_Type.[Name]
	) counted_comission
right join Item_Type on counted_comission.[Type] = Item_Type.[Name]

-- (d) Найти клиентов, которые не выкупили свой товар в срок
-- вместо getdate() берём '2025-09-01'

select
	Client.SNILS as SNILS
from Client
join [Contract] on [Contract].Client_SNILS = Client.SNILS
where [Contract].Date_Of_Redemption > '2025-09-25'
and [Contract].Redemption_Info = 'Not Redeemed'

-- (e) Найти клиентов, пользовавшихся услугами ломбарда 2 и более раз и всегда выкупавших все свои товары
-- вместо getdate() берём '2025-09-23'

with
regulars as (	-- выбирем тех, кто пользовался 2 и более раз
select				
	Client.SNILS as SNILS,
	count([Contract].[Date]) as [Count]
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
group by Client.SNILS
having count([Contract].[Date]) > 1
),
having_active as (	-- выбираем тех, у кого активные заказы
select distinct		
	Client_SNILS as SNILS,
	count([Contract].[Date]) as [Count]
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
where [Contract].Redemption_Info = 'Not Redeemed' and [Contract].Sale_Info <> 'Sold'
group by Client_SNILS
),
regulars_with_no_actives as ( -- вычитаем активные заказы у постоянных
select 
	regulars.SNILS as s1,
	having_active.SNILS as s2,
	case
		when having_active.SNILS is not null then (regulars.[Count] - having_active.[Count])
		else regulars.[Count]
	end [Count]
from regulars
left join having_active on regulars.SNILS = having_active.SNILS
)
select 
	s1 as SNILS
from regulars_with_no_actives
where [Count] >=2
except
select			-- исключаем тех, кто не выкупил свои товары (есть товар на продаже / проданный товар)
	Client.SNILS as SNILS
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
where [Contract].Sale_Info <> N'Not on sale'
group by Client.SNILS

-- Лаба 4
-- Процедуры
-- a) Процедура без параметров, формирующая список товаров, которые не были выкуплены клиентами в сроки, описанные в договоре
-- вместо getdate() берём '2025-09-01'

create or alter procedure ItemsNotRedeemedItTime
as
Begin
	select
		Client.Fullname,
		Item.ID,
		Item_Type.[Name] as 'Type Name'
	from Client
	join [Contract] on [Contract].Client_SNILS = Client.SNILS
	join Item on Item.ID = [Contract].Item_ID
	join Item_Type on Item_Type.ID = Item.[Type_ID]
	where [Contract].Date_Of_Redemption < '2025-09-01' 
	and [Contract].Redemption_Info = 'Not Redeemed'
End

execute ItemsNotRedeemedItTime

drop procedure ItemsNotRedeemedItTime

-- b) Процедура, на входе получающая ФИО клиента и формирующая список товаров, которые он когда-либо приносил закладывать в ломбард

create or alter procedure GetItems
	@Name nvarchar(50)
as
Begin
	with getId 
	as (
		select
			SNILS
		from Client
		where Fullname = @Name
	)
	select
		Item.ID,
		Item_Type.[Name] as 'Type Name',
		[Contract].[Date],
		[Contract].Redemption_Info,
		[Contract].Sale_Info
	from [Contract]
	join Item on Item.ID = [Contract].Item_ID
	join Item_Type on Item_Type.ID = Item.[Type_ID]
	where [Contract].Client_SNILS in (select SNILS from getId)
End

execute GetItems 'Немчанинов Руслан Владимирович'

drop procedure GetItems

-- c) Процедура, на входе получающая ФИО клиента, выходной параметр – общая сумма денег, которые он получил за все товары, заложенные им в ломбарде

create procedure GetMoney
	@Name nvarchar(50),
	@TotalSum money output
as
Begin
	set nocount on;

	select
		@TotalSum = isnull(round(sum(Material.Cost_Per_Gramm * Item_Contains_Material.[Weight]), 2), 0)
	from [Contract]
	join Client on Client.SNILS = [Contract].Client_SNILS
	join Item on Item.ID = [Contract].Item_ID
	join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
	join Material on Material.Periodic_Table_Name = Item_Contains_Material.Material_Name
	where Fullname = @Name
End

declare @Sum money;
exec GetMoney @Name = 'Немчанинов Руслан Владимирович', @TotalSum = @Sum output;
select @Sum as TotalMoneyReceived;

-- проверка
select
	Material.Periodic_Table_Name,
	Material.Cost_Per_Gramm,
	Item_Contains_Material.[Weight]
from [Contract]
	join Client on Client.SNILS = [Contract].Client_SNILS
	join Item on Item.ID = [Contract].Item_ID
	join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
	join Material on Material.Periodic_Table_Name = Item_Contains_Material.Material_Name
where Client.Fullname = 'Немчанинов Руслан Владимирович'

drop procedure GetMoney

-- d) Процедура, вызывающая вложенную процедуру, которая находит самого «дорогого» клиента (с максимальной суммой денег, полученных им от ломбарда). Главная процедура выводит для этого клиента список товаров, которые он когда-либо приносил в залог, и сведения об их выкупе

create or alter procedure GetMostPricey
	@SNILS int output
as
Begin
	--with 
	--counted_prices as (
	select top 1 
		@SNILS = [Contract].Client_SNILS
	from [Contract]
	join Item on Item.ID = [Contract].Item_ID
	join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
	join Material on Material.Periodic_Table_Name = Item_Contains_Material.Material_Name
	group by [Contract].Client_SNILS
	order by round(sum(Material.Cost_Per_Gramm * Item_Contains_Material.[Weight]),2) desc
End
	--),
	--top_by_price as (
	--	select top 1
	--		SNILS
	--	from counted_prices
	--	order by Price desc
	--)
	--select
	--	@SNILS = SNILS
	--from top_by_price

create procedure GetMostPriceyStats
as
Begin
	declare @snils int = 0;
	execute GetMostPricey @snils output

	select
		Client.Fullname,
		Item_Type.[Name],
		[Contract].Redemption_Info
	from Client
	join [Contract] on [Contract].Client_SNILS = Client.SNILS
	join Item on Item.ID = [Contract].Item_ID
	join Item_Type on Item_Type.ID = Item.[Type_ID]
	where Client.SNILS = @snils
End

-- вложенная
declare @snils int = 0;
execute GetMostPricey @snils output
print @snils

-- внешняя
execute GetMostPriceyStats

drop procedure GetMostPricey

drop procedure GetMostPriceyStats

-- Функции
-- a) Скалярная функция, подсчитывающая количество товаров, которые д.б. выставлены на продажу (не выкуплены в срок)
-- вместо getdate() берём '2025-09-01'

create or alter function CountOfItemsToSale()
returns int
as
Begin
	declare @countOfItems int

	select
		@countOfItems = isnull(count(*), 0)
	from [Contract]
	where Date_Of_Redemption < '2025-09-01'
	and Redemption_Info = 'Not Redeemed'
	and Sale_Info = 'Not on sale'

	return @countOfItems
End

select dbo.CountOfItemsToSale() as 'Count of Items'

drop function CountOfItemsToSale

-- b) Inline-функция, возвращающая список клиентов, которые не всегда выкупали свои товары
-- вместо getdate() берём '2025-09-01'
-- FIXED --

create or alter function ClientsWithNotRedeemedState()
returns table
as
return (
	select distinct
		CLNT.SNILS,
		CLNT.Fullname
	from Client CLNT
	where exists ( -- Проверяем, есть ли у клиента контракты, у которых прошла дата выкупа (исключаем активные заказы)
		select 1 
		from [Contract] C
		where C.Client_SNILS = CLNT.SNILS
		and C.Date_Of_Redemption < '2025-09-01'
		and C.Redemption_Info = 'Not Redeemed'
	)
)

select * from dbo.ClientsWithNotRedeemedState()

select * from [Contract]

drop function ClientsWithNotRedeemedState

-- c) Multi-statement-функция, выдающая список товаров, состоящих из 3-х и более материалов, и ФИО их владельца
-- FIXED --

create or alter function ItemsWith3OrMoreMaterials()
returns @ItemsWith3orMoreMaterials_list table (
	ItemName nvarchar(50),
	CountOfMaterials int,
	ClientName nvarchar(50)
)
as
Begin 
	with 
	correct_items as (
		select
			I.ID,
			count(ICM.ID) as CountOfMaterials
		from Item I
		join Item_Contains_Material ICM on ICM.Item_ID = I.ID
		group by I.ID
		having count(ICM.ID) >= 3
	)
	insert into @ItemsWith3orMoreMaterials_list(ItemName, CountOfMaterials, ClientName)
	select 
		Item_Type.[Name],
		correct_items.CountOfMaterials,
		Client.Fullname
	from Client
	join [Contract] on [Contract].Client_SNILS = Client.SNILS
	join correct_items on correct_items.ID = [Contract].Item_ID
	join Item on Item.ID = correct_items.ID
	join Item_Type on Item_Type.ID = Item.[Type_ID]
	return
End

select * from dbo.ItemsWith3OrMoreMaterials()

-- Триггеры
-- a) Триггер любого типа на добавление товара – если процент износа > 50, то товар не добавляется, выдается соотв. сообщение

create or alter trigger CheckWear_LessThen50
on Item
instead of insert
as
Begin
	set nocount on

	declare @Wear int
	declare @Type_ID int
	
	-- создаём курсор
	declare	insert_cursor cursor for
	select Wear, [Type_ID]
	from inserted

	-- открываем курсор
	open insert_cursor

	-- получаем первую строку
	fetch next from insert_cursor
	into @Wear, @Type_ID

	-- обрабатываем пока есть строки
	while @@FETCH_STATUS = 0
	begin
		-- выполняем проверку
		if @Wear > 50
		begin
			print concat('Предмет с износом ', @Wear, ' не добавлен: износ выше допустимого - 50');
		end
		else
		begin
			-- если пройдена проверка - вставляем
			insert into Item (Wear, [Type_ID])
			values (@Wear, @Type_ID)

			print concat('Предмет с износом ', @Wear, ' добавлен успешно!');
		end

		-- получаем следующую строку
		fetch next from insert_cursor
		into @Wear, @Type_ID
	end

	-- освобождаем курсор
	close insert_cursor
	deallocate insert_cursor
End

insert into Item (Wear, [Type_ID])
values
	(12,1),
	(60,1)

select * from Item

drop trigger CheckWear_LessThen50

-- b)  Последующий триггер на изменение признака выкупа товара – если срок выкупа истек, то признак выкупа может поменяться только на значение «не выкуплен», если нет, то признак выкупа может поменяться только на значение «выкуплен»
-- вместо getdate() берём '2025-09-01'
-- FIXED --

create or alter trigger CheckRedemptionInfo_OnDateOfRedemption
on [Contract]
after update
as
Begin
	declare @Number int
	declare @Date date
	declare @Date_Of_Redemption date
	declare @Comission money
	declare @Old_Redemption_Info nvarchar(15) -- старый статус выкупа
	declare @New_Redemption_Info nvarchar(15) -- изменённый статус выкупа
	declare @Sale_Info nvarchar(15)
	declare @Client_SNILS int
	declare @Item_ID int

	-- создаём курсор
	declare update_cursor cursor for
	select
		i.Number,
		i.[Date],
		i.Date_Of_Redemption,
		i.Comission,
		d.Redemption_Info as Old_Redemption_Info,
		i.Redemption_Info as New_Redemption_Info,
		i.Sale_Info,
		i.Client_SNILS,
		i.Item_ID
	from inserted i
	join deleted d on i.Number = d.Number
	where i.Redemption_Info <> d.Redemption_Info -- оставляем только записи, где происходят изменения

	-- открываем курсор
	open update_cursor

	-- получаем первую строку
	fetch next from update_cursor
	into 
		@Number,
		@Date,
		@Date_Of_Redemption,
		@Comission,
		@Old_Redemption_Info,
		@New_Redemption_Info,
		@Sale_Info,
		@Client_SNILS,
		@Item_ID

	while @@FETCH_STATUS = 0
	begin
		-- выполняем проверку
		if (@Date_Of_Redemption < '2025-09-01' and @New_Redemption_Info = 'Redeemed')
		begin
			print concat('Обновление контракта с номером ', @Number, ' невозможно - изменение статуса выкупа на "', 
			@New_Redemption_Info, '" невозможно к установке когда прошёл срок выкупа. ',
			'Будут оставлены старые данные.')

			update [Contract]
			set Redemption_Info = @Old_Redemption_Info
			where Number = @Number
		end
		else if (@Date_Of_Redemption >= '2025-09-01' and @New_Redemption_Info = 'Not Redeemed')
		begin
			print concat('Обновление контракта с номером ', @Number, ' невозможно - изменение статуса выкупа на "', 
			@New_Redemption_Info, '" невозможно к установке пока не прошёл срок выкупа ',
			'Будут оставлены старые данные.')

			update [Contract]
			set Redemption_Info = @Old_Redemption_Info
			where Number = @Number
		end

		-- получаем следующую строку
		fetch next from update_cursor
		into 
			@Number,
			@Date,
			@Date_Of_Redemption,
			@Comission,
			@Old_Redemption_Info,
			@New_Redemption_Info,
			@Sale_Info,
			@Client_SNILS,
			@Item_ID
	end

	-- освобождаем курсор
	close update_cursor
	deallocate update_cursor

	print ('Обновление записей прошло успешно!')
End

begin tran
select * from Contract
update [Contract]
set Redemption_Info = 'Not redeemed'

select * from Contract
rollback

drop trigger CheckRedemptionInfo_OnDateOfRedemption

-- c) Замещающий триггер на операцию удаления владельца товара – если у него по всем договорам товары выкуплены, то удаляем владельца и все его договора, если нет – ничего не удаляем, выводим сообщение 
-- FIXED --

create or alter trigger CheckDelete_ClientOnlyContractsWithRedeemedState
on [Client]
instead of delete
as
Begin
	declare @SNILS int
	declare @Fullname nvarchar(50)
	declare @Address nvarchar(50)
	declare @Passport_Series int
	declare @Passport_ID int
	declare @deleting_items table (id int)

	-- создаём курсор
	declare delete_cursor cursor for
	select SNILS, Fullname, [Address], Passport_Series, Passport_ID
	from deleted

	-- открываем курсор
	open delete_cursor

	-- получаем первую строку
	fetch next from delete_cursor
	into @SNILS, @Fullname, @Address, @Passport_Series, @Passport_ID

	while @@FETCH_STATUS = 0
	begin
		-- выполняем проверку
		if (@SNILS in (
			select distinct
				SNILS
			from Client CLNT
			join [Contract] C on C.Client_SNILS = CLNT.SNILS
			where Redemption_Info = 'Not Redeemed'
		))
		begin
			print concat('Удаление клиента со СНИЛСом ', @SNILS, ' невозможно - у клиента имеются незавершённые контракты')
		end
		else
		begin
			-- если пройдена проверка - можно удалять
			-- сначала запоминаем id товаров, которые удаляем
			-- тк они внешние ключи в контрактах

			insert into @deleting_items(id)
			select
				Item_ID
			from [Contract]
			where Client_SNILS = @SNILS

			-- удаляем:
			-- контракты
			delete from [Contract]
			where Client_SNILS = @SNILS

			-- связки товар-материал
			delete from Item_Contains_Material
			where Item_ID in (select id from @deleting_items)

			-- товары
			delete from [Item]
			where ID in (select id from @deleting_items)

			-- клиентов
			delete from Client
			where SNILS = @SNILS

			print concat('Удалён клиент со СНИЛСом ', @SNILS)
		end

		-- получаем следующую строку
		fetch next from delete_cursor
		into @SNILS, @Fullname, @Address, @Passport_Series, @Passport_ID
	end

	-- освобождаем курсор
	close delete_cursor
	deallocate delete_cursor
End

begin tran
select * from [Client]
delete from [Client]
where SNILS = 101
select * from [Client]
rollback

drop trigger CheckDelete_ClientOnlyContractsWithRedeemedState

-- Лаба 5
-- Задание 1
-- 1-я роль - руководитель ломбарда
-- 2-я роль - работник ломбарда

-- создаём роли
create role [Director]
create role [Worker]

-- выдаём права руководителю
grant select on dbo.Item_Type to [Director] with grant option;
grant insert, update, delete on dbo.Item_Type to [Director];

grant select, insert on dbo.Item to [Director] with grant option;
grant update, delete on dbo.Item to [Director];

grant select on dbo.Material to [Director] with grant option;
grant insert, update, delete on dbo.Material to [Director];

grant insert on dbo.Client to [Director] with grant option;
grant select, update, delete on dbo.Client to [Director];

grant select, insert on dbo.Item_Contains_Material to [Director] with grant option;
grant update, delete on dbo.Item_Contains_Material to [Director];

grant select, insert on dbo.[Contract] to [Director] with grant option;
grant update, delete on dbo.[Contract] to [Director];

grant execute on dbo.ItemsNotRedeemedItTime to [Director] with grant option;
grant execute on dbo.GetItems to [Director] with grant option;
grant execute on dbo.GetMoney to [Director];
grant execute on dbo.GetMostPriceyStats to [Director];
grant execute on dbo.CountOfItemsToSale to [Director] with grant option;
grant select on dbo.ClientsWithNotRedeemedState to [Director] with grant option;
grant select on dbo.ItemsWith3OrMoreMaterials to [Director];

-- выдаём права работнику
grant select on dbo.Item_Type to [Worker];
deny insert, update, delete on dbo.Item_Type to [Worker];

grant select, insert on dbo.Item to [Worker];
deny update, delete on dbo.Item to [Worker];

grant select on dbo.Material to [Worker];
deny insert, update, delete on dbo.Material to [Worker];

grant insert on dbo.Client to [Worker];
deny select, update, delete on dbo.Client to [Worker];

grant select, insert on dbo.Item_Contains_Material to [Worker]; 
deny update, delete on dbo.Item_Contains_Material to [Worker];

grant select, insert on dbo.[Contract] to [Worker]; 
deny update, delete on dbo.[Contract] to [Worker];

grant execute on dbo.GetItems to [Worker];
grant execute on dbo.CountOfItemsToSale to [Worker];
grant select on dbo.ClientsWithNotRedeemedState to [Worker];

revoke execute on dbo.ItemsNotRedeemedItTime to [Worker];
deny execute on dbo.GetMoney to [Worker];
deny execute on dbo.GetMostPricey to [Worker];
deny execute on dbo.GetMostPriceyStats to [Worker];
deny select on dbo.ItemsWith3OrMoreMaterials to [Worker];

revoke grant option for execute on dbo.ItemsNotRedeemedItTime to [Director] cascade
grant execute on dbo.ItemsNotRedeemedItTime to [Worker] as [Director];
-- создаём пользователей
create login user_director with password = '1234567';
create user user_director for login user_director;

create login user_worker with password = '1234567';
create user user_worker for login user_worker;

-- добавляем пользователей в роли
alter role [Director] add member user_director
alter role [Worker] add member user_worker

-- проверка прав
use [Pawnshop_DB]
select user_name()

select *
from Item_Contains_Material
select *
from Material
select *
from Client
select *
from [Contract]
select *
from Item
select *
from Item_Type

exec ItemsNotRedeemedItTime
exec GetItems
exec GetMoney
exec GetMostPriceyStats
exec GetClientData
exec CountOfItemsToSale
select * from ClientsWithNotRedeemedState
select * from ItemsWith3OrMoreMaterials

-- insert
begin tran
insert into Item_Type (Name)
values
	(N'Цепь')
rollback

begin tran
insert into Material
values
	(N'Argentum', 1.03)
rollback

begin tran
insert into Item (Wear, [Type_ID])
values
	(0,1)
rollback
	
begin tran
insert into Item_Contains_Material (Item_ID, Material_Name, [Weight])
values	
	(1,N'Aurum',5)
rollback

begin tran
insert into Client
values
	(101,N'Волкова Анастасия Дмитриевна',N'Бабича, 11к5',1001,100001)
rollback

begin tran
insert into [Contract] ([Date], Date_Of_Redemption, Comission, Redemption_Info, Sale_Info, Client_SNILS, Item_ID)
values
	('2025-08-31','2025-09-30',200.0,N'Redeemed',N'Not on sale',101,1)
rollback

--update
begin tran
update Item_Type
set [Name] = 'qwerty'
where ID = 1
rollback

begin tran
update Item
set Wear = 0
where ID = 1
rollback

begin tran
update Material
set Periodic_Table_Name = 'AAAAAAA'
where Periodic_Table_Name = 'Aurum'
rollback

begin tran
update Item_Contains_Material
set Weight = 0
where ID = 1
rollback

begin tran
update Client
set Fullname = 'AAAAAAAAAa'
where SNILS = 101
rollback

begin tran
update [Contract]
set Comission = 100000000
where Number = 15
rollback

--delete
begin tran
delete Item_Type
where ID = 1
rollback

begin tran
delete Item
where ID = 1
rollback

begin tran
delete Material
where Periodic_Table_Name = 'Aurum'
rollback

begin tran
delete Item_Contains_Material
where ID = 1
rollback

begin tran
delete Client
where SNILS = 101
rollback

begin tran
delete [Contract]
where Number = 15
rollback

-- Задание 2
-- Маскируем паспортные данные для Worker
-- Метод 1

alter table dbo.Client
alter column Fullname add masked with (function = 'partial(2, "xxxx", 0)');

grant UNMASK to [Director];

select * from Client

-- Метод 2

-- 1. Функция для маскировки
create function MaskString (@Input nvarchar(50), @VisibleChars int, @MaskChar nvarchar(10))
returns nvarchar(50)
as
begin
    return left(@Input, @VisibleChars) + replicate(@MaskChar, len(@Input) - @VisibleChars);
end;

-- 2. Предствление с маскированными данными для сотрудника
create view Client_MaskedView as
select 
    SNILS,
    dbo.MaskString(Fullname, 2, 'x') as Fullname_Masked,
    [Address],
    '****' as Passport_Series_Masked,
    '******' as Passport_ID_Masked
from Client;

-- 3. Процедура для выборки (использует представление для работника или оригинал для директора)
create procedure GetClientData
    @SNILS int
as
begin
    -- проверяем роль
    if is_member('Director') = 1
    begin
        -- директор видит оригинал
        select * from Client where (SNILS = @SNILS);
    end
    else
    begin
        -- работник видит представление
        select * from dbo.Client_MaskedView where (SNILS = @SNILS);
    end
end;

-- выдаём роли
grant select on dbo.Client_MaskedView to [Director];
grant execute on dbo.GetClientData to [Director];
grant execute on dbo.MaskString to [Director];

grant select on dbo.Client_MaskedView to [Worker];
grant execute on dbo.GetClientData to [Worker];
grant execute on dbo.MaskString to [Worker];

select * from Client

declare @SNILS int = 101
exec GetClientData @SNILS

use [Pawnshop_DB]
select user_name()