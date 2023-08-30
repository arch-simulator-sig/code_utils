# cpp规范



1. 禁止显式使用new delete

<img src="D:\git-repo\code_utils\cpp\cpp规范.assets\image-20230816162806543.png" alt="image-20230816162806543" style="zoom:33%;" />

<img src="D:\git-repo\code_utils\cpp\cpp规范.assets\image-20230816162946095.png" alt="image-20230816162946095" style="zoom:33%;" />

2. 出现nullptr的地方使用std::optional
3. 使用constexpr加速编译，同时还有if constexpr
4. enum class 实现类型安全