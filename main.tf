terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-3"
}


resource "aws_security_group" "winrm" {
name = "allow-winrm-rdp-http"
vpc_id = "vpc-e30fe08b"
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 5985
    to_port = 5985
    protocol = "tcp"
  }
ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 3389
    to_port = 3389
    protocol = "tcp"
  }
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
from_port = 80
    to_port = 80
    protocol = "tcp"
  }
egress {
   from_port = 0
   to_port = 0
   protocol = "-1"
   cidr_blocks = ["0.0.0.0/0"]
 }
}

resource "aws_instance" "app_server" {
  count = 2
  ami                    = "ami-022d7dc38f1289513"
  instance_type          = "t2.micro"
  key_name   = "Good_keys"
  security_groups = ["${aws_security_group.winrm.id}"]
  subnet_id              = "subnet-16ef995b"
  associate_public_ip_address = true
  provisioner "local-exec" {
    command = "netsh advfirewall firewall add rule name='WinRM-HTTP' dir=in localport=5985 protocol=TCP action=allow"
	interpreter = ["PowerShell", "-Command"]
  }
  tags = {
    Name = "VM-${count.index}"
  }
}

resource "aws_elb" "load_balancer" {
  name               = "test-lb"
  availability_zones = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]

  listener {
    instance_port     = 80
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:80"
    interval            = 30
  }

  instances                   = "${aws_instance.app_server.*.id}"
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

}