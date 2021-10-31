# Terraform project - IaaC
![](https://github.com/ameedghanem/Terraform-Project/blob/main/logo/logo.png)

  A terraform code that sets up the following infrastructure:
  - 2 Instances (t2.micro) - with NGINX running on each
  - An Application Load Balancer that forwards the users’ traffic to the servers

## Prerequesties
    Amazon account
    IAM user with access key and secret key
    terraform

## Installation
    $ git clone https://github.com/ameedghanem/Terraform_Project.git
      ...
    $ cd Terraform_Project

## Deployment
    $ terraform init
    $ terraform apply -var="accessKey=<your access key>" -var="secretKey=<you secret key>"
    
To verify everything is working:
  - Sign in to your amazon account
  - Go to the newly created load balancer, named fursa_lb
  - Navigate in the browser to the DNS url, you should see the following page:
 
![](https://github.com/ameedghanem/Terraform-Project/blob/main/logo/welcome%20nginx.PNG)
