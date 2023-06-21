# deepin-m1

## 重要参考资料

Asahi Linux: https://asahilinux.org/

Asahi Linux Wiki: https://github.com/AsahiLinux/docs/wiki/

Asahi Linux Debian installer: https://git.zerfleddert.de/cgi-bin/gitweb.cgi/m1-debian

## 简介

想要在 m1 设备上安装 deepin，需要准备一份 deepin 的安装用的 rootfs，使用 asahi 公开的一些内核补丁和 m1n1 完成对系统的引导。

为了完成在 m1 设备上安装并使用 deepin，需要准备以下内容：

- [x] deepin rootfs
- [x] m1n1
- [ ] 内核补丁
    - 将上游适配 m1 的补丁和驱动应用到 deepin 维护的内核
- [x] 打包可支持M1 GPU的Mesa修改版
    - [ ] 内核正确开启模块 appledrm
    - [ ] 窗管特效支持M1 GPU
- [ ] 驱动扬声器
    - [ ] 内核正确开启模块 snd_soc_macaudio
- [x] 启动DDE桌面
- [ ] 图形化安装向导
    - [ ] 在 mac 上运行的安装 deepin 的向导程序
- [x] arm 仓库
    - 目前 deepin v23 已有 arm64 仓库

为了更好的支持在 m1 设备上运行 deepin，还需要后续的努力：

- [ ] 逆向设备驱动
- [ ] touchbar适配
    - 可先做模拟界面，等待驱动适配
- [ ] 指纹支持
    - Apple 安全芯片没有驱动，指纹设备无法使用
- [ ] 软件支持 16k 内存页大小
- [ ] 优化调度器
    - m1 使用异构设计，调度器需要安排合适的任务到大小核上执行

支持设备列表：

- [ ] MacBook Pro M1
- [ ] MacBook Pro M1 Pro/Max
- [x] Mac Mini M1

## 安装流程

deepin ci仓库有提供现成的安装脚本。当然，你也可以通过自行搭建安装仓库的方法自行安装。

如果你不怕麻烦的话，也可以通过仅安装官方m1n1+uboot引导的方式，通过插入写好特制内容的deepin安装盘进行安装。

### 使用Deepin的安装仓库

在MacOS上打开Terminal，然后，运行以下命令执行安装脚本。

```zsh
curl https://ci.deepin.com/repo/deepin/deepin-ports/deepin-m1/deepin.install | sh
```

- 注意，跑完脚本后，它会让你关机．(Mac Mini)开机时，长摁开机键直至出现启动菜单．选择deepin，然后跟着脚本走来设置deepin为默认的启动项．
- deepin系统默认用户 hiweed, 密码为 1



### 自行搭建安装仓库

##### 准备工作

- 打rootfs包的系统暂时只试过Linux (deepin V20, deepin V23, Arch Linux)，没试过Mac OS本地能否打包．

- 安装必要的打rootfs包依赖：

  - debootstrap
  - eatmydata
  - pigz
  - qemu-user-static (非ARM机器上需要)

- 创建指向/usr/share/debootstrap/scripts/buster的/usr/share/debootstrap/scripts/beige脚本

  ```bash
  sudo ln -s /usr/share/debootstrap/scripts/buster /usr/share/debootstrap/scripts/beige
  ```

- (deepin以外的发行版需要的) 

  - 获取keyring: /usr/share/keyrings/deepin-archive-camel-keyring.gpg．非deepin发行版可以通过解包deepin-keyring包获得．
  - (Arch或其他非Debian衍生发行版) /usr/share/debootstrap/scripts/debian-common中，需要屏蔽添加usr-is-merged依赖的那一段switch-case块．

##### 搭建仓库


当前仅从Thomas Glanzmann的Asahi Linux Debian安装器仓库修改了bootstrap脚本生成rootfs压缩包．(如果想和上游对比的话，可以自行开启．打包时默认屏蔽掉了．) 

首先，因为安装脚本是在线安装模式的，所以需要先搭建一个安装仓库（推荐为http，其他的没试过，比如本地方式．听justforlxz说本地的话，会在其中某一步挂掉．我还没尝试）(**使用python的http.server搭建的服务器是无法被安装脚本使用的，本人试过了．后面用的apache2的http服务**)

仓库结构如下：

```bash
/path/to/repo
├── asahilinux.install (可选，一般是修改成使用本文件服务器地址的安装脚本)
├── installer_data.json (使用本项目带的)
└── os
    └── deepin-base.zip (运行本项目中的bootstrap.sh, 然后会在项目的build目录下生成)
    └── deepin-desktop.zip (运行本项目中的bootstrap.sh, 然后会在项目的build目录下生成)
```

