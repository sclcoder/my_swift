import Foundation

/// Represents a response to a `MoyaProvider.request`.
public final class Response: CustomDebugStringConvertible, Equatable {

    /// The status code of the response.
    public let statusCode: Int

    /// The response data.
    public let data: Data

    /// The original URLRequest for the response.
    public let request: URLRequest?

    /// The HTTPURLResponse object.
    public let response: HTTPURLResponse?

    public init(statusCode: Int, data: Data, request: URLRequest? = nil, response: HTTPURLResponse? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.request = request
        self.response = response
    }

    /// A text description of the `Response`.
    public var description: String {
        "Status Code: \(statusCode), Data Length: \(data.count)"
    }

    /// A text description of the `Response`. Suitable for debugging.
    public var debugDescription: String { description }

    public static func == (lhs: Response, rhs: Response) -> Bool {
        lhs.statusCode == rhs.statusCode
            && lhs.data == rhs.data
            && lhs.response == rhs.response
    }
}

public extension Response {

    /**
     Swift 标准库中的以下类型都符合 RangeExpression 协议：

     Range<Bound>：表示不包括上界的连续区间，例如 0..<10。
     ClosedRange<Bound>：表示包括上界的连续区间，例如 0...10。
     PartialRangeThrough<Bound>：表示从某个值起直到并包括某个上界的区间，例如 ...5。
     PartialRangeFrom<Bound>：表示从某个下界开始到无穷大的区间，例如 5...。
     PartialRangeUpTo<Bound>：表示从某个值起直到但不包括某个上界的区间，例如 ..<5。
     */
    
    
    /** 区间类型
     1.闭区间 (ClosedRange)
     语法: a...b
     类型: ClosedRange<T>
     
     2. 半开区间 (Range)
     语法: a..<b
     类型: Range<T>
     描述: 表示从 a 到 b 之间的所有值，包含 a 但不包含 b。
     
     
     单侧区间
    a. 起始区间 (PartialRangeFrom)
    语法: a...
    类型: PartialRangeFrom<T>
    描述: 表示从 a 到任意大（无限）的所有值，包含 a。
     
    b. 结束区间 (PartialRangeUpTo)
    语法: ..<b
    类型: PartialRangeUpTo<T>
    描述: 表示从起点到 b 之间的所有值，不包含 b。
     
    c. 结束区间（包含边界）(PartialRangeThrough)
     语法: ...b
     类型: PartialRangeThrough<T>
     描述: 表示从起点到 b 的所有值，包含 b。

     4. 范围表达式 (RangeExpression)
     类型: RangeExpression
     描述: RangeExpression 是一个协议，ClosedRange、Range、PartialRangeFrom、PartialRangeUpTo、PartialRangeThrough 都符合这个协议。这些范围表达式可以用来表示区间并在各种集合类型上使用，例如数组、字符串的切片等。
     
     
    
     总结
     ClosedRange<T>: 表示闭区间，包含起点和终点 (a...b)。
     Range<T>: 表示半开区间，包含起点，不包含终点 (a..<b)。
     PartialRangeFrom<T>: 从某个起点开始的区间，延伸到无穷大 (a...)。
     PartialRangeUpTo<T>: 到某个终点之前的区间 (..<b)。
     PartialRangeThrough<T>: 从起点到某个终点（包含终点）的区间 (...b)。
     */
    /**
     Returns the `Response` if the `statusCode` falls within the specified range.

     - parameters:
        - statusCodes: The range of acceptable status codes.
     - throws: `MoyaError.statusCode` when others are encountered.
    */
    func filter<R: RangeExpression>(statusCodes: R) throws -> Response where R.Bound == Int {
        guard statusCodes.contains(statusCode) else {
            throw MoyaError.statusCode(self)
        }
        return self
    }

    /**
     Returns the `Response` if it has the specified `statusCode`.

     - parameters:
        - statusCode: The acceptable status code.
     - throws: `MoyaError.statusCode` when others are encountered.
    */
    func filter(statusCode: Int) throws -> Response {
        try filter(statusCodes: statusCode...statusCode)
    }

