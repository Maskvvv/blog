# 一、安装 online 版的 LibreOffice

## 1.1 使用 docker 安装 

```shell
docker run -t -d -p 9980:9980  -e "username=admin" -e "password=123456" -e "extra_params=--o:ssl.enable=false --o:net.post_allow.host[0]=::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" --restart always --privileged --cap-add MKNOD libreoffice/online
```

> 命令解释：
>
> - `--privileged`：为这个容器提供扩展权限，不加的化容器内会出现 **Operation not permitted** 的错误。
> - `-o:ssl.enable=false`： 关闭 ssl 请求做 HTTP.
> - `-o:net.post_allow.host[0]=::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}`：开放所有 IP 访问 LibreOffice
> - `-e "username=admin" -e "password=123456"`：设置访问 web 页面的账号密码

## 1.2 配置 LibreOffice（可以跳过）

### 修改配置文件

LibreOffice 的配置文件放在了容器的 `/etc/loolwsd/loolwsd.xml` 路径下。

```shell
# 将配置文件考出来修改
docker cp 容器id:/etc/loolwsd/loolwsd.xml /root/libreoffice/loolwsd.xml

# 修改完毕后放回容器
docker cp /root/libreoffice/loolwsd.xml 容器id:/etc/loolwsd/loolwsd.xml
```

#### 配置文件模板

