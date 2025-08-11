# Android 基础应用开发框架

一个完整的Android应用开发基础框架，提供自动化的开发环境搭建、项目构建和部署流程。

## 项目功能

- **Android基础应用开发** - 提供完整的Android应用开发模板
- **Native库集成支持** - 包含JNI/NDK集成示例，支持C++原生代码开发
- **自动化开发环境** - 一键安装和配置Android开发所需的所有工具
- **项目构建和部署** - 提供完整的构建、清理、打包和安装脚本

## 项目结构

```
npzcc_android_base_build/
├── .gitignore                 # Git忽略文件配置
├── android/                    # Android应用项目
│   ├── app/                   # 应用主模块
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml           # Android应用清单文件
│   │   │   ├── java/          # Kotlin/Java源码
│   │   │   │   └── com/example/demo/
│   │   │   │       ├── MainActivity.kt       # 应用主Activity
│   │   │   │       └── NativeLib.kt          # JNI接口类
│   │   │   ├── cpp/           # C++原生代码(JNI)
│   │   │   │   ├── CMakeLists.txt             # Native构建配置
│   │   │   │   └── native-lib.cpp             # C++原生代码实现
│   │   │   └── res/           # 应用资源文件
│   │   │       ├── layout/
│   │   │       │   └── activity_main.xml      # 主界面布局文件
│   │   │       ├── mipmap-hdpi/               # 高密度图标资源
│   │   │       │   ├── ic_launcher.png        # 应用图标(高密度)
│   │   │       │   └── ic_launcher_round.png  # 圆形应用图标(高密度)
│   │   │       ├── mipmap-mdpi/               # 中密度图标资源
│   │   │       │   ├── ic_launcher.png        # 应用图标(中密度)
│   │   │       │   └── ic_launcher_round.png  # 圆形应用图标(中密度)
│   │   │       ├── mipmap-xhdpi/              # 超高密度图标资源
│   │   │       │   ├── ic_launcher.png        # 应用图标(超高密度)
│   │   │       │   └── ic_launcher_round.png  # 圆形应用图标(超高密度)
│   │   │       ├── mipmap-xxhdpi/             # 超超高密度图标资源
│   │   │       │   ├── ic_launcher.png        # 应用图标(超超高密度)
│   │   │       │   └── ic_launcher_round.png  # 圆形应用图标(超超高密度)
│   │   │       ├── mipmap-xxxhdpi/            # 超超超高密度图标资源
│   │   │       │   ├── ic_launcher.png        # 应用图标(超超超高密度)
│   │   │       │   └── ic_launcher_round.png  # 圆形应用图标(超超超高密度)
│   │   │       ├── values/                    # 值资源文件
│   │   │       │   ├── colors.xml             # 颜色定义
│   │   │       │   ├── strings.xml            # 字符串资源
│   │   │       │   └── themes.xml             # 应用主题样式
│   │   │       └── xml/                       # XML配置文件
│   │   │           ├── backup_rules.xml       # 数据备份规则
│   │   │           └── data_extraction_rules.xml # 数据提取规则
│   │   └── build.gradle       # 应用构建配置
│   ├── build.gradle           # 项目级构建配置
│   ├── gradle.properties      # Gradle属性配置
│   ├── gradlew                # Gradle Wrapper脚本(Linux/Mac)
│   ├── gradlew.bat            # Gradle Wrapper脚本(Windows)
│   ├── local.properties       # 本地配置文件(SDK路径等)
│   ├── settings.gradle        # 项目设置
│   └── gradle/                # Gradle Wrapper配置
│       └── wrapper/
│           ├── gradle-wrapper.jar        # Gradle Wrapper JAR文件
│           └── gradle-wrapper.properties # Gradle Wrapper配置
│
├── scripts/                   # 自动化脚本工具
│   ├── tools_install.sh       # 开发环境安装脚本(Java/SDK/NDK/Gradle等)
│   ├── env_setup.sh          # 环境变量配置脚本
│   ├── build_project.sh      # 项目编译构建脚本
│   ├── clean_project.sh      # 项目清理脚本(清理编译产物)
│   ├── app_icon_create.py    # 应用图标生成脚本
│   ├── app_icon_handle.sh    # 图标处理脚本
│   └── github_push.sh        # Git代码推送脚本
│
├── resources/                 # 项目资源文件
│   └── origin.png            # 原始应用图标素材(用于生成多尺寸图标)
│
├── tools/                    # 开发工具目录(脚本自动创建)
│   ├── java/                 # OpenJDK安装目录
│   ├── android-sdk/          # Android SDK安装目录
│   ├── gradle/               # Gradle工具安装目录
│   └── ndk/                  # Android NDK安装目录
│
└── output/                   # 构建输出目录(自动生成)
    └── *.apk                 # 编译生成的APK文件
```

