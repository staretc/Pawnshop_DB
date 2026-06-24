-- 1. Таблица Жанров
CREATE TABLE Genres (
    GenreId INT ,
    GenreName NVARCHAR(50) NOT NULL UNIQUE
);

-- 2. Таблица Фильмов
CREATE TABLE Movies (
    MovieId INT ,
    Title NVARCHAR(255) NOT NULL,
    Duration INT NOT NULL CHECK (Duration > 0),
    ReleaseYear INT NOT NULL CHECK (ReleaseYear >= 1888)
);

-- 3. Связующая таблица Фильмы-Жанры 
CREATE TABLE MovieGenres (
    MovieId INT,
    GenreId INT 
   
);

-- 4. Таблица Актеров
CREATE TABLE Actors (
    ActorId INT ,
    ActorName NVARCHAR(100) NOT NULL
);

CREATE TABLE MovieCast (
    MovieId INT ,
    ActorId INT 
);

-- 5. Таблица Пользователей с ROWVERSION 
CREATE TABLE Users (
    UserId INT,
    Email NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,
    SubscriptionStatus NVARCHAR(20) NOT NULL DEFAULT 'Inactive' CHECK (SubscriptionStatus IN ('Active', 'Inactive')),
    SubscriptionEndDate DATETIME2 NULL,
    RowVer ROWVERSION NOT NULL 
);

-- 6. Таблица Истории просмотров и отзывов
CREATE TABLE WatchHistory (
    WatchId INT,
    UserId INT NOT NULL,
    MovieId INT NOT NULL,
    WatchStart DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    MinutesWatched INT NOT NULL DEFAULT 0,
    Score INT NULL,
    ReviewComment NVARCHAR(MAX) NULL
);

