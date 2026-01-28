#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${WORKDIR:-/opt/n8n-python}"
N8N_VERSION="${N8N_VERSION:-2.4.6}"
N8N_IMAGE="${N8N_IMAGE:-n8n-python:latest}"
RUNNERS_IMAGE="n8nio/runners:${N8N_VERSION}"
TZ_VALUE="${TZ_VALUE:-Asia/Shanghai}"
NETWORK_NAME="${NETWORK_NAME:-n8n-net}"
VOLUME_NAME="${VOLUME_NAME:-n8n_data}"
N8N_CONTAINER_NAME="${N8N_CONTAINER_NAME:-n8n-main}"
RUNNERS_CONTAINER_NAME="${RUNNERS_CONTAINER_NAME:-n8n-runners}"
TOKEN_FILE="${TOKEN_FILE:-${WORKDIR}/.runners_auth_token}"

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

cat > Dockerfile <<'EOF'
FROM n8nio/n8n:latest

USER root

RUN set -eux; \
  . /etc/os-release; \
  ALPINE_VERSION_ID="$VERSION_ID"; \
  ARCH="$(uname -m)"; \
  case "$ARCH" in \
    x86_64) ALPINE_ARCH="x86_64" ;; \
    aarch64) ALPINE_ARCH="aarch64" ;; \
    armv7*) ALPINE_ARCH="armv7" ;; \
    *) echo "Unsupported arch: $ARCH" >&2; exit 1 ;; \
  esac; \
  REPO_BASE="https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION_ID}/main/${ALPINE_ARCH}"; \
  busybox wget -qO /tmp/APKINDEX.tar.gz "${REPO_BASE}/APKINDEX.tar.gz"; \
  tar -xzf /tmp/APKINDEX.tar.gz -C /tmp APKINDEX; \
  APK_TOOLS_VER="$(awk 'BEGIN{f=0} /^P:apk-tools-static$/{f=1} f && /^V:/{print substr($0,3); exit}' /tmp/APKINDEX)"; \
  test -n "$APK_TOOLS_VER"; \
  busybox wget -qO /tmp/apk-tools-static.apk "${REPO_BASE}/apk-tools-static-${APK_TOOLS_VER}.apk"; \
  tar -xzf /tmp/apk-tools-static.apk -C /tmp; \
  /tmp/sbin/apk.static -X "https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION_ID}/main" -U --allow-untrusted add apk-tools; \
  rm -rf /tmp/APKINDEX.tar.gz /tmp/APKINDEX /tmp/apk-tools-static.apk /tmp/sbin; \
  printf '%s\n' \
    "https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION_ID}/main" \
    "https://mirrors.aliyun.com/alpine/v${ALPINE_VERSION_ID}/community" \
    > /etc/apk/repositories; \
  apk add --no-cache python3 py3-pip; \
  python3 -m venv /opt/venv; \
  /opt/venv/bin/python -m pip install --no-cache-dir --upgrade pip setuptools wheel; \
  chown -R node:node /opt/venv

ENV PATH="/opt/venv/bin:${PATH}"

USER node
EOF

if [ -f "${TOKEN_FILE}" ]; then
  TOKEN="$(cat "${TOKEN_FILE}")"
else
  TOKEN="$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')$(cat /proc/sys/kernel/random/uuid | sed 's/-//g')"
  printf '%s' "${TOKEN}" > "${TOKEN_FILE}"
  chmod 600 "${TOKEN_FILE}" || true
fi

docker build --progress=plain -t "${N8N_IMAGE}" .
docker pull "${RUNNERS_IMAGE}"

docker volume create "${VOLUME_NAME}" >/dev/null 2>&1 || true
docker network create "${NETWORK_NAME}" >/dev/null 2>&1 || true

docker rm -f n8n >/dev/null 2>&1 || true
docker rm -f "${N8N_CONTAINER_NAME}" >/dev/null 2>&1 || true
docker rm -f "${RUNNERS_CONTAINER_NAME}" >/dev/null 2>&1 || true

docker run -d \
  --name "${N8N_CONTAINER_NAME}" \
  --network "${NETWORK_NAME}" \
  -p 5678:5678 \
  -e TZ="${TZ_VALUE}" \
  -e GENERIC_TIMEZONE="${TZ_VALUE}" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_SECURE_COOKIE=false \
  -e N8N_RUNNERS_ENABLED=true \
  -e N8N_RUNNERS_MODE=external \
  -e N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0 \
  -e N8N_RUNNERS_AUTH_TOKEN="${TOKEN}" \
  -e N8N_NATIVE_PYTHON_RUNNER=true \
  -v "${VOLUME_NAME}:/home/node/.n8n" \
  "${N8N_IMAGE}"

docker run -d \
  --name "${RUNNERS_CONTAINER_NAME}" \
  --network "${NETWORK_NAME}" \
  -e N8N_RUNNERS_TASK_BROKER_URI="http://${N8N_CONTAINER_NAME}:5679" \
  -e N8N_RUNNERS_AUTH_TOKEN="${TOKEN}" \
  "${RUNNERS_IMAGE}"

docker ps --filter name="${N8N_CONTAINER_NAME}" --filter name="${RUNNERS_CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
