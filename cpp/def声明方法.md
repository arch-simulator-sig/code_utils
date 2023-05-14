# 通过def文件声明 
将所有与声明目标有关的信息以使用宏的形式列举出来，在需要声明的地方通过外部定义宏，之后将这个文件通过`#include`包含进来实现声明。通过这种方式进行声明可以有效保证不同地方声明的一致性，同时提高代码的可维护性。
# 
在[scarab](https://github.com/hpsresearchgroup/scarab)项目中的使用方式如下：
`frontend/frontend_table.def`
```C++
// Format: enum name, text name, function name prefix
FRONTEND_IMPL(PIN_EXEC_DRIVEN, "pin_exec_driven", pin_exec_driven)
FRONTEND_IMPL(TRACE,           "trace",           trace)
#ifdef ENABLE_MEMTRACE
FRONTEND_IMPL(MEMTRACE,	       "memtrace",	  memtrace)
#endif
```
`frontend/frontend_intf.c`
```C++
Frontend_Impl frontend_table[] = {
#define FRONTEND_IMPL(id, name, prefix) \
  {name,                                \
   prefix##_next_fetch_addr,            \
   prefix##_can_fetch_op,               \
   prefix##_fetch_op,                   \
   prefix##_redirect,                   \
   prefix##_recover,                    \
   prefix##_retire},
#include "frontend/frontend_table.def"
#undef FRONTEND_IMPL
};
```
`frontend/frontend_intf.h`
```C++
typedef enum Frontend_Id_enum {
#define FRONTEND_IMPL(id, name, prefix) FE_##id,
#include "frontend/frontend_table.def"
#undef FRONTEND_IMPL
  NUM_FRONTENDS
} Frontend_Id;
```