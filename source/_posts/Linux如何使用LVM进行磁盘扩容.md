---
title: Linux如何使用LVM进行磁盘扩容
subtitle: 在Linux下，使用LVM对现有磁盘进行扩容
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/img/1200px-LVM1.svg.png'
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
tags:
  - Linux
  - LVM
  - 磁盘扩容
categories:
  - Linux
typora-copy-images-to: upload
abbrlink: 189b3b4
date: 2020-11-06 18:29:50
update: 2020-11-06 18:29:50
---

# Linux如何使用LVM进行磁盘扩容

***提醒：操作磁盘的工作都需要小心谨慎，避免数据丢失损坏，下文涉及到分区表的操作请再三确认***

## 背景介绍

关于LVM的介绍请参考[维基百科](https://en.wikipedia.org/wiki/Logical_Volume_Manager_(Linux))或[百度百科](https://baike.baidu.com/item/LVM)。

本文不提供如何将现有的非LVM分区转换为LVM分区的方法，本文主要解决现有LVM如何进行扩容的问题。

## 磁盘状态查看

***注意：磁盘操作需要有管理员权限，请确认你有管理员权限再执行如下操作。***

我们可以使用这个命令来查看当前硬盘的详细信息，包括当前磁盘容量以及分区信息。

```bash
fdisk -l
```

命令执行结果与下图类似：

![image-20201106185215998](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106185215998.png)

可以看到我们这块磁盘有`268.4GB`大小的空间，但只有两个分区`vda1`和`vda2`。我们同样可以使用<span id="lsblk">`lsblk`</span>来查看当前分区状态。执行结果应该类似下图：

![image-20201106190400637](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106190400637.png)

通过这里我们看到，主要要解决的问题是，如何把我们这200多GB的空间都用上。

## 磁盘扩容

根据我们的硬盘名称，执行下面的命令进入磁盘分区管理。其中`/dev/vda`应该更换为你自己查询到的名字。

```bash
fdisk /dev/vda
```

命令执行后的状态应该类似下图：

![image-20201106190949198](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106190949198.png)

我们可以在这里输入`p`来查看当前硬盘的信息，结果如下：

![image-20201106191051650](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106191051650.png)

接下来执行我们的扩容过程。

### 新建一块分区

新建分区的过程如下图所示，输入`n`，然后输入`P`（最多四个分区）。接下来的`Partition number`、`First sector`及`Last sector`我这里选择的都是默认值，因为我要用到剩下全部的磁盘空间，你在设置的时候根据你自己的情况决定。

![image-20201106191356630](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106191356630.png)

再次输入`p`，我们可以看到新建的分区。

![image-20201106191912730](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106191912730.png)

### 修改分区类型

我们这里的分区类型有问题，需要修改分区类型为`8e`。

输入`t`，选择新建出来的分区号，我这里是`3`，然后输入`8e`，再输入`p`查看分区类型，我们可以看到新建的分区的类型已经更改过来了。

![image-20201106192200782](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106192200782.png)

### 写入分区表

输入`w`，将刚刚的更改写入。然后执行`partprobe`重读分区表。

![image-20201106192900952](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106192900952.png)

### 扩容VG 

输入`vgdisplay`查看当前VG信息。

输入下面的命令，其中`centos`是刚刚看到的`VG Name`，`/dev/vda3`是刚刚新建的分区

```bash
vgextend centos /dev/vda3
```

![image-20201106193352723](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106193352723.png)

### 扩容LV

输入`lvdisplay`来查看当前存在的LV信息，如下图所示。

![image-20201106194122215](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106194122215.png)

确定我们要扩容的分区，可以通过刚才执行的<a href="#lsblk">`lsblk`</a>命令查看，我们这里要扩容的`LV Path`是`/dev/centos/root`。

执行以下命令：

```bash
lvextend -l +100%FREE /dev/centos/root
xfs_growfs /dev/centos/root
```

这时候我们执行下面命令查看，就能看到已经成功扩容了。

```bash
df -h
```



![image-20201106201915719](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201106201915719.png)

---



欢迎扫码关注，不定期更新各种经验。

<img src="https://gitee.com/halfcoke/blog_img/raw/master/img/qrcode.jpg" style="zoom: 67%;" />