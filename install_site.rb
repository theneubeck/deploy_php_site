#! /usr/bin/ruby

require 'rubygems'
require 'commander'
require 'yaml'
require 'erb'
require 'ostruct'
include  Commander::UI

# following http://blog.awellis.me/post/3756809191/configuring-a-lamp-stack-on-debian-with-fastcgi-and
vhost_dir = "/etc/apache2/sites-enabled"

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
  # execute command
  color %x[#{line}], :yellow
end

users = YAML.load_file("users.yml")

vars = OpenStruct.new({
  sitename: ARGV[0],
  username: ARGV[1],
  password: %x[ pwgen -1 ].strip,
  
  db_user: ARGV[1],
  db_name: ARGV[2],
  db_password: %x[ pwgen -1 ].strip
})


if vars.username.nil?
  vars.username = vars.sitename[/(www\.)?(.*)\.\w{2,3}$/, 2].gsub(/\W/, "_")
  vars.db_user  = vars.username
end

if vars.db_name.nil?
  vars.db_name  = vars.sitename[/(www\.)?(.*)$/, 2].gsub(/\W/, "_")
end


 if users.include? vars.username
   color "#{vars.username} already exists!", :red
   exit(1)
 end

print vars.marshal_dump.to_yaml

# 1. Create User

# groupadd companyName
# useradd -g companyName -d /var/www/example.com -s /bin/bash -c "companyName" client
# mkdir /var/www/domain.com
# chown -R client:companyName /var/www/domain.com

cmd "mkdir /var/www/#{vars.sitename}"
cmd "groupadd #{vars.username}"
cmd %Q[useradd -g #{vars.username} -d /var/www/#{vars.sitename} -s /bin/bash -c "#{vars.username}" #{vars.username}]

# 1b. Prepare dir
# su client
# cd ~
# mkdir fcgi-bin; mkdir uploads; mkdir sessions; mkdir logs; mkdir public;

cmd "chmod 0750 /var/www/#{vars.sitename}"
cmd %Q[su #{vars.username} -c "cd && mkdir fcgi-bin && mkdir uploads && mkdir sessions && mkdir logs && mkdir public"]

# 2. Add groupname to www-data
# usermod www-data -a -G groupname 
cmd "usermod www-data -a -G #{vars.username}"


# 3. Create vhost
vhost = ERB.new(File.read("templates/vhost.conf.erb")).result(binding)
# copy file
File.open("#{vhost_dir}/#{sitename}", "w") { |f| f.write(vhost) }


# 5. Create php fcgi script
# cd fcgi-bin;

fcgi = File.read("templates/php.fcgi") % vars.marshal_dump
# write fcgi file
File.open("/var/www/#{sitename}/fcgi-bin/php.fcgi", "w") { |f| f.write(fcgi) }
# chmod +x php.fcgi
cmd "chmod +x /var/www/#{sitename}/fcgi-bin/php.fcgi"

# 6. Create Php.ini file
# create dir
# copy file


# 7. deploy site
# create index.php-file
 File.open("/var/www/#{sitename}/public/index.php", "w") { |f| f.write(Q%[<?php\necho "Hello World";\n] }
# set owners on dir stuff
cmd "chown -R #{vars.username}:#{vars.username} /var/www/#{vars.sitename}"

# enable vhost
# restart apache

# 8 Table stuff
# Create DB user, tablename
sql = File.read("templates/create_db.sql") % vars.marshal_dump
cmd %Q[mysql -uroot -p -e "#{sql}"]

# save of username, password, db_table, db_user, db_passwd 
puts
color "Your details:", :green
color "=" * 30, :green
vars.marshal_dump.each do |k, v|
  color "#{k} :\t#{v}", :green
end
color "=" * 30, :green
puts

users[vars.username] = vars.marshal_dump
File.open("users.yml", "w") { |f| f.write(users.to_yaml) }
