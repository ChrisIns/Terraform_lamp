# test
module "apache-image" {
  source = "./modules/apache-image"
}

module "lamp_network" {
  source = "./modules/lamp_network"
}

module "mariadb-image" {
  source = "./modules/mariadb-image"
}

module "mariadb_volume" {
  source = "./modules/mariadb_volume"
}

resource "docker_container" "apache" {
  name     = var.container_name[0]
  hostname = var.container_hostname[0]
  image    = module.apache-image.image
  networks = [module.lamp_network.network]
  ports {
    internal = var.ports_internal[0]
    external = var.ports_external[0]
    ip       = var.ip
  }
  labels {
    label = var.label
    value = var.project_name
  }
  volumes {
    container_path = var.container_path[0]
    host_path      = var.host_path
  }
}

resource "docker_container" "mariadb" {
  name     = var.container_name[1]
  hostname = var.container_hostname[1]
  image    = module.mariadb-image.image
  networks = [module.lamp_network.network]
  ports {
    internal = var.ports_internal[1]
    external = var.ports_external[1]
    ip       = var.ip
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
    volume_name    = module.mariadb_volume.volume
    container_path = var.container_path[1]
  }
}
