---
title: Cookie案例
date: 2019-04-10
tags:
  - Java
  - Sverlet
  - Cookie
categories:
  - Java
  - Sverlet
  - Cookie
---

利用Cookie记录上一次访问的时间

<!--more-->

1. ## 获取所求Cookie，并判断是否以前访问过，如果访问过输出上次访问的时间

   ```java
   		//设置相应消息体的数据格式及编码
           response.setContentType("text/html;charset=utf-8");
   
           //1.获取所有cookie
           Cookie[] cookies = request.getCookies();
           boolean flag = false;//没有cookie为lastTime
           //2.遍历cookie数组
           if (cookies != null && cookies.length > 0){
               for (Cookie cookie : cookies) {
                   //3.获取cookie名称
                   String name = cookie.getName();
                   //4.判断名称是否是：lastTime
                   if ("lastTime".equals(name)){
                       //有该cookie，不是第一次访问
   
                       //响应数据
                       //获取cookie的value时间
                       String value = cookie.getValue();
   
                       //System.out.println("解码前"+value);
                       //URL解码
                       value = URLDecoder.decode(value,"utf-8");
                       //System.out.println("解码后"+value);
   
                       response.getWriter().write("欢迎回来，上次访问是将为："+value);
   
                       flag = true;//有lastTime
                       //获取当前时间的字符串，重新是指cookie的值，重新发送cookie
                       Date data = new Date();
                       //重定义时间格式
                       SimpleDateFormat sdf = new SimpleDateFormat("yyyy年MM月dd日 HH:mm:ss");
                       String str_data = sdf.format(data);
   
                       //System.out.println("编码前："+str_data);
                       //URL编码
                       str_data = URLEncoder.encode(str_data, "utf-8");
                       //System.out.println("编码后："+str_data);
   
                       cookie.setValue(str_data);
                       //是指cookie存活时间
                       cookie.setMaxAge(60*60*24*30);
                       //发送cookie
                       response.addCookie(cookie);
   
   
                       break;
                   }
               }
   
           }
   ```

   

2. ## 若曾经没有访问过，将本次访问的时间以Cookie的形式返回浏览器

   ```java
   			if (cookies ==null || cookies.length == 0 || flag == false){
               Date data = new Date();
               //重定义时间格式
               SimpleDateFormat sdf = new SimpleDateFormat("yyyy年MM月dd日 HH:mm:ss");
               String str_data = sdf.format(data);
   
               //System.out.println("编码前："+str_data);
               //URL编码
               str_data = URLEncoder.encode(str_data, "utf-8");
               //System.out.println("编码后："+str_data);
   
               Cookie cookie = new Cookie("lastTime", str_data);
               //是指cookie存活时间
               cookie.setMaxAge(60*60*24*30);
               //发送cookie
               response.addCookie(cookie);
   
               response.getWriter().write("欢迎首次访问！");
   
           }
   ```

   3. ## 注意

      ### 3.1 由于Cookie不支持特殊字符，所以向Cookie传值是需要先编码，如。

      ```java
      str_data = URLEncoder.encode(str_data, "utf-8");
      cookie.setValue(str_data);
      ```

      ### 3.2 同时输出Cookie值时需要解码，如。

      ```java
       String value = cookie.getValue();
       value = URLDecoder.decode(value,"utf-8");
      ```

      