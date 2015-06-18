CREATE TABLE example_audit (
  id int(11) NOT NULL,
  name varchar(255) DEFAULT NULL,
  description varchar(255) DEFAULT NULL,
  date_time datetime,
  user VARCHAR(50)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
