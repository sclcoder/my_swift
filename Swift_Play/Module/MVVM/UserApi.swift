//
//  UserApi.swift
//  my_swift
//
//  Created by tiny on 2025/3/9.
//

import Moya

enum UserAPI {
    case getUsers
    case getUserDetail(userId: Int) // 新增获取用户详情
}

extension UserAPI: TargetType {
    var baseURL: URL {
        return URL(string: "https://jsonplaceholder.typicode.com")!
    }

    var path: String {
        switch self {
        case .getUsers:
            return "/users"
        case .getUserDetail(let userId):
            return "/users/\(userId)" // 访问用户详情
        }
    }

    var method: Moya.Method {
        return .get
    }

    var task: Task {
        return .requestPlain
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }
}
