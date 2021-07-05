---
title: Flink StreamingFileSink源码分析
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Flink SteamingFileSink源码分析
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/img/20201223151557.png'
tags:
  - Flink
  - 流处理
  - 大数据
  - 源码
categories:
  - 大数据
  - 流处理
  - Flink
abbrlink: 6a92d281
date: 2021-07-04 03:27:40
update: 2021-07-04 03:27:40
---

# Flink StreamingFileSink源码分析

## 介绍

`org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink`

Flink中的`StreamingFileSink`是用来将流式数据写入文件系统的Sink。在`StreamingFileSink`中会将数据首先发送到bucket中，bucket与存储目录相关，然后与Checkpoint机制配合来达到精准一次的语义。

其中`BucketAssigner`用来定义如何将元素写入哪些目录中，默认的BucketAssigner实现是DataTimeBucketAssigner，每个小时会创建一个bucket。

在写入文件时，文件有三种状态：`in-progress`，`pending`，`finished`，这是为了提供对精准一次语义的保证，新来的数据会首先写入到`in-progress`文件中，当通过用户定义的RollingPolicy触发了文件的关闭条件时(比如文件大小)，会关闭in-progress文件，并向一个新的`in-progress`文件中继续写数据。直到收到Checkpoint成功的信息时，会将`pending`的文件转换为`finished`。

![](https://gitee.com/halfcoke/blog_img/raw/master/20210704231111.svg)

## 源码分析(Base Flink-1.12.3)

### StreamingFileSink工作流程

首先分析`StreamingFileSink`整体工作流程，下文摘录主要源码进行说明。

`StreamingFileSink`继承自`RichSinkFunction`，并且实现了与checkpoint相关的两个接口(与Checkpoint有关的功能在下面逐步提及)。

构造函数源码：

```java
public class StreamingFileSink<IN> extends RichSinkFunction<IN> implements CheckpointedFunction, CheckpointListener{
    
    ...
        
     // StreamingFileSink构造函数
     /**
     * Creates a new {@code StreamingFileSink} that writes files to the given base directory with
     * the give buckets properties.
     */
    protected StreamingFileSink(BucketsBuilder<IN, ?, ? extends BucketsBuilder<IN, ?, ?>> bucketsBuilder,
            long bucketCheckInterval) {
        Preconditions.checkArgument(bucketCheckInterval > 0L);
        this.bucketsBuilder = Preconditions.checkNotNull(bucketsBuilder);
        this.bucketCheckInterval = bucketCheckInterval;
    }
    
    ...
        
}
    
```

`StreamingFileSink`的构造函数的访问修饰符是`protected`，需要通过两个Builder方法新建实例。

![image-20210704233834035](https://gitee.com/halfcoke/blog_img/raw/master/20210704233838.png)

而且这两个Builder均继承自`StreamingFileSink`的内部抽象类`BucketsBuilder`。

![image-20210705000231492](https://gitee.com/halfcoke/blog_img/raw/master/20210705101329.png)



