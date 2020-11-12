---
title: 从源码看Flink任务启动流程
subtitle: 分析Flink源码，来看Flink任务如何启动
cover: 
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
tags:
  - Flink
  - 流处理
  - 大数据
  - 源码
categories:
  - 大数据
  - 流处理
  - Flink
typora-copy-images-to: upload
date: 2020-11-07 18:29:50
update: 2020-11-07 18:29:50
---

# 从源码看Flink任务启动流程

***本文以Flink 1.11 版本为例***

## 启动前

流处理任务都需要先获取一个流处理环境，然后执行`execute()`方法来开始执行任务，因此我们从`execute()`方法开始看程序入口。

```java
final StreamExecutionEnvironment env = StreamExecutionEnvironment.getExecutionEnvironment();
...
env.execute("job");
```

`execute()`方法源码如下：

```java
// src/main/java/org/apache/flink/streaming/api/environment/StreamExecutionEnvironment.java
/**
 * Triggers the program execution. The environment will execute all parts of
 * the program that have resulted in a "sink" operation. Sink operations are
 * for example printing results or forwarding them to a message queue.
 *
 * <p>The program execution will be logged and displayed with the provided name
 *
 * @param jobName
 * 		Desired name of the job
 * @return The result of the job execution, containing elapsed time and accumulators.
 * @throws Exception which occurs during job execution.
 */
public JobExecutionResult execute(String jobName) throws Exception {
	Preconditions.checkNotNull(jobName, "Streaming Job name should not be null.");
	return execute(getStreamGraph(jobName));
}
```

该方法首先调用`getStreamGraph(jobName)`获取数据流图。

### 数据流图获取

```java
// src/main/java/org/apache/flink/streaming/api/environment/StreamExecutionEnvironment.java
/**
 * Getter of the {@link org.apache.flink.streaming.api.graph.StreamGraph} of the streaming job. This call
 * clears previously registered {@link Transformation transformations}.
 *
 * @param jobName Desired name of the job
 * @return The streamgraph representing the transformations
 */
@Internal
public StreamGraph getStreamGraph(String jobName) {
	return getStreamGraph(jobName, true);
}

/**
 * Getter of the {@link org.apache.flink.streaming.api.graph.StreamGraph StreamGraph} of the streaming job
 * with the option to clear previously registered {@link Transformation transformations}. Clearing the
 * transformations allows, for example, to not re-execute the same operations when calling
 * {@link #execute()} multiple times.
 *
 * @param jobName Desired name of the job
 * @param clearTransformations Whether or not to clear previously registered transformations
 * @return The streamgraph representing the transformations
 */
@Internal
public StreamGraph getStreamGraph(String jobName, boolean clearTransformations) {
	StreamGraph streamGraph = getStreamGraphGenerator().setJobName(jobName).generate();
	if (clearTransformations) {
		this.transformations.clear();
	}
	return streamGraph;
}
```

### 数据流图生成

首先会新建一个生成器，然后设置一些参数。

```java
// src/main/java/org/apache/flink/streaming/api/environment/StreamExecutionEnvironment.java
private StreamGraphGenerator getStreamGraphGenerator() {
	if (transformations.size() <= 0) {
		throw new IllegalStateException("No operators defined in streaming topology. Cannot execute.");
	}
	return new StreamGraphGenerator(transformations, config, checkpointCfg)
		.setStateBackend(defaultStateBackend)
		.setChaining(isChainingEnabled)
		.setUserArtifacts(cacheFile)
		.setTimeCharacteristic(timeCharacteristic)
		.setDefaultBufferTimeout(bufferTimeout);
}
```

这里会检查`transformations`的大小，`transformations`也就是拓扑中算子的个数，这里拓扑中的算子是在Flink程序中进行定义的，也就是`addSource`或`addSink`或`process`等方法。

接下来我们看一下`StreamGraphGenerator`的`generate()`方法。

```java
// src/main/java/org/apache/flink/streaming/api/graph/StreamGraphGenerator.java
public StreamGraph generate() {
	streamGraph = new StreamGraph(executionConfig, checkpointConfig, savepointRestoreSettings);
	streamGraph.setStateBackend(stateBackend);
	streamGraph.setChaining(chaining);
	streamGraph.setScheduleMode(scheduleMode);
	streamGraph.setUserArtifacts(userArtifacts);
	streamGraph.setTimeCharacteristic(timeCharacteristic);
	streamGraph.setJobName(jobName);
	streamGraph.setGlobalDataExchangeMode(globalDataExchangeMode);

	alreadyTransformed = new HashMap<>();

	for (Transformation<?> transformation: transformations) {
		transform(transformation);
	}

	final StreamGraph builtStreamGraph = streamGraph;

	alreadyTransformed.clear();
	alreadyTransformed = null;
	streamGraph = null;

	return builtStreamGraph;
}
```

