module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = "ankaa-vpc-prod"
  cidr = "10.0.0.0/16"

  azs = ["us-east-1a", "us-east-1b"]

  # PUBLIC SUBNETS: Application Load Balancer (ALB), NAT Gateway
  public_subnets = ["10.0.1.0/24", "10.0.2.0/24"]

  # PRIVATE APP SUBNETS: Phoenix App (ECS), Rust Simulator (ECS)
  # These can reach OUT to the internet (via NAT) but the internet cannot reach IN.
  private_subnets = ["10.0.3.0/24", "10.0.4.0/24"]

  # DATABASE SUBNETS: RDS Postgres
  # Totally isolated. No internet access at all.
  database_subnets = ["10.0.5.0/24", "10.0.6.0/24"]

  # === COST SAVING CONFIGURATION ===
  # We enable NAT so private apps can download updates/talk to IoT Core.
  # We use "single_nat_gateway" to share one NAT across both zones.
  # SAVINGS: ~$32/month (vs ~$64 for one per zone)
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  # DNS Settings (Required for internal service discovery)
  enable_dns_hostnames = true
  enable_dns_support   = true
}