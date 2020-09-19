provider "aws" {
  region     = "us-west-2"
  access_key = "AKIAIG7ZEPTO5GEE4KQA"
  secret_key = "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"
}
resource "aws_vpc" "prod" {
  cidr_block = "192.168.0.0/16"
} 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod.id

  tags = {
    Name = "EmmaVPC"
  }
}
resource "aws_route_table" "r" {
  vpc_id = aws_vpc.prod.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
   }
}
resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "Subnet1"
  }
}
resource "aws_route_table_association" "route1" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id 
}
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.prod.id

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
    Name = "allow_web"
  }
}
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet1.id
  private_ips     = ["192.168.1.23"]
  security_groups = [aws_security_group.allow_web.id]
}
resource "aws_eip" "lb" {
  instance = aws_instance.web-server-Instance.id
  vpc      = true
}
resource "aws_instance" "web-server-Instance" {
  ami           = "ami-01ce4793a2f45922e"
  instance_type = "t2.micro"
  key_name      =  "LunaKP"
  network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  tags = {
    Name = "HelloWorld"
  }
user_data = <<-EOF
             #!/bin/bash
             yum update -y
             yum install httpd -y
             service httpd start
             chkconfig httpd on
             cd /var/www/html
             echo "<html><h1>Hello Cloud Gurus Welcome To My      Webpage</h1></html>" > index.html
EOF
}

