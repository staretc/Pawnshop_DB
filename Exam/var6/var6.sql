-- 1.

CREATE TABLE Cells (
    CellId INT,
    CellCode NVARCHAR(20) NOT NULL UNIQUE,
    CellType NVARCHAR(30) NOT NULL CHECK (CellType IN ('Standard', 'Refrigerated')),
    MaxWeightKG INT NOT NULL CHECK (MaxWeightKG > 0)
);

CREATE TABLE Items (
    ItemId INT,
    ItemName NVARCHAR(100) NOT NULL,
    RequiredTempCelsius DECIMAL(4,1) NOT NULL
);

CREATE TABLE Pallets (
    PalletId INT,
    CurrentWeightKG INT NOT NULL,
    PalletStatus NVARCHAR(20) NOT NULL DEFAULT 'Empty' CHECK (PalletStatus IN ('Empty', 'Loaded', 'InTransit'))
);

CREATE TABLE Movements (
    MovementId INT,
    PalletId INT NOT NULL,
    FromCellId INT NOT NULL,
    ToCellId INT NOT NULL,
    StartTime DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    EndTime DATETIME2 NULL,
    RobotId INT NOT NULL
);

CREATE TABLE TelemetryAudit (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    CellId INT NOT NULL,
    OldTemp DECIMAL(4,1) NULL,
    NewTemp DECIMAL(4,1) NULL,
    ChangedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);

CREATE TABLE PalletContents (
    PalletId INT NOT NULL,
    ItemId INT NOT NULL,
    Quantity INT NOT NULL-- Количество штук товара на паллете
   
);

CREATE TABLE CellAdjacency (
    CellId INT NOT NULL,
    NeighborCellId INT NOT NULL,
    DistanceMeter DECIMAL(4,2) NOT NULL DEFAULT 1.0, -- Дополнительно: расстояние между ними
       -- Защита от связи ячейки самой с собой
    CONSTRAINT CHK_NoSelfNeighbor CHECK (CellId <> NeighborCellId) 
);

GO

-- ============================================================================
-- ЧАСТЬ 2: НАПОЛНЕНИЕ ДАННЫМИ (DML)
-- ============================================================================

INSERT INTO Cells (CellCode, CellType, MaxWeightKG) VALUES 
('A-01', 'Standard', 2000),
('B-02', 'Refrigerated', 1500),
('C-03', 'Standard', 1000);

INSERT INTO Items (ItemName, RequiredTempCelsius) VALUES 
('Heavy Machinery Parts', 22.0),
('Frozen Fish', -18.5),
('Electronics', 20.0);

INSERT INTO Pallets (CurrentWeightKG, PalletStatus) VALUES 
(800, 'Loaded'),
(1200, 'InTransit'),
(300, 'Empty');

-- Прошедшие и одно активное перемещение
INSERT INTO Movements (PalletId, FromCellId, ToCellId, StartTime, EndTime, RobotId) VALUES 
(1, 1, 3, DATEADD(hour, -5, SYSUTCDATETIME()), DATEADD(hour, -4, SYSUTCDATETIME()), 101),
(3, 3, 1, DATEADD(hour, -2, SYSUTCDATETIME()), DATEADD(hour, -1, SYSUTCDATETIME()), 102),
(2, 1, 2, DATEADD(minute, -10, SYSUTCDATETIME()), NULL, 103); -- Активное (InTransit)
GO

-- 2.
-- ПРИВОДИМ МОДЕЛЬ К РИСУНКУ

-- Cells
update Cells
set CellId = 1
where CellCode = 'A-01'

update Cells
set CellId = 2
where CellCode = 'B-02'

update Cells
set CellId = 3
where CellCode = 'C-03'

alter table Cells
alter column CellId INT not null

alter table Cells
add constraint PK_CellId primary key (CellId)

-- Items
update Items
set ItemId = 1
where ItemName = 'Heavy Machinery Parts'

update Items
set ItemId = 2
where ItemName = 'Frozen Fish'

update Items
set ItemId = 3
where ItemName = 'Electronics'

alter table Items
alter column ItemId INT not null

alter table Items
add constraint PK_ItemId primary key (ItemId)

-- Pallets
update Pallets
set PalletId = 1
where CurrentWeightKG = 800

update Pallets
set PalletId = 2
where CurrentWeightKG = 1200

update Pallets
set PalletId = 3
where CurrentWeightKG = 300

alter table Pallets
alter column PalletId INT not null

