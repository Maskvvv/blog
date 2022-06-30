---
title: IDAE的常用快捷键和快速生成代码
date: 2019-03-20 
tags:
  - IDEA
  - Java
categories:
  - Java
  - IDEA
---

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701199-113.png)

<!--more-->

------



### 1.快速生成mian方法

输入`psvm`，然后回车。

```java
//psvm(main) + Enter
public static void main(String[] args) {    
}
```

### 2.生成println输出函数

输入`sout`，然后Enter。

```java
//sout + Enter
System.out.println();
```

### 3.生成普通for循环

```java
//fori + Enter
for (int i = 0; i < ; i++) {           
}
```

### 4.生成增强for循环

```java
//集合.for + Enter
String [] arrs = {"1","2","3"};
for (String arr : arrs) {
}
```

### 5.生成流程控制语句

选中后`Ctrl+Alt+T`，效果图如下。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701287-%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE-17-.png)

### 6.生成构造方法、get和set方法、重写toString()的方法、重写父类方法等。

`Alt+insert`,笔记本用户可能需要`Alt+Fn+insert`，效果图如下。

![](http://qiniu.zhouhongyin.top/2022/06/08/1654701343-%E5%B1%8F%E5%B9%95%E6%88%AA%E5%9B%BE-18-.png)

### 7.常用快捷键

#### 7.1Ctrl相关

|         快捷键          |              简介              |
| :---------------------: | :----------------------------: |
| ctrl+space(建议修改为;) | 基础代码补全(建议修改为ctrl+;) |
|       ctrl + home       |        移动到文件的顶部        |
|       ctrl + end        |        移动到文件的底部        |
|         ctrl+f          |     在当前文本进行文本查找     |
|         ctrl+h          |        查看类的继承结构        |
|         ctrl+n          |        根据类名定位文件        |
|         ctrl+o          |        快速重写父类方法        |
|         ctrl+d          |            复制一行            |
|        ctrl+f12         |        弹出当前文本结构        |
|         ctrl+/          |          单行代码注释          |
|      ctrl+shift+/       |          多行代码注释          |

#### 7.2Alt相关

|  快捷键   |                           简介                           |
| :-------: | :------------------------------------------------------: |
| alt+enter | 根据光标所在位置，提供快速修复选择，用的最多的是生成变量 |

#### 7.3Shift相关

|       快捷键        |        简介        |
| :-----------------: | :----------------: |
| shift + ctrl + 上下 |   上下移动代码块   |
| shift + alt + 上下  | 上下移动选中的代码 |
|    shift + enter    |    向下插入一行    |



#### 7.4Ctrl+Alt相关

|   快捷键   |                 简介                 |
| :--------: | :----------------------------------: |
| Ctrl+Alt+B | 在某个方法名上使用会跳到具体的实现出 |
| Ctrl+Alt+D |      格式化代码，可使代码变整齐      |
| Ctrl+Alt+T |     对选中的代码弹出环绕项弹出层     |

#### 7.5Ctrl+Shift相关

|    快捷键    |              简介              |
| :----------: | :----------------------------: |
| ctrl+shift+/ |          多行代码注释          |
| ctrl+shift+r |  根据输入的内容替换对应的内容  |
| ctrl+shift+u | 对选中的代码进行大小写轮流转换 |
| ctrl+shift+z |   取消撤销，建议修改为ctrl+y   |

