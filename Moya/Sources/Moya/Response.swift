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
    }

    /// Maps data received from the signal into a String.
    ///
    /// - parameter atKeyPath: Optional key path at which to parse string.
    func mapString(atKeyPath keyPath: String? = nil) throws -> String {
        if let keyPath = keyPath {
            // Key path was provided, try to parse string at key path
            guard let jsonDictionary = try mapJSON() as? NSDictionary,
                let string = jsonDictionary.value(forKeyPath: keyPath) as? String else {
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
    func map<D: Decodable>(_ type: D.Type, atKeyPath keyPath: String? = nil, using decoder: JSONDecoder = JSONDecoder(), failsOnEmptyData: Bool = true) throws -> D {
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
        keyPathCheck: if let keyPath = keyPath {
            guard let jsonObject = (try mapJSON(failsOnEmptyData: failsOnEmptyData) as? NSDictionary)?.value(forKeyPath: keyPath) else {
                if failsOnEmptyData {
                    throw MoyaError.jsonMapping(self)
                } else {
                    jsonData = data
                    break keyPathCheck
                }
            }

            if let data = try serializeToData(jsonObject) {
                jsonData = data
            } else {
                let wrappedJsonObject = ["value": jsonObject]
                let wrappedJsonData: Data
                if let data = try serializeToData(wrappedJsonObject) {
                    wrappedJsonData = data
                } else {
                    throw MoyaError.jsonMapping(self)
                }
                do {
                    return try decoder.decode(DecodableWrapper<D>.self, from: wrappedJsonData).value
                } catch let error {
                    throw MoyaError.objectMapping(error, self)
                }
            }
        } else {
            jsonData = data
        }
        do {
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

private struct DecodableWrapper<T: Decodable>: Decodable {
    let value: T
}
