variable "instance_type" {
  default = "t3.micro"
}

variable "allowed_ssh_ip" {
  description = "Your public IP in CIDR format"
  type        = string
}



variable "ssh_port" {
  description = "Custom SSH Port"
  default     = 2222
}
output "public_ip" {
  value = aws_instance.react_server.public_ip
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.react_cdn.domain_name
}

output "private_key_location" {
  value = local_file.private_key.filename
}