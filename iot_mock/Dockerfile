FROM rust:bookworm AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y musl-tools
RUN rustup target add x86_64-unknown-linux-musl
COPY . .
RUN cargo build --target x86_64-unknown-linux-musl --release

FROM alpine:latest
RUN apk add --no-cache ca-certificates
COPY --from=builder /app/target/x86_64-unknown-linux-musl/release/iot_mock /usr/local/bin/iot_mock
CMD ["iot_mock"]