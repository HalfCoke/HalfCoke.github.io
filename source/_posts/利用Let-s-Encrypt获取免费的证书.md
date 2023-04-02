---
title: 利用Let's Encrypt获取免费的证书
tags:
  - 证书
  - Linux
  - Docker
  - 工具
categories:
  - 工具
  - 系统工具
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
abbrlink: b14aeca0
date: 2022-10-03 14:26:40
update: 2022-09-18 14:41:08
---

# Let's Encrypt简介（摘自官网文档）

为了在你的网站上设定HTTPS，你需要从凭证颁发机构(Certificate Authority, CA) 获取凭证，而Let's Encrypt 就是一个凭证颁发机构。要从Let's Encrypt 上获得属于你网站的凭证，你必须证明你对域名的控制权。你可以在你的主机上运行使用[ACME 协议](https://tools.ietf.org/html/rfc8555)的软件，来获取Let's Encrypt 的凭证。

Let’s Encrypt 和 [ACME 协议](https://tools.ietf.org/html/rfc8555)的目标是使配置能够自动获取受信任浏览器的证书的 HTTPS 服务器成为可能。 这是通过在 web 服务器上运行证书管理代理来完成的。

## 域名认证

Let’s Encrypt 通过公钥识别服务器管理员。 证书管理软件首次与 Let’s Encrypt 交互时，会生成新的密钥对，并向 Let’s Encrypt CA 证明服务器控制着一个或多个域名。 这类似于创建帐户和向该帐户添加域名的传统证书颁发流程。

## ACME客户端

Let’s Encrypt 使用 ACME 协议来验证您对给定域名的控制权并向您颁发证书。 要获得 Let’s Encrypt 证书，您需要选择一个要使用的 ACME 客户端软件。

我们建议大多数人从 [Certbot](https://certbot.eff.org/) 客户端开始。 它既可以只为您获取证书，也可以帮助您获取并安装证书。 它易于使用，适用于许多操作系统，并且具有出色的文档。

# Certbot简介

Cerbot是免费开源的工具，可以使用Let's Encrypt使网站开启HTTPS

# ACME.sh

**acme.sh**实现了`acme`协议，可以从letsencrypt生成免费的证书。

# 基于ACME.sh与DNSPOD实现自动生成证书

> acme.sh目前支持cloudflare, dnspod, cloudxns, godaddy 以及 ovh 等解析商，参考https://github.com/acmesh-official/acme.sh/wiki/dnsapi
>
> 下文以DNSPOD为例

## 准备工作

### 获取DNSPOD的id与key

1. 登陆DNSpod

   ![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221003151659511.png)

2. 点击API密钥

   ![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221003151747649.png)

   

   3. 点击Dnspod token，创建密钥

      ![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221003151917001.png)

   4. 按要求验证后输入名称，保存ID与Token

   至此获得Dnspod的token

### 安装acme.sh（仅在主机部署时使用）

参考acme.sh文档https://github.com/acmesh-official/acme.sh/wiki/How-to-install可以手动安装脚本

```bash
./acme.sh --install  \
--home ~/myacme \
--config-home ~/myacme/data \
--cert-home  ~/mycerts \
--accountemail  "my@example.com" \
--accountkey  ~/myaccount.key \
--accountconf ~/myaccount.conf \
--useragent  "this is my client."
```

参数说明：

- `--home`参数是自定义的安装路径，默认：`~/.acme.sh`
- `--config-home`是写入配置的文件夹，包括证书、配置等全部文件，默认是`--home`
- `--cert-home`是自定义的路径保存申请的证书，默认在`--config-home`中
- `--accountemail`是用来向Let's Encrypt申请证书时所用的邮箱，将在这里收到更新提醒
- `--accountkey`是用来存储用户私钥的文件，默认保存在`--config-home`中
- `--user-agent`是发送至Let's Encrypt的`user-agent`头部的值
- `--nocron`表示不进行自动调度

### 生成证书

使用下面的命令可以生成证书，这里使用了dnspod的api，更多api配置请参考https://github.com/acmesh-official/acme.sh/wiki/dnsapi

```bash
export DP_Id="1234"
export DP_Key="sADDsdasdgdsf"

~/.acme.sh/acme.sh --issue --dns dns_dp -d *.example.com
```

`DP_ID`和`DP_Key`会被保存在`~/.acme.sh/account.conf`

## 安装证书

acme.sh不建议直接将nginx/apache的配置路径指定为acme.sh证书安装的路径

>  注意, 默认生成的证书都放在安装目录下: `~/.acme.sh/`, 请不要直接使用此目录下的文件, 例如: 不要直接让 nginx/apache 的配置文件使用这下面的文件. 这里面的文件都是内部使用, 而且目录结构可能会变化.

### Case1: 主机已有Nginx

已有Nginx时可直接使用acme.sh脚本对证书进行安装。

```bash
~/.acme.sh/acme.sh --install-cert -d example.com \
--key-file       /path/to/keyfile/in/nginx/key.pem  \
--fullchain-file /path/to/fullchain/nginx/cert.pem \
--reloadcmd     "service nginx force-reload"
```

(一个小提醒, 这里用的是 `service nginx force-reload`, 不是 `service nginx reload`, 据测试, `reload` 并不会重新加载证书, 所以用的 `force-reload`)

Nginx 的配置 `ssl_certificate` 使用 `/etc/nginx/ssl/fullchain.cer` ，而非 `/etc/nginx/ssl/<domain>.cer` ，否则 [SSL Labs](https://www.ssllabs.com/ssltest/) 的测试会报 `Chain issues Incomplete` 错误。

`--install-cert`命令可以携带很多参数, 来指定目标文件. 并且可以指定 reloadcmd, 当证书更新以后, reloadcmd会被自动调用,让服务器生效.

详细参数请参考: https://github.com/Neilpang/acme.sh#3-install-the-issued-cert-to-apachenginx-etc

值得注意的是, 这里指定的所有参数都会被自动记录下来, 并在将来证书自动更新以后, 被再次自动调用.

### Case2: 主机没有Nginx，仅用于生成证书，手动复制至其他位置

这里使用docker来实现自动生成证书至指定路径，需要将docker的生成路径暴露出来。

acme.sh本身也提供了docker方式，acme.sh提供的docker方式应该能处理大多数场景https://github.com/acmesh-official/acme.sh/wiki/Run-acme.sh-in-docker

这里主要实现的是通过docker获取证书，然后将证书输出到指定文件夹中

Dockerfile相关文件参考：https://github.com/HalfCoke/open_action/tree/main/docker/acme.sh

也可以直接使用`docker pull halfcoke/acme.sh`这个镜像：https://hub.docker.com/repository/docker/halfcoke/acme.sh

镜像的使用方式如下：

```bash
docker run -d \
-e EMAIL=abc@example.com \
-e DOMAINS="a.example.com,b.example.com,*.c.example.com" \
-e API="DNSPOD;dpid,dpkey" \
-v /path/to/ssl:/ssl
halfcoke/acme.sh
```

目前仅支持DNSPOD api，后面会逐渐增加，或者自行改造也比较容易。

向nginx中配置证书，使用这两个文件即可

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221006173103336.png)

### Case3: todo

逐渐完善其他场景.....

# 参考资料

1. Let's Encrypt 官网：https://letsencrypt.org/zh-cn/how-it-works/
2. Cerbot官网：https://certbot.eff.org/
3. ACME.sh：https://github.com/acmesh-official/acme.sh
