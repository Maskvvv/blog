---
title: 内部比较器（Comparable接口）和外部比较器（Comparator接口)
date: 2021-6-13
updated: 2021-6-13
tags:
  - Java
  - Comparable
  - Comparator
categories:
  - 面试
  - 内部比较器（Comparable接口）和外部比较器（Comparator接口)
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042428-1_iIXOmGDzrtTJmdwbn7cGMw.png)

<!-- more -->

## 一、比较器简介

说到比较器我们第一时间会想到 equals ，但是 equals 是用来比较是否相等的，Comparator 或者 Comparable 是用来比较顺序的（也就是排序）。

### 1.1 比较器的概念

确定两个对象之间的大小关系及排列顺序称为比较，能实现这个比较功能的类或方法称之为比较器，在 java 中只有两种比较器。

### 1.2 比较器的分类

内部比较器（Comparable接口）和外部比较器（Comparator接口）。

## 二、内部比较器（Comparable接口）

### 2.1 内部比较器的概念

类实现了 **Comparable** 接口，然后重写了**compareTo 方法**（这个方法可以看作比较器），这个类就拥有了内部比较器。注意，你一旦实现了比较器，就说明这个类支持排序，比如单例模式的类就不能进行排序。（简单点说就是把比较器写在类的内部）

### 2.2 Comparable接口的源码（了解）

```java
package java.lang;
public interface Comparable<T>
{
    public int compareTo(T o); 
    
    1）如果此对象（调用比较器方法的对象）大于指定对象（目标比较对象），返回正整数   
    2）如果此对象小于指定对象，返回负整数   
    3）如果此对象等于指定对象，返回零 
}
```

## 三、外部比较器（Comparator接口）

### 3.1外部比较器的概念

新定义一个类，类名随意，但这个类必须实现 **Comparator** 接口，重写**compare** 方法，我们把这个称作外部比较器。（简单点说就是把比较器写在类的外边，没错！就是在外边新定义了个比较器类！）

### 3.2 Comparable接口的源码（了解）

```java
package java.util;
public interface Comparator<T> {  
	int compare(T o1, T o2);  

  	1）如果o1大于o2，则返回正整数； 
 	2）如果o1小于o2，则返回负整数 
 	3）如果o1等于o2，则返回零   
}
```

## 四、两种比较器的应用场景

① 我们自定义一个类时，可以选择内部比较器，内部比较器很符合 java 封装的思想，也就是高内聚，但是！但是！但是！我们平时用到的类往往不是自定义的，而是别人已经写好并且已编译的类，我们只能调用，不能修改其源代码，这时我们就只能用外部比较器了。

② 还有种情况，我们用到的还是别人已经写好并且已编译的类，他写这个类的时候恰好也实现了内部比较器（我们常用的有基本类型的封装类，String，Date），但是他定义的这种比较方法，不是我们想要的（举个例子，integer 的内部比较器是按照数字大小进行比较排序，但是我们的需求是按照数字的绝对值进行排序，这就很尴尬了），这时我们就只能用外部比较器了。

③ 第三种情况，我们平时对对象进行排序，往往需要多种排序方式（举个例子，学生表的排序方式有学号排序，年龄排序，性别排序等等），这时我们也不得不用外部比较器了（也就是定义多个外部比较器类）。

由此看出，外部比较器比内部比较器更灵活，更易维护。

## 五、比较器的应用

最最常见的应用还是用在集合（list）和数组的 sort() 方法中，如果我们想用 sort() 方法，必须实现存储元素对象的内部比较器或者自定义一个用于存储元素对象之间的外部比较器，不然用 sort() 方法的时候容器会报错，它不知道用哪种方式进行排序。

**通过 Comparable 实现比较器**

```java
/** 
 * 员工实体 
 * @author Sam 
 * 
 */  
public class Employee implements Comparable<Employee> {  
      
    private int id;// 员工编号  
    private double salary;// 员工薪资  
      
    public int getId() {  
        return id;  
    }  
  
    public void setId(int id) {  
        this.id = id;  
    }  
  
    public double getSalary() {  
        return salary;  
    }  
  
    public void setSalary(double salary) {  
        this.salary = salary;  
    }  
      
    public Employee(int id, double salary) {  
        super();  
        this.id = id;  
        this.salary = salary;  
    }  
      
    // 为了输出方便，重写toString方法  
    @Override  
    public String toString() {  
        // 简单输出信息  
        return "id:"+ id + ",salary=" + salary;  
    }  
  
    // 比较此对象与指定对象的顺序  
    @Override  
    public int compareTo(Employee o) {  
        // 比较员工编号，如果此对象的编号大于、等于、小于指定对象，则返回1、0、-1  
        int result = this.id > o.id ? 1 : (this.id == o.id ? 0 : -1);  
        // 如果编号相等，则比较薪资  
        if (result == 0) {  
            // 比较员工薪资，如果此对象的薪资大于、等于、小于指定对象，则返回1、0、-1  
            result = this.salary > o.salary ? 1 : (this.salary == o.salary ? 0 : -1);  
        }  
        return result;  
    }  
  
}  
```

**通过 Comparator 实现比较器**

```java
/** 
 * 自定义员工比较器 
 * 
 */  
class EmployeeComparable implements Comparator<Employee> {  
  
    @Override  
    public int compare(Employee o1, Employee o2) {  
        // 比较员工编号，如果此对象的编号大于、等于、小于指定对象，则返回1、0、-1  
        int result = o1.getId() > o2.getId() ? 1 : (o1.getId() == o2.getId() ? 0 : -1);  
        // 如果编号相等，则比较薪资  
        if (result == 0) {  
            // 比较员工薪资，如果此对象的薪资大于、等于、小于指定对象，则返回1、0、-1  
            result = o1.getSalary() > o2.getSalary() ? 1 : (o1.getSalary() == o2.getSalary() ? 0 : -1);  
        }  
        return result;  
    }  
      
}  
```

**测试**

```java
/** 
 * 测试两种比较器 
 * @author Sam 
 * 
 */  
public class TestEmployeeCompare {  
    /** 
     * @param args 
     */  
    public static void main(String[] args) {  
          
        List<Employee> employees = new ArrayList<Employee>();  
        employees.add(new Employee(2, 5000));  
        employees.add(new Employee(1, 4500));  
        employees.add(new Employee(4, 3500));  
        employees.add(new Employee(5, 3000));  
        employees.add(new Employee(4, 4000));  
        // 内部比较器：要排序的对象要求实现了Comparable接口  
        Collections.sort(employees);  
        System.out.println("通过内部比较器实现：");  
        System.out.println(employees);  
          
        List<Employee> employees2 = new ArrayList<Employee>();  
        employees2.add(new Employee(2, 5000));  
        employees2.add(new Employee(1, 4500));  
        employees2.add(new Employee(4, 3500));  
        employees2.add(new Employee(5, 3000));  
        employees2.add(new Employee(4, 4000));  
        // 外部比较器：自定义类实现Comparator接口  
        Collections.sort(employees2, new EmployeeComparable());  
        System.out.println("通过外部比较器实现：");  
        System.out.println(employees2);  
    }  
  
}  
```


原文链接：https://blog.csdn.net/qq_36711757/article/details/80427064