alter table Pallets
add constraint PK_PalletId primary key (PalletId)

-- Movements
-- primary key
update Movements
set MovementId = 1
where RobotId = 101

update Movements
set MovementId = 2
where RobotId = 102

update Movements
set MovementId = 3
where RobotId = 103

alter table Movements
alter column MovementId INT not null

alter table Movements
add constraint PK_MovementId primary key (MovementId)

-- foreign keys
alter table Movements
add constraint FK_PalletId foreign key (PalletId) references Pallets(PalletId)

alter table Movements
add constraint FK_FromCellId foreign key (FromCellId) references Cells(CellId)

alter table Movements
add constraint FK_ToCellId foreign key (ToCellId) references Cells(CellId)

-- TelemetryAudit
-- с ним всё ок

-- PalletContents
alter table PalletContents
add constraint FK_PalletId_PC foreign key (PalletId) references Pallets(PalletId) on delete cascade -- каскадное удаление паллеты

alter table PalletContents
add constraint FK_ItemId foreign key (ItemId) references Items(ItemId)

-- CellAdjacency
alter table CellAdjacency
add constraint FK_CellId_CA foreign key (CellId) references Cells(CellId)

alter table CellAdjacency
add constraint FK_NeighborCellId foreign key (NeighborCellId) references Cells(CellId)

-- ДОБАВЛЯАЕМ CHECKS
alter table Pallets
add constraint check_weight check ([CurrentWeightKG] > 0) 

alter table Movements
add constraint check_endTime check ([EndTime] >= [StartTime])

-- ДОБАВЛЯЕМ СВОИ ДАННЫЕ
-- заполнение таблицы cells
insert into Cells (CellId, CellCode, CellType, MaxWeightKG) values
(4, 'D-01', 'Standard', 1500),
(5, 'D-02', 'Standard', 1500),
(6, 'D-03', 'Refrigerated', 1000),
(7, 'D-04', 'Refrigerated', 1000),
(8, 'D-05', 'Standard', 2000);

-- заполнение таблицы items
insert into Items (ItemId, ItemName, RequiredTempCelsius) values
(101, 'молоко 3.2%', 4.0),
(102, 'замороженная рыба', -18.0),
(103, 'крупа гречневая', 20.0),
(104, 'свежие яблоки', 6.0),
(105, 'шоколадные конфеты', 15.0);

-- заполнение таблицы pallets
insert into Pallets (PalletId, CurrentWeightKG, PalletStatus) values
(201, 450, 'Loaded'),
(202, 800, 'Loaded'),
(203, 50, 'Empty'),
(204, 600, 'InTransit'),
(205, 300, 'Loaded');

-- заполнение таблицы palletcontents
insert into PalletContents (PalletId, ItemId, Quantity) values
(201, 101, 400),
(202, 102, 750),
(204, 104, 550),
(205, 105, 250),
(201, 103, 50);

-- заполнение таблицы movements
insert into Movements (MovementId, PalletId, FromCellId, ToCellId, StartTime, EndTime, RobotId) values
(301, 201, 4, 5, '2026-06-23 08:00:00', '2026-06-23 08:05:00', 11),
(302, 202, 5, 6, '2026-06-23 09:15:00', '2026-06-23 09:22:00', 12),
(303, 204, 6, 7, '2026-06-23 10:30:00', null, 11),
(304, 205, 7, 8, '2026-06-23 11:00:00', '2026-06-23 11:10:00', 13),
(305, 203, 4, 8, '2026-06-23 13:00:00', '2026-06-23 13:15:00', 12);

-- заполнение таблицы telemetryaudit
insert into TelemetryAudit (CellId, OldTemp, NewTemp, ChangedBy, ChangedAt) values
(6, 5.0, 4.0, 'operator_1', '2026-06-23 07:30:00'),
(7, -15.5, -18.0, 'system_monitor', '2026-06-23 08:00:00'),
(6, 4.0, 4.2, 'sensor_node_3', '2026-06-23 12:00:00'),
(7, -18.0, -17.5, 'operator_2', '2026-06-23 14:15:00'),
(6, 4.2, 4.0, 'system_monitor', '2026-06-23 16:00:00');

-- заполнение таблицы celladjacency
insert into CellAdjacency (CellId, NeighborCellId, DistanceMeter) values
(4, 5, 1.20),
(5, 4, 1.20),
(5, 6, 2.50),
(6, 5, 2.50),
(7, 8, 1.05);

