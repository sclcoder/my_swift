import UIKit

// MARK: - 测试模型
struct User: MiniDecodable {
    let id: Int
    let name: String

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
