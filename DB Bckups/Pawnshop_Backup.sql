USE [msdb];
GO

-- Удаление задания

EXEC dbo.sp_delete_job 
    @job_name = N'Pawnshop_Full_Backup_Job'; 
GO

USE [msdb];
GO

-- Пути
DECLARE @BackupDir NVARCHAR(100) = N'C:\Pawnshop_Backups';
DECLARE @RemoteDir NVARCHAR(100) = N'C:\Pawnshop_Remote_Backups';
DECLARE @LogFile   NVARCHAR(100) = N'C:\Pawnshop_Backups\tasks.log';

------------------------------------------------------------------------
-- Полный бэкап (Каждые 7 минут)
------------------------------------------------------------------------
EXEC dbo.sp_add_job @job_name = N'Pawnshop_Full_Backup_Job', @enabled = 1;

EXEC dbo.sp_add_jobstep @job_name = N'Pawnshop_Full_Backup_Job', @step_name = N'Execute Full Backup and Copy',
    @subsystem = N'TSQL',
    @command = N'
    DECLARE @TimeStr VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), '':'', '''');
    DECLARE @FileName VARCHAR(260) = ''C:\Pawnshop_Backups\Pawnshop_DB_Full_'' + @TimeStr + ''.bak'';
    DECLARE @RemoteName VARCHAR(260) = ''C:\Pawnshop_Remote_Backups\Pawnshop_DB_Full_'' + @TimeStr + ''.bak'';
    
    -- Бэкап
    DECLARE @BackupSQL NVARCHAR(MAX) = ''BACKUP DATABASE [Pawnshop_DB] TO DISK = '''''' + CAST(@FileName AS NVARCHAR(260)) + '''''' WITH NOINIT, NAME = ''''Pawnshop_Full_Backup'''';'';
    EXEC (@BackupSQL);
    
    -- Копирование
    DECLARE @CopySQL VARCHAR(8000) = ''copy "'' + @FileName + ''" "'' + @RemoteName + ''"'';
    EXEC master..xp_cmdshell @CopySQL;',
    @output_file_name = @LogFile, @flags = 2;

EXEC dbo.sp_add_jobschedule @job_name = N'Pawnshop_Full_Backup_Job', @name = N'Full_Backup_Schedule_7min',
    @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 7;
EXEC dbo.sp_add_jobserver @job_name = N'Pawnshop_Full_Backup_Job';

------------------------------------------------------------------------
-- Дифференциальный бэкап (Каждые 5 минут)
------------------------------------------------------------------------
EXEC dbo.sp_add_job @job_name = N'Pawnshop_Diff_Backup_Job', @enabled = 1;

EXEC dbo.sp_add_jobstep @job_name = N'Pawnshop_Diff_Backup_Job', @step_name = N'Execute Diff Backup and Copy',
    @subsystem = N'TSQL',
    @command = N'
    DECLARE @TimeStr VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), '':'', '''');
    DECLARE @FileName VARCHAR(260) = ''C:\Pawnshop_Backups\Pawnshop_DB_Diff_'' + @TimeStr + ''.bak'';
    DECLARE @RemoteName VARCHAR(260) = ''C:\Pawnshop_Remote_Backups\Pawnshop_DB_Diff_'' + @TimeStr + ''.bak'';
    
    DECLARE @BackupSQL NVARCHAR(MAX) = ''BACKUP DATABASE [Pawnshop_DB] TO DISK = '''''' + CAST(@FileName AS NVARCHAR(260)) + '''''' WITH DIFFERENTIAL, NOINIT, NAME = ''''Pawnshop_Diff_Backup'''';'';
    EXEC (@BackupSQL);
    
    DECLARE @CopySQL VARCHAR(8000) = ''cmd.exe /c copy "'' + @FileName + ''" "'' + @RemoteName + ''"'';
    EXEC master..xp_cmdshell @CopySQL;',
    @output_file_name = @LogFile, @flags = 2;

