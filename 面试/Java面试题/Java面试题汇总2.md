---
title: Java面试题（二）
date: 2021-6-12
updated: 2021-6-12
tags:
  - Java
  - JVM
categories:
  - 面试
  - Java面试题（二）
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042748-1_iIXOmGDzrtTJmdwbn7cGMw.png)

<!-- more -->

## 什么是迭代器(Iterator)？

**答案一：**

迭代器是一种设计模式，它是一个对象，它可以遍历并选择序列中的对象，而开发人员不需要了解该序列的底层结构。迭代器通常被称为“轻量级”对象，因为创建它的代价小。

Java 中的 Iterator 功能比较简单，并且只能单向移动：

1. 使用方法 iterator() 要求容器返回一个Iterator。第一次调用 Iterator 的 next() 方法时，它返回序列的第一个元素。注意：iterator() 方法是 java.lang.Iterable 接口，被 Collection 继承。 　　

2. 使用 next() 获得序列中的下一个元素。

3. 使用 hasNext() 检查序列中是否还有元素。

4. 使用 remove() 将迭代器新返回的元素删除。


Iterator 是 Java 迭代器最简单的实现，为 List 设计的 ListIterator 具有更多的功能，它可以从两个方向遍历List，也可以从 List 中插入和删除元素。

**例子：**

```java
public void main(String[] args) {
    List list = new ArrayList();
    Map map = new HashMap();

    for (int i = 0; i < 10; i++) {
        list.add(new String("list" + i));
        map.put(i, new String("map" + i));

    }
    Iterator iterList = list.iterator();//List接口实现了Iterable接口
    while (iterList.hasNext()) {
        String strList = (String) iterList.next();
        System.out.println(strList.toString());
    }

    Iterator iterMap = map.entrySet().iterator();
    while (iterMap.hasNext()) {
        Map.Entry strMap = (Map.Entry) iterMap.next();
        System.out.println(strMap.getValue());
    }
}
```

**答案二：**

Iterator 提供了统一遍历操作集合元素的统一接口， Collection 接口实现 Iterable 接口，每个集合都通过实现Iterable 接口中 iterator() 方法返回 Iterator 接口的实例，然后对集合的元素进行迭代操作，有一点需要注意的是：在迭代元素的时候不能通过集合的方法删除元素，否则会抛 `ConcurrentModificationException`异常，但是可以通过 Iterator 接口中的 remove() 方法进行删除。

- Iterable 接口
  - Iteratoriterator();
- Iterator 接口
  - boolean hasNext();
  - E next();
  - void remove();

> 迭代器模式（Iterator），提供一种方法顺序访问一个聚合对象中的各种元素，而又不暴露该对象的内部表示。
>
> 当你需要访问一个聚合对象，而且不管这些对象是什么都需要遍历的时候，就应该考虑使用迭代器模式。另外，当需要对聚集有多种方式遍历时，可以考虑去使用迭代器模式。迭代器模式为遍历不同的聚集结构提供如开始、下一个、是否结束、当前哪一项等统一的接口。

## Iterator 和 ListIterator 的区别是什么？

我们在使用 List 、Set 的时候，为了实现对其数据的遍历，我们经常使用到了 Iterator (迭代器)。

使用迭代器，你不需要干涉其遍历的过程，只需要每次取出一个你想要的数据进行处理就可以了。但是在使用的时候也是有不同的。 

List 和 Set 都有 iterator() 来取得其迭代器。对 List 来说，你也可以通过 listIterator() 取得其迭代器，两种迭代器在有些时候是不能通用的，Iterator 和 ListIterator 主要区别在以下方面： 

1. ListIterator 有 add() 方法，可以向 List 中添加对象，而 Iterator 不能 
2. Iterator 可用来遍历 Set 和 List 集合，但是 ListIterator 只能用来遍历 List。
3. ListIterator 和 Iterator 都有 hasNext() 和 next() 方法，可以实现顺序向后遍历，但是 ListIterator 有 hasPrevious() 和 previous() 方法，可以实现逆向（顺序向前）遍历。Iterator 就不可以。 
4. ListIterator 可以定位当前的索引位置，nextIndex() 和 previousIndex() 可以实现。 Iterator 没有此功能。 
5. 都可实现删除对象，但是 ListIterator 可以实现对象的修改，set() 方法可以实现。Iierator 仅能遍历，不能修改。 因为 ListIterator 的这些功能，可以实现对 LinkedList 等 List 数据结构的操作。 
    其实，数组对象也可以用迭代器来实现。org.apache.commons.collections.iterators.ArrayIterator 就可以实现此功能。

一般情况下，我们使用 Iterator 就可以了，如果你需要进行记录的前后反复检索的话，你就可以使用 ListIterator 来扩展你的功能，（有点象 JDBC 中的滚动结果集）。 

ListIterator 是一个双向迭代器。 ListIterator 没有当前元素，它的当前游标是位于调用 next() 和 previsous() 返回的元素之间。不过下面举的例子有点问题：下面的例子是n+1个元素。如果有n个元素，那么游标索引就是0...n共n+1个。 