在这里会新建数据流图对象。然后将数据流图生成器中的的属性传递给数据流图。**这里有个`globalDataExchangeMode`不清楚其具体类型什么意思，留个坑。**

`transform()`方法中会根据算子类型的不同，将算子添加进数据流图中。

```java
// src/main/java/org/apache/flink/streaming/api/graph/StreamGraphGenerator.java
/**
 * Transforms one {@code Transformation}.
 *
 * <p>This checks whether we already transformed it and exits early in that case. If not it
 * delegates to one of the transformation specific methods.
 */
private Collection<Integer> transform(Transformation<?> transform) {

	if (alreadyTransformed.containsKey(transform)) {
		return alreadyTransformed.get(transform);
	}

	LOG.debug("Transforming " + transform);

	if (transform.getMaxParallelism() <= 0) {

		// if the max parallelism hasn't been set, then first use the job wide max parallelism
		// from the ExecutionConfig.
		int globalMaxParallelismFromConfig = executionConfig.getMaxParallelism();
		if (globalMaxParallelismFromConfig > 0) {
			transform.setMaxParallelism(globalMaxParallelismFromConfig);
		}
	}

	// call at least once to trigger exceptions about MissingTypeInfo
	transform.getOutputType();

	Collection<Integer> transformedIds;
	if (transform instanceof OneInputTransformation<?, ?>) {
		transformedIds = transformOneInputTransform((OneInputTransformation<?, ?>) transform);
	} else if (transform instanceof TwoInputTransformation<?, ?, ?>) {
		transformedIds = transformTwoInputTransform((TwoInputTransformation<?, ?, ?>) transform);
	} else if (transform instanceof AbstractMultipleInputTransformation<?>) {
		transformedIds = transformMultipleInputTransform((AbstractMultipleInputTransformation<?>) transform);
	} else if (transform instanceof SourceTransformation) {
		transformedIds = transformSource((SourceTransformation<?>) transform);
	} else if (transform instanceof LegacySourceTransformation<?>) {
		transformedIds = transformLegacySource((LegacySourceTransformation<?>) transform);
	} else if (transform instanceof SinkTransformation<?>) {
		transformedIds = transformSink((SinkTransformation<?>) transform);
	} else if (transform instanceof UnionTransformation<?>) {
		transformedIds = transformUnion((UnionTransformation<?>) transform);
	} else if (transform instanceof SplitTransformation<?>) {
		transformedIds = transformSplit((SplitTransformation<?>) transform);
	} else if (transform instanceof SelectTransformation<?>) {
		transformedIds = transformSelect((SelectTransformation<?>) transform);
	} else if (transform instanceof FeedbackTransformation<?>) {
		transformedIds = transformFeedback((FeedbackTransformation<?>) transform);
	} else if (transform instanceof CoFeedbackTransformation<?>) {
		transformedIds = transformCoFeedback((CoFeedbackTransformation<?>) transform);
	} else if (transform instanceof PartitionTransformation<?>) {
		transformedIds = transformPartition((PartitionTransformation<?>) transform);
	} else if (transform instanceof SideOutputTransformation<?>) {
		transformedIds = transformSideOutput((SideOutputTransformation<?>) transform);
	} else {
		throw new IllegalStateException("Unknown transformation: " + transform);
	}
    ...
```

我们点进一个方法看一下。

这其中执行的`streamGraph.addOperator()`方法，将算子加入数据流图。同时也会增加边。