-- 7. Таблица Аудита Безопасности
CREATE TABLE UserSecurityAudit (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    FieldName NVARCHAR(50) NOT NULL,
    OldValue NVARCHAR(MAX) NULL,
    NewValue NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ЗАПОЛНЕНИЕ ДЕМО-ДАННЫМИ
INSERT INTO Genres (GenreName) VALUES ('Sci-Fi'), ('Action'), ('Drama');
INSERT INTO Actors (ActorName) VALUES ('Leonardo DiCaprio'), ('Elliot Page'), ('Tom Hardy');

INSERT INTO Movies (Title, Duration, ReleaseYear) VALUES ('Inception', 148, 2010), ('Interstellar', 169, 2014);
INSERT INTO MovieGenres (MovieId, GenreId) VALUES (1, 1), (1, 2), (2, 1);
INSERT INTO MovieCast (MovieId, ActorId) VALUES (1, 1), (1, 2), (1, 3);

INSERT INTO Users (Email, PasswordHash, SubscriptionStatus, SubscriptionEndDate) 
VALUES ('john.doe@example.com', 0x123456, 'Active', DATEADD(day, 30, SYSUTCDATETIME())),
       ('jane.smith@example.com', 0x789012, 'Inactive', NULL);

INSERT INTO WatchHistory (UserId, MovieId, WatchStart, MinutesWatched, Score, ReviewComment)
VALUES (1, 1, SYSUTCDATETIME(), 148, 10, 'Amazing!');


--============ пример исправленной бд ========
-- Создание базы данных
CREATE DATABASE Movies;
GO

USE Movies;
GO

-- 1. Таблица Жанров
CREATE TABLE Genres (
    GenreId INT IDENTITY(1,1) PRIMARY KEY,
    GenreName NVARCHAR(50) NOT NULL UNIQUE
);

-- 2. Таблица Фильмов
CREATE TABLE Movies (
    MovieId INT IDENTITY(1,1) PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    Duration INT NOT NULL CHECK (Duration > 0 AND Duration < 600),
    ReleaseYear INT NOT NULL CHECK (ReleaseYear >= 1888 AND ReleaseYear <= YEAR(GETDATE()) + 5)
);

-- 3. Связующая таблица Фильмы-Жанры (с внешними ключами и CASCADE)
CREATE TABLE MovieGenres (
    MovieId INT NOT NULL,
    GenreId INT NOT NULL,
    PRIMARY KEY (MovieId, GenreId),
    FOREIGN KEY (MovieId) REFERENCES Movies(MovieId) ON DELETE CASCADE,
    FOREIGN KEY (GenreId) REFERENCES Genres(GenreId) ON DELETE CASCADE
);

-- 4. Таблица Актеров
CREATE TABLE Actors (
    ActorId INT IDENTITY(1,1) PRIMARY KEY,
    ActorName NVARCHAR(100) NOT NULL
);

-- Связующая таблица Фильмы-Актеры (с внешними ключами и CASCADE)
CREATE TABLE MovieCast (
    MovieId INT NOT NULL,
    ActorId INT NOT NULL,
    PRIMARY KEY (MovieId, ActorId),
    FOREIGN KEY (MovieId) REFERENCES Movies(MovieId) ON DELETE CASCADE,
    FOREIGN KEY (ActorId) REFERENCES Actors(ActorId) ON DELETE CASCADE
);

-- 5. Таблица Пользователей с ROWVERSION
CREATE TABLE Users (
    UserId INT IDENTITY(1,1) PRIMARY KEY,
    Email NVARCHAR(256) NOT NULL UNIQUE,
    PasswordHash VARBINARY(64) NOT NULL,
    SubscriptionStatus NVARCHAR(20) NOT NULL DEFAULT 'Inactive' 
        CHECK (SubscriptionStatus IN ('Active', 'Inactive', 'Trial')),
    SubscriptionEndDate DATETIME2 NULL,
    RowVer ROWVERSION NOT NULL
);

-- 6. Таблица Истории просмотров и отзывов (с внешними ключами и CASCADE)
CREATE TABLE WatchHistory (
    WatchId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    MovieId INT NOT NULL,
    WatchStart DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    MinutesWatched INT NOT NULL DEFAULT 0,
    Score INT NULL CHECK (Score >= 1 AND Score <= 10),
    ReviewComment NVARCHAR(MAX) NULL,
    FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE CASCADE,
    FOREIGN KEY (MovieId) REFERENCES Movies(MovieId) ON DELETE CASCADE
);

-- 7. Таблица Аудита Безопасности
CREATE TABLE UserSecurityAudit (
    AuditId INT IDENTITY(1,1) PRIMARY KEY,
    UserId INT NOT NULL,
    FieldName NVARCHAR(50) NOT NULL,
    OldValue NVARCHAR(MAX) NULL,
    NewValue NVARCHAR(MAX) NULL,
    ChangedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ChangedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
);
GO

-- ЗАПОЛНЕНИЕ ДЕМО-ДАННЫМИ
-- Используем IDENTITY_INSERT для вставки конкретных ID

SET IDENTITY_INSERT Genres ON;
INSERT INTO Genres (GenreId, GenreName) VALUES 
    (1, 'Sci-Fi'), 
    (2, 'Action'), 
    (3, 'Drama');
SET IDENTITY_INSERT Genres OFF;

SET IDENTITY_INSERT Actors ON;
INSERT INTO Actors (ActorId, ActorName) VALUES 
    (1, 'Leonardo DiCaprio'), 
    (2, 'Elliot Page'), 
    (3, 'Tom Hardy');
SET IDENTITY_INSERT Actors OFF;

SET IDENTITY_INSERT Movies ON;
INSERT INTO Movies (MovieId, Title, Duration, ReleaseYear) VALUES 
    (1, 'Inception', 148, 2010), 
    (2, 'Interstellar', 169, 2014);
SET IDENTITY_INSERT Movies OFF;

-- Связи (внешние ключи)
INSERT INTO MovieGenres (MovieId, GenreId) VALUES 
    (1, 1), (1, 2), (2, 1);

INSERT INTO MovieCast (MovieId, ActorId) VALUES 
    (1, 1), (1, 2), (1, 3);

SET IDENTITY_INSERT Users ON;
INSERT INTO Users (UserId, Email, PasswordHash, SubscriptionStatus, SubscriptionEndDate) 
VALUES 
    (1, 'john.doe@example.com', 0x123456, 'Active', DATEADD(day, 30, SYSUTCDATETIME())),
    (2, 'jane.smith@example.com', 0x789012, 'Inactive', NULL);
SET IDENTITY_INSERT Users OFF;

SET IDENTITY_INSERT WatchHistory ON;
INSERT INTO WatchHistory (WatchId, UserId, MovieId, WatchStart, MinutesWatched, Score, ReviewComment)
VALUES 
    (1, 1, 1, SYSUTCDATETIME(), 148, 10, 'Amazing!');
SET IDENTITY_INSERT WatchHistory OFF;
GO

--============= Примеры запросов ==========


-- Актеры, которые снялись более чем в 3 фильмах
SELECT 
    a.ActorName,
    COUNT(mc.MovieId) AS MovieCount
FROM Actors a
JOIN MovieCast mc ON a.ActorId = mc.ActorId
GROUP BY a.ActorId, a.ActorName
HAVING COUNT(mc.MovieId) > 3;

-- Жанры, суммарная продолжительность фильмов в которых превысила 500 минут
SELECT 
    g.GenreName,
    SUM(m.Duration) AS TotalDuration
FROM Genres g
JOIN MovieGenres mg ON g.GenreId = mg.GenreId
JOIN Movies m ON mg.MovieId = m.MovieId
GROUP BY g.GenreId, g.GenreName
HAVING SUM(m.Duration) > 500;

-- Пользователи, которые посмотрели более 5 фильмов со средней оценкой выше 7
SELECT 
    u.Email,
    COUNT(wh.MovieId) AS MoviesWatched,
    AVG(CAST(wh.Score AS DECIMAL(3,1))) AS AvgScore
FROM Users u
JOIN WatchHistory wh ON u.UserId = wh.UserId
WHERE wh.Score IS NOT NULL
GROUP BY u.UserId, u.Email
HAVING COUNT(wh.MovieId) > 5 AND AVG(CAST(wh.Score AS DECIMAL(3,1))) > 7;


--====Пример перехода из реляционной в графовую ===========

-- 1) Создаём графовые узлы (NODE)
-- Узел: Актёры
CREATE TABLE ActorNode (
    ActorId INT PRIMARY KEY,
    ActorName NVARCHAR(100) NOT NULL
) AS NODE;

