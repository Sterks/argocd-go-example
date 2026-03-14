#!/bin/bash

set -e

# Node1 IP для доступа к registry через NodePort
NODE_IP="192.168.0.101"
NODE_PORT="30500"
REGISTRY="${NODE_IP}:${NODE_PORT}"

IMAGE_NAME="argocd-go-example"
TAG="${1:-latest}"
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "Building image: ${FULL_IMAGE}"
docker build -t "${FULL_IMAGE}" .

echo "Pushing image to registry: ${FULL_IMAGE}"
docker push "${FULL_IMAGE}"

echo "Done! Image pushed: ${FULL_IMAGE}"
