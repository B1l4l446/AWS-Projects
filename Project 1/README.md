# 🚀 Advanced WordPress Deployment on AWS

This project demonstrates an advanced deployment of a **WordPress website on AWS**, using scalable, secure, and production-ready architecture. It utilizes a custom VPC, EC2, RDS (MySQL), NAT Gateway, Application Load Balancer (ALB), and a Bastion Host for secure access.

---

## 🌐 Architecture Overview

- **VPC** with custom CIDR block
- **3-Tier Architecture** (Public + Private Subnets)
- **Internet & NAT Gateways** for traffic control
- **Application Load Balancer** for traffic distribution
- **EC2 Instances** hosting WordPress in private subnets
- **RDS (MySQL)** in private subnets for database layer
- **Bastion Host** for secure SSH access

---

## 🛠️ Step-by-Step Deployment

### 1. Create VPC and Subnets
- **CIDR**: `10.0.0.0/16`

#### Public Subnets
| Subnet | AZ     | CIDR         |
|--------|--------|--------------|
| Subnet1 | AZ-a | `10.0.1.0/24` |
| Subnet2 | AZ-b | `10.0.2.0/24` |
| Subnet3 | AZ-c | `10.0.3.0/24` |

#### Private Subnets
| Subnet | AZ     | CIDR          |
|--------|--------|---------------|
| Subnet4 | AZ-a | `10.0.11.0/24` |
| Subnet5 | AZ-b | `10.0.12.0/24` |
| Subnet6 | AZ-c | `10.0.13.0/24` |

---

### 2. Create Internet Gateway
- **Name**: `MyIGW`
- Attach to your VPC

---

### 3. Create NAT Gateway
- **Name**: `MyNGW`
- Deploy in a public subnet
- Assign an Elastic IP
- Ensure it uses public connectivity

---

### 4. Configure Route Tables

#### Public Route Table (`PublicRT`)
- Route: `0.0.0.0/0` → **MyIGW**
- Associate with all **public subnets**

#### Private Route Table (`PrivateRT`)
- Route: `0.0.0.0/0` → **MyNGW**
- Associate with all **private subnets**

---

### 5. Create Security Groups

#### ALB Security Group (`ALB-SG`)
- **Inbound**: HTTP (80) from anywhere
- **Outbound**: All traffic

#### WordPress EC2 Security Group (`Wordpress-SG`)
- **Inbound**:
  - HTTP (80), HTTPS (443) from `ALB-SG`
  - SSH (22) from **Bastion host** (configured later)
- **Outbound**: All traffic (to reach RDS & Internet via NAT)

#### RDS Security Group (`RDS-SG`)
- **Inbound**: MySQL (3306) from `Wordpress-SG`
- **Outbound**: All traffic

---

### 6. Application Load Balancer (ALB)
- **Type**: Application Load Balancer
- **Scheme**: Internet-facing
- **Subnets**: All public subnets
- **Security Group**: `ALB-SG`

#### Listener
- Protocol: **HTTP (port 80)**

#### Target Group
- **Target Type**: Instance
- **Health Check Path**: `/`
- **Protocol**: HTTP

---

### 7. Launch MySQL RDS (Private Subnet)

- **Subnet Group Name**: `my-db-subnet-group` (min. 2 AZs)
- **Engine**: MySQL
- **Deployment**: Single AZ (Free Tier)
- **Name**: `MyRDS`
- **Credentials**: Set master username/password
- **Public Access**: Disabled
- **VPC Security Group**: `RDS-SG`

---

### 8. Launch EC2 Instance (WordPress)

- **AMI**: Ubuntu (Free Tier)
- **Subnet**: Private
- **Security Group**: `Wordpress-SG`
- **User Data Script**: Installs and configures WordPress

<details>
<summary>📜 <strong>Click to view WordPress install script</strong></summary>

```bash
#!/bin/bash
# Update system
apt update -y
apt upgrade -y

# Install Apache, PHP, MySQL extensions
apt install -y apache2 php php-mysql libapache2-mod-php wget unzip

# Start Apache
systemctl enable apache2
systemctl start apache2

# Download and configure WordPress
cd /var/www/html
wget https://wordpress.org/latest.zip
unzip latest.zip
cp -r wordpress/* .
rm -rf wordpress latest.zip

# Set correct permissions
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

# Create config file
cp wp-config-sample.php wp-config.php

# Replace placeholders with actual DB credentials
sed -i "s/database_name_here/your_db_name/" wp-config.php
sed -i "s/username_here/your_db_user/" wp-config.php
sed -i "s/password_here/your_db_password/" wp-config.php
sed -i "s/localhost/your-db-endpoint.rds.amazonaws.com/" wp-config.php
</details>
⚠️ Replace the placeholders:
your_db_name, your_db_user, your_db_password, and your-db-endpoint.rds.amazonaws.com

9. Bastion Host Setup (For SSH Access)
Launch an EC2 instance in a public subnet

Assign a public IP

Allow SSH (22) from your IP

Add a rule in Wordpress-SG to allow SSH from the Bastion SG

Copy Key to Bastion
powershell
Copy
Edit
scp -i bastion.pem wordpress.pem ubuntu@<bastion-public-ip>:~
On Bastion Instance
bash
Copy
Edit
chmod 400 wordpress.pem
ssh -i wordpress.pem ubuntu@<wordpress-private-ip>
🧪 Troubleshooting
🔧 Issue: ALB Shows Apache Default Page
Cause: WordPress files not installed in /var/www/html.

Fix:

bash
Copy
Edit
sudo rm -f /var/www/html/index.html
sudo mv wordpress/* /var/www/html/
sudo chown -R www-data:www-data /var/www/html/
sudo systemctl restart apache2
✅ Features & Benefits
✅ Isolated and secure VPC architecture

✅ High availability across multiple AZs

✅ Secure Bastion SSH access to private EC2

✅ Scalable WordPress with ALB and RDS

✅ Infrastructure aligned with best practices
