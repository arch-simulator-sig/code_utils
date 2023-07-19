# ASim Port
asim仓库：[asim](https://github.com/Asim-Modeling/asimcore)

## 端口数据读写
lib/libasim/include/asim/port.h
```C++
class BufferStorage
```
端口读写实现：`BufferStorage::Read(); BufferStorage::Write();`

## 端口连接实现
asim采用维护端口链表，对所有端口按照名称排序后，将相同名称的端口连接起来。
lib/libasim/src/port.cpp `BasePort::ConnectAll()`

## 端口扇出、带宽与延迟
lib/libasim/src/port.cpp
lib/libasim/include/asim/port.h
