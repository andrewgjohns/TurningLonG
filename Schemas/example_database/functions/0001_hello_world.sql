﻿DELIMITER $$
CREATE FUNCTION hello_world()
  RETURNS TEXT
  LANGUAGE SQL
BEGIN
  RETURN 'Hello World';
END;
$$
DELIMITER ;