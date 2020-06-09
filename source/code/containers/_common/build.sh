#!/bin/bash
set -e

IMAGE_NAME=$1
IMAGE_TAG=$2

echo "Docker Login to ECR"
eval $(aws ecr get-login --no-include-email --region ${AWS_REGION})


# build the base image
docker build \
    --build-arg VERSION=$IMAGE_TAG \
    -t $IMAGE_NAME .

# build the image with an AWS specific entrypoint
docker build \
    --build-arg BASE_IMAGE=$IMAGE_NAME \
    -t $IMAGE_NAME:$IMAGE_TAG \
    -t $IMAGE_NAME:latest \
    -f _common/aws.dockerfile .
