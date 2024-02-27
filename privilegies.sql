
drop table if exists project cascade;
drop table if exists task cascade;
drop table if exists users cascade;
drop table if exists commentss cascade;


REVOKE ALL PRIVILEGES ON TABLE orders FROM admin;
REVOKE ALL PRIVILEGES ON TABLE customers FROM admin;
drop user if exists admin;
drop user if exists project_manager;
drop user if exists developer;
drop user if exists client;

CREATE USER admin WITH PASSWORD 'admin_password';
CREATE USER project_manager WITH PASSWORD 'pm_password';
CREATE USER developer WITH PASSWORD 'dev_password';
CREATE USER client WITH PASSWORD 'client_password';

CREATE TABLE project (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    start_date DATE,
    end_date DATE
);


CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    role VARCHAR(50)
);

CREATE TABLE task (
    id SERIAL PRIMARY KEY,
    project_id INTEGER REFERENCES project(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    status VARCHAR(50),
    priority INTEGER,
    assignee_id INTEGER REFERENCES users(id),
    due_date DATE
);


CREATE TABLE commentss (
    id SERIAL PRIMARY KEY,
    task_id INTEGER REFERENCES task(id),
    user_id INTEGER REFERENCES users(id),
    content TEXT,
    created_at TIMESTAMP
);

-- Администратор
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA a TO admin;

-- Менеджер проекта
GRANT SELECT, INSERT, UPDATE ON project, task TO project_manager;
GRANT SELECT ON users TO project_manager;
GRANT SELECT, INSERT ON commentss TO project_manager;

-- Разработчик
GRANT SELECT ON project, task, users TO developer;
GRANT SELECT, INSERT ON commentss TO developer;

-- Заказчик
GRANT SELECT ON project, task TO client;
GRANT SELECT, INSERT ON commentss TO client;


SELECT table_name, privilege_type
FROM information_schema.table_privileges
WHERE grantee = 'client';


