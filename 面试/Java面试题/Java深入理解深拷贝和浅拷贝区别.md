---
title: Java 深入理解深拷贝和浅拷贝区别
date: 2021-6-19
updated: 2021-6-19
tags:
  - Java
  - 深拷贝和浅拷贝
categories:
  - 面试
  - Java 深入理解深拷贝和浅拷贝区别
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043229-1_iIXOmGDzrtTJmdwbn7cGMw.png)

<!-- more -->

## 一、拷贝的引入

### 1.1 引用拷贝

创建一个指向对象的引用变量的拷贝。

```java
class Teacher {
    private String name;
    private int age;

    public Teacher(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}

public class QuoteCopy {
    public static void main(String[] args) {
        Teacher teacher = new Teacher("riemann", 28);
        Teacher otherTeacher = teacher;
        System.out.println(teacher);
        System.out.println(otherTeacher);
    }
}
```

输出结果：

```java
com.test.Teacher@28a418fc
com.test.Teacher@28a418fc
```

结果分析：由输出结果可以看出，它们的**地址值是相同的**，那么它们肯定**是同一个对象**。**teacher 和 otherTeacher** 的**只是引用而已**，他们都指向了一个相同的对象 `Teacher(“riemann”,28)`。 这就叫做**引用拷贝**。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043234-20200830151203613.png)

### 1.2 对象拷贝

创建对象本身的一个副本。

```java
class Teacher implements Cloneable {
    private String name;
    private int age;

    public Teacher(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public Object clone() throws CloneNotSupportedException {
        Object object = super.clone();
        return object;
    }
}

public class ObjectCopy {
    public static void main(String[] args) throws CloneNotSupportedException {
        Teacher teacher = new Teacher("riemann", 28);
        Teacher otherTeacher = (Teacher) teacher.clone();
        System.out.println(teacher);
        System.out.println(otherTeacher);
    }
}
```

输出结果：

```java
com.test.Teacher@28a418fc
com.test.Teacher@5305068a
```

结果分析：由输出结果可以看出，它们的**地址是不同的**，也就是说**创建了新的对象**， 而不是把原对象的地址赋给了一个新的引用变量，这就叫做**对象拷贝**。

> 注：深拷贝和浅拷贝都是对象拷贝

## 二、浅拷贝

### 2.1 浅拷贝介绍

浅拷贝是按位拷贝对象，它会创建一个新对象，这个对象有着原始对象属性值的一份精确拷贝。如果属性是基本类型，拷贝的就是基本类型的值；如果属性是内存地址（引用类型），拷贝的就是内存地址 ，因此如果其中一个对象改变了这个地址，就会影响到另一个对象。即默认拷贝构造函数只是对对象进行浅拷贝复制(逐个成员依次拷贝)，即只复制对象空间而不复制资源。

简而言之，`浅拷贝仅仅复制所考虑的对象，而不复制它所引用的对象。`

### 2.2 浅拷贝特点

对于基本数据类型的成员对象，因为基础数据类型是值传递的，所以是直接将属性值赋值给新的对象。基础类型的拷贝，其中一个对象修改该值，不会影响另外一个。

对于引用类型，比如数组或者类对象，因为引用类型是引用传递，所以浅拷贝只是把内存地址赋值给了成员变量，它们指向了同一内存空间。改变其中一个，会对另外一个也产生影响。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043238-8878793-61eb6dbc8885a9bc.webp)

```java
public class ShallowCopy {
    public static void main(String[] args) throws CloneNotSupportedException {
        Teacher teacher = new Teacher();
        teacher.setName("riemann");
        teacher.setAge(28);

        Student student1 = new Student();
        student1.setName("edgar");
        student1.setAge(18);
        student1.setTeacher(teacher);

        Student student2 = (Student) student1.clone();
        System.out.println("-------------拷贝后-------------");
        System.out.println(student2.getName());
        System.out.println(student2.getAge());
        System.out.println(student2.getTeacher().getName());
        System.out.println(student2.getTeacher().getAge());

        System.out.println("-------------修改老师的信息后-------------");
        // 修改老师的信息
        teacher.setName("jack");
        System.out.println("student1的teacher为： " + student1.getTeacher().getName());
        System.out.println("student2的teacher为： " + student2.getTeacher().getName());

    }
}

class Teacher implements Cloneable {
    private String name;
    private int age;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}

class Student implements Cloneable {
    private String name;
    private int age;
    private Teacher teacher;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public Teacher getTeacher() {
        return teacher;
    }

    public void setTeacher(Teacher teacher) {
        this.teacher = teacher;
    }

    public Object clone() throws CloneNotSupportedException {
        Object object = super.clone();
        return object;
    }
}
```

