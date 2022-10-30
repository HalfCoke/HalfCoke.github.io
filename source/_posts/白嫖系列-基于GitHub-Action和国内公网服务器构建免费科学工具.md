---
title: 白嫖系列-基于GitHub Action和国内公网服务器构建免费科学工具
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
date: 2022-10-30 16:01:55
typora-copy-images-to: upload
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/spf.jpg'
tags:
  - 转发
  - 隧道
  - Gihub Action
categories:
  - 工具
  - 折腾
  - 科学工具
---

> 重要说明：这篇文章仅用于技术探讨，请遵守相关法律法规

# 环境准备

## Github Action

Github Action是一种持续集成和部署（CI/CD）平台，可用于自动生成、测试和部署。详细介绍请参考[官网](https://docs.github.com/en/actions)

由于Github本身是在外网，在本文中便是借助这个临时环境部署了WS+VMESS环境来进行科学上网。（关于VMESS是什么请谷哥或度娘）。

Github Action可以在公开的仓库中免费使用，下面主要介绍与本文相关的主要功能和概念。

### Github Action基本介绍

Action的功能在这里可以直接看到

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221030163949452.png)

Action主要通过写yaml文件进行定义，yaml文件需要定义在`.github/workflows`路径下

![image-20221030164124222](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221030164124222.png)

下面给出一个简单的action文件的组成部分

```yaml
name: action name # 这里是描述这个action的名字
on: # action的触发条件，比如手动、定时、收到push事件等
  workflow_dispatch: # 这个表示，该action可以手动触发
  schedule: # 定时调度规则
    - cron: '*/30 * * * *'
jobs: # 开始定义要执行的任务
  first: # 任务的名称，这个‘first’可以自定义名字
    runs-on: unbuntu-latest # 需要依赖于什么环境运行，参看官网https://docs.github.com/en/actions/using-jobs/choosing-the-runner-for-a-job
    steps: # 开始定义任务执行的步骤
      - name: set env # 步骤的名字
        run: | # 这一步骤的脚本，可以直接sudo执行命令，环境中的默认用户名是runner，下面这个脚本就是修改runner的默认密码
          sudo apt update
          sudo apt -y install sshpass
          sudo passwd runner << EOD
          root
          root
          EOD
      - name: step2
      ....
```

下图对上面部分位置做了简单对应

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221030165206665.png)

### Github action secrets介绍

因为仓库是公开的，secrets主要是为了存储一些不想被别人看到的信息。secrets的创建位置如下图所示，secrets创建后不能修改，只能更新。

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221030165456577.png)

secrets创建后，可以在yaml文件中以`${{ secrets.SERVER_IP }}`的方式引用，注意两侧有两个空格。

至此，最简单的action配置介绍完了。

## 公网服务器

公网服务器的申请可以从阿里云、腾讯云等大厂申请国内的公网服务器，这里主要是要有一个公网ip，方便action中的虚拟环境可以直接访问，如果家庭有公网ip也可以不用申请云服务器。

## 科学工具

本文的环境使用clash客户端。

ClashX For Mac：https://github.com/yichengchen/clashX/releases

Clash For Windows（当前也支持Mac）：https://github.com/Fndroid/clash_for_windows_pkg/releases

# 原理介绍

整个工作过程的原理如下图所示，原理很简单：

1. Github Action将其中的Vmess服务转发至国内的公网服务器上
2. 客户端直接连接公网服务器上的端口

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221030172053793.png)

# 部署及使用

## 服务端

action的配置文件可以直接从这里下载：https://halfcoke.github.io/config/action/ssh-forward.yaml

### v2ray配置说明

下面摘出了v2ray的config.json的配置文件，做一些简单说明

