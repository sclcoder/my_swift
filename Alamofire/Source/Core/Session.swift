//
//  Session.swift
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

/// `Session` creates and manages Alamofire's `Request` types during their lifetimes. It also provides common
/// functionality for all `Request`s, including queuing, interception, trust management, redirect handling, and response
/// cache handling.
open class Session {
    /**
     使用 `` 来定义和关键字重名的方法和属性 https://gitbook.swiftgg.team/swift/yu-yan-can-kao/02_lexical_structure#identifiers
     标识符（identifier） 可以由以下的字符开始：大写或小写的字母 A 到 Z、下划线（_）、基本多文种平面（Basic Multilingual Plane）中非字符数字组合的 Unicode 字符以及基本多文种平面以外的非个人专用区字符。在首字符之后，允许使用数字和组合 Unicode 字符。

     以下划线开头的标识视为内部标识符，即使声明了 public 访问级别。这个约定允许框架作者标记一部分不能被使用方调用或依赖的 API，即便因为某些限制原因导致它的声明必须是公开的。另外，双下划线开头的标识符是为 Swift 编译器和标准库预留的。

     使用保留字作为标识符，需要在其前后增加反引号（`）。例如，class 不是合法的标识符，但可以使用 `class`。反引号不属于标识符的一部分，`x` 和 x 表示同一标识符。

     闭包中如果没有明确指定参数名称，参数将被隐式命名为 $0、$1、$2 等等。这些命名在闭包作用域范围内是合法的标识符。

     编译器给含有属性包装器呈现值的属性自动合成以美元符号（$）开头的标识符。你的代码可以与这些标识符进行交互，，但是不能使用该前缀声明标识符。更详细的介绍，请查看 特性 章节中的 属性包装器 部分。
     */
    
    /// Shared singleton instance used by all `AF.request` APIs. Cannot be modified.
    public static let `default` = Session()

    /// Underlying `URLSession` used to create `URLSessionTasks` for this instance, and for which this instance's
    /// `delegate` handles `URLSessionDelegate` callbacks.
    ///
    /// - Note: This instance should **NOT** be used to interact with the underlying `URLSessionTask`s. Doing so will
    ///         break internal Alamofire logic that tracks those tasks.
    ///
    public let session: URLSession
    
    
    /// Instance's `SessionDelegate`, which handles the `URLSessionDelegate` methods and `Request` interaction.
    public let delegate: SessionDelegate
    
    
    /// Root `DispatchQueue` for all internal callbacks and state update. **MUST** be a serial queue.
    public let rootQueue: DispatchQueue
    
    
    /// Value determining whether this instance automatically calls `resume()` on all created `Request`s.
    public let startRequestsImmediately: Bool
    
    
    /// `DispatchQueue` on which `URLRequest`s are created asynchronously. By default this queue uses `rootQueue` as its
    /// `target`, but a separate queue can be used if request creation is determined to be a bottleneck. Always profile
    /// and test before introducing an additional queue.
    public let requestQueue: DispatchQueue
    
    
    /// `DispatchQueue` passed to all `Request`s on which they perform their response serialization. By default this
    /// queue uses `rootQueue` as its `target` but a separate queue can be used if response serialization is determined
    /// to be a bottleneck. Always profile and test before introducing an additional queue.
    public let serializationQueue: DispatchQueue
    
    
    /**
     `RequestInterceptor` 用于Session实例创建的所有 `Request`。 也可以在每个“Request”的基础上设置“RequestInterceptor”，在这种情况下，“Request”的拦截器优先于该值。
     */
    /// `RequestInterceptor` used for all `Request` created by the instance. `RequestInterceptor`s can also be set on a
    /// per-`Request` basis, in which case the `Request`'s interceptor takes precedence over this value.
    ///
    public let interceptor: RequestInterceptor?
    
    
    /// `ServerTrustManager` instance used to evaluate all trust challenges and provide certificate and key pinning.
    public let serverTrustManager: ServerTrustManager?
    
    /// `RedirectHandler` instance used to provide customization for request redirection.
    public let redirectHandler: RedirectHandler?
    
    /// `CachedResponseHandler` instance used to provide customization of cached response handling.
    public let cachedResponseHandler: CachedResponseHandler?
    
    /// `CompositeEventMonitor` used to compose Alamofire's `defaultEventMonitors` and any passed `EventMonitor`s.
    public let eventMonitor: CompositeEventMonitor
    
    /// `EventMonitor`s included in all instances. `[AlamofireNotifications()]` by default.
    public let defaultEventMonitors: [EventMonitor] = [AlamofireNotifications()]

    /// Internal map between `Request`s and any `URLSessionTasks` that may be in flight for them.
    var requestTaskMap = RequestTaskMap()
    
    /// `Set` of currently active `Request`s.
    var activeRequests: Set<Request> = []
    
    /// Completion events awaiting `URLSessionTaskMetrics`.
    var waitingCompletions: [URLSessionTask: () -> Void] = [:]

    
    
    /// Creates a `Session` from a `URLSession` and other parameters.
    ///
    /// - Note: When passing a `URLSession`, you must create the `URLSession` with a specific `delegateQueue` value and
    ///         pass the `delegateQueue`'s `underlyingQueue` as the `rootQueue` parameter of this initializer.
    ///
    /// - Parameters:
    ///   - session:                  Underlying `URLSession` for this instance.
    ///   - delegate:                 `SessionDelegate` that handles `session`'s delegate callbacks as well as `Request`
    ///                               interaction.
    ///   - rootQueue:                Root `DispatchQueue` for all internal callbacks and state updates. **MUST** be a
    ///                               serial queue.
    ///   - startRequestsImmediately: Determines whether this instance will automatically start all `Request`s. `true`
    ///                               by default. If set to `false`, all `Request`s created must have `.resume()` called.
    ///                               on them for them to start.
    ///   - requestQueue:             `DispatchQueue` on which to perform `URLRequest` creation. By default this queue
    ///                               will use the `rootQueue` as its `target`. A separate queue can be used if it's
    ///                               determined request creation is a bottleneck, but that should only be done after
    ///                               careful testing and profiling. `nil` by default.
    ///   - serializationQueue:       `DispatchQueue` on which to perform all response serialization. By default this
    ///                               queue will use the `rootQueue` as its `target`. A separate queue can be used if
    ///                               it's determined response serialization is a bottleneck, but that should only be
    ///                               done after careful testing and profiling. `nil` by default.
    ///   - interceptor:              `RequestInterceptor` to be used for all `Request`s created by this instance. `nil`
    ///                               by default.
    ///   - serverTrustManager:       `ServerTrustManager` to be used for all trust evaluations by this instance. `nil`
    ///                               by default.
    ///   - redirectHandler:          `RedirectHandler` to be used by all `Request`s created by this instance. `nil` by
    ///                               default.
    ///   - cachedResponseHandler:    `CachedResponseHandler` to be used by all `Request`s created by this instance.
    ///                               `nil` by default.
    ///   - eventMonitors:            Additional `EventMonitor`s used by the instance. Alamofire always adds a
    ///                               `AlamofireNotifications` `EventMonitor` to the array passed here. `[]` by default.

