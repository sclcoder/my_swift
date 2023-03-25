//
//  HomeViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/2/16.
//

import UIKit
import Moya
import Alamofire
import SnapKit

class HomeViewController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    let identifier = "ChatTableViewCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }
    
    
    func setupUI() -> Void {
        self.view.backgroundColor = .white
        self.title = "Home"

        let tableView = UITableView(frame: CGRectZero, style: .plain)
        tableView.backgroundColor = .white
        tableView.rowHeight = 60
    
        tableView.register(UINib.init(nibName: "ChatTableViewCell", bundle: Bundle.main), forCellReuseIdentifier: identifier)
        tableView.dataSource = self
        tableView.delegate = self
        
        
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    
    
    // MARK: API
    func makeRequest()->Void{
        print(Event.Name.login)
        AF.request("http://www.weather.com.cn/data/sk/101190408.html").responseJSON { response in
        print(response)
        }
    }

}


extension HomeViewController{
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier)
        else {
            return ChatTableViewCell()
        }
        return cell
    }
}


extension HomeViewController{
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(indexPath.row)
        let chatVC = ChatViewController()
        chatVC.sessionId = String(indexPath.row)
        self.navigationController?.pushViewController(chatVC, animated: true)
    }
}

