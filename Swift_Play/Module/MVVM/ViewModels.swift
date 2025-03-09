//
//  ViewModels.swift
//  my_swift
//
//  Created by tiny on 2025/3/9.
//

import Foundation

import RxSwift
import RxCocoa

class UserListViewModel {
    let users = BehaviorRelay<[User]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = PublishRelay<String>()
    
    private let disposeBag = DisposeBag()

    func fetchUsers() {
        isLoading.accept(true)

        APIService.shared.fetchUsers()
            .subscribe(
                onSuccess: { [weak self] users in
                    self?.users.accept(users)
                    self?.isLoading.accept(false)
                },
                onFailure: { [weak self] error in
                    self?.errorMessage.accept(error.localizedDescription)
                    self?.isLoading.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }
}

class UserDetailViewModel {
    let user = BehaviorRelay<User?>(value: nil) // 存储用户详情
    let isLoading = BehaviorRelay<Bool>(value: false)
    let errorMessage = PublishRelay<String>()

    private let disposeBag = DisposeBag()

    func fetchUserDetail(userId: Int) {
        isLoading.accept(true)

        APIService.shared.fetchUserDetail(userId: userId)
            .subscribe(
                onSuccess: { [weak self] user in
                    self?.user.accept(user)
                    self?.isLoading.accept(false)
                },
                onFailure: { [weak self] error in
                    self?.errorMessage.accept(error.localizedDescription)
                    self?.isLoading.accept(false)
                }
            )
            .disposed(by: disposeBag)
    }
}

