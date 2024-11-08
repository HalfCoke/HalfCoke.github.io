---
title: 使用Nginx同时代理Web服务与Trojan（或其他TCP/UDP服务）
tags:
  - Trojan
  - 工具
  - Nginx
categories:
  - 工具
  - 折腾
  - 科学工具
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
abbrlink: 6b488705
cover: https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/Nginx-Web-Server-Reverse-Proxy-Load-Balancer-Dengan-Performa-Tinggi.png
date: 2023-04-02 15:58:29
---

整体部署可以分为三个部分：Nginx+Web服务+Trojan

其中web服务可以是任意自定义的服务，在本文最后给出我的web服务的配置，但不做过多说明。

另外，Trojan使用docker部署，Nginx使用宿主机部署的服务

# 一些前提条件

1. 需要有自己的域名，可以考虑申请使用免费的域名（eu.org），但是需要有一段时间的审核，申请的教程参考https://iweec.com/363.html

2. 需要申请ssl证书，建议使用certbot，安装教程有很多，安装完成后可以使用如下命令申请自定义证书

   ```bash
   apt install certbot
   apt install python3-certbot-nginx
   # 仅申请，不进行安装
   certbot certonly --nginx -d test.example.org
   # 可以通过crontab配置renew
   crontab -e
   # 在打开的编辑器中放入以下内容
   0 12 * * * /usr/bin/certbot renew --quiet
   ```
   
   

# Trojan代理服务部署

来自ChatGPT的说明：

> Trojan代理服务是一种基于Trojan协议的网络代理工具，它可以在用户与互联网之间建立一个加密的通信隧道，以保护用户的网络通信安全和隐私。通过使用Trojan代理服务，用户可以隐藏其真实IP地址和位置，以避免被追踪或监视，同时还可以绕过地理限制和网络封锁，访问被屏蔽的内容和服务。
>
> 与其他传统的代理服务不同，Trojan代理服务使用了一种更加安全和高效的加密方式，可以在传输过程中对数据进行加密和解密，保证数据传输的安全性和可靠性。此外，Trojan代理服务还支持多种协议和代理模式，包括HTTP、SOCKS5等，可以满足不同用户的需求和应用场景。
>
> 然而，由于Trojan代理服务可以被用于绕过封锁和访问被屏蔽的内容，也可能被用于非法活动，因此在使用Trojan代理服务时，用户应该注意合法使用，不要用于违法行为，同时也需要选择可靠和安全的服务提供商，以保证使用的安全和隐私。

Tronjan代理服务使用docker部署，docker-compose文件如下：

将其中的`test.example.org`换成你自己的域名

```yaml
version: "3"
services:
  trojan:
    image: trojangfw/trojan
    #restart: always
    command: trojan /etc/trojan/config.json
    ports:
      - "6443:443/tcp"
      - "6443:443/udp"
    volumes:
      - ./config.json:/etc/trojan/config.json
      - /etc/letsencrypt/live/test.example.org/fullchain.pem:/etc/fullchain.pem
      - /etc/letsencrypt/live/test.example.org/privkey.pem:/etc/privkey.pem
```

trojan的配置文件如下：

注意修改文件注释的部分

```json
{
    "run_type": "server",
    "local_addr": "0.0.0.0",
    "local_port": 443,
    "remote_addr": "127.0.0.1", // 一般情况填写本机的地址，当请求不匹配trojan协议时，会自动向这里发送http请求
    "remote_port": 80,
    "password": [
        "11111" // 换成你的密码
    ],
    "log_level": 0,
    "tcp": {
        "fastopen": true,
        "no_delay": true,
        "keepalive": true,
        "reuse_port": true
    },
    "udp": {
        "prefer_gro": true,
        "buffer_size": 6291456,
        "reuse_port": true
    },
    "ssl": {
        "cert": "/etc/fullchain.pem",
        "key": "/etc/privkey.pem",
        "alpn": [
            "http/1.1"
        ],
        "verify": true,
        "verify_hostname": true,
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-SHA",
        "session_ticket": true,
        "reuse_session": true,
        "prefer_server_cipher": true,
        "sni": "test.example.org" // 换成你自己的域名
    }
}
```



