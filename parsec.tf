# Variables

variable "server_key" {
  type = "string"
}

variable "region" {
  type = "string"
}

variable "vpc_id" {
  type = "string"
}

variable "subnet_id" {
  type = "string"
}

variable "spot_price" {
  type = "string"
}

variable "instance_type" {
  type = "string"
}

variable "ami" {
  type = "string"
}

variable "ip"  {
  type = "string"
}

# Template

provider "aws" {
  region = "${var.region}"
}

data "aws_ami" "parsec" {
  most_recent = true
  filter {
    name = "name"
    values = ["${var.ami}"]
  }
}

resource "aws_security_group" "parsec" {
  vpc_id = "${var.vpc_id}"
  name = "parsec"
  description = "Allow inbound Parsec traffic and all outbound."

  ingress {
      from_port = 8000
      to_port = 8040
      protocol = "tcp"
      cidr_blocks = ["${var.ip}"]
  }

  ingress {
      from_port = 5900
      to_port = 5900
      protocol = "tcp"
      cidr_blocks = ["${var.ip}"]
  }

  ingress {
      from_port = 5900
      to_port = 5900
      protocol = "udp"
      cidr_blocks = ["${var.ip}"]
  }

  ingress {
      from_port = 8000
      to_port = 8040
      protocol = "tcp"
      cidr_blocks = ["${var.ip}"]
  }

  ingress {
      from_port = 8000
      to_port = 8040
      protocol = "udp"
      cidr_blocks = ["${var.ip}"]
  }

  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
    template = "${file("user_data.tmpl")}"

    vars {
        server_key = "${var.server_key}"
    }
}

resource "aws_spot_instance_request" "parsec" {
    spot_price = "${var.spot_price}"
    ami = "${data.aws_ami.parsec.id}"
    subnet_id = "${var.subnet_id}"
    instance_type = "${var.instance_type}"
    spot_type = "one-time"

    tags {
        Name = "ParsecServer"
    }

    root_block_device {
      volume_size = 50
    }

    ebs_block_device {
      volume_size = 100
      volume_type = "gp2"
      device_name = "xvdg"
    }

    user_data = "${data.template_file.user_data.rendered}"

    vpc_security_group_ids = ["${aws_security_group.parsec.id}"]
    associate_public_ip_address = true
}

output "server_key" {
  value = "${var.server_key}"
}

output "region" {
  value = "${var.region}"
}

output "vpc_id" {
  value = "${var.vpc_id}"
}

output "subnet_id" {
  value = "${var.subnet_id}"
}

output "spot_price" {
  value = "${var.spot_price}"
}

output "instance_type" {
  value = "${var.instance_type}"
}

output "spot_instance_id" {
  value = "${aws_spot_instance_request.parsec.spot_instance_id}"
}

output "spot_bid_status" {
  value = "${aws_spot_instance_request.parsec.spot_bid_status}"
}
