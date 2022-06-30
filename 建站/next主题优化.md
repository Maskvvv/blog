---
title: next主题优化
date: 2019-02-12 
tags:
  - Hexo
  - blog
  - next
categories:
  - Hexo
  - next
---

记录一下自己在优化next主题时遇到的问题。

![](https://gitee.com/Maskvvv/bolg/raw/master/pic/bg1.jpg)

<!--more-->

------



## 修改博客的背景图片

查阅了大量更换背景图片的资料，都是告诉你修改`custom.style`，但新版的next没有了`custom.style`文件，所以修改背景图片可通过修改`themes\next\source\css\_common\components`路径下的`back-to-top.styl`文件，在尾部添加以下代码即可修改背景图片

```
body {
  background: url(图片路径);
  background-size: cover;
  background-repeat: no-repeat;
  background-attachment: fixed;
  background-position: 50% 50%;
}
```

## 博客图片不显示问题

首先确认根目录`_config.yml`中有:

```
post_asset_folder: true
```

在博客的根路径下执行：

```
npm install https://github.com/CodeFalling/hexo-asset-image --save
```

