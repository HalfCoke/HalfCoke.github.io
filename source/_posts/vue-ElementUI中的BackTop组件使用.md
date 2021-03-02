---
title: vue ElementUI中的BackTop组件使用
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: vue ElementUI中的BackTop组件使用
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/20210302131412.png'
tags:
  - Vue
  - ElementUI
  - 前端
categories:
  - WEB
  - 前端
abbrlink: e15cc6f
date: 2021-03-02 13:10:40
update: 2021-03-02 13:10:40
---

# vue ElementUI中的BackTop组件使用

[官方文档](https://element.eleme.cn/2.15/#/zh-CN/component/backtop)中关于BackTop组件的使用说明有坑，实际上该组件的使用非常简单，见如下代码，记得把代码放在最外层的div里的第一个，不要放在尾部。

```html
<template>
	<div id="app">
		<el-backtop :bottom="100">
			<div class="back_top">
				UP
			</div>
		</el-backtop>
		<router-view/>
	</div>
</template>
```



## 参考链接：

[1]https://www.cnblogs.com/xyann/p/12739515.html

