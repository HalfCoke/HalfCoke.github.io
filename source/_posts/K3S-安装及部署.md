---
title: K3S 安装及部署
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20221021222858950.png'
date: 2022-10-21 22:22:19
update: 2022-10-21 22:22:19
tags:
  - 学习笔记
  - K3S
  - Linux
categories:
  - 学习笔记
  - K3S
---

# K3s

## 简介

> Lightweight Kubernetes. Easy to install, half the memory, all in a binary of less than 100 MB.

K3s是K8s轻量级的发行版，K3s完全兼容K8s，主要是为了边缘计算和物联网，所以K3s也支持ARM架构。

## 安装

### 前置条件

#### 通用

> If all your nodes have the same hostname, use the `--with-node-id` option to append a random suffix for each node, or otherwise devise a unique name to pass with `--node-name` or `$K3S_NODE_NAME` for each node you add to the cluster.

每个主机不能有相同的名字，如果有相同的名字可以使用`--with-node-id`参数来生成随机后缀，或者使用`--node-name`或变量`$K3S_NODE_NAME`指定节点名称。

#### 操作系统

对于Red Hat/Centos需要关闭firewalld

```
systemctl disable firewalld --now
```

其他系统的前置条件参考官网文档（https://docs.k3s.io/advanced#additional-os-preparations）

#### 网络

1. 所有节点需要能够访问K3s server的`6443`端口
2. 当使用Flannel VXLAN时，所有节点需要能够互相访问`8472/udp`；当使用Flannel Wireguard时，需要能够互相访问`51820/udp`和`51821/udp`（IPv6）
3. 如果使用metrics server 还需要在每个节点上开启`10250`端口
4. 如果要通过内建的etcd实现server的高可用，还需要开启`2379`和`2380`端口

