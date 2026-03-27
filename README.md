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
| **Alamofire** (local pod) | HTTP 网络库，本地源码引入便于学习 |
| **Moya / Moya+RxSwift** (local pod) | 基于 Alamofire 的网络抽象层 |
| **RxSwift / RxCocoa** | 响应式编程框架 |
| **SnapKit** | Auto Layout DSL |
| **Toast-Swift / PKHUD / ProgressHUD** | HUD 与 Toast 提示 |

## 网络层示例（MVVM 模块）

```
UserAPI (TargetType) → ApiService (MoyaProvider + Rx) → ViewModel → ViewController
```

使用 [JSONPlaceholder](https://jsonplaceholder.typicode.com) 作为测试 API。

## License

见 [LICENSE](LICENSE) 文件。
