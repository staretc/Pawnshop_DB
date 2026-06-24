-- 1.

create database ScooterRental;

create table Tariffs (
	ID int not null primary key,
	NameTariffs nvarchar(50) not null UNIQUE,
	PriceStart int not null,
	PriceMinute int not null
)

create table Scooters(
	ID int not null primary key,
	SerialNumber int not null,
	Model nvarchar(50) not null,
	BataryLevel int  not null CHECK (BataryLevel between 0 and 100),
	Status nvarchar(20) not null CHECK (Status in ('Доступен', 'В поездке', 'На зарядке', 'Обслуживание'))
)

create table Users (
	ID int not null primary key,
	email nvarchar(50) not null UNIQUE,
	Balance int not null,
	StatusVerification nvarchar(3) not null CHECK (StatusVerification in ('Да', 'Нет'))
)

create table Rides (
	ID int not null primary key,
	UserID int not null foreign key references Users(ID) on delete cascade,
	ScooterID int not null foreign key references Scooters(ID),
	TimeStart datetime not null,
	TimeEnd datetime null,
	Distance int not null,
	TarifID int not null foreign key references Tariffs(ID),
	TotalPrice int null,
	Feedback nvarchar(250) null,
	constraint TimeCheck CHECK (TimeEnd is null or TimeStart <= TimeEnd)
)

create table UserBalanceAudit(
	ID int not null primary key,
	UserID int not null foreign key references Users(ID),
	OldBalance int not null,
	NewBalance int not null,
	SystemUserName nvarchar(50) not null,
	Date datetime not null 
)


-- =============================
-- 2. Заполнение данными
-- =============================


insert into Tariffs (ID, NameTariffs, PriceStart, PriceMinute)
values (1, 'Эконом', 50, 6),
		(2, 'Стандарт', 80, 10),
		(3, 'Стандарт+', 100, 15)

insert into Scooters (ID, SerialNumber, Model, BataryLevel, Status)
values (1, 1, 'Юрент', 70, 'Доступен'),
		(2, 1, 'Яндекс', 90, 'В поездке'),
		(3, 2, 'Юрент', 55, 'На зарядке'),
		(4, 1, 'Вхуш', 30, 'Обслуживание'),
		(5, 1, 'Юрент', 25, 'Доступен')

insert into Users (ID, email, Balance, StatusVerification)
values (1, 'ivanov@mail.ru', 100, 'Да'),
	(2, 'smirnov@mail.ru', 250, 'Да'),
	(3, 'petrov@mail.ru', 1000, 'Нет')

insert into Rides (ID, UserID, ScooterID, TimeStart, TimeEnd, Distance, TarifID, TotalPrice, Feedback)
values (1, 1, 1, '2026-06-25T10:25:00', '2026-06-25T10:50:00', 1500, 1, 200, 'Хорошо'),
		(2, 2, 2, '2026-06-24T20:00:00', '2026-06-24T21:30:00', 3500, 2, 100, 'Нормальная поездка'),
		(3, 3, 3, '2026-06-11T09:12:00', '2026-06-11T10:00:00', 4000, 3, 340, 'Самокат хороший'),
		(4, 1, 4, '2026-06-25T15:45:00', '2026-06-25T16:05:00', 500, 1, 400, 'Все норм'),
		(5, 2, 5, '2026-06-25T10:25:00', NULL, 200, 3, NULL, NULL)


insert into UserBalanceAudit (ID, UserID, OldBalance, NewBalance, SystemUserName, Date)
values 
	(1, 1, 100, -100, 'system', '2026-06-25T10:50:00'),
	(2, 2, 250, -730, 'system', '2026-06-24T21:30:00'),
	(3, 3, 1000, 180, 'system', '2026-06-11T10:00:00')


-- ================================================
-- 3. для каждого пользователя вывести список всех поездок, отсортированных по дате начала, и с помощью оконной функции 
-- рассчитать нарастающий итог потраченный им денег (стоимост поездок)
-- ================================================

select 
    u.ID, u.email, r.ID,
    r.TimeStart, r.TimeEnd, r.Distance,
    t.NameTariffs,
    r.TotalPrice,
    SUM(r.TotalPrice) OVER (PARTITION BY r.UserID ORDER BY r.TimeStart) as TotalSpent
from 
    Rides r
    join Users u on r.UserID = u.ID
    join Tariffs t on r.TarifID = t.ID
where r.TotalPrice is not null  -- исключаем активные поездки
order by u.ID, r.TimeStart;

--Оконная функция — это функция, которая выполняет вычисления над набором строк (окном), 
--связанных с текущей строкой, сохраняя при этом все строки в результате (в отличие от GROUP BY, 
--который сворачивает данные в одну строку)


-- ================================================
-- 4. Графовая модель
-- ================================================

create table UsersNode (
	ID int not null primary key,
	email nvarchar(50) not null UNIQUE,
	Balance int not null,
	StatusVerification nvarchar(3) not null CHECK (StatusVerification in ('Да', 'Нет'))
) as Node

create table ScootersNode(
	ID int not null primary key,
	SerialNumber int not null,
	Model nvarchar(50) not null,
	BataryLevel int  not null CHECK (BataryLevel between 0 and 100),
	Status nvarchar(20) not null CHECK (Status in ('Доступен', 'В поездке', 'На зарядке', 'Обслуживание'))
) as Node

-- Связи
create table IsFriendsWith as Edge;
create table Rented (
    TimeStart datetime not null,
    TimeEnd datetime null,
    Distance int not null,
    TotalPrice int null
) as Edge;

insert into UsersNode(ID, email, Balance, StatusVerification)
select ID, email, Balance, StatusVerification
from Users

