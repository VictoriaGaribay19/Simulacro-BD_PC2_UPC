--Funciones
--El gerente de Northwind quiere saber los productos m�s vendidos en la empresa. Los productos m�s vendidos, 
--son aquellos que durante una fecha ingresada se hayan solicitado en m�s de 18 �rdenes. Para ello debes crear una funci�n que liste:
--Del producto: Nombre del Producto, cantidad por unidad, Precio Unitario, Descuento y la cantidad en stock actual
--La funci�n recibe el periodo de operaci�n, expresada en una fecha inicial y final. Vale decir, que la funci�n 
--recibe dos fechas como par�metro.

CREATE FUNCTION P1SIM(@fini date , @ffin date) RETURNS TABLE
AS
RETURN (SELECT P.ProductName,
P.QuantityPerUnit,
P.UnitPrice,
AVG(OD.Discount) "PROMEDIO",
P.UnitsInStock
FROM [Order Details] OD INNER JOIN Orders O ON OD.OrderID = O.OrderID
INNER JOIN Products P ON P.ProductID = OD.ProductID
WHERE O.OrderDate BETWEEN @fini AND @ffin
GROUP BY P.ProductName,
P.QuantityPerUnit,
P.UnitPrice,
P.UnitsInStock
HAVING COUNT(DISTINCT OD.OrderID) > 18)


SELECT *
FROM P1SIM('1997-01-01','1998-01-01')


--Procedimientos
--Modifique mediante script la tabla Customers y agregue un campo de nombre Premium (bit)
--Realice una sentencia Update que coloque en el campo Premium reci�n creado el valor 1 y 
--solo a los clientes cuya cantidad de �rdenes compradas haya superado el promedio de �rdenes compradas,
--esta parte debe ser desarrollada con nn Stored procedure

ALTER TABLE Customers ADD PREMIUM BIT

SELECT * FROM Customers

UPDATE Customers set PREMIUM = 0

--OBTENEMOS CUANTAS ORDENES HA COMPRADO CADA CLIENTE

SELECT O.CustomerID,
COUNT(DISTINCT O.OrderID) "ORDENES"
FROM Orders O
GROUP BY O.CustomerID

--OBTENEMOS EL PROMEDIO POR CLIENTE

SELECT AVG(OPC.ORDENES)
FROM(SELECT O.CustomerID,
COUNT(DISTINCT O.OrderID) "ORDENES"
FROM Orders O
GROUP BY O.CustomerID) OPC

--FILTRAMOS A TODOS LOS QUE COMPRARON MAS QUE EL PROMEDIO



CREATE VIEW CLIENTES_PREM AS 
SELECT O.CustomerID
FROM Orders O
GROUP BY O.CustomerID
HAVING COUNT(DISTINCT O.OrderID) > (SELECT AVG(OPC.ORDENES)
FROM(SELECT O.CustomerID,
COUNT(DISTINCT O.OrderID) "ORDENES"
FROM Orders O
GROUP BY O.CustomerID) OPC)

UPDATE Customers SET PREMIUM = 1 FROM CLIENTES_PREM CP WHERE CP.CustomerID = Customers.CustomerID

SELECT * FROM Customers


CREATE PROCEDURE P2_SIM
AS
UPDATE Customers SET PREMIUM = 1 FROM CLIENTES_PREM CP WHERE CP.CustomerID = Customers.CustomerID


--Views

--El gerente de ventas de Northwind desea saber c�mo son las ventas (monto) d�a por d�a en el mes que m�s se vendi� y 
--en el mes que menos se vendi� en un determinado a�o. Debe mostrar en un procedimiento el d�a, el a�o, el mes, 
--el monto de ventas del mes que m�s se vendi� y el monto de venta del mes que menos se vendi�.