    /**
     -  DispatchQueue 是基于 Grand Central Dispatch (GCD) 的抽象，它提供了一个轻量级的、底层的接口来执行任务。你可以使用 DispatchQueue 来创建队列，并将任务提交到队列中执行，但是它没有提供诸如任务依赖、取消任务等高级功能。
     -  OperationQueue 则是基于 Operation 和 OperationQueue 的抽象，它提供了更高级别的接口来管理任务。你可以创建 Operation 对象来表示一个任务，并将这些任务添加到 OperationQueue 中。OperationQueue 提供了一些额外的功能，比如任务依赖、取消任务、调整最大并发数等。
     
     */
    /// 指定构造器:确保所有存储型属性都被初始化
    public init(session: URLSession,
                delegate: SessionDelegate,
                rootQueue: DispatchQueue,
                startRequestsImmediately: Bool = true,
                requestQueue: DispatchQueue? = nil,
                serializationQueue: DispatchQueue? = nil,
                interceptor: RequestInterceptor? = nil,
                serverTrustManager: ServerTrustManager? = nil,
                redirectHandler: RedirectHandler? = nil,
                cachedResponseHandler: CachedResponseHandler? = nil,
                eventMonitors: [EventMonitor] = []) {
        
        /// 断言
        precondition(session.configuration.identifier == nil,
                     "Alamofire does not support background URLSessionConfigurations.")
        
        /// 确保 session.delegateQueue.underlyingQueue 和 rootQueue 是同一个 GCD 队列，如果不匹配，则触发 precondition 断言，导致程序崩溃并输出错误信息。
        precondition(session.delegateQueue.underlyingQueue === rootQueue,
                     "Session(session:) initializer must be passed the DispatchQueue used as the delegateQueue's underlyingQueue as rootQueue.")

        self.session = session
        
        self.delegate = delegate
        
        /// 一个以DispatchQueue(label: "org.alamofire.session.rootQueue")为targetQueue的串行队列
        self.rootQueue = rootQueue
        
        self.startRequestsImmediately = startRequestsImmediately
        
        /// 一个以DispatchQueue(label: "org.alamofire.session.rootQueue")为targetQueue的串行队列
        self.requestQueue = requestQueue ?? DispatchQueue(label: "\(rootQueue.label).requestQueue", target: rootQueue)
        
        /// 一个以DispatchQueue(label: "org.alamofire.session.rootQueue")为targetQueue的串行队列
        self.serializationQueue = serializationQueue ?? DispatchQueue(label: "\(rootQueue.label).serializationQueue", target: rootQueue)
        
        //// Session级别的请求拦截器 - 默认是nil
        self.interceptor = interceptor
        
        self.serverTrustManager = serverTrustManager
        
        self.redirectHandler = redirectHandler
        
        self.cachedResponseHandler = cachedResponseHandler
        
        /// eventMonitor在此初始化 - 默认只有AlamofireNotifications这一个Monitor
        eventMonitor = CompositeEventMonitor(monitors: defaultEventMonitors + eventMonitors)
        
        delegate.eventMonitor = eventMonitor
        
        delegate.stateProvider = self
    }

    
    
    
    /// Creates a `Session` from a `URLSessionConfiguration`.
    ///
    /// - Note: This initializer lets Alamofire handle the creation of the underlying `URLSession` and its
    ///         `delegateQueue`, and is the recommended initializer for most uses.
    ///
    /// - Parameters:
    ///   - configuration:            `URLSessionConfiguration` to be used to create the underlying `URLSession`. Changes
    ///                               to this value after being passed to this initializer will have no effect.
    ///                               `URLSessionConfiguration.af.default` by default.
    ///   - delegate:                 `SessionDelegate` that handles `session`'s delegate callbacks as well as `Request`
    ///                               interaction. `SessionDelegate()` by default.
    ///   - rootQueue:                Root `DispatchQueue` for all internal callbacks and state updates. **MUST** be a
    ///                               serial queue. `DispatchQueue(label: "org.alamofire.session.rootQueue")` by default.
    ///   - startRequestsImmediately: Determines whether this instance will automatically start all `Request`s. `true`
    ///                               by default. If set to `false`, all `Request`s created must have `.resume()` called.
    ///                               on them for them to start.
    ///   - requestQueue:             `DispatchQueue` on which to perform `URLRequest` creation. By default this queue
    ///                               will use the `rootQueue` as its `target`. A separate queue can be used if it's
    ///                               determined request creation is a bottleneck, but that should only be done after
    ///                               careful testing and profiling. `nil` by default.
    ///   - serializationQueue:       `DispatchQueue` on which to perform all response serialization. By default this
    ///                               queue will use the `rootQueue` as its `target`. A separate queue can be used if
    ///                               it's determined response serialization is a bottleneck, but that should only be
    ///                               done after careful testing and profiling. `nil` by default.
    ///   - interceptor:              `RequestInterceptor` to be used for all `Request`s created by this instance. `nil`
    ///                               by default.
    ///   - serverTrustManager:       `ServerTrustManager` to be used for all trust evaluations by this instance. `nil`
    ///                               by default.
    ///   - redirectHandler:          `RedirectHandler` to be used by all `Request`s created by this instance. `nil` by
    ///                               default.
    ///   - cachedResponseHandler:    `CachedResponseHandler` to be used by all `Request`s created by this instance.
    ///                               `nil` by default.
    ///   - eventMonitors:            Additional `EventMonitor`s used by the instance. Alamofire always adds a
    ///                               `AlamofireNotifications` `EventMonitor` to the array passed here. `[]` by default.
    
