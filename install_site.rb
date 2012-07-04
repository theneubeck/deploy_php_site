#! /usr/bin/ruby

require 'rubygems'
require 'commander'
require 'yaml'
include  Commander::UI

sitename = ARGV[0]
if sitename.nil? || sitename == ""
  color "No site given\n", :red
  color "usage:\n\n./install_site.rb sitename.com [username [db_name]]\n\n", :green
  exit(1)
end

def cmd(line)
  print "[executing]\n"
  color line, :magenta
  print "[response]\n"
  color %x[#{line}], :yellow
end

users = YAML.load_file("users.yml")

vars = { 
  sitename: ARGV[0],
  username: ARGV[1],
  password: %x[ pwgen -1 ].strip,
  
  db_user: ARGV[1],
  db_table: ARGV[2],
  db_passwd: %x[ pwgen -1 ].strip
}


# 1. Create User

# groupadd companyName
# useradd -g companyName -d /var/www/example.com -s /bin/bash -c "companyName" client
# mkdir /var/www/domain.com
# chown -R client:companyName /var/www/domain.com

# 2. Add groupname to www-data
# usermod www-data -a -G groupname 

# 3. Create vhost
# copy file

# 4. Prepare dir
# chmod 0750 /var/www/domain.com
# su client
# cd ~
# mkdir fcgi-bin; mkdir uploads; mkdir sessions; mkdir logs; mkdir public;

# 5. Create php fcgi script
# cd fcgi-bin;

fcgi = File.read("templates/php.fcgi") % vars 

# copy file
# chmod +x php.fcgi
# set correct user

# 6. Create Php.ini file
# create dir
# copy file


# 7. deploy site
# create index.php-file
# enable vhost
# restart apache

# Create DB user, tablename

# save of username, password, db_table, db_user, db_passwd 
