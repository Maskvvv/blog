# 引言

近期项目遇到不少并发问题，解决的方式就是加锁，但是错误的加锁方式遇到 Spring 事务可能并不能达到预期效果。

# 问题分析

```java
@RestController
@RequestMapping("user")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping("add")
    public String add(@RequestBody User user) {
        String res = userService.add(user);
        return res;
    }
}

@Service
public class UserService {

    @Autowired
    private UserAccessor userAccessor;
    
    @Transactional
    public String add(User user) {
        
        // 如果用户不存在则添加该用户
        User user = userAccessor.choseOne(user.getId());
        if(user == null) {
            userAccessor.add(user);
        }
        
        return "success";

    }
}
```

上面的代码业务非常简单，就是当用户不存在时添加该用户，但是由于**判断用户是否存在和添加用户不是原子性**的，当并发上来或者某些原因导致请求在几毫秒内请求了多次可能会存在多条一样的用户记录问题，user 数据库一般有关于 user 的唯一索引，所以问题不大，到时候报错就是了，但是有些业务场景没办法加唯一索引，就可能存在多条重复数据了，解决办法有可能是下面这样，在查询用户是否存在和添加用户前后加锁释放锁，已保证查询用户和插入用户操作是原子性的，代码如下：

```java
....Controller

@Service
public class UserService {

    @Autowired
    private UserAccessor userAccessor;
    
    // 锁（伪代码，演示用）
    @Autowired
    Lock lock;
    
    @Transactional
    public String add(User user) {
        
        // 对用户id加锁
        String key = user.getId();
        lock.lcok(key);
        
        // 如果用户不存在则添加该用户
        User user = userAccessor.choseOne(user.getId());
        if(user == null) {
            userAccessor.add(user);
        }
        
        lock.unlock(user.getId);
 
        return "success";

    }
}
```

上面的代码对吗，我们分析一下：

当有两个线程同时添加同一个用户时：

|      |               Thread1               |                  Thread2                   |
| :--: | :---------------------------------: | :----------------------------------------: |
|  T1  |              开启事务               |                  开启事务                  |
|  T2  |   `lock.lcok(key);` （加锁成功）    |          `lock.lcok(key);` (阻塞)          |
|  T3  |    查询用户是否存在 -> user为空     |                                            |
|  T4  |       user 为空 -> 插入该用户       |                                            |
|  T5  | `lock.unlock(user.getId);` （解锁） |                                            |
|  T6  |                                     | （线程被唤醒）查询用户是否存在 -> user为空 |
|  T7  |              提交事务               |          user 为空 -> 插入该用户           |
|  T8  |                                     |    `lock.unlock(user.getId);` （解锁）     |
|  T9  |                                     |                  提交事务                  |

可以看到最终数据库会有两条重复的 user 数据，导致该问题的原因是什么呢： Thread1 在提交事务之前就释放了锁，导致 Thread2 被唤醒时查询 Thread1 刚刚插入的那条用户查询不到的，所以导致了这个问题。

> 由于 @Transactional 是通过 AOP 实现的，会在目标方法执行前和执行后进行开启事务和提交事务。
>
> 源码位置：`org.springframework.transaction.interceptor.TransactionAspectSupport#invokeWithinTransaction()`

# 解决方案

其实解决方法很简单只要让加锁和释放锁的操作在开启事务和提交事务的外层就可以了，具体流程如下：

1. 生成需要加锁的 key
2. 加锁
3. 开启事务
4. 执行业务
5. 提交事务
6. 解锁

下面举两种方案，其他方式都大同小异：

## 编程式事务

```java
....Controller

@Service
public class UserService {
    
    @Autowired
	private PlatformTransactionManager transactionManager;

    @Autowired
    private UserAccessor userAccessor;
    
    // 锁（伪代码，演示用）
    @Autowired
    Lock lock;
    
    public String add(User user) {
        
        // 对用户id加锁
        String key = user.getId();
        lock.lcok(key);
        
          TransactionStatus status = transactionManager.getTransaction(new DefaultTransactionDefinition());
          try {
               // 如果用户不存在则添加该用户
               User user = userAccessor.choseOne(user.getId());
               if(user == null) {
                   userAccessor.add(user);
               }
               transactionManager.commit(status);
          } catch (Exception e) {
              transactionManager.rollback(status);
          }
        
        lock.unlock(user.getId);
 
        return "success";

    }
}
```

## 声明式事务

