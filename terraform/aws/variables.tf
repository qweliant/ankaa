variable "db_password" {
  description = "The password for the RDS database"
  type        = string
  sensitive   = true
}

variable "domain_name" {
  description = "The domain name for the application (e.g., ankaa.io)"
  type        = string
}
