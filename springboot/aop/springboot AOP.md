![](http://qiniu.zhouhongyin.top/2022/06/05/1654404587-1654404567174-download.png)

```java
@Aspect
@Component
public class LogAdvice {

    private final WrappedLogger logger;

    private final JwtContext jwtContext;

    @Autowired
    public LogAdvice(JwtContext jwtContext) {
        this.logger = WrappedLogger.getLogger(this.getClass(), MarkerFactory.getMarker(OberonConst.Service));
        this.jwtContext = jwtContext;
    }

    /**
     * 要对所有的Controller的方法进行配置
     * 指定包名 controller 下以及它的所有子包
     */
    @Pointcut("execution(* com.qst.ourea.portal.controller..*.*Controller.*(..))")
    public void pointCurt() {}

    @Before("pointCurt()")
    public void logStart(JoinPoint joinPoint) {//切点
        getLoginUser();
        logger.info("请求访问{}开始执行", getRequestURI());
    }

    @After("pointCurt()")
    public void logEnd(JoinPoint joinPoint) {
        logger.info("请求访问{}结束执行", getRequestURI());
    }

    @AfterReturning(value = "pointCurt()", returning = "result")
    public void logReturn(JoinPoint joinPoint, Object result) {
        // 获取方法返回值
        //logger.info("请求访问{}", getRequestURI());
    }

    /**
     * 获取请求uri
     */
    private String getRequestURI(){
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request = attributes.getRequest();
        return request.getRequestURI();
    }

    /**
     * 获取当前登录的用户
     */
    private void getLoginUser(){
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        HttpServletRequest request = attributes.getRequest();
        JwtIdentity identity = jwtContext.getIdentity(request);
        if(identity != null){
            logger.info("访问者id{}，访问者名称{}", identity.getMemberId(), identity.getMemberName());

        } else {
            logger.info("游客登录访问");
        }
    }
}
```

