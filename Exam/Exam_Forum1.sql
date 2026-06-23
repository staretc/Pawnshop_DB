-- 1. Реляционная БД

use [Exam]

create table ForumMembers (
    MemberId int not null primary key Identity(1,1),
    MemberName varchar(100)
    )
go
create table ForumPosts (
    [PostID] int not null primary key,
    PostTitle varchar(100),
    PostBody varchar(100),
    OwnerID int,
    ReplyTo int
    )
go
Create table Likes (
    MemberId int,
    PostId int
    )
go
create table LikeMember (
    MemberId int,
    LikedMemberId int
    )
go
INSERT INTO ForumMembers values
    ('Mike'),
    ('Carl'),
    ('Paul'),
    ('Christy'),
    ('Jennifer'),
    ('Charlie')
go
INSERT INTO  [ForumPosts] (
    [PostID],
    [PostTitle],
    [PostBody],
    OwnerID,
    ReplyTo
) VALUES
    (4,'Geography','Im Christy from USA',4,null),
    (1,'Intro','Hi There This is Carl',2,null)
    (8,'Intro','nice to see all here!',1,1),
    (7,'Intro','I''m Mike from Argentina',1,1),
    (6,'Re:Geography','I''m Mike from Argentina',1,4),
    (5,'Re:Geography','I''m Jennifer from Brazil',5,4),
    (3,'Re: Intro','Hey Paul This is Christy',4,2),
    (2,'Intro','Hello I''m Paul',3,1)
go
INSERT INTO Likes VALUES 
    (1,4),
    (2,7),
    (2,8),
    (2,2),
    (4,5),
    (4,6),
    (1,2),
    (3,7),
    (3,8),
    (5,4)
go
Insert INTO LikeMember VALUES
    (2,1),
    (2,3),
    (4,1),
    (4,5)

-- 2. Добавление внешних ключей

ALTER TABLE ForumPosts
ADD CONSTRAINT FK_OwnerID
FOREIGN KEY (OwnerID)
REFERENCES [dbo].[ForumMembers](MemberId) ON UPDATE CASCADE

ALTER TABLE ForumPosts
ADD CONSTRAINT FK_ReplyTo
FOREIGN KEY (ReplyTo)
REFERENCES [dbo].[ForumPosts](PostId) ON UPDATE CASCADE

ALTER TABLE Likes
ADD CONSTRAINT FK_MemberId
FOREIGN KEY (MemberId)
REFERENCES [dbo].[ForumMembers](MemberId) ON UPDATE CASCADE

ALTER TABLE Likes
ADD CONSTRAINT FK_PostId
FOREIGN KEY (PostId)
REFERENCES [dbo].[ForumPosts](PostId) ON UPDATE CASCADE

ALTER TABLE LikeMember
ADD CONSTRAINT FK_LikeMember_MemberId
FOREIGN KEY (MemberId)
REFERENCES [dbo].[ForumMembers](MemberId) ON UPDATE CASCADE

ALTER TABLE LikeMember
ADD CONSTRAINT FK_LikeMember_LikedMemberId
FOREIGN KEY (LikedMemberId)
REFERENCES [dbo].[ForumMembers](MemberId) ON UPDATE CASCADE

-- 3. Графовая БД по реляционной

create table G_ForumMembers (
	MemberId int not null primary key Identity(1,1),
	MemberName varchar(100)
	) AS NODE
go
create table G_ForumPosts (
	[PostID] int not null primary key,
	PostTitle varchar(100),
	PostBody varchar(100),
	OwnerID int,
	ReplyTo int
	) AS NODE
go

CREATE TABLE G_LikeMember AS EDGE
go

CREATE TABLE G_LikePost AS EDGE
go

CREATE TABLE G_WrittenBy AS EDGE
go

CREATE TABLE G_ReplyTo AS EDGE
go

INSERT INTO G_ForumMembers (MemberName)
SELECT MemberName FROM [dbo].[ForumMembers]

INSERT INTO G_ForumPosts ([PostID], PostTitle, PostBody)
SELECT [PostID], PostTitle, PostBody FROM [dbo].[ForumPosts]

INSERT INTO G_LikeMember ($from_id, $to_id)
SELECT 
	gfm1.$node_id, gfm2.$node_id
FROM [dbo].[LikeMember] lm
JOIN [dbo].[G_ForumMembers] gfm1 ON lm.MemberId = gfm1.MemberId
JOIN [dbo].[G_ForumMembers] gfm2 ON lm.LikedMemberId = gfm2.MemberId

INSERT INTO G_LikePost ($from_id, $to_id)
SELECT 
	gfm.$node_id, gfp.$node_id
FROM [dbo].[Likes] l
JOIN [dbo].[G_ForumMembers] gfm ON l.MemberId = gfm.MemberId
JOIN [dbo].[G_ForumPosts] gfp ON l.PostId = gfp.PostID

