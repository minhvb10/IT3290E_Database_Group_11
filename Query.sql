--1 
--Retrieve the list of books published by a publisher whose name is Ace
SELECT b.*
FROM book b
JOIN publisher p ON p.publisher_id = b.publisher_id
WHERE p.name = 'Ace';

CREATE INDEX idx_1 ON publisher(name);

--2
--Retrieve the list of borrowers who borrowed at least one book in 2021
SELECT DISTINCT b.*
FROM borrower b
JOIN loan l ON l.borrower_id = b.borrower_id
WHERE EXTRACT(YEAR FROM l.borrow_date) = 2021;

--3
--List of books have been borrowed by the current date
SELECT b.* 
FROM book b
JOIN loan l ON b.book_id = l.book_id
WHERE l.borrow_date = CURRENT_DATE;

CREATE INDEX idx_3 ON loan(borrow_date);

--4
--Retrieve the list of books that have amount greater than 3
SELECT title, COUNT(*) AS number_of_book
FROM book
GROUP BY title
HAVING COUNT(*) > 3;

--5
--Retrieve the list of books and their genre
SELECT b.*, g.name
FROM book b
JOIN genre g ON g.genre_id = b.genre_id;

--6
--List of borrowers who have borrowed more than 5 books in June
SELECT br.*
FROM borrower br
JOIN loan l ON l.borrower_id = br.borrower_id
JOIN book bk ON bk.book_id = l.book_id
WHERE EXTRACT(MONTH FROM l.borrow_date) = 6
GROUP BY br.borrower_id
HAVING COUNT(l.book_id) > 5;
	
--7
--Determine the number of books borrowed by borrower with ID "1576"
SELECT COUNT(l.book_id)
FROM loan l
WHERE borrower_id = '1576';

create index idx_7 on loan(borrower_id)

--8
--List the borrowers who have borrowed both book titled "Ukridge" and "The Log from the Sea of Cortez"
SELECT br.*
FROM borrower br
JOIN loan l ON l.borrower_id = br.borrower_id
JOIN book bk ON bk.book_id = l.book_id
WHERE bk.title = 'The Wise Woman'
INTERSECT
SELECT br.*
FROM borrower br
JOIN loan l ON l.borrower_id = br.borrower_id
JOIN book bk ON bk.book_id = l.book_id
WHERE bk.title = 'Spares';

create index idx_8 on loan(book_id)

--9
--Retrieve the list of authors and their title books
SELECT a.*, b.title
FROM author a
JOIN write w ON a.author_id = w.author_id
JOIN book b ON w.book_id = b.book_id;

--10
--List of the most borrowed book genre
SELECT g.name, COUNT(g.genre_id) AS count
FROM genre g
JOIN book b ON g.genre_id = b.genre_id
JOIN loan l ON l.book_id = b.book_id
GROUP BY g.genre_id
HAVING COUNT(g.genre_id) >= ALL 
(
SELECT COUNT(g.genre_id) AS count_book
FROM genre g
JOIN book b ON g.genre_id = b.genre_id
JOIN loan l ON l.book_id = b.book_id
GROUP BY g.genre_id
);

-- 11. List borrowers who have overdue (return_date > due_date) loans
SELECT b.borrower_id, b.name, l.loan_id, (CURRENT_DATE - l.date) AS days_overdue
FROM borrower b
JOIN loan l ON b.borrower_id = l.borrower_id
WHERE l.return_date IS NULL
  AND l.date < CURRENT_DATE;

-- 12. Top 10 borrowers who borrowed the most books
SELECT b.borrower_id, b.name, COUNT(l.book_id) AS total_books
FROM borrower b
JOIN loan l ON b.borrower_id = l.borrower_id
GROUP BY b.borrower_id, b.name
ORDER BY total_books DESC
LIMIT 10;

-- 13. Books not borrowed in last 6 months
SELECT book_id, title
FROM book
WHERE book_id NOT IN (
    SELECT DISTINCT book_id
    FROM loan
    WHERE loan.date >= CURRENT_DATE - INTERVAL '6 months'
);

-- 14. Average book price by languages
SELECT languages, AVG(price) AS avg_price
FROM book
GROUP BY languages
HAVING AVG(price) > 0;


