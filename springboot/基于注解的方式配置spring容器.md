# 一、`@Autowired`

## 1.1 构造方法

你可以将该注解添加导类的构造方法上。

```java
public class MovieRecommender {

    private final CustomerPreferenceDao customerPreferenceDao;
Wire
    @Autowired
    public MovieRecommender(CustomerPreferenceDao customerPreferenceDao) {
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...
}
```

> 从 Spring 的 4.3 版本开始，如果你的目标 bean 中只有一个构造方法，那个 @Autowired将不再必须添加。但是如果有多个构造方法，为了让 Spring 知道该用那个，你必须通过 @Autowired 指定一个构造方法

## 1.2 setter 方法

你可以将 @Autowired 注释应用于传统的 setter 方法。

```java
public class SimpleMovieLister {

    private MovieFinder movieFinder;

    @Autowired
    public void setMovieFinder(MovieFinder movieFinder) {
        this.movieFinder = movieFinder;
    }

    // ...
}	
```

## 1.3 任意方法和多个参数

你可以将注释应用于具有任意名称和多个参数的方法。

```java
public class MovieRecommender {

    private MovieCatalog movieCatalog;

    private CustomerPreferenceDao customerPreferenceDao;

    @Autowired
    public void prepare(MovieCatalog movieCatalog,
            CustomerPreferenceDao customerPreferenceDao) {
        this.movieCatalog = movieCatalog;
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...
}
```

## 1.4 属性或者混合使用

您还可以将@Autowired 应用于属性，甚至可以将其与构造函数混合使用

```java
public class MovieRecommender {

    private final CustomerPreferenceDao customerPreferenceDao;

    @Autowired
    private MovieCatalog movieCatalog;

    @Autowired
    public MovieRecommender(CustomerPreferenceDao customerPreferenceDao) {
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...
}
```

## 1.5 获取全部指定类型

通过一个指定 Type 的 array，获取指定类型的 bean 数组。

```java
public class MovieRecommender {

    @Autowired
    private MovieCatalog[] movieCatalogs;

    // ...
}
```

集合的形式。

```java
public class MovieRecommender {

    private Set<MovieCatalog> movieCatalogs;

    @Autowired
    public void setMovieCatalogs(Set<MovieCatalog> movieCatalogs) {
        this.movieCatalogs = movieCatalogs;
    }

    // ...
}
```

> 如果你想让你注入到 array 或者 集合中的元素有先后顺序，你需要让你的目标 bean 实现 `org.springframework.core.Ordered` 接口或者使用 @Order 注解 或者 标准的 @Priority 注解。否则，他们的顺序会遵循容器中目标 bean 的注册顺序。
>
> 值得注意的是，标准的 `javax.annotation.Priority` 注解不能用在 @Bean 上，因为他不能用在方法上。

只要 Map 的 key 为 String 类型，那么 Map 类型也可以当作自动注入的实例。map 的值就是你希望注入的 bean，key 就是 bean 的名字。

```Java
public class MovieRecommender {

    private Map<String, MovieCatalog> movieCatalogs;

    @Autowired
    public void setMovieCatalogs(Map<String, MovieCatalog> movieCatalogs) {
        this.movieCatalogs = movieCatalogs;
    }

    // ...
}
```

默认情况下，如果找不到可用的需要注入的类型 bean 是，自动 autowired 就会失败。对于 array、collection 或者 map 来说至少有一个匹配的元素才不会报错。

如果你想改变这种默认情况，让矿建跳过着各种不满足的注入点，你可以通过将 @Autowired 的 required 设置为 false，将它标记为非必须。

```java
public class SimpleMovieLister {

    private MovieFinder movieFinder;

    @Autowired(required = false)
    public void setMovieFinder(MovieFinder movieFinder) {
        this.movieFinder = movieFinder;
    }

    // ...
}
```

当一个方法被标记为 non-required 时，如果他的参数依赖没有人使用，那么改方法将不会被调用；当一个字段被标记为 non-required 时，那么他将不会被填充，只会保存他的默认值

## 1.6 Java 8’s `java.util.Optional`

你也可以通过  Java 8’s `java.util.Optional` 来表示依赖的 non-required。

```java
public class SimpleMovieLister {

    @Autowired
    public void setMovieFinder(Optional<MovieFinder> movieFinder) {
        ...
    }
}
```

## 1.7 `@Nullable`

从 Spring 5.0 开始你可以通过 `@Nullable` 注解来表示依赖的 non-required。

