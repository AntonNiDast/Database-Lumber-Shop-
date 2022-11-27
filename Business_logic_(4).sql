--1.Контролировать расход материалов.
--Реализовать ценовую политику при продаже изделий в зависимости от их количества, рассчитывать общие стоимость и объем продажи с учетом количества, стоимости и объема затрачиваемого сырья товара.
--2.Контролировать расход материалов.
--При недостаточном количестве сырья сохранять информацию о несостоявшейся продаже во вспомогательной таблице deferred_sales(Отложенная продажа).
--Процелура: Заполнение таблицы deferred_sales(Отложенная продажа), на основе входных данных.
CREATE OR REPLACE PROCEDURE insert_deferred_sale(def_saleDate IN DATE, def_productID IN INTEGER, def_clientID IN INTEGER, def_quantityProd IN INTEGER, def_saleVol IN NUMBER, def_saleAmount IN NUMBER)
IS
PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    INSERT INTO deferred_sales (saleDate, productID, clientID, quantityProd, saleVol, saleAmount)
    VALUES (def_saleDate, def_productID, def_clientID, def_quantityProd, def_saleVol, def_saleAmount);
    COMMIT;
END;

--Триггер: при создании заказа в таблице sales(Продажи) автоматически высчитывать поля saleAmount(Общая стоймость продажи), saleVol(Общий объем продажи)
--на основе данных о стоймости, объеме, количестве продаваемого товара.
--Если объем продажи превышает объем сырья на складе, записать заказ в таблицу deferred_sales(Отложенная продажа)
--и отменить запись в таблицу sales(Продажи), выведя ошибку: Недостаточно сырья. Данные заказ перенаправлен в таблицу "Отложенные продажи".
--Если объем продажи не превышает объем сырья на складе, позволить создать заказ.
CREATE OR REPLACE TRIGGER control_materials
BEFORE INSERT
ON sales
FOR EACH ROW
DECLARE
    CURSOR material_cur IS
        SELECT m.quantityMat, m.ID, p.unitCost, p.productVol
        FROM materials m JOIN products p ON m.ID=p.materialID
        WHERE p.ID=:new.productID;
    material_out material_cur%ROWTYPE;
    diff NUMBER(16,9);
BEGIN
    OPEN material_cur;
    FETCH material_cur into material_out;
    IF material_cur%FOUND
    THEN
        CLOSE material_cur;
    END IF;

    :new.saleVol := :new.quantityProd * material_out.productVol;
    :new.saleAmount := :new.quantityProd * material_out.unitCost;

    IF (:new.saleVol > material_out.quantityMat) THEN
        insert_deferred_sale(:new.saleDate, :new.productID, :new.clientID, :new.quantityProd, :new.saleVol, :new.saleAmount);
        RAISE_APPLICATION_ERROR(
            num=> -20008,
            msg=> 'Недостаточно сырья. Данные заказ перенаправлен в таблицу "Отложенные продажи"');
    ELSE
        diff := material_out.quantityMat - :new.saleVol;
        UPDATE materials
        SET quantityMat = diff
        WHERE ID = material_out.ID;
    END IF;
END control_materials;

--Проверка выполнения триггера.
INSERT INTO SALES (saleDate, productID, clientID, quantityProd)
values (to_date('17.10.2022', 'dd.mm.yy'), 6, 5, 20);

--Триггер: при обновлении количества продукции в заказе, не позволяет увеличить, если недостаточно сырья.
--Также запрещает изменение продукции в заказе и выдает сообщение: Изменение продукта не позволительно. Удалите заказ и создайте заново.
CREATE OR REPLACE TRIGGER update_quantityProd_sales
BEFORE UPDATE
ON sales
FOR EACH ROW
DECLARE
    CURSOR material_cur IS
        SELECT m.quantityMat, m.ID, p.unitCost, p.productVol
        FROM materials m JOIN products p ON m.ID=p.materialID
        WHERE p.ID=:old.productID;
    material_out material_cur%ROWTYPE;
    diff NUMBER(16,9);
BEGIN
    IF UPDATING('productID')
    THEN
        RAISE_APPLICATION_ERROR(
            num=> -20014,
            msg=> 'Изменение продукта не позволительно. Можете удалить заказ и создать заново.');
    ELSIF UPDATING('quantityProd')
    THEN
        OPEN material_cur;
        FETCH material_cur into material_out;
        IF material_cur%FOUND
        THEN
            CLOSE material_cur;
        END IF;

        :new.saleVol := :new.quantityProd * material_out.productVol;
        :new.saleAmount := :new.quantityProd * material_out.unitCost;

        IF (:new.saleVol - :old.saleVol > material_out.quantityMat) THEN
            RAISE_APPLICATION_ERROR(
                num=> -20012,
                msg=> 'Недостаточно сырья для увеличения числа продукции.');
        ELSE
            diff := material_out.quantityMat - (:new.saleVol - :old.saleVol);
            UPDATE materials
            SET quantityMat = diff
            WHERE ID = material_out.ID;
        END IF;
    END IF;
END update_quantityProd_sales;

