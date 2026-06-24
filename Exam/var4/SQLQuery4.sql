--1. 
create table TaxiOrders
(OrderId int identity(1,1) primary key,
 PriceTravel money,
 ClientId int foreign key references Clients(ClientId),
 DriveId int foreign key references Drivers(DriveId),
 CityTravel nvarchar(20),
 DateTravel date,	
 TimeTravel float)
go
create table Drivers
(DriveId int identity(1,1) primary key,
 PhoneDriver nvarchar(15),
 EmailDriver nvarchar(50),
 CarID int foreign key references Cars(CarID)
)
go
Create table Clients
(ClientId int identity(1,1) primary key,
 PhoneClient nvarchar(15),
 CityClient nvarchar(20)
)
go
create table Cars
(CarID int identity(1,1) primary key)
go

-- 2.
-- Вставка данных в таблицу Cars
insert into Cars
default values;

insert into Cars
default values;

insert into Cars
default values;

insert into Cars
default values;

insert into Cars
default values;
go
-- Вставка данных в таблицу Drivers
INSERT INTO Drivers (PhoneDriver, EmailDriver, CarID)
VALUES
('89101234567', 'driver1@example.com', 1),
('89091234567', 'driver2@example.com', 2),
('89361234567', 'driver3@example.com', 3),
('89011234567', 'driver4@example.com', 4),
('89561234567', 'driver5@example.com', 5);
select * from Drivers
-- Вставка данных в таблицу Clients
INSERT INTO Clients (PhoneClient, CityClient)
VALUES
('9012345678',N'Москва'),
('9023456789', N'Санкт-Петербург'),
('9034567890', N'Новосибирск'),
('9045678901', N'Казань'),
('9056789012', N'Екатеринбург');
select * from clients
-- Вставка данных в таблицу TaxiOrders
INSERT INTO TaxiOrders (PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel)
VALUES
(500.00, 1, 1, N'Москва', getdate(), 15.5),
(750.00, 2, 3, N'Санкт-Петербург', getdate(), 25.0),
(1200.00, 3, 1, N'Новосибирск', getdate(), 45.0),
(600.00, 2, 4, N'Казань',null, 20.0),
(900.00, 5, 2, N'Екатеринбург',getdate(),30.0);

-- 4 
select 
    c.ClientId,
    c.CityClient as HomeCity,
    t.CityTravel as DestinationCity,
    count(*) as TripCount
from Clients c
inner join TaxiOrders t on c.ClientId = t.ClientId
where t.CityTravel != c.CityClient
group by c.ClientId, c.CityClient, t.CityTravel
order by count(*) desc;

-- 5
-- Создание графовых узлов (Nodes)

create table ClientNode (
    ClientId int primary key,
    PhoneClient nvarchar(15),
    CityClient nvarchar(20)
) as node;
go

create table DriverNode (
    DriveId int primary key,
    PhoneDriver nvarchar(15),
    EmailDriver nvarchar(50)
) as node;
go

create table CarNode (
    CarID int primary key
) as node;
go

create table CityNode (
    CityName nvarchar(20) primary key
) as node;
go

create table OrderEdge (
    OrderId int primary key,
    PriceTravel money,
    DateTravel date,
    TimeTravel float,
    CityTravel nvarchar(20) 
) as edge;
go

create table DrivesCarEdge as edge;
go

create table LivesInEdge as edge;
go

------------------------------------------
insert into ClientNode (ClientId, PhoneClient, CityClient)
select ClientId, PhoneClient, CityClient
from Clients;

insert into DriverNode (DriveId, PhoneDriver, EmailDriver)
select DriveId, PhoneDriver, EmailDriver
from Drivers;

insert into CarNode (CarID)
select CarID
from Cars;

insert into CityNode (CityName)
select distinct CityClient from Clients
union
select distinct CityTravel from TaxiOrders where CityTravel is not null;

insert into DrivesCarEdge ($from_id, $to_id)
select 
    (select $node_id from DriverNode where DriveId = d.DriveId),
    (select $node_id from CarNode where CarID = d.CarID)
from Drivers d;

insert into LivesInEdge ($from_id, $to_id)
select 
    (select $node_id from ClientNode where ClientId = c.ClientId),
    (select $node_id from CityNode where CityName = c.CityClient)
from Clients c;

insert into OrderEdge ($from_id, $to_id, OrderId, PriceTravel, DateTravel, TimeTravel, CityTravel)
select 
    (select $node_id from ClientNode where ClientId = t.ClientId),
    (select $node_id from DriverNode where DriveId = t.DriveId),
    t.OrderId,
    t.PriceTravel,
    t.DateTravel,
    t.TimeTravel,
    t.CityTravel
from TaxiOrders t;
go

-- 5
--данные
INSERT INTO TaxiOrders (PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel)
VALUES
-- Клиент 1 едет с водителем 1 второй раз
(800.00, 1, 1, N'Казань', '2024-01-15', 30.0),

-- Клиент 1 едет с водителем 1 третий раз
(650.00, 1, 1, N'Екатеринбург', '2024-01-20', 28.0),

-- Клиент 2 едет с водителем 3 второй раз
(950.00, 2, 3, N'Москва', '2024-01-18', 35.0),

-- Клиент 3 едет с водителем 1 второй раз
(1100.00, 3, 1, N'Казань', '2024-01-22', 40.0),

-- Клиент 4 едет с водителем 4 первый раз
(700.00, 4, 4, N'Москва', '2024-01-25', 22.0),

