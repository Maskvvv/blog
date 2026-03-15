# Java WebSocket 使用示例汇总

本文档提供两个完整的 WebSocket 示例：

1. **纯 Java 环境**（使用 Java EE WebSocket API 和 Tyrus 独立服务器）
2. **Spring Boot 环境**（使用 STOMP 协议，基于消息代理）

并针对 Spring 配置中的 `enableSimpleBroker` 进行深入解释。

------

## 第一部分：纯 Java WebSocket 示例（Java EE + Tyrus）

此示例不依赖任何 Web 容器，使用 Tyrus 作为独立服务器，演示服务端广播和客户端收发消息。

### 环境准备

- JDK 8+
- Maven 或 Gradle

### Maven 依赖

xml

```
<dependencies>
    <!-- WebSocket API -->
    <dependency>
        <groupId>javax.websocket</groupId>
        <artifactId>javax.websocket-api</artifactId>
        <version>1.1</version>
        <scope>provided</scope>
    </dependency>
    <!-- 客户端 API -->
    <dependency>
        <groupId>javax.websocket</groupId>
        <artifactId>javax.websocket-client-api</artifactId>
        <version>1.1</version>
    </dependency>
    <!-- Tyrus 独立服务器（Grizzly 容器） -->
    <dependency>
        <groupId>org.glassfish.tyrus</groupId>
        <artifactId>tyrus-container-grizzly-server</artifactId>
        <version>1.17</version>
    </dependency>
    <!-- Tyrus 客户端 -->
    <dependency>
        <groupId>org.glassfish.tyrus</groupId>
        <artifactId>tyrus-client</artifactId>
        <version>1.17</version>
    </dependency>
</dependencies>
```



### 服务端端点

创建一个广播式服务端，收到消息后发送给所有连接的客户端。

java

```
import javax.websocket.*;
import javax.websocket.server.ServerEndpoint;
import java.io.IOException;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

@ServerEndpoint("/chat")
public class ChatServer {

    private static final Set<Session> sessions = Collections.synchronizedSet(new HashSet<>());

    @OnOpen
    public void onOpen(Session session) {
        sessions.add(session);
        System.out.println("新连接加入：" + session.getId() + "，当前在线：" + sessions.size());
    }

    @OnMessage
    public void onMessage(String message, Session session) {
        System.out.println("收到来自 " + session.getId() + " 的消息：" + message);
        broadcast("用户 " + session.getId() + ": " + message);
    }

    @OnClose
    public void onClose(Session session) {
        sessions.remove(session);
        System.out.println("连接关闭：" + session.getId() + "，当前在线：" + sessions.size());
    }

    @OnError
    public void onError(Session session, Throwable error) {
        System.err.println("连接 " + session.getId() + " 发生错误：" + error.getMessage());
    }

    private void broadcast(String message) {
        for (Session s : sessions) {
            if (s.isOpen()) {
                try {
                    s.getBasicRemote().sendText(message);
                } catch (IOException e) {
                    System.err.println("广播失败：" + e.getMessage());
                }
            }
        }
    }
}
```



### 客户端端点

实现 `@ClientEndpoint` 处理接收到的消息。

java

```
import javax.websocket.*;

@ClientEndpoint
public class ChatClientEndpoint {

    @OnOpen
    public void onOpen(Session session) {
        System.out.println("客户端连接成功，Session ID：" + session.getId());
    }

    @OnMessage
    public void onMessage(String message) {
        System.out.println("客户端收到消息：" + message);
    }

    @OnClose
    public void onClose(Session session, CloseReason reason) {
        System.out.println("客户端连接关闭，原因：" + reason.getReasonPhrase());
    }

    @OnError
    public void onError(Throwable error) {
        System.err.println("客户端错误：" + error.getMessage());
    }
}
```



### 启动服务器和客户端

创建主类，启动服务器，并模拟两个客户端通信。

java

```
import org.glassfish.tyrus.server.Server;
import javax.websocket.ContainerProvider;
import javax.websocket.Session;
import javax.websocket.WebSocketContainer;
import java.net.URI;

public class WebSocketDemo {

    public static void main(String[] args) throws Exception {
        // 1. 启动 Tyrus 服务器
        Server server = new Server("localhost", 8080, "/ws", ChatServer.class);
        server.start();
        System.out.println("WebSocket 服务器启动：ws://localhost:8080/ws/chat");

        // 2. 创建两个客户端并通信
        WebSocketContainer container = ContainerProvider.getWebSocketContainer();

        Session session1 = container.connectToServer(ChatClientEndpoint.class, URI.create("ws://localhost:8080/ws/chat"));
        Session session2 = container.connectToServer(ChatClientEndpoint.class, URI.create("ws://localhost:8080/ws/chat"));

        Thread.sleep(1000); // 等待连接稳定

        session1.getBasicRemote().sendText("大家好，我是客户端1！");
        Thread.sleep(1000);

        session2.getBasicRemote().sendText("你好，我是客户端2！");
        Thread.sleep(1000);

        session1.close();
        session2.close();

        server.stop();
        System.out.println("演示结束，服务器已关闭。");
    }
}
```



