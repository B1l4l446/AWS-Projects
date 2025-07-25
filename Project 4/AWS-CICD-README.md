
# 🚀 AWS CI/CD Pipeline with GitHub – Dev & Prod Environments

A fully automated CI/CD pipeline using AWS CodeDeploy, EC2, CodePipeline, and GitHub. This project deploys different environments (dev and prod) using separate branches, showcasing DevOps skills in automation, infrastructure, and continuous delivery.

---

## 1. 🌐 VPC and Networking

- **Create a VPC**
  - Name: `nginx-VPC`
  - IPv4 CIDR: `10.0.0.0/16`

- **Create a Public Subnet**
  - Name: `nginx-publicsubnet`
  - CIDR Block: `10.0.1.0/24`

- **Internet Gateway**
  - Create and attach to VPC
  - Name: `MyIGW`

- **Route Table**
  - Name: `nginx-publicRT`
  - Route: `0.0.0.0/0` → Target: `MyIGW`
  - Associate with public subnet

- **Security Group (EC2-SG)**
  - Inbound rules:
    - SSH (22) → My IP
    - HTTP (80) → `0.0.0.0/0`

---

## 2. 🔐 IAM Roles

### EC2 Role: `EC2CodeDeployRole`

- Trusted entity: EC2
- Permissions:
  - `AmazonEC2RoleforAWSCodeDeploy`
  - `AmazonS3ReadOnlyAccess`
- Attach this role to **both EC2 instances**

### CodeDeploy Role: `CodeDeployServiceRole`

- Trusted entity: CodeDeploy
- Permissions:
  - `AWSCodeDeployRole`

---

## 3. 💻 Launch EC2 Instances

### Dev Instance

- Name: `nginx-dev-EC2`
- Subnet: `nginx-publicsubnet`
- Security Group: `EC2-SG`
- IAM Role: `EC2CodeDeployRole`
- Tag: `Env=dev`

### Prod Instance

- Name: `nginx-prod-EC2`
- Subnet: `nginx-publicsubnet`
- Tag: `Env=prod`
- Same config as dev

### SSH into each EC2 instance and run:

```bash
# Install Nginx
sudo apt update
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx

# Install CodeDeploy Agent
sudo apt update -y
sudo apt install ruby-full wget -y
cd /home/ubuntu
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install
chmod +x install
sudo ./install auto
sudo systemctl start codedeploy-agent
sudo systemctl enable codedeploy-agent
```

---

## 4. Create the GitHub repository

- Click create new repository
  - Name: `nginx-cicd`
  - Visibility: I chose private

- Create the Main and Dev branches

  - GitHub should have created the main branch by default
  - To create the dev branch:
    - Click the branch dropdown that says "main"
    - In the input field, type "dev"
    - Click "Create branch: dev from 'main'"
    - You should now have two branches: `main` and `dev`

---

## 5. Upload files to the main and dev branch

### Dev branch

- Click add files
- Upload your `index.html`, `appspec.yml`, and the folder `scripts/` with `install_nginx.sh`
- In `index.html`, you can add a heading like `<h1>Development Environment</h1>`
- Click commit changes

### Main branch

- Switch back to the main branch from the dropdown
- Upload the same files (`index.html`, `appspec.yml`, and the folder `scripts/` with `install_nginx.sh`)
- Change the content in `index.html` to `<h1>Production Environment</h1>`
- Click commit changes

---

## 6. Configure AWS CodeDeploy Applications and Deployment Groups

- In the AWS Console, navigate to CodeDeploy
- Create two applications:
  - `nginx-app-prod` (for production)
  - `nginx-app-dev` (for development)

- For each application, create a deployment group:
  - Assign a descriptive name: e.g., `nginx-prod-deploy-group` and `nginx-dev-deploy-group`
  - Select the Service Role: use the `CodeDeployServiceRole` you created earlier
  - Choose the EC2 instances by tags:
    - Filter by `Env=prod` for production group
    - Filter by `Env=dev` for development group
  - Set deployment settings: Deployment type: In-place

---

## 7. Set Up AWS CodePipeline for Automated CI/CD

- Create two pipelines: one for production and one for development

- For each pipeline:

  - **Source stage**:
    - Connect your GitHub repo and select the appropriate branch (`main` for production, `dev` for development)
  
  - **Deploy stage**:
    - Use AWS CodeDeploy
    - Select the corresponding application and deployment group

- You can skip the other stages and create the pipeline

---

## 8. Deploy and Verify

- Push code changes to your dev branch → CodePipeline triggers deployment to the dev EC2 instance
- After testing, merge dev into main → triggers production deployment
- Verify the deployment by accessing the public IP of each EC2 instance:
  - Dev instance should display: Development Environment page
  - Prod instance should display: Production Environment page

---

# 🔧 Troubleshooting and Fixes

## Deployment Scripts Not Running Correctly

**Problem**: CodeDeploy failed because the script `install_nginx.sh` didn’t execute.

**Cause**: Script lacked execute permission.

**Fix**:

```bash
chmod +x scripts/install_nginx.sh
```