    /// 便利构造器
    public convenience init(configuration: URLSessionConfiguration = URLSessionConfiguration.af.default,
                            delegate: SessionDelegate = SessionDelegate(),
                            rootQueue: DispatchQueue = DispatchQueue(label: "org.alamofire.session.rootQueue"),
                            startRequestsImmediately: Bool = true,
                            requestQueue: DispatchQueue? = nil,
                            serializationQueue: DispatchQueue? = nil,
                            interceptor: RequestInterceptor? = nil,
                            serverTrustManager: ServerTrustManager? = nil,
                            redirectHandler: RedirectHandler? = nil,
                            cachedResponseHandler: CachedResponseHandler? = nil,
                            eventMonitors: [EventMonitor] = []) {
        
        precondition(configuration.identifier == nil, "Alamofire does not support background URLSessionConfigurations.")

        /**
         ## Target Queue： https://juejin.cn/post/6844903588930519047#heading-0  、https://www.humancode.us/2014/08/14/target-queues.html
           - What does it mean for a queue to have a target queue?
           - It’s a little surprising, actually: each time an enqueued block becomes ready to execute, the queue will re-enqueue that block on the target queue for actual execution.
        
         ## DispatchQueue(label: rootQueue.label, target: rootQueue)的作用
         在 rootQueue 不是 DispatchQueue.main 的情况下，创建一个新的串行队列 (serialRootQueue)，但让它的 target 仍然是 rootQueue。这有助于控制任务的调度和执行顺序，同时继承 rootQueue 的 QoS 和执行环境。它不会独立管理自己的任务，而是把任务交给 rootQueue，从而保持与 rootQueue 统一的调度策略。
         
         serialRootQueue 本身是一个串行队列，但它的任务会被 rootQueue 处理。
         
         # 假如rootQueue 是并发队列的情况下，仍然确保某些任务按顺序执行。
         serialRootQueue 只是按顺序把任务交给 rootQueue，但 rootQueue 如何执行任务仍然是它自己的规则（即并发执行）。
         serialRootQueue 里面的任务 1 必须先被提交到 rootQueue，然后才能提交任务 2，以此类推。
         但是 rootQueue 仍然是并发的，它可能还在处理其他任务（比如任务 X、Y、Z），所以任务 1 在 rootQueue 里 可能会和其他任务并发执行
         但任务 2 仍然要等任务 1 提交完毕后才能进入 rootQueue。
         */
        
        // Retarget the incoming rootQueue for safety, unless it's the main queue, which we know is safe.
        let serialRootQueue = (rootQueue === DispatchQueue.main) ? rootQueue : DispatchQueue(label: rootQueue.label,
                                                                                             target: rootQueue)
        /**
         ## target 与 underlyingQueue 的区别
         属性    target（目标队列）                 underlyingQueue（底层队列）
         适用于   DispatchQueue                   OperationQueue
         作用    控制任务提交到哪个 DispatchQueue    允许 OperationQueue 共享一个 DispatchQueue
         影响    影响 QoS 继承、任务调度             主要用于 OperationQueue 与 DispatchQueue 结合
         
         target 主要用于 DispatchQueue，让多个队列共享同一个执行上下文。
         underlyingQueue主要用于OperationQueue，让OperationQueue在指定的GCD 队列上运行。
        
         ❌ 如果不设置 delegateQueue.underlyingQueue = rootQueue：
         delegateQueue 会创建自己的 DispatchQueue，导致 URLSessionDelegate 的回调不在 rootQueue 上执行。
         可能导致 任务执行顺序不一致，影响请求的管理和状态同步。
         可能导致 Alamofire 内部逻辑失效，因为 Alamofire 假设 delegateQueue 是 rootQueue 的子队列。
         
         ✅ 如果正确设置 underlyingQueue = rootQueue：
         保证 URLSessionDelegate 的回调在 rootQueue 上执行，防止任务乱序。
         保证 rootQueue 负责的请求任务和回调在同一个队列上，避免线程安全问题。
         确保 Alamofire 或其他网络库可以正确管理请求和回调的生命周期。
         */
        
        /// delegateQueue.是OperationQueue类型，其underlyingQueue 是 serialRootQueue，即Session.rootQueue,Session.rootQueue的真实值为serialRootQueue
        let delegateQueue = OperationQueue(maxConcurrentOperationCount: 1, underlyingQueue: serialRootQueue, name: "\(serialRootQueue.label).sessionDelegate")
        
        /**
         URLSession  的代理是 SessionDelegate。 SessionDelegate.stateProvider 是 Session。
         SessionDelegate中的request函数会通过 stateProvider（即Alamofire.Session类）的   func request(for task: URLSessionTask) -> Request? 函数找到 Request（Alamofire.Request类）,并且在适当的时机调用Request中的对应函数
         SessionDelegate 在URLSession回调里，会调用 Request的相应的函数
         */
        let session = URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue)

