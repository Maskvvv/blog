# n8n + Python 自定义镜像构建与容器启动（阿里云服务器）

适用场景：在已安装 Docker 的阿里云 Linux 服务器上，自行构建一个带 Python 环境的 n8n 镜像，并用该镜像启动 n8n 服务。

已验证环境（本次实际执行的服务器）：
- 服务器：39.105.207.111（root 用户）
- Docker：Docker Engine 27.3.1（linux/amd64）
- n8n 基础镜像：`n8nio/n8n:latest`

## 1. 背景说明（为什么需要“自举 apk”）

`n8nio/n8n:latest` 当前使用了更精简/加固的基础镜像：看起来是 Alpine，但在镜像构建阶段常见现象是包管理器 `apk` 不存在，导致类似命令失败：

```bash
apk add --no-cache python3 py3-pip
# /bin/sh: apk: not found
```

因此本方案会先从 Alpine 仓库下载 `apk-tools-static`，用 `apk.static` 把 `apk-tools` 安装回镜像，然后再通过 `apk` 安装 Python。

为提升国内网络稳定性，本方案使用阿里云 Alpine 镜像源：`https://mirrors.aliyun.com/alpine/`

## 2. 登录服务器并创建工作目录

```bash
ssh root@39.105.207.111

mkdir -p /opt/n8n-python
cd /opt/n8n-python
```

（可选）确认 Docker 可用：

```bash
docker version
```

## 3. 编写 Dockerfile（n8n + Python + venv）

在 `/opt/n8n-python` 下创建 `Dockerfile`：

```bash
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
```

说明：
- Python 安装后会创建虚拟环境 `/opt/venv`
- 通过 `ENV PATH="/opt/venv/bin:${PATH}"`，让 n8n 运行时 `python` / `pip` 默认指向虚拟环境

## 4. 构建镜像

```bash
docker build --progress=plain -t n8n-python:latest .
```

构建完成后可验证镜像中 Python 是否可用：

```bash
docker run --rm n8n-python:latest python --version
docker run --rm n8n-python:latest pip --version
```

## 5. 创建数据卷并启动 n8n 容器

创建数据卷（用于持久化 n8n 配置、密钥、SQLite 等）：

```bash
docker volume create n8n_data
```

停止并移除旧容器（如果存在）：

```bash
docker rm -f n8n 2>/dev/null || true
```

启动新容器（端口 5678，对外提供 n8n Web UI）：

```bash
docker run -d \
  --name n8n \
  -p 5678:5678 \
  -e TZ="Asia/Shanghai" \
  -e GENERIC_TIMEZONE="Asia/Shanghai" \
  -e N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS=true \
  -e N8N_RUNNERS_ENABLED=true \
  -v n8n_data:/home/node/.n8n \
  n8n-python:latest
```

查看容器状态：

```bash
docker ps --filter name=n8n --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
```

查看日志（确认启动正常）：

```bash
docker logs -n 100 n8n
```

## 6. 验证容器内 Python 可用

```bash
docker exec n8n python --version
docker exec n8n python -c "print('hello from python')"
```

## 7. 访问地址与安全组放行

浏览器访问：
- `http://39.105.207.111:5678`

若访问不到，请检查：
- 阿里云安全组是否放行 TCP 5678
- 服务器本地防火墙是否放行 5678

## 8. 常见问题排查

### 8.1 构建时卡住“很久不动”

常见原因是下载依赖较慢（APK 索引、pip 包下载）。本方案已将 Alpine 仓库切换为阿里云镜像源以提升稳定性。仍慢时可观察构建输出是否在下载/解压阶段。

### 8.2 Windows 终端推送脚本到 Linux 后报奇怪路径错误（例如 `path ".\r" not found`）

这通常是脚本带有 Windows 的 CRLF（`\r\n`）导致。将输入通过 `tr -d '\r'` 过滤再执行可解决：

```bash
... | tr -d '\r' | bash -s
```

### 8.3 需要预装 Python 第三方库

如果你希望镜像里自带库（例如 requests / pandas / numpy），建议在 Dockerfile 里增加一行：

```bash
/opt/venv/bin/pip install --no-cache-dir requests pandas
```

然后重新构建镜像并重启容器即可。