-- Клиент 4 едет с водителем 4 второй раз
(550.00, 4, 4, N'Санкт-Петербург', '2024-01-28', 18.0);
go

-- Обновляем графовую модель новыми заказами
insert into OrderEdge ($from_id, $to_id, OrderId, PriceTravel, DateTravel, TimeTravel, CityTravel)
select 
    (select $node_id from ClientNode where ClientId = t.ClientId),
    (select $node_id from DriverNode where DriveId = t.DriveId),
    t.OrderId,
    t.PriceTravel,
    t.DateTravel,
    t.TimeTravel,
    t.CityTravel
from TaxiOrders t
where t.OrderId > 5; -- Только новые заказы
go

select 
    c.ClientId,
    c.PhoneClient,
    d.DriveId,
    d.PhoneDriver,
    d.EmailDriver,
    count(*) as TripCount
from ClientNode c, OrderEdge o, DriverNode d
where match(c-(o)->d)
group by c.ClientId, c.PhoneClient, d.DriveId, d.PhoneDriver, d.EmailDriver
having count(*) >= 2
order by count(*) desc;

-- 6. Хранимая процедура для расчета выручки таксиста по месяцам за текущий год
create procedure GetDriverMonthlyRevenue
    @DriverId int
as
begin
    select 
        d.DriveId,
        d.PhoneDriver,
        d.EmailDriver,
        month(t.DateTravel) as Month,
        datename(month, t.DateTravel) as MonthName,
        count(*) as OrderCount,
        sum(t.PriceTravel) as TotalRevenue
    from Drivers d
    left join TaxiOrders t on d.DriveId = t.DriveId
    where d.DriveId = @DriverId
        and year(t.DateTravel) = year(getdate()) -- Текущий год
        and t.DateTravel is not null
    group by d.DriveId, d.PhoneDriver, d.EmailDriver, month(t.DateTravel), datename(month, t.DateTravel)
    order by month(t.DateTravel);
end;
go

-- Использование:
exec GetDriverMonthlyRevenue @DriverId = 1;


-- 7 
-- данные 
-- Добавляем поле времени заказа
alter table TaxiOrders
add OrderDateTime datetime default getdate();
go

-- Обновляем существующие записи (задаем разное время)
update TaxiOrders set OrderDateTime = dateadd(hour, OrderId, '2024-01-30 10:00:00');
go

-- 7. Триггер: не более 2х поездок в один город в течение 2 часов
create trigger trg_LimitCityTrips
on TaxiOrders
instead of insert
as
begin
    -- Проверяем каждую вставляемую запись
    if exists (
        select 1
        from inserted i
        where (
            -- Считаем поездки клиента в тот же город за последние 2 часа
            select count(*)
            from TaxiOrders t
            where t.ClientId = i.ClientId
                and t.CityTravel = i.CityTravel -- В тот же город
                and t.OrderDateTime >= dateadd(hour, -2, i.OrderDateTime) -- За последние 2 часа
                and t.OrderDateTime < i.OrderDateTime -- До текущего заказа
        ) >= 2 -- Уже есть 2 заказа
    )
    begin
        raiserror('Ошибка: клиент не может заказывать более 2х поездок в один город в течение 2 часов!', 16, 1);
        rollback transaction;
        return;
    end;
    
    -- Если проверка пройдена, вставляем данные
    insert into TaxiOrders (PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel, OrderDateTime)
    select PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel, 
           coalesce(OrderDateTime, getdate())
    from inserted;
end;
go


INSERT INTO TaxiOrders (PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel, OrderDateTime)
VALUES (1000.00, 1, 2, N'Москва', '2024-01-30', 8.0, '2024-01-30 10:00:00');
-- Успех

-- 2. Клиент 1 заказывает поездку в Москву в 10:30 (через 30 минут)
INSERT INTO TaxiOrders (PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel, OrderDateTime)
VALUES (1200.00, 1, 3, N'Москва', '2024-01-30', 9.0, '2024-01-30 10:30:00');
-- Успех (2-я поездка)

-- 3. Клиент 1 заказывает поездку в Москву в 11:00 (через 1 час) - ОШИБКА!
INSERT INTO TaxiOrders (PriceTravel, ClientId, DriveId, CityTravel, DateTravel, TimeTravel, OrderDateTime)
VALUES (1500.00, 1, 4, N'Москва', '2024-01-30', 10.0, '2024-01-30 11:00:00');
-- Ожибка! (3-я поездка в течение 2 часов)

-- 8
select 
    car.CarID as "car_id",
    json_query(
        (
            select 
                d.DriveId as "driver_id",
                d.EmailDriver as "email",
                d.PhoneDriver as "phone"
            from Drivers d
            where d.CarID = car.CarID
            for json path, without_array_wrapper
        )
    ) as "driver",
    json_query(
        (
            select 
                t.OrderId as "order_id",
                t.PriceTravel as "Price",
                t.CityTravel as "City",
                convert(varchar(10), t.DateTravel, 23) as "Date",
                json_query(
                    (
                        select 
                            c.ClientId as "client_id",
                            c.PhoneClient as "phone",
                            c.CityClient as "City"
                        from Clients c
                        where c.ClientId = t.ClientId
                        for json path, without_array_wrapper
                    )
                ) as "client"
            from TaxiOrders t
            inner join Drivers d on t.DriveId = d.DriveId
            where d.CarID = car.CarID
            order by t.OrderDateTime desc
            for json path
        )
    ) as "TaxiOrders"
from Cars car
for json path;