--Создание таблицы клиентов
CREATE TABLE clients
(
    ID       INTEGER generated always as identity,
    fname    VARCHAR2(30) NOT NULL,
    CONSTRAINT fname
        CHECK (fname = initcap(fname)),
    lname    VARCHAR2(30) NOT NULL,
    CONSTRAINT lname
        CHECK (lname = initcap(lname)),
    phoneNum CHAR(17),
    CONSTRAINT ch_phoneNum_clients
        CHECK (REGEXP_LIKE(phoneNum, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
    CONSTRAINT uni_phoneNum_clients UNIQUE (phoneNum)
);

--Создание таблицы поставщиков
CREATE TABLE providers
(
    ID         INTEGER generated always as identity,
    nameComp   VARCHAR2(50)  NOT NULL,
    adressComp VARCHAR2(100) NOT NULL,
    phoneNum   CHAR(17),
    CONSTRAINT ch_phoneNum_providers
        CHECK (REGEXP_LIKE(phoneNum, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
    CONSTRAINT uni_phoneNum_providers UNIQUE (phoneNum)
);

--Создание таблицы материалов
CREATE TABLE materials
(
    ID          INTEGER generated always as identity,
    nameMat     VARCHAR2(50)      NOT NULL,
    CONSTRAINT nameMat
        CHECK (nameMat = initcap(nameMat)),
    quantityMat Number(16, 9) NOT NULL,
    providerID  INTEGER       NOT NULL
);

--Создание таблицы продуктов
CREATE TABLE products
(
    ID         INTEGER generated always as identity,
    nameProd   VARCHAR2(50)  NOT NULL,
    length     NUMBER(16, 9) NOT NULL,
    width      NUMBER(16, 9) NOT NULL,
    height     NUMBER(16, 9) NOT NULL,
    unitCost   NUMBER(10, 2) NOT NULL,
    productVol NUMBER(16, 9) NOT NULL,
    materialID INTEGER       NOT NULL
);

--Создание таблицы продаж
CREATE TABLE sales
(
    ID           INTEGER generated always as identity,
    saleDate     DATE DEFAULT SYSDATE,
    productID    INTEGER       NOT NULL,
    clientID     INTEGER       NOT NULL,
    quantityProd INTEGER       NOT NULL,
    saleVol      NUMBER(16, 9) NOT NULL,
    saleAmount   NUMBER(10, 2) NOT NULL
);

--Создание первичных ключей
ALTER TABLE clients
    ADD CONSTRAINT ID_client
        PRIMARY KEY (ID)
    nocache;

ALTER TABLE providers
    ADD CONSTRAINT ID_provider
        PRIMARY KEY (ID)
    nocache;

ALTER TABLE products
    ADD CONSTRAINT ID_product
        PRIMARY KEY (ID)
    nocache;

ALTER TABLE materials
    ADD CONSTRAINT ID_material
        PRIMARY KEY (ID)
    nocache;

ALTER TABLE sales
    ADD CONSTRAINT ID_sale
        PRIMARY KEY (ID)
    nocache;

--Создание внешних ключей
ALTER TABLE sales
    ADD CONSTRAINT client_ID
        FOREIGN KEY (clientID)
            REFERENCES clients (ID);

ALTER TABLE sales
    ADD CONSTRAINT product_ID
        FOREIGN KEY (productID)
            REFERENCES products (ID);

ALTER TABLE products
    ADD CONSTRAINT material_ID
        FOREIGN KEY (materialID)
            REFERENCES materials (ID);

ALTER TABLE materials
    ADD CONSTRAINT provider_ID
        FOREIGN KEY (providerID)
            REFERENCES providers (ID);

--Trigger(product_volume)
--Trigger(is_unuseable_date)

--Создание архива реализованных изделий ранее текущего месяца
CREATE TABLE archive_products
(
    ID         INTEGER generated always as identity,
    nameProd   VARCHAR2(50)  NOT NULL,
    length     NUMBER(16, 9) NOT NULL,
    width      NUMBER(16, 9) NOT NULL,
    height     NUMBER(16, 9) NOT NULL,
    unitCost   NUMBER(10, 2) NOT NULL,
    productVol NUMBER(16, 9) NOT NULL,
    nameMat    VARCHAR2(50)  NOT NULL,
    CONSTRAINT nameMaterial
        CHECK (nameMat = initcap(nameMat))
);

ALTER TABLE  archive_products
    ADD CONSTRAINT ID_archive_products
        PRIMARY KEY (ID)
    nocache;

--Создание таблицы отложенных продаж.
CREATE TABLE deferred_sales
(
    ID           INTEGER generated always as identity,
    saleDate     DATE DEFAULT SYSDATE,
    productID    INTEGER       NOT NULL,
    clientID     INTEGER       NOT NULL,
    quantityProd INTEGER       NOT NULL,
    saleVol      NUMBER(16, 9) NOT NULL,
    saleAmount   NUMBER(10, 2) NOT NULL
);

ALTER TABLE deferred_sales
    ADD CONSTRAINT ID_sales
        PRIMARY KEY (ID)
    nocache;

ALTER TABLE deferred_sales
    ADD CONSTRAINT def_ID_client
        FOREIGN KEY (clientID)
            REFERENCES clients (ID);

ALTER TABLE deferred_sales
    ADD CONSTRAINT def_ID_product
        FOREIGN KEY (productID)
            REFERENCES products (ID);

--Создание таблицы LOG1.
CREATE TABLE LOG1
(
    ID              INTEGER generated always as identity,
    nameUser        VARCHAR2(70),
    dataChange_time TIMESTAMP,
    dataChange_name CHAR(6),
    nameColumn      VARCHAR2(30),
    oldValue        VARCHAR2(50),
    newValue        VARCHAR2(50)
);

ALTER TABLE LOG1
    ADD CONSTRAINT ID_LOG1
        PRIMARY KEY (ID)
    nocache;

--Создание таблицы LOG2.
CREATE TABLE LOG2
(
    ID              INTEGER generated always as identity,
    nameUser        VARCHAR2(70),
    dataChange_time TIMESTAMP,
    dataChange_name VARCHAR2(6),
    nameTable      VARCHAR2(30)
);

ALTER TABLE LOG2
    ADD CONSTRAINT ID_LOG2
        PRIMARY KEY (ID)
    nocache;

--Создание таблицы LOG3.
CREATE TABLE LOG3
(
    ID           INTEGER generated always as identity,
    nameUser     VARCHAR2(70),
    LOGtype_time TIMESTAMP,
    LOGtype_name VARCHAR2(20),
    quantityRows NUMBER
);

ALTER TABLE LOG3
    ADD CONSTRAINT ID_LOG3
        PRIMARY KEY (ID)
    nocache;