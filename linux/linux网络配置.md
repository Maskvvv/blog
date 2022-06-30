---
title: Linux网络配置（虚拟机）
date: 2020-09-28
tags:
  - Linux
  - VM虚拟机
categories:
  - Linux
---

![](linux%E7%BD%91%E7%BB%9C%E9%85%8D%E7%BD%AE/download.jpg)

<!-- more -->

## 一、配置VM虚拟网络编辑器

![](linux%E7%BD%91%E7%BB%9C%E9%85%8D%E7%BD%AE/image-20200927172608039.png)

<!-- more -->

> **注：网卡的选择**

![](linux%E7%BD%91%E7%BB%9C%E9%85%8D%E7%BD%AE/image-20200927173323852.png)

[vmware 桥接模式下与虚拟机互ping不通问题-终极解决办法](https://blog.csdn.net/helloexp/article/details/84787019)

## 二、给Linux配置静态ip

#### 2.1 给Linux分配静态IP

```sh
# 1.分配静态ip
dhclient
# 2.查看分配到静态ip（ens-33）
ifconfig
```

![](linux%E7%BD%91%E7%BB%9C%E9%85%8D%E7%BD%AE/image-20210425204331040.png)

#### 2.2 编辑配置文件

```sh
vi /etc/sysconfig/network-scripts/ifcfg-ens-33

BOOTPROTO="static"
IPADDR="192.168.199.135"
NETMASK="255.255.255.0"
GATEWAY="192.168.199.1"
DNS1="119.29.29.29"
```

![](linux%E7%BD%91%E7%BB%9C%E9%85%8D%E7%BD%AE/image-20200927180116711.png)

#### 2.3 重启网卡

```sh
systemctl restart network.service
```

