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

resource "aws_route_table_association" "public-a" {
		subnet_id = "${aws_subnet.public-a.id}"
		route_table_id = "${aws_route_table.public_route.id}"
		depends_on = ["aws_subnet.public-a", "aws_route_table.public_route"]
}
