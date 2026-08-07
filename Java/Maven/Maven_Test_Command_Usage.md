# Maven test 命令与单元测试执行指南

## 概述

`mvn test` 是 Maven 中执行单元测试的标准命令。它属于 Maven **默认生命周期（default lifecycle）** 的一个阶段，由 `maven-surefire-plugin` 插件负责实际执行测试并生成报告。理解 `mvn test` 需要掌握三件事：它在生命周期中的位置、Surefire 插件的运行机制、以及常用参数组合。

## 生命周期中的位置

执行 `mvn test` 时，Maven 会按顺序执行 `test` 之前的所有阶段：

```
validate → compile → test-compile → test
```

| 阶段 | 作用 |
| --- | --- |
| validate | 校验项目结构与配置 |
| compile | 编译主代码（`src/main/java`） |
| test-compile | 编译测试代码（`src/test/java`） |
| test | 由 Surefire 插件执行单元测试 |

注意：`mvn test` **不会**打包（package）和安装（install）。如果需要跑完测试后继续打包，执行 `mvn package` 即可（会自动经过 test 阶段）。

> 与集成测试的区别：单元测试用 Surefire（`mvn test`），集成测试通常用 `maven-failsafe-plugin`（`mvn verify`），两者职责分离，后文有说明。

## Surefire 如何识别测试类

Surefire 按**类名模式**自动扫描 `src/test/java` 下的测试类，默认匹配规则：

```
**/Test*.java        （Test 开头）
**/*Test.java        （Test 结尾）
**/*Tests.java       （Tests 结尾）
**/*TestCase.java    （TestCase 结尾）
```

只要类名符合上述模式，且包含 JUnit / TestNG 的测试方法，就会被执行。**不符合命名模式的测试类会被直接忽略**——这是"测试没被执行"最常见的原因之一。

测试框架支持：

- JUnit 5（Jupiter）：Surefire 2.22+ 内置 provider，无需额外依赖
- JUnit 4：内置 provider
- TestNG：内置 provider

## 基本用法

```bash
# 执行当前项目的所有单元测试
mvn test

# 多模块项目：从聚合根执行所有模块的测试
mvn test
```

执行结果输出在控制台，同时生成报告文件：

```
target/surefire-reports/
├── *.txt          # 文本格式结果摘要
└── TEST-*.xml     # XML 格式详细报告（CI 工具消费）
```

## 按条件筛选测试

### -Dtest：按类名/方法名筛选

```bash
# 只运行一个测试类
mvn test -Dtest=UserServiceTest

# 只运行多个测试类（逗号分隔）
mvn test -Dtest=UserServiceTest,OrderServiceTest

# 通配符匹配
mvn test -Dtest='*ServiceTest'
mvn test -Dtest='User*Test'

# 只运行某个测试方法
mvn test -Dtest=UserServiceTest#testCreateUser

# 运行某类的多个方法
mvn test -Dtest=UserServiceTest#testCreateUser+testDeleteUser

# 通配符 + 方法组合
mvn test -Dtest='User*Test#test*'
```

> Windows CMD/PowerShell 下含通配符或 `#` 的参数建议加引号，避免被 shell 解释。

### JUnit 5 标签 / JUnit 4 分类

```bash
# JUnit 5：按 @Tag 标签筛选（Surefire 3.x）
mvn test -Dgroups=fast
mvn test -DexcludedGroups=slow,integration

# JUnit 4：按 @Category 筛选
mvn test -Dgroups=com.example.FastTests
```

## 跳过测试

两个参数含义不同，容易混淆：

| 参数 | 效果 |
| --- | --- |
| `-DskipTests` | 编译测试代码，但**不执行** |
| `-Dmaven.test.skip=true` | **不编译也不执行**测试代码 |

```bash
mvn package -DskipTests             # 常用：打包但跳过测试执行
mvn package -Dmaven.test.skip=true  # 激进：连测试代码都不编译
```

如果项目 POM 里通过 `<skipTests>true</skipTests>` 配置了默认跳过，命令行传 `-DskipTests=false` 可以强制覆盖：

```bash
mvn test -DskipTests=false -Dmaven.test.skip=false
```

## 失败与空结果控制

```bash
# 测试失败不让构建中断（继续跑完并汇总，常用于 CI 收集全量结果）
mvn test -Dmaven.test.failure.ignore=true

# 默认行为：指定了 -Dtest 但没匹配到任何测试时构建报错
# Surefire 3.x 可用此参数放行（多模块联动构建时几乎必加）
mvn test -Dtest=XxxTest -Dsurefire.failIfNoSpecifiedTests=false

# 老版本（2.x）对应的参数
mvn test -Dtest=XxxTest -DfailIfNoTests=false
```

## 多模块项目

多模块（聚合）工程中，测试命令常与模块选择参数组合：

| 参数 | 全称 | 含义 |
| --- | --- | --- |
| `-pl` | `--projects` | 只构建指定模块 |
| `-am` | `--also-make` | 连带构建该模块**依赖**的模块 |
| `-amd` | `--also-make-dependents` | 连带构建**依赖该模块**的模块 |

```bash
# 只测某个模块（要求它依赖的兄弟模块已 install 到本地仓库）
mvn test -pl module-a

# 推荐：连带依赖模块一起构建（兄弟模块未 install 时必须这样）
mvn test -pl module-a -am

# 组合筛选：联动构建 + 只跑指定测试类
mvn test -pl module-a -am -Dtest=XxxTest -Dsurefire.failIfNoSpecifiedTests=false
```

