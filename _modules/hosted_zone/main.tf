resource "aws_route53_zone" "public" {
  name          = "${var.env}.${var.name}"
  tags          = "${merge(map("Name", "${var.env}.${var.name}"), var.tags)}"
  force_destroy = true
}

data "aws_route53_zone" "main" {
  name    = "${var.name}"
}

resource "aws_route53_record" "ns" {
  zone_id = "${data.aws_route53_zone.main.zone_id}"
  name    = "${var.env}.${var.name}"
  type    = "NS"
  ttl     = "30"

  records = [
    "${aws_route53_zone.public.name_servers.0}",
    "${aws_route53_zone.public.name_servers.1}",
    "${aws_route53_zone.public.name_servers.2}",
    "${aws_route53_zone.public.name_servers.3}",
  ]
}
