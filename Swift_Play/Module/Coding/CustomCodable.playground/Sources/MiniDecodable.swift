//
//  CustomDecodable.swift
//  my_swift
//
//  Created by Tiny Sun (Lofty Team) on 2025/4/11.
//

import Foundation

/// ⚠️ 注意加 public，Playground 中 Sources 里的类型默认是 internal，对主页面不可见，除非加 public。
/// 🔐 记住：public 是关键，Playground 的主页面访问不到 internal 作用域的类型。

/**
 MiniDecodable    模拟 Decodable 协议，模型对象 conform 它来参与解码
 MiniDecoder    负责提供解码环境和容器，模拟 Decoder 协议
 KeyedContainer<Key>    模拟 KeyedDecodingContainer，用于从字典中读取值
 decode(_:from:)    入口函数，开始解码流程
 */


public protocol MiniDecodable {
    init(from decoder: MiniDecoder) throws
}

// 🧱 2. 进入 decode(_:from:)
public func decode<T: MiniDecodable>(_ type: T.Type, from data: [String: Any]) throws -> T {
    let decoder = MiniDecoder(data: data) // ⬅️ 模拟 Decoder
    return try T(from: decoder)  // ⬅️ 触发 T 的 init(from:)
}


public class MiniDecoder {
    let data: [String: Any]
    
    public init(data: [String: Any]) {
        self.data = data
    }
    /**
     我们写的 MiniDecoder 其实是一个简化版的 Decoder，只是没有去显式实现 Decoder 协议

     Swift 标准库中：
     public protocol Decoder {
         var codingPath: [CodingKey] { get }
         var userInfo: [CodingUserInfoKey : Any] { get }
     
        // 标准库的 KeyedDecodingContainer，它们的本质都是包装了一层底层的「字典」结构，并提供了类型安全的 decode(_:forKey:) 接口，来按需取值。
         func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey
         func unkeyedContainer() throws -> UnkeyedDecodingContainer
         func singleValueContainer() throws -> SingleValueDecodingContainer
     }
     */
    
    /**
     keyedBy: Key.Type 是一个“类型”（Type）参数，而不是实例。
     
     🧠 解构它的含义
     这不是在传入一个具体的 Key 实例，而是在告诉编译器：“我要用哪一种 CodingKey 类型来解码这段数据。”
     所以参数 keyedBy 实际类型是 Key.Type，也就是说，它接收的是一个类型本身，而不是值
     例如 User.CodingKeys.self。这种形式在 Swift 中被称为“metatype 参数”。
     
     ✅ 为什么这么设计？
     这个设计有两个核心原因：
     范型类型推断：这个参数本身就决定了 Key 是什么类型。
     编译器通过这个参数知道：后续你 container.decode(..., forKey: .id) 中 .id 是哪个 enum 的 case。
     让 container 返回带 Key 泛型的容器：
     -> KeyedContainer<Key>
     它就能根据你提供的 CodingKeys 类型，构造出你专属的容器。
     
     🧩 和普通参数的区别
     普通参数传的是“值”，比如：func sayHello(name: String)
     
     ## keyedBy: Key.Type 的意思是「告诉我你要用哪个 CodingKey 类型来从字典中提取字段」，这是 Swift Decodable 设计中实现类型安全的关键方式之一。
     */
    // 🧱 4. 进入 container(keyedBy:)
    public func container<Key: CodingKey>(keyedBy: Key.Type) -> KeyedContainer<Key> {
        return KeyedContainer<Key>(data: data)
        // ⬅️ 本质是把字典包进去
        // data 是原始 [String: Any]
        // KeyedContainer 是我们模拟的 key-value 解析器
    }
}

public struct KeyedContainer<Key: CodingKey> {
    let data: [String: Any]

    public func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let value = data[key.stringValue] as? String else {
            throw DecodingError.keyNotFound(key, .init(codingPath: [], debugDescription: "Missing key"))
        }
        return value
    }

    public func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let value = data[key.stringValue] as? Int else {
            throw DecodingError.keyNotFound(key, .init(codingPath: [], debugDescription: "Missing key"))
        }
        return value
    }
}

/**
 ## CodingKey 是字段映射的中间人，让容器知道“我要从 JSON 的哪个字段里取出数据，赋值给模型中的哪个属性”。
 
 🎯 CodingKey协议的作用
 ✅ 提供 字段名 的类型安全表示，让 Swift 的解码器知道该从数据中取哪个字段。可以把它当作是「模型属性名 ↔ JSON 字段名」之间的桥梁。
 
 假设你要解码这个 JSON：
 {
   "user_id": 123,
   "username": "Alice"
 }
 
 你定义了模型：
 struct User: Decodable {
     let id: Int
     let name: String

     enum CodingKeys: String, CodingKey {
         case id = "user_id"
         case name = "username"
     }
 }
 
 👉 这个 CodingKeys 枚举 conform 了 CodingKey 协议，它有两个作用：

 1. 提供字段名的映射（默认就是属性名）
 key.stringValue → 你在 JSON 中的字段名
 
 key.stringValue for .id   ⟶ "user_id"
 key.stringValue for .name ⟶ "username"
 
 2. 参与 container 解析
 当你写：
 let container = try decoder.container(keyedBy: CodingKeys.self)
 就代表：我要从这个 container 中，按 CodingKeys 中定义的字段，来取值。
 
 🔍 CodingKey 协议长什么样？
 public protocol CodingKey {
     var stringValue: String { get }
     var intValue: Int? { get }

     init?(stringValue: String)
     init?(intValue: Int)
 }
 你可以自定义它，但 Swift 编译器通常会为你生成。

 🤖 自动合成 & 手动实现
 
 ✅ 自动合成
 如果你这样写：
 struct User: Decodable {
     let id: Int
     let name: String
 }
 Swift 会自动生成这个：
 enum CodingKeys: String, CodingKey {
     case id
     case name
 }
 也就是 stringValue == 属性名

 
 ✍️ 手动实现（自定义字段名）
 如果你想字段名不同，就手动实现：
 enum CodingKeys: String, CodingKey {
     case id = "user_id"
     case name = "username"
 }

 */


