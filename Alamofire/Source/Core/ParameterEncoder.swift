//
//  ParameterEncoder.swift
//
//  Copyright (c) 2014-2018 Alamofire Software Foundation (http://alamofire.org/)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import Foundation

/**
  详解 Codable 的用法和原理  https://juejin.cn/post/7142499077417074696
  通过了解Codable的原理，理解以下设计
 */


/**
 alamofire中 ParameterEncoder 、 ParameterEncoding 两个类感觉做的工作重复了，为什么要这么设计?
 
 ChatGPT said:
 ChatGPT
 在 Alamofire 中，ParameterEncoder 和 ParameterEncoding 确实都与参数编码相关，但它们的设计初衷和应用场景有所不同。这种设计提供了更大的灵活性和向后兼容性，同时也适应了 Swift 语言和 Alamofire 框架的发展。

 ParameterEncoding
 用途: ParameterEncoding 是 Alamofire 早期版本中用来对请求参数进行编码的主要方式。它决定了如何将参数编码到请求中，比如编码到 URL 作为查询参数，或者编码到请求体中作为 JSON、表单等格式。
 
 类型:
 URLEncoding: 将参数编码为 URL 查询字符串，常用于 GET 请求。
 JSONEncoding: 将参数编码为 JSON 格式，通常用于 POST、PUT 等请求体。
 PropertyListEncoding: 将参数编码为 Plist 格式，较少使用。
 
 示例:
 swift
 Copy code
 let parameters: [String: Any] = ["foo": "bar"]
 let encoding: ParameterEncoding = JSONEncoding.default
 let request = try? URLRequest(url: "https://api.example.com", method: .post)
 let encodedRequest = try? encoding.encode(request, with: parameters)
 
 

 ParameterEncoder
 用途: ParameterEncoder 是在 Alamofire 5 中引入的一个新概念，提供了一种更现代化、更 Swifty 的编码方式。与 ParameterEncoding 类似，它也用于将参数编码到请求中，但它利用了 Swift 的 Encodable 协议，可以更方便地处理复杂的数据结构。

 类型:
 JSONParameterEncoder: 将符合 Encodable 协议的对象编码为 JSON 并添加到请求体中。
 URLEncodedFormParameterEncoder: 将参数编码为 URL 查询字符串，适用于 Encodable 对象。
 PropertyListParameterEncoder: 将参数编码为 Plist 格式。
 
 示例:
 swift
 Copy code
 struct MyParameters: Encodable {
     let foo: String
 }

 let parameters = MyParameters(foo: "bar")
 let encoder: ParameterEncoder = JSONParameterEncoder.default
 let request = try? URLRequest(url: "https://api.example.com", method: .post)
 let encodedRequest = try? encoder.encode(parameters, into: request)
 为什么同时存在这两个类？
 向后兼容性: ParameterEncoding 是 Alamofire 早期版本使用的编码机制，许多项目中已经大量使用了它。引入 ParameterEncoder 后，保留 ParameterEncoding 可以确保这些项目在升级到新版本 Alamofire 时不需要大量修改代码。

 
 功能区分:
 ParameterEncoding 主要面向简单的字典参数编码（[String: Any]），适用于简单的 API 请求。
 ParameterEncoder 则面向更加现代的 Encodable 数据结构，更加适合处理复杂的对象和数据类型。它利用了 Swift 的类型系统，避免了很多手动处理数据转换的麻烦。
 
 灵活性和扩展性:
 ParameterEncoder 允许开发者定义自己的编码器，基于 Encodable 协议定制参数的编码方式，这在处理复杂数据结构时非常有用。
 ParameterEncoding 则保持了简单和直接的优点，适用于那些无需复杂编码逻辑的场景。
 
 过渡到现代 Swift API:
 ParameterEncoder 是 Alamofire 向现代 Swift API 转变的标志，拥抱了 Swift 的类型安全特性和协议导向的设计。它提供了一种更 Swifty 的编码方式，减少了使用 Any 类型和手动类型转换的需求。
 
 */


/// A type that can encode any `Encodable` type into a `URLRequest`.
public protocol ParameterEncoder {
    /// Encode the provided `Encodable` parameters into `request`.
    ///
    /// - Parameters:
    ///   - parameters: The `Encodable` parameter value.
    ///   - request:    The `URLRequest` into which to encode the parameters.
    ///
    /// - Returns:      A `URLRequest` with the result of the encoding.
    /// - Throws:       An `Error` when encoding fails. For Alamofire provided encoders, this will be an instance of
    ///                 `AFError.parameterEncoderFailed` with an associated `ParameterEncoderFailureReason`.
    func encode<Parameters: Encodable>(_ parameters: Parameters?, into request: URLRequest) throws -> URLRequest
}

/// A `ParameterEncoder` that encodes types as JSON body data.
///
/// If no `Content-Type` header is already set on the provided `URLRequest`s, it's set to `application/json`.
open class JSONParameterEncoder: ParameterEncoder {
    /// Returns an encoder with default parameters.
    public static var `default`: JSONParameterEncoder { JSONParameterEncoder() }

