//
//  UserDetailViewController.swift
//  my_swift
//
//  Created by tiny on 2025/3/9.
//

import UIKit
import RxSwift
import RxCocoa

class UserDetailViewController: UIViewController {
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    private let viewModel = UserDetailViewModel()
    private let disposeBag = DisposeBag()
    
    private let userId: Int

    init(userId: Int) {
        self.userId = userId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.fetchUserDetail(userId: userId) // 触发获取用户详情
    }

    private func setupUI() {
        title = "User Detail"
        view.backgroundColor = .white

        nameLabel.font = UIFont.boldSystemFont(ofSize: 24)
        emailLabel.font = UIFont.systemFont(ofSize: 18)
        emailLabel.textColor = .gray

        let stackView = UIStackView(arrangedSubviews: [nameLabel, emailLabel])
        stackView.axis = .vertical
        stackView.spacing = 10

        view.addSubview(stackView)
        view.addSubview(loadingIndicator)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20)
        ])
    }

    private func setupBindings() {
        viewModel.user
            .compactMap { $0 } // 过滤空值
            .subscribe(onNext: { [weak self] user in
                self?.nameLabel.text = "Name: \(user.name)"
                self?.emailLabel.text = "Email: \(user.email)"
            })
            .disposed(by: disposeBag)

        viewModel.isLoading
            .bind(to: loadingIndicator.rx.isAnimating)
            .disposed(by: disposeBag)

        viewModel.errorMessage
            .subscribe(onNext: { [weak self] message in
                let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            })
            .disposed(by: disposeBag)
    }
}
