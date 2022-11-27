-- Горизонтальное обновляемое представление
CREATE OR REPLACE VIEW saleAm_gorz AS
select *
from sales
where saleAmount >= 100
WITH CHECK OPTION CONSTRAINT cons_saleAm_gorz;

-- Вертикальное обновляемое представление
CREATE OR REPLACE VIEW saleAm_vert AS
select saleDate, productID, quantityProd, saleAmount
from sales
WITH CHECK OPTION CONSTRAINT cons_saleAm_vert;

-- Смешаное необновляемое представление
CREATE OR REPLACE VIEW materials_providers AS
SELECT m.nameMat, m.quantityMat, p.nameComp
FROM materials m
         right JOIN providers p on p.ID = m.providerID
WHERE m.quantityMat <= 30
  and m.quantityMat >= 0;

-- Создание обновляемого представления с ограничением работы по времени и дню недели
create or replace view client as
select *
from clients
where (to_number(to_char(CURRENT_DATE, 'D')) between 2 and 6)
      and (to_number(to_char(CURRENT_TIMESTAMP, 'HH24')) between 9 and 17)
with check option;