-- 3. Ячейки, через которые прошло более 10 различных паллет, и их суммарное время нахождения там > 100ч

-- собираем все паллеты и промежутки времени, когда они находились в ячейке
with pallet_stays as (
    select
        ToCellId as cellid,
        PalletId,
        EndTime as arrival_time,
        -- Находим время следующего перемещения этой же паллеты (время убытия)
        -- для этого ищем функцией lead следующую по времени строку в таблице с перемещением этой палеты
        lead(StartTime) over (partition by PalletId order by StartTime) as departure_time
    from Movements
    where EndTime is not null
)
select 
    cellid as 'Cell ID',
    count(distinct PalletId) as 'Total Pallets',
    sum(datediff(minute, arrival_time, departure_time)) / 60.0 as 'Total Hours'
from pallet_stays
where departure_time is not null -- отбрасываем активные перемещения
group by cellid
having count(distinct PalletId) > 10 -- 10 различных
   and sum(datediff(minute, arrival_time, departure_time)) / 60.0 > 100; -- суммарное время > 100ч

-- заполним данными для проверки

-- добавляем ячейки
insert into cells (cellid, cellcode, celltype, maxweightkg) values
(10, 'c010', 'standard', 2000),
(20, 'c020', 'standard', 2000),
(30, 'c030', 'standard', 2000),
(100, 'c100', 'standard', 5000);

-- добавляем паллеты (11 штук для тестов ячеек 10 и 20 + 2 штуки для ячейки 30)
insert into pallets (palletid, currentweightkg, palletstatus) values
(1001, 500, 'loaded'),
(1002, 500, 'loaded'),
(1003, 500, 'loaded'),
(1004, 500, 'loaded'),
(1005, 500, 'loaded'),
(1006, 500, 'loaded'),
(1007, 500, 'loaded'),
(1008, 500, 'loaded'),
(1009, 500, 'loaded'),
(1010, 500, 'loaded'),
(1011, 500, 'loaded'),
(2001, 600, 'loaded'),
(2002, 600, 'loaded');

-- добавляем историю перемещений (movements)
insert into movements (movementid, palletid, fromcellid, tocellid, starttime, endtime, robotid) values
-- ячейка 10: 11 паллет по 10 часов нахождения в ячейке
(5001, 1001, 100, 10, '2026-01-01 00:00:00', '2026-01-01 00:30:00', 1),
(5002, 1001, 10, 100, '2026-01-01 10:30:00', '2026-01-01 11:00:00', 1),
(5003, 1002, 100, 10, '2026-01-02 00:00:00', '2026-01-02 00:30:00', 1),
(5004, 1002, 10, 100, '2026-01-02 10:30:00', '2026-01-02 11:00:00', 1),
(5005, 1003, 100, 10, '2026-01-03 00:00:00', '2026-01-03 00:30:00', 1),
(5006, 1003, 10, 100, '2026-01-03 10:30:00', '2026-01-03 11:00:00', 1),
(5007, 1004, 100, 10, '2026-01-04 00:00:00', '2026-01-04 00:30:00', 1),
(5008, 1004, 10, 100, '2026-01-04 10:30:00', '2026-01-04 11:00:00', 1),
(5009, 1005, 100, 10, '2026-01-05 00:00:00', '2026-01-05 00:30:00', 1),
(5010, 1005, 10, 100, '2026-01-05 10:30:00', '2026-01-05 11:00:00', 1),
(5011, 1006, 100, 10, '2026-01-06 00:00:00', '2026-01-06 00:30:00', 1),
(5012, 1006, 10, 100, '2026-01-06 10:30:00', '2026-01-06 11:00:00', 1),
(5013, 1007, 100, 10, '2026-01-07 00:00:00', '2026-01-07 00:30:00', 1),
(5014, 1007, 10, 100, '2026-01-07 10:30:00', '2026-01-07 11:00:00', 1),
(5015, 1008, 100, 10, '2026-01-08 00:00:00', '2026-01-08 00:30:00', 1),
(5016, 1008, 10, 100, '2026-01-08 10:30:00', '2026-01-08 11:00:00', 1),
(5017, 1009, 100, 10, '2026-01-09 00:00:00', '2026-01-09 00:30:00', 1),
(5018, 1009, 10, 100, '2026-01-09 10:30:00', '2026-01-09 11:00:00', 1),
(5019, 1010, 100, 10, '2026-01-10 00:00:00', '2026-01-10 00:30:00', 1),
(5020, 1010, 10, 100, '2026-01-10 10:30:00', '2026-01-10 11:00:00', 1),
(5021, 1011, 100, 10, '2026-01-11 00:00:00', '2026-01-11 00:30:00', 1),
(5022, 1011, 10, 100, '2026-01-11 10:30:00', '2026-01-11 11:00:00', 1),