```xml
<config>

    <!-- Note: 'default' attributes are used to document a setting's default value as well as to use as fallback. -->
    <!-- Note: When adding a new entry, a default must be set in WSD in case the entry is missing upon deployment. -->

    <allowed_languages desc="List of supported languages of Writing Aids (spell checker, grammar checker, thesaurus, hyphenation) on this instance. Allowing too many has negative effect on startup performance." default="de_DE en_GB en_US es_ES fr_FR it nl pt_BR pt_PT ru">de_DE en_GB en_US es_ES fr_FR it nl pt_BR pt_PT ru</allowed_languages>

    <sys_template_path desc="Path to a template tree with shared libraries etc to be used as source for chroot jails for child processes." type="path" relative="true" default="systemplate"></sys_template_path>
    <child_root_path desc="Path to the directory under which the chroot jails for the child processes will be created. Should be on the same file system as systemplate and lotemplate. Must be an empty directory." type="path" relative="true" default="jails"></child_root_path>
    <mount_jail_tree desc="Controls whether the systemplate and lotemplate contents are mounted or not, which is much faster than the default of linking/copying each file." type="bool" default="true"></mount_jail_tree>

    <server_name desc="External hostname:port of the server running loolwsd. If empty, it's derived from the request (please set it if this doesn't work). Must be specified when behind a reverse-proxy or when the hostname is not reachable directly." type="string" default=""></server_name>
    <file_server_root_path desc="Path to the directory that should be considered root for the file server. This should be the directory containing loleaflet." type="path" relative="true" default="loleaflet/../"></file_server_root_path>

    <memproportion desc="The maximum percentage of system memory consumed by all of the LibreOffice Online Personal, after which we start cleaning up idle documents" type="double" default="80.0"></memproportion>
    <num_prespawn_children desc="Number of child processes to keep started in advance and waiting for new clients." type="uint" default="1">1</num_prespawn_children>
    <per_document desc="Document-specific settings, including LO Core settings.">
        <max_concurrency desc="The maximum number of threads to use while processing a document." type="uint" default="4">4</max_concurrency>
        <batch_priority desc="A (lower) priority for use by batch eg. convert-to processes to avoid starving interactive ones" type="uint" default="5">5</batch_priority>
        <document_signing_url desc="The endpoint URL of signing server, if empty the document signing is disabled" type="string" default=""></document_signing_url>
        <redlining_as_comments desc="If true show red-lines as comments" type="bool" default="false">false</redlining_as_comments>
        <idle_timeout_secs desc="The maximum number of seconds before unloading an idle document. Defaults to 1 hour." type="uint" default="3600">3600</idle_timeout_secs>
        <!-- Idle save and auto save are checked every 30 seconds -->
        <!-- They are disabled when the value is zero or negative. -->
        <idlesave_duration_secs desc="The number of idle seconds after which document, if modified, should be saved. Defaults to 30 seconds." type="int" default="30">30</idlesave_duration_secs>
        <autosave_duration_secs desc="The number of seconds after which document, if modified, should be saved. Defaults to 5 minutes." type="int" default="300">300</autosave_duration_secs>
        <always_save_on_exit desc="On exiting the last editor, always perform the save, even if the document is not modified." type="bool" default="false">false</always_save_on_exit>
        <limit_virt_mem_mb desc="The maximum virtual memory allowed to each document process. 0 for unlimited." type="uint">0</limit_virt_mem_mb>
        <limit_stack_mem_kb desc="The maximum stack size allowed to each document process. 0 for unlimited." type="uint">8000</limit_stack_mem_kb>
        <limit_file_size_mb desc="The maximum file size allowed to each document process to write. 0 for unlimited." type="uint">0</limit_file_size_mb>
        <limit_num_open_files desc="The maximum number of files allowed to each document process to open. 0 for unlimited." type="uint">0</limit_num_open_files>
        <limit_load_secs desc="Maximum number of seconds to wait for a document load to succeed. 0 for unlimited." type="uint" default="100">100</limit_load_secs>
        <limit_convert_secs desc="Maximum number of seconds to wait for a document conversion to succeed. 0 for unlimited." type="uint" default="100">100</limit_convert_secs>
        <cleanup desc="Checks for resource consuming (bad) documents and kills associated kit process. A document is considered resource consuming (bad) if is in idle state for idle_time_secs period and memory usage passed limit_dirty_mem_mb or CPU usage passed limit_cpu_per" enable="false">
            <cleanup_interval_ms desc="Interval between two checks" type="uint" default="10000">10000</cleanup_interval_ms>
            <bad_behavior_period_secs desc="Minimum time period for a document to be in bad state before associated kit process is killed. If in this period the condition for bad document is not met once then this period is reset" type="uint" default="60">60</bad_behavior_period_secs>
            <idle_time_secs desc="Minimum idle time for a document to be candidate for bad state" type="uint" default="300">300</idle_time_secs>
            <limit_dirty_mem_mb desc="Minimum memory usage for a document to be candidate for bad state" type="uint" default="3072">3072</limit_dirty_mem_mb>
            <limit_cpu_per desc="Minimum CPU usage for a document to be candidate for bad state" type="uint" default="85">85</limit_cpu_per>
        </cleanup>
    </per_document>

    <per_view desc="View-specific settings.">
        <out_of_focus_timeout_secs desc="The maximum number of seconds before dimming and stopping updates when the browser tab is no longer in focus. Defaults to 120 seconds." type="uint" default="120">120</out_of_focus_timeout_secs>
        <idle_timeout_secs desc="The maximum number of seconds before dimming and stopping updates when the user is no longer active (even if the browser is in focus). Defaults to 15 minutes." type="uint" default="900">900</idle_timeout_secs>
    </per_view>

    <loleaflet_html desc="Allows UI customization by replacing the single endpoint of loleaflet.html" type="string" default="loleaflet.html">loleaflet.html</loleaflet_html>

    <logging>
        <color type="bool">true</color>
        <level type="string" desc="Can be 0-8, or none (turns off logging), fatal, critical, error, warning, notice, information, debug, trace" default="warning">warning</level>
        <protocol type="bool" desc="Enable minimal client-site JS protocol logging from the start">false</protocol>
        <!-- lokit_sal_log example: Log WebDAV-related messages, that is interesting for debugging Insert - Image operation: "+TIMESTAMP+INFO.ucb.ucp.webdav+WARN.ucb.ucp.webdav"
             See also: https://docs.libreoffice.org/sal/html/sal_log.html -->
        <lokit_sal_log type="string" desc="Fine tune log messages from LOKit. Default is to suppress log messages from LOKit." default="-INFO-WARN">-INFO-WARN</lokit_sal_log>
        <file enable="false">
            <property name="path" desc="Log file path.">/var/log/loolwsd.log</property>
            <property name="rotation" desc="Log file rotation strategy. See Poco FileChannel.">never</property>
            <property name="archive" desc="Append either timestamp or number to the archived log filename.">timestamp</property>
            <property name="compress" desc="Enable/disable log file compression.">true</property>
            <property name="purgeAge" desc="The maximum age of log files to preserve. See Poco FileChannel.">10 days</property>
            <property name="purgeCount" desc="The maximum number of log archives to preserve. Use 'none' to disable purging. See Poco FileChannel.">10</property>
            <property name="rotateOnOpen" desc="Enable/disable log file rotation on opening.">true</property>
            <property name="flush" desc="Enable/disable flushing after logging each line. May harm performance. Note that without flushing after each line, the log lines from the different processes will not appear in chronological order.">false</property>
        </file>
        <anonymize>
            <anonymize_user_data type="bool" desc="Enable to anonymize/obfuscate of user-data in logs. If default is true, it was forced at compile-time and cannot be disabled." default="false">false</anonymize_user_data>
            <anonymization_salt type="uint" desc="The salt used to anonymize/obfuscate user-data in logs. Use a secret 64-bit random number." default="82589933">82589933</anonymization_salt>
        </anonymize>
    </logging>

    <loleaflet_logging desc="Logging in the browser console" default="false">false</loleaflet_logging>

    <trace desc="Dump commands and notifications for replay. When 'snapshot' is true, the source file is copied to the path first." enable="false">
        <path desc="Output path to hold trace file and docs. Use '%' for timestamp to avoid overwriting. For example: /some/path/to/looltrace-%.gz" compress="true" snapshot="false"></path>
        <filter>
            <message desc="Regex pattern of messages to exclude"></message>
        </filter>
        <outgoing>
            <record desc="Whether or not to record outgoing messages" default="false">false</record>
        </outgoing>
    </trace>

    <net desc="Network settings">
      <!-- On systems where localhost resolves to IPv6 [::1] address first, when net.proto is all and net.listen is loopback, loolwsd unexpectedly listens on [::1] only.
           You need to change net.proto to IPv4, if you want to use 127.0.0.1. -->
      <proto type="string" default="all" desc="Protocol to use IPv4, IPv6 or all for both">all</proto>
      <listen type="string" default="any" desc="Listen address that loolwsd binds to. Can be 'any' or 'loopback'.">any</listen>
      <service_root type="path" default="" desc="Prefix all the pages, websockets, etc. with this path."></service_root>
      <proxy_prefix type="bool" default="false" desc="Enable a ProxyPrefix to be passed int through which to redirect requests"></proxy_prefix>
      <post_allow desc="Allow/deny client IP address for POST(REST)." allow="true">
        <host desc="The IPv4 private 192.168 block as plain IPv4 dotted decimal addresses.">192\.168\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="Ditto, but as IPv4-mapped IPv6 addresses">::ffff:192\.168\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="The IPv4 loopback (localhost) address.">127\.0\.0\.1</host>
        <host desc="Ditto, but as IPv4-mapped IPv6 address">::ffff:127\.0\.0\.1</host>
        <host desc="The IPv6 loopback (localhost) address.">::1</host>
        <host desc="The IPv4 private 172.17.0.0/16 subnet (Docker).">172\.17\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="Ditto, but as IPv4-mapped IPv6 addresses">::ffff:172\.17\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="Custom definition">::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}</host>
      </post_allow>
      <frame_ancestors desc="Specify who is allowed to embed the LO Online iframe (loolwsd and WOPI host are always allowed). Separate multiple hosts by space."></frame_ancestors>
      <connection_timeout_secs desc="Specifies the connection, send, recv timeout in seconds for connections initiated by loolwsd (such as WOPI connections)." type="int" default="30"></connection_timeout_secs>
    </net>

    <ssl desc="SSL settings">
        <enable type="bool" desc="Controls whether SSL encryption between browser and loolwsd is enabled (do not disable for production deployment). If default is false, must first be compiled with SSL support to enable." default="true">false</enable>
        <termination desc="Connection via proxy where loolwsd acts as working via https, but actually uses http." type="bool" default="true">false</termination>
        <cert_file_path desc="Path to the cert file" relative="false">/etc/loolwsd/cert.pem</cert_file_path>
        <key_file_path desc="Path to the key file" relative="false">/etc/loolwsd/key.pem</key_file_path>
        <ca_file_path desc="Path to the ca file" relative="false">/etc/loolwsd/ca-chain.cert.pem</ca_file_path>
        <cipher_list desc="List of OpenSSL ciphers to accept" default="ALL:!ADH:!LOW:!EXP:!MD5:@STRENGTH"></cipher_list>
        <hpkp desc="Enable HTTP Public key pinning" enable="false" report_only="false">
            <max_age desc="HPKP's max-age directive - time in seconds browser should remember the pins" enable="true">1000</max_age>
            <report_uri desc="HPKP's report-uri directive - pin validation failure are reported at this URL" enable="false"></report_uri>
            <pins desc="Base64 encoded SPKI fingerprints of keys to be pinned">
            <pin></pin>
            </pins>
        </hpkp>
    </ssl>

    <security desc="Altering these defaults potentially opens you to significant risk">
      <seccomp desc="Should we use the seccomp system call filtering." type="bool" default="true">true</seccomp>
      <capabilities desc="Should we require capabilities to isolate processes into chroot jails" type="bool" default="true">true</capabilities>
    </security>

    <watermark>
      <opacity desc="Opacity of on-screen watermark from 0.0 to 1.0" type="double" default="0.2"></opacity>
      <text desc="Watermark text to be displayed on the document if entered" type="string"></text>
    </watermark>

    <welcome>
      <enable type="bool" desc="Controls whether the welcome screen should be shown to the users on new install and updates." default="false">false</enable>
      <enable_button type="bool" desc="Controls whether the welcome screen should have an explanatory button instead of an X button to close the dialog." default="false">false</enable_button>
      <path desc="Path to 'welcome-$lang.html' files served on first start or when the version changes. When empty, defaults to the Release notes." type="path" relative="true" default="loleaflet/welcome"></path>
    </welcome>

    <user_interface>
      <mode type="string" desc="Controls the user interface style (classic|notebookbar)" default="classic">classic</mode>
    </user_interface>

    <storage desc="Backend storage">
        <filesystem allow="false" />
        <wopi desc="Allow/deny wopi storage. Mutually exclusive with webdav." allow="true">
            <host desc="Regex pattern of hostname to allow or deny." allow="true"></host>
            <host desc="Regex pattern of hostname to allow or deny." allow="true">10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}</host>
            <host desc="Regex pattern of hostname to allow or deny." allow="true">172\.1[6789]\.[0-9]{1,3}\.[0-9]{1,3}</host>
            <host desc="Regex pattern of hostname to allow or deny." allow="true">172\.2[0-9]\.[0-9]{1,3}\.[0-9]{1,3}</host>
            <host desc="Regex pattern of hostname to allow or deny." allow="true">172\.3[01]\.[0-9]{1,3}\.[0-9]{1,3}</host>
            <host desc="Regex pattern of hostname to allow or deny." allow="true">192\.168\.[0-9]{1,3}\.[0-9]{1,3}</host>
            <host desc="Regex pattern of hostname to allow or deny." allow="false">192\.168\.1\.1</host>
            <max_file_size desc="Maximum document size in bytes to load. 0 for unlimited." type="uint">0</max_file_size>
            <reuse_cookies desc="When enabled, cookies from the browser will be captured and set on WOPI requests." type="bool" default="false">false</reuse_cookies>
            <locking desc="Locking settings">
                <refresh desc="How frequently we should re-acquire a lock with the storage server, in seconds (default 15 mins) or 0 for no refresh" type="int" default="900">900</refresh>
            </locking>
        </wopi>
        <webdav desc="Allow/deny webdav storage. Mutually exclusive with wopi." allow="false">
            <host desc="Hostname to allow" allow="false"></host>
        </webdav>
        <ssl desc="SSL settings">
	    <as_scheme type="bool" default="true" desc="When set we exclusively use the WOPI URI's scheme to enable SSL for storage">true</as_scheme>
            <enable type="bool" desc="If as_scheme is false or not set, this can be set to force SSL encryption between storage and loolwsd. When empty this defaults to following the ssl.enable setting"></enable>
            <cert_file_path desc="Path to the cert file" relative="false"></cert_file_path>
            <key_file_path desc="Path to the key file" relative="false"></key_file_path>
            <ca_file_path desc="Path to the ca file. If this is not empty, then SSL verification will be strict, otherwise cert of storage (WOPI-like host) will not be verified." relative="false"></ca_file_path>
            <cipher_list desc="List of OpenSSL ciphers to accept. If empty the defaults are used. These can be overriden only if absolutely needed."></cipher_list>
        </ssl>
    </storage>

    <tile_cache_persistent desc="Should the tiles persist between two editing sessions of the given document?" type="bool" default="true">true</tile_cache_persistent>

    <admin_console desc="Web admin console settings.">
        <enable desc="Enable the admin console functionality" type="bool" default="true">true</enable>
        <enable_pam desc="Enable admin user authentication with PAM" type="bool" default="false">false</enable_pam>
        <username desc="The username of the admin console. Ignored if PAM is enabled.">admin</username>
        <password desc="The password of the admin console. Deprecated on most platforms. Instead, use PAM or loolconfig to set up a secure password.">123456</password>
    </admin_console>

    <monitors desc="Addresses of servers we connect to on start for monitoring">
    </monitors>

</config>
```

