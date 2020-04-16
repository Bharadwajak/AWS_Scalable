provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "Web_Proj_1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1a" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"

  tags {
      Name = "public_subnet_1a"
  }
}

resource "aws_subnet" "public_subnet_1b" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-1b"

  tags {
      Name = "public_subnet_1b"
  }
}

resource "aws_subnet" "private_subnet_1a" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-1a"

  tags {
      Name = "private_subnet_1a"
  }
}

resource "aws_subnet" "private_subnet_1b" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-west-1b"

  tags {
      Name = "private_subnet_1b"
  }
}

resource "aws_internet_gateway" "itgw" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"

  tags {
      Name = "Web_Proj_1_itgw"
  }
}

resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.Web_Proj_eip.id}"
  subnet_id = "${aws_subnet.public_subnet_1a.id}"
}
resource "aws_eip" "Web_Proj_eip" {
  vpc = true
}

resource "aws_instance" "Web_Proj_bastion" {
ami = "ami-06fcc1f0bc2c8943f"
instance_type = "t2.micro"
key_name = "bastion_key"
}
