resource "docker_image" "mariadb-image" {
        name = var.image
        build {
                path = var.path
                label = {
                        project : var.project_name
                }
        }
}
