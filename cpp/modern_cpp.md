# modern_cpp

refer [现代 C++ 教程：高速上手 C++11/14/17/20](https://changkun.de/modern-cpp/zh-cn/00-preface/)



## 弃用char *

统一使用const char * 或者 auto

## nullptr constexpr :star:

禁用NULL，统一使用nullptr

constexpr可以使用常量表达式

```c++
const int len_2 = len + 1;
constexpr int len_2_constexpr = 1 + 2 + 3;
char arr_4[len_2];                	 // 非法
char arr_4[len_2_constexpr];         // 合法
```

使用 `if constexpr` 判断常量表达式

```c++
#include <iostream>

template<typename T>
auto print_type_info(const T& t) {
    if constexpr (std::is_integral<T>::value) {
        return t + 1;
    } else {
        return t + 0.001;
    }
}
int main() {
    std::cout << print_type_info(5) << std::endl;
    std::cout << print_type_info(3.14) << std::endl;
}
```



## make_tuple  :star: :star:

使得decode能拆成类似nutshell的写法

```c++
#include <iostream>
#include <tuple>

std::tuple<int, double, std::string> f() {
    return std::make_tuple(1, 2.3, "456");
}

int main() {
    auto [x, y, z] = f();
    std::cout << x << ", " << y << ", " << z << std::endl;
    return 0;
}
```



## 区间for :star:

加 &  的区别是readonly和writeonly

```c++
std::vector<int> vec = {1, 2, 3, 4};   
for (auto element : vec)
std::cout << element << std::endl; // read only
for (auto &element : vec) {
        element += 1;       // writeable
}
```



## 枚举类

实现类型安全，dreamCore使用较多enum class

## 折叠表达式 :star:

```c++
#include <iostream>
template<typename ... T>
auto sum(T ... t) {
    return (t + ...);
}
int main() {
    std::cout << sum(1, 2, 3, 4, 5, 6, 7, 8, 9, 10) << std::endl;
}
```



## 智能指针 :star::star::star:

### shared_ptr

消除显式调用delete，引用计数为0时自动删除对象；对应的，使用make_shared消除显示调用new;

get获取原始指针，reset减少引用计数，use_count查看引用计数

```c++
#include <iostream>
#include <memory>
void foo(std::shared_ptr<int> i) {
    (*i)++;
}
int main() {
    // auto pointer = new int(10); // illegal, no direct assignment
    // Constructed a std::shared_ptr
    auto pointer = std::make_shared<int>(10);
    foo(pointer);
    std::cout << *pointer << std::endl; // 11
    // The shared_ptr will be destructed before leaving the scope
    return 0;
}

auto pointer = std::make_shared<int>(10);
auto pointer2 = pointer; // 引用计数+1
auto pointer3 = pointer; // 引用计数+1
int *p = pointer.get();  // 这样不会增加引用计数
std::cout << "pointer.use_count() = " << pointer.use_count() << std::endl;   // 3
std::cout << "pointer2.use_count() = " << pointer2.use_count() << std::endl; // 3
std::cout << "pointer3.use_count() = " << pointer3.use_count() << std::endl; // 3

pointer2.reset();
std::cout << "reset pointer2:" << std::endl;
std::cout << "pointer.use_count() = " << pointer.use_count() << std::endl;   // 2
std::cout << "pointer2.use_count() = "
          << pointer2.use_count() << std::endl;           // pointer2 已 reset; 0
std::cout << "pointer3.use_count() = " << pointer3.use_count() << std::endl; // 2
```



### unique_ptr

独占的智能指针，它禁止其他智能指针与其共享同一个对象,不可复制，使用std::move转移给其他unique_ptr

```c++
std::unique_ptr<int> pointer = std::make_unique<int>(10); // make_unique 从 C++14 引入
std::unique_ptr<int> pointer2 = pointer; // 非法
```

### weak_ptr

shared_ptr可能内存泄漏，weak_ptr不会导致计数增加