# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Swift/iOS learning and experimentation project (`my_swift`) that explores various iOS frameworks, patterns, and Swift language features through working examples. It is not a production app — it's a personal study project with hands-on demos.

## Build & Run

- **Workspace**: Open `my_swift.xcworkspace` (not the `.xcodeproj`) since CocoaPods is used
- **Dependencies**: `pod install` (CocoaPods)
- **Min deployment target**: iOS 13.0
- **Build**: `xcodebuild -workspace my_swift.xcworkspace -scheme my_swift -sdk iphonesimulator build`

## Architecture

The app is a tab-based UIKit application (`TabbarController` → `NavigationController` → feature VCs).

### Key directories

- `Swift_Play/` — Main app source code
  - `Bundle Files/` — AppDelegate, SceneDelegate, Assets, Info.plist
  - `RootVC/` — TabbarController, NavigationController, custom transition animations
  - `Module/` — Feature modules, each in its own folder:
    - `MVVM/` — Moya + RxSwift MVVM pattern demo (UserApi, ApiService, ViewModels) hitting jsonplaceholder.typicode.com
    - `Network/` — Alamofire usage examples, Swift concurrency (async/await), Codable, GCD, dynamic member lookup
    - `RxSwift/` — RxSwift/RxCocoa examples
    - `Coding/` — Codable protocol exploration (includes playgrounds)
    - `Home/` — Chat UI demo
    - `GussePet/` — Custom view controller transitions (flip animations, swipe interactions)
    - `WebView/` — Rich text editor
    - `Tools/` — Utility helpers
  - `Others/` — Miscellaneous Swift experiments (enums, etc.)
  - `UI/` — UI-related files
- `Playgrounds/` — Swift language fundamentals (data types, control flow, functions, optionals, enums, protocols)
- `Alamofire/` — Local copy of Alamofire (referenced as a local pod)
- `Moya/` — Local copy of Moya + RxMoya (referenced as a local pod)

### Dependencies (CocoaPods)

- **Alamofire** — local pod (`./Alamofire`)
- **Moya** + **Moya/RxSwift** — local pod (`./Moya`)
- **RxSwift** / **RxCocoa**
- **SnapKit** — Auto Layout DSL
- **Toast-Swift**, **PKHUD**, **ProgressHUD** — HUD/toast UI

Alamofire and Moya are included as local pods，并添加了大量中文源码注释，用于深入学习框架内部实现。

### Alamofire 中文注释覆盖范围

已注释的核心文件：Session.swift、Request.swift、SessionDelegate.swift、Protected.swift、ParameterEncoding.swift、ParameterEncoder.swift、HTTPMethod.swift、HTTPHeaders.swift、AFError.swift。注释内容包括：

- 框架初始化与配置流程（Session 创建）
- 队列管理机制（DispatchQueue / OperationQueue、target queue）
- 请求生命周期与状态管理（Request 状态流转、@Protected 线程安全包装）
- 多线程与线程安全（竞态条件、锁同步、URLSession 回调线程）
- 协议设计对比（ParameterEncoding vs ParameterEncoder 的演进）
- Swift 语言特性说明（闭包、可选项、属性包装器、标识符规则等，附官方文档链接）

### Moya 中文注释覆盖范围

已注释的文件：MoyaProvider.swift、MoyaProvider+Internal.swift、Endpoint.swift、Response.swift、Task.swift、TargetType.swift、ValidationType.swift、URL+Moya.swift、Moya+Alamofire.swift。注释内容包括：

- Endpoint 抽象层设计（URL / method / task / headers 的组装与自定义）
- 请求完整流程（requestNormal 构建 Endpoint → stub 判断 → URLRequest 生成 → Plugin 处理）
- Stub/Mock 机制（开发与测试场景下的 stub 用法）
- Task 枚举的 9 种变体及使用场景
- Plugin 插件链的 reduce 处理模式
- Swift 语言特性（关联值、模式匹配、RangeExpression 协议、协议属性要求等）

> RxMoya 部分暂无中文注释。

### Networking pattern

The MVVM module demonstrates the standard Moya networking pattern:
1. `UserAPI` enum conforms to `TargetType` (defines endpoints)
2. `ApiService` creates `MoyaProvider` and exposes RxSwift-based API calls
3. `ViewModels` consume the service and expose data to view controllers

## Language

Source comments and notes are primarily in Chinese (中文). Respond in the same language the user uses.
