---
title: 如何利用Hexo和gitee搭建自己的博客
date: 2019-02-1
tags:
  - Hexo
  - blog
categories:
  - Hexo
---

记录一下自己第一次搭建博客的过程。(本过程全部基于window10系统)

![](https://gitee.com/Maskvvv/bolg/raw/master/pic/%20(13).jpg)

<!--more -->

------



## 前期准备

### 01.安装Node.js

可登录[官方网站](https://nodejs.org/en/)下载安装包，由于网站是国外的下在会很慢，也可用[百度网盘](https://pan.baidu.com/s/1ra6ii9efDuQXMD6kpHZHOA)下载，安装是全部默认设置next就好，环境会自己给你配置好。

![屏幕截图(5)](https://gitee.com/Maskvvv/bolg/raw/master/blog/屏幕截图(5).png)



### 02.安装git

可[官方网站](https://git-scm.com/downloads)下载，也可[百度网盘](https://pan.baidu.com/s/1sOGS7snuiVaCPkvjJr8tQg)下载，同样安装是全部默认设置next就好，环境会自己给你配置好。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/屏幕截图(3).png)





## 开始搭建博客

### 01.新建一个空的文件夹

此文件夹日后会放你博客的东西（**重要**），这里我选择在桌面新建一个文件夹命名为Myblog（名称随意，但最好是英文）。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/屏幕截图(6).png)



### 02.安装hexo

右键你刚刚创建的文件夹，选择git bash Here。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/屏幕截图(7).png)



输入`node -v`和`npm -v`，查看Node.js 是否安装成功，如果显示版本号，则表示成功安装。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/2-1.png)



安装cnpm提高下载速度，以后下载就可以不用npm下载了。

```
npm install -g cnpm --registry=https://registry.npm.taobao.org
```



安装hexo，这里用刚才装的cnpm安装，也可用npm安装但速度会很慢。

```
cnpm install -g hexo-cli
```

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/2-3.png)

这里可以看到代码的最后一行hexo是默认安装在c盘的。



输入`hexo -v`查看hexo信息，显示此信息表示安装成功。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/2-4.png)



输入`hexo Init`初始化一个博客。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/2-5.png)

如果出现卡在`INFO Install dependencies`的请况可`Ctrl+c`停止运行，然后输入`cnpm install`接着安装。出现这种情况的原因是网络问题。![](https://gitee.com/Maskvvv/bolg/raw/master/blog/2-6.png)

这时你可以在你刚才建的文件夹里看见hexo为你初始的博客的一些文件。

![](https://gitee.com/Maskvvv/bolg/raw/master/blog/2-7.png)





## 03.测试hexo

待续.......