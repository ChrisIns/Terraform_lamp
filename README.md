# Terraform_lamp

# Goal of this project

This project will be about building a LAMP stack as microservices with Docker using Terraform

# Installing Terraform

Commands used to install terraform 

```
wget https://releases.hashicorp.com/terraform/0.13.0/terraform_0.13.0_linux_amd64.zip
unzip terraform_0.13.0_linux_amd64.zip
sudo mv terraform /usr/local/bin
```

a rapid terraform check show that terraform is installed
```
$ terraform version
```
**Terraform v0.13.0**

# Creating the provider.tf file

We create the provider file to control the version of the docker provider

```
terraform {
        required_providers {
                docker = {
                        source = "kreuzwerker/docker"
                        version = "2.16.0"
                }
        }
}
```
# Creating the Dockerfile for the Apache image

```
FROM php:7.0-apache

RUN docker-php-ext-install -j$(nproc) pdo
RUN docker-php-ext-install -j$(nproc) pdo_mysql

```

# Creating the Apache docker image with Terraform

To build a docker image with Terraform and docker provider, we just have to specify the image path to the required Dockerfile:

``` 

resource "docker_image" "apache-image" {
        name = "apache:lamp"
        build {
                path = "~/lamp/images/apache/"
                label = {
                        project : "lamp"
                }
        }
}

```

We can check that the image is indeed created with **docker images** command

```
docker images | grep apache
apache       lamp         7286ec2e1d75   17 minutes ago   368MB
```
# Creating the docker network 

We will need a docker network from which will be connected the Apache and the MariaDB container

```
resource "docker_network" "lamp_network" {
        name = "lamp_network"
}
```

We can check that the network is created with the **docker network ls** command

```
docker network ls | grep lamp
0f462ff504e0   lamp_network   bridge    local
```
# Creating the Apache container

Creating the docker container with Terraform requires more parameters, we need to specify:

- The image ressource id
- The network that the container will use
- The port inside the container and the port exposed on the host (similar to docker run -p 80:80...), here we use the 0.0.0.0 IP address for localhost.
- The volume to have a mount point (we'll see later that we can also use a Docker volume with the mariadb container)
- Depends_on will tell Terraform to build the network resource before the container resource.

```
resource "docker_container" "apache" {
        name = "webserver"
        hostname = "apache"
        image = docker_image.apache-image.latest
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
```