注意：romove 和 set 方法不是针对当前游标的操作，而是针对最后一次的 next() 或者 previous() 调用

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042757-733131_1470636870149_A99B8AC1B2797AE567C4F897B8902D94.png)

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042759-733131_1470636931013_13A06D025548C29F6AAFF3CB2EE0CCCF.png)

## 快速失败(fail-fast)和安全失败(fail-safe)的区别是什么？

**一：快速失败（fail—fast）**

在用迭代器遍历一个集合对象时，如果遍历过程中对集合对象的结构进行了修改（增加、删除），则会抛出`Concurrent Modification Exception`。

原理：迭代器在遍历时直接访问集合中的内容，并且在遍历过程中使用一个 modCount 变量。集合在被遍历期间如果结构发生变化，就会改变 modCount 的值。每当迭代器使用 hashNext()/next() 遍历下一个元素之前，都会检测 modCount 变量是否为 expectedmodCount 值，是的话就返回遍历；否则抛出异常，终止遍历。

注意：这里异常的抛出条件是检测到 `modCount！= expectedmodCount` 这个条件。如果集合发生变化时修改 modCount 值刚好又设置为了 expectedmodCount 值，则异常不会抛出。因此，不能依赖于这个异常是否抛出而进行并发操作的编程，这个异常只建议用于检测并发修改的 bug。

场景：java.util 包下的集合类都是快速失败的，不能在多线程下发生并发修改（迭代过程中被修改）。

**二：安全失败（fail—safe）**

采用安全失败机制的集合容器，在遍历时不是直接在集合内容上访问的，而是先复制原有集合内容，在拷贝的集合上进行遍历。

原理：由于迭代时是对原集合的拷贝进行遍历，所以在遍历过程中对原集合所作的修改并不能被迭代器检测到，所以不会触发 `Concurrent Modification Exception`。

缺点：基于拷贝内容的优点是避免了`Concurrent Modification Exception`，但同样地，迭代器并不能访问到修改后的内容，即：迭代器遍历的是开始遍历那一刻拿到的集合拷贝，在遍历期间原集合发生的修改迭代器是不知道的。

场景：java.util.concurrent 包下的容器都是安全失败，可以在多线程下并发使用，并发修改。

> 快速失败补充：如果不修改集合对象的结构只修改内容是不会报异常的 比如修改一个键值对的值
>
> ```java
> HashMap<String, Integer> map = new HashMap<>();
> map.put("1",1);
> map.put("2",2);
> map.put("3",3);
> map.put("4",4);
> Iterator<Map.Entry<String, Integer>> iteratormmap = map.entrySet().iterator();
> System.out.println(map.toString());
> int i = 0;
> while(iteratormmap.hasNext())
> 
> {
>     if (++i == 1) {
>         System.out.println("执行修改");
>         map.put("1", 5);
>         //  map.put("5",5); //修改了结构 抛ConcurrentModificationException
>     }
>     System.out.println(iteratormmap.next());
> }
> System.out.println(map.toString());
> ```

## Java 中的 HashMap 的工作原理是什么？

hashmap 是一个 key-value 键值对的数据结构，从结构上来讲在 jdk1.8 之前是用数组加链表的方式实现，jdk1.8 加了红黑树，hashmap 数组的默认初始长度是16，hashmap 数组只允许一个 key 为 null，允许多个 value 为null。

hashmap 的内部实现，hashmap 是使用**数组+链表+红黑树**的形式实现的，其中数组是一个一个 Node[] 数组，我们叫他 hash 桶数组，它上面存放的是 key-value 键值对的节点。HashMap 是用 hash 表来存储的，在 hashmap 里为解决 hash 冲突，使用**链地址法**，简单来说就是数组加链表的形式来解决，当数据被 hash 后，得到数组下标，把数据放在对应下标的链表中。

 然后再说一下 hashmap 的方法实现

 put 方法，put 方法的第一步，就是计算出要 put 元素在 hash 桶数组中的索引位置，得到索引位置需要三步，去 put 元素 key 的 hashcode 值，高位运算，取模运算，高位运算就是用第一步得到的值 h，用 h 的高16位和低 16 位进行异或操作，第三步为了使 hash 桶数组元素分布更均匀，采用取模运算，取模运算就是用第二步得到的值和 hash 桶数组长度-1的值取与。这样得到的结果和传统取模运算结果一致，而且效率比取模运算高

 jdk1.8 中 put 方法的具体步骤，先判断 hashmap 是否为空，为空的话扩容，不为空计算出 key 的 hash 值 i，然后看 table[i] 是否为空，为空就直接插入，不为空判断当前位置的 key 和 table[i] 是否相同，相同就覆盖，不相同就查看 table[i] 是否是红黑树节点，如果是的话就用红黑树直接插入键值对，如果不是开始遍历链表插入，如果遇到重复值就覆盖，否则直接插入，如果链表长度大于8，转为红黑树结构，执行完成后看size是否大于阈值threshold，大于就扩容，否则直接结束
 get 方法就是计算出要获取元素的hash值，去对应位置取即可。

扩容机制，hashmap 的扩容中主要进行两部，第一步把数组长度变为原来的两倍，第二部把旧数组的元素重新计算 hash 插入到新数组中，在jdk1.8时，不用重新计算 hash，只用看看原来的 hash 值新增的一位是零还是1，如果是 1 这个元素在新数组中的位置，是原数组的位置加原数组长度，如果是零就插入到原数组中。扩容过程第二部一个非常重要的方法是 transfer 方法，采用头插法，把旧数组的元素插入到新数组中。

