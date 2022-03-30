---
title: FRP端口转发工具
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: frp端口转发工具加部署详解
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/20210908221022.jpg'
tags:
  - Linux
  - SSH
  - 转发
  - 隧道
categories:
  - 工具
abbrlink: f282203b
date: 2021-09-08 22:06:21
update: 2021-09-08 22:06:21
---

# FRP端口转发工具及部署方式详解(win+linux)

## 前言

在此前的[文章](https://halfcoke.github.io/2021/cac946/)中，介绍了使用ssh命令进行端口转发。

使用ssh进行端口转发有优点也有缺点，其优点主要在使用方便，服务器上基本都安装了ssh服务用来进行远程登录，因此只要有ssh命令就能实现端口转发的功能。但其缺点也很明显，主要在于远程转发、本地转发、动态转发等配置参数让使用者常常混淆，使用频率不高时也记不住这些参数。如果忘记设置ssh保活或出现网络波动导致链接断开也不方便自动重连，常常需要用户自己再写脚本来维护，这也增加了复杂性。

在实际使用中使用ssh来进行临时的端口转发比较方便，但是如果我们想建立一个长期的转发链接的时候(比如转发Windows的远程访问端口，可以随时远程访问放在固定位置的电脑)，在使用ssh就可能要自己造一些轮子。

为方便起见，更推荐使用frp工具进行端口转发。

## frp工具介绍

frp 是一个专注于内网穿透的高性能的反向代理应用，支持 TCP、UDP、HTTP、HTTPS 等多种协议。可以将内网服务以安全、便捷的方式通过具有公网 IP 节点的中转暴露到公网。

frp是采用go语言编写的开源工具，go保证了高效率，开源保证了工具没有夹带私货，可以放心使用。

首先附上frp工具的下载链接：[https://github.com/fatedier/frp/releases](https://github.com/fatedier/frp/releases)

frp工具有很多种功能，我们将在本文中介绍最基本的端口转发部分的功能。

frp采用CS模式，需要在具有公网IP的节点上设置服务端，在需要进行转发的机器上设置客户端。

工具的安装部署也极为便捷，直接解压压缩包便可以获得如下文件。

![image-20210908224239220](https://gitee.com/halfcoke/blog_img/raw/master/20210908224239.png)

文件非常清晰，`frpc`表示客户端，`frpc.ini`表示客户端配置；`frps`表示服务端，`frps.ini`表示服务端配置。

接下来我们介绍一下用于端口转发的服务端、客户端的配置项。

### frp服务端配置

服务端配置daemo如下，实现基本功能需要配置的内容非常少。

```ini
[common]
bind_port = 1234

authentication_method = token
authenticate_heartbeats = true
authenticate_new_work_conns = true
token = ^EJSNkz4MLMJC6W!TyLhmNwJ3k3Hk833cmzBNU2ZasD3dja4*Bf

log_file = /opt/frp_0.37.0_linux_amd64/log/frps.log
log_level = debug
log_max_days = 7
```

在我的配置文件中主要分为三个部分：

- 基本配置

  在这项配置中，配置**`frp`服务端监听的端口**，这个端口是用来与frp客户端进行链接的，与我们后续要转发的服务无关。这一项一定要有，不然客户端也不知道链接谁。

  ```ini
  bind_port = 1234
  ```

- 安全配置

  这一项配置不是强制的，但是推荐配置。毕竟你也不想那自己的服务器去做慈善，主要以防万一你的服务端frp泄露。

  ```ini
  authentication_method = token
  authenticate_heartbeats = true
  authenticate_new_work_conns = true
  token = ^EJSNkz4MLMJC6W!TyLhmNwJ3k3Hk833cmzBNU2ZasD3dja4*Bf
  ```

  其中token换成自己生成的，其余三项配置与我相同即可，配置项的意思就是英文的意思，不用过多解释了。

- 日志配置

  日志配置根据自己的需要进行配置即可，也可以不配置，主要用来查看一下有没有异常的链接或查看bug等情况使用。

  `log_file`默认是`./frps.log`

  ```ini
  log_file = /opt/frp_0.37.0_linux_amd64/log/frps.log
  log_level = debug
  log_max_days = 7
  ```

### frp客户端配置

客户端的配置内容稍微多一点，因为涉及到我们要转发的服务的配置。服务端的配置daemon如下所示。

```ini
[common]
server_addr = test.cn
server_port = 1234

token = ^EJSNkz4MLMJC6W!TyLhmNwJ3k3Hk833cmzBNU2ZasD3dja4*Bf
authentication_method = token
authenticate_heartbeats = true
authenticate_new_work_conns = true

user = my_computer

log_file = ./log/frpc.log
log_level = debug


[rdp]
type = tcp
use_compression = true

local_ip = 127.0.0.1
local_port = 3389
remote_port = 3389

```

在这个配置文件中，可以分为5个部分：

- 基本配置

  在基本配置中，需要配置`frp`服务端的ip地址和端口，端口需要与服务端配置中`bind_port`相同。

  ```ini
  server_addr = test.cn
  server_port = 1234
  ```

- 安全配置

  安全配置需要与服务端保持一致，所有的内容都应相同。

  ```ini
  token = ^EJSNkz4MLMJC6W!TyLhmNwJ3k3Hk833cmzBNU2ZasD3dja4*Bf
  authentication_method = token
  authenticate_heartbeats = true
  authenticate_new_work_conns = true
  ```

- 用户名配置

  这条配置信息其实是给待转发端口的服务名增加了前缀，因为可能存在多个客户端共用同一个服务端的情况，避免服务名称冲突。

  比如在我们的配置中，要转发的`rdp`服务的完整服务名会自动拼接为`my_computer.rdp`。

  ```ini
  user = my_computer
  ```

- 日志配置

  日志配置与服务端的作用相同，根据需要选择配置即可。

  ```ini
  log_file = ./log/frpc.log
  log_level = debug
  ```

- 服务配置

  需要转发的服务在这里配置，其中`[rdp]`为服务名，中括号包起来的部分可以自定义

  `type`表示服务的链接类型，我们用于转发远程桌面或ssh端口是使用`tcp`，完整的选项可以参考[官网说明](https://gofrp.org/docs/reference/proxy/#%E5%9F%BA%E7%A1%80%E9%85%8D%E7%BD%AE)。

  `use_compression`表示是否对数据进行压缩

  `local_ip`和`local_port`表示运行`frp`客户端的机器能够直接访问到的地址，比如我要转发本机的远程桌面端口，就是如下的配置。如果我要转发本地局域网内的其他服务，按照当前机器访问服务的地址和端口填写即可。

  `remote_port`表示在**`frp`服务端**上监听的端口(用来访问当前服务使用)。在我的配置文件中，访问`test.cn:2345`也就相当于访问了**`frp`客户端**的3389端口。

  ```ini
  [rdp]
  type = tcp
  use_compression = true
  
  local_ip = 127.0.0.1
  local_port = 3389
  remote_port = 2345
  ```

## 部署方式

接下来介绍一下在Windows上与Linux上将frp部署的方式。

### Windows

- 方式一

  可以直接运行`frpc.exe`，但是这样无法做到后台运行，而且重启以后就没办法自动启动，所以推荐使用方式二，将`frpc`作为服务部署

- 方式二

  为了将`frpc.exe`作为服务部署，需要借助[`WinSW`工具](https://github.com/winsw/winsw)。这一工具仅需要简单的配置便可以将自己的应用作为windows服务。

  可以从[https://github.com/winsw/winsw/releases](https://github.com/winsw/winsw/releases)下载对应版本的软件(32位或64位)。

  `WinSW-x64.exe`或`WinSW-x32.exe`下载好以后，将该文件命名成你喜欢的名字，比如`myapp.exe`，同时新建一个同名的xml文件`myapp.xml`。

  继续本文的例子，我们可以复制一下内容到xml文件中。

  ```xml
  <service>
    
    <!-- ID of the service. It should be unique across the Windows system-->
    <id>rdpforward</id>
    <!-- Display name of the service -->
    <name>RDP Port Forward </name>
    <!-- Service description -->
    <description>Forward Windows RDP Port</description>
    
    <!-- Path to the executable, which should be started -->
    <executable>frp_0.37.0_windows_amd64\frpc.exe</executable>
  
    <arguments>-c "frp_0.37.0_windows_amd64\frpc.ini"  </arguments>
  
    <startmode>Automatic</startmode>
    <onfailure action="restart" delay="10 sec"/>
    <log mode="reset"></log>
  </service>
  ```

  其中:

  - `<id>`应该为系统范围内独一无二的标识。自己直接写就行，一般也不会和系统里的重复。

  - `<name>`为服务显示的名称，比如在下图中显示出了我这个服务的名称。

  - `<description>`为服务的描述，和名称一样，也是给自己看的。

  - `<executable>`要执行程序的路径，这里我写的是相对路径。

  - `<arguments>`执行程序的参数，对frpc来说，需要指定一下配置文件的位置。

  - `<startmode>`启动模式，是否是开机自动运行。

  - `<onfailure>`服务启动失败时的动作。

  - `<log>`记录日志的模式。

    ![image-20210908232555264](https://gitee.com/halfcoke/blog_img/raw/master/20210908232555.png)

  配置完成后，在`myapp.exe`所在的目录直接输入`cmd .`（注意有个空格 和点）直接打开cmd窗口，如下所示

  ![image-20210908233045415](https://gitee.com/halfcoke/blog_img/raw/master/20210908233045.png)

  然后执行

  ```bash
  myapp.exe install
  myapp.exe start
  # 如果想删除则是
  myapp.exe stop
  myapp.exe uninstall
  ```

  至此，Windows上服务部署完成。

### Linux

在Linux上部署服务通常是frp服务端，下面以部署服务端为例说明，客户端同理。

`frp`工具非常贴心的已经带了服务的配置文件（位于`frp`的`systemd`文件夹下），我们仅需要做一些修改就好。

```
[Unit]
Description=Frp Server Service
After=network.target

[Service]
Type=simple
User=nobody
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/frps -c /etc/frp/frps.ini

[Install]
WantedBy=multi-user.target
```

将其中的`ExecStart`的内容按照实际放置的位置填写就好。

`User`根据实际情况写，也可以不写。

我的配置信息如下：

```
[Unit]
Description=Frp server daemon

[Service]
WorkingDirectory=/opt/frp_0.37.0_linux_amd64
ExecStart=/opt/frp_0.37.0_linux_amd64/frps -c /opt/frp_0.37.0_linux_amd64/frps.ini
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
```

然后将文件命名为`frps.service`，扩展名为service即可。

然后将文件copy至`/etc/systemd/system/`中。

运行如下命令启动服务

```bash
# 启动服务
systemctl start frps
# 开机启动
systemctl enable frps
# 取消开机启动
systemctl disable frps
# 停止服务
systemctl stop frps
```

## 参考资料

- [frp中文官网](https://gofrp.org/)
- [WinSW](https://github.com/winsw/winsw)

好了~剩下的功能大家可以自行探索，别干什么触碰高压线的事就行哈~
