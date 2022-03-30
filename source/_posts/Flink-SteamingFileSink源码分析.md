---
title: Flink StreamingFileSink源码分析
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
mathjax: true
subtitle: Flink SteamingFileSink源码分析
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131610.png'
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
typora-copy-images-to: upload
---

# Flink StreamingFileSink源码分析

## 介绍

`org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink`

Flink中的`StreamingFileSink`是用来将流式数据写入文件系统的Sink。在`StreamingFileSink`中会将数据首先发送到bucket中，bucket与存储目录相关，然后与Checkpoint机制配合来达到精准一次的语义。

其中`BucketAssigner`用来定义如何将元素写入哪些目录中，默认的BucketAssigner实现是DataTimeBucketAssigner，每个小时会创建一个bucket。

在写入文件时，文件有三种状态：`in-progress`，`pending`，`finished`，这是为了提供对精准一次语义的保证，新来的数据会首先写入到`in-progress`文件中，当通过用户定义的RollingPolicy触发了文件的关闭条件时(比如文件大小)，会关闭in-progress文件，并向一个新的`in-progress`文件中继续写数据。直到收到Checkpoint成功的信息时，会将`pending`的文件转换为`finished`。

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131203.png)

## 源码分析(Base Flink-1.12.3)

### StreamingFileSink工作流程

#### 实例创建

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

![image-20210704233834035](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131546.png)

而且这两个Builder均继承自`StreamingFileSink`的内部抽象类`BucketsBuilder`。

![image-20210705000231492](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131650.png)

这两个类的实例化是通过`StreamingFileSink`中的两个静态方法

```java
/**
 * Creates the builder for a {@link StreamingFileSink} with row-encoding format.
 *
 * @param basePath the base path where all the buckets are going to be created as
 *     sub-directories.
 * @param encoder the {@link Encoder} to be used when writing elements in the buckets.
 * @param <IN> the type of incoming elements
 * @return The builder where the remaining of the configuration parameters for the sink can be
 *     configured. In order to instantiate the sink, call {@link RowFormatBuilder#build()} after
 *     specifying the desired parameters.
 */
public static <IN> StreamingFileSink.DefaultRowFormatBuilder<IN> forRowFormat(
        final Path basePath, final Encoder<IN> encoder) {
    return new DefaultRowFormatBuilder<>(basePath, encoder, new DateTimeBucketAssigner<>());
}

/**
 * Creates the builder for a {@link StreamingFileSink} with bulk-encoding format.
 *
 * @param basePath the base path where all the buckets are going to be created as
 *     sub-directories.
 * @param writerFactory the {@link BulkWriter.Factory} to be used when writing elements in the
 *     buckets.
 * @param <IN> the type of incoming elements
 * @return The builder where the remaining of the configuration parameters for the sink can be
 *     configured. In order to instantiate the sink, call {@link BulkFormatBuilder#build()}
 *     after specifying the desired parameters.
 */
public static <IN> StreamingFileSink.DefaultBulkFormatBuilder<IN> forBulkFormat(
        final Path basePath, final BulkWriter.Factory<IN> writerFactory) {
    return new StreamingFileSink.DefaultBulkFormatBuilder<>(
            basePath, writerFactory, new DateTimeBucketAssigner<>());
}
```



#### 状态初始化与数据消费

状态初始化时会创建`StreamingFileSinkHelper`，这个`StreamingFileSinkHelper`基本上包含了所有的状态、数据消费的行为。

```java
// StreamingFileSink中实现的与sink以及checkpoint相关的methods

    @Override
    public void initializeState(FunctionInitializationContext context) throws Exception {
        this.helper =
                new StreamingFileSinkHelper<>(
                        bucketsBuilder.createBuckets(getRuntimeContext().getIndexOfThisSubtask()),
                        context.isRestored(),
                        context.getOperatorStateStore(),
                        ((StreamingRuntimeContext) getRuntimeContext()).getProcessingTimeService(),
                        bucketCheckInterval);
    }

    @Override
    public void notifyCheckpointComplete(long checkpointId) throws Exception {
        this.helper.commitUpToCheckpoint(checkpointId);
    }

    @Override
    public void notifyCheckpointAborted(long checkpointId) {}

    @Override
    public void snapshotState(FunctionSnapshotContext context) throws Exception {
        Preconditions.checkState(helper != null, "sink has not been initialized");
        this.helper.snapshotState(context.getCheckpointId());
    }

    @Override
    public void invoke(IN value, SinkFunction.Context context) throws Exception {
        this.helper.onElement(
                value,
                context.currentProcessingTime(),
                context.timestamp(),
                context.currentWatermark());
    }

    @Override
    public void close() throws Exception {
        if (this.helper != null) {
            this.helper.close();
        }
    }
```

