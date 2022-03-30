---
title: ESXi镜像自定义(集成网卡驱动)及硬盘分区
author:
  nick: HalfCoke
  link: 'https://halfcoke.github.io/'
typora-copy-images-to: upload
mathjax: true
subtitle: 自定义ESXi镜像踩坑及数据分区、服务部署
cover: 'https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117154.jpeg'
tags:
  - 虚拟化
  - ESXi
  - VMware
categories:
  - 虚拟化技术
  - ESXi
abbrlink: ef096570
date: 2021-11-20 22:53:35
update: 2021-11-20 22:53:35
---
# ESXi镜像自定义(集成网卡驱动)及硬盘分区

安装ESXi至物理机时，需要提前查看硬件兼容列表，此次安装时发现ESXi原生没有RTL-r8168网卡驱动，需要将网卡驱动打包至ESXi镜像中。

目前(2021-11-20)尝试过后，ESXi7.0暂无法使用该网卡(r8168)

## ESXi镜像自定义

ESXi镜像自定义有两种方式，一是使用Powershell脚本安装，另一种是自己使用命令打包镜像。

### 环境准备

#### PowerCLI安装

当前版本VMware Power CLI安装较为容易，官网链接：[https://developer.vmware.com/powercli](https://developer.vmware.com/powercli)

**step1：** 使用管理员身份打开powershell

**step2：**粘贴`Install-Module -Name VMware.PowerCLI`然后回车

#### ESXi官方镜像文件准备（脚本安装时可选）

自定义ESXi镜像时，不能直接使用iso文件，需要使用**Offline Bundle**文件，点击[官方下载链接](https://customerconnect.vmware.com/downloads/info/slug/datacenter_cloud_infrastructure/vmware_vsphere/6_7)，或者访问我的[下载链接](https://github.com/HalfCoke/custom-vmware-exsi/raw/main/esxi/ESXi670-201912001.zip)

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117820.png)

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117696.png)

#### 网卡驱动准备(以r8168为例)

[下载](https://vibsdepot.v-front.de/wiki/index.php/Net55-r8168)网卡驱动，vib格式在使用脚本打包的时候会用到，Offline Bundle格式在使用命令行打包时会用到

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117630.png)

在当前路径新建文件夹`drivers`，将vib格式的网卡驱动移动进文件夹

至此，环境准备工作完成

### 自定义镜像打包

#### 使用脚本方式打包

1. 纯离线方式（推荐）

    **Step1：** 在`https://github.com/VFrontDe/ESXi-Customizer-PS`下载最新的release版本的脚本(ps1文件就是powershell脚本)，并将脚本放入ESXi镜像文件所在的目录

    **Step2：**运行脚本

    ```powershell
    .\ESXi-Customizer-PS.ps1 -izip ESXi670-201912001.zip -pkgDir .\drivers\
    ```

2. 在线方式

   **Step1：** 在`https://github.com/VFrontDe/ESXi-Customizer-PS`下载最新的release版本的脚本(ps1文件就是powershell脚本)

   **Step2：**直接运行`.\ESXi-Customizer-PS.ps1 -v67 -vft -load net55-r8168`

   这种方式理论上应该是可以的，但是实际执行时总会出现错误，使用第一种离线方式打包成功了

#### 命令行自行打包

**Step1：**将之前下载的zip文件添加到工作空间中，执行`add-esxsoftwaredepot .\ESXi670-201912001.zip`

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117070.png)

**Step2：**检查当前的`Acceptance Level`，执行`get-esximageprofile`，接下来需要修改`Acceptance Level`

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117003.png)

**Step3：**

```powershell
new-esximageprofile -cloneprofile "ESXi-6.7.0-20191204001-standard" -name "ESXi-6.7.0-custom" -vendor "VMware-cus"
```

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117892.png)

**Step4：**

```powershell
set-esximageprofile -ImageProfile "ESXi-6.7.0-custom" -acceptancelevel "CommunitySupported"
```

![image-20211121193658977](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117762.png)

**Step4：**

```powershell
add-esxsoftwaredepot net55-r8168-8.045a-napi-offline_bundle.zip
```

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310117785.png)

**Step5：**

```powershell
add-esxsoftwarepackage -ImageProfile "ESXi-6.7.0-custom" -SoftwarePackage "net55-r8168"
```

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118007.png)

**Step6：**检查是否加入成功

```
(get-esximageprofile ESXi-6.7.0-custom).viblist
```

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118647.png)

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118228.png)

**Step7：**导出文件

-  ZIP (Bundle)：

```powershell
 export-esximageprofile -imageprofile ESXi-6.7.0-custom -exporttobundle  -filepath .\ESXi-6.7.0-custom.zip  -nosignaturecheck  -Force
```

- ISO (Installable)：

```pow
export-esximageprofile -imageprofile ESXi-6.7.0-custom -exporttoiso  -filepath .\ESXi-6.7.0-custom.iso  -nosignaturecheck  -Force
```

![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118913.png)

## 得到ISO文件之后

拿到iso文件后就可以像正常装系统一样写入到u盘中去安装了

安装教程有很多，随便搜搜就行了

## 硬盘分区及数据存储