```java
public class SimpleMovieLister {

    @Autowired
    public void setMovieFinder(@Nullable MovieFinder movieFinder) {
        ...
    }
}
```

## 1.8 其他

你可以通过 `@Autowired` 来获取一些众所周知的接口或者他们的拓展接口：`BeanFactory`, `ApplicationContext`, `Environment`, `ResourceLoader`, `ApplicationEventPublisher`, and `MessageSource`；拓展接口： `ConfigurableApplicationContext` 或 `ResourcePatternResolver`。

```java
public class MovieRecommender {

    @Autowired
    private ApplicationContext context;

    public MovieRecommender() {
    }

    // ...
}
```

> `@Autowired`，`@Inject`，`@Value` 和 `@Resource` 注解都是通过 Spring 的 `BeanPostProcessor` 实现的，这意味着您不能在自己的 `BeanPostProcessor` 或 `BeanFactoryPostProcessor` 类型(如果有的话)中应用这些注解，这些自定义的类型必须通过 XML 或者 Spring @Bean 方法连接起来

# 二、`@Primary`

因为通过类型自动装配可能会存在多个候选的 bean，所以控制 bean 的选择过程就十分有必要了。其中一种实现方式就是通过 Spring 的 `@Primary` 注解。 当单值依赖有多个候选 bean 时， `@Primary`  可以指示一个特殊的 bean 当作依赖。如果在多个候选 bean 中恰好只有一个 primary bean，那么他就会成为自动装配的值。

```java
@Configuration
public class MovieConfiguration {

    @Bean
    @Primary
    public MovieCatalog firstMovieCatalog() { ... }

    @Bean
    public MovieCatalog secondMovieCatalog() { ... }

    // ...
}

public class MovieRecommender {

    @Autowired
    private MovieCatalog movieCatalog;

    // ...
}
```

上面这个例子中 `MovieRecommender` 中的 `movieCatalog` 会自动装配 `firstMovieCatalog`。

# 三、使用限定符微调基于注释的自动装配

当通过类型自动装配存在多个候选 bean，但是只有一个 主要的候选bean是，`@Primary` 是非常有效的方式。当你需要更多的控制 bean 的选择过程时，你可以通过 Spring 提供的 `@Qualifier` 注解实现。您可以将限定符值与特定的参数相关联，缩小类型匹配集，以便为每个参数选择特定的 bean。

```java
public class MovieRecommender {

    @Autowired
    @Qualifier("main")
    private MovieCatalog movieCatalog;

    // ...
}
```

你可以指定 `@Qualifier` 注解在构造方法或者普通方法的单个参数上。

```java
public class MovieRecommender {

    private MovieCatalog movieCatalog;

    private CustomerPreferenceDao customerPreferenceDao;

    @Autowired
    public void prepare(@Qualifier("main") MovieCatalog movieCatalog,
            CustomerPreferenceDao customerPreferenceDao) {
        this.movieCatalog = movieCatalog;
        this.customerPreferenceDao = customerPreferenceDao;
    }

    // ...
}
```

> `@Autowired` 注解可以应用在 字段、构造方法、多参数方法中，并且可以通过 qualifier 注解缩小装配的范围。与之相比，`@Resourse` 注解只能被用在 字段和单参数 setter 方法中。所以，如果你需要注入目标是 构造方法或者是多参数方法，那么建议 `@Autowired` 配合 qualifier 注解使用。

# 四、使用泛型作为自动装配的限定词

除了使用 `@Qualifier` 注解作为限定词外，还可以使用 java 的反省类型作为一个隐式的限定词形式。

```java
@Configuration
public class MyConfiguration {

    @Bean
    public StringStore stringStore() {
        return new StringStore();
    }

    @Bean
    public IntegerStore integerStore() {
        return new IntegerStore();
    }
}
```

假设上面的两个 bean 实现了一个泛型接口（比如，分别实现了 `Store<String>` 和 `Store<Integer>` ），当你通过 `@Autowired` 注入 `Store` 时，泛型就会被当作一个限定词。

```java
@Autowired
private Store<String> s1; // <String> qualifier, injects the stringStore bean

@Autowired
private Store<Integer> s2; // <Integer> qualifier, injects the integerStore bean
```

当然泛型的的限定词作用也可以应用在 lists、Map 和 array 上。

```java
// Inject all Store beans as long as they have an <Integer> generic
// Store<String> beans will not appear in this list
@Autowired
private List<Store<Integer>> s;
```

