DROP PROCEDURE IF EXISTS UpdateExample;
DELIMITER $$


CREATE PROCEDURE UpdateExample
(
	IN 
	 p_name VARCHAR(255)
	,p_description VARCHAR(255)
)
BEGIN
    INSERT INTO example (name, description) 
    VALUES (p_name, p_description);
END $$
DELIMITER ;