        /**
         requestQueue、serializationQueue的targetQueue都是rootQueue,这里的rootQueue实际是作为了后续队列的targetQueue,
         默认值是DispatchQueue(label: "org.alamofire.session.rootQueue")
         
         Session.rootQueue的真实值为serialRootQueue
         */
        self.init(session: session,
                  delegate: delegate,
                  rootQueue: serialRootQueue, /// 一个以DispatchQueue(label: "org.alamofire.session.rootQueue")为targetQueue的串行队列
                  startRequestsImmediately: startRequestsImmediately, /// 默认YES
                  requestQueue: requestQueue,
                  serializationQueue: serializationQueue,
                  interceptor: interceptor,
                  serverTrustManager: serverTrustManager,
                  redirectHandler: redirectHandler,
                  cachedResponseHandler: cachedResponseHandler,
                  eventMonitors: eventMonitors)
    }

    deinit {
        finishRequestsForDeinit()
        session.invalidateAndCancel()
    }

    // MARK: - All Requests API

    /// Perform an action on all active `Request`s.
    ///
    /// - Note: The provided `action` closure is performed asynchronously, meaning that some `Request`s may complete and
    ///         be unavailable by time it runs. Additionally, this action is performed on the instances's `rootQueue`,
    ///         so care should be taken that actions are fast. Once the work on the `Request`s is complete, any
    ///         additional work should be performed on another queue.
    ///
    /// - Parameters:
    ///   - action:     Closure to perform with all `Request`s.
    public func withAllRequests(perform action: @escaping (Set<Request>) -> Void) {
        rootQueue.async {
            action(self.activeRequests)
        }
    }

    /// Cancel all active `Request`s, optionally calling a completion handler when complete.
    ///
    /// - Note: This is an asynchronous operation and does not block the creation of future `Request`s. Cancelled
    ///         `Request`s may not cancel immediately due internal work, and may not cancel at all if they are close to
    ///         completion when cancelled.
    ///
    /// - Parameters:
    ///   - queue:      `DispatchQueue` on which the completion handler is run. `.main` by default.
    ///   - completion: Closure to be called when all `Request`s have been cancelled.
    public func cancelAllRequests(completingOnQueue queue: DispatchQueue = .main, completion: (() -> Void)? = nil) {
        withAllRequests { requests in
            requests.forEach { $0.cancel() }
            queue.async {
                completion?()
            }
        }
    }

    // MARK: - DataRequest

    /// Closure which provides a `URLRequest` for mutation.
    public typealias RequestModifier = (inout URLRequest) throws -> Void

    struct RequestConvertible: URLRequestConvertible {
        let url: URLConvertible
        let method: HTTPMethod
        let parameters: Parameters?
        let encoding: ParameterEncoding
        let headers: HTTPHeaders?
        let requestModifier: RequestModifier?

        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            
            // 在构建完URLRequest后，触发 1.requestModifier 2.encoding请求参数编码
            try requestModifier?(&request)
            return try encoding.encode(request, with: parameters)
        }
    }

    /// Creates a `DataRequest` from a `URLRequest` created using the passed components and a `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.get` by default.
    ///   - parameters:      `Parameters` (a.k.a. `[String: Any]`) value to be encoded into the `URLRequest`. `nil` by
    ///                      default.
    ///   - encoding:        `ParameterEncoding` to be used to encode the `parameters` value into the `URLRequest`.
    ///                      `URLEncoding.default` by default.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from the provided
    ///                      parameters. `nil` by default.
    ///
    /// - Returns:       The created `DataRequest`.
    open func request(_ convertible: URLConvertible,
                      method: HTTPMethod = .get,
                      parameters: Parameters? = nil,
                      encoding: ParameterEncoding = URLEncoding.default,
                      headers: HTTPHeaders? = nil,
                      interceptor: RequestInterceptor? = nil,
                      requestModifier: RequestModifier? = nil) -> DataRequest {
        let convertible = RequestConvertible(url: convertible,
                                             method: method,
                                             parameters: parameters,
                                             encoding: encoding,
                                             headers: headers,
                                             requestModifier: requestModifier)

        return request(convertible, interceptor: interceptor)
    }

    struct RequestEncodableConvertible<Parameters: Encodable>: URLRequestConvertible {
        let url: URLConvertible
        let method: HTTPMethod
        let parameters: Parameters?
        let encoder: ParameterEncoder
        let headers: HTTPHeaders?
        let requestModifier: RequestModifier?

        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            try requestModifier?(&request)

            return try parameters.map { try encoder.encode($0, into: request) } ?? request
        }
    }

    /// Creates a `DataRequest` from a `URLRequest` created using the passed components, `Encodable` parameters, and a
    /// `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.get` by default.
    ///   - parameters:      `Encodable` value to be encoded into the `URLRequest`. `nil` by default.
    ///   - encoder:         `ParameterEncoder` to be used to encode the `parameters` value into the `URLRequest`.
    ///                      `URLEncodedFormParameterEncoder.default` by default.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from
    ///                      the provided parameters. `nil` by default.
    ///
    /// - Returns:           The created `DataRequest`.
    open func request<Parameters: Encodable>(_ convertible: URLConvertible,
                                             method: HTTPMethod = .get,
                                             parameters: Parameters? = nil,
                                             encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
                                             headers: HTTPHeaders? = nil,
                                             interceptor: RequestInterceptor? = nil,
                                             requestModifier: RequestModifier? = nil) -> DataRequest {
        let convertible = RequestEncodableConvertible(url: convertible,
                                                      method: method,
                                                      parameters: parameters,
                                                      encoder: encoder,
                                                      headers: headers,
                                                      requestModifier: requestModifier)

        return request(convertible, interceptor: interceptor)
    }

    /// Creates a `DataRequest` from a `URLRequestConvertible` value and a `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible: `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - interceptor: `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///
    /// - Returns:       The created `DataRequest`.
    open func request(_ convertible: URLRequestConvertible, interceptor: RequestInterceptor? = nil) -> DataRequest {
        /// 注意：DataRequest的delegate是Session
        let request = DataRequest(convertible: convertible,
                                  underlyingQueue: rootQueue,
                                  serializationQueue: serializationQueue,
                                  eventMonitor: eventMonitor,
                                  interceptor: interceptor,
                                  delegate: self)
        /// 异步函数: 会立马返回
        perform(request)
        
        return request
    }

    // MARK: - DataStreamRequest

    /// Creates a `DataStreamRequest` from the passed components, `Encodable` parameters, and `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible:                      `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:                           `HTTPMethod` for the `URLRequest`. `.get` by default.
    ///   - parameters:                       `Encodable` value to be encoded into the `URLRequest`. `nil` by default.
    ///   - encoder:                          `ParameterEncoder` to be used to encode the `parameters` value into the
    ///                                       `URLRequest`.
    ///                                       `URLEncodedFormParameterEncoder.default` by default.
    ///   - headers:                          `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - automaticallyCancelOnStreamError: `Bool` indicating whether the instance should be canceled when an `Error`
    ///                                       is thrown while serializing stream `Data`. `false` by default.
    ///   - interceptor:                      `RequestInterceptor` value to be used by the returned `DataRequest`. `nil`
    ///                                       by default.
    ///   - requestModifier:                  `RequestModifier` which will be applied to the `URLRequest` created from
    ///                                       the provided parameters. `nil` by default.
    ///
    /// - Returns:       The created `DataStream` request.
    open func streamRequest<Parameters: Encodable>(_ convertible: URLConvertible,
                                                   method: HTTPMethod = .get,
                                                   parameters: Parameters? = nil,
                                                   encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
                                                   headers: HTTPHeaders? = nil,
                                                   automaticallyCancelOnStreamError: Bool = false,
                                                   interceptor: RequestInterceptor? = nil,
                                                   requestModifier: RequestModifier? = nil) -> DataStreamRequest {
        let convertible = RequestEncodableConvertible(url: convertible,
                                                      method: method,
                                                      parameters: parameters,
                                                      encoder: encoder,
                                                      headers: headers,
                                                      requestModifier: requestModifier)

        return streamRequest(convertible,
                             automaticallyCancelOnStreamError: automaticallyCancelOnStreamError,
                             interceptor: interceptor)
    }

    /// Creates a `DataStreamRequest` from the passed components and `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible:                      `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:                           `HTTPMethod` for the `URLRequest`. `.get` by default.
    ///   - headers:                          `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - automaticallyCancelOnStreamError: `Bool` indicating whether the instance should be canceled when an `Error`
    ///                                       is thrown while serializing stream `Data`. `false` by default.
    ///   - interceptor:                      `RequestInterceptor` value to be used by the returned `DataRequest`. `nil`
    ///                                       by default.
    ///   - requestModifier:                  `RequestModifier` which will be applied to the `URLRequest` created from
    ///                                       the provided parameters. `nil` by default.
    ///
    /// - Returns:       The created `DataStream` request.
    open func streamRequest(_ convertible: URLConvertible,
                            method: HTTPMethod = .get,
                            headers: HTTPHeaders? = nil,
                            automaticallyCancelOnStreamError: Bool = false,
                            interceptor: RequestInterceptor? = nil,
                            requestModifier: RequestModifier? = nil) -> DataStreamRequest {
        let convertible = RequestEncodableConvertible(url: convertible,
                                                      method: method,
                                                      parameters: Empty?.none,
                                                      encoder: URLEncodedFormParameterEncoder.default,
                                                      headers: headers,
                                                      requestModifier: requestModifier)

        return streamRequest(convertible,
                             automaticallyCancelOnStreamError: automaticallyCancelOnStreamError,
                             interceptor: interceptor)
    }

    /// Creates a `DataStreamRequest` from the passed `URLRequestConvertible` value and `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible:                      `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - automaticallyCancelOnStreamError: `Bool` indicating whether the instance should be canceled when an `Error`
    ///                                       is thrown while serializing stream `Data`. `false` by default.
    ///   - interceptor:                      `RequestInterceptor` value to be used by the returned `DataRequest`. `nil`
    ///                                        by default.
    ///
    /// - Returns:       The created `DataStreamRequest`.
    open func streamRequest(_ convertible: URLRequestConvertible,
                            automaticallyCancelOnStreamError: Bool = false,
                            interceptor: RequestInterceptor? = nil) -> DataStreamRequest {
        let request = DataStreamRequest(convertible: convertible,
                                        automaticallyCancelOnStreamError: automaticallyCancelOnStreamError,
                                        underlyingQueue: rootQueue,
                                        serializationQueue: serializationQueue,
                                        eventMonitor: eventMonitor,
                                        interceptor: interceptor,
                                        delegate: self)

        perform(request)

        return request
    }

    // MARK: - DownloadRequest

    /// Creates a `DownloadRequest` using a `URLRequest` created using the passed components, `RequestInterceptor`, and
    /// `Destination`.
    ///
    /// - Parameters:
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.get` by default.
    ///   - parameters:      `Parameters` (a.k.a. `[String: Any]`) value to be encoded into the `URLRequest`. `nil` by
    ///                      default.
    ///   - encoding:        `ParameterEncoding` to be used to encode the `parameters` value into the `URLRequest`.
    ///                      Defaults to `URLEncoding.default`.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from the provided
    ///                      parameters. `nil` by default.
    ///   - destination:     `DownloadRequest.Destination` closure used to determine how and where the downloaded file
    ///                      should be moved. `nil` by default.
    ///
    /// - Returns:           The created `DownloadRequest`.
    open func download(_ convertible: URLConvertible,
                       method: HTTPMethod = .get,
                       parameters: Parameters? = nil,
                       encoding: ParameterEncoding = URLEncoding.default,
                       headers: HTTPHeaders? = nil,
                       interceptor: RequestInterceptor? = nil,
                       requestModifier: RequestModifier? = nil,
                       to destination: DownloadRequest.Destination? = nil) -> DownloadRequest {
        let convertible = RequestConvertible(url: convertible,
                                             method: method,
                                             parameters: parameters,
                                             encoding: encoding,
                                             headers: headers,
                                             requestModifier: requestModifier)

        return download(convertible, interceptor: interceptor, to: destination)
    }

    /// Creates a `DownloadRequest` from a `URLRequest` created using the passed components, `Encodable` parameters, and
    /// a `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.get` by default.
    ///   - parameters:      Value conforming to `Encodable` to be encoded into the `URLRequest`. `nil` by default.
    ///   - encoder:         `ParameterEncoder` to be used to encode the `parameters` value into the `URLRequest`.
    ///                      Defaults to `URLEncodedFormParameterEncoder.default`.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from the provided
    ///                      parameters. `nil` by default.
    ///   - destination:     `DownloadRequest.Destination` closure used to determine how and where the downloaded file
    ///                      should be moved. `nil` by default.
    ///
    /// - Returns:           The created `DownloadRequest`.
    open func download<Parameters: Encodable>(_ convertible: URLConvertible,
                                              method: HTTPMethod = .get,
                                              parameters: Parameters? = nil,
                                              encoder: ParameterEncoder = URLEncodedFormParameterEncoder.default,
                                              headers: HTTPHeaders? = nil,
                                              interceptor: RequestInterceptor? = nil,
                                              requestModifier: RequestModifier? = nil,
                                              to destination: DownloadRequest.Destination? = nil) -> DownloadRequest {
        let convertible = RequestEncodableConvertible(url: convertible,
                                                      method: method,
                                                      parameters: parameters,
                                                      encoder: encoder,
                                                      headers: headers,
                                                      requestModifier: requestModifier)

        return download(convertible, interceptor: interceptor, to: destination)
    }

    /// Creates a `DownloadRequest` from a `URLRequestConvertible` value, a `RequestInterceptor`, and a `Destination`.
    ///
    /// - Parameters:
    ///   - convertible: `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - interceptor: `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - destination: `DownloadRequest.Destination` closure used to determine how and where the downloaded file
    ///                  should be moved. `nil` by default.
    ///
    /// - Returns:       The created `DownloadRequest`.
    open func download(_ convertible: URLRequestConvertible,
                       interceptor: RequestInterceptor? = nil,
                       to destination: DownloadRequest.Destination? = nil) -> DownloadRequest {
        let request = DownloadRequest(downloadable: .request(convertible),
                                      underlyingQueue: rootQueue,
                                      serializationQueue: serializationQueue,
                                      eventMonitor: eventMonitor,
                                      interceptor: interceptor,
                                      delegate: self,
                                      destination: destination ?? DownloadRequest.defaultDestination)

        perform(request)

        return request
    }

    /// Creates a `DownloadRequest` from the `resumeData` produced from a previously cancelled `DownloadRequest`, as
    /// well as a `RequestInterceptor`, and a `Destination`.
    ///
    /// - Note: If `destination` is not specified, the download will be moved to a temporary location determined by
    ///         Alamofire. The file will not be deleted until the system purges the temporary files.
    ///
    /// - Note: On some versions of all Apple platforms (iOS 10 - 10.2, macOS 10.12 - 10.12.2, tvOS 10 - 10.1, watchOS 3 - 3.1.1),
    /// `resumeData` is broken on background URL session configurations. There's an underlying bug in the `resumeData`
    /// generation logic where the data is written incorrectly and will always fail to resume the download. For more
    /// information about the bug and possible workarounds, please refer to the [this Stack Overflow post](http://stackoverflow.com/a/39347461/1342462).
    ///
    /// - Parameters:
    ///   - data:        The resume data from a previously cancelled `DownloadRequest` or `URLSessionDownloadTask`.
    ///   - interceptor: `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - destination: `DownloadRequest.Destination` closure used to determine how and where the downloaded file
    ///                  should be moved. `nil` by default.
    ///
    /// - Returns:       The created `DownloadRequest`.
    open func download(resumingWith data: Data,
                       interceptor: RequestInterceptor? = nil,
                       to destination: DownloadRequest.Destination? = nil) -> DownloadRequest {
        let request = DownloadRequest(downloadable: .resumeData(data),
                                      underlyingQueue: rootQueue,
                                      serializationQueue: serializationQueue,
                                      eventMonitor: eventMonitor,
                                      interceptor: interceptor,
                                      delegate: self,
                                      destination: destination ?? DownloadRequest.defaultDestination)

        perform(request)

        return request
    }

    // MARK: - UploadRequest

    struct ParameterlessRequestConvertible: URLRequestConvertible {
        let url: URLConvertible
        let method: HTTPMethod
        let headers: HTTPHeaders?
        let requestModifier: RequestModifier?

        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            try requestModifier?(&request)

            return request
        }
    }

    struct Upload: UploadConvertible {
        let request: URLRequestConvertible
        let uploadable: UploadableConvertible

        func createUploadable() throws -> UploadRequest.Uploadable {
            try uploadable.createUploadable()
        }

        func asURLRequest() throws -> URLRequest {
            try request.asURLRequest()
        }
    }

    // MARK: Data

    /// Creates an `UploadRequest` for the given `Data`, `URLRequest` components, and `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - data:            The `Data` to upload.
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.post` by default.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager:     `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                      default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from the provided
    ///                      parameters. `nil` by default.
    ///
    /// - Returns:           The created `UploadRequest`.
    open func upload(_ data: Data,
                     to convertible: URLConvertible,
                     method: HTTPMethod = .post,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default,
                     requestModifier: RequestModifier? = nil) -> UploadRequest {
        let convertible = ParameterlessRequestConvertible(url: convertible,
                                                          method: method,
                                                          headers: headers,
                                                          requestModifier: requestModifier)

        return upload(data, with: convertible, interceptor: interceptor, fileManager: fileManager)
    }

    /// Creates an `UploadRequest` for the given `Data` using the `URLRequestConvertible` value and `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - data:        The `Data` to upload.
    ///   - convertible: `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - interceptor: `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager: `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                  default.
    ///
    /// - Returns:       The created `UploadRequest`.
    open func upload(_ data: Data,
                     with convertible: URLRequestConvertible,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default) -> UploadRequest {
        upload(.data(data), with: convertible, interceptor: interceptor, fileManager: fileManager)
    }

    // MARK: File

    /// Creates an `UploadRequest` for the file at the given file `URL`, using a `URLRequest` from the provided
    /// components and `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - fileURL:         The `URL` of the file to upload.
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.post` by default.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `UploadRequest`. `nil` by default.
    ///   - fileManager:     `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                      default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from the provided
    ///                      parameters. `nil` by default.
    ///
    /// - Returns:           The created `UploadRequest`.
    open func upload(_ fileURL: URL,
                     to convertible: URLConvertible,
                     method: HTTPMethod = .post,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default,
                     requestModifier: RequestModifier? = nil) -> UploadRequest {
        let convertible = ParameterlessRequestConvertible(url: convertible,
                                                          method: method,
                                                          headers: headers,
                                                          requestModifier: requestModifier)

        return upload(fileURL, with: convertible, interceptor: interceptor, fileManager: fileManager)
    }

    /// Creates an `UploadRequest` for the file at the given file `URL` using the `URLRequestConvertible` value and
    /// `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - fileURL:     The `URL` of the file to upload.
    ///   - convertible: `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - interceptor: `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager: `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                  default.
    ///
    /// - Returns:       The created `UploadRequest`.
    open func upload(_ fileURL: URL,
                     with convertible: URLRequestConvertible,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default) -> UploadRequest {
        upload(.file(fileURL, shouldRemove: false), with: convertible, interceptor: interceptor, fileManager: fileManager)
    }

    // MARK: InputStream

    /// Creates an `UploadRequest` from the `InputStream` provided using a `URLRequest` from the provided components and
    /// `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - stream:          The `InputStream` that provides the data to upload.
    ///   - convertible:     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - method:          `HTTPMethod` for the `URLRequest`. `.post` by default.
    ///   - headers:         `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:     `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager:     `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                      default.
    ///   - requestModifier: `RequestModifier` which will be applied to the `URLRequest` created from the provided
    ///                      parameters. `nil` by default.
    ///
    /// - Returns:           The created `UploadRequest`.
    open func upload(_ stream: InputStream,
                     to convertible: URLConvertible,
                     method: HTTPMethod = .post,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default,
                     requestModifier: RequestModifier? = nil) -> UploadRequest {
        let convertible = ParameterlessRequestConvertible(url: convertible,
                                                          method: method,
                                                          headers: headers,
                                                          requestModifier: requestModifier)

        return upload(stream, with: convertible, interceptor: interceptor, fileManager: fileManager)
    }

    /// Creates an `UploadRequest` from the provided `InputStream` using the `URLRequestConvertible` value and
    /// `RequestInterceptor`.
    ///
    /// - Parameters:
    ///   - stream:      The `InputStream` that provides the data to upload.
    ///   - convertible: `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - interceptor: `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager: `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                  default.
    ///
    /// - Returns:       The created `UploadRequest`.
    open func upload(_ stream: InputStream,
                     with convertible: URLRequestConvertible,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default) -> UploadRequest {
        upload(.stream(stream), with: convertible, interceptor: interceptor, fileManager: fileManager)
    }

    // MARK: MultipartFormData

    /// Creates an `UploadRequest` for the multipart form data built using a closure and sent using the provided
    /// `URLRequest` components and `RequestInterceptor`.
    ///
    /// It is important to understand the memory implications of uploading `MultipartFormData`. If the cumulative
    /// payload is small, encoding the data in-memory and directly uploading to a server is the by far the most
    /// efficient approach. However, if the payload is too large, encoding the data in-memory could cause your app to
    /// be terminated. Larger payloads must first be written to disk using input and output streams to keep the memory
    /// footprint low, then the data can be uploaded as a stream from the resulting file. Streaming from disk MUST be
    /// used for larger payloads such as video content.
    ///
    /// The `encodingMemoryThreshold` parameter allows Alamofire to automatically determine whether to encode in-memory
    /// or stream from disk. If the content length of the `MultipartFormData` is below the `encodingMemoryThreshold`,
    /// encoding takes place in-memory. If the content length exceeds the threshold, the data is streamed to disk
    /// during the encoding process. Then the result is uploaded as data or as a stream depending on which encoding
    /// technique was used.
    ///
    /// - Parameters:
    ///   - multipartFormData:      `MultipartFormData` building closure.
    ///   - url:                    `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - encodingMemoryThreshold: Byte threshold used to determine whether the form data is encoded into memory or
    ///                              onto disk before being uploaded. `MultipartFormData.encodingMemoryThreshold` by
    ///                              default.
    ///   - method:                  `HTTPMethod` for the `URLRequest`. `.post` by default.
    ///   - headers:                 `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:             `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager:             `FileManager` to be used if the form data exceeds the memory threshold and is
    ///                              written to disk before being uploaded. `.default` instance by default.
    ///   - requestModifier:         `RequestModifier` which will be applied to the `URLRequest` created from the
    ///                              provided parameters. `nil` by default.
    ///
    /// - Returns:                   The created `UploadRequest`.
    open func upload(multipartFormData: @escaping (MultipartFormData) -> Void,
                     to url: URLConvertible,
                     usingThreshold encodingMemoryThreshold: UInt64 = MultipartFormData.encodingMemoryThreshold,
                     method: HTTPMethod = .post,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default,
                     requestModifier: RequestModifier? = nil) -> UploadRequest {
        let convertible = ParameterlessRequestConvertible(url: url,
                                                          method: method,
                                                          headers: headers,
                                                          requestModifier: requestModifier)

        let formData = MultipartFormData(fileManager: fileManager)
        multipartFormData(formData)

        return upload(multipartFormData: formData,
                      with: convertible,
                      usingThreshold: encodingMemoryThreshold,
                      interceptor: interceptor,
                      fileManager: fileManager)
    }

    /// Creates an `UploadRequest` using a `MultipartFormData` building closure, the provided `URLRequestConvertible`
    /// value, and a `RequestInterceptor`.
    ///
    /// It is important to understand the memory implications of uploading `MultipartFormData`. If the cumulative
    /// payload is small, encoding the data in-memory and directly uploading to a server is the by far the most
    /// efficient approach. However, if the payload is too large, encoding the data in-memory could cause your app to
    /// be terminated. Larger payloads must first be written to disk using input and output streams to keep the memory
    /// footprint low, then the data can be uploaded as a stream from the resulting file. Streaming from disk MUST be
    /// used for larger payloads such as video content.
    ///
    /// The `encodingMemoryThreshold` parameter allows Alamofire to automatically determine whether to encode in-memory
    /// or stream from disk. If the content length of the `MultipartFormData` is below the `encodingMemoryThreshold`,
    /// encoding takes place in-memory. If the content length exceeds the threshold, the data is streamed to disk
    /// during the encoding process. Then the result is uploaded as data or as a stream depending on which encoding
    /// technique was used.
    ///
    /// - Parameters:
    ///   - multipartFormData:       `MultipartFormData` building closure.
    ///   - request:                 `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - encodingMemoryThreshold: Byte threshold used to determine whether the form data is encoded into memory or
    ///                              onto disk before being uploaded. `MultipartFormData.encodingMemoryThreshold` by
    ///                              default.
    ///   - interceptor:             `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager:             `FileManager` to be used if the form data exceeds the memory threshold and is
    ///                              written to disk before being uploaded. `.default` instance by default.
    ///
    /// - Returns:                   The created `UploadRequest`.
    open func upload(multipartFormData: @escaping (MultipartFormData) -> Void,
                     with request: URLRequestConvertible,
                     usingThreshold encodingMemoryThreshold: UInt64 = MultipartFormData.encodingMemoryThreshold,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default) -> UploadRequest {
        let formData = MultipartFormData(fileManager: fileManager)
        multipartFormData(formData)

        return upload(multipartFormData: formData,
                      with: request,
                      usingThreshold: encodingMemoryThreshold,
                      interceptor: interceptor,
                      fileManager: fileManager)
    }

    /// Creates an `UploadRequest` for the prebuilt `MultipartFormData` value using the provided `URLRequest` components
    /// and `RequestInterceptor`.
    ///
    /// It is important to understand the memory implications of uploading `MultipartFormData`. If the cumulative
    /// payload is small, encoding the data in-memory and directly uploading to a server is the by far the most
    /// efficient approach. However, if the payload is too large, encoding the data in-memory could cause your app to
    /// be terminated. Larger payloads must first be written to disk using input and output streams to keep the memory
    /// footprint low, then the data can be uploaded as a stream from the resulting file. Streaming from disk MUST be
    /// used for larger payloads such as video content.
    ///
    /// The `encodingMemoryThreshold` parameter allows Alamofire to automatically determine whether to encode in-memory
    /// or stream from disk. If the content length of the `MultipartFormData` is below the `encodingMemoryThreshold`,
    /// encoding takes place in-memory. If the content length exceeds the threshold, the data is streamed to disk
    /// during the encoding process. Then the result is uploaded as data or as a stream depending on which encoding
    /// technique was used.
    ///
    /// - Parameters:
    ///   - multipartFormData:       `MultipartFormData` instance to upload.
    ///   - url:                     `URLConvertible` value to be used as the `URLRequest`'s `URL`.
    ///   - encodingMemoryThreshold: Byte threshold used to determine whether the form data is encoded into memory or
    ///                              onto disk before being uploaded. `MultipartFormData.encodingMemoryThreshold` by
    ///                              default.
    ///   - method:                  `HTTPMethod` for the `URLRequest`. `.post` by default.
    ///   - headers:                 `HTTPHeaders` value to be added to the `URLRequest`. `nil` by default.
    ///   - interceptor:             `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager:             `FileManager` to be used if the form data exceeds the memory threshold and is
    ///                              written to disk before being uploaded. `.default` instance by default.
    ///   - requestModifier:         `RequestModifier` which will be applied to the `URLRequest` created from the
    ///                              provided parameters. `nil` by default.
    ///
    /// - Returns:                   The created `UploadRequest`.
    open func upload(multipartFormData: MultipartFormData,
                     to url: URLConvertible,
                     usingThreshold encodingMemoryThreshold: UInt64 = MultipartFormData.encodingMemoryThreshold,
                     method: HTTPMethod = .post,
                     headers: HTTPHeaders? = nil,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default,
                     requestModifier: RequestModifier? = nil) -> UploadRequest {
        let convertible = ParameterlessRequestConvertible(url: url,
                                                          method: method,
                                                          headers: headers,
                                                          requestModifier: requestModifier)

        let multipartUpload = MultipartUpload(encodingMemoryThreshold: encodingMemoryThreshold,
                                              request: convertible,
                                              multipartFormData: multipartFormData)

        return upload(multipartUpload, interceptor: interceptor, fileManager: fileManager)
    }

    /// Creates an `UploadRequest` for the prebuilt `MultipartFormData` value using the providing `URLRequestConvertible`
    /// value and `RequestInterceptor`.
    ///
    /// It is important to understand the memory implications of uploading `MultipartFormData`. If the cumulative
    /// payload is small, encoding the data in-memory and directly uploading to a server is the by far the most
    /// efficient approach. However, if the payload is too large, encoding the data in-memory could cause your app to
    /// be terminated. Larger payloads must first be written to disk using input and output streams to keep the memory
    /// footprint low, then the data can be uploaded as a stream from the resulting file. Streaming from disk MUST be
    /// used for larger payloads such as video content.
    ///
    /// The `encodingMemoryThreshold` parameter allows Alamofire to automatically determine whether to encode in-memory
    /// or stream from disk. If the content length of the `MultipartFormData` is below the `encodingMemoryThreshold`,
    /// encoding takes place in-memory. If the content length exceeds the threshold, the data is streamed to disk
    /// during the encoding process. Then the result is uploaded as data or as a stream depending on which encoding
    /// technique was used.
    ///
    /// - Parameters:
    ///   - multipartFormData:       `MultipartFormData` instance to upload.
    ///   - request:                 `URLRequestConvertible` value to be used to create the `URLRequest`.
    ///   - encodingMemoryThreshold: Byte threshold used to determine whether the form data is encoded into memory or
    ///                              onto disk before being uploaded. `MultipartFormData.encodingMemoryThreshold` by
    ///                              default.
    ///   - interceptor:             `RequestInterceptor` value to be used by the returned `DataRequest`. `nil` by default.
    ///   - fileManager:             `FileManager` instance to be used by the returned `UploadRequest`. `.default` instance by
    ///                              default.
    ///
    /// - Returns:                   The created `UploadRequest`.
    open func upload(multipartFormData: MultipartFormData,
                     with request: URLRequestConvertible,
                     usingThreshold encodingMemoryThreshold: UInt64 = MultipartFormData.encodingMemoryThreshold,
                     interceptor: RequestInterceptor? = nil,
                     fileManager: FileManager = .default) -> UploadRequest {
        let multipartUpload = MultipartUpload(encodingMemoryThreshold: encodingMemoryThreshold,
                                              request: request,
                                              multipartFormData: multipartFormData)

        return upload(multipartUpload, interceptor: interceptor, fileManager: fileManager)
    }

    // MARK: - Internal API

    // MARK: Uploadable

    func upload(_ uploadable: UploadRequest.Uploadable,
                with convertible: URLRequestConvertible,
                interceptor: RequestInterceptor?,
                fileManager: FileManager) -> UploadRequest {
        let uploadable = Upload(request: convertible, uploadable: uploadable)

        return upload(uploadable, interceptor: interceptor, fileManager: fileManager)
    }

    func upload(_ upload: UploadConvertible, interceptor: RequestInterceptor?, fileManager: FileManager) -> UploadRequest {
        let request = UploadRequest(convertible: upload,
                                    underlyingQueue: rootQueue,
                                    serializationQueue: serializationQueue,
                                    eventMonitor: eventMonitor,
                                    interceptor: interceptor,
                                    fileManager: fileManager,
                                    delegate: self)

        perform(request)

        return request
    }

    // MARK: Perform

    /// Starts performing the provided `Request`.
    ///
    /// - Parameter request: The `Request` to perform.
    func perform(_ request: Request) {
        rootQueue.async { /// 异步函数
            guard !request.isCancelled else { return }

            print(request.state) /// initialized

            self.activeRequests.insert(request)

            print(request.state) /// initialized
    /**
     这里request.state更新为resumed了？ 在哪变化的呢？ 注意：perform函数是异步函数，在调用perform函数后就返回了
     perform函数返回后，外界调用DataRequest.response函数这个函数内部会根据配置startRequestsImmediately、startImmediately,将Request的state更新
     注意：requestQueue将rootQueue设置为了自己的target Queue
     */
            self.requestQueue.async {
                
                print(request.state) /// resume

                // Leaf types must come first, otherwise they will cast as their superclass.
                switch request {
                case let r as UploadRequest: self.performUploadRequest(r) // UploadRequest must come before DataRequest due to subtype relationship.
                case let r as DataRequest: self.performDataRequest(r)
                case let r as DownloadRequest: self.performDownloadRequest(r)
                case let r as DataStreamRequest: self.performDataStreamRequest(r)
                default: fatalError("Attempted to perform unsupported Request subclass: \(type(of: request))")
                }
            }
        }
    }

    func performDataRequest(_ request: DataRequest) {
        /// 保证一下的执行在requestQueue队列，否则不会执行
        dispatchPrecondition(condition: .onQueue(requestQueue))

        performSetupOperations(for: request, convertible: request.convertible)
    }

    func performDataStreamRequest(_ request: DataStreamRequest) {
        dispatchPrecondition(condition: .onQueue(requestQueue))

        performSetupOperations(for: request, convertible: request.convertible)
    }

    func performUploadRequest(_ request: UploadRequest) {
        dispatchPrecondition(condition: .onQueue(requestQueue))

        performSetupOperations(for: request, convertible: request.convertible) {
            do {
                let uploadable = try request.upload.createUploadable()
                self.rootQueue.async { request.didCreateUploadable(uploadable) }
                return true
            } catch {
                self.rootQueue.async { request.didFailToCreateUploadable(with: error.asAFError(or: .createUploadableFailed(error: error))) }
                return false
            }
        }
    }

    func performDownloadRequest(_ request: DownloadRequest) {
        dispatchPrecondition(condition: .onQueue(requestQueue))

        switch request.downloadable {
        case let .request(convertible):
            performSetupOperations(for: request, convertible: convertible)
        case let .resumeData(resumeData):
            rootQueue.async { self.didReceiveResumeData(resumeData, for: request) }
        }
    }

    func performSetupOperations(for request: Request,
                                convertible: URLRequestConvertible,
                                shouldCreateTask: @escaping () -> Bool = { true }) {
        dispatchPrecondition(condition: .onQueue(requestQueue))

        let initialRequest: URLRequest

        do {
            /// 通过传递过来的参数URLRequestConvertible, 初始化initialRequest
            initialRequest = try convertible.asURLRequest()
            try initialRequest.validate()
        } catch {
            /// 报告状态：执行Alamofire.Request类中的函数 didFailToCreateURLRequest
            rootQueue.async { request.didFailToCreateURLRequest(with: error.asAFError(or: .createURLRequestFailed(error: error))) }
            return
        }
        /// 报告状态：执行Alamofire.Request类中的函数 didCreateInitialURLRequest
        rootQueue.async { request.didCreateInitialURLRequest(initialRequest) }
        
        guard !request.isCancelled else { return }
        
        guard let adapter = adapter(for: request) else {
            guard shouldCreateTask() else { return }
            /// 1.没有适配器: 处理创建URLRequest之后的事情， 直接使用initialRequest作为最终的参数，创建Task
            rootQueue.async { self.didCreateURLRequest(initialRequest, for: request) }
            return
        }
        
        /// 2.有适配器 : 这部分暂未研究
        let adapterState = RequestAdapterState(requestID: request.id, session: self)
        adapter.adapt(initialRequest, using: adapterState) { result in
            do {
                let adaptedRequest = try result.get()
                
                try adaptedRequest.validate()
                
                self.rootQueue.async { request.didAdaptInitialRequest(initialRequest, to: adaptedRequest) }
                
                guard shouldCreateTask() else { return }
                
                /// 执行didCreateURLRequest,创建Task
                self.rootQueue.async { self.didCreateURLRequest(adaptedRequest, for: request) }
                
            } catch {
                self.rootQueue.async { request.didFailToAdaptURLRequest(initialRequest, withError: .requestAdaptationFailed(error: error)) }
            }
        }
    }

    // MARK: - Task Handling

    func didCreateURLRequest(_ urlRequest: URLRequest, for request: Request) {
        /// 条件检查，如果不是在rootQueue就返回了
        dispatchPrecondition(condition: .onQueue(rootQueue))
        
        /// 报告状态: 执行回调函数didCreateURLRequest
        request.didCreateURLRequest(urlRequest)

        guard !request.isCancelled else { return }
        
        /// 创建task
        let task = request.task(for: urlRequest, using: session)
        
        requestTaskMap[request] = task
        
        /// 报告状态: 执行回调函数
        request.didCreateTask(task)
        
        /// Alamofire.Request的withState闭包，回调中会更新更新task状态。
        /// 通过request的resume状态来启动task,即task.resume()
        updateStatesForTask(task, request: request)
    }

    func didReceiveResumeData(_ data: Data, for request: DownloadRequest) {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        guard !request.isCancelled else { return }

        let task = request.task(forResumeData: data, using: session)
        requestTaskMap[request] = task
        request.didCreateTask(task)

        updateStatesForTask(task, request: request)
    }

    func updateStatesForTask(_ task: URLSessionTask, request: Request) {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        request.withState { state in
            switch state {
            case .initialized, .finished:
                // Do nothing.
                break
            case .resumed:
                // 启动task
                task.resume()
                rootQueue.async { request.didResumeTask(task) }
            case .suspended:
                task.suspend()
                rootQueue.async { request.didSuspendTask(task) }
            case .cancelled:
                // Resume to ensure metrics are gathered.
                task.resume()
                task.cancel()
                rootQueue.async { request.didCancelTask(task) }
            }
        }
    }

    // MARK: - Adapters and Retriers

    func adapter(for request: Request) -> RequestAdapter? {
        if let requestInterceptor = request.interceptor, let sessionInterceptor = interceptor {
            return Interceptor(adapters: [requestInterceptor, sessionInterceptor])
        } else {
            return request.interceptor ?? interceptor
        }
    }

    func retrier(for request: Request) -> RequestRetrier? {
        if let requestInterceptor = request.interceptor, let sessionInterceptor = interceptor {
            return Interceptor(retriers: [requestInterceptor, sessionInterceptor])
        } else {
            return request.interceptor ?? interceptor
        }
    }

    // MARK: - Invalidation

    func finishRequestsForDeinit() {
        requestTaskMap.requests.forEach { request in
            rootQueue.async {
                request.finish(error: AFError.sessionDeinitialized)
            }
        }
    }
}

