/* ����� 1. �������� ��������� */
/* ������� 1.  ������� ������� uEmployee, ������������� ����� ���������� ����� � ������� Employee.
������ ������� ������ �������� ������� ModifiedDate ������� ����� (������� GETDATE()). �����
�������������� �������� ������� ��������, ������� ���� ������ � ������� Employee.*/
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

/* ������� 2. ������� ������� dEmployee, ������������� ������ �������� ����� ������� Employees.
������ ������� ������ ��������� ������ �������� ����� ������� Employees.*/

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
/* ������� 3. ������� ������� iAuthors, ������������� �� ������� (��, ������ ��� ����� ������� �
���������� �����) ����� ������ � ������� Authors. ������ ������� ������ �������� ��������� ��������
�������� LastName � FirstName: ������ ����� � ���������, ��������� � ��������. ��������� ������
��������.*/

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
VALUES ('����', '������', '1809', '1852', '������');
SELECT * from dbo.Authors;
DELETE From Authors WHERE FirstName='�������';
Go

/* ����� 2. ���������� �������� �������� � ������� */
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
--���
/*5*/
EXEC LongLeadProducts 4
/*6*/
Select * INTO Lab2_BookShop.dbo.Department 
FROM AdventureWorks.HumanResources.Department
Go

Use Lab2_BookShop
Go
/*7 ������� �������� ���������, ������� ��������� ����� ����� � ������� Department*/
CREATE PROC AddDepartment
	@Name nvarchar(50), @GroupName nvarchar(50), @DeptID smallint OUTPUT
AS
INSERT INTO Department (Name, GroupName, ModifiedDate)
	VALUES (@Name, @GroupName, '15/12/19') 
SET @DeptID = SCOPE_IDENTITY()
/*8 ������� ID ������ ������, ��������� ��������� ���������� @dept.*/
DECLARE @dept int
EXEC AddDepartment 'Refunds', '', @dept OUTPUT 
SELECT @dept
/*9*/
Select * INTO Lab2_BookShop.dbo.SalesOrderDetail 
FROM AdventureWorks.Sales.SalesOrderDetail
Go

Use Lab2_BookShop
Go
/*10 ������� ��������� �������, ������� ������������ ����� ���������� ���� ������ ���
������������� �������� � ���������� ����� ���������� ��� int*/
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
/*13 ������� ������������� ��������� �������, ������� ���������� ����� ����������� ���
������������� ���������. */
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
/*15 ��������� ������ ������� ��������� ���������� � ����� ���������, ���������
@tbl_Employees. ������ ������� ���������� � ����������� �� ���������� ��������
��������� @format.*/
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
/*17 � ����� ���� ������ ������� ��������� �������, ������� �� ��������������� ������
�������� � ������ ������ ������ ������ ���� ���������, ��������� � �������� (��. �����
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

INSERT INTO Authors VALUES ('������', '��������', '1891', '1940', '������');
SELECT * FROM Authors
Go

CREATE PROC AddBook
@Title nvarchar(100),
@Janr nvarchar(50),
@BookID int
AS
INSERT INTO dbo.Books(Title, Janr, BookID)
VALUES (@Title, @Janr, @BookID)

EXEC AddBook '������ � ���������', '�����', 11
SELECT * FROM Books
Go















CREATE TRIGGER insertAuthors ON Authors
INSTEAD OF INSERT NOT FOR REPLICATION AS
BEGIN
UPDATE Authors
SET Authors.FirstName = '���������� ' + Authors.FirstName WHERE Authors.FirstName = '����'
END
INSERT INTO Authors VALUES ('����', '����', '1897', '1937', '������');
SELECT * FROM Authors
DROP TRIGGER insertAuthors
Go

CREATE TRIGGER eAuthors ON Authors
INSTEAD OF Delete NOT FOR REPLICATION AS
BEGIN
UPDATE Authors
SET YearDied=1940 Where FirstName = '������'
End
Delete from Authors where FirstName = '������'
Go

CREATE TRIGGER proAuthors ON Authors
AFTER INSERT AS
BEGIN
--SET NOCOUNT ON;
UPDATE Authors SET
		Authors.LastName= UPPER(SUBSTRING(Authors.LastName, 1,1))+LOWER(SUBSTRING(Authors.LastName, 2, LEN(Authors.LastName))) + ' ������'
		FROM Authors
		WHERE Authors.LastName = '����'
End
INSERT INTO dbo.Authors
VALUES ('����', '����', '1897', '1937', '������');
SELECT * from Authors;
DROP TRIGGER proAuthors