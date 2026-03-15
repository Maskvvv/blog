#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${WORKDIR:-/opt/n8n-python}"
N8N_VERSION="${N8N_VERSION:-2.4.6}"
N8N_IMAGE="${N8N_IMAGE:-n8n-python:latest}"
RUNNERS_BASE_IMAGE="n8nio/runners:${N8N_VERSION}"
RUNNERS_IMAGE="${RUNNERS_IMAGE:-${RUNNERS_BASE_IMAGE}}"
EXECUTIONS_TIMEOUT="${EXECUTIONS_TIMEOUT:-3600}"
EXECUTIONS_TIMEOUT_MAX="${EXECUTIONS_TIMEOUT_MAX:-7200}"
N8N_RUNNERS_TASK_TIMEOUT="${N8N_RUNNERS_TASK_TIMEOUT:-900}"
N8N_RUNNERS_TASK_REQUEST_TIMEOUT="${N8N_RUNNERS_TASK_REQUEST_TIMEOUT:-120}"
N8N_RUNNERS_MAX_CONCURRENCY="${N8N_RUNNERS_MAX_CONCURRENCY:-2}"
RUNNERS_PYTHON_PACKAGES="${RUNNERS_PYTHON_PACKAGES:-}"
RUNNERS_EXTERNAL_ALLOW="${RUNNERS_EXTERNAL_ALLOW:-}"
RUNNERS_STDLIB_ALLOW="${RUNNERS_STDLIB_ALLOW:-}"
RUNNERS_ALLOWED_ENV_EXTRA="${RUNNERS_ALLOWED_ENV_EXTRA:-OPENAI_API_KEY,HTTP_PROXY,HTTPS_PROXY,NO_PROXY}"
TZ_VALUE="${TZ_VALUE:-Asia/Shanghai}"
NETWORK_NAME="${NETWORK_NAME:-n8n-net}"
VOLUME_NAME="${VOLUME_NAME:-n8n_data}"
N8N_CONTAINER_NAME="${N8N_CONTAINER_NAME:-n8n-main}"
RUNNERS_CONTAINER_NAME="${RUNNERS_CONTAINER_NAME:-n8n-runners}"
TOKEN_FILE="${TOKEN_FILE:-${WORKDIR}/.runners_auth_token}"

mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

cat > Dockerfile <<'EOF'
ARG N8N_VERSION=2.4.6
FROM n8nio/n8n:${N8N_VERSION}

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

docker build --progress=plain --build-arg N8N_VERSION="${N8N_VERSION}" -t "${N8N_IMAGE}" .
docker pull "${RUNNERS_BASE_IMAGE}"

if [ -n "${RUNNERS_PYTHON_PACKAGES}" ] || [ -n "${RUNNERS_EXTERNAL_ALLOW}" ] || [ -n "${RUNNERS_STDLIB_ALLOW}" ]; then
  RUNNERS_IMAGE="n8n-runners-custom:${N8N_VERSION}"

  cat > Dockerfile.runners <<'EOF'
ARG RUNNERS_BASE_IMAGE=n8nio/runners:2.4.6
FROM ${RUNNERS_BASE_IMAGE}

USER root

ARG RUNNERS_PYTHON_PACKAGES
ARG RUNNERS_EXTERNAL_ALLOW
ARG RUNNERS_STDLIB_ALLOW
ARG RUNNERS_ALLOWED_ENV_EXTRA

RUN if [ -n "${RUNNERS_PYTHON_PACKAGES}" ]; then \
      /opt/runners/task-runner-python/.venv/bin/python -m ensurepip --upgrade; \
      /opt/runners/task-runner-python/.venv/bin/python -m pip install --no-cache-dir ${RUNNERS_PYTHON_PACKAGES}; \
    fi

RUN RUNNERS_EXTERNAL_ALLOW="${RUNNERS_EXTERNAL_ALLOW}" \
    RUNNERS_STDLIB_ALLOW="${RUNNERS_STDLIB_ALLOW}" \
    RUNNERS_ALLOWED_ENV_EXTRA="${RUNNERS_ALLOWED_ENV_EXTRA}" \
    /usr/local/bin/python - <<'PY'
import json
import os

path = "/etc/n8n-task-runners.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

external_allow = os.environ.get("RUNNERS_EXTERNAL_ALLOW", "")
stdlib_allow = os.environ.get("RUNNERS_STDLIB_ALLOW", "")
allowed_env_extra = [x.strip() for x in os.environ.get("RUNNERS_ALLOWED_ENV_EXTRA", "").split(",") if x.strip()]

for r in data.get("task-runners", []):
    if r.get("runner-type") != "python":
        continue

    if allowed_env_extra:
        allowed = list(r.get("allowed-env", []))
        for k in allowed_env_extra:
            if k not in allowed:
                allowed.append(k)
        r["allowed-env"] = allowed

    env = dict(r.get("env-overrides", {}))
    if stdlib_allow != "":
        env["N8N_RUNNERS_STDLIB_ALLOW"] = stdlib_allow
    if external_allow != "":
        env["N8N_RUNNERS_EXTERNAL_ALLOW"] = external_allow
    r["env-overrides"] = env

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, ensure_ascii=False, indent=2)
PY

USER runner
EOF

  docker build --progress=plain \
    --build-arg RUNNERS_BASE_IMAGE="${RUNNERS_BASE_IMAGE}" \
    --build-arg RUNNERS_PYTHON_PACKAGES="${RUNNERS_PYTHON_PACKAGES}" \
    --build-arg RUNNERS_EXTERNAL_ALLOW="${RUNNERS_EXTERNAL_ALLOW}" \
    --build-arg RUNNERS_STDLIB_ALLOW="${RUNNERS_STDLIB_ALLOW}" \
    --build-arg RUNNERS_ALLOWED_ENV_EXTRA="${RUNNERS_ALLOWED_ENV_EXTRA}" \
    -t "${RUNNERS_IMAGE}" \
    -f Dockerfile.runners .
fi

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
  -e EXECUTIONS_TIMEOUT="${EXECUTIONS_TIMEOUT}" \
  -e EXECUTIONS_TIMEOUT_MAX="${EXECUTIONS_TIMEOUT_MAX}" \
  -e N8N_RUNNERS_ENABLED=true \
  -e N8N_RUNNERS_MODE=external \
  -e N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0 \
  -e N8N_RUNNERS_AUTH_TOKEN="${TOKEN}" \
  -e N8N_RUNNERS_TASK_TIMEOUT="${N8N_RUNNERS_TASK_TIMEOUT}" \
  -e N8N_RUNNERS_TASK_REQUEST_TIMEOUT="${N8N_RUNNERS_TASK_REQUEST_TIMEOUT}" \
  -e N8N_NATIVE_PYTHON_RUNNER=true \
  -v "${VOLUME_NAME}:/home/node/.n8n" \
  "${N8N_IMAGE}"

docker run -d \
  --name "${RUNNERS_CONTAINER_NAME}" \
  --network "${NETWORK_NAME}" \
  -e N8N_RUNNERS_TASK_BROKER_URI="http://${N8N_CONTAINER_NAME}:5679" \
  -e N8N_RUNNERS_AUTH_TOKEN="${TOKEN}" \
  -e N8N_RUNNERS_TASK_TIMEOUT="${N8N_RUNNERS_TASK_TIMEOUT}" \
  -e N8N_RUNNERS_MAX_CONCURRENCY="${N8N_RUNNERS_MAX_CONCURRENCY}" \
  "${RUNNERS_IMAGE}"

docker ps --filter name="${N8N_CONTAINER_NAME}" --filter name="${RUNNERS_CONTAINER_NAME}" --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
