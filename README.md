# deepin-m1

想要在 m1 设备上安装 deepin，需要准备一份 deepin 的安装用的 rootfs，使用 asahi 公开的一些内核补丁和 m1n1 完成对系统的引导。

为了完成在 m1 设备上安装并使用 deepin，需要准备以下内容：

- [ ] deepin rootfs
- [ ] m1n1
- [ ] 内核补丁
    - 将上游适配 m1 的补丁和驱动应用到 deepin 维护的内核
- [ ] 图形化安装向导
    - 在 mac 上运行的安装 deepin 的向导程序
- [ ] arm 仓库
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

待支持的设备列表：

- [ ] MacBook Pro M1
- [ ] MacBook Pro M1 Pro/Max
- [ ] Mac Mini M1
