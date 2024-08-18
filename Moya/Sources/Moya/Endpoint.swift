import Foundation
/**
 Endpoint 是 Moya 中一个核心的设计，它代表了一个网络请求的抽象，包括请求的 URL、HTTP 方法、头信息、参数等。Endpoint 的设计使得请求的配置更加灵活，同时也为自定义请求行为（如签名、加密等）提供了可能。

 核心概念
 Endpoint 的组成部分：

 url: 完整的请求 URL，由基础 URL 和路径组合而成。
 method: 请求的方法，比如 GET、POST、PUT、DELETE 等。
 task: 表示请求的任务类型，可以是请求参数（如 requestParameters）、文件上传（如 uploadMultipart）等。
 httpHeaderFields: 请求头信息的字典，用于设置请求的头信息。
 sampleResponseClosure: 一个闭包，用于提供模拟响应的数据。这通常在测试和调试时使用。
 Endpoint 的生成：

 Moya 的设计理念是每个 TargetType 实例（如你的 API 枚举的一个 case）都可以生成一个 Endpoint。在默认实现中，MoyaProvider 会根据 TargetType 的属性自动生成 Endpoint
 
 自定义 Endpoint：

 你可以通过覆写 endpointClosure 来自定义生成 Endpoint 的过程。这在你需要对所有请求统一添加签名、认证信息等时候非常有用。
 

 Endpoint 的灵活性：

 Endpoint 的设计使得每个请求都可以在生成阶段进行高度自定义。这种灵活性允许你对每个请求进行不同的处理，比如动态地更改 URL、请求参数、添加头信息等。
 
 Moya 中的 Endpoint 是对网络请求的一个高级抽象，提供了极大的灵活性和可定制性。通过自定义 Endpoint，你可以轻松地为每个请求添加特定的行为或配置，确保你的网络层能够适应各种需求。
 */
/// Used for stubbing responses.
public enum EndpointSampleResponse {

    /// The network returned a response, including status code and data.
    case networkResponse(Int, Data)

    /// The network returned response which can be fully customized.
    case response(HTTPURLResponse, Data)

    /// The network failed to send the request, or failed to retrieve a response (eg a timeout).
    case networkError(NSError)
}

/// Class for reifying a target of the `Target` enum unto a concrete `Endpoint`.
/// - Note: As of Moya 11.0.0 Endpoint is no longer generic.
///   Existing code should work as is after removing the generic.
///   See #1529 and #1524 for the discussion.
open class Endpoint {
    public typealias SampleResponseClosure = () -> EndpointSampleResponse

    /// A string representation of the URL for the request.
    public let url: String

    /// A closure responsible for returning an `EndpointSampleResponse`.
    public let sampleResponseClosure: SampleResponseClosure

    /// The HTTP method for the request.
    public let method: Moya.Method

    /// The `Task` for the request.
    public let task: Task

    /// The HTTP header fields for the request.
    public let httpHeaderFields: [String: String]?

    public init(url: String,
                sampleResponseClosure: @escaping SampleResponseClosure,
                method: Moya.Method,
                task: Task,
                httpHeaderFields: [String: String]?) {

        self.url = url
        self.sampleResponseClosure = sampleResponseClosure
        self.method = method
        self.task = task
        self.httpHeaderFields = httpHeaderFields
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with added HTTP header fields.
    open func adding(newHTTPHeaderFields: [String: String]) -> Endpoint {
        Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, task: task, httpHeaderFields: add(httpHeaderFields: newHTTPHeaderFields))
    }

    /// Convenience method for creating a new `Endpoint` with the same properties as the receiver, but with replaced `task` parameter.
    open func replacing(task: Task) -> Endpoint {
        Endpoint(url: url, sampleResponseClosure: sampleResponseClosure, method: method, task: task, httpHeaderFields: httpHeaderFields)
    }

    fileprivate func add(httpHeaderFields headers: [String: String]?) -> [String: String]? {
        guard let unwrappedHeaders = headers, unwrappedHeaders.isEmpty == false else {
            return self.httpHeaderFields
        }

        var newHTTPHeaderFields = self.httpHeaderFields ?? [:]
        unwrappedHeaders.forEach { key, value in
            newHTTPHeaderFields[key] = value
        }
        return newHTTPHeaderFields
    }
}

