//
//  ChatViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/3/25.
//

import UIKit

class ChatViewController: UIViewController {
    
    var sessionId : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "Chat"
        
        self.view.backgroundColor = .red
    }
    

//    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        self.navigationController?.pushViewController(SettingViewController(), animated: true)
//    }
}
