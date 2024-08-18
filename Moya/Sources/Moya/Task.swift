import Foundation
/**
 
 在 Moya 中，Task 是用来定义请求任务的一个关键概念。它描述了网络请求所包含的内容，比如请求参数、上传的文件、下载任务等。通过 Task，你可以灵活地指定每个网络请求的具体行为。

 Task 的类型
 Moya 提供了多种 Task 类型，分别适用于不同的网络请求需求：

 requestPlain

 代表一个没有任何参数的简单请求，通常用于 GET 请求或不需要请求体的请求。
 例如，获取用户信息的请求：
 swift
 Copy code
 .requestPlain
 requestData(Data)

 用于发送原始的二进制数据作为请求体。这种方式适合发送 JSON、XML 或其他自定义格式的数据。
 例如，发送 JSON 数据：
 swift
 Copy code
 .requestData(jsonData)
 requestJSONEncodable(Encodable)

 将一个 Swift 对象（符合 Encodable 协议）编码为 JSON 并作为请求体。这种方式简化了 JSON 数据的构建过程。
 例如，发送一个用户对象：
 swift
 Copy code
 struct User: Encodable {
     let id: Int
     let name: String
 }
 let user = User(id: 1, name: "John")
 .requestJSONEncodable(user)
 requestCustomJSONEncodable(Encodable, encoder: JSONEncoder)

 与 requestJSONEncodable 类似，但允许你使用自定义的 JSONEncoder 来编码对象。
 例如，使用自定义日期格式的 JSONEncoder：
 swift
 Copy code
 let encoder = JSONEncoder()
 encoder.dateEncodingStrategy = .iso8601
 .requestCustomJSONEncodable(user, encoder: encoder)
 requestParameters([String: Any], encoding: ParameterEncoding)

 用于发送参数的请求，你可以指定参数和编码方式（如 URL 编码、JSON 编码等）。这在需要发送表单数据或查询参数时非常常用。
 例如，发送查询参数：
 swift
 Copy code
 .requestParameters(["name": "John", "age": 30], encoding: URLEncoding.default)
 requestCompositeData(bodyData: Data, urlParameters: [String: Any])

 允许你同时发送二进制数据作为请求体，并在 URL 中附加查询参数。
 例如，上传文件并附带查询参数：
 swift
 Copy code
 .requestCompositeData(bodyData: fileData, urlParameters: ["id": 123])
 requestCompositeParameters(bodyParameters: [String: Any], bodyEncoding: ParameterEncoding, urlParameters: [String: Any])

 允许你同时指定请求体参数和 URL 参数，并为请求体参数选择编码方式。
 例如，发送表单数据并附加查询参数：
 swift
 Copy code
 .requestCompositeParameters(bodyParameters: ["name": "John"], bodyEncoding: JSONEncoding.default, urlParameters: ["id": 123])
 uploadFile(URL)

 表示一个文件上传任务，文件以 URL 的形式提供。
 例如，上传本地文件：
 swift
 Copy code
 .uploadFile(fileURL)
 uploadMultipart([MultipartFormData])

 表示一个多部分表单数据的上传任务，适用于上传文件和其他表单数据的组合请求。
 例如，上传图片和文本：
 swift
 Copy code
 let multipartData = MultipartFormData(provider: .data(imageData), name: "image", fileName: "image.jpg", mimeType: "image/jpeg")
 .uploadMultipart([multipartData])
 uploadCompositeMultipart([MultipartFormData], urlParameters: [String: Any])

 允许你上传多部分表单数据并附加 URL 参数。
 例如，上传文件并附加查询参数：
 swift
 Copy code
 .uploadCompositeMultipart([multipartData], urlParameters: ["id": 123])
 downloadDestination(DownloadDestination)

 表示一个下载任务，并指定文件下载到的位置。
 例如，下载文件到本地：
 swift
 Copy code
 .downloadDestination { temporaryURL, response in
     let destinationURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(response.suggestedFilename!)
     return (destinationURL, [.removePreviousFile, .createIntermediateDirectories])
 }
 downloadParameters([String: Any], encoding: ParameterEncoding, destination: DownloadDestination)

 允许你在下载任务中附加参数，并指定文件下载位置。
 例如，带参数的文件下载：
 swift
 Copy code
 .downloadParameters(["name": "file"], encoding: URLEncoding.default, destination: downloadDestination)
 适用场景
 GET 请求：通常使用 .requestPlain 或 .requestParameters 来发送不带请求体或带查询参数的请求。
 POST 请求：常见的使用场景包括 .requestData（发送 JSON 等数据）、.requestJSONEncodable（发送对象）以及 .requestParameters（发送表单数据）。
 文件上传：使用 .uploadFile 或 .uploadMultipart 来处理文件上传请求。
 文件下载：使用 .downloadDestination 或 .downloadParameters 来处理文件下载请求。
 总结
 Task 是 Moya 中定义网络请求内容的核心组件。通过不同类型的 Task，你可以轻松处理各种复杂的请求需求，从简单的 GET 请求到文件上传、下载任务，Task 提供了极大的灵活性和功能覆盖，使得 Moya 成为处理网络请求的强大工具。
 
 
 
 */
