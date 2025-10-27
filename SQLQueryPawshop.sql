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
	(N'������'),
	(N'�������'),
	(N'����'),
	(N'������'),
	(N'������'),
	(N'������')

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
	(101,N'������� ��������� ����������',N'������, 11�5',1001,100001),
	(102,N'�������� ����� �������������',N'�������, 28',1001,100002),
	(103,N'������ ���� �������������',N'�������, 20',1001,100003),
	(104,N'���������� ������ ������������',N'����������, 11',1001,100004),
	(105,N'�������� ���� �������������',N'�������, 28',1001,100005),
	(106,N'��������� ������� ����������',N'�����������, 150',1001,100006),
	(107,N'������� ������� ����������',N'�������, 16',1001,100007),
	(108,N'���������� �������� ����������',N'����������, 11',1001,100008),
	(109,N'������� ����� ���������',N'��������, 52',1001,100009),
	(110,N'������ ���� ��������',N'�������, 0',1001,100010),
	(111,N'������� ������ ��������',N'���������, 777',1002,100001)

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
from Item_Contains_Material
select *
from Material
select *
from Client
select *
from [Contract]
select *
from Item
left join Item_Contains_Material on Item.ID = Item_Contains_Material.Item_ID

-- ���� 3
-- ����� 1
-- 1.
-- 1.1 ������� [Contract], ���������� �� ���� � ��������

select *
from [Contract]
order by [Date]

select *
from [Contract]
order by Comission

-- 1.2 ������� [Contract], �������:
-- (1) ���� ��������� ������ 1 ������� 2025

select *
from [Contract]
where [Date] < '2025-08-01'

-- (2) ����� ������

select *
from [Contract]
where Sale_Info = N'Sold'

-- (3) �������� �� ������ 200 � ���� ������ ����� 25 �������� 2025

select *
from [Contract]
where Comission >= 200 and Date_Of_Redemption > '2025-09-25'

-- 1.3 ������� [Contract]
-- (1) ������� ����� ���������� ���������� � ����������� � �����������, ������������ � ������� ����� ��������

select 
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]

-- (2) ��� ������� ������� ������ ������� ����� ���������� ���������� 
-- � ����������� � �����������, ������������ � ������� ����� ��������

select 
	Redemption_Info,
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]
group by Redemption_Info

-- (3) ��� ������ ���� ������� ������ � ������� ������� ������� ����� ���������� ���������� 
-- � ����������� � �����������, ������������ � ������� ����� ��������

select 
	Redemption_Info,
	Sale_Info,
	COUNT(*) as Total_Contracts,
	MIN(Comission) as Min_Comission,
	MAX(Comission) as Max_Comission,
	AVG(Comission) as Average_Comission
from [Contract]
group by Redemption_Info, Sale_Info


-- 1.4 ������� [Contract]
-- (1) ����������� � ��������� (rollup) �� Client_SNILS � Sale_Info
-- ������� ����� ��� ������� Client_SNILS � ���� ������� �������

select 
	isnull(cast (Client_SNILS as nvarchar), N'TOTAL') as Client_SNILS,	-- ��������� TOTAL ����� isnull
	iif(grouping(Sale_Info) = 1, N'TOTAL', Sale_Info) as Sale_Info,		-- ��������� TOTAL ����� grouping
	count(Item_ID) as Items
from [Contract]
group by rollup (Client_SNILS, Sale_Info)

-- (2) ����������� � ��������� (cube) �� ������ � ���� � �������
-- ������� ����� ��� ������� Sale_Info � ������� Client_SNILS

select 
	isnull(cast (Client_SNILS as nvarchar), N'TOTAL') as Client_SNILS,	-- ��������� TOTAL ����� isnull
	iif(grouping(Sale_Info) = 1, N'TOTAL', Sale_Info) as Sale_Info,		-- ��������� TOTAL ����� grouping
	count(Item_ID) as Items
from [Contract]
group by cube (Client_SNILS, Sale_Info)

-- (3) ����������� � �������� ���� ����� (all), ��� ������������ ��������, ��������� �� Sale_Info

select
	count(Client_SNILS) as Clients,
	Sale_Info
from [Contract]
-- where Sale_Info = N'On Sale'		-- ����� �������� �������, ����� � Clients ����� ���� ����� ����� ���������� Sale_Info
group by all Sale_Info

-- 1.5 ������� Material, ������� ��������, ��� ��� ������������������ "iu"

select Periodic_Table_Name
from Material
where Periodic_Table_Name not like '%iu%'