# 五、通过 `@Resoure` 注入

Spring 支持在字段或者 bean 属性的 setter 方法上通过 `@Resource` （`javax.annotation.Resource`）注解注入它们。

`@Resource` 有一个 name 属性，在默认情况下，Spring 会解析该值作为需要注入的 bean 的名字。

```java
public class SimpleMovieLister {

    private MovieFinder movieFinder;

    @Resource(name="myMovieFinder") 
    public void setMovieFinder(MovieFinder movieFinder) {
        this.movieFinder = movieFinder;
    }
}
```

如果 name 属性没有被显式指定，则会使用字段名或者使用属性的 setter 方法的属性名。

```java
public class SimpleMovieLister {

    private MovieFinder movieFinder;

    @Resource
    public void setMovieFinder(MovieFinder movieFinder) {
        this.movieFinder = movieFinder;
    }
}
```

```JAVA
public class MovieRecommender {

    @Resource
    private CustomerPreferenceDao customerPreferenceDao;

    @Resource
    private ApplicationContext context; 

    public MovieRecommender() {
    }

    // ...
}
```

# 六、`@Value`

`@Value` 通常被用作注入外部的属性。

```java
@Component
public class MovieRecommender {

    private final String catalog;

    public MovieRecommender(@Value("${catalog.name}") String catalog) {
        this.catalog = catalog;
    }
}
```

```java
@Configuration
@PropertySource("classpath:application.properties")
public class AppConfig { }
```

`application.properties` 如下所示：

```properties
catalog.name=MovieCatalog
```

此时 `catalog` 的值为 `MovieCatalog`。

Spring 默认情况下提供了一个宽松的嵌入式解析器。他将会尝试解析属性值，如果不能解析，则将注入属性名（例如 `${ catalog.name }`）作为值。如果你想保持严格控制不存在的值，你可以声明一个 `PropertySourcesPlaceholderConfigurer` bean。

```java
@Configuration
public class AppConfig {

    @Bean
    public static PropertySourcesPlaceholderConfigurer propertyPlaceholderConfigurer() {
        return new PropertySourcesPlaceholderConfigurer();
    }
}
```

> 注意声明 `PropertySourcesPlaceholderConfigurer`，`@Bean` 的方法必须是 static。

在使用上面的配置后，如果有任何 `${}` 占位符解析失败都会导致 Spring 初始化失败。还可以使用 setPlaceholderPrefix、 setPlaceholderAffix 或 setValueMolecular ator 等方法来定制占位符。

> `PropertySourcesPlaceholderConfigurer` 默认从 `application.properties` 和 `application.yml` 文件中读取属性值。

Spring 内置的转换器支持简单的类型自动转换（比如：转换为 Integer 或者 int）。多个逗号分隔的值将会被自动转换为 String 类型的 Array 或者集合。

你可以通过下面的这种方式提供一个默认值：

```java
@Component
public class MovieRecommender {

    private final String catalog;

    public MovieRecommender(@Value("${catalog.name:defaultCatalog}") String catalog) {
        this.catalog = catalog;
    }
}
```

Spring `BeanPostProcessor` 在后台使用 `ConversionService` 来处理将 `@Value` 中的字符串值转换为目标类型的过程。如果想为自己的自定义类型提供转换支持，你可以提供一个你自己的 `ConversionService` bean实例。

```java
@Configuration
public class AppConfig {

    @Bean
    public ConversionService conversionService() {
        DefaultFormattingConversionService conversionService = new DefaultFormattingConversionService();
        conversionService.addConverter(new MyCustomConverter());
        return conversionService;
    }
}
```

当 `@Value` 包含一个 [`SpEL` 表达式](https://docs.spring.io/spring-framework/docs/5.3.24/reference/html/core.html#expressions)时，该值将在运行时动态计算。

```java
@Component
public class MovieRecommender {

    private final String catalog;

    public MovieRecommender(@Value("#{systemProperties['user.catalog'] + 'Catalog' }") String catalog) {
        this.catalog = catalog;
    }
}
```

SPEL 还支持使用更复杂的数据结构。

```java
@Component
public class MovieRecommender {

    private final Map<String, Integer> countOfMoviesPerCatalog;

    public MovieRecommender(
            @Value("#{{'Thriller': 100, 'Comedy': 300}}") Map<String, Integer> countOfMoviesPerCatalog) {
        this.countOfMoviesPerCatalog = countOfMoviesPerCatalog;
    }
}
```

