# Hosted Zone in AWS
resource "aws_route53_zone" "main" {
  name = var.domain_name
}

# Output the Nameservers for Squarespace
output "nameservers" {
  value = aws_route53_zone.main.name_servers
}