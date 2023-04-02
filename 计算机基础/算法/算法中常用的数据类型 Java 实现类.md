---
title: 算法中常用的数据类型 Java 实现类
date: 2022-4-29
updated: 2022-4-29
tags:
  - 算法
  - LeetCode
  - Java
categories:
  - 算法
  - 数据结构
---

算法中常用的数据类型 Java 实现类

![leetcode](http://qiniu.zhouhongyin.top/2022/06/12/1655043610-leetcode.png)

<!--more-->

# 一、栈

## 1.1 Deque

### 1.1.1 ArrayDeque

```java
public void arrayStack() {
    Deque<Integer> stack = new ArrayDeque<>();
    // 入栈
    stack.push(1);
    stack.push(2);
    stack.push(3);
    stack.push(4);
    System.out.println(stack);

    // 出栈
    stack.pop();
    stack.remove();
    System.out.println(stack);

    // 获取栈顶元素
    System.out.println(stack.peek());
    System.out.println(stack.peekFirst());
}
```

```java
public void arrayStack1() {
    Deque<Integer> stack = new ArrayDeque<>();
    // 入栈
    stack.addFirst(1);
    stack.addFirst(2);
    stack.addFirst(3);
    stack.addFirst(4);
    System.out.println(stack);

    // 出栈
    stack.removeFirst();
    System.out.println(stack);

    // 获取栈顶元素
    System.out.println(stack.peek());
    System.out.println(stack.peekFirst());
}
```

```java
public void arrayStack2() {
    Deque<Integer> stack = new ArrayDeque<>();
    // 入栈
    stack.addLast(1);
    stack.addLast(2);
    stack.addLast(3);
    stack.addLast(4);
    System.out.println(stack);

    // 出栈
    stack.removeLast();
    System.out.println(stack);

    // 获取栈顶元素
    System.out.println(stack.peekLast());
}
```

### 1.1.2 LinkedList

```java
@Test
public void linkedStack() {
    Deque<Integer> stack = new LinkedList<>();
    // 入栈
    stack.push(1);
    stack.push(2);
    stack.push(3);
    stack.push(4);
    System.out.println(stack);

    // 出栈
    stack.pop();
    stack.remove();
    System.out.println(stack);

    // 获取栈顶元素
    System.out.println(stack.peek());
    System.out.println(stack.peekFirst());
}
```

### 1.1.3 Stack

```java
public void stack() {
    Stack<Integer> stack = new Stack<>();
    // 入栈
    stack.push(1);
    stack.push(2);
    stack.push(3);
    stack.push(4);
    System.out.println(stack);

    // 出栈
    stack.pop();
    System.out.println(stack);

    // 获取栈顶元素
    System.out.println(stack.peek());
}
```

# 二、队列

## 2.1 Deque

### 2.1.1 ArrayDeque

```java
public void arrayQueue() {
    Deque<Integer> queue = new ArrayDeque<>();
    // 入队
    queue.offer(1);
    queue.offer(2);
    queue.offer(3);
    queue.offer(4);
    System.out.println(queue);

    // 出队
    queue.poll();
    queue.remove();
    System.out.println(queue);

    // 获取队头元素
    System.out.println(queue.peek());
    System.out.println(queue.peekFirst());
}
```

### 2.1.2 LinkedList

```java
public void linkedQueue() {
    Deque<Integer> queue = new LinkedList<>();
    // 入队
    queue.offer(1);
    queue.offer(2);
    queue.offer(3);
    queue.offer(4);
    System.out.println(queue);

    // 出队
    queue.poll();
    queue.remove();
    System.out.println(queue);

    // 获取队头元素
    System.out.println(queue.peek());
    System.out.println(queue.peekFirst());
}
```

