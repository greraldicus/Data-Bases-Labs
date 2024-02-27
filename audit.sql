drop table if exists baby;
drop table if exists users;
drop table if exists products;

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  password TEXT NOT NULL
);

CREATE TABLE products (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  price NUMERIC(10, 2) NOT NULL,
  description TEXT
);



CREATE OR REPLACE FUNCTION create_audit_tables() RETURNS void AS $$
DECLARE
  table_name_ text;
  column_name_ text;
  column_type text;
  column_list text;
  audit_table_name text;
BEGIN
  FOR table_name_ IN (SELECT table_name FROM information_schema.tables WHERE table_schema = 'a' AND table_type = 'BASE TABLE') LOOP
    audit_table_name := quote_ident(table_name_) || '_audit';
    column_list := '';
    FOR column_name_, column_type IN (SELECT column_name, data_type FROM information_schema.columns WHERE table_name = table_name_) LOOP
      column_list := column_list || quote_ident(column_name_) || ' ' || column_type || ', ';
    END LOOP;
    column_list := column_list || 'modified_at timestamp, modified_by text, modification_type text';
    EXECUTE 'CREATE TABLE ' || quote_ident(audit_table_name) || ' (' || column_list || ')';
    EXECUTE 'CREATE TRIGGER ' || quote_ident(audit_table_name || '_insert') || ' AFTER INSERT ON ' || quote_ident(table_name_) || ' FOR EACH ROW EXECUTE PROCEDURE audit_insert()';
    EXECUTE 'CREATE TRIGGER ' || quote_ident(audit_table_name || '_update') || ' AFTER UPDATE ON ' || quote_ident(table_name_) || ' FOR EACH ROW EXECUTE PROCEDURE audit_update()';
    EXECUTE 'CREATE TRIGGER ' || quote_ident(audit_table_name || '_delete') || ' AFTER DELETE ON ' || quote_ident(table_name_) || ' FOR EACH ROW EXECUTE PROCEDURE audit_delete()';
  END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION audit_insert() RETURNS trigger AS $$
BEGIN
  INSERT INTO audit_table_name SELECT NEW.*, now(), current_user, TG_OP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_update() RETURNS trigger AS $$
BEGIN
  INSERT INTO audit_table_name SELECT NEW.*, now(), current_user, TG_OP;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_delete() RETURNS trigger AS $$
BEGIN
  INSERT INTO audit_table_name SELECT OLD.*, now(), current_user, TG_OP;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

SELECT create_audit_tables();
SELECT table_name FROM information_schema.tables WHERE table_schema = 'a' AND table_type = 'BASE TABLE' AND table_name LIKE '%_audit';

