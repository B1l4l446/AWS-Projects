# Terraform: WordPress on AWS (EC2 + VPC)

A step-by-step, human-friendly guide to deploy **WordPress on an Ubuntu EC2 instance** with a **custom VPC** using Terraform. This is designed to be easy to follow, copy/paste friendly, and strong enough to showcase on your CV or portfolio.

---

## What you’ll build

- A **custom VPC** with a public subnet
- **Internet Gateway + Route Table** for outbound internet access
- A **Security Group** that allows HTTP(80) and SSH(22)
- An **Ubuntu EC2 instance** with WordPress installed automatically via `user_data`
- Terraform **outputs** that show the public IP/URL after apply

### Architecture (simplified)

```
                 +---------------------------+
                 |         AWS VPC           |
                 |     CIDR: 10.0.0.0/16     |
                 |                           |
  Internet  ---> |  IGW  ----  Route Table   |
                 |             0.0.0.0/0     |
                 |               |           |
                 |        Public Subnet      |
                 |       10.0.1.0/24         |
                 |               |           |
                 |        EC2 (Ubuntu)       |
                 |     Apache + WordPress    |
                 +---------------------------+
```

---

## Prerequisites

- **AWS account** with programmatic access (Access Key + Secret Key)
- **Terraform** v1.0+ installed
- An **existing EC2 Key Pair** in your AWS region (for SSH)
- Basic familiarity with a terminal

> Tip: Configure AWS CLI once via `aws configure` or export environment variables before running Terraform.

---

## Repo layout (files you’ll create)

```
.
├── provider.tf
├── variables.tf
├── main.tf
└── outputs.tf
```

---

## Step-by-step: Quick start

1. **Clone** (or create) the repository locally and move into the folder.
2. **Create the files** below exactly as shown.
3. Initialize Terraform:
   ```bash
   terraform init
   ```
4. Preview the plan:
   ```bash
   terraform plan
   ```
5. Apply the changes:
   ```bash
   terraform apply
   ```
   - Enter your **key pair name** when prompted (e.g., `EC2`).
   - Type `yes` to confirm.

6. When apply finishes, Terraform will print the public **IP/URL**. Open it in a browser to finish the WordPress setup.

> On the WordPress setup page, use:
> - **Database Name:** `wordpress`
> - **Username:** `wpuser`
> - **Password:** `password`
> - **Database Host:** `localhost`

---

## Terraform files

> Copy these into files with the same names in your working directory.

### `provider.tf`

```hcl
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### `variables.tf`

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "key_name" {
  description = "AWS EC2 key pair name (must already exist)"
  type        = string
}

variable "allowed_ip" {
  description = "CIDR allowed to SSH (22) into the instance"
  type        = string
  default     = "0.0.0.0/0"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
```

### `main.tf`

```hcl
############################
# Networking (VPC + Subnet)
############################

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-gateway"
  }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

#########################
# Security Group (HTTP/SSH)
#########################

resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Allow HTTP and SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpress-sg"
  }
}

#########################
# AMI Lookup (Ubuntu 22.04 LTS)
#########################

# This finds a recent Ubuntu 22.04 LTS image in your chosen region.
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#########################
# EC2 Instance + WordPress
#########################

resource "aws_instance" "wordpress" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    set -e

    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get install -y apache2 mysql-server php php-mysql libapache2-mod-php php-cli wget unzip

    systemctl enable apache2
    systemctl start apache2

    # MySQL secure-ish setup (demo purposes)
    mysql -e "CREATE DATABASE wordpress;"
    mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'password';"
    mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
    mysql -e "FLUSH PRIVILEGES;"

    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz

    rm -rf /var/www/html/*
    mv wordpress/* /var/www/html/
    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/

    systemctl restart apache2
  EOF

  tags = {
    Name = "Terraform-WordPress"
  }
}
```

### `outputs.tf`

```hcl
output "public_ip" {
  description = "Public IP of the WordPress EC2 instance"
  value       = aws_instance.wordpress.public_ip
}

output "wordpress_url" {
  description = "URL to access WordPress"
  value       = "http://${aws_instance.wordpress.public_ip}"
}
```

---

## How it works (short version)

- **Networking:** A fresh VPC + public subnet + IGW + route table let the EC2 instance reach the internet.  
- **Security:** Security group exposes only **HTTP (80)** to the world and **SSH (22)** to your chosen CIDR.  
- **Compute:** An Ubuntu AMI is discovered dynamically; EC2 runs a `user_data` script that installs Apache, MySQL, PHP, and WordPress.  
- **Output:** After apply, Terraform prints the public IP/URL so you can hit the WordPress setup page immediately.

---

## Troubleshooting

- **No public IP?** Make sure `map_public_ip_on_launch = true` is set on the subnet (already included). Re-apply if needed.  
- **Can’t SSH?** Confirm your **key pair name** is correct and `allowed_ip` includes your public IP (use `https://ifconfig.me`).  
- **WordPress can’t connect to DB?** Use the credentials above (`wordpress` / `wpuser` / `password` / `localhost`).  
- **User data didn’t run?** Check `/var/log/cloud-init-output.log` on the instance for script output and errors.

---

## Clean up

To avoid ongoing charges, destroy the stack when you’re done:

```bash
terraform destroy
```

Type `yes` to confirm.

---

## Next steps (nice enhancements)

- Move MySQL to **Amazon RDS** for durability and backups  
- Add an **Application Load Balancer** and an Auto Scaling Group  
- Use **Terraform modules** and a **remote backend** (S3 + DynamoDB for state/locking)  
- Replace SSH with **AWS Systems Manager Session Manager**  
- Add **TLS/HTTPS** with Let’s Encrypt on the instance or via ALB

---

## Notes

- This repo is for learning and portfolio purposes. For production, use managed DB (RDS), private subnets, ALB/ASG, and proper secrets management.