hashmap 大小为什么是2的幂次方
 在计算插入元素在 hash 桶数组的索引时第三步，为了使元素分布的更加均匀，用取模操作，但是传统取模操作效率低，然后优化成 h&(length-1) ，设置成 2 幂次方，是因为 2 的幂次方-1后的值每一位上都是1，然后与第二步计算出的 h 值与的时候，最终的结果只和 key 的 hashcode 值本身有关，这样不会造成空间浪费并且分布均匀。

 **如果length不为2的幂，比如15。那么length-1的2进制就会变成1110。在 h 为随机数的情况下，和 1110做&操作。尾数永远为0。那么0001、1001、1101等尾数为 1 的位置就永远不可能被 entry 占用。这样会造成浪费，不随机等问题。**

>   java8 对 hashmap 做了优化，底层有两种实现方法，一种是数组和链表，一种是数组和红黑树，hsahmap会根据数据量选择存储结构
>
>   if (binCount >= TREEIFY_THRESHOLD - 1)
>
>   当符合这个条件的时候，把链表变成treemap，这样查找效率从o(n)变成了o(log n)

## hashCode() 和 equals() 方法的重要性体现在什么地方？

hashcode 和 equals 组合在一起确定元素的唯一性。

查找元素时，如果单单使用 equals 来确定一个元素，需要对集合内的元素逐个调用 equals 方法，效率太低。因此加入了 hashcode 方法，将元素映射到随机的内存地址上，通过 hashcode 快速定位到元素（大致）所在的内存地址，再通过使用 equals 方法确定元素的精确位置。比较两个元素时，先比较 hashcode，如果 hashcode 不同，则元素一定不相等；如果相同，再用 equals 判断。

 HashMap 采用这两个方法实现散列存储，提高键的索引性能。HashSet 是基于HashMap 实现的。

**答案二：**

HashMap 的很多函数要基于 equal() 函数和 hashCode() 函数。hashCode() 用来定位要存放的位置，equal() 用来判断相等。 

那么，相等的概念是什么？
Object 版本的 equal 只是简单地判断是不是**同一个**实例。但是有的时候，我们想要的的是逻辑上的相等。比如有个学生类 student，有一个属性 studentID ，只要 studentID 相等，不是同一个实例我们也认为是同一学生。当我们认为判定 equals 的相等应该**是逻辑上的相等而不是只是判断是不是内存中的同一个东西的时候**，就需要重写equal()。**而涉及到 HashMap 的时候，重写了 equals()，就需要重写 hashCode()**

我们总结一下几条基本原则 ：

1. 同一个对象（没有发生过修改）无论何时调用 hashCode() 得到的返回值必须一样。 
   **如果一个 key 对象在 put 的时候调用 hashCode() 决定了存放的位置，而在 get 的时候调用 hashCode() 得到了不一样的返回值，这个值映射到了一个和原来不一样的地方，那么肯定就找不到原来那个键值对了。**   
2. hashCode() 的返回值相等的对象不一定相等，通过 hashCode() 和 equals() 必须能唯一确定一个对象 
   **不相等的对象的 hashCode() 的结果可以相等。hashCode() 在注意关注碰撞问题的时候，也要关注生成速度问题，完美 hash 不现实**    
3. 一旦重写了 equals() 函数（重写 equals 的时候还要注意要满足**自反性、对称性、传递性、一致性**），就必须重写 hashCode() 函数。而且 hashCode() 的生成哈希值的依据应该是 equals() 中用来比较是否相等的字段 
   **如果两个由 equals() 规定相等的对象生成的 hashCode 不等，对于 hashMap 来说，他们很可能分别映射到不同位置，没有调用 equals() 比较是否相等的机会，两个实际上相等的对象可能被插入不同位置，出现错误。其他一些基于哈希方法的集合类可能也会有这个问题**

## HashMap 和 Hashtable 有什么区别？

区别：

1. HashMap 是非线程安全的，HashTable 是线程安全的。 
2. HashMap 的键和值都允许有 null 值存在，而 HashTable 则不行。 
3. 因为线程安全的问题，HashMap 效率比 HashTable 的要高。 
4. Hashtable 是同步的，而 HashMap 不是。因此，HashMap 更适合于单线程环境，而 Hashtable 适合于多线程环境。

一般现在**不建议用 HashTable**,  ①是 HashTable 是遗留类，内部实现很多没优化和冗余。②即使在**多线程**环境下，现在也有同步的 **ConcurrentHashMap **替代，没有必要因为是多线程而用HashTable。

## 数组(Array)和列表(ArrayList)有什么区别？什么时候应该使用Array而不是ArrayList？

**答案一：**

ArrayList 可以算是 Array 的加强版。（对 array 有所取舍的加强）。   

**存储内容比较：**

- Array 数组可以包含基本类型和对象类型，        
- ArrayList 却只能包含对象类型。      

但是需要注意的是：Array 数组在存放的时候一定是同种类型的元素。ArrayList 就不一定了，因为 ArrayList 可以存储 Object。

