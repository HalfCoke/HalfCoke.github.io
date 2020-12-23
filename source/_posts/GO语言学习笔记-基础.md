---
title: GO语言学习笔记-基础
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Go语言学习笔记，Go语言基本内容
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/img/20201120135457.png'
tags:
  - 学习笔记
  - go语言
categories:
  - 学习笔记
  - Go语言
abbrlink: e5c841b2
date: 2020-11-20 13:53:56
update: 2020-11-20 13:53:56
---

# Go语言学习笔记-基础内容

## 基础概念

**通道**是一种允许某一例程向另一例程传递指定类型的值的通信机制。

当一个goroutine试图在一个通道上进行发送或接收操作时，它会阻塞，直到另一个goroutine试图进行接收或发送操作才传递值，并开始处理两个goroutine。

### 一些习惯

- Go语言使用**驼峰式**风格
- 包名称本身总是由小写字母组成。
- 通常名称的作用域越大，就使用越长且更有意义的名称。

### 生命周期问题

- 如果一个实体在函数中声明，那么它仅对函数局部有效。如果一个实体在函数外部声明，它将对==**包**==里所有源文件可见。
- 实体第一个字母的大小写决定其可见性是否跨包。

### 作用域与生命周期

声明的作用域是声明在程序文本中出现的区域，它是一个编译时属性。变量的生命周期是变量在程序执行期间能被程序的其他部分所引用的起止时间，它是一个运行时属性。



在包级别声明，可以被同一个包里的任何文件引用；导入的包是文件级别的，所以可以在同一个文件内引用；

内部的声明会覆盖外层的。

## 基础语句

### 循环语句

for是go里面唯一的循环语句，有以下形式

```go
// 1. 第一种，与其他语言的for循环类似
for initialization;condition;post{
    // 0个或多个语句
}
// 2. 第二种，其他语言的while语句
for condition{
    // 语句
}
// 3. 第三种，传统的无限循环
for {
    // 语句
}
// 4. 第四种，在字符串或slice数据上迭代
for _,_ := range os.Args[1:]{
    //语句
}
```

### new 函数

使用new函数创建变量，表达式`new(T)`创建一个未命名的T类型变量，初始化未T类型的零值，**并返回其地址**。



## 一些待解决的问题

### 1. URL响应问题

使用go做服务器时，**以`/`结尾的处理模式匹配所有含有这个前缀的URL**，比如下面这个例子，会触发两次处理。

```go
	http.HandleFunc("/", handler2)
	http.HandleFunc("/count",counter)
```

但有个问题，使用`http.Get`对url进行请求时，就不会触发`/`。服务器与客户端代码如下，访问结果在代码下方。

服务端代码：

```go
package main

import (
	"fmt"
	"log"
	"net/http"
	"sync"
)
var mu sync.Mutex
var count int
func main() {
	// 问题：这种方式处理，是否两个处理函数都会触发
	http.HandleFunc("/", handler2)
	http.HandleFunc("/count",counter)
	log.Fatal(http.ListenAndServe("localhost:8000",nil))
}
func handler2(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	count++
	fmt.Fprintf(w, "URL.Path = %q\n", r.URL.Path)
	fmt.Println("this is path '/'")
	mu.Unlock()
}
func counter(w http.ResponseWriter, r *http.Request){
	mu.Lock()
	fmt.Fprintf(w, "Count %d\n",count)
	fmt.Println("this is path 'count'")
	mu.Unlock()
}

```

客户端代码:

```go
package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {
	ch := make(chan string)
	for i := 0; i < 100; i++ {
		go getURL(ch)
	}
	for i := 0; i < 100; i++ {
		fmt.Println(<-ch)
	}

}
func getURL(ch chan<- string) {
	url := "http://localhost:8000/count"
	start := time.Now()
	resp, err := http.Get(url)
	if err != nil {
		fmt.Sprint(os.Stderr, err)
		return
	}
	reader := new(strings.Builder)
	io.Copy(reader, resp.Body)
	resp.Body.Close()
	secs := time.Since(start).Seconds()
	ch <- fmt.Sprintf("%.2fs %s", secs, reader.String())
}

```

![image-20201120172805036](https://gitee.com/halfcoke/blog_img/raw/master/img/20201120172805.png)

### 2. 算法原理

![image-20201127210210047](https://gitee.com/halfcoke/blog_img/raw/master/img/20201127210210.png)