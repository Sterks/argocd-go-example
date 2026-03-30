#!/bin/bash

set -e

# Harbor registry через NodePort (прямой доступ по HTTP)
NODE_IP="192.168.0.101"
NODE_PORT="30500"
REGISTRY="${NODE_IP}:${NODE_PORT}"

IMAGE_NAME="argocd-go-example"
TAG="${1:-latest}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building image for linux/amd64: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .
docker push "${FULL_IMAGE}"

echo "Done! Image pushed: ${FULL_IMAGE}"
