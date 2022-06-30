---
title: git学习
date: 2019-09-29
tags:
  - git
categories:
  - git
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700964-download.png)

<!-- more -->

## 一、介绍与安装

### 1.1 介绍

> Git是一个开源的分布式版本控制系统,用于敏捷高效地处理任何或小或大的项目。
>
> Git是 Linus Torvalds为了帮助管理 Linux内核开发而开发的一个开放源码的版本控制软件。
>
> 官网：https://git-scm.com

### 1.2 安装

> 下载git：https://git-scm.com/download

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700971-image-20200929091007310.png)

### 1.3 git的初始设置

```sh
# 安装后，打开cmd，自报家门
# 如下学习会在提价代码时使用，记录每次是谁提交的，可通过‘给git log’查看
# 执行
git config --global user.name "Your Name"  # 用户名
git config --global user.email "1429855087@qq.com"  # 邮箱
#查看信息
git config -l
# 测试
git version
```

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700973-image-20200929091653016.png)

### 1.4 架构

> **版本库：工作区中有一个隐藏目录`.git`,这个目录不属于工作区,而是git的`版本库`,是git管理的所有内容**
>
> **暂存区：版本库中包含一个临时区域,保存下一步要提交的文件。**
>
> **分支：版本库中包含若干分支,提交的文件存储在分支中。**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700976-image-20200929093204187.png)

## 二、本地仓库

> **对应的就是一个`目录`,这个目录中的所有文件被gt管理起来。**
>
> **以后会将一个`项目的根目录`,作为仓库。**
>
> **仓库中的每个文件的改动都由git跟踪**

> **cmd中执行命令：`git init`**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700979-image-20200929093911671.png)

## 三、基本操作

### 3.1 查看仓库状态

> **执行`git status`可以查看仓库状态**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700981-image-20200929094701065.png)

### 3.2 暂存文件

> **执行 `git add`  . 将工作区中的文件全部暂入缓存区**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700984-image-20200929095017250.png)

### 3.3 提交文件

> **执行 `git commit -m` “这里写需要提交的描述信息” 将缓存区的文件存入分支，形成一个版本。注：`-m` 意味massage， 描述本次提交。**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700987-image-20200929100956391.png)

## 四、远程仓库

> **当多人协同开发时,每人都在自己的本地仓库维护版本。**
>
> **但很重要的一点是,多人之间需要共享代码、合并代码,此时就需要一个`远程仓库`。**

### 4.1 远程仓库的工作模式

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700990-image-20200929101442512.png)

### 4.2 远程仓库选型

> 有很多git服务器库可以选择，我们可以在上面构建自己的远程仓库，比如git hub(https://github.com/)，码云(https://gitee.com/)。
>
> 许多公司也会构建自己的git服务器

### 4.3基本操作

#### 4.3 .1 注册git服务器账号

略

#### 4.3.2 建立远程仓库

![](http://qiniu.zhouhongyin.top/2022/06/08/1654700996-image-20200929102725571.png)



![](http://qiniu.zhouhongyin.top/2022/06/08/1654701004-image-20200929103105638.png)

#### 4.3.3 关联远程仓库

> **关联远程仓库 `git remote add origin https://github.com/Maskvvv/first_git.git`**
>
> **查看地址信息 `git remote -v`**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701007-image-20200929104524372.png)

#### 4.3.4 推送文件至远程仓库

> **将本地仓库中已经 commit的内容push到远程仓库,以共享自己的代码。**
>
> **将本地仓库master分支push到远程** `git push origin master`**，上传时会提示输入 git hub 的账号密码。**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701010-image-20200929105400733.png)

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701013-image-20200929105451915.png)

#### 4.3.5 克隆远程仓库

> **克隆远程仓库 `git clone https://github.com/Maskvvv/first_git.git`**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701016-image-20200929112553251.png)

#### 4.3.6 代码共享

> **多人协同开发时,写好代码的 `git push`上传到远程仓库;需要代码的 `git pull`拉取代码即可。**

> **上传：**
>
> - **`git add`**
> - **`git commit -m "new file hello.txt"`**
> - **`git push origin master`**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701019-image-20200929121719056.png)

> **拉取：**
>
> - **`git pull origin master`**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701023-image-20200929121954120.png)

#### 4.3.7 命令汇总

| 命令                                            | 介绍                                             |
| :---------------------------------------------- | ------------------------------------------------ |
| **`git remote add 标识名(origin)远程仓库地址`** | **关联到远程仓库**                               |
| **`git push 标识名(origin) 远程仓库地址`**      | **将本地仓库上传只远程仓库**                     |
| **`git pull 标识名(origin) 远程仓库地址`**      | **从远程仓库下载到本地仓库**                     |
| **`git clone 远程仓库地址`**                    | **将远程仓库复制到本地，并自动形成一个本地仓库** |

## 五、分支

### 5.1 分支的简介

> **分支，是一个个版本最终存储的位置。**
>
> **分支，就是一条时间线,每次 `git commit`形成一个个版本,一个个版本依次存储在分支的一个个提交点上**

| 分支由多个提交点组成,分支上会有一个指针,默认总是指向最新的提交点 |
| :----------------------------------------------------------: |
|    ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701028-image-20201002104218873.png)    |

### 5.2 分支的基本操作

#### 5.2.1 查看分支

