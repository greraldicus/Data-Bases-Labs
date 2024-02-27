drop schema if exists a cascade;

CREATE SCHEMA a;

CREATE TABLE a.people (
    person_id SERIAL PRIMARY KEY,
    name TEXT NOT null,
    balance decimal(10,2) not null
);


insert into a.people values (1,'mikhail','101');
insert into a.people values (2,'grisha','-1');
insert into a.people values (3,'pavel','0');
select * from a.people;


--Фантомное чтение
--read committed => repeatable read;
--BEGIN TRANSACTION ISOLATION LEVEL repeatable read;
--select * from a.people where name = 'pavel';
--select pg_sleep(5);
--select * from a.people where name = 'pavel';
--COMMIT;


--Неповторяемое чтение
--read committed => repeatable read;
--BEGIN TRANSACTION ISOLATION LEVEL repeatable read;
--select * from a.people where name = 'pavel';
--select pg_sleep(5);
--select * from a.people where name = 'pavel';
--COMMIT;

--Аномалия сериализации
--repeatable read => serializable;
--BEGIN TRANSACTION ISOLATION LEVEL serializable;
--update a.people set balance = '1000' where name = 'pavel';
--select pg_sleep(5);
--select * from a.people;
--COMMIT;


--BEGIN TRANSACTION ISOLATION LEVEL read uncommitted;
--insert into a.people values (4,'viktor','44');
--select pg_sleep(5);
--rollback transaction;


--begin transaction;
--savepoint moneyback;
--update a.people set balance = 1000 where name = 'mikhail';
--select * from a.people;
--rollback to moneyback;
--update a.people set balance = -1000 where name = 'mikhail';
--commit;
--select * from a.people;




Скрипт 2


--Фантомное чтение
--read committed => repeatable read;
--BEGIN TRANSACTION ISOLATION LEVEL repeatable read;
--=> serializable;
--insert into a.people values (4,'pavel',55);
--commit;

--Неповторяющееся чтение
--read committed => repeatable read;
--BEGIN TRANSACTION ISOLATION LEVEL repeatable read;
--update a.people set balance = -1000 where name = 'pavel';
--commit;


--Аномалия сериализации
--repeatable read => serializable;
--BEGIN TRANSACTION ISOLATION level serializable;
--update a.people set balance = '-1000' where name = 'pavel';
--select pg_sleep(5);
--select * from a.people;
--COMMIT;




--BEGIN TRANSACTION ISOLATION LEVEL read uncommitted;
--select * from a.people;
--commit;