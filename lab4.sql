/* ЧАСТЬ 1. СОЗДАНИЕ ТРИГГЕРОВ */
/* Задание 1.  Создать триггер uEmployee, срабатывающий после обновления строк в таблице Employee.
Данный триггер должен заменять столбец ModifiedDate текущей датой (функция GETDATE()). Затем
протестировать действие данного триггера, изменив одну строку в таблице Employee.*/
Use AdventureWorks
Go
SELECT * INTO Lab2_BookShop.dbo.Employee FROM AdventureWorks.HumanResources.Employee;

Use Lab2_BookShop
Go
CREATE TRIGGER uEmployee ON Employee 
AFTER UPDATE NOT FOR REPLICATION AS 
BEGIN
	SET NOCOUNT ON; 
	UPDATE Employee
		SET Employee.ModifiedDate = GETDATE()
		FROM inserted
		WHERE inserted.EmployeeID = Employee.EmployeeID
END

--Update Employee SET ModifiedDate='01/01/01' WHERE EmployeeID=1;

SELECT * from dbo.Employee WHERE EmployeeID=1;

DROP TRIGGER uEmployee
Go

/* Задание 2. Создать триггер dEmployee, срабатывающий вместо удаления строк таблицы Employees.
Данный триггер должен запрещать всякое удаление строк таблицы Employees.*/

CREATE TRIGGER [dEmployee] ON [dbo].[Employee]
INSTEAD OF DELETE NOT FOR REPLICATION AS 
BEGIN
	SET NOCOUNT ON;
	DECLARE @DeleteCount int;
	SELECT @DeleteCount = COUNT(*) FROM deleted; 
	IF @DeleteCount > 0
	BEGIN
		RAISERROR
			(N'Employees cannot be deleted.', -- Message
			10, -- Severity. 
			1); -- State.
		IF @@TRANCOUNT > 0 -- Roll back any active or uncommittable transactions 
		BEGIN
			ROLLBACK TRANSACTION; 
		END
	END; 
END;

DELETE From Employee WHERE EmployeeID=1;

DROP TRIGGER dEmployee
Go
/* Задание 3. Создать триггер iAuthors, срабатывающий на вставку (до, вместо или после вставки –
определить самим) новой строки в таблицу Authors. Данный триггер должен заменять введенные значения
столбцов LastName и FirstName: первая буква – заглавная, остальные – строчные. Проверить работу
триггера.*/

CREATE TRIGGER iAuthors ON dbo.Authors
AFTER INSERT AS
BEGIN
	SET NOCOUNT ON;
	UPDATE Authors SET
		FirstName=UPPER(SUBSTRING(inserted.FirstName, 1,1))+LOWER(SUBSTRING(inserted.FirstName, 2, LEN(inserted.FirstName)))
		FROM inserted
		WHERE inserted.AuthorID = Authors.AuthorID
	UPDATE Authors SET
		LastName=UPPER(SUBSTRING(inserted.LastName, 1,1))+LOWER(SUBSTRING(inserted.LastName, 2, LEN(inserted.LastName)))
		FROM inserted
		WHERE inserted.AuthorID = Authors.AuthorID
END

INSERT INTO dbo.Authors
VALUES ('Коля', 'гоголь', '1809', '1852', 'Россия');
SELECT * from dbo.Authors;
DELETE From Authors WHERE FirstName='николай';
Go

/* ЧАСТЬ 2. РЕАЛИЗАЦИЯ ХРАНИМЫХ ПРОЦЕДУР И ФУНКЦИЙ */
/*1*/
Use AdventureWorks
Go
Select * INTO Lab2_BookShop.dbo.Product FROM AdventureWorks.Production.Product

Use Lab2_BookShop
Go
/*2*/
CREATE PROC LongLeadProducts 
AS
	SELECT Name, ProductNumber 
	FROM Product
	WHERE DaysToManufacture >= 1
GO
/*3*/
EXEC LongLeadProducts
Go
/*4*/
Alter proc LongLeadProducts
@MinimumLength int = 1 -- default value
AS 
	IF (@MinimumLength < 0) -- validate
	BEGIN
		RAISERROR('Invalid lead time.', 14, 1)
		RETURN
	END
SELECT Name, ProductNumber, DaysToManufacture
FROM .Product
WHERE DaysToManufacture >= @MinimumLength
ORDER BY DaysToManufacture DESC, Name

--EXEC LongLeadProducts @MinimumLength=4
--Или
/*5*/
EXEC LongLeadProducts 4
/*6*/
Select * INTO Lab2_BookShop.dbo.Department 
FROM AdventureWorks.HumanResources.Department
Go

Use Lab2_BookShop
Go
/*7 Создать хранимую процедуру, которая добавляет новый отдел в таблицу Department*/
CREATE PROC AddDepartment
	@Name nvarchar(50), @GroupName nvarchar(50), @DeptID smallint OUTPUT
AS
INSERT INTO Department (Name, GroupName, ModifiedDate)
	VALUES (@Name, @GroupName, '15/12/19') 
SET @DeptID = SCOPE_IDENTITY()
/*8 Вывести ID нового отдела, используя локальную переменную @dept.*/
DECLARE @dept int
EXEC AddDepartment 'Refunds', '', @dept OUTPUT 
SELECT @dept
/*9*/
Select * INTO Lab2_BookShop.dbo.SalesOrderDetail 
FROM AdventureWorks.Sales.SalesOrderDetail
Go

