//
//  CodableViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/4/1.
//

import UIKit

class CodableViewController: UIViewController {
    /// Codable 协议 https://juejin.cn/post/6971997599725256734
    
    struct Person: Codable {
//        let name: String
        let firstName: String
        let age: Int
        var additionInfo: String?
        
        enum CodingKeys: String, CodingKey {
//            case name
            case firstName
            case age
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
//            name = try values.decode(String.self, forKey: .name)
            firstName = try values.decode(String.self, forKey: .firstName)
            age = try values.decode(Int.self, forKey: .age)
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
//            try container.encode(name, forKey: .name)
            try container.encode(firstName, forKey: .firstName)
            try container.encode(age, forKey: .age)
        }
    }

    
    
    

    @IBAction func testCoding() {
        //解码 JSON 数据
        let json = #" {"first_name":"Tom", "age": 2} "#
        
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let person = try? decoder.decode(Person.self, from: json.data(using: .utf8)!)
        print(person!)


        //编码导出为 JSON 数据
        let data0 = try? JSONEncoder().encode(person)
        let dataObject = try? JSONSerialization.jsonObject(with: data0!, options: [])
        print(dataObject ?? "nil") // { age = 2; name = Tom; }

        let data1 = try? JSONSerialization.data(withJSONObject: ["name": person!.firstName, "age": person!.age], options: [])
        print(String(data: data1!, encoding: .utf8)!) //{"name":"Tom","age":2}
    }
}





extension CodableViewController{
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Coding"
    }
}
