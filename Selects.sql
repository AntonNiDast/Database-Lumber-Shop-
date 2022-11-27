--Select
--Итоговый запрос: Вывести расход материалов за все время (название, объем израсходованного материала)
SELECT m.nameMat, sum(s.saleVol) as consumption_of_materials
FROM sales s
         JOIN products p on p.ID = s.productID
         JOIN materials m on m.ID = p.materialID
GROUP BY nameMat;

--Условный запрос: Вывести реализованные изделия за последнюю неделю (Имя, фамилию клиента; название, количество изделия; сумму, дату продажи)
SELECT c.fname || ' ' || c.lname as fname_lname, p.nameProd, s.saleAmount, s.saleDate, s.quantityProd
FROM sales s
         JOIN clients c on c.ID = s.clientID
         JOIN products p on p.ID = s.productID
WHERE sysdate - s.saleDate <= 7
  and sysdate - s.saleDate >= 0;

--Параметрический запрос: Вывести проданные изделия изготовленные из заданной породы древесины (Дата, объем количество продажи; название продукции; название материала; имя, фамилия, телефон клиента)
SELECT s.saleDate,
       s.saleVol,
       s.saleAmount,
       p.nameProd,
       m.nameMat,
       c.fname,
       c.lname,
       c.phoneNum
FROM sales s
         JOIN clients c on c.ID = s.clientID
         JOIN products p on p.ID = s.productID
         JOIN materials m on m.ID = p.materialID
WHERE m.nameMat in (:v_nameMat);

--Перекрестный запрос: Вывести суммы продаж товаров по неделям текущего месяца (Название продукции; Первая, вторая, третья, четвертая неделя текущего месяца)
SELECT p.nameProd,
       SUM(CASE WHEN to_char(s.saleDate, 'w') = '1' THEN s.saleAmount END) AS First_Week,
       SUM(CASE WHEN to_char(s.saleDate, 'w') = '2' THEN s.saleAmount END) AS Second_Week,
       SUM(CASE WHEN to_char(s.saleDate, 'w') = '3' THEN s.saleAmount END) AS Third_Week,
       SUM(CASE WHEN to_char(s.saleDate, 'w') = '4' THEN s.saleAmount END) AS Fourth_Week,
       SUM(CASE WHEN to_char(s.saleDate, 'w') = '5' THEN s.saleAmount END) AS Fifth_Week
FROM products p
         JOIN sales s on s.productID = p.ID
WHERE to_char(s.saleDate, 'mm') = to_char(sysdate, 'mm')
GROUP BY p.nameProd;


--Запрос на объединение: Вывести общий список изделий и сырья с указанием количества по каждой позиции (Название; Количество)
SELECT p.nameProd AS Name, SUM(s.quantityProd) AS Quantity
FROM products p
         JOIN sales s on s.productID = p.ID
GROUP BY p.nameprod
UNION
SELECT nameMat, SUM(quantityMat)
FROM materials m
GROUP BY nameMAt;

--Запросы индивидуальные
--С внутренним соединением таблиц:
--Вывести количество закзов по месецам текущего года по каждому из клиентов
SELECT c.fname || ' ' || c.lname                                       as fname_lname,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '01' THEN s.ID END) AS January,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '02' THEN s.ID END) AS February,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '03' THEN s.ID END) AS March,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '04' THEN s.ID END) AS April,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '05' THEN s.ID END) AS May,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '06' THEN s.ID END) AS June,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '07' THEN s.ID END) AS July,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '08' THEN s.ID END) AS August,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '09' THEN s.ID END) AS September,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '10' THEN s.ID END) AS October,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '11' THEN s.ID END) AS November,
       COUNT(CASE WHEN to_char(s.saleDate, 'MM') = '12' THEN s.ID END) AS December
FROM sales s
         JOIN clients c on c.ID = s.clientID
WHERE to_char(s.saleDate, 'yyyy') = to_char(sysdate, 'yyyy')
GROUP BY c.fname || ' ' || c.lname;

--С внешним соединением таблиц:
--Вывести дату и сумму заказа, количество заказанной продукции для всей продукции
--Использование предиканта IN с подзапросом
SELECT s.saleDate, s.quantityProd, s.saleAmount, p.nameProd
FROM sales s
         RIGHT JOIN products p on p.ID = s.productID
WHERE p.nameProd IN (SELECT nameProd FROM products);

