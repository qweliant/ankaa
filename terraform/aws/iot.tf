resource "aws_iot_thing" "backend" {
  name = "ankaa-phoenix-backend"
  attributes = { role = "server" }
}

resource "aws_iot_thing" "simulator" {
  name = "ankaa-rust-simulator"
  attributes = { role = "device" }
}

# Generate a certificate for the Phoenix Backend
resource "aws_iot_certificate" "backend_cert" {
  active = true
}

# Generate a certificate for the Rust Simulator
resource "aws_iot_certificate" "simulator_cert" {
  active = true
}

# Attach Certs to Things
resource "aws_iot_thing_principal_attachment" "att_backend" {
  thing     = aws_iot_thing.backend.name
  principal = aws_iot_certificate.backend_cert.arn
}

resource "aws_iot_thing_principal_attachment" "att_sim" {
  thing     = aws_iot_thing.simulator.name
  principal = aws_iot_certificate.simulator_cert.arn
}

resource "aws_iot_policy" "backend_policy" {
  name = "AnkaaBackendPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = ["iot:Connect"],
        Resource = "*"
      },
      # READ: Listen to device data (Telemetry)
      {
        Effect = "Allow",
        Action = ["iot:Subscribe", "iot:Receive"],
        Resource = [
          "arn:aws:iot:*:*:topicfilter/ankaa/+/telemetry",
          "arn:aws:iot:*:*:topicfilter/devices/+/telemetry",
          "arn:aws:iot:*:*:topic/ankaa/+/telemetry",
          "arn:aws:iot:*:*:topic/devices/+/telemetry",
        ]
      },
      # WRITE: Send signals/modes to the Rust app (Commands)
      {
        Effect = "Allow",
        Action = ["iot:Publish"],
        Resource = [
          "arn:aws:iot:*:*:topic/ankaa/+/cmd",
          "arn:aws:iot:*:*:topic/ankaa/simulator/control"
        ]
      }
    ]
  })
}

resource "aws_iot_policy" "simulator_policy" {
  name = "AnkaaSimulatorPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Action = ["iot:Connect"],
        Resource = "*"
      },
      # WRITE: Send device data (Telemetry)
      {
        Effect = "Allow",
        Action = ["iot:Publish"],
        Resource = ["arn:aws:iot:*:*:topic/ankaa/+/telemetry", "arn:aws:iot:*:*:topic/devices/+/telemetry"]
      },
      # READ: Listen for start/stop signals (Commands)
      {
        Effect = "Allow",
        Action = ["iot:Subscribe", "iot:Receive"],
        Resource = [
          # Matches Rust: client.subscribe("ankaa/simulator/control")
          "arn:aws:iot:*:*:topicfilter/ankaa/simulator/control",
          "arn:aws:iot:*:*:topic/ankaa/simulator/control",
          
        ]
      }
    ]
  })
}

# Attach Policies to Certs
resource "aws_iot_policy_attachment" "att_backend_policy" {
  policy = aws_iot_policy.backend_policy.name
  target = aws_iot_certificate.backend_cert.arn
}

resource "aws_iot_policy_attachment" "att_sim_policy" {
  policy = aws_iot_policy.simulator_policy.name
  target = aws_iot_certificate.simulator_cert.arn
}

# We create a secret object in AWS.
resource "aws_secretsmanager_secret" "iot_identities" {
  name = "ankaa/prod/iot_certs"
  description = "Stores the mTLS certificates for backend and simulator"
}

# We stuff the generated keys into that secret as a JSON blob.
# Your Rust app and Phoenix app will read this JSON at runtime.
resource "aws_secretsmanager_secret_version" "iot_identities_val" {
  secret_id = aws_secretsmanager_secret.iot_identities.id
  secret_string = jsonencode({
    # The Endpoint URL (needed to connect)
    endpoint = data.aws_iot_endpoint.current.endpoint_address
    
    # Phoenix Credentials
    backend_cert_pem = aws_iot_certificate.backend_cert.certificate_pem
    backend_private_key = aws_iot_certificate.backend_cert.private_key
    
    # Rust Simulator Credentials
    sim_cert_pem = aws_iot_certificate.simulator_cert.certificate_pem
    sim_private_key = aws_iot_certificate.simulator_cert.private_key
  })
}

# Get the IoT Endpoint URL dynamically
data "aws_iot_endpoint" "current" {
  endpoint_type = "iot:Data-ATS"
}