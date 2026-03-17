# Ecomm Project – End-to-End Deployment Guide

## 1.Overview
This document explains step-by-step how to build and deploy the Ecomm web application on an EC2 instance with Tomcat 9 using AWS CodePipeline, CodeBuild, and CodeDeploy. Any teammate should be able to follow this document to set up the entire project from scratch.

## 2. Prerequisites

- AWS Account with admin access
- EC2 instance (Amazon Linux 2 preferred)
- GitHub (or CodeCommit) repository containing:
  - Ecomm.war (or Maven project with pom.xml)
  - appspec.yml
  - buildspec.yml
  - scripts/ folder with deployment scripts
  - tomcat-users.xml

## 3. IAM Roles Setup

Role for EC2 :

1. Go to IAM - Roles - Create role  
2. Select EC2 as trusted entity  
3. Attach policies:
   - AmazonEC2RoleforAWSCodeDeploy
   - AmazonS3FullAccess 
4. Name: EC2-CodeDeploy-Role  
5. Attach this role to the EC2 instance  

Role for CodeDeploy :

1. Create new IAM role  
2. Trusted entity: CodeDeploy  
3. Attach policy: AWSCodeDeployRole  
4. Name: CodeDeployServiceRole  

Role for CodeBuild

1. Create new IAM role  
2. Trusted entity: CodeBuild  
3. Attach policies:
   - AmazonS3FullAccess
   - AWSCodeCommitReadOnly 
   - AmazonEC2ContainerRegistryReadOnly
4. Name: CodeBuildServiceRole  

Role for CodePipeline:

1. Create IAM role  
2. Click Custom Trusted entity: 

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}

```
3.Attach policies:
 o	AmazonS3FullAccess
 o	AWSCodeDeployFullAccess
 o	AWSCodeBuildDeveloperAccess
 o	AWScodepipelinefullaccess
4.Name: CodePipelineServiceRole

4. EC2 Setup:

  1.Launch Amazon Linux 2 EC2 instance in your region.

  2.Attach EC2-CodeDeploy-Role IAM role.

  3.Install CodeDeploy agent:
  ```
  sudo yum update -y
  
  sudo yum install -y ruby wget
  
  cd /home/ec2-user
  
  wget https://aws-codedeploy-ap-south-1.s3.ap-south1.amazonaws.com/latest/install
  
  chmod +x ./install
  
  sudo ./install auto
  
  sudo systemctl enable codedeploy-agent
  
  sudo systemctl start codedeploy-agent
```
  
  5. Repository Structure
   
   Ecomm-Project/
   
   ├── appspec.yml
   
   ├── buildspec.yml
   
   ├── tomcat-users.xml
   
   ├── scripts/
   
   │   ├── install_and_deploy_tomcat.sh
   
   └── src/ (Maven project or Ecomm.war)
   
7. CodeBuild Configuration

buildspec.yml:
```
version: 0.2
phases:
  install:
    runtime-versions:
      java: corretto11
    commands:
      - yum install -y maven
  build:
    commands:
      - mvn clean package -DskipTests
      - cp target/Ecomm.war .
artifacts:
  files:
    - Ecomm.war
    - appspec.yml
    - scripts/*
    - tomcat-users.xml
```

7. CodeDeploy Configuration
   
appspec.yml:
```
version: 0.0
os: linux
files:
  - source: Ecomm.war
    destination: /home/ec2-user/
  - source: tomcat-users.xml
    destination: /home/ec2-user/
hooks:
  AfterInstall:
    - location: scripts/install_and_deploy_tomcat.sh
      timeout: 300
      runas: ec2-user
```

8. Deployment Script
```
scripts/install_and_deploy_tomcat.sh
#!/bin/bash
set -e
TOMCAT_VERSION=9.0.88
TOMCAT_DIR=/opt/tomcat
WAR_NAME=Ecomm.war

if [ ! -d "$TOMCAT_DIR" ]; then
  sudo mkdir -p $TOMCAT_DIR
  cd /tmp
  wget https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz
  sudo tar xzvf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C $TOMCAT_DIR --strip-components=1
  sudo chmod +x $TOMCAT_DIR/bin/*.sh
fi

sudo cp /home/ec2-user/$WAR_NAME $TOMCAT_DIR/webapps/
sudo cp /home/ec2-user/tomcat-users.xml $TOMCAT_DIR/conf/

sudo $TOMCAT_DIR/bin/shutdown.sh || true
sudo $TOMCAT_DIR/bin/startup.sh
```

9. Creating AWS Services
    
9.1 Create S3 Bucket

 •	Create an S3 bucket for storing build artifacts.
 
9.2 Create CodeBuild Project

 1.	Go to CodeBuild > Create project
 2.	Source: GitHub/CodeCommit repo
 3.	Environment: Managed image, Amazon Linux 2, runtime Corretto 11
 4.	Buildspec: buildspec.yml
 5.	Service role: CodeBuildServiceRole
    
9.3 Create CodeDeploy Application

 1.	Go to CodeDeploy > Applications > Create application
 2.	Compute platform: EC2/On-premises
 3.	Name: EcommApp
9.4 Create CodeDeploy Deployment Group
   	
 1.	Inside the application, create a Deployment Group
 2.	Name: EcommDG
 3.	Service role: CodeDeployServiceRole
 4.	Deployment type: In-place
 5.	Environment: Select EC2 instance with EC2-CodeDeploy-Role
    
9.5 Create CodePipeline

 1.	Go to CodePipeline - Create pipeline
 2.	Pipeline name: EcommPipeline
 3.	Service role: CodePipelineServiceRole
 4.	Source stage: GitHub/CodeCommit
 5.	Build stage: Select EcommBuild (CodeBuild project)
 6.	Deploy stage: Select EcommApp (CodeDeploy application) and EcommDG



10. Deploy & Access
    
  •	Push code to repo → triggers pipeline.
  
  • CodePipeline runs CodeBuild → generates artifact → pushes to S3.
  
  •	CodeDeploy fetches artifact → deploys to EC2 → starts Tomcat.

  
  
12.	Access:
    
 o	Tomcat Home → http://<EC2-Public-IP>:8080
 
 o	Manager App → http://<EC2-Public-IP>:8080/manager/html
 
 o	Ecomm App → http://<EC2-Public-IP>:8080/Ecomm

 
  
