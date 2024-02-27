DROP FUNCTION if exists trigger_next_id(_name_table varchar, _name_column varchar);
DROP table if exists test;
DROP table if exists test2;
DROP TABLE if exists spec_table;



CREATE TABLE spec_table (
  id INT NOT NULL PRIMARY KEY,
  name_table VARCHAR NOT NULL,
  name_column VARCHAR NOT NULL,
  max_value_id INT NOT NULL
);
CREATE TABLE test
(
    id integer NOT NULL
);
CREATE TABLE test2
(
    num_value1 integer NOT NULL,
    num_value2 integer NOT NULL
);

INSERT INTO spec_table VALUES (1, 'spec_table', 'id', 1);

CREATE OR REPLACE FUNCTION update_spec()
    RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    max_value INT;
BEGIN
    EXECUTE format('SELECT MAX(%s) FROM new_table', quote_ident(tg_argv[0])) INTO max_value;
    UPDATE spec_table SET max_value_id = max_value WHERE name_table = tg_table_name AND name_column = tg_argv[0] AND max_value > max_value_id;
    RETURN NEW;
END;
$$;




CREATE OR REPLACE FUNCTION trigger_next_id(table_name_ VARCHAR, column_name_ VARCHAR, out _max_id INT)
    LANGUAGE plpgsql AS $$
declare 
	triggers_count integer;
BEGIN
    UPDATE spec_table SET max_value_id = max_value_id + 1
                      WHERE name_table = table_name_ AND name_column = column_name_ RETURNING max_value_id INTO _max_id;
    IF _max_id IS NULL then
    
    	IF NOT EXISTS (SELECT * from information_schema.tables where table_name = table_name_) THEN
            RAISE EXCEPTION 'Не существует таблицы %', table_name_;
        END IF;
       
        IF NOT EXISTS (SELECT * from information_schema.columns where table_name = table_name_ and column_name = column_name_) THEN
             RAISE EXCEPTION 'Не существует столбца % в таблице %', column_name_, table_name_;
        END IF;
       
        IF (SELECT DATA_TYPE FROM information_schema.columns WHERE table_name = table_name_ and column_name = column_name_)
            NOT IN ('integer') THEN
            RAISE EXCEPTION 'Тип значений в столбце % не целочисленный', column_name_;
        END IF;
       
       
        EXECUTE  format('SELECT COALESCE(MAX(%s) + 1, 1) FROM %s', quote_ident(column_name_), quote_ident(table_name_)) INTO _max_id;
        INSERT INTO spec_table VALUES(trigger_next_id('spec_table', 'id'), table_name_, column_name_, _max_id);
       
       	SELECT count(*) into triggers_count from information_schema.triggers where event_object_table = table_name_;
       
       	LOOP
        triggers_count = triggers_count + 1;
        EXIT WHEN NOT EXISTS(SELECT * from information_schema.triggers
                            where trigger_name = quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count));
        END LOOP;


        EXECUTE ('CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count)
                     || ' AFTER INSERT ON ' || quote_ident(table_name_) || ' REFERENCING NEW TABLE AS new_table' ||
                     ' FOR EACH STATEMENT EXECUTE FUNCTION update_spec ('
                     || quote_literal(column_name_) || ')');
                            
        LOOP
        triggers_count = triggers_count + 1;
        EXIT WHEN NOT EXISTS(SELECT * from information_schema.triggers
                            where trigger_name = quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count));
        END LOOP;            
       
       
        EXECUTE ('CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_' || column_name_ || '_' || triggers_count)
                     || ' AFTER UPDATE ON ' || quote_ident(table_name_) || ' REFERENCING NEW TABLE AS new_table' ||
                     ' FOR EACH STATEMENT EXECUTE FUNCTION update_spec ('
                     || quote_literal(column_name_) || ')');

    END IF;
END;
$$;


SELECT trigger_next_id('spec_table', 'id');
SELECT * FROM spec_table;

drop table if exists baby;
create table baby(numbers1 integer, numbers2 integer, words varchar);

insert into baby values(1, 2, 'three');
insert into baby values(4, 5, 'six');
insert into test values (1);

create trigger test2_num_value1_15
after update on test2
referencing new table as new_table for each STATEMENT
EXECUTE FUNCTION update_spec(id);

create trigger test2_num_value1_14
after update on test2
referencing new table as new_table for each STATEMENT
EXECUTE FUNCTION update_spec(id);


select trigger_next_id('test2','num_value1');
select trigger_next_id('test','id');
select trigger_next_id('baby', 'numbers1');
select trigger_next_id('spec_table','id');

select * from information_schema.triggers;




DROP FUNCTION if exists trigger_next_id(_name_table varchar, _name_column varchar);
DROP TABLE test;
DROP TABLE test2;
DROP TABLE spec_table;