```java
@RestController
@RequestMapping("user")
public class UserController {

    @Autowired
    private UserService userService;
    
    // 锁（伪代码，演示用）
    @Autowired
    Lock lock;
    
    @PostMapping("add")
    public String add(@RequestBody User user) {
        // 对用户id加锁
        String key = user.getId();
        lock.lcok(key);
        
        String res = userService.add(user);
        
        lock.unlock(user.getId);
        
        return res;
    }
}

@Service
public class UserService {

    @Autowired
    private UserAccessor userAccessor;
    
    @Transactional
    public String add(User user) {
        
        // 如果用户不存在则添加该用户
        User user = userAccessor.choseOne(user.getId());
        if(user == null) {
            userAccessor.add(user);
        }
        
        return "success";

    }
}
```

# 通过 AOP 实现对锁的统一管理

通过上文可知，只要保证锁和事务的先后顺序就可已保证锁的正确型，两种解决方案的也都是通过这个流程解决的，那么我们是不是可以通过 AOP 实现对锁的统一不用在遇到需要加锁的地方就写一遍冗余代码呢，答案肯定是可以的。

## 需求分析

来看一下我们要统一管理锁要解决哪些问题

### 加锁的 key 如何获取

在切面中我们可以拿到目标方法的执行参数，但是各个业务场景需要加锁的 key 肯定是不同的，我们当然可以规定需要加锁的目标方法的第一的方法参数必须是需要加锁的 key，但是这对业务的侵入性太大了，肯定是不能接受的。

### 加锁的方式

现在许多项目都是集群部署，加锁的时候都是加分布式锁，而有些项目是单机部署，或者不许要保证集群间的并发问题，所以可能会加单机锁比如说通过 ReentrantLock 进行加锁，所以我们需要对不同的场景有相应的拓展点，供自由选择。

## 实现

这里讲一下大体实现思路。

### 注解

我们需要一个注解来 标注需要切入的目标方法、指定生成需要加锁 key 的方式和加锁的方式。

```java
@Target({ElementType.METHOD})
@Retention(RetentionPolicy.RUNTIME)
public @interface AthenaLock {

    String prefix() default "";

    Class<? extends KeyConvert>[] keyConvert() default {};

    String spEl() default "";

    String keySeparator() default ":";

    long leaseTime() default 10 * 1000;

    Class<? extends AthenaLockProcessor>[] lockProcessor() default {};
}
```

看下该注解都有哪些东西：

- prefix：前缀，可以定义为和项目相关
- keyConvert：key 生成器
- spEl：spEL 表达式

以上三个定义其中一个即可，都定义会通过 keySeparator 进行拼接，都为空会抛异常。

- leaseTime：锁的过期时间
- lockProcessor：锁执行器，是一个拓展点，可以实现为分布式锁，也可以是单机锁

### 锁执行器

```java
public interface AthenaLockProcessor {

    Object proceed(ProceedingJoinPoint joinPoint, String key, long leaseTime) throws Throwable;

}
```

我们 AOP 的 Around Advise 不会执行 joinPoint，而是会将 joinPoint 交给 `AthenaLockProcessor` 的实现类，方便对目标方法进行加锁。

框架提供一个默认实现，单机锁版本。

```java
@Component
public class DefaultLockProcessor implements AthenaLockProcessor {

    @Override
    public Object proceed(ProceedingJoinPoint joinPoint, String key, long leaseTime) throws Throwable {
        synchronized (key.intern()) {
            return joinPoint.proceed();
        }
    }
}
```

建议根据项目具体情况实现一个自己的 `LockProcessor`，我们项目用的 `Redisson` 如下所示。**记得加上 @Primary 注解，这样在注解中不指定 `lockProcessor` 属性时，会默认使用该实现。**

```java
@Primary
@Component
public class RedissonLockProcessor implements AthenaLockProcessor {

    private final Redisson redisson;

    public RedissonLockProcessor(Redisson redisson) {
        this.redisson = redisson;
    }

    @Override
    public Object proceed(ProceedingJoinPoint joinPoint, String key, long leaseTime) throws Throwable {
        RLock lock = null;
        try {
            lock = redisson.getLock(key);
            if (leaseTime > 0) {
                lock.lock(leaseTime, TimeUnit.MILLISECONDS);
            } else {
                lock.lock();
            }

            return joinPoint.proceed();
        } catch (Exception e) {
            throw new RuntimeException(e);
        } finally {
            if (lock != null && lock.isLocked()) {
                lock.unlock();
            }
        }
    }
}
```

### 加锁 key 的获取

**方式一：`KeyConvert` 生成器**

```java
public interface KeyConvert {
    String getKey(Object... params);
}
```

