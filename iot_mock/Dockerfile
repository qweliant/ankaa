# 1. BUILD STAGE
FROM rust:bookworm AS builder
WORKDIR /app
COPY . .
# Build the release binary (Dynamic linking is fine here)
RUN cargo build --release

# 2. RUNTIME STAGE
FROM debian:bookworm-slim

# Install OpenSSL and CA Certificates
# - ca-certificates: Needed to verify EMQX's SSL certificate
# - libssl-dev: Needed because rumqttc (native-tls) links against this
RUN apt-get update && \
    apt-get install -y --no-install-recommends libssl-dev ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy the binary
COPY --from=builder /app/target/release/iot_mock /usr/local/bin/

# Run it
CMD ["iot_mock"]