-- Узел: Фильмы
CREATE TABLE MovieNode (
    MovieId INT PRIMARY KEY,
    Title NVARCHAR(255) NOT NULL,
    Duration INT NOT NULL,
    ReleaseYear INT NOT NULL
) AS NODE;

-- Узел: Жанры
CREATE TABLE GenreNode (
    GenreId INT PRIMARY KEY,
    GenreName NVARCHAR(50) NOT NULL
) AS NODE;

-- Узел: Пользователи
CREATE TABLE UserNode (
    UserId INT PRIMARY KEY,
    Email NVARCHAR(256) NOT NULL,
    SubscriptionStatus NVARCHAR(20) NOT NULL
) AS NODE;

-- 2) Создаём графовые связи (EDGE)

-- Связь: Актёр снялся в фильме
CREATE TABLE ActedIn AS EDGE;

-- Связь: Фильм относится к жанру
CREATE TABLE BelongsTo AS EDGE;

-- Связь: Пользователь посмотрел фильм
CREATE TABLE Watched AS EDGE;

-- Связь: Фильмы похожи (по общим жанрам)
CREATE TABLE SimilarTo AS EDGE;

-- 3): Переносим данные из реляционных таблиц

-- Заполняем узлы
INSERT INTO ActorNode (ActorId, ActorName)
SELECT ActorId, ActorName FROM Actors;

INSERT INTO MovieNode (MovieId, Title, Duration, ReleaseYear)
SELECT MovieId, Title, Duration, ReleaseYear FROM Movies;

