//
//  CodableViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/4/1.
//

import UIKit

class CodableViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Coding"
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        baseUse()
        advanceUse()
    }
    
}


extension CodableViewController{
    func baseUse() -> Void {
        /// Codable 协议 https://juejin.cn/post/6971997599725256734
        struct Person: Codable {
            let firstName: String
            let age: Int
            var additionInfo: String?
            
            enum CodingKeys: String, CodingKey {
                case firstName
                case age
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                firstName = try container.decode(String.self, forKey: .firstName)

                do {
                    age = try container.decode(Int.self, forKey: .age)
                } catch {
                    age = 20
                }
            }
            
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(firstName, forKey: .firstName)
                try container.encode(age, forKey: .age)
            }
        }
        
        
        //解码 JSON 数据
        let json = #" {"firstName":"Tom", "age": 120} "#
//        let json = #" {"firstName":"Tom", "age": "100"} "#

        let jsonData = json.data(using: .utf8)!

        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(Person.self, from: jsonData)
            print("解码成功：\(user)")
        } catch let DecodingError.dataCorrupted(context) {
            print("数据损坏：\(context.debugDescription)")
        } catch let DecodingError.keyNotFound(key, context) {
            print("缺少键 '\(key.stringValue)'：\(context.debugDescription)")
        } catch let DecodingError.typeMismatch(type, context) {
            print("类型不匹配 '\(type)'：\(context.debugDescription)")
        } catch let DecodingError.valueNotFound(value, context) {
            print("缺少值 '\(value)'：\(context.debugDescription)")
        } catch {
            print("其他错误：\(error)")
        }
        

        //编码导出为 JSON 数据
//        let data0 = try? JSONEncoder().encode(person)
//        let dataObject = try? JSONSerialization.jsonObject(with: data0!, options: [])
//        print(dataObject ?? "nil") // { age = 2; name = Tom; }
//
//        let data1 = try? JSONSerialization.data(withJSONObject: ["name": person!.firstName, "age": person!.age], options: [])
//        print(String(data: data1!, encoding: .utf8)!) //{"name":"Tom","age":2}

    }
    
    func advanceUse() ->Void {

        // MARK: - 用户模型
        struct User: Codable {
            let id: Int
            let name: String
            let email: String
        }

        // MARK: - 订单配送信息模型
        struct ShippingInfo: Codable {
            let address: String
            let city: String
            let zipcode: String
        }

        // MARK: - 订单模型
        struct Order: Codable {
            let orderId: Int
            let product: String
            let quantity: Int
            let price: Double
            let shipping: ShippingInfo
        }

        // MARK: - 用户订单的顶层模型
        struct UserOrder: Codable {
            let user: User
            let orders: [Order]
        }
        /**
         为什么 CodingKeys 需要遵守 String 和 CodingKey 协议？
         1. 遵守 CodingKey 协议的作用
         CodingKey 是一个 Swift 标准库提供的协议，用于表示编码和解码时使用的 key。遵守 CodingKey 协议让 CodingKeys 枚举能够被 Encoder 和 Decoder 使用。它定义了两个属性和一个初始化方法：
             stringValue：将 key 转换为 String 类型。对于大多数 JSON 数据来说，key 通常是字符串类型。
             intValue：将 key 转换为 Int 类型。虽然 JSON 的 key 通常是字符串，但 intValue 可以用于处理以整数为 key 的情况（例如数组的索引）。
             初始化方法 init?(stringValue:) 和 init?(intValue:)：用于根据 String 或 Int 值来创建 key。
         通过遵守 CodingKey 协议，CodingKeys 枚举可以被 Encoder 和 Decoder 识别，用于正确地进行编码和解码。
         
         
         2. 为什么要遵守 String 协议
         我们通常将 CodingKeys 枚举声明为遵守 String 协议：
         当 CodingKeys 遵守 String 协议时，每个枚举 case 会自动将 case 名称作为对应的字符串值（rawValue）。例如，case id 的 rawValue 就是 "id"。
         这使得我们无需手动为每个 case 提供字符串值，简化了代码
            
         
         简洁：使用 String, CodingKey 使得 CodingKeys 枚举更简洁，无需手动实现 stringValue 属性和 init?(stringValue:) 方法。
         自动映射：自动将枚举 case 名称映射为 JSON 字符串 key，减少了手动配置的出错几率。
         更易读：代码更简洁清晰，更符合 Swift 的惯用法。
         
         */
//        enum CodingKeys: String,CodingKey{
//            
//        }
        
        // 示例 JSON 字符串
        let jsonString = """
        {
            "user": {
                "id": 123,
                "name": "Alice",
                "email": "alice@example.com"
            },
            "myOrders": [
                {
                    "orderId": 1,
                    "product": "iPhone",
                    "quantity": 2,
                    "price": 999.99,
                    "shipping": {
                        "address": "123 Apple St",
                        "city": "Cupertino",
                        "zipcode": "95014"
                    }
                },
                {
                    "orderId": 2,
                    "product": "iPad",
                    "quantity": 1,
                    "price": 799.99,
                    "shipping": {
                        "address": "456 Peach Ave",
                        "city": "Sunnyvale",
                        "zipcode": "94086"
                    }
                }
            ]
        }
        """
        
        // 将 JSON 字符串转换为 Data
        guard let jsonData = jsonString.data(using: .utf8) else {
            print("JSON 字符串转换为 Data 失败")
            return
        }
        
        // 解码 JSON 为 Swift 数据模型
        do {
            let decoder = JSONDecoder()
            let userOrder = try decoder.decode(UserOrder.self, from: jsonData)
            
            print("解码成功！")
            print("用户 ID: \(userOrder.user.id)")
            print("用户名: \(userOrder.user.name)")
            print("用户邮箱: \(userOrder.user.email)")
            print("订单数: \(userOrder.orders.count)")
            
            for order in userOrder.orders {
                print("\n订单 ID: \(order.orderId)")
                print("产品: \(order.product)")
                print("数量: \(order.quantity)")
                print("价格: \(order.price)")
                print("配送地址: \(order.shipping.address), \(order.shipping.city) \(order.shipping.zipcode)")
            }
            
            // 重新编码为 JSON
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // 使输出的 JSON 美化（带缩进）
            let encodedData = try encoder.encode(userOrder)
            
            if let jsonString = String(data: encodedData, encoding: .utf8) {
                print("\n重新编码为 JSON:")
                print(jsonString)
            }
            
        } catch {
            print("解码失败: \(error)")
        }

    }
}
