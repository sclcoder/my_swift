import Foundation

/// Represents the status codes to validate through Alamofire.
public enum ValidationType {

    /// No validation.
    case none

    /// Validate success codes (only 2xx).
    case successCodes

    /// Validate success codes and redirection codes (only 2xx and 3xx).
    case successAndRedirectCodes

    /**
     关联值 https://gitbook.swiftgg.team/swift/swift-jiao-cheng/08_enumerations#associated-values
     - 可以定义 Swift 枚举来存储任意类型的关联值，如果需要的话，每个枚举成员的关联值类型可以各不相同。
     - 枚举的这种特性跟其他语言中的可识别联合（discriminated unions），标签联合（tagged unions），或者变体（variants）相似。
    
     
     原始值和关联值是不同的。
     - 原始值是在定义枚举时被预先填充的值，对于一个特定的枚举成员，它的原始值始终不变。关联值是创建一个基于枚举成员的常量或变量时才设置的值，枚举成员的关联值可以变化。
     
     */
    /// Validate only the given status codes.
    case customCodes([Int])

    /// The list of HTTP status codes to validate.
    var statusCodes: [Int] {
        switch self {
        case .successCodes:
            return Array(200..<300)
        case .successAndRedirectCodes:
            return Array(200..<400)
        case .customCodes(let codes): /// 联值可以被提取出来作为 switch 语句的一部分。你可以在 switch 的 case 分支代码中提取每个关联值作为一个常量（用 let 前缀）或者作为一个变量（用 var 前缀）来使用
            return codes
        case .none:
            return []
        }
    }
}

/**
    通过扩展实现协议: 你可以为枚举、结构体或类添加新功能，并让它们遵循特定协议，如 Equatable。
    **元组和模式匹配: switch 语句结合元组和模式匹配，可以非常直观和简洁地比较多个枚举值。**
    **关联值匹配: 你可以在 switch 语句中匹配枚举的关联值，并使用它们进行进一步比较。**
 */
extension ValidationType: Equatable {

    public static func == (lhs: ValidationType, rhs: ValidationType) -> Bool {
        /**
        GPT的语法解析
         
         元组 (Tuple): (lhs, rhs) 是一个由两个 ValidationType 枚举实例组成的元组。你可以将多个值组合成一个元组，然后在 switch 语句中对其进行模式匹配。

         Switch 语句:

         多模式匹配: case (.none, .none), (.successCodes, .successCodes), (.successAndRedirectCodes, .successAndRedirectCodes) 这部分代码表示，如果 lhs 和 rhs 都是相同的特定枚举值 (.none, .successCodes, .successAndRedirectCodes)，那么返回 true，表示它们相等。

         绑定和比较: case (.customCodes(let code1), .customCodes(let code2)): 这部分代码表示，如果 lhs 和 rhs 都是 .customCodes，那么从中提取出关联值 code1 和 code2，然后比较它们是否相等。

         默认情况: default: 表示如果上述所有情况都不匹配，则返回 false，表示两个枚举值不相等。

         模式匹配
         关联值匹配: 枚举 ValidationType 的某些情况可能带有关联值，例如 .customCodes(let code1)。在这种情况下，switch 语句不仅匹配枚举的具体情况，还可以解包并比较其关联值。
         */
        switch (lhs, rhs) { // 元组和模式匹配: switch 语句结合元组和模式匹配，可以非常直观和简洁地比较多个枚举值
        case (.none, .none),
             (.successCodes, .successCodes),
             (.successAndRedirectCodes, .successAndRedirectCodes):
            return true
        case (.customCodes(let code1), .customCodes(let code2)): // 关联值匹配: 你可以在 switch 语句中匹配枚举的关联值，并使用它们进行进一步比较。
            return code1 == code2
        default:
            return false
        }
    }
}
