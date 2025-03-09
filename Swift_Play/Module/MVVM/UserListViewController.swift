//
//  UserListViewController.swift
//  my_swift
//
//  Created by tiny on 2025/3/9.
//

import UIKit
import RxSwift
import RxCocoa

class UserListViewController: UIViewController {
    private let tableView = UITableView()
    private let viewModel = UserListViewModel()
    private let disposeBag = DisposeBag()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.fetchUsers()
    }

    private func setupUI() {
        title = "MVVM"
        view.backgroundColor = .white

        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        view.addSubview(tableView)
        view.addSubview(loadingIndicator)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func setupBindings() {
        // 绑定用户列表数据
        viewModel.users
            .bind(to: tableView.rx.items(cellIdentifier: UserCell.identifier, cellType: UserCell.self)) { _, user, cell in
                cell.configure(with: user)
            }
            .disposed(by: disposeBag)
        
        
        // **新增：点击 Cell 跳转到详情页**
        tableView.rx.modelSelected(User.self)
          .subscribe(onNext: { [weak self] user in
              let detailVC = UserDetailViewController(userId: user.id)
              self?.navigationController?.pushViewController(detailVC, animated: true)
          })
          .disposed(by: disposeBag)

        // 绑定加载指示器
        viewModel.isLoading
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        // 绑定错误信息
        viewModel.errorMessage
            .subscribe(onNext: { [weak self] message in
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)

        // 绑定下拉刷新
        tableView.rx.contentOffset
            .filter { $0.y < -100 }
            .map { _ in }
            .bind(onNext: { [weak self] in self?.viewModel.fetchUsers() })
            .disposed(by: disposeBag)
    }
}

