---
title: Docker学习笔记-基本
subtitle: 'Docker学习笔记，Dockerfile,compose,swarm的基本内容'
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/img/docker.png'
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
tags:
  - Docker
  - 学习笔记
categories:
  - 学习笔记
  - Docker
abbrlink: 42d8e328
date: 2020-11-10 13:10:43
update: 2020-11-10 13:10:43
---
# Docker学习笔记

![](https://gitee.com/halfcoke/blog_img/raw/master/img/1158417-20190119105601346-1695190871.png)

## 基本概念

镜像(image)：docker镜像就是一个模板，可以通过这个镜像来创建容器服务。

容器(container)：把容器理解为简易的linux，独立的运行一个或一组应用，通过镜像来创建

仓库：存放镜像的位置，分为公有和私有

## 安装Docker

### 环境准备

Linux环境

```bash
[root@centos7vm ~]# uname -r
3.10.0-1062.el7.x86_64

[root@centos7vm ~]# cat /etc/os-release
NAME="CentOS Linux"
VERSION="7 (Core)"
ID="centos"
ID_LIKE="rhel fedora"
VERSION_ID="7"
PRETTY_NAME="CentOS Linux 7 (Core)"
ANSI_COLOR="0;31"
CPE_NAME="cpe:/o:centos:centos:7"
HOME_URL="https://www.centos.org/"
BUG_REPORT_URL="https://bugs.centos.org/"

CENTOS_MANTISBT_PROJECT="CentOS-7"
CENTOS_MANTISBT_PROJECT_VERSION="7"
REDHAT_SUPPORT_PRODUCT="centos"
REDHAT_SUPPORT_PRODUCT_VERSION="7"
```

### 安装

[官网帮助文档](https://docs.docker.com/engine/install/centos/)

```bash
# 1. 卸载旧版本
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine
# 2. 需要的安装包
sudo yum install -y yum-utils
# 3. 设置镜像仓库
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo # 默认是国外的
sudo yum-config-manager \
	--add-repo \
	https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo  
	# 这里用阿里云的
	
# 4. 安装docker相关的包  docker-ce 社区  ee企业版	
sudo yum install -y docker-ce docker-ce-cli containerd.io
# 5. 启动docker
sudo systemctl start docker
# 6. 使用docker version测试是否成功    
[root@centos7vm ~]# docker version
Client: Docker Engine - Community
 Version:           19.03.13
 API version:       1.40
 Go version:        go1.13.15
 Git commit:        4484c46d9d
 Built:             Wed Sep 16 17:03:45 2020
 OS/Arch:           linux/amd64
 Experimental:      false

Server: Docker Engine - Community
 Engine:
  Version:          19.03.13
  API version:      1.40 (minimum version 1.12)
  Go version:       go1.13.15
  Git commit:       4484c46d9d
  Built:            Wed Sep 16 17:02:21 2020
  OS/Arch:          linux/amd64
  Experimental:     false
 containerd:
  Version:          1.3.7
  GitCommit:        8fba4e9a7d01810a393d5d25a3621dc101981175
 runc:
  Version:          1.0.0-rc10
  GitCommit:        dc9208a3303feef5b3839f4323d9beb36df0a9dd
 docker-init:
  Version:          0.18.0
  GitCommit:        fec3683    
# 7. 使用Hello world测试是否安装成功
docker run hello-world
```

![image-20201107230858385](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201107230858385.png)

```bash
# 8. 查看下载的helloworld镜像
[root@centos7vm ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-world         latest              bf756fb1ae65        10 months ago       13.3kB
```

## 阿里云镜像加速

```bash
sudo mkdir -p /etc/docker
sudo tee /etc/docker/daemon.json <<-'EOF'
{
  "registry-mirrors": ["https://l5e8i15v.mirror.aliyuncs.com"]
}
EOF
sudo systemctl daemon-reload
sudo systemctl restart docker
```

## 底层原理

**Docker是怎么工作的？**

Docker是一个Client-server结构的系统，Docker守护进程运行在主机上，通过Socket从客户端访问。

DockerServer接收到Docker-client的指令，就会执行这个命令。

**Docker为什么比VM快？**

1. Docker比虚拟机更少的抽象层
2. Docker利用的是宿主机的内核，vm需要的是Guest os

![image-20201107232451728](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201107232451728.png)

所以，新建一个容器的时候，Docker不需要像虚拟机一样重新加载一个操作系统，避免引导。虚拟机是加载Guest os，分钟级别，而Docker是利用宿主机的操作系统 ，省略这个过程，秒级。

## Docker常用命令

----

### 帮助命令

```bash
docker version		# 版本信息
docker info			# 显示Docker系统信息，包括镜像和容器的数量
docker 命令 --help    # 帮助命令
```

[官方帮助文档](https://docs.docker.com/reference/)

### 镜像命令

---

**docker images 查看所有本地的主机上的镜像**

````bash
[root@centos7vm docker]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
hello-world         latest              bf756fb1ae65        10 months ago       13.3kB

# 解释
REPOSITORY	镜像的仓库源
TAG			镜像的标签
IMAGE ID	镜像的ID
CREATED		镜像的创建时间
SIZE		镜像的大小
# 可选项
-a, --all		# 列出所有镜像
-q, --quiet		# 只显示镜像id
````

**docker search 搜索镜像**

```bash
[root@centos7vm docker]# docker search mysql
NAME                              DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
mysql                             MySQL is a widely used, open-source relation…   10134               [OK]

# 可选项，通过收藏来过滤
--filter=stars=3000 #搜索3000以上的
```

**docker pull 下载镜像**

```bash
[root@centos7vm docker]# docker pull mysql
Using default tag: latest # 不写tag 默认是latest
latest: Pulling from library/mysql
bb79b6b2107f: Pull complete # 分层下载，联合文件系统
49e22f6fb9f7: Pull complete
842b1255668c: Pull complete
9f48d1f43000: Pull complete
c693f0615bce: Pull complete
8a621b9dbed2: Pull complete
0807d32aef13: Pull complete
a56aca0feb17: Pull complete
de9d45fd0f07: Pull complete
1d68a49161cc: Pull complete
d16d318b774e: Pull complete
49e112c55976: Pull complete
Digest: sha256:8c17271df53ee3b843d6e16d46cff13f22c9c04d6982eb15a9a47bd5c9ac7e2d # 签名
Status: Downloaded newer image for mysql:latest
docker.io/library/mysql:latest #真实地址


docker pull mysql
docker pull docker.io/library/mysql:latest  # 这两个命令等价

# 指定版本下载
docker pull mysql:5.7
```

**docker rmi 删除镜像**

```bash
[root@centos7vm docker]# docker rmi -f db2b37ec6181 # 删除指定镜像
[root@centos7vm docker]# docker rmi -f 镜像id 镜像id 镜像id  # 删除多个镜像
[root@centos7vm docker]# docker rmi -f $(docker images -aq)  # 删除全部镜像
```

### 容器命令

---

*说明：我们有了镜像才能创建容器，下载一个centos测试学习*

```bash
docker pull centos
```

**新建容器并启动**

```bash
docker run [可选参数] image
# 参数说明
--name="Name"  	容器名字，用来区分容器
-d				后台方式运行
-it				使用交互方式运行，进入容器查看内容
-p				指定容器端口  -p 8080:8080
	-p ip:主机端口:端口
	-p 主机端口:容器  (常用)
	-p 容器端口
	容器端口
-P				随机指定端口
# 测试 启动并进入容器
[root@centos7vm docker]# docker run -it centos /bin/bash
[root@02861391cd3a /]#

# 从容器退回主机
```

**退出容器**

```bash
exit # 停止容器并退出
ctrl + p + q  #退出容器不停止
```



**列出所有运行容器**

```bash
docker ps 命令
	# 列出当前正在运行的容器
-a  # 列出当前正在运行的+历史运行过的容器
-n=? #显示最近创建的容器
-q # 只显示容器的不编号

[root@centos7vm docker]# docker ps  
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
[root@centos7vm docker]# docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED              STATUS                      PORTS               NAMES
02861391cd3a        centos              "/bin/bash"         About a minute ago   Exited (0) 41 seconds ago                       brave_wright
67d2c31f379c        bf756fb1ae65        "/hello"            48 minutes ago       Exited (0) 48 minutes ago                       exciting_mirzakhani
```

**删除容器**

```bash
docker rm 容器id # 删除指定容器
docker rm -f $(docker ps -aq) #删除所有容器
docker ps -aq | xargs docker rm #删除所有容器
```

**启动和停止容器的操作**

```bash
docker start 容器id		#启动容器
docker restart  容器id	# 重启容器
docker stop  容器id 		# 停止容器
docker kill  容器id		# 强制停止容器
```

**后台启动容器**

```bash
docker run -d centos

# 问题 docker ps 发现容器停止了
# 常见的问题，docker容器后台运行，必须要有一个前台进程，docker发现没有对外提供服务的应用，就会停止
# nginx，容器启动后，发现自己没有提供服务，就会立刻停止，就是没有程序了
```

**查看日志**

```bash
docker logs
# 显示日志
docker logs -tf --tail 10 19d1483e6662
	-tf   # 显示日志
	--tail number  # 要显示日志的跳数
# 自己写一段脚本

```

**查看容器中进程信息**

```bash
# 命令 docker top 容器id
[root@centos7vm docker]#  docker top 19d1483e6662
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                21885               21867               0                   17:02               ?                   00:00:00            /bin/sh -c while true;do echo 123;sleep 1;done
root                22090               21885               0                   17:04               ?                   00:00:00            /usr/bin/coreutils --coreutils-prog-shebang=sleep /usr/bin/sleep 1
```

**查看镜像元数据**

```bash
[root@centos7vm docker]# docker inspect --help

Usage:  docker inspect [OPTIONS] NAME|ID [NAME|ID...]

Return low-level information on Docker objects

Options:
  -f, --format string   Format the output using the given Go template
  -s, --size            Display total file sizes if the type is container
      --type string     Return JSON for specified type
[root@centos7vm docker]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS               NAMES
19d1483e6662        centos              "/bin/sh -c 'while t…"   4 minutes ago       Up 4 minutes                            confident_murdock
[root@centos7vm docker]# docker inspect 19d1483e6662
[
    {
        "Id": "19d1483e66621a38c4e175b4c4615adb3427eaaa07a632f3fa5835ff264a639a",
        "Created": "2020-11-08T09:02:27.513000805Z",
        "Path": "/bin/sh",
        "Args": [
            "-c",
            "while true;do echo 123;sleep 1;done"
        ],
        "State": {
            "Status": "running",
            "Running": true,
            "Paused": false,
            "Restarting": false,
            "OOMKilled": false,
            "Dead": false,
            "Pid": 21885,
            "ExitCode": 0,
            "Error": "",
            "StartedAt": "2020-11-08T09:02:28.217868188Z",
            "FinishedAt": "0001-01-01T00:00:00Z"
        },
        "Image": "sha256:0d120b6ccaa8c5e149176798b3501d4dd1885f961922497cd0abef155c869566",
        "ResolvConfPath": "/var/lib/docker/containers/19d1483e66621a38c4e175b4c4615adb3427eaaa07a632f3fa5835ff264a639a/resolv.conf",
        "HostnamePath": "/var/lib/docker/containers/19d1483e66621a38c4e175b4c4615adb3427eaaa07a632f3fa5835ff264a639a/hostname",
        "HostsPath": "/var/lib/docker/containers/19d1483e66621a38c4e175b4c4615adb3427eaaa07a632f3fa5835ff264a639a/hosts",
        "LogPath": "/var/lib/docker/containers/19d1483e66621a38c4e175b4c4615adb3427eaaa07a632f3fa5835ff264a639a/19d1483e66621a38c4e175b4c4615adb3427eaaa07a632f3fa5835ff264a639a-json.log",
        "Name": "/confident_murdock",
        "RestartCount": 0,
        "Driver": "overlay2",
        "Platform": "linux",
        "MountLabel": "",
        "ProcessLabel": "",
        "AppArmorProfile": "",
        "ExecIDs": null,
        "HostConfig": {
            "Binds": null,
            "ContainerIDFile": "",
            "LogConfig": {
                "Type": "json-file",
                "Config": {}
            },
            "NetworkMode": "default",
            "PortBindings": {},
            "RestartPolicy": {
                "Name": "no",
                "MaximumRetryCount": 0
            },
            "AutoRemove": false,
            "VolumeDriver": "",
            "VolumesFrom": null,
            "CapAdd": null,
            "CapDrop": null,
            "Capabilities": null,
            "Dns": [],
            "DnsOptions": [],
            "DnsSearch": [],
            "ExtraHosts": null,
            "GroupAdd": null,
            "IpcMode": "private",
            "Cgroup": "",
            "Links": null,
            "OomScoreAdj": 0,
            "PidMode": "",
            "Privileged": false,
            "PublishAllPorts": false,
            "ReadonlyRootfs": false,
            "SecurityOpt": null,
            "UTSMode": "",
            "UsernsMode": "",
            "ShmSize": 67108864,
            "Runtime": "runc",
            "ConsoleSize": [
                0,
                0
            ],
            "Isolation": "",
            "CpuShares": 0,
            "Memory": 0,
            "NanoCpus": 0,
            "CgroupParent": "",
            "BlkioWeight": 0,
            "BlkioWeightDevice": [],
            "BlkioDeviceReadBps": null,
            "BlkioDeviceWriteBps": null,
            "BlkioDeviceReadIOps": null,
            "BlkioDeviceWriteIOps": null,
            "CpuPeriod": 0,
            "CpuQuota": 0,
            "CpuRealtimePeriod": 0,
            "CpuRealtimeRuntime": 0,
            "CpusetCpus": "",
            "CpusetMems": "",
            "Devices": [],
            "DeviceCgroupRules": null,
            "DeviceRequests": null,
            "KernelMemory": 0,
            "KernelMemoryTCP": 0,
            "MemoryReservation": 0,
            "MemorySwap": 0,
            "MemorySwappiness": null,
            "OomKillDisable": false,
            "PidsLimit": null,
            "Ulimits": null,
            "CpuCount": 0,
            "CpuPercent": 0,
            "IOMaximumIOps": 0,
            "IOMaximumBandwidth": 0,
            "MaskedPaths": [
                "/proc/asound",
                "/proc/acpi",
                "/proc/kcore",
                "/proc/keys",
                "/proc/latency_stats",
                "/proc/timer_list",
                "/proc/timer_stats",
                "/proc/sched_debug",
                "/proc/scsi",
                "/sys/firmware"
            ],
            "ReadonlyPaths": [
                "/proc/bus",
                "/proc/fs",
                "/proc/irq",
                "/proc/sys",
                "/proc/sysrq-trigger"
            ]
        },
        "GraphDriver": {
            "Data": {
                "LowerDir": "/var/lib/docker/overlay2/86b18b8dd45c45fd5ed8e6d2ed808c689e9061e61c6526c055637d349d4f98dc-init/diff:/var/lib/docker/overlay2/b61e299d2bb31a1fb57bbdf890f6d559b1a92394e98c4b2463c1e0c34ed37341/diff",
                "MergedDir": "/var/lib/docker/overlay2/86b18b8dd45c45fd5ed8e6d2ed808c689e9061e61c6526c055637d349d4f98dc/merged",
                "UpperDir": "/var/lib/docker/overlay2/86b18b8dd45c45fd5ed8e6d2ed808c689e9061e61c6526c055637d349d4f98dc/diff",
                "WorkDir": "/var/lib/docker/overlay2/86b18b8dd45c45fd5ed8e6d2ed808c689e9061e61c6526c055637d349d4f98dc/work"
            },
            "Name": "overlay2"
        },
        "Mounts": [],
        "Config": {
            "Hostname": "19d1483e6662",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
            ],
            "Cmd": [
                "/bin/sh",
                "-c",
                "while true;do echo 123;sleep 1;done"
            ],
            "Image": "centos",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "org.label-schema.build-date": "20200809",
                "org.label-schema.license": "GPLv2",
                "org.label-schema.name": "CentOS Base Image",
                "org.label-schema.schema-version": "1.0",
                "org.label-schema.vendor": "CentOS"
            }
        },
        "NetworkSettings": {
            "Bridge": "",
            "SandboxID": "06d26833c3845620a37f361cda733999dba841c8f80bd14691d7a6275e2f0430",
            "HairpinMode": false,
            "LinkLocalIPv6Address": "",
            "LinkLocalIPv6PrefixLen": 0,
            "Ports": {},
            "SandboxKey": "/var/run/docker/netns/06d26833c384",
            "SecondaryIPAddresses": null,
            "SecondaryIPv6Addresses": null,
            "EndpointID": "990d153ba0bf1db91808560d3f87069dda4a2d98f8d614bf50dcde4e9e95d9a2",
            "Gateway": "172.17.0.1",
            "GlobalIPv6Address": "",
            "GlobalIPv6PrefixLen": 0,
            "IPAddress": "172.17.0.2",
            "IPPrefixLen": 16,
            "IPv6Gateway": "",
            "MacAddress": "02:42:ac:11:00:02",
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "NetworkID": "8c37dffaecb4dec076d5745cb032f23a991ec67976c1e2ae78e837d60075d48c",
                    "EndpointID": "990d153ba0bf1db91808560d3f87069dda4a2d98f8d614bf50dcde4e9e95d9a2",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "MacAddress": "02:42:ac:11:00:02",
                    "DriverOpts": null
                }
            }
        }
    }
]
```

**进入当前运行的容器**

```bash
# 容器通常都是后台运行，需要进入容器修改一些配置

# 命令
# 方式一
docker exec -it 容器id bashshell
[root@centos7vm docker]# docker exec -it 19d1483e6662 /bin/bash
[root@19d1483e6662 /]# ls
bin  dev  etc  home  lib  lib64  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
[root@19d1483e6662 /]# ps -ef
UID         PID   PPID  C STIME TTY          TIME CMD
root          1      0  0 09:02 ?        00:00:00 /bin/sh -c while true;do echo 123;sleep 1;done
root        448      0  0 09:09 pts/0    00:00:00 /bin/bash
root        465      1  0 09:09 ?        00:00:00 /usr/bin/coreutils --coreutils-prog-shebang=sleep /usr/bin/sleep 1
root        466    448  3 09:09 pts/0    00:00:00 ps -ef

# 方式二
# 测试
docker attach -it 19d1483e6662
正在执行的代码....

# 区别
# docker exec  # 进入容器后开启一个新的终端，可以在里面操作
# docker attach	# 进入容器正在执行的终端，不会启动新的进程
```

**从容器内拷贝文件到主机上**

```bash
docker cp 容器ID:容器内路径   目的主机路径

# 进入容器内部
[root@centos7vm ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
df42673d50f2        centos              "/bin/bash"         28 seconds ago      Up 25 seconds                           magical_jones
[root@centos7vm ~]# docker attach df42673d50f2
# 新建一个文件测试，将文件copy出来
[root@df42673d50f2 /]# touch test.java
[root@centos7vm ~]# docker cp df42673d50f2:/test.java ./

# copy是一个手动过程，未来使用卷的技术来对路径做映射
```

## 练习

### 安装Nginx

---

![image-20201108173050520](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108173050520.png)

```bash
# 1. 搜索镜像   建议在Docker Hub上搜索  能够看到详细信息
[root@centos7vm ~]# docker search -f stars=1000 nginx
NAME                  DESCRIPTION                                     STARS               OFFICIAL            AUTOMATED
nginx                 Official build of Nginx.                        13977               [OK]                
jwilder/nginx-proxy   Automated Nginx reverse proxy for docker con…   1906                                    [OK]
# 2. 下载镜像
[root@centos7vm ~]# docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
bb79b6b2107f: Pull complete 
5a9f1c0027a7: Pull complete 
b5c20b2b484f: Pull complete 
166a2418f7e8: Pull complete 
1966ea362d23: Pull complete 
Digest: sha256:aeade65e99e5d5e7ce162833636f692354c227ff438556e5f3ed0335b7cc2f1b
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest
# 3. 启动容器
-d	# 后台运行
--name # 为容器起名字
-p 	# 暴露端口   宿主机端口：容器内部端口
[root@centos7vm ~]# docker run -d --name nginx01 -p 3344:80 nginx
cb3b7175c1b43ee40bd2f398ed24854eb1a487ee305cec13735603ed5ab8c8e6
[root@centos7vm ~]# docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                  NAMES
cb3b7175c1b4        nginx               "/docker-entrypoint.…"   6 seconds ago       Up 4 seconds        0.0.0.0:3344->80/tcp   nginx01
# 4. 进入容器
docker exec nginx01 /bin/bash
```

### 安装tomcat

---

```bash
# 官方的使用
$ docker run -it --rm tomcat:9.0

# 我们之前的启动都是后台，停止了容器后，容器还是可以查到  docker run -it --rm， 一般用来测试，用完即删

# 下载再启动
[root@centos7vm ~]# docker run -d -p 3355:8080 --name tomcat01 tomcat
# 测试访问没有问题

# 进入容器
[root@centos7vm ~]# docker exec -it tomcat01 /bin/bash
# linux命令少、没有webapps   默认是最小的镜像，不必要的都剔除
# 保证最小可运行的环境
```

### 部署es+kibana

---

```bash
# es占内存多
# es暴露端口多
# es的数据一般需要放置到安全目录 挂载
# --net somenetwork 网络配置
$ docker run -d --name elasticsearch --net somenetwork -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch:tag

# 启动elasticsearch
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" elasticsearch


# docker stats查看CPU状态
docker stats
# 增加内存的限制  -e参数进行环境修改
docker run -d --name elasticsearch -p 9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e ES_JAVA_OPTS="-Xms64m -Xmx512m" elasticsearch
# 查看状态
```

![image-20201108180804691](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108180804691.png)

```bash
[root@centos7vm ~]# curl localhost:9211
{
  "name" : "UrvHV2Q",
  "cluster_name" : "elasticsearch",
  "cluster_uuid" : "NHWT8qNERMe9UhNZSUSGpw",
  "version" : {
    "number" : "5.6.12",
    "build_hash" : "cfe3d9f",
    "build_date" : "2018-09-10T20:12:43.732Z",
    "build_snapshot" : false,
    "lucene_version" : "6.6.1"
  },
  "tagline" : "You Know, for Search"
}
```

## 可视化

- portainer
- Rancher(CI/CD再用)

什么是portainer？

Docker图形化界面管理工具，提供一个后台面板

```bash
[root@centos7vm ~]# docker run -d -p 8088:9000 --restart=always -v /var/run/docker.sock:/var/run/docker.sock --privileged=true portainer/portainer-ce
```

## commit 镜像

```shell
docker commit 提交容器成为一个新的副本
# 命令和git类似
docker commit -m="提交的描述信息" -a="作者" 容器ID  目标镜像名：[TAG]

```

**练习**

```shell
# 启动一个默认的tomcat
# 默认的tomcat没有webapps应用，
# 自己将webapps.dist内容拷贝进去
# 通过commit提交了一个新的镜像
docker commit -a="halfcoke" -m="add webapps app" 容器ID tomcat01:1.1

[root@centos7vm ~]# docker commit -a="halfcoke" -m="add webapps app" d59f955ed1ac tomcat_test:1.0
sha256:8119e221b3f258d762ca461759af00417f2ea2e3d6eccf0b7dee850c5cb7ee53
[root@centos7vm ~]# docker images
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
tomcat_test              1.0                 8119e221b3f2        7 seconds ago       653MB
tomcat                   9.0                 dab3cf97dd54        39 hours ago        648MB
tomcat                   latest              dab3cf97dd54        39 hours ago        648MB
```

## 容器数据卷

### 什么是数据卷

![image-20201108195121399](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108195121399.png)

容器内的目录映射到外部目录，为了容器的持久化和同步操作，容器间数据能够共享

### 使用数据卷

**方式一**：使用命令挂载 -v

```shell
docker run -it -v 主机目录：容器内目录 -p 主机端口：容器端口
 
docker run -it -v /root/test:/home centos /bin/bash

# 通过inspect 查看容器信息
docker inspect 容器id
```

![image-20201108195708778](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108195708778.png)

其中source是主机内的地址，Destination是容器内的地址

```shell
# 测试
```

![image-20201108200240055](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108200240055.png)

之后修改直接在本地修改

**练习** **安装mysql**

```bash
# 下载镜像
[root@centos7vm ~]# docker pull mysql:5.7

# 官方测试
docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag
# 运行容器，需要数据挂载
-d 后台运行
-e 环境配置
--name 名字
-v 卷挂载
-p 端口映射
[root@centos7vm ~]# docker run -d -p 3310:3306 -v /root/mysql/conf:/etc/mysql/conf.d -v /root/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123 --name mysql01 mysql:5.7
# 启动成功后，链接测试
# 容器删除后，数据也不会丢失
```

### 具名挂载和匿名挂载

```bash
# 匿名挂载
-v 容器内路径
-P 随机指定端口
docker run -d -P --name nginx01 -v /etc/nginx nginx

# 查看当前挂载的卷
docker volume --help
[root@centos7vm ~]# docker volume --help

Usage:	docker volume COMMAND

Manage volumes

Commands:
  create      Create a volume
  inspect     Display detailed information on one or more volumes
  ls          List volumes
  prune       Remove all unused local volumes
  rm          Remove one or more volumes

Run 'docker volume COMMAND --help' for more information on a command.
# 查看所有的卷的情况
# 这里发现volume name都是加密后的，没有指定容器外的路径，就是匿名挂载
[root@centos7vm ~]# docker volume ls
DRIVER              VOLUME NAME
local               4ec45c6cdf92869673d25a42192fb0fe4d272e90343a4ca55650364e4ffda7fc
local               5b4a7949963490b29a916aec8dbac7e552bbf915fb3863da2902475d2c9483c2
local               5dfa3b399cff8cc630c709e738ace5feacd91085f0e2aad61f7cc7353abf3fa1
local               d5cdb69a6cc404ebb990956c8c8132e589010d1176e3a0a4bf3624992f74c236
local               f258608b52225ead6f764860b476f188cd1794e1533e667953fb6b98855b09ee
local               fece1a11094a2f65d572ea20c0e2561efc4a738a9a84667f5f6d5d9d0bf9a6a8
# 可以直接以  名字:容器内路径 的方式指定数据卷挂载，这就是具名挂载
# docker -v 卷名：容器内路径
[root@centos7vm ~]# docker run -d -P --name nginx02 -v juming:/etc/nginx nginx
7dba2abd87dfd70ea89c957b03dd797a3b9a8ae9597ed478dc22155c4676eb05
[root@centos7vm ~]# docker volume ls
DRIVER              VOLUME NAME
local               4ec45c6cdf92869673d25a42192fb0fe4d272e90343a4ca55650364e4ffda7fc
local               5b4a7949963490b29a916aec8dbac7e552bbf915fb3863da2902475d2c9483c2
local               5dfa3b399cff8cc630c709e738ace5feacd91085f0e2aad61f7cc7353abf3fa1
local               d5cdb69a6cc404ebb990956c8c8132e589010d1176e3a0a4bf3624992f74c236
local               f258608b52225ead6f764860b476f188cd1794e1533e667953fb6b98855b09ee
local               fece1a11094a2f65d572ea20c0e2561efc4a738a9a84667f5f6d5d9d0bf9a6a8
local               juming

# 通过docker volume inspect 来查看卷名的具体位置
# 在没有指定目录的情况下，都是在/var/lib/docker/volumes/xxxx/_data
# 我们通过具名挂载可以方便的找一个卷，大多数情况都是具名挂载
[root@centos7vm ~]# docker volume inspect juming
[
    {
        "CreatedAt": "2020-11-08T20:25:02+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/juming/_data",
        "Name": "juming",
        "Options": null,
        "Scope": "local"
    }
]
-v 容器内路径  # 匿名挂载
-v 卷名：容器内路径 # 具名挂载
-v /宿主机路径：容器路径  # 指定路径挂载
```

拓展

```shell
# 通过 -v 容器内路径  ro rw 改变读写权限

# 一旦设置了容器权限，容器对我们挂载出来的内容就有限定了
[root@centos7vm ~]# docker run -d -P --name nginx02 -v juming:/etc/nginx:ro nginx
[root@centos7vm ~]# docker run -d -P --name nginx02 -v juming:/etc/nginx:rw nginx

# ro只能从外部改变，只能从宿主机修改
# rw则可读可写
```

### 初识DockerFile

**方式二：使用DockerFile挂载**

通过dokerFile这个脚本可以生成镜像，每个命令都是一层

```bash
# vim dockerfile01内容
FROM centos

VOLUME ["volume01","volume02"]

CMD echo "----------end------------"
CMD /bin/bash
# 使用如下命令生成镜像
-f 指定从那个文件生成
-t 镜像名
. 位置
[root@centos7vm docker-test-volume]# docker build -f dockerfile1 -t test_os/centos:1.0 .
Sending build context to Docker daemon  2.048kB
Step 1/4 : FROM centos
 ---> 0d120b6ccaa8
Step 2/4 : VOLUME ["volume01","volume02"]
 ---> Running in 6e98aba39de7
Removing intermediate container 6e98aba39de7
 ---> e2b73d377118
Step 3/4 : CMD echo "----------end------------"
 ---> Running in b36b63a3e0e8
Removing intermediate container b36b63a3e0e8
 ---> f5f1b57f30fa
Step 4/4 : CMD /bin/bash
 ---> Running in f5ac620b0aac
Removing intermediate container f5ac620b0aac
 ---> 22cd294f67ad
Successfully built 22cd294f67ad
Successfully tagged test_os/centos:1.0
# 执行自己的镜像
[root@centos7vm docker-test-volume]# docker run -it 22cd294f67ad /bin/bash
[root@08b42c895f34 /]# ls
bin  dev  etc  home  lib  lib64  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var  volume01	volume02
# 最后面两个文件夹就是自动挂载的数据卷目录

```

最后两个卷一定与外部有同步的。

没有写名字，这是匿名挂载

![image-20201108210619365](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108210619365.png)

查看容器属性，确定是匿名挂载

![image-20201108210750028](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108210750028.png)

这种使用方式非常多，如果构建镜像的时候没有挂载，就要手动挂载 -v 卷名:容器内路径。



### 数据卷容器

两个mysql之间同步数据

![image-20201108211127849](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108211127849.png)

```bash
# 启动容器，通过自己写的镜像启动
```

![image-20201108211313942](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108211313942.png)

```bash
# 再新建一个容器，从docker01中继承数据卷
[root@centos7vm ~]# docker run -it --name docker02 --volumes-from docker01 test_os/centos:1.0
同一个目录数据可以同步

这里面docker01就叫做数据卷容器
```

多个mysql数据共享

```bash
[root@centos7vm ~]# docker run -d -p 3310:3306 --volumes-from mysql01 -e MYSQL_ROOT_PASSWORD=123 --name mysql01 mysql:5.7
```



## DockerFile

---

### 基本知识

DockerFile是用来构建Docker镜像的文件，是一种命令参数脚本

构建步骤：

1. 编写一个dockerfile文件
2. docker build构建成为一个镜像
3. docker run 运行镜像
4. docker push 发布镜像(Docker Hub、阿里云镜像仓库)

### dockerfile构建过程

**基础知识：**

1. 保留关键字(指令)都必须是大写字母
2. 指令顺序执行
3. \# 表示注释
4. 每一个指令都是一个镜像层

DockerFile是面向开发的，以后发布项目，做镜像，就需要编写dockerfile文件。

DockerFile： 构建文件，定义了一切步骤，源代码

DockerImages：通过DockerFile构建生成的镜像，最终发布和运行的产品

Docker容器：容器就是镜像运行起来提供服务的

**DockerFile命令**

```bash
FROM 		# 基础镜像，一切从这里开始构建
MAINTAINER	# 镜像是谁写的，姓名+邮箱
RUN			# 镜像构建的时候需要运行的命令
ADD			# 步骤：tomcat镜像，这个tomcat压缩包，添加内容
WORKDIR		# 镜像的工作目录   进入镜像时的目录
VOLUME		# 挂载的目录位置
EXPOSE		# 暴露端口配置
CMD			# 指定容器启动的时候要运行的命令，CMD只有最后一个会生效，而且可被替代
ENTRYPOINT   # 容器启动的时候要运行的命令，可以追加命令  
# CMD 与ENTRYPOINT 区别，比如说   ls -l   如果是使用CMD 写ls -a  则执行docker run 会替换掉ls -l   如果是ENTRYPOINT则会变成 ls -a  ls -l 下面详细介绍
ONBUILD 	# 当构建一个被继承DockerFile的时候，就会歘ONBUILD执行，触发指令
COPY 		#  类似ADD,将我们的问价拷贝到镜像中
ENV 		# 构建的时候，设置的环境变量    
```

这里放的图片比较多，更全面的写展示各种命令

![image-20201108213930017](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108213930017.png)

![image-20201108213418167](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108213418167.png)

![image-20201108213512266](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108213512266.png)

![image-20201108213536145](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108213536145.png)

### 实战测试

Docker Hub中绝大多数镜像都是从基础镜像过来的FROM scratch，然后配置需要的软件和环境

![image-20201108214918038](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201108214918038.png)

```bash
# 创建自己的centos
# 1. 编写dockerfile文件
[root@centos7vm dockerfile]# cat mycentos.dockerfile 
FROM centos
MAINTAINER halfcoke<halfcoke@163.com>

ENV MYPATH /usr/local
WORKDIR $MYPATH

RUN yum -y install vim
RUN yum -y install net-tools

EXPOSE 80

CMD echo $MYPATH
CMD ECHO "------END-----"
CMD /bin/bash
# 2. 通过文件构建镜像
docker build -f mycentos.dockerfile -t mycentos:0.1 .
# 3. 测试运行一下
```

### CMD 和 ENTRYPOINT区别

CMD 只有最后一个CMD会生效

#### 测试cmd

```bash
# dockerfile文件内容
FROM centos
CMD ["ls","-a"]
# 构建镜像
docker build -f file -t cmdtest .
# 运行结果
[root@centos7vm dockerfile]# docker run cmdtest
.
..
.dockerenv
bin
dev
etc
home
lib
lib64
lost+found
.........
# 想追加一个命令 -l
[root@centos7vm dockerfile]# docker run cmdtest -l
docker: Error response from daemon: OCI runtime create failed: container_linux.go:349: starting container process caused "exec: \"-l\": executable file not found in $PATH": unknown.
ERRO[0000] error waiting for container: context canceled 

```

#### 测试entrypoint

```bash
# dockerfile文件内容
FROM centos
ENTRYPOINT ["ls","-a"]
# 构建镜像
docker build -f file -t cmdtest .
# 运行结果

[root@centos7vm dockerfile]# docker run entrytest
.
..
.dockerenv
bin
dev
etc
home
lib
lib64
lost+found
media
...............
# 想追加一个命令 -l
[root@centos7vm dockerfile]# docker run entrytest -l
total 0
drwxr-xr-x   1 root root   6 Nov  8 14:08 .
drwxr-xr-x   1 root root   6 Nov  8 14:08 ..
-rwxr-xr-x   1 root root   0 Nov  8 14:08 .dockerenv
lrwxrwxrwx   1 root root   7 May 11  2019 bin -> usr/bin
drwxr-xr-x   5 root root 340 Nov  8 14:08 dev
drwxr-xr-x   1 root root  66 Nov  8 14:08 etc
drwxr-xr-x   2 root root   6 May 11  2019 home
lrwxrwxrwx   1 root root   7 May 11  2019 lib -> usr/lib
lrwxrwxrwx   1 root root   9 May 11  2019 lib64 -> usr/lib64
drwx------   2 root root   6 Aug  9 21:40 lost+found
drwxr-xr-x   2 root root   6 May 11  2019 media
drwxr-xr-x   2 root root   6 May 11  2019 mnt
drwxr-xr-x   2 root root   6 May 11  2019 opt
dr-xr-xr-x 301 root root   0 Nov  8 14:08 proc
dr-xr-x---   2 root root 162 Aug  9 21:40 root
drwxr-xr-x  11 root root 163 Aug  9 21:40 run
lrwxrwxrwx   1 root root   8 May 11  2019 sbin -> usr/sbin
drwxr-xr-x   2 root root   6 May 11  2019 srv
dr-xr-xr-x  13 root root   0 Nov  8 13:12 sys
drwxrwxrwt   7 root root 145 Aug  9 21:40 tmp
drwxr-xr-x  12 root root 144 Aug  9 21:40 usr
drwxr-xr-x  20 root root 262 Aug  9 21:40 var

```

### 练习：TomCat镜像

1. 准备压缩文件

   ![image-20201109103657554](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109103657554.png)

2. 编写Dockerfile文件 官方命名`Dockerfile`，build就会自动寻找这个文件，不需要`-f`指定

   ```bash
   FROM centos
   MAINTAINER halcoke<halfcoke@163.com>
   
   COPY readme.txt /usr/local/readme.txt
   
   ADD jdk-8u271-linux-x64.tar.gz /usr/local/
   ADD apache-tomcat-9.0.39.tar.gz /usr/local/
   
   RUN yum -y install vim
   
   ENV MYPATH /usr/local
   WORKDIR $MYPATH
   
   ENV JAVA_HOME /usr/local/jdk1.8.0_271
   ENV CLASSPATH $JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar
   ENV CATALINA_HOME /usr/local/apache-tomcat-9.0.39
   ENV CATALINA_BASH /usr/local/apache-tomcat-9.0.39
   ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/lib:$CATALINA_HOME/bin
   
   EXPOSE 8080
   
   CMD /usr/local/apache-tomcat-9.0.39/bin/startup.sh && tail -F /usr/localapache-tomcat-9.0.39/bin/logs/catalina.out
   
   ```

3. 构建镜像

   ```bash
   docker build -t diytomcat .
   ```

   

4. 启动镜像

5. 访问测试

6. 发布项目

   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <web-app version="2.4" 
       xmlns="http://java.sun.com/xml/ns/j2ee" 
       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
       xsi:schemaLocation="http://java.sun.com/xml/ns/j2ee 
           http://java.sun.com/xml/ns/j2ee/web-app_2_4.xsd">
   </web-app>
   ```

   ```jsp
   <%@ page language="java" contentType="text/html; charset=UTF-8"
       pageEncoding="UTF-8"%>
   <!DOCTYPE html>
   <html>
   <head>
   <meta charset="utf-8">
   <title>菜鸟教程(runoob.com)</title>
   </head>
   <body>
   Hello World!<br/>
   <%
   out.println("你的 IP 地址 " + request.getRemoteAddr());
   %>
   </body>
   </html>
   ```

   ### 发布镜像

   **发布到阿里云**

   参考阿里云官方文档

   ### 小结

   ![image-20201109135918607](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109135918607.png)

## Docker网络

---

### 理解Docker0

docker生成的网卡

![image-20201109140804266](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109140804266.png)

```bash
# docker 是如何处理网络链接的

# 查看容器内部的ip地址  ip addr， 发现容器启动的时候会得到一个eth0@if97ip地址
[root@centos7vm ~]# docker run -d -P --name tomcat01 tomcat
Unable to find image 'tomcat:latest' locally
latest: Pulling from library/tomcat
e4c3d3e4f7b0: Pull complete 
101c41d0463b: Pull complete 
8275efcd805f: Pull complete 
751620502a7a: Pull complete 
a59da3a7d0e7: Pull complete 
9c0f1dffe039: Pull complete 
474314d81831: Pull complete 
90ee5d998c5c: Pull complete 
a79c7e2a85e1: Pull complete 
1e48dd1bb576: Pull complete 
Digest: sha256:ad82afe54f2aa67167e873162578a751aed3173e42250a9ed68f306aa4b83025
Status: Downloaded newer image for tomcat:latest
04c9ac8b93a7efd8c19b0932bcfe5803be94d059fb6f365dd47d2ee63e935fe8
[root@centos7vm ~]# docker exec -it 04c9a /bin/bash
root@04c9ac8b93a7:/usr/local/tomcat# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
96: eth0@if97: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
root@04c9ac8b93a7:/usr/local/tomcat# 

# linux能够ping通容器内部
```

### 原理

1. 每启动一个docker容器，docker就会给docker容器分配一个ip，我们只要安装了docker，就会有一个docker0

2. 启动一个容器后，会多出一对网卡，容器内一个，主机上一个

   ![image-20201109143414467](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109143414467.png)

我们先这个容器网卡，都是一对一对的

evth-pair就是一对虚拟设备接口，他们都是成对出现的，

evth-pair充当一个桥梁，链接各种虚拟网络设备

3. 两个容器之间也能够ping通 

```bash
# 使用tcpdump 抓包
root@60f31d3cc794:/usr/local/tomcat# tcpdump -i eth0
tcpdump: verbose output suppressed, use -v or -vv for full protocol decode listening on eth0, link-type EN10MB (Ethernet), capture size 262144 bytes
06:51:02.491361 ARP, Request who-has 172.17.0.3 tell 60f31d3cc794, length 28
06:51:02.491396 ARP, Reply 172.17.0.3 is-at 02:42:ac:11:00:03 (oui Unknown), length 28
06:51:02.491398 IP 60f31d3cc794 > 172.17.0.3: ICMP echo request, id 371, seq 1, length 64
06:51:02.491420 IP 172.17.0.3 > 60f31d3cc794: ICMP echo reply, id 371, seq 1, length 64
06:51:02.491718 IP 60f31d3cc794.47353 > 192.168.3.1.domain: 56068+ PTR? 3.0.17.172.in-addr.arpa. (41)
06:51:02.502944 IP 192.168.3.1.domain > 60f31d3cc794.47353: 56068 NXDomain* 0/1/0 (95)
06:51:02.503226 IP 60f31d3cc794.52337 > 192.168.3.1.domain: 16962+ PTR? 1.3.168.192.in-addr.arpa. (42)
06:51:02.504061 IP 192.168.3.1.domain > 60f31d3cc794.52337: 16962 NXDomain- 0/0/0 (42)
06:51:03.494530 IP 60f31d3cc794 > 172.17.0.3: ICMP echo request, id 371, seq 2, length 64
06:51:03.494575 IP 172.17.0.3 > 60f31d3cc794: ICMP echo reply, id 371, seq 2, length 64
06:51:07.501141 ARP, Request who-has 172.17.0.1 tell 60f31d3cc794, length 28
06:51:07.501159 ARP, Request who-has 60f31d3cc794 tell 172.17.0.3, length 28
06:51:07.501165 ARP, Reply 60f31d3cc794 is-at 02:42:ac:11:00:04 (oui Unknown), length 28
06:51:07.501246 ARP, Reply 172.17.0.1 is-at 02:42:65:8d:e1:2b (oui Unknown), length 28
06:51:07.501342 IP 60f31d3cc794.56205 > 192.168.3.1.domain: 41516+ PTR? 1.0.17.172.in-addr.arpa. (41)
06:51:07.507059 IP 192.168.3.1.domain > 60f31d3cc794.56205: 41516 NXDomain* 0/1/0 (95)
06:51:12.522774 ARP, Request who-has 60f31d3cc794 tell 172.17.0.1, length 28
06:51:12.522783 ARP, Reply 60f31d3cc794 is-at 02:42:ac:11:00:04 (oui Unknown), length 28

```

evth-pair有点类似于一个虚拟交换机，为每个虚拟设备建立一对端口，虚拟设备上一个，宿主机上一个，相当于用网线链接起来。[参考链接](https://www.cnblogs.com/bakari/p/10613710.html)

### --link

容器之间不通过ip可以互相ping通

```bash
# 直接ping无法ping通
[root@centos7vm ~]# docker exec tomcat01 ping tomcat02
ping: tomcat02: Name or service not known
# 如何解决？
# 通过--link的方式可以连接
[root@centos7vm ~]# docker run -d -P --name tomcat03 --link tomcat02 tomcat
adde4bc5e9fb8e398bbaba77f889819d623df12190f42a4c9eaa93e910ad2bf4
[root@centos7vm ~]# docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                     NAMES
adde4bc5e9fb        tomcat              "catalina.sh run"   4 seconds ago       Up 3 seconds        0.0.0.0:32781->8080/tcp   tomcat03
f7fa8f2e44a8        tomcat              "catalina.sh run"   5 hours ago         Up 5 hours          0.0.0.0:32778->8080/tcp   tomcat02
04c9ac8b93a7        tomcat              "catalina.sh run"   5 hours ago         Up 5 hours          0.0.0.0:32777->8080/tcp   tomcat01
[root@centos7vm ~]# docker exec -it tomcat03 ping tomcat02
PING tomcat02 (172.17.0.3) 56(84) bytes of data.
64 bytes from tomcat02 (172.17.0.3): icmp_seq=1 ttl=64 time=0.251 ms
64 bytes from tomcat02 (172.17.0.3): icmp_seq=2 ttl=64 time=0.080 ms
64 bytes from tomcat02 (172.17.0.3): icmp_seq=3 ttl=64 time=0.097 ms
^C
--- tomcat02 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 6ms
rtt min/avg/max/mdev = 0.080/0.142/0.251/0.078 ms
# 反向无法连通
[root@centos7vm ~]# docker exec -it tomcat02 ping tomcat03
ping: tomcat03: Name or service not known
# --link 是在host文件中进行了配置
[root@centos7vm ~]# docker exec tomcat03 cat /etc/hosts
127.0.0.1	localhost
::1	localhost ip6-localhost ip6-loopback
fe00::0	ip6-localnet
ff00::0	ip6-mcastprefix
ff02::1	ip6-allnodes
ff02::2	ip6-allrouters
172.17.0.3	tomcat02 f7fa8f2e44a8
172.17.0.4	adde4bc5e9fb

```

**现在不建议使用--link**

docker0问题，不支持容器名链接访问



### 自定义网络

```bash
# 查看所有的网络模式
[root@centos7vm ~]# docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
8c37dffaecb4        bridge              bridge              local
35c2a571afd2        host                host                local
b9de4a74c582        none                null                local

```

**网络模式**

bridge： 桥接

none：不配置网络

host：和宿主机共享网络

container：容器内网络连通

**测试**

```bash
# 是默认增加了--net bridge， 这个就是docker0
[root@centos7vm ~]# docker run -d -P --name tomcat01  tomcat 
[root@centos7vm ~]# docker run -d -P --name tomcat01 --net bridge tomcat 
# docker0特点，默认，域名不能访问

# 自定义网络
# --driver bridge
# --subnet 192.168.0.0/16
# --gateway 192.168.0.1
[root@centos7vm ~]# docker network create --driver bridge --subnet 192.168.0.0/16 --gateway 192.168.0.1 mynet
8df9a7ad718555216a856cf0c5fa4cf02788f4c840a2d832453a4ab3d3ef3ef6
[root@centos7vm ~]# docker network ls
NETWORK ID          NAME                DRIVER              SCOPE
8c37dffaecb4        bridge              bridge              local
35c2a571afd2        host                host                local
8df9a7ad7185        mynet               bridge              local
b9de4a74c582        none                null                local

```

![image-20201109192308737](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109192308737.png)

```bash
# 添加两个容器
[root@centos7vm ~]# docker run -d -P --name tomcat01 --net mynet tomcat
54c6db4b62e6ea50dbbffb7559a08f93ff62d3944e10ffa6a32dbec56dc70a22
[root@centos7vm ~]# docker run -d -P --name tomcat02 --net mynet tomcat
80b3e7d6343eca724f0c99c43dfeb0df985163dea8b207046bf375b724a25f6e
[root@centos7vm ~]# docker network inspect mynet
[
    {
        "Name": "mynet",
        "Id": "8df9a7ad718555216a856cf0c5fa4cf02788f4c840a2d832453a4ab3d3ef3ef6",
        "Created": "2020-11-09T19:21:57.212203173+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.0/16",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "54c6db4b62e6ea50dbbffb7559a08f93ff62d3944e10ffa6a32dbec56dc70a22": {
                "Name": "tomcat01",
                "EndpointID": "967a2066e520708347d6b4f7ce52d3eb0d6284684808a6f7222f96f5461dc424",
                "MacAddress": "02:42:c0:a8:00:02",
                "IPv4Address": "192.168.0.2/16",
                "IPv6Address": ""
            },
            "80b3e7d6343eca724f0c99c43dfeb0df985163dea8b207046bf375b724a25f6e": {
                "Name": "tomcat02",
                "EndpointID": "758970ddbc8affa25a1de8a36ce9e013863dc1769694081713affd587cfdf81e",
                "MacAddress": "02:42:c0:a8:00:03",
                "IPv4Address": "192.168.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
# 现在不需要使用--link，也能ping名字了
[root@centos7vm ~]# docker exec tomcat01 ping 192.168.0.3
PING 192.168.0.3 (192.168.0.3) 56(84) bytes of data.
64 bytes from 192.168.0.3: icmp_seq=1 ttl=64 time=0.067 ms
64 bytes from 192.168.0.3: icmp_seq=2 ttl=64 time=0.055 ms
^C
[root@centos7vm ~]# docker exec tomcat01 ping tomcat02
PING tomcat02 (192.168.0.3) 56(84) bytes of data.
64 bytes from tomcat02.mynet (192.168.0.3): icmp_seq=1 ttl=64 time=0.039 ms
64 bytes from tomcat02.mynet (192.168.0.3): icmp_seq=2 ttl=64 time=0.073 ms

```

我们自定义网络都已经帮我们维护好了对应的关系，推荐使用。



好处：

不同集群使用不同网络，这样能保证网络健康





### 网络连通

![image-20201109192920354](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109192920354.png)

![image-20201109192945986](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201109192945986.png)

**测试打通**

```bash
[root@centos7vm ~]# docker network connect mynet tomcat03
[root@centos7vm ~]# docker network inspect mynet
[
    {
        "Name": "mynet",
        "Id": "8df9a7ad718555216a856cf0c5fa4cf02788f4c840a2d832453a4ab3d3ef3ef6",
        "Created": "2020-11-09T19:21:57.212203173+08:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": {},
            "Config": [
                {
                    "Subnet": "192.168.0.0/16",
                    "Gateway": "192.168.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": false,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "4fb292c8352c281860cb89dd8be171bdc4872f5bca008dc3924256fc6ac7a32a": {
                "Name": "tomcat03",
                "EndpointID": "bcc695da7144029eb0fc674249d3286fb8cc2bba863ef5e1c1197f579e9e6d76",
                "MacAddress": "02:42:c0:a8:00:04",
                "IPv4Address": "192.168.0.4/16",
                "IPv6Address": ""
            },
            "54c6db4b62e6ea50dbbffb7559a08f93ff62d3944e10ffa6a32dbec56dc70a22": {
                "Name": "tomcat01",
                "EndpointID": "967a2066e520708347d6b4f7ce52d3eb0d6284684808a6f7222f96f5461dc424",
                "MacAddress": "02:42:c0:a8:00:02",
                "IPv4Address": "192.168.0.2/16",
                "IPv6Address": ""
            },
            "80b3e7d6343eca724f0c99c43dfeb0df985163dea8b207046bf375b724a25f6e": {
                "Name": "tomcat02",
                "EndpointID": "758970ddbc8affa25a1de8a36ce9e013863dc1769694081713affd587cfdf81e",
                "MacAddress": "02:42:c0:a8:00:03",
                "IPv4Address": "192.168.0.3/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {}
    }
]
[root@centos7vm ~]# docker exec tomcat03 ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
111: eth0@if112: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:ac:11:00:02 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.17.0.2/16 brd 172.17.255.255 scope global eth0
       valid_lft forever preferred_lft forever
113: eth1@if114: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default 
    link/ether 02:42:c0:a8:00:04 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.0.4/16 brd 192.168.255.255 scope global eth1
       valid_lft forever preferred_lft forever
[root@centos7vm ~]# docker exec tomcat03 ping tomcat01
PING tomcat01 (192.168.0.2) 56(84) bytes of data.
64 bytes from tomcat01.mynet (192.168.0.2): icmp_seq=1 ttl=64 time=0.108 ms
64 bytes from tomcat01.mynet (192.168.0.2): icmp_seq=2 ttl=64 time=0.048 ms
^C
[root@centos7vm ~]# docker exec tomcat03 ping tomcat02
PING tomcat02 (192.168.0.3) 56(84) bytes of data.
64 bytes from tomcat02.mynet (192.168.0.3): icmp_seq=1 ttl=64 time=0.057 ms
64 bytes from tomcat02.mynet (192.168.0.3): icmp_seq=2 ttl=64 time=0.063 ms

```

结论，假设跨网络操作，就需要这么操作。

## Redis集群

```bash
# 创建redis配置文件
#!/bin/bash

for port in $(seq 1 6);
do
mkdir -p /mydata/redis/node-${port}/conf
touch /mydata/redis/node-${port}/conf/redis.conf
cat << EOF > /mydata/redis/node-${port}/conf/redis.conf
port 6379
bind 0.0.0.0
cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip 172.38.0.1${port}
cluster-announce-port 6379
cluster-announce-bus-port 16379
appendonly yes
EOF
done
# 运行容器

#!/bin/bash

for n in $(seq 1 6);
do
docker run -p 637${n}:6379 -p 1637${n}:16379 --name redis-${n} \
-v /mydata/redis/node-${n}/data:/data \
-v /mydata/redis/node-${n}/conf/redis.conf:/etc/redis/redis.conf \
-d --net redis --ip 172.38.0.1${n} redis:5.0.9-alpine3.11 redis-server /etc/redis/redis.conf
done

# 创建集群
/data # redis-cli --cluster create 172.38.0.11:6379 172.38.0.12:6379 172.38.0.13:6379 172.38.0.14:6379 172.38.0.15:6379 172.38.0.16:6379 --cluster-replicas 1

```

## Docker Compose

### 介绍

定义运行多个容器

YAML file配置文件

single command 命令？

### 使用compose三个步骤

> 官方说明：
>
> Using Compose is basically a three-step process:
>
> 1. Define your app’s environment with a `Dockerfile` so it can be reproduced anywhere.
> 2. Define the services that make up your app in `docker-compose.yml` so they can be run together in an isolated environment.
> 3. Run `docker-compose up` and Compose starts and runs your entire app.

`dockerfile` 保证我们的项目在任何地方都可以运行

docker-compose.yaml怎么写

使用docker-compose up命令启动compose

### 其他介绍

compose 是docker官方的开源项目，需要安装。

`docker-compose.yml`文件格式：

```yaml
version: "3.8"
services:
  web:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - .:/code
      - logvolume01:/var/log
    links:
      - redis
  redis:
    image: redis
volumes:
  logvolume01: {}
```

Compose：重要的概念

- 服务service：容器，应用
- 项目project。一组关联的容器。

### 安装

[官方链接](https://docs.docker.com/compose/install/#install-compose-on-linux-systems)

```bash
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

### 练习

[官方链接](https://docs.docker.com/compose/gettingstarted/)

### yaml规则

`docker-compose.yml`核心

```yaml
# 3层
version: '' # 版本  根据docker版本来
services: # 服务
  服务1: web
    # 服务配置
    build: .
    images: ....
  服务2: redis
  ....
# 其他配置  网络/卷/全局规则
volumes:
networks:
configs:
```



## Docker Swarm

### 创建Swarm集群

```bash
# docker swarm init 初始化一个集群
[root@docker-0 ~]# docker swarm init
Swarm initialized: current node (0onzn4z1ljxw7delulxewvnvk) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-3vk8ohuxr68hy9o6udjzfi5q8dmasvapcu500tzvs22vpijnny-7qt31z6lamb831ym9qjd23s3y 192.168.3.20:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
# 使用下面命令可以生成加入集群的命令
docker swarm join-token manager
docker swarm join-token worker
```

### 创建服务

````bash
[root@docker-0 ~]# docker service --help

Usage:	docker service COMMAND

Manage services

Commands:
  create      Create a new service
  inspect     Display detailed information on one or more services
  logs        Fetch the logs of a service or task
  ls          List services
  ps          List the tasks of one or more services
  rm          Remove one or more services
  rollback    Revert changes to a service's configuration
  scale       Scale one or multiple replicated services
  update      Update a service

Run 'docker service COMMAND --help' for more information on a command.

````

### 概念总结

#### swarm

集群的管理和编号，docker可以初始化一个集群，其他节点可以加入

#### Node

就是一个docker节点，多个节点就组成了一个网络集群(管理者，工作者)

#### Service

任务，可以在管理节点或工作节点来运行，

#### Task

