module "vpc" {
  source   = "_modules/vpc"
  name     = "${var.name}"
  env      = "${var.env}"
  vpc_cidr = "${var.vpc_cidr}"
  clusters = "${var.clusters}"

  tags {
    Infra       = "${var.env}.${var.name}"
    Environment = "${var.env}"
    Terraformed = "true"
  }
}

module "subnet_pair" {
  source              = "_modules/subnet_pair"
  name                = "${var.name}"
  env                 = "${var.env}"
  vpc_id              = "${module.vpc.vpc_id}"
  vpc_cidr            = "${module.vpc.cidr_block}"
  internet_gateway_id = "${module.vpc.internet_gateway_id}"
  availability_zones  = "${var.zones}"
  clusters            = "${var.clusters}"

  tags {
    Infra       = "${var.env}.${var.name}"
    Environment = "${var.env}"
    Terraformed = "true"
  }
}

module "hosted_zone" {
  source   = "_modules/hosted_zone"
  name     = "${var.name}"
  env      = "${var.env}"

  tags {
    Infra       = "${var.env}.${var.name}"
    Environment = "${var.env}"
    Terraformed = "true"
  }
}

module "remote_state" {
  source   = "_modules/remote_state"
  name     = "${var.name}"
  env      = "${var.env}"
  region   = "${var.region}"

  tags {
    Infra       = "${var.env}.${var.name}"
    Environment = "${var.env}"
    Terraformed = "true"
  }
}
