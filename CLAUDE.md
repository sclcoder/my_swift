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

Alamofire and Moya are included as local pods for source-level study. The local copies may diverge from upstream releases.

### Networking pattern

The MVVM module demonstrates the standard Moya networking pattern:
1. `UserAPI` enum conforms to `TargetType` (defines endpoints)
2. `ApiService` creates `MoyaProvider` and exposes RxSwift-based API calls
3. `ViewModels` consume the service and expose data to view controllers

## Language

Source comments and notes are primarily in Chinese (中文). Respond in the same language the user uses.
