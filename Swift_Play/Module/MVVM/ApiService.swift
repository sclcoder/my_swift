//
//  ApiService.swift
//  my_swift
//
//  Created by tiny on 2025/3/9.
//

import RxSwift
import Moya

class APIService {
    static let shared = APIService()
    private let provider = MoyaProvider<UserAPI>()

    private init() {}
    // MARK: Moya并没有提供异步函数的接口，但提供RxSwift接口。
    // 不过，我们可以通过 自定义扩展 来为 Moya 添加 async/await 能力。 https://github.com/Moya/Moya/issues/2265
    // 获取用户列表
    func fetchUsers() -> Single<[User]> {
        return provider.rx.request(.getUsers)
            .map([User].self)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
    }

    // **新增：获取用户详情**
    func fetchUserDetail(userId: Int) -> Single<User> {
        return provider.rx.request(.getUserDetail(userId: userId))
            .map(User.self)
            .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .observe(on: MainScheduler.instance)
    }
}
