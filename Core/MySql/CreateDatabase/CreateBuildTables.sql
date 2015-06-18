CREATE TABLE database_version (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  version varchar(50) DEFAULT NULL,
  created_date datetime DEFAULT NULL,
  modified_date datetime DEFAULT NULL,
  modified_by varchar(50) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;

CREATE TABLE database_scriptsrun (
  id bigint(20) NOT NULL AUTO_INCREMENT,
  version_id bigint(20) DEFAULT NULL,
  script_name varchar(255) DEFAULT NULL,
  script_hash varchar(255) DEFAULT NULL,
  text_of_script text,
  one_time_script tinyint(1) DEFAULT NULL,
  created_date datetime DEFAULT NULL,
  modified_date datetime DEFAULT NULL,
  modified_by varchar(50) DEFAULT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8;