数据消费的时序图及其说明如下：

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131187.png)

进行数据消费时，主要的步骤有以下几步：

1. 会调用`buckets`的`onElement`方法来进行写数据之前的一些状态更新和`bucket`的检查，检查`bucket`所对应的目录，这部分的代码主要是`org.apache.flink.streaming.api.functions.sink.filesystem.Buckets#getOrCreateBucketForBucketId`

   ```java
   private Bucket<IN, BucketID> getOrCreateBucketForBucketId(final BucketID bucketId)
           throws IOException {
       Bucket<IN, BucketID> bucket = activeBuckets.get(bucketId); // 根据bucketid检查一下之前是否创建过bucket
       if (bucket == null) { // 创建一个新的bucket
           final Path bucketPath = assembleBucketPath(bucketId);
           bucket =
                   bucketFactory.getNewBucket(
                           subtaskIndex,
                           bucketId,
                           bucketPath,
                           maxPartCounter,
                           bucketWriter,
                           rollingPolicy,
                           fileLifeCycleListener,
                           outputFileConfig);
           activeBuckets.put(bucketId, bucket);
           notifyBucketCreate(bucket);
       }
       return bucket;
   }
   ```

2. `bucket`检查完成后调用bucket的`write`方法，即`org.apache.flink.streaming.api.functions.sink.filesystem.Bucket#write`，在`write`方法中会检查文件是否触发了rolling的条件，如果触发了rolling则关闭当前文件，再新建下一个文件；然后将数据写入文件中。

   ```java
   void write(IN element, long currentTime) throws IOException {
       if (inProgressPart == null || rollingPolicy.shouldRollOnEvent(inProgressPart, element)) {// 检查是否触发了需要rolling的条件
   
           if (LOG.isDebugEnabled()) {
               LOG.debug(
                       "Subtask {} closing in-progress part file for bucket id={} due to element {}.",
                       subtaskIndex,
                       bucketId,
                       element);
           }
   
           inProgressPart = rollPartFile(currentTime);
       }
       inProgressPart.write(element, currentTime); // 向in-progress文件中写数据
   }
   ```

   在`org.apache.flink.streaming.api.functions.sink.filesystem.Bucket#rollPartFile`方法中，执行的`org.apache.flink.streaming.api.functions.sink.filesystem.Bucket#closePartFile`方法，会将当前关闭的in-progress文件存入状态中，等待checkpoint时使用。

   ```java
   private InProgressFileWriter.PendingFileRecoverable closePartFile() throws IOException {
       InProgressFileWriter.PendingFileRecoverable pendingFileRecoverable = null;
       if (inProgressPart != null) {
           pendingFileRecoverable = inProgressPart.closeForCommit();
           // 将文件关闭。处于当前checkpointid时，该状态会保存所有关闭的in-progress文件，实际上此时文件逻辑状态已经转换为pending。
           pendingFileRecoverablesForCurrentCheckpoint.add(pendingFileRecoverable); 
           inProgressPart = null;
       }
       return pendingFileRecoverable;
   }
   ```

#### 文件状态转换与checkpoint

在触发checkpoint时有两个方法，一个是常规触发checkpoint时执行的`snapshotState`方法，另一个是checkpoint完成时执行的回调`notifyCheckpointComplete`

因为在写文件时需要一致性的保证，所以采用这种两阶段提交的方式，在执行`notifyCheckpointComplete`方法后才会真正的提交完成。

##### 执行checkpoint逻辑

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131060.png)

在`org.apache.flink.streaming.api.functions.sink.filesystem.Buckets#snapshotActiveBuckets`中依次对每个bucket调用`org.apache.flink.streaming.api.functions.sink.filesystem.Bucket#onReceptionOfCheckpoint`，然后再将`onReceptionOfCheckpoint`返回的状态进行序列化保存

这其中的主要方法是`onReceptionOfCheckpoint`，这是每个`bucket`执行`checkpoint`的主要逻辑.

在这个方法中可以主要分为两个部分，其一是处理pending状态的文件，其二是处理当前正在写的in-progress文件

