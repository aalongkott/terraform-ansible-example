terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  profile = "default"
}

#aws instance creation
resource "aws_instance" "os1" {
  depends_on             = [aws_security_group.demo-sg, aws_key_pair.ssh_kp]
  ami                    = "ami-010aff33ed5991201"
  instance_type          = "t2.micro"
  key_name               = "ansible_terraform_key_pair"
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  tags = {
    Name = "TerraformOS"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.pk.private_key_pem
    host        = self.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo amazon-linux-extras install ansible2 -y",
    ]
  }
}

#IP of aws instance copied to a file ip.txt in local system
resource "local_file" "ip" {
  content  = aws_instance.os1.public_ip
  filename = "ip.txt"
}

resource "null_resource" "nullremote0" {
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.pk.private_key_pem
    host        = aws_instance.os1.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "mkdir -p ansible_terraform/aws_instance",
      "cd /home/ec2-user/ansible_terraform/aws_instance/",
      "echo '${tls_private_key.pk.private_key_pem}' > ./private_key.pem && chmod 400 ./private_key.pem "
    ]
  }
}
#connecting to the Ansible control node using SSH connection
resource "null_resource" "nullremote1" {
  depends_on = [aws_instance.os1, null_resource.nullremote0]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.pk.private_key_pem
    host        = aws_instance.os1.public_ip
  }

  provisioner "file" {
    source      = "ansible.cfg"
    destination = "/home/ec2-user/ansible_terraform/aws_instance/ansible.cfg"
  }

  provisioner "file" {
    source      = "ip.txt"
    destination = "/home/ec2-user/ansible_terraform/aws_instance/ip.txt"
  }

  provisioner "file" {
    source      = "instance_playbook.yml"
    destination = "/home/ec2-user/ansible_terraform/aws_instance/instance_playbook.yml"
  }
}

#connecting to the Linux OS having the Ansible playbook
resource "null_resource" "nullremote2" {
  depends_on = [aws_volume_attachment.ebs_att, null_resource.nullremote1]
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = tls_private_key.pk.private_key_pem
    host        = aws_instance.os1.public_ip
  }
  #command to run ansible playbook on remote Linux OS
  provisioner "remote-exec" {
    inline = [
      "cd /home/ec2-user/ansible_terraform/aws_instance/",
      "sudo ansible-playbook instance_playbook.yml"
    ]
  }
}
