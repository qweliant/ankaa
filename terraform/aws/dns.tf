resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.ankaa_alb.dns_name
    zone_id                = aws_lb.ankaa_alb.zone_id
    evaluate_target_health = true
  }
}