-- 2.
-- 2.1 
-- (1) ������� Item � Item_Type, ������� Item.Type_ID �� Item_Type.Name

select
	Item.ID as ID,
	Item.Wear as Wear,
	Item_Type.[Name] as [Type_Name]
from Item, Item_Type
where Item.[Type_ID] = Item_Type.ID

-- (2) ������� Item_Contains_Material � Material, 
-- ������� Item_Contains_Material.Material_Name �� Material.Periodic_Table_Name

select
	Item_Contains_Material.Item_ID as Item_ID,
	Material.Periodic_Table_Name as Material_Name
from Item_Contains_Material, Material
where Item_Contains_Material.Material_Name = Material.Periodic_Table_Name

-- 2.2 ������ ������� �� 2.1 c where �� join
-- (1)

select
	Item.ID as ID,
	Item.Wear as Wear,
	Item_Type.[Name] as [Type_Name]
from Item join Item_Type on Item.[Type_ID] = Item_Type.ID

-- (2)

select
	Item_Contains_Material.Item_ID as Item_ID,
	Material.Periodic_Table_Name as Material_Name
from Item_Contains_Material join Material on Item_Contains_Material.Material_Name = Material.Periodic_Table_Name

-- 2.3 
-- (1) ������, ����� �������� ���� � ���� �������� �� ����

select
	Client.SNILS as SNILS,
	isnull(cast([Contract].Number as varchar), 'No Contracts') as Contract_Number
from Client left join [Contract] on Client.SNILS = [Contract].Client_SNILS

-- (2) ������, ����� ��������� ���� ��������� �� ������� ���� �����

select
	isnull(cast([Contract].Number as varchar), 'No Contracts') as Contract_Number,
	isnull(cast(Item.ID as varchar), 'No Items') as Item_ID,
	Item_Type.Name as Item_Type
from  Item_Type
left join Item on Item_Type.ID = Item.Type_ID
left join [Contract] on Item.ID = [Contract].Item_ID

-- 2.4 ��������� ������� �� 2.3 �� right join
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
-- (1) ��������� ���������� ���������� ��� ������� �������

select
	Client.SNILS as SNILS,
	count([Contract].Number) as Num_Of_Contracts
from Client 
left join [Contract] on Client.SNILS = [Contract].Client_SNILS
group by Client.SNILS

-- (2) ��������� ���������� ������������ � ������ ������ ��� ������� �������

select
	Client.SNILS as SNILS,
	isnull(cast(max([Contract].Comission) as varchar), 'No Contracts') as Max_Comission
from Client 
left join [Contract] on Client.SNILS = [Contract].Client_SNILS
group by Client.SNILS

-- 2.6 

-- (1) ������� ��������, ��� ������ ���� ������� ���������

select
	Client.SNILS as SNILS
from Client 
join [Contract] on Client.SNILS = [Contract].Client_SNILS
group by Client.SNILS, [Contract].Sale_Info
having [Contract].Sale_Info = N'Sold'

-- (2) ������� ��������, � ������� ���� ��������� �� ����

select
	Client.SNILS as SNILS
from Client 
join [Contract] on Client.SNILS = [Contract].Client_SNILS
join [Item] on Item.ID = [Contract].Item_ID
join [Item_Type] on Item_Type.ID = Item.[Type_ID]
group by Client.SNILS, Item_Type.[Name]
having Item_Type.[Name] = N'����'

-- 2.7 
	
-- (1) ����� ����� ���������������� �������� � ������� � ����

select top 1 with ties
	materials_in_items.Material as Material
from (
	select
		Item_Contains_Material.Material_Name as Material,
		count(Item.ID) as Count_Items
	from Item
	join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
	group by Item_Contains_Material.Material_Name
	) materials_in_items
order by materials_in_items.Count_Items desc

-- (2) ����� ��������, � ������� ��� �������� ���������
-- (��� ��������� ����� Redemption_Info = N'Redeemed' / Sale_Info = N'Sold' / ��������� ���)

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

-- (3) ����� ���������, ��������� �� ����� ������� > 1

select *
from Material
where exists (
	select *
	from Item_Contains_Material
	where Item_Contains_Material.Material_Name = Material.Periodic_Table_Name 
	and Material.Cost_Per_Gramm > 1
	)

-- 3.
-- 3.1 
-- (1) ������������� ��� ������� �� 2.5 (1)

create view Count_Contracts_per_Client
as 
	select
		Client.SNILS as SNILS,
		count([Contract].Number) as Num_Of_Contracts
	from Client 
	left join [Contract] on Client.SNILS = [Contract].Client_SNILS
	group by Client.SNILS

