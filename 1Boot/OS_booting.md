# 系统启动引导过程  

## 计算模型 取址执行  
我们要关注**指针ＩＰ**及其**指向的内容**  
**计算机刚打开电源时，ＩＰ=？  **  
**由硬件设计者决定**  
  
## Ｘ86ＰＣ
(1) X86PC 刚开机时CPU处于实模式    （实模式的寻址CS：IP（CS左移4位+IP），和保护模式不一样）  
(2)开机时，CS = 0xFFFF； IP=0x0000  
(3)寻址0xFFFF0（ROM BIOS 映射区）  
(4)检查RAM，键盘，显示器，软硬磁盘  
(5)将磁盘0磁道0扇区读入0x7c00处  
(6)设置CS=0x7c0, IP=0x0000  

先放一张全景图，从内存使用上说明系统引导与启动的过程。  
![系统启动与引导](./jpg/系统启动与引导.JPG)    