> **查看当前仓库分支 `git branch`**
>
> **仓库默认只有 `master` 分支**
>
> **执行 `git commit` 时，默认实在`master`分支上保存版本**

|                 每个仓库默认只有`master`分支                 |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701032-image-20201002104844695.png) |

#### 5.2.2 创建分支

> **在商业项目开发过程中,我们不会轻易的在 `master分支`上做操作**
>
> **我们会通过`git branch 分支名`新建一个开发用的分支,在此分支上做版本的记录**
>
> **代码确实没有问题时,才会将开发分支上成熟的代码版本添加到 `master分支`上**
>
> **既保证开发过程中,可以及时记录版本,有保证 `master分支`上每个提交点都是稳健版本。**

|               通过`git branch 分支名`新建分支                |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701036-image-20201002203808973.png) |



#### 5.2.3 切换分支

> **默认情况下,当前使用的分支是 `master分支`**
>
> **可以通过`git checkout dev` 切换到`dev分支,`则后续的 `git commit`便会在`dev分支`上新建版本(提交点**

|             通过`git checkout dev` 切换到dev分支             |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701039-image-20201002204209814.png) |



### 5.3 新建分支的细节

#### 5.3.1 新分支初始内容

> **每个分支都有一个`指针`,新建一个分支,首先是新建一个`指针`。**
>
> **而且新分支的指针会和当前分支指向`同一个提交点`。**
>
> **新分支包含的提交点就是从第一个提交点到分支指针指向的提交点**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701042-image-20201002205354104.png)

#### 5.3.2 多分支走向

> **在 maste分支和新分支,分别进行 `git add`和 `git commit`**
>
> **分支情况如下图：**

|                   在dev分支进行一次commit                    |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701046-image-20201002205753712.png) |

|             在master和dev分支分别进行一次commit              |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701048-image-20201002205833432.png) |

#### 5.3.3 分支提交日志

> **查看分支的提交日志,进而看到分支中提交点的详细情况。**
>
> **查看简易的提交日志：`git log --oneline`**
>
> **查看完整的提交日志：`git log`**
>
> **查看完整的提交日志和简易分支图：`git log --oneline --graph`**

|                         查看提交日志                         |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701052-image-20201002211118466.png) |

### 5.4 分支的合并

> **两个分支的内容合并**
>
> **合并分支a的内容到分支b上（在分支b中执行）：`git merge 分支a`**

> **分支分为两种：`快速合并`和`三方合并`**

#### 5.4.1 快速合并

> **如果分支A当前是完全基于分支B的修改而来,则B分支合并A分是移动指针即可**

|                           快速合并                           |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701055-GIF.gif)![](http://qiniu.zhouhongyin.top/2022/06/08/1654701058-image-20201002215425195.png) |

#### 5.4.2 三方合并

> **在不具备快速合并的条件下,会果用三方合并。**

|       三方合并,将2和3的更改都累加在1上,形成新的提交点        |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701064-sanfanghebing.gif) |

|      通过 `git log --oneline --graph` 查看简易分支走势       |
| :----------------------------------------------------------: |
| ![](http://qiniu.zhouhongyin.top/2022/06/08/1654701068-image-20201002220250337.png) |

#### 5.4.3 合并冲突

> **两个分支进行合并，但它们含有对同一个文件的修改，则在合并时出现冲突，git无法决断该保留改文件哪个分支的修改，冲突后，git会将两个分支的内容都展示在文件中，并用 <<< ===>>> 进行分割**

> **解决方法：**
>
> 1. **保留某一方的,删除另一方的**
> 2. **保留双方的**
> 3. **但无论如何,要记得删除 `<<< == >>>>`分割**
> 4. **本质是两人协商为冲突的内容,定制出合理的内容。**
> 5. **修改完后在进行一次commit**

## 六、idea关联git

### 6.1 通过idea创建仓库

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701071-gitchangjiancangku.gif)

-------

### 6.2 idea忽略文件`.git`

```.git
HELP.md
target/
!.mvn/wrapper/maven-wrapper.jar
!**/src/main/**/target/
!**/src/test/**/target/

### STS ###
.apt_generated
.classpath
.factorypath
.project
.settings
.springBeans
.sts4-cache

### IntelliJ IDEA ###
.idea
*.iws
*.iml
*.ipr

### NetBeans ###
/nbproject/private/
/nbbuild/
/dist/
/nbdist/
/.nb-gradle/
build/
!**/src/main/**/build/
!**/src/test/**/build/

### VS Code ###
.vscode/

```

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701075-image-20201003104927475.png)

----

### 6.3 通过idea进行commit

> 1. **点击commit按钮**
> 2. **选择为跟踪文件和更新的文件**
> 3. **填写提交信息**
> 4. **commit**

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701079-image-20201003110144808.png)

---------

### 6.4 通过idea push到远程仓库

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701081-image-20201003110739914.png)

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701084-image-20201003111336662.png)

### 6.5 分支的操作

#### 新建分支

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701087-newdev.gif)

#### 切换分支

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701089-checkoutdev.gif)

### 6.6 从远程仓库克隆（clone）

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701094-image-20201003113438933.png)

![image-20201003113559415](http://qiniu.zhouhongyin.top/2022/06/08/1654701097-image-20201003113559415.png)

### 6.7 从远程仓库更新（pull）

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701099-image-20201003115624216.png)

### 6.8 冲突解决

待续.....

