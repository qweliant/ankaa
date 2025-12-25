# Request the Certificate
resource "aws_acm_certificate" "ankaa_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  # Also secure "www" or subdomains if needed
  subject_alternative_names = ["www.${var.domain_name}"]

  tags = {
    Environment = "Production"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Create the Validation Record in Route53 (Proof of Ownership)
resource "aws_route53_record" "ankaa_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ankaa_cert.domain_validation_options : dvo.domain_name => dvo
  }

  allow_overwrite = true
  name            = each.value.resource_record_name
  records         = [each.value.resource_record_value]
  ttl             = 60
  type            = each.value.resource_record_type
  zone_id = aws_route53_zone.main.zone_id
}

# Wait for the Certificate to be Validated
resource "aws_acm_certificate_validation" "ankaa_cert" {
  certificate_arn         = aws_acm_certificate.ankaa_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.ankaa_cert_validation : record.fqdn]
}