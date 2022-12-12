variable "image" {
	type = string
	default = "apache:lamp"
}

variable "path" {
	type = string
	default = "~/Terraform_lamp/images/apache"
}

variable "project_name" {
	type = string
	default = "lamp"
}