> **Important:** The VXLAN port on nodes should not be exposed to the world as it opens up your cluster network to be accessed by anyone. Run your nodes behind a firewall/security group that disables access to port 8472. **Warning:** Flannel relies on the [Bridge CNI plugin](https://www.cni.dev/plugins/current/main/bridge/) to create a L2 network that switches traffic. Rogue pods with NET_RAW capabilities can abuse that L2 network to launch attacks such as [ARP spoofing](https://static.sched.com/hosted_files/kccncna19/72/ARP DNS spoof.pdf). Therefore, as documented in the [kubernetes docs](https://kubernetes.io/docs/concepts/security/pod-security-standards/), please set a restricted profile that disables NET_RAW on non-trustable pods.

注意事项：

 VXLAN port应仅能被各个节点访问，不能被外部访问

| Protocol | Port      | Source                     | Description                                           |
| -------- | --------- | -------------------------- | ----------------------------------------------------- |
| TCP      | 6443      | K3s agent nodes            | Kubernetes API Server                                 |
| UDP      | 8472      | K3s server and agent nodes | Required only for Flannel VXLAN                       |
| UDP      | 51820     | K3s server and agent nodes | Required only for Flannel Wireguard backend           |
| UDP      | 51821     | K3s server and agent nodes | Required only for Flannel Wireguard backend with IPv6 |
| TCP      | 10250     | K3s server and agent nodes | Kubelet metrics                                       |
| TCP      | 2379-2380 | K3s server nodes           | Required only for HA with embedded etcd               |

5. 可以通过`--cluster-cidr`指定子网范围，但是要注意pod数量，别耗光所有ip

### 离线环境准备

#### 搭建私有仓库(ubuntu20)

1. 在主节点上安装docker

   说明：直接使用k3s可以不用安装docker，但是建议在一个有网络的机器上安装docker 方便拉取镜像

   ```bash
   # 1. 添加密钥
   curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
   # 2. 添加仓库
   add-apt-repository \
   "deb [arch=amd64] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   # 3. 安装docker
   apt install docker-ce
   ```

2. 启动私有仓库

   ```bash
   docker run -d -p 5000:5000 --restart=always --name registry registry:2
   ```

3. 配置本地仓库http

   编辑`/etc/docker/daemon.json`

   根据实际ip进行修改

   ```json
   {"insecure-registries" : "192.168.6.1:5000"}
   ```

   然后重启docker

   ```bash
   systemctl restart docker
   ```

4. 下载K3s必要镜像

   下载链接：https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s-airgap-images-amd64.tar.gz

5. 下载ingress-nginx必要镜像（需要代理或者科学）

   ```bash
   docker pull nginx/nginx-ingress:2.4.1
   docker pull docker-registry.nginx.com/nap-dos/app_protect_dos_arb:1.1.0
   ```

   

6. 将镜像推送至私有仓库

   根据实际版本修改脚本中的版本号

   ```shell
   #!/bin/bash
   
   PRIVATE_REGISTRY="192.168.6.1:5000"
   docker load -i k3s-airgap-images-amd64.tar.gz
   
   BUSYBOX="1.34.1"
   HELM="v0.7.3-build20220613"
   TRAEFIK="2.6.2"
   COREDNS="1.9.1"
   KLIPPER_LB="v0.3.5"
   PROVISIONER="v0.0.21"
   METRICS="v0.5.2"
   PAUSE="3.6"
   
   INGRESS_NGINX_APP_PROTECT="1.1.0"
   INGRESS_NGINX_CONTROLLER="2.4.1"
   
   docker tag rancher/mirrored-library-busybox:$BUSYBOX $PRIVATE_REGISTRY/rancher/mirrored-library-busybox:$BUSYBOX            
   docker tag rancher/klipper-helm:$HELM $PRIVATE_REGISTRY/rancher/klipper-helm:$HELM
   docker tag rancher/mirrored-library-traefik:$TRAEFIK $PRIVATE_REGISTRY/rancher/mirrored-library-traefik:$TRAEFIK
   docker tag rancher/mirrored-coredns-coredns:$COREDNS $PRIVATE_REGISTRY/rancher/mirrored-coredns-coredns:$COREDNS  
   docker tag rancher/klipper-lb:$KLIPPER_LB $PRIVATE_REGISTRY/rancher/klipper-lb:$KLIPPER_LB
   docker tag rancher/local-path-provisioner:$PROVISIONER $PRIVATE_REGISTRY/rancher/local-path-provisioner:$PROVISIONER
   docker tag rancher/mirrored-metrics-server:$METRICS $PRIVATE_REGISTRY/rancher/mirrored-metrics-server:$METRICS
   docker tag rancher/mirrored-pause:$PAUSE $PRIVATE_REGISTRY/rancher/mirrored-pause:$PAUSE
   docker tag nginx/nginx-ingress:$INGRESS_NGINX_CONTROLLER $PRIVATE_REGISTRY/nginx/nginx-ingress:$INGRESS_NGINX_CONTROLLER
   docker tag docker-registry.nginx.com/nap-dos/app_protect_dos_arb:$INGRESS_NGINX_APP_PROTECT $PRIVATE_REGISTRY/nap-dos/app_protect_dos_arb:$INGRESS_NGINX_APP_PROTECT
   
   docker push $PRIVATE_REGISTRY/rancher/mirrored-library-busybox:$BUSYBOX 
   docker push $PRIVATE_REGISTRY/rancher/klipper-helm:$HELM
   docker push $PRIVATE_REGISTRY/rancher/mirrored-library-traefik:$TRAEFIK
   docker push $PRIVATE_REGISTRY/rancher/mirrored-coredns-coredns:$COREDNS
   docker push $PRIVATE_REGISTRY/rancher/klipper-lb:$KLIPPER_LB
   docker push $PRIVATE_REGISTRY/rancher/local-path-provisioner:$PROVISIONER
   docker push $PRIVATE_REGISTRY/rancher/mirrored-metrics-server:$METRICS
   docker push $PRIVATE_REGISTRY/rancher/mirrored-pause:$PAUSE
   docker push $PRIVATE_REGISTRY/nap-dos/app_protect_dos_arb:$INGRESS_NGINX_APP_PROTECT
   docker push $PRIVATE_REGISTRY/nginx/nginx-ingress:$INGRESS_NGINX_CONTROLLER
   ```

#### 配置k3s私有仓库

```bash
mkdir -p /etc/rancher/k3s/
cat > /etc/rancher/k3s/registries.yaml  << EOF
mirrors:
  docker.io:
    endpoint:
      - "http://10.111.7.106:5000"
  registry.k8s.io:
    endpoint:
      - "http://10.111.7.106:5000"
    rewrite:
      "^rancher/(.*)": "mirrorproject/rancher-images/$1"
EOF
```

#### 下载k3s安装文件及执行文件

下载链接：https://github.com/k3s-io/k3s/releases/download/v1.25.2%2Bk3s1/k3s

下载链接：https://get.k3s.io./

```bash
chmod +x k3s
chmod +x install.sh

cp k3s /usr/local/bin/
```

#### 准备离线安装ingress-nginx-controller

官方安装说明：https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/

将所需文件存储为`ingress-nginx.yml`

注意：ingress默认只能进行http(s)代理，为了进行tcp或udp代理，并且将服务端口暴露在宿主机桑，需要对官方文件进行一些调整

1. 

执行如下命令

```bash
kubectl apply -f ingress-nginx.yml
```



### 单Server

使用内建etcd安装，后续比较方便升级高可用

#### 服务端安装

```bash
INSTALL_K3S_SKIP_DOWNLOAD=true INSTALL_K3S_EXEC='server --cluster-init --disable traefik' K3S_TOKEN=FpqAiu2DZgSEyuHHoH83mFrm ./install.sh
```

#### 代理安装

```bash
INSTALL_K3S_SKIP_DOWNLOAD=true K3S_URL=https://10.111.7.106:6443 K3S_TOKEN=FpqAiu2DZgSEyuHHoH83mFrm ./install.sh
```

### 高可用





# 简单服务部署



