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
	(N'Монета')

insert into Material
values
	(N'Ferrum', 0.8),
	(N'Palladium', 42.68),
	(N'Rhodium', 438.6),
	(N'Iridium', 187.23),
	(N'Titanium', 0.21),
	(N'Tungsten', 0.09),
	(N'Aurum', 93.07),
	(N'Argentum', 1.03),
	(N'Platinum', 31.45),
	(N'Cuprum', 0.01)

insert into Item (Wear, [Type_ID])
values
	(28,2),
	(16,5),
	(14,3),
	(32,5),
	(21,3),
	(0,1),
	(20,1),
	(1,3),
	(6,5),
	(9,2),
	(69,5),
	(88,4),
	(42,3),
	(14,4)

insert into Item_Contains_Material (Item_ID, Material_Name, [Weight])
values
	(1,N'Aurum',5),
	(2,N'Platinum',4),
	(3,N'Aurum',150),
	(3,N'Argentum',100),
	(4,N'Cuprum',10),
	(5,N'Platinum',30),
	(6,N'Aurum',8),
	(7,N'Aurum',1000),
	(8,N'Platinum',200),
	(8,N'Aurum',50),
	(9,N'Cuprum',500)

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
	(110,N'Энэнов Энэн Энэнович',N'Энэнова, 0',1001,100010)

insert into [Contract] ([Date], Date_Of_Redemption, Comission, Redemption_Info, Sale_Info, Client_SNILS, Item_ID)
values
	('2025-08-31','2025-09-30',200.0,N'Redeemed',N'Not on sale',101,1),
	('2025-08-31','2025-09-30',250.5,N'Not redeemed',N'Not on sale',101,2),
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
from Item
select *
from Item_Type
select *
from Client
select *
from [Contract]

-- Лаба 3
-- 1.
-- 1.1 Таблица [Contract], сортировка по дате и комиссии

select *
from [Contract]
order by [Date]

select *
from [Contract]
order by Comission

-- 1.2 Таблица [Contract], Условия:
-- (1) Дата контракта раньше 1 августа 2025

select *
from [Contract]
where [Date] < '2025-08-01'

-- (2) Товар продан

select *
from [Contract]
where Sale_Info = N'Sold'

-- (3) Комиссия не меньше 200 и дата выкупа позже 25 сентября 2025

select *
from [Contract]
where Comission >= 200 and Date_Of_Redemption > '2025-09-25'

-- 1.3 Таблица [Contract]

select 
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]

select 
	Redemption_Info,
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]
group by Redemption_Info

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



-- 1.5 Таблица Material, вывести названия, где нет последовательности "iu"

select Periodic_Table_Name
from Material
where Periodic_Table_Name not like '%iu%'