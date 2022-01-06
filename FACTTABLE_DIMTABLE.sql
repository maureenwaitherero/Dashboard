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
SELECT SD.SalesOrderID,
	S.OrderDate,
	S.ShipDate,
	S.ShipMethodID,	
	S.CustomerID,
	S.SalesPersonID,
	ST.TerritoryID,
	SD.ProductID,
	SD.SpecialOfferID,
	PC.ProductCategoryID,
	PSC.ProductSubcategoryID,
	SD.OrderQty,
	SD.UnitPrice,
	SD.UnitPriceDiscount,
	S.Freight,
	S.TaxAmt,
	PP.StandardCost,
	SD.LineTotal, -- (Per product subtotal.) Computed as UnitPrice * (1 - UnitPriceDiscount) *OrderQty.
	PP.StandardCost * OrderQty as TotalStandardCost, --Standard cost of the product.
	SD.LineTotal - (PP.StandardCost * OrderQty) as GrossProfit
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
SELECT DISTINCT PP.ProductID,
	 PC.ProductCategoryID ,
	 PP.ProductSubcategoryID,
	 PP.Name AS Product_Name,
	 PP.StandardCost,
	 PP.DaysToManufacture,
	 PP.ProductLine, --R = Road, M = Mountain, T = Touring, S = Standard
	 PP.Style, --W = Womens, M = Mens, U = Universal
	 PP.Color, --Product color
	 PP.Size, --Product size
	 PP.Class,
	 PP.Weight
FROM Production.Product AS PP
FULL JOIN [Production].[ProductSubcategory] AS PSC  ON PSC.ProductSubcategoryID = PP.ProductSubcategoryID
FULL JOIN Sales.SalesOrderDetail AS SD ON SD.ProductID = PP.ProductID
FULL JOIN [Production].[ProductCategory]  AS PC ON PC.ProductCategoryID = PSC.ProductCategoryID
FULL JOIN Production.ProductModel AS PPM ON PPM.ProductModelID = PP.ProductModelID
WHERE PP.ProductID IS NOT NULL
GROUP BY PP.ProductID,
	PP.Name,
	PP.Color,
	PP.Size,
	PP.Weight,
	PP.Style,
	PP.StandardCost,
	PP.DaysToManufacture,
	PP.Class,
	PPM.ProductModelID,
	PP.ProductLine,
	PPM.Name,
	PC.ProductCategoryID,
	PC.ProductCategoryID ,
	PP.ProductSubcategoryID
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
	 PSC.ProductSubcategoryID, 	
	 PSC.Name AS ProductSubcategoryName
FROM [Production].[ProductSubcategory] AS PSC
GO

--#########################################
--DIM TABLE SALES PERSON
CREATE VIEW DimSalesPerson AS
SELECT 	SSP.BusinessEntityID as SalesPersonID,
	PPER.FirstName + ' '+ PPER.LastName AS FullName,
	HE.BirthDate,
	HE.Gender,
	HE.JobTitle,
	HE.MaritalStatus,
	HE.OrganizationLevel,
	HE.SickLeaveHours,
	HE.VacationHours,
	SSP.TerritoryID,
	SSP.SalesQuota,
	SSP.SalesYTD,
	SSP.Bonus,
	SSP.CommissionPct,
	SSP.SalesLastYear
FROM Person.Person AS PPER
INNER JOIN Sales.SalesPerson AS SSP ON PPER.BusinessEntityID =  SSP.BusinessEntityID 
INNER JOIN HumanResources.Employee AS HE ON PPER.BusinessEntityID = HE.BusinessEntityID
GO

--#########################################
--DIM TABLE TERRITORY
CREATE VIEW DimTerritory AS
SELECT ST.*	
FROM Sales.SalesTerritory as ST 
GO

CREATE VIEW DimStateProvinceTerritory AS
SELECT *
FROM Person.StateProvince
GO

--#########################################
--DIM TABLE CUSTOMER

CREATE VIEW DimCustomer AS
SELECT DISTINCT PPER.BusinessEntityID,
	SC.CustomerID,
	SC.PersonID,
	SC.StoreID,
	SC.TerritoryID,
	PA.StateProvinceID,
	PPER.PersonType, 
	PPER.FirstName +' '+PPER.LastName AS Full_Name,	
	PPER.Suffix,
	PPER.Title,		
	PA.AddressLine1,
	PA.AddressLine2,
	PA.PostalCode,
	PA.City
FROM Sales.SalesOrderHeader AS SOH
INNER JOIN Person.Address AS PA ON PA.AddressID = SOH.BillToAddressID
INNER JOIN Sales.Customer AS SC ON SOH.CustomerID = SC.CustomerID 
INNER JOIN Sales.SalesTerritory AS ST ON ST.TerritoryID = SC.TerritoryID 
INNER JOIN Person.CountryRegion AS PCR ON ST.CountryRegionCode =PCR.CountryRegionCode
INNER JOIN Person.StateProvince AS PSP ON PSP.CountryRegionCode = PCR.CountryRegionCode
LEFT JOIN Person.Person AS PPER ON SC.PersonID = PPER.BusinessEntityID
GO

--#########################################
--DIM TABLE STORE
CREATE VIEW DimStore AS
SELECT distinct ST.SalesPersonID,
	ST.BusinessEntityID,
	ST.Name
FROM Sales.Store AS ST
GO


--#########################################
--DIM TABLE HUMAN RESOURCE
CREATE VIEW DimEmployee AS
SELECT
	Employee.BusinessEntityID,
	PPER.FirstName +' '+PPER.LastName AS Full_Name,
	JobTitle,
	BirthDate,
	HireDate,
	DepartmentHistory.StartDate,
	DepartmentHistory.EndDate,
	MaritalStatus,
	Gender,	
	SalariedFlag,
	VacationHours,
	SickLeaveHours,
	CurrentFlag,	
	DepartmentHistory.ShiftID,	
	HRshift.Name AS Shift,
	Department.Name	
FROM  HumanResources.Employee AS Employee 
INNER JOIN Person.Person AS PPER ON  PPER.BusinessEntityID = Employee.BusinessEntityID 
INNER JOIN HumanResources.EmployeeDepartmentHistory AS DepartmentHistory ON  DepartmentHistory.BusinessEntityID = Employee.BusinessEntityIDINNER JOIN HumanResources.Shift AS HRshift ON HRshift .ShiftID = DepartmentHistory.ShiftIDINNER JOIN HumanResources.Department AS Department ON Department.DepartmentID = DepartmentHistory.DepartmentIDGO


