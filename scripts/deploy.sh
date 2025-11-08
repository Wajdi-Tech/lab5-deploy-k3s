#!/usr/bin/env bash
set -euo pipefail

# === Configuration ===
DOCKERHUB_USER="wajditech"
IMAGE_NAME="lab5-webapp"
TAG="latest"
FULL_IMAGE="${DOCKERHUB_USER}/${IMAGE_NAME}:${TAG}"

# Path variables
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
K8S_DIR="${ROOT_DIR}/k8s"

echo "🚀 Building Docker image ${FULL_IMAGE}..."
cd "${APP_DIR}"

# Make sure package.json present
if [ ! -f package.json ]; then
  echo "❌ package.json not found in ${APP_DIR}"
  exit 1
fi

docker build -t "${FULL_IMAGE}" .

echo "✅ Docker build complete."

echo "🔐 Login to Docker Hub (you will be prompted if not already logged in):"
docker login

echo "📤 Pushing image to Docker Hub..."
docker push "${FULL_IMAGE}"

echo "✅ Image pushed successfully."

# Replace placeholder in k8s web-deployment if present (temporary)
TMP_DEPLOY="${K8S_DIR}/web-deployment.tmp.yaml"
sed "s|YOUR_DOCKERHUB_USERNAME/${IMAGE_NAME}:latest|${FULL_IMAGE}|g" "${K8S_DIR}/web-deployment.yaml" > "${TMP_DEPLOY}"

echo "📦 Applying Kubernetes manifests..."
kubectl apply -f "${K8S_DIR}/db-deployment.yaml"
kubectl apply -f "${K8S_DIR}/db-service.yaml"

# Wait for DB Pod to be ready
echo "⏳ Waiting for PostgreSQL pod to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres --timeout=120s || {
  echo "⚠️ Timeout waiting for db pod ready. Run: kubectl get pods -A"
}

# Apply web deployment & service
kubectl apply -f "${TMP_DEPLOY}"
kubectl apply -f "${K8S_DIR}/web-service.yaml"

echo "🧹 Cleanup temp files..."
rm -f "${TMP_DEPLOY}"

echo "✅ Deployment finished!"
echo "🌐 Access the web app at: http://<node-ip>:30080"
echo "   (Use the IP of your master or any worker node)"