Use Lab2_BookShop
Go
/*10 Создать скалярную функцию, которая подсчитывает общее количество всех продаж для
определенного продукта и возвращает общее количество как int*/
CREATE FUNCTION SumSold(@ProductID int) 
RETURNS int AS
BEGIN
	DECLARE @ret int
	SELECT @ret = SUM(OrderQty)
	FROM SalesOrderDetail WHERE ProductID = @ProductID 
	IF (@ret IS NULL)
		SET @ret = 0 
	RETURN @ret
END
Go
/*11*/
SELECT ProductID, Name, dbo.SumSold(ProductID) AS SumSold From Product

SELECT * INTO Lab2_BookShop.dbo.Contact FROM Lab2_BookShop.dbo.Authors
Go
/*13 Создать подставляемую табличную функцию, которая возвращает имена подчиненных для
определенного менеджера. */
CREATE FUNCTION BooksForAuthor 
	(@BookId int)
RETURNS TABLE 
AS
RETURN (
	SELECT FirstName, LastName
	FROM Authors INNER JOIN BooksAuthor 
		ON BooksAuthor.AuthorID = Authors.AuthorID
	WHERE BookId = @BookId )
Go
/*14*/
SELECT * FROM BooksForAuthor(1) 
SELECT * FROM BooksForAuthor(4) 
Go
/*15 Следующий пример создает табличную переменную с двумя столбцами, названную
@tbl_Employees. Второй столбец изменяется в зависимости от требуемого значения
параметра @format.*/
CREATE FUNCTION AuthorsNames
	(@format nvarchar(9))
RETURNS @tbl_Authors TABLE 
	(AuthorID int PRIMARY KEY, [AuthorsNames] nvarchar(100))
AS
BEGIN
	If(@format = 'SHORTNAME')
		INSERT @tbl_Authors
		SELECT AuthorID,LastName 
		FROM Authors
	ELSE IF (@format = 'LONGNAME')
		INSERT @tbl_Authors
		SELECT AuthorID, (FirstName + ' ' + LastName)
		FROM Authors
	RETURN
END
GO
/*16*/
SELECT * FROM AuthorsNames ('LONGNAME')
SELECT * FROM AuthorsNames ('SHORTNAME')

Use Lab2_BookShop
Go
/*17 В своей базе данных создать скалярную функцию, которая бы преобразовывала строку
символов – первый символ строки должен быть заглавным, остальные – строчные (см. часть
1).*/
CREATE FUNCTION GoodName(@input nvarchar(100))
RETURNS nvarchar(100)
AS
BEGIN
	DECLARE @first varchar(1);
	SELECT @first = UPPER(SUBSTRING(@input, 1, 2))
	RETURN @first + LOWER(SUBSTRING(@input, 2, LEN(@input)))
END
Go

Drop TRIGGER iAuthors
Go

CREATE TRIGGER iAuthors ON dbo.Authors
	AFTER INSERT AS
	BEGIN
		SET NOCOUNT ON;
		UPDATE Authors SET FirstName=dbo.GoodName(Authors.FirstName)
		FROM inserted
		WHERE inserted.AuthorID = Authors.AuthorID
		UPDATE Authors SET LastName=dbo.GoodName(Authors.LastName)
		FROM inserted
		WHERE inserted.AuthorID = Authors.AuthorID
END

INSERT INTO Authors VALUES ('михаил', 'булгаков', '1891', '1940', 'Россия');
SELECT * FROM Authors
Go

CREATE PROC AddBook
@Title nvarchar(100),
@Janr nvarchar(50),
@BookID int
AS
INSERT INTO dbo.Books(Title, Janr, BookID)
VALUES (@Title, @Janr, @BookID)

EXEC AddBook 'Мастер и Маргарита', 'роман', 11
SELECT * FROM Books
Go















CREATE TRIGGER insertAuthors ON Authors
INSTEAD OF INSERT NOT FOR REPLICATION AS
BEGIN
UPDATE Authors
SET Authors.FirstName = 'Знаменитый ' + Authors.FirstName WHERE Authors.FirstName = 'Илья'
END
INSERT INTO Authors VALUES ('Илья', 'Ильф', '1897', '1937', 'Россия');
SELECT * FROM Authors
DROP TRIGGER insertAuthors
Go

CREATE TRIGGER eAuthors ON Authors
INSTEAD OF Delete NOT FOR REPLICATION AS
BEGIN
UPDATE Authors
SET YearDied=1940 Where FirstName = 'Михаил'
End
Delete from Authors where FirstName = 'Михаил'
Go

CREATE TRIGGER proAuthors ON Authors
AFTER INSERT AS
BEGIN
--SET NOCOUNT ON;
UPDATE Authors SET
		Authors.LastName= UPPER(SUBSTRING(Authors.LastName, 1,1))+LOWER(SUBSTRING(Authors.LastName, 2, LEN(Authors.LastName))) + ' Петров'
		FROM Authors
		WHERE Authors.LastName = 'Ильф'
End
INSERT INTO dbo.Authors
VALUES ('Илья', 'Ильф', '1897', '1937', 'Россия');
SELECT * from Authors;
DROP TRIGGER proAuthors