---
title: 验证码项目
date: 2019-04-10
tags:
  - Java
  - Sverlet
categories:
  - Java
  - Sverlet
---

验证码的随机生成。

<!-- more -->

## ChackCode验证码

1. ### 创建一张图片

```java
        int width = 600;
        int height = 300;
        //创建一张图片
        BufferedImage image = new BufferedImage(width,height,BufferedImage.TYPE_3BYTE_BGR);
```

2. ### 美化图片

```java
        Graphics g = image.getGraphics(); //画背景
        g.setColor(Color.pink);
        g.fillRect(0,0,width,height);
        g.setColor(Color.BLUE);//话边框
        g.drawRect(0,0,width-1,height-1);

```

3. ### 写验证码

```java
        String str = "ABCDEFGHIJKLMNOPQRSTUVWHYZabcdefghijklmnopqrstuvwxyz0123456789";

        Random ran = new Random(); //生成随机角标

        for (int i = 1; i < 5; i++) {
            int index = ran.nextInt(str.length());
            char ch = str.charAt(index);
            g.drawString(ch+"",width/5*i,height/2);
        }

        g.setColor(Color.GREEN);//画作标线
        for (int i = 0; i < 10; i++) {
            int x1 = ran.nextInt(width);
            int x2 = ran.nextInt(width);
            int y2 = ran.nextInt(height);
            int y1 = ran.nextInt(height);
            g.drawLine(x1,x2,y1,y2);
        }


```



4. ### 输出到浏览器

```java
	ImageIO.write(image,"jpg",response.getOutputStream());
```

