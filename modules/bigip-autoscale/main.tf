data "aws_ami" "latest-f5-image" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["F5 BIGIP-15.1.2.1-0.0.10 PAYG-Good 25Mbps*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

