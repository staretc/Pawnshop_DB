create database Employees

create TABLE Employee(
	ID Int Identity(1,1),
	EMPNO NUMERIC(4) NOT NULL,
	ENAME VARCHAR(10),
	DATEOFBIRTH  DATE
	
) AS NODE;

CREATE TABLE empReportsTo AS EDGE

INSERT INTO Employee VALUES
(7369, 'SMITH',  '02-03-1970'),
(7499, 'ALLEN',  '20-03-1971'),
(7521, 'WARD',  '07-02-1983'),
(7566, 'JONES',  '02-06-1961'),
(7654, 'MARTIN',  '28-02-1971'),
(7698, 'BLAKE', '01-01-1988'),
(7782, 'CLARK',  '09-04-1971'),
(7788, 'SCOTT',  '09-12-1982'),
(7839, 'KING',  '17-07-1971'),
(7844, 'TURNER',  '08-09-1971'),
(7876, 'ADAMS',  '12-03-1973'),
(7900, 'JAMES',  '03-11-1971'),
(7902, 'FORD',  '04-03-1961'),
(7934, 'MILLER',  '21-01-1972')

select *  from Employee


INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 1),
   	(SELECT $node_id FROM Employee WHERE id = 13));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 2),
   	(SELECT $node_id FROM Employee WHERE id = 6));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 3),
   	(SELECT $node_id FROM Employee WHERE id = 6))
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 4),
   	(SELECT $node_id FROM Employee WHERE id = 9));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 5),
   	(SELECT $node_id FROM Employee WHERE id = 6));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 6),
   	(SELECT $node_id FROM Employee WHERE id = 9));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 7),
   	(SELECT $node_id FROM Employee WHERE id = 9));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 8),
   	(SELECT $node_id FROM Employee WHERE id = 4));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 9),
   	(SELECT $node_id FROM Employee WHERE id = 9));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 10),
   	(SELECT $node_id FROM Employee WHERE id = 6));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 11),
   	(SELECT $node_id FROM Employee WHERE id = 8));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 12),
   	(SELECT $node_id FROM Employee WHERE id = 6));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 13),
   	(SELECT $node_id FROM Employee WHERE id = 4));
INSERT INTO empReportsTo  VALUES ((SELECT $node_id FROM Employee WHERE ID = 14),
   	(SELECT $node_id FROM Employee WHERE id = 7));



    -- Все связи с именами сотрудников
SELECT 
    e1.ENAME AS Employee,
    e2.ENAME AS Manager,
    e1.ID AS EmployeeID,
    e2.ID AS ManagerID
FROM 
    Employee e1,
    empReportsTo r,
    Employee e2
WHERE 
    MATCH(e1-(r)->e2)
ORDER BY 
    e2.ENAME, e1.ENAME;


  -- пример запроса с shortes_path
  -- Поиск кратчайшего пути между SMITH и KING