### 运行说明

1. 将代码放入相应包（如 `com.example.websocket`）。
2. 使用 Maven 编译并运行 `WebSocketDemo.main()`。
3. 控制台会输出连接、消息广播等日志，两个客户端互相收到对方的消息。

#### 输出示例

text

```
WebSocket 服务器启动：ws://localhost:8080/ws/chat
客户端连接成功，Session ID：0
客户端连接成功，Session ID：1
新连接加入：0，当前在线：1
新连接加入：1，当前在线：2
收到来自 0 的消息：大家好，我是客户端1！
客户端收到消息：用户 0: 大家好，我是客户端1！
客户端收到消息：用户 0: 大家好，我是客户端1！
收到来自 1 的消息：你好，我是客户端2！
客户端收到消息：用户 1: 你好，我是客户端2！
客户端收到消息：用户 1: 你好，我是客户端2！
...
```



------

## 第二部分：Spring Boot 中使用 WebSocket（STOMP）

Spring 推荐使用 STOMP 协议构建 WebSocket 应用，支持高级消息路由和订阅机制。以下示例实现一个简单的聊天室。

### 环境准备

- JDK 8+
- Spring Boot 2.x
- Maven 或 Gradle

### 创建项目并添加依赖

#### Maven (`pom.xml`)

xml

```
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>2.7.0</version>
</parent>

<dependencies>
    <!-- WebSocket 支持 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-websocket</artifactId>
    </dependency>
    <!-- 用于前端页面测试 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-thymeleaf</artifactId>
    </dependency>
</dependencies>
```



### 配置 WebSocket 消息代理

创建配置类，启用 STOMP 消息代理。

java

```
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        // 服务端发送给客户端的消息前缀（客户端订阅）
        config.enableSimpleBroker("/topic", "/queue");
        // 客户端发送给服务端的消息前缀
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        // 注册 STOMP 端点，客户端通过此路径连接
        registry.addEndpoint("/chat-websocket")
                .setAllowedOrigins("*")  // 生产环境请谨慎
                .withSockJS();           // 启用 SockJS 回退
    }
}
```



### 创建消息实体

java

```
public class ChatMessage {
    private String from;
    private String content;

    public ChatMessage() {}

    public ChatMessage(String from, String content) {
        this.from = from;
        this.content = content;
    }

    // getters and setters
    public String getFrom() { return from; }
    public void setFrom(String from) { this.from = from; }
    public String getContent() { return content; }
    public void setContent(String content) { this.content = content; }
}
```



### 创建消息处理控制器

使用 `@MessageMapping` 处理客户端消息，并广播到指定主题。

java

```
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.stereotype.Controller;

@Controller
public class ChatController {

    @MessageMapping("/chat.sendMessage")      // 对应 /app/chat.sendMessage
    @SendTo("/topic/public")                  // 广播给所有订阅 /topic/public 的客户端
    public ChatMessage sendMessage(@Payload ChatMessage chatMessage) {
        // 可添加业务逻辑
        return chatMessage;
    }
}
```



### 创建前端页面测试

在 `src/main/resources/templates/chat.html` 中编写 HTML 和 JavaScript，使用 SockJS 和 STOMP.js 连接。

html

```
<!DOCTYPE html>
<html>
<head>
    <title>WebSocket Chat</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/sockjs-client/1.5.1/sockjs.min.js"></script>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/stomp.js/2.3.3/stomp.min.js"></script>
    <script>
        var stompClient = null;

        function connect() {
            var socket = new SockJS('/chat-websocket');
            stompClient = Stomp.over(socket);
            stompClient.connect({}, function (frame) {
                console.log('Connected: ' + frame);
                stompClient.subscribe('/topic/public', function (message) {
                    var chat = JSON.parse(message.body);
                    showMessage(chat.from + ": " + chat.content);
                });
            });
        }

        function sendMessage() {
            var from = document.getElementById('from').value;
            var content = document.getElementById('content').value;
            stompClient.send("/app/chat.sendMessage", {}, JSON.stringify({ 'from': from, 'content': content }));
        }

        function showMessage(msg) {
            var messages = document.getElementById('messages');
            var p = document.createElement('p');
            p.appendChild(document.createTextNode(msg));
            messages.appendChild(p);
        }
    </script>
</head>
<body>
    <div>
        <label>用户名:</label>
        <input id="from" type="text" />
    </div>
    <div>
        <label>消息:</label>
        <input id="content" type="text" />
        <button onclick="sendMessage()">发送</button>
    </div>
    <button onclick="connect()">连接</button>
    <div id="messages"></div>
</body>
</html>
```



