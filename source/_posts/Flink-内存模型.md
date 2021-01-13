---
title: Flink 内存模型
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: 基于Flink1.12.0介绍Flink内存模型
tags:
  - Flink
  - 内存
  - 流处理
categories:
  - 大数据
  - 流处理框架
  - Flink
abbrlink: '9367e715'
date: 2021-01-04 14:23:01
update: 2021-01-04 14:23:01
cover:
---

# Flink内存模型

Flink1.12.0支持更为细粒度的内存配置，本文基于Flink1.12对现行的Flink内存管理机制进行介绍，主要内容来自[Flink文档](https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/memory/mem_setup.html)

## 总内存说明

Flink JVM 进程的*进程总内存（Total Process Memory）*包含了由 Flink 应用使用的内存（*Flink 总内存*）以及由运行 Flink 的 JVM 使用的内存。 *Flink 总内存（Total Flink Memory）*包括 *JVM 堆内存（Heap Memory）*和*堆外内存（Off-Heap Memory）*。 其中堆外内存包括*直接内存（Direct Memory）*和*本地内存（Native Memory）*。

<img src="https://ci.apache.org/projects/flink/flink-docs-release-1.12/fig/process_mem_model.svg" style="width:35%" />

配置Flink内存使用的简单方法可以使用如下两个配置项

