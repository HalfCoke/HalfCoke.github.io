---
title: ClickHouse分布式表介绍
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/20210704040505.png'
tags:
  - 数据库
  - ClickHouse
categories:
  - 数据库
  - ClickHouse
abbrlink: e20ce22c
date: 2021-07-04 03:29:27
update: 2021-07-04 03:29:27
subtitle: ClickHouse分布式表介绍
---

# ClickHouse分布式表介绍

ClickHouse中的分布式表，本身并不存储数据，而是要依赖一些本地表

在进行分布式表创建时其实是指定的创建表的引擎为Distributed

```sql
CREATE TABLE IF NOT EXISTS events ON CLUSTER test_cluster
AS events
ENGINE = Distributed(test_cluster,test,events_local,rand());
```

Distributed引擎需要以下几个参数：

- 集群标识符
   注意不是复制表宏中的标识符，而是<remote_servers>中指定的那个。
- 本地表所在的数据库名称
- 本地表名称
- （可选的）分片键（sharding key）
   该键与config.xml中配置的分片权重（weight）一同决定写入分布式表时的路由，即数据最终落到哪个物理表上。它可以是表中一列的原始数据，也可以是函数调用的结果，如上面的SQL语句采用了随机值`rand()`。注意该键要尽量保证数据均匀分布，另外一个常用的操作是采用区分度较高的列的哈希值。

在分布式表上执行查询的流程简图如下所示。发出查询后，各个实例之间会交换自己持有的分片的表数据，最终汇总到同一个实例上返回给用户。

![img](https://gitee.com/halfcoke/blog_img_2021/raw/master/20210705182734.webp)

