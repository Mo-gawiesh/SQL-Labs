USE master
GO
CREATE DATABASE Lab2_BookShop;

EXEC sp_helpdb Lab2_BookShop;
Go

CREATE TABLE Authors (
    AuthorID int IDENTITY NOT NULL,
    FirstName VARCHAR(30) NOT NULL default 'unknown',
    LastName VARCHAR(30) NULL,
    YearBorn CHAR(4) NULL,
    YearDied CHAR(4) NOT NULL default 'no',
);

EXEC sp_help Authors;

ALTER TABLE Authors
ADD Descr VARCHAR(200) NOT NULL
GO

USE Lab2_BookShop
GO
CREATE TABLE Books
(
BookID int not null PRIMARY KEY,
Title VARCHAR(100) not null,
Janr VARCHAR(50) null
)
EXEC sp_help Books;

USE Lab2_BookShop
GO
CREATE TABLE BooksAuthor
(
BookID int not null,
AuthorID int not null
)
EXEC sp_help BooksAuthor;

ALTER TABLE BooksAuthor
ADD PRIMARY KEY (BookID, AuthorID)

ALTER TABLE BooksAuthor
ADD CONSTRAINT Books_Authors
FOREIGN KEY (BookID) REFERENCES Books (BookID)

ALTER TABLE Authors
ADD PRIMARY KEY (AuthorID)

ALTER TABLE BooksAuthor
ADD CONSTRAINT BooksAuthor_Authors
FOREIGN KEY (AuthorID) REFERENCES Authors (AuthorID)

ALTER TABLE Authors
ADD CONSTRAINT check_YearBorn
CHECK (YearBorn LIKE '[1-2][0,6-9][0-9][0-9]');

ALTER TABLE Authors
ADD CONSTRAINT check_YearDied
CHECK (YearDied LIKE '[1-2][0,6-9][0-9][0-9]' or YearDied LIKE 'no');

ALTER TABLE Authors
ADD CONSTRAINT check_YearBorn_YearDied
CHECK (YearDied > YearBorn);