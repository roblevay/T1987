--Ta fram de 10 dyraste produkterna
--i bokstavsordning
USE AdventureWorks
SELECT TOP 10
	name,ListPrice
FROM
	Production.Product
ORDER BY
	ListPrice DESC

--Smartaste sättet är en Common Table Expression CTE
WITH prickigkorv(namn,pris) AS(--Tabelluttryck
SELECT TOP 10--inre frågan
	name,ListPrice
FROM
	Production.Product
ORDER BY
	ListPrice DESC)
SELECT * FROM prickigkorv ORDER BY namn;
GO
--Stapla cte
--Smartaste sättet är en Common Table Expression CTE
WITH Kunder AS
(SELECT * FROM Sales.Customer)
,Ordrar AS (SELECT * FROM Sales.SalesOrderHeader)
SELECT * FROM Kunder INNER JOIN Ordrar
ON Kunder.CustomerID=Ordrar.CustomerID;
