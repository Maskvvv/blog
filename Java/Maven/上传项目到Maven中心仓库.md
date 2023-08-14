本文介绍了将一个自己在 github 上的开源项目上传到 Maven 中心仓库的过程

# 一、注册 Sonatype JIRA 账号

https://issues.sonatype.org/secure/Signup!default.jspa

# 二、创建 issue

![](http://qiniu.zhouhongyin.top/2023/08/05/1691204962-image-20230805110922051.png)

![](http://qiniu.zhouhongyin.top/2023/08/05/1691204996-image-20230805110956270.png)

# 三、创建一个临时 github 仓库

创建完毕 issue 后，处理问题的机器人会评论你的 issue，让你**创建一个以问题 id 为名的问题仓库**，证明这个 github 账号是你的。

然后将 issue 的状态改为 **open**。

![](http://qiniu.zhouhongyin.top/2023/08/05/1691206192-image-20230805112951950.png)

之后，机器人会告诉你可以上传项目到 中心仓库了。

![](http://qiniu.zhouhongyin.top/2023/08/05/1691206410-image-20230805113330755.png)

可以登录看看 https://s01.oss.sonatype.org

![](http://qiniu.zhouhongyin.top/2023/08/05/1691209590-image-20230805122630447.png)

# 四、安装和使用 GPG（GnuPG）

基于网络的开源项目，能给用户带来在公共标准基础上的自由发挥，并且能很好地给每个自愿人士提供了共享贡献的机会。但是，同时也因为大众化给使用共享的程序员或团队带来了安全性问题。

当程序员从中央仓库下载第三方构件的时候，下载的文件有可能被另外一个人篡改过，从而破坏代码。为了确定下载的内容是正确的，一般在发布自己构件的同时，还会发布一个签名认证文件。

使用者在使用下载的第三方构件前，先通过签名验证后，确定没有被篡改后再安心使用。GPG 就是这样一个认证签名技术。

接下来就介绍如何使用 GPG 技术，为发布的 [Maven](https://blog.csdn.net/maven/) 构件签名，从而提高项目的安全性。

GnuPG，简称 GPG，来自 [http://www.gnupg.org](http://www.gnupg.org/)，是 GPG 标准的一个免费实现。不管是 Linux 还是 Windows 平台，都可以使用。GPGneng 可以为文件生成签名、管理密匙以及验证签名。

## 4.1 下载 GPG

https://www.gnupg.org/download/

![](http://qiniu.zhouhongyin.top/2023/08/05/1691206644-image-20230805113724629.png)

安装就不说了，一路下一步。

## 4.2 生成密钥对

![image-20230805121021385](http://qiniu.zhouhongyin.top/2023/08/05/1691208621-image-20230805121021385.png)

![](http://qiniu.zhouhongyin.top/2023/08/05/1691208695-image-20230805121135739.png)

输入 passphrase ，后面要有记住

![](http://qiniu.zhouhongyin.top/2023/08/05/1691208716-image-20230805121156225.png)

![image-20230805121240773](http://qiniu.zhouhongyin.top/2023/08/05/1691208760-image-20230805121240773.png)

发布公钥到服务器。

![](http://qiniu.zhouhongyin.top/2023/08/05/1691208797-image-20230805121317797.png)

# 五、配置 Maven setting.xml

```xml
  <servers>
	  <server>
        <id>ossrh</id>
        <username>SonaType账号</username>
        <password>填你注册SonaType时填写的密码</password>
	  </server>
  </servers>
 
  <profiles>
    <profile>
      <id>ossrh</id>
      <activation>
        <activeByDefault>true</activeByDefault>
      </activation>
      <properties>
        <gpg.executable>gpg</gpg.executable>
        <gpg.passphrase>填写你生成秘钥时输入的密码</gpg.passphrase>
      </properties>
    </profile>
  </profiles>
```

# 六、修改项目 pom.xml 文件

```xml
<!--groupId 要和你上面 issue 里写的一样-->
<groupId>io.github.maskvvv</groupId>
<artifactId>easy-flink-cdc</artifactId>
<packaging>pom</packaging>
<!-- -SNAPSHOT 结尾则上传到 SNAPSHOT 仓库-->
<version>1.0.0</version>


<!--项目信息-->
<name>easy-flink-cdc</name>
<description>easy use for flink-cdc</description>
<url>https://github.com/Maskvvv/easy-flink-cdc</url>

<!--开源协议...-->
<licenses>
    <license>
        <name>The Apache Software License, Version 2.0</name>
        <url>http://www.apache.org/licenses/LICENSE-2.0.txt</url>
    </license>
</licenses>

<!--开发者信息-->

<developers>
    <developer>
        <id>henrie chou</id>
        <name>henrie chou</name>
        <email>zhouhongyin1998@gmail.com</email>
        <roles>
            <role>Project Manager</role>
            <role>Architect</role>
        </roles>
        <timezone>+8</timezone>
    </developer>
</developers>

<!--项目在github或其它托管平台的地址-->

<scm>
    <connection>https://github.com/Maskvvv/easy-flink-cdc.git</connection>
    <developerConnection>git@github.com:Maskvvv/easy-flink-cdc.git</developerConnection>
    <url>https://github.com/Maskvvv/easy-flink-cdc</url>
</scm>

<profiles>
    <profile>
        <!--注意,此id必须与setting.xml中指定的一致,不要自作聪明改它名字-->
        <id>ossrh</id>
        <activation>
            <activeByDefault>true</activeByDefault>
        </activation>
        <build>
            <!--发布到中央SNAPSHOT仓库插件-->
            <plugins>
                <plugin>
                    <groupId>org.sonatype.plugins</groupId>
                    <artifactId>nexus-staging-maven-plugin</artifactId>
                    <version>1.6.7</version>
                    <extensions>true</extensions>
                    <configuration>
                        <serverId>ossrh</serverId>
                        <nexusUrl>https://s01.oss.sonatype.org/</nexusUrl>
                        <autoReleaseAfterClose>true</autoReleaseAfterClose>
                    </configuration>
                </plugin>

                <!--生成源码插件-->
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-source-plugin</artifactId>
                    <version>2.2.1</version>
                    <executions>
                        <execution>
                            <id>attach-sources</id>
                            <goals>
                                <goal>jar-no-fork</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>

                <!--生成API文档插件-->
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-javadoc-plugin</artifactId>
                    <version>2.9.1</version>
                    <executions>
                        <execution>
                            <id>attach-javadocs</id>
                            <goals>
                                <goal>jar</goal>
                            </goals>
                            <configuration>
                                <additionalparam>-Xdoclint:none</additionalparam>
                            </configuration>
                        </execution>
                    </executions>
                </plugin>

                <!--gpg插件-->
                <plugin>
                    <groupId>org.apache.maven.plugins</groupId>
                    <artifactId>maven-gpg-plugin</artifactId>
                    <version>1.5</version>
                    <executions>
                        <execution>
                            <id>sign-artifacts</id>
                            <phase>verify</phase>
                            <goals>
                                <goal>sign</goal>
                            </goals>
                        </execution>
                    </executions>
                </plugin>

            </plugins>
        </build>

        <distributionManagement>
            <snapshotRepository>
                <!--注意,此id必须与setting.xml中指定的一致-->
                <id>ossrh</id>
                <url>https://s01.oss.sonatype.org/content/repositories/snapshots</url>
            </snapshotRepository>
            <repository>
                <id>ossrh</id>
                <url>https://s01.oss.sonatype.org/service/local/staging/deploy/maven2/</url>
            </repository>
        </distributionManagement>
    </profile>

</profiles>
```

完整 xml。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>io.github.maskvvv</groupId>
    <artifactId>easy-flink-cdc</artifactId>
    <packaging>pom</packaging>
    <version>1.0.0</version>
    <modules>
        <module>easy-flink-cdc-boot-starter</module>
        <module>easy-flink-cdc-demo</module>
    </modules>

    <name>easy-flink-cdc</name>
    <description>easy use for flink-cdc</description>
    <url>https://github.com/Maskvvv/easy-flink-cdc</url>

    <licenses>
        <license>
            <name>The Apache Software License, Version 2.0</name>
            <url>http://www.apache.org/licenses/LICENSE-2.0.txt</url>
        </license>
    </licenses>

    <developers>
        <developer>
            <id>henrie chou</id>
            <name>henrie chou</name>
            <email>zhouhongyin1998@gmail.com</email>
            <roles>
                <role>Project Manager</role>
                <role>Architect</role>
            </roles>
            <timezone>+8</timezone>
        </developer>
    </developers>

    <scm>
        <connection>https://github.com/Maskvvv/easy-flink-cdc.git</connection>
        <developerConnection>git@github.com:Maskvvv/easy-flink-cdc.git</developerConnection>
        <url>https://github.com/Maskvvv/easy-flink-cdc</url>
    </scm>

    <properties>

        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <maven.compiler.encoding>UTF-8</maven.compiler.encoding>

        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
        <java.version>1.8</java.version>
        <lombok.version>1.18.12</lombok.version>
        <es-rest-high-level-client.version>7.14.0</es-rest-high-level-client.version>
        <es.version>7.14.0</es.version>
        <fastjson.version>1.2.83</fastjson.version>
        <codec.version>1.13</codec.version>
        <spring-boot.version>2.6.10</spring-boot.version>
        <maven-jar-plugin.version>3.2.2</maven-jar-plugin.version>
    </properties>

    <dependencyManagement>
        <dependencies>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-autoconfigure</artifactId>
                <version>${spring-boot.version}</version>
            </dependency>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-configuration-processor</artifactId>
                <version>${spring-boot.version}</version>
            </dependency>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-starter-logging</artifactId>
                <version>${spring-boot.version}</version>
            </dependency>
            <dependency>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-starter-log4j2</artifactId>
                <version>${spring-boot.version}</version>
            </dependency>


            <dependency>
                <groupId>com.alibaba</groupId>
                <artifactId>fastjson</artifactId>
                <version>${fastjson.version}</version>
            </dependency>
        </dependencies>
    </dependencyManagement>


    <profiles>
        <profile>
            <!--注意,此id必须与setting.xml中指定的一致,不要自作聪明改它名字-->
            <id>ossrh</id>
            <activation>
                <activeByDefault>true</activeByDefault>
            </activation>
            <build>
                <!--发布到中央SNAPSHOT仓库插件-->
                <plugins>
                    <plugin>
                        <groupId>org.sonatype.plugins</groupId>
                        <artifactId>nexus-staging-maven-plugin</artifactId>
                        <version>1.6.7</version>
                        <extensions>true</extensions>
                        <configuration>
                            <serverId>ossrh</serverId>
                            <nexusUrl>https://s01.oss.sonatype.org/</nexusUrl>
                            <autoReleaseAfterClose>true</autoReleaseAfterClose>
                        </configuration>
                    </plugin>

                    <!--生成源码插件-->
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-source-plugin</artifactId>
                        <version>2.2.1</version>
                        <configuration>
                            <encoding>utf8</encoding>
                        </configuration>
                        <executions>
                            <execution>
                                <id>attach-sources</id>
                                <goals>
                                    <goal>jar-no-fork</goal>
                                </goals>
                            </execution>
                        </executions>
                    </plugin>

                    <!--生成API文档插件-->
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-javadoc-plugin</artifactId>
                        <version>2.9.1</version>
                        <configuration>
                            <encoding>utf8</encoding>
                        </configuration>
                        <executions>
                            <execution>
                                <id>attach-javadocs</id>
                                <goals>
                                    <goal>jar</goal>
                                </goals>
                            </execution>
                        </executions>
                    </plugin>

                    <!--gpg插件-->
                    <plugin>
                        <groupId>org.apache.maven.plugins</groupId>
                        <artifactId>maven-gpg-plugin</artifactId>
                        <version>1.5</version>
                        <executions>
                            <execution>
                                <id>sign-artifacts</id>
                                <phase>verify</phase>
                                <goals>
                                    <goal>sign</goal>
                                </goals>
                            </execution>
                        </executions>
                    </plugin>

                </plugins>
            </build>

            <distributionManagement>
                <snapshotRepository>
                    <!--注意,此id必须与setting.xml中指定的一致-->
                    <id>ossrh</id>
                    <url>https://s01.oss.sonatype.org/content/repositories/snapshots</url>
                </snapshotRepository>
                <repository>
                    <id>ossrh</id>
                    <url>https://s01.oss.sonatype.org/service/local/staging/deploy/maven2/</url>
                </repository>
            </distributionManagement>
        </profile>

    </profiles>


</project>
```

# 七、打包  发布

![](http://qiniu.zhouhongyin.top/2023/08/05/1691210053-image-20230805123413456.png)

> 踩坑 maven 打包报错：编码GBK的不可映射字符：
>
> 解决方法 https://blog.csdn.net/qq_53316135/article/details/121242773

项目的版本号以 `-SNAPSHOT` 结尾则上传到 SNAPSHOT 仓库，其他则上传到中心仓库。

去 nexus 上看看上传成功没。https://s01.oss.sonatype.org/

![](http://qiniu.zhouhongyin.top/2023/08/05/1691210278-image-20230805123758706.png)

# 八、搜索

等一段时间就可以在中心仓库搜索到了。

https://repo1.maven.org/maven2/

![](http://qiniu.zhouhongyin.top/2023/08/05/1691210420-image-20230805124020001.png)

https://central.sonatype.com/?smo=true

![](http://qiniu.zhouhongyin.top/2023/08/05/1691210434-image-20230805124034455.png)