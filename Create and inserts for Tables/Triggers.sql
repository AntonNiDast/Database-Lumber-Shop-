--Вычисляемое поле
create or replace trigger product_volume
    before insert or update of length, width, height
    on products
    for each row
begin
    :new.productVol := :new.length * :new.width * :new.height;
end product_volume;

--Неверная дата
create or replace trigger is_unuseable_date
    before insert or update of saleDate
    on sales
    for each row
begin
    IF ((to_date(:new.saleDate)) > sysdate)
    THEN
        RAISE_APPLICATION_ERROR(
                -20000,
                'Invalid sale date: Сhange the date of sale'
            );
    END IF;
end is_unuseable_date;

--Вычисляемое поле
create or replace trigger sale_volume_amount1
    after update
    on products
    for each row
DECLARE
    unit_Cost NUMBER(10, 2);
    prod_Vol  NUMBER(16, 9);
    prod_ID   INTEGER;
begin
    unit_Cost := :new.unitCost;
    prod_vol := :new.productVol;
    prod_ID := :old.ID;
    update sales
    set saleAmount = quantityProd * unit_Cost,
        saleVol    = quantityProd * prod_vol
    where productId = prod_ID;
end sale_volume_amount1;