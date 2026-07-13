# ECS 上 n8n / MySQL 资源占用排查与调整记录

日期：2026-07-13  
服务器：`<ecs-server>`

## 背景

这台 ECS 会间歇性出现 CPU 跑满，严重时 SSH 无法正常连接。服务器上主要运行一套 Docker 部署的 n8n，以及一个给 n8n 节点使用的 MySQL 测试库。

排查时看到的容器：

```text
n8n-main      n8n-python:latest
n8n-runners   n8n-runners-custom:2.4.6
mysql         mysql:8.0
redis         redis:5.0.10，历史遗留停止容器
zk            zookeeper:3.4.14，历史遗留停止容器
```

## 初始现象

- ECS 监控显示 CPU 曾长时间接近 100%。
- 问题时间段里，磁盘读取 BPS 和 IOPS 也偏高。
- 公网流量有短暂尖峰，但没有持续异常外发流量。
- 机器过载时，SSH 连接会失败，典型报错如下：

```text
Connection timed out during banner exchange
Connection to <ecs-server> port 22 timed out
```

这说明当时机器已经卡到 `sshd` 都无法稳定响应。

## 安全排查结论

本次排查没有发现明显的入侵证据：

- `root` 用户 crontab 为空。
- `/etc/cron.d` 里只有系统默认的 hourly 配置。
- 已启用的 systemd 服务里没有明显随机命名或可疑服务。
- 登录记录主要是看起来已知的来源 IP。
- 重启后没有观察到陌生的高 CPU 进程。

这不能 100% 证明服务器完全没有安全风险，但当前证据更指向资源耗尽，而不是中病毒。主要压力来自小规格 ECS 上同时运行 n8n 和 MySQL。

## n8n 排查结果

`n8n-main` 没有把这个 MySQL 容器作为 n8n 主数据库使用。环境变量里没有看到 `DB_TYPE=mysql` 或 `DB_MYSQLDB_*` 这类配置。

n8n 当前使用的是数据卷里的本地 SQLite：

```text
/home/node/.n8n/database.sqlite        约 97.9M
/home/node/.n8n/database.sqlite-wal    约 5.0M
```

看到的 n8n 相关环境变量包括：

```text
N8N_RUNNERS_ENABLED=true
N8N_RUNNERS_MODE=external
N8N_RUNNERS_BROKER_LISTEN_ADDRESS=0.0.0.0
N8N_NATIVE_PYTHON_RUNNER=true
EXECUTIONS_TIMEOUT=3600
EXECUTIONS_TIMEOUT_MAX=7200
GENERIC_TIMEZONE=Asia/Shanghai
TZ=Asia/Shanghai
```

n8n 日志里曾出现执行历史维护和数据库超时信息：

```text
Starting workflow history compaction
Workflow history compaction complete
Database connection timed out
Database connection recovered
```

这说明 n8n 的 SQLite 维护、工作流执行、执行历史压缩等操作，可能会带来短时间 CPU / IO 峰值。

## MySQL 排查结果

MySQL 会被 n8n workflow 里的节点使用，作为测试数据库存在；但它不是 n8n 自身的主数据库。

MySQL 容器信息：

```text
Image: mysql:8.0
Public port mapping: 0.0.0.0:<mysql-host-port>->3306/tcp
Docker network: bridge and n8n-net
Data volume: /var/lib/mysql via Docker volume
```

MySQL 中存在多个业务/测试数据库。具体库名已在本文档中省略。

示例结构：

```text
<application_db>
<test_db>
mysql
performance_schema
sys
```

MySQL 在没有足够内存余量时，会明显增加整机压力。曾尝试把 MySQL 容器限制到 `320MiB`，结果 MySQL 被 OOM kill：

```text
mysql status=exited exit=137 oom=true
```

因此确认 `320MiB` 对这个 MySQL 容器来说太小。

## 资源查看命令

查看整机内存和 swap：

```bash
free -h
swapon --show
```

查看系统负载：

```bash
uptime
```

查看 Docker 容器资源占用：

```bash
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.BlockIO}}'
```

查看容器状态、OOM 状态和资源限制：

```bash
docker inspect --format '{{.Name}} status={{.State.Status}} oom={{.State.OOMKilled}} exit={{.State.ExitCode}} memory={{.HostConfig.Memory}} cpus={{.HostConfig.NanoCpus}}' mysql
```

查看宿主机 CPU 占用最高的进程：

```bash
ps -eo pid,ppid,user,stat,pcpu,pmem,etime,comm,args --sort=-pcpu | head -20
```

查看 MySQL 是否能正常响应：

```bash
docker exec mysql mysql -uroot -p'<mysql-root-password>' -e 'SHOW FULL PROCESSLIST; SHOW DATABASES;'
```

## MySQL 资源限制调整

