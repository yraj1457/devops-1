# Requirements
1. Docker
2. Terraform
3. AWS CLI
4. Python

# SimpleTimeService

A microservice that returns date and time along with the ip when hit, dockerized and pushed to Dockerhub for easy building and deployment as a lightweight container

Steps to build:
1. docker pull yraj1457/simple-time-service
2. docker run -p 5050:5050 yraj1457/simple-time-service

**Note**: This application runs on port 5050

# Terraform and Cloud: create the infrastructure to host your container

This sets up the container to run the microservice

Steps to build:
1. git clone <url>
2. cd into cloned directory
3. aws configure to authenticate
4. terraform init
5. terraform plan
6. terraform apply

