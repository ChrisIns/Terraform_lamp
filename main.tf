resource "docker_image" "php-image" {
        name = "php:lamp"
        build {
                path = "~/lamp/images/php/"
                label = {
                        project : "lamp"
                }
        }
}

resource "docker_network" "lamp_network" {
	name = "lamp_network"
}

resource "docker_container" "php-httpd" {
	name = "webserver"
	hostname = "php-httpd"
	image = docker_image.php-image.latest
	networks = [docker_network.lamp_network.id]
	ports {
		internal = 80
		external = 80
		ip = "0.0.0.0"
	}
	labels {
		label = "project"
		value = "lamp"
	}
	volumes {
		container_path = "/var/www/html"
		host_path = "/home/kali/lamp/website_files"
	}
	depends_on = [
		docker_network.lamp_network
	]
}

resource "docker_image" "mariadb-image" {
	name = "mariadb:lamp"
	build {
		path = "~/lamp/images/db"
		label = {
			project : "lamp"
		}
	}
}

resource "docker_volume" "mariadb_volume" {
	name = "mariadb_volume"
}

resource "docker_container" "mariadb" {
	name = "db"
	hostname = "db"
	image = docker_image.mariadb-image.latest
	networks = [docker_network.lamp_network.id]
	ports {
		internal = 3306
		external = 3306
		ip = "0.0.0.0"
	}
	labels {
		label = "project"
		value = "lamp"
	}
	env = [
		"MYSQL_ROOT_PASSWORD=1234",
                "MYSQL_DATABASE=simple-website"
	]
	volumes {
		volume_name = docker_volume.mariadb_volume.id
		container_path = "/var/lib/mysql"
	}
	depends_on = [
		docker_network.lamp_network,
		docker_volume.mariadb_volume
	]
}