EXEC dbo.sp_add_jobschedule @job_name = N'Pawnshop_Diff_Backup_Job', @name = N'Diff_Backup_Schedule_5min',
    @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 5;
EXEC dbo.sp_add_jobserver @job_name = N'Pawnshop_Diff_Backup_Job';

------------------------------------------------------------------------
-- Бэкап лога (Каждые 3 минуты)
------------------------------------------------------------------------
EXEC dbo.sp_add_job @job_name = N'Pawnshop_Log_Backup_Job', @enabled = 1;

EXEC dbo.sp_add_jobstep @job_name = N'Pawnshop_Log_Backup_Job', @step_name = N'Execute Log Backup and Copy',
    @subsystem = N'TSQL',
    @command = N'
    DECLARE @TimeStr VARCHAR(20) = CONVERT(VARCHAR(20), GETDATE(), 112) + ''_'' + REPLACE(CONVERT(VARCHAR(20), GETDATE(), 108), '':'', '''');
    DECLARE @FileName VARCHAR(260) = ''C:\Pawnshop_Backups\Pawnshop_DB_Log_'' + @TimeStr + ''.bak'';
    DECLARE @RemoteName VARCHAR(260) = ''C:\Pawnshop_Remote_Backups\Pawnshop_DB_Log_'' + @TimeStr + ''.bak'';
    
    DECLARE @BackupSQL NVARCHAR(MAX) = ''BACKUP LOG [Pawnshop_DB] TO DISK = '''''' + CAST(@FileName AS NVARCHAR(260)) + '''''' WITH NOINIT, NAME = ''''Pawnshop_Log_Backup'''';'';
    EXEC (@BackupSQL);
    
    DECLARE @CopySQL VARCHAR(8000) = ''cmd.exe /c copy "'' + @FileName + ''" "'' + @RemoteName + ''"'';
    EXEC master..xp_cmdshell @CopySQL;',
    @output_file_name = @LogFile, @flags = 2;

EXEC dbo.sp_add_jobschedule @job_name = N'Pawnshop_Log_Backup_Job', @name = N'Log_Backup_Schedule_3min',
    @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 3;
EXEC dbo.sp_add_jobserver @job_name = N'Pawnshop_Log_Backup_Job';
GO

------------------------------------------------------------------------
-- Процедура восстановления
------------------------------------------------------------------------
USE [master];
GO

CREATE OR ALTER PROCEDURE dbo.sp_RestorePawnshopToPointInTime
    @SourceDBName SYSNAME = N'Pawnshop_DB',
    @TargetTime DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TargetDBName SYSNAME = N'Pawnshop_DB_Restored';
    DECLARE @NewFilesPath NVARCHAR(100) = N'C:\Pawnshop_Backups\';

    -- Переменные для поиска контрольных точек
    DECLARE @FullBackupSetId INT, @FullBackupPath NVARCHAR(260);
    DECLARE @DiffBackupSetId INT, @DiffBackupPath NVARCHAR(260);
    DECLARE @LastLogSetId INT;
    DECLARE @BaseFinishDate DATETIME;
    DECLARE @SQL NVARCHAR(MAX);

    --------------------------------------------------------------------------------
    -- 1. Поиск ближайшего ПОЛНОГО бэкапа ПЕРЕД целевым временем
    --------------------------------------------------------------------------------
    SELECT TOP 1 
        @FullBackupSetId = bs.backup_set_id,
        @FullBackupPath = bmf.physical_device_name
    FROM msdb.dbo.backupset bs
    JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = @SourceDBName
      AND bs.type = 'D'
      AND bs.backup_finish_date <= @TargetTime
    ORDER BY bs.backup_finish_date DESC;

    IF @FullBackupSetId IS NULL
    BEGIN
        RAISERROR('Критическая ошибка: Полный бэкап до указанного времени не найден!', 16, 1);
        RETURN;
    END;

    --------------------------------------------------------------------------------
    -- 2. Поиск ближайшего ДИФФЕРЕНЦИАЛЬНОГО бэкапа ПЕРЕД целевым временем
    --------------------------------------------------------------------------------
    SELECT TOP 1 
        @DiffBackupSetId = bs.backup_set_id,
        @DiffBackupPath = bmf.physical_device_name,
        @BaseFinishDate = bs.backup_finish_date
    FROM msdb.dbo.backupset bs
    JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
    WHERE bs.database_name = @SourceDBName
      AND bs.type = 'I'
      AND bs.backup_finish_date <= @TargetTime
      AND bs.backup_finish_date > (SELECT bs_sub.backup_finish_date FROM msdb.dbo.backupset bs_sub WHERE bs_sub.backup_set_id = @FullBackupSetId)
    ORDER BY bs.backup_finish_date DESC;

    IF @DiffBackupSetId IS NULL
        SELECT @BaseFinishDate = bs_f.backup_finish_date FROM msdb.dbo.backupset bs_f WHERE bs_f.backup_set_id = @FullBackupSetId;

    --------------------------------------------------------------------------------
    -- 3. Поиск первого бэкапа лога ПОСЛЕ целевого времени
    --------------------------------------------------------------------------------
    SELECT TOP 1 
        @LastLogSetId = bs.backup_set_id
    FROM msdb.dbo.backupset bs
    WHERE bs.database_name = @SourceDBName
      AND bs.type = 'L'
      AND bs.backup_finish_date >= @TargetTime
    ORDER BY bs.backup_finish_date ASC;

    IF @LastLogSetId IS NULL
    BEGIN
        RAISERROR('Предупреждение: Бэкап лога, покрывающий целевое время, не найден.', 10, 1);
    END;

    --------------------------------------------------------------------------------
    -- 4. Генерация конструкции MOVE для изоляции новой БД
    --------------------------------------------------------------------------------
    DECLARE @MoveClause NVARCHAR(MAX) = N'';
    DECLARE @LogicalName SYSNAME, @FileType INT;

    DECLARE file_cursor CURSOR FOR
    SELECT name, type FROM sys.master_files WHERE database_id = DB_ID(@SourceDBName);

    OPEN file_cursor;
    FETCH NEXT FROM file_cursor INTO @LogicalName, @FileType;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        IF @FileType = 0 
            SET @MoveClause = @MoveClause + N', MOVE ''' + @LogicalName + N''' TO ''' + @NewFilesPath + @TargetDBName + N'_' + @LogicalName + N'.mdf''';
        ELSE IF @FileType = 1 
            SET @MoveClause = @MoveClause + N', MOVE ''' + @LogicalName + N''' TO ''' + @NewFilesPath + @TargetDBName + N'_' + @LogicalName + N'.ldf''';
        
        FETCH NEXT FROM file_cursor INTO @LogicalName, @FileType;
    END;
    CLOSE file_cursor;
    DEALLOCATE file_cursor;

    --------------------------------------------------------------------------------
    -- 5. Процесс восстановления
    --------------------------------------------------------------------------------
    BEGIN TRY
        
        -- Удаление старой версии базы данных
        IF DB_ID(@TargetDBName) IS NOT NULL
        BEGIN
            IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @TargetDBName AND state_desc = 'RESTORING')
            BEGIN
                SET @SQL = N'DROP DATABASE [' + @TargetDBName + N'];';
            END
            ELSE
            BEGIN
                SET @SQL = N'ALTER DATABASE [' + @TargetDBName + N'] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [' + @TargetDBName + N'];';
            END;
            
            PRINT 'Удаление предыдущей незавершенной версии базы ' + @TargetDBName;
            EXEC(@SQL);
        END;

        -- Восстановление Полного бэкапа
        PRINT 'Восстановление полного бэкапа из: ' + @FullBackupPath;
        SET @SQL = N'RESTORE DATABASE [' + @TargetDBName + N'] FROM DISK = @Path WITH NORECOVERY, REPLACE' + @MoveClause + N';';
        EXEC sp_executesql @SQL, N'@Path NVARCHAR(260)', @Path = @FullBackupPath;

        -- Восстановление Дифференциального бэкапа
        IF @DiffBackupSetId IS NOT NULL
        BEGIN
            PRINT 'Восстановление дифференциального бэкапа из: ' + @DiffBackupPath;
            SET @SQL = N'RESTORE DATABASE [' + @TargetDBName + N'] FROM DISK = @Path WITH NORECOVERY;';
            EXEC sp_executesql @SQL, N'@Path NVARCHAR(260)', @Path = @DiffBackupPath;
        END;

        -- Восстановление последовательности логов
        DECLARE @LogSetId INT, @LogPath NVARCHAR(260);

        DECLARE log_cursor CURSOR FOR
        SELECT bs.backup_set_id, bmf.physical_device_name
        FROM msdb.dbo.backupset bs
        JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
        WHERE bs.database_name = @SourceDBName
          AND bs.type = 'L'
          AND bs.backup_finish_date > @BaseFinishDate
          AND (bs.backup_set_id <= @LastLogSetId OR @LastLogSetId IS NULL)
        ORDER BY bs.backup_finish_date ASC;

        OPEN log_cursor;
        FETCH NEXT FROM log_cursor INTO @LogSetId, @LogPath;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            IF @LogSetId = @LastLogSetId
            BEGIN
                PRINT 'Применение финального лога со STOPAT из: ' + @LogPath;
                SET @SQL = N'RESTORE LOG [' + @TargetDBName + N'] FROM DISK = @Path WITH RECOVERY, STOPAT = @Time;';
                EXEC sp_executesql @SQL, N'@Path NVARCHAR(260), @Time DATETIME', @Path = @LogPath, @Time = @TargetTime;
            END;
            ELSE
            BEGIN
                PRINT 'Применение промежуточного лога из: ' + @LogPath;
                SET @SQL = N'RESTORE LOG [' + @TargetDBName + N'] FROM DISK = @Path WITH NORECOVERY;';
                EXEC sp_executesql @SQL, N'@Path NVARCHAR(260)', @Path = @LogPath;
            END;

            FETCH NEXT FROM log_cursor INTO @LogSetId, @LogPath;
        END;
        CLOSE log_cursor;
        DEALLOCATE log_cursor;

        -- Если логов вообще не было, выводим базу в онлайн
        IF @DiffBackupSetId IS NULL AND @LastLogSetId IS NULL
        BEGIN
            SET @SQL = N'RESTORE DATABASE [' + @TargetDBName + N'] WITH RECOVERY;';
            EXEC(@SQL);
        END;

        PRINT 'Успешно! База данных восстановлена на момент времени: ' + CONVERT(NVARCHAR(19), @TargetTime, 120);
    END TRY
    BEGIN CATCH
        IF CURSOR_STATUS('local', 'log_cursor') >= 0
        BEGIN
            CLOSE log_cursor;
            DEALLOCATE log_cursor;
        END;

        DECLARE @ErrorMsg NVARCHAR(4000) = 'Ошибка восстановления: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMsg, 16, 1);
    END CATCH
END;
GO

-- ПРОВЕРКА РАБОТЫ
use [Pawnshop_DB]
insert into Item_Type
values (N'TEST TYPE')
select * from Item_Type

declare @before int;
select @before = count(*) from Item_Type

-- ЗАПУСК ПРОЦЕДУРЫ ВОССТАНОВЛЕНИЯ
USE [master];
EXEC dbo.sp_RestorePawnshopToPointInTime 
    @SourceDBName = N'Pawnshop_DB', 
    @TargetTime = '19-05-2026 13:31:40';

use [Pawnshop_DB_Restored]
declare @after int;
select @after = count(*) from Item_Type

print 'before: ' + CONVERT(varchar, @before) + '. after: ' + CONVERT(varchar, @after)

use [Pawnshop_DB]
delete from Item_Type
where Name = N'TEST TYPE'