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
