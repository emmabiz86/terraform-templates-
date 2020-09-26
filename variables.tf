variable "region"  {
  default = "us-east-2"
}

variable "access_key" {
  default = "AKIAIQYIPFZW6PNQLKCA"
}

variable "secret_key" {
  default = "PDNSyTf5xXsY7fTQuRjOZ+AOEqKN1D2Bp9NgdyTB"
}

variable "public_subnet_az" {
  default = "us-east-2a"
}

variable "private_subnet_az" {
  default = "us-east-2b"
}

variable "ami_image" {
  default = "ami-03657b56516ab7912"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "keypair_name" {
  default = "AverlyKP"
}

variable "db_identifier" {
  default = "wordpress"
}

variable "db_name" {
  default = "wordpress"
}

variable "db_username" {
  default = "wordpress"
}

variable "db_password" {
  default = "wordpress"
}

variable "db_availability_zone" {
  default = "us-east-2b"
}

variable "user_data" {
  default =  <<-EOF
             #!/bin/bash
             yum update -y
             yum install httpd php php-mysql -y
             cd /var/www/html
             echo "healthy" > healthy.html
             wget https://wordpress.org/wordpress-5.1.1.tar.gz
             tar -xzf wordpress-5.1.1.tar.gz
             cp -r wordpress/* /var/www/html/
             rm -rf wordpress
             rm -rf wordpress-5.1.1.tar.gz
             chmod -R 755 wp-content
             chown -R apache:apache wp-content
             wget https://s3.amazonaws.com/bucketforwordpresslab-donotdelete/htaccess.txt
             mv htaccess.txt .htaccess
             chkconfig httpd on
             service httpd start
             EOF
             
}