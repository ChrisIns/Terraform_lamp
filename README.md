# Terraform_lamp

# Goal of this project

This project is a POC about building a LAMP stack as microservices with Docker using Terraform and implementing a CICD pipeline on top of that.

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


# Creating the docker network 

We will need a docker network from which will be connected the Apache and the MariaDB container

```
resource "docker_network" "lamp_network" {
        name = "lamp_network"
}
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

# Creating the Docker volume for MariaDB container

We will need a volume for the MariaDB container.The creation of a docker volume is pretty easy with Terraform:

```
resource "docker_volume" "mariadb_volume" {
        name = "mariadb_volume"
}
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

We can list the resources created with the **terraform state list** command.

```
terraform state list         
docker_container.apache
docker_container.mariadb
docker_image.apache-image
docker_image.mariadb-image
docker_network.lamp_network
docker_volume.mariadb_volume
```

# Verification of the docker resource

We can check that the image is indeed created with **docker images** command

```
docker images | grep apache
apache       lamp         7286ec2e1d75   17 minutes ago   368MB
```

We can check that the network is created with the **docker network ls** command

```
docker network ls | grep lamp
0f462ff504e0   lamp_network   bridge    local
```

We can then check if the container is UP with the **docker ps** command:

```
docker ps                    
CONTAINER ID   IMAGE          COMMAND                  CREATED          STATUS          PORTS                    NAMES
9ee3d31fb065   7286ec2e1d75   "docker-php-entrypoi…"   12 minutes ago   Up 12 minutes   0.0.0.0:80->80/tcp       webserver
```

We can check that the volume is indeed created with the **docker volume ls** command

``` 
docker volume ls
DRIVER    VOLUME NAME
local     mariadb_volume
```
Check to see if the mariadb image is indeed created:

```
docker images | grep mariadb
mariadb      lamp         f29f113b8c8f   34 minutes ago   360MB
```
We check that the mariadb container is indeed created:

```
docker ps | grep db
f336385e1ecf   f29f113b8c8f   "docker-entrypoint.s…"   21 minutes ago   Up 21 minutes   0.0.0.0:3306->3306/tcp   db
```
# Testing that the website is up and running

I didn't do some groundbreaking website for this project, since the goal was just to deploy a LAMP stack to host our web files.
I put emphasis on the IaC side of things, and not on the web dev side of things so here is a rapid test to check if the website is running:

```
curl http://localhost
<html>
 <head>
  <title>Test PHP</title>
 </head>
 <body>
 <p>Hello World</p> </body>
</html>
```

Indeed the server is up and running ! 

# Improving our code

# Adding a variables.tf file

We will add a variables.tf file to declare our variables:

```
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
```

# Adding a terraform.tfvars file

We will declare the value in the terraform.tfvars file:

```
images=["apache:lamp","mariadb:lamp"]
path=["~/lamp/images/apache","~/lamp/images/db"]
container_path=["/var/www/html","/var/lib/mysql"]
network_name="lamp_network"
ports_internal=[80,3306]
ports_external=[80,3306]
ip="0.0.0.0"
host_path="/home/kali/lamp/website_files"
volume_name="mariadb_volume"
mysql_pass="MYSQL_ROOT_PASSWORD=1234"
mysql_database="MYSQL_DATABASE=simple-website"
```

Yes, putting the password in plain text is bad, but here its a localhost server so its not important, but in real world prod environment, we should store it in an encrypted backend or use Vault to manage the secrets.

# Modifying the main.tf file

And then we change the hardcoded values in our main.tf file by **var.<variable_name>**, for example:

```
ports {
                internal = var.ports_internal[0]
                external = var.ports_external[0]
                ip = var.ip
        }
```

# Adding child modules 

Let's try to put some hierarchy in our code with child modules
We create a **modules** directory in the working directory. This mdoules files will contains our differents child modules, we can see the working directory hierarchy with a tree command:

