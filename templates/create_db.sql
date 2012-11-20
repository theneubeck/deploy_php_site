set names utf8;
CREATE DATABASE %{db_name};
CREATE USER '%{db_user}'@'localhost' IDENTIFIED BY '%{db_password}';
GRANT ALL ON %{db_name}.* TO '%{db_user}'@'localhost';
FLUSH PRIVILEGES;
