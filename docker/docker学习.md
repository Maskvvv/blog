---
title: Docker学习
date: 2020-10-02
updated: 2021-5-22
tags:
  - Linux
  - Docker
  - docker-compose
categories:
  - Docker
  - Docker学习
---

<img src="http://qiniu.zhouhongyin.top/2022/06/05/1654405895-Microsoft.VisualStudio.Services.Icons.png" style="zoom:33%;" />

<!-- more -->

## 一、Docker 的简介

### 1.1 什么是 Docker

**Docker** 最初是 `dotCloud` 公司创始人 [Solomon Hykes (opens new window)](https://github.com/shykes)在法国期间发起的一个公司内部项目，它是基于 `dotCloud` 公司多年云服务技术的一次革新，并于 [2013 年 3 月以 Apache 2.0 授权协议开源 (opens new window)](https://en.wikipedia.org/wiki/Docker_(software))，主要项目代码在 [GitHub (opens new window)](https://github.com/moby/moby)上进行维护。`Docker` 项目后来还加入了 Linux 基金会，并成立推动 [开放容器联盟（OCI） (opens new window)](https://opencontainers.org/)。

**Docker** 自开源后受到广泛的关注和讨论，至今其 [GitHub 项目 (opens new window)](https://github.com/moby/moby)已经超过 5 万 7 千个星标和一万多个 `fork`。甚至由于 `Docker` 项目的火爆，在 `2013` 年底，[dotCloud 公司决定改名为 Docker (opens new window)](https://www.docker.com/blog/dotcloud-is-becoming-docker-inc/)。`Docker` 最初是在 `Ubuntu 12.04` 上开发实现的；`Red Hat` 则从 `RHEL 6.5` 开始对 `Docker` 进行支持；`Google` 也在其 `PaaS` 产品中广泛应用 `Docker`。

**Docker** 使用 `Google` 公司推出的 [Go 语言 (opens new window)](https://golang.google.cn/)进行开发实现，基于 `Linux` 内核的 [cgroup (opens new window)](https://zh.wikipedia.org/wiki/Cgroups)，[namespace (opens new window)](https://en.wikipedia.org/wiki/Linux_namespaces)，以及 [OverlayFS (opens new window)](https://docs.docker.com/storage/storagedriver/overlayfs-driver/)类的 [Union FS (opens new window)](https://en.wikipedia.org/wiki/Union_mount)等技术，对进程进行封装隔离，属于 [操作系统层面的虚拟化技术 (opens new window)](https://en.wikipedia.org/wiki/Operating-system-level_virtualization)。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。最初实现是基于 [LXC (opens new window)](https://linuxcontainers.org/lxc/introduction/)，从 `0.7` 版本以后开始去除 `LXC`，转而使用自行开发的 [libcontainer (opens new window)](https://github.com/docker/libcontainer)，从 `1.11` 版本开始，则进一步演进为使用 [runC (opens new window)](https://github.com/opencontainers/runc)和 [containerd (opens new window)](https://github.com/containerd/containerd)。

![Docker 架构](http://qiniu.zhouhongyin.top/2022/06/05/1654405900-docker-on-linux.png)

> `runc` 是一个 Linux 命令行工具，用于根据 [OCI容器运行时规范 (opens new window)](https://github.com/opencontainers/runtime-spec)创建和运行容器。

> `containerd` 是一个守护程序，它管理容器生命周期，提供了在一个节点上执行容器和管理镜像的最小功能集。

**Docker** 在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大的简化了容器的创建和维护。使得 `Docker` 技术比虚拟机技术更为轻便、快捷。

### 1.2 容器和传统虚拟机的比较

下面的图片比较了 **Docker** 和传统虚拟化方式的不同之处。传统虚拟机技术是虚拟出一套硬件后，在其上运行一个完整操作系统，在该系统上再运行所需应用进程；而容器内的应用进程直接运行于宿主的内核，容器内没有自己的内核，而且也没有进行硬件虚拟。因此容器要比传统虚拟机更为轻便。

**容器的特点：**

- 资源利用率更高：一台物理机可以运行数百个容器，但是一般只能运行数十个虚拟机
- 开销更小：不需要启动单独的虚拟机OS内核占用硬件资源
- 启动速度更快：可以在数秒内完成启动
- 集成性更好：和CI/CD（持续集成/持续部署）相关技术结合性更好，实现自动化管理

![Virtual Machines](http://qiniu.zhouhongyin.top/2022/06/05/1654405904-virtualization.bfc621ce.png)

![Docker](http://qiniu.zhouhongyin.top/2022/06/05/1654405909-docker.20496661.png)

### 1.3 为什么要使用 Docker

#### 更高效的利用系统资源

由于容器不需要进行硬件虚拟以及运行完整操作系统等额外开销，`Docker` 对系统资源的利用率更高。无论是应用执行速度、内存损耗或者文件存储速度，都要比传统虚拟机技术更高效。因此，相比虚拟机技术，一个相同配置的主机，往往可以运行更多数量的应用。

#### 更快速的启动时间

传统的虚拟机技术启动应用服务往往需要数分钟，而 `Docker` 容器应用，由于直接运行于宿主内核，无需启动完整的操作系统，因此可以做到秒级、甚至毫秒级的启动时间。大大的节约了开发、测试、部署的时间。

#### 一致的运行环境

开发过程中一个常见的问题是环境一致性问题。由于开发环境、测试环境、生产环境不一致，导致有些 bug 并未在开发过程中被发现。而 `Docker` 的镜像提供了除内核外完整的运行时环境，确保了应用运行环境一致性，从而不会再出现 *「这段代码在我机器上没问题啊」* 这类问题。

#### 持续交付和部署

对开发和运维（[DevOps (opens new window)](https://zh.wikipedia.org/wiki/DevOps)）人员来说，最希望的就是一次创建或配置，可以在任意地方正常运行。

使用 `Docker` 可以通过定制应用镜像来实现持续集成、持续交付、部署。开发人员可以通过 [Dockerfile](https://vuepress.mirror.docker-practice.com/image/dockerfile/) 来进行镜像构建，并结合 [持续集成(Continuous Integration) (opens new window)](https://en.wikipedia.org/wiki/Continuous_integration)系统进行集成测试，而运维人员则可以直接在生产环境中快速部署该镜像，甚至结合 [持续部署(Continuous Delivery/Deployment) (opens new window)](https://en.wikipedia.org/wiki/Continuous_delivery)系统进行自动部署。

而且使用 [`Dockerfile`](https://vuepress.mirror.docker-practice.com/image/build.html) 使镜像构建透明化，不仅仅开发团队可以理解应用运行环境，也方便运维团队理解应用运行所需条件，帮助更好的生产环境中部署该镜像。

#### 更轻松的迁移

由于 `Docker` 确保了执行环境的一致性，使得应用的迁移更加容易。`Docker` 可以在很多平台上运行，无论是物理机、虚拟机、公有云、私有云，甚至是笔记本，其运行结果是一致的。因此用户可以很轻易的将在一个平台上运行的应用，迁移到另一个平台上，而不用担心运行环境的变化导致应用无法正常运行的情况。

#### 更轻松的维护和扩展

`Docker` 使用的分层存储以及镜像的技术，使得应用重复部分的复用更为容易，也使得应用的维护更新更加简单，基于基础镜像进一步扩展镜像也变得非常简单。此外，`Docker` 团队同各个开源项目团队一起维护了一大批高质量的 [官方镜像 (opens new window)](https://hub.docker.com/search/?type=image&image_filter=official)，既可以直接在生产环境使用，又可以作为基础进一步定制，大大的降低了应用服务的镜像制作成本。

#### 对比传统虚拟机总结

| 特性       | 容器               | 虚拟机      |
| :--------- | :----------------- | :---------- |
| 启动       | 秒级               | 分钟级      |
| 硬盘使用   | 一般为 `MB`        | 一般为 `GB` |
| 性能       | 接近原生           | 弱于        |
| 系统支持量 | 单机支持上千个容器 | 一般几十个  |

### 1.4 Docker 的组成

- Docker 主机(Host)：一个物理机或虚拟机，用于运行Docker服务进程和容器，也称为宿主机，node节点
- Docker 服务端(Server)：Docker守护进程，运行docker容器
- Docker 客户端(Client)：客户端使用docker 命令或其他工具调用docker API
- Docker 仓库(Registry): 保存镜像的仓库，官方仓库: https://hub.docker.com/
- Docker 镜像(Images)：镜像可以理解为创建实例使用的模板
- Docker 容器(Container): 容器是从镜像生成对外提供服务的一个或一组服务

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405915-engine-components-flow.png)

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405933-image-20200122144408057.png)



![Docker architecture](http://qiniu.zhouhongyin.top/2022/06/05/1654405920-image-20210522195714010.png)



## 二、Docker 的安装（Linux）

```shell
1. 使用官方安装脚本自动安装
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
2. 启动 docker 服务
systemctl start docker
3. 检查 docker 运行状态
systemctl start docker
4. 设置 docker 开机自启动
systemctl enable docker
5. 创建 docker 组
sudo groupadd docker
6. 使用 root 用户
sudo usermod -aG docker $USER
7. 重启 docker 服务
systemctl restart docker
8. 设置 阿里云 镜像
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://xxxx.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 三、Docker 镜像

### 3.1 什么是镜像

我们都知道，操作系统分为 **内核** 和 **用户空间**。对于 `Linux` 而言，内核启动后，会挂载 `root` 文件系统为其提供用户空间支持。而 **Docker 镜像**（`Image`），就相当于是一个 `root` 文件系统。比如官方镜像 `ubuntu:18.04` 就包含了完整的一套 Ubuntu 18.04 最小系统的 `root` 文件系统。

**Docker 镜像** 是一个特殊的文件系统，除了提供容器运行时所需的程序、库、资源、配置等文件外，还包含了一些为运行时准备的一些配置参数（如匿名卷、环境变量、用户等）。镜像 **不包含** 任何动态数据，其内容在构建之后也不会被改变。

> **分层存储：**
>
> 因为镜像包含操作系统完整的 `root` 文件系统，其体积往往是庞大的，因此在 Docker 设计时，就充分利用 [Union FS (opens new window)](https://en.wikipedia.org/wiki/Union_mount)的技术，将其设计为分层存储的架构。所以严格来说，镜像并非是像一个 `ISO` 那样的打包文件，镜像只是一个虚拟的概念，其实际体现并非由一个文件组成，而是由一组文件系统组成，或者说，由多层文件系统联合组成。
>
> 镜像构建时，会一层层构建，前一层是后一层的基础。每一层构建完就不会再发生改变，后一层上的任何改变只发生在自己这一层。比如，删除前一层文件的操作，实际不是真的删除前一层的文件，而是仅在当前层标记为该文件已删除。在最终容器运行的时候，虽然不会看到这个文件，但是实际上该文件会一直跟随镜像。因此，在构建镜像的时候，需要额外小心，每一层尽量只包含该层需要添加的东西，任何额外的东西应该在该层构建结束前清理掉。
>
> 分层存储的特征还使得镜像的复用、定制变的更为容易。甚至可以用之前构建好的镜像作为基础层，然后进一步添加新的层，以定制自己所需的内容，构建新的镜像。

### 3.2 镜像的基本操作

#### pull

```shell
# 1.拉取镜像到本地
docker pull 镜像名称[:tag]
```

#### images


```shell
# 2.查看本地镜像
docker images
docker images 镜像名称
# 只显示镜像 id
docker images -q
```

#### rmi

```shell
# 3.删除本地镜像
docker rmi 镜像的标识
docker rmi -f 镜像的标识
# 删除所有镜像
docker rmi -f $(docker images -qa)
```

#### save & load

```sh
# 4.镜像的导入导出
docker save -o 导出的路径(建议: 镜像名-tag.tar) 镜像id
# 加载本地的镜像文件
docker load -i 镜像文件
# 修改镜像名称
docker tag 镜像id 新景象的名称:版本
#启动Docker，输入systemctl start docker命令
```

## 四、Docker 容器

### 4.1 什么使 Docker 容器

镜像（`Image`）和容器（`Container`）的关系，就像是面向对象程序设计中的 `类` 和 `实例` 一样，镜像是静态的定义，容器是镜像运行时的实体。容器可以被创建、启动、停止、删除、暂停等。

容器的实质是进程，但与直接在宿主执行的进程不同，容器进程运行于属于自己的独立的 [命名空间 (opens new window)](https://en.wikipedia.org/wiki/Linux_namespaces)。因此容器可以拥有自己的 `root` 文件系统、自己的网络配置、自己的进程空间，甚至自己的用户 ID 空间。容器内的进程是运行在一个隔离的环境里，使用起来，就好像是在一个独立于宿主的系统下操作一样。这种特性使得容器封装的应用比直接在宿主运行更加安全。也因为这种隔离的特性，很多人初学 Docker 时常常会混淆容器和虚拟机。

前面讲过镜像使用的是分层存储，容器也是如此。每一个容器运行时，是以镜像为基础层，在其上创建一个当前容器的存储层，我们可以称这个为容器运行时读写而准备的存储层为 **容器存储层**。

容器存储层的生存周期和容器一样，容器消亡时，容器存储层也随之消亡。因此，任何保存于容器存储层的信息都会随容器删除而丢失。

按照 Docker 最佳实践的要求，容器不应该向其存储层内写入任何数据，容器存储层要保持无状态化。所有的文件写入操作，都应该使用 [数据卷（Volume）](https://vuepress.mirror.docker-practice.com/data_management/volume.html)、或者 [绑定宿主目录](https://vuepress.mirror.docker-practice.com/data_management/bind-mounts.html)，在这些位置的读写会跳过容器存储层，直接对宿主（或网络存储）发生读写，其性能和稳定性更高。

数据卷的生存周期独立于容器，容器消亡，数据卷不会消亡。因此，使用数据卷后，容器删除或者重新运行之后，数据却不会丢失。

### 4.2 容器的基本操作(容器就是运行起来的镜像)

#### run

```sh
# 1.运行容器
# 简单操作
docker run 容器的标识|容器名称[:tag]
# 常用的参数（常用）
docker run -d|-it -p 宿主机端口:容器端口 --name 容器名称 容器标识|容器名称[:tag] /bin/bash
- # -d： 代表后台运行容器
- # -p 宿主机端口:容器端口：为了映射当前Linux的端口和容器的端口
- # --name 容器的名称：指定容器的名称
- # -i： 交互式操作。
- # -t： 终端
- # /bin/bash：放在镜像名后的是命令，这里我们希望有个交互式 Shell，因此用的是 /bin/bash。要退出终端，直接输入 exit
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405942-image-20200926084808755.png)

#### ps

```sh
# 2.  查看正在运行的容器
docker ps [-qa]
- # -a：查看全部容器，包括没有运行的
- # -q：只查看容器的标识符
```

#### logs

```sh
# 3. 查看容器的日志
docker logs -f 容器id
- # -f 可以滚动查看日志的最后几行
- # -t 加入书简戳
- # --tail n 显示最后剩余 n 行
```

#### exec

```sh
# 4. 进入到容器内部(execute)
docker exec -it 容器id /bin/bash
# 退出容器
exit
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405946-image-20200926091200335.png)

#### stop & rm

```sh
# 5. 删除容器(删除容器前需要先停止容器)
docker stop 容器id
docker stop $(docker ps -qa)
docker rm 容器id
docker rm -f 容器id
docker rm $(docker ps -qa)
```

#### satrt

```sh
# 6. 启动存在的容器
docker start 容器id
```

#### top

```shell
# 7. 查看容器内运行列那些进程
docker top 容器id
```

#### cp

```shell
# 8. 容器与宿主机之间拷贝文件
# 宿主机 ------> 容器
docker cp 文件|目录 容器id:容器路径
# 容器 ------> 宿主机
docker cp 容器id:容器内资源路径 宿主机目录路径
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405951-image-20210519154550340.png)

#### inspect

```shell
# 9. 查看容器内部细节
docker inspect 容器id
```

#### volume

```shell
# 10. 数据卷 Volume
docker run -d -v 宿主机目录:容器目录:ro
# :ro 表示容器只能进行读操作不能写

# 自动数据卷,当填写的宿主机路径不存在时，会在 /var/lib/docker/volumes/数据卷名称/_data 下创建这个路径，并且将容器中映射路径下的文件拷贝到该路径下
docker run -d -v 宿主机中一个不存在的目录:容器目录

# 查看数据卷
docker volume ls

# 查看每个数据卷的细节
docker volume inspect 卷名

# 创建一个数据卷
docker volume create 卷名

# 删除未被使用的数据卷
docker volume prune

# 删除指定的数据卷
docker volume rm 卷名
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405955-image-20210519161236819.png)

#### commit

```shell
# 将容器打包成镜像
docker commit -m "镜像描述" -a "作者" 容器id 打包成的镜像名称:tags
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405960-image-20210521084436162.png)

## 五、Docker Registry

镜像构建完成后，可以很容易的在当前宿主机上运行，但是，如果需要在其它服务器上使用这个镜像，我们就需要一个集中的存储、分发镜像的服务，[Docker Registry](https://vuepress.mirror.docker-practice.com/repository/registry.html) 就是这样的服务。

一个 **Docker Registry** 中可以包含多个 **仓库**（`Repository`）；每个仓库可以包含多个 **标签**（`Tag`）；每个标签对应一个镜像。

通常，一个仓库会包含同一个软件不同版本的镜像，而标签就常用于对应该软件的各个版本。我们可以通过 `<仓库名>:<标签>` 的格式来指定具体是这个软件哪个版本的镜像。如果不给出标签，将以 `latest` 作为默认标签。

以 [Ubuntu 镜像 (opens new window)](https://hub.docker.com/_/ubuntu)为例，`ubuntu` 是仓库的名字，其内包含有不同的版本标签，如，`16.04`, `18.04`。我们可以通过 `ubuntu:16.04`，或者 `ubuntu:18.04` 来具体指定所需哪个版本的镜像。如果忽略了标签，比如 `ubuntu`，那将视为 `ubuntu:latest`。

仓库名经常以 *两段式路径* 形式出现，比如 `jwilder/nginx-proxy`，前者往往意味着 Docker Registry 多用户环境下的用户名，后者则往往是对应的软件名。但这并非绝对，取决于所使用的具体 Docker Registry 的软件或服务。

### 5.1 Docker Registry 公开服务

Docker Registry 公开服务是开放给用户使用、允许用户管理镜像的 Registry 服务。一般这类公开服务允许用户免费上传、下载公开的镜像，并可能提供收费服务供用户管理私有镜像。

最常使用的 Registry 公开服务是官方的 [Docker Hub (opens new window)](https://hub.docker.com/)，这也是默认的 Registry，并拥有大量的高质量的 [官方镜像 (opens new window)](https://hub.docker.com/search?q=&type=image&image_filter=official)。除此以外，还有 Red Hat 的 [Quay.io (opens new window)](https://quay.io/repository/)；Google 的 [Google Container Registry (opens new window)](https://cloud.google.com/container-registry/)，[Kubernetes (opens new window)](https://kubernetes.io/)的镜像使用的就是这个服务；代码托管平台 [GitHub (opens new window)](https://github.com/)推出的 [ghcr.io (opens new window)](https://docs.github.com/cn/packages/guides/about-github-container-registry)。

由于某些原因，在国内访问这些服务可能会比较慢。国内的一些云服务商提供了针对 Docker Hub 的镜像服务（`Registry Mirror`），这些镜像服务被称为 **加速器**。常见的有 [阿里云加速器 (opens new window)](https://www.aliyun.com/product/acr?source=5176.11533457&userCode=8lx5zmtu)、[DaoCloud 加速器 (opens new window)](https://www.daocloud.io/mirror#accelerator-doc)等。使用加速器会直接从国内的地址下载 Docker Hub 的镜像，比直接从 Docker Hub 下载速度会提高很多。在 [安装 Docker](https://vuepress.mirror.docker-practice.com/install/mirror.html) 一节中有详细的配置方法。

国内也有一些云服务商提供类似于 Docker Hub 的公开服务。比如 [网易云镜像服务 (opens new window)](https://c.163.com/hub#/m/library/)、[DaoCloud 镜像市场 (opens new window)](https://hub.daocloud.io/)、[阿里云镜像库 (opens new window)](https://www.aliyun.com/product/acr?source=5176.11533457&userCode=8lx5zmtu)等。

### 5.2 私有 Docker Registry

除了使用公开服务外，用户还可以在本地搭建私有 Docker Registry。Docker 官方提供了 [Docker Registry (opens new window)](https://hub.docker.com/_/registry/)镜像，可以直接使用做为私有 Registry 服务。在 [私有仓库](https://vuepress.mirror.docker-practice.com/repository/registry.html) 一节中，会有进一步的搭建私有 Registry 服务的讲解。

开源的 Docker Registry 镜像只提供了 [Docker Registry API (opens new window)](https://docs.docker.com/registry/spec/api/)的服务端实现，足以支持 `docker` 命令，不影响使用。但不包含图形界面，以及镜像维护、用户管理、访问控制等高级功能。

除了官方的 Docker Registry 外，还有第三方软件实现了 Docker Registry API，甚至提供了用户界面以及一些高级功能。比如，[Harbor (opens new window)](https://github.com/goharbor/harbor)和 [Sonatype Nexus](https://vuepress.mirror.docker-practice.com/repository/nexus3_registry.html)。

## 六、Docker 的网桥

在运行 docker 时，docker 会为我们创建一个名为 docker0 的网桥，当运行容器时容器会默认使用该网桥，docker 也会为其分配 子网 ip，但当我们运行多个容器时，都注册在统一网桥上，容器之间可能会出现相互影响，为了解决这一问题，我们可以自己创建一个网桥。

```shell
# 1. 查看所有网桥
docker network ls
```

```shell
# 2. 创建一个网桥
docker network create 网桥名称
```

```shell
# 3. 指定容器使用那个网桥（容器名会与分配的ip做映射：http://172.0.2.2:8080 ----> http://容器名:8080）
docker -d --net 网桥名称 --name 容器名 镜像id
```

```shell
# 4. 删除网桥
docker network rm 网桥名称
```

```shell
# 5. 查看网桥详细信息
docker network inspect 网桥名称
```

## 七、 Docker的应用

### 7.1 关闭本机的tomcat和mysql

```sh
# 关闭本机的tomcat和mysql
systemctl stop mysqld	# 停止mysql
systemctl disable mysqld	# 停止开机自启
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405965-image-20200926094820156.png)

### 7.2 部署 mysql

```sh
# 运行MySQL容器
docker run -d -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root daocloud.io/library/mysql:5.7.4
- # -e 指定环境变量
- # -e MYSQL_ROOT_PASSWORD=：指定密码

# 指定数据卷启动(防止数据丢失)
docker run -d -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root -v mysqldata:/var/lib/mysql mysql:5.5.62
# 容器数据默认保存在 /var/lib/mysql 

# 指定指定配置文件
docker run -d -p 3306:3306 --name mysql -e MYSQL_ROOT_PASSWORD=root -v mysqldata:/var/lib/mysql  -v mysqlconf:/etc/mysql mysql:5.5.62
# 容器配置文件默认保存在 /etc/mysql
```

### 7.3 部署 tomcat

```sh
docker run -d -p 8080:8080 --name tomcat -v webapps:/usr/local/tomcat/webapps -v tomcatconf:/usr/local/tomcat/conf tomcat:8.0-jre8
# /usr/local/tomcat/webapps /usr/local/tomcat/conf 分别为容器内 webapps 和 配置文件目录。
```

### 7.4 部署 redis

```shell
docker run -d -p 6379:6379 --name redis redis:5.0.10
```

```shell
# 开启redis 持久化
docker run -d -p 6379:6379 -v redisdata:/data --name redis redis:5.0.10 redis-server --appendonly yes
# 通过 redis-server --appendonly yes 开启持久化，并映射容器内的 /data 路径
```

```shell
# 以配置文件的方式启动
docker run -d -v /root/redisconf:/usr/local/etc/redis -p 6379:6379 --name myredis redis:5.0.10 redis-server /usr/local/etc/redis/redis.conf
# 通过 redis-server /usr/local/etc/redis/redis.conf 命令在容器启动时加载 redis.conf 配置文件
```

### 7.5 部署 ElasticSearch

```shell
docker run -d --name elasticsearch --net elastic_search -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:6.8.0
# 由于 ES 默认以集群的方式启动，所以可以通过 -e "discovery.type=single-node" 命令设置为单节点启动
#建议通过　--net elastic_search　指定网桥
```

> 启动可能会遇到的问题：**max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]**
>
> ![](http://qiniu.zhouhongyin.top/2022/06/05/1654405969-image-20210520201355349.png)
>
> **解决方案:**
>
> 1. 在 centos 虚拟机中，修改 **sysctl.conf**：`vim /etc/sysctl.conf`
> 2. 加入如下配置：`vm.max_map_count=262144`
> 3. 启用配置：`sysctl -p`

```shell
# ES 持久化
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -p 9200:9200 -p 9300:9300 elasticsearch:6.8.0
```

```shell
# ES 挂载配置文件
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -p 9200:9200 -p 9300:9300 elasticsearch:6.8.0
```

```shell
# ES 挂载插件目录
docker run -d --name elasticsearch -v esdata:/usr/share/elasticsearch/data -v esconfig:/usr/share/elasticsearch/config -v esplugins:/usr/share/elasticsearch/plugins -p 9200:9200 -p 9300:9300 elasticsearch:6.8.0
```

### 7.6 安装 kibana

```shell
docker run -d --name kibana --net elastic_search -p 5601:5601 kibana:6.8.0
```

```shell
# 指定 ES 端口启动
docker run -d --name kibana --net elastic_search -e "ELASTICSEARCH_HOSTS=http://elasticseach:9200" -p 5601:5601 kibana:6.8.0
```

```shell
# 加载配置文件启动
docker run -d --name kibana --net elastic_search -v kibanaconf:/usr/share/kibana/config -p 5601:5601 kibana:6.8.0
# 启动后修改 kibana.yml 即可
```

## 八、Dockerfile 自定义镜像

### 8.1 Dockerfile 简介

Dockerfile 由一行行命令语句组成，并且支持以 `#` 开头的注释行。

Dockerfile 存在的目录为上下文目录，会将所在的目录的文件全部打包。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405975-image-20210521094831001.png)

### 8.2 Dockerfile 指令

一般的，Dockerfile 分为四部分：基础镜像信息、维护者信息、镜像操作指令和容器启动时执行指令。

| 指令             | 作用                                                         |
| ---------------- | ------------------------------------------------------------ |
| FROM             | 当前镜像是基于那个镜像（**第一条指令必须是FROM**）           |
| MAINTAINER(弃用) | 维护者的姓名的邮箱地址                                       |
| RUN              | 构建镜像是需要运行的指令（在镜像系统中执行）                 |
| EXPOSE           | 当前容器对外暴露的端口                                       |
| WORDIR           | 指定在创建容器吼，终端默认登录进来的共做目录，一个落脚点     |
| ENV              | 在构建镜像的过程中设置环境变量                               |
| ADD              | 将宿主机目录下的文件拷贝进镜像且 ADD 命令会自动处理 URL 和解压 tar 包 |
| COPY             | 类似于 ADD ，拷贝文件和目录到镜像中<br />将从构建上下文目录中<源路径>的文件/目录复制到新的一层的镜像内<目标路径>位置 |
| VOLUME           | 创建一个可以从本地主机或其他容器挂载的挂载点，一般用来存放数据库和需要保持的数据等。 |
| CMD              | 指定一个容器启动时要运行的命令<br />Dockerfile 中可以有多个 CMD 指令，但只有最后一个生效，CMD 会被 `docker run`之后的参数替换 |
| ENTRYPOINT       | 指定一个容器启动时要运行的命令<br />ENTRYPOINT 的目的和 CMD 一样，都是在指定容器启动程序及其参数 |

#### FROM

格式为 `FROM <image>`|`FROM <image>:<tag>`。

**第一条指令必须为 `FROM` 指令**。并且，如果在同一个 Dockerfile 中创建多个镜像时，可以使用多个 `FROM` 指令（每个镜像一次）。

```dockerfile
FROM centos:7
```

#### RUN

格式为 `RUN <command> ` 或 `RUN ["executable", "param1", "param2"]`。

每条 `RUN` 指令将在当前镜像基础上执行指定命令，并提交为新的镜像。当命令较长时可以使用 `\` 来换行。

```
FROM centos:7
RUN yum install -y vim
RUN ["yum","install","-y","vim"]
```

> `RUN yum install -y vim` 等价于`RUN ["yum","install","-y","vim"]`
>
> **注意**：Dockerfile 的指令每执行一次都会在 docker 上新建一层。所以过多无意义的层，会造成镜像膨胀过大
>
> ```dockerfile
> FROM centos
> RUN yum install wget
> RUN wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz"
> RUN tar -xvf redis.tar.gz
> # 以上执行会创建 3 层镜像。可简化为以下格式：
> FROM centos
> RUN yum install wget \
>     && wget -O redis.tar.gz "http://download.redis.io/releases/redis-5.0.3.tar.gz" \
>     && tar -xvf redis.tar.gz
> ```
>

#### CMD

格式为：

```dockerfile
CMD <shell 命令> 
CMD ["<可执行文件或命令>","<param1>","<param2>",...] 
CMD ["<param1>","<param2>",...]  # 该写法是为 ENTRYPOINT 指令指定的程序提供默认参数
```

> 推荐使用第二种格式，执行过程比较明确。第一种格式实际上在运行的过程中也会自动转换成第二种格式运行，并且默认可执行文件是 sh。

CMD 类似于 RUN 指令，用于运行程序，但二者运行的时间点不同:

- CMD 在docker run 时运行。
- RUN 是在 docker build。

> **作用**：为启动的容器指定默认要运行的程序，程序运行结束，容器也就结束。CMD 指令指定的程序可被 docker run 命令行参数中指定要运行的程序所覆盖。
>
> **注意**：如果 Dockerfile 中如果存在多个 CMD 指令，仅最后一个生效。

#### ENTRYPOINT

格式为：`ENTRYPOINT ["<executeable>","<param1>","<param2>",...]`

类似于 CMD 指令，但其**不会被 docker run 的命令行参数指定的指令所覆盖**，而且这些命令行参数会被当作参数送给 ENTRYPOINT 指令指定的程序。

但是, 如果运行 docker run 时使用了 --entrypoint 选项，将覆盖 CMD 指令指定的程序。

**优点**：在执行 docker run 的时候可以指定 ENTRYPOINT 运行所需的参数。

**注意**：如果 Dockerfile 中如果存在多个 ENTRYPOINT 指令，仅最后一个生效。

**示例：**

```dockerfile
# Dockerfile
FROM centos:7
ENTRYPOINT ["ls"] # 定参
CMD ["/data"] # 变参 
```

- 不传参运行

```shell
docker run mycentos:1.0
# 容器内执行
ls /data
```

- 传参运行

```dockerfile
docker run centos:7 /data/aa
# 容器内执行
ls /data/aa
```



#### EXPOSE

格式为 `EXPOSE <port> [<port>...]`。

告诉 Docker 服务端容器暴露的端口号，供互联系统使用。在启动容器时需要通过 -P ，Docker 主机会自动分配一个端口转发到指定的端口，或通过 -p 自己指定。(如果不指定的化后面将无法通过 -p 映射端口)

```dockerfile
FROM centos:7
RUN yum install -y vim
RUN ["yum","install","-y","vim"]
EXPOSE 5672
EXPOSE 15672
```

#### COPY

格式为 `COPY <src> <dest>`。

复制本地主机的 `<src>`（为 Dockerfile 所在目录的相对路径）到容器中的 `<dest>`。

当使用本地目录为源目录时，推荐使用 `COPY`。

> **<目标路径>**：容器内的指定路径，该路径不用事先建好，路径不存在的话，会自动创建。

```dockerfile
FROM centos:7
RUN yum install -y vim
RUN ["yum","install","-y","vim"]
EXPOSE 5672
EXPOSE 15672
WORKDIR /data
WORKDIR bb
COPY aa.txt /data/bb/aa.txt
```

#### ADD 

格式为 `ADD <src> <dest>`。

该命令将复制指定的 `<src>` 到容器中的 `<dest>`。 其中 `<src>` 可以是Dockerfile所在目录的一个相对路径；也可以是一个 URL；还可以是一个 tar 文件（自动解压为目录）。

> ADD 指令和 COPY 的使用格式一致（**同样需求下，官方推荐使用 COPY**）。功能也类似，不同之处如下：
>
> - ADD 的优点：在执行 <源文件> 为 tar 压缩文件的话，压缩格式为 gzip, bzip2 以及 xz 的情况下，会自动复制并解压到 <目标路径>。
> - ADD 的缺点：在不解压的前提下，无法复制 tar 压缩文件。会令镜像构建缓存失效，从而可能会令镜像构建变得比较缓慢。具体是否使用，可以根据是否需要自动解压来决定。

```dockerfile
FROM centos:7
RUN yum install -y vim
RUN ["yum","install","-y","vim"]
EXPOSE 5672
EXPOSE 15672
WORKDIR /data
WORKDIR bb
ADD bb.txt /data/bb/bb.txt
ADD https://apache.claz.org/tomcat/tomcat-8/v8.5.66/bin/apache-tomcat-8.5.66.tar.gz /data/bb
ADD apache-tomcat-8.5.66.tar.gz /data/bb
```

#### WORKDIR

格式为 `WORKDIR /path/to/workdir`。

为后续的 `RUN`、`CMD`、`ENTRYPOINT` 指令配置工作目录。

> 可以使用多个 `WORKDIR` 指令，后续命令如果参数是相对路径，则会基于之前命令指定的路径。例如
>
> ```dockerfile
> WORKDIR /a
> WORKDIR b
> WORKDIR c
> # 等价与
> WORKDIR /a/b/c
> ```

####  VOLUME

格式为 `VOLUME ["<路径1>", "<路径2>"...]` |  `VOLUME <路径>`。

创建一个可以从本地主机或其他容器挂载的挂载点，一般用来存放数据库和需要保持的数据等。

> 定义匿名数据卷。在启动容器时忘记挂载数据卷，会自动挂载到匿名卷。
>
> 作用：
>
> - 避免重要的数据，因容器重启而丢失，这是非常致命的。
> - 避免容器不断变大。
>
> 在启动容器 docker run 的时候，我们可以通过 -v 参数修改挂载点。

```dockerfile
FROM centos:7
RUN yum install -y vim
RUN ["yum","install","-y","vim"]
EXPOSE 5672
EXPOSE 15672
WORKDIR /data
WORKDIR bb
COPY aa.txt /data/bb
ADD bb.txt /data/bb
ADD https://apache.claz.org/tomcat/tomcat-8/v8.5.66/bin/apache-tomcat-8.5.66.tar.gz /data/bb
ADD apache-tomcat-8.5.66.tar.gz /data/bb
RUN mv apache-tomcat-8.5.66 tomcat
WORKDIR tomcat
VOLUME ["/data/bb/tomcat/webapps"]
```

#### ENV

格式为：`ENV <key> <value>` | `ENV <key1>=<value1> <key2>=<value2>...`

设置环境变量，定义了环境变量，那么在后续的指令中，就可以使用这个环境变量。

```dockerfile
FROM centos:7
ENV BASE_DIR /data/bb
COPY aa.txt $BASE_DIR
```

#### USER

用于指定执行后续命令的用户和用户组，这边只是切换后续命令执行的用户（用户和用户组必须提前已经存在）。

格式：`USER <用户名>[:<用户组>]`

### 8.3 创建镜像

编写完成 Dockerfile 之后，可以通过 `docker build` 命令来创建镜像。

基本的格式为 `docker build [选项] 路径`，该命令将读取指定路径下（包括子目录）的 Dockerfile，并将该路径下所有内容发送给 Docker 服务端，由服务端来创建镜像。因此一般建议放置 Dockerfile 的目录为空目录。也可以通过 `.dockerignore` 文件（每一行添加一条匹配模式）来让 Docker 忽略路径下的目录和文件。

要指定镜像的标签信息，可以通过 `-t` 选项，例如

```shell
docker build -t mycentos:1.0 .
```

### 8.4 使用 Dockerfile 构建 springboot 应用

#### 8.4.1 创建 Dockerfile 文件

```dockerfile
FROM openjdk:8-jre
WORKDIR /app # 设置工作目录为 /app
ADD vueadmin-java-0.0.1-SNAPSHOT.jar app.jar # 将context 路径上的vueadmin-java-0.0.1-SNAPSHOT.jar 添加到镜像中并重新命名为app.jar
EXPOSE 8081 # 暴露端口 8081 ，方便 -p 映射端口
ENTRYPOINT ["java","-jar"] # 执行命令java -jar
CMD [ "app.jar" ] #　参数为　app.jar
```

#### 8.4.2 构建镜像

```shell
docker build -t admin-vue:1.0 .
```

#### 8.4.3 创建容器

```shell
docker run -d -p 8081:8081 admin-vue:1.0
```

#### 8.4.4 效果

![](http://qiniu.zhouhongyin.top/2022/06/05/1654405991-image-20210521161401190.png)

## 九、idea 连接使用 Docker

参考博客：https://blog.csdn.net/qq_40298902/article/details/106543208

#### 9.1 开启 Docker 远程访问

```shell
#修改Docker服务文件，需要先切换到root用户
vim /lib/systemd/system/docker.service
#注释掉"ExecStart"这一行，并添加下面这一行信息
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock -H tcp://0.0.0.0:2375
```

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406079-1654405996-image-20210521195424704.png)

#### 9.2 重新加载配置文件

```shell
#重新加载配置文件
systemctl daemon-reload
#重启服务
systemctl restart docker.service
#查看配置的端口号（2375）是否开启（非必要）
netstat -nlpt  #如果找不到netstat命令，可以先安装一下这个工具，具体百度

```

#### 9.3 使用 idea 连接docker

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406004-image-20210521195607141.png)

#### 9.4 连接成功

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406084-image-20210521195804298.png)

>  **idea 连接远程服务器：**
>
> ![](http://qiniu.zhouhongyin.top/2022/06/05/1654406096-image-20210521165941811.png)
>
> ![](http://qiniu.zhouhongyin.top/2022/06/05/1654406102-image-20210521194527489.png)
>
> 

## 十、[Compose](https://docs.docker.com/compose/)

### 10.1 引言

Dockerfile 可以让用户管理一个单独的应用容器；而 Compose 则允许用户在一个模板（YAML 格式）中定义一组相关联的应用容器（被称为一个 **project**，即项目），例如一个 Web 服务容器再加上后端的数据库服务容器等。

Compose 使用的三个步骤：

- 使用 Dockerfile 定义应用程序的环境。
- 使用 docker-compose.yml 定义构成应用程序的服务，这样它们可以在隔离环境中一起运行。
- 最后，执行 docker-compose up 命令来启动并运行整个应用程序。

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406106-compose.png)

> 之前运行一个镜像，需要添加大量的参数。
>
> 现在可以通过docker-dompose来编写这些参数
>
> docker-dompose可以帮助我们批量管理容器
>
> 只需要通过一个docker-compose.yml文件去维护即可

#### 两个重要概念

- **服务（service）：**一个应用容器，实际上可以运行多个相同镜像的实例，也就是多个服务。
- **项目（project）：**由一组关联的应用容器组成的一个完整业务单元，就叫做项目。

可见，一个项目可以由多个服务（容器）关联而成，Compose 面向项目进行管理。

### 10.2 下载和安装 docker-Compose

```sh
# 下载 docker-compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
# 设置权限
sudo chmod a+x /usr/local/bin/docker-compose
```

### 10.3 docker-compose.yml 配置指令

#### version

指定本 yml 依从的 compose 哪个版本制定的，一般为 3.0 ~ 3.9。[具体版本信息](https://docs.docker.com/compose/compose-file/compose-file-v3/)

```yml
version: "3.1"
```

> 可通过 `docker info` 查看自己**Docker Engine release**
>
> ![](http://qiniu.zhouhongyin.top/2022/06/05/1654406114-image-20210522111010818.png)

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406116-image-20210522110857480.png)

#### services

下面写服务名。

```yml
version: "3.1"
services:
  tomcat: # 服务名

```

#### 服务名

标识一个服务。

```yml
version: "3.1"
services:
  tomcat: # 服务名
  	.....
  mysql:
  	.....
  redis:
  	.....
```

#### container_name

设置容器名

```yml
version: "3.1"
services:
  tomcat:
    container_name: tomcat01
```

#### image

指定为镜像名称或镜像 ID。如果镜像在本地不存在，`Compose` 将会尝试拉去这个镜像。

```yml
version: "3.1"
services:
  tomcat:
    image: tomcat:8.0-jre8
```

#### build

指定 `Dockerfile` 所在文件夹的路径。 `Compose` 将会利用它自动构建这个镜像，然后使用这个镜像（镜像名为服务名）。

- context：上下文路径（Dockerfile 所在的目录）。
- dockerfile：指定构建镜像的 Dockerfile 文件名。
- args：添加构建参数，这是只能在构建过程中访问的环境变量。
- labels：设置构建镜像的标签。
- target：多层构建，可以指定构建哪一层。

```yml
# 指定为从上下文路径 ./dir/Dockerfile 所构建的镜像：
version: "3.7"
services:
  webapp:
    build: ./dir

version: "3.7"
services:
  webapp:
    build: # 构建的镜像名为服务名
      context: ./dir # 相对与 docker-compose 文件
      dockerfile: Dockerfile # 默认为 Dockerfile
```



#### ports

定义端口映射。

```yml
version: "3.1"
services:
  tomcat:
    ports:
      - "8080:8080"
```

#### expose

暴露端口，但不映射到宿主机，只被连接的服务访问。

```yml
version: "3.1"
services:
  tomcat:
    expose:
      - "3000"
      - "8000"
```

#### volumes

数据卷映射路径。可以设置宿主机路径 （`HOST:CONTAINER`） 或加上访问模式 （`HOST:CONTAINER:ro`）。

> 如果定义的不是绝对路径。那么**需要在配置文件中声明**，这样 docker 会自动创建名为 `项目名_宿主机映射路径` 的数据卷。例如：`tomcatapp:/usr/local/tomcat/webapps` -----> `hellocompose_tomcatapp`，如果不想加上项目名，可以设至 external: false，但需要数据卷存在。

```yml
version: "3.1"
services:
  tomcat:
    volumes:
      - tomcatapp:/usr/local/tomcat/webapps
     
# 声明 volume
volumes:
  tomcatapp:
    external:
      false
```

#### networks

设置容器连接的网桥。网桥不存在时需要在配置文件中声明，使 docker 自动创建名为 `项目名_网桥名` 的网桥。**如果不指定此命令 docker-compose 会自动为该项目创建名为 `项目名_default` 的网桥，并将该项目的所有服务连接到该网桥上。**

> 同一网络上的其他容器可以使用服务名称或此别名来连接到对应容器的服务。

```yml
version: "3.1"
services:
  tomcat:
    networks:
      - hello
# 声明网桥
networks:
  hello:
   # external: 
   #   true # 使用外部自己创建的网桥
```

#### environment

设置环境变量。你可以使用数组或字典两种格式。

添加环境变量。您可以使用数组或字典、任何布尔值，布尔值需要用引号引起来，以确保 YML 解析器不会将其转换为 True 或 False。

```yml
version: "3.1"
services:
  mysql:
    environment:
      - MYSQL_ROOT_PASSWORD=root
    # environment:
      # MYSQL_ROOT_PASSWORD=root
      # TZ: Asia/Shanghai  # 指定时区
```

#### env_file

从文件添加环境变量。可以是单个值或列表的多个值。

```
version: "3.1"
services:
  mysql:
   env_file:
     - ./mysql.env 
```

创建以 `.env` 结尾的文件：

```env
MYSQL_ROOT_PASSWORD=root
```

#### command

覆盖容器启动的默认命令。

```yml
version: "3.1"
services:  
  redis:
    # command: "redis-server --appendonly yes" 
    command: ["redis-server", "--appendonly", "yes"]
```

#### restart

- no：是默认的重启策略，在任何情况下都不会重启容器。
- always：容器总是重新启动。
- on-failure：在容器非正常退出时（退出状态非0），才会重启容器。
- unless-stopped：在容器退出时总是重启容器，但是不考虑在Docker守护进程启动时就已经停止了的容器

```yml
version: "3.1"
services:
  mysql:
    restart: always
```

#### depends_on

设置依赖关系。

- docker-compose up ：以依赖性顺序启动服务。在以下示例中，先启动 db 和 redis ，才会启动 web。
- docker-compose up SERVICE ：自动包含 SERVICE 的依赖项。在以下示例中，docker-compose up web 还将创建并启动 db 和 redis。
- docker-compose stop ：按依赖关系顺序停止服务。在以下示例中，web 在 db 和 redis 之前停止。

```yml
version: "3.7"
services:
  web:
    build: .
    depends_on:
      - db
      - redis
  redis:
    image: redis
  db:
    image: postgres
```

> 注意：web 服务不会等待 redis db 完全启动 之后才启动。

#### healthcheck

用于检测 docker 服务是否健康运行。

```yml
version: "3.7"
services:
  web:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"] # 设置检测程序
      interval: 1m30s # 设置检测间隔
      timeout: 10s # 设置检测超时时间
      retries: 3 # 设置重试次数
      start_period: 40s # 启动后，多少秒开始启动检测程序
```

#### sysctls(非必须)

设置容器中的内核参数，可以使用数组或字典格式。

```yml
version: "3.7"
services:
  web:
    sysctls:
      net.core.somaxconn: 1024
      net.ipv4.tcp_syncookies: 0
```

#### ulimits(非必须)

覆盖容器默认的 ulimit。

```yml
version: "3.7"
services:
  web:
    ulimits: # 修改容器中系统内部的最大进程数
      nproc: 65535
      nofile:
        soft: 20000
        hard: 40000
```

### 10.4 Compose 命令说明

#### 10.4.1 Compose 的命令对象与格式

对于 Compose 来说，大部分命令的对象既可以是项目本身，也可以指定为项目中的服务或者容器。如果没有特别的说明，命令对象将是项目，这意味着项目中所有的服务都会受到命令影响。

执行 `docker-compose [COMMAND] --help` 或者 `docker-compose help [COMMAND]` 可以查看具体某个命令的使用格式。

`docker-compose` 命令的基本的使用格式是

```bash
docker-compose [-f=<arg>...] [options] [COMMAND] [ARGS...]
```

#### 10.4.2 命令选项

- `-f, --file FILE` 指定使用的 Compose 模板文件，默认为 `docker-compose.yml`，可以多次指定。
- `-p, --project-name NAME` 指定项目名称，默认将使用所在目录名称作为项目名。
- `--verbose` 输出更多调试信息。
- `-v, --version` 打印版本并退出。

#### 10.4.3 指令使用说明

##### `build`

格式为 `docker-compose build [options] [SERVICE...]`。

构建（重新构建）项目中的服务容器。

服务容器一旦构建后，将会带上一个标记名，例如对于 web 项目中的一个 db 容器，可能是 web_db。

可以随时在项目目录下运行 `docker-compose build` 来重新构建服务。

选项包括：

- `--force-rm` 删除构建过程中的临时容器。
- `--no-cache` 构建镜像过程中不使用 cache（这将加长构建过程）。
- `--pull` 始终尝试通过 pull 来获取更新版本的镜像。

##### `config`

验证 Compose 文件格式是否正确，若正确则显示配置，若格式错误显示错误原因。

##### `down`

此命令将会停止 `up` 命令所启动的容器，并移除网络

##### `exec`

进入指定的容器。

`docker-compose exec server_name `

##### `help`

获得一个命令的帮助。

##### `images`

列出 Compose 文件中包含的镜像。

##### `kill`

格式为 `docker-compose kill [options] [SERVICE...]`。

通过发送 `SIGKILL` 信号来强制停止服务容器。

支持通过 `-s` 参数来指定发送的信号，例如通过如下指令发送 `SIGINT` 信号。

```bash
$ docker-compose kill -s SIGINT
```

##### `logs`

格式为 `docker-compose logs [options] [SERVICE...]`。

查看服务容器的输出。默认情况下，docker-compose 将对不同的服务输出使用不同的颜色来区分。可以通过 `--no-color` 来关闭颜色。

该命令在调试问题的时候十分有用。

##### `pause`

格式为 `docker-compose pause [SERVICE...]`。

暂停一个服务容器。

##### `port`

格式为 `docker-compose port [options] SERVICE PRIVATE_PORT`。

打印某个容器端口所映射的公共端口。

选项：

- `--protocol=proto` 指定端口协议，tcp（默认值）或者 udp。
- `--index=index` 如果同一服务存在多个容器，指定命令对象容器的序号（默认为 1）。

##### `ps`

格式为 `docker-compose ps [options] [SERVICE...]`。

列出项目中目前的所有容器。

选项：

- `-q` 只打印容器的 ID 信息。

##### `pull`

格式为 `docker-compose pull [options] [SERVICE...]`。

拉取服务依赖的镜像。

选项：

- `--ignore-pull-failures` 忽略拉取镜像过程中的错误。

##### `push`

推送服务依赖的镜像到 Docker 镜像仓库。

##### `restart`

格式为 `docker-compose restart [options] [SERVICE...]`。

重启项目中的服务。

选项：

- `-t, --timeout TIMEOUT` 指定重启前停止容器的超时（默认为 10 秒）。

##### `rm`

格式为 `docker-compose rm [options] [SERVICE...]`。

删除所有（停止状态的）服务容器。推荐先执行 `docker-compose stop` 命令来停止容器。

选项：

- `-f, --force` 强制直接删除，包括非停止状态的容器。一般尽量不要使用该选项。
- `-v` 删除容器所挂载的数据卷。

##### `run`

格式为 `docker-compose run [options] [-p PORT...] [-e KEY=VAL...] SERVICE [COMMAND] [ARGS...]`。

在指定服务上执行一个命令。

例如：

```bash
$ docker-compose run ubuntu ping docker.com
```

将会启动一个 ubuntu 服务容器，并执行 `ping docker.com` 命令。

默认情况下，如果存在关联，则所有关联的服务将会自动被启动，除非这些服务已经在运行中。

该命令类似启动容器后运行指定的命令，相关卷、链接等等都将会按照配置自动创建。

两个不同点：

- 给定命令将会覆盖原有的自动运行命令；
- 不会自动创建端口，以避免冲突。

如果不希望自动启动关联的容器，可以使用 `--no-deps` 选项，例如



```bash
$ docker-compose run --no-deps web python manage.py shell
```

将不会启动 web 容器所关联的其它容器。

选项：

- `-d` 后台运行容器。
- `--name NAME` 为容器指定一个名字。
- `--entrypoint CMD` 覆盖默认的容器启动指令。
- `-e KEY=VAL` 设置环境变量值，可多次使用选项来设置多个环境变量。
- `-u, --user=""` 指定运行容器的用户名或者 uid。
- `--no-deps` 不自动启动关联的服务容器。
- `--rm` 运行命令后自动删除容器，`d` 模式下将忽略。
- `-p, --publish=[]` 映射容器端口到本地主机。
- `--service-ports` 配置服务端口并映射到本地主机。
- `-T` 不分配伪 tty，意味着依赖 tty 的指令将无法运行。

##### `scale`

格式为 `docker-compose scale [options] [SERVICE=NUM...]`。

设置指定服务运行的容器个数。

通过 `service=num` 的参数来设置数量。例如：



```bash
$ docker-compose scale web=3 db=2
```

将启动 3 个容器运行 web 服务，2 个容器运行 db 服务。

一般的，当指定数目多于该服务当前实际运行容器，将新创建并启动容器；反之，将停止容器。

选项：

- `-t, --timeout TIMEOUT` 停止容器时候的超时（默认为 10 秒）。

##### `start`

格式为 `docker-compose start [SERVICE...]`。

启动已经存在的服务容器。

##### `stop`

格式为 `docker-compose stop [options] [SERVICE...]`。

停止已经处于运行状态的容器，但不删除它。通过 `docker-compose start` 可以再次启动这些容器。

选项：

- `-t, --timeout TIMEOUT` 停止容器时候的超时（默认为 10 秒）。

##### `top`

查看各个服务容器内运行的进程。

##### `unpause`

格式为 `docker-compose unpause [SERVICE...]`。

恢复处于暂停状态中的服务。

##### `up`

格式为 `docker-compose up [options] [SERVICE...]`。

该命令十分强大，它将尝试自动完成包括构建镜像，（重新）创建服务，启动服务，并关联服务相关容器的一系列操作。

链接的服务都将会被自动启动，除非已经处于运行状态。

可以说，大部分时候都可以直接通过该命令来启动一个项目。

默认情况，`docker-compose up` 启动的容器都在前台，控制台将会同时打印所有容器的输出信息，可以很方便进行调试。

当通过 `Ctrl-C` 停止命令时，所有容器将会停止。

如果使用 `docker-compose up -d`，将会在后台启动并运行所有的容器。一般推荐生产环境下使用该选项。

默认情况，如果服务容器已经存在，`docker-compose up` 将会尝试停止容器，然后重新创建（保持使用 `volumes-from` 挂载的卷），以保证新启动的服务匹配 `docker-compose.yml` 文件的最新内容。如果用户不希望容器被停止并重新创建，可以使用 `docker-compose up --no-recreate`。这样将只会启动处于停止状态的容器，而忽略已经运行的服务。如果用户只想重新部署某个服务，可以使用 `docker-compose up --no-deps -d ` 来重新创建服务并后台停止旧服务，启动新服务，并不会影响到其所依赖的服务。

选项：

- `-d` 在后台运行服务容器。
- `--no-color` 不使用颜色来区分不同的服务的控制台输出。
- `--no-deps` 不启动服务所链接的容器。
- `--force-recreate` 强制重新创建容器，不能与 `--no-recreate` 同时使用。
- `--no-recreate` 如果容器已经存在了，则不重新创建，不能与 `--force-recreate` 同时使用。
- `--no-build` 不自动构建缺失的服务镜像。
- `-t, --timeout TIMEOUT` 停止容器时候的超时（默认为 10 秒）。

##### `version`

格式为 `docker-compose version`。

打印版本信息。

### 10.5 docker-compose 配置 Dockerfile 使用

> 使用docker-compose.yml 文件以及Dockerfile文件在生成自定义镜像的同时启动当前镜像，并且由docker-compose去管理容器。

```yml
# yml 文件
version: '3.1'
service:
  ssm:
    restart: always
    build:   # 构建自定义镜像
      context: ../  #指定Dockerfile文件所在的路径
      dockerfile: Dockerfile  # 指定Dockerfile 文件名称
    image: ssm:1.0.1
    container_name: ssm
    ports:
      - 8081:8080
    environment:
      TZ: Asia/Shanghai
```

----------------


```dockerfile
# Dockerfile 文件
form daocloud.io/library/mysql:5.7.4
copy ssm.war /usr/local.tomcar/webapps
```

-----------

```shell
# 可以直接启动基于 docker-compose.yml以及 Dockerfile文件构建的自定义镜像
docker-compose up -d
# 如果基于自定义镜像不存在，docker-compose会帮助我们构建自定义镜像，如果自定义镜像已经存在，会直接运行这个镜像
# 如果在运行之后想重新构建自定义镜像
docker-compose build
# 如果在运行之前就构建自定义镜像
docker- up -d --build
```

> **可以直接启动基于 docker-compose.yml 以及 Dockerfile 文件构建的自定义镜像：`docker-compose up -d`**
>
> **如果基于自定义镜像不存在，docker-compose 会帮助我们构建自定义镜像，如果自定义镜像已经存在，会直接运行这个镜像**
>
> **如果在运行之后想重新构建自定义镜像：`docker-compose build`**
>
> **如果在运行之前就构建自定义镜像：`docker- up -d --build`**

## 十一、可视化图形工具 Portainer

### 11.1 Portainer介绍

Portainer是一个可视化的容器镜像的图形管理工具，利用Portainer可以轻松构建，管理和维护Docker环境。 而且完全免费，基于容器化的安装方式，方便高效部署。

官方站点：[https://www.portainer.io/](http://www.yunweipai.com/go?_=ad9d485327aHR0cHM6Ly93d3cucG9ydGFpbmVyLmlvLw==)

### 11.2 安装

```shell
# 拉取镜像
docker pull portainer/portainer

# 运行容器
docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer
```

### 11.3 连接

#### 11.3.1 使用浏览器访问网址

访问 http://ip:9000/

#### 11.3.2 注册账号

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406146-image-20210522164853986.png)

#### 11.3.3 选择本地模式

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406149-image-20210522163757224.png)

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406168-image-20210522165333523.png)

![](http://qiniu.zhouhongyin.top/2022/06/05/1654406154-image-20210522165418924.png)