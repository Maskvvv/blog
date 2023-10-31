# jps（虚拟机进程状况工具）

JDK 的很多小工具的名字都参考了UNIX命令的命名方式，jps（JVM Process Status Tool）是其中 的典型。除了名字像UNIX的ps命令之外，它的功能也和ps命令类似：可以列出正在运行的虚拟机进 程，并显示虚拟机执行主类（Main Class，main()函数所在的类）名称以及这些进程的本地虚拟机唯一 ID（LVMID，Local Virtual Machine Identifier）。虽然功能比较单一，但它绝对是使用频率最高的JDK 命令行工具，因为其他的JDK工具大多需要输入它查询到的LVMID来确定要监控的是哪一个虚拟机进 程。对于本地虚拟机进程来说，LVMID与操作系统的进程ID（PID，Process Identifier）是一致的，使 用Windows的任务管理器或者UNIX的ps命令也可以查询到虚拟机进程的LVMID，但如果同时启动了 多个虚拟机进程，无法根据进程名称定位时，那就必须依赖jps命令显示主类的功能才能区分了。

**命令格式：**

```shell
jps [ options ] [ hostid ]
```

**主要选项：**

![](http://qiniu.zhouhongyin.top/2023/10/14/1697270633-image-20231014160353867.png)

> jps还可以通过RMI协议查询开启了RMI服务的远程虚拟机进程状态，参数hostid为RMI注册表中 注册的主机名。

**执行样例：**

```shell
jps -v -l
15805 java_study-1.0-SNAPSHOT-exec.jar -Dserver.port=9000
```

# jstat（虚拟机统计信息监视工具）

jstat（JVM Statistics Monitoring Tool）是用于监视虚拟机各种运行状态信息的命令行工具。它可以显示本地或者远程虚拟机进程中的类加载、内存、垃圾收集、即时编译等运行时数据，在没有 GUI图形界面、只提供了纯文本控制台环境的服务器上，它将是运行期定位虚拟机性能问题的常用工具。

**命令格式：**

```shell
jstat [ option vmid [interval[s|ms] [count]] ]
```

- 对于命令格式中的 VMID 与 LVMID 需要特别说明一下：如果是本地虚拟机进程，VMID 与 LVMID 是一致的；如果是远程虚拟机进程，那 VMID 的格式应当是：`[protocol:][//]lvmid[@hostname[:port]/servername]`
- 参数 interval 和count 代表查询间隔和次数，如果省略这 2 个参数，说明只查询一次。假设需要每 250 毫秒查询一次进程 2764 垃圾收集状况，一共查询20次，那命令应当是：`stat -gc 2764 250 20`

**主要选项：**

选项 option 代表用户希望查询的虚拟机信息，主要分为三类：类加载、垃圾收集、运行期编译状况。

![](http://qiniu.zhouhongyin.top/2023/10/14/1697271541-image-20231014161901560.png)

**执行样例：**

```
jstat -gcutil 2764
S0 S1 E O P YGC YGCT FGC FGCT GCT
0.00 0.00 6.20 41.42 47.20 16 0.105 3 0.472 0.577
```

查询结果表明：这台服务器的新生代 Eden 区（E，表示Eden）使用了 6.2% 的空间，2 个 Survivor 区 （S0、S1，表示 Survivor0、Survivor1）里面都是空的，老年代（O，表示 Old）和永久代（P，表示 Permanent）则分别使用了 41.42% 和 47.20% 的空间。程序运行以来共发生 Minor GC（YGC，表示Young GC）16 次，总耗时 0.105 秒；发生 Full GC（FGC，表示 Full GC）3次，总耗时（FGCT，表示Full GC Time）为 0.472 秒；所有 GC 总耗时（GCT，表示 GC Time）为 0.577 秒。 

使用 jstat 工具在纯文本状态下监视虚拟机状态的变化，在用户体验上也许不如后文将会提到的 JMC、VisualVM 等可视化的监视工具直接以图表展现那样直观，但在实际生产环境中不一定可以使用 图形界面，而且多数服务器管理员也都已经习惯了在文本控制台工作，直接在控制台中使用 jstat 命令 依然是一种常用的监控方式。

# jinfo（Java配置信息工具）

jinfo（Configuration Info for Java）的作用是实时查看和调整虚拟机各项参数。使用 jps 命令的 `-v` 参数可以查看虚拟机启动时显式指定的参数列表，但如果想知道未被显式指定的参数的系统默认值，除 了去找资料外，就只能使用 jinfo 的 `-flag` 选项进行查询了（如果只限于JDK 6或以上版本的话，使用 java `-XX:+PrintFlagsFinal` 查看参数默认值也是一个很好的选择）。jinfo 还可以使用 `-sysprops` 选项把虚拟机进程的 `System.getProperties()` 的内容打印出来。这个命令在 JDK 5时期已经随着 Linux 版的 JDK 发布，当时只提供了信息查询的功能，JDK 6之后，jinfo 在 Windows 和Linux 平台都有提供，并且加入了在运行期 修改部分参数值的能力（可以使用 `-flag[+|-]name` 或者 `-flag name=value` 在运行期修改一部分运行期可写的虚拟机参数值）。在 JDK 6中，jinfo 对于Windows 平台功能仍然有较大限制，只提供了最基本的 `-flag` 选 项。

**命令格式：**

```shell
jinfo [ option ] pid
```

**执行样例：**

查询 CMSInitiatingOccupancyFraction 参数值

```shell
info -flag CMSInitiatingOccupancyFraction 15805
-XX:CMSInitiatingOccupancyFraction=-1
```

# jmap（Java内存映像工具）

jmap（Memory Map for Java）命令用于生成堆转储快照（一般称为 heapdump 或 dump 文件）。如果不使用 jmap 命令，要想获取 Java 堆转储快照也还有一些比较“暴力”的手段：譬如在第 2 章中用过的 `-XX:+HeapDumpOnOutOfMemoryError` 参数，可以让虚拟机在内存溢出异常出现之后自动生成堆转储 快照文件，通过 `-XX:+HeapDumpOnCtrlBreak` 参数则可以使用 `[Ctrl]+[Break]` 键让虚拟机生成堆转储快照文件，又或者在 Linux 系统下通过 `Kill -3` 命令发送进程退出信号“恐吓”一下虚拟机，也能顺利拿到堆转储快照。

jmap 的作用并不仅仅是为了获取堆转储快照，它还可以查询 finalize 执行队列、Java 堆和方法区的 详细信息，如空间使用率、当前用的是哪种收集器等。

和 jinfo 命令一样，jmap 有部分功能在 Windows 平台下是受限的，除了生成堆转储快照的 `-dump` 选项 和用于查看每个类的实例、空间占用统计的 `-histo` 选项在所有操作系统中都可以使用之外，其余选项都 只能在 Linux/Solaris 中使用。

**命令格式：**

```shell
jmap [ option ] vmid
```

**主要选项：**

![](http://qiniu.zhouhongyin.top/2023/10/14/1697274132-image-20231014170212120.png)

**执行样例：**

```shell
jmap -dump:live,format=b,file=heap.bin 15805
Dumping heap to /root/app/heap.bin ...
Heap dump file created
```

```shell
jmap -heap 15805
Attaching to process ID 15805, please wait...
Debugger attached successfully.
Server compiler detected.
JVM version is 25.361-b09

using thread-local object allocation.
Mark Sweep Compact GC

Heap Configuration:
   MinHeapFreeRatio         = 40
   MaxHeapFreeRatio         = 70
   MaxHeapSize              = 482344960 (460.0MB)
   NewSize                  = 10485760 (10.0MB)
   MaxNewSize               = 160759808 (153.3125MB)
   OldSize                  = 20971520 (20.0MB)
   NewRatio                 = 2
   SurvivorRatio            = 8
   MetaspaceSize            = 21807104 (20.796875MB)
   CompressedClassSpaceSize = 1073741824 (1024.0MB)
   MaxMetaspaceSize         = 17592186044415 MB
   G1HeapRegionSize         = 0 (0.0MB)

Heap Usage:
New Generation (Eden + 1 Survivor Space):
   capacity = 22544384 (21.5MB)
   used     = 10202128 (9.729507446289062MB)
   free     = 12342256 (11.770492553710938MB)
   45.25352300599564% used
Eden Space:
   capacity = 20054016 (19.125MB)
   used     = 9521600 (9.08050537109375MB)
   free     = 10532416 (10.04449462890625MB)
   47.47976664624183% used
From Space:
   capacity = 2490368 (2.375MB)
   used     = 680528 (0.6490020751953125MB)
   free     = 1809840 (1.7259979248046875MB)
   27.32640316611842% used
To Space:
   capacity = 2490368 (2.375MB)
   used     = 0 (0.0MB)
   free     = 2490368 (2.375MB)
   0.0% used
tenured generation:
   capacity = 49950720 (47.63671875MB)
   used     = 46387784 (44.23883819580078MB)
   free     = 3562936 (3.3978805541992188MB)
   92.86709781160312% used

27688 interned Strings occupying 2546352 bytes.
```

```shell
jmap -histo 15805 | grep zhy
1075:             5            160  com.zhy.spring.di.TestStrategyEunm
1236:             5            120  com.zhy.middleware.es.spring.RestClientConfig$$EnhancerBySpringCGLIB$$7986e6cf$$FastClassBySpringCGLIB$$9f7b715f
1237:             5            120  com.zhy.middleware.rabbitmq.RabbitMQConfig$$EnhancerBySpringCGLIB$$ef627865$$FastClassBySpringCGLIB$$8172b352
1238:             5            120 
```

# jhat（虚拟机堆转储快照分析工具）

JDK 提供 jhat（JVM Heap Analysis Tool）命令与 jmap 搭配使用，来分析 jmap 生成的堆转储快照。 jhat 内置了一个微型的 HTTP/Web 服务器，生成堆转储快照的分析结果后，可以在浏览器中查看。不过 实事求是地说，在实际工作中，除非手上真的没有别的工具可用，否则多数人是不会直接使用jhat 命令 来分析堆转储快照文件的，主要原因有两个方面。一是一般不会在部署应用程序的服务器上直接分析 堆转储快照，即使可以这样做，也会尽量将堆转储快照文件复制到其他机器上进行分析，因为分析 工作是一个耗时而且极为耗费硬件资源的过程，既然都要在其他机器上进行，就没有必要再受命令行 工具的限制了。另外一个原因是 jhat 的分析功能相对来说比较简陋，后文将会介绍到的VisualVM，以 及专业用于分析堆转储快照文件的 Eclipse Memory Analyzer、IBM HeapAnalyzer 等工具，都能实现比 jhat 更强大专业的分析功能。

**命令格式：**

```shell
jhat file
```

**执行样例：**

```shell
jhat heap.bin
Reading from heap.bin...
Dump file created Sat Oct 14 16:55:35 CST 2023
Snapshot read, resolving...
Resolving 740539 objects...
Chasing references, expect 148 dots....................................................................................................................................................
Eliminating duplicate references....................................................................................................................................................
Snapshot resolved.
Started HTTP server on port 7000
Server is ready.
```

`http://localhost:7000/`

![](http://qiniu.zhouhongyin.top/2023/10/14/1697275553-image-20231014172552956.png)

分析结果默认以包为单位进行分组显示，分析内存泄漏问题主要会使用到其中的“Heap Histogram”（与jmap-histo功能一样）与 OQL 页签的功能，前者可以找到内存中总容量最大的对象，后 者是标准的对象查询语言，使用类似 SQL 的语法对内存中的对象进行查询统计。

# jstack（Java堆栈跟踪工具）

jstack（Stack Trace for Java）命令用于生成虚拟机当前时刻的线程快照（一般称为 threaddump 或者 javacore文件）。线程快照就是当前虚拟机内每一条线程正在执行的方法堆栈的集合，生成线程快照的 目的通常是定位线程出现长时间停顿的原因，如线程间死锁、死循环、请求外部资源导致的长时间挂起等，都是导致线程长时间停顿的常见原因。线程出现停顿时通过 jstack 来查看各个线程的调用堆栈， 就可以获知没有响应的线程到底在后台做些什么事情，或者等待着什么资源。

**命令格式：**

```shell
jstack [ option ] vmid
```

**主要选项：**

![](http://qiniu.zhouhongyin.top/2023/10/14/1697275919-image-20231014173159505.png)

**执行样例：**

```shell
jstack 15805
2023-10-14 17:34:35
Full thread dump Java HotSpot(TM) 64-Bit Server VM (25.361-b09 mixed mode):

"Attach Listener" #35 daemon prio=9 os_prio=0 tid=0x00007fbde4005000 nid=0x53aa waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"DestroyJavaVM" #34 prio=5 os_prio=0 tid=0x00007fbe14009800 nid=0x3dbe waiting on condition [0x0000000000000000]
   java.lang.Thread.State: RUNNABLE

"http-nio-9000-Acceptor" #33 daemon prio=5 os_prio=0 tid=0x00007fbe14333000 nid=0x3e59 runnable [0x00007fbddbdfc000]
   java.lang.Thread.State: RUNNABLE
        at sun.nio.ch.ServerSocketChannelImpl.accept0(Native Method)
        at sun.nio.ch.ServerSocketChannelImpl.accept(ServerSocketChannelImpl.java:424)
        at sun.nio.ch.ServerSocketChannelImpl.accept(ServerSocketChannelImpl.java:252)
        - locked <0x00000000eed4a2a0> (a java.lang.Object)
        at org.apache.tomcat.util.net.NioEndpoint.serverSocketAccept(NioEndpoint.java:574)
        at org.apache.tomcat.util.net.NioEndpoint.serverSocketAccept(NioEndpoint.java:80)
        at org.apache.tomcat.util.net.Acceptor.run(Acceptor.java:106)
        at java.lang.Thread.run(Thread.java:750)
```

> 从JDK 5起，java.lang.Thread类新增了一个getAllStackTraces()方法用于获取虚拟机中所有线程的 StackTraceElement对象。使用这个方法可以通过简单的几行代码完成jstack的大部分功能，在实际项目 中不妨调用这个方法做个管理员页面，可以随时使用浏览器来查看线程堆栈：
>
> ```jsp
> <%@ page import="java.util.Map"%>
> <html>
> <head>
>     <title>服务器线程信息</title>
> </head>
> <body>
>     <pre>
>         <%
>         for (Map.Entry<Thread, StackTraceElement[]> stackTrace : Thread.getAllStack-Traces().entrySet()) {
>             Thread thread = (Thread) stackTrace.getKey();
>             StackTraceElement[] stack = (StackTraceElement[]) stackTrace.getValue();
>             if (thread.equals(Thread.currentThread())) {
>                 continue;
>             }
>             out.print("\n线程：" + thread.getName() + "\n");
>             for (StackTraceElement element : stack) {
>                 out.print("\t"+element+"\n");
>             }
>         }
>         %>
>     </pre>
> </body>
> </html>
> ```

# 基础工具总结

**基础工具：**用于支持基本的程序创建和运行

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276548-image-20231014174228293.png)

**安全：**用于程序签名、设置安全测试等

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276571-image-20231014174251286.png)

**国际化：**用于创建本地语言文件

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276587-image-20231014174307391.png)

**远程方法调用：**用于跨Web或网络的服务交互

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276623-image-20231014174343861.png)

**Java IDL与RMI-IIOP：**在JDK 11中结束了十余年的CORBA支持，这些工具不再提供

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276661-image-20231014174420975.png)

**部署工具：**用于程序打包、发布和部署

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276680-image-20231014174440774.png)

**Java Web Start**

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276698-image-20231014174458780.png)

**性能监控和故障处理工具**

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276768-image-20231014174608583.png)

**WebService工具：**与CORBA一起在JDK 11中被移除

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276793-image-20231014174633388.png)

**REPL 和脚本工具**

![](http://qiniu.zhouhongyin.top/2023/10/14/1697276814-image-20231014174654275.png)