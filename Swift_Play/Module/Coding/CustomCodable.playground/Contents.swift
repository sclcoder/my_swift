import UIKit

// MARK: - 测试模型
struct User: MiniDecodable {
    let id: Int
    let name: String

    /**
     Q:CodingKeys 是如何遵守CodingKey协议的? 你可能会问：这个枚举只写了两行 case，看起来好像什么都没实现，它是怎么就自动 conform 了 CodingKey 协议的？
     
     A:✅ 答案：Swift 编译器为你自动合成了协议的实现！
     因为：你用 enum CodingKeys: String, CodingKey 明确指定了：原始类型是 String 、要遵守 CodingKey
     于是 Swift 能根据这些信息自动合成出 CodingKey 协议中所需的属性和初始化器
     
     等同于
     enum CodingKeys: String, CodingKey {
         case id
         case name
     
         // ✅ CodingKey 协议要求的属性
         var stringValue: String {
             return self.rawValue  // 也就是 "id" / "name"
         }
     
         var intValue: Int? {
             return nil // 因为我们没有使用 intValue，当 key 是字符串时通常返回 nil
         }

         // ✅ CodingKey 协议要求的初始化器
         init?(stringValue: String) {
             self.init(rawValue: stringValue) // 利用 enum 的 rawValue 初始化
         }

         init?(intValue: Int) {
             return nil // 我们不支持 Int key
         }
     }
     
     🤔 所以，什么时候不会自动合成？
     如果你没有用 String 或 Int 作为原始类型（或者用了复杂的 enum case ），Swift 就不会自动生成 CodingKey 实现，你就得自己实现 stringValue、intValue 等方法。
     
     条件    Swift 自动合成？
     枚举使用 String 或 Int 原始类型         ✅ 会合成
     所有 case 的 rawValue 唯一且明确        ✅ 会合成
     自定义 rawValue 或复杂 case            ❌ 可能需要手动实现
     */
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
    

    // 🧩 3. 进入模型的 init(from:)
    // 调用 MiniDecoder.container(keyedBy:)
    // 返回一个 KeyedContainer<CodingKeys>，可以从中读取值
    init(from decoder: MiniDecoder) throws {
        let container = decoder.container(keyedBy: CodingKeys.self) // 泛型的具体类型KeyedContainer<CodingKeys>
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
    }
}

// MARK: - 模拟 JSON 数据 + 解码测试
let json: [String: Any] = [
    "id": 123,
    "name": "Grace Hopper"
]

do {
    /**整体串起来像这样：
     decode(User.self, from: data)
       ⬇️
     let decoder = MiniDecoder(data: data)
       ⬇️
     T.init(from: decoder) → User.init(from:)
       ⬇️
     let container = decoder.container(keyedBy: CodingKeys.self)
       ⬇️
     container.decode(Int.self, forKey: .id)
       ⬇️
     从 data["id"] 中提取值并转成 Int
     */
    // 🟢 1. 从入口调用开始
    let user = try decode(User.self, from: json)
    print("✅ 解码成功: \(user.name), id: \(user.id)")
} catch {
    print("❌ 解码失败: \(error)")
}