### 关键配置项解释

对应启动容器时的 `--o:ssl.enable=false` 命令

```xml
<ssl desc="SSL settings">
    <enable type="bool" desc="Controls whether SSL encryption between browser and loolwsd is enabled (do not disable for production deployment). If default is false, must first be compiled with SSL support to enable." default="true">false</enable>
</ssl>
```

对应启动容器时的 `--o:net.post_allow.host[0]=::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}"` 命令（ip匹配规则用正则）

```xml
<net desc="Network settings">
    <post_allow desc="Allow/deny client IP address for POST(REST)." allow="true">
        <host desc="The IPv4 private 192.168 block as plain IPv4 dotted decimal addresses.">192\.168\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="Ditto, but as IPv4-mapped IPv6 addresses">::ffff:192\.168\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="The IPv4 loopback (localhost) address.">127\.0\.0\.1</host>
        <host desc="Ditto, but as IPv4-mapped IPv6 address">::ffff:127\.0\.0\.1</host>
        <host desc="The IPv6 loopback (localhost) address.">::1</host>
        <host desc="The IPv4 private 172.17.0.0/16 subnet (Docker).">172\.17\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="Ditto, but as IPv4-mapped IPv6 addresses">::ffff:172\.17\.[0-9]{1,3}\.[0-9]{1,3}</host>
        <host desc="Custom definition">::ffff:[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}</host>
    </post_allow>
</net>
```