CREATE VIEW VENT_ANHOMES AS
SELECT
YEAR(O.OrderDate) "ANHO",
MONTH(O.OrderDate) "MES",
SUM((OD.Quantity*OD.UnitPrice)*(1-OD.Discount)) "MONTO_VENTA"
FROM Orders O INNER JOIN [Order Details] OD ON O.OrderID = OD.OrderId
GROUP BY
YEAR(O.OrderDate),
MONTH(O.OrderDate)

SELECT MAX(VAM.MONTO_VENTA)
FROM VENT_ANHOMES VAM

--ANHOMES QUE MAS SE VENDIO
SELECT 
VAM.ANHO,
VAM.MES
FROM VENT_ANHOMES VAM
WHERE VAM.MONTO_VENTA >=(SELECT MAX(VAM.MONTO_VENTA)
FROM VENT_ANHOMES VAM)

--ANHOMES QUE MENOS SE VENDIO

SELECT 
VAM.ANHO,
VAM.MES
FROM VENT_ANHOMES VAM
WHERE VAM.MONTO_VENTA<=(SELECT MIN(VAM.MONTO_VENTA)
FROM VENT_ANHOMES VAM)

--GUARDARE EL ANHOMES MAYOR Y EL MENOR


CREATE VIEW ANHOMESMM AS
SELECT 
VAM.ANHO,
VAM.MES
FROM VENT_ANHOMES VAM
WHERE VAM.MONTO_VENTA >=(SELECT MAX(VAM.MONTO_VENTA)
FROM VENT_ANHOMES VAM)
UNION
SELECT 
VAM.ANHO,
VAM.MES
FROM VENT_ANHOMES VAM
WHERE VAM.MONTO_VENTA<=(SELECT MIN(VAM.MONTO_VENTA)
FROM VENT_ANHOMES VAM)



--CALCULEMOS EL MONTO DE VENTA DIA A DIA

SELECT
O.OrderDate,
SUM((OD.Quantity*OD.UnitPrice)*(1-OD.Discount)) "MONTO_VENTA"
FROM Orders O INNER JOIN [Order Details] OD ON O.OrderID = OD.OrderId,
ANHOMESMM AMM
WHERE AMM.ANHO = YEAR(O.OrderDate) AND AMM.MES =MONTH(O.OrderDate)
GROUP BY
O.OrderDate
ORDER BY 1 ASC


--Triggers

--El gerente general de Northwind conversa con la gerenta de CX que est� preocupada por los env�os que est�n 
--demorando mucho, sobre todo cuando los productos ser�n recibidos por el cliente en una fecha mayor o igual a 25 d�as. 
--Para ello, debe realizar lo siguiente:
--Crear una tabla llamada �tb_envios� con las siguientes columnas: CustomerID, ShippedDate, Dif_Dias INT,
--OrderDate, Dif_Semanas INT (para el resto de las columnas use los mismos tipos de datos de Northwind)
--Crear un trigger que permita insertar un registro en la tabla tb_envios cada vez que se actualice el 
--ShippedDate y la diferencia entre la fecha de la orden y la fecha de despacho sea mayor o igual a 8 d�as. 
--De esta manera Northwind podr� avisarle y disculparse con sus clientes que estar�n recibiendo sus productos una semana despu�s.

--CREACION DE LA TABLA CHECK

DROP TABLE tb_envios

CREATE TABLE tb_envios(
CustomerID nchar(5),
ShippedDate date,
Dif_Dias int,
OrderDate date,
Dif_Semanas int
)

CREATE TRIGGER TX_ORDER_DIF ON Orders
FOR UPDATE
AS
INSERT INTO tb_envios
SELECT I.CustomerId, 
I.ShippedDate,
DATEDIFF(DAY, I.ShippedDate, I.OrderDate),
I.OrderDate,
DATEDIFF(WEEK, I.ShippedDate, I.OrderDate)
FROM INSERTED I
WHERE DATEDIFF(DAY, I.ShippedDate, I.OrderDate) >=8