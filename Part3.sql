--Create Tables--
create table Addresses(
Address VARCHAR(50) Not Null primary key,
--lookup table for countries to help the user find the address
)

create table Customers(
EmailAddress Varchar(50) Not Null PRIMARY KEY,
FirstName Varchar(20) Not Null,
LastName Varchar(20) Not Null,
PhoneNumber VARCHAR(13)Not Null,
Country varchar(20) not null,
CONSTRAINT	ck_EmailAddress CHECK (EmailAddress LIKE '%@%.%'),
constraint CK_phoneNumber CHECK (PhoneNumber LIKE '%[0-9]%')
--The first constraint checks for '@' and '.'
--The second constraint checks all digits as numbers
)


CREATE TABLE Products (
   ProductID INT  not null PRIMARY KEY,
   ProductName VARCHAR(50) not null,
   Description VARCHAR(100),
   Price money,
   StockLevel VARCHAR(3),
   constraint CK_Price CHECK (Price > 0 ),
   constraint CK_StockLevel CHECK (StockLevel IN ('yes','no'))
   --The first constrain checks for price bigger than 0
   --The second constraint checks for "yes" or "no" answer
)

CREATE TABLE Searches (
   SearchIP INT not null,
   SearchDT DATETime not null,
   SearchQuery VARCHAR(50),
   EmailAddress Varchar(50),
   constraint CK_Search primary key(SearchIP,SearchDT),
   constraint fk_EmailAddre foreign key (EmailAddress) REFERENCES Customers(EmailAddress)
  
)


CREATE TABLE Shipments (
   ShipmentID INT not null PRIMARY KEY,
   ShipmentDT DATE not null,
   Driver VARCHAR(20),
   Address VARCHAR(50),
   CONSTRAINT fk_Address foreign key (Address) REFERENCES Addresses(Address)
)




CREATE TABLE CreditCards (
   CCNumber char(16) not null PRIMARY KEY,
   CCExpiration Varchar(5) not null,
   CCCVV CHAR(3)not null ,
   EmailAddress Varchar(50) Not Null,
   constraint fk_Customer foreign key (EmailAddress) references Customers(EmailAddress),
   constraint CK_CCNumber CHECK (CCNumber LIKE '%[0-9]%'),
   constraint CK_CCExpiration CHECK (CCExpiration LIKE '[0-9][0-9]/[0-9][0-9]'),
   constraint CK_CCCVV CHECK (CCCVV LIKE '%[0-9]%')
   --The first constraint checks for digits
   --The second constraint checks for valid date
   --The third constraint checks for digits
)

CREATE TABLE Orders (
   OrderID INT not null PRIMARY KEY,
   OrderDT DATE not null,
   Note VARCHAR(50),
   CCNumber char(16) not null,
   ShipmentID INT not null,
  constraint fk_CreditCards foreign key (CCNumber) REFERENCES CreditCards(CCNumber),
  constraint fk_Shipment foreign key (ShipmentID) REFERENCES Shipments(ShipmentID),
)



CREATE TABLE Ratings (
   EmailAddress VARCHAR(50) not null,
   ProductID INT not null,
   Rank INT,
   RatingDate DATE,
   Comment VARCHAR(100),
   constraint Pk_Rating PRIMARY KEY (EmailAddress, ProductID),
   constraint fk_Email foreign key (EmailAddress) REFERENCES Customers(EmailAddress),
   constraint fk_Product foreign key (ProductID) REFERENCES Products(ProductID),
   constraint Ck_Rank check (Rank  between 0 and 5),
   --The constrains checks for rank between 0 and 5
)

create table Including (
ProductID INT not null,
OrderID INT not null,
constraint Pk_Includes PRIMARY KEY (OrderID, ProductID),
constraint fk_Order foreign key (OrderID) REFERENCES Orders(OrderID),
constraint fk_Product2 foreign key (ProductID) REFERENCES Products(ProductID),
)


create table Leading(
ProductID INT not null,
SearchIP INT not null,
SearchDT DATETime not null,
constraint Pk_Leads PRIMARY KEY (ProductID, SearchIP,SearchDT),
constraint fk_Search foreign key (SearchIP,SearchDT) REFERENCES Searches(SearchIP,SearchDT),
constraint fk_Product3 foreign key (ProductID) REFERENCES Products(ProductID),
)

--Drop Tables--
DROP TABLE Leading
DROP TABLE Including
DROP TABLE Ratings
DROP TABLE Orders
DROP TABLE CreditCards
DROP TABLE Shipments
DROP TABLE Searches
DROP TABLE Products
DROP TABLE Customers
DROP TABLE Addresses

--Assignment 1--

