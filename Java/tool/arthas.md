# 引言

Arthas 是一款线上监控诊断产品，通过全局视角实时查看应用 load、内存、gc、线程的状态信息，并能在不修改应用代码的情况下，对业务问题进行诊断，包括查看方法调用的出入参、异常，监测方法执行耗时，类加载信息等，大大提升线上问题排查效率。

> Arthas 是基于 **ASM** 和 **Java Agent** 技术实现的 Java 诊断利器。
>
> -  **ASM** 是指一个 Java 字节码操作框架，用于动态生成或者增强 class。
> -  **采用 Attach API 方式的 Java Agent** 是指在 JVM 启动后通过 Attach API 执行 agentmian 方法，利用 **Instrumentation API** 的 debug 和 profiler 能力。

# 安装

```shell
// 下载
curl -O https://arthas.aliyun.com/arthas-boot.jar

// 启动
java -jar arthas-boot.jar
```

# dashboard

![img](http://qiniu.zhouhongyin.top/2023/02/17/1676600461-dashboard.png)

# thread

|      参数名称 | 参数说明                                                |
| ------------: | :------------------------------------------------------ |
|          *id* | 线程 id                                                 |
|          [n:] | 指定最忙的前 N 个线程并打印堆栈                         |
|           [b] | 找出当前阻塞其他线程的线程                              |
| [i `<value>`] | 指定 cpu 使用率统计的采样间隔，单位为毫秒，默认值为 200 |
|       [--all] | 显示所有匹配的线程                                      |

# memory

查看 JVM 内存信息。

```shell
$ memory
Memory                           used      total      max        usage
heap                             32M       256M       4096M      0.79%
g1_eden_space                    11M       68M        -1         16.18%
g1_old_gen                       17M       184M       4096M      0.43%
g1_survivor_space                4M        4M         -1         100.00%
nonheap                          35M       39M        -1         89.55%
codeheap_'non-nmethods'          1M        2M         5M         20.53%
metaspace                        26M       27M        -1         96.88%
codeheap_'profiled_nmethods'     4M        4M         117M       3.57%
compressed_class_space           2M        3M         1024M      0.29%
codeheap_'non-profiled_nmethods' 685K      2496K      120032K    0.57%
mapped                           0K        0K         -          0.00%
direct                           48M       48M        -          100.00%

```

# heapdump

dump java heap, 类似 jmap 命令的 heap dump 功能。

```shell
heapdump /tmp/dump.hprof

heapdump --live /tmp/dump.hprof
```

# jad

反编译指定已加载类的源码

`jad` 命令将 JVM 中实际运行的 class 的 byte code 反编译成 java 代码，便于你理解业务逻辑；

|              参数名称 | 参数说明                                   |
| --------------------: | :----------------------------------------- |
|       *class-pattern* | 类名表达式匹配                             |
|                `[c:]` | 类所属 ClassLoader 的 hashcode             |
| `[classLoaderClass:]` | 指定执行表达式的 ClassLoader 的 class name |
|                   [E] | 开启正则表达式匹配，默认为通配符匹配       |

```shell
jad --source-only com.zhy.other.arthas.HeapDumpDemo 

jad --source-only com.zhy.other.arthas.HeapDumpDemo main
```

# stack

```shell
stack com.zhy.other.arthas.ArthasStackController test  -n 5 
```

# trace

方法内部调用路径，并输出方法路径上的每个节点上耗时

```shell
trace com.zhy.other.arthas.ArthasTraceController test  -n 5 --skipJDKMethod false 
```

# tt

方法执行数据的时空隧道，记录下指定方法每次调用的入参和返回信息，并能对这些不同的时间下调用进行观测

```shell
tt -t com.zhy.other.arthas.ArthasWatchController test -n 5 

tt -l

tt -p -i 1000
```

# watch

让你能方便的观察到指定函数的调用情况。能观察到的范围为：`返回值`、`抛出异常`、`入参`，通过编写 OGNL 表达式进行对应变量的查看。

```shell
watch com.zhy.other.arthas.ArthasWatchController test '{params,returnObj,throwExp}'  -n 5  -x 3 
```

# reset

重置增强类，将被 Arthas 增强过的类全部还原，Arthas 服务端`stop`时会重置所有增强过的类

# quit

退出当前 Arthas 客户端，其他 Arthas 客户端不受影响。等同于**exit**、**logout**、**q**三个指令。

# stop

关闭 Arthas 服务端，所有 Arthas 客户端全部退出。