-- 4. Реляционная: Количество участников, поставивших лайк на каждый пост
select
	fp.PostID as Post,
	count(*) as Likes
from [dbo].[ForumPosts] fp
left join [dbo].[Likes] l on fp.PostID = l.PostId
group by fp.PostID

-- 5. Графовая: Участники, которые лайкнули пост но не ответили на него
select
	fm.[MemberName],
	fp.[PostTitle]
from [dbo].[G_ForumPosts] fp, [dbo].[G_ForumMembers] fm, [dbo].[G_LikePost] lp
where match (fm-(lp)->fp)
except
select
	fm.[MemberName],
	fp.[PostTitle]
from [dbo].[G_ForumPosts] fp, [dbo].[G_ForumMembers] fm, [dbo].[G_LikePost] lp, [dbo].[G_ForumPosts] rep, [dbo].[G_WrittenBy] wb, [dbo].[G_ReplyTo] rt
where match (fp<-(rt)-rep-(wb)->fm-(lp)->fp)

-- 6. Процедура: вывод ветки постов (от данного до корневого)
create or alter procedure GetReplyTree
	@PostID int,
	@ReplyTree nvarchar(max) output
as
Begin
	set nocount on;

	with replies as (
		select
			fp.PostID,
			cast(fp.PostTitle as nvarchar(max)) as PostTitle,
			fp.ReplyTo,
			1 as lvl
		from [dbo].[ForumPosts] fp
		where fp.PostID = @PostID

		union all

		select
			fp.PostID,
			r.PostTitle + ' -> ' + cast(fp.PostTitle as nvarchar(max)),
			fp.ReplyTo,
			r.lvl + 1
		from [dbo].[ForumPosts] fp
		join replies r on r.ReplyTo = fp.PostID
	)

	select @ReplyTree = PostTitle
	from replies
End

declare @Tree nvarchar(max);
exec GetReplyTree @PostID = 3, @ReplyTree = @Tree output;
select @Tree as Tree;

-- 7. Тригер: Не более 5 ответов на разные посты, содержащие один и тот же текст

create or alter trigger ForumPost_LessOrEqual5ReplierWithSameBody
on [dbo].[ForumPosts] instead of insert
as
Begin
	declare @PostID int
	declare @PostTitle varchar(100)
	declare @PostBody varchar(100)
	declare @OwnerID int
	declare @ReplyTo int
	declare @count int

	declare cur cursor for
	select PostID, PostTitle, PostBody, OwnerID, ReplyTo
	from inserted

	open cur

	fetch next from cur
	into @PostID, @PostTitle, @PostBody, @OwnerID, @ReplyTo

	while @@FETCH_STATUS = 0
	begin
		-- посчитаем количество постов от этого автора с таким же текстом, которые являются ответами на другие посты
		select @count = count(*)
		from [dbo].[ForumPosts]
		where OwnerID = @OwnerID
		and ReplyTo is not null
		and PostBody = @PostBody
		group by OwnerID

		if @count >= 5
		begin
			insert into [dbo].[ForumPosts]
			values (@PostID, @PostTitle, @PostBody, @OwnerID, @ReplyTo)
		end
	end

	close cur
	deallocate cur
End