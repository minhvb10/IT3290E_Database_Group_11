-- Function to check borrower's eligibility
CREATE OR REPLACE FUNCTION check_borrower_eligibility()
RETURNS TRIGGER AS $$
DECLARE 
    cur_deposit INT;
BEGIN
    SELECT deposit INTO cur_deposit FROM borrower 
    WHERE borrower_id = NEW.borrower_id;

    -- Check if borrower is blacklisted
    IF EXISTS (SELECT * FROM borrower WHERE borrower_id = NEW.borrower_id AND black_list = true) THEN
        RAISE EXCEPTION 'Borrower is blacklisted and cannot borrow books';
    END IF;

     -- Check if borrower has sufficient deposit
    IF cur_deposit = 0  THEN
        RAISE EXCEPTION 'Not enough deposit to borrow book';
    END IF;

    -- Check if borrower has less than 3 books currently borrowed
    IF (SELECT COUNT(*) FROM loan 
        WHERE borrower_id = NEW.borrower_id 
        AND date IS NULL) >= 3 THEN
        RAISE EXCEPTION 'Maximum borrowing limit (3 books) reached';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to check eligibility before allowing new loans
CREATE TRIGGER check_eligibility_before_loan
BEFORE INSERT ON loan
FOR EACH ROW
EXECUTE FUNCTION check_borrower_eligibility();

-- Function to set loan period and due date
CREATE OR REPLACE FUNCTION set_loan_period()
RETURNS TRIGGER AS $$
BEGIN
    NEW.borrow_date := CURRENT_DATE;
    -- Set expected return date to 3 months from borrow date
    NEW.return_date := NEW.borrow_date + INTERVAL '3 months';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set loan period automatically
CREATE TRIGGER set_loan_period_trigger
AFTER INSERT ON loan
FOR EACH ROW
EXECUTE FUNCTION set_loan_period();

-- Function to handle book returns 
CREATE OR REPLACE FUNCTION process_book_return()
RETURNS TRIGGER AS $$
DECLARE
    days_overdue INTEGER;
BEGIN
    -- Calculate overdue days
    days_overdue := EXTRACT(DAY FROM (NEW.return_date - NEW.date));
    
    -- Handle over 10 days late returns
    IF days_overdue > 10 THEN
        UPDATE borrower
        SET black.list = TRUE
        WHERE borrower_id = NEW.borrower_id;
        RAISE EXCEPTION 'Returning book late over 10 days! Borrower is now blacklisted and cannot borrow books';
    -- Handle late returns
    ELSEIF days_overdue > 0 THEN
        -- Deduct late fee from deposit
        UPDATE borrower 
        SET deposit = deposit - 100000
        WHERE borrower_id = NEW.borrower_id;
        RAISE EXCEPTION 'Returning book late! Borrower deposit has been deducted';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to process returns
CREATE TRIGGER process_return_trigger
BEFORE UPDATE ON loan
FOR EACH ROW
WHEN (OLD.date IS NULL AND NEW.date IS NOT NULL)
EXECUTE FUNCTION process_book_return();

-- Function to update blacklist status for borrowers with books overdue by 10 days or more
CREATE OR REPLACE FUNCTION update_blacklist_books()
RETURNS void AS $$
BEGIN
    -- Update blacklist status for borrowers with books overdue by 10 days or more
    UPDATE borrower
    SET black_list = true
    WHERE borrower_id IN (
        SELECT borrower_id
        FROM loan
        WHERE date IS NULL
        AND CURRENT_DATE - return_date > 10
        INTERSECT 
        SELECT borrower_id
        FROM loan
        WHERE date IS NOT NULL
        AND date - return_date > 10
    );
END;
$$ LANGUAGE plpgsql;

-- Create a function to initialize new borrower accounts
CREATE OR REPLACE FUNCTION initialize_borrower()
RETURNS TRIGGER AS $$
BEGIN
    --Initial deposit amount
    NEW.deposit := 100000;
    NEW.black_list := false;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to initialize new borrower accounts
CREATE TRIGGER initialize_borrower_trigger
BEFORE INSERT ON borrower
FOR EACH ROW
EXECUTE FUNCTION initialize_borrower();

-- Function to search books (case insensitive)
CREATE OR REPLACE FUNCTION search_books(p_title VARCHAR = NULL)
RETURNS TABLE (book_id CHAR(8), title VARCHAR(400), genre_name VARCHAR(30), 
    author_name CHAR(100), publisher_name VARCHAR(100)) AS $$
DECLARE total_books INT;
        loaned_books INT;
BEGIN
    IF p_title IS NOT NULL THEN
        SELECT COUNT(b.book_id) INTO total_books
        FROM book b 
        WHERE  b.title ILIKE '%' || p_title || '%';

        SELECT COUNT(l.loan_id) INTO loaned_books
        FROM loan l JOIN book b using(book_id)
        WHERE b.title ILIKE '%' || p_title || '%'
        AND date IS NULL ;

        IF loaned_books = total_books THEN
            RAISE EXCEPTION 'There is no left book to borrow' ;
        END IF;
    END IF; 
    RETURN QUERY
    SELECT DISTINCT b.book_id, b.title, g.name AS genre_name, a.author_name AS author_name,
        p.name AS publisher_name
    FROM book b JOIN genre g ON b.genre_id = g.genre_id
                JOIN written w ON b.book_id = w.book_id
                JOIN author a ON w.author_id = a.author_id
                JOIN publisher p ON b.publisher_id = p.publisher_id
    WHERE (p_title IS NULL OR b.title ILIKE '%' || p_title || '%') ;
END;
$$ LANGUAGE plpgsql;


-- Function to handle damaged book returns 
CREATE OR REPLACE FUNCTION handle_damaged_book_return()
RETURNS TRIGGER AS $$
DECLARE
    book_price INTEGER;
BEGIN
    SELECT price INTO book_price FROM book;
    UPDATE loan SET NEW.fee = book_price
    WHERE loan_id = NEW.loan_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to handle damaged book returns 
CREATE TRIGGER trigger_handle_damaged_book_return
BEFORE UPDATE ON loan
FOR EACH ROW
WHEN (NEW.damaged = True)
EXECUTE FUNCTION handle_damaged_book_return();