```json
{
  "log": {
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 3456, // v2ray监听的端口，需要与caddy配置文件中相同
      "protocol": "vmess",
      "allocate": {
        "strategy": "always"
      },
      "settings": {
        "clients": [
          {
            "id": "26e3a620-e33e-****-****-4570b0ecf39c", // uuid，客户端连接时使用，需要重新生成
            "level": 1,
            "alterId": 0,
            "email": "client@example.com"
          }
        ],
        "disableInsecureEncryption": true
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "connectionReuse": true,
          "path": "/graphql" // ws的路径
        },
        "security": "none",
        "tcpSettings": {
          "header": {
            "type": "http",
            "response": {
              "version": "1.1",
              "status": "200",
              "reason": "OK",
              "headers": {
                "Content-Type": [
                  "application/octet-stream",
                  "application/x-msdownload",
                  "text/html",
                  "application/x-shockwave-flash"
                ],
                "Transfer-Encoding": ["chunked"],
                "Connection": ["keep-alive"],
                "Pragma": "no-cache"
              }
            }
          }
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "domainStrategy": "AsIs",
    "rules": [
      {
        "type": "field",
        "ip": [
          "0.0.0.0/8",
          "10.0.0.0/8",
          "100.64.0.0/10",
          "127.0.0.0/8",
          "169.254.0.0/16",
          "172.16.0.0/12",
          "192.0.0.0/24",
          "192.0.2.0/24",
          "192.168.0.0/16",
          "198.18.0.0/15",
          "198.51.100.0/24",
          "203.0.113.0/24",
          "::1/128",
          "fc00::/7",
          "fe80::/10",
          "geoip:private"
        ],
        "outboundTag": "blocked"
      },
      {
        "type": "field",
        "protocol": ["bittorrent"],
        "outboundTag": "blocked"
      }
    ]
  }
}
```

### Caddy配置说明

下面对Caddy配置文件进行简单说明

```bash
:${{ secrets.SERVER_REMOTE_PORT }} { # 这个端口需要与ssh转发的端口相同
  log {
  	output stdout
  }
  root * /web
  reverse_proxy localhost:3456 # 这个端口需要与v2ray相同
}
auto_https off # 关闭自动https
```

### ssh远程端口转发说明

因为ssh本身不支持在命令行中输入密码，可以采用类似这种方式，或者使用sshpass，本文使用了sshpass

```bash
sudo passwd runner << EOD
root
root
EOD
```

端口转发命令：

```bash
sshpass -p ${{ secrets.SERVER_SSH_PASSWORD }} ssh -o "StrictHostKeyChecking no" -f -NT -p ${{ secrets.SERVER_SSH_PORT }} -R :${{ secrets.SERVER_REMOTE_PORT }}:localhost:${{ secrets.SERVER_REMOTE_PORT }} ${{ secrets.SERVER_SSH_USER }}@${{ secrets.SERVER_IP }}
```

关于ssh端口转发的详细介绍请参考这篇文章：SSH端口转发详解https://halfcoke.github.io/2021/cac946/

### Github Action Secrets配置

需要在Secrets中配置下面这几个变量：

```bash
SERVER_SSH_USER # 公网服务器的ssh用户
SERVER_SSH_PASSWORD  # 公网服务器的ssh密码

SERVER_IP # 公网服务器的域名，目前必须使用域名
SERVER_SSH_PORT # 公网服务器的ssh端口

SERVER_REMOTE_PORT # vmess服务想要在公网服务器上监听的端口
```

## 客户端

客户端主要配置clash的配置文件，已经标出了需要修改的部分。

```yaml

redir-port: 7892 

# 允许局域网的连接
allow-lan: true

# 自动更新周期

interval: 3600

# 规则模式：Rule（规则） / Global（全局代理）/ Direct（全局直连）
mode: global 

# 设置日志输出级别 (默认级别：silent，即不输出任何内容，以避免因日志内容过大而导致程序内存溢出）。
# 5 个级别：silent / info / warning / error / debug。级别越高日志输出量越大，越倾向于调试，若需要请自行开启。
log-level: silent
# Clash 的 RESTful API
external-controller: '0.0.0.0:9090'

# RESTful API 的口令
secret: '' 
proxies: 
  - name: "代理名字" # 需要修改
    server: "服务器域名" # 需要修改
    port: 服务器监听的端口 # 需要修改
    type: vmess
    uuid: vmess配置文件中的uuid # 需要修改
    alterId: 0
    cipher: auto
    network: ws
    tls: false
    ws-path: /graphql
    ws-opts: 
      path: /graphql
proxy-groups:
  - name: 🎯 全球直连
    type: select
    proxies:
      - 代理名字 # 需要修改
rules:
 - GEOIP,CN,🎯 全球直连
```



好了，快去测试一下吧！

# 参考资料

1. github action. https://docs.github.com/en/actions
2. v2ray服务. https://www.v2fly.org/
3. caddy配置. https://caddyserver.com/docs/
