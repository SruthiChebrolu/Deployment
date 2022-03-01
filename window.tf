provider "aws" {
    profile = "default"
    region = "us-east-1"
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
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name        = "sruthi-subnet-11"
  }
}


/* Private subnet */
resource "aws_subnet" "private_subnet1" {
  vpc_id                  = "${aws_vpc.terraform-vpc.id}"
  cidr_block              = "172.16.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false
  tags = {
    Name        = "sruthi-subnet-2"
  }
}




/* Internet gateway for the VPC */
resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = "sruthi-ingw-16"
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
    Name        = "sruthi-ngw-16"
 
  }
}



/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = "sruthi-route-16"
  }
}


/* Routing table for private subnet */
resource "aws_route_table" "private1" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    Name        = "sruthi-route-166"
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
resource "aws_security_group" "terraform_public_sg" {
  description = "Allow limited inbound external traffic"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"
  name        = "sruthi-sg-16"

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
    Name = "ec2-public-sg"
  }
}


resource "aws_security_group" "terraform_private_sg" {
  description = "Allow limited inbound external traffic"
  vpc_id      = "${aws_vpc.terraform-vpc.id}"
  name        = "sruthi-security-16"

ingress {

    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["172.16.1.0/24"]

  } 
  egress {
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
  }
}




resource "aws_instance" "public_ec2" {
    ami = "ami-033b95fb8079dc481"
    instance_type = "t2.micro"
    vpc_security_group_ids =  [ "${aws_security_group.terraform_public_sg.id}" ]
    subnet_id = "${aws_subnet.public_subnet.id}"

    key_name               = "chintu-key"
    count         = 1
    associate_public_ip_address = true
    tags = {
      Name              = "sruthi-instance1"
      Environment       = "development"
      Project           = "TERRAFORM"
    }
}



resource "aws_instance" "private_ec2" {
    ami = "ami-0c19f80dba70861db"
    instance_type = "t2.micro"
    vpc_security_group_ids =  [ "${aws_security_group.terraform_private_sg.id}" ]
    subnet_id = "${aws_subnet.private_subnet1.id}"
    key_name               = "chintu-key"
    associate_public_ip_address = true
    tags = {
      Name              = "sruthi-instance2"
      Environment       = "development"
      Project           = "TERRAFORM"
    }
}

resource "aws_ebs_volume" "data-vol-1" {
 availability_zone = "us-east-1a"
 size = 50
 tags = {
        Name = "sruthi-volume-1"
 }

}

resource "aws_volume_attachment" "vol-1" {
 device_name = "/dev/xvdb"
 volume_id = "${aws_ebs_volume.data-vol-1.id}"
 instance_id = "${aws_instance.private_ec2.id}"
}


resource "aws_ebs_volume" "data-vol-2" {
 availability_zone = "us-east-1a"
 size = 50
 tags = {
        Name = "sruthi-volume-2"
 }

}

resource "aws_volume_attachment" "vol-2" {
 device_name = "/dev/xvdc"
 volume_id = "${aws_ebs_volume.data-vol-2.id}"
 instance_id = "${aws_instance.private_ec2.id}"
}






