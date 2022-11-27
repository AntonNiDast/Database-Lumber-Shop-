CREATE OR REPLACE PROCEDURE analysis_product(product_name products.nameProd%TYPE)
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
END;