对于需要加锁的目标方法，我们通过定义 `KeyConvert` 的实现类，在注解 `keyConvert` 属性中指定该实现类的 Class 就可已解决我们上面提到的 “加锁的 key 如何获取” 的问题了

**方式二：spEL**

spEL 功能强大，只需要通过一行字符串就可以，获取对象，获取 bean，执行方法等等操作，通过 spEL 我们就不用为每个需要加锁的 key 定义一个 `KeyConvert` 的实现类了。

spEL 虽然功能强大，但是使用的变量是需要出现在 spEL 上下文中的，框架目前只将目标方法的参数加入到了上下文中，你可已直接使用，如果你有其他的需求可以实现 `AthenaLockSpELContextPostProcessor` 的实现类：

```java
public interface AthenaLockSpELContextPostProcessor {

    void postProcess(StandardEvaluationContext context);

}
```

比如说我想在 spEL 中直接使用 fastjson 的 `toJSONString()` 方法将目标方法的参数转换为 json 作为加锁的键，你可以像下面这样：

```java
@Component
public class JsonSpELContextPostProcessor implements AthenaLockSpELContextPostProcessor {


    @Override
    public void postProcess(StandardEvaluationContext context) {
        try {
            context.setVariable("json", JSON.class.getMethod("toJSONString", Object.class));
        } catch (NoSuchMethodException e) {
            throw new RuntimeException(e);
        }
    }

}
```

### 切面

```java
@Aspect
@Component
public class AthenaLockAspect implements Ordered {

    private final AthenaLockProcessor lock;
    private final Map<Class<?>, AthenaLockProcessor> lockMap = new HashMap<>();
    private final Map<Class<?>, KeyConvert> keyConvertMap = new HashMap<>();
    private final List<AthenaLockSpELContextPostProcessor> contextPostProcessors;

    public AthenaLockAspect(List<AthenaLockProcessor> lockList, List<KeyConvert> keyConvertList,
                            @Autowired(required = false) AthenaLockProcessor lock, List<AthenaLockSpELContextPostProcessor> contextPostProcessors) {
        this.lock = lock;
        this.contextPostProcessors = contextPostProcessors;
        for (AthenaLockProcessor athenaLockProcessor : lockList) {
            lockMap.put(athenaLockProcessor.getClass(), athenaLockProcessor);
        }

        for (KeyConvert keyConvert : keyConvertList) {
            keyConvertMap.put(keyConvert.getClass(), keyConvert);
        }
    }


    @Pointcut("@annotation(com.zhy.spring.aop.lock.AthenaLock)")
    public void pointCut() {
    }

    @Around("pointCut()")
    public Object around(ProceedingJoinPoint joinPoint) throws Throwable {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        Method method = signature.getMethod();
        AthenaLock annotation = method.getAnnotation(AthenaLock.class);

        String key = generateKey(joinPoint);

        return lockAndProceed(joinPoint, annotation, key);
    }

    private Object lockAndProceed(ProceedingJoinPoint joinPoint, AthenaLock annotation, String key) throws Throwable {
        Class<? extends AthenaLockProcessor>[] lockClazzs = annotation.lockProcessor();
        AthenaLockProcessor lockProcessor = lock;
        if (lockClazzs.length > 0) {
            lockProcessor = lockMap.get(lockClazzs[0]);
        }

        return lockProcessor.proceed(joinPoint, key, annotation.leaseTime());
    }

    private String generateKey(ProceedingJoinPoint joinPoint) {
        MethodSignature signature = (MethodSignature) joinPoint.getSignature();
        String[] parameterNames = signature.getParameterNames();
        Object[] args = joinPoint.getArgs();
        Method method = signature.getMethod();
        AthenaLock annotation = method.getAnnotation(AthenaLock.class);

        String prefix = annotation.prefix();
        String convertKey = parserKeyConvert(annotation, args);
        String spELKey = parserSpEL(parameterNames, args, annotation);
        return keyJoin(annotation.keySeparator(), prefix, convertKey, spELKey);
    }

    private String parserKeyConvert(AthenaLock annotation, Object[] args) {
        Class<? extends KeyConvert>[] classes = annotation.keyConvert();
        if (ObjectUtils.isEmpty(classes)) {
            return "";
        }

        Class<? extends KeyConvert> keyConvertClass = classes[0];
        KeyConvert keyConvert = keyConvertMap.get(keyConvertClass);

        return keyConvert.getKey(args);
    }

    private String parserSpEL(String[] parameterNames, Object[] args, AthenaLock annotation) {
        String expressionString = annotation.spEl();
        if (StringUtils.isEmpty(expressionString)) return expressionString;

        ExpressionParser parser = new SpelExpressionParser();
        StandardEvaluationContext context = new StandardEvaluationContext();

        for (int i = 0; i < parameterNames.length; i++) {
            context.setVariable(parameterNames[i], args[i]);
        }

        for (AthenaLockSpELContextPostProcessor contextPostProcessor : contextPostProcessors) {
            contextPostProcessor.postProcess(context);
        }

        return parser.parseExpression(expressionString, new TemplateParserContext()).getValue(context, String.class);
    }

    private String keyJoin(String delimiter, String... keys) {
        StringBuilder stringBuilder = new StringBuilder();

        for (int i = 0; i < keys.length; i++) {
            String k = keys[i];
            if (!StringUtils.isEmpty(k)) {
                stringBuilder.append(k).append(delimiter);
            }
        }

        if (stringBuilder.length() > 1) {
            stringBuilder.deleteCharAt(stringBuilder.length() - 1);
            return stringBuilder.toString();
        }

        throw new RuntimeException("lock key is null!");
    }

    @Override
    public int getOrder() {
        return Ordered.LOWEST_PRECEDENCE - 1;
    }
}
```

