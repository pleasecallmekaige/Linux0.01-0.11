# Linux-0.11实验环境准备

1. 克隆仓库

如果没有git，那么先安装git
sudo apt-get install git

git clone https://github.com/Wangzhike/HIT-Linux-0.11.git


2. 安装实验环境
进入文件夹
cd HIT-Linux-0.11/prepEnv/hit-oslab-qiuyu/
运行脚本
./setup.sh
本脚本会将实验环境安装在当前登录用户的家目录下，文件名为oslab，即我们的实验目录是~/oslab 

注意，请不要用超级用户权限执行此命令，当有需要时该脚本会请求超级用户权限。

3. 编译Linux 0.11
cd ~/oslab/linux-0.11

make

此时会生成镜像文件Image
4. 运行
cd ~/oslab

./run 

这里的run也是一个脚本，其最后一行的命令是启动Bochs

$OSLAB_PATH/bochs/bochs-gdb -q -f $OSLAB_PATH/bochs/bochsrc.bxrc

5. 调试
汇编语言级别
./dbg-asm

通过Bochs进行汇编语言级别调试。
C语言级别

先运行
./dbg-c

再开一个终端，运行
./rungdb 

则可以通过gdb进行C语言级别调试。






