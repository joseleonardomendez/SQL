--
-- Welcome to Task 2 !!
--
-- Advanced RDB and SQL

-- CREATE TABLES

CREATE TABLE customer(
customer_id CHAR(10) PRIMARY KEY,
customer_name VARCHAR(50),
credit_limit INT
);

CREATE TABLE customer_order(
customer_order_id CHAR(10) PRIMARY KEY,
customer_id CHAR(10)
);

CREATE TABLE customer_order_line_item(
customer_order_id CHAR(10),
merchandise_item_id CHAR(10),
quantity INT,
PRIMARY KEY (customer_order_id, merchandise_item_id),
FOREIGN KEY(customer_order_id) REFERENCES customer_order(customer_order_id) ON DELETE CASCADE
);

CREATE TABLE merchandise_item(
merchandise_item_id CHAR(10),
description VARCHAR(50),
unit_price INT,
qoh INT,
bundle_id CHAR(10),
PRIMARY KEY (merchandise_item_id)
);


-- SERVER FUNCTIONS

USE advanced_sql_project_coursera;

-- AGGREGATE FUNCTIONS
-- Aggregate functions are functions that take a bunch of values or a bunch of rows from the table and return a single value.

SELECT COUNT(*) FROM customer;

SELECT MAX(qoh) FROM merchandise_item;

SELECT MIN(unit_price)/100 FROM merchandise_item;

SELECT AVG(unit_price)/100 
AS average_price FROM
merchandise_item;

SELECT SUM(quantity) FROM customer_order_line_item;


-- NON-AGGREGATE FUNCTIONS 

SELECT FORMAT(unit_price/100, 2, "en_IN")
AS unit_price_decimal
FROM merchandise_item;

SELECT CONCAT(CHAR_LENGTH(description), "chars")
FROM merchandise_item;

-- Write an SQL statement to:

