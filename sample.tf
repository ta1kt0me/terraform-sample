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
