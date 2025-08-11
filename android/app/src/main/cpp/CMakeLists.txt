# CMake构建脚本
cmake_minimum_required(VERSION 3.22.1)

# 声明项目名称
project("ndkdemo")

# 指定C++标准
set(CMAKE_CXX_STANDARD 17)

# 添加库文件
add_library(
    # 设置库名称
    ndkdemo
    
    # 设置库为共享库
    SHARED
    
    # 提供相对于此CMakeLists.txt的源文件路径
    native-lib.cpp
)

# 查找NDK中的log库
find_library(
    # 设置path变量名称
    log-lib
    
    # 指定CMake需要定位的NDK库名称
    log
)

# 指定CMake应该链接到目标库的库
target_link_libraries(
    # 指定目标库
    ndkdemo
    
    # 将目标库链接到NDK中包含的log库
    ${log-lib}
)