-- find the average all the unit_price in the table merchandise_item
-- (don't forget to divide it by 100)
-- format it to 2 decimal places and use country code "en_IN" for Indian English
-- add the Rupee symbol ₹ in front of it, copy and paste it if you'd like

SELECT CONCAT("₹", FORMAT(AVG(unit_price)/100, 2, "es_IN"))
FROM merchandise_item;



-- Task 3 !!

-- STORED FUNCTIONS

-- Store functions are like little pieces of program that you can store in the database and execute later in different places.
-- You can just call it like a function.

DROP FUNCTION IF EXISTS check_credit;

DELIMITER $$
CREATE FUNCTION check_credit (
	target_item_id CHAR(10)
    )
    RETURNS INT
    
    DETERMINISTIC
    
    BEGIN
    
		RETURN
        (SELECT unit_price FROM merchandise_item
        WHERE merchandise_item_id = target_item_id);
END $$
DELIMITER ;

-- Basically, we're changing that the limiter to something else other than a semicolon because we have to use a semicolon in the definition itself
-- so we cannot use it as the terminator for this entire statement. So we changed it to two dollar signs so we can use it here, and the we can get back to a semicolon.
-- Function can only return one value if it returns anything at all. We're specifying that it's returning an integer
-- The next keyword is DETERMINISTIC or NOT DETERMINISTIC. Deterministic means the function will return the same value every time if we pass the same parameters.
-- not deterministic will mean that it might not return the same values.

DELIMITER $$

CREATE FUNCTION check_credit (
	requesting_customer_id CHAR(10),
	request_amount INT
    )
	RETURNS BOOLEAN

-- It is a check_credit function. It takes a requesting_customer_id And then request_amount. So we are going to look up the customer database and see is
-- customer table and see if they if their credit limit is greater than or equal to the amounts that they are going to put in in an order for.

DETERMINISTIC

-- write an SQL to select the credit_limit
-- from table customer
-- for customer_id matching requesting_customer_id

BEGIN

	RETURN
	(SELECT credit_limit
    FROM customer
    WHERE customer_id = requesting_customer_id
	) >= request_amount;

END $$

DELIMITER ;

-- So you can see that we're using the results of that query and comparing it to the request_amount that they passed in to see if it's greater than or equal to.

-- check to see if the function works
SET @approved = check_credit("C000000001", 4000000);
SELECT @approved;

-- -------------------------------------------------

DROP FUNCTION IF EXISTS get_qoh_ftn;

DELIMITER $$

CREATE FUNCTION get_qoh_ftn (
	request_item_id CHAR(10)
    )
RETURNS INT
    
DETERMINISTIC
   
-- write an SQL to select the qoh (quantity on hand)
-- from table merchandise_item
-- for merchandise_item_id matching request_item_id   
   
BEGIN

	RETURN 
    (SELECT qoh
    FROM merchandise_item
    WHERE merchandise_item_id = request_item_id 
    );


END $$
    
DELIMITER ;


-- check to see if the function works
SET @qty = get_qoh_ftn("KYOTOCBOOK");
SELECT @qty;


-- --------------------------------------------------------------
-- Task 4

-- STORE PROCEDURE


-- unlike a stored function, a stored procedure, first of all, has name just like functions these are the parameters.
-- So it's a list of you can see in and out, and some of them are in out. So in means this is an input only. So even if we change the value in the body, it does not
-- get returned to the caller. Out is where we will pass new values back to the caller so we can have a bunch of those
-- and then just the same way, we'll have a body of definition

DROP PROCEDURE IF EXISTS customer_roster_stp;

DELIMITER $$

CREATE PROCEDURE customer_roster_stp()

-- write an SQL to select all the customer
-- from table customer
-- sort it by customer_name

BEGIN

	SELECT * FROM customer
    ORDER BY customer_name;

END $$

DELIMITER ;

-- check to see if it works
CALL customer_roster_stp();

-- --------------

DROP PROCEDURE IF EXISTS get_qoh_stp;

DELIMITER $$

CREATE PROCEDURE get_qoh_stp(
	IN request_item_id CHAR(10),
    OUT qoh_to_return INT)

-- write an SQL to select the qoh (quantity on hand)
-- from table merchandise_item
-- for merchandise_item_id matching request_item_id
-- note that your statement will not run yet
    
BEGIN

	SELECT qoh INTO qoh_to_return
    FROM merchandise_item
    WHERE merchandise_item_id = request_item_id;
    
END$$

DELIMITER ;

SET @qty = 0;
CALL get_qoh_stp("ITALYPASTA", @qty);
SELECT @qty;


-- --------------------------------------------------------------------------------------------

-- Task 5

-- TRIGGERS

-- So triggers look the same as stored functions and procedures, but the difference is you cannot just call a trigger.
-- It gets called automatically at some events.


-- EXAMPLE

DROP TRIGGER IF EXISTS log_name_change_tgr;
DELIMITER $$

CREATE TRIGGER log_name_change_tgr
	AFTER UPDATE ON customer
    FOR EACH ROW
    
    BEGIN
    
    INSERT INTO name_change_log
    SET old_name = OLD.costumer_name,
		new_name = NEW.customer_name;
        
	END $$   

-- So this trigger here basically says ... whenever a row in the customer table get updated. So after the update they want for each row, we get updated.
-- We want to execute its code in this block, and then the old and new. It's how you get the values. So old, it's before the update.
-- New ... the column name is after the update, so you get both values so you can do something with it.
-- Obviously only insert... for insert.
-- You only have the new, for update. You have old and new and for delete you only have the old values.


DROP TRIGGER IF EXISTS decrease_inventory_tgr;

-- decrease qoh (quantity on hand) after inserting a new line item
-- into the table customer_order_line_item

DELIMITER $$

CREATE TRIGGER decrease_inventory_tgr

	AFTER INSERT ON customer_order_line_item 
    FOR EACH ROW
    
    -- we'll do after insert because that's when we we put the row in the customer order line item.
	-- So the table would be customer order line item, then for each row that gets inserted
    
    -- I'm want to minus the one that the customer ordered, which is, of course, the quantity that we just put into that table. So it will be new dot quantity 
    -- because that's the one that's the quantity they ordered. And then where the merchandise item id equals to would be the new merchandise item id.
    -- That's the one that they ordered. Whenever they put in a row in that table that ... the quantity of that item in the merchandise
	-- item table will get decreased.
    
    BEGIN
    
		UPDATE merchandise_item
        SET qoh = qoh - NEW.quantity
        WHERE merchandise_item_id = NEW.merchandise_item_id;
        
	END $$

DELIMITER ;


-- check qoh (quantity on hand) before inserting a new line item
-- into the table customer_order_line_item

DROP TRIGGER IF EXISTS inventory_check_tgr;

-- this trigger is called inventory check. basically, I want to do before someone put in that order. that line in the table...
-- I want to check to see if we have enough quantity on hand to support that order.

DELIMITER $$

CREATE TRIGGER inventory_check_tgr

	BEFORE INSERT ON customer_order_line_item
    FOR EACH ROW

BEGIN
           
	-- using stored function
           
-- 	IF (get_qoh_ftn(NEW.merchandise_item_id) < NEW.quantity) THEN
-- 		SIGNAL SQLSTATE "45000"
-- 		SET MESSAGE_TEXT = "Insufficient inventory";
-- 	END IF;
        
	-- using stored procedure
    
    -- we are just going to use the stored procedure. So what we have to do is we have to In this block, we have to declare a local variable called inventory, 
    -- which is an integer. And then we're going to call our stored procedure that we created in the last task. We're going to pass the merchandise
	-- item ID ... for as an input and the inventory variable would be our output.
    
    DECLARE inventory INT;
    
    CALL get_qoh_stp(NEW.merchandise_item_id, inventory);
    
    -- after we called the stored procedure, we're going to compare the inventory to the new one that we're going, we're trying to insert into
	-- the table if they ... if there's not enough ... in the inventory is going to do what these two lines do. It's going to signal an SQL error
	-- It's kind of like an exception for the ... Whoever called this function called executed this SQL statement. It's going to receive this error cod
    
	IF (inventory < NEW.quantity) THEN
		SIGNAL SQLSTATE "45000"
		SET MESSAGE_TEXT = "Insufficient inventory";
	END IF;
        
END $$
        
DELIMITER ;

-- check to see if it works!

UPDATE merchandise_item
SET qoh = 10
WHERE merchandise_item_id = "ITALYPASTA";

DELETE FROM customer_order_line_item
WHERE customer_order_id = "D000000003" AND
merchandise_item_id = "ITALYPASTA";

INSERT INTO customer_order_line_item
SET 
customer_order_id = "D000000003",
merchandise_item_id = "ITALYPASTA",
quantity = 5;

-- --------------------------------------------------------------------------------------------------------------------------------

-- Task 6 

-- COMMON TABLE EXPRESSIONS (CTE)

-- So now, unlike all the others things that we've been working on, common table expressions are not entities that got saved, it just a syntax.
-- so you do have to specify it somewhere else. You can use it in all the other things that we've been working on or just by itself.
-- But they are not entities that got saved in the database.

-- We start on this common table expression called order_line_item_cte. Then we have column names

WITH order_line_item_cte (new_name, new_order_id, new_description, order_qty, new_unit_price, line_subtotal ) AS

-- this is the definition of how we create those, and they all have to match. They have to have the same number.
-- They don't have to have the same names. But whatever you select down here, get mapped to these columns up here and then down below.

(

SELECT
customer.customer_name,
customer_order_line_item.customer_order_id,
merchandise_item.description,
customer_order_line_item.quantity,
merchandise_item.unit_price / 100 AS "unit_price_decimal",
customer_order_line_item.quantity * merchandise_item.unit_price / 100 AS "line_total"
FROM customer_order_line_item, customer_order, customer, merchandise_item
WHERE
customer_order_line_item.merchandise_item_id = merchandise_item.merchandise_item_id AND
customer_order.customer_id = customer.customer_id AND
customer_order_line_item.customer_order_id = customer_order.customer_order_id
ORDER BY
customer_name,
customer_order_line_item.customer_order_id,
merchandise_item.description

)

-- After the  definition and down below. We can just use this expression as if it is a table. But this is read only.

SELECT * from order_line_item_cte;


-- write a common table expression
-- call it customer_cte
-- select two columns customer_id and customer_name
-- from the table customer
-- sort by customer_name
-- run it buy select *


WITH customer_cte(customer_id, customer_name) AS

(

SELECT
customer.customer_id, 
customer.customer_name
FROM customer
ORDER BY customer_name
)


SELECT * from customer_cte;

-- This is not saved anywhere in the database. This is just an expression. So you go if you can use this somewhere else or you can save it in the file.
-- But it it's not like a trigger or store procedure or stored function. They are not automatically saved because they're not entities by themselves.


-- ----------------------------------------------------------------------------------------------------------------------------------------------

-- CTE RECURSIVE 

-- We have the column names. 

WITH RECURSIVE merchandise_cte (merchandise_item_id, depth, description, unit_price_decimal, alpha_sort, bundle_id)

-- defining the common table expression

AS ( 

	-- top level items. This section is called anchor that gets executed one time

	SELECT 
		merchandise_item_id,						-- merchandise_item_id
		1,											-- depth
		CAST(description AS CHAR(500)),				-- description
		CAST(unit_price / 100 AS DECIMAL(8, 2)),	-- unit_price_decimal
		CAST(description AS CHAR(700)), 			-- alpha_sort
		bundle_id									-- bundle_id
	FROM merchandise_item

	-- All the result sets get merged into one big result set using UNION ALL

	UNION ALL

	-- these are the contents of the bundles. This is the recursive section... and all the columns, the numbers have to match.
    -- And then that's the recursive section just keeps calling itself until there's a stop condition that's got met. 
    -- So in this case, if there's no more... bundle IDs. the recursive section to the first time
    -- it runs and it finds all the items that have sub-items. So that's the first iteration. So now it keeps calling itself so this interns get used
	-- to call itself again. So we're going to find out. We want to see if all the items are the parents of any of the sub-items.

	SELECT 
		D.merchandise_item_id,												-- merchandise_item_id
		depth + 1,															-- depth
		CAST(CONCAT(REPEAT(" |__ ", depth), D.description) AS CHAR(500)),	-- description
		CAST(NULL AS DECIMAL(8, 2)),										-- unit_price_decimal
		CAST(CONCAT(C.alpha_sort, " ", D.description) AS CHAR(700)),    	-- alpha_sort
		D.bundle_id															-- bundle_id
	FROM merchandise_cte AS C, merchandise_item AS D
	WHERE C.merchandise_item_id = D.bundle_id
)

-- using the common table expression

SELECT * FROM merchandise_cte
ORDER BY alpha_sort 

-- So recursive common table expression is really good for recursive operations like that... usually when there's a 
-- this item that points to itself in the table that can go into so many levels. So it's perfect for that.