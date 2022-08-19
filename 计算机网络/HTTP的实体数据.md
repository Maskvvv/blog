

# MIME

## 介绍

MIME(Multipurpose Internet Mail Extensions)多用途互联网邮件扩展类型。是设定某种扩展名的文件用一种应用程序来打开的方式类型，当该扩展名文件被访问的时候，浏览器会自动使用指定应用程序来打开。多用于指定一些客户端自定义的文件名，以及一些媒体文件打开方式。

多用途互联网邮件扩展，它是一个互联网标准，在1992年最早应用于电子邮件系统，但后来也应用到浏览器。**服务器**会将它们发送的多媒体数据的类型告诉浏览器，而通知手段就是说明该多媒体数据的MIME类型，从而让浏览器知道接收到的信息哪些是MP3文件，哪些是Shockwave文件等等。服务器将MIME标志符放入传送的数据中来告诉浏览器使用哪种插件读取相关文件。

最早的HTTP协议中，并没有附加的数据类型信息，所有传送的数据都被客户程序解释为超文本标记语言HTML 文档，而为了支持多媒体数据类型，HTTP协议中就使用了附加在文档之前的MIME数据类型信息来标识数据类型。

## 分类

MIME 把数据分成了八大类，每个大类下再细分出多个子类，每个MIME类型由两部分组成，前面是数据的大类别，形式是“type/subtype”的字符串。

HTTP 中常遇到的几个类别：

1. **text：**即文本格式的可读数据，我们最熟悉的应该就是 text/html 了，表示超文本文档，此外还有纯文本 text/plain、样式表 text/css 等。
2. **image：**即图像文件，有 image/gif、image/jpeg、image/png 等。
3. **audio/video：**音频和视频数据，例如 audio/mpeg、video/mp4 等。
4. **application：**数据格式不固定，可能是文本也可能是二进制，必须由上层应用程序来解释。常见的有 application/json，application/javascript、application/pdf 等，另外，如果实在是不知道数据是什么类型，像刚才说的“黑盒”，就会是 application/octet-stream，即不透明的二进制数据。

# Encoding type

有 MIME type 还不够，因为 HTTP 在传输时为了节约带宽，有时候还会压缩数据，为了不要让浏览器继续“猜”，还需要有一个“Encoding type”，告诉数据是用的什么编码格式，这样对方才能正确解压缩，还原出原始的数据。

比起 MIME type 来说，Encoding type 就少了很多，常用的只有下面三种：

1. **gzip：**GNU zip 压缩格式，也是互联网上最流行的压缩格式；
2. **deflate：**zlib（deflate）压缩格式，流行程度仅次于 gzip；
3. **br：**一种专门为 HTTP 优化的新压缩算法（Brotli）。

# 数据类型与数据压缩

有了 MIME type 和 Encoding type，无论是浏览器还是服务器就都可以轻松识别出 body 的类型，也就能够正确处理数据了。

HTTP 协议为此定义了两个 Accept 请求头字段和两个 Content 实体头字段，用于客户端和服务器进行“**内容协商**”。也就是说，客户端用 Accept 头告诉服务器希望接收什么样的数据，而服务器用 Content 头告诉客户端实际发送了什么样的数据。

