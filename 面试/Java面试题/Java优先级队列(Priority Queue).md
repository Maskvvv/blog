---
title: Java优先级队列(Priority Queue)
date: 2021-6-13
updated: 2021-6-13
tags:
  - Java
  - Priority Queue
categories:
  - 面试
  - Java优先级队列(Priority Queue)
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043388-1_iIXOmGDzrtTJmdwbn7cGMw.png)

<!--more-->

## 一、优先级队列的定义

优先级队列是逻辑结构是小根堆，存储结构是动态数组（到达上限，容量自动加一）的集合类。

## 二、优先级队列的特点

- 优先级队列里的元素**必须有优先级**！！！优先级是前后排序的“规则”，也就是说插入队列的类**必须实现内部比较器或拥有外部比较器**（在构造函数中当参数）！！！！
- 优先级队列的**拥有小根堆的所有特性**。
- 优先级队列**不是线程安全的**。
- 优先级队列**不允许使用null元素**。
- 优先级队列本身并不是一个有序（从a[0]-a[n]全部升序）序列，只有当你把元素一个个取出的时候，这些取出的元素所排成的序列才是有序序列。原因很简单，优先级队列是一个小根堆，也就是只能保证根节点（a[0]）是最小的，其余元素的顺序不能保证（当然，其他元素必须遵守小根堆的特性），当我们取出元素（poll）时，我们只能取出根节点的元素，然后把堆的最后一个元素剪切到根节点（这种取出方式是底层算法规定的，充分利用了堆的特性），然后对所有剩余元素进行建堆，建堆之后根节点元素还是最小的（初始堆中的第二小）。由此特点，我们可以引出另外两个知识点：
  - ① 优先级队列的迭代器遍历出来的数组是没有排序的，只是个小根堆。
  - ② 如果我们想得到有序的堆，需要把堆先转为数组，然后arrays.sort(queue.toarray)，arrays.sort(queue.toarray，comparator对象)或者其他sort方法。
- 优先级队列（堆）中的插入就只能插到最后，也就是说添加和插入一个意思；删除也只能删第一个。

> 注：每个元素的优先级根据问题的要求而定。当从优先级队列中取出一个元素后，可能出现多个元素具有相同的优先权。在这种情况下，把这些具有相同优先权的元素视为一个先来先服务的队列，按他们的入队顺序进行先后处理。

## 三、常用方法

**添加（插入）：**

`public boolean add(E e)`

**查看（只返回根节点元素，不删除）：**

`public E peek()`

**取出（返回根节点元素，会删除源数据）：**

`public E poll()`

**删除（如果有多个相同元素，只会删除第一个）:**

`public boolean remove(Object o)`

还有就是一些 collection 类通有的方法，不多说了记住！！！所有会破坏堆的特性的方法（比如插入删除等）的源码里最后都会加一个建堆方法（ **siftUp(i, e)**，也可以说交换方法，调整方法），使队列保持堆的特性


## Priority Queue应用实例

Priority Queue 这种数据结构支持按照优先级取出里面的元素。这是和其它常用数据结构，比如 ArrayList, Queue, Stack等最大的区别。因为要支持优先级，而 heap 具有类似的结构，所以，Priority Queue一般都是基于HEAP实现的。（也可以用其它数据结构实现，但是各种复杂度会有不同。）

基于 HEAP 实现的 Priority Queue 复杂度分析：

- **add(E e)：** O(lg n)
- **poll()：**  O(lg n) (注意，取出元素只需要O(1), 但是维护HEAP结构需要 O(lg n))
- **remove(E e)：** O(n)

下面例子是用 Priority Queue 保存学生信息，学生类含有姓名和成绩，当把学生保存在 Priority Queue 里时，成绩最低的学生放在最前面。如果想把成绩最高的放在最前面，只要把 compare 方法改成 `return s2.grade - s1.grade;` 即可。

```java
import java.util.Comparator;
import java.util.PriorityQueue;
import java.util.Random;
public class PriorityQueueTutorial{
	public static void main(String args[]){
        // 创建 PriorityQueue 并实现 Comparator 比较器
		PriorityQueue<Student> queue = new PriorityQueue<Student>(11,
		        new Comparator<Student>() {
		          public int compare(Student s1, Student s2) {
		            return s1.grade - s2.grade;
		          }
		        });	    

        //向队列中添加元素
		for (int i = 1; i <= 100; i++) {
			queue.add(new Student("student" + i, (new Random().nextInt(1000))));
		}
        
        // 打印结果
		while (!queue.isEmpty()) {
		      System.out.println(queue.poll().toString());
	    }
	}
}
 /**
 * Student 实体类
 **/
class Student {	
	String name;
	int grade;
	public Student(String name, int grade)
	{
		this.name = name;
	    this.grade = grade;
	}
	public String toString() {
		return name + " " + grade;
	}
}
```

