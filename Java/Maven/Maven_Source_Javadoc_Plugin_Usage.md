# Maven Source 与 Javadoc 插件使用说明

## 概述

`maven-source-plugin` 和 `maven-javadoc-plugin` 是 Maven 构建生命周期中常用的两个插件，主要用于在项目打包时自动生成源码包和 API 文档包。方便其他开发者查看源码和接口文档。

## 插件配置

```xml
<build>
    <plugins>
        <!-- 源码插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-source-plugin</artifactId>
            <version>3.3.0</version>
            <executions>
                <execution>
                    <id>attach-sources</id>
                    <phase>verify</phase>
                    <goals>
                        <goal>jar-no-fork</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
        <!-- 文档插件 -->
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-javadoc-plugin</artifactId>
            <version>3.6.3</version>
            <configuration>
                <source>1.8</source>
                <encoding>UTF-8</encoding>
                <doclint>none</doclint>
                <failOnError>false</failOnError>
            </configuration>
            <executions>
                <execution>
                    <id>attach-javadocs</id>
                    <phase>verify</phase>
                    <goals>
                        <goal>jar</goal>
                    </goals>
                </execution>
            </executions>
        </plugin>
    </plugins>
</build>
```

## 插件详解

### maven-source-plugin（源码插件）

| 配置项 | 说明 |
|--------|------|
| `phase` | 绑定到 `verify` 阶段，在 `mvn verify` 或 `mvn deploy` 时执行 |
| `goal` | `jar-no-fork` 表示生成源码 jar 包，不 fork 新进程 |

**作用**：自动生成 `*-sources.jar` 文件，包含项目的所有 `.java` 源文件。

**使用场景**：
- 发布到私服后，其他项目依赖时可自动下载源码
- IDE 中可直接查看依赖库源码，方便调试和学习

### maven-javadoc-plugin（文档插件）

| 配置项 | 说明 |
|--------|------|
| `source` | Java 源码版本，本项目使用 1.8 |
| `encoding` | 文件编码，统一使用 UTF-8 |
| `doclint` | 设置为 `none` 关闭文档格式检查，避免因注释不规范导致构建失败 |
| `failOnError` | 设置为 `false`，即使生成文档出错也继续构建 |
| `phase` | 绑定到 `verify` 阶段 |
| `goal` | `jar` 表示生成 javadoc jar 包 |

**作用**：自动生成 `*-javadoc.jar` 文件，包含项目的 API 文档（HTML 格式）。

**使用场景**：
- 发布到私服后，IDE 可自动加载 API 文档
- 方便其他开发者了解接口用法和参数说明

## 执行时机

两个插件都绑定在 Maven 的 `verify` 阶段，执行以下命令时会自动触发：

```bash
# 本地验证
mvn verify

# 发布到私服（包含 verify 阶段）
mvn deploy
```

## 最终产物

构建完成后，`target` 目录下会生成以下文件：

```
target/
├── base-server-api-1.0.0.jar           # 编译后的 class 文件（主包）
├── base-server-api-1.0.0-sources.jar   # 源码包
└── base-server-api-1.0.0-javadoc.jar   # API 文档包
```

## 注意事项

1. **注释规范**：建议为类和公共方法添加规范的 Javadoc 注释，生成的文档更有价值
2. **编码问题**：确保源文件使用 UTF-8 编码，避免生成文档时出现乱码
3. **构建速度**：javadoc 生成较耗时，开发阶段可跳过：`mvn install -Dmaven.javadoc.skip=true`
4. **适用模块**：通常只需在 API 模块配置，Server 实现模块一般不需要

## 相关链接

- [maven-source-plugin 官方文档](https://maven.apache.org/plugins/maven-source-plugin/)
- [maven-javadoc-plugin 官方文档](https://maven.apache.org/plugins/maven-javadoc-plugin/)
