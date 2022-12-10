container_path     = ["/var/www/html", "/var/lib/mysql"]
ports_internal     = [80, 3306]
ports_external     = [80, 3306]
ip                 = "0.0.0.0"
host_path          = "/home/kali/lamp/website_files"
mysql_pass         = "MYSQL_ROOT_PASSWORD=1234"
mysql_database     = "MYSQL_DATABASE=simple-website"
project_name       = "lamp"
label              = "project"
container_name     = ["webserver", "db"]
container_hostname = ["apache", "db"]