搭好之后，直接参照[官方教程](https://asahilinux.org/2022/03/asahi-linux-alpha-release/)进行安装．这里只简单描述大致流程．

1. 跑Asahi Linux的安装脚本．一般拿[官方](https://alx.sh)的改INSTALLER_DATA变量成deepin安装仓库地址就行，也可以改本项目中asahilinux.install的REPO_BASE．

   ``` bash
   # 假设你在安装仓库根目录放了安装脚本
   curl protocol://hostname:port/path/to/repo/asahilinux.install | sh
   ```

2. 跟着脚本走就是了．:)



### 使用deepin 23 for M1安装盘

这里所说的deepin安装盘可**不是给通常机器安装使用的iso镜像盘。**只需要在U盘上**创建一个FAT分区**并**将安装内容写入根目录**即可。

具体步骤如下：

- 创建安装盘

  - 按照m1-debian的介绍，运行一下命令创建分区。

    ```bash
    # 替换成你U盘的对应设备
    DEVICE=/dev/sdX
    sudo parted -a optimal $DEVICE mklabel msdos
    sudo parted -a optimal $DEVICE mkpart primary fat32 2048s 100%
    sudo mkfs.vfat ${DEVICE}1
    sudo mount ${DEVICE}1 /mnt
    ```

  - 在[这里](https://ci.deepin.com/repo/deepin/deepin-ports/deepin-m1/deepin-m1-usb-installer.zip)下载安装盘压缩包，并解压到**U盘FAT分区**的**根目录**。

- 在Mac上安装m1n1+uboot引导。(Asahi Linux官方安装脚本选第三项UEFI environment only, m1n1+uboot+esp)

  ```bash
  curl https://alx.sh/ | sh
  ```

- 像上面脚本一样，跟着脚本走，安装引导系统并设置默认启动项。

- 像正常安装一样，插入U盘并开机。如果没识别U盘，在U-Boot界面跑usb reset命令刷新一下。

- 进行安装时，请选择**自定义安装，并选择空闲磁盘空间进行安装**。

**(!!!请不要选择全盘安装模式或高级安装。这样会导致抹除原来的MacOS系统和引导，使机器变砖，只能线刷救回。!!!)**

**(!!!请不要选择全盘安装模式或高级安装。这样会导致抹除原来的MacOS系统和引导，使机器变砖，只能线刷救回。!!!)**

**(!!!请不要选择全盘安装模式或高级安装。这样会导致抹除原来的MacOS系统和引导，使机器变砖，只能线刷救回。!!!)**



## DDE桌面移植进展

当前打包脚本会生成deepin-desktop.zip，预装桌面环境的rootfs包．

base包的话，大概需要安装dde-session-ui, deepin-desktop-environment-core, deepin-desktop-environment-base, dde-session-shell, libssl-dev　(libssl的打包有问题，没有提供libssl.so，需要修)

当前默认用户hiweed，密码为1

(从deepin-base包安装桌面环境时，可能可以使用声音，但重启之后失效。)

同时，当前桌面环境存在以下已知问题：

- 系统GPU加速无法使用，可能导致一些应用发生异常。例如，Chromium无法正常启动。
- 系统无法识别任何声音设备，导致无声音播放功能。只有小概率下，刚安装完成时才会有声音。
- USB安装方式只能使用自定义安装，不能动任何已有分区。否则机器会变砖。
- 如果长时间不动鼠标，会导致其被休眠而无法使用。这个时候需要点击鼠标按键才能重新使用。
- 重启后桌面无壁纸
- 插入网线，显示网线未接入
- 没有休眠功能
- 引导界面按键盘无响应
- 时间显示错误，没有同步时间
- 没有蓝牙模块，且蓝牙不可用
- 系统版本为 beta,但是控制中心出现更新 beta版本的发布日志更新
- 应用商店中无应用
- 修改亮度无效果
- 调节色温无效果
- 深度之家标题栏错位重叠
- 无线网络未识别，无法使用
- 文件管理器中无法挂载其他操作系统的分区
- 桌面异常卡死

## FAQ

#### Q: 我重启之后，local policy update的时候没跑完就忽然黑屏重启了．

A: 参考https://asahilinux.org/2022/03/asahi-linux-alpha-release/#how-do-i-uninstall-it . 简单来说，你需要在recoveryOS或者禁用SIP的情况下，跑官方的cleanbp.sh脚本去清启动策略．

recoveryOS呼出terminal方法：shift+win+t (普通en_US键盘)

#### Q: 如何卸载安装好的Linux系统？

A: 可以使用https://github.com/AsahiLinux/asahi-installer/blob/main/tools/wipe-linux.sh 脚本。