    /**
     Returns the `Response` if the `statusCode` falls within the range 200 - 299.

     - throws: `MoyaError.statusCode` when others are encountered.
    */
    func filterSuccessfulStatusCodes() throws -> Response {
        try filter(statusCodes: 200...299)
    }

    /**
     Returns the `Response` if the `statusCode` falls within the range 200 - 399.

     - throws: `MoyaError.statusCode` when others are encountered.
    */
    func filterSuccessfulStatusAndRedirectCodes() throws -> Response {
        try filter(statusCodes: 200...399)
    }

    /// Maps data received from the signal into an Image.
    func mapImage() throws -> Image {
        guard let image = Image(data: data) else {
            throw MoyaError.imageMapping(self)
        }
        return image
    }

    /// Maps data received from the signal into a JSON object.
    ///
    /// - parameter failsOnEmptyData: A Boolean value determining
    /// whether the mapping should fail if the data is empty.
    func mapJSON(failsOnEmptyData: Bool = true) throws -> Any {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            if data.isEmpty && !failsOnEmptyData {
                return NSNull()
            }
            throw MoyaError.jsonMapping(self)
        }
    
        /**
         功能                        工具                        输入                   输出                          优点
         JSON 解码（弱类型）    JSONSerialization.jsonObject    JSON Data                Any（通常是 [String: Any]）    快速 & 老派，适合简单解析
         JSON 编码            JSONEncoder                     Swift 对象（Encodable）   JSON Data                     用于上传或缓存 JSON
         JSON 解码（强类型）    JSONDecoder                     JSON Data                Swift 对象（Decodable）        安全、类型明确
         */

    }

    /// Maps data received from the signal into a String.
    ///
    /// - parameter atKeyPath: Optional key path at which to parse string.
    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            // Key path was provided, try to parse string at key path
            guard let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
                /// “如果 keyPath 指向的值是 String，那就返回它；否则就报错。”
                    throw MoyaError.stringMapping(self)
            }
            return string
        } else {
            // Key path was not provided, parse entire response as string
            guard let string = String(data: data, encoding: .utf8) else {
                throw MoyaError.stringMapping(self)
            }
            return string
        }
    }

    /// Maps data received from the signal into a Decodable object.
    ///
    /// - parameter atKeyPath: Optional key path at which to parse object.
    /// - parameter using: A `JSONDecoder` instance which is used to decode data to an object.
    /// 将 Moya 响应 (Response) 的 JSON 数据，转换为某个 Decodable 类型的对象，支持从指定 keyPath 提取并解码。
    func map<D: Decodable>(_ type: D.Type,
                           atKeyPath keyPath: String? = nil,
                           using decoder: JSONDecoder = JSONDecoder(),
                           failsOnEmptyData: Bool = true) throws -> D {
        /**
         map(_:atKeyPath:using:failsOnEmptyData:)
         ├─ 有 keyPath？
         │   ├─ 有数据 → 取出 → 能序列化？
         │   │   ├─ 能 → 解码成目标类型
         │   │   └─ 否 → 包装 value → 解码 wrapper
         │   └─ 无数据 → 允许空就继续 → 否则抛错
         └─ 无 keyPath
             ├─ 直接解码 data
             └─ 空数据处理（根据参数决定）
         */
        
        
        
        /// 这个闭包的作用是：把 [String: Any]、[[String: Any]] 等 JSON 结构转成 Data，以便 JSONDecoder 去解码。
        let serializeToData: (Any) throws -> Data? = { (jsonObject) in
            guard JSONSerialization.isValidJSONObject(jsonObject) else {
                return nil
            }
            do {
                return try JSONSerialization.data(withJSONObject: jsonObject)
            } catch {
                throw MoyaError.jsonMapping(self)
            }
        }
        let jsonData: Data
        
        /**
         这是一个 标签（label），可以贴在 if、for、while、switch 等语句前面，用来给后面的 break keyPathCheck 指定“跳出的位置”
         语法形式    用途
         label: if { ... break label }    中途退出某个语句块
         label: while { ... break label }    跳出循环
         label: switch { ... break label }    从嵌套的 switch 中跳出
         */
        keyPathCheck: if let keyPath = keyPath {
            /// 先拿到 JSON 并用 NSDictionary 形式解析,再通过keyPath获取到的要转换的value
            guard let jsonObject = (try mapJSON(failsOnEmptyData: failsOnEmptyData) as? NSDictionary)?.value(forKeyPath: keyPath) else {
                /// 如果 keyPath 找不到，处理为空 or 抛错
                if failsOnEmptyData {
                    throw MoyaError.jsonMapping(self)
                } else {
                    /// 直接解码 data
                    jsonData = data
                    break keyPathCheck
                }
            }
            /// 将通过keyPath获取到的jsonObject转为JsonData
            /**
             这里进行try操作时，为什么没有进行catch
             try    发生错误时会抛出，必须配合 do-catch 使用。
             try?    发生错误时会返回 nil，不会抛出，需要你自己判断。
             try!    强制尝试，发生错误会 crash。通常不建议使用。
             if let val = try? xxx()    语法糖：尝试执行并绑定值，如果失败就进入 else，不会抛出异常。
             
             try 单独使用时 必须配合 do-catch。
             try + if let 或 try? 是一种 错误转可选类型 的方式，常用于处理可能失败但非致命的操作。
             */
            if let data = try serializeToData(jsonObject) {
                jsonData = data
            } else {
                /// 让 D 能在不符合 JSON 结构要求时（比如你 keyPath 拿到的是裸值或数组），通过包装成一个合法的嵌套结构 { "value": ... } 后再解码出来。
                /// 这是一种极高兼容性的解法，非常聪明，是 Moya 内部对 JSONDecoder 行为的一种“补丁式容错”。

                /// 如果不是合法 JSON 对象（比如是 "hello" 或 123），包装起来再解析：
                /// 如 let wrappedJsonObject = ["value": "hello"] ， wrappedJsonData 就是 {"value": "hello"} 的 JSON data
                let wrappedJsonObject = ["value": jsonObject]
                let wrappedJsonData: Data
                if let data = try serializeToData(wrappedJsonObject) {
                    wrappedJsonData = data
                } else {
                    throw MoyaError.jsonMapping(self)
                }
                do {
                    /**
                     如 传进去的 DecodableWrapper<String>.self 是一个具有如下结构的类型：
                     struct DecodableWrapper<String>: Decodable {
                         let value: String
                     }
                     JSON 内容是：{ "value": "hello" }
                     
                     这个 JSON 的结构正好匹配这个类型，所以：
                     Swift 的 JSONDecoder 会找到 "value" 这个 key,把 "hello" 当作 String 来解析
                     返回一个 DecodableWrapper(value: "hello") 对象. 最后 .value 拿到的就是 "hello" 这个 D 类型的值
                     */
                    return try decoder.decode(DecodableWrapper<D>.self, from: wrappedJsonData).value
                } catch let error {
                    throw MoyaError.objectMapping(error, self)
                }
            }
        } else {
            /// 如果是从keyPathCheck调过来的或者keyPath不存在，直接解码 data
            jsonData = data
        }
        
        do {
            /**
             尽可能智能地构造一个“合理的空对象”来避免崩溃，适配 Decodable 的两种典型使用方式（对象 vs 数组）
             
             尝试用 "{}" 解码成 D.self
             如果失败，再尝试用 "[{}]" 解码成 D.self
             如果还是失败，那就继续抛错
             */
            if jsonData.isEmpty && !failsOnEmptyData {
                if let emptyJSONObjectData = "{}".data(using: .utf8), let emptyDecodableValue = try? decoder.decode(D.self, from: emptyJSONObjectData) {
                    return emptyDecodableValue
                } else if let emptyJSONArrayData = "[{}]".data(using: .utf8), let emptyDecodableValue = try? decoder.decode(D.self, from: emptyJSONArrayData) {
                    return emptyDecodableValue
                }
            }
            return try decoder.decode(D.self, from: jsonData)
        } catch let error {
            throw MoyaError.objectMapping(error, self)
        }
    }
}

/// 🎯 这是个妙招: 为了支持 "value": <原始值> 的包装解析
private struct DecodableWrapper<T: Decodable>: Decodable {
    let value: T
}
