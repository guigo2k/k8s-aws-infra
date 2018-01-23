variable "env" {}
variable "name" {}
variable "vpc_cidr" {}

variable "tags" {
  type    = "map"
  default = {}
}

variable "clusters" {
  type    = "map"
  default = {}
}