/// Extension for converting an `Endpoint` into a `URLRequest`.
public extension Endpoint {
    // swiftlint:disable cyclomatic_complexity
    /// Returns the `Endpoint` converted to a `URLRequest` if valid. Throws an error otherwise.
    func urlRequest() throws -> URLRequest {
        guard let requestURL = Foundation.URL(string: url) else {
            throw MoyaError.requestMapping(url)
        }

        var request = URLRequest(url: requestURL)
        request.httpMethod = method.rawValue
        request.allHTTPHeaderFields = httpHeaderFields

        switch task {
        case .requestPlain, .uploadFile, .uploadMultipart, .downloadDestination:
            return request
        case .requestData(let data):
            request.httpBody = data
            return request
        case let .requestJSONEncodable(encodable):
            return try request.encoded(encodable: encodable)
        case let .requestCustomJSONEncodable(encodable, encoder: encoder):
            return try request.encoded(encodable: encodable, encoder: encoder)
        case let .requestParameters(parameters, parameterEncoding):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .uploadCompositeMultipart(_, urlParameters):
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .downloadParameters(parameters, parameterEncoding, _):
            return try request.encoded(parameters: parameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeData(bodyData: bodyData, urlParameters: urlParameters):
            request.httpBody = bodyData
            let parameterEncoding = URLEncoding(destination: .queryString)
            return try request.encoded(parameters: urlParameters, parameterEncoding: parameterEncoding)
        case let .requestCompositeParameters(bodyParameters: bodyParameters, bodyEncoding: bodyParameterEncoding, urlParameters: urlParameters):
            if let bodyParameterEncoding = bodyParameterEncoding as? URLEncoding, bodyParameterEncoding.destination != .httpBody {
                fatalError("Only URLEncoding that `bodyEncoding` accepts is URLEncoding.httpBody. Others like `default`, `queryString` or `methodDependent` are prohibited - if you want to use them, add your parameters to `urlParameters` instead.")
            }
            let bodyfulRequest = try request.encoded(parameters: bodyParameters, parameterEncoding: bodyParameterEncoding)
            let urlEncoding = URLEncoding(destination: .queryString)
            return try bodyfulRequest.encoded(parameters: urlParameters, parameterEncoding: urlEncoding)
        }
    }
    // swiftlint:enable cyclomatic_complexity
}

/// Required for using `Endpoint` as a key type in a `Dictionary`.
extension Endpoint: Equatable, Hashable {
    public func hash(into hasher: inout Hasher) {
        switch task {
        case let .uploadFile(file):
            hasher.combine(file)
        case let .uploadMultipart(multipartData), let .uploadCompositeMultipart(multipartData, _):
            hasher.combine(multipartData)
        default:
            break
        }

        if let request = try? urlRequest() {
            hasher.combine(request)
        } else {
            hasher.combine(url)
        }
    }

    /// Note: If both Endpoints fail to produce a URLRequest the comparison will
    /// fall back to comparing each Endpoint's hashValue.
    public static func == (lhs: Endpoint, rhs: Endpoint) -> Bool {
        let areEndpointsEqualInAdditionalProperties: Bool = {
            switch (lhs.task, rhs.task) {
            case (let .uploadFile(file1), let .uploadFile(file2)):
                return file1 == file2
            case (let .uploadMultipart(multipartData1), let .uploadMultipart(multipartData2)),
                 (let .uploadCompositeMultipart(multipartData1, _), let .uploadCompositeMultipart(multipartData2, _)):
                return multipartData1 == multipartData2
            default:
                return true
            }
        }()
        let lhsRequest = try? lhs.urlRequest()
        let rhsRequest = try? rhs.urlRequest()
        if lhsRequest != nil, rhsRequest == nil { return false }
        if lhsRequest == nil, rhsRequest != nil { return false }
        if lhsRequest == nil, rhsRequest == nil { return lhs.hashValue == rhs.hashValue && areEndpointsEqualInAdditionalProperties }
        return lhsRequest == rhsRequest && areEndpointsEqualInAdditionalProperties
    }
}
