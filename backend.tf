terraform {
  backend "s3" {
    bucket = "cally-terraform-state-2026-110"
    key    = "terraform-portfolio/terraform.tfstate"
    region = "eu-west-2"
  }
}