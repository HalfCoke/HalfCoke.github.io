---
title: GoLang远程开发配置
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: GoLang远程开发配置
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310132941.png'
tags:
  - Go语言
  - 远程开发
categories:
  - 学习笔记
  - Go语言
abbrlink: e1ea5816
date: 2021-03-06 10:13:10
update: 2021-03-06 10:13:10
---

# GoLang远程开发配置

**本文介绍如何配置GoLang如何在服务器上进行调试开发**

附上官网说明:

[https://www.jetbrains.com/help/go/attach-to-running-go-processes-with-debugger.html#step-2-run-delve-on-the-host-machine](https://www.jetbrains.com/help/go/attach-to-running-go-processes-with-debugger.html#step-2-run-delve-on-the-host-machine)

远程环境与本地环境版本最好相同，避免玄学错误

## 远程环境

远程使用Ubuntu18

Go语言linux版下载链接：[go1.16.linux-amd64.tar.gz](https://golang.org/dl/go1.16.linux-amd64.tar.gz)

```bash
# 使用命令解压压缩包
tar -C ./env/go -zxf go1.16.linux-amd64.tar.gz
# 配置环境变量
vim ~/.bashrc
# 在最下面加上这几行
# >>> go env >>>
export GOPATH=~/.go
export GOROOT=~/env/go
export GOBIN=$GOROOT/bin
export PATH=$GOBIN:$PATH
# <<< go env <<<
# 使环境变量生效
source ~/.bashrc
# 执行命令
go version
# 输出：go version go1.16 linux/amd64

# 安装远程调试工具  
# github：https://github.com/go-delve/delve
# 执行以下命令：
go install github.com/go-delve/delve/cmd/dlv@latest
# 安装完成后，执行以下命令验证：
dlv version

Delve Debugger
Version: 1.6.0
Build: $Id: 8cc9751909843dd55a46e8ea2a561544f70db34d $

# 至此远程环境配置完成
```



## 本地环境

本地使用GoLand进行开发

在本地新建`Hello.go`文件

```go
package main

import "fmt"

func main() {
	fmt.Println("run")
	fmt.Println("debug")
	fmt.Println("finish")
}

```

**然后创建Go.mod文件**

！！！很重要，不然无法断点调试

![image-20210306120910761](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310132304.png)

在GoLand配置`Deployment`，将本地文件同步到服务器上，如何配置Deployment参考网络上其他教程，讲这部分内容的很多，主要步骤如下截图：

![image-20210306103624938](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310132358.png)

![image-20210306103717312](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310132513.png)

点击这里

![image-20210306103925994](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310133594.png)

新建一个Go Remote配置

![image-20210306103951739](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310133462.png)

根据自己的情况设置IP和端口

![image-20210306104039977](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310133240.png)

在**远程环境**的终端上进入刚刚的项目路径（比如我的是`/tmp/go_practice/2021-03-06`），然后选择执行如下命令

```
在 main.go目录下执行 
dlv debug --headless --listen=:2345 --api-version=2
```

然后回到Goland点击调试即可

![image-20210306121101391](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310133618.png)

直接在GoLand中进行远程调试就很方便了。

![image-20210306121931106](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310133606.png)