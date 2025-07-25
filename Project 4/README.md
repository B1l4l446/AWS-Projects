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


---

## 4. 📦 Create the GitHub Repository

- Go to GitHub and create a new repository:
  - Name: `nginx-cicd`
  - Visibility: Private (or Public if showcasing)

### Create the `main` and `dev` Branches

- GitHub creates the `main` branch by default.
- To create the `dev` branch:
  - Click the branch dropdown that says "main"
  - In the input field, type `dev`
  - Click **"Create branch: dev from 'main'"**
- You should now have two branches: `main` and `dev`

---

## 5. 📁 Upload Files to GitHub

### Dev Branch
- Switch to the `dev` branch
- Upload:
  - `index.html` – with `<h1>Development Environment</h1>`
  - `appspec.yml`
  - `scripts/install_nginx.sh`
- Click **Commit Changes**

### Main Branch
- Switch back to the `main` branch
- Upload the **same files**, but modify:
  - `index.html` – with `<h1>Production Environment</h1>`
- Click **Commit Changes**

---

## 6. 🚀 Configure AWS CodeDeploy Applications & Deployment Groups

- Navigate to **AWS Console → CodeDeploy**
- Create two applications:
  - `nginx-app-dev`
  - `nginx-app-prod`

### For Each Application:
- Create a **Deployment Group**:
  - Example names:
    - Dev: `nginx-dev-deploy-group`
    - Prod: `nginx-prod-deploy-group`
  - Select the **Service Role**: `CodeDeployServiceRole`
  - Select EC2 instances **by tag**:
    - Dev: `Env=dev`
    - Prod: `Env=prod`
  - Deployment type: **In-place**

---

## 7. 🔁 Configure AWS CodePipeline (CI/CD)

Create two pipelines: one for development, one for production.

### For Each Pipeline:
- **Source Stage**:
  - Provider: GitHub
  - Repo: `nginx-cicd`
  - Branch:
    - Dev Pipeline: `dev`
    - Prod Pipeline: `main`

- **Deploy Stage**:
  - Provider: AWS CodeDeploy
  - Application Name:
    - Dev: `nginx-app-dev`
    - Prod: `nginx-app-prod`
  - Deployment Group:
    - Dev: `nginx-dev-deploy-group`
    - Prod: `nginx-prod-deploy-group`

- Skip Build stage (unless using CodeBuild)
- Click **Create pipeline**

---

## 8. ✅ Deploy and Verify

- Push code to the `dev` branch:
  - Triggers deployment to **Dev EC2 instance**
- After successful testing, merge `dev` into `main`:
  - Triggers deployment to **Prod EC2 instance**

### ✅ Verify the Result:
- Access the **public IP** of each EC2 instance:
  - Dev instance should show: **Development Environment**
  - Prod instance should show: **Production Environment**

---

## 🛠️ Troubleshooting & Fixes

### ❌ Deployment Script Not Running

**Problem:**  
Deployment failed because `install_nginx.sh` didn’t execute.

**Cause:**  
The script was **not executable**.

**Fix:**  
Make sure the script has execute permissions before pushing to GitHub:

```bash
chmod +x scripts/install_nginx.sh