    /// Returns an encoder with `JSONEncoder.outputFormatting` set to `.prettyPrinted`.
    public static var prettyPrinted: JSONParameterEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted

        return JSONParameterEncoder(encoder: encoder)
    }

    /// Returns an encoder with `JSONEncoder.outputFormatting` set to `.sortedKeys`.
    @available(macOS 10.13, iOS 11.0, tvOS 11.0, watchOS 4.0, *)
    public static var sortedKeys: JSONParameterEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys

        return JSONParameterEncoder(encoder: encoder)
    }

    /// `JSONEncoder` used to encode parameters.
    public let encoder: JSONEncoder

    /// Creates an instance with the provided `JSONEncoder`.
    ///
    /// - Parameter encoder: The `JSONEncoder`. `JSONEncoder()` by default.
    public init(encoder: JSONEncoder = JSONEncoder()) {
        self.encoder = encoder
    }

    open func encode<Parameters: Encodable>(_ parameters: Parameters?,
                                            into request: URLRequest) throws -> URLRequest {
        guard let parameters = parameters else { return request }

        var request = request

        do {
            let data = try encoder.encode(parameters)
            request.httpBody = data
            if request.headers["Content-Type"] == nil {
                request.headers.update(.contentType("application/json"))
            }
        } catch {
            throw AFError.parameterEncodingFailed(reason: .jsonEncodingFailed(error: error))
        }

        return request
    }
}

#if swift(>=5.5)
extension ParameterEncoder where Self == JSONParameterEncoder {
    /// Provides a default `JSONParameterEncoder` instance.
    public static var json: JSONParameterEncoder { JSONParameterEncoder() }

    /// Creates a `JSONParameterEncoder` using the provided `JSONEncoder`.
    ///
    /// - Parameter encoder: `JSONEncoder` used to encode parameters. `JSONEncoder()` by default.
    /// - Returns:           The `JSONParameterEncoder`.
    public static func json(encoder: JSONEncoder = JSONEncoder()) -> JSONParameterEncoder {
        JSONParameterEncoder(encoder: encoder)
    }
}
#endif

/// A `ParameterEncoder` that encodes types as URL-encoded query strings to be set on the URL or as body data, depending
/// on the `Destination` set.
///
/// If no `Content-Type` header is already set on the provided `URLRequest`s, it will be set to
/// `application/x-www-form-urlencoded; charset=utf-8`.
///
/// Encoding behavior can be customized by passing an instance of `URLEncodedFormEncoder` to the initializer.
open class URLEncodedFormParameterEncoder: ParameterEncoder {
    /// Defines where the URL-encoded string should be set for each `URLRequest`.
    public enum Destination {
        /// Applies the encoded query string to any existing query string for `.get`, `.head`, and `.delete` request.
        /// Sets it to the `httpBody` for all other methods.
        case methodDependent
        /// Applies the encoded query string to any existing query string from the `URLRequest`.
        case queryString
        /// Applies the encoded query string to the `httpBody` of the `URLRequest`.
        case httpBody

        /// Determines whether the URL-encoded string should be applied to the `URLRequest`'s `url`.
        ///
        /// - Parameter method: The `HTTPMethod`.
        ///
        /// - Returns:          Whether the URL-encoded string should be applied to a `URL`.
        func encodesParametersInURL(for method: HTTPMethod) -> Bool {
            switch self {
            case .methodDependent: return [.get, .head, .delete].contains(method)
            case .queryString: return true
            case .httpBody: return false
            }
        }
    }

    /// Returns an encoder with default parameters.
    public static var `default`: URLEncodedFormParameterEncoder { URLEncodedFormParameterEncoder() }

    /// The `URLEncodedFormEncoder` to use.
    public let encoder: URLEncodedFormEncoder

    /// The `Destination` for the URL-encoded string.
    public let destination: Destination

