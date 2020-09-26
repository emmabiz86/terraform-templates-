provider "aws" {
  region     =   var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
resource "aws_vpc" "wordpressVPC" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "emma_vpc"
  }
}
resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.wordpressVPC.id

  tags = {
    Name = "emma_IGW"
  }
}
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.wordpressVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.public_subnet_az
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.wordpressVPC.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.private_subnet_az
  map_public_ip_on_launch = "false"

  tags = {
    Name = "private"
  }
}
resource "aws_route_table" "public_route" {
  vpc_id = aws_vpc.wordpressVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "public"
  }
}
resource "aws_route_table" "private_route" {
  vpc_id = aws_vpc.wordpressVPC.id

  tags = {
    Name = "private"
  }
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route.id
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route.id
}

resource "aws_route" "r" {
  route_table_id            = aws_route_table.public_route.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id                = aws_internet_gateway.gateway.id
  depends_on       = [aws_internet_gateway.gateway, aws_route_table.public_route]
}

resource "aws_eip" "nat_eip" {
vpc      = true
}
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "nat_gateway"
  }
}

resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private_route.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id

  timeouts {
    create = "5m"
  }
}


resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      =  aws_vpc.wordpressVPC.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}
resource "aws_instance" "web-server-Instance" {
  ami           = var.ami_image
  instance_type = var.instance_type
  key_name      =  var.keypair_name
  network_interface {
    network_interface_id = aws_network_interface.test.id
    device_index         = 0
  }

  tags = {
    Name = "wordpress_server"
  }
user_data = var.user_data


}
resource "aws_network_interface" "test" {
  subnet_id       = aws_subnet.public_subnet.id
  private_ips     = ["10.0.1.25"]
  security_groups = [aws_security_group.allow_http.id]


}
resource "aws_eip" "webservser_eip" {
  instance = aws_instance.web-server-Instance.id
  vpc      = true
}


resource "aws_db_instance" "default" {
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  identifier           = var.db_identifier
  name                 = var.db_name
  username             = var.db_username
  password             = var.db_password
  port                 = "3306"
  publicly_accessible  = "false"
  storage_encrypted    = "false"
  backup_retention_period = 0
  skip_final_snapshot       = true
  final_snapshot_identifier = "Ignore"
  db_subnet_group_name      = aws_db_subnet_group.msql_subnet_group.id
  vpc_security_group_ids    = [aws_security_group.Mysql-sg.id]
  availability_zone    = var.db_availability_zone
  
  
}

resource "aws_db_subnet_group" "msql_subnet_group" {
  name       = "main"
  subnet_ids = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_security_group" "Mysql-sg" {
  name   = "mysql-security-group"
  vpc_id = aws_vpc.wordpressVPC.id

  ingress {
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    cidr_blocks = ["10.0.1.0/24"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}
