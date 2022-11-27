-- 1. Написать с помощью пакета DBMS_SQL динамическую процедуру или функцию, в которой заранее неизвестен текст команды SELECT.
-- Предусмотреть возможность вывода разных результатов, в зависимости от количества передаваемых параметров.
-- Динамическая процеудра: Передаваемые параметры:
-- list_tab (Передаваемые таблицы с выбранными колонками, для которых выбрана функция в запросе)- коллекция с полями: название таблицы (table_name), коллекция (tab_columns) с названиями полей: название колонки (column_name), функция (col_function)
-- join_type - тип связи таблиц (LEFT JOIN, RIGHT JOIN, FULL JOIN, JOIN, CROSS JOIN)
-- where_type - условие запроса
-- having_type - условия запроса
-- orderby_type - сортировка данных

CREATE TYPE columns_obj_type IS OBJECT(column_name VARCHAR2(100),
                                       col_function VARCHAR2(100));
CREATE TYPE columns_type IS TABLE OF columns_obj_type;
CREATE TYPE table_obj_type IS OBJECT(table_name VARCHAR2(1000),
                                    tab_columns columns_type);
CREATE TYPE table_type IS TABLE OF table_obj_type;                                  

CREATE OR REPLACE PROCEDURE otchet(list_tab IN OUT table_type, join_type IN OUT VARCHAR2, where_type IN OUT VARCHAR2, having_type IN OUT VARCHAR2, orderby_type IN OUT VARCHAR2)
IS
    -- строки для создания запроса
    select_str VARCHAR2(30000) := 'SELECT ';
    from_str VARCHAR2(30000) := 'FROM ';
    where_str VARCHAR2(30000):= 'WHERE ';
    groupby_str VARCHAR2(30000) := 'GROUP BY ';
    having_str VARCHAR2(30000) := 'HAVING ';
    orderby_str VARCHAR2(30000) := 'ORDER BY ';
    vyvod_str VARCHAR2(30000);
    -- переменные для реализации процедуры
    list_tables table_type := list_tab;
    list_columns columns_type;
    TYPE correct_columns_obj_type IS RECORD(column_name VARCHAR2(1000),
                                            value VARCHAR2(1000));
    TYPE correct_columns_type IS TABLE OF correct_columns_obj_type;
    correct_list_columns correct_columns_type := correct_columns_type();
    col_name VARCHAR2(1000);
    col_function VARCHAR2(1000);
    table_name VARCHAR2(1000);
    table_name1 VARCHAR2(1000);
    table_name2 VARCHAR2(1000);
    -- переменные для поиска связи таблиц (если не переданы поля для соединения)
    join_columns VARCHAR2(30000) :='SELECT a.table_name AS main_tab, :name_tab2 AS doch_tab, u.column_name AS foreing_key, (select column_name 
                                                                        from user_cons_columns
                                                                        where constraint_name = (SELECT constraint_name
                                                                                                FROM ALL_CONSTRAINTS
                                                                                                WHERE table_name = :name_tab1
                                                                                                AND owner = :name_owner
                                                                                                AND constraint_type = :name_cons2)) as primary_key
                                    FROM all_tables a, user_cons_columns u
                                    WHERE a.owner = :name_owner
                                    AND a.table_name = :name_tab1
                                    AND u.constraint_name = (SELECT constraint_name
                                                            FROM ALL_CONSTRAINTS
                                                            WHERE constraint_type = :name_cons1
                                                                AND owner = :name_owner
                                                                AND table_name = :name_tab2
                                                                AND r_constraint_name IN (SELECT constraint_name
                                                                                        FROM ALL_CONSTRAINTS
                                                                                        WHERE table_name = :name_tab1
                                                                                            AND owner = :name_owner
                                                                                            AND constraint_type = :name_cons2))';
    all_columns_tab VARCHAR2(30000) := 'SELECT column_name
                                        FROM all_tab_columns
                                        WHERE owner = :owner
                                            AND table_name = :tab_name';
    out_column_name VARCHAR(1000);             
    main_tab VARCHAR2(1000);
    doch_tab VARCHAR2(1000);
    foreing_key VARCHAR2(1000);
    primary_key VARCHAR2(1000);
    cur NUMBER;
    enter INTEGER;
    name_owner VARCHAR2(100) := 'WKSP_ANTONNIDAST';
    cons1 CHAR(1) := 'R';
    cons2 CHAR(1) := 'P';
    error_join EXCEPTION;
    error_function EXCEPTION;
    no_connection EXCEPTION;
    error_tables EXCEPTION;