**空间大小比较：**

- Array 它的空间大小是固定的，空间不够时也不能再次申请，所以需要事前确定合适的空间大小。
- ArrayList 的空间是动态增长的，如果空间不够，它会创建一个空间比原空间大一倍的新数组，然后将所有元素复制到新数组中，接着抛弃旧数组。而且，每次添加新的元素的时候都会检查内部数组的空间是否足够。（比较麻烦的地方）。            

**方法上的比较：**  

ArrayList 作为 Array 的增强版，当然是在方法上比 Array 更多样化，比如添加全部 addAll()、删除全部removeAll()、返回迭代器 iterator() 等。   

对于基本类型数据，集合使用自动装箱来减少编码工作量。但是，当处理固定大小的基本数据类型的时候，这种方式相对比较慢。

**适用场景：**

如果想要保存一些在整个程序运行期间都会存在而且不变的数据，我们可以将它们放进一个全局数组里，但是如果我们单纯只是想要以数组的形式保存数据，而不对数据进行增加等操作，只是方便我们进行查找的话，那么，我们就选择 ArrayList。而且还有一个地方是必须知道的，就是如果我们需要对元素进行频繁的移动或删除，或者是处理的是超大量的数据，那么，使用ArrayList就真的不是一个好的选择，因为它的效率很低，使用数组进行这样的动作就很麻烦，那么，我们可以考虑选择 LinkedList。

**答案二：**

区别：

- 数组可以包含基本数据类型和引用类型，ArrayList 只能包含引用类型。
- ArrayList 是基于数组实现的，数组大小不可以调整大小，但 ArrayList 可以通过内部方法自动调整容量。
- ArrayList 是 List 接口的实现类，相比数组支持更多的方法和特性。

场景：

- 当集合长度固定时，使用数组；当集合的长度不固定时，使用 ArrayList。但如果长度增长频繁，应考虑预设 ArrayList 的长度或者使用链表 LinkedList 代替，ArrayList 每次扩容都要进行数组的拷贝。
- 由于ArrayList不支持基本数据类型，所以保存基本数据类型时需要装箱处理，对比数组性能会下降。这种情况尽量使用数组。
- 数组支持的操作方法很少，但内存占用少，如果只需对集合进行随机读写，选数组；如果需要进行插入和数组，使用数组的话，需要手动编写移动元素的代码，ArrayList中内置了这些操作，开发更方便。

## ArrayList 和LinkedList 有什么区别？

**答案一：**

ArrayList的实现用的是数组，LinkedList是基于链表，ArrayList 适合查找，LinkedList 适合增删

**答案二：**

因为 Array 是基于索引  (index)  的数据结构，它使用索引在数组中搜索和读取数据是很快的。  Array 获取数据的时间复杂度是  O(1),  但是要删除数据却是开销很大的，因为这需要重排数组中的所有数据。

 相对于 ArrayList ，LinkedList 插入是更快的。因为 LinkedList 不像 ArrayList 一样，不需要改变数组的大小，也不需要在数组装满的时候要将所有的数据重新装入一个新的数组，这是 ArrayList 最坏的一种情况，时间复杂度是  O(n) ，而 LinkedList 中插入或删除的时间复杂度仅为 O(1) 。ArrayList 在插入数据时还需要更新索引（除了插入数组的尾部）。

类似于插入数据，删除数据时，  LinkedList 也优于 ArrayList  。

LinkedList 需要更多的内存，因为  ArrayList  的每个索引的位置是实际的数据，而 LinkedList 中的每个节点中存储的是实际的数据和前后节点的位置  (一个 LinkedList 实例存储了两个值：  Node<E> first  和  Node<E> last  分别表示链表的其实节点和尾节点，每个  Node  实例存储了三个值： E item,Node next,Node pre)  。

**什么场景下更适宜使用 LinkedList，而不用 ArrayList **

你的应用不会随机访问数据。因为如果你需要 LinkedList 中的第 n 个元素的时候，你需要从第一个元素顺序数到第 n 个数据，然后读取数据。

你的应用更多的插入和删除元素，更少的读取数据。因为插入和删除元素不涉及重排数据，所以它要比 ArrayList 要快。      

你需要一个不同步的基于索引的数据访问时，请尽量使用 ArrayList 。ArrayList 很快，也很容易使用。但是要记得要给定一个合适的初始大小，尽可能的减少更改数组的大小。

**答案三：**

ArrayList 和 LinkedList 都实现了 List 接口，他们有以下的不同点：

ArrayList 是基于索引的数据接口，它的底层是数组。它可以以O(1)时间复杂度对元素进行随机访问。与此对应，LinkedList 是以元素列表的形式存储它的数据，每一个元素都和它的前一个和后一个元素链接在一起，在这种情况下，查找某个元素的时间复杂度是O(n)。

相对于 ArrayList，LinkedList 的插入，添加，删除操作速度更快，因为当元素被添加到集合任意位置的时候，不需要像数组那样重新计算大小或者是更新索引。

LinkedList 比 ArrayList 更占内存，因为 LinkedList 为每一个节点存储了两个引用，一个指向前一个元素，一个指向下一个元素。

