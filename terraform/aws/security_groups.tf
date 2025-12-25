# LB allows the whole world to connect via HTTPS
module "alb_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "ankaa-alb-sg"
  description = "Allow HTTPS inbound traffic from internet"
  vpc_id      = module.vpc.vpc_id

  # Inbound: Allow HTTPS (443) and HTTP (80) from anywhere
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["https-443-tcp", "http-80-tcp"]

  # Outbound: Allow everything (to talk to the App)
  egress_rules = ["all-all"]
}

# APP / ECS SG tasks  Only accepts traffic from the Load Balancer
module "app_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "ankaa-app-sg"
  description = "Security group for Phoenix App ECS tasks"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-8080-tcp" # Phoenix listens on 4000 usually, but we map port 80/443 -> container port
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Allow traffic from ALB"
    },
    {
      from_port                = 4000
      to_port                  = 4000
      protocol                 = "tcp"
      source_security_group_id = module.alb_sg.security_group_id
      description              = "Allow traffic from ALB to Phoenix Port"
    }
  ]
  
  number_of_computed_ingress_with_source_security_group_id = 2

  # Outbound: Needs internet access (via NAT) to download Docker images and talk to AWS IoT
  egress_rules = ["all-all"]
}

# db SG only accepts traffic from the App
module "db_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "ankaa-db-sg"
  description = "Security group for RDS Postgres"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.app_sg.security_group_id
      description              = "Allow traffic only from Phoenix App"
    }
  ]
  
  number_of_computed_ingress_with_source_security_group_id = 1

  # Database should NOT talk to the outside world
  egress_rules = []
}