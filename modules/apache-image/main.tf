resource "docker_image" "apache-image" {
        name = var.image
        build {
                path = var.path
                label = {
                        project : var.project_name
                }
        }
}

