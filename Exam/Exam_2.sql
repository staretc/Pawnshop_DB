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
			fp.PostTitle,
			fp.ReplyTo,
			1 as lvl
		from [dbo].[ForumPosts] fp
		where fp.PostID = @PostID

		union all

		select
			fp.PostID,
			fp.PostTitle,
			fp.ReplyTo,
			r.lvl + 1
		from [dbo].[ForumPosts] fp
		join replies r on r.ReplyTo = fp.PostID
	)

	select @ReplyTree = string_agg(cast(PostTitle as nvarchar(max)), '->') within group (order by lvl)
	from replies
End

declare @Tree nvarchar(max);
exec GetReplyTree @PostID = 3, @ReplyTree = @Tree output;
select @Tree as Tree;