输出结果：

```java
-------------拷贝后-------------
edgar
18
riemann
28
-------------修改老师的信息后-------------
student1的teacher为： jack
student2的teacher为： jack

```

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043243-20200830152336282.png)

结果分析： 两个引用`student1`和`student2`指向不同的两个对象，但是两个引用`student1`和`student2`中的两个`teacher`**引用指向的是同一个对象**，所以说明是`浅拷贝`。

## 三、深拷贝

### 3.1 深拷贝介绍

通过上面的例子可以看到，浅拷贝会带来数据安全方面的隐患，例如我们只是想修改了 `student1` 的 `teacher`，但是 `student2` 的 `teacher` 也被修改了，因为它们都是指向的同一个地址。所以，此种情况下，我们需要用到深拷贝。

> 深拷贝，在拷贝引用类型成员变量时，为引用类型的数据成员另辟了一个独立的内存空间，实现真正内容上的拷贝。

### 3.2 深拷贝特点

对于基本数据类型的成员对象，因为基础数据类型是值传递的，所以是直接将属性值赋值给新的对象。基础类型的拷贝，其中一个对象修改该值，不会影响另外一个（和浅拷贝一样）。

对于引用类型，比如数组或者类对象，深拷贝会新建一个对象空间，然后拷贝里面的内容，所以它们指向了不同的内存空间。改变其中一个，不会对另外一个也产生影响。

对于有多层对象的，每个对象都需要实现 `Cloneable` 并重写 `clone()` 方法，进而实现了对象的串行层层拷贝。

深拷贝相比于浅拷贝速度较慢并且花销较大。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043246-8878793-858c3f7c993e4348.webp)

### 3.3 深拷贝实例

```java
public class DeepCopy {
    public static void main(String[] args) throws CloneNotSupportedException {
        Teacher teacher = new Teacher();
        teacher.setName("riemann");
        teacher.setAge(28);

        Student student1 = new Student();
        student1.setName("edgar");
        student1.setAge(18);
        student1.setTeacher(teacher);

        Student student2 = (Student) student1.clone();
        System.out.println("-------------拷贝后-------------");
        System.out.println(student2.getName());
        System.out.println(student2.getAge());
        System.out.println(student2.getTeacher().getName());
        System.out.println(student2.getTeacher().getAge());

        System.out.println("-------------修改老师的信息后-------------");
        // 修改老师的信息
        teacher.setName("jack");
        System.out.println("student1的teacher为： " + student1.getTeacher().getName());
        System.out.println("student2的teacher为： " + student2.getTeacher().getName());
    }
}

class Teacher implements Cloneable {
    private String name;
    private int age;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public Object clone() throws CloneNotSupportedException {
        return super.clone();
    }
}

class Student implements Cloneable {
    private String name;
    private int age;
    private Teacher teacher;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }

    public Teacher getTeacher() {
        return teacher;
    }

    public void setTeacher(Teacher teacher) {
        this.teacher = teacher;
    }

    public Object clone() throws CloneNotSupportedException {
        // 浅复制时：
        // Object object = super.clone();
        // return object;

        // 改为深复制：
        Student student = (Student) super.clone();
        // 本来是浅复制，现在将Teacher对象复制一份并重新set进来
        student.setTeacher((Teacher) student.getTeacher().clone());
        return student;

    }
}
```

**输出结果：**

```java
-------------拷贝后-------------
edgar
18
riemann
28
-------------修改老师的信息后-------------
student1的teacher为： jack
student2的teacher为： riemann

```

**结果分析：**
两个引用`student1`和`student2`指向不同的两个对象，两个引用`student1`和`student2`中的两个`teacher`引用指向的是两个对象，但对`teacher`对象的修改只能影响`student1`对象,所以说是`深拷贝`。

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043251-20200830152450179.png)

