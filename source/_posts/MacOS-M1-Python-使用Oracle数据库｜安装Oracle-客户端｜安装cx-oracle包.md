---
title: MacOS M1 Python 使用Oracle数据库｜安装Oracle 客户端｜安装cx_oracle包
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
tags:
  - 环境部署
  - mac
  - 工具
categories:
  - 环境部署
  - mac
abbrlink: 88b111d7
date: 2022-09-10 10:58:49
update: 2021-05-02 18:48:31
---

## 安装rosetta2（可选）

这是一个将x86程序翻译至m1的软件

直接安装即可

```bash
/usr/sbin/softwareupdate --install-rosetta
```

## 安装x86_64 brew（可选）

> 为了安装其他x86架构的软件方便，此次不安装也可以

### ARM版brew安装

- 访问官网：https://brew.sh/index_zh-cn

- 使用命令安装即可

  ```shell
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```

### X86版本 brew

在命令前增加`arch -x86_64`

```shell
arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 多版本共存

在 `~/.zprofile`文件中添加如下内容

```bash
alias abrew='arch -arm64 /opt/homebrew/bin/brew'
alias ibrew='arch -x86_64 /usr/local/bin/brew'
```

其中，`abrew`和`ibrew`这两个名字可变，这样一个是运行arm版本，一个是运行x86版本

执行`source ~/.zprofile`在当前终端中生效

## 安装x86_64 Anaconda

多版本的anaconda共存**初步尝试**后会有问题，如果之前安装过arm版本的anaconda，如无特殊需求，最好卸载，直接安装x86版本。

**如果之前配置过复杂的python环境，谨慎操作**

### 安装

- 访问官网：https://www.anaconda.com/

- 下载x86版本的安装文件

  ```bash
  wget -o https://repo.anaconda.com/archive/Anaconda3-2022.05-MacOSX-x86_64.sh
  ```

- 直接安装，安装开始的时候会有提醒安装的是x86版本，直接确认即可

### 创建python环境

```bash
conda create -n py37_x86 python=3.7
```

arm版本能够安装的python版本最低是3.8

只要能创建3.7的环境就说明安装应该没问题

## 安装cx_oracle及oracle client

### 安装cx_oracle

- 激活python环境

  ```bash
  conda activate py37_x86
  ```

- 使用pip安装

  ```bash
  pip install cx_oracle
  ```

安装后无法直接使用，需要下载oracle官网上的一些安装包

### 安装oracle client

- 访问下载页：https://www.oracle.com/database/technologies/instant-client/macos-intel-x86-downloads.html

- 下载Basic Package (ZIP)、SQL*Plus Package (ZIP)、SDK Package (ZIP)三个包

- 将这三个包解压至相同路径，解压完成后就是这些文件

  <img src="https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20220910112749749.png" alt="image-20220910112749749" style="zoom: 33%;" />

- 配置环境变量，编辑`~/.zprofile`，根据实际情况修改自己的路径

  ```bash
  export PATH=/Users/halfcoke/oracle_client/instantclient_19_8:$PATH
  export ORACLE_HOME=/Users/halfcoke/oracle_client/instantclient_19_8
  export DYLD_LIBRARY_PATH=/Users/halfcoke/oracle_client/instantclient_19_8
  export OCI_LIB_DIR=/Users/halfcoke/oracle_client/instantclient_19_8
  export OCI_INC_DIR=/Users/halfcoke/oracle_client/instantclient_19_8/sdk/include
  ```

在这之后就可以在python中导入cx_oracle使用了，首次运行会弹出“macOS 无法验证此app”的问题

打开**系统偏好设置>安全性与隐私>通用**，这时候会有“仍然允许”的按钮，点击即可，应该会有多个，多点几次就可以了，下次运行不会再出现了。

图片是在网上找的图，应用名称可能会不一样，用作示意。

<img src="https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/watermark,type_ZmFuZ3poZW5naGVpdGk,shadow_10,text_aHR0cHM6Ly9ibG9nLmNzZG4ubmV0L21oc3N6bQ==,size_16,color_FFFFFF,t_70.jpeg" alt="img" style="zoom:33%;" />



## 参考资料

1. https://developers.ascendcorp.com/how-to-install-oracle-instant-client-on-apple-silicon-m1-24b67f2dc743
2. https://zhuanlan.zhihu.com/p/341831809
3. https://www.macjb.com/article/229012.html
