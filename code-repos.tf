resource "aws_codecommit_repository" "infrastructure" {
  repository_name = "${var.appname}-infrastructure"
  description     = "${var.appname} - Terraform Infrastructure Repo"
  tags = {
    appname = var.appname
  }
}

resource "aws_codecommit_repository" "backend" {
  repository_name = "${var.appname}-backend"
  description     = "${var.appname} - Backend Repo"
  tags = {
    appname = var.appname
  }
}