--Вывести дату и сумму заказа, количество заказанной продукции для продукции, сделанной из заданного материала
--Использование предиканта IN и ANY с подзапросом
SELECT s.saleDate, s.quantityProd, s.saleAmount, p.nameProd
FROM sales s
         RIGHT JOIN products p on p.ID = s.productID
WHERE p.nameProd IN (SELECT nameProd
                     FROM products p1
                              JOIN materials m1 on m1.ID = p1.materialID
                     WHERE m1.nameMat = ANY (:v_nameMat));


--Вывести продуцию с самой большой прибылью
--Использование предиканта ANY/ALL с подзапросом
SELECT SUM(s.quantityProd), SUM(s.saleAmount), p.nameProd
FROM sales s
         RIGHT JOIN products p on p.ID = s.productID
WHERE p.nameProd IN (SELECT nameProd FROM products)
GROUP BY p.nameProd
HAVING SUM(s.saleAmount) >= ALL (SELECT SUM(s1.saleAmount)
                                 FROM sales s1
                                          JOIN products p1 on p1.ID = s1.productID
                                 GROUP BY p1.nameProd)

--Вывести продукцию с прибылью больше заданной
--Использование предиканта ANY/ALL с подзапросом
SELECT SUM(s.quantityProd), SUM(s.saleAmount), p.nameProd
FROM sales s
         RIGHT JOIN products p on p.ID = s.productID
WHERE p.nameProd IN (SELECT nameProd FROM products)
GROUP BY p.nameProd
HAVING SUM(s.saleAmount) >= ANY (SELECT SUM(s1.saleAmount)
                                 FROM sales s1
                                          JOIN products p1 on p1.ID = s1.productID
                                 WHERE s1.saleAmount >= :v_saleAmount
                                 GROUP BY p1.nameProd)

--Вывести название продукции, которая ни разу не продовалась
--Использование предиканта NOT EXISTS/EXISTS с подзапросом
SELECT s.saleDate, s.quantityProd, s.saleAmount, p.nameProd
FROM sales s
         RIGHT JOIN products p on p.ID = s.productID
WHERE NOT EXISTS(SELECT 1 FROM products WHERE p.ID = s.productID);

--Изменить стоймость продукции сделанной из Дуба на 10%, а из Ели на 20%
--Обновление строк с помощью оператора UPDATE
UPDATE products
SET unitCost = (CASE
                  WHEN products.ID IN (SELECT p.ID
                             FROM materials m
                                      JOIN products p on m.ID = p.materialID
                             WHERE m.nameMat = 'Дуб') THEN unitCost * 1.1
                  WHEN products.ID IN (SELECT p.ID
                             FROM materials m
                                      JOIN products p on m.ID = p.materialID
                             WHERE m.nameMat = 'Ель') THEN unitCost * 1.2
                  ELSE unitCost END)

--Вывести данные о клиенте и сумму кол-ва их покупок при условии, что он купил больше изделий из ели, чем из пихты
SELECT c.fname || ' ' || c.lname        as fname_lname,
       COUNT(s.ID)                      as Kolvo_pokypok,
       SUM(CASE
               WHEN NOT EXISTS(SELECT 1 FROM products WHERE p.ID = s.productID and m.nameMat IN ('Ель')) THEN 0
               ElSE s.QUANTITYPROD END) as spruceProd,
       SUM(CASE
               WHEN NOT EXISTS(SELECT 1 FROM products WHERE p.ID = s.productID and m.nameMat IN ('Пихта')) THEN 0
               ElSE s.QUANTITYPROD END) as firProd
FROM clients c
         JOIN sales s on c.ID = s.clientID
         JOIN products p on p.ID = s.productID
         JOIN materials m on m.ID = p.materialID
GROUP BY c.fname || ' ' || c.lname
HAVING SUM(CASE
               WHEN NOT EXISTS(SELECT 1
                               FROM products
                               WHERE p.ID = s.productID
                                 and m.nameMat IN ('Ель'))
                   THEN 0
               ElSE s.QUANTITYPROD END) > SUM(CASE
                                                  WHEN NOT EXISTS(SELECT 1
                                                                  FROM products
                                                                  WHERE p.ID = s.productID
                                                                    and m.nameMat IN ('Пихта'))
                                                      THEN 0
                                                  ElSE s.QUANTITYPROD END);