-- ячейка 20: те же 11 паллет, но стоят всего по 1 часу
(5023, 1001, 100, 20, '2026-02-01 00:00:00', '2026-02-01 00:30:00', 1),
(5024, 1001, 20, 100, '2026-02-01 01:30:00', '2026-02-01 02:00:00', 1),
(5025, 1002, 100, 20, '2026-02-02 00:00:00', '2026-02-02 00:30:00', 1),
(5026, 1002, 20, 100, '2026-02-02 01:30:00', '2026-02-02 02:00:00', 1),
(5027, 1003, 100, 20, '2026-02-03 00:00:00', '2026-02-03 00:30:00', 1),
(5028, 1003, 20, 100, '2026-02-03 01:30:00', '2026-02-03 02:00:00', 1),
(5029, 1004, 100, 20, '2026-02-04 00:00:00', '2026-02-04 00:30:00', 1),
(5030, 1004, 20, 100, '2026-02-04 01:30:00', '2026-02-04 02:00:00', 1),
(5031, 1005, 100, 20, '2026-02-05 00:00:00', '2026-02-05 00:30:00', 1),
(5032, 1005, 20, 100, '2026-02-05 01:30:00', '2026-02-05 02:00:00', 1),
(5033, 1006, 100, 20, '2026-02-06 00:00:00', '2026-02-06 00:30:00', 1),
(5034, 1006, 20, 100, '2026-02-06 01:30:00', '2026-02-06 02:00:00', 1),
(5035, 1007, 100, 20, '2026-02-07 00:00:00', '2026-02-07 00:30:00', 1),
(5036, 1007, 20, 100, '2026-02-07 01:30:00', '2026-02-07 02:00:00', 1),
(5037, 1008, 100, 20, '2026-02-08 00:00:00', '2026-02-08 00:30:00', 1),
(5038, 1008, 20, 100, '2026-02-08 01:30:00', '2026-02-08 02:00:00', 1),
(5039, 1009, 100, 20, '2026-02-09 00:00:00', '2026-02-09 00:30:00', 1),
(5040, 1009, 20, 100, '2026-02-09 01:30:00', '2026-02-09 02:00:00', 1),
(5041, 1010, 100, 20, '2026-02-10 00:00:00', '2026-02-10 00:30:00', 1),
(5042, 1010, 20, 100, '2026-02-10 01:30:00', '2026-02-10 02:00:00', 1),
(5043, 1011, 100, 20, '2026-02-11 00:00:00', '2026-02-11 00:30:00', 1),
(5044, 1011, 20, 100, '2026-02-11 01:30:00', '2026-02-11 02:00:00', 1),

-- ячейка 30: всего 2 паллеты, но стоят очень долго (по 48 часов каждая)
(5045, 2001, 100, 30, '2026-03-01 00:00:00', '2026-03-01 00:30:00', 1),
(5046, 2001, 30, 100, '2026-03-03 00:30:00', '2026-03-03 01:00:00', 1),
(5047, 2002, 100, 30, '2026-03-05 00:00:00', '2026-03-05 00:30:00', 1),
(5048, 2002, 30, 100, '2026-03-07 00:30:00', '2026-03-07 01:00:00', 1);

-- 4. Преобразование в графовую

-- вершины
create table CellNode (
    CellId INT PRIMARY KEY,
    CellCode NVARCHAR(20) NOT NULL UNIQUE,
    CellType NVARCHAR(30) NOT NULL CHECK (CellType IN ('Standard', 'Refrigerated')),
    MaxWeightKG INT NOT NULL CHECK (MaxWeightKG > 0)
) as node

create table ItemNode (
    ItemId INT PRIMARY KEY,
    ItemName NVARCHAR(100) NOT NULL,
    RequiredTempCelsius DECIMAL(4,1) NOT NULL
) as node

-- ребра
create table ConnectedTo as edge

create table [Contains] (Quantity INT NOT NULL) as edge

-- заполнение

insert into CellNode (CellId, CellCode, CellType, MaxWeightKG)
select CellId, CellCode, CellType, MaxWeightKG
from Cells