insert into ScootersNode (ID, SerialNumber, Model, BataryLevel, Status)
select ID, SerialNumber, Model, BataryLevel, Status
from Scooters

insert into IsFriendsWith
values ((select $node_id from UsersNode where ID = 1), (select $node_id from UsersNode where ID = 2)),
		((select $node_id from UsersNode where ID = 2), (select $node_id from UsersNode where ID = 3)),
		((select $node_id from UsersNode where ID = 1), (select $node_id from UsersNode where ID = 3))

insert into Rented
values ((select $node_id from UsersNode where ID = 1), (select $node_id from ScootersNode where ID = 1),
	 '2026-06-25T10:25:00', '2026-06-25T10:50:00', 1500, 200),
	((select $node_id from UsersNode where ID = 1), (select $node_id from ScootersNode where ID = 5),
	 '2026-06-25T10:25:00', NULL, 200, NULL),
	((select $node_id from UsersNode where ID = 2), (select $node_id from ScootersNode where ID = 3),
	 '2026-06-24T20:00:00', '2026-06-24T21:30:00', 3500, 980),
	((select $node_id from UsersNode where ID = 3), (select $node_id from ScootersNode where ID = 2),
	 '2026-06-11T09:12:00', '2026-06-11T10:00:00', 4000, 820),
	((select $node_id from UsersNode where ID = 3), 
	 (select $node_id from ScootersNode where ID = 4),
	 '2026-06-25T15:45:00', '2026-06-25T16:05:00', 500, 170);

--================================================
-- 5. все самокаты, которые арендовали друзья пользователя Ивана (глубина связи 1 друг),
-- но сам Иван никода эти модели самокатов не брал 
--================================================
select u1.ID, u1.email, s.ID, s.Model
from UsersNode u, ScootersNode s, IsFriendsWith f, Rented r, UsersNode u1
where match (u-(f)->u1) and u.ID = 1
and match (u1-(r)->s)
and not exists (
	select 1 
	from Rented r2
	where match (u-(r2)->s)
)

-- если исключать именно модели
select u1.ID, u1.email, s.ID, s.Model
from UsersNode u, ScootersNode s, IsFriendsWith f, Rented r, UsersNode u1
where match (u-(f)->u1) and u.ID = 1
and match (u1-(r)->s)
and not exists (
	select 1 
	from Rented r2, ScootersNode s2
	where 
	match (u-(r2)->s2) and s2.Model = s.Model
)


--================================================
-- 6. процедура или функция в графовой модели на работу с таблицей Rented.
-- Если система фиксирует попытку начать новую поездку для UserId, у которого прямо сейчас уже есть другая незавершенная поездка
-- (где время окончания IS NULL) транзакция должна быть жестко заблокирована и откатана с выводом предупреждения
--================================================

create or alter function CheckActiveRide (
    @UserID int
)
returns nvarchar(100)
as
begin
    declare @Result nvarchar(100);
    -- Проверяем, есть ли активная поездка 
    if exists (
        select 1
        from UsersNode u, Rented r, ScootersNode s
        where match(u-(r)->s)
        and u.ID = @UserID
        and r.TimeEnd is null
    )
    begin
        set @Result = 'ОШИБКА: У пользователя уже есть активная поездка';
    end
    else
    begin
        set @Result = 'OK';
    end
    
    return @Result;
end;


select dbo.CheckActiveRide(1) as Status;

-- ================================================
-- 7. триггер на таблицу пользователей. При любом изменении баланса кошелька (Balance) триггер должен автоматически фиксировать старое, новое значение и метаданные операции в таблицу UserBalance Audit. 
-- ================================================

CREATE TRIGGER trg_AuditUserBalance
ON Users
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Проверяем, затрагивал ли запрос столбец Balance
    IF UPDATE(Balance)
    BEGIN
        -- Находим текущий максимальный ID в аудите, чтобы продолжить нумерацию
        DECLARE @BaseID INT;
        SELECT @BaseID = ISNULL(MAX(ID), 0) FROM UserBalanceAudit;

        -- Вставляем данные об изменениях
        INSERT INTO UserBalanceAudit (ID, UserID, OldBalance, NewBalance, SystemUserName, Date)
        SELECT 
            -- Динамически формируем ID для каждой вставляемой строки
            @BaseID + ROW_NUMBER() OVER (ORDER BY i.ID),
            i.ID,
            d.Balance,  -- Старое значение из таблицы deleted
            i.Balance,  -- Новое значение из таблицы inserted
            'system',   -- Имя пользователя
            GETDATE()   -- Текущая дата и время
        FROM inserted i
        JOIN deleted d ON i.ID = d.ID
        WHERE i.Balance <> d.Balance; -- Логируем только если баланс реально изменился
    END
END;
GO

-- ================================================
-- 8. Преобразование реляционной структуры в JSON для MongoDB
-- ================================================
select 
    u.id as userId,
    u.email as email,
    
    -- profile
    json_query((
        select 
            u.statusverification as isVerified,
            cast(u.balance as decimal(10,2)) as currentBalance
        for json path, without_array_wrapper
    )) as profile,
    
    -- activeRides (массив активных поездок)
    json_query((
        select 
            s.model as scooterModel,
            r.timestart as startTime
        from rides r
        join scooters s on r.scooterid = s.id
        where r.userid = u.id 
            and r.timeend is null
        for json path
    )) as activeRides,
    
    -- pastRidesSummary (массив с итогами по завершенным поездкам)
    json_query((
        select 
            sum(r.distance) as totalDistance,
            cast(sum(r.totalprice) as decimal(10,2)) as totalSpent
        from rides r
        where r.userid = u.id 
            and r.timeend is not null
            and r.totalprice is not null
        for json path
    )) as pastRidesSummary

from users u
where u.id is not null
for json path;