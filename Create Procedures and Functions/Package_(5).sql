CREATE OR REPLACE PACKAGE arhive AS
    PROCEDURE archive_prod;
    FUNCTION proizvodstvo_prod(product_ID IN NUMBER) RETURN VARCHAR2;
    PROCEDURE proizv_prod;
    PROCEDURE analysis_product(product_name products.nameProd%TYPE);
END arhive;

CREATE OR REPLACE PACKAGE BODY arhive AS

PROCEDURE archive_prod
IS
    CURSOR relasied_prod IS
        SELECT p.nameProd, p.length, p.width, p.height, p.unitCost, p.productVol, m.nameMat
        FROM products p JOIN materials m ON m.ID=p.materialID
        WHERE p.nameProd IN (SELECT p.nameProd
                             FROM sales s JOIN products p ON p.ID=s.productID JOIN materials m ON m.ID=p.materialID
                             WHERE EXISTS(SELECT 1
                                          FROM sales s
                                          WHERE p.ID=s.productID)
                                   AND to_char(s.saledate,'yy.mm')<to_char(sysdate,'yy.mm')
                             GROUP BY p.nameProd);
output_rows relasied_prod%ROWTYPE;
BEGIN
    DELETE FROM archive_products;
    OPEN relasied_prod;
    LOOP
        FETCH relasied_prod INTO output_rows;
        EXIT WHEN relasied_prod%NOTFOUND;
                DBMS_OUTPUT.PUT_LINE('Product: '||output_rows.nameProd ||', Length: '||output_rows.length ||', Width: '||output_rows.width ||', Height: '||output_rows.height ||', Unit cost: '||output_rows.unitCost ||', Product volume: '||output_rows.productVol ||', Material: '||output_rows.nameMat);
                INSERT INTO archive_products (nameProd, length, width, height, unitCost, productVol, nameMat)
                VALUES (output_rows.nameProd, output_rows.length, output_rows.width, output_rows.height, output_rows.unitCost, output_rows.productVol, output_rows.nameMat);
        END LOOP;
        CLOSE relasied_prod;
END archive_prod;

FUNCTION proizvodstvo_prod(product_ID IN NUMBER) RETURN VARCHAR2
IS
    enough_mat EXCEPTION;
    CURSOR quantity_prod IS
        SELECT FLOOR(m.quantityMat/p.productVol) as quantity
        FROM products p JOIN materials m ON m.ID=p.materialID
        WHERE p.ID=product_ID;
quantity_out quantity_prod%ROWTYPE;
BEGIN
    OPEN quantity_prod;
    FETCH quantity_prod INTO quantity_out;
    IF quantity_out.quantity<=10
    THEN CLOSE quantity_prod;
    ELSE RAISE enough_mat;
    END IF;
    RETURN (quantity_out.quantity ||' - '|| 'Сырье в недостатке');
EXCEPTION
    WHEN enough_mat
    THEN RETURN quantity_out.quantity;
END proizvodstvo_prod;

PROCEDURE proizv_prod
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
END proizv_prod;

PROCEDURE analysis_product(product_name products.nameProd%TYPE)
IS
    no_info EXCEPTION;

    CURSOR prod_cur IS
        SELECT p.nameProd, p.productVol, m.nameMat, m.quantityMat, COUNT(s.id) AS quantity_sale
        FROM products p JOIN materials m ON m.ID=p.materialID left JOIN sales s ON p.ID=s.productID
        WHERE p.nameProd = product_name
        GROUP BY p.nameProd, p.productVol, m.nameMat, m.quantityMat;
    prod_out prod_cur%ROWTYPE;

    FUNCTION signal(product_volume products.productVol%TYPE, quantity_material materials.quantityMat%TYPE) RETURN VARCHAR2 
    IS
    BEGIN
        IF FLOOR(quantity_material/product_volume)<=10
        THEN
            RETURN 'Недостаток';
        ELSE
            RETURN '';
        END IF;
    END;

    PROCEDURE analysis(signalization IN VARCHAR2)
    IS
    BEGIN
        IF signalization = 'Недостаток'
        THEN
            DBMS_OUTPUT.PUT_LINE('Сырье для производства данного продукта в недостатке');
        END IF;
    END;

    PROCEDURE analysis(quantity_sales IN INTEGER)
    IS
    no_sales EXCEPTION;
    BEGIN
        IF quantity_sales = 0
        THEN
            RAISE no_sales;
        END IF;
        EXCEPTION
            WHEN no_sales
            THEN
                DBMS_OUTPUT.PUT_LINE('Данный продукт еще не был реализован в продажу');
    END;

BEGIN
    OPEN prod_cur;
    FETCH prod_cur INTO prod_out;
    IF prod_cur%FOUND
    THEN
        CLOSE prod_cur;
    ELSE
        RAISE no_info;
    END IF;

    analysis(prod_out.quantity_sale);
    analysis(signal(prod_out.productVol, prod_out.quantityMat));

    EXCEPTION
    WHEN no_info
    THEN
        DBMS_OUTPUT.PUT_LINE('Данного продукта нет в базе');
END analysis_product;

END arhive;