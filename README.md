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

We can then check if the container is UP with the **docker ps** command:

```
docker ps                    
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                    NAMES
9ee3d31fb065   7286ec2e1d75   "docker-php-entrypoi…"   12 minutes ago   Up 12 minutes   0.0.0.0:80->80/tcp       webserver
```

# Creating the Docker volume for MariaDB container

We will need a volume for the MariaDB container.The creation of a docker volume is pretty easy with Terraform:

```
resource "docker_volume" "mariadb_volume" {
        name = "mariadb_volume"
}
```
We can check that the volume is indeed created with the **docker volume ls** command

``` 
docker volume ls
DRIVER    VOLUME NAME
local     mariadb_volume
```

# Creating the docker image for the mariaDB container

Same thing as the Apache container:

```
resource "docker_image" "mariadb-image" {
        name = "mariadb:lamp"
        build {
                path = "~/lamp/images/db"
                label = {
                        project : "lamp"
                }
        }
}
```

A rapid check to see if the image is indeed created:

```
docker images | grep mariadb
mariadb      lamp         f29f113b8c8f   34 minutes ago   360MB
```

# Creating the MariaDB container

Same thing as with the Apache container, but here we will mount the container on the Docker volume.
We can also specify environment variable that will be used to connect to the SQL server database.
We make terraform launch the network and volume resource before the container with the **depends_on** parameter.

```
resource "docker_container" "mariadb" {
        name = "db"
        hostname = "db"
        image = docker_image.mariadb-image.latest
        networks = [docker_network.lamp_network.id]
        ports {
                internal = 3306
                external = 3306
                ip = "0.0.0.0"
        }
        labels {
                label = "project"
                value = "lamp"
        }
        env = [
                "MYSQL_ROOT_PASSWORD=1234",
                "MYSQL_DATABASE=simple-website"
        ]
        volumes {
                volume_name = docker_volume.mariadb_volume.id
                container_path = "/var/lib/mysql"
        }
        depends_on = [
                docker_network.lamp_network,
                docker_volume.mariadb_volume
        ]
}
```

We check that the docker container is indeed created with **docker ps** command.

```
docker ps | grep db
f336385e1ecf   f29f113b8c8f   "docker-entrypoint.s…"   21 minutes ago   Up 21 minutes   0.0.0.0:3306->3306/tcp   db
```
# Deploying the resources with the terraform workflow

Now that we have our main.tf file created, we will do the 3 terraform commands to deploy our resources:

- **terraform init** to download the required providers plugins
- **terraform plan** to generate the execution plan
- **terraform apply -auto-approve** to deploy our resources

We can see in the output that the resources are indeed created:

**terraform apply -auto-approve**
```
docker_volume.mariadb_volume: Creating...
docker_network.lamp_network: Creating...
docker_image.mariadb-image: Creating...
docker_image.apache-image: Creating...
docker_volume.mariadb_volume: Creation complete after 0s [id=mariadb_volume]
docker_image.mariadb-image: Creation complete after 0s [id=sha256:2dc13ca6fd9198bcf3abde5c84a2f37b4b03d46a2de1cded77362b3fbefe950fmariadb:lamp]
docker_image.apache-image: Creation complete after 0s [id=sha256:47b086c0c6fb92a2eccc039af6ed753f5a1322cc68dd5db99079123bd7a3f0e1apache:lamp]
docker_network.lamp_network: Creation complete after 2s [id=85ff7919fe9be6fe035ee8ba98002496c4bd7683559275393694a81e549f01a1]
docker_container.apache: Creating...
docker_container.mariadb: Creating...
docker_container.mariadb: Creation complete after 0s [id=0aa893ca2ffd0ecaae11242a45b62f8a92008a058c4ab0e26b5540bef26781f2]
docker_container.apache: Creation complete after 0s [id=9eb19fc0b3b950dafb55363b5c14d4646427e467adfb53c25dfd36fb4ff44906]

Apply complete! Resources: 6 added, 0 changed, 0 destroyed. 
```
