--1.Написать DML-триггер, регистрирующий изменение данных (вставку, обновление, удаление) в таблице clients(Клиенты). 
--Во вспомогательную таблицу LOG1 записывать, кто, когда (дата и время) и какое именно изменение произвел, для одного из столбцов сохранять старые и новые значения.

--Процедура: Записывает какое изменение, когда  и для какого столбца произошло, а также старое и новое значение.
CREATE OR REPLACE PROCEDURE insert_LOG1(name_dataChange IN CHAR, columnName IN VARCHAR2, old_Value IN VARCHAR2, new_Value IN VARCHAR)
IS
    PRAGMA AUTONOMOUS_TRANSACTION;
BEGIN
    IF  name_dataChange IN ('INSERT', 'DELETE') OR (name_dataChange IN ('UPDATE') AND old_Value != new_Value)
    THEN
        INSERT INTO LOG1(nameUser, dataChange_time, dataChange_name, nameColumn, oldValue, newValue)
        VALUES (USER, CURRENT_TIMESTAMP, name_dataChange, columnName, old_Value, new_Value);
        COMMIT;
    END IF;
END;

--Триггер: 
CREATE OR REPLACE TRIGGER changes_on_clients_into_LOG1
AFTER UPDATE OR INSERT OR DELETE
ON clients
FOR EACH ROW
BEGIN
    CASE 
        WHEN INSERTING THEN
            insert_LOG1('INSERT', 'fname', NULL, :new.fname);
            insert_LOG1('INSERT', 'lname', NULL, :new.lname);
            insert_LOG1('INSERT', 'phoneNum', NULL, :new.phoneNum);
        WHEN DELETING THEN
            insert_LOG1('DELETE', 'fname', :old.fname, NULL);
            insert_LOG1('DELETE', 'lname', :old.lname, NULL);
            insert_LOG1('DELETE', 'phoneNum', :old.phoneNum, NULL);
        WHEN UPDATING('fname') OR UPDATING('lname') OR UPDATING('phoneNum') THEN
            insert_LOG1('UPDATE', 'fname', :old.fname, :new.fname);
            insert_LOG1('UPDATE', 'lname', :old.lname, :new.lname);
            insert_LOG1('UPDATE', 'phoneNum', :old.phoneNum, :new.phoneNum);
    END CASE;
END changes_on_clients_into_LOG1;

--2.Написать DDL-триггер, протоколирующий действия пользователей по созданию, изменению и удалению таблиц 
--в схеме во вспомогательную табли-цу LOG2 в определенное время и запрещающий эти действия в другое время.

--Триггер:
CREATE OR REPLACE TRIGGER changes_on_tables_into_LOG2
AFTER CREATE OR ALTER OR DROP
ON SCHEMA
BEGIN
    IF ORA_DICT_OBJ_TYPE = 'TABLE' THEN
        IF to_number(to_char(CURRENT_DATE, 'D')) BETWEEN 2 AND 6 THEN
            IF to_number(to_char(CURRENT_TIMESTAMP, 'HH24')) BETWEEN 8 AND 18 THEN
                BEGIN
                    CASE ORA_SYSEVENT
                        WHEN 'CREATE' THEN
                            INSERT INTO LOG2(nameTable, nameUser, dataChange_time, dataChange_name) 
                            VALUES (ORA_DICT_OBJ_NAME, USER, CURRENT_TIMESTAMP, 'CREATE');
                        WHEN 'ALTER' THEN
                            INSERT INTO LOG2(nameTable, nameUser, dataChange_time, dataChange_name) 
                            VALUES (ORA_DICT_OBJ_NAME, USER, CURRENT_TIMESTAMP, 'ALTER');
                        WHEN 'DROP' THEN
                            INSERT INTO LOG2(nameTable, nameUser, dataChange_time, dataChange_name) 
                            VALUES (ORA_DICT_OBJ_NAME, USER, CURRENT_TIMESTAMP, 'DROP');
                    END CASE;
                END;
            ELSE
                RAISE_APPLICATION_ERROR (
                num=> -20000,
                msg=> 'Невозможно испльзование DDL-команд в нерабочее время.');
            END IF;
        ELSE
            RAISE_APPLICATION_ERROR (
            num=> -20000,
            msg=> 'Невозможно испльзование DDL-команд во время выходных дней.');
        END IF;
    END IF;
END changes_on_tables_into_LOG2;

--3.Написать системный триггер, добавляющий запись во вспомогатель-ную таблицу LOG3, когда пользователь подключается или отключается. 
--В таблицу логов записывается имя пользователя (USER), тип активности (LOGON или LOGOFF), дата (SYSDATE), количество записей в основной таблице БД.

--Триггер на вход.
CREATE OR REPLACE TRIGGER logon_in_sys
AFTER LOGON 
ON SCHEMA
DECLARE
quant_rows number;
BEGIN
    SELECT COUNT(*) INTO quant_rows FROM sales;
    INSERT INTO LOG3 (nameUser, LOGtype_name, LOGtype_time, quantityRows)
    VALUES (USER, 'LOGON', SYSDATE, quant_rows);
END logon_in_sys;

--Триггер на выход.
CREATE OR REPLACE TRIGGER logoff_in_sys
BEFORE LOGOFF 
ON SCHEMA
DECLARE
quant_rows number;
BEGIN
    SELECT COUNT(*) INTO quant_rows FROM sales;
    INSERT INTO LOG3 (nameUser, LOGtype_name, LOGtype_time, quantityRows)
    VALUES (USER, 'LOGOFF', SYSDATE, quant_rows);
END logoff_in_sys;