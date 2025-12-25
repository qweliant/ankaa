# The Load Balancer (The actual infrastructure)
resource "aws_lb" "ankaa_alb" {
  name               = "ankaa-alb-prod"
  internal           = false
  load_balancer_type = "application"

  # Use the Security Group we made for the ALB
  security_groups = [module.alb_sg.security_group_id]

  # Place it in the Public Subnets so the internet can reach it
  subnets = module.vpc.public_subnets
  enable_deletion_protection = false # Set to true for real production

  tags = {
    Environment = "Production"
  }
}

# The Target Group of servers traffic is sent to
resource "aws_lb_target_group" "ankaa_tg" {
  name     = "ankaa-tg-prod"
  port     = 4000 # Phoenix listens on 4000 by default
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

  # Health Check: The ALB pings this path to see if the app is alive
  health_check {
    path                = "/" # Or "/health" if you have a specific health endpoint
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# Connecting  specific EC2 to the Target Group
resource "aws_lb_target_group_attachment" "ankaa_ec2_attach" {
  target_group_arn = aws_lb_target_group.ankaa_tg.arn
  target_id        = aws_instance.ankaa_app_server.id
  port             = 4000
}

# Listener 1: HTTPS (Secure Port 443) -> Forwards to App
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ankaa_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  
  # Use a modern security policy (TLS 1.2+)
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate_validation.ankaa_cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ankaa_tg.arn
  }
}

# Listener 2: HTTP (Insecure Port 80) -> Redirects to HTTPS
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ankaa_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301" # Permanent Redirect
    }
  }
}