## Comparable 和 Comparator 接口是干什么的？列出它们的区别。

Comparable & Comparator 都是用来实现**集合**中元素的**比较、排序**的，只是 Comparable 是在**集合内部定义**的方法实现的排序，Comparator 是在**集合外部**实现的排序，所以，如想实现排序，就需要在集合外定义 Comparator 接口的方法或在集合内实现 Comparable 接口的方法。 Comparator 位于包 **java.util** 下，而 Comparable 位于包 **java.lang** 下。

Comparable 是一个对象本身就已经支持自比较所需要实现的接口（如 String、Integer 自己就可以完成比较大小操作，已经实现了Comparable接口），**自定义的类要在加入 list 容器中后能够排序，可以实现Comparable 接口**，**在用 Collections 类的 sort 方法排序时，如果不指定 Comparator，那么就以自然顺序排序**， 这里的自然顺序就是实现 Comparable 接口设定的排序方式。

 而 Comparator 是一个专用的比较器，当这个对象不支持自比较或者自比较函数不能满足你的要求时，你可以写一个比较器来完成两个对象之间大小的比较。 可以说一个是自已完成比较，一个是外部程序实现比较的差别而已。 用 Comparator 是策略模式（strategy design pattern），就是不改变对象自身，而用一个策略对象（strategy object）来改变它的行为。 比如：你想对整数采用绝对值大小来排序，Integer 是不符合要求的，你不需要去修改 Integer 类（实际上你也不能这么做）去改变它的排序行为，只要使用一个实现了 Comparator 接口的对象来实现控制它的排序就行了。

## 什么是Java优先级队列(Priority Queue)？

**答案一：**

优先级队列中的元素可以按照任意的顺序插入，却总是按照排序的顺序进行检索。无论何时调用 remove 方法，总会获得当前优先级队列中的最小元素，但并不是对所有元素都排序。它是采用了堆（一个可以自我调整的二叉树），执行增加删除操作后，可以让最小元素移动到根。

**答案二：**

PriorityQueue 是从 JDK1.5 开始提供的新的数据结构接口，它是一种基于优先级堆的极大优先级队列。优先级队列是不同于先进先出队列的另一种队列。每次从队列中取出的是具有最高优先权的元素。如果不提供Comparator 的话，优先队列中元素默认按自然顺序排列，也就是数字默认是小的在队列头，字符串则按字典序排列（参阅  Comparable ），也可以根据  Comparator 来指定，这取决于使用哪种构造方法。优先级队列不允许 null  元素。依靠自然排序的优先级队列还不允许插入不可比较的对象（这样做可能导致  ClassCastException ）

优先级队列有一个内部容量，控制着用于存储队列元素的数组大小。它通常至少等于队列的大小。随着不断向优先级队列添加元素，其容量会自动增加。无需指定容量增加策略的细节。

最后， PriorityQueue 不是线程安全的，入队和出队的时间复杂度是 O(log(n))  。

## 你了解大O符号(big-O notation)么？你能给出不同数据结构的例子么？

大 O 符号表示**一个程序运行时所需要的渐进时间复杂度上界**。

其函数表示是： 对于函数 f(n)、g(n)，如果存在一个常数 c，使得 `f(n)<=c*g(n),则 f(n)=O(g(n));`

大 O 描述当数据结构中的元素增加时，算法的规模和性能在最坏情景下有多好。 

大 O 还可以描述其它行为，比如内存消耗。因为集合类实际上是数据结构，因此我们一般使用大 O 符号基于时间，内存，性能选择最好的实现。大 O 符号可以对大量数据性能给予一个很好的说明。

## 如何权衡是使用无序的数组还是有序的数组？

- 有序数组 
  - 查找：可以使用二分查找， 时间复杂度 O(long N) 
  - 插入：需要比较，移动数据，找到合适的位置插入数据 O(N)
- 无序数组：
  - 查找：需要循环遍历 O(N)
  - 插入：放到末尾就好 O(1)

| 数组类型 | 查找    | 插入    |
| -------- | ------- | ------- |
| 有序数组 | O(logN) | O(logN) |
| 无序数组 | O(N)    | O(1)    |

## Java集合类框架的最佳实践有哪些？（怎么去选择一个合适的集合类框架）

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042769-9356584_1527335930072_69875FF03E527B3EC9A92FEE00147F79.png)

## Enumeration 接口和 Iterator 接口的区别有哪些？

```java
package java.util;
public interface Enumeration {  
    boolean hasMoreElements();  
    E nextElement();  
}  

public interface Iterator {  
    boolean hasNext();  
    E next();  
    void remove();  
}  
```

**区别：**

- 函数接口不同  
  -  Enumeration 只有2个函数接口。通过 Enumeration，我们只能读取集合的数据，而不能对数据进行修改。   
  - Iterator 只有3个函数接口。Iterator 除了能读取集合的数据之外，也能对数据进行删除操作。
