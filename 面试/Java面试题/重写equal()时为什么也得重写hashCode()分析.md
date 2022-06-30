---
title: 重写equal()时为什么也得重写hashCode()分析
date: 2021-6-12
updated: 2021-6-12
tags:
  - Java
  - hashMap
categories:
  - 面试
  - 重写equal()时为什么也得重写hashCode()分析
---

![](http://qiniu.zhouhongyin.top/2022/06/12/1655043306-1_iIXOmGDzrtTJmdwbn7cGMw.png)

<!--more-->

## 一、equals() 的所属以及内部原理（即 Object 中 equals 方法的实现原理）

说起 equals 方法，我们都知道是超类 Object 中的一个基本方法，用于检测一个对象是否与另外一个对象相等。而在 Object 类中这个方法实际上是判断两个对象是否具有相同的引用，如果有，它们就一定相等。其源码如下：

```java
public boolean equals(Object obj) {   return (this == obj);     }
```


实际上我们知道所有的对象都拥有标识(内存地址)和状态(数据)，同时 “==” 比较两个对象的的内存地址，所以说 Object 的 equals() 方法是比较两个对象的内存地址是否相等，即若 object1.equals(object2) 为 true，则表示 equals1 和 equals2 实际上是引用同一个对象。

## 二、equals() 与 ‘==’ 的区别

或许这是我们面试时更容易碰到的问题 ”equals方法与‘==’运算符有什么区别？“，并且常常我们都会胸有成竹地回答：“equals 比较的是对象的内容，而 ‘==’ 比较的是对象的地址”。但是从前面我们可以知道 equals 方法在Object 中的实现也是间接使用了 ‘==’ 运算符进行比较的，所以从严格意义上来说，我们前面的回答并不完全正确。我们先来看一段代码并运行再来讨论这个问题。

```java
package com.zejian.test;
public class Car {
	private int batch;
	public Car(int batch) {
		this.batch = batch;
	}
	public static void main(String[] args) {
		Car c1 = new Car(1);
		Car c2 = new Car(1);
		System.out.println(c1.equals(c2));
		System.out.println(c1 == c2);
	}
}
```

运行结果：

```powershell
false
false
```

分析：对于 ‘==’ 运算符比较两个Car对象，返回了false，这点我们很容易明白，毕竟它们比较的是内存地址，而 c1与 c2 是两个不同的对象，所以 c1 与 c2 的内存地址自然也不一样。现在的问题是，我们希望生产的两辆的批次（batch）相同的情况下就认为这两辆车相等，但是运行的结果是尽管 c1 与 c2 的批次相同，但 equals 的结果却反回了 false。当然对于 equals 返回了 false，我们也是心知肚明的，因为 equal 来自 Object 超类，访问修饰符为 public，而我们并没有重写equal方法，故调用的必然是Object超类的原始方equals方法，根据前面分析我们也知道该原始 equal 方法内部实现使用的是 '==' 运算符，所以返回了 false。因此为了达到我们的期望值，我们必须重写Car 的 equal 方法，让其比较的是对象的批次（即对象的内容），而不是比较内存地址，于是修改如下：

```java
@Override
public boolean equals(Object obj) {
    if (obj instanceof Car) {
        Car c = (Car) obj;
        return batch == c.batch;
    }
    return false;
}
```

使用 instanceof 来判断引用 obj 所指向的对象的类型，如果 obj 是 Car 类对象，就可以将其强制转为 Car 对象，然后比较两辆 Car 的批次，相等返回 true，否则返回 false。当然如果 obj 不是 Car 对象，自然也得返回 false。我们再次运行：

```java
true
false
```

嗯，达到我们预期的结果了。因为前面的面试题我们应该这样回答更佳

总结：默认情况下也就是从超类 Object 继承而来的 equals 方法与 ‘==’ 是完全等价的，比较的都是对象的内存地址，但我们可以重写 equals 方法，使其按照我们的需求的方式进行比较，如 String 类重写了 equals 方法，使其比较的是字符的序列，而不再是内存地址。

## 三、equals() 的重写规则

前面我们已经知道如何去重写 equals 方法来实现我们自己的需求了，但是我们在重写equals方法时，还是需要注意如下几点规则的。

- **自反性：**对于任何非 null 的引用值 x，`x.equals(x)` 应返回 true。

- **对称性：**对于任何非 null 的引用值 x 与 y，当且仅当：`y.equals(x)` 返回 true 时，`x.equals(y)` 才返回 true。

- **传递性：**对于任何非 null 的引用值 x、y 与 z，如果 `y.equals(x)` 返回true，`y.equals(z)` 返回 true，那么 `x.equals(z)` 也应返回 true。

- **一致性：**对于任何非 null 的引用值 x 与 y，假设对象上 equals 比较中的信息没有被修改，则多次调用`x.equals(y)` 始终返回 true 或者始终返回 false。

- 对于任何非空引用值 x，`x.equal(null)` 应返回 false。


当然在通常情况下，如果只是进行同一个类两个对象的相等比较，一般都可以满足以上5点要求，下面我们来看前面写的一个例子。

```java
package com.zejian.test;
public class Car {
	private int batch;
	public Car(int batch) {
		this.batch = batch;
	}
	public static void main(String[] args) {
		Car c1 = new Car(1);
		Car c2 = new Car(1);
		Car c3 = new Car(1);
		System.out.println("自反性->c1.equals(c1)：" + c1.equals(c1));
		System.out.println("对称性：");
		System.out.println(c1.equals(c2));
		System.out.println(c2.equals(c1));
		System.out.println("传递性：");
		System.out.println(c1.equals(c2));
		System.out.println(c2.equals(c3));
		System.out.println(c1.equals(c3));
		System.out.println("一致性：");
		for (int i = 0; i < 50; i++) {
			if (c1.equals(c2) != c1.equals(c2)) {
				System.out.println("equals方法没有遵守一致性！");
				break;
			}
		}
		System.out.println("equals方法遵守一致性！");
		System.out.println("与null比较：");
		System.out.println(c1.equals(null));
	}
	@Override
	public boolean equals(Object obj) {
		if (obj instanceof Car) {
			Car c = (Car) obj;
			return batch == c.batch;
		}
		return false;
	}
}
```

运行结果：

```java
自反性->c1.equals(c1)：true

对称性：
true
true

传递性：
true
true
true

一致性：
equals方法遵守一致性！

与null比较：
false
```

由运行结果我们可以看出 equals 方法在同一个类的两个对象间的比较还是相当容易理解的。但是如果是子类与父类混合比较，那么情况就不太简单了。下面我们来看看另一个例子，首先，我们先创建一个新类 BigCar ，继承于 Car，然后进行子类与父类间的比较。

```java
public class BigCar extends Car {
	int count;
	public BigCar(int batch, int count) {
		super(batch);
		this.count = count;
	}
	@Override
	public boolean equals(Object obj) {
		if (obj instanceof BigCar) {
			BigCar bc = (BigCar) obj;
			return super.equals(bc) && count == bc.count;
		}
		return false;
	}
	public static void main(String[] args) {
		Car c = new Car(1);
		BigCar bc = new BigCar(1, 20);
		System.out.println(c.equals(bc));
		System.out.println(bc.equals(c));
	}
}
```

运行结果：

```java
true

false
```

对于这样的结果，自然是我们意料之中的啦。因为 BigCar 类型肯定是属于Car 类型，所以 c.equals(bc) 肯定为true，对于 bc.equals(c) 返回 false，是因为 Car 类型并不一定是 BigCar 类型（Car类还可以有其他子类）。嗯，确实是这样。但如果有这样一个需求，只要 BigCar 和 Car 的生产批次一样，我们就认为它们两个是相当的，在这样一种需求的情况下，父类（Car）与子类（ BigCar ）的混合比较就不符合 equals 方法对称性特性了。很明显一个返回 true，一个返回了 false ，根据对称性的特性，此时两次比较都应该返回true才对。那么该如何修改才能符合对称性呢？其实造成不符合对称性特性的原因很明显，那就是因为 Car 类型并不一定是 BigCar 类型（Car类还可以有其他子类），在这样的情况下(Car instanceof BigCar)永远返回false，因此，我们不应该直接返回false，而应该继续使用父类的 equals 方法进行比较才行（因为我们的需求是批次相同，两个对象就相等，父类 equals 方法比较的就是 batch 是否相同）。因此 BigCar 的 equals 方法应该做如下修改：

```java
 @Override
public boolean equals(Object obj) {
    if (obj instanceof BigCar) {
        BigCar bc = (BigCar) obj;
        return super.equals(bc) && count == bc.count;
    }
    return super.equals(obj);
}
```

这样运行的结果就都为 true 了。但是到这里问题并没有结束，虽然符合了对称性，却还没符合传递性，实例如下：

bc，bc2，c的批次都是相同的，按我们之前的需求应该是相等，而且也应该符合 equals 的传递性才对。但是事实上运行结果却不是这样，违背了传递性。出现这种情况根本原因在于：

- 父类与子类进行混合比较。

- 子类中声明了新变量，并且在子类 equals 方法使用了新增的成员变量作为判断对象是否相等的条件。


只要满足上面两个条件，equals 方法的传递性便失效了。而且目前并没有直接的方法可以解决这个问题。因此我们在重写 equals 方法时这一点需要特别注意。虽然没有直接的解决方法，但是间接的解决方案还说有滴，那就是通过组合的方式来代替继承，还有一点要注意的是组合的方式并非真正意义上的解决问题（只是让它们间的比较都返回了 false，从而不违背传递性，然而并没有实现我们上面 batch 相同对象就相等的需求），而是让 equals 方法满足各种特性的前提下，让代码看起来更加合情合理，代码如下：

```java
public class Combination4BigCar {
	private Car c;
	private int count;
	public Combination4BigCar(int batch, int count) {
		c = new Car(batch);
		this.count = count;
	}
	@Override
	public boolean equals(Object obj) {
		if (obj instanceof Combination4BigCar) {
			Combination4BigCar bc = (Combination4BigCar) obj;
			return c.equals(bc.c) && count == bc.count;
		}
		return false;
	}
}
```


从代码来看即使 batch 相同，Combination4BigCar 类的对象与 Car 类的对象间的比较也永远都是false，但是这样看起来也就合情合理了，毕竟 Combination4BigCar 也不是 Car 的子类，因此 equals 方法也就没必要提供任何对Car 的比较支持，同时也不会违背了 equals 方法的传递性。

## 四、equals() 的重写规则之必要性深入解读

前面我们一再强调了 equals 方法重写必须遵守的规则，接下来我们就是分析一个反面的例子，看看不遵守这些规则到底会造成什么样的后果。

```java
package com.zejian.test;
import java.util.ArrayList;
import java.util.List;
/** * 反面例子 * @author zejian */
public class AbnormalResult {
	public static void main(String[] args) {
		List<A> list = new ArrayList<A>();
		A a = new A();
		B b = new B();
		list.add(a);
		System.out.println("list.contains(a)->" + list.contains(a));
		System.out.println("list.contains(b)->" + list.contains(b));
		list.clear();
		list.add(b);
		System.out.println("list.contains(a)->" + list.contains(a));
		System.out.println("list.contains(b)->" + list.contains(b));
	}
	static class A {
		@Override
		public boolean equals(Object obj) {
			return obj instanceof A;
		}
	}
	static class B extends A {
		@Override
		public boolean equals(Object obj) {
			return obj instanceof B;
		}
	}
}
```


上面的代码，我们声明了 A,B 两个类，注意必须是 static，否则无法被 main 调用。B 类继承 A，两个类都重写了 equals 方法，但是根据我们前面的分析，这样重写是没有遵守对称性原则的，我们先来看看运行结果：

```java
list.contains(a)->true
list.contains(b)->false
list.contains(a)->true
list.contains(b)->true
```

19 行和 24 行的输出没什么好说的，将 a，b分别加入 list 中，list 中自然会含有 a，b。但是为什么 20 行和 23行结果会不一样呢？我们先来看看 contains 方法内部实现

```java
@Override       
public boolean contains(Object o) { 
     return indexOf(o) != -1; 
 }
```

进入 indexof 方法

```java
@Override
public int indexOf(Object o) {
    E[] a = this.a;
    if (o == null) {
        for (int i = 0; i < a.length; i++)
            if (a[i] == null)
                return i;
    } else {
        for (int i = 0; i < a.length; i++)
            if (o.equals(a[i]))
                return i;
    }
    return -1;
}
```

可以看出最终调用的是对象的 equals 方法，所以当调用20行代码 list.contains(b) 时，实际上调用了b.equals(a[i])，a[i] 是集合中的元素集合中的类型而且为 A 类型(只添加了 a  对象)，虽然 B 继承了 A，但此时

```java
a[i] instanceof B
```

结果为false，equals 方法也就会返回 false；而当调用 23 行代码 list.contains(a) 时，实际上调用了a.equal(a[i])，其中 a[i] 是集合中的元素而且为 B 类型(只添加了b对象)，由于B类型肯定是A类型（B继承了A），所以

```java
a[i] instanceof A
```

结果为 true，equals 方法也就会返回true，这就是整个过程。但很明显结果是有问题的，因为我们的 list 的泛型是 A，而 B 又继承了 A，此时无论加入了 a 还是 b，都属于同种类型，所以无论是 contains(a)，还是 contains(b)都应该返回 true才算正常。而最终却出现上面的结果，这就是因为重写 equals 方法时没遵守对称性原则导致的结果，如果没遵守传递性也同样会造成上述的结果。当然这里的解决方法也比较简单，我们只要将 B 类的 equals 方法修改一下就可以了。

```java
static class B extends A{
    @Override
    public boolean equals(Object obj) {
        if(obj instanceof B){
            return true;
        }
        return super.equals(obj);
    }
}
```

到此，我们也应该明白了重写 equals 必须遵守几点原则的重要性了。当然这里不止是 list，只要是 java 集合类或者 java 类库中的其他方法，重写 equals 不遵守5点原则的话，都可能出现意想不到的结果。

## 五、为什么重写 equals() 的同时还得重写 hashCode()

这个问题之前我也很好奇，不过最后还是在书上得到了比较明朗的解释，当然这个问题主要是针对映射相关的操作（Map接口）。学过数据结构的同学都知道 Map 接口的类会使用到键对象的哈希码，当我们调用 put 方法或者get 方法对 Map 容器进行操作时，都是根据键对象的哈希码来计算存储位置的，因此如果我们对哈希码的获取没有相关保证，就可能会得不到预期的结果。在 Java 中，我们可以使用 hashCode() 来获取对象的哈希码，其值就是对象的存储地址，这个方法在 Object 类中声明，因此所有的子类都含有该方法。那我们先来认识一下 hashCode() 这个方法吧。hashCode 的意思就是散列码，也就是哈希码，是由对象导出的一个整型值，散列码是没有规律的，如果 x 与 y 是两个不同的对象，那么 x.hashCode() 与 y.hashCode() 基本是不会相同的，下面通过 String 类的 hashCode() 计算一组散列码：

```java
public class HashCodeTest {
	public static void main(String[] args) {
		int hash=0;
		String s="ok";
		StringBuilder sb =new StringBuilder(s);
        
        System.out.println(s.hashCode()+"  "+sb.hashCode());

        String t = new String("ok");
        StringBuilder tb =new StringBuilder(s);
        System.out.println(t.hashCode()+"  "+tb.hashCode());
	}
}
```

运行结果：

```java
3548  1829164700
3548  2018699554
```

我们可以看出，字符串 s 与 t 拥有相同的散列码，这是因为字符串的散列码是由内容导出的。而字符串缓冲 sb 与 tb 却有着不同的散列码，这是因为 StringBuilder 没有重写 hashCode 方法，它的散列码是由 Object 类默认的hashCode 方法计算出来的对象存储地址，所以散列码自然也就不同了。那么我们该如何重写出一个较好的hashCode 方法呢，其实并不难，我们只要合理地组织对象的散列码，就能够让不同的对象产生比较均匀的散列码。例如下面的例子：

```java
package com.zejian.test;
public class Model {
	private String name;
	private double salary;
	private int sex;
	

	@Override
	public int hashCode() {
		return name.hashCode()+new Double(salary).hashCode() 
				+ new Integer(sex).hashCode();
	}

}
```

上面的代码我们通过合理的利用各个属性对象的散列码进行组合，最终便能产生一个相对比较好的或者说更加均匀的散列码，当然上面仅仅是个参考例子而已，我们也可以通过其他方式去实现，只要能使散列码更加均匀（所谓的均匀就是每个对象产生的散列码最好都不冲突）就行了。不过这里有点要注意的就是 java 7 中对 hashCode 方法做了两个改进，首先 Java 发布者希望我们使用更加安全的调用方式来返回散列码，也就是使用 null 安全的方法 Objects.hashCode（注意不是 Object 而是 java.util.Objects ） 方法，这个方法的优点是如果参数为null，就只返回0，否则返回对象参数调用的 hashCode 的结果。 Objects.hashCode 源码如下：

```java
public static int hashCode(Object o) {
        return o != null ? o.hashCode() : 0;
}
```

因此我们修改后的代码如下：

```java
package com.zejian.test;
import java.util.Objects;
public  class Model {
	private   String name;
	private double salary;
	private int sex;
	@Override
	public int hashCode() {
		return Objects.hashCode(name)+new Double(salary).hashCode() 
				+ new Integer(sex).hashCode();
	}
}
```

java 7 还提供了另外一个方法 java.util.Objects.hash(Object... objects)，当我们需要组合多个散列值时可以调用该方法。进一步简化上述的代码：

```JAVA
package com.zejian.test;
import java.util.Objects;
public  class Model {
private   String name;
private double salary;
private int sex;
//	@Override
//	public int hashCode() {
//		return Objects.hashCode(name)+new Double(salary).hashCode() 
//				+ new Integer(sex).hashCode();
//	}

	@Override
	public int hashCode() {
		return Objects.hash(name,salary,sex);
	}

}
```

好了，到此 hashCode() 该介绍的我们都说了，还有一点要说的如果我们提供的是一个数值类型的变量的话，那么我们可以调用 Arrays.hashCode() 来计算它的散列码，这个散列码是由数组元素的散列码组成的。接下来我们回归到我们之前的问题，重写 equals 方法时也必须重写 hashCode 方法。在 Java API 文档中关于 hashCode 方法有以下几点规定（原文来自 Java 深入解析一书）。

1. 在 Java 应用程序执行期间，如果在 equals 方法比较中所用的信息没有被修改，那么在同一个对象上多次调用hashCode 方法时必须一致地返回相同的整数。如果多次执行同一个应用时，不要求该整数必须相同。

2. 如果两个对象通过调用 equals 方法是相等的，那么这两个对象调用 hashCode 方法必须返回相同的整数。

3. 如果两个对象通过调用 equals 方法是不相等的，不要求这两个对象调用 hashCode 方法必须返回不同的整数。但是程序员应该意识到对不同的对象产生不同的 hash 值可以提高哈希表的性能。


通过前面的分析，我们知道在 Object 类中，hashCode 方法是通过 Object 对象的地址计算出来的，因为 Object 对象只与自身相等，所以同一个对象的地址总是相等的，计算取得的哈希码也必然相等，对于不同的对象，由于地址不同，所获取的哈希码自然也不会相等。因此到这里我们就明白了，如果一个类重写了 equals 方法，但没有重写 hashCode 方法，将会直接违法了第2条规定，这样的话，如果我们通过映射表( Map 接口)操作相关对象时，就无法达到我们预期想要的效果。如果大家不相信, 可以看看下面的例子（来自 Java 深入解析一书）

```JAVA
import java.util.HashMap;
import java.util.Map;
public class MapTest {
	public static void main(String[] args) {
		Map<String,Value> map1 = new HashMap<String,Value>();
		String s1 = new String("key");
		String s2 = new String("key");	
		Value value = new Value(2);
		map1.put(s1, value);
		System.out.println("s1.equals(s2):"+s1.equals(s2));
		System.out.println("map1.get(s1):"+map1.get(s1));
		System.out.println("map1.get(s2):"+map1.get(s2));
		
		

		Map<Key,Value> map2 = new HashMap<Key,Value>();
		Key k1 = new Key("A");
		Key k2 = new Key("A");
		map2.put(k1, value);
		System.out.println("k1.equals(k2):"+s1.equals(s2));
		System.out.println("map2.get(k1):"+map2.get(k1));
		System.out.println("map2.get(k2):"+map2.get(k2));
	}
	
	/**
	 * 键
	 * @author zejian
	 *
	 */
	static class Key{
		private String k;
		public Key(String key){
			this.k=key;
		}
		
		@Override
		public boolean equals(Object obj) {
			if(obj instanceof Key){
				Key key=(Key)obj;
				return k.equals(key.k);
			}
			return false;
		}
	}
	
	/**
	 * 值
	 * @author zejian
	 *
	 */
	static class Value{
		private int v;
		
		public Value(int v){
			this.v=v;
		}
		
		@Override
		public String toString() {
			return "类Value的值－－>"+v;
		}
	}

}
```

代码比较简单，我们就不过多解释了（注意 Key 类并没有重写 hashCode 方法），直接运行看结果

```JAVA
s1.equals(s2):true
map1.get(s1):类Value的值－－>2
map1.get(s2):类Value的值－－>2
k1.equals(k2):true
map2.get(k1):类Value的值－－>2
map2.get(k2):null
```

对于 s1 和 s2 的结果，我们并不惊讶，因为相同的内容的 s1 和 s2 获取相同内的 value 这个很正常，因为 String 类重写了 equals 方法和 hashCode 方法，使其比较的是内容和获取的是内容的哈希码。但是对于k1和 k2 的结果就不太尽人意了，k1 获取到的值是 2， k2 获取到的是 null，这是为什么呢？想必大家已经发现了，Key 只重写了 equals 方法并没有重写 hashCode 方法，这样的话，equals 比较的确实是内容，而 hashCode 方法呢？没重写，那就肯定调用超类 Objec t的 hashCode 方法，这样返回的不就是地址了吗？k1 与 k2 属于两个不同的对象，返回的地址肯定不一样，所以现在我们知道调用 map2.get(k2 )为什么返回 null 了吧？那么该如何修改呢？很简单，我们要做也重写一下 hashCode 方法即可（如果参与 equals 方法比较的成员变量是引用类型的，则可以递归调用hashCode 方法来实现）：

```JAVA
@Override
public int hashCode() {
     return k.hashCode();
}
```

再次运行：

```
s1.equals(s2):true
map1.get(s1):类Value的值－－>2
map1.get(s2):类Value的值－－>2
k1.equals(k2):true
map2.get(k1):类Value的值－－>2
map2.get(k2):类Value的值－－>2
```

## 六、重写 equals() 中 getClass 与 instanceof 的区别

虽然前面我们都在使用 instanceof（当然前面我们是根据需求（批次相同即相等）而使用 instanceof 的），但是在重写 equals() 方法时，一般都是推荐使用 getClass 来进行类型判断（除非所有的子类有统一的语义才使用instanceof），不是使用 instanceof。我们都知道  instanceof  的作用是判断其左边对象是否为其右边类的实例，返回 boolean 类型的数据。可以用来判断继承中的子类的实例是否为父类的实现。下来我们来看一个例子：父类Person

```java
public class Person {
    protected String name;
    public String getName() {
        return name;
    }
    public void setName(String name) {
        this.name = name;
    }
    public Person(String name){
        this.name = name;
    }
    public boolean equals(Object object){
        if(object instanceof Person){
            Person p = (Person) object;
            if(p.getName() == null || name == null){
                return false;
            }
            else{
                return name.equalsIgnoreCase(p.getName ());
            }
        }
        return false;
    }
}
```

子类 Employee

```java
public class Employee extends Person{
    private int id;
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public Employee(String name,int id){
        super(name);
        this.id = id;
    }
    /**
         * 重写equals()方法
         */
    public boolean equals(Object object){
        if(object instanceof Employee){
            Employee e = (Employee) object;
            return super.equals(object) && e.getId() == id;
        }
        return false;
    }
}
```

上面父类 Person 和子类 Employee 都重写了 equals()，不过 Employee 比父类多了一个 id 属性，而且这里我们并没有统一语义。测试代码如下：

```java
public class Test {
    public static void main(String[] args) {
        Employee e1 = new Employee("chenssy", 23);
        Employee e2 = new Employee("chenssy", 24);
        Person p1 = new Person("chenssy");
        System.out.println(p1.equals(e1));
        System.out.println(p1.equals(e2));
        System.out.println(e1.equals(e2));
    }
}
```

上面代码我们定义了两个员工和一个普通人，虽然他们同名，但是他们肯定不是同一人，所以按理来说结果应该全部是 false，但是事与愿违，结果是：true、true、false。对于那  e1!=e2 我们非常容易理解，因为他们不仅需要比较 name，还需要比较 ID。但是 p1 即等于 e1 也等于 e2，这是非常奇怪的，因为 e1、e2 明明是两个不同的类，但为什么会出现这个情况？首先 p1.equals(e1)，是调用 p1 的 equals 方法，该方法使用  instanceof 关键字来检查 e1 是否为 Person 类，这里我们再看看  instanceof：判断其左边对象是否为其右边类的实例，也可以用来判断继承中的子类的实例是否为父类的实现。他们两者存在继承关系，肯定会返回 true 了，而两者 name 又相同，所以结果肯定是 true。所以出现上面的情况就是使用了关键字 instanceof，这是非常容易导致我们“钻牛角尖”。故在覆写 equals 时推荐使用 getClass 进行类型判断。而不是使用 instanceof（除非子类拥有统一的语义）。

## 七、编写一个完美equals()的几点建议

下面给出编写一个完美的 equals 方法的建议（出自Java核心技术 第一卷：基础知识）：

1. 显式参数命名为 otherObject，稍后需要将它转换成另一个叫做 other 的变量（参数名命名，强制转换请参考建议5）
2. 检测 this 与 otherObject 是否引用同一个对象：`if(this == otherObject) return true;`（存储地址相同，肯定是同个对象，直接返回true）
3. 检测 otherObject 是否为 null ，如果为null，返回 false，`if(otherObject == null) return false;`。

4. 比较 this 与 otherObject 是否属于同一个类 （视需求而选择）
   - 如果 equals 的语义在每个子类中有所改变，就使用 getClass 检测 ：`if(getClass()!=otherObject.getClass()) return false;` (参考前面分析的第6点)
   - 如果所有的子类都拥有统一的语义，就使用 instanceof 检测 ：`if(!(otherObject instanceof ClassName)) return false;`（即前面我们所分析的父类 car与子类 bigCar 混合比，我们统一了批次相同即相等）
5. 将 otherObject 转换为相应的类类型变量：`ClassName other = (ClassName) otherObject;`

6. 现在开始对所有需要比较的域进行比较 。使用 == 比较基本类型域，使用 equals 比较对象域。如果所有的域都匹配，就返回 true，否则就返回 flase。
   - 如果在子类中重新定义 equals，就要在其中包含调用 `super.equals(other)`
   - 当此方法被重写时，通常有必要重写 hashCode 方法，以维护 hashCode 方法的常规协定，该协定声明相等对象必须具有相等的哈希码 。

原文链接：https://blog.csdn.net/javazejian/article/details/51348320