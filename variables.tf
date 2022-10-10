variable "images" {
	type = list(string)
}

variable "path" {
	type = list(string)
}

variable "container_path" {
	type = list(string)
}

variable "network_name" {
	type = string
}

variable "ports_internal" {
	type = list(number)
}

variable "ports_external" {
	type = list(number)
}

variable "ip" {
	type = string
	description = "IP localhost"
}

variable "host_path" {
	type = string
}

variable "volume_name" {
	type = string
}

variable "mysql_pass" {
	type = string
}

variable "mysql_database" {
	type = string
}

variable "project_name" {
	type = string
}
