#!/bin/bash


REGION="us-east-1"
ACCOUNT_ID="725149888536"
REGISTRY="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
TAG="latest"

# Default to false
BUILD_BEACON=false
BUILD_IOT=false

if [ $# -eq 0 ]; then
    BUILD_BEACON=true
    BUILD_IOT=true
else
    for arg in "$@"
    do
        case $arg in
            -beacon)
            BUILD_BEACON=true
            shift
            ;;
            -iot)
            BUILD_IOT=true
            shift
            ;;
            *)
            echo "Unknown argument: $arg"
            echo "Usage: ./build_images.sh [-beacon] [-iot]"
            exit 1
            ;;
        esac
    done
fi

echo "🐳 Logging into AWS ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $REGISTRY

if [ "$BUILD_BEACON" = true ]; then
    echo "🛠️  Building Ankaa Beacon (Backend)..."
    docker build -t $REGISTRY/ankaa-backend:$TAG -f ./ankaa_beacon/Dockerfile ./ankaa_beacon
    docker push $REGISTRY/ankaa-backend:$TAG
    echo "✅ Backend pushed."
fi

if [ "$BUILD_IOT" = true ]; then
    echo "🛠️  Building IoT Mock (Simulator)..."
    docker build -t $REGISTRY/ankaa-simulator:$TAG -f ./iot_mock/Dockerfile ./iot_mock
    docker push $REGISTRY/ankaa-simulator:$TAG
    echo "✅ Simulator pushed."
fi

echo "🎉 All requested builds complete!"