---
title: Linux用户权限'/etc/sudoer'配置
subtitle: Linux下使用sudoer管理用户权限
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
tags:
  - Linux
  - 用户权限
categories:
  - Linux
typora-copy-images-to: upload
abbrlink: 4adf7b4
date: 2020-11-11 18:44:10
update: 2020-11-11 18:44:10
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/img/sudo-command-in-linux.jpg'
---

# 【转载】Linux /etc/sudoer 配置

> 原文链接：https://zhuanlan.zhihu.com/p/43934300

当普通用户向其他的用户获取它的权限的时候，其他用户怎么去判断是不是需要给这样的权限给这个普通用户。其中的权限分配体现在给予权限者的`/etc/sudoers`文件当中。

比如在文件中配置有这样一条信息。

![v2-aabac307640f3d2f50be74d9c6cc2497_r](https://gitee.com/halfcoke/blog_img/raw/master/img/v2-aabac307640f3d2f50be74d9c6cc2497_r.png)

- `zhang`：表示用户名
- `ALL=(ALL)`：第一个`ALL`表示所有的主机，第二个`ALL`表示所有的用户
- NOPASSWD：表示不需要密码就能切换到用户
- `/usr/bin/bash,/usr/bin/sh`：表示能够执行的命令

这个配置的意思就是，`zhang`用户可以在任意主机上不输入密码的情况下以任意用户执行`/usr/bin/bash,/usr/bin/sh`

![v2-df97d0ae89d65a68445075be4e4a7304_r](https://gitee.com/halfcoke/blog_img/raw/master/img/v2-df97d0ae89d65a68445075be4e4a7304_r.jpg)