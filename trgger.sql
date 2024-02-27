-- create a table
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

INSERT INTO spec_table VALUES (1, 'spec', 'id', 1);

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
BEGIN
    UPDATE spec_table SET max_value_id = max_value_id + 1
                      WHERE name_table = table_name_ AND name_column = column_name_ RETURNING max_value_id INTO _max_id;
    IF _max_id IS NULL THEN
        EXECUTE  format('SELECT COALESCE(MAX(%s) + 1, 1) FROM %s', quote_ident(column_name_), quote_ident(table_name_)) INTO _max_id;
        INSERT INTO spec_table VALUES(trigger_next_id('spec', 'id'), table_name_, column_name_, _max_id);

        EXECUTE ('CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_' || column_name_ || '_in')
                     || ' AFTER INSERT ON ' || quote_ident(table_name_) || ' REFERENCING NEW TABLE AS new_table' ||
                     ' FOR EACH STATEMENT EXECUTE FUNCTION update_spec ('
                     || quote_literal(column_name_) || ')');
        EXECUTE ('CREATE OR REPLACE TRIGGER ' || quote_ident(table_name_ || '_' || column_name_ || '_up')
                     || ' AFTER UPDATE ON ' || quote_ident(table_name_) || ' REFERENCING NEW TABLE AS new_table' ||
                     ' FOR EACH STATEMENT EXECUTE FUNCTION update_spec ('
                     || quote_literal(column_name_) || ')');

    END IF;
END;
$$;


SELECT trigger_next_id('spec', 'id');
SELECT * FROM spec_table;
SELECT trigger_next_id('spec', 'id');
SELECT * FROM spec_table;
INSERT INTO test VALUES (10);
SELECT trigger_next_id('test', 'id');
SELECT * FROM spec_table;


DROP FUNCTION trigger_next_id(_name_table varchar, _name_column varchar);
DROP TABLE test;
DROP TABLE test2;
DROP TABLE spec_table;