// MARK: - RequestDelegate

extension Session: RequestDelegate {
    public var sessionConfiguration: URLSessionConfiguration {
        session.configuration
    }

    public var startImmediately: Bool { startRequestsImmediately }

    public func cleanup(after request: Request) {
        activeRequests.remove(request)
    }

    public func retryResult(for request: Request, dueTo error: AFError, completion: @escaping (RetryResult) -> Void) {
        guard let retrier = retrier(for: request) else {
            rootQueue.async { completion(.doNotRetry) }
            return
        }

        retrier.retry(request, for: self, dueTo: error) { retryResult in
            self.rootQueue.async {
                guard let retryResultError = retryResult.error else { completion(retryResult); return }

                let retryError = AFError.requestRetryFailed(retryError: retryResultError, originalError: error)
                completion(.doNotRetryWithError(retryError))
            }
        }
    }

    public func retryRequest(_ request: Request, withDelay timeDelay: TimeInterval?) {
        rootQueue.async {
            let retry: () -> Void = {
                guard !request.isCancelled else { return }

                request.prepareForRetry()
                self.perform(request)
            }

            if let retryDelay = timeDelay {
                self.rootQueue.after(retryDelay) { retry() }
            } else {
                retry()
            }
        }
    }
}

// MARK: - SessionStateProvider

extension Session: SessionStateProvider {
    func request(for task: URLSessionTask) -> Request? {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        return requestTaskMap[task]
    }

    func didGatherMetricsForTask(_ task: URLSessionTask) {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        let didDisassociate = requestTaskMap.disassociateIfNecessaryAfterGatheringMetricsForTask(task)

        if didDisassociate {
            waitingCompletions[task]?()
            waitingCompletions[task] = nil
        }
    }

    func didCompleteTask(_ task: URLSessionTask, completion: @escaping () -> Void) {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        let didDisassociate = requestTaskMap.disassociateIfNecessaryAfterCompletingTask(task)

        if didDisassociate {
            completion()
        } else {
            waitingCompletions[task] = completion
        }
    }

    func credential(for task: URLSessionTask, in protectionSpace: URLProtectionSpace) -> URLCredential? {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        return requestTaskMap[task]?.credential ??
            session.configuration.urlCredentialStorage?.defaultCredential(for: protectionSpace)
    }

    func cancelRequestsForSessionInvalidation(with error: Error?) {
        dispatchPrecondition(condition: .onQueue(rootQueue))

        requestTaskMap.requests.forEach { $0.finish(error: AFError.sessionInvalidated(error: error)) }
    }
}
