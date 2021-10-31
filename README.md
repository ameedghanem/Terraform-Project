# Terraform project - IaaC
  A terraform code that sets up the following infrastructure:
  - 2 Instances (t2.micro) - with NGINX running on each
  - An Application Load Balancer that forwards the users’ traffic to the servers

## The big picture
![](https://github.com/ameedghanem/Terraform-Project/blob/main/logo/logo.png)

## Prerequesties
    terraform

## Installation
    $ git clone https://github.com/ameedghanem/Terraform_Project.git
      ...
    $ cd Terraform_Project

## Deployment
    $ terraform init
    $ terraform apply -var="accessKey=<your access key>" -var="secretKey=<you secret key>"