-- 15. Borrowers who have never returned a book on time
SELECT DISTINCT b.borrower_id, b.name
FROM borrower b
JOIN loan l ON b.borrower_id = l.borrower_id
WHERE l.return_date IS NOT NULL
  AND l.return_date > l.date;

-- 16. Count of blacklisted borrowers
SELECT COUNT(*) AS total_black_list
FROM borrower
WHERE black_list = TRUE;

-- 17. List borrowers with total borrowed books and total deposit
SELECT b.borrower_id, b.name,  b.deposit,
       (SELECT COUNT(*) FROM loan l WHERE l.borrower_id = b.borrower_id) AS total_loan
FROM borrower b;

-- 18. Books borrowed more than once
SELECT book_id, COUNT(*) AS borrow_count
FROM loan
GROUP BY book_id
HAVING COUNT(*) > 1;

-- 19. Overdue loans older than 10 days
SELECT l.loan_id, b.borrower_id, (CURRENT_DATE - l.date) AS overdue_days
FROM loan l
JOIN borrower b ON l.borrower_id = b.borrower_id
WHERE l.return_date IS NULL
  AND (CURRENT_DATE - l.date) > 10;


-- 20. List borrowers who borrowed more than 2 books in the last month
WITH recent_loan AS (
    SELECT borrower_id, COUNT(*) AS loan_count
    FROM loan
    WHERE date >= CURRENT_DATE - INTERVAL '1 month'
    GROUP BY borrower_id
)
SELECT b.borrower_id, b.name, r.loan_count
FROM borrower b
JOIN recent_loan r ON b.borrower_id = r.borrower_id
WHERE r.loan_count > 2;

-- 21: Contact list of members that have not pay their fees
FROM borrower
WHERE borrower_id IN (
SELECT borrower_id FROM loan
WHERE fee >0
AND fee_paid = false);

--  22. List of borrowers who repeat borrow for same books
SELECT borrower_id, name, phone, address, email 
FROM borrower
WHERE borrower_id IN (
SELECT borrower_id FROM loan
WHERE fee > 0
AND fee_paid = false);

-- 23. Book cannot be borrowed
SELECT * FROM book
WHERE book_id IN (
SELECT book_id FROM loan
WHERE date is NULL);

-- 24. Frequency of borrowing books of members 
SELECT b.borrower_id, b.name, 
count(distinct l.borrow_date) AS borrow_count  FROM borrower b
JOIN loan l using (borrower_id)
GROUP BY b.borrower_id, b.name
ORDER BY borrow_count DESC;

-- 25. Most borrowed book
SELECT b.book_id, b.title,
count(l.book_id) AS borrow_times
FROM book b JOIN loan l using (book_id)
GROUP BY book_id
ORDER BY borrow_times DESC
LIMIT 1;

-- 26. LIST OF STAFF WHOSE AGE OVER 50
WITH tmp AS (
SELECT staff_id, name, 
EXTRACT(YEAR FROM AGE(CURRENT_DATE, dob)) AS age
FROM staff)
SELECT * FROM tmp
WHERE age > 50;

-- 27. STAFF NEVERS UPDATE BOOK
SELECT s.staff_id, s.name FROM staff s
LEFT JOIN update_table u USING(staff_id)
WHERE book_id is NULL;

-- 28. NUMBERS OF BOOK IN EACH LANGUAGE 
SELECT languages, count(*) FROM book
GROUP BY languages;

-- 29. List all books borrowed by a specific borrower along with the borrow and return dates
SELECT b.book_id, b.title, l.borrow_date, l.return_date
FROM book b
JOIN loan l ON b.book_id = l.book_id
WHERE l.borrower_id = 'B1234567';

-- 30. Find the total number of books borrowed and returned by each borrower
SELECT br.borrower_id, br.name, 
       COUNT(l.loan_id) FILTER (WHERE l.return_date IS NOT NULL) AS total_returned,
       COUNT(l.loan_id) FILTER (WHERE l.return_date IS NULL) AS total_borrowed
FROM borrower br
JOIN loan l ON br.borrower_id = l.borrower_id
GROUP BY br.borrower_id, br.name;
