---
title: DeltaLake论文阅读笔记
subtitle: >-
  DeltaLake论文 Lakehouse A New Generation of Open Platforms that Unify Data
  Warehousing and Advanced Analytics
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
tags:
  - 大数据
  - Lakehouse
  - DeltaLake
categories:
  - 大数据
  - 存储架构
  - Lakehouse
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202309291558033.png'
abbrlink: c0df81a5
date: 2023-09-29 15:52:34
---

# DeltaLake论文：Lakehouse: A New Generation of Open Platforms that Unify Data Warehousing and Advanced Analytics

> 论文原文地址：http://cidrdb.org/cidr2021/papers/cidr2021_paper17.pdf

## 原文阅读

### 摘要

1.Lakehouse基于开源的数据格式，比如Parquet

2.Lakehouse对机器学习和数据科学的支持很好

3.Lakehouse提供了很好的确保状态一致性的性能

### 介绍

第一代数仓支撑了BI，但需要严格按照数据库schema去写，来确保为了下游的BI工具可以消费

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20230929160840665.png)

但是第一代的数据架构面临着一些问题。1.存算集中在一起。2.越来越多的数据集存在非结构化数据。

为了解决这些问题，第二代的数据分析平台提供了原始数据存储，形成了数据湖。数据湖架构是在读数据时才决定数据schema的体系。

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20230929161239782.png)

当前广泛采用双层架构

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20230929162534659.png)

但是这种双层架构会有以下四个问题

1.可靠性。保证数据湖和数仓的数据一致性是很困难的。在两个系统之间进行ETL会引入很多问题降低数据可靠性。

2.数据实时性。相比于数据湖，数仓的数据是比较旧的。但是数仓可以立即查询可用数据，数据湖则需要很长时间进行数据准备。数据分析经常需要使用过期的数据

3.限制了高级数据分析。数仓架构难以支撑机器学习框架。而使用数据湖胶固，则损失了数仓的ACID等优势特性。

4.资源浪费。

### 2 动机

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20230929225330385.png)

目前已有的数据格式，没有解决ETL复杂性、实时性和高级数据分析的问题

### 3 Lakehouse架构

#### 3.2 数据管理的元数据层

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/image-20230929223802980.png)

Dleta Lake，Iceberg和Hudi至支持单边事务，优化事务日志和被管理的对象大小也是个开放问题

#### 3.3 SQL性能优化

Lakehouse：1.Lakehouse独立于数据格式（比如parquet和orc）以便于日后更新。2.

