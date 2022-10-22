---
title: Flink Metrics REST API使用
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: 介绍通过REST API获取Flink相关状态
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310130905.png'
tags:
  - Flink
  - metrics
  - 流处理
categories:
  - 大数据
  - 流处理
  - Flink
abbrlink: c73cf02
date: 2020-12-23 15:10:30
update: 2020-12-23 15:10:30
---

# Flink Metrics REST API使用

## Operator Metrics采集

- idletime
- numRecords
- queueLen

https://ci.apache.org/projects/flink/flink-docs-release-1.12/ops/metrics.html#default-shuffle-service

## TaskManager Metrics采集

Flink基于JVM运行，对TM Metrics的分析实际上就是在进程及线程级别进行分析。

Flink采集TM的JVM指标时，是通过java自己的`OperatingSystemMXBean`来进行采集的，具体如下：

#### JVM CPU负载情况

Flink部分源码

```java
// org/apache/flink/runtime/metrics/util/MetricUtils.java
private static void instantiateCPUMetrics(MetricGroup metrics) {
    try {
        final com.sun.management.OperatingSystemMXBean mxBean = (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();

        metrics.<Double, Gauge<Double>>gauge("Load", mxBean::getProcessCpuLoad);
        metrics.<Long, Gauge<Long>>gauge("Time", mxBean::getProcessCpuTime);
    } catch (Exception e) {
        LOG.warn("Cannot access com.sun.management.OperatingSystemMXBean.getProcessCpuLoad()" +
                 " - CPU load metrics will not be available.", e);
    }
}
```

