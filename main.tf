provider "aws" {
  region = "us-west-1"
}

resource "aws_vpc" "Web_Proj_1" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet_1c" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1c"
  map_public_ip_on_launch = true

  tags {
      Name = "public_subnet_1c"
  }
}

resource "aws_subnet" "public_subnet_1b" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-1b"
  map_public_ip_on_launch = true

  tags {
      Name = "public_subnet_1b"
  }
}

resource "aws_subnet" "private_subnet_1b" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-1b"

  tags {
      Name = "private_subnet_1b"
  }
}

resource "aws_subnet" "private_subnet_1c" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-west-1c"

  tags {
      Name = "private_subnet_1c"
  }
}

resource "aws_internet_gateway" "itgw" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"

  tags {
      Name = "Web_Proj_1_itgw"
  }
}

resource "aws_route_table" "rt_public" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.itgw.id}"
  }
  tags {
    Name = "rt_public"
  }
}

resource "aws_route_table" "rt_private" {
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.natgw.id}"
  }
  tags {
    Name = "rt_private"
  }
}

resource "aws_route_table_association" "pr-a" {
subnet_id = "${aws_subnet.private_subnet_1b.id}"
route_table_id = "${aws_route_table.rt_private.id}"
}

resource "aws_route_table_association" "pr-b" {
subnet_id = "${aws_subnet.private_subnet_1c.id}"
route_table_id = "${aws_route_table.rt_private.id}"
}
resource "aws_route_table_association" "pu-a" {
subnet_id = "${aws_subnet.public_subnet_1b.id}"
route_table_id = "${aws_route_table.rt_public.id}"
}

resource "aws_route_table_association" "pu-b" {
subnet_id = "${aws_subnet.public_subnet_1c.id}"
route_table_id = "${aws_route_table.rt_public.id}"
}


/*
resource "aws_default_route_table" "Web_Proj_Route_Table" {
  default_route_table_id = "${aws_vpc.Web_Proj_1.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
  }
}
*/
resource "aws_nat_gateway" "natgw" {
  allocation_id = "${aws_eip.Web_Proj_eip.id}"
  subnet_id = "${aws_subnet.public_subnet_1b.id}"
}

resource "aws_eip" "Web_Proj_eip" {
  vpc = true
}

resource "aws_security_group" "Bastion_SG" {
    name = "Bastion_SG"
    description = "Allows my pc to Bastion Instances"
    vpc_id = "${aws_vpc.Web_Proj_1.id}"

    ingress {
      description = "TLS from VPC"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "sgelb" {
    name = "sgelb"
    description = "security group for elb"
    vpc_id = "${aws_vpc.Web_Proj_1.id}"

    ingress {
      description = "elb for security group"
      from_port = 80
      to_port = 80
      protocol = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "private_Webservers" {
    name = "private_Webservers"
    description = "security group for private web servers"
    vpc_id = "${aws_vpc.Web_Proj_1.id}"

    ingress {
      description = "security group for elb"
      from_port = 80
      to_port = 80
      protocol = "TCP"
      security_groups = ["${aws_security_group.sgelb.id}"]
    }

    ingress {
      description = "Security group access of Bastion sg"
      from_port = 0
      to_port = 0
      protocol = "-1"
      security_groups = ["${aws_security_group.Bastion_SG.id}"]
    }
/*
    egress {
      description = "Outbound of Private servers for patches"
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    } */
}

resource "aws_instance" "Web_Proj_bastion" {
subnet_id = "${aws_subnet.public_subnet_1b.id}"
vpc_security_group_ids = ["${aws_security_group.Bastion_SG.id}"]
associate_public_ip_address = true
ami = "ami-06fcc1f0bc2c8943f"
instance_type = "t2.micro"
key_name = "bastion_key"
}

resource "aws_instance" "Web_Proj_WebServer1" {
vpc_security_group_ids = ["${aws_security_group.private_Webservers.id}"]
subnet_id = "${aws_subnet.private_subnet_1b.id}"
ami = "ami-06fcc1f0bc2c8943f"
instance_type = "t2.micro"
key_name = "WebServer"

user_data = <<EOF
  #!/bin/bash
  yum update -y
  yum install httpd -y
  service httpd start
  chkconfig httpd on
  cd /var/www/html
  echo "<html><body>IP address of this instance: " > index.html
  curl http://169.254.169.254/latest/meta-data/local-ipv4 >> index.html
  echo "</body></html>" >> index.html

EOF
}

resource "aws_instance" "Web_Proj_WebServer2" {
subnet_id = "${aws_subnet.private_subnet_1c.id}"
vpc_security_group_ids = ["${aws_security_group.private_Webservers.id}"]
ami = "ami-06fcc1f0bc2c8943f"
instance_type = "t2.micro"
key_name = "WebServer"

user_data = <<EOF
  #!/bin/bash
  yum update -y
  yum install httpd -y
  service httpd start
  chkconfig httpd on
  cd /var/www/html
  echo "<html><body>IP address of this instance: " > index.html
  curl http://169.254.169.254/latest/meta-data/local-ipv4 >> index.html
  echo "</body></html>" >> index.html
EOF
}

# Load Balancer

resource "aws_alb" "alb" {
  name = "elb-WebProj"
  subnets = ["${aws_subnet.public_subnet_1b.id}","${aws_subnet.public_subnet_1c.id}"]
  security_groups = ["${aws_security_group.sgelb.id}"]
  internal = false
  tags {
    Name = "Web_Proj ALB"
  }
}

resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = "${aws_alb.alb.arn}"
  port = "80"
  protocol = "HTTP"

  default_action {
    target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
    type = "forward"
  }
}

resource "aws_alb_target_group" "alb_target_group" {
  name = "webProjtargetgroup"
  port = "80"
  protocol = "HTTP"
  vpc_id = "${aws_vpc.Web_Proj_1.id}"
  tags {
    Name = "webproj_tg"
  }
    health_check {    
    healthy_threshold   = 3    
    unhealthy_threshold = 10    
    timeout             = 5    
    interval            = 10    
    path                = "/index.html"    
    port                = "80"  
  }
}

resource "aws_alb_target_group_attachment" "alb_targetgroup_attachment1" {
  target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
  target_id = "${aws_instance.Web_Proj_WebServer1.id}"
  port = 80
}

resource "aws_alb_target_group_attachment" "alb_targetgroup_attachment2" {
  target_group_arn = "${aws_alb_target_group.alb_target_group.arn}"
  target_id = "${aws_instance.Web_Proj_WebServer2.id}"
  port = 80
}




