variable "keypair" {
		default = "sample"
}

variable "tag" {
		default = "sample"
}

variable "cidr" {
		default = {
				public = "10.1.1.0/24"
				private = "10.1.2.0/24"
		}
}

provider "aws" {
		region = "ap-northeast-1"
}

resource "aws_vpc" "sampleVPC" {
		cidr_block = "10.1.0.0/16"
		instance_tenancy = "default"
		enable_dns_support = "true"
		enable_dns_hostnames = "true"
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_internet_gateway" "sampleIGW" {
		vpc_id = "${aws_vpc.sampleVPC.id}"
		depends_on = ["aws_vpc.sampleVPC"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_subnet" "public-a" {
		vpc_id = "${aws_vpc.sampleVPC.id}"
		cidr_block = "${var.cidr.public}"
		availability_zone = "ap-northeast-1a"
		depends_on = ["aws_vpc.sampleVPC"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_subnet" "private-a" {
		vpc_id = "${aws_vpc.sampleVPC.id}"
		cidr_block = "${var.cidr.private}"
		availability_zone = "ap-northeast-1a"
		depends_on = ["aws_vpc.sampleVPC"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_route_table" "public_route" {
		vpc_id = "${aws_vpc.sampleVPC.id}"
		route {
				cidr_block = "0.0.0.0/0"
				gateway_id = "${aws_internet_gateway.sampleIGW.id}"
		}
		depends_on = ["aws_vpc.sampleVPC", "aws_internet_gateway.sampleIGW"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_route_table" "nat_route" {
		vpc_id = "${aws_vpc.sampleVPC.id}"
		route {
				cidr_block = "0.0.0.0/0"
				instance_id = "${aws_instance.nat_host.id}"
		}
		depends_on = ["aws_vpc.sampleVPC", "aws_instance.nat_host"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_route_table_association" "public-a" {
		subnet_id = "${aws_subnet.public-a.id}"
		route_table_id = "${aws_route_table.public_route.id}"
		depends_on = ["aws_subnet.public-a", "aws_route_table.public_route"]
}

resource "aws_route_table_association" "private-a" {
		subnet_id = "${aws_subnet.private-a.id}"
		route_table_id = "${aws_route_table.nat_route.id}"
		depends_on = ["aws_subnet.public-a", "aws_route_table.nat_route"]
}

resource "aws_security_group" "nat" {
		name = "nat"
		description = "allow public & private traffic"
		vpc_id = "${aws_vpc.sampleVPC.id}"
		ingress {
				from_port = 22
				to_port = 22
				protocol = "tcp"
				cidr_blocks = ["0.0.0.0/0"]
		}
		ingress {
				from_port = 80
				to_port = 80
				protocol = "tcp"
				cidr_blocks = ["${var.cidr.private}"]
		}
		ingress {
				from_port = 443
				to_port = 443
				protocol = "tcp"
				cidr_blocks = ["${var.cidr.private}"]
		}
		egress {
				from_port = 0
				to_port = 0
				protocol = "-1"
				cidr_blocks = ["0.0.0.0/0"]
		}
		depends_on = ["aws_vpc.sampleVPC"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_security_group" "app" {
		name = "app"
		description = "allow private traffic"
		vpc_id = "${aws_vpc.sampleVPC.id}"
		ingress {
				from_port = 22
				to_port = 22
				protocol = "tcp"
				cidr_blocks = ["${var.cidr.public}"]
		}
		ingress {
				from_port = 80
				to_port = 80
				protocol = "tcp"
				cidr_blocks = ["${var.cidr.public}"]
		}
		ingress {
				from_port = 443
				to_port = 443
				protocol = "tcp"
				cidr_blocks = ["${var.cidr.public}"]
		}
		egress {
				from_port = 0
				to_port = 0
				protocol = "-1"
				cidr_blocks = ["0.0.0.0/0"]
		}
		depends_on = ["aws_vpc.sampleVPC"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_instance" "nat_host" {
		ami = "ami-2443b745"
		instance_type = "t2.micro"
		key_name = "${var.keypair}"
		vpc_security_group_ids = [
				"${aws_security_group.nat.id}"
		]
		subnet_id = "${aws_subnet.public-a.id}"
		associate_public_ip_address = "true"
		source_dest_check = "false"
		root_block_device = {
				volume_type = "gp2"
				volume_size = "8"
		}
		depends_on = [
				"aws_subnet.public-a",
				"aws_security_group.nat"
		]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_instance" "app_host" {
		ami = "ami-a21529cc"
		instance_type = "t2.micro"
		key_name = "${var.keypair}"
		vpc_security_group_ids = [
				"${aws_security_group.app.id}"
		]
		subnet_id = "${aws_subnet.private-a.id}"
		associate_public_ip_address = "false"
		root_block_device = {
				volume_type = "gp2"
				volume_size = "8"
		}
		iam_instance_profile = "${aws_iam_instance_profile.app_profile.name}"
		depends_on = [
				"aws_subnet.private-a",
				"aws_security_group.app",
				"aws_iam_instance_profile.app_profile"
		]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_eip" "nat" {
		instance = "${aws_instance.nat_host.id}"
		vpc = true
}

resource "aws_iam_role" "cloudwatch_logs" {
		name = "cloudwatch_logs"
		assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "cloudwatch_logs" {
		name = "cloudwatch_logs"
		role = "${aws_iam_role.cloudwatch_logs.id}"
		depends_on = [
				"aws_iam_role.cloudwatch_logs"
		]
		policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "app_profile" {
		name = "app_profile"
		roles = [
				"${aws_iam_role.cloudwatch_logs.name}"
		]
		depends_on = [
				"aws_iam_role.cloudwatch_logs"
		]
}

output "eip" {
		value = "${aws_eip.nat.public_ip}"
}
output "app private id" {
		value = "${aws_instance.app_host.private_ip}"
}
