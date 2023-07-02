BeanFactory处理bean的过程 

1.注册bean Definition  registerBeanDefinition() 

2.bean Definition的合并阶段  getMergedLocalBeanDefinition(),比如user和superUser 最后都变为root bean Definition 

3.创建bean createBean() 

4.将bean类型从string变为class类型 resolveBeanClass() 

5.bean实例化前工作resolveBeforeInstantiation(),比如可以返回自定义的bean对象让spring不在实例化bean对象 6.开始实例化bean doCreateBean() 

7.实例化bean createBeanInstance() 

8.bean实例化后 postProcessAfterInstantiation()返回false即bean不在对属性处理 

9.属性赋值前对属性处理postProcessProperties() 

10.属性赋值applyPropertyValues() 

11.bean初始化阶段initializeBean() 

12.初始化前aware接口回调(非ApplicationContextAware),比如beanFactoryAware 

13.初始化前回调applyBeanPostProcessorsBeforeInitialization(),比如@PostConstructor 

14.初始化invokeInitMethods(),比如实现InitializingBean接口的afterPropertiesSet()方法回调 

15.初始化后的回调applyBeanPostProcessorsAfterInitialization() 

16.bean重新的填充覆盖来更新bean preInstantiateSingletons() 

17.bean销毁前postProcessBeforeDestruction() 

18.bean销毁,比如@PreDestroy