```

─$ tree


├── main.tf \
├── modules \
│   ├── apache-image \
│   │   ├── main.tf \
│   │   ├── output.tf \
│   │   ├── provider.tf \
│   │   └── variables.tf \
│   ├── lamp_network \
│   │   ├── main.tf \
│   │   ├── output.tf \
│   │   ├── provider.tf \
│   │   └── variables.tf \
│   ├── mariadb-image \
│   │   ├── main.tf \
│   │   ├── output.tf \
│   │   ├── provider.tf \
│   │   └── variables.tf \
│   └── mariadb_volume \
│       ├── main.tf \
│       ├── output.tf \
│       ├── provider.tf \
│       └── variables.tf \
├── provider.tf \ 
├── README.md \
├── terraform.tfstate \
├── terraform.tfstate.backup \
├── terraform.tfvars \
├── variables.tf \
```
In each modules directory, we'll have the main.tf, the variables.tf to define our variables and the output.tf for making attribute available for resources in our root module, lets see an example:

Here's the code for the mariadb_volume child module:

```

resource "docker_volume" "mariadb_volume" {
        name = var.volume_name
}

```

We define the associated variables.tf file:

```

variable "volume_name" {
        type = string
        default = "mariadb_volume"
}

```

And we define the output file:

```

output "volume" {
        value = docker_volume.mariadb_volume.id
}

```

Then to define the child module to use in our root module:

```

module "mariadb_volume" {
        source = "./modules/mariadb_volume"
}

```

And then to access a value from a child module output:

```

volume_name = module.mariadb_volume.volume

```

The syntax is module.<child_module_name>.<output_name>

# Adding CI CHECK with github action

Let's add a CI to check if the code is valid after each push to the branch.
We will check the validity of the code with a tf fmt and a tf validate
We will then initialize terraform

```

name: Terraform

on:
  push:
    branches: [master]

jobs:
  terraform:
    name: 'Terraform'
    runs-on: self-hosted
    env:
      working-directory: ../../
    defaults:
      run:
        working-directory: ${{ env.working-directory }}    
    steps:
      - name: Where am i
        id: where
        run: pwd
      - name: Terraform Format
        id: fmt
        run: terraform fmt -check 
      - name: Terraform Init
        id: init
        run: terraform init
      - name: Terraform Validate
        id: validate
        run: terraform validate -no-color
```
# Adding CD to the project

We will then add more code to our workflow to perform terraform plan and apply after a PR.
Normally the code would have generated the PR automatically but it seems to have a problem somewhere, even though I followed the Terraform guide on that.

Here's the part of the code for the CD:

```
- name: Terraform Plan
        id: plan
        if: github.event_name == 'pull_request'
        run: terraform plan -no-color -input=false
        continue-on-error: true
      - name: Update Pull Request
        uses: actions/github-script@v6
        if: github.event_name == 'pull_request'
        env:
          PLAN: "terraform\n${{ steps.plan.outputs.stdout }}"
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          script: |
            const output = `#### Terraform Format and Style 🖌\`${{ steps.fmt.outcome }}\`
            #### Terraform Initialization ⚙\`${{ steps.init.outcome }}\`
            #### Terraform Plan 📖\`${{ steps.plan.outcome }}\`
            #### Terraform Validation 🤖\`${{ steps.validate.outcome }}\`

            <details><summary>Show Plan</summary>

            \`\`\`\n
            ${process.env.PLAN}
            \`\`\`

            </details>

            *Pushed by: @${{ github.actor }}, Action: \`${{ github.event_name }}\`*`;

            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: output
            })
      - name: Terraform Plan Status
        if: steps.plan.outcome == 'failure'
        run: exit 1
      - name: Terraform Apply
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        run: terraform apply -auto-approve -input=false
```

Even though we have to create the PR ourself, after validating the PR and merging to main branch, terraform apply the config on our host and run the containers:

```
└─$ docker ps                                                                                                                             
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                    NAMES
27e15cca1055   89cdac8dc0ae   "docker-php-entrypoi…"   3 minutes ago   Up 3 minutes   0.0.0.0:80->80/tcp       webserver
1e37d1053af4   89fb791d5ffe   "docker-entrypoint.s…"   3 minutes ago   Up 3 minutes   0.0.0.0:3306->3306/tcp   db