> `-am` 联动时每个参与模块都会执行 test 阶段，`-Dtest=` 过滤器在其他模块匹配不到测试，因此通常要配合 `-Dsurefire.failIfNoSpecifiedTests=false`，否则构建会在第一个"没匹配到测试"的模块上中断。

## 单元测试 vs 集成测试（Surefire vs Failsafe）

| | Surefire | Failsafe |
| --- | --- | --- |
| 命令 | `mvn test` | `mvn verify`（integration-test + verify 阶段） |
| 默认类名模式 | `*Test` / `Test*` / `*TestCase` | `*IT` / `IT*` / `*ITCase` |
| 失败行为 | 立即失败 | 先执行 post-integration-test 清理，verify 阶段才判定失败 |
| 适用 | 快速单元测试 | 依赖外部资源（数据库/容器/服务）的集成测试 |

```bash
# 跳过单元测试、只跑集成测试
mvn verify -DskipTests
```

## POM 中的常用配置

```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-surefire-plugin</artifactId>
            <version>3.2.5</version>
            <configuration>
                <!-- 自定义测试类匹配规则 -->
                <includes>
                    <include>**/*Test.java</include>
                    <include>**/*Spec.java</include>
                </includes>
                <excludes>
                    <exclude>**/*IntegrationTest.java</exclude>
                </excludes>
                <!-- JVM 参数：常见于 JDK 17+ 反射开放、内存设置 -->
                <argLine>-Xmx512m --add-opens java.base/java.lang=ALL-UNNAMED</argLine>
                <!-- 并行执行：按类并行，4 线程 -->
                <parallel>classes</parallel>
                <threadCount>4</threadCount>
                <!-- fork 策略：每个测试类独立 JVM（隔离性好、速度慢） -->
                <forkCount>1</forkCount>
                <reuseForks>false</reuseForks>
                <!-- 项目级默认跳过（可用 -DskipTests=false 覆盖） -->
                <skipTests>false</skipTests>
            </configuration>
        </plugin>
    </plugins>
</build>
```

## 常用命令速查

| 场景 | 命令 |
| --- | --- |
| 跑全部单测 | `mvn test` |
| 跑单个测试类 | `mvn test -Dtest=XxxTest` |
| 跑单个测试方法 | `mvn test -Dtest=XxxTest#methodName` |
| 通配符筛选 | `mvn test -Dtest='*ServiceTest'` |
| 多模块指定模块（连带依赖） | `mvn test -pl module-x -am` |
| 打包跳过测试 | `mvn package -DskipTests` |
| 失败不中断 | `mvn test -Dmaven.test.failure.ignore=true` |
| 指定 JDK 运行（PowerShell） | `$env:JAVA_HOME='D:\java\jdk-21'; mvn test` |
| 指定 JDK 运行（Linux/Mac） | `JAVA_HOME=/path/to/jdk mvn test` |
| 调试模式跑测试（远程调试端口 5005） | `mvn test -Dmaven.surefire.debug -Dtest=XxxTest` |

## 常见问题排查

### 1. Tests are skipped.（测试被跳过）

项目 POM 中配置了 `<skipTests>true</skipTests>` 或 `<maven.test.skip>true</maven.test.skip>`，或命令行传了跳过参数。解决：

```bash
mvn test -DskipTests=false -Dmaven.test.skip=false
```

### 2. No tests matching pattern "Xxx" were executed!

`-Dtest` 指定的类在当前模块不存在。多模块联动构建（`-am`）时属于预期现象，加放行参数：

```bash
-Dsurefire.failIfNoSpecifiedTests=false   # Surefire 3.x
-DfailIfNoTests=false                     # Surefire 2.x
```

### 3. 测试类存在但没被执行

检查类名是否符合 Surefire 默认模式（`*Test`/`Test*`/`*Tests`/`*TestCase`），或在 POM 中自定义 `<includes>`。另外确认测试目录是 `src/test/java` 且被 IDE/Maven 识别为测试源码根。

### 4. JDK 版本不匹配报错

项目要求的 JDK 与 `JAVA_HOME` 指向的版本不一致（如 Spring Boot 3.x 需要 JDK 17+）。构建前切换：

```powershell
# Windows PowerShell
$env:JAVA_HOME='D:\path\to\jdk-21'
mvn -version   # 确认 Java version 已切换
```

```bash
# Linux / macOS
export JAVA_HOME=/path/to/jdk-21
mvn -version
```

### 5. 中文/编码乱码

测试涉及中文断言信息或文件读写时，统一指定 UTF-8：

```bash
mvn test -Dfile.encoding=UTF-8
```

或在 POM 中设置：

```xml
<properties>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
</properties>
```

### 6. 依赖解析失败导致测试编译失败

先确认依赖完整（内网仓库、SNAPSHOT 依赖等），必要时先执行 `mvn install` 安装兄弟模块，或使用 `-am` 联动构建。

## 最佳实践

1. **提交前至少跑一次 `mvn test`**，不要只依赖 IDE 局部运行
2. **CI 流水线用 `mvn verify`** 而非 `mvn test`，给集成测试留位置
3. **本地调试单个测试用 `-Dtest=类名#方法名`**，比全量跑快几个数量级
4. **慢测试打标签隔离**（JUnit 5 `@Tag("slow")`），日常构建排除、夜间构建纳入
5. **测试失败先看 `target/surefire-reports/*.txt`**，比控制台翻日志高效
6. **并行测试谨慎开启**：共享静态状态、端口、文件系统的测试不适合并行
