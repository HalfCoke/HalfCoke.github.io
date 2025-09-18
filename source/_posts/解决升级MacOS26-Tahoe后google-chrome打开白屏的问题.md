---
title: 解决升级MacOS26 Tahoe后google chrome打开白屏的问题
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
cover: >-
  https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/google-chrome-logo.jpg
tags:
  - mac
  - chrome
  - Tahoe
  - macOS
categories:
  - 工具
abbrlink: 73aadaa1
date: 2025-09-18 08:35:57
---



2025年9月18日，升级了MacOS26 Tahoe后，打开谷歌浏览器Chrome直接白屏，可以通过以下办法解决

## 1. 在终端中运行如下命令，打开Chrome

```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --disable-gpu
```

## 2. 打开设置页面

![image-20250918084401334](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20250918084401334.png)

## 3. 在系统设置位置，关闭图形加速功能，然后重启Chrome即可

![image-20250918084453204](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20250918084453204.png)
