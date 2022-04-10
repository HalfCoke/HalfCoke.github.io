---
title: 转载——跨域资源共享CORS浅析及便捷解决方案
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: 跨域资源共享CORS浅析及便捷解决方案
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308982.png'
tags:
  - WEB技术
categories:
  - 转载
  - WEB技术
abbrlink: 7a010a2b
date: 2021-03-01 15:30:11
update: 2021-03-01 15:30:11
---

# 转载——跨域资源共享CORS浅析及便捷解决方案

> 跨源资源共享 (CORS) （或通俗地译为跨域资源共享）是一种基于HTTP 头的机制，该机制通过允许服务器标示除了它自己以外的其它origin（域，协议和端口），这样浏览器可以访问加载这些资源。跨源资源共享还通过一种机制来检查服务器是否会允许要发送的真实请求，该机制通过浏览器发起一个到服务器托管的跨源资源的"预检"请求。在预检中，浏览器发送的头中标示有HTTP方法和真实请求中会用到的头。

> 跨源HTTP请求的一个例子：运行在 [http://domain-a.com](http://domain-a.com/) 的JavaScript代码使用XMLHttpRequest来发起一个到 [https://domain-b.com/data.json](https://domain-b.com/data.json) 的请求。

> 出于安全性，浏览器限制脚本内发起的跨源HTTP请求。 例如，XMLHttpRequest和Fetch API遵循同源策略。 这意味着使用这些API的Web应用程序只能从加载应用程序的同一个域请求HTTP资源，除非响应报文包含了正确CORS响应头。

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308378.jpeg)

在上图中，当我们访问`domain-a.com`的页面，这其中蓝色的image是从`domain-a.com`请求的，这属于同源请求，是被允许的。红色的image是从 `domain-b.com`请求的，需要收到CORS机制的控制

> 跨源域资源共享（ CORS ）机制允许 Web 应用服务器进行跨源访问控制，从而使跨源数据传输得以安全进行。现代浏览器支持在 API 容器中（例如 XMLHttpRequest 或 Fetch ）使用 CORS，以降低跨源 HTTP 请求所带来的风险。

## 简单请求

> 比如说，假如站点 [http://foo.example](http://foo.example/) 的网页应用想要访问 [http://bar.other](http://bar.other/) 的资源。

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308566.jpeg)

分别查看请求报文和响应报文

```xml
GET /resources/public-data/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Referer: http://foo.example/examples/access-control/simpleXSInvocation.html
Origin: http://foo.example

HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 00:23:53 GMT
Server: Apache/2.0.61
Access-Control-Allow-Origin: *
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Transfer-Encoding: chunked
Content-Type: application/xml
```