BEGIN
    IF list_tables.COUNT > 2 OR list_tables.COUNT = 0 THEN
        RAISE error_tables;
    ELSIF list_tables.COUNT = 2 THEN
        FOR i IN list_tables.FIRST .. list_tables.LAST
        LOOP
            table_name1 := list_tables(list_tables.FIRST).table_name;
            table_name2 := list_tables(list_tables.LAST).table_name;
            list_columns := list_tables(i).tab_columns;
            table_name := list_tables(i).table_name;

            IF list_columns.COUNT > 0 THEN
                FOR j IN list_columns.FIRST .. list_columns.LAST 
                LOOP
                    col_name := list_columns(j).column_name;
                    col_function := list_columns(j).col_function;

                    cur := DBMS_SQL.OPEN_CURSOR;
                    DBMS_SQL.PARSE(cur, all_columns_tab, DBMS_SQL.native);
                    DBMS_SQL.BIND_VARIABLE(cur,':owner',name_owner);
                    DBMS_SQL.BIND_VARIABLE(cur,':tab_name',table_name);
                    DBMS_SQL.DEFINE_COLUMN(cur, 1, out_column_name, 1000);
                    enter := DBMS_SQL.EXECUTE(cur);
                    LOOP
                        IF DBMS_SQL.FETCH_ROWS(cur) = 0 THEN
                            EXIT; 
                        END IF;    
                        DBMS_SQL.COLUMN_VALUE(cur, 1, out_column_name);
                        IF out_column_name = col_name THEN
                            IF j = list_columns.FIRST THEN
                                IF col_function IS NULL THEN
                                    IF SUBSTR(select_str,-1,1)=' ' THEN
                                        correct_list_columns.EXTEND;
                                        correct_list_columns(correct_list_columns.LAST).column_name := table_name||'.'||col_name;
                                        select_str := select_str||table_name||'.'||col_name;
                                        groupby_str := groupby_str||table_name||'.'||col_name;
                                    ELSE
                                        correct_list_columns.EXTEND;
                                        correct_list_columns(correct_list_columns.LAST).column_name := table_name||'.'||col_name;
                                        select_str := select_str||', '||table_name||'.'||col_name;
                                        groupby_str := groupby_str||', '||table_name||'.'||col_name;
                                    END IF;
                                ELSIF col_function IN ('SUM', 'AVG', 'MIN', 'MAX', 'COUNT') THEN
                                    IF SUBSTR(select_str,-1,1)=' ' THEN
                                        correct_list_columns.EXTEND;
                                        correct_list_columns(correct_list_columns.LAST).column_name := col_function||'('||table_name||'.'||col_name||')';
                                        select_str := select_str||col_function||'('||table_name||'.'||col_name||')';
                                    ELSE
                                        correct_list_columns.EXTEND;
                                        correct_list_columns(correct_list_columns.LAST).column_name := col_function||'('||table_name||'.'||col_name||')';
                                        select_str := select_str||', '||col_function||'('||table_name||'.'||col_name||')';
                                    END IF;
                                ELSE
                                    DBMS_SQL.CLOSE_CURSOR(cur);
                                    RAISE error_function;
                                END IF;
                            ELSE
                                IF col_function IS NULL THEN
                                    correct_list_columns.EXTEND;
                                    correct_list_columns(correct_list_columns.LAST).column_name := table_name||'.'||col_name;
                                    select_str := select_str||', '||table_name||'.'||col_name;
                                    groupby_str := groupby_str||', '||table_name||'.'||col_name;
                                ELSIF list_columns(j).col_function IN ('SUM', 'AVG', 'MIN', 'MAX', 'COUNT') THEN
                                    correct_list_columns.EXTEND;
                                    correct_list_columns(correct_list_columns.LAST).column_name := col_function||'('||table_name||'.'||col_name||')';
                                    select_str := select_str||', '||col_function||'('||table_name||'.'||col_name||')';
                                ELSE
                                    DBMS_SQL.CLOSE_CURSOR(cur);
                                    RAISE error_function;
                                END IF;
                            END IF;
                        END IF;
                    END LOOP;
                    DBMS_SQL.CLOSE_CURSOR(cur);
                END LOOP;
            END IF;
            IF i = list_columns.FIRST THEN
                from_str := from_str||table_name;
            ELSE
                IF join_type IN ('JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'FULL JOIN') THEN
                    
                    cur := DBMS_SQL.OPEN_CURSOR;
                    DBMS_SQL.PARSE(cur, join_columns, DBMS_SQL.native);
                    DBMS_SQL.BIND_VARIABLE(cur,':name_owner',name_owner);
                    DBMS_SQL.BIND_VARIABLE(cur,':name_tab1',table_name1);
                    DBMS_SQL.BIND_VARIABLE(cur,':name_tab2',table_name2);
                    DBMS_SQL.BIND_VARIABLE(cur,':name_cons1',cons1);
                    DBMS_SQL.BIND_VARIABLE(cur,':name_cons2',cons2);
                    DBMS_SQL.DEFINE_COLUMN(cur, 1, main_tab, 1000);
                    DBMS_SQL.DEFINE_COLUMN(cur, 2, doch_tab, 1000);
                    DBMS_SQL.DEFINE_COLUMN(cur, 3, foreing_key, 1000);
                    DBMS_SQL.DEFINE_COLUMN(cur, 4, primary_key, 1000);
                    enter := DBMS_SQL.EXECUTE(cur);

                    IF DBMS_SQL.FETCH_ROWS(cur) = 0 THEN 
                        DBMS_SQL.CLOSE_CURSOR(cur);
                        cur := DBMS_SQL.OPEN_CURSOR;
                        DBMS_SQL.PARSE(cur, join_columns, DBMS_SQL.native);
                        DBMS_SQL.BIND_VARIABLE(cur,':name_owner',name_owner);
                        DBMS_SQL.BIND_VARIABLE(cur,':name_tab1',table_name2);
                        DBMS_SQL.BIND_VARIABLE(cur,':name_tab2',table_name1);
                        DBMS_SQL.BIND_VARIABLE(cur,':name_cons1',cons1);
                        DBMS_SQL.BIND_VARIABLE(cur,':name_cons2',cons2);
                        DBMS_SQL.DEFINE_COLUMN(cur, 1, main_tab, 1000);
                        DBMS_SQL.DEFINE_COLUMN(cur, 2, doch_tab, 1000);
                        DBMS_SQL.DEFINE_COLUMN(cur, 3, foreing_key, 1000);
                        DBMS_SQL.DEFINE_COLUMN(cur, 4, primary_key, 1000);
                        enter := DBMS_SQL.EXECUTE(cur);

                        IF DBMS_SQL.FETCH_ROWS(cur) = 0 THEN 
                            DBMS_SQL.CLOSE_CURSOR(cur);
                            RAISE no_connection;
                        ELSE
                            DBMS_SQL.COLUMN_VALUE(cur, 1, main_tab);
                            DBMS_SQL.COLUMN_VALUE(cur, 2, doch_tab);
                            DBMS_SQL.COLUMN_VALUE(cur, 3, foreing_key);
                            DBMS_SQL.COLUMN_VALUE(cur, 4, primary_key);

                            from_str := from_str||' '||join_type||' '||table_name||' ON '||main_tab||'.'||primary_key||' = '||doch_tab||'.'||foreing_key;
                            DBMS_SQL.CLOSE_CURSOR(cur);
                        END IF;
                    ELSE
                        DBMS_SQL.COLUMN_VALUE(cur, 1, main_tab);
                        DBMS_SQL.COLUMN_VALUE(cur, 2, doch_tab);
                        DBMS_SQL.COLUMN_VALUE(cur, 3, foreing_key);
                        DBMS_SQL.COLUMN_VALUE(cur, 4, primary_key);

                        from_str := from_str||' '||join_type||' '||table_name||' ON '||main_tab||'.'||primary_key||' = '||doch_tab||'.'||foreing_key;
                        DBMS_SQL.CLOSE_CURSOR(cur);
                    END IF;
                ELSIF join_type = 'CROSS JOIN' THEN
                    from_str := from_str||' '||join_type||' '||table_name;
                ELSE
                    RAISE error_join;
                END IF;
            END if;
        END LOOP;
    ELSIF list_tables.COUNT = 1 THEN 
        list_columns := list_tables(list_tables.FIRST).tab_columns;
        table_name := list_tables(list_tables.FIRST).table_name;

        IF list_columns.COUNT > 0 THEN
            FOR j IN list_columns.FIRST .. list_columns.LAST 
            LOOP
                col_name := list_columns(j).column_name;
                col_function := list_columns(j).col_function;
                cur := DBMS_SQL.OPEN_CURSOR;
                DBMS_SQL.PARSE(cur, all_columns_tab, DBMS_SQL.native);
                DBMS_SQL.BIND_VARIABLE(cur,':owner',name_owner);
                DBMS_SQL.BIND_VARIABLE(cur,':tab_name',table_name);
                DBMS_SQL.DEFINE_COLUMN(cur, 1, out_column_name, 1000);
                enter := DBMS_SQL.EXECUTE(cur);
                LOOP
                    IF DBMS_SQL.FETCH_ROWS(cur) = 0 THEN
                        EXIT; 
                    END IF;    
                    DBMS_SQL.COLUMN_VALUE(cur, 1, out_column_name);
                    IF out_column_name = col_name THEN
                        IF j = list_columns.FIRST THEN
                            IF col_function IS NULL THEN
                                IF SUBSTR(select_str,-1,1)=' ' THEN
                                    correct_list_columns.EXTEND;
                                    correct_list_columns(correct_list_columns.LAST).column_name := table_name||'.'||col_name;
                                    select_str := select_str||table_name||'.'||col_name;
                                    groupby_str := groupby_str||table_name||'.'||col_name;
                                ELSE
                                    correct_list_columns.EXTEND;
                                    correct_list_columns(correct_list_columns.LAST).column_name := table_name||'.'||col_name;
                                    select_str := select_str||', '||table_name||'.'||col_name;
                                    groupby_str := groupby_str||', '||table_name||'.'||col_name;
                                END IF;
                            ELSIF col_function IN ('SUM', 'AVG', 'MIN', 'MAX', 'COUNT') THEN
                                IF SUBSTR(select_str,-1,1)=' ' THEN
                                    correct_list_columns.EXTEND;
                                    correct_list_columns(correct_list_columns.LAST).column_name := col_function||'('||table_name||'.'||col_name||')';
                                    select_str := select_str||col_function||'('||table_name||'.'||col_name||')';
                                ELSE
                                    correct_list_columns.EXTEND;
                                    correct_list_columns(correct_list_columns.LAST).column_name := col_function||'('||table_name||'.'||col_name||')';
                                    select_str := select_str||', '||col_function||'('||table_name||'.'||col_name||')';
                                END IF;
                            ELSE
                                DBMS_SQL.CLOSE_CURSOR(cur);
                                RAISE error_function;
                            END IF;
                        ELSE
                            IF col_function IS NULL THEN
                                correct_list_columns.EXTEND;
                                correct_list_columns(correct_list_columns.LAST).column_name := table_name||'.'||col_name;
                                select_str := select_str||', '||table_name||'.'||col_name;
                                groupby_str := groupby_str||', '||table_name||'.'||col_name;
                            ELSIF list_columns(j).col_function IN ('SUM', 'AVG', 'MIN', 'MAX', 'COUNT') THEN
                                correct_list_columns.EXTEND;
                                correct_list_columns(correct_list_columns.LAST).column_name := col_function||'('||table_name||'.'||col_name||')';
                                select_str := select_str||', '||col_function||'('||table_name||'.'||col_name||')';
                            ELSE
                                DBMS_SQL.CLOSE_CURSOR(cur);
                                RAISE error_function;
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
                DBMS_SQL.CLOSE_CURSOR(cur);
            END LOOP;
        END IF;
        from_str := from_str||' '||table_name;
    END IF;

    select_str := select_str||' '||from_str;
    IF where_type IS NOT NULL THEN
        where_str := where_str||where_type;
        select_str := select_str||' '||where_str||' '||groupby_str;
        IF having_type IS NOT NULL THEN
            having_str := having_str||having_type;
            select_str := select_str||' '||having_str;
            IF orderby_type IS NOT NULL THEN
                orderby_str := orderby_str||orderby_type;
                select_str := select_str||' '||orderby_str;
            END IF;
        ELSE
            IF orderby_type IS NOT NULL THEN
                orderby_str := orderby_str||orderby_type;
                select_str := select_str||' '||orderby_str;
            END IF; 
        END IF;
    ELSE
        select_str := select_str||' '||groupby_str;
        IF having_type IS NOT NULL THEN
            having_str := having_str||having_type;
            select_str := select_str||' '||having_str;
            IF orderby_type IS NOT NULL THEN
                orderby_str := orderby_str||orderby_type;
                select_str := select_str||' '||orderby_str;
            END IF;
        ELSE
            IF orderby_type IS NOT NULL THEN
                orderby_str := orderby_str||orderby_type;
                select_str := select_str||' '||orderby_str;
            END IF; 
        END IF;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Код запроса: '||select_str);
    DBMS_OUTPUT.PUT_LINE('______________________');
    cur := DBMS_SQL.OPEN_CURSOR;
    DBMS_SQL.PARSE(cur,select_str,DBMS_SQL.NATIVE);
    FOR i IN correct_list_columns.FIRST .. correct_list_columns.LAST
    LOOP
        DBMS_SQL.DEFINE_COLUMN(cur, i, correct_list_columns(i).value, 1000);
    END LOOP;
    enter := DBMS_SQL.EXECUTE(cur);
    LOOP
        IF DBMS_sQL.FETCH_ROWS(cur) = 0 THEN
            EXIT;
        END IF;
        FOR i IN correct_list_columns.FIRST .. correct_list_columns.LAST
        LOOP
            DBMS_SQL.COLUMN_VALUE(cur, i, correct_list_columns(i).value);
            vyvod_str := vyvod_str||' '||correct_list_columns(i).column_name||': '||correct_list_columns(i).value;
        END LOOP;
        DBMS_OUTPUT.PUT_LINE(vyvod_str);
        vyvod_str := NULL;
    END LOOP;
    DBMS_SQL.CLOSE_CURSOR(cur);
    EXCEPTION
        WHEN error_function THEN
            DBMS_OUTPUT.PUT_LINE('FUN');
        WHEN error_join THEN
            DBMS_OUTPUT.PUT_LINE('JOIN');
        WHEN no_connection THEN
            DBMS_OUTPUT.PUT_LINE('CONNCET');
        WHEN error_tables THEN
            DBMS_OUTPUT.PUT_LINE('TABLE');
END;

-- Проверка работы процедуры
DECLARE
    list_tab table_type := table_type( table_obj_type('PRODUCTS',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEPROD', null),columns_obj_type('UNITCOST', NULL))));
    join_type varchar2(100) := Null;
    where_type varchar2(30000) := NULL;
    having_type varchar2(30000) := NULL;
    orderby_type varchar2(30000) := NULL;
BEGIN
        otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

DECLARE
    list_tab table_type := table_type( table_obj_type('PRODUCTS',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEPROD', null),columns_obj_type('UNITCOST', null))), table_obj_type('SALES', columns_type(columns_obj_type('ID', 'COUNT'), columns_obj_type('SALEAMOUNT', 'SUM'))));
    join_type varchar2(100) := 'LEFT JOIN';
    where_type varchar2(30000) := NULL;
    having_type varchar2(30000) := 'COUNT(SALES.ID)>0';
    orderby_type varchar2(30000) := 'PRODUCTS.ID DESC';
BEGIN
    otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

DECLARE
    list_tab table_type := table_type( table_obj_type('DSLFDSFKL',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEPROD', null),columns_obj_type('UNITCOST', null))), table_obj_type('SALES', columns_type(columns_obj_type('ID', 'COUNT'), columns_obj_type('SALEAMOUNT', 'SUM'))));
    join_type varchar2(100) := 'LEFT JOIN';
    where_type varchar2(30000) := NULL;--'PRODUCTS.UNITCOST > 10';
    having_type varchar2(30000) := 'COUNT(SALES.ID)>0';
    orderby_type varchar2(30000) := 'PRODUCTS.ID DESC';
BEGIN
    otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

DECLARE
    list_tab table_type := table_type( table_obj_type('PRODUCTS',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEPROD', null),columns_obj_type('UNITCOST', null))), table_obj_type('SALES', columns_type(columns_obj_type('ID', 'COUNT'), columns_obj_type('SALEAMOUNT', 'SUM'))));
    join_type varchar2(100) := 'dfsfs';
    where_type varchar2(30000) := NULL;--'PRODUCTS.UNITCOST > 10';
    having_type varchar2(30000) := 'COUNT(SALES.ID)>0';
    orderby_type varchar2(30000) := 'PRODUCTS.ID DESC';
BEGIN
    otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

DECLARE
    list_tab table_type := table_type( table_obj_type('PRODUCTS',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEPROD', null),columns_obj_type('UNITCOST', null))), table_obj_type('SALES', columns_type(columns_obj_type('ID', 'sdfsdf'), columns_obj_type('SALEAMOUNT', 'SUM'))));
    join_type varchar2(100) := 'LEFT JOIN';
    where_type varchar2(30000) := NULL;--'PRODUCTS.UNITCOST > 10';
    having_type varchar2(30000) := 'COUNT(SALES.ID)>0';
    orderby_type varchar2(30000) := 'PRODUCTS.ID DESC';
BEGIN
    otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

DECLARE
    list_tab table_type := table_type( table_obj_type('MATERIALS',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEMAT', null))), table_obj_type('PRODUCTS', columns_type(columns_obj_type('ID', 'COUNT'))));
    join_type varchar2(100) := 'JOIN';
    where_type varchar2(30000) :='PRODUCTS.UNITCOST > 10';
    having_type varchar2(30000) := NULL;
    orderby_type varchar2(30000) := 'MATERIALS.ID DESC';
BEGIN
    otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

DECLARE
    list_tab table_type := table_type( table_obj_type('PRODUCTS',columns_type(columns_obj_type('ID', null),columns_obj_type('NAMEPROD', null),columns_obj_type('UNITCOST', null))), table_obj_type('SALES', columns_type(columns_obj_type('ID', 'COUNT'), columns_obj_type('SALEAMOUNT', 'SUM'))));
    join_type varchar2(100) := 'LEFT JOIN';
    where_type varchar2(30000) := 'PRODUCTS.UNITCOST > 10';
    having_type varchar2(30000) := 'COUNT(SALES.ID)>0';
    orderby_type varchar2(30000) := 'PRODUCTS.ID DESC';
BEGIN
    otchet(list_tab , join_type, where_type, having_type, orderby_type);
END;

-- 2. Написать, используя встроенный динамический SQL, процедуру создания в БД нового объекта (представления или таблицы) на основе существующей таблицы. 
-- Имя нового объекта должно формироваться динамически и проверяться на существование в словаре данных. 
-- В качестве входных параметров указать тип нового объекта, исходную таблицу, столбцы и количество строк, которые будут использоваться в запросе.

-- Тип данных коллекции для выбранных полей.
CREATE TYPE column_type AS TABLE OF VARCHAR2(100);

-- Процедура.
-- Передаваемые параметры:
-- objType - выбранный тип объекта: view/table
-- nameOwner - имя схемы в которой находится исходная таблица
-- startTab - имя исходной таблицы
-- col_name - колекция с выбранными полями из исходной таблицы

CREATE OR REPLACE PROCEDURE create_obj(objType IN VARCHAR2, nameOwner IN VARCHAR2, startTab IN VARCHAR2, col_name IN column_type, countRows IN INTEGER) 
IS
    
    TYPE col_type_cur IS RECORD(column_name all_tab_columns.column_name%TYPE,
                                identity_column all_tab_columns.identity_column%TYPE); -- Тип данных для выборки элементов из all_tab_columns для создание новой таблицы;
    TabOut col_type_cur; -- Переменная для записи в нее строк с помощью курсора
    TYPE TabCurType IS REF CURSOR; -- Создание курсоной переменной 

    TabCur TabCurType; -- Курсорная переменная
    nameTab VARCHAR2(100) := UPPER(startTab); -- Название исходной таблицы
    select_str VARCHAR2(30000); -- Переменная для запросов
    name_tab VARCHAR2(1000) := UPPER(objType||startTab||DBMS_SESSION.UNIQUE_SESSION_ID); -- Название новой созданной таблицы/view
    ddl_str VARCHAR2(30000) := 'CREATE '||objType||' '||name_tab||' AS (SELECT'; -- Начало pl/sql блока для создания таблицы/view
    ddl_str_view_end VARCHAR2(30000); -- Конец pl/sql блока для создания таблицы/view
    NameTABcreate VARCHAR2(1000):= name_tab; -- Переменная с название новой таблицы/view
    col_name1 column_type := column_type(); -- Хранит верные колонки исходной таблицы, перенесенные в таблицу/view
    col_key VARCHAR2(100); -- Название Ключевого поля для исходной таблицы
    no_info EXCEPTION;
BEGIN
    select_str :='SELECT column_name, identity_column 
                  FROM all_tab_columns
                  WHERE owner = :own
                  AND table_name = :tab';
-- В зависимости от выбранного типа объекта создать представление или таблицу.
    IF UPPER(objType) = 'TABLE' THEN --Создание TABLE
        OPEN TabCur FOR select_str USING nameOwner, nameTab;
        LOOP
            FETCH TabCur INTO TabOut;
            EXIT WHEN TabCur%NOTFOUND;
-- Создание блока для создание объкта с типом TABLE.
                IF TabOut.identity_column = 'YES' THEN
                    col_key := TabOut.column_name;    
                END IF;
                FOR i IN col_name.FIRST .. col_name.LAST
                LOOP
                    IF col_name(i) = TabOut.column_name THEN
                        IF SUBSTR(ddl_str, -1, 1) =' ' THEN
                            ddl_str := ddl_str||',';
                        END IF;
                            ddl_str := ddl_str||' '||TabOut.column_name||' ';
                    END IF;
                END LOOP;
        END LOOP;
-- Если запрос из словаря данных ничего не вернул: следовательно такой таблицы нету в словаре данных, иначе создаем новую таблицу.
        IF TabCur%ROWCOUNT = 0 THEN
            RAISE no_info;
        ELSE
            CLOSE TabCur;
        END IF;
        ddl_str_view_end := ' FROM (SELECT * FROM '||UPPER(startTab)||' ORDER BY '||col_key||' DESC) WHERE ROWNUM <='||countRows||' )';
        ddl_str := ddl_str||ddl_str_view_end;
-- Выполнение созданного блока, для создание TABLE.
	DBMS_OUTPUT.PUT_LINE('Вывод строки создание объекта с типом TABLE: '||ddl_str);
        EXECUTE IMMEDIATE ddl_str;
    ELSIF UPPER(objType) = 'VIEW' THEN --Создание VIEW
        OPEN TabCur FOR select_str USING nameOwner, nameTab;
        LOOP
            FETCH TabCur INTO TabOut;
            EXIT WHEN TabCur%NOTFOUND;
-- Создание блока для создание объкта с типом VIEW.
                IF TabOut.identity_column = 'YES' THEN
                    col_key := TabOut.column_name;    
                END IF;
                FOR i IN col_name.FIRST .. col_name.LAST
                LOOP
                    IF col_name(i) = TabOut.column_name THEN
                        IF SUBSTR(ddl_str, -1, 1) =' ' THEN
                            ddl_str := ddl_str||',';
                        END IF;
                            ddl_str := ddl_str||' '||TabOut.column_name||' ';
                    END IF;
                END LOOP;
        END LOOP;
-- Если запрос из словаря данных ничего не вернул: следовательно такой таблицы нету в словаре данных, иначе создаем новую таблицу.
        IF TabCur%ROWCOUNT = 0 THEN
            RAISE no_info;
        ELSE
            CLOSE TabCur;
        END IF;
        ddl_str_view_end := ' FROM (SELECT * FROM '||UPPER(startTab)||' ORDER BY '||col_key||' DESC) WHERE ROWNUM <='||countRows||' )';
        ddl_str := ddl_str||ddl_str_view_end;
-- Выполнение созданного блока, для создание VIEW.
	DBMS_OUTPUT.PUT_LINE('Вывод строки создание объекта с типом VIEW: '||ddl_str);
        EXECUTE IMMEDIATE ddl_str;
    END IF;
    EXCEPTION
        WHEN no_info THEN
            DBMS_OUTPUT.PUT_LINE('Invalid table or owner');
END;

-- Проверка.
DECLARE
COLs column_type := column_type('LNAME','FNAME');
BEGIN
    create_obj('VIEW','WKSP_ANTONNIDAST','CLIENTS',COLs,3);
END;

DECLARE
COLs column_type := column_type('SALEAMOUNT','SALEVOL','ID','PRODUCTID', 'ERROR_ROW');
BEGIN
    create_obj('TABLE','WKSP_ANTONNIDAST','dkosadk',COLs,5);
END;

-- 3. Создать процедуру, которая принимает в качестве параметра имя таблицы и имена двух полей в этой таблице и добавляет содержание первого поля к содержанию второго. 
-- Если поле_2 пустое, то просто копировать поле_1 в поле_2 и наоборот.

-- Процедура.
CREATE OR REPLACE PROCEDURE cancat_columns(nameTab IN VARCHAR2, nameCol1 IN VARCHAR2, nameCol2 IN VARCHAR2) 
IS
    TYPE col_type_cur IS RECORD(column_name all_tab_columns.column_name%TYPE,
                                data_type all_tab_columns.data_type%TYPE,
                                identity_column all_tab_columns.identity_column%TYPE);
    TabOut col_type_cur;
    TYPE ref_cur IS REF CURSOR;
    cur ref_cur;
    nameID VARCHAR2(100);
    type_col1 VARCHAR2(100);
    type_col2 VARCHAR2(100);
    name_owner VARCHAR2(100) := 'WKSP_ANTONNIDAST';
    str_select VARCHAR2(30000) :='SELECT column_name, data_type, identity_column
                                    FROM all_tab_columns
                                    WHERE owner = :own
                                    AND table_name = :tab
                                    AND (column_name = :namecol1 OR column_name = :namecol2 OR identity_column = :yes)';
    str VARCHAR2(30000);
    invalid_col_tab EXCEPTION;
    invalid_col_type EXCEPTION;
    invalid_col_ID EXCEPTION;
BEGIN
    OPEN cur FOR str_select USING name_owner, UPPER(nameTab), UPPER(nameCol1), UPPER(nameCol2), 'YES';
    LOOP
        FETCH cur INTO TabOut;
        EXIT WHEN cur%NOTFOUND;
            IF nameCol1 = TabOut.column_name THEN
               type_col1 := TabOut.data_type;
            ELSIF nameCol2 = TabOut.column_name THEN
                type_col2 := TabOut.data_type;
            ELSIF TabOut.identity_column = 'YES' THEN
                nameID := TabOut.column_name;
            END IF;
    END LOOP;
    IF nameCol1 = nameID OR nameCol2 = nameID THEN
        RAISE invalid_col_ID;
    ELSIF cur%ROWCOUNT != 3 THEN
        RAISE invalid_col_tab;
    ELSE
        IF type_col1 != type_col2 AND type_col2 != 'VARCHAR2' THEN
            RAISE invalid_col_type;
        ELSE
            CLOSE cur;
        END IF;
    END IF;
    str_select :='DECLARE
                    CURSOR curs IS
                        SELECT '||nameID||', '||nameCol1||', '||nameCol2||' FROM '||nameTab||';
                    cur_out curs%ROWTYPE;
                    type_cols1 VARCHAR2(100);
                    type_cols2 VARCHAR2(100);
                  BEGIN
                    SELECT data_type INTO type_cols1 FROM ALL_TAB_COLUMNS WHERE owner = :owner_1 AND table_name = :tab_1 and column_name = :column_1;
                    SELECT data_type INTO type_cols2 FROM ALL_TAB_COLUMNS WHERE owner = :owner_2 AND table_name = :tab_2 and column_name = :column_2;
                    OPEN curs;
                    LOOP
                        FETCH curs INTO cur_out;
                        EXIT WHEN curs%NOTFOUND;
                            IF cur_out.'||nameCol1||' IS NULL AND type_cols1 = type_cols2 THEN
                                UPDATE '||nameTab||'
                                SET '||nameCol1||' = cur_out.'||nameCol2||'
                                WHERE '||nameID||' = cur_out.'||nameID||';
                            ELSIF cur_out.'||nameCol2||' IS NULL AND type_cols1 = type_cols2 THEN
                                UPDATE '||nameTab||'
                                SET '||nameCol2||' = cur_out.'||nameCol1||'
                                WHERE '||nameID||' = cur_out.'||nameID||';
                            ELSIF cur_out.'||nameCol2||' IS NULL AND type_cols2 = ''VARCHAR2'' THEN
                                UPDATE '||nameTab||'
                                SET '||nameCol2||' = TO_CHAR(cur_out.'||nameCol1||')
                                WHERE '||nameID||' = cur_out.'||nameID||';
                            ELSIF cur_out.'||nameCol1||' IS NOT NULL AND cur_out.'||nameCol2||' IS NOT NULL THEN
                                IF type_cols2 = ''VARCHAR2'' THEN
                                    UPDATE '||nameTab||'
                                    SET '||nameCol2||' = CONCAT(cur_out.'||nameCol2||', TO_CHAR(cur_out.'||nameCol1||'))
                                    WHERE '||nameID||' = cur_out.'||nameID||';
                                ELSIF type_cols2 = type_cols1 AND type_cols2 = ''NUMBER'' THEN
                                    UPDATE '||nameTab||'
                                    SET '||nameCol2||' = cur_out.'||nameCol2||' + cur_out.'||nameCol1||'
                                    WHERE '||nameID||' = cur_out.'||nameID||';
                                END IF;
                            END IF;
                    END LOOP;
                    CLOSE curs;
                  END;';
                  DBMS_OUTPUT.PUT_LINE(str_select);
    EXECUTE IMMEDIATE str_select USING name_owner, UPPER(nameTab), UPPER(nameCol1), name_owner, UPPER(nameTab), UPPER(nameCol2);
    EXCEPTION
        WHEN invalid_col_tab THEN
            DBMS_OUTPUT.PUT_LINE('Invalid table or columns');
        WHEN invalid_col_type THEN
            DBMS_OUTPUT.PUT_LINE('Invalid columns. They have different types');
        WHEN invalid_col_ID THEN
            DBMS_OUTPUT.PUT_LINE('Invalid column. We cant use identity column');
END;

-- Проверка
CREATE TABLE clientsCOL (
    ID       INTEGER generated always as identity,
    fname    VARCHAR2(1000),
    lname    VARCHAR2(1000),
    phoneNum CHAR(17),
    date_kol DATE,
    CONSTRAINT ch_phoneNum_clientsASD
        CHECK (REGEXP_LIKE(phoneNum, '^\+375\(\d{2}\)\d{3}-\d{2}-\d{2}$')),
    CONSTRAINT uni_phoneNum_clientsASD UNIQUE (phoneNum)
);

INSERT INTO  clientsCOL (FNAME, LNAME, PHONENUM)  SELECT FNAME, LNAME, PHONENUM FROM CLIENTS

DELETE FROM clientsCOL

BEGIN
    cancat_columns('clientsCOL','DATE_KOL', 'FNAME');
END;

-- 4. Написать программу, которая позволит для двух указанных в параметрах таблиц существующей БД определить, есть ли между ними связь «один ко многим». 
-- Если связь есть, то на основе родительской таблицы создать новую, в которой будут присутствовать все поля старой и одно новое поле с типом коллекции, 
-- в котором при переносе данных помещаются все связанные записи из дочерней таблицы.

-- Процедура.
CREATE OR REPLACE PROCEDURE one_to_many(nameTab1 IN VARCHAR2, nameTab2 IN VARCHAR2)
IS  
    TYPE name_out_par_table IS RECORD(table_name all_tables.table_name%TYPE,
                                      col_foreingkey all_tab_columns.column_name%TYPE,
                                      col_key all_tab_columns.column_name%TYPE);
    name_par_table name_out_par_table;
    name_main_table VARCHAR2(1000);
    TYPE col_type_cur IS RECORD(column_name all_tab_columns.column_name%TYPE,
                                data_type all_tab_columns.data_type%TYPE,
                                data_precision all_tab_columns.data_precision%TYPE,
                                data_scale all_tab_columns.data_scale%TYPE,
                                data_length all_tab_columns.data_length%TYPE);
    TabOut col_type_cur;
    TYPE ref_cur IS REF CURSOR;
    cur ref_cur;
    name_doch_table VARCHAR(100);
    name_col_key VARCHAR(100);
    name_col_foreingkey VARCHAR(100);
    name_type VARCHAR2(1000);
    name_tab VARCHAR2(1000);
    name_cons1 CHAR(1) := 'R';
    name_cons2 CHAR(1) := 'P';
    columns_tab VARCHAR2(30000);
    insert_columns_tab VARCHAR2(30000);
    select_columns_tab VARCHAR2(30000);
    name_owner VARCHAR2(100) := 'WKSP_ANTONNIDAST';
    str_select VARCHAR2(30000) :='SELECT a.table_name, u.column_name, (select column_name 
                                                                        from user_cons_columns
                                                                        where constraint_name = (SELECT constraint_name
                                                                                                FROM ALL_CONSTRAINTS
                                                                                                WHERE table_name = :name_tab1
                                                                                                AND owner = :name_owner
                                                                                                AND constraint_type = :name_cons2)) as Key_id
                                    FROM all_tables a, user_cons_columns u
                                    WHERE a.owner = :name_owner
                                    AND a.table_name = :name_tab1
                                    AND u.constraint_name = (SELECT constraint_name
                                                            FROM ALL_CONSTRAINTS
                                                            WHERE constraint_type = :name_cons1
                                                                AND owner = :name_owner
                                                                AND table_name = :name_tab2
                                                                AND r_constraint_name IN (SELECT constraint_name
                                                                                        FROM ALL_CONSTRAINTS
                                                                                        WHERE table_name = :name_tab1
                                                                                            AND owner = :name_owner
                                                                                            AND constraint_type = :name_cons2))';   
    ddl_str VARCHAR2(30000);
    no_connection EXCEPTION;

BEGIN
    OPEN cur FOR str_select USING nameTab1,name_owner,name_cons2,name_owner, nameTab1, name_cons1, name_owner, nameTab2, nameTab1, name_owner, name_cons2; -- Проверка существование связи один ко многим, где родительская таблица nameTab1, а дочерняя nameTab2
    FETCH cur INTO name_par_table;
    IF cur%FOUND THEN
        name_doch_table := nameTab2;
        name_main_table := name_par_table.table_name;
        name_col_key := name_par_table.col_key;
        name_col_foreingkey := name_par_table.col_foreingkey;
        name_type := UPPER(name_doch_table||DBMS_SESSION.UNIQUE_SESSION_ID||'_type'); -- Имя типа данных объекта с полями дочерней таблицы
        name_tab := UPPER(nameTab1||DBMS_SESSION.UNIQUE_SESSION_ID); -- Имя новой таблицы на основе родительской
        CLOSE cur;
    ELSE
        CLOSE cur;
        OPEN cur FOR str_select USING nameTab2,name_owner,name_cons2,name_owner, nameTab2, name_cons1, name_owner, nameTab1, nameTab2, name_owner, name_cons2; -- Проверка существование связи один ко многим, где родительская таблица nameTab2, а дочерняя nameTab1
        FETCH cur INTO name_par_table;
        IF cur%FOUND THEN
            name_doch_table := nameTab1;
            name_main_table := name_par_table.table_name;
            name_col_key := name_par_table.col_key;
            name_col_foreingkey := name_par_table.col_foreingkey;
            name_type := UPPER(name_doch_table||DBMS_SESSION.UNIQUE_SESSION_ID||'_type'); -- Имя типа данных объекта с полями дочерней таблицы
            name_tab := UPPER(nameTab2||DBMS_SESSION.UNIQUE_SESSION_ID); -- Имя новой таблицы на основе родительской
            CLOSE cur;
        ELSE 
            RAISE no_connection;
        END IF;
    END IF;
    ddl_str := 'CREATE TABLE '||name_tab||'(';
    str_select :='SELECT column_name, data_type, data_precision, data_scale, data_length
                  FROM all_tab_columns
                  WHERE owner = :own
                  AND table_name = :tab';
    OPEN cur FOR str_select USING name_owner, name_doch_table; -- Создание строки для создание типа коллекции с типом объекта с колонками из дочерней таблицы (создание типа вложеной таблицы)
    LOOP
        FETCH cur INTO TabOut;
        EXIT WHEN cur%NOTFOUND;
            IF columns_tab IS NULL THEN
                select_columns_tab := select_columns_tab||' '||TabOut.column_name;
                IF TabOut.data_TYPE = 'NUMBER' THEN
                    IF TabOut.data_precision IS NULL AND TabOut.data_scale IS NULL THEN
                        columns_tab := columns_tab||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                    ELSIF TabOut.data_precision IS NOT NULL AND TabOut.data_scale IS NULL THEN
                        columns_tab := columns_tab||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_precision||')';
                    ELSIF TabOut.data_precision IS NOT NULL AND TabOut.data_scale IS NOT NULL THEN
                        columns_tab := columns_tab||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_precision||','||TabOut.data_scale||')';
                    ELSE
                        columns_tab := columns_tab||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                    END IF;
                ELSIF TabOut.data_TYPE = 'DATE' OR TabOut.data_TYPE = 'TIMESTAMP' THEN
                    columns_tab := columns_tab||' '||TabOut.column_name||' '||TabOut.data_type;
                ELSE
                    columns_tab := columns_tab||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                END IF;
            ELSE 
                select_columns_tab := select_columns_tab||', '||TabOut.column_name;
                IF TabOut.data_TYPE = 'NUMBER' THEN
                    IF TabOut.data_precision IS NULL AND TabOut.data_scale IS NULL THEN
                        columns_tab := columns_tab||', '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                    ELSIF TabOut.data_precision IS NOT NULL AND TabOut.data_scale IS NULL THEN
                        columns_tab := columns_tab||', '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_precision||')';
                    ELSIF TabOut.data_precision IS NOT NULL AND TabOut.data_scale IS NOT NULL THEN
                        columns_tab := columns_tab||', '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_precision||','||TabOut.data_scale||')';
                    ELSE
                        columns_tab := columns_tab||', '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                    END IF;
                ELSIF TabOut.data_TYPE = 'DATE' OR TabOut.data_TYPE = 'TIMESTAMP' THEN
                    columns_tab := columns_tab||', '||TabOut.column_name||' '||TabOut.data_type;
                ELSE
                    columns_tab := columns_tab||', '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                END IF;
            END IF;
    END LOOP;
    CLOSE cur;
    DBMS_OUTPUT.PUT_LINE('Строка создания типа объекта с колонками из дочерней таблицы: CREATE TYPE '||name_type||' IS OBJECT('||columns_tab||')');
    EXECUTE IMMEDIATE 'CREATE TYPE '||name_type||' IS OBJECT('||columns_tab||')'; -- Создание типа объекта с колонками из дочерней таблицы

    DBMS_OUTPUT.PUT_LINE('Строка создания типа вложенной таблицы с типом созданного объекта: CREATE TYPE '||name_type||'_TAB IS TABLE OF '||name_type);
    EXECUTE IMMEDIATE 'CREATE TYPE '||name_type||'_TAB IS TABLE OF '||name_type; -- Создание типа вложенной таблицы с типом созданного объекта

    OPEN cur FOR str_select USING name_owner, name_main_table; -- Создание строки для создания таблицы на основе родительской с полем с типом коллекция
    LOOP
        FETCH cur INTO TabOut;
        EXIT WHEN cur%NOTFOUND;
            IF SUBSTR(ddl_str, -1, 1) = ')' OR SUBSTR(ddl_str, -1, 1) = ' ' THEN
                ddl_str := ddl_str||',';
                insert_columns_tab := insert_columns_tab||','; 
            END IF;
            insert_columns_tab := insert_columns_tab||' '||TabOut.column_name;
            IF TabOut.data_TYPE = 'NUMBER' THEN
                IF TabOut.data_precision IS NULL AND TabOut.data_scale IS NULL THEN
                    ddl_str := ddl_str||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                ELSIF TabOut.data_precision IS NOT NULL AND TabOut.data_scale IS NULL THEN
                    ddl_str := ddl_str||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_precision||')';
                ELSIF TabOut.data_precision IS NOT NULL AND TabOut.data_scale IS NOT NULL THEN
                    ddl_str := ddl_str||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_precision||','||TabOut.data_scale||')';
                ELSE
                    ddl_str := ddl_str||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
                END IF;
            ELSIF TabOut.data_TYPE = 'DATE' OR TabOut.data_TYPE = 'TIMESTAMP' THEN
                ddl_str := ddl_str||' '||TabOut.column_name||' '||TabOut.data_type||' ';
            ELSE
                ddl_str := ddl_str||' '||TabOut.column_name||' '||TabOut.data_type||'('||TabOut.data_length||')';
            END IF;
    END LOOP;
    CLOSE cur;
    ddl_str := ddl_str||', col_collection '||name_type||'_TAB ) NESTED TABLE col_collection STORE AS col_collection_'||name_tab;
    DBMS_OUTPUT.PUT_LINE('Строка создания таблицы на основе родительской с полем с типом коллекции: '||ddl_str);
    EXECUTE IMMEDIATE ddl_str; -- Создание таблицы на основе родительской с полем с типом коллекции
    DBMS_OUTPUT.PUT_LINE('Строка заполнения созданной таблицы на основе данных из родительской таблицы (без заполнения поля с типом коллекции): INSERT INTO '||name_tab||'('||insert_columns_tab||') SELECT '||insert_columns_tab||' FROM '||name_main_table);    
    EXECUTE IMMEDIATE 'INSERT INTO '||name_tab||'('||insert_columns_tab||') SELECT '||insert_columns_tab||' FROM '||name_main_table; -- Заполнение созданной таблицы на основе данных из родительской таблицы (без заполнения поля с типом коллекции)
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Строка заполнения в созданной таблице поля с типом коллекции для каждой строки: 
                       DECLARE  
                       CURSOR cur_par IS 
                        SELECT '||name_col_key||'
                        FROM '||name_tab||';
                        cur_out cur_par%ROWTYPE;
                        col '||name_type||'_TAB;
                       BEGIN 
                        OPEN cur_par;
                        LOOP
                            FETCH cur_par INTO cur_out;
                            EXIT WHEN cur_par%NOTFOUND;
                                SELECT '||name_type||'('||select_columns_tab||')
                                BULK COLLECT INTO col
                                FROM '||name_doch_table||'
                                WHERE '||name_col_foreingkey||' = cur_out.'||name_col_key||';
                                IF col.COUNT != 0 THEN
                                    UPDATE '||name_tab||'
                                    SET col_collection = col
                                    WHERE '||name_col_key||' = cur_out.'||name_col_key||';
                                    COMMIT;
                                    col := null;
                                ELSE
                                    col := null;
                                END IF;
                        END LOOP;
                        CLOSE cur_par;
                       END;');
    EXECUTE IMMEDIATE 'DECLARE  
                       CURSOR cur_par IS 
                        SELECT '||name_col_key||'
                        FROM '||name_tab||';
                        cur_out cur_par%ROWTYPE;
                        col '||name_type||'_TAB;
                       BEGIN 
                        OPEN cur_par;
                        LOOP
                            FETCH cur_par INTO cur_out;
                            EXIT WHEN cur_par%NOTFOUND;
                                SELECT '||name_type||'('||select_columns_tab||')
                                BULK COLLECT INTO col
                                FROM '||name_doch_table||'
                                WHERE '||name_col_foreingkey||' = cur_out.'||name_col_key||';
                                IF col.COUNT != 0 THEN
                                    UPDATE '||name_tab||'
                                    SET col_collection = col
                                    WHERE '||name_col_key||' = cur_out.'||name_col_key||';
                                    COMMIT;
                                    col := null;
                                ELSE
                                    col := null;
                                END IF;
                        END LOOP;
                        CLOSE cur_par;
                       END;'; -- Заполнение для каждой строки в созданной таблице поля с типом коллекции
EXCEPTION
    WHEN no_connection THEN
        DBMS_OUTPUT.PUT_LINE('NO CONNECTION'); -- Если связи нет, выводит в консоль NO CONNECTION
END;

-- Проверка.
BEGIN
    one_to_many('CLIENTS','SALES');
END;

BEGIN
    one_to_many('PROVIDERS','SALES');
END;

SELECT M.*, T.*
FROM MATERIALS098C7A1C0001 M, TABLE(M.col_collection) (+)T;

SELECT M.*, T.*
FROM PRODUCTS093FF9090001 M, TABLE(M.col_collection) (+)T;

SELECT M.*, T.*
FROM CLIENTS06EC79C90002 M, TABLE(M.col_collection) (+)T;

SELECT M.ID, M.NAMEMAT, M.QUANTITYMAT, T.*
FROM MATERIALS098C7A1C0001 M, TABLE(M.col_collection) (+)T;

SELECT M.ID, M.NAMEMAT, M.QUANTITYMAT, T.*
FROM MATERIALS098C7A1C0001 M, TABLE(M.col_collection) (+)T;