DROP TRIGGER IF EXISTS example_audit_insert;
DELIMITER $$

CREATE TRIGGER example_audit_insert 
	AFTER INSERT ON example FOR EACH ROW 
BEGIN
	DECLARE vUser varchar(50);
	SELECT USER() INTO vUser;

    INSERT INTO example_audit (id, name, description, date_time, user) 
	VALUES (NEW.id, NEW.name, NEW.description, NOW(), vUser);
END $$
DELIMITER ;