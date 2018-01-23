resource "aws_s3_bucket" "state_store" {
  bucket        = "${var.env}.${var.name}-state"
  acl           = "private"
  tags          = "${merge(map("Name", "${var.env}.${var.name}-state"), var.tags)}"
  force_destroy = true

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }
}

data "template_file" "backend" {
  template = "${file("${path.module}/backend.tmpl")}"

  vars {
    region = "${var.region}"
    bucket = "${var.env}.${var.name}-state"
    key    = "${var.env}.${var.name}.tfstate"
  }
}

resource "local_file" "backend" {
  depends_on = ["aws_s3_bucket.state_store"]
  content    = "${data.template_file.backend.rendered}"
  filename   = "backend.tf"
}
