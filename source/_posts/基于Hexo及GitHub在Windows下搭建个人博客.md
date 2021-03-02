---
title: 基于Hexo及GitHub在Windows下搭建个人博客
subtitle: 使用Hexo及GitHub在Windows下部署个人博客，利用GitHub做图床，将图片保存至GitHub
cover: https://gitee.com/halfcoke/blog_img/raw/master/img/20201102182344.png
tags:
  - Hexo
  - GitHub
  - Windows
  - 图床
categories:
  - WEB
  - WEB部署
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
abbrlink: fa08f4c5
date: 2020-11-02 11:44:06
update: 2020-11-02 18:37:00
---

# 基于Hexo及GitHub在Windows下搭建个人博客

## Hexo安装

Hexo[官网](https://hexo.io/zh-cn/)提供了一些[安装说明](https://hexo.io/zh-cn/docs/)，但是有些部分不够清晰，对新手不够友好。接下来我们在Windows环境下安装Hexo。

我会先介绍Hexo如何安装，然后在后文再介绍如何进行配置Hexo以及如何安装主题，如何设置图床等。

### Hexo安装前

在Hexo安装前需要安装下列环境：

- [Node.js](https://nodejs.org/zh-cn/)
- [GIt](https://git-scm.com/)

#### Node.js安装及验证

1. 下载

   当前Node.js官网[https://nodejs.org/zh-cn/](https://nodejs.org/zh-cn/)所提供的下载版本为14.15.0，可直接[点击下载](https://nodejs.org/dist/v14.15.0/node-v14.15.0-x64.msi)。

![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102132645990.png)

2. 安装

   下载完成后，直接使用默认设置一直`next`就可以，安装路径自行更改。

![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102133232192.png)

3. 验证

   使用`WIN+R`打开运行，输入`cmd`，然后输入`npm -v`验证是否安装成功。如下图所示则没有问题。

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102133438956.png)

#### Git安装

1. 下载

   Git下载页面为[https://git-scm.com/downloads](https://git-scm.com/downloads)，可直接[点击下载](https://github.com/git-for-windows/git/releases/download/v2.29.2.windows.1/Git-2.29.2-64-bit.exe)，下载2.29.2 64位版本。

2. 安装

   如果有其他Git需求的用户可以搜索Git安装教程，如果没有其他需求直接默认配置安装。

3. 验证

   安装完成后，重新打开cmd，输入`git --version`，应该出现如下提示。

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102134311394.png)
   
4. 初始化配置

   首次安装git需要对git进行配置

   ```bash
   git config --global user.name "halfcoke"
   git config --global user.email halfcoke@163.com
   ```

   如果你后续想修改这个配置，可以重新执行一次，或者在`C:\Users\<你的用户名>\.gitconfig`文件中修改

### Hexo安装

Hexo需要在本地有一个文件夹，来存放与自己博客有关的内容，这个文件夹不能删除，之后写博客也需要继续用到，后续会说明如何在云端保存这个文件夹，现在我们主要说明如何安装Hexo。

1. 在一个你喜欢的地方新建一个文件夹

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102134745775.png)

2. 安装Hexo

   我们可以使用`git bash`在这个文件夹中打开命令行窗口，或者使用`cmd`进入当前路径。然后输入：

   ```bash
   npm install -g hexo-cli
   ```

   然后输入来验证安装：

   ```bash
   hexo version
   ```

   应该输出：

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102142055989.png)

3. 初始化

   使用如下命令对Hexo进行初始化。

   ```bash
   hexo init your_blog_name
   cd your_blog_name
   npm install
   ```

4. 验证安装

   依次执行如下命令：

   ```bash
   hexo g  # 生成页面
   hexo server # 在本地测试
   ```

   最后应该会出现这样的提示：

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102142855559.png)

   在你的浏览器中输入`localhost:4000`。

   至此你的第一个页面应该生成完成了。

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102143050036.png)

   但是这页面也太简单了！！！

   好吧，接下来我们看一下如何进行配置，以及如何部署到GitHub上。

## Hexo部署到GitHub

为了连续性，我们先讲如何将Hexo部署到GitHub，这样后续配置完的页面你自己就会部署到GitHub上了。