直接`docker-compose up -d `就可以启动了，可以先访问测试一下行不行，然后再配置通过nginx代理。

可以直接在clash的`setting -> parsers`处增加如下配置

```yaml
parsers: # array
  - url: https://.... # 你自己的订阅链接
    yaml:
      prepend-rules:
        - 'DOMAIN-SUFFIX,openai.com,CHATGPT_PERSONAL' # 想要自己定义的一些规则，如果不需要直接删掉
      append-proxies:
        - name: test.example.org  # 名字随便起
          type: trojan
          server: test.example.org # 你自己的服务器域名
          port: 443
          password: 11111  # trojan配置文件中的密码
          udp: true
          sni: test.example.org  # 你自己服务器的域名
      append-proxy-groups:
        - name: CHATGPT_PERSONAL # 名字随便起，别和上面一样就行
          type: select
          proxies:
            - "test.example.org" # 上面proxies的name
```

或者直接编辑clash的配置文件

```yaml
# (HTTP and SOCKS5 in one port)
mixed-port: 7890
# RESTful API for clash
external-controller: 127.0.0.1:58767
allow-lan: false
mode: rule
log-level: warning

# proxies:

# proxy-groups:

# rules:
#   - DOMAIN-SUFFIX,google.com,DIRECT
#   - DOMAIN-KEYWORD,google,DIRECT
#   - DOMAIN,google.com,DIRECT
#   - DOMAIN-SUFFIX,ad.com,REJECT
#   - GEOIP,CN,DIRECT
#   - MATCH,DIRECT
proxies:
  - name: TEST_TROJAN
    type: trojan
    server: test.example.org # 你自己的服务器域名
    port: 443 # 注意端口
    password: 1111 # trojan配置文件中的密码
    udp: true
    sni: test.example.org # 你自己的服务器域名
proxy-groups:
  - name: 🎯 全球直连
    type: select
    proxies:
      - TEST_TROJAN
rules:
  - GEOIP,CN,🎯 全球直连

```

到现在，应该可以通过trojan进行代理了，接下来看下如何通过nginx在前面进行反向代理，实现端口复用。

# Nginx配置

一般情况我们直接使用nginx进行http的反向代理，但是trojan不是标准http协议，直接用nginx的http模块无法使用，此时需要使用nginx的stream模块，最新版nginx可以直接使用。

stream模块与http模块同级，可以进行tcp/udp流量的反向代理，下面给出nginx不同部分的配置文件，在配置文件中进行说明。

## 代理Trojan服务配置

`/etc/nginx/nginx.conf`

```bash
user  nginx;
worker_processes  auto;
error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    # 日志格式增加了一个$proxy_protocol_addr，后面会说明
    log_format  main  '$proxy_protocol_addr - $remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"'; 
    access_log  /var/log/nginx/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  65;
    #gzip  on;
    include /etc/nginx/conf.d/*.conf;
}
# 前面其余配置均是nginx默认配置，没有做改动
# 新增stream模块
stream {
    log_format steam_main '$remote_addr [$time_local] $protocol $status $bytes_sent $bytes_received';
    # map的作用时将sni中的主机名，进行映射
    # 下面这个，当内部变量$ssl_preread_server_name匹配到任意一个域名的时候，会将第二个值赋值给$backend_name
    # 具体来说，当sni为test.example.org时，变量$backend_name的值为trojan_proxy
    map $ssl_preread_server_name $backend_name {
        test.example.org trojan_proxy;
        default web;
    }
		# upstream模块作用与http模块中的相同
    upstream web {
        server 127.0.0.1:80;
    }
    upstream chat {
       server 127.0.0.1:1443;
    }
    upstream trojan {
       server 127.0.0.1:6443;
    }
    
    server {
        access_log /var/log/nginx/stream.access.log steam_main;
        error_log /var/log/nginx/stream.error.log debug;
        listen 443 reuseport; # 这里server监听443端口，http模块中的server就不能监听443端口了，需要通过proxy_pass代理
        listen [::]:443 reuseport;
        proxy_protocol on; # 开启代理协议，会将4层访问的真实地址传递给后端服务，当然后端服务也需要支持代理协议
        ssl_preread on; # 开启预读sni的功能，使得map模块正常工作
        proxy_pass $backend_name;
    }
    # 由于trojan本身不支持proxy_protocol代理协议，需要通过nginx做下转化
    upstream trojan_proxy {
      server 127.0.0.1:6234;
    }
    
    server {
      listen 127.0.0.1:6234 proxy_protocol;
      proxy_pass trojan;
    }
}
```

