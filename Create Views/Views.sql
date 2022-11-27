-- Горизонтальное обновляемое представление
CREATE OR REPLACE VIEW saleAm_gorz AS
select *
from sales
where saleAmount >= 100
WITH CHECK OPTION CONSTRAINT cons_saleAm_gorz;

-- Проверка возможности выполнения dml команд
-- insert
insert into saleAm_gorz (saleDate, productID, clientID, quantityProd)
values (to_date('01.10.2022', 'dd.mm.yy'), 6, 2, 20);
-- Возможно вставить строку в данное представление, т.к. все поля с ограничением NOT NULL родительской таблицы присутствуют во View

-- update
update saleAm_gorz
set saleDate = to_date('03.09.2022', 'dd.mm.yy')
where ID = 21;
-- Выполнение данной команды возможно, т.к. изменяется не ключевое поле, все связанные с этой таблицей данные не пострадают

-- delete
delete from saleAm_gorz
where ID = 21;
-- Выполнение команды возможно, т.к. данная таблица не является родительской не для какой из таблиц

-- Вертикальное обновляемое представление
CREATE OR REPLACE VIEW saleAm_vert AS
select saleDate, productID, quantityProd, saleAmount
from sales
WITH CHECK OPTION CONSTRAINT cons_saleAm_vert;

-- Проверка возможности выполнения dml команд
-- insert
insert into saleAm_vert (saleDate, productID, quantityProd, saleAmount)
values (to_date('01.10.2022', 'dd.mm.yy'), 6, 20, 250);
-- Невозможно вставить строку в данное представление, т.к. не все поля с ограничением NOT NULL родительской таблицы присутствуют во View

-- update
update saleAm_vert
set saleDate = to_date('11.10.2022', 'dd.mm.yy')
where saleDate = to_date('06.10.2022', 'dd.mm.yy');
-- Выполнение данной команды возможно, т.к. изменяется не ключевое поле, все связанные с этой таблицей данные не пострадают

-- delete
delete from saleAm_vert
where saleDate = to_date('11.10.2022', 'dd.mm.yy');
-- Выполнение команды возможно, т.к. данная таблица не является родительской не для какой из таблиц

-- Смешаное необновляемое представление
CREATE OR REPLACE VIEW materials_providers AS
SELECT m.nameMat, m.quantityMat, p.nameComp
FROM materials m
         right JOIN providers p on p.ID = m.providerID
WHERE m.quantityMat <= 30
  and m.quantityMat >= 0;

-- Проверим работу dml команд
-- insert
insert into materials_providers(nameMat, quantityMat, nameComp)
values ('Пень', 15, 'BenzoKosilka');
-- Операцию выполнить невозможно, т.к. представление необновляемое и связывает данные нескольких таблиц, в которых находятся не затроннутые данные представлением

-- update
update materials_providers
set nameComp='Кастер';
-- Операция не выполнилась, т.к. поле не будет удовлетворять условию  представления

-- delete
delete from materials_providers
where nameComp='Кастер';
-- Операция выполнилась

-- Создание обновляемого представления с ограничением работы по времени и дню недели
create or replace view client as
select *
from clients
where (to_number(to_char(CURRENT_DATE, 'D')) between 2 and 6)
      and (to_number(to_char(CURRENT_TIMESTAMP, 'HH24')) between 9 and 17)
with check option;

-- Проверим работу dml команд
-- insert
insert into client (fname, lname, phoneNum) values ('Илья', 'Магамедов', '+375(29)222-33-74');

-- update
update client
    set lname = 'Мухаджан'
    where lname = 'Магамедов';

-- delete
delete from client
where lname = 'Мухаджан';

select (to_number(to_char(CURRENT_TIMESTAMP, 'HH24'))), (to_number(to_char(CURRENT_DATE, 'D'))) from dual;
alter session Set TIME_ZONE='+03:00';