/** Decodable 的深入理解
 
 一、什么是 Decodable
 Decodable 是 Swift Codable 协议中的一部分，用于从外部数据（如 JSON）解码成 Swift 类型的实例。
 
 protocol Decodable {
     init(from decoder: Decoder) throws
 }
 
 🪜 二、初级使用方式：自动合成
 Swift 为符合 Decodable 的结构体提供了自动合成的能力，只要所有属性本身也都符合 Decodable。

 ✅ 示例：最基本的用法
 struct User: Decodable {
     let id: Int
     let name: String
 }

 let jsonData = """
 {
     "id": 1,
     "name": "Alice"
 }
 """.data(using: .utf8)!

 let user = try JSONDecoder().decode(User.self, from: jsonData)
 print(user.name)  // 输出 "Alice"
 
 注意事项
 JSON 字段名必须和结构体属性名完全匹配
 数据类型要匹配
 
 
 
 🔧 三、中级使用方式：自定义键名或结构
 ✅ 使用 CodingKeys 自定义映射
 
 struct User: Decodable {
     let id: Int
     let fullName: String

     enum CodingKeys: String, CodingKey {
         case id
         case fullName = "name"
     }
 }
 
 ✅ 解码嵌套结构

 struct User: Decodable {
     let id: Int
     let profile: Profile

     struct Profile: Decodable {
         let email: String
         let age: Int
     }
 }

 
 ✅ 解码数组
 let jsonArray = """
 [
     { "id": 1, "name": "Alice" },
     { "id": 2, "name": "Bob" }
 ]
 """.data(using: .utf8)!

 let users = try JSONDecoder().decode([User].self, from: jsonArray)
 
 
 🧠 四、高级使用方式：自定义 init(from:)
 当自动合成或 CodingKeys 无法满足需求时，可以手动实现解码逻辑
 
 struct User: Decodable {
     let id: Int
     let name: String
     let tags: [String]

     init(from decoder: Decoder) throws {
         let container = try decoder.container(keyedBy: CodingKeys.self)
         id = try container.decode(Int.self, forKey: .id)
         name = try container.decode(String.self, forKey: .name)

         // 支持 tags 是逗号分隔字符串
         let tagsString = try container.decode(String.self, forKey: .tags)
         tags = tagsString.components(separatedBy: ",")
     }

     enum CodingKeys: String, CodingKey {
         case id, name, tags
     }
 }
 
 ✅ 支持 Fallback 默认值 / 容错
 age = try container.decodeIfPresent(Int.self, forKey: .age) ?? 0

 
 🧬 五、深入理解：解码过程底层原理
 Swift 的 Decodable 解码是基于以下协议体系：

 1. Decoder 协议
 protocol Decoder {
     var codingPath: [CodingKey] { get }
     func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
     func unkeyedContainer() throws -> UnkeyedDecodingContainer
     func singleValueContainer() throws -> SingleValueDecodingContainer
 }
 
 KeyedDecodingContainer：解码字典
 UnkeyedDecodingContainer：解码数组
 SingleValueDecodingContainer：解码基本类型或单值结构
 
 2. JSONDecoder 是 Decoder 的具体实现
 你调用的 JSONDecoder().decode(User.self, from: data)，实际上做了以下几件事：
 创建 JSON 解析器（内部基于 Foundation 的 JSONSerialization）
 通过 Decoder 接口构建数据容器（Keyed/Unkeyed）
 调用 User.init(from:) 解码数据


 🔄 六、与 Codable 的关系
 typealias Codable = Decodable & Encodable
 所以如果你想同时支持编码（转成 JSON）和解码（从 JSON），使用 Codable 即可。

 七、常见问题
 1. 字段类型不匹配怎么办？
 手动实现 init(from:) 并做类型转换或 fallback。

 2. JSON 字段缺失？
 使用 decodeIfPresent，或者设置默认值。

 3. Date 格式不对？
 let decoder = JSONDecoder()
 decoder.dateDecodingStrategy = .iso8601
 
 🎓 八、小结
 层次    技巧或概念
 初级    自动合成 Decodable，字段匹配
 中级    CodingKeys、嵌套结构、数组
 高级    自定义 init(from:)，容错策略
 底层实现    解码协议：Decoder / Container
 实战注意点    Date 格式、默认值处理、类型转换
 
 */