- Iterato 支持 fail-fast 机制，而 Enumeration 不支持
  -  Enumeration 是 JDK1.0 添加的接口。使用到它的函数包括 Vector、Hashtable 等类，这些类都是JDK 1.0 中加入的，Enumeration 存在的目的就是为它们提供遍历接口。Enumeration 本身并没有支持同步，而在 Vector、Hashtable 实现 Enumeration 时，添加了同步。
  - 而 Iterator 是 JDK 1.2 才添加的接口，它也是为了 HashMap、ArrayList 等集合提供遍历接口。Iterator 是支持 fail-fast 机制的：当多个线程对同一个集合的内容进行操作时，就可能会产生 fail-fast 事件。



> 速失败的“快”不是体现在迭代器访问集合的时候，两个线程间的快慢。而是体现在，当 A 线程访问集合时，有另外一个线程B改变了该集合的结构，（添加/删除一个或多个映射关系），除非通过迭代器本身的 remove 方法，其他任何时间任何方式的修改 都会导致 A线程会“立即”抛出 ConcurrentModificationException 异常，迭代“快速终止”。
>
> 与“快速失败”相对的有一个概念是“安全失败”。Iterator 的安全失败是基于对底层集合做拷贝，因此，它不受源集合上修改的影响。也就是同样的情况下，A集合不会抛出ConcurrentModificaitonException异常，迭代会继续。

> 在用迭代器遍历一个集合对象时，如果遍历过程中对集合对象的结构进行了修改（增加、删除），则会抛出 Concurrent Modification Exception。
>
> 原理：迭代器在遍历时直接访问集合中的内容，并且在遍历过程中使用一个 modCount 变量。集合在被遍历期间如果结构发生变化，就会改变 modCount 的值。每当迭代器使用 hashNext()/next() 遍历下一个元素之前，都会检测modCount变量是否为 expectedmodCount 值，是的话就返回遍历；否则抛出异常，终止遍历。
>      在遍历的过程中，使用 iterator.remove() 一个元素，不会报异常。

## HashSet 和 TreeSet 有什么区别？

**答案一：**

HashSet 不允许保存重复对象，这个重复是有自己定义的。比如需要保存 People 对象，People 类包含名字和年龄两个属性，你可以在 People 类中重写 equals 和 hashCode方法，指明姓名和年龄都相等的 People 对象是相等的，那么就不能重复存入姓名和年龄相等的 People 对象。HashSet 中的对象没有顺序。

TreeSet 保存的对象有顺序性，也有不可重复性。顺序性有两种方法实现，一个是类实现 Comparable 接口；另一个是构造比较器，将比较器对象作为 TreeSet 的构造函数的参数传入。顺序性和不可重复性都是在 compareTo() 方法中实现的，当按年龄排序时，先比较年龄，年龄相等再比较姓名，姓名相等则不存入。

**答案二：**

1、HashSet 对速度进行了优化，提供了最快的查找速度，无特殊说明一般默认是用这个 Set 放到 HashSet 中的元素要保证唯一，应该重写 hashCode 方法和 equals 方法，但是不能保证元素有序底层实现是哈希结构

2、TreeSet 底层实现是红黑树(自平衡二叉树)，不但能保证元素唯一，还能元素保证有序，
**存放到 TreeSet 中的元素应该实现 Comparable 接口，重写 compareTo 方法**，否则会抛出 ClassCastException
按照该方法指定的规则维持元素的顺序

3、LinkedHashSet，底层实现是哈希表和链表，保持了HashSet 的速度，还能按照插入元素的顺序维持元素顺序

**答案三：**

HashSet 是由一个 **hash 表**来实现的，因此，它的元素是**无序**的。add()，remove()，contains()方法的时间复杂度是 O(1)。 

 TreeSe t是由一个**红黑树**的结构来实现的，它里面的元素是**有序**的。因此add()，remove()，contains() 方法的时间复杂度是O(logn)。

## Java中垃圾回收有什么目的？什么时候进行垃圾回收？

垃圾回收GC（Garbage Collector，垃圾回收）的目的是回收堆内存中不再使用的对象所占的内存，释放资源。

1.回收哪些对象的判定
 垃圾回收最简单的思路是采用**引用计数的方式**，即记录对象被引用的次数，直到一段时间内对象都没有被其他对象引用，此时可以确定该对象能被回收，引用计数实现简单，运行高效，但是有一个循环引用的问题，即两个本应被回收的对象因为互相引用而无法被回收，针对这个问题又有了弱引用，即把两个互相引用的一个引用计数改为弱引用，弱引用不会使次数加1，c++即是这么做的。

> jvm 虚拟机的使用的是**根寻路算法**，其大致思想是看除堆区以外的内存区域能否通过引用链找到堆中的对象，找不到就证明该对象可以被回收。

  2.如何回收 

jvm 有两种回收方式，一种是**标记完待回收的对象之后一起释放内存**，这种方法的缺点是会产生较多难以重复利用的**内存碎片**。另一种为了避免内存碎片的出现，将内存分为两块，一块使用，一块不使用，标记完所有待回收的对象之后，将还要使用的内存复制到不使用的区域，然后对使用的整体区域进行内存回收，这种方法没有内存碎片问题，但是每次回收的复制工作很耗性能。 

通过统计发现，在内存中存活越久的对象就越不容易被回收，越是新分配的内存对象就越可能会被回收。根据这个特性，把内存区域分为新生代和老年代(有的虚拟机会分为很多代)，**新生代**容易被回收，采用**复制内存再回收**的方法，**老年代**不容易被回收，**采用标记后回收和复制内存相结合**的方法。 

