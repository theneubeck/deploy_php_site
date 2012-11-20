#! /usr/bin/ruby

require 'rubygems'
require 'commander'
require 'yaml'
require 'erb'
require 'ostruct'
include  Commander::UI

# following http://blog.awellis.me/post/3756809191/configuring-a-lamp-stack-on-debian-with-fastcgi-and
vhost_dir = "/etc/apache2/sites-available"

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

users = {}

if File.exist? "users.yml"
  users = YAML.load_file("users.yml")
end



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

if vars.username.length > 16
  vars.username = vars.username[0..15]
end
if vars.db_user.length > 16
  vars.db_user = vars.db_user[0..15]
end

if vars.db_name.nil?
  vars.db_name  = vars.sitename[/(www\.)?(.*)$/, 2].gsub(/\W/, "_")
end


if users.include? vars.username
  color "#{vars.username} already exists!", :red
  exit(1)
end
# 1. Create User

cmd "mkdir /var/www/#{vars.sitename}"
cmd "groupadd #{vars.username}"
cmd %Q[useradd -g #{vars.username} -d /var/www/#{vars.sitename} -s /bin/bash -c "#{vars.username}" #{vars.username}]

# 1b. Prepare dir

cmd "chmod 0750 /var/www/#{vars.sitename}"
cmd %Q[cd /var/www/#{vars.sitename} && mkdir fcgi-bin && mkdir uploads && mkdir sessions && mkdir logs && mkdir public]

# 2. Add groupname to www-data
cmd "usermod www-data -a -G #{vars.username}"

# 3. Create vhost
vhost = ERB.new(File.read("templates/vhost.conf.erb")).result(binding)
# copy file
File.open("#{vhost_dir}/#{vars.sitename}", "w") { |f| f.write(vhost) }


# 5. Create php fcgi script
fcgi = File.read("templates/php.fcgi") % vars.marshal_dump
# write fcgi file
File.open("/var/www/#{vars.sitename}/fcgi-bin/php.fcgi", "w") { |f| f.write(fcgi) }
cmd "chmod +x /var/www/#{vars.sitename}/fcgi-bin/php.fcgi"

# 6. Create Php.ini file
php_ini = ERB.new(File.read("templates/php.ini.erb")).result(binding)
cmd "mkdir /etc/php5/vhosts.d/#{vars.sitename}"
File.open("/etc/php5/vhosts.d/#{vars.sitename}/php.ini", "w") { |f| f.write(php_ini) }


# 7. deploy site
# create index.php-file
File.open("/var/www/#{vars.sitename}/public/index.php", "w") { |f| f.write(%Q[<?php\necho "Hello #{vars.sitename}";\n]) }
# set owners on dir stuff
cmd "chown -R #{vars.username}:#{vars.username} /var/www/#{vars.sitename}"


# 8. Apache
cmd "a2ensite #{vars.sitename}"
cmd "/usr/sbin/service apache2 restart"
# enable vhost
# restart apache

# 9 DB-stuff
# Create DB user, tablename
sql = File.read("templates/create_db.sql") % vars.marshal_dump
cmd %Q[mysql -uroot -p -e "#{sql}"]


# 10 set user password
cmd %Q[echo "#{vars.username}:#{vars.password}" | /usr/sbin/chpasswd ]

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


color "Now you're on your own. Do something like this:", :green
color %Q[
  su #{vars.username} && cd
  grep -rni --color leomira_d0ri0 public

  # rsync the dir
  rsync -avz root@leomira.com:/home/leomira/public_html/. ./public/.

  # dump the db
  mkdir dbs
  ssh root@leomira.com "mysqldump -uroot <old_db>" > dbs/#{vars.sitename}.sql

  cat dbs/#{vars.sitename}.sql | mysql -u #{vars.db_user} #{vars.db_name} -p 
], :yellow