nginx文件做了如上配置后，就应该可以正常代理到后端的trojan服务了。

## 代理其他web服务配置

其他http服务中的server在进行监听时，就不能使用443端口了，需要指定其他端口，下面给出服务配置。



```bash
server {
        server_name test.example.org;
        # logging
        access_log /var/log/nginx/access.log main;
        error_log /var/log/nginx/error.log warn;

        # reverse proxy
        location / {
                proxy_pass http://127.0.0.1:3002;
                #proxy_http_version      1.1;
                proxy_cache_bypass      $http_upgrade;
                proxy_set_header Upgrade                        $http_upgrade;
                proxy_set_header Connection             "upgrade";
                proxy_set_header Host                           $host;
                # 这里应该换成$proxy_protocol_addr，由于我的后端服务不需要ip，就没修改
                proxy_set_header X-Real-IP                      $remote_addr; 
                proxy_set_header X-Forwarded-For        $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto      $scheme;
                proxy_set_header X-Forwarded-Host       $host;
                proxy_set_header X-Forwarded-Port       $server_port;
        }

        # additional config
        # favicon.ico
        location = /favicon.ico {
                log_not_found off;
                access_log off;
        }
        # robots.txt
        location = /robots.txt {
                log_not_found off;
                access_log off;
        }
        # gzip
        gzip on;
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_types text/plain text/css text/xml application/json application/javascript application/rss+xml application/atom+xml image/svg+xml;

    # 注意端口，并且需要proxy_protocol这个参数
    listen [::]:1443 ssl ipv6only=on proxy_protocol; # managed by Certbot
    listen 1443 ssl proxy_protocol; # managed by Certbot
    ssl_certificate /etc/letsencrypt/live/<你的web服务域名>/fullchain.pems; # managed by Certbot
    ssl_certificate_key /etc/letsencrypt/live/<你的web服务域名>/privkey.pem; # managed by Certbot
    include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
}


server {
    if ($host = <你的web服务域名>) {
        return 301 https://$host$request_uri;
    } # managed by Certbot
    server_name <你的web服务域名>;
    # 注意这里没有proxy_protocol参数，为了实现自动跳转至https
    listen 80;
    listen [::]:80;
    return 404; # managed by Certbot
}
```

下面是nginx的http块默认的配置文件，我修改为，非指定域名均无返回的设置了。

```bash
server {
       listen       80 default_server;
        listen       [::]:80 default_server; 
        listen       1443 ssl http2 default_server proxy_protocol;
        listen       [::]:1443 ssl http2 default_server proxy_protocol;
        server_name  _;
        ssl_reject_handshake on ;
        return 444;

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
```



# 参考资料

1. https://chat.openai.com/chat
2. https://razeen.me/posts/nginx-tcp-stream-proxy-keep-real-client-ip/
3. https://www.huangyuexiang.com/2020/05/09/Nginx%E9%85%8D%E7%BD%AE%E4%B8%80%E4%B8%AA%E7%AB%AF%E5%8F%A3%E5%90%8C%E6%97%B6%E5%A4%84%E7%90%86%E5%A4%9A%E7%A7%8D%E5%8D%8F%E8%AE%AE/
4. https://www.chengxiaobai.com/trouble-maker/trojan-shared-443-port-scheme
