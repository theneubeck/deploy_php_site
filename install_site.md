Instructions
============

following http://blog.awellis.me/post/3756809191/configuring-a-lamp-stack-on-debian-with-fastcgi-and


vhost_dir = "/etc/apache2/sites-enabled"

#### 1. Create User

```
groupadd companyName
useradd -g companyName -d /var/www/example.com -s /bin/bash -c "companyName" client
mkdir /var/www/domain.com
chown -R client:companyName /var/www/domain.com
```

#### 1b. Prepare dir
```
su client
cd ~
mkdir fcgi-bin; mkdir uploads; mkdir sessions; mkdir logs; mkdir public;
```

#### 2. Add groupname to www-data

```
usermod www-data -a -G groupname 
```


#### 3. Create vhost

copy file vhost file


#### 5. Create php fcgi script
```
cd fcgi-bin;
# write fcgi file
chmod +x php.fcgi
```

#### 6. Create Php.ini file

* create dir
* copy file


#### 7. deploy site
* create index.php-file
* set owners on dir stuff

#### 8. Apache

* enable vhost
* restart apache

#### 9 DB-stuff

* Create DB user, tablename
* save of username, password, db_table, db_user, db_passwd 
Vimium has been updated to 1.32.x