| **Component**        | **Option for TaskManager**                                   | **Option for JobManager**                                    |
| :------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| Total Flink memory   | [`taskmanager.memory.flink.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/config.html#taskmanager-memory-flink-size) | [`jobmanager.memory.flink.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/config.html#jobmanager-memory-flink-size) |
| Total process memory | [`taskmanager.memory.process.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/config.html#taskmanager-memory-process-size) | [`jobmanager.memory.process.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/config.html#jobmanager-memory-process-size) |

Flink会根据默认值或其他配置参数来调整剩余内存部分的大小。

- 配置`Flink memory`对于`standalone deployments`更为合适，该参数可以声明为Flink本身提供多少内存，`total Flink memory`被划分为`JVM Heap`和`Off-heap`内存。

- 配置`total process memory`可以声明Flink JVM进程总计使用多少内存，对于容器话部署来说，这涉及请求多大的容器。

- 此外，可以通过设置`total Flink memory`中的特定内部组成部分来进行内存配置，JM及TM所需要设置的内存组成部分是不一样的。详情参考[TaskManager](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#configure-heap-and-managed-memory)和[JobManager](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_jobmanager.html#configure-jvm-heap)文档。

用户需要选择至少一种方式进行配置，需要从以下无默认值的配置参数（参数组合中）选择一个给出明确的配置。

| **TaskManager:**                                             | **JobManager:**                                              |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [`taskmanager.memory.flink.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-flink-size) | [`jobmanager.memory.flink.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#jobmanager-memory-flink-size) |
| [`taskmanager.memory.process.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-process-size) | [`jobmanager.memory.process.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#jobmanager-memory-process-size) |
| [`taskmanager.memory.task.heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-task-heap-size) 和 [`taskmanager.memory.managed.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-size) | [`jobmanager.memory.heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#jobmanager-memory-heap-size) |

同时进行`total process memory`及`total flink memory`配置时可能会造成配置冲突

Flink 进程启动时，会根据配置的和自动推导出的各内存部分大小，显式地设置以下 JVM 参数：

| **JVM 参数**                                                 | **TaskManager 取值**                       | **JobManager 取值**      |
| :----------------------------------------------------------- | :----------------------------------------- | :----------------------- |
| *-Xmx* 和 *-Xms*                                             | 框架堆内存 + 任务堆内存                    | JVM 堆内存 (\*)          |
| *-XX:MaxDirectMemorySize* （TaskManager 始终设置，JobManager 见注释） | 框架堆外内存 + 任务堆外内存(**) + 网络内存 | 堆外内存 (\*\*) (\*\*\*) |
| *-XX:MaxMetaspaceSize*                                       | JVM Metaspace                              | JVM Metaspace            |

(\*) 请记住，根据所使用的 GC 算法，你可能无法使用到全部堆内存。一些 GC 算法会为它们自身分配一定量的堆内存。这会导致[堆的指标](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/metrics.html#memory)返回一个不同的最大值。
(\*\*) 请注意，堆外内存也包括了用户代码使用的本地内存（非直接内存）。
(\*\*\*) 只有在 [`jobmanager.memory.enable-jvm-direct-memory-limit`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#jobmanager-memory-enable-jvm-direct-memory-limit) 设置为 `true` 时，JobManager 才会设置 *JVM 直接内存限制*。

## TaskManager内存模型

### 配置堆内存和托管内存

另一种配置 Flink 内存的方式是同时设置[任务堆内存](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#task-operator-heap-memory)和[托管内存](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#managed-memory)。 通过这种方式，用户可以更好地掌控用于 Flink 任务的 JVM 堆内存及 Flink 的[托管内存](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#managed-memory)大小。

Flink 会根据默认值或其他配置参数自动调整剩余内存部分的大小。 关于各内存部分的更多细节，请参考[相关文档](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#detailed-memory-model)。

**提示** 如果已经明确设置了任务堆内存和托管内存，建议不要再设置*进程总内存*或 *Flink 总内存*，否则可能会造成内存配置冲突。

#### 任务(算子)堆内存

如果希望确保指定大小的 JVM 堆内存给用户代码使用，可以明确指定*任务堆内存*（[`taskmanager.memory.task.heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-task-heap-size)）。 指定的内存将被包含在总的 JVM 堆空间中，专门用于 Flink 算子及用户代码的执行。

#### 托管内存

*托管内存*是由 Flink 负责分配和管理的本地（堆外）内存。 以下场景需要使用*托管内存*：

- 流处理作业中用于 [RocksDB State Backend](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/ops/state/state_backends.html#the-rocksdbstatebackend)。
- [批处理作业](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/dev/batch/)中用于排序、哈希表及缓存中间结果。
- 流处理和批处理作业中用于[在 Python 进程中执行用户自定义函数](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/dev/python/table-api-users-guide/udfs/python_udfs.html)。

可以通过以下两种范式指定*托管内存*的大小：

- 通过 [`taskmanager.memory.managed.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-size) 明确指定其大小。
- 通过 [`taskmanager.memory.managed.fraction`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-fraction) 指定在*Flink 总内存*中的占比。

当同时指定二者时，会优先采用指定的大小（Size）。 若二者均未指定，会根据[默认占比](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-fraction)进行计算。

#### 消费者权重

对于包含不同种类的托管内存消费者的作业，可以进一步控制托管内存如何在消费者之间分配。 通过 [`taskmanager.memory.managed.consumer-weights`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-consumer-weights) 可以为每一种类型的消费者指定一个权重，Flink 会按照权重的比例进行内存分配。 目前支持的消费者类型包括：

- `DATAPROC`：用于流处理中的 RocksDB State Backend 和批处理中的内置算法。
- `PYTHON`：用户 Python 进程。

例如，一个流处理作业同时使用到了 RocksDB State Backend 和 Python UDF，消费者权重设置为 `DATAPROC:70,PYTHON:30`，那么 Flink 会将 `70%` 的托管内存用于 RocksDB State Backend，`30%` 留给 Python 进程。

**提示** 只有作业中包含某种类型的消费者时，Flink 才会为该类型分配托管内存。 例如，一个流处理作业使用 Heap State Backend 和 Python UDF，消费者权重设置为 `DATAPROC:70,PYTHON:30`，那么 Flink 会将全部托管内存用于 Python 进程，因为 Heap State Backend 不使用托管内存。

**提示** 对于未出现在消费者权重中的类型，Flink 将不会为其分配托管内存。 如果缺失的类型是作业运行所必须的，则会引发内存分配失败。 默认情况下，消费者权重中包含了所有可能的消费者类型。 上述问题仅可能出现在用户显式地配置了消费者权重的情况下。

### 配置堆外内存(直接内存或本地内存)

用户代码中分配的堆外内存被归为*任务堆外内存（Task Off-heap Memory）*，可以通过 [`taskmanager.memory.task.off-heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-task-off-heap-size) 指定。

**提示** 你也可以调整[框架堆外内存（Framework Off-heap Memory）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#framework-memory)。 这是一个进阶配置，建议仅在确定 Flink 框架需要更多的内存时调整该配置。

Flink 将*框架堆外内存*和*任务堆外内存*都计算在 JVM 的*直接内存*限制中，请参考 [JVM 参数](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup.html#jvm-parameters)。

**提示** 本地内存（非直接内存）也可以被归在*框架堆外内存*或*任务堆外内存*中，在这种情况下 JVM 的*直接内存*限制可能会高于实际需求。

**提示** *网络内存（Network Memory）*同样被计算在 JVM *直接内存*中。 Flink 会负责管理网络内存，保证其实际用量不会超过配置大小。 因此，调整*网络内存*的大小不会对其他堆外内存有实质上的影响。

<img src="https://ci.apache.org/projects/flink/flink-docs-release-1.12/fig/detailed-mem-model.svg" style="width:35%" />

如上图所示，下表中列出了 Flink TaskManager 内存模型的所有组成部分，以及影响其大小的相关配置参数。

| **组成部分**                                                 | **配置参数**                                                 | **描述**                                                     |
| :----------------------------------------------------------- | :----------------------------------------------------------- | :----------------------------------------------------------- |
| [框架堆内存（Framework Heap Memory）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#framework-memory) | [`taskmanager.memory.framework.heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-framework-heap-size) | 用于 Flink 框架的 JVM 堆内存（进阶配置）。                   |
| [任务堆内存（Task Heap Memory）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#task-operator-heap-memory) | [`taskmanager.memory.task.heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-task-heap-size) | 用于 Flink 应用的算子及用户代码的 JVM 堆内存。               |
| [托管内存（Managed memory）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#managed-memory) | [`taskmanager.memory.managed.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-size) [`taskmanager.memory.managed.fraction`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-managed-fraction) | 由 Flink 管理的用于排序、哈希表、缓存中间结果及 RocksDB State Backend 的本地内存。 |
| [框架堆外内存（Framework Off-heap Memory）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#framework-memory) | [`taskmanager.memory.framework.off-heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-framework-off-heap-size) | 用于 Flink 框架的[堆外内存（直接内存或本地内存）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#configure-off-heap-memory-direct-or-native)（进阶配置）。 |
| [任务堆外内存（Task Off-heap Memory）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#configure-off-heap-memory-direct-or-native) | [`taskmanager.memory.task.off-heap.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-task-off-heap-size) | 用于 Flink 应用的算子及用户代码的[堆外内存（直接内存或本地内存）](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup_tm.html#configure-off-heap-memory-direct-or-native)。 |
| 网络内存（Network Memory）                                   | [`taskmanager.memory.network.min`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-network-min) [`taskmanager.memory.network.max`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-network-max) [`taskmanager.memory.network.fraction`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-network-fraction) | 用于任务之间数据传输的直接内存（例如网络传输缓冲）。该内存部分为基于 [Flink 总内存](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup.html#configure-total-memory)的[受限的等比内存部分](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup.html#capped-fractionated-components)。 |
| [JVM Metaspace](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup.html#jvm-parameters) | [`taskmanager.memory.jvm-metaspace.size`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-jvm-metaspace-size) | Flink JVM 进程的 Metaspace。                                 |
| JVM 开销                                                     | [`taskmanager.memory.jvm-overhead.min`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-jvm-overhead-min) [`taskmanager.memory.jvm-overhead.max`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-jvm-overhead-max) [`taskmanager.memory.jvm-overhead.fraction`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/config.html#taskmanager-memory-jvm-overhead-fraction) | 用于其他 JVM 开销的本地内存，例如栈空间、垃圾回收空间等。该内存部分为基于[进程总内存](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup.html#configure-total-memory)的[受限的等比内存部分](https://ci.apache.org/projects/flink/flink-docs-release-1.12/zh/deployment/memory/mem_setup.html#capped-fractionated-components)。 |

## Web UI 界面介绍

![](https://gitee.com/halfcoke/blog_img/raw/master/img/20210103212633.svg)

### 内存根据Slot数量划分部分源码

```java
// org/apache/flink/runtime/resourcemanager/slotmanager/SlotManagerImpl.java
@VisibleForTesting
public static ResourceProfile generateDefaultSlotResourceProfile(WorkerResourceSpec workerResourceSpec, int numSlotsPerWorker) {
    return ResourceProfile.newBuilder()
        .setCpuCores(workerResourceSpec.getCpuCores().divide(numSlotsPerWorker))
        .setTaskHeapMemory(workerResourceSpec.getTaskHeapSize().divide(numSlotsPerWorker))
        .setTaskOffHeapMemory(workerResourceSpec.getTaskOffHeapSize().divide(numSlotsPerWorker))
        .setManagedMemory(workerResourceSpec.getManagedMemSize().divide(numSlotsPerWorker))
        .setNetworkMemory(workerResourceSpec.getNetworkMemSize().divide(numSlotsPerWorker))
        .build();
}
```

### 获取已用Managed内存核心源码

```java
// org/apache/flink/runtime/metrics/util/MetricUtils.java
private static long getUsedManagedMemory(TaskSlotTable<?> taskSlotTable) {
    Set<AllocationID> activeTaskAllocationIds = taskSlotTable.getActiveTaskSlotAllocationIds();

    long usedMemory = 0L;
    for (AllocationID allocationID : activeTaskAllocationIds) {
        try {
            MemoryManager taskSlotMemoryManager = taskSlotTable.getTaskMemoryManager(allocationID);
            usedMemory += taskSlotMemoryManager.getMemorySize() - taskSlotMemoryManager.availableMemory();
        } catch (SlotNotFoundException e) {
            LOG.debug("The task slot {} is not present anymore and will be ignored in calculating the amount of used memory.", allocationID);
        }
    }

    return usedMemory;
}
```

### Flink源码修改

1. 增加显示算子实例与slot之间的对应关系

   `请求地址`：

![image-20210107211317693](https://gitee.com/halfcoke/blog_img/raw/master/img/20210107211317.png)

​		`数据样例`：

![image-20210107211257448](https://gitee.com/halfcoke/blog_img/raw/master/img/20210107211257.png)

2. 增加Taskmanager中对slotsStatus的显示

![image-20210107213354649](https://gitee.com/halfcoke/blog_img/raw/master/img/20210107213354.png)