SELECT		C.EmailAddress, C.Country, Amount= count(P.ProductID), Total= SUM(P.Price)
FROM		Customers AS C join Ratings AS R on C.EmailAddress=R.EmailAddress  join Products AS P on R.ProductID=P.ProductID  
Where         R.Rank>3
GROUP BY	C.EmailAddress, C.Country 
HAVING        count(P.ProductID)>1
ORDER BY	3 DESC



SELECT	O.OrderID,I.ProductID , O.OrderDT ,S.Driver, S.Address
FROM		Orders AS O join Shipments AS S on O.ShipmentID= S.ShipmentID  join Including as I on O.OrderID=I.OrderID
Where         Year(O.OrderDT)=2022 
ORDER BY	3 



SELECT 	ProductID, ProductName, NewPrice= Price*0.9
FROM 		Products
WHERE	StockLevel in ('yes') and Price in ( 
			SELECT Price FROM Products group by Price having price>(select avg(price) from Products))
ORDER BY	3 DESC



SELECT 	Country,TOTAL_Customers_inSameCountry = count (*),proportion=  Cast(Count(*) as float)/Cast ((select count (*)  from Customers) as float)
 FROM 		Customers
 GROUP BY 	Country 		
 order by 2 Desc


ALTER TABLE Products DROP COLUMN AvgRank
ALTER TABLE Products ADD AvgRank int
UPDATE	Products
SET		AvgRank = (
                     SELECT        AVG(Rank) 
                     FROM           Ratings
                     WHERE        Ratings.ProductID=Products.ProductID)





    SELECT DISTINCT EmailAddress
    FROM Customers
    where EmailAddress IN (select EmailAddress 
	                       from Orders as O join CreditCards as Cr on O.CCNumber=Cr.CCNumber
						   join Including as I on O.OrderID=I .OrderID join Products as P on I.ProductID=P.ProductID 
						   group by EmailAddress
						   having (select AVG(price) from products )<SUM(price))

    Except

    SELECT DISTINCT EmailAddress
    FROM   Ratings
	

	
--Assignment 2--
	
 
Drop  VIEW View_ActiveCustomer	
CREATE VIEW View_ActiveCustomer AS
SELECT EmailAddress,O.OrderID
FROM  Orders as O join CreditCards as Cr on O.CCNumber=Cr.CCNumber join Including as I on O.OrderID=I .OrderID join Products as P on I.ProductID=P.ProductID 
where Cr.CCNumber  in (select CCNumber from Orders) and EmailAddress  in (select EmailAddress from Ratings) 
group by EmailAddress,O.OrderID

select distinct EmailAddress,Country=(select Country from Customers as C where C.EmailAddress=V.EmailAddress),TotalOrders=Count(V.OrderID)
from  View_ActiveCustomer as V
Group by EmailAddress
Having COUNT(V.OrderID)>5
Order by 3 DESC




Drop    FUNCTION RankOfPro
CREATE 	FUNCTION RankOfPro ( @ProName varchar(50))  
RETURNS	int
AS 	BEGIN
		DECLARE 	@Rankk	Int
		SELECT    @Rankk = AVG (Rank) 
		FROM	 Products as P join Ratings as R On P.ProductID  = R.ProductID 
		WHERE  	  P.ProductName = @ProName
		
		RETURN 	@Rankk
	END

select AVGRank = dbo.RankOfPro('Dumbbells')

SELECT	ProductID, ProductName, 
AVGRANK = dbo.RankOfPro (ProductName)
FROM		Products
ORDER BY 	ProductID




Drop  FUNCTION 	OrderDetails
CREATE 	FUNCTION 	OrderDetails ( @OrdID int )  
RETURNS 	TABLE
AS 	RETURN
SELECT	OrderID , ProductName,Price
FROM	Products as P JOIN Including as I On P.ProductID = I.ProductID
where OrderID = @OrdID

	Select *
	from dbo.OrderDetails(1)




	Alter table Customers Drop column LastSale 
	Alter table Customers Add LastSale Date
Create TRIGGER update_lastsale
ON Orders
for INSERT
AS
    UPDATE Customers
    SET LastSale = i.OrderDT
    FROM Customers AS C
    JOIN inserted AS i ON C.EmailAddress = (SELECT EmailAddress FROM CreditCards WHERE CCNumber = i.CCNumber)
	
	Delete from Orders where OrderID=999
	insert into   Orders values  (999,'7/7/2024','',2354439204744388,2)






	Drop PROCEDURE SP_valuableProducts
	CREATE PROCEDURE SP_valuableProducts 	@rank int