切面类就不详细说了，大体过程如下：

1. 通过目标方法注解中的 `prefix`、`keyConvert`、`spEl` 生成需要加锁的 key
2. 选择合适的 `AthenaLockProcessor` 执行

> `@Transactional` 切面的 Order 为 `Ordered.LOWEST_PRECEDENCE`，我们需要保证我们的切面在他前面执行，所以我们 Order 定义为 `Ordered.LOWEST_PRECEDENCE - 1` 就可以了

## 使用

下面我们看看怎么通过我们的方式解决上面遇到的并发问题。例子再贴一下，方便查看

```java
@RestController
@RequestMapping("user")
public class UserController {

    @Autowired
    private UserService userService;

    @PostMapping("add")
    public String add(@RequestBody User user) {
        String res = transactionService.add(user);
        return res;
    }
}

@Service
public class UserService {

    @Autowired
    private UserAccessor userAccessor;
    
    @Transactional
    public String add(User user) {
        
        // 如果用户不存在则添加该用户
        User user = userAccessor.choseOne(user.getId);
        if(user == null) {
            userAccessor.add(user);
        }
        
        return "success";

    }
}
```

### 通过 `KeyConvert` 生成器

定义 `KeyConvert` 实现类

```java
@Component
public class UserKeyConvert implements KeyConvert {

    @Override
    public String getKey(Object... params) {
        User user = (User) params[0];

        return user.getId();
    }
}
```

定义注解

```java
@Service
public class UserService {

    @Autowired
    private UserAccessor userAccessor;
    
    //@AthenaLock(keyConvert = UserKeyConvert.class, lockProcessor = RedissonLockProcessor.class)
    @AthenaLock(keyConvert = UserKeyConvert.class)
    @Transactional
    public String add(User user) {
        
        // 如果用户不存在则添加该用户
        User user = userAccessor.choseOne(user.getId);
        if(user == null) {
            userAccessor.add(user);
        }
        
        return "success";

    }
}
```

> @AthenaLock 中 lockProcessor 不指定就用默认的或者 @Primary 标注的

### 通过 spEL

```java
@Service
public class UserService {

    @Autowired
    private UserAccessor userAccessor;
    
    @AthenaLock(spEl = "#{ #user.getId() }
    @Transactional
    public String add(User user) {
        
        // 如果用户不存在则添加该用户
        User user = userAccessor.choseOne(user.getId);
        if(user == null) {
            userAccessor.add(user);
        }
        
        return "success";

    }
}
```

可以看到不管通过哪种方式实现，都可以通过 1-2 步操作实现对目标业务的加锁，可以说是非常方便了。

## 注意事项

1. 框架通过注解中的  `prefix`、`keyConvert`、`spEl` 生成需要加锁的 key，都为空会抛异常，所以建议，再目标方法前校验需要加锁的字段是否是空。
2. spEL 虽然方便，但是表达式的解析是 cup 密集型的，可能会对项目性能有影响
3. spEL 虽然方便，但是由于他是字符串，后面可能会有维护上的问题
4. `KeyConvert` 相比于 spEL 非常适合于需要加锁的 key 生成非常复杂的场景，他除了 需要为每个加锁的场景都需要定义一个实现类外，没有缺点，而且维护起来方便许多，所以推荐。