SELECT PersonName, Friends
FROM (
    SELECT
        e1.ENAME AS PersonName,
        STRING_AGG(e2.ENAME, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
        LAST_VALUE(e2.ENAME) WITHIN GROUP (GRAPH PATH) AS LastNode
    FROM
        Employee AS e1,
        empReportsTo FOR PATH AS r,
        Employee FOR PATH AS e2
    WHERE MATCH(SHORTEST_PATH(e1(-(r)->e2)+))
    AND e1.ENAME = 'SMITH'
) AS Q
WHERE Q.LastNode = 'KING';



-- Подсчет уровней от SMITH до KING
SELECT PersonName, Friends, levels
FROM (
    SELECT
        e1.ENAME AS PersonName,
        STRING_AGG(e2.ENAME, '->') WITHIN GROUP (GRAPH PATH) AS Friends,
        LAST_VALUE(e2.ENAME) WITHIN GROUP (GRAPH PATH) AS LastNode,
        COUNT(e2.ENAME) WITHIN GROUP (GRAPH PATH) AS levels
    FROM
        Employee AS e1,
        empReportsTo FOR PATH AS r,
        Employee FOR PATH AS e2
    WHERE MATCH(SHORTEST_PATH(e1(-(r)->e2)+))
    AND e1.ENAME = 'SMITH'
) AS Q
WHERE Q.LastNode = 'KING';


-- ==========================================
-- в реляционную
-- ==========================================
CREATE TABLE Employee1 (
    ID INT IDENTITY(1,1) PRIMARY KEY,
    EMPNO NUMERIC(4) NOT NULL UNIQUE,
    ENAME VARCHAR(10) NOT NULL,
    DATEOFBIRTH DATE NOT NULL
);

CREATE TABLE ReportsTo (
    IDEmp1 int foreign key references Employee1(ID),
    IDEmp2 int foreign key references Employee1(ID),
    primary key (IDEmp1, IDEmp2)
);

set IDENTITY_INSERT Employee1 on

insert into Employee1(ID, EMPNO, ENAME, DATEOFBIRTH)
select ID, EMPNO, ENAME, DATEOFBIRTH
from Employee

insert into ReportsTo(IDEmp1, IDEmp2)
select e1.ID, e2.ID
from empReportsTo r, Employee e1, Employee e2
where match(e1-(r)->e2)


-- ==========================================
-- ПРЕОБРАЗОВАНИЕ РЕЛЯЦИОННОЙ МОДЕЛИ В JSON ДЛЯ MONGODB
-- ==========================================

SELECT 
    e.ID AS EmployeeId,
    e.ENAME AS Name,
    e.EMPNO AS EmpNumber,
    e.DATEOFBIRTH AS BirthDate,
    
    -- Информация о начальнике
    JSON_QUERY((
        SELECT 
            m.ID AS ManagerId,
            m.ENAME AS ManagerName,
            m.EMPNO AS ManagerEmpNumber
        FROM Employee1 m
        WHERE m.ID = r.IDEmp2
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )) AS Manager,
    
    -- Список подчиненных
    JSON_QUERY((
        SELECT 
            sub.ID AS SubordinateId,
            sub.ENAME AS SubordinateName,
            sub.EMPNO AS SubordinateEmpNumber
        FROM Employee1 sub
        JOIN ReportsTo rt ON sub.ID = rt.IDEmp1
        WHERE rt.IDEmp2 = e.ID
        FOR JSON PATH
    )) AS Subordinates,
    
    -- Количество подчиненных
    (SELECT COUNT(*) FROM ReportsTo rt WHERE rt.IDEmp2 = e.ID) AS SubordinatesCount

FROM Employee1 e
LEFT JOIN ReportsTo r ON e.ID = r.IDEmp1
WHERE e.ID IS NOT NULL
GROUP BY e.ID, e.ENAME, e.EMPNO, e.DATEOFBIRTH, r.IDEmp2
FOR JSON PATH;


-- еще пример
-- ==========================================
-- ПРЕОБРАЗОВАНИЕ РЕЛЯЦИОННОЙ МОДЕЛИ В JSON ДЛЯ MONGODB
-- ==========================================

SELECT 
    e.ID AS EmployeeId,
    e.ENAME AS Name,
    e.EMPNO AS EmpNumber,
    e.DATEOFBIRTH AS BirthDate,
    
    -- Список подчиненных
    JSON_QUERY((
        SELECT 
            sub.ID AS SubordinateId,
            sub.ENAME AS SubordinateName,
            sub.EMPNO AS SubordinateEmpNumber
        FROM Employee1 sub
        JOIN ReportsTo rt ON sub.ID = rt.IDEmp1
        WHERE rt.IDEmp2 = e.ID
        FOR JSON PATH
    )) AS Subordinates,
    
    -- Количество подчиненных
    (SELECT COUNT(*) FROM ReportsTo rt WHERE rt.IDEmp2 = e.ID) AS SubordinatesCount

FROM Employee1 e
WHERE e.ID IS NOT NULL
FOR JSON PATH;
