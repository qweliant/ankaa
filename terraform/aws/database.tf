module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.0"

  identifier = "ankaa-postgres-prod"

  # engine options
  engine               = "postgres"
  engine_version       = "15" # Check latest stable
  family               = "postgres15" # Parameter group family
  major_engine_version = "15"
  instance_class       = "db.t3.micro" # Free tier eligible (750hrs/mo)

  # storage
  allocated_storage     = 20
  max_allocated_storage = 100 

  # pass these in variables)
  db_name  = "ankaa_prod"
  username = "ankaa_admin"
  port     = 5432

  # network puts the DB in the "Database Subnets" (private, no internet)
  db_subnet_group_name   = module.vpc.database_subnet_group
  vpc_security_group_ids = [module.db_sg.security_group_id]
  
  # Make sure db is NOT publicly accessible
  publicly_accessible = false

  # HIPAA complient settings
  storage_encrypted   = true    # Mandatory for HIPAA
  # kms_key_id        = (uses default aws/rds key if not specified, which is fine)
  
  multi_az            = false   # Set to TRUE for high availability, FALSE for dev/start
  deletion_protection = true    # prevents accidental destruction of data

  # backups
  backup_retention_period = 7   # Keep backups for 7 days
  skip_final_snapshot     = false # Always take a snapshot before deleting

  # force SSL connections for security
  parameters = [
    {
      name  = "rds.force_ssl"
      value = "1"
    }
  ]
}