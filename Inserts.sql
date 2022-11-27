--Clients
INSERT INTO CLIENTS (fname, lname, phoneNum)
values ('Антон', 'Герасимович', '+375(29)221-11-71');
INSERT INTO CLIENTS (fname, lname, phoneNum)
values ('Илья', 'Хомяков', '+375(29)221-22-71');
INSERT INTO CLIENTS (fname, lname, phoneNum)
values ('Артем', 'Снитко', '+375(29)221-33-71');
INSERT INTO CLIENTS (fname, lname, phoneNum)
values ('Никита', 'Шыбеко', '+375(29)221-44-71');
INSERT INTO CLIENTS (fname, lname, phoneNum)
values ('Кирилл', 'Драцевич', '+375(29)221-55-71');

--Providers
INSERT INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('Древобел', 'г. Минск, ул. Сурганова, д.12', '+375(29)221-56-71');
INSERT INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('BenzoKosilka', 'г. Слоним, ул. Пугачевская, д.13', '+375(29)221-56-23');
INSERT INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('БелОргДрев', 'г. Минск, ул. Дугачевская, д.10', '+375(29)221-56-13');
INSERT INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('ЗеленыйБор', 'г. Брест, ул. Заславская, д.13', '+375(29)221-56-34');
INSERT INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('БелДрев', 'г. Кричев, ул. Гуганская, д.5', '+375(29)224-42-23');
INSERT INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('БрестДревоОрг', 'г. Брест, ул. Пушкинская, д.5', '+375(29)212-42-23');

--Insert all
INSERT ALL
    INTO CLIENTS (fname, lname, phoneNum)
values ('Егор', 'Ковалевский', '+375(29)531-11-71')
INTO PROVIDERS (NAMECOMP, ADRESSCOMP, PHONENUM)
values ('Пинскдрев', 'г. Пинск, ул. Кровельная, д.12', '+375(29)552-13-61')
SELECT *
FROM DUAL;

--Materials
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Береза', 46, 4);
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Дуб', 25, 2);
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Осина', 12, 3);
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Сосна', 30, 1);
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Ель', 15, 5);
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Пихта', 2, 3);
INSERT INTO MATERIALS (nameMat, quantityMat, providerID)
values ('Кедр', 10, 6);

--Products
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Вагонка 27.5x30x200', 2, 0.275, 0.3, 5.20, 1);
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Доска пола 25x4x300', 3, 0.25, 0.04, 12.50, 7);
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Блок-хаус 25x5x350', 3.5, 25, 0.05, 11.75, 3);
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Брус 25x25x200', 2, 0.25, 0.25, 3.00, 4);
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Мебельный щит 25x2x120', 1.2, 0.25, 0.02, 12.50, 5);
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Плинтус 150x4x125', 1.25, 1.50, 0.04, 2.50, 6);
INSERT INTO PRODUCTS (nameProd, length, width, height, unitCost, materialID)
values ('Мебельный щит 30x2x240', 2.4, 0.30, 0.02, 17.5, 5);

--Sales
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('21.09.2022', 'dd.mm.yy'), 1, 1, 20);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('22.09.2022', 'dd.mm.yy'), 6, 2, 10);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('19.09.2022', 'dd.mm.yy'), 5, 3, 20);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('17.09.2022', 'dd.mm.yy'), 7, 4, 10);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('20.09.2022', 'dd.mm.yy'), 6, 5, 20);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('30.09.2022', 'dd.mm.yy'), 3, 4, 10);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('29.09.2022', 'dd.mm.yy'), 4, 5, 20);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('01.10.2022', 'dd.mm.yy'), 1, 1, 40);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('10.10.2022', 'dd.mm.yy'), 6, 2, 20);
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('13.10.2022', 'dd.mm.yy'), 6, 2, 20);