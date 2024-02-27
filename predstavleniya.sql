CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

CREATE TABLE courses (
    id SERIAL PRIMARY KEY,
    course_name VARCHAR(255) NOT NULL
);

CREATE TABLE student_courses (
    student_id INTEGER REFERENCES students(id),
    course_id INTEGER REFERENCES courses(id),
    grade INTEGER NOT NULL,
    PRIMARY KEY (student_id, course_id)
);


CREATE VIEW student_course_view AS
SELECT s.name AS student_name, c.course_name, sc.grade
FROM students s
JOIN student_courses sc ON s.id = sc.student_id
JOIN courses c ON c.id = sc.course_id;


CREATE OR REPLACE FUNCTION insert_student_course_view() RETURNS TRIGGER AS $$
DECLARE
    student_id INTEGER;
    course_id INTEGER;
BEGIN
    SELECT id INTO student_id FROM students WHERE name = NEW.student_name;
    IF NOT FOUND THEN
        INSERT INTO students (name) VALUES (NEW.student_name) RETURNING id INTO student_id;
    END IF;

    SELECT id INTO course_id FROM courses WHERE course_name = NEW.course_name;
    IF NOT FOUND THEN
        INSERT INTO courses (course_name) VALUES (NEW.course_name) RETURNING id INTO course_id;
    END IF;

    INSERT INTO student_courses (student_id, course_id, grade) VALUES (student_id, course_id, NEW.grade);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_student_course_view_trigger
INSTEAD OF INSERT ON student_course_view
FOR EACH ROW EXECUTE FUNCTION insert_student_course_view();


CREATE OR REPLACE FUNCTION update_student_course_view() RETURNS TRIGGER AS $$
BEGIN
    UPDATE student_courses
    SET grade = NEW.grade
    WHERE student_id = (SELECT id FROM students WHERE name = OLD.student_name)
    AND course_id = (SELECT id FROM courses WHERE course_name = OLD.course_name);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_student_course_view_trigger
INSTEAD OF UPDATE ON student_course_view
FOR EACH ROW EXECUTE FUNCTION update_student_course_view();


CREATE OR REPLACE FUNCTION delete_student_course_view() RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM student_courses
    WHERE student_id = (SELECT id FROM students WHERE name = OLD.student_name)
    AND course_id = (SELECT id FROM courses WHERE course_name = OLD.course_name);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER delete_student_course_view_trigger
INSTEAD OF DELETE ON student_course_view
FOR EACH ROW EXECUTE FUNCTION delete_student_course_view();



insert into student_course_view values ('mikhail','teorver',2);
insert into student_course_view values ('grisha','syap',3);
insert into student_course_view values ('grisha', 'baby',2);

UPDATE student_course_view SET grade = 95 WHERE student_name = 'grisha' AND course_name = 'syap';

DELETE FROM student_course_view WHERE student_name = 'mikhail' AND course_name = 'teorver';

select * from students;
select * from courses;
select * from student_courses;



drop table if exists students cascade;
drop table if exists courses cascade;
drop table if exists student_courses cascade;
drop view if exists student_course_view cascade;