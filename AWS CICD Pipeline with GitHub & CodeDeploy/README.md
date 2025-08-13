# 🚀 AWS CI/CD Pipeline with GitHub & CodeDeploy
A fully automated CI/CD pipeline on AWS using CodePipeline, CodeDeploy, and a GitHub repository to deploy a static website to an EC2 instance running Nginx. 
This project follows DevOps best practices including secure IAM roles, infrastructure-as-code principles, and automated deployment hooks.

---


## 📌 Architecture Overview
EC2 instance with Nginx in a public subnet

GitHub repository as the source for deployments

CodePipeline for orchestrating deployment stages

CodeDeploy handling app lifecycle and instance updates

IAM roles for controlled access

Nginx setup automated via deployment script

---


## 🛠️ Technologies Used
AWS EC2

AWS CodeDeploy

AWS CodePipeline

GitHub (Public Repo)

Ubuntu (on EC2)

Nginx

Bash scripting

---


## 🧱 Step-by-Step Setup
1️⃣ VPC & Networking
VPC: nginx-VPC (CIDR: 10.0.0.0/16)

Subnet: nginx-publicsubnet (10.0.1.0/24)

Internet Gateway attached and routing configured

Security Group (EC2-SG):

Inbound: SSH (22) from My IP

Inbound: HTTP (80) from 0.0.0.0/0

Outbound: All traffic

2️⃣ EC2 Instance Setup (Ubuntu + Nginx)
Launched Ubuntu EC2 instance in public subnet

Connected via SSH and installed Nginx manually:

bash
Copy
Edit
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
3️⃣ IAM Roles for CodeDeploy & CodePipeline
Created EC2CodeDeployRole with:

AmazonEC2RoleforAWSCodeDeploy

AmazonS3ReadOnlyAccess

Attached role to EC2 instance

Created CodePipelineServiceRole and granted:

codedeploy:*, s3:*, codepipeline:*, codeconnections:*

4️⃣ GitHub Repository Setup
Public GitHub repository containing:

index.html – Static homepage

install_nginx.sh – Bash script to configure Nginx

appspec.yml – Deployment config for CodeDeploy

5️⃣ CodeDeploy Agent Setup (EC2)
Installed agent via:

bash
Copy
Edit
sudo apt update -y
sudo apt install ruby-full wget -y
cd /home/ubuntu
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
6️⃣ CodeDeploy Configuration
Application Name: nginx-app

Deployment Group: nginx-deploy-group

Tag key-value: nginx-EC2

Service Role: CodeDeployServiceRole

7️⃣ CodePipeline Setup
Pipeline Name: nginx-pipeline

Source: GitHub (via GitHub App connection)

Build stage: skipped

Deploy stage:

Provider: AWS CodeDeploy

Application: nginx-app

Deployment Group: nginx-deploy-group

---


## 🔧 Troubleshooting & Fixes

**Issue:**  
❌ GitHub source error  
**Solution:**  
Made repository public and used GitHub App connection


**Issue:**  
⚠️ IAM permission denied (S3/Deploy)  
**Solution:**  
Updated CodePipeline role to include `s3:PutObject` and `codedeploy:*`


**Issue:**  
🛑 Script not executing  
**Solution:**  
Corrected filename and added `chmod +x install_nginx.sh`


**Issue:**  
🚫 EC2 not receiving deployments  
**Solution:**  
Verified EC2 tag and ensured CodeDeploy agent was active

---


## ✅ Outcome
Functional end-to-end CI/CD pipeline

Automatically deploys new GitHub code to EC2 instance

Nginx serves updated content without manual intervention

All scripts and configurations version-controlled

📂 Repository Structure
pgsql
Copy
Edit
CI-CD-practice/
├── index.html
├── appspec.yml
└── install_nginx.sh
💡 Future Improvements
Add a CodeBuild stage for unit testing or linting

Enable SNS notifications on failed deployments

Dockerize app and migrate to ECS or EKS for scalability
