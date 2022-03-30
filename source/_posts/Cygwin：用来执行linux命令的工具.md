---
title: Cygwin：用来执行linux命令的工具
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Cygwin：用来执行linux命令的工具安装与配置
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310129661.png'
tags:
  - 系统工具
  - cygwin
categories:
  - 工具
  - 系统工具
  - cygwin
abbrlink: 8d1f253e
date: 2021-05-09 15:57:59
update: 2021-05-09 15:57:59
---

# Cygwin：在Windows上执行linux命令的工具

## 介绍

官网链接：[https://cygwin.com/index.html](https://cygwin.com/index.html)

维基百科：[https://zh.wikipedia.org/wiki/Cygwin](https://zh.wikipedia.org/wiki/Cygwin)

## 安装

直接[点击链接](https://cygwin.com/setup-x86_64.exe)下载64位版本的Cygwin，安装过程比较简单，一直下一步即可，建议保留此安装包，后续在Cygwin中安装软件还会需要。

## 安装软件

### 方法一

安装软件需要运行Cygwin安装包，一直点击下一步到如下页面。

![image-20210509160734409](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310108820.png)

比如要安装wget，则在搜索框中输入`wget`，view选择Full。然后选择软件版本，我这里已经安装过了，所以会有`keep`和`reinstall`选项。然后再一直点击下一步即可。

![image-20210509160832027](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310108541.png)

### 方法二

使用`apt-cyg`对软件进行安装，首先需要下载安装`apt-cyg`。在[链接]([https://github.com/transcode-open/apt-cyg](https://github.com/transcode-open/apt-cyg))中下载`apt-cyg`，然后copy到`C:\cygwin64\bin`目录下，这里`C:\cygwin64\`是我的cygwin的安装目录，根据情况进行修改。

这时启动cygwin终端已经可以使用`apt-cyg`命令了。

![image-20210509161847316](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310108268.png)

## 其他说明

### ssh

如果windows本身安装了ssh，需要卸掉原来的ssh客户端，避免与`cygwin`中的冲突，冲突的情况下会无法使用`rsync`命令

### Cygwin使用rsync报错解决

参考：https://zhuanlan.zhihu.com/p/110217604

删除windows的ssh即可