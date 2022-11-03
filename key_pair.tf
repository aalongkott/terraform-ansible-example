resource "tls_private_key" "pk" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_kp" {
  key_name   = "ansible_terraform_key_pair"
  public_key = tls_private_key.pk.public_key_openssh
}