```java
BucketState<BucketID> onReceptionOfCheckpoint(long checkpointId) throws IOException {
    prepareBucketForCheckpointing(checkpointId);  // 处理pending状态的文件，将pending的文件的状态进行保存

    InProgressFileWriter.InProgressFileRecoverable inProgressFileRecoverable = null;
    long inProgressFileCreationTime = Long.MAX_VALUE;

    // 如果当前正在写的文件不为空，需要处理当前正在写的文件，记录相关信息到状态中
    if (inProgressPart != null) {
        inProgressFileRecoverable = inProgressPart.persist();
        inProgressFileCreationTime = inProgressPart.getCreationTime();
        this.inProgressFileRecoverablesPerCheckpoint.put(
                checkpointId, inProgressFileRecoverable);
    }

    return new BucketState<>(
            bucketId,
            bucketPath,
            inProgressFileCreationTime,
            inProgressFileRecoverable,
            pendingFileRecoverablesPerCheckpoint);
}
```

- 处理pending文件的状态主要是以下方法

```java
private void prepareBucketForCheckpointing(long checkpointId) throws IOException {
    if (inProgressPart != null && rollingPolicy.shouldRollOnCheckpoint(inProgressPart)) {
        if (LOG.isDebugEnabled()) {
            LOG.debug(
                    "Subtask {} closing in-progress part file for bucket id={} on checkpoint.",
                    subtaskIndex,
                    bucketId);
        }
        closePartFile();
    }

    if (!pendingFileRecoverablesForCurrentCheckpoint.isEmpty()) {// 将存储在当前checkpoint中的pending文件放到所有checkpoint的集合的状态中
        pendingFileRecoverablesPerCheckpoint.put(
                checkpointId, pendingFileRecoverablesForCurrentCheckpoint);
        pendingFileRecoverablesForCurrentCheckpoint = new ArrayList<>();
    }
}
```

- 处理当前正在写的in-progress文件的状态主要是这个代码段

  ```java
  BucketState<BucketID> onReceptionOfCheckpoint(long checkpointId) throws IOException {
      ...
      // 如果当前正在写的文件不为空，需要处理当前正在写的文件，记录相关信息到状态中
      if (inProgressPart != null) {
          // persist()主要是用来保存当前状态写入的信息，比如写入偏移量，
          inProgressFileRecoverable = inProgressPart.persist();
          inProgressFileCreationTime = inProgressPart.getCreationTime();
          this.inProgressFileRecoverablesPerCheckpoint.put(
                  checkpointId, inProgressFileRecoverable);
      }
      ...
  }
  ```

##### checkpoint完成时

`org.apache.flink.streaming.api.functions.sink.filesystem.StreamingFileSink#notifyCheckpointComplete`方法用来执行checkpoint完成时的逻辑

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131350.png)

这其中最终调用的方法是`org.apache.flink.streaming.api.functions.sink.filesystem.Bucket#onSuccessfulCompletionOfCheckpoint`

```java
void onSuccessfulCompletionOfCheckpoint(long checkpointId) throws IOException {
    checkNotNull(bucketWriter);

    // 获取所有的pending文件
    Iterator<Map.Entry<Long, List<InProgressFileWriter.PendingFileRecoverable>>> it =
            pendingFileRecoverablesPerCheckpoint
                    .headMap(checkpointId, true)
                    .entrySet()
                    .iterator();

    while (it.hasNext()) {
        Map.Entry<Long, List<InProgressFileWriter.PendingFileRecoverable>> entry = it.next();

        for (InProgressFileWriter.PendingFileRecoverable pendingFileRecoverable :
                entry.getValue()) {
            // 对所有的pending文件进行提交，将文件逻辑的状态转换为finished，可供下游使用了
            bucketWriter.recoverPendingFile(pendingFileRecoverable).commit();
        }
        it.remove();
    }
    // 对当前的in-progress文件进行处理
    cleanupInProgressFileRecoverables(checkpointId);
}
```



**至此，StreamingFileSink对数据的处理流程基本完成。**

附：

写数据时的inprogress文件

![image-20210705161008160](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310131121.png)

finished文件，可供下游使用

![image-20210705161125002](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310132279.png)

## StreamingFileSink对Failover的处理

StreamingFileSink在恢复状态时，会恢复每个bucket中的计数信息、正在写的in-progress、pending的信息。

![image-20210705171020224](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310132932.png)

当Failover出现在不同的阶段：

![無標題-2021-07-05-1613](https://gitee.com/halfcoke/blog_img_2021/raw/master/20210705172516.png)