INSERT INTO GenreNode (GenreId, GenreName)
SELECT GenreId, GenreName FROM Genres;

INSERT INTO UserNode (UserId, Email, SubscriptionStatus)
SELECT UserId, Email, SubscriptionStatus FROM Users;


-- Заполняем связи
-- Актёр снялся в фильме
INSERT INTO ActedIn ($from_id, $to_id)
SELECT 
    (SELECT $node_id FROM ActorNode WHERE ActorId = mc.ActorId),
    (SELECT $node_id FROM MovieNode WHERE MovieId = mc.MovieId)
FROM MovieCast mc;

-- Фильм относится к жанру
INSERT INTO BelongsTo ($from_id, $to_id)
SELECT 
    (SELECT $node_id FROM MovieNode WHERE MovieId = mg.MovieId),
    (SELECT $node_id FROM GenreNode WHERE GenreId = mg.GenreId)
FROM MovieGenres mg;

-- Пользователь посмотрел фильм
INSERT INTO Watched ($from_id, $to_id)
SELECT 
    (SELECT $node_id FROM UserNode WHERE UserId = wh.UserId),
    (SELECT $node_id FROM MovieNode WHERE MovieId = wh.MovieId)
FROM WatchHistory wh;

-- Фильмы похожи (если у них есть общие жанры)
INSERT INTO SimilarTo ($from_id, $to_id)
SELECT DISTINCT
    m1.$node_id,
    m2.$node_id
FROM MovieNode m1
CROSS JOIN MovieNode m2
WHERE m1.MovieId <> m2.MovieId
AND EXISTS (
    SELECT 1 
    FROM MovieGenres mg1
    JOIN MovieGenres mg2 ON mg1.GenreId = mg2.GenreId
    WHERE mg1.MovieId = m1.MovieId 
    AND mg2.MovieId = m2.MovieId
);

-- пример графового запроса --
SELECT m.Title
FROM ActorNode a, ActedIn ai, MovieNode m
WHERE MATCH(a-(ai)->m)
AND a.ActorName = 'Leonardo DiCaprio';

--===========Пример из реляционной в json ===========
SELECT 
    m.MovieId,
    m.Title,
    m.Duration,
    m.ReleaseYear,
    
    -- Жанры фильма (массив)
    JSON_QUERY((
        SELECT 
            g.GenreId,
            g.GenreName
        FROM MovieGenres mg
        JOIN Genres g ON mg.GenreId = g.GenreId
        WHERE mg.MovieId = m.MovieId
        FOR JSON PATH
    )) AS Genres,
    
    -- Актёры фильма (массив)
    JSON_QUERY((
        SELECT 
            a.ActorId,
            a.ActorName
        FROM MovieCast mc
        JOIN Actors a ON mc.ActorId = a.ActorId
        WHERE mc.MovieId = m.MovieId
        FOR JSON PATH
    )) AS Cast,
    
    -- Пользователи, которые смотрели этот фильм (массив с их данными)
    JSON_QUERY((
        SELECT 
            u.UserId,
            u.Email,
            u.SubscriptionStatus,
            wh.WatchStart,
            wh.MinutesWatched,
            wh.Score,
            wh.ReviewComment
        FROM WatchHistory wh
        JOIN Users u ON wh.UserId = u.UserId
        WHERE wh.MovieId = m.MovieId
        FOR JSON PATH
    )) AS Viewers,
    
    -- Статистика фильма (агрегированные данные)
    JSON_QUERY((
        SELECT 
            COUNT(wh.WatchId) AS TotalViews,
            ISNULL(AVG(CAST(wh.Score AS DECIMAL(3,1))), 0) AS AverageRating,
            ISNULL(SUM(wh.MinutesWatched), 0) AS TotalMinutesWatched,
            COUNT(DISTINCT wh.UserId) AS UniqueViewers
        FROM WatchHistory wh
        WHERE wh.MovieId = m.MovieId
        FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
    )) AS Stats

FROM Movies m
WHERE m.MovieId IS NOT NULL
FOR JSON PATH;