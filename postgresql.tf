provider "aws" {
    profile = "default"
    region = "us-east-2"
}

## Create VPC ##
resource "aws_vpc" "terraform-vpc" {
  cidr_block       = "172.16.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "sruthi-vpc-11"
  }
}

output "aws_vpc_id" {
  value = "${aws_vpc.terraform-vpc.id}"
}


/*==== Subnets ======*/

/* Public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "172.16.1.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags = {
    Name        = "sruthi-subnet-11"
  }
}


/* Private subnet */
resource "aws_subnet" "private_subnet1" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "172.16.2.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false
  tags = {
    Name        = "sruthi-subnet-2"
  }
}




/* Internet gateway for the VPC */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = "sruthi-ingw-11"
  }
}



resource "aws_eip" "nat_eip" {
  vpc        = true
}

/* NAT */
resource "aws_nat_gateway" "nat1" {
  allocation_id = "${aws_eip.nat_eip.id}"
   subnet_id     = "${aws_subnet.public_subnet.id}"
  depends_on    = [aws_internet_gateway.ig]
  tags = {
    Name        = "sruthi-ngw-11"
 
  }
}



/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = "sruthi-route-11"
  }
}


/* Routing table for private subnet */
resource "aws_route_table" "private1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = "sruthi-route-111"
  }
}



resource "aws_route" "route_internet_gateway" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}


resource "aws_route" "route_nat_gateway1" {
  route_table_id         = "${aws_route_table.private1.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_nat_gateway.nat1.id}"
}



/* Route table associations */
resource "aws_route_table_association" "public_ass" {
  subnet_id      = "${aws_subnet.public_subnet.id}"
  route_table_id = "${aws_route_table.public.id}"
}


resource "aws_route_table_association" "private1_ass" {
  subnet_id     = "${aws_subnet.private_subnet1.id}"
  route_table_id = "${aws_route_table.private1.id}"
}	


## Security Group##
resource "aws_security_group" "terraform_private_sg" {
  description = "Allow limited inbound external traffic"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"
  name        = "sruthi-security-group-11"

 ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 80
  }

 ingress {
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 80
  }


  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = "ec2-private-sg"
  }
}



output "aws_security_gr_id" {
  value = "${aws_security_group.terraform_private_sg.id}"
}

resource "aws_instance" "public_ec2" {
    ami = "ami-0b614a5d911900a9b"
    instance_type = "t2.micro"
    vpc_security_group_ids =  [ "${aws_security_group.terraform_private_sg.id}" ]
    subnet_id = "${aws_subnet.public_subnet.id}"

    key_name               = "chebrolu-pair"
    count         = 1
    associate_public_ip_address = true
    tags = {
      Name              = "sruthi-111"
      Environment       = "development"
      Project           = "TERRAFORM"
    }
}




resource "aws_instance" "private_ec2" {
    ami = "ami-0b614a5d911900a9b"
    instance_type = "t2.micro"
  vpc_security_group_ids =  [ "${aws_security_group.terraform_private_sg.id}" ]
    subnet_id = "${aws_subnet.private_subnet1.id}"
root_block_device {
    volume_size           = "200"
}
  user_data= <<-EOF
#!/bin/bash
# update system packages
yum update -y

# enable repository to install postgresql
amazon-linux-extras enable postgresql11

# Install PostgreSQL server and initialize the database 
# cluster for this server
yum install postgresql-server postgresql-devel -y
/usr/bin/postgresql-setup --initdb
# Update the IPs of the address to listen from PostgreSQL config
sed -i "59i listen_addresses = '*'" /var/lib/pgsql/data/postgresql.conf

# Start the db service
systemctl enable postgresql
systemctl start postgresql

EOF
    key_name               = "chebrolu-pair"
    count         = 1
    associate_public_ip_address = true
    tags = {
      Name              = "sruthi_11"
      Environment       = "development"
      Project           = "TERRAFORM"
    }
}