    /// Creates an instance with the provided `URLEncodedFormEncoder` instance and `Destination` value.
    ///
    /// - Parameters:
    ///   - encoder:     The `URLEncodedFormEncoder`. `URLEncodedFormEncoder()` by default.
    ///   - destination: The `Destination`. `.methodDependent` by default.
    public init(encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), destination: Destination = .methodDependent) {
        self.encoder = encoder
        self.destination = destination
    }

    open func encode<Parameters: Encodable>(_ parameters: Parameters?,
                                            into request: URLRequest) throws -> URLRequest {
        guard let parameters = parameters else { return request }

        var request = request

        guard let url = request.url else {
            /**
             在 Swift 中，如果枚举 case 需要初始化，但其关联值可以通过上下文推导出来，我们可以直接写出嵌套 case，而无需显式地创建实例
             
             Swift 会自动推导：
             .url 是 Component 类型的一个 case。
             .missingRequiredComponent(.url) 需要一个 Component 类型的值，Swift 知道 .url 属于 Component，所以推导出 missingRequiredComponent(.url) 是 ParameterEncoderFailureReason 类型的。
             .parameterEncoderFailed(reason: .missingRequiredComponent(.url)) 需要一个 ParameterEncoderFailureReason 类型的值，Swift 知道 missingRequiredComponent(.url) 已经是 ParameterEncoderFailureReason，所以最终推导出整个表达式是 AFError 类型的。
             因此，我们不需要手动创建实例，而是可以直接写出 .parameterEncoderFailed(reason: .missingRequiredComponent(.url))，Swift 会自动构造整个值
             
             如果我们手动创建实例，相当于写成：
             let error = AFError.parameterEncoderFailed(reason: ParameterEncoderFailureReason.missingRequiredComponent(Component.url))
             这种写法与前面的简写方式是完全等效的，Swift 允许我们省略冗余的类型名称。
             */
            throw AFError.parameterEncoderFailed(reason: .missingRequiredComponent(.url))
        }

        guard let method = request.method else {
            let rawValue = request.method?.rawValue ?? "nil"
            throw AFError.parameterEncoderFailed(reason: .missingRequiredComponent(.httpMethod(rawValue: rawValue)))
        }

        if destination.encodesParametersInURL(for: method),
           var components = URLComponents(url: url, resolvingAgainstBaseURL: false) {
            
            /**
             Result<String, Error> 的理解
             1.使用Result处理可能抛出错误的表达式 2.如果发生错误,转换错误类型 3.获取最终结果
             - Result<String, Error> 是一个 Swift Result 类型，它用于封装可能成功或失败的操作。
             - { try encoder.encode(parameters) } 这个闭包的返回值类型是 String，如果 try encoder.encode(parameters) 执行成功，Result 就会持有 .success(编码后的字符串)，否则会持有 .failure(错误).

             - 等价写法：
             let result: Result<String, Error>
             do {
                 let encoded = try encoder.encode(parameters)
                 result = .success(encoded)
             } catch {
                 result = .failure(error)
             }
             
             try Result<String, Error> { try encoder.encode(parameters) }
             本质上是 编译器的语法糖，等价于你提供的 do-catch 语句。Swift 编译器提供了一种 初始化 Result 的简洁方式，可以直接在 Result 的初始化闭包 {} 内部执行 try 代码，而不需要显式地写 do-catch 语句。
             { try encoder.encode(parameters) } 这个闭包会自动捕获 try 可能抛出的错误，并转换成 .failure(error)。
             本质上就是对 Result 进行封装，让 try 语句的失败自动转换成 Result.failure。
             
             
             mapError {} 是 Result 提供的一个方法，专门用于转换 Result 的错误（.failure）类型。
             这里的 $0 代表原始的 Error，它被转换为 AFError.parameterEncoderFailed(reason: .encoderFailed(error: $0))。
             作用：
             如果 Result 是 .success，mapError {} 不会做任何事，保持 .success(值).
             如果 Result 是 .failure(原始错误), 它会 将错误转换为 AFError 类型。
             
             get() 是 Result 提供的一个方法，它的作用是 获取 Result 中的成功值，如果 Result 是 .failure，则 会抛出错误。
             这里 get() 可能会抛出 AFError.parameterEncoderFailed(reason: .encoderFailed(error: 原始错误))。
             */
            
            let query: String = try Result<String, Error> { try encoder.encode(parameters) }
                .mapError { AFError.parameterEncoderFailed(reason: .encoderFailed(error: $0)) }.get()
            
            // compactMap { $0 } 作用是去除 nil 值，即过滤掉 percentEncodedQuery 为空的情况
            let newQueryString = [components.percentEncodedQuery, query].compactMap { $0 }.joinedWithAmpersands()
            
            components.percentEncodedQuery = newQueryString.isEmpty ? nil : newQueryString

            guard let newURL = components.url else {
                throw AFError.parameterEncoderFailed(reason: .missingRequiredComponent(.url))
            }

            request.url = newURL
        } else {
            if request.headers["Content-Type"] == nil {
                request.headers.update(.contentType("application/x-www-form-urlencoded; charset=utf-8"))
            }

            request.httpBody = try Result<Data, Error> { try encoder.encode(parameters) }
                .mapError { AFError.parameterEncoderFailed(reason: .encoderFailed(error: $0)) }.get()
        }

        return request
    }
}

#if swift(>=5.5)
extension ParameterEncoder where Self == URLEncodedFormParameterEncoder {
    /// Provides a default `URLEncodedFormParameterEncoder` instance.
    public static var urlEncodedForm: URLEncodedFormParameterEncoder { URLEncodedFormParameterEncoder() }

    /// Creates a `URLEncodedFormParameterEncoder` with the provided encoder and destination.
    ///
    /// - Parameters:
    ///   - encoder:     `URLEncodedFormEncoder` used to encode the parameters. `URLEncodedFormEncoder()` by default.
    ///   - destination: `Destination` to which to encode the parameters. `.methodDependent` by default.
    /// - Returns:       The `URLEncodedFormParameterEncoder`.
    public static func urlEncodedForm(encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(),
                                      destination: URLEncodedFormParameterEncoder.Destination = .methodDependent) -> URLEncodedFormParameterEncoder {
        URLEncodedFormParameterEncoder(encoder: encoder, destination: destination)
    }
}
#endif
