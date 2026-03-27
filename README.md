# my_swift

一个 Swift/iOS 学习与实践项目，通过实际代码示例探索各种 iOS 框架、设计模式和 Swift 语言特性。

## 环境要求

- Xcode (iOS 13.0+)
- CocoaPods

## 快速开始

```bash
pod install
open my_swift.xcworkspace
```

> 请使用 `.xcworkspace` 而非 `.xcodeproj`，因为项目使用了 CocoaPods。

## 项目结构

```
Swift_Play/
├── Bundle Files/       # AppDelegate、SceneDelegate、资源文件
├── RootVC/             # TabbarController、NavigationController、转场动画
├── Module/
│   ├── MVVM/           # Moya + RxSwift MVVM 模式示例
│   ├── Network/        # Alamofire 网络请求、async/await、Codable、GCD
│   ├── RxSwift/        # RxSwift / RxCocoa 示例
│   ├── Coding/         # Codable 协议探索（含 Playground）
│   ├── Home/           # 聊天 UI 示例
│   ├── GussePet/       # 自定义转场动画（翻转、滑动交互）
│   ├── WebView/        # 富文本编辑器
│   └── Tools/          # 工具类
├── Others/             # 枚举等 Swift 语言实验
└── UI/                 # UI 相关文件

Playgrounds/            # Swift 基础语法（数据类型、流程控制、函数、可选项、枚举、协议）
Alamofire/              # Alamofire 本地源码（local pod）
Moya/                   # Moya + RxMoya 本地源码（local pod）
```

## 依赖

| 库 | 说明 |
|---|---|
| **Alamofire** (local pod) | HTTP 网络库，本地源码引入并附有大量中文注释 |
| **Moya / Moya+RxSwift** (local pod) | 基于 Alamofire 的网络抽象层，同样附有详细中文注释 |
| **RxSwift / RxCocoa** | 响应式编程框架 |
| **SnapKit** | Auto Layout DSL |
| **Toast-Swift / PKHUD / ProgressHUD** | HUD 与 Toast 提示 |

## 源码注释

本项目对本地引入的 Alamofire 和 Moya 源码添加了大量**中文注释**，适合用于学习框架内部实现：

### Alamofire 注释覆盖

Session、Request、SessionDelegate、Protected、ParameterEncoding/Encoder、HTTPMethod、HTTPHeaders、AFError 等核心文件，涵盖：

- 框架初始化与 Session 配置流程
- 队列管理（DispatchQueue / OperationQueue / target queue）
- 请求生命周期与状态管理（@Protected 线程安全）
- 多线程安全机制（竞态条件、锁同步）
- ParameterEncoding vs ParameterEncoder 设计演进
- 相关 Swift 语言特性（闭包、可选项、属性包装器等）

### Moya 注释覆盖

MoyaProvider、MoyaProvider+Internal、Endpoint、Response、Task、TargetType、ValidationType 等文件，涵盖：

- Endpoint 抽象层设计与自定义
- 请求完整流程（Endpoint → stub → URLRequest → Plugin 链）
- Stub/Mock 测试机制
- Task 枚举 9 种变体及使用场景
- Plugin 插件的 reduce 处理模式
- 相关 Swift 语言特性（关联值、模式匹配、RangeExpression 等）

> RxMoya 部分暂无中文注释。

## 网络层示例（MVVM 模块）

```
UserAPI (TargetType) → ApiService (MoyaProvider + Rx) → ViewModel → ViewController
```

使用 [JSONPlaceholder](https://jsonplaceholder.typicode.com) 作为测试 API。

## License

见 [LICENSE](LICENSE) 文件。
