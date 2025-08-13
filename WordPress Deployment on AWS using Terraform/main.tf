# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "main-vpc"
  }
}

# Create a subnet
resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true     # <-- Add this line
  tags = {
    Name = "main-subnet"
  }
}


# Create an internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-gateway"
  }
}

# Create a route table
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

# Associate route table with subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

# Security Group allowing HTTP, HTTPS, SSH
resource "aws_security_group" "wordpress_sg" {
  name        = "wordpress-sg"
  description = "Allow HTTP, HTTPS, SSH"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
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
}

# EC2 instance with WordPress install
resource "aws_instance" "wordpress" {
  ami                    = "ami-08c40ec9ead489470"  # Ubuntu 22.04 LTS in us-east-1
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.wordpress_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 mysql-server php php-mysql libapache2-mod-php php-cli wget unzip -y
              sudo systemctl enable apache2
              sudo systemctl start apache2

              sudo mysql -e "CREATE DATABASE wordpress;"
              sudo mysql -e "CREATE USER 'wpuser'@'localhost' IDENTIFIED BY 'password';"
              sudo mysql -e "GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';"
              sudo mysql -e "FLUSH PRIVILEGES;"

              cd /tmp
              wget https://wordpress.org/latest.tar.gz
              tar -xvzf latest.tar.gz
              sudo rm -rf /var/www/html/*
              sudo mv wordpress/* /var/www/html/
              sudo chown -R www-data:www-data /var/www/html/
              sudo chmod -R 755 /var/www/html/
              sudo systemctl restart apache2
              EOF

  tags = {
    Name = "Terraform-WordPress"
  }
}
