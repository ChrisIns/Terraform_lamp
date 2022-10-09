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
