//
//  HomeViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/2/16.
//

import UIKit
import Moya
import Alamofire

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .systemBackground
        
        self.title = "Home"
        
        print(Event.Name.login)
        
        request1()
    }

}


func request1() -> Void {
        
    AF.request("http://www.weather.com.cn/data/sk/101190408.html").responseJSON { response in
        print(response)
    }
}
