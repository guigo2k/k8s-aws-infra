variable "env" {}
variable "name" {}
variable "region" {}
variable "vpc_cidr" {}

variable "zones" {
  type    = "list"
  default = []
}