### 添加页面控制器

返回测试页面。

java

```
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class PageController {
    @GetMapping("/")
    public String chat() {
        return "chat";
    }
}
```



### 启动应用

- 在 `application.properties` 中（可选）设置 `server.port=8080`。
- 运行 Spring Boot 主类（带有 `@SpringBootApplication`）。
- 访问 `http://localhost:8080`，点击“连接”，然后发送消息，所有已连接的客户端都会收到广播。

### 关键点解释

- **`@EnableWebSocketMessageBroker`**：开启基于消息代理的 WebSocket 支持。
- **`configureMessageBroker`**：配置消息代理。
  - `enableSimpleBroker("/topic", "/queue")`：启动内存代理，处理订阅和广播。
  - `setApplicationDestinationPrefixes("/app")`：客户端发送消息到服务器的前缀。
- **`registerStompEndpoints`**：注册 STOMP 端点，客户端通过此路径连接。
- **`@MessageMapping`**：映射客户端发送到特定目的地的消息。
- **`@SendTo`**：指定方法返回值应广播到的目的地。

### 扩展：原生 WebSocket 方式（不使用 STOMP）

如果只需简单双向通信，也可使用 `@ServerEndpoint`，但需要注册 `ServerEndpointExporter`。不过这种方式无法利用 Spring 的依赖注入，通常不如 STOMP 方便。

java

```
@Component
@ServerEndpoint("/ws/chat")
public class MyWebSocket {
    @OnOpen public void onOpen(Session session) { ... }
    @OnMessage public void onMessage(String message) { ... }
}

@Configuration
public class WebSocketConfig {
    @Bean
    public ServerEndpointExporter serverEndpointExporter() {
        return new ServerEndpointExporter();
    }
}
```



------

## 第三部分：关于 `enableSimpleBroker` 配置的说明

### 问题

在 Spring STOMP 配置中，如果没有配置 `enableSimpleBroker("/topic", "/queue")`（也没有配置 `enableStompBrokerRelay` 连接外部代理），会发生什么？消息还能转发给客户端吗？

### 原因

`enableSimpleBroker` 的作用是启动一个**基于内存的简单消息代理**，负责维护客户端的订阅关系，并将服务端发往匹配前缀的消息分发给所有订阅者。
如果不配置任何代理，Spring WebSocket 的 STOMP 支持就没有消息代理来处理“发布-订阅”模式。

### 没有配置的后果

1. **客户端无法订阅**
   `stompClient.subscribe('/topic/public', callback)` 会失败（服务器返回错误，因为没有组件处理订阅）。
2. **服务端的 `@SendTo` 和 `SimpMessagingTemplate` 失效**
   - 即使 `@MessageMapping` 方法正常执行并返回数据，由于没有代理，返回值无法路由给任何客户端。
   - 手动注入 `SimpMessagingTemplate` 并调用 `convertAndSend("/topic/public", data)` 也无法送达消息。
3. **但 `@MessageMapping` 仍可处理请求-响应？**
   客户端发送到 `/app/someEndpoint` 的消息可以被服务器接收处理，但无法通过返回值将响应发回客户端（因为没有代理处理目的地）。最终客户端收不到响应。

### 替代方案：外部消息代理

如果不想使用内存代理，可以配置 `enableStompBrokerRelay` 连接支持 STOMP 的外部代理（如 RabbitMQ、ActiveMQ），它们同样可以处理订阅和广播。

### 总结

**没有消息代理配置，就无法实现“服务器推送”和“订阅/发布”功能**。WebSocket 退化为一个双向通信的管道，但无法利用 STOMP 的主题广播机制。若只需点对点通信（如向特定用户发送消息），可结合 `@SendToUser` 和用户队列，但用户队列底层仍依赖代理（`/user` 前缀由代理特殊处理）。因此，**简单内存代理是最轻量的实现方式，在大多数基于 STOMP 的应用中必不可少**。

------

## 参考资料

- [Java WebSocket API (JSR 356)](https://javaee.github.io/tutorial/websocket.html)
- [Spring WebSocket 文档](https://docs.spring.io/spring-framework/docs/current/reference/html/web.html#websocket)
- [Tyrus 项目](https://eclipse-ee4j.github.io/tyrus/)