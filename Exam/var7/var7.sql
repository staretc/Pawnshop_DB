-- Узел Подстанций
CREATE TABLE SubstationNode (
    SubstationId INT IDENTITY(1,1) PRIMARY KEY,
    SubstationName NVARCHAR(100) NOT NULL,
    MaxCapacityKW DECIMAL(10,2) NOT NULL CHECK (MaxCapacityKW > 0),
    IsActive BIT NOT NULL DEFAULT 1
) AS NODE;

-- Узел Умных домов
CREATE TABLE HouseNode (
    HouseId INT IDENTITY(1,1) PRIMARY KEY,
    AddressName NVARCHAR(100) NOT NULL,
    MaxAllowedLoadKW DECIMAL(10,2) NOT NULL CHECK (MaxAllowedLoadKW > 0)
) AS NODE;
GO


-- ============================================================================
-- 2. СОЗДАНИЕ ТАБЛИЦ-СВЯЗЕЙ (EDGE TABLES)
-- ============================================================================

-- Ребро: Линия передач от подстанции к дому (направленная связь)
CREATE TABLE PowerLine (
    LineId INT IDENTITY(1,1) PRIMARY KEY,
    MaxLoadKW DECIMAL(10,2) NOT NULL CHECK (MaxLoadKW > 0)
) AS EDGE;

-- Ребро: Линия связи между соседними домами для шеринга энергии (симметричная связь)
CREATE TABLE ConnectedHouses (
    TransferCapacityKW DECIMAL(10,2) NOT NULL CHECK (TransferCapacityKW > 0)
) AS EDGE;
GO


-- ============================================================================
-- 3. НАПОЛНЕНИЕ ГРАФА ДЕМО-ДАННЫМИ (DML)
-- ============================================================================

-- Шаг A: Заполняем узлы подстанций
INSERT INTO SubstationNode (SubstationName, MaxCapacityKW, IsActive) VALUES 
('Main Substation Alpha', 5000.00, 1),
('Backup Substation Beta', 2500.00, 0);

-- Шаг B: Заполняем узлы умных домов
INSERT INTO HouseNode (AddressName, MaxAllowedLoadKW) VALUES 
('Smart House 101', 50.00),
('Smart House 102', 60.00),
('Smart House 103', 45.00);
GO

-- Шаг C: Создаем ребра PowerLine (Подстанция Alpha -> Дома)
INSERT INTO PowerLine ($from_id, $to_id, MaxLoadKW) VALUES 
(
    (SELECT $node_id FROM SubstationNode WHERE SubstationName = 'Main Substation Alpha'),
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 101'),
    100.00
),
(
    (SELECT $node_id FROM SubstationNode WHERE SubstationName = 'Main Substation Alpha'),
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 102'),
    100.00
),
(
    (SELECT $node_id FROM SubstationNode WHERE SubstationName = 'Main Substation Alpha'),
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 103'),
    80.00
);

-- Шаг D: Создаем ребра ConnectedHouses (Шеринг между домами 101 и 102)
-- В MSSQL Graph связи направленные, поэтому для ненаправленного соседства делаем 2 записи
INSERT INTO ConnectedHouses ($from_id, $to_id, TransferCapacityKW) VALUES 
(
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 101'),
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 102'),
    20.00
),
(
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 102'),
    (SELECT $node_id FROM HouseNode WHERE AddressName = 'Smart House 101'),
    20.00
);
GO

-- РЕЛЯЦИОННАЯ БД

create table Substations (
    SubstationId int identity(1,1) primary key,
    SubstationName nvarchar(100) not null,
    MaxCapacityKW decimal(10,2) not null check (maxcapacitykw > 0),
    IsActive bit not null default 1
)

create table Houses (
    HouseId int identity(1,1) primary key,
    AddressName nvarchar(100) not null,
    MaxAllowedLoadKW decimal(10,2) not null check (maxallowedloadkw > 0)
)

create table PowerLines (
    LineId int identity(1,1) primary key,
    SubstationId int not null foreign key references Substations(SubstationId),
    HouseId int not null foreign key references Houses(HouseId),
    MaxLoadKW decimal(10,2) not null check (maxloadkw > 0),
    
)

create table HouseConnections (
    HouseId1 int not null foreign key references Houses(HouseId),
    HouseId2 int not null foreign key references Houses(HouseId),
    TransferCapacityKW decimal(10,2) not null check (TransferCapacityKW > 0),
    primary key (houseid1, houseid2),
    check (houseid1 <> houseid2)
)

-- ПЕРЕНОС ДАННЫХ

set identity_insert Substations on

insert into Substations (substationid, substationname, maxcapacitykw, isactive)
select substationid, substationname, maxcapacitykw, isactive
from substationnode

set identity_insert Substations off

set identity_insert Houses on

insert into Houses (HouseId, AddressName, MaxAllowedLoadKW)
select HouseId, AddressName, MaxAllowedLoadKW
from HouseNode

set identity_insert Houses off

set identity_insert PowerLines on

insert into PowerLines (LineId, SubstationId, HouseId, MaxLoadKW)
select 
    pl.LineId,
    sn.SubstationId,
    hn.HouseId,
    pl.MaxLoadKW
from PowerLine pl
join SubstationNode sn on pl.$from_id = sn.$node_id
join HouseNode hn on pl.$to_id = hn.$node_id

set identity_insert PowerLines off

insert into HouseConnections (HouseId1, HouseId2, TransferCapacityKW)
select 
    hn1.HouseId,
    hn2.HouseId,
    ch.TransferCapacityKW
from ConnectedHouses ch
join HouseNode hn1 on ch.$from_id = hn1.$node_id
join HouseNode hn2 on ch.$to_id = hn2.$node_id