3.什么时候回收 

即触发 GC 的时间，在新生代的 Eden 区满了，会触发新生代GC（Minor GC），经过多次触发新生代 GC 存活下来的对象就会升级到老年代，升级到老年代的对象所需的内存大于老年代剩余的内存，则会触发老年代GC（Full    GC）。当程序调用 System.gc() 时也会触发Full GC。

1. 新创建的对象首先分配在 eden 区
2. 新生代空间不足时，触发 minor gc ，eden 区 和 from 区存活的对象使用 - copy 复制到 to 中，存活的对象年龄加 1，然后交换 from to
3. minor gc 会引发 stop the world，暂停其他线程，等垃圾回收结束后，恢复用户线程运行
4. 当幸存区对象的寿命超过阈值时，会晋升到老年代，最大的寿命是 15（4bit）
5. 当老年代空间不足时，会先触发 minor gc，如果空间仍然不足，那么就触发 full fc ，停止的时间更长！

## System.gc() 和 Runtime.gc() 会做什么事情？

这两个方法用来提示 JVM 要进行垃圾回收。但是，立即开始还是延迟进行垃圾回收是取决于JVM 的。

`java.lang.System.gc()` 只是 `java.lang.Runtime.getRuntime().gc()` 的简写，两者的行为没有任何不同。唯一要能说有什么不同那就是在字节码层面上调用前者比调用后者短一点点，前者是1条字节码而后者是2条。

实际运行起来性能几乎一样。不过如果对字节码大小非常非常敏感的话建议用 System.gc() 。从通常的代码习惯说也是 System.gc() 用得多些。

## finalize() 方法什么时候被调用？析构函数 (finalization) 的目的是什么？

**答案一：**

调用时机：当垃圾回收器要宣告一个对象死亡时，至少要经过两次标记过程：如果对象在进行可达性分析后发现没有和 GC Roots 相连接的引用链，就会被第一次标记，并且判断是否执行 finalizer( ) 方法，如果对象覆盖finalizer( ) 方法且未被虚拟机调用过，那么这个对象会被放置在 F-Queue 队列中，并在稍后由一个虚拟机自动建立的低优先级的 Finalizer 线程区执行触发 finalizer( ) 方法，但不承诺等待其运行结束。

finalization 的目的：对象逃脱死亡的最后一次机会。（只要重新与引用链上的任何一个对象建立关联即可，如果关联成功，在下一次标记的时候从“即将回收的对象”集合中移除；如果失败那么该对象基本就会被真的回收）但是不建议使用，运行代价高昂，不确定性大，且无法保证各个对象的调用顺序。可用 try-finally 或其他替代。

**答案一：**

 finalize() 是 Object 的 protected 方法，子类可以覆盖该方法以实现资源清理工作，GC 在回收对象之前调用该方法。

  当对象变成 (GC Roots) 不可达时，GC 会判断该对象是否覆盖了 finalize 方法，若未覆盖，则直接将其回收。否则，若对象未执行过 finalize 方法，将其放入F-Queue 队列，由一低优先级线程执行该队列中对象的 finalize 方法。执行 finalize 方法完毕后，GC 会再次判断该对象是否可达，若不可达，则进行回收，否则，对象“复活”。

## 如果对象的引用被置为 null，垃圾收集器是否会立即释放对象占用的内存？

不会立即释放对象占用的内存。  如果对象的引用被置为 null，只是断开了当前线程栈帧中对该对象的引用关系，而垃圾收集器是运行在后台的线程，只有当用户线程运行到安全点 (safe point) 或者安全区域才会扫描对象引用关系，扫描到对象没有被引用则会标记对象，这时候仍然不会立即释放该对象内存，因为有些对象是可恢复的（在 finalize方法中恢复引用  ）。只有确定了对象无法恢复引用的时候才会清除对象内存。

## Java堆的结构是什么样子的？什么是堆中的永久代(Perm Gen space)?

Java堆可以细分为：新生代（Young Generation）和老年代（Old Generation）；在细致一点的有 Eden 空间、From Survivor空间、To Survivor空间等。

- **年轻代:**

  所有新生成的对象首先都是放在年轻代的。年轻代的目标就是尽可能快速的收集掉那些生命周期短的对象。年轻代分三个区。一个 Eden 区，两个 Survivor 区(一般而言)。大部分对象在 Eden 区中生成。当 Eden 区满时，还存活的对象将被复制到 Survivor 区（两个中的一个），当这个 Survivor 区满时，此区的存活对象将被复制到另外一个 Survivor 区，当这个 Survivor 去也满了的时候，从第一个 Survivor 区复制过来的并且此时还存活的对象，将被复制“年老区(Tenured)”。需要注意，Survivor 的两个区是对称的，没先后关系，所以同一个区中可能同时存在从 Eden 复制过来对象，和从前一个Survivor 复制过来的对象，而复制到年老区的只有从第一个 Survivor 去过来的对象。而且，Survivor 区总有一个是空的。同时，根据程序需要， Survivor区是可以配置为多个的（多于两个），这样可以增加对象在年轻代中的存在时间，减少被放到年老代的可能。

