output "name" {
  value = "${var.name}"
}

output "vpc_name" {
  value = "${var.env}.${var.name}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "clusters" {
  value = "${var.clusters}"
}

output "name_servers" {
  value = "${module.hosted_zone.name_servers}"
}

output "public_zone_id" {
  value = "${module.hosted_zone.public_zone_id}"
}

output "state_store" {
  value = "${module.remote_state.state_store}"
}

output "public_subnet_ids" {
  value = "${module.subnet_pair.public_subnet_ids}"
}

output "private_subnet_ids" {
  value = "${module.subnet_pair.private_subnet_ids}"
}

output "nat_gateway_ids" {
  value = "${module.subnet_pair.nat_gateway_ids}"
}

output "availability_zones" {
  value = "${module.subnet_pair.availability_zones}"
}
