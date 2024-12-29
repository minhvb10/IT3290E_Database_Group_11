-- Function to check borrower's eligibility
CREATE OR REPLACE FUNCTION check_borrower_eligibility()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if borrower is blacklisted
    IF EXISTS (SELECT 1 FROM borrower WHERE borrower_id = NEW.borrower_id AND black_list = true) THEN
        RAISE EXCEPTION 'Borrower is blacklisted and cannot borrow books';
    END IF;

    -- Check if borrower has sufficient deposit
    IF (SELECT deposit FROM borrower WHERE borrower_id = NEW.borrower_id) < 100000 THEN
        RAISE EXCEPTION 'Insufficient deposit. Minimum deposit of 100,000 VND required';
    END IF;

    -- Check if borrower has less than 3 books currently borrowed
    IF (SELECT COUNT(*) FROM loan 
        WHERE borrower_id = NEW.borrower_id 
        AND return_date IS NULL) >= 3 THEN
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
    -- Set borrow date to current date if not specified
    IF NEW.borrow_date IS NULL THEN
        NEW.borrow_date := CURRENT_DATE;
    END IF;
    
    -- Set due date to 3 months from borrow date
    NEW.due_date := NEW.borrow_date + INTERVAL '3 months';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to set loan period automatically
CREATE TRIGGER set_loan_period_trigger
BEFORE INSERT ON loan
FOR EACH ROW
EXECUTE FUNCTION set_loan_period();

-- Function to handle book returns and calculate fees
CREATE OR REPLACE FUNCTION process_book_return()
RETURNS TRIGGER AS $$
DECLARE
    days_overdue INTEGER;
BEGIN
    -- Calculate overdue days
    days_overdue := EXTRACT(DAY FROM (NEW.return_date - NEW.due_date));
    
    -- Handle late returns
    IF days_overdue > 0 THEN
        -- Deduct late fee from deposit
        UPDATE borrower 
        SET deposit = deposit - 100000
        WHERE borrower_id = NEW.borrower_id;
        
        -- Insert fine record
        INSERT INTO fine (borrow_id, amount, reason) VALUES (NEW.borrow_id, 100000, 'Late return');
    END IF;
    
    -- Handle damaged or lost books
    IF NEW.status = 'damaged' OR NEW.status = 'lost' THEN
        -- Deduct book price from deposit
        UPDATE borrower 
        SET deposit = deposit - (
            SELECT price 
            FROM book 
            WHERE book_id = NEW.book_id
        )
        WHERE borrower_id = NEW.borrower_id;
        
        -- Insert fine record
        INSERT INTO fine (borrow_id, amount, reason) VALUES (NEW.borrow_id, (SELECT price FROM book WHERE book_id = NEW.book_id), 'Damaged or lost book');
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to process returns
CREATE TRIGGER process_return_trigger
BEFORE UPDATE ON loan
FOR EACH ROW
WHEN (OLD.return_date IS NULL AND NEW.return_date IS NOT NULL)
EXECUTE FUNCTION process_book_return();

-- Function to check for overdue books and blacklist borrowers
CREATE OR REPLACE FUNCTION check_overdue_books()
RETURNS void AS $$
BEGIN
    -- Update blacklist status for borrowers with books overdue by 10 days or more
    UPDATE borrower
    SET black_list = true
    WHERE borrower_id IN (
        SELECT DISTINCT borrower_id
        FROM loan
        WHERE return_date IS NULL
        AND CURRENT_DATE - due_date > 10
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

-- Function to search books
CREATE OR REPLACE FUNCTION search_books(
    p_title VARCHAR = NULL,
    p_genre_id CHAR(8) = NULL,
    p_author_id CHAR(8) = NULL,
    p_publisher_id CHAR(8) = NULL
)
RETURNS TABLE (
    book_id CHAR(8),
    title VARCHAR,
    genre_name VARCHAR,
    author_name VARCHAR,
    publisher_name VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT DISTINCT b.book_id, b.title, g.name AS genre_name, a.name AS author_name,
        p.name AS publisher_name
    FROM book b JOIN genre g ON b.genre_id = g.genre_id
                JOIN writen w ON b.book_id = w.book_id
                JOIN author a ON w.author_id = a.author_id
                JOIN publisher p ON b.publisher_id = p.publisher_id
    WHERE (p_title IS NULL OR b.title ILIKE '%' || p_title || '%') -- Handle case-insensitive pattern matching
    AND (p_genre_id IS NULL OR b.genre_id = p_genre_id)
    AND (p_author_id IS NULL OR w.author_id = p_author_id)
    AND (p_publisher_id IS NULL OR b.publisher_id = p_publisher_id);
END;
$$ LANGUAGE plpgsql;
