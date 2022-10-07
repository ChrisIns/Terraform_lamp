resource "docker_image" "php-image" {
        name = "php:lamp"
        build {
                path = "~/lamp/images/php/"
                label = {
                        project : "lamp"
                }
        }
}
