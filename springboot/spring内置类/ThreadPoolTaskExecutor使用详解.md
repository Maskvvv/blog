---
title: ThreadPoolTaskExecutor 使用详解
date: 2021-8-3
tags:
  - spring
  - spring 内置类
  - ThreadPoolTaskExecutor
  - ThreadPoolTaskExecutor 使用详解
categories:
  - spring
  - spring 内置类
  - ThreadPoolTaskExecutor 使用详解
---

![](http://qiniu.zhouhongyin.top/download.png)

<!-- more -->

当我们需要实现并发、异步等操作时，通常都会使用到`ThreadPoolTaskExecutor`。

# 一、配置

## 1.1 将 ThreadPoolTaskExecutor 注入到 spring 容器内

```java
@Configuration
public class ThreadTaskPoolExecutorConfiguration {
    @Bean
    public ThreadPoolTaskExecutor threadPoolTaskExecutor(){
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        // 核心线程数
        taskExecutor.setCorePoolSize(5);
        // 最大线程数
        taskExecutor.setMaxPoolSize(15);
        // 队列大小 默认使用LinkedBlockingQueue
        taskExecutor.setQueueCapacity(100);
        // 线程最大空闲时间
        taskExecutor.setKeepAliveSeconds(300);
        // 拒绝策略 默认new ThreadPoolExecutor.AbortPolicy()
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        // 线程名称前缀
        taskExecutor.setThreadNamePrefix("My-Task-Executor-");
        //交给spring托管的会自动初始化，因为实现了InitializingBean接口
        // taskExecutor.initialize();
        return taskExecutor;
    }
}
```

## 1.2 拒绝策略配置

**`rejectedExecutionHandler` 字段用于配置拒绝策略，常用的拒绝策略如下：**

- `AbortPolicy`：用于被拒绝任务的处理程序，它将抛出 `RejectedExecutionException`。
- `CallerRunsPolicy`：用于被拒绝任务的处理程序，它直接在 execute 方法的调用线程中运行被拒绝的任务。
- `DiscardOldestPolicy`：用于被拒绝任务的处理程序，它放弃最旧的未处理请求，然后重试 execute。
- `DiscardPolicy`：用于被拒绝任务的处理程序，默认情况下它将丢弃被拒绝的任务。

> **其他说明：**
>
> 1. 为了实现某些特殊的业务需求，用户可以选择使用自定义策略，只需实现`RejectedExecutionHandler`接口即可。
> 2. 建议配置`threadNamePrefix`属性，出问题时可以更方便的进行排查。

## 1.3 配置线程池个数

- 如果是 **CPU 密集型任务**，那么线程池的线程个数应该尽量少一些，一般为 **CPU 的个数+1条线程**。
- 如果是 **IO 密集型任务**，那么线程池的线程可以放的很大，如 **2*CPU 的个数**。
- 对于**混合型任务**，如果可以拆分的话，通过拆分成 CPU 密集型和 IO 密集型两种来提高执行效率；如果不能拆分的的话就可以根据实际情况来调整线程池中线程的个数

# 二、处理流程

1. 当一个任务被提交到线程池时，首先查看线程池的核心线程是否都在执行任务，否就选择一条线程执行任务，是就执行第二步。
2. 查看核心线程池是否已满，不满就创建一条线程执行任务，否则执行第三步。
3. 查看任务队列是否已满，不满就将任务存储在任务队列中，否则执行第四步。
4. 查看线程池是否已满，不满就创建一条线程执行任务，否则就按照策略处理无法执行的任务。

**在 `ThreadPoolExecutor` 中表现为:**

- 如果当前运行的线程数小于corePoolSize，那么就创建线程来执行任务（执行时需要获取全局锁）。
- 如果运行的线程大于或等于corePoolSize，那么就把task加入BlockQueue。
- 如果创建的线程数量大于BlockQueue的最大容量，那么创建新线程来执行该任务。
- 如果创建线程导致当前运行的线程数超过maximumPoolSize，就根据饱和策略来拒绝该任务。

# 三、关闭线程池

调用shutdown或者shutdownNow，两者都不会接受新的任务，而且通过调用要停止线程的interrupt方法来中断线程，有可能线程永远不会被中断，不同之处在于shutdownNow会首先将线程池的状态设置为STOP，然后尝试停止所有线程（有可能导致部分任务没有执行完）然后返回未执行任务的列表。而shutdown则只是将线程池的状态设置为shutdown，然后中断所有没有执行任务的线程，并将剩余的任务执行完。

# 四、监控线程池状态

常用状态：

- taskCount：线程需要执行的任务个数。
- completedTaskCount：线程池在运行过程中已完成的任务数。
- largestPoolSize：线程池曾经创建过的最大线程数量。
- getPoolSize获取当前线程池的线程数量。
- getActiveCount：获取活动的线程的数量

通过继承线程池，重写beforeExecute，afterExecute 和 terminated 方法来在线程执行任务前，线程执行任务结束，和线程终结前获取线程的运行情况，根据具体情况调整线程池的线程数量。

# 五、实战

```java
@RunWith(SpringRunner.class)
@SpringBootTest(classes = TestApplication.class)
public class TestApplicationTests {

    // 注入ThreadPoolTaskExecutor
    @Resource
    private ThreadPoolTaskExecutor threadPoolTaskExecutor;

    @Test
    public void ThreadTest(){
        System.out.println(threadPoolTaskExecutor);

        System.out.println("new Runnable()");
        // 创建并执行线程，方式一
        threadPoolTaskExecutor.execute(new Runnable() {
            @Override
            public void run() {
                for (int i = 0; i < 100; i++) {
                    System.out.println("new Runnable()"+i+"当前线程"+Thread.currentThread().getName());
                }
            }
        });

        // // 创建并执行线程，方式二
        System.out.println("lambda");
        threadPoolTaskExecutor.execute(() -> {
            for (int i = 0; i < 100; i++) {
                System.out.println("lambda"+i+"当前线程"+Thread.currentThread().getName());
            }
        });
    }
}
```

**运行截图：**

![](http://qiniu.zhouhongyin.top/image-20210803185821400.png)

> **用lambda表达式实现Runnable**
>
> 我开始使用Java 8时，首先做的就是使用lambda表达式替换匿名类，而实现Runnable接口是匿名类的最好示例。看一下Java 8之前的runnable实现方法，需要4行代码，而使用lambda表达式只需要一行代码。我们在这里做了什么呢？那就是用() -> {}代码块替代了整个匿名类。
>
> ```java
> // Java 8之前：
> new Thread(new Runnable() {
>     @Override
>     public void run() {
>     System.out.println("Before Java8, too much code for too little to do");
>     }
> }).start();
> 
> //Java 8方式：
> new Thread( () -> System.out.println("In Java8, Lambda expression rocks !!") ).start();
> ```