![img](http://qiniu.zhouhongyin.top/2022/08/13/1660378009-5191bce1329efa157a6cc37ab9e789b9.png)

## Accept 和 Content-Type

**Accept** 字段标记的是客户端可理解的 MIME type，可以用“,”做分隔符列出多个类型，让服务器有更多的选择余地，例如下面的这个头，他告诉了服务器我可以接受的数据类型。

```http
Accept: text/html,application/xml,image/webp,image/png
```

同样服务端会在相应报文里用头字段 **Content-Type** 告诉实体数据的真实类型：

```http
Content-Type: text/html
Content-Type: image/png
```

这样浏览器看到报文里的类型是“text/html”就知道是 HTML 文件，会调用排版引擎渲染出页面，看到“image/png”就知道是一个 PNG 文件，就会在页面上显示出图像。

> Accept 或者 Content 不是只能由客户端发送或者服务器发送，他们都可以发送 Accept 或者 Content 。
>
> content-type是实体字段，所以请求和响应里都可以用，作用是指明body数据的类型。

## Accept-Encoding 和 Content-Encoding 

**Accept-Encoding** 字段标记的是客户端支持的压缩格式，例如上面说的 gzip、deflate 等，同样也可以用“,”列出多个，服务器可以选择其中一种来压缩数据，实际使用的压缩格式放在响应头字段 **Content-Encoding** 里。

```http
Accept-Encoding: gzip, deflate, br
Content-Encoding: gzip
```

> 这两个字段可以省略代表不支持压缩格式或者内容没有压缩。

# 语言类型与编码

## 引言

### 关于语言

MIME type 和 Encoding type 解决了计算机理解 body 数据的问题，但互联网遍布全球，不同国家不同地区的人使用了很多不同的语言，虽然都是 text/html，但如何让浏览器显示出每个人都可理解可阅读的语言文字呢？

这实际上就是“国际化”的问题。HTTP 采用了与数据类型相似的解决方案，又引入了两个概念：语言类型与字符集。

所谓的“**语言类型**”就是人类使用的自然语言，例如英语、汉语、日语等，而这些自然语言可能还有下属的地区性方言，所以在需要明确区分的时候也要使用“type-subtype”的形式，不过这里的格式与数据类型不同，**分隔符不是“/”，而是“-”**。

比如：en 表示任意的英语，en-US 表示美式英语，en-GB 表示英式英语，而 zh-CN 就表示我们最常使用的汉语。

### 关于字符集

关于自然语言的计算机处理还有一个更麻烦的东西叫做“字符集”。

在计算机发展的早期，各个国家和地区的人们“各自为政”，发明了许多字符编码方式来处理文字，比如英语世界用的 ASCII、汉语世界用的 GBK、BIG5，日语世界用的 Shift_JIS 等。同样的一段文字，用一种编码显示正常，换另一种编码后可能就会变得一团糟。

所以后来就出现了 Unicode 和 UTF-8，把世界上所有的语言都容纳在一种编码方案里，遵循 UTF-8 字符编码方式的 Unicode 字符集也成为了互联网上的标准字符集。

## 语言类型使用的头字段

同样的，HTTP 协议也使用 Accept 请求头字段和 Content 实体头字段，用于客户端和服务器就语言与编码进行“**内容协商**”。

### Accept-Language 和 Content-Language

**Accept-Language** 字段标记了客户端可理解的自然语言，也允许用“,”做分隔符列出多个类型，例如下面这个请求头会告诉服务器：“最好给我 zh-CN 的汉语文字，如果没有就用其他的汉语方言，如果还没有就给英文”。

```http
Accept-Language: zh-CN, zh, en
```

相应的，服务器应该在响应报文里用头字段 **Content-Language** 告诉客户端实体数据使用的实际语言类型：

```http
Content-Language: zh-CN
```

### Accept-Charset

字符集在 HTTP 里使用的请求头字段是 **Accept-Charset**，但响应头里却没有对应的 Content-Charset，而是在 **Content-Type** 字段的数据类型后面用“charset=xxx”来表示，这点需要特别注意。

例如，浏览器请求 GBK 或 UTF-8 的字符集，然后服务器返回的是 UTF-8 编码，就是下面这样：

```http
Accept-Charset: gbk, utf-8
Content-Type: text/html; charset=utf-8
```

> **不过现在的浏览器都支持多种字符集，通常不会发送 Accept-Charset，而服务器也不会发送 Content-Language**，因为使用的语言完全可以由字符集推断出来，所以在请求头里一般只会有 Accept-Language 字段，响应头里只会有 Content-Type 字段。
>
> ![img](http://qiniu.zhouhongyin.top/2022/08/13/1660383069-0e9bcd6922fa8908bdba79d98ae5fa10.png)

# 内容协商

## 内容协商的质量值

在 HTTP 协议里用 Accept、Accept-Encoding、Accept-Language 等请求头字段进行内容协商的时候，还可以用一种特殊的“q”参数表示权重来设定优先级，这里的“q”是“quality factor”的意思。

**权重的最大值是 1，最小值是 0.01，默认值是 1**，如果值是 **0 就表示拒绝**。具体的形式是在数据类型或语言代码后面加一个“;”，然后是“q=value”。

> 这里要提醒的是“;”的用法，在大多数编程语言里“;”的断句语气要强于“,”，而在 HTTP 的内容协商里却恰好反了过来，“;”的意义是小于“,”的。

例如下面的 Accept 字段，它表示浏览器最希望使用的是 HTML 文件，权重是 1，其次是 XML 文件，权重是 0.9，最后是任意数据类型，权重是 0.8。服务器收到请求头后，就会计算权重，再根据自己的实际情况优先输出 HTML 或者 XML。

```http
Accept: text/html,application/xml;q=0.9,*/*;q=0.8
```

## 内容协商的结果

内容协商的过程是不透明的，每个 Web 服务器使用的算法都不一样。但有的时候，服务器会在响应头里多加一个 **Vary** 字段，记录服务器在内容协商时参考的请求头字段，给出一点信息，例如：

```http
Vary: Accept-Encoding,User-Agent,Accept
```

这个 Vary 字段表示服务器依据了 Accept-Encoding、User-Agent 和 Accept 这三个头字段，然后决定了发回的响应报文。

Vary 字段可以认为是响应报文的一个特殊的“版本标记”。每当 Accept 等请求头变化时，Vary 也会随着响应报文一起变化。也就是说，同一个 URI 可能会有多个不同的“版本”，主要用在传输链路中间的代理服务器实现缓存服务。

# 小结

![img](http://qiniu.zhouhongyin.top/2022/08/13/1660383436-b2118315a977969ddfcc7ab9d26cb358.png)

1. 
   数据类型表示实体数据的内容是什么，使用的是 MIME type，相关的头字段是 Accept 和 Content-Type；
2. 数据编码表示实体数据的压缩方式，相关的头字段是 Accept-Encoding 和 Content-Encoding；
3. 语言类型表示实体数据的自然语言，相关的头字段是 Accept-Language 和 Content-Language；
4. 字符集表示实体数据的编码方式，相关的头字段是 Accept-Charset 和 Content-Type；
5. 客户端需要在请求头里使用 Accept 等头字段与服务器进行“内容协商”，要求服务器返回最合适的数据；
6. Accept 等头字段可以用“,”顺序列出多个可能的选项，还可以用“;q=”参数来精确指定权重。