insert into ItemNode (ItemId, ItemName, RequiredTempCelsius)
select ItemId, ItemName, RequiredTempCelsius
from Items

insert into ConnectedTo ($from_id, $to_id)
select cn1.$node_id, cn2.$node_id
from CellAdjacency ca, CellNode cn1, CellNode cn2
where ca.CellId = cn1.CellId
and ca.NeighborCellId = cn2.CellId

-- находим последнее положение каждой паллеты
with latest_pallet_location as (
    select 
        PalletId, 
        ToCellId,
        row_number() over (partition by PalletId order by EndTime desc, StartTime desc) as rn
    from Movements
    where EndTime is not null
),
-- Группируем предметы со всей паллеты в ячейке
current_cell_items as (
    select 
        lpl.ToCellId as cellid,
        pc.ItemId,
        sum(pc.Quantity) as total_quantity
    from latest_pallet_location lpl
    join PalletContents pc on lpl.palletid = pc.palletid
    where lpl.rn = 1 -- учитываем только последнюю положенную в ячейку паллету
    group by lpl.ToCellId, pc.ItemId
)
insert into [Contains] ($from_id, $to_id, Quantity)
select c.$node_id, i.$node_id, cci.total_quantity
from current_cell_items cci
join CellNode c on cci.cellid = c.CellId
join ItemNode i on cci.itemid = i.ItemId;

-- 5. Найти товары в ячейках, связанных с ячейкой 'A-01' (соседи первого порядка?)

select ind.*
from CellNode cn1, ConnectedTo ct, CellNode cn2, ItemNode ind, [Contains] cont
where match (ind<-(cont)-cn1-(ct)->cn2)
and cn2.CellCode = 'A-01'

-- 6. Триггер в реляционной модели: Запрет на начало перемещения палеты, если она уже перемещается

create or alter trigger Movements_RestrictOnMovingIfAlreadyMoving
on Movements instead of insert
as
Begin
    declare @MovementId int
    declare @PalletId int
    declare @FromCellId int
    declare @ToCellId int
    declare @StartTime DATETIME2
    declare @EndTime DATETIME2
    declare @RobotId int

    declare cur cursor for
    select MovementId, PalletId, FromCellId, ToCellId, StartTime, EndTime, RobotId
    from inserted

    open cur

    fetch next from cur
    into @MovementId, @PalletId, @FromCellId, @ToCellId, @StartTime, @EndTime, @RobotId

    while @@FETCH_STATUS = 0
    begin
        if exists (
            select 1
            from Pallets
            where PalletId = @PalletId and PalletStatus = 'InTransit'
        )
        begin
            insert into Movements (MovementId, PalletId, FromCellId, ToCellId, StartTime, EndTime, RobotId)
            values (@MovementId, @PalletId, @FromCellId, @ToCellId, @StartTime, @EndTime, @RobotId)
        end
        else
        begin
            print 'Movement ' + cast(@MovementId as varchar(max)) + ' is not inserted'
        end

        fetch next from cur
    into @MovementId, @PalletId, @FromCellId, @ToCellId, @StartTime, @EndTime, @RobotId
    end

    close cur
    deallocate cur
End

-- проверка
begin tran
insert into Movements (MovementId, PalletId, FromCellId, ToCellId, StartTime, EndTime, RobotId) values
(600, 201, 4, 5, '2026-06-23 08:00:00', '2026-06-23 08:05:00', 11)
rollback

-- 7. Процедура: Назначение роботу перемещения палеты

create or alter procedure ScheduleMovementOnRobot
    @RobotId int,
    @PalletId int
