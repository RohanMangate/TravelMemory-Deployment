# Security Group for Web Server (Public Subnet)
resource "aws_security_group" "web_sg" {
  name        = "TravelMemory-Web-SG"
  description = "Security group for web server"
  vpc_id      = aws_vpc.main.id

  # SSH access from your IP only
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP access
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Node.js backend port
  ingress {
    description = "Node.js Backend"
    from_port   = 3001
    to_port     = 3001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # React frontend port
  ingress {
    description = "React Frontend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TravelMemory-Web-SG"
  }
}

# Security Group for Database Server (Private Subnet)
resource "aws_security_group" "db_sg" {
  name        = "TravelMemory-DB-SG"
  description = "Security group for database server"
  vpc_id      = aws_vpc.main.id

  # SSH from web server only (for Ansible via bastion/jump host)
  ingress {
    description     = "SSH from Web Server"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # MongoDB from web server only
  ingress {
    description     = "MongoDB from Web Server"
    from_port       = 27017
    to_port         = 27017
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # All outbound traffic (for package updates via NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TravelMemory-DB-SG"
  }
}
