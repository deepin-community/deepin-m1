# deepin-m1

## 重要参考资料

Asahi Linux: https://asahilinux.org/

Asahi Linux Wiki: https://github.com/AsahiLinux/docs/wiki/

Asahi Linux debian installer: https://git.zerfleddert.de/cgi-bin/gitweb.cgi/m1-debian

## 简介

想要在 m1 设备上安装 deepin，需要准备一份 deepin 的安装用的 rootfs，使用 asahi 公开的一些内核补丁和 m1n1 完成对系统的引导。

为了完成在 m1 设备上安装并使用 deepin，需要准备以下内容：

- [x] deepin rootfs
- [ ] m1n1
- [ ] 内核补丁
    - 将上游适配 m1 的补丁和驱动应用到 deepin 维护的内核
- [ ] 打包可支持M1 GPU的Mesa修改版
- [ ] 启动DDE桌面
- [ ] 图形化安装向导
    - 在 mac 上运行的安装 deepin 的向导程序
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

## 准备工作

- 打rootfs包的系统暂时只试过Linux (Deepin V20, Deepin V23, Arch Linux)，没试过Mac OS本地能否打包．

- 安装必要的打rootfs包脚本的依赖：

  - debootstrap
  - eatmydata
  - pigz
  - qemu-user-static (非ARM机器上需要)

- 创建指向/usr/share/debootstrap/scripts/buster的/usr/share/debootstrap/scripts/beige脚本

  ```bash
  sudo ln -s /usr/share/debootstrap/scripts/buster /usr/share/debootstrap/scripts/beige
  ```

- (Deepin以外的发行版需要的) 

  - 获取keyring /usr/share/keyrings/deepin-archive-camel-keyring.gpg．可以通过解包deepin-keyring包获得．
  - (Arch或其他非Debian衍生发行版) /usr/share/debootstrap/scripts/debian-common中，需要屏蔽添加usr-is-merged依赖的那一段switch-case块．

## 安装流程

当前仅从Thomas Glanzmann的Asahi Linux Debian安装脚本修改出了bootstrap生成rootfs压缩包．其他组件比如内核，mesa，Asahi Linux安装脚本，还是使用Thomas Glanzmann和官方的．

首先，因为安装脚本是在线安装模式的，所以需要先搭建一个安装仓库（推荐为http，其他的没试过，比如本地方式．听justforlxz说本地的话，会在其中某一步挂掉．我还没尝试）(**使用python的http.server搭建的服务器是无法被安装脚本使用的，本人试过了．后面用的apache2的http服务**)

仓库结构如下：

```bash
/path/to/repo
├── asahilinux.install (可选，一般是修改成使用本仓库地址的安装脚本)
├── installer_data.json (使用本项目带的)
└── os
    └── deepin-base.zip (运行bootstrap.sh生成)
```

搭好之后，直接参照[官方教程](https://asahilinux.org/2022/03/asahi-linux-alpha-release/)进行安装．这里只简单描述大致流程．

1. 跑Asahi Linux的安装脚本．一般拿[官方](https://alx.sh)的改INSTALLER_DATA变量成Deepin安装仓库地址就行，也可以改本项目中asahilinux.install的REPO_BASE．

   ``` bash
   # 假设你在安装仓库根目录放了安装脚本
   curl protocol://hostname:port/path/to/repo/asahilinux.install | sh
   ```

2. 跟着脚本走就是了．:)



## FAQ

#### Q: 我重启之后，local policy update的时候没跑完就忽然黑屏重启了．

A: 参考https://asahilinux.org/2022/03/asahi-linux-alpha-release/#how-do-i-uninstall-it . 简单来说，你需要在recoveryOS或者禁用SIP的情况下，跑官方的cleanbp.sh脚本去清启动策略．

recoveryOS呼出terminal方法：shift+win+t (普通en_US键盘)