```java
// src/main/java/org/apache/flink/streaming/api/graph/StreamGraphGenerator.java
/**
 * Transforms a {@code OneInputTransformation}.
 *
 * <p>This recursively transforms the inputs, creates a new {@code StreamNode} in the graph and
 * wired the inputs to this new node.
 */
private <IN, OUT> Collection<Integer> transformOneInputTransform(OneInputTransformation<IN, OUT> transform) {

	Collection<Integer> inputIds = transform(transform.getInput());

	// the recursive call might have already transformed this
	if (alreadyTransformed.containsKey(transform)) {
		return alreadyTransformed.get(transform);
	}

	String slotSharingGroup = determineSlotSharingGroup(transform.getSlotSharingGroup(), inputIds);

	streamGraph.addOperator(transform.getId(),
			slotSharingGroup,
			transform.getCoLocationGroupKey(),
			transform.getOperatorFactory(),
			transform.getInputType(),
			transform.getOutputType(),
			transform.getName());

	if (transform.getStateKeySelector() != null) {
		TypeSerializer<?> keySerializer = transform.getStateKeyType().createSerializer(executionConfig);
		streamGraph.setOneInputStateKey(transform.getId(), transform.getStateKeySelector(), keySerializer);
	}

	int parallelism = transform.getParallelism() != ExecutionConfig.PARALLELISM_DEFAULT ?
		transform.getParallelism() : executionConfig.getParallelism();
	streamGraph.setParallelism(transform.getId(), parallelism);
	streamGraph.setMaxParallelism(transform.getId(), transform.getMaxParallelism());

	for (Integer inputId: inputIds) {
		streamGraph.addEdge(inputId, transform.getId(), 0);
	}

	return Collections.singleton(transform.getId());
}
```

### 任务提交

回到`execute()`方法，在得到数据流图之后，会进行数据流图的异步执行。

```java
//src/main/java/org/apache/flink/streaming/api/environment/StreamExecutionEnvironment.java
/**
 * Triggers the program execution. The environment will execute all parts of
 * the program that have resulted in a "sink" operation. Sink operations are
 * for example printing results or forwarding them to a message queue.
 *
 * @param streamGraph the stream graph representing the transformations
 * @return The result of the job execution, containing elapsed time and accumulators.
 * @throws Exception which occurs during job execution.
 */
@Internal
public JobExecutionResult execute(StreamGraph streamGraph) throws Exception {
	final JobClient jobClient = executeAsync(streamGraph);

	try {
		final JobExecutionResult jobExecutionResult;

		if (configuration.getBoolean(DeploymentOptions.ATTACHED)) {
			jobExecutionResult = jobClient.getJobExecutionResult(userClassloader).get();
		} else {
			jobExecutionResult = new DetachedJobExecutionResult(jobClient.getJobID());
		}

		jobListeners.forEach(jobListener -> jobListener.onJobExecuted(jobExecutionResult, null));

		return jobExecutionResult;
	} catch (Throwable t) {
		// get() on the JobExecutionResult Future will throw an ExecutionException. This
		// behaviour was largely not there in Flink versions before the PipelineExecutor
		// refactoring so we should strip that exception.
		Throwable strippedException = ExceptionUtils.stripExecutionException(t);

		jobListeners.forEach(jobListener -> {
			jobListener.onJobExecuted(null, strippedException);
		});
		ExceptionUtils.rethrowException(strippedException);

		// never reached, only make javac happy
		return null;
	}
}
```

在`executeAsync`方法中，会根据执行环境的不同得到不同的执行器，比如`local`、`k8s`、`yarn`等。如下图所示。

```java
//src/main/java/org/apache/flink/streaming/api/environment/StreamExecutionEnvironment.java
/**
 * Triggers the program execution asynchronously. The environment will execute all parts of
 * the program that have resulted in a "sink" operation. Sink operations are
 * for example printing results or forwarding them to a message queue.
 *
 * @param streamGraph the stream graph representing the transformations
 * @return A {@link JobClient} that can be used to communicate with the submitted job, completed on submission succeeded.
 * @throws Exception which occurs during job execution.
 */
@Internal
public JobClient executeAsync(StreamGraph streamGraph) throws Exception {
	checkNotNull(streamGraph, "StreamGraph cannot be null.");
	checkNotNull(configuration.get(DeploymentOptions.TARGET), "No execution.target specified in your configuration file.");

	final PipelineExecutorFactory executorFactory =
		executorServiceLoader.getExecutorFactory(configuration);

	checkNotNull(
		executorFactory,
		"Cannot find compatible factory for specified execution.target (=%s)",
		configuration.get(DeploymentOptions.TARGET));

	CompletableFuture<JobClient> jobClientFuture = executorFactory
		.getExecutor(configuration)
		.execute(streamGraph, configuration);

	try {
		JobClient jobClient = jobClientFuture.get();
		jobListeners.forEach(jobListener -> jobListener.onJobSubmitted(jobClient, null));
		return jobClient;
	} catch (ExecutionException executionException) {
		final Throwable strippedException = ExceptionUtils.stripExecutionException(executionException);
		jobListeners.forEach(jobListener -> jobListener.onJobSubmitted(null, strippedException));

		throw new FlinkException(
			String.format("Failed to execute job '%s'.", streamGraph.getJobName()),
			strippedException);
	}
}
```

![image-20201107190550707](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201107190550707.png)