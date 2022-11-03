output "web_url" {
  value = "http://${aws_instance.os1.public_ip}/web/"
}