/// Represents an HTTP task.
public enum Task {

    /// A request with no additional data.
    case requestPlain

    /// A requests body set with data.
    case requestData(Data)

    /// A request body set with `Encodable` type
    case requestJSONEncodable(Encodable)

    /// A request body set with `Encodable` type and custom encoder
    case requestCustomJSONEncodable(Encodable, encoder: JSONEncoder)

    /// A requests body set with encoded parameters.
    case requestParameters(parameters: [String: Any], encoding: ParameterEncoding)

    /// A requests body set with data, combined with url parameters.
    case requestCompositeData(bodyData: Data, urlParameters: [String: Any])

    /// A requests body set with encoded parameters combined with url parameters.
    case requestCompositeParameters(bodyParameters: [String: Any], bodyEncoding: ParameterEncoding, urlParameters: [String: Any])

    /// A file upload task.
    case uploadFile(URL)

    /// A "multipart/form-data" upload task.
    case uploadMultipart([MultipartFormData])

    /// A "multipart/form-data" upload task  combined with url parameters.
    case uploadCompositeMultipart([MultipartFormData], urlParameters: [String: Any])

    /// A file download task to a destination.
    case downloadDestination(DownloadDestination)

    /// A file download task to a destination with extra parameters using the given encoding.
    case downloadParameters(parameters: [String: Any], encoding: ParameterEncoding, destination: DownloadDestination)
}

/**
 
 在 Moya 中，Endpoint 和 Task 都与网络请求相关，但它们扮演不同的角色，分别处理请求的不同方面。这种设计的核心目的是分离职责，从而提供更大的灵活性和可扩展性。

 Endpoint 和 Task 的职责
 Endpoint:

 请求的全局配置：Endpoint 主要用于描述网络请求的整体信息，包括 URL、HTTP 方法、请求头、以及可能的模拟响应数据等。
 请求的抽象表示：Endpoint 是对一个请求的抽象表示，可以包含所有影响请求的全局配置。它决定了请求的基本结构和行为，但不处理具体的请求内容。
 灵活性：Endpoint 的设计允许开发者在全局层面上自定义请求行为，比如添加通用的认证信息、修改请求的基础 URL 等。
 Task:

 请求的具体内容：Task 则专注于定义请求的具体内容，如请求的参数、上传的文件、下载的目标位置等。它描述了一个请求所需的实际数据和任务类型。
 任务的分类和执行：Task 的不同类型如 .requestPlain、.requestData、.uploadFile 等，明确了请求的目的和内容，比如这是一个简单的 GET 请求还是一个文件上传任务。
 细粒度控制：通过 Task，你可以精细地控制每个请求的具体执行方式和传递的数据，从而适应各种不同的请求场景。
 这种设计的优点
 分离关注点：

 Endpoint 和 Task 各自处理请求的不同方面，使得请求的配置和请求的内容可以独立定义和修改。这种分离使得代码更加清晰、模块化，易于维护。
 增强灵活性：

 通过分离 Endpoint 和 Task，Moya 允许你对每个请求的不同方面进行独立定制。例如，你可以在 Endpoint 中统一添加请求头信息，同时在 Task 中灵活配置不同请求的参数或数据。
 提高可扩展性：

 当你需要扩展或修改请求行为时，可以只修改 Endpoint 或 Task 的部分，而无需重写整个请求逻辑。例如，你可以通过自定义 Endpoint 来添加统一的认证逻辑，而不影响 Task 中定义的具体请求内容。
 支持复杂场景：

 在复杂的应用场景中，可能需要对同一个请求使用不同的配置（如不同的任务类型）。通过 Task 和 Endpoint 的分离，Moya 能够轻松处理这些情况。例如，你可以在同一个 Endpoint 下定义多个不同的 Task，分别用于处理数据请求、文件上传、文件下载等。
 总结
 Moya 中 Endpoint 和 Task 的设计遵循了单一职责原则，它们各自处理请求的不同层面，使得网络请求的配置和执行更加灵活和可控。Endpoint 负责请求的全局配置和抽象表示，而 Task 则专注于具体的请求内容和任务类型。这种分离使得代码更加模块化、易于维护，并且可以灵活应对各种复杂的网络请求场景。
 
 */
