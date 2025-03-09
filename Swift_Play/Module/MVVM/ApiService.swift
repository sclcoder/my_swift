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
