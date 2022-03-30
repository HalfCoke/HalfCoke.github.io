---
title: Linux如何在LVM中移除PV
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Linux如何在LVM中移除PV
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310134214.png'
tags:
  - Linux
  - LVM
categories:
  - Linux
  - LVM
abbrlink: 2d54e946
date: 2021-03-18 09:38:22
update: 2021-03-18 09:38:22
---

# Linux如何在LVM中移除PV

网上很多人都在讲如何直接移除PV，但是实际过程中，很有可能我们的PV还没有空闲空间，这样也就没办法直接用`pvmove`指令。

我们先介绍如何将pv空闲出来。

## 移除PV准备工作

通过`lsblk`命令我们可以看到，当前根目录的`LVM`是用了两个盘的，即`sda`和`sdb`。我们想将`sda`从`LVM`中拿出来，这样`sda`就可以用来做别的事情了。

![image-20210318100540412](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310134687.png)

使用`df -hT`查看当前分区的使用情况，我们可以看到根目录只用了72G，`/home`目录空闲有249G，这个时候我们可以将`/home`中的一部分空间拿出来，最好空闲直接大于72G，保证能装得下。如果小于72G的时候不确定能不能装得下，这部分需要自己试一下。

![image-20210318101352606](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310134104.png)

我们执行一下`lvdisplay`，查看一下lv的信息，下图列出了部分内容。

![image-20210318101759476](https://gitee.com/halfcoke/blog_img/raw/master/20210318101759.png)

这个时候我们执行`lvreduce -L 150G /dev/cl/home`命令，这条命令相当于将`/home`路径的空间直接缩小到150G，因为我们在上面通过`df -hT`看到了`/home`目录只用了144G。

这样我们相当于已经有空间用来存放根目录的数据了。

接下来我们执行移除PV的相关操作

## 移除PV

我们执行`pvs -o+pv_used`，只要`/dev/sda1`的`used`的是0就可以了。下面这个图忘记截了，放一个之前的数据的图。

![image-20210318103700432](https://gitee.com/halfcoke/blog_img/raw/master/20210318103700.png)

```bash
# 然后执行下面的命令，转移PV中的数据
pvmove /dev/sda1
# 然后从vg中移除pv
vgreduce {vg组名} /dev/sda1
即：vgreduce cl /dev/sda1
# 然后移除PV
pvremove /dev/sda1
```

至此，所有步骤完成。

## 参考链接

[1] [How to Remove Physical Volume from a Volume Group in LVM](https://www.2daygeek.com/linux-remove-delete-physical-volume-pv-from-volume-group-vg-in-lvm/)

[2] [LVM : 缩减文件系统的容量](https://www.cnblogs.com/sparkdev/p/10213655.html)

[3] [Linux如何使用LVM进行磁盘扩容](https://halfcoke.github.io/2020/189b3b4/)