对 MySQL 容器设置了 Docker 资源限制：

```bash
docker update --cpus 0.5 --memory 512m --memory-swap 512m --pids-limit 120 mysql
```

最终生效的限制：

```text
memory=536870912
memorySwap=536870912
nanoCpus=500000000
pids=120
```

含义：

- 内存限制：`512MiB`
- CPU 限制：`0.5` 核
- 进程数限制：`120`
- 容器内存加 swap 总量仍限制在 `512MiB`

之前测试过 `320MiB`，不够用，会导致 MySQL OOM。调整到 `512MiB` 后，MySQL 可以正常启动并运行。

## ECS 添加 Swap

服务器原本没有 swap：

```text
Swap: 0B total
```

根分区空间足够：

```text
/dev/vda3  40G total, 15G used, 26G available
```

创建并启用 `2G` swap 文件：

```bash
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

写入 `/etc/fstab`，保证重启后自动启用：

```text
/swapfile none swap sw 0 0
```

最终 swap 状态：

```text
NAME      TYPE SIZE USED PRIO
/swapfile file   2G   0B   -2
```

### Swappiness 设置

为了让系统尽量优先使用内存，只在内存紧张时使用 swap，将 `vm.swappiness` 设置为 `10`：

```bash
sysctl vm.swappiness=10
```

原有配置里存在 `vm.swappiness = 0`，因此同步修改为 `10`：

```text
/etc/sysctl.conf:vm.swappiness = 10
/etc/sysctl.d/99-sysctl.conf:vm.swappiness = 10
/etc/sysctl.d/99-swap.conf:vm.swappiness = 10
```

最终确认值：

```text
vm.swappiness = 10
```

备注：执行过程中曾因 PowerShell 解析远端 `$(date ...)` 表达式，生成了一个文件名不太美观的 fstab 备份：

```text
/etc/fstab.bak.
```

这个文件不影响系统运行。

## 最终验证结果

添加 swap，并把 MySQL 限制为 `512MiB / 0.5 CPU` 后，三个容器可以同时运行：

```text
n8n-runners   Up
n8n-main      Up
mysql         Up
```

最终观察到的整机资源状态：

```text
Mem:  1.6Gi total, 1.0Gi used, 646Mi available
Swap: 2.0Gi total, about 524K used
Load: 0.02, 0.88, 1.24
```

最终容器资源占用：

```text
NAME          CPU %   MEM USAGE / LIMIT      BLOCK I/O
n8n-runners   0.00%   5.793MiB / 1.636GiB    11MB / 0B
n8n-main      0.04%   274.9MiB / 1.636GiB    426MB / 151MB
mysql         0.11%   441.5MiB / 512MiB      147MB / 16.3MB
```

MySQL 能正常响应：

```text
SHOW FULL PROCESSLIST;
SHOW DATABASES;
```

MySQL 日志显示正常启动：

```text
/usr/sbin/mysqld: ready for connections
```

启动 MySQL 后，检查 n8n 近期日志，没有发现新的异常报错。

## 当前结论

当前最可能的根因是资源耗尽，而不是已确认的中病毒：

- ECS 只有约 `1.6GiB` 内存。
- n8n 使用 SQLite，工作流执行和历史压缩可能产生 CPU / IO 峰值。
- MySQL 在 `512MiB` 限制下仍会占用约 `440MiB`。
- 添加 swap 之前，整机内存余量太少，容易导致机器无响应。
- 添加 `2G` swap 并限制 MySQL 资源后，n8n 和 MySQL 同时运行在短时间验证中保持稳定。

## 日常操作建议

现在 MySQL 可以和 n8n 同时运行，但机器规格仍然偏小。如果后续再次出现不稳定，可以只在需要测试库时启动 MySQL：

```bash
docker start mysql
docker stop mysql
```

如果希望长期稳定运行，建议把 ECS 升级到至少 `2C4G`。

## 安全建议

MySQL 曾观察到通过宿主机公网端口暴露。具体端口已在本文档中省略。

```text
0.0.0.0:<host-port>->3306/tcp
```

建议：

- 在阿里云安全组中限制 MySQL 宿主机端口，只允许可信来源 IP 访问。
- 如果 MySQL 只给本机 Docker workload 使用，尽量不要暴露到公网。
- 如果 MySQL root 密码曾经被共享或暴露，建议轮换密码。

## 暂缓的 n8n 历史清理

本次讨论过 n8n 执行历史清理，但最终按要求暂缓，没有实际调整 n8n。

后续如需开启 n8n execution pruning，可以考虑添加环境变量：

```text
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=168
EXECUTIONS_DATA_PRUNE_MAX_COUNT=5000
```

这些配置需要重建或更新 `n8n-main` 容器环境变量。本次最终没有执行该操作。