INSERT INTO G_WrittenBy ($from_id, $to_id)
SELECT 
	gfp.$node_id, gfm.$node_id
FROM [dbo].[ForumPosts] fp
JOIN [dbo].[G_ForumMembers] gfm ON fp.OwnerID = gfm.MemberId
JOIN [dbo].[G_ForumPosts] gfp ON fp.PostId = gfp.PostID

INSERT INTO G_ReplyTo ($from_id, $to_id)
SELECT 
	gfp1.$node_id, gfp2.$node_id
FROM [dbo].[ForumPosts] fp
JOIN [dbo].[G_ForumPosts] gfp1 ON fp.PostId = gfp1.PostID
JOIN [dbo].[G_ForumPosts] gfp2 ON fp.ReplyTo = gfp2.PostID

-- 4. Реляционная: Общее количество лайков для каждого сообщения

SELECT
	fp.PostTitle as Post,
	count(l.MemberId) as Likes
FROM [dbo].[ForumPosts] fp
JOIN [dbo].[Likes] l ON fp.PostID = l.PostId
GROUP BY fp.PostTitle

-- 5. Графовая: Участники, которые лайкнули пост и ответили на него

SELECT
	fm.MemberName as Name,
	fp.PostTitle
FROM [dbo].[G_ForumMembers] fm, [dbo].[G_ForumPosts] fp, [dbo].[G_ForumPosts] rep, [dbo].[G_LikePost] lp, [dbo].[G_ReplyTo] rt, [dbo].[G_WrittenBy] wb
WHERE MATCH(fp<-(lp)-fm<-(wb)-rep-(rt)->fp)

-- 6. Процедура: вывод ветки постов (от данного до корневого)

create or alter procedure GetReplyTree
	@PostID int,
	@ReplyTree nvarchar(max) output
as
Begin
	SET NOCOUNT ON;

    -- Проверяем существование поста, чтобы не возвращать пустую строку
    IF NOT EXISTS (SELECT 1 FROM ForumPosts WHERE PostID = @PostID)
    BEGIN
        SELECT @ReplyTree = 'Пост не найден'
        RETURN;
    END;

    WITH ThreadCTE AS (
        -- Базовая часть: целевой пост (самый левый в будущей строке)
        SELECT 
            PostID, 
            PostTitle, 
            ReplyTo, 
            1 AS Steps -- Порядковый номер для сборки строки
        FROM ForumPosts
        WHERE PostID = @PostID

        UNION ALL

        -- Рекурсивная часть: идем вверх к родительским постам (вправо)
        SELECT 
            p.PostID, 
            p.PostTitle, 
            p.ReplyTo, 
            t.Steps + 1
        FROM ForumPosts p
        INNER JOIN ThreadCTE t ON p.PostID = t.ReplyTo
    )
    -- Собираем строку, используя STRING_AGG
    SELECT @ReplyTree = STRING_AGG(CAST(PostTitle AS NVARCHAR(MAX)), '->') WITHIN GROUP (ORDER BY Steps ASC)
    FROM ThreadCTE;
End

declare @Tree nvarchar(max);
exec GetReplyTree @PostID = 3, @ReplyTree = @Tree output;
select @Tree as Tree;

-- 7. Триггер: не позволяет посту быть ответом на 2 других поста

create or alter trigger ForumPost_OnePostCannoBeReaplyToMultiplePosts
on [dbo].[G_ReplyTo] instead of insert
as
Begin
    -- Проверяем, нет ли дубликатов $from_id внутри inserted
    IF EXISTS (
        SELECT 1 
        FROM inserted
        GROUP BY JSON_VALUE($from_id, '$.graph_id')
        HAVING COUNT(DISTINCT JSON_VALUE($to_id, '$.graph_id')) > 1
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Проверяем, нет ли вставляемых постов, которые УЖЕ являются ответами в целевой таблице
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        -- Связываем по внутреннему идентификатору графа
        JOIN G_ReplyTo rt ON JSON_VALUE(i.$from_id, '$.graph_id') = JSON_VALUE(rt.$from_id, '$.graph_id')
    )
    BEGIN
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Если все проверки пройдены, выполняем вставку
    -- Используем функцию NODE_ID_FROM_PARTS, чтобы корректно перенести данные из inserted
    INSERT INTO G_ReplyTo ($from_id, $to_id)
    SELECT 
        NODE_ID_FROM_PARTS(OBJECT_ID('G_ForumPosts'), CAST(JSON_VALUE($from_id, '$.graph_id') AS BIGINT)),
        NODE_ID_FROM_PARTS(OBJECT_ID('G_ForumPosts'), CAST(JSON_VALUE($to_id, '$.graph_id') AS BIGINT))
    FROM inserted;
End