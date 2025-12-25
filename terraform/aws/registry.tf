resource "aws_ecr_repository" "ankaa_repo" {
  name                 = "ankaa-backend"
  image_tag_mutability = "MUTABLE"

  # SECURITY: Scan images for vulnerabilities on push (Good for HIPAA)
  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true # Allows destroying terraform even if images exist
}

resource "aws_ecr_repository" "ankaa_simulator_repo" {
  name                 = "ankaa-rust-simulator"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true
}

# Allow the EC2 Instance to PULL from this repo
resource "aws_iam_role_policy" "ecr_pull_access" {
  name = "AllowECRPull"
  role = aws_iam_role.ankaa_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })
}