- **年老代:**

  在年轻代中经历了 N 次垃圾回收后仍然存活的对象，就会被放到年老代中。因此，可以认为年老代中存放的都是一些生命周期较长的对象。

这样划分的目的是为了使 JVM 能够更好的管理堆内存中的对象，可以根据跟个年代的特点采用最适当的收集算法。在新生代中，每次垃圾收集时都发现有大批的对象死去，只有少量存活，那就选用**复制算法**，只需要付出少量存活对象的复制成本就可以完成收集。而老年代中因为对象存活率高、没有额外空间对它进行分配担保，就必须使用"**标记---整理**”算法来进行回收。

![Java堆内存默认划分示意图](http://qiniu.zhouhongyin.top/2022/06/12/1655042777-551067454_1544335119038_42B44DEE891A3CB84B4F765E9B3D8785.png)

> 绝大部分 Java 程序员应该都见过 `java.lang.OutOfMemoryError: PermGen space`"这个异常。这里的 "PermGen space"其实指的就是方法区。不过方法区和“PermGen space”又有着本质的区别。前者是 JVM 的规范，而后者则是 JVM 规范的一种实现，并且只有 HotSpot 才有 “PermGen space”，而对于其他类型的虚拟机，如JRockit（Oracle）、J9（IBM） 并没有“PermGen space”。由于方法区主要存储类的相关信息，所以对于动态生成类的情况比较容易出现永久代的内存溢出。最典型的场景就是，在 jsp 页面比较多的情况，容易出现永久代内存溢出。

方法区与 Java 堆一样，是各个线程共享的内存区域，它用于存储已被 Java 虚拟机加载的**类信息、常量、静态变量、即时编译器编译后的代码等数据**。

在 Java8 中移除了永生代，取而代之是元空间（Metaspace）

- 移除了永久代（PermGen），替换为元空间（Metaspace）
- 永久代中的 class metadata 转移到了 native memory（本地内存，而不是虚拟机）；
- 永久代中的 interned Strings 和 class static variables 转移到了 Java heap；
- 永久代参数 （PermSize MaxPermSize） -> 元空间参数（MetaspaceSize MaxMetaspaceSize）

![](http://qiniu.zhouhongyin.top/2022/06/12/1655042780-20210208112903305-1623570548865.png)

> **栈内存和堆内存：**
>
> 在函数中定义的**一些基本类型的变量和对象的引用变量都是在函数的栈内存中分配** 。**当在一段代码块中定义一个变量时，Java 就在栈中为这个变量分配内存空间**，当超过变量的作用域后，Java 会自动释放掉为该变量分配的内存空间，该内存空间可以立刻被另作他用。
>
> **堆内存用于存放由 new 创建的对象和数组**。在堆中分配的内存，由 java 虚拟机自动垃圾回收器来管理。在堆中产生了一个数组或者对象后，还可以在栈中定义一个特殊的变量，这个变量的取值等于数组或者对象在堆内存中的首地址，在栈中的这个特殊的变量就变成了数组或者对象的引用变量，以后就可以在程序中使用栈内存中的引用变量来访问堆中的数组或者对象，引用变量相当于为数组或者对象起的一个别名，或者代号。

## 串行(serial)收集器和吞吐量(throughput)收集器的区别是什么？

**串行GC：**整个扫描和复制过程均采用**单线程**的方式，相对于吞吐量GC来说简单；适合于**单CPU、客户端**级别。 

**吞吐量GC：**采用**多线程**的方式来完成垃圾收集；适合于**吞吐量**要求较高的场合，比较适合中等和大规模的应用程序。

## 在 Java 中，对象什么时候可以被垃圾回收？

判断对象是否存活，可以使用**引用计数器或者可达性分析**两种方法。  

**引用计数器：**

当引用计数器为零的时候，表明没用引用再指向该对象，但是引用计数器不能解决循环引用的情况；  

**可达性分析：**

1. 当不能从 GC Root 寻找一条路径到达该对象时， 将进行第一次标记。 

2. 第一次标记后检查对象是否重写了 finalize() 和是否已经被调用了 finalize() 方法。若没有重写 finalize() 方法或已经被调用，则进行回收。
3. 在已经重写 finalize() 方法且未调用的情况下，将对象加入一个 F-Queue 的队列中，稍后进行第二次检查。
4. 在第二次标记之前，对象如果执行 finalize() 方法并完成自救(将自身赋予某个引用)，对象则不会被回收。否则完成第二次标记，进行回收。值得注意的是 finalize() 方法并不可靠。

## JVM 的永久代中会发生垃圾回收么？

**永久代回收的条件：**

1. 该类的实例都被回收。
2. 加载该类的 classLoader 已经被回收
3. 该类不能通过反射访问到其方法，而且该类的java.lang.class没有被引用

当满足这3个条件时，是可以回收，但回不回收还得看jvm。

> 废弃常量：比如字符串"123"已经进入常量池，但是当前系统没有任何 String 对象引用常量池中的 "123"，也没有其他地方引用该字面量，若发生内存回收，且必要的话，该"123"就会被系统清理出常量池，而且常量池的中的其他类（接口）、方法、字段的符号引用与此类似。