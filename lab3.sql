USE Lab2_BookShop

/*Задание 13*/
SELECT AuthorID, FirstName, LastName 
FROM Authors
FOR XML RAW('Author'), ROOT ('Authors') 

/*Задание 14*/
SELECT AuthorID, FirstName, LastName 
FROM Authors
FOR XML RAW('Author'), ELEMENTS, ROOT('Authors') 

/*Задание 15*/
SELECT 1 AS TAG,
null AS Parent,
AuthorID AS [Author!1!ID],
FirstName AS [Author!1!First!Element],
LastName AS [Author!1!Last!Element]
FROM Authors 
FOR XML EXPLICIT

/*Задание 16*/
SELECT b.BookID, b.Title, concat(a.FirstName,' ' ,a.LastName) AS Author 
FROM Books b
LEFT JOIN BooksAuthor ab ON (b.BookID = ab.BookID)
LEFT JOIN Authors a ON (a.AuthorID = ab.AuthorID)
FOR XML RAW('Book'), ELEMENTS




SELECT Book.BookID BookID, Title Title,
(SELECT concat(Authors.FirstName,' ',Authors.LastName) Author FROM BooksAuthor, Authors
WHERE BooksAuthor.AuthorID =Authors.AuthorID AND BookID = Book.BookID
FOR XML AUTO, TYPE )
FROM Books book
INNER JOIN BooksAuthor ON Book.BookID = BooksAuthor.BookID
INNER JOIN Authors ON BooksAuthor.AuthorID = Authors.AuthorID
GROUP BY Book.BookID, Book.Title
FOR XML PATH('Book'), ELEMENTS










SELECT a.AuthorID, concat(a.FirstName,' ' ,a.LastName) AS Author, b.Title
FROM Authors a
LEFT JOIN BooksAuthor ab ON (a.AuthorID = ab.AuthorID)
LEFT JOIN Books b ON (b.BookID = ab.BookID)
FOR XML AUTO