AS
	SELECT 	P.ProductID, ProductName,AVGRANK=AVG(Rank) 
	FROM 	Ratings as	R join Products as P On R.ProductID = P.ProductID
	Group by P.ProductID, ProductName
	having AVG (Rank) >= @rank
	order by AVG (Rank) 
	EXECUTE SP_valuableProducts  4




	--Assignment 3--


	-- Average ratings by product--
	DROP VIEW AverageRatingsByProduct
	CREATE VIEW AverageRatingsByProduct AS
SELECT p.ProductName, AVG(r.Rank) AS AverageRating
FROM Products as p
JOIN Ratings as r ON p.ProductID = r.ProductID
GROUP BY p.ProductName


--Total sales with rating by product--
Drop   VIEW TotalSalesByProduct
create VIEW TotalSalesByProduct AS
SELECT  p.ProductName, COUNT(*) AS TotalSales
FROM Products as p
JOIN Including as i ON p.ProductID = i.ProductID
where i.productID in  (select productID from ratings)
GROUP BY p.ProductName



--Total sales by month--
Drop   VIEW MonthlySales
CREATE VIEW MonthlySales AS
SELECT SalesMonth, TotalSales
FROM (
    SELECT FORMAT(OrderDT, 'yyyy-MM') AS SalesMonth, COUNT(*) AS TotalSales
    FROM Orders
    GROUP BY FORMAT(OrderDT, 'yyyy-MM')
) AS Subquery


--Total revenue by product--
Drop   VIEW TotalRevenueByProduct
CREATE VIEW TotalRevenueByProduct AS
SELECT p.ProductName, SUM(p.Price) AS TotalRevenue
FROM Products p
JOIN Including i ON p.ProductID = i.ProductID
GROUP BY  p.ProductName


--revenue by country--
Drop   VIEW RevenueByCountry
CREATE VIEW RevenueByCountry AS
SELECT C.Country, SUM(P.Price) AS TotalRevenue
FROM Customers AS C
JOIN CreditCards AS Cr ON C.EmailAddress = Cr.EmailAddress
JOIN Orders AS O ON Cr.CCNumber = O.CCNumber
JOIN Including AS I ON O.OrderID = I.OrderID
JOIN Products AS P ON I.ProductID = P.ProductID
GROUP BY C.Country



--Avg searches per hour--
Drop   VIEW SearchesPerHour
CREATE VIEW SearchesPerHour AS
SELECT DATEPART(HOUR, SearchDT) AS SearchHour, COUNT(*) AS TotalSearches
FROM Searches
GROUP BY DATEPART(HOUR, SearchDT)



--num of products in stock--
Drop   VIEW ProductsInStock
CREATE VIEW ProductsInStock AS
SELECT
    SUM(CASE WHEN StockLevel = 'yes' THEN 1 ELSE 0 END) AS ProductsInStock,
    SUM(CASE WHEN StockLevel = 'no' THEN 1 ELSE 0 END) AS ProductsOutOfStock
FROM Products


--top 10 products based on total revenue--
Drop    VIEW Top10ProductsByRevenue
CREATE VIEW Top10ProductsByRevenue AS
SELECT TOP 10 p.ProductName, COUNT(*) AS TotalSales,
   p.Price * COUNT(*) AS Revenue
FROM Products as p
JOIN Including i ON p.ProductID = i.ProductID
GROUP BY  p.ProductName, p.Price
ORDER BY Revenue DESC



--products without sales and without stock--
Drop   VIEW ProductsWithoutSales
CREATE VIEW ProductsWithoutSales AS
SELECT p.ProductName, p.Price
FROM Products as p
LEFT JOIN Including i ON p.ProductID = i.ProductID
WHERE i.ProductID IS NULL and  p.StockLevel = 'no'







	--Assignment 4--

Select OrderID , ProductName , Price, Rank = Rank( ) over(Partition by OrderID order by Price desc ),
	          SalePrice = Sum(Price) over (partition by OrderID order by Price desc rows between UNBOUNDED preceding 
	and current row)
	from Products as P JOIN Including as I On P.ProductID = I.ProductID
	




	SELECT   S.ShipmentID, S.ShipmentDT, S.Driver,
    DriverTotalShipment = COUNT(*) OVER (PARTITION BY Driver),
    ShipmentNumber=ROW_NUMBER() OVER (PARTITION BY Driver ORDER BY ShipmentDT ),
	ShipmentDateGap = DATEDIFF(day, LAG(S.ShipmentDT) OVER (PARTITION BY Driver ORDER BY ShipmentDT), ShipmentDT),
	TotalOrders=COUNT(O.OrderID)
    FROM Shipments as S join Orders as O on S.ShipmentID=O.ShipmentID
    group by S.ShipmentID, S.ShipmentDT, S.Driver
    order by Driver




	Drop FUNCTION IS_CC_VAILD
	Create FUNCTION IS_CC_VAILD (@ExpMonth Varchar(5) ,@ExpYear Varchar(5))
	RETURNS VarChar(8) AS 
		BEGIN
				IF @ExpYear < substring(cast(YEAR(getdate()) as varchar(5)),3,2) OR (@ExpYear =  substring(cast(YEAR(getdate()) as varchar(5)),3,2) AND @ExpMonth < MONTH(GETDATE()))
			RETURN 'NotValid'
			RETURN 'Valid'
		END

