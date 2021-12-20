USE AdventureWorks2019;
GO

-- View Server Name
SELECT @@SERVERNAME
GO

-- View Total number of tables in AdventureWorks2019 database
SELECT COUNT(*) FROM sys.tables --'sys.tables' returns a row for each user table in SQL Server.
GO

/* CREATE FACT AND DIMENSION TABLES TO CREATE A STAR SCHEMA */

--#########################################
--CREATE FACT TABLE FOR ADVENTUREWORKS DB
CREATE VIEW FactSales AS
SELECT S.OrderDate,
	SD.SalesOrderID,
	S.CustomerID,
	S.SalesPersonID,
	ST.TerritoryID,
	SD.ProductID,
	PC.ProductCategoryID,
	PSC.ProductSubcategoryID,
	SD.OrderQty,
	SD.UnitPrice,
	SD.UnitPriceDiscount,
	SD.LineTotal, -- (Per product subtotal.) Computed as UnitPrice * (1 - UnitPriceDiscount) *OrderQty.
	PP.StandardCost, --Standard cost of the product.
	SD.LineTotal-PP.StandardCost AS GrossMargin
FROM Sales.SalesOrderHeader as S
INNER JOIN Sales.SalesTerritory as ST ON ST.TerritoryID = S.TerritoryID
INNER JOIN Sales.Customer AS SC ON SC.CustomerID = S.CustomerID 
INNER JOIN Sales.SalesOrderDetail as SD ON S.SalesOrderID = SD.SalesOrderID
INNER JOIN Production.Product AS PP ON PP.ProductID = SD.ProductID
INNER JOIN [Production].[ProductSubcategory] AS PSC ON PSC.ProductSubcategoryID = PP.ProductSubcategoryID
INNER JOIN [Production].[ProductCategory]  AS PC ON PC.ProductCategoryID = PSC.ProductCategoryID
GO

--#########################################
--DIM TABLE PRODUCT
CREATE VIEW DimProduct AS
SELECT PP.ProductID
	,PP.Name AS Product_Name
	,PP.Color
	,PP.Size
	,PP.Weight
	,PP.Style
	,PP.ListPrice
	,PP.StandardCost
	,PP.ListPrice - PP.StandardCost AS Expected_Margin
FROM Production.Product AS PP
INNER JOIN [Production].[ProductSubcategory] AS PSC  
ON PSC.ProductSubcategoryID = PP.ProductSubcategoryID
INNER JOIN [Production].[ProductCategory]  AS PC   
ON PC.ProductCategoryID = PSC.ProductCategoryID
GROUP BY PP.ProductID
	,PP.Name
	,PP.Color
	,PP.Size
	,PP.Weight
	,PP.Style
	,PP.ListPrice
	,PP.StandardCost
	,PP.ListPrice -PP.StandardCost
GO

--#########################################
--DIM TABLE PRODUCT CATEGORY
CREATE VIEW DimProductCategory AS
SELECT 
	 PC.ProductCategoryID
	,PC.Name AS ProductCategoryName	
FROM [Production].[ProductCategory]  AS PC 
GO

--#########################################
--DIMENSION TABLE PRODUCT SUBCATEGORY
CREATE VIEW DimProductSubCategory AS
SELECT 
	 PSC.ProductSubcategoryID 	
	,PSC.Name AS ProductSubcategoryName
FROM [Production].[ProductSubcategory] AS PSC
GO

--#########################################
--DIM TABLE SALES PERSON
CREATE VIEW DimSalesPerson AS
 SELECT PPER.FirstName + ' '+ PPER.LastName AS FullName
	,HE.BirthDate
	,HE.Gender
	,SSP.*	
FROM Person.Person AS PPER
INNER JOIN Sales.SalesPerson AS SSP
ON PPER.BusinessEntityID =  SSP.BusinessEntityID 
INNER JOIN HumanResources.Employee AS HE
ON PPER.BusinessEntityID = HE.BusinessEntityID
GO

--#########################################
--DIM TABLE TERRITORY
CREATE VIEW DimTerritory AS
SELECT ST.*
	,PCR.Name AS CountryName
FROM Sales.SalesTerritory as ST
INNER JOIN Person.CountryRegion AS PCR
ON ST.CountryRegionCode =PCR.CountryRegionCode
GO
--#########################################
--DIM TABLE CUSTOMER
/*
SELECT  DISTINCT  SC.CustomerID
	,PPER.FirstName +' '+PPER.LastName AS Full_Name	
	,ST.TerritoryID
	,PCR.Name AS CountryName
	,PPER.PersonType
FROM Sales.Customer AS SC
INNER JOIN Sales.SalesTerritory AS ST
ON ST.TerritoryID = SC.TerritoryID
INNER JOIN Person.CountryRegion AS PCR
ON ST.CountryRegionCode =PCR.CountryRegionCode
LEFT JOIN Person.Person AS PPER
ON SC.PersonID = PPER.BusinessEntityID
GO
*/
CREATE VIEW DimCustomer AS
SELECT DISTINCT SC.CustomerID
	,PPER.PersonType
	,PPER.FirstName +' '+PPER.LastName AS Full_Name	
	,PA.AddressLine1
	,PA.PostalCode
	,PA.City
	,ST.TerritoryID
	,PCR.Name AS CountryName
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN Person.Address AS PA
ON PA.AddressID = SOH.BillToAddressID
INNER JOIN Sales.Customer AS SC
ON SOH.CustomerID = SC.CustomerID 
INNER JOIN Sales.SalesTerritory AS ST
ON ST.TerritoryID = SC.TerritoryID 
INNER JOIN Person.CountryRegion AS PCR
ON ST.CountryRegionCode =PCR.CountryRegionCode
LEFT JOIN Person.Person AS PPER
ON SC.PersonID = PPER.BusinessEntityID 
INNER JOIN Sales.Store AS SST
ON 	SC.StoreID =SST.BusinessEntityID
GO

--#########################################
--DIM TABLE STORE
CREATE VIEW DimStore AS
SELECT distinct ST.SalesPersonID
,ST.BusinessEntityID
,ST.Name
FROM Sales.Store AS ST
GO




