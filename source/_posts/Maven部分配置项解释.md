---
title: Maven部分配置项解释
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: Maven部分配置项解释
tags:
  - 开发工具
  - maven
categories:
  - 开发工具
  - maven
abbrlink: 4346098d
date: 2021-05-02 18:48:31
update: 2021-05-02 18:48:31
cover:
---

# Maven部分配置项解释

首先来看我当前的`pom.xml`文件。

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>你的id</groupId>
    <artifactId>你的id</artifactId>
    <version>1.0-SNAPSHOT</version>

    <properties>
        <maven.compiler.source>8</maven.compiler.source>
        <maven.compiler.target>8</maven.compiler.target>
		<build.target.pathname>你的路径名</build.target.pathname>
		<build.target.dir>${project.basedir}/${build.target.pathname}</build.target.dir>
    </properties>

	<build>
		<plugins>
			<!--删除生成的目标目录-->
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-clean-plugin</artifactId>
				<version>3.1.0</version>
				<configuration>
					<filesets>
                        <!--在这里指定哪些文件夹也需要删除 -->
						<fileset>
							<directory>${build.target.pathname}</directory>
						</fileset>
					</filesets>
				</configuration>
			</plugin>
			<!--将依赖放入lib文件夹-->
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-dependency-plugin</artifactId>
				<version>3.1.1</version>
				<executions>
					<execution>
						<id>copy-dependencies</id>
						<phase>package</phase>
						<goals>
							<goal>copy-dependencies</goal>
						</goals>
						<configuration>
                            <!-- 在这里将依赖的jar包(你程序的依赖),copy进哪个文件夹-->
							<outputDirectory>${build.target.dir}/lib</outputDirectory>
						</configuration>
					</execution>
				</executions>
			</plugin>
			<!--排除打入jar包的文件路径-->
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-jar-plugin</artifactId>
				<version>3.0.0</version>
				<configuration>
                    <!-- 在这里是指将编译好的jar包(你自己的程序),copy进哪个文件夹-->
					<outputDirectory>
						${build.target.dir}/lib
					</outputDirectory>
					<excludes>
                        <!--在这里表示，会排除static路径下的所有文件，不会打入jar包中，这个路径需要是classes目录的相对路径
						https://maven.apache.org/plugins/maven-jar-plugin/examples/include-exclude.html
						实际就是resources下的路径，比如我这里static文件夹就位于resources下
						-->
						<exclude>static/**</exclude>
					</excludes>
				</configuration>
			</plugin>
            <!--用来指定将哪些文件复制到哪里去-->
			<plugin>
				<groupId>org.apache.maven.plugins</groupId>
				<artifactId>maven-resources-plugin</artifactId>
				<version>3.1.0</version>
				<executions>
					<execution>
						<id>copy-resources</id>
						<phase>package</phase>
						<goals>
							<goal>copy-resources</goal>
						</goals>
						<configuration>
							<encoding>UTF-8</encoding>
                            <!--复制的目标地址，这个变量是我自定义的-->
							<outputDirectory>${build.target.dir}</outputDirectory>
							<resources>
                                <!--资源地址-->
								<resource>
									<directory>
										${project.basedir}/src/main/resources/static/
									</directory>
								</resource>
							</resources>
						</configuration>
					</execution>
				</executions>
			</plugin>
		</plugins>
	</build>

	<dependencies>
		<dependency>
			<groupId>io.netty</groupId>
			<artifactId>netty-all</artifactId>
			<version>4.1.63.Final</version>
		</dependency>
	</dependencies>
</project>

```



pom文件的整体说明如上，接下来具体介绍一下pom文件中的不同内容。



### Maven内置变量

```shell
${project.build.sourceDirectory}:项目的主源码目录，默认为src/main/java/.   
${project.build.testSourceDirectory}:项目的测试源码目录，默认为/src/test/java/.  
${project.build.directory}:项目构建输出目录，默认为target/.         
${project.build.outputDirectory}:项目主代码编译输出目录，默认为target/classes/.    
${project.build.testOutputDirectory}:项目测试代码编译输出目录，默认为target/testclasses/.     
${project.groupId}:项目的groupId.    
${project.artifactId}:项目的artifactId. 
${project.version}:项目的version,等同于${version}               
${project.build.finalName}:项目打包输出文件的名称，默认为${project.artifactId}${project.version}.
```





## 参考

https://blog.csdn.net/fly910905/article/details/79119349

https://www.cnblogs.com/willvi624/p/9456239.html