---
title: Linux Top 命令详解
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Top命令详细说明
tags:
  - Linux
  - 命令
categories:
  - Linux
  - 命令
abbrlink: '8649918'
date: 2020-12-23 13:53:45
update: 2020-12-23 13:53:45
cover: https://gitee.com/halfcoke/blog_img/raw/master/img/20201223140206.png
---

# Linux下Top命令详解

## 命令简介

**top命令** 可以实时动态地查看系统的整体运行情况，是一个综合了多方信息监测系统性能和运行信息的实用工具。通过top命令所提供的互动式界面，用热键可以管理。

## 命令选项

```bash
-b：以批处理模式操作；
-c：显示完整的治命令；
-d：屏幕刷新间隔时间；
-I：忽略失效过程；
-s：保密模式；
-S：累积模式；
-i<时间>：设置间隔时间；
-u<用户名>：指定用户名；
-p<进程号>：指定进程；
-n<次数>：循环显示的次数。
```

## 交互命令

```bash
h：显示帮助画面，给出一些简短的命令总结说明；
k：终止一个进程；
i：忽略闲置和僵死进程，这是一个开关式命令；
q：退出程序；
r：重新安排一个进程的优先级别；
S：切换到累计模式；
s：改变两次刷新之间的延迟时间（单位为s），如果有小数，就换算成ms。输入0值则系统将不断刷新，默认值是5s；
f或者F：从当前显示中添加或者删除项目；
o或者O：改变显示项目的顺序；
l：切换显示平均负载和启动时间信息；
m：切换显示内存信息；
t：切换显示进程和CPU状态信息；
c：切换显示命令名称和完整命令行；
M：根据驻留内存大小进行排序；
P：根据CPU使用百分比大小进行排序；
T：根据时间/累计时间进行排序；
w：将当前设置写入~/.toprc文件中。
I: 切换Irix模式和Solaris模式
```

## 显示结果介绍

![image-20201223140206196](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310133699.png)

```
top - 14:12:41 up 40 days,  8:58,  1 user,  load average: 0.01, 0.04, 0.05
Tasks: 150 total,   1 running, 149 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.2 us,  0.1 sy,  0.0 ni, 99.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem : 16265208 total, 13027888 free,  1907500 used,  1329820 buff/cache
KiB Swap:  2097148 total,  2097148 free,        0 used. 14028784 avail Mem

  PID 	USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
31413	lsy       20   0 7789400 810980  28092 S   1.7  5.0   0:38.60 java
14052	lsy       20   0 6060348 282744  22764 S   0.7  1.7  96:03.88 java
31983	root      20   0  162152   2288   1548 R   0.3  0.0   0:00.50 top
1		root      20   0  191284   4280   2596 S   0.0  0.0   0:15.67 systemd
2		root      20   0       0      0      0 S   0.0  0.0   0:00.60 kthreadd
4		root       0 -20       0      0      0 S   0.0  0.0   0:00.00 kworker/0:0H
5		root      20   0       0      0      0 S   0.0  0.0   0:10.16 kworker/u16:0
```

**第一行**

- `top - 14:09:28`：显示当前系统时间
- `up 40 days,  8:57`：系统已经运行了16天
- ` 1 user`：一个用户登录
- `load average: 0.04, 0.05, 0.05`：系统负载，即任务队列的平均长度，三个数值分别为截止目前1分钟，5分钟，15分钟内的平均值

**第二行**

- `Tasks: 150 total`：总进程数
- `1 running`：正在运行的进程数
- `149 sleeping`：睡眠进程数
- `0 stopped`：停止进程数
- `0 zombie`：冻结进程数

**第三行**

- `%Cpu(s):  0.2 us`：用户空间进程占用CPU时间的百分比

- `0.1 sy`：内核空间进程占用CPU时间的百分比

- `0.0 ni`：ni表示nice的意思，也就是哪些用户进程被提升优先级之后，占用的CPU运行时间

- `99.7 id`：系统空闲时间

- `0.0 wa`：等待输入输出的CPU百分比

- `0.0 hi`：CPU处理硬中断(hard interrupt）的时间百分比

- ` 0.0 si`：CPU处理软中断(soft interrupt）的时间百分比

- `0.0 st`：这个表示在有虚拟机的时候，被虚拟机占用的CPU时间。st表示窃取的意思，steal的意思。

  ***上面这些百分比相加的话，是等于100%的，按数字键 1 可以看到不同核心的负载***

**第四行**

- `KiB Mem : 16265208 total`：表示系统可用的物理内存总量
- `13027888 free`：表示当前空闲的内存总量
- `1907500 used`：表示当前已用的内存总量
- `1329820 buff/cache`：用作系统内核缓存的物理内存总量

**第五行**

- `KiB Swap:  2097148 total`：交换区总量
- `2097148 free`：交换区空闲
- `      0 used`：交换区使用
- `14028784 avail Mem`：avail number是在不进行交换的情况下，用于启动新应用程序的可用物理内存的估计。与free字段不同，它试图考虑容易回收的页面缓存和内存。它在内核3.14上可用，在内核2.6.27+上可模拟，否则就像free一样

**第七行以下**

- `PID`：进程id
- `USER`：进程所有者
- `PR`：进程优先级
- `NI`：nice值。负值表示高优先级，正值表示低优先级
- `VIRT`：进程使用的虚拟内存总量，单位kb。VIRT=SWAP+RES
- `RES`：进程使用的、未被换出的物理内存大小，单位kb。RES=CODE+DATA
- `SHR`：共享内存大小，单位kb
- `S`：进程状态。D=不可中断的睡眠状态 R=运行 S=睡眠 T=跟踪/停止 Z=僵尸进程
- `%CPU`：上次更新到现在的CPU时间占用百分比，对一个多线程程序，如果不是在线程模式下，这个数值是可能超过100%的。对于多处理器环境，如果`Irix`模式是关闭状态，top将在`Solaris`模式下工作，任务的CPU使用率将除以CPU数量，可以通过交互命令`I`来更改状态
- `%MEM`：进程使用的物理内存百分比
- `TIME+`：进程使用的CPU时间总计，单位1/100秒
- `COMMAND`：进程名称（命令名/命令行）

参考：

[1] https://wangchujiang.com/linux-command/c/top.html

[2] https://www.cnblogs.com/taobataoma/archive/2007/12/26/1015167.html