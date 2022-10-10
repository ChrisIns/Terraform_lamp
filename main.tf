resource "docker_image" "apache-image" {
        name = var.images[0]
        build {
                path = var.path[0]
                label = {
                        project : var.project_name
                }
        }
}

resource "docker_network" "lamp_network" {
	name = var.network_name
}

resource "docker_container" "apache" {
	name = var.container_name[0]
	hostname = var.container_hostname[0]
	image = docker_image.apache-image.latest
	networks = [docker_network.lamp_network.id]
	ports {
		internal = var.ports_internal[0]
		external = var.ports_external[0]
		ip = var.ip
	}
	labels {
		label = var.label
		value = var.project_name
	}
	volumes {
		container_path = var.container_path[0]
		host_path = var.host_path
	}
	depends_on = [
		docker_network.lamp_network
	]
}

resource "docker_image" "mariadb-image" {
	name = var.images[1]
	build {
		path = var.path[1]
		label = {
			project : var.project_name
		}
	}
}

resource "docker_volume" "mariadb_volume" {
	name = var.volume_name
}

resource "docker_container" "mariadb" {
	name = var.container_name[1]
	hostname = var.container_hostname[1]
	image = docker_image.mariadb-image.latest
	networks = [docker_network.lamp_network.id]
	ports {
		internal = var.ports_internal[1]
		external = var.ports_external[1]
		ip = var.ip
	}
	labels {
		label = var.label
		value = var.project_name
	}
	env = [
		var.mysql_pass,
                var.mysql_database
	]
	volumes {
		volume_name = docker_volume.mariadb_volume.id
		container_path = var.container_path[1]
	}
	depends_on = [
		docker_network.lamp_network,
		docker_volume.mariadb_volume
	]
}
