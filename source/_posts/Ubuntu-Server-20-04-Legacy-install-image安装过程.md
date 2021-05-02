---
title: Ubuntu Server 20.04 Legacy install image安装过程
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Ubuntu Server 20.04 Legacy install image安装过程
abbrlink: '83723065'
date: 2021-03-18 14:19:24
update: 2021-03-18 14:19:24
cover: https://gitee.com/halfcoke/blog_img/raw/master/20210318142453.png
tags:
  - Linux
  - Ubuntu
categories:
  - Linux
  - 系统安装
---

# Ubuntu Server 20.04 Legacy install image安装过程

## 准备安装

使用Ubuntu官网主页的下载的镜像安装起来会出错，后来查询资料得知，可以使用传统安装镜像，具体原因没有深究，记录本次安装过程如下，包含了每一个步骤。

镜像下载网页：[http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/](http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/)

镜像下载地址：[http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/ubuntu-20.04.1-legacy-server-amd64.iso](http://cdimage.ubuntu.com/ubuntu-legacy-server/releases/20.04/release/ubuntu-20.04.1-legacy-server-amd64.iso)

## 安装过程

只做启动盘等工具的过程略

1. 从镜像启动安装程序，此处可以直接选中文，方向键切换，回车键确认。

   ![image-20210318142402884](https://gitee.com/halfcoke/blog_img/raw/master/20210318142402.png)

2. 安装 Ubuntu服务器版，可能会卡顿一下。

   ![image-20210318142453839](https://gitee.com/halfcoke/blog_img/raw/master/20210318142453.png)

3. 选择语言，直接yes就行。

   ![image-20210318142655508](https://gitee.com/halfcoke/blog_img/raw/master/20210318142655.png)

4. 检测键盘布局，选否，一会自己手动选。

   ![image-20210318142725215](https://gitee.com/halfcoke/blog_img/raw/master/20210318142725.png)

5. 选Englis(us)

   ![image-20210318142801389](https://gitee.com/halfcoke/blog_img/raw/master/20210318142801.png)

   ![image-20210318142819409](https://gitee.com/halfcoke/blog_img/raw/master/20210318142819.png)

6. 等一会

   ![image-20210318142952977](https://gitee.com/halfcoke/blog_img/raw/master/20210318142953.png)

7. 选择网络接口

   ![image-20210318143456635](https://gitee.com/halfcoke/blog_img/raw/master/20210318143456.png)

8. 配置静态ip

   ![image-20210318143851952](https://gitee.com/halfcoke/blog_img/raw/master/20210318143852.png)

   ![image-20210318143902464](https://gitee.com/halfcoke/blog_img/raw/master/20210318143902.png)

   接下来的一些信息根据个人情况填写，主要就是主机名、用户名、ip，网关等

9. 进行磁盘分区，这里选手动分区，因为咱们需要为/boot目录创建一个分区。

   ![image-20210318144237167](https://gitee.com/halfcoke/blog_img/raw/master/20210318144237.png)

10. 先把之前旧的信息清理掉，先选择配置逻辑卷管理器，如果有弹窗就选‘是’

    ![image-20210318144323051](https://gitee.com/halfcoke/blog_img/raw/master/20210318144323.png)

    

11. 删除原来的逻辑卷，有几个删除几个，可能会卡顿，等一会。

    ![](https://gitee.com/halfcoke/blog_img/raw/master/20210318144433.png)

12. 逻辑卷都删除完了以后要删除卷组，然后完成，返回。

    ![image-20210318144618435](https://gitee.com/halfcoke/blog_img/raw/master/20210318144618.png)

13. 接下来我们选中要安装系统的ssd，敲一下回车，写入空的分区表。

    ![image-20210318144718509](https://gitee.com/halfcoke/blog_img/raw/master/20210318144718.png)

    ![image-20210318144749522](https://gitee.com/halfcoke/blog_img/raw/master/20210318144749.png)

14. 创建分区，光标放在这一行

    ![image-20210318150852362](https://gitee.com/halfcoke/blog_img/raw/master/20210318150852.png)

    创建新分区

    ![image-20210318150924747](https://gitee.com/halfcoke/blog_img/raw/master/20210318150924.png)

    先建立一个1GB大小的分区，用来挂载`/boot`目录，选择`主分区`，分区的位置选`开始`。这里选择下图这样的配置，然后分区设定结束。

    ![image-20210318151106480](https://gitee.com/halfcoke/blog_img/raw/master/20210318151106.png)

15. 然后再配置逻辑卷，弹出的窗口还是选择是。

    ![image-20210318151249883](https://gitee.com/halfcoke/blog_img/raw/master/20210318151249.png)

    创建卷组，卷组名就`ubuntu`就可以

    ![image-20210318151310165](https://gitee.com/halfcoke/blog_img/raw/master/20210318151310.png)

    设备选择有`free`标记的那里，按空格选择，按回车确认，然后继续选择是

    ![image-20210318151343523](https://gitee.com/halfcoke/blog_img/raw/master/20210318151343.png)

    创建两个逻辑卷，一个命名为swap，空间为2GB，一个命名为root，剩余空间都给过去。配置详情如下，然后完成返回。

    ![image-20210318151742323](https://gitee.com/halfcoke/blog_img/raw/master/20210318151742.png)

16. 设置挂载路径和文件系统格式

    ![image-20210318151848705](https://gitee.com/halfcoke/blog_img/raw/master/20210318151848.png)

    其中root那个设置如下：

    ![image-20210318151923289](https://gitee.com/halfcoke/blog_img/raw/master/20210318151923.png)

    swap那个设置如下：

    ![image-20210318151952830](https://gitee.com/halfcoke/blog_img/raw/master/20210318151952.png)

    最终效果如下，然后选择`结束分区设定并将修改写入磁盘`，然后选`是`

    ![image-20210318152009023](https://gitee.com/halfcoke/blog_img/raw/master/20210318152009.png)

17. http代理不需要设置

    ![image-20210318153101142](https://gitee.com/halfcoke/blog_img/raw/master/20210318153101.png)

18. 不用自动安装更新

    ![image-20210318153214470](https://gitee.com/halfcoke/blog_img/raw/master/20210318153214.png)

19. 安装openssh服务

    ![image-20210318153238318](https://gitee.com/halfcoke/blog_img/raw/master/20210318153238.png)

20. 安装引导，注意选择设备

    ![image-20210318155100368](https://gitee.com/halfcoke/blog_img/raw/master/20210318155100.png)

    ![image-20210318155118729](https://gitee.com/halfcoke/blog_img/raw/master/20210318155118.png)

21. 安装完成后重启即可。

## 安装后配置

### 更改root密码

```bash
sudo passwd
```

### 静态ip

```bash
root@slave3:  vi /etc/netplan/01-*.yaml

```

**此处注意yaml文件格式**，`:`后要有空格，缩进至少两个空格，同级缩进保持一致。

```bash
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eno1:   # 网卡名称
      dhcp4: no     # 关闭dhcp
      dhcp6: no
      addresses: [10.254.13.19/24]  # 静态ip,根据实际情况配置
      gateway4: 10.254.13.254    # 网关
      nameservers:
        addresses: [223.5.5.5, 114.114.114.114]
```

```bash
root@slave3:  netplan apply
```

### ssh服务

```
root@slave3: vi /etc/ssh/sshd_config
```

修改端口，禁用root密码登录

```bash
# 重启sshd服务
root@slave3: systemctl restart sshd
```

**注意在当前用户和root用户执行一遍下面的命令**，一路敲回车即可

```bashr
root@slave3: ssh-keygen
user@slave3: ssh-keygen
```