jvm提供的[`getProcessCpuLoad()`方法](https://docs.oracle.com/javase/7/docs/jre/api/management/extension/com/sun/management/OperatingSystemMXBean.html#getProcessCpuLoad())，介绍如下

> 返回Java虚拟机进程的“最近cpu使用量”。该值是[0.0,1.0]区间内的一个双精度值。0.0的值表示在最近观察的时间段内没有一个cpu运行来自JVM进程的线程，而1.0的值表示在最近观察的时间段内，所有cpu 100%都在活跃地运行来自JVM进程的线程。来自JVM的线程包括应用程序线程和JVM内部线程。根据JVM进程和整个系统中正在进行的活动，0.0到1.0之间的所有值都是可能的。如果Java虚拟机最近的CPU占用率不可用，该方法返回一个负数。
>
> Returns the "recent cpu usage" for the Java Virtual Machine process. This value is a double in the [0.0,1.0] interval. A value of 0.0 means that none of the CPUs were running threads from the JVM process during the recent period of time observed, while a value of 1.0 means that all CPUs were actively running threads from the JVM 100% of the time during the recent period being observed. Threads from the JVM include the application threads as well as the JVM internal threads. All values betweens 0.0 and 1.0 are possible depending of the activities going on in the JVM process and the whole system. If the Java Virtual Machine recent CPU usage is not available, the method returns a negative value.

该方法返回整个JVM的CPU使用情况，要想获得进程级别的需要考虑其他方法。

- 可以通过jps获得TaskManager的进程ID

![image-20201224222950624](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131222.png)

- 然后根据进程ID通过`top -H -p 23621`可以看到线程对CPU的使用情况，这里可以看到每一个算子都是一个线程，但是使用程序导出时应考虑一下其他命令

![image-20201224222919852](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131259.png)

#### JVM 内存使用情况

##### JVM 内存类型

> 参考https://docs.oracle.com/javase/8/docs/api/java/lang/management/MemoryMXBean.html

1. Heap

   > Java虚拟机有一个堆，它是运行时数据区域，所有类实例和数组的内存都从这个堆中分配。它在Java虚拟机启动时创建。对象的堆内存由被称为垃圾收集器的自动内存管理系统回收。
   >
   > 堆的大小可以固定，也可以扩展或收缩。堆的内存不需要是连续的。
   >
   > The Java virtual machine has a *heap* that is the runtime data area from which memory for all class instances and arrays are allocated. It is created at the Java virtual machine start-up. Heap memory for objects is reclaimed by an automatic memory management system which is known as a *garbage collector*.
   >
   > The heap may be of a fixed size or may be expanded and shrunk. The memory for the heap does not need to be contiguous.

2. Non-Heap

   > Java虚拟机管理堆以外的内存(称为非堆内存)。
   >
   > Java虚拟机有一个在所有线程之间共享的方法区域。方法区域属于非堆内存。它存储每个类的结构，比如运行时常量池、字段和方法数据，以及方法和构造函数的代码。它在Java虚拟机启动时创建。
   >
   > 
   >
   > 方法区域在逻辑上是堆的一部分，但是Java虚拟机实现可以选择不进行垃圾收集或压缩它。与堆类似，方法区域可以是固定大小的，也可以扩展或收缩。方法区域的内存不需要是连续的。
   >
   > 
   >
   > 除了方法区域，Java虚拟机实现可能需要内存用于内部处理或优化，这些内存也属于非堆内存。例如，JIT编译器需要内存来存储从Java虚拟机代码转换过来的本机机器代码，以获得高性能。
   >
   > The Java virtual machine manages memory other than the heap (referred as *non-heap memory*).
   >
   > The Java virtual machine has a *method area* that is shared among all threads. The method area belongs to non-heap memory. It stores per-class structures such as a runtime constant pool, field and method data, and the code for methods and constructors. It is created at the Java virtual machine start-up.
   >
   > The method area is logically part of the heap but a Java virtual machine implementation may choose not to either garbage collect or compact it. Similar to the heap, the method area may be of a fixed size or may be expanded and shrunk. The memory for the method area does not need to be contiguous.
   >
   > In addition to the method area, a Java virtual machine implementation may require memory for internal processing or optimization which also belongs to non-heap memory. For example, the JIT compiler requires memory for storing the native machine code translated from the Java virtual machine code for high performance.

##### MemoryUsage

MemoryUsage对象包含四部分

- init

  表示Java虚拟机在启动期间从操作系统请求内存管理的初始内存量(以字节为单位)。Java虚拟机可能会向操作系统请求额外的内存，也可能会随着时间的推移向系统释放内存。init的值可能是未定义的。

- used

  当前正在使用的内存量，字节数

- committed

  表示保证可由Java虚拟机使用的内存量(以字节为单位)。提交的内存数量可能会随时间变化(增加或减少)。Java虚拟机可能释放内存给系统，提交的内存可能小于init。committed总是大于或等于used。

- max

  表示可用于内存管理的最大内存量(以字节为单位)。它的值可能没有定义。如果定义了最大内存量，则可能随时间而改变。如果定义了max，则已使用和提交的内存总量将始终小于或等于max。如果试图增加已用内存使其大于提交内存，这样即使used <= max仍然为true(例如，当系统的虚拟内存不足时)，那么内存分配可能会失败。

![image-20201228104216053](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131803.png)

对jvm内存的事情情况通过 OpenJDK管理工具获取

```java
// org/apache/flink/runtime/metrics/util/MetricUtils.java
private static void instantiateMemoryUsageMetrics(final MetricGroup metricGroup, final Supplier<MemoryUsage> memoryUsageSupplier) {
    metricGroup.<Long, Gauge<Long>>gauge(MetricNames.MEMORY_USED, () -> memoryUsageSupplier.get().getUsed());
    metricGroup.<Long, Gauge<Long>>gauge(MetricNames.MEMORY_COMMITTED, () -> memoryUsageSupplier.get().getCommitted());
    metricGroup.<Long, Gauge<Long>>gauge(MetricNames.MEMORY_MAX, () -> memoryUsageSupplier.get().getMax());
}
```

***关于堆内存、非堆内存等内存类型参考JVM虚拟机相关内容***

Status.Flink.Memory是[Flink1.12.0](https://cwiki.apache.org/confluence/display/FLINK/FLIP-102%3A+Add+More+Metrics+to+TaskManager)新增加的[特性](https://issues.apache.org/jira/browse/FLINK-14406)

在获取Flink已用的内存大小时，是依次获得每个Slot所用的内存。

获得总计的Flink管理内存时，是直接获取配置文件中的`taskmanager.memory.managed.size`

> TaskExecutor管理内存大小，是由memory manager管理的非堆内存大小，为排序、哈希表、中间结果缓存、RocksDB状态后端所保留的大小。
>
> 内存使用者可以从内存管理器中以MemorySegments的形式分配内存，也可以从内存管理器中保留字节，并将其内存使用保持在该边界内。如果未指定，则派生它，以构成总Flink内存的配置部分。
>
> Managed Memory size for TaskExecutors. This is the size of off-heap memory managed by the memory manager, reserved for sorting, hash tables, caching of intermediate results and RocksDB state backend. Memory consumers can either allocate memory from the memory manager in the form of MemorySegments, or reserve bytes from the memory manager and keep their memory usage within that boundary. If unspecified, it will be derived to make up the configured fraction of the Total Flink Memory.

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



#### JVM垃圾回收情况

垃圾回收可以获得回收的次数以及总时间，其中<GarbageCollector>的名字是通过Jvm管理工具的如下方法获得的。

```java
GarbageCollectorMXBean::getName
```

#### TM网络情况

这里会采集TM所用的网络内存的相关信息https://ci.apache.org/projects/flink/flink-docs-release-1.12/ops/metrics.html#default-shuffle-service

通过下面的Flink源码增加了相关的Metrics

```java
// org/apache/flink/runtime/io/network/metrics/NettyShuffleMetricFactory.java
private static void internalRegisterShuffleMetrics(
    MetricGroup parentMetricGroup,
    NetworkBufferPool networkBufferPool) {
    MetricGroup shuffleGroup = parentMetricGroup.addGroup(METRIC_GROUP_SHUFFLE);
    MetricGroup networkGroup = shuffleGroup.addGroup(METRIC_GROUP_NETTY);

    networkGroup.gauge(METRIC_TOTAL_MEMORY_SEGMENT,
                       networkBufferPool::getTotalNumberOfMemorySegments);
    networkGroup.gauge(METRIC_TOTAL_MEMORY,
                       networkBufferPool::getTotalMemory);

    networkGroup.gauge(METRIC_AVAILABLE_MEMORY_SEGMENT,
                       networkBufferPool::getNumberOfAvailableMemorySegments);
    networkGroup.gauge(METRIC_AVAILABLE_MEMORY,
                       networkBufferPool::getAvailableMemory);

    networkGroup.gauge(METRIC_USED_MEMORY_SEGMENT,
                       networkBufferPool::getNumberOfUsedMemorySegments);
    networkGroup.gauge(METRIC_USED_MEMORY,
                       networkBufferPool::getUsedMemory);
}
```

`getTotalNumberOfMemorySegments`与[`taskmanager.memory.network.min`](https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/config.html#taskmanager-memory-network-min)配置项相关

> TaskExecutors的最小网络内存大小。网络内存是为ShuffleEnvironment预留的堆外内存(例如，网络缓冲区)。网络内存大小是由总链接内存的配置部分组成的。如果导出的大小小于/大于配置的最小/最大大小，则使用最小/最大大小。网络内存的确切大小可以通过设置相同的最小/最大值来显式指定
>
> Min Network Memory size for TaskExecutors. Network Memory is off-heap memory reserved for ShuffleEnvironment (e.g., network buffers). Network Memory size is derived to make up the configured fraction of the Total Flink Memory. If the derived size is less/greater than the configured min/max size, the min/max size will be used. The exact size of Network Memory can be explicitly specified by setting the min/max to the same value.

#### Metrics 列表

##### JVM CPU指标

|        Scope         | Infix          | Metrics | Description                      | Type  |
| :------------------: | :------------- | :------ | :------------------------------- | :---- |
| **Job-/TaskManager** | Status.JVM.CPU | Load    | The recent CPU usage of the JVM. | Gauge |
|                      |                | Time    | The CPU time used by the JVM.    | Gauge |

##### JVM Memory

|        Scope         | Infix               | Metrics              | Description                                                  | Type  |
| :------------------: | :------------------ | :------------------- | :----------------------------------------------------------- | :---- |
| **Job-/TaskManager** | Status.JVM.Memory   | Heap.Used            | The amount of heap memory currently used (in bytes).         | Gauge |
|                      |                     | Heap.Committed       | The amount of heap memory guaranteed to be available to the JVM (in bytes). | Gauge |
|                      |                     | Heap.Max             | The maximum amount of heap memory that can be used for memory management (in bytes). This value might not be necessarily equal to the maximum value specified through -Xmx or the equivalent Flink configuration parameter. Some GC algorithms allocate heap memory that won't be available to the user code and, therefore, not being exposed through the heap metrics. | Gauge |
|                      |                     | NonHeap.Used         | The amount of non-heap memory currently used (in bytes).     | Gauge |
|                      |                     | NonHeap.Committed    | The amount of non-heap memory guaranteed to be available to the JVM (in bytes). | Gauge |
|                      |                     | NonHeap.Max          | The maximum amount of non-heap memory that can be used for memory management (in bytes). | Gauge |
|                      |                     | Metaspace.Used       | The amount of memory currently used in the Metaspace memory pool (in bytes). | Gauge |
|                      |                     | Metaspace.Committed  | The amount of memory guaranteed to be available to the JVM in the Metaspace memory pool (in bytes). | Gauge |
|                      |                     | Metaspace.Max        | The maximum amount of memory that can be used in the Metaspace memory pool (in bytes). | Gauge |
|                      |                     | Direct.Count         | The number of buffers in the direct buffer pool.             | Gauge |
|                      |                     | Direct.MemoryUsed    | The amount of memory used by the JVM for the direct buffer pool (in bytes). | Gauge |
|                      |                     | Direct.TotalCapacity | The total capacity of all buffers in the direct buffer pool (in bytes). | Gauge |
|                      |                     | Mapped.Count         | The number of buffers in the mapped buffer pool.             | Gauge |
|                      |                     | Mapped.MemoryUsed    | The amount of memory used by the JVM for the mapped buffer pool (in bytes). | Gauge |
|                      |                     | Mapped.TotalCapacity | The number of buffers in the mapped buffer pool (in bytes).  | Gauge |
|                      | Status.Flink.Memory | Managed.Used         | The amount of managed memory currently used.                 | Gauge |
|                      |                     | Managed.Total        | The total amount of managed memory.                          | Gauge |

##### GarbageCollection

|        Scope         | Infix                       | Metrics                  | Description                                         | Type  |
| :------------------: | :-------------------------- | :----------------------- | :-------------------------------------------------- | :---- |
| **Job-/TaskManager** | Status.JVM.GarbageCollector | <GarbageCollector>.Count | The total number of collections that have occurred. | Gauge |
|                      |                             | <GarbageCollector>.Time  | The total time spent performing garbage collection. | Gauge |

#### 使用RestAPI获取TM JVM性能指标

##### CPU

`url`: `http://<jobmanager>:<port>/taskmanagers/:taskmanagerid/metrics`

`params`:

- `Status.JVM.CPU.Time`
- `Status.JVM.CPU.Load`获取jvm进程的CPU负载，要想获得线程级的需要进一步考虑

## System Metrics采集

### 基本信息

Flink使用`OSHI`来采集系统硬件信息

#### CPU使用率获取方式

Flink中关于CPU负载部分的采集源码如下，其中`getSystemCpuLoadTicks()`方法为[OSHI的方法](https://oshi.github.io/oshi/apidocs/oshi/hardware/CentralProcessor.html#getSystemCpuLoadTicks())。

该方法返回的指标中，`irq`为`Hardware interrupts`，`SoftIRQ`为`Software interrupts`。

oshi访问`/proc/stat`文件获取CPU信息

`/proc/stat`文件部分截图

![image-20201223170433096](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131765.png)

***重要***

`oshi`在对`cpuUsage`使用的`getSystemCpuLoad()`方法调用了调用了`com.sun.management.OperatingSystemMXBean`中的[`getSystemCpuLoad()`方法](https://docs.oracle.com/javase/7/docs/jre/api/management/extension/com/sun/management/OperatingSystemMXBean.html#getSystemCpuLoad())来获得负载。该方法说明如下：

> 返回整个系统的“最近的CPU使用情况”。 此值是[0.0,1.0]区间中的小数。 值0.0表示在最近观察到的时间内所有CPU都处于空闲状态，而值1.0表示在观察到的最近一段时间内所有CPU 100％处于活动状态。 介于0.0到1.0之间的所有值都是可能的，具体取决于系统中正在进行的活动。 如果系统最近的CPU使用率不可用，则该方法返回负值。
>
> Returns the "recent cpu usage" for the whole system. This value is a double in the [0.0,1.0] interval. A value of 0.0 means that all CPUs were idle during the recent period of time observed, while a value of 1.0 means that all CPUs were actively running 100% of the time during the recent period being observed. All values betweens 0.0 and 1.0 are possible depending of the activities going on in the system. If the system recent cpu usage is not available, the method returns a negative value.

```java
// org/apache/flink/runtime/metrics/util/SystemResourcesCounter.java
	private void calculateCPUUsage(CentralProcessor processor) {
		long[] ticks = processor.getSystemCpuLoadTicks();
		if (this.previousCpuTicks == null) {
			this.previousCpuTicks = ticks;
		}
		// 使用两次检测之间的时钟数来计算百分比
		long userTicks = ticks[TickType.USER.getIndex()] - previousCpuTicks[TickType.USER.getIndex()];
		long niceTicks = ticks[TickType.NICE.getIndex()] - previousCpuTicks[TickType.NICE.getIndex()];
		long sysTicks = ticks[TickType.SYSTEM.getIndex()] - previousCpuTicks[TickType.SYSTEM.getIndex()];
		long idleTicks = ticks[TickType.IDLE.getIndex()] - previousCpuTicks[TickType.IDLE.getIndex()];
		long iowaitTicks = ticks[TickType.IOWAIT.getIndex()] - previousCpuTicks[TickType.IOWAIT.getIndex()];
		long irqTicks = ticks[TickType.IRQ.getIndex()] - previousCpuTicks[TickType.IRQ.getIndex()];
		long softIrqTicks = ticks[TickType.SOFTIRQ.getIndex()] - previousCpuTicks[TickType.SOFTIRQ.getIndex()];
        // 这说明user、nice、sys、idle、iow、irq、softirq之和应为100%。
        // 在flink提供的指标中，放弃了getSystemCpuLoadTicks()方法返回的Steal时间，Steal时间表示有虚拟机的时候，被虚拟机占用的时间
		long totalCpuTicks = userTicks + niceTicks + sysTicks + idleTicks + iowaitTicks + irqTicks + softIrqTicks;
		this.previousCpuTicks = ticks;

		cpuUser = 100d * userTicks / totalCpuTicks;
		cpuNice = 100d * niceTicks / totalCpuTicks;
		cpuSys = 100d * sysTicks / totalCpuTicks;
		cpuIdle = 100d * idleTicks / totalCpuTicks;
		cpuIOWait = 100d * iowaitTicks / totalCpuTicks;
		cpuIrq = 100d * irqTicks / totalCpuTicks;
		cpuSoftIrq = 100d * softIrqTicks / totalCpuTicks;

		cpuUsage = processor.getSystemCpuLoad() * 100;

		double[] loadAverage = processor.getSystemLoadAverage(3);
		cpuLoad1 = (loadAverage[0] < 0 ? Double.NaN : loadAverage[0]);
		cpuLoad5 = (loadAverage[1] < 0 ? Double.NaN : loadAverage[1]);
		cpuLoad15 = (loadAverage[2] < 0 ? Double.NaN : loadAverage[2]);

		double[] load = processor.getProcessorCpuLoadBetweenTicks();
		checkState(load.length == cpuUsagePerProcessor.length());
		for (int i = 0; i < load.length; i++) {
			cpuUsagePerProcessor.set(i, load[i] * 100);
		}
	}
```

#### 内存使用率获取方式

oshi访问文件` /proc/meminfo `来获取内存信息

`/proc/meminfo`文件部分截图

![image-20201223165623999](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131311.png)

```java
// org/apache/flink/runtime/metrics/util/SystemResourcesMetricsInitializer.java

private static void instantiateMemoryMetrics(MetricGroup metrics, GlobalMemory memory) {
    // 获取Available大小，这与Free不同，Free表示一直没有被使用过的内存，如果有一个程序之前使用了部分内存，现在不用了，Linux也不会将这部分内存算成Free
    // 而Available包含了这部分可以回收的内存，因此Available要大于Free
    metrics.<Long, Gauge<Long>>gauge("Available", memory::getAvailable);
    metrics.<Long, Gauge<Long>>gauge("Total", memory::getTotal);
}
```

#### swap交换分区使用率获取方式

oshi访问文件` /proc/meminfo `来获取内存信息，与获取内存使用相同

这里直接调用`oshi`的`getSwapUsed`方法，在`oshi`中，`SwapUsed`是通过`/proc/meminfo`文件中的`Total`和`Free`相减得到的。

Swap的使用，能表现出系统内存是否够用，如果频繁使用Swap，则表示*系统内存不足*。

![image-20201223170913324](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131950.png)

```java
// org/apache/flink/runtime/metrics/util/SystemResourcesMetricsInitializer.java

private static void instantiateSwapMetrics(MetricGroup metrics, GlobalMemory memory) {
    metrics.<Long, Gauge<Long>>gauge("Used", memory::getSwapUsed);
    metrics.<Long, Gauge<Long>>gauge("Total", memory::getSwapTotal);
}
```

#### 网络使用情况获取方式

`oshi`通过`getNetworkIFs()`方法获取网络接口列表，包括本地接口。访问以下这些文件获取接口数据。

```java
// oshi/hardware/platform/linux/LinuxNetworks.java
public static void updateNetworkStats(NetworkIF netIF) {
    String txBytesPath = String.format("/sys/class/net/%s/statistics/tx_bytes", netIF.getName());
    String rxBytesPath = String.format("/sys/class/net/%s/statistics/rx_bytes", netIF.getName());
    String txPacketsPath = String.format("/sys/class/net/%s/statistics/tx_packets", netIF.getName());
    String rxPacketsPath = String.format("/sys/class/net/%s/statistics/rx_packets", netIF.getName());
    String txErrorsPath = String.format("/sys/class/net/%s/statistics/tx_errors", netIF.getName());
    String rxErrorsPath = String.format("/sys/class/net/%s/statistics/rx_errors", netIF.getName());
    String speed = String.format("/sys/class/net/%s/speed", netIF.getName());

    netIF.setTimeStamp(System.currentTimeMillis());
    netIF.setBytesSent(FileUtil.getLongFromFile(txBytesPath));
    netIF.setBytesRecv(FileUtil.getLongFromFile(rxBytesPath));
    netIF.setPacketsSent(FileUtil.getLongFromFile(txPacketsPath));
    netIF.setPacketsRecv(FileUtil.getLongFromFile(rxPacketsPath));
    netIF.setOutErrors(FileUtil.getLongFromFile(txErrorsPath));
    netIF.setInErrors(FileUtil.getLongFromFile(rxErrorsPath));
    netIF.setSpeed(FileUtil.getLongFromFile(speed));
}
```

在Flink中，获得每个接口的发送接收的速率。

```java
// org/apache/flink/runtime/metrics/util/SystemResourcesMetricsInitializer.java
// 这里分别获取不同网卡的信息
private static void instantiateNetworkMetrics(MetricGroup metrics, SystemResourcesCounter usageCounter) {
    for (int i = 0; i < usageCounter.getNetworkInterfaceNames().length; i++) {
        MetricGroup interfaceGroup = metrics.addGroup(usageCounter.getNetworkInterfaceNames()[i]);

        final int interfaceNo = i;
        interfaceGroup.<Long, Gauge<Long>>gauge("ReceiveRate", () -> usageCounter.getReceiveRatePerInterface(interfaceNo));
        interfaceGroup.<Long, Gauge<Long>>gauge("SendRate", () -> usageCounter.getSendRatePerInterface(interfaceNo));
    }
}

private void calculateNetworkUsage(NetworkIF[] networkIFs) {
    checkState(networkIFs.length == receiveRatePerInterface.length());

    for (int i = 0; i < networkIFs.length; i++) {
        NetworkIF networkIF = networkIFs[i];
        networkIF.updateNetworkStats();
// 在这里设置每个接口发送接收的速率
        receiveRatePerInterface.set(i, (networkIF.getBytesRecv() - bytesReceivedPerInterface[i]) * 1000 / probeIntervalMs);
        sendRatePerInterface.set(i, (networkIF.getBytesSent() - bytesSentPerInterface[i]) * 1000 / probeIntervalMs);

        bytesReceivedPerInterface[i] = networkIF.getBytesRecv();
        bytesSentPerInterface[i] = networkIF.getBytesSent();
    }
}
```

### 配置Flink

```bash
# FLINK_HOME/lib文件夹下
wget https://repo1.maven.org/maven2/com/github/oshi/oshi-core/3.4.0/oshi-core-3.4.0.jar
wget https://repo1.maven.org/maven2/net/java/dev/jna/jna-platform/4.2.2/jna-platform-4.2.2.jar
wget https://repo1.maven.org/maven2/net/java/dev/jna/jna/4.2.2/jna-4.2.2.jar
```

### Metrics列表

#### System CPU

|        Scope         | Infix      | Metrics   | Description                                                  |
| :------------------: | :--------- | :-------- | :----------------------------------------------------------- |
| **Job-/TaskManager** | System.CPU | Usage     | 总体CPU使用。Overall % of CPU usage on the machine.          |
|                      |            | Idle      | CPU空闲半分比，% of CPU Idle usage on the machine.           |
|                      |            | Sys       | CPU内核时间占用百分比，% of System CPU usage on the machine. |
|                      |            | User      | CPU用户空间占用百分比，% of User CPU usage on the machine.   |
|                      |            | IOWait    | CPU等待输入输出百分比，% of IOWait CPU usage on the machine. |
|                      |            | Irq       | % of Irq CPU usage on the machine.                           |
|                      |            | SoftIrq   | % of SoftIrq CPU usage on the machine.                       |
|                      |            | Nice      | % of Nice Idle usage on the machine.                         |
|                      |            | Load1min  | Average CPU load over 1 minute                               |
|                      |            | Load5min  | Average CPU load over 5 minute                               |
|                      |            | Load15min | Average CPU load over 15 minute                              |
|                      |            | UsageCPU* | % of CPU usage per each processor                            |

#### System memory

|        Scope         | Infix         | Metrics   | Description               |
| :------------------: | :------------ | :-------- | :------------------------ |
| **Job-/TaskManager** | System.Memory | Available | Available memory in bytes |
|                      |               | Total     | Total memory in bytes     |
|                      | System.Swap   | Used      | Used swap bytes           |
|                      |               | Total     | Total swap in bytes       |

#### System network

|        Scope         | Infix                         | Metrics     | Description                              |
| :------------------: | :---------------------------- | :---------- | :--------------------------------------- |
| **Job-/TaskManager** | System.Network.INTERFACE_NAME | ReceiveRate | Average receive rate in bytes per second |
|                      |                               | SendRate    | Average send rate in bytes per second    |

### 使用REST API获取TM系统性能指标

举例部分API

#### 获取TM列表

`url`: `http://<jobmanager>:<port>/taskmanagers`

#### 获取TM系统信息

##### CPU

`url`: `http://<jobmanager>:<port>/taskmanagers/:taskmanagerid/metrics`

`params`: 

- `System.CPU.Usage`，这一指标显示可能与Top不同
- `System.CPU.Idle`，采集空闲指标

##### Memory

`url`: `http://<jobmanager>:<port>/taskmanagers/:taskmanagerid/metrics`

`params`: 

- `System.Memory.Total`，字节数
- `System.Memory.Available`，采集空闲内存，字节数
- `System.Swap.Used`，使用Swap是否被使用，来考虑系统内存是否足够用，如果系统内存不足，则会使用Swap分区
- `System.Swap.Total`，

###### Network

`url`: `http://<jobmanager>:<port>/taskmanagers/:taskmanagerid/metrics`

`params`: 

- `System.Network.<interface_name>.ReceiveRate`，每秒字节数
- `System.Network.<interface_name>.SendRate`，发送字节数

