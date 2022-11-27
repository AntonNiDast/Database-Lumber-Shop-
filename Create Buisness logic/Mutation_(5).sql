--При увеличении стоймости продукции, увеличить стоймость продукции из того же материала но такой же процент.
--Триггер с мутацией
CREATE OR REPLACE TRIGGER unitCost_edit
BEFORE UPDATE OF unitCost
ON products
FOR EACH ROW
DECLARE
    procent NUMBER;
    max_unitCost NUMBER;
BEGIN
    SELECT unitCost INTO max_unitCost
    FROM products
    WHERE unitCost >= ALL(SELECT unitCost
                          FROM products);
    IF :new.unitCost > :old.unitCost AND :old.unitCost = max_unitCost
    THEN
        procent := :new.unitCost / :old.unitCost;
        UPDATE products
        SET unitCost = ROUND(unitCost * procent, 2)
        WHERE ID != :old.ID;
    END IF;
END unitCost_edit;

--способ избежания мутации
CREATE OR REPLACE TRIGGER unitCost_edit_comp
FOR UPDATE OF unitCost
ON products
COMPOUND TRIGGER
    procent NUMBER;
    return_true NUMBER;
    max_unitCost NUMBER;
    ID_prod INTEGER;

    BEFORE STATEMENT IS
        BEGIN
            SELECT max(unitCost) INTO max_unitCost
            FROM products;
    END BEFORE STATEMENT;

    BEFORE EACH ROW IS
        BEGIN
            IF :old.unitCost = max_unitCost AND :new.unitCost > :old.unitCost
            THEN
                BEGIN
                    ID_prod := :old.ID;
                    procent := :new.unitCost / :old.unitCost;
                    return_true := 1;
                END;
            END IF;
    END BEFORE EACH ROW;

    AFTER STATEMENT IS
    BEGIN
        IF return_true = 1 
        THEN
            UPDATE products
            SET unitCost = ROUND(unitCost * procent, 2)
            WHERE ID != ID_prod;
        END IF;
    END AFTER STATEMENT;
END unitCost_edit_comp;
