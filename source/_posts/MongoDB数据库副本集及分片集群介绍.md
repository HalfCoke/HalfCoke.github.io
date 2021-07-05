---
title: MongoDB数据库副本集及分片集群介绍
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: MongoDB数据库副本集及分片集群介绍
cover: 'https://gitee.com/halfcoke/blog_img/raw/master/20210704040220.png'
tags:
  - 数据库
  - MongoDB
categories:
  - 数据库
  - MongoDB
abbrlink: e385259a
date: 2021-07-04 03:29:09
update: 2021-07-04 03:29:09
---

# MongoDB数据库副本集及分片集群介绍

## MongoDB核心概念

- [Document](https://docs.mongodb.com/manual/introduction/#document-database)：

  MongoDB中的数据记录就是一个Document，Document的结构与JSON比较类似；

  document可以嵌套

  ![](https://docs.mongodb.com/manual/images/crud-annotated-document.bakedsvg.svg)

- [Collection](https://docs.mongodb.com/manual/core/databases-and-collections/#collections):

  MongoDB的Document存储在collection中，collection的概念与关系型数据库中表的概念相对应

  ![](https://docs.mongodb.com/manual/images/crud-annotated-collection.bakedsvg.svg)

- [Database](https://docs.mongodb.com/manual/core/databases-and-collections/#databases)：

  Database可以包含多个collection

## 副本集Replica Set

副本集中的每个节点维护着相同的数据，副本集的存在是为了提供数据冗余，提供高可用

副本集包含多个数据承载节点和一个可选的仲裁节点；在数据承载节点中，只有一个节点被视为主节点，其他的数据承载节点被视为备份节点

主节点接收所有写操作，主节点记录所有对数据集的更改，将其作为oplog。

![](https://docs.mongodb.com/manual/images/replica-set-read-write-operations-primary.bakedsvg.svg)

备份节点重复主节点的oplog，并将其中的操作应用在备份节点的数据中，从而与主节点之间形成同步。如果主节点不可用，有资格的备份节点将会选举出新的主节点。

## 分片集群

分片的作用是将数据分布在多个机器上，MongoDB使用分片支持部署超大规模的数据，并提供高吞吐。

MongoDB的分片集群包含以下组件：

- [分片shard](https://docs.mongodb.com/manual/core/sharded-cluster-shards/)

  每个分片是分片数据的自己，每个分片都可以部署为一个replica set

- [路由mongos](https://docs.mongodb.com/manual/core/sharded-cluster-query-router/)

  `mongos`作为一个查询的路由，作为用户查询MongoDB分片集群的入口

- [配置服务器config servers](https://docs.mongodb.com/manual/core/sharded-cluster-config-servers/)

  配置服务器存放了集群的元数据和配置设置

![](https://docs.mongodb.com/manual/images/sharded-cluster-production-architecture.bakedsvg.svg)

MongoDB的将数据在collection级别分片， 将collection数据分布在集群的shards之间。



用户在使用分片集群与非分片集群的MongoDB时，在使用上没有区别，通过客户端和mongouri即可访问；