## 核心文件说明

### Android应用文件
- **MainActivity.kt** - 应用主Activity，包含UI交互逻辑
- **NativeLib.kt** - JNI接口类，负责调用C++原生代码
- **native-lib.cpp** - C++原生代码实现，提供JNI函数

### 应用资源文件
- **activity_main.xml** - 应用主界面布局文件，定义UI组件和约束布局
- **ic_launcher.png** - 应用图标(多密度版本)，用于在桌面和应用列表显示
- **ic_launcher_round.png** - 圆形应用图标(多密度版本)，适配圆形图标主题
- **colors.xml** - 颜色资源定义，包含应用主题色和UI组件颜色
- **strings.xml** - 字符串资源定义，包含应用名称和界面文本
- **themes.xml** - 应用主题样式定义，包含Material Design主题配置
- **backup_rules.xml** - Android数据备份规则配置
- **data_extraction_rules.xml** - 数据提取规则配置(Android 12+)

### 脚本工具文件
- **tools_install.sh** - 核心安装脚本，支持多种安装模式(单独安装/预装模式)
- **env_setup.sh** - 环境变量设置，配置ANDROID_HOME、JAVA_HOME等
- **build_project.sh** - 项目构建脚本，执行Gradle编译并输出APK
- **clean_project.sh** - 清理脚本，清除Java/C++编译缓存和产物
- **app_icon_create.py** - Python脚本，自动生成多尺寸应用图标
- **app_icon_handle.sh** - 应用图标处理脚本，调用Python脚本生成图标
- **github_push.sh** - Git工作流脚本，自动化代码提交推送

### 资源文件
- **origin.png** - 原始应用图标素材，用于app_icon_create.py脚本生成多尺寸图标

### 配置文件
- **build.gradle** - Gradle构建配置，定义依赖和编译选项
- **CMakeLists.txt** - CMake配置，定义C++编译规则
- **gradle.properties** - Gradle属性配置
- **gradlew** - Gradle Wrapper执行脚本(Linux/Mac系统)
- **gradlew.bat** - Gradle Wrapper执行脚本(Windows系统)
- **local.properties** - 本地SDK路径配置文件
- **settings.gradle** - Gradle项目设置文件
- **gradle-wrapper.jar** - Gradle Wrapper的JAR执行文件
- **gradle-wrapper.properties** - Gradle Wrapper版本和下载配置
- **AndroidManifest.xml** - Android应用清单文件，定义权限和组件
- **.gitignore** - Git忽略文件配置

## 技术特性

- **开发环境**: 支持Java 17、Android SDK、Gradle 8.5、NDK r25
- **应用架构**: Kotlin + C++ JNI混合开发
- **构建系统**: Gradle + CMake双构建系统
- **目标平台**: Android 7.0+ (API 24+)
- **环境隔离**: 所有开发工具安装在项目目录，不影响系统环境

## 应用功能演示

当前Android应用包含以下功能模块：
- 基础Native调用演示(JNI字符串返回)
- 系统信息获取(通过JNI获取设备架构)
- 现代化UI界面(ConstraintLayout + Material Design)

---

这是一个可直接使用的Android应用开发基础框架，适合作为新项目的起始模板。