> 第 1\~10 行是请求首部。第10行 的请求首部字段 Origin 表明该请求来源于 [http://foo.example](http://foo.example/)。
> 第 13\~22 行是来自于 [http://bar.other](http://bar.other/) 的服务端响应。响应中携带了响应首部字段 Access-Control-Allow-Origin（第 16 行）。使用 Origin 和 Access-Control-Allow-Origin 就能完成最简单的访问控制。本例中，服务端返回的 Access-Control-Allow-Origin: * 表明，该资源可以被任意外域访问。如果服务端仅允许来自 [http://foo.example](http://foo.example/) 的访问，该首部字段的内容如下：
> Access-Control-Allow-Origin: [http://foo.example](http://foo.example/)
> 现在，除了 [http://foo.example](http://foo.example/)，其它外域均不能访问该资源（该策略由请求首部中的 ORIGIN 字段定义，见第10行）。Access-Control-Allow-Origin 应当为 * 或者包含由 Origin 首部字段所指明的域名。

## 预检请求

> 与前述简单请求不同，“需预检的请求”要求必须首先使用 OPTIONS 方法发起一个预检请求到服务器，以获知服务器是否允许该实际请求。"预检请求“的使用，可以避免跨域请求对服务器的用户数据产生未预期的影响。
> 如下是一个需要执行预检请求的 HTTP 请求：

```jsx
var invocation = new XMLHttpRequest();
var url = 'http://bar.other/resources/post-here/';
var body = '<?xml version="1.0"?><person><name>Arun</name></person>';

function callOtherDomain(){
  if(invocation)
    {
      invocation.open('POST', url, true);
      invocation.setRequestHeader('X-PINGOTHER', 'pingpong');
      invocation.setRequestHeader('Content-Type', 'application/xml');
      invocation.onreadystatechange = handler;
      invocation.send(body);
    }
}
```

> 上面的代码使用 POST 请求发送一个 XML 文档，该请求包含了一个自定义的请求首部字段（X-PINGOTHER: pingpong）。另外，该请求的 Content-Type 为 application/xml。因此，该请求需要首先发起“预检请求”。

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308507.png)

```xml
OPTIONS /resources/post-here/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
Origin: http://foo.example
Access-Control-Request-Method: POST
Access-Control-Request-Headers: X-PINGOTHER, Content-Type

HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:39 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.example
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: X-PINGOTHER, Content-Type
Access-Control-Max-Age: 86400
Vary: Accept-Encoding, Origin
Content-Encoding: gzip
Content-Length: 0
Keep-Alive: timeout=2, max=100
Connection: Keep-Alive
Content-Type: text/plain
```

预检请求完成之后，发送实际请求：

```xml
POST /resources/post-here/ HTTP/1.1
Host: bar.other
User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1b3pre) Gecko/20081130 Minefield/3.1b3pre
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: en-us,en;q=0.5
Accept-Encoding: gzip,deflate
Accept-Charset: ISO-8859-1,utf-8;q=0.7,*;q=0.7
Connection: keep-alive
X-PINGOTHER: pingpong
Content-Type: text/xml; charset=UTF-8
Referer: http://foo.example/examples/preflightInvocation.html
Content-Length: 55
Origin: http://foo.example
Pragma: no-cache
Cache-Control: no-cache

<?xml version="1.0"?><person><name>Arun</name></person>

HTTP/1.1 200 OK
Date: Mon, 01 Dec 2008 01:15:40 GMT
Server: Apache/2.0.61 (Unix)
Access-Control-Allow-Origin: http://foo.example
Vary: Accept-Encoding, Origin
Content-Encoding: gzip
Content-Length: 235
Keep-Alive: timeout=2, max=99
Connection: Keep-Alive
Content-Type: text/plain

[Some GZIP'd payload]
```

> 浏览器检测到，从 JavaScript 中发起的请求需要被预检。从上面的报文中，我们看到，第 1\~12 行发送了一个使用 OPTIONS 方法的“预检请求”。 OPTIONS 是 HTTP/1.1 协议中定义的方法，用以从服务器获取更多信息。该方法不会对服务器资源产生影响。 预检请求中同时携带了下面两个首部字段：

```xml
Access-Control-Request-Method: POST
Access-Control-Request-Headers: X-PINGOTHER, Content-Type
```

> 首部字段 Access-Control-Request-Method 告知服务器，实际请求将使用 POST 方法。首部字段 Access-Control-Request-Headers 告知服务器，实际请求将携带两个自定义请求首部字段：X-PINGOTHER 与 Content-Type。服务器据此决定，该实际请求是否被允许。
> 第14\~26 行为预检请求的响应，表明服务器将接受后续的实际请求。重点看第 17\~20 行：

```xml
Access-Control-Allow-Origin: http://foo.example
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: X-PINGOTHER, Content-Type
Access-Control-Max-Age: 86400
```

> 首部字段 Access-Control-Allow-Methods 表明服务器允许客户端使用 POST, GET 和 OPTIONS 方法发起请求。该字段与 HTTP/1.1 Allow: response header 类似，但仅限于在需要访问控制的场景中使用。
> 首部字段 Access-Control-Allow-Headers 表明服务器允许请求中携带字段 X-PINGOTHER 与 Content-Type。与 Access-Control-Allow-Methods 一样，Access-Control-Allow-Headers 的值为逗号分割的列表。
> 最后，首部字段 Access-Control-Max-Age 表明该响应的有效时间为 86400 秒，也就是 24 小时。在有效时间内，浏览器无须为同一请求再次发起预检请求。请注意，浏览器自身维护了一个最大有效时间，如果该首部字段的值超过了最大有效时间，将不会生效。

## 便捷跨域解决方案

- Fork github项目 [https://github.com/Rob--W/cors-anywhere.git](https://github.com/Rob--W/cors-anywhere.git)
- 在[heroku.com](http://heroku.com/)注册一个账号
- 在[heroku.com](http://heroku.com/)上创建一个app

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308258.png)

- app名字唯一，后续访问时会用到，比如我的就是halfcoke1
- 选择GitHub，输入刚刚Fork的仓库，点击connect

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308021.png)

- 点击这两个位置，然后等待完成

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202204102308207.png)

- 接下来便可以通过 [`https://halfcoke1.herokuapp.com/](https://halfcoke1.herokuapp.com/)<url>`的方式进行访问，比如访问 [`https://halfcoke1.herokuapp.com/https://github.com/login/oauth/access_token`](https://halfcoke.herokuapp.com/https://github.com/login/oauth/access_token)

## 参考资料

1.[https://developer.mozilla.org/zh-CN/docs/Web/HTTP/CORS](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/CORS)

[跨源资源共享（CORS）](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/CORS)

2.[https://segmentfault.com/a/1190000011145364](https://segmentfault.com/a/1190000011145364)

[前端常见跨域解决方案（全）](https://segmentfault.com/a/1190000011145364)

3.Cover图片来自[AJAX 与跨域通信（二）：跨域解决方案](https://chorer.github.io/2019/11/07/F-AJAX%E4%B8%8E%E8%B7%A8%E5%9F%9F%E9%80%9A%E4%BF%A1%EF%BC%88%E4%BA%8C%EF%BC%89/)