--Триггер: при удалении заказа, возвращает материал на склад для производства нужного количества продукции.
CREATE OR REPLACE TRIGGER delete_sales
BEFORE DELETE
ON sales
FOR EACH ROW
DECLARE
    CURSOR material_cur IS
        SELECT m.quantityMat, m.ID
        FROM materials m JOIN products p ON m.ID=p.materialID
        WHERE p.ID=:old.productID;
    material_out material_cur%ROWTYPE;
    diff NUMBER(16,9);
BEGIN
    CASE
    WHEN DELETING THEN
        OPEN material_cur;
        FETCH material_cur into material_out;
        IF material_cur%FOUND
        THEN
            CLOSE material_cur;
        END IF;
        DBMS_OUTPUT.PUT_LINE('Заказ: '|| :old.ID || ' - отменен');
        diff := material_out.quantityMat + :old.saleVol;
        UPDATE materials
        SET quantityMat = diff
        WHERE ID = material_out.ID;
    END CASE;
END delete_sales;

--3.Контроль отложенных продаж.
--Автоматически пополнять наличие сырья на определенное количество раз в неделю и проверять возможность выполнения отложенных продаж.

--Планировщик задач: Автоматически раз в неделю выполняет процедуру пополнения сырья на скалде.
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name => 'multiple_scheduler',
        job_type => 'STORED_PROCEDURE',
        job_action => 'deferred_sales_into_sales',
        repeat_interval => 'FREQ=MINUTELY; INTERVAL=7',
        enabled => true
    );
END;

--Процедура: пополняет наличие сырья в зависимости от количества их на складе:
--Если сырья меньше 15 ед. - недостаток на складе, тогда пополнить на 25 ед.
--Если сырья от 15 до 30 ед. - оптимально на складе, тогда пополнить на 10 ед.
--Если сырья больше 30 ед. - избыток сырья на складе, тогда не пополнять.
--После пополнения сырья, проводит проверку возможностси реализации отложенных продаж.
--Если продажа возможно, то перемещает ее в таблицу sales.
CREATE OR REPLACE PROCEDURE deferred_sales_into_sales
IS
    CURSOR def_sale_cur IS
        SELECT ID
        FROM deferred_sales;
    def_sale_out def_sale_cur%ROWTYPE;

    PROCEDURE replenishment_of_materials
    IS
        PRAGMA AUTONOMOUS_TRANSACTION;

        CURSOR materials_cur IS
            SELECT ID, nameMat, quantityMat
            FROM materials;
        materials_out materials_cur%ROWTYPE;

        FUNCTION signal(quantity_material IN materials.quantityMat%TYPE) RETURN VARCHAR2
        IS
        BEGIN
            IF quantity_material < 15
            THEN
            RETURN 'Недостаток';
            ELSIF quantity_material BETWEEN 15 AND 30
            THEN
                RETURN 'Оптимально';
            ELSE
                RETURN 'Избыток';
            END IF;
        END;

        PROCEDURE analysis(signalization IN VARCHAR2, material_ID IN INTEGER)
        IS
        PRAGMA AUTONOMOUS_TRANSACTION;
        BEGIN
            IF signalization = 'Недостаток'
            THEN
                UPDATE materials
                SET quantityMat= quantityMat + 25
                WHERE ID = material_ID;
                COMMIT;
            ELSIF signalization = 'Оптимально'
            THEN
                UPDATE materials
                SET quantityMat= quantityMat + 10
                WHERE ID = material_ID;
                COMMIT;
            ELSIF signalization = 'Избыток'
            THEN
                UPDATE materials
                SET quantityMat= quantityMat
                WHERE ID = material_ID;
                COMMIT;    
            END IF;
        END;

    BEGIN
        OPEN materials_cur;
        LOOP
            FETCH materials_cur INTO materials_out;
            EXIT WHEN materials_cur%NOTFOUND;
                analysis(signal(materials_out.quantityMat), materials_out.ID);
                COMMIT;
            END LOOP;
            CLOSE materials_cur;
    END;

    PROCEDURE def_into_sale(ID_def IN INTEGER)
    IS
        CURSOR def_cur IS
        SELECT d.ID, d.saleDate, d.productID, d.clientID, d.quantityProd, d.saleVol, m.quantityMat
        FROM deferred_sales d JOIN products p ON p.ID=d.productID JOIN materials m ON m.ID=p.materialID
        WHERE d.ID = ID_def;
        def_out def_cur%ROWTYPE;
        PRAGMA AUTONOMOUS_TRANSACTION;
    BEGIN
        OPEN def_cur;
        FETCH def_cur INTO def_out;
        IF def_cur%FOUND THEN
            CLOSE def_cur;
        END IF;
        IF def_out.saleVol < def_out.quantityMat THEN
            INSERT INTO sales(saleDate, productID, clientID, quantityProd)
            VALUES (def_out.saleDate, def_out.productID, def_out.clientID, def_out.quantityProd);
            COMMIT;
            DELETE deferred_sales
            WHERE ID = ID_def;
            COMMIT;
        END IF;
    END;

BEGIN
    replenishment_of_materials;

    OPEN def_sale_cur;
    LOOP
        FETCH def_sale_cur INTO def_sale_out;
        EXIT WHEN def_sale_cur%NOTFOUND;
            def_into_sale(def_sale_out.ID);
    END LOOP;
    CLOSE def_sale_cur;
END;
