CREATE OR REPLACE PROCEDURE proizv_prod
IS
    CURSOR prod_cur IS
        SELECT p.nameProd, p.productVol, m.nameMat, m.quantityMat
        FROM products p JOIN materials m ON m.ID=p.materialID;
    prod_out prod_cur%ROWTYPE;

    FUNCTION quant_prod(product_volume products.productVol%TYPE, quantity_material materials.quantityMat%TYPE) RETURN INTEGER 
    IS
    BEGIN
        RETURN FLOOR(quantity_material/product_volume);
    END;

    FUNCTION material_out(quantity IN INTEGER) RETURN VARCHAR2
    IS
    BEGIN
        IF quantity<=10
        THEN 
            RETURN 'Сырье в недостатке';
        ELSE
            RETURN '';
        END IF;
    END;

BEGIN
    OPEN prod_cur;
    LOOP
        FETCH prod_cur INTO prod_out;
        EXIT WHEN prod_cur%NOTFOUND;
                DBMS_OUTPUT.PUT_LINE('Product: '||prod_out.nameProd ||', Material: '||prod_out.nameMat ||', Quantity: '||quant_prod(prod_out.productVol, prod_out.quantityMat) ||', Storage: '||material_out(quant_prod(prod_out.productVol, prod_out.quantityMat)));
        END LOOP;
        CLOSE prod_cur;
END;