一般通过web页面即可创建，但有时也需要手动创建来解决问题，手动分区及创建存储方式如下

### 硬盘分区

在ESXi中进行分区需要使用`partedUtil`工具

- 查看硬盘列表，上面框起来的就是实际的硬盘以及分区，后面有数字的表示分区，没有数字的表示硬盘本身

  ```bash
  ls /vmfs/devices/disks/
  ```

  ![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118644.png)

- 查看分区表

  查看硬盘`t10.ATA_____Lenovo_X800_SATA_256G_SSD_______________8S16010501X03403263_`实例如下

  ```bash
  partedUtil getptbl "/vmfs/devices/disks/t10.ATA_____Lenovo_X800_SATA_256G_SSD_______________8S16010501X03403263_"
  ```

  ![image-20211121195405778](https://gitee.com/halfcoke/blog_img/raw/master/image-20211121195405778.png)

  第一行是分区格式gpt

  第二行是硬盘的总体信息

  ![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118376.png)

  第三行之后是分区信息

  ![](https://cdn.jsdelivr.net/gh/HalfCoke/blog_img@master/img/202203310118009.png)

- 创建分区

  在创建分区时要注意的是，必须完整的输入分区表，如下所示

  ```bash
  partedUtil setptbl "/vmfs/devices/disks/t10.ATA_____Lenovo_X800_SATA_256G_SSD_______________8S16010501X03403263_" gpt "1 64 8191 C12A7328F81F11D2BA4B00A0C93EC93B 128" "5 8224 520191 EBD0A0A2B9E5443387C068B6B72699C7  0" "6 520224 1032191 EBD0A0A2B9E5443387C068B6B72699C7  0" "7 1032224 1257471 9D27538040AD11DBBF97000C2911D1B8  0" "8 1257504 1843199 EBD0A0A2B9E5443387C068B6B72699C7  0" "9 1843200 7086079 9D27538040AD11DBBF97000C2911D1B8  0" "2 7086080 15472639 EBD0A0A2B9E5443387C068B6B72699C7  0" "3 15472640 500118158 AA31E02A400F11DB9590000C2911D1B8  0"
  ```

  ESXi/ESX 常用的分区类型包括：

  | **分区**       | **GUID**                         | **类型（十六进制）** | **类型（十进制）** |
  | -------------- | -------------------------------- | -------------------- | ------------------ |
  | VMFS 数据存储  | AA31E02A400F11DB9590000C2911D1B8 | 0xFB                 | 251                |
  | VMKCore 诊断   | 9D27538040AD11DBBF97000C2911D1B8 | 0xFC                 | 252                |
  | VMware 预留    | 9198EFFC31C011DB8F78000C2911D1B8 |                      |                    |
  | 基本数据       | EBD0A0A2B9E5443387C068B6B72699C7 | 0x83                 | 131                |
  | Linux Swap     | 0657FD6DA4AB43C484E50933C84B4F4F | 0x82                 | 130                |
  | Linux LVM      | E6D6D379F50744C2A23C238F2A3DF928 | 0x8E                 | 142                |
  | Linux RAID     | A19D880F05FC4D3BA006743F0F84911E | 0xFD                 | 253                |
  | EFi 系统       | C12A7328F81F11D2BA4B00A0C93EC93B | 0xEF                 | 239                |
  | Microsoft 预留 | E3C9E3160B5C4DB8817DF92DF00215AE |                      |                    |
  | 未使用条目     | 00000000000000000000000000000000 |                      |                    |

### 创建数据存储

创建数据存储需要使用` vmkfstools`命令

使用示例：

```bash
vmkfstools -C vmfs6 -S NewDatastore /vmfs/devices/disks/t10.ATA_____Lenovo_X800_SATA_256G_SSD_______________8S16010501X03403263_:3
```

接下来就可以在web页面看到相关的存储信息了

## 参考资料

1 VMware Front Experience：[https://www.v-front.de/](https://www.v-front.de/)

2 Download VMware vSphere：[https://customerconnect.vmware.com/downloads/info/slug/datacenter_cloud_infrastructure/vmware_vsphere/6_7](https://customerconnect.vmware.com/downloads/info/slug/datacenter_cloud_infrastructure/vmware_vsphere/6_7)

3 使用脚本添加网卡驱动：[http://woshub.com/add-drivers-vmware-esxi-iso-image/](http://woshub.com/add-drivers-vmware-esxi-iso-image/)

4 使用命令行打包镜像：[https://communities.vmware.com/t5/ESXi-Discussions/Pink-Screen-ESXi-6-5-Failed-Install-Unable-to-Verify-Acceptance/m-p/504351#M42504](https://communities.vmware.com/t5/ESXi-Discussions/Pink-Screen-ESXi-6-5-Failed-Install-Unable-to-Verify-Acceptance/m-p/504351#M42504)

5 ESXi硬盘分区：[https://kb.vmware.com/s/article/1036609?lang=zh_CN](https://kb.vmware.com/s/article/1036609?lang=zh_CN)

6 ESXi创建数据存储：[https://kb.vmware.com/s/article/1009829?lang=zh_CN](https://kb.vmware.com/s/article/1009829?lang=zh_CN)
