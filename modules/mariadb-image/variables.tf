variable "image" {
	type = string
	default = "mariadb:latest"
}

variable "path" {
	type = string
	default = "~/Terraform_lamp/images/db"
}

variable "project_name" {
	type = string
	default = "lamp"
}
