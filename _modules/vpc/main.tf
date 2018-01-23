resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  tags                 = "${merge(map("Name", "${var.env}.${var.name}"), var.tags, var.clusters)}"
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags   = "${merge(map("Name", "${var.env}.${var.name}-ig"), var.tags, var.clusters)}"
}