```
# Adding the monitoring

To finish the pipeline, We will add in the CICD pipeline the deployment of our supervision to monitor our container with Prometheus and Grafana.
For this, due to the the multiple component of prometheus + grafana, docker compose is the perfect choice to dpeloy all the component required by the supervion.
Then we will add the docker-compose up -d command in github action workflow file to deploy the monitoring containers.

For this we could create our own dockerfiles of each prometheus component, but we'll use the dockprom repo for that: https://github.com/stefanprodan/dockprom

Then we add the following in our wokflow file:

```

supervision:
    name: Supervision
    runs-on: self-hosted
    env:
      working-directory: ../../dockprom
    needs: terraform
    defaults:
      run:
        working-directory: ${{ env.working-directory }}
    steps:
      - name: Lauch docker compose
        if: github.ref == 'refs/heads/main' && github.event_name == 'push'
        id: grafana
        run: docker-compose up -d
```

So, by doing the PR + merge, our CICD will run the command docker-compose to deploy all the containers required for supervision.

Here's is the list of all containers deployed:

```
inux@linux-virtual-machine:~/Terraform_lamp$ docker ps
CONTAINER ID   IMAGE                              COMMAND                  CREATED             STATUS                   PORTS                                                                                                                                                                                                                                NAMES
448ceca343ed   794222d20bc6                       "docker-php-entrypoi…"   7 minutes ago       Up 7 minutes             0.0.0.0:80->80/tcp                                                                                                                                                                                                                   webserver
00dbc3cdb5b3   13a64d6be661                       "docker-entrypoint.s…"   7 minutes ago       Up 7 minutes             0.0.0.0:3306->3306/tcp                                                                                                                                                                                                               db
fef8d22d0bc1   grafana/grafana:9.2.4              "/run.sh"                11 minutes ago      Up 7 minutes             3000/tcp                                                                                                                                                                                                                             grafana
cd9d29bb200a   prom/prometheus:v2.40.1            "/bin/prometheus --c…"   11 minutes ago      Up 7 minutes             9090/tcp                                                                                                                                                                                                                             prometheus
06373dc89fcb   prom/alertmanager:v0.24.0          "/bin/alertmanager -…"   11 minutes ago      Up 7 minutes             9093/tcp                                                                                                                                                                                                                             alertmanager
6c527c5acea9   caddy:2.6.2                        "caddy run --config …"   11 minutes ago      Up 7 minutes             80/tcp, 443/tcp, 0.0.0.0:3000->3000/tcp, :::3000->3000/tcp, 0.0.0.0:8080->8080/tcp, :::8080->8080/tcp, 0.0.0.0:9090-9091->9090-9091/tcp, :::9090-9091->9090-9091/tcp, 2019/tcp, 443/udp, 0.0.0.0:9093->9093/tcp, :::9093->9093/tcp   caddy
2854d5b8c288   prom/node-exporter:v1.4.0          "/bin/node_exporter …"   About an hour ago   Up 7 minutes             9100/tcp                                                                                                                                                                                                                             nodeexporter
570ae1bf95fe   prom/pushgateway:v1.4.3            "/bin/pushgateway"       About an hour ago   Up 7 minutes             9091/tcp                                                                                                                                                                                                                             pushgateway
8366f645176a   gcr.io/cadvisor/cadvisor:v0.46.0   "/usr/bin/cadvisor -…"   About an hour ago   Up 7 minutes (healthy)   8080/tcp                                                                                                                                                                                                                             cadvisor
```

And now we can go 127.0.0.1:3000 (grafana default webpage) and check our dashboard:

![grafana dashboard](https://user-images.githubusercontent.com/45426865/207140062-91e3a20a-cc5a-4bfe-b590-38ef8c9d9a5c.png)




                                                                                                                       

