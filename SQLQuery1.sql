USE master
GO
CREATE DATABASE MyDB
ON /* файл данных */
( NAME = MyDB_Dat,
FILENAME = 'C:\4311\MyDB_Dat.mdf',
SIZE = 4,
MAXSIZE = 10,
FILEGROWTH = 1)
LOG ON /*файл журнала*/
( NAME = MyDB_Log,
FILENAME = 'C:\4311\MyDB_Log.ldf', /* Есть такой вариант создания, бд с параметрами*/
SIZE = 2,
MAXSIZE = 5,
FILEGROWTH = 1%)
EXEC sp_helpdb MyDB
USE [master]
GO
ALTER DATABASE [MyDB] MODIFY FILE ( NAME = N'MyDB_Dat', MAXSIZE = 15 ) /* измена размера файла с 10 мб на 15*/
GO
DROP DATABASE MyDB

CREATE DATABASE MyDB /* Создается бд по умолчанию без этих файлов данных и файла журнала*/
USE MyDB
GO

CREATE TABLE table__1 (id int NOT NULL, fio varchar(20) NULL, datar datetime)
INSERT INTO table__1(id, fio, datar) VALUES (1, 'Ivanov', '07/09/2018 9:10:30.000')
INSERT INTO table__1(id, fio, datar) VALUES (2, 'Stepanov', '08/09/2018 9:10:30.000')
select * from table__1
ALTER DATABASE MyDB
ADD FILEGROUP [Secondary]
GO

ALTER DATABASE MyDB
ADD FILE (NAME=N'Test',
FILENAME=N'C:\4311\Test.ndf')
TO FILEGROUP [Secondary]
GO
ALTER DATABASE MyDB MODIFY FILEGROUP [Secondary] DEFAULT
GO
CREATE DATABASE MyDB_Snapshot ON
( NAME = N'MyDB', FILENAME= 
N'C:\4311\MyDB.ss'), /* создаем копию баззы данных*/
(NAME = N'Test', FILENAME=
N'C:\4311\Test.ss')   
AS SNAPSHOT OF MyDB  /*  Снапшот -простая копия бд, но не сама бд. Предназначен только для чтения, тестирования разработки бд*/
USE [MyDB]
GO
(SELECT * FROM MyDB_.dbo.table__1)
(SELECT * FROM MyDB_Snapshot.dbo.table__1)
UPDATE MyDB.dbo.table__1 SET id=5
USE master
GO
DROP DATABASE MyDB_Snapshot
DROP DATABASE MyDB
