--Создать процедуру, переносящую в архив информацию о товарах, которые реализованы ранее текущего месяца. Архив должен содержать не значения ключей, а реальные названия изделий и сырья.
CREATE OR REPLACE PROCEDURE archive_prod
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
END;

--Написать функцию, которая возвращает пустую строку или строку «Сырье в недостатке», если заданный товар возможно произвести только меньше 10 единиц, а также выводит перечень товаров с количеством его возможного производства.
CREATE OR REPLACE FUNCTION proizvodstvo_prod(product_ID IN NUMBER) RETURN VARCHAR2
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
END;

BEGIN
    DBMS_OUTPUT.PUT_LINE('Итог: '|| proizvodstvo_prod(5));
END;
