# Build stage
FROM rust:bookworm AS builder
WORKDIR /app
COPY . .
RUN cargo build --release

# Runtime stage
FROM debian:bookworm
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends libssl3 && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/iot_mock /usr/local/bin/
CMD ["iot_mock"]