Hexo部署到GitHub非常简单，但是需要先在GitHub上创建属于自己的仓库。

### GitHub相关

如果你会GitHub相关的操作，那么直接创建一个你自己的公开仓库，然后跳到下一节，命名格式如下：

```bash
your_repo.github.io   # 对 仓库名叫这个，<your_repo>设置为你自己GitHub的用户名
```

如果你不会GitHub，往下看：

1. 进入[GitHub](https://github.com/)，注册属于自己的账号，或者直接点击到[注册页面](https://github.com/join?ref_cta=Sign+up&ref_loc=header+logged+out&ref_page=%2F&source=header-home)。

2. 然后登录进去，按下图点击创建一个仓库

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102143936299.png)

3. 在下图红框的位置填入自己GitHub的名字，后续可以直接通过这个域名访问自己的博客(当然也可以通过其他方式自定义，这个后续再说)。

   比如我的这个账号的就是`halfcokey`

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102151749812.png)
   
   关于GitHub就差不多这样了，接下来我们配置一下Hexo

### Hexo相关

在我们刚才初始化Hexo的文件夹中，找到`_config.yml`，不要用记事本打开，你可以下载个[VS Code](https://code.visualstudio.com/)或者[Sublime](https://www.sublimetext.com/)等一类的都行。

拉到最下面找到`deploy`，进行类似如下的配置，注意`yaml`文件依靠缩进，并且在`:`后有空格，一定要注意格式：

```yml
deploy:
  type: git
  repo: https://github.com/halfcokey/halfcokey.github.io.git # 你刚才新建的那个仓库的链接
  branch: master
```

更详细的说明及配置可以[参考官网](https://hexo.io/zh-cn/docs/one-command-deployment#Git)。

然后，在这个路径下打开`cmd`，执行如下命令安装部署插件：

```bash
npm install hexo-deployer-git --save
```



### 部署

这个时候你可以执行如下命令来进行部署你的个人网站：

```bash
hexo d
```

应该可以弹出让你输入账号或者授权的页面，点击授权即可。

这个时候，你就可以通过`<your_repo>.github.io`来访问你的页面了，比如我的就是[halfcoke.github.io](https://halfcoke.github.io)

## Hexo安装及部署命令总结

如果你对上面执行的这些命令好奇，想查看具体说明的话，可以查看[官网](https://hexo.io/zh-cn/docs/commands)

这些命令在之后写文章可能也会用到，所以还是需要了解一下都是什么意思

```bash
# 初始化你的博客
hexo init <folder>
# 生成静态文件
hexo g
# 部署网站
hexo d
#################
# 这里是一些上面没有用到的命令，但之后可能会用到
# 新建一篇标题为title的文章，这默认放在source/_posts文件夹下
hexo n "title"
# 清除缓存文件，如果更换主题等，建议执行一次
hexo clean
```

更详细的命令介绍请直接[点击官网](https://hexo.io/zh-cn/docs/commands)查看。

## Hexo配置

### 基本配置

Hexo配置项有很多内容，详细的可以查看[官网](https://hexo.io/zh-cn/docs/configuration)，下面我介绍一些我修改了的配置。在安装主题之后，还会再修改一些配置，我会在主题安装那里再介绍。

```yml
title: 'CCCCCoke' # 自己网站的名字
language: zh_cn # 网站语言
timezone: 'Asia/ShangHai' # 时区
url: https://HalfCoke.github.io  # 改成自己的地址
```

## Hexo本地文件夹上传

我在部署Hexo的时候第一个问题就是如果我的Hexo文件夹丢失了怎么办。因为从GitHub上看到，通过`hexo d`上传的只有我们的静态页面，所以我们就需要将Hexo的文件夹上传到云端，这样我们换了一个环境后也能无差别的编辑自己的博客，而且最好方便管理而且别太麻烦。

在这里我参考了网上其他人的做法，就是在存放自己博客的GitHub仓库新建一个分支`hexo`来存放这些文件。

具体步骤如下：

首先建议先创建`.editorconfig`文件，方便你在使用各种IDE编辑的时候配置统一，这里不做过多介绍，文件内容如下：

```ini
root = true

[*]
charset = utf-8
end_of_line = lf
```

然后，在自己博客的目录(比如我的是`d:\Blog\blog_test`)，打开`cmd`或`git bash`，然后执行如下命令：

```bash
git init # 初始化git仓库
git add . # 将当前文件添加进去
git commit -m "init" # 在本地提交

# 添加远程仓库，注意将halfcokey替换为自己的用户名
git remote add origin https://github.com/halfcokey/halfcokey.github.io.git

# 创建分支，以后的文件直接在这个分支进行提交
git checkout -b "hexo" 
# 将本地分支推送到远程仓库,并进行关联。
git push -u origin hexo
```

在之后修改文件，只需要执行如下命令即可：

```bash
git commit -a -m "修改..." # 这里建议填写一些有意义的备注
git push origin hexo
```

## MarkDown文章图片自动上传GitHub

在使用MarkDown编辑的博客的时候，如果文章中的图片数量比较少，还可以手动的将图片传到图床上，然后再添加图片链接。但如果你想放很多图片，手动就麻烦的要死。

在这里我使用[Typora](https://typora.io/)+[PicGo](https://molunerfinn.com/PicGo/)的方式来管理文章的图片。

这两个软件的安装过程比较简单，下面主要说一下我进行配置的相关的内容。

### PicGo

PicGo的配置方式比较容易，我们选择`GitHub图床`

看到我们需要填写`仓库名`、`分支名`、`Token`这些信息，下面我们分别介绍一下。

![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102164205931.png)

1. 仓库名

   我们可以新建一个仓库专门用来存放图片，新建仓库的方式与之前相同，但是这是我们的仓库名就没有那么多限制了，可以随便起，我的创建的仓库名是[blog_img](https://github.com/HalfCoke/blog_img)，然后在这个位置填入`<用户名>/<仓库名>`

2. 分支名

   默认使用master就行

3. Token

   在GitHub自己头像的位置点击`settings`，或者直接点击[https://github.com/settings/profile](https://github.com/settings/profile)

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102164652421.png)

   然后点击`Developer settings->Personal access tokens`，或者直接点击[https://github.com/settings/tokens](https://github.com/settings/tokens)

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102164803092.png)

   然后点击`Generate new token`

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102165048712.png)

   在Note的位置随便输入一个名字，下面的权限选第一个应该就行，如果前两个都选上。拉到最下面点击生成。

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102165252125.png)

   这时会有这样的提示，把这一串复制填写在PicGo的Token中，这样就可以了。

   ![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102165419821.png)

### Typora

[Typora](https://typora.io/)直接支持使用[PicGo](https://molunerfinn.com/PicGo/)。在`文件->偏好设置`中进行如下配置，主要是红框的位置

![](https://gitee.com/halfcoke/blog_img/raw/master/img/image-20201102164000589.png)

然后当你打开一个MarkDown文件的时候，点击Typora的`格式->图像->当插入本地图片时->上传图片`就可以了。这样你放进来的图片就会自动上传到你的仓库中，而且链接也会替换成在线链接。

## 其他

### Hexo主题配置

我所使用的主题是[hexo-theme-skapp](https://github.com/Mrminfive/hexo-theme-skapp)，作者提供了比较详细的配置过程，大家可以直接参考。

### Hexo插件

#### 中文标题链接处理

使用Hexo的`abbrlink`插件，方法参考作者Shin的[博客]( http://www.ideashin.com/post/2a09be9d/)

1. 安装
    ```bash
    npm install hexo-abbrlink --save
    ```
    
2. 在Hexo站点配置文件`_config.yml`中修改

    ```
    permalink: :year/:abbrlink/
    ```

3. 添加abbrlink配置

    ```
    # abbrlink config
    abbrlink:
      alg: crc32  # 算法：crc16(default) and crc32
      rep: hex    # 进制：dec(default) and hex
    ```



---


有任何问题欢迎一起探讨！
欢迎扫码关注，不定期更新各种经验。

<img src="https://gitee.com/halfcoke/blog_img/raw/master/img/qrcode.jpg" style="zoom: 67%;" />