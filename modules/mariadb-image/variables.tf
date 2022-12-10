variable "image" {
	type = string
	default = "mariadb:latest"
}

variable "path" {
	type = string
	default = "~/lamp/images/db"
}

variable "project_name" {
	type = string
	default = "lamp"
}
