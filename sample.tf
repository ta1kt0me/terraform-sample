variable "tag" {
		default = "sample"
}
provider "aws" {
		region = "ap-northeast-1"
}

resource "aws_vpc" "sampleVPC" {
		cidr_block = "10.1.0.0/16"
		instance_tenancy = "default"
		enable_dns_support = "true"
		enable_dns_hostnames = "false"
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
		cidr_block = "10.1.1.0/24"
		availability_zone = "ap-northeast-1a"
		depends_on = ["aws_vpc.sampleVPC"]
		tags {
				Name = "${var.tag}"
		}
}

resource "aws_subnet" "private-a" {
		vpc_id = "${aws_vpc.sampleVPC.id}"
		cidr_block = "10.1.2.0/24"
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
				instance_id = "${aws_instance.jump_host.id}"
		}
		depends_on = ["aws_vpc.sampleVPC", "aws_instance.jump_host"]
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

resource "aws_security_group" "jump" {
		name = "jump"
		description = "allow ssh inbound traffic"
		vpc_id = "${aws_vpc.sampleVPC.id}"
		ingress {
				from_port = 22
				to_port = 22
				protocol = "tcp"
				cidr_blocks = ["0.0.0.0/0"]
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

resource "aws_instance" "jump_host" {
		ami = "ami-374db956"
		instance_type = "t2.micro"
		key_name = "sample"
		vpc_security_group_ids = [
				"${aws_security_group.jump.id}"
		]
		subnet_id = "${aws_subnet.public-a.id}"
		associate_public_ip_address = "true"
		root_block_device = {
				volume_type = "gp2"
				volume_size = "8"
		}
		depends_on = ["aws_subnet.public-a", "aws_security_group.jump"]
		tags {
				Name = "${var.tag}"
		}
}