-- �������� �������

select *
from Count_Contracts_per_Client

-- (2) ������������� ��� ������� �� 2.7 (2)

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

-- �������� �������

select *
from Clients_With_No_Active_Contracts

-- 3.2
-- (1) ����� ������������ ������������ ����� ���� ���������� ��� ������� ���� ������ �� ���� ������

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

-- (2) ����� ��������, � ������� � ������� ���� ����� ���������,
-- ��� ����� ��� �� ���� ������� > 100

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
-- (1) �� ������� ������� ������� ������ ����������, ������������ � �� �������

select
	row_number() over (partition by Client.SNILS order by Item_Contains_Material.Material_Name) as Num,
	Client.SNILS as SNILS,
	isnull(Item_Contains_Material.Material_Name, N'NO ITEMS') as Material
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item_Contains_Material.Material_Name

-- (2) ������� ��� �������� �� ���� ���������� �� ���� �������

select
	rank() over(order by sum(Item_Contains_Material.[Weight]) desc) as [Rank],
	Client.SNILS as SNILS,
	isnull(sum(Item_Contains_Material.[Weight]), 0) as Total_Weight
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS

-- (3) ���������� ������, �� ��� ��� ����� ������������� �����

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
-- (1) ����� ��� ��������, ������� ������� ������� ������� ����� ������ 10 �

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

-- (2) ����� ��� ��������, ������� ������� ������� ������� ��� ������� ����� ������ 100 �

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

-- (3) ����� ��� ��������, ������� ������� ������� �������, �� �� ������� ���������� �������

select
	Client.SNILS as SNILS,
	Item.ID as Item_ID,
	Item_Contains_Material.Material_Name as Material
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item.ID, Item_Contains_Material.Material_Name
having Item_Contains_Material.Material_Name = N'Aurum'
except 
select
	Client.SNILS as SNILS,
	Item.ID as Item_ID,
	Item_Contains_Material.Material_Name as Material
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
left join Item on Item.ID = [Contract].Item_ID
left join Item_Contains_Material on Item_Contains_Material.Item_ID = Item.ID
group by Client.SNILS, Item.ID, Item_Contains_Material.Material_Name
having Item_Contains_Material.Material_Name = N'Platinum'

-- 6.
-- 6.1
-- (1) ��������� ��� ������� �������, ������� ����� ������ � ���������� � ��� ������� 

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

-- (2) ��������� ���������� �������� (���� ��� � ����� ���������, ����������� � ������ ���)

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
-- (1) ��� ������� ������� �������, ������� � ��� ������� ������, ������� � �������

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

-- (2) ����� ������ �� 6.2 (1) � ���� ���������� ������� 
-- (� �������� � ���� ����, ��� ������ ������������ ���������� � ������� 
-- �� ��� ����� ���������� �� ��� ��������� ����������)

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

-- ����� 2
-- (a) ������ ������ �������, ������������ �� �������

select
	Item_ID
from [Contract]
where Sale_Info = N'On sale'

-- (b) ������ ������ �������, �������� � ����� (����, ��� ������, ����������)

select
	[Contract].[Date] as [Date],
	Item_Type.[Name] as [Type],
	1 as [Count]
from [Contract]
join Item on Item.ID = [Contract].Item_ID
join Item_Type on Item_Type.ID = Item.[Type_ID]
where [Contract].Redemption_Info = N'Not redeemed' and [Contract].Sale_Info <> N'Sold'

-- (c) ����� ������� �������� �� ������������ � ������ �������� ���� ��� ������� ���� ������

select 
	Item_Type.[Name] as [Type],
	sum([Contract].Comission) as Total_Comission
from [Contract]
join Item on Item.ID = [Contract].Item_ID
join Item_Type on Item_Type.ID = Item.[Type_ID]
where [Contract].[Date] > '01.01.2025'
group by Item_Type.[Name]

-- (d) ����� ��������, ������� �� �������� ���� ����� � ����

select
	Client.SNILS as SNILS
from Client
join [Contract] on [Contract].Client_SNILS = Client.SNILS
where [Contract].Sale_Info <> 'Not on sale'

-- (e) ����� ��������, �������������� �������� �������� 2 � ����� ��� � ������ ���������� ��� ���� ������

select
	Client.SNILS as SNILS
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
group by Client.SNILS
having count([Contract].[Date]) > 1
except
select
	Client.SNILS as SNILS
from Client
left join [Contract] on [Contract].Client_SNILS = Client.SNILS
where [Contract].Redemption_Info = N'Not Redeemed'
group by Client.SNILS