Drop 	PROCEDURE RemoveinValidCC	
Create PROCEDURE RemoveinValidCC (@ExpirationMonth Varchar(5), @ExpirationYear Varchar(5))
	AS DECLARE @IsVaild varCHAR(8)
	BEGIN	
	SET @IsVaild = dbo.IS_CC_VAILD(@ExpirationMonth, @ExpirationYear)
	IF @IsVaild = 'NotValid'
	DELETE FROM dbo.CreditCards WHERE CCExpiration= @ExpirationMonth + '/' + @ExpirationYear
	END

	
Drop TRIGGER UpdateCreditCards
Create TRIGGER UpdateCreditCards
	ON dbo.CreditCards
	FOR INSERT AS 
	DECLARE @ExpM Varchar(5)
	DECLARE @ExpY Varchar(5)
	BEGIN
	SELECT @ExpM = SUBSTRING(CCExpiration,1,2) , @ExpY =SUBSTRING(CCExpiration,4,2)   FROM inserted
	EXECUTE dbo.RemoveinValidCC @ExpM, @ExpY 
	END


INSERT INTO CreditCards  VALUES ('2000400050001000', '03/22', 444, 'ALF8108@gmail.com')

Delete from CreditCards where CCNumber='2000411115000100'
INSERT INTO CreditCards  VALUES ('2000411115000100','10/24', 777,'ALF8108@gmail.com' )






WITH TopCountries AS (
    SELECT C.Country, COUNT(DISTINCT O.OrderID) AS TotalOrdersForCountry, SUM(P.Price) AS PurchasesAmountForCountry
    FROM
       Customers AS C
        JOIN CreditCards AS CC ON C.EmailAddress = CC.EmailAddress
        JOIN Orders AS O ON CC.CCNumber = O.CCNumber
        JOIN Including AS I ON O.OrderID = I.OrderID
        JOIN Products AS P ON I.ProductID = P.ProductID
    GROUP BY C.Country
	Having COUNT(DISTINCT O.OrderID)> 40
),
TopCustomers AS (
    SELECT  C.EmailAddress, CustomerName =  C.FirstName + ' ' + C.LastName,	C.Country,
        COUNT(DISTINCT O.OrderID) AS TotalOrdersForCust,
        SUM(P.Price) AS CustomerTotalSpent
    FROM
        Customers AS C
        JOIN CreditCards AS CC ON C.EmailAddress = CC.EmailAddress
        JOIN Orders AS O ON CC.CCNumber = O.CCNumber
        JOIN Including AS I ON O.OrderID = I.OrderID
        JOIN Products AS P ON I.ProductID = P.ProductID
    GROUP BY  C.EmailAddress, C.FirstName, C.LastName,C.Country
    HAVING   COUNT(DISTINCT O.OrderID) >= 3 and SUM(P.Price)> 5000
		
),
PopularProducts AS (
    SELECT  P.ProductID,  P.ProductName,  COUNT(I.OrderID) AS TotalOrdersForPro
    FROM
        Products AS P
        JOIN Including AS I ON P.ProductID = I.ProductID
    GROUP BY P.ProductID, P.ProductName
    having  COUNT(I.OrderID)>2
    
),
HighRatedProducts AS (
    SELECT   P.ProductID,R.EmailAddress, Rank AS HighRank
    FROM
        Products AS P
        JOIN Ratings AS R ON P.ProductID = R.ProductID
		where Rank > 3 
    GROUP BY  P.ProductID,R.EmailAddress,Rank
    
)
SELECT
    TP.Country,
    TP.TotalOrdersForCountry,
    TP.PurchasesAmountForCountry,
    TC.CustomerName,
    TC.TotalOrdersForCust,
    TC.CustomerTotalSpent,
    PP.ProductName,
    PP.TotalOrdersForPro,
    HR.HighRank
FROM
    TopCountries AS TP
    JOIN TopCustomers AS TC ON TP.Country = TC.Country
    JOIN HighRatedProducts AS HR ON TC.EmailAddress = HR.EmailAddress
     JOIN PopularProducts AS PP ON HR.ProductID = PP.ProductID
ORDER BY
    TP.Country


