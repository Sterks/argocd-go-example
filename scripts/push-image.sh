#!/bin/bash

set -e

# Node1 IP для доступа к registry через NodePort
NODE_IP="192.168.0.101"
NODE_PORT="30500"
REGISTRY="${NODE_IP}:${NODE_PORT}"

IMAGE_NAME="argocd-go-example"
TAG="${1:-latest}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building image for linux/amd64: ${FULL_IMAGE}"
docker buildx build --platform linux/amd64 -t "${FULL_IMAGE}" --push .

echo "Done! Image pushed: ${FULL_IMAGE}"