对应启动容器时的 ` -e "username=admin" -e "password=123456" ` 命令

```xml
<admin_console desc="Web admin console settings.">
    <enable desc="Enable the admin console functionality" type="bool" default="true">true</enable>
    <enable_pam desc="Enable admin user authentication with PAM" type="bool" default="false">false</enable_pam>
    <username desc="The username of the admin console. Ignored if PAM is enabled.">admin</username>
    <password desc="The password of the admin console. Deprecated on most platforms. Instead, use PAM or loolconfig to set up a secure password.">123456</password>
</admin_console>
```

## 1.3 测试转换功能

这里建议先用内网跑再用，用外网ip测试，看看用外网ip能跑通吗。

```shell
curl -F "data=@test.pptx" http://外网ip或者域名:9980/lool/convert-to/pdf > out.pdf
```

## 1.4 管理控制台

[LibreOffice Online Personal - 管理控制台](http://81.70.239.72:9980/loleaflet/dist/admin/admin.html)

感觉没啥用

![](http://qiniu.zhouhongyin.top/2022/08/19/1660890657-image-20220819143056879.png)

> local 版的 libreoffice 比较简单这里就不说了。

# 二、spring boot 整合

## 2.1 添加相关依赖

```xml
<!--jodconverter 核心包 -->
<dependency>
    <groupId>org.jodconverter</groupId>
    <artifactId>jodconverter-core</artifactId>
    <version>4.2.4</version>
</dependency>

<!--springboot支持包，里面包括了自动配置类 -->
<dependency>
    <groupId>org.jodconverter</groupId>
    <artifactId>jodconverter-spring-boot-starter</artifactId>
    <version>4.2.4</version>
</dependency>


<!--jodconverter 本地 -->
<dependency>
    <groupId>org.jodconverter</groupId>
    <artifactId>jodconverter-local</artifactId>
    <version>4.2.4</version>
</dependency>

<!-- jodconverter online -->
<dependency>
    <groupId>org.jodconverter</groupId>
    <artifactId>jodconverter-online</artifactId>
    <version>4.2.4</version>
</dependency>
```

## 2.2 编写配置文件

```yml
jodconverter:
  # local 版
  local:
    enabled: false
    max-tasks-per-process: 10
    port-numbers: 8100,8101,8102,8103
    taskExecutionTimeout: 200000
    officeHome: C:\Program Files\LibreOffice
    working-dir: /home
  # online 版
  online:
    enabled: true
    url: http://ip:9980/
    taskExecutionTimeout: 200000
    taskQueueTimeout: 200000
    ssl:
      enabled: false
```

> 注意：这里 local 版 和 online 版 只能开启一个

> 注意：`working-dir: /home`：jodconverter 的默认工作路径是 **/tmp**，项目启动时会在 **working-dir** 指定的目录下创建自己的工作目录 （没有指定就是/tmp）。如果项目是集群部署，并且没有指定 **working-dir** 和 **/tmp** 做了数据卷的映射，会导致工作目录冲突项目启动不起来。所以这里推荐自己指定一个容器专属的目录。

## 2.3 编写测试接口

```java
@RestController
@RequestMapping("jodconverter")
@Slf4j
public class JodconverterController {

    @Autowired(required = false)
    DocumentConverter documentConverter;

    @Autowired(required = false)
    OnlineConverter onlineConverter;

    /**
     * local 版
     */
    @GetMapping("/transfer")
    public void toPdfFile(HttpServletResponse response, HttpServletRequest request, MultipartFile file) throws Exception {

        ServletOutputStream outputStream = response.getOutputStream();

        String contentType = file.getContentType();
        log.info("contentType:{}", contentType);
        String name = file.getName();
        log.info("name:{}", name);
        String originalFilename = file.getOriginalFilename();
        log.info("originalFilename:{}", originalFilename);

        int i = originalFilename.lastIndexOf(".");

        String pdfName = originalFilename.substring(0, i) + ".pdf";
        response.setHeader(Header.CONTENT_DISPOSITION.name(), "attachment;fileName=" + URLEncoder.createDefault().encode(pdfName, StandardCharsets.UTF_8));
        response.setContentType(contentType);

        documentConverter.convert(file.getInputStream()).to(outputStream).as(DefaultDocumentFormatRegistry.PDF).execute();
    }

    /**
     * online 版
     */
    @GetMapping("/transfer/online")
    public void toPdfFileOnline(HttpServletResponse response, HttpServletRequest request, MultipartFile file) throws Exception {

        ServletOutputStream outputStream = response.getOutputStream();

        String contentType = file.getContentType();
        log.info("contentType:{}", contentType);
        String name = file.getName();
        log.info("name:{}", name);
        String originalFilename = file.getOriginalFilename();
        log.info("originalFilename:{}", originalFilename);

        int i = originalFilename.lastIndexOf(".");

        String pdfName = originalFilename.substring(0, i) + ".pdf";
        response.setHeader(Header.CONTENT_DISPOSITION.name(), "attachment;fileName=" + URLEncoder.createDefault().encode(pdfName, StandardCharsets.UTF_8));
        response.setContentType(contentType);

        onlineConverter.convert(file.getInputStream()).as(DefaultDocumentFormatRegistry.XLSX).to(outputStream).as(DefaultDocumentFormatRegistry.PDF).execute();
    }
}
```

## 2.4 测试结果

![image-20220819145829310](http://qiniu.zhouhongyin.top/2022/08/19/1660892309-image-20220819145829310.png)

# 参考资料

- https://blog.51cto.com/u_15060507/4403770
- http://blog.joylau.cn/2020/04/12/Docker-LibreOffice-Online/
- https://blog.minirplus.com/16696/
- https://blog.csdn.net/qq_31810357/article/details/126300176
- https://juejin.cn/post/6844903505048633351
- https://hub.docker.com/r/libreoffice/online/