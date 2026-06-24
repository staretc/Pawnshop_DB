-- Узлы: Терминалы и Самолеты
CREATE TABLE TerminalGateNode (
    GateId INT IDENTITY(1,1) PRIMARY KEY,
    GateNumber NVARCHAR(10) NOT NULL,
    TerminalLetter NVARCHAR(5) NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    MaxLoad DECIMAL(10,2) NOT NULL CHECK (MaxLoad  >= 0)
) AS NODE;

CREATE TABLE AircraftNode (
    AircraftId INT IDENTITY(1,1) PRIMARY KEY,
    TailNumber NVARCHAR(20) NOT NULL,
    ModelName NVARCHAR(50) NOT NULL
) AS NODE;

-- Ребра: Назначение на гейт и Трансферные коридоры между гейтами
CREATE TABLE AssignedToGatg (
    BaggageFeeUSD DECIMAL(10,2) NOT NULL CHECK (BaggageFeeUSD >= 0),
    ServiceRate DECIMAL(10,2) NOT NULL
    
) AS EDGE;

CREATE TABLE TransferRoute (
    DistanceMeters INT NOT NULL CHECK (DistanceMeters > 0)
) AS EDGE;
GO

-- Наполнение данными
INSERT INTO TerminalGateNode (GateNumber, TerminalLetter, MaxLoad) VALUES ('A-1', 'A', 1000), ('A-2', 'A', 456), ('B-1', 'B', 780);
INSERT INTO TerminalGateNode (GateNumber, TerminalLetter, MaxLoad) VALUES ('B-2', 'B', 600), ('C-1', 'C', 740), ('C-2', 'C', 800);
INSERT INTO AircraftNode (TailNumber, ModelName) VALUES ('RA-73001', 'Boeing 777'), ('RA-89002', 'SSJ-100');
INSERT INTO AircraftNode (TailNumber, ModelName) VALUES ('RA-90000', 'Boeing 776'), ('RA-90001', 'SSJ-100'), ('RA-90010', 'Boeing 775');

