resource "aws_iam_role" "ankaa_app_role" {
  name = "AnkaaAppRole"

  # who is allowed to wear this ID badge? (The EC2 service)
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# allow Session Manager (SSM) so you can shell in without SSH keys
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.ankaa_app_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allows EC2 to read the Certs from the Secret Manager
resource "aws_iam_role_policy" "secrets_access" {
  name = "AllowReadingIoTSecrets"
  role = aws_iam_role.ankaa_app_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.iot_identities.arn]
      }
    ]
  })
}

# Create Instance Profile: container that holds the role for EC2)
resource "aws_iam_instance_profile" "ankaa_app_profile" {
  name = "AnkaaAppInstanceProfile"
  role = aws_iam_role.ankaa_app_role.name
}