as
Begin
    set nocount on

    declare @FromCellId int
    declare @ToCellId int
    declare @Weight int
    declare @RequiredType nvarchar(30) = 'Standard'
    declare @NewMovementId int

    -- подбираем ячейку: должна быть свободна и подходить по типу/весу
    -- свободна: в ней нет паллеты (либо вообще не загружали, либо крайнее действие - выгружали)
    -- по типу: если необходимая температура < 10 градусов, значит нужна холодильная ячейка, иначе обычная
    -- по весу: смотрим вес паллеты и максимально допустимый вес ячейки
    if exists (select 1 from Movements where palletid = @palletid and endtime is null)
    begin
        print 'Паллета ' + cast(@PalletId as varchar(max)) + ' уже находится в процессе перемещения'
        return
    end

    -- определение текущего местоположения паллеты (последняя точка прибытия)
    select top 1 @FromCellId = ToCellId
    from Movements
    where PalletId = @PalletId and EndTime is not null
    order by StartTime desc

    if @FromCellId is null
    begin
        print 'Не удалось определить исходную ячейку паллеты ' + cast(@PalletId as varchar(max))
        return
    end

    -- определение параметров груза (вес и температурные требования)
    select @Weight = CurrentWeightKG from Pallets where PalletId = @PalletId

    if exists (
        select 1 
        from PalletContents pc 
        join Items i on pc.ItemId = i.ItemId 
        where pc.Palletid = @PalletId and i.RequiredTempCelsius < 10.0
    )
    begin
        set @RequiredType = 'refrigerated' 
    end

    -- подбор подходящей свободной ячейки
    select top 1 @ToCellId = c.cellid
        from Cells c
        where c.CellId <> @FromCellId -- нельзя перемещать в ту же самую ячейку
          and c.MaxWeightKG >= @Weight -- подходит по весу
          and c.CellType = @RequiredType -- подходит по типу
          and c.CellId not in (
              -- проверка на занятость ячейки:
              -- 1. прямо сейчас к ней направляется какая-то паллета
              select ToCellId from Movements where EndTime is null
              union
              -- 2. в ней прямо сейчас  находится паллета
              select m.ToCellId
              from Movements m
              where m.EndTime is not null
                and not exists (
                    select 1 from movements m2
                    where m2.PalletId = m.PalletId
                      and m2.StartTime > m.StartTime
                )
          )
        order by c.CellId -- возьмём первую ячейку
        
        -- если подходящая ячейка не найдена, выводим сообщение
        if @ToCellId is null
        begin
            print 'нет подходящих свободных ячеек для паллеты ' + cast(@PalletId as varchar(max))
            return
        end

        -- генерация нового id перемещения
        select @NewMovementId = isnull(max(MovementId), 0) + 1 from Movements;
        
        -- создание записи о начале перемещения
        insert into Movements (MovementId, PalletId, FromCellId, ToCellId, StartTime, EndTime, RobotId)
        values (@NewMovementId, @Palletid, @FromCellId, @ToCellId, sysutcdatetime(), null, @RobotId);
        
        -- изменение статуса самой паллеты на "в транзите"
        update Pallets
        set PalletStatus = 'InTransit'
        where PalletId = @PalletId;

        -- вывод информации о назначенном задании для робота
        select 
            @NewMovementId as MovementId,
            @PalletId as Pallet,
            @FromCellId as FromCell,
            @ToCellId as ToCell,
            @RequiredType as Type
End

-- проверка
begin tran
exec ScheduleMovementOnRobot @RobotId = 10, @PalletId = 204 -- в процессе перемещения
rollback

begin tran
exec ScheduleMovementOnRobot @RobotId = 10, @PalletId = 205 -- успешное назначение
rollback

-- 8. JSON-скрипт
-- ИЗМЕНЁН, тк в задании 9 необходимо считать суммарный вес груза, а данная структура документа его не сохраняет

select (
    select 
        c.CellCode as [CellCode],
        c.CellType as [Specs.Туре],
        c.MaxWeightKG as [Specs.MaxWeight],
        -- текущая паллета в ячейке (последнее завершенное перемещение)
        json_query(isnull((
            select 
                p.PalletId as [PalletId], 
                p.CurrentWeightKG as [CurrentWeight]
            from Movements m
            join Pallets p on m.PalletId = p.PalletId
            where m.ToCellId = c.CellId 
                and m.EndTime is not null
                and not exists (
                    select 1 
                    from Movements m2 
                    where m2.PalletId = m.PalletId 
                    and m2.StartTime > m.StartTime
                )
            for json path
        ), '[]')) as [CurrentPallet],
        -- история всех роботов, привозивших груз в эту ячейку
        json_query(isnull((
            select 
                m.RobotId as [RobotId], 
                datediff(minute, m.StartTime, m.EndTime) as [DurationMinutes],
                p.CurrentWeightKG as [Weight] -- дополнительно записываем в историю вес (не дано в задании)
            from Movements m
            join Pallets p on m.PalletId = p.PalletId -- присоединяем таблицу паллет для записи веса
            where m.TocellId = c.CellId 
                and m.EndTime is not null
            for json path
        ), '[]')) as [History]
    for json path, without_array_wrapper -- получим по одному json на каждую ячейку
) as cell_json_document
from Cells c