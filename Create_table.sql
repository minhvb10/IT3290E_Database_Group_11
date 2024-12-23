CREATE DATABASE dbproject;
\c dbproject;

CREATE TABLE book (
book_id char(8) NOT NULL,
publisher_id char(8) NOT NULL,
genre_id char(8) NOT NULL,
title varchar(30) NOT NULL,
languages varchar(20),
publish_year int,
book_count int,
CONSTRAINT pk_book PRIMARY KEY (book_id)
);

CREATE TABLE publisher (
publisher_id char(8) NOT NULL,
name varchar(30),
CONSTRAINT pk_write PRIMARY KEY (publisher_id)
);

CREATE TABLE genre (
genre_id char(8) NOT NULL,
name varchar(30),
CONSTRAINT pk_genre PRIMARY KEY (genre_id)
);

CREATE TABLE author (
author_id char(8) NOT NULL,
name varchar(30)
);

CREATE TABLE writen (
author_id char(8) NOT NULL,
book_id char(8) NOT NULL
);

CREATE TABLE loan (
loan_id char(8) NOT NULL,
book_id char(8) NOT NULL,
borrower_id char(8) NOT NULL,
staff_id char(8) NOT NULL,
borrow_date date,
return_date date,
date date,
fee int,
book_paid boolean,
fee_paid boolean,
damaged boolean,
CONSTRAINT pk_loan PRIMARY KEY (loan_id)
);

CREATE TABLE borrower (
borrower_id char(8) NOT NULL,
name varchar(20) NOT NULL,
phone char(10),
address varchar(30),
email varchar(20),
dob date,
deposit int,
black_list boolean,
CONSTRAINT pk_borrower PRIMARY KEY (borrower_id)
);

CREATE TABLE staff (
staff_id char(8) NOT NULL,
name varchar(20) NOT NULL,
phone char(10),
dob date, 
CONSTRAINT pk_staff PRIMARY KEY (staff_id)
);

CREATE TABLE update_table(
book_id char(8),
staff_id char(8),
update_date date
);

-- ADD CONSTRAINT OF book TABLE
ALTER TABLE book ADD CONSTRAINT fk_book2publisher FOREIGN KEY (publisher_id) REFERENCES publisher (publisher_id);
ALTER TABLE book ADD CONSTRAINT fk_book2genre FOREIGN KEY (genre_id) REFERENCES genre (genre_id);


-- ADD CONSTRAINT OF author TABLE
ALTER TABLE author ADD CONSTRAINT pk_author PRIMARY KEY (author_id);

-- ADD CONSTRAINT OF writen TABLE
ALTER TABLE writen ADD CONSTRAINT fk_write2book FOREIGN KEY (book_id) REFERENCES book (book_id);
ALTER TABLE writen ADD CONSTRAINT fk_write2author FOREIGN KEY (author_id) REFERENCES author (author_id);

-- ADD CONSTRAINT OF loan TABLE
ALTER TABLE loan ADD CONSTRAINT fk_loan2book FOREIGN KEY (book_id) REFERENCES book (book_id);
ALTER TABLE loan ADD CONSTRAINT fk_loan2borrower FOREIGN KEY (borrower_id) REFERENCES borrower (borrower_id);
ALTER TABLE loan ADD CONSTRAINT fk_loan2staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id);


-- ADD CONSTRAINT OF update TABLE
ALTER TABLE update_table ADD CONSTRAINT fk_update2book FOREIGN KEY (book_id) REFERENCES book (book_id);
ALTER TABLE update_table ADD CONSTRAINT fk_update2staff FOREIGN KEY (staff_id) REFERENCES staff (staff_id);