INSERT INTO AssignedToGatg ($from_id, $to_id, BaggageFeeUSD, ServiceRate ) VALUES 
((SELECT $node_id FROM AircraftNode WHERE TailNumber = 'RA-73001'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-1'), 150.00, 1.2),
((SELECT $node_id FROM AircraftNode WHERE TailNumber = 'RA-89002'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-2'), 90.00, 2.3);

INSERT INTO AssignedToGatg ($from_id, $to_id, BaggageFeeUSD, ServiceRate ) VALUES 
((SELECT $node_id FROM AircraftNode WHERE TailNumber = 'RA-90000'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'B-1'), 160.00, 4.2),
((SELECT $node_id FROM AircraftNode WHERE TailNumber = 'RA-90010'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), 145.00, 3.2),
((SELECT $node_id FROM AircraftNode WHERE TailNumber = 'RA-90001'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-2'), 95.00, 3.3);

INSERT INTO TransferRoute ($from_id, $to_id, DistanceMeters) VALUES 
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-2'), 120),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-2'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-1'), 120);


INSERT INTO TransferRoute ($from_id, $to_id, DistanceMeters) VALUES 
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-2'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'B-1'), 160),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'B-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-2'), 160),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-2'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), 120),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-2'), 120),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'B-1'), 120),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'B-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), 160),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-1'), 150),
((SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'A-1'), (SELECT $node_id FROM TerminalGateNode WHERE GateNumber = 'C-1'), 150);
GO
delete from TransferRoute

-- 3 все самолеты, которые припаркованы у гейтов, находящихся в пешей близости от гейта самолета 'RA-73001' (расстояние меньше 150м)
select 
    an1.TailNumber,
    tgn1.GateNumber,
    tr.DistanceMeters
from AircraftNode an, AssignedToGatg atg,TerminalGateNode tgn,TerminalGateNode tgn1,TransferRoute tr, AssignedToGatg atg1, AircraftNode an1
where match(an-(atg)->tgn-(tr)->tgn1<-(atg1)-an1) 
    AND tr.DistanceMeters < 150 
    AND an.TailNumber = 'RA-73001' -- можно на этом проверить'RA-90010'
    AND an1.TailNumber != 'RA-73001' --'RA-90010'

-- 4 Реляционная БД
create table AirportObjects1 (
    ObjectId int primary key,
    ObjectType nvarchar(20) not null,
    
    -- Поля для гейтов
    GateNumber nvarchar(10) null,
    TerminalLetter nvarchar(5) null,
    IsActive bit null,
    MaxLoad decimal(10,2) null,
    
    -- Поля для самолётов
    TailNumber nvarchar(20) null,
    ModelName nvarchar(50) null,
    
    -- Ограничения
    constraint CK_Gate_Required1 check (
        (ObjectType = 'Gate' and GateNumber is not null and TerminalLetter is not null and MaxLoad is not null and MaxLoad >= 0)
        or ObjectType = 'Aircraft'
    ),
    constraint CK_Aircraft_Required1 check (
        (ObjectType = 'Aircraft' and TailNumber is not null and ModelName is not null)
        or ObjectType = 'Gate'
    )
);
-- b. HubConnections: Таблица связей, заменяющая ребро (TransferRoute)
create table HubConnections (
    FromGateId int not null foreign key references AirportObjects1(ObjectId),
    ToGateId int not null foreign key references AirportObjects1(ObjectId),
    primary key (FromGateId,ToGateId) ,
    DistanceMeters int not null check (DistanceMeters > 0)
);

-- c. FlightLogs: Таблица логов обслуживания (замена AssignedToGatg)
create table FlightLogs1 (
    primary key (AircraftId,GateId),
    AircraftId int not null foreign key references AirportObjects1(ObjectId),
    GateId int not null foreign key references AirportObjects1(ObjectId),
    BaggageFeeUSD decimal(10,2) not null check (BaggageFeeUSD >= 0),
    ServiceRate decimal(10,2) not null,
    ServiceDateTime datetime default getdate()
);
go

-- заполняем

insert into AirportObjects1 ([ObjectId], ObjectType, GateNumber, TerminalLetter, IsActive, MaxLoad)
select GateId, 'Gate', GateNumber, TerminalLetter, IsActive, MaxLoad
from TerminalGateNode;

insert into AirportObjects1 ([ObjectId], ObjectType, TailNumber, ModelName)
select AircraftId+100,'Aircraft', TailNumber, ModelName
from AircraftNode;

-- Переносим связи из TransferRoute
insert into HubConnections (FromGateId, ToGateId, DistanceMeters)
select 
    ao1.ObjectId as FromGateId,
    ao2.ObjectId as ToGateId,
    tr.DistanceMeters
from TransferRoute tr,TerminalGateNode tgn1,TerminalGateNode tgn2,
        AirportObjects1 ao1,
        AirportObjects1 ao2
where match(tgn1-(tr)->tgn2) and ao1.GateNumber= tgn1.GateNumber 
and ao1.GateNumber = tgn1.GateNumber and ao2.GateNumber = tgn2.GateNumber

-- Переносим назначения из AssignedToGatg
insert into FlightLogs1 (AircraftId, GateId, BaggageFeeUSD, ServiceRate, ServiceDateTime)
select 
    ao_aircraft.ObjectId,
    ao_gate.ObjectId,
    atg.BaggageFeeUSD,
    atg.ServiceRate,
    dateadd(hour, ao_aircraft.ObjectId + ao_gate.ObjectId, '2026-06-01') -- Разные даты на основе ID
from AssignedToGatg atg, AircraftNode an, TerminalGateNode tgn, AirportObjects1 ao_aircraft, AirportObjects1 ao_gate
where match(an-(atg)->tgn) 
    and ao_aircraft.TailNumber = an.TailNumber 
    and ao_aircraft.ObjectType = 'Aircraft'
    and ao_gate.GateNumber = tgn.GateNumber 
    and ao_gate.ObjectType = 'Gate';

-- 5. добавим данные
insert into FlightLogs1 (AircraftId, GateId, BaggageFeeUSD, ServiceRate, ServiceDateTime)
values
    ((select ObjectId from AirportObjects1 where TailNumber = 'RA-73001'), 
     (select ObjectId from AirportObjects1 where GateNumber = 'B-1'), 
     250.00, 1.2, '2026-06-15T10:30:00'),
    
    ((select ObjectId from AirportObjects1 where TailNumber = 'RA-73001'), 
     (select ObjectId from AirportObjects1 where GateNumber = 'C-1'), 
     180.00, 2.5, '2026-06-16T14:20:00'),
    
    ((select ObjectId from AirportObjects1 where TailNumber = 'RA-73001'), 
     (select ObjectId from AirportObjects1 where GateNumber = 'B-2'), 
     220.00, 3.8, '2026-06-18T12:00:00');
go
select * from FlightLogs1

-- 5.
with AircraftServiceLog as (
    select 
        ao.TailNumber,
        ao.ModelName,
        ao_gate.GateNumber,
        fl.ServiceDateTime,
        fl.ServiceRate,
        fl.BaggageFeeUSD
    from FlightLogs1 fl
    inner join AirportObjects1 ao on fl.AircraftId = ao.ObjectId
    inner join AirportObjects1 ao_gate on fl.GateId = ao_gate.ObjectId
    where ao.ObjectType = 'Aircraft' and ao_gate.ObjectType = 'Gate'
)
select 
    TailNumber,
    ModelName,
    GateNumber,
    ServiceDateTime,
    ServiceRate,
    BaggageFeeUSD,
    avg(BaggageFeeUSD) over (
        partition by TailNumber 
        order by ServiceDateTime 
        rows between 2 preceding and current row
    ) as MovingAverage_3Records
from AircraftServiceLog
order by TailNumber, ServiceDateTime;

-- 6.
create procedure FindGateWithMaxBaggage
    @SearchDate date
as
begin
    select top 1
        ao_gate.GateNumber,
        ao_gate.TerminalLetter,
        sum(fl.BaggageFeeUSD) as TotalBaggage,
        count(*) as ServiceCount
    from FlightLogs1 fl
    inner join AirportObjects1 ao_gate on fl.GateId = ao_gate.ObjectId
    where ao_gate.ObjectType = 'Gate'
        and cast(fl.ServiceDateTime as date) = @SearchDate
    group by ao_gate.GateNumber, ao_gate.TerminalLetter
    order by sum(fl.BaggageFeeUSD) desc;
end;
go

-- Использование:
exec FindGateWithMaxBaggage @SearchDate = '2026-06-15';

-- 7
create trigger trg_PreventBaggageOverload
on FlightLogs1
instead of insert
as
begin
    -- Проверяем все вставляемые записи за один раз
    if exists (
        select 1
        from inserted i
        inner join AirportObjects1 ao on i.GateId = ao.ObjectId
        cross apply (
            select isnull(sum(BaggageFeeUSD), 0) as CurrentLoad
            from FlightLogs1
            where GateId = i.GateId
        ) as current_load
        where ao.ObjectType = 'Gate'
            and (current_load.CurrentLoad + i.BaggageFeeUSD) > ao.MaxLoad
    )
    begin
        raiserror('Ошибка: превышена максимальная загрузка багажной ленты гейта!', 16, 1);
        rollback transaction;
        return;
    end;
    
    -- Если проверка пройдена, вставляем данные
    insert into FlightLogs1 (AircraftId, GateId, BaggageFeeUSD, ServiceRate, ServiceDateTime)
    select AircraftId, GateId, BaggageFeeUSD, ServiceRate, ServiceDateTime
    from inserted;
end;
go
-- 8.
select 
    (
        select 
            gate.ObjectId as "GateId",
            gate.GateNumber as "GateNumber",
            gate.TerminalLetter as "Terminal",
            gate.MaxLoad as "MaxLoad",
            (
                select 
                    aircraft.ObjectId as "AircraftId",
                    aircraft.TailNumber as "TailNumber",
                    (
                        select 
                            convert(varchar, fl.ServiceDateTime, 127) as "Timestamp",
                            fl.BaggageFeeUSD as "BaggageKG",
                            fl.ServiceRate as "ServiceRate"
                        from FlightLogs1 fl
                        where fl.AircraftId = aircraft.ObjectId 
                            and fl.GateId = gate.ObjectId
                        order by fl.ServiceDateTime
                        for json path
                    ) as "MaintenanceHistory"
                from AirportObjects1 aircraft
                where aircraft.ObjectType = 'Aircraft'
                    and exists (
                        select 1 from FlightLogs1 fl 
                        where fl.AircraftId = aircraft.ObjectId 
                            and fl.GateId = gate.ObjectId
                    )
                for json path
            ) as "AssignedAircrafts"
        from AirportObjects1 gate
        where gate.ObjectType = 'Gate'
        for json path
    ) as "AirportExport"
for json path, without_array_wrapper;