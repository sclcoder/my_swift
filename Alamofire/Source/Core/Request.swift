//
//  Request.swift
//
//  Copyright (c) 2014-2020 Alamofire Software Foundation (http://alamofire.org/)
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

/// `Request` is the common superclass of all Alamofire request types and provides common state, delegate, and callback
/// handling.
public class Request {
    /// State of the `Request`, with managed transitions between states set when calling `resume()`, `suspend()`, or
    /// `cancel()` on the `Request`.
    public enum State {
        /// Initial state of the `Request`.
        case initialized
        /// `State` set when `resume()` is called. Any tasks created for the `Request` will have `resume()` called on
        /// them in this state.
        case resumed
        /// `State` set when `suspend()` is called. Any tasks created for the `Request` will have `suspend()` called on
        /// them in this state.
        case suspended
        /// `State` set when `cancel()` is called. Any tasks created for the `Request` will have `cancel()` called on
        /// them. Unlike `resumed` or `suspended`, once in the `cancelled` state, the `Request` can no longer transition
        /// to any other state.
        case cancelled
        /// `State` set when all response serialization completion closures have been cleared on the `Request` and
        /// enqueued on their respective queues.
        case finished

        /// Determines whether `self` can be transitioned to the provided `State`.
        func canTransitionTo(_ state: State) -> Bool {
            switch (self, state) {
            case (.initialized, _):
                return true
            case (_, .initialized), (.cancelled, _), (.finished, _):
                return false
            case (.resumed, .cancelled), (.suspended, .cancelled), (.resumed, .suspended), (.suspended, .resumed):
                return true
            case (.suspended, .suspended), (.resumed, .resumed):
                return false
            case (_, .finished):
                return true
            }
        }
    }

    // MARK: - Initial State

    /// `UUID` providing a unique identifier for the `Request`, used in the `Hashable` and `Equatable` conformances.
    public let id: UUID
    /// The serial queue for all internal async actions.
    public let underlyingQueue: DispatchQueue
    /// The queue used for all serialization actions. By default it's a serial queue that targets `underlyingQueue`.
    public let serializationQueue: DispatchQueue
    /// `EventMonitor` used for event callbacks.
    public let eventMonitor: EventMonitor?
    /// The `Request`'s interceptor.
    public let interceptor: RequestInterceptor?
    /// The `Request`'s delegate.
    public private(set) weak var delegate: RequestDelegate?

    // MARK: - Mutable State
    /// Type encapsulating all mutable state that may need to be accessed from anything other than the `underlyingQueue`.
    struct MutableState {
        /// State of the `Request`.
        var state: State = .initialized
        /// `ProgressHandler` and `DispatchQueue` provided for upload progress callbacks.
        var uploadProgressHandler: (handler: ProgressHandler, queue: DispatchQueue)?
        /// `ProgressHandler` and `DispatchQueue` provided for download progress callbacks.
        var downloadProgressHandler: (handler: ProgressHandler, queue: DispatchQueue)?
        /// `RedirectHandler` provided for to handle request redirection.
        var redirectHandler: RedirectHandler?
        /// `CachedResponseHandler` provided to handle response caching.
        var cachedResponseHandler: CachedResponseHandler?
        /// Queue and closure called when the `Request` is able to create a cURL description of itself.
        var cURLHandler: (queue: DispatchQueue, handler: (String) -> Void)?
        /// Queue and closure called when the `Request` creates a `URLRequest`.
        var urlRequestHandler: (queue: DispatchQueue, handler: (URLRequest) -> Void)?
        /// Queue and closure called when the `Request` creates a `URLSessionTask`.
        var urlSessionTaskHandler: (queue: DispatchQueue, handler: (URLSessionTask) -> Void)?
        
        
        /// Response serialization closures that handle response parsing.
        var responseSerializers: [() -> Void] = []
        /// Response serialization completion closures executed once all response serializers are complete.
        var responseSerializerCompletions: [() -> Void] = []
        /// Whether response serializer processing is finished.
        var responseSerializerProcessingFinished = false
        /// `URLCredential` used for authentication challenges.
        var credential: URLCredential?
        /// All `URLRequest`s created by Alamofire on behalf of the `Request`.
        var requests: [URLRequest] = []
        /// All `URLSessionTask`s created by Alamofire on behalf of the `Request`.
        var tasks: [URLSessionTask] = []
        /// All `URLSessionTaskMetrics` values gathered by Alamofire on behalf of the `Request`. Should correspond
        /// exactly the the `tasks` created.
        var metrics: [URLSessionTaskMetrics] = []
        /// Number of times any retriers provided retried the `Request`.
        var retryCount = 0
        /// Final `AFError` for the `Request`, whether from various internal Alamofire calls or as a result of a `task`.
        var error: AFError?
        /// Whether the instance has had `finish()` called and is running the serializers. Should be replaced with a
        /// representation in the state machine in the future.
        var isFinishing = false
        /// Actions to run when requests are finished. Use for concurrency support.
        var finishHandlers: [() -> Void] = []
    }

    /**
    ## @Protected包装器的作用
         在 Alamofire 的 Request 类中，mutableState 使用了 @Protected 属性包装器，这是为了 线程安全地访问和修改 mutableState。它的作用是保证多线程环境下对 mutableState 的读写是安全的，防止数据竞争（Race Condition）。
    
    ## 在 Swift 中，如果你使用 @Protected 修饰一个属性 mutableState，你可以用 $mutableState 访问它的包装器。因为内部的projectedValue返回的是包装器本身
         所以 $mutableState.state 实际上等价于：mutableState.wrappedValue.state这会 在 @Protected 内部自动进行线程安全的读写。
     
     ## mutableState 维护的是 Request 的可变状态，可能包含：
          - 请求的当前状态（进行中、完成、失败等）、响应数据、进度信息、其他动态参数
          - 这些状态可能在多个线程中被访问或修改，比如：主线程 可能会检查请求状态、网络线程 可能会修改状态，比如收到响应后更新 mutableStateadad、回调线程 可能会处理请求完成的逻辑
     
     ## 这些属性什么时候会在多线程中被访问和修改？ 如 tasks、requests等
      Alamofire 的 URLSessionTask 生命周期事件（例如重定向、认证挑战、任务完成等）是由底层的 URLSession 在 后台线程 触发的。例如：
      重定向：当服务器返回 3xx 状态码时，系统会在后台线程创建新的 URLSessionTask。
      重试：通过 RetryPolicy 重试请求时，新的任务可能在任意线程创建。
      适配器修改：RequestAdapter 可能在任意线程生成新的 URLRequest 并创建新任务。
      这些操作会修改 Request 内部的 tasks 数组，因此存在多线程并发访问的可能性。
      
      如该didCreateInitialURLRequest方法在Session中是这样调用的
      rootQueue.async { request.didCreateInitialURLRequest(initialRequest) } ,可知是在子线程执行操作对MutableState中的数据进行更改
     
    ## Alamofire 的 mutableState 被设计为完全线程安全，无论外部代码在哪个队列调用，其内部状态始终通过锁（如 os_unfair_lock 或 NSLock）保护。
       这种设计：
            统一性：所有对 mutableState 的访问都强制加锁，避免遗漏。
            防御性：即使未来代码变动导致 mutableState 被其他队列访问，也能保证线程安全。
            兼容性：与某些特殊场景兼容（如外部代码直接操作 Request 的状态）
     */

    /// Protected `MutableState` value that provides thread-safe access to state values.
    @Protected
    fileprivate var mutableState = MutableState()
    
    /**
     因为@Protected内部的projectedValue返回的是包装器本身，所以$mutableState是在访问它的包装器 @Protected<MutableState>，
     所以$mutableState.state是在访问 `Protected<MutableState>` 的 `state` 属性
     - 编译器会转成：$mutableState[dynamicMember: \MutableState.state]
     Q: 编译器是如何知道state是来自于MutableState类型呢
     A: 因为 $mutableState 本身是 Protected<MutableState> 类型，而 @dynamicMemberLookup 允许自动解析Protected<MutableState>的属性。通过 @Protected内部实现可知，编译器自动推断 T = MutableState，因此 state 被解析为 MutableState.state。
     */
    /// `State` of the `Request`.
    public var state: State {
        $mutableState.state
    }
    /// Returns whether `state` is `.initialized`.
    public var isInitialized: Bool { state == .initialized }
    /// Returns whether `state is `.resumed`.
    public var isResumed: Bool { state == .resumed }
    /// Returns whether `state` is `.suspended`.
    public var isSuspended: Bool { state == .suspended }
    /// Returns whether `state` is `.cancelled`.
    public var isCancelled: Bool { state == .cancelled }
    /// Returns whether `state` is `.finished`.
    public var isFinished: Bool { state == .finished }

    // MARK: Progress

    /// Closure type executed when monitoring the upload or download progress of a request.
    public typealias ProgressHandler = (Progress) -> Void

    /// `Progress` of the upload of the body of the executed `URLRequest`. Reset to `0` if the `Request` is retried.
    public let uploadProgress = Progress(totalUnitCount: 0)
    /// `Progress` of the download of any response data. Reset to `0` if the `Request` is retried.
    public let downloadProgress = Progress(totalUnitCount: 0)
    /// `ProgressHandler` called when `uploadProgress` is updated, on the provided `DispatchQueue`.
    private var uploadProgressHandler: (handler: ProgressHandler, queue: DispatchQueue)? {
        get { $mutableState.uploadProgressHandler }
        set { $mutableState.uploadProgressHandler = newValue }
    }

    /// `ProgressHandler` called when `downloadProgress` is updated, on the provided `DispatchQueue`.
    fileprivate var downloadProgressHandler: (handler: ProgressHandler, queue: DispatchQueue)? {
        get { $mutableState.downloadProgressHandler }
        set { $mutableState.downloadProgressHandler = newValue }
    }

    // MARK: Redirect Handling

    /// `RedirectHandler` set on the instance.
    /**
     public 表示这个属性在模块外部是可见的，任何模块都可以访问这个属性。
     private(set) 表示这个属性的 setter 方法在模块外部是不可见的，只有在定义它的模块内部可以进行设置。也就是说，属性可以被外部访问，但只能在内部进行写操作。
     */
    public private(set) var redirectHandler: RedirectHandler? {
        get { $mutableState.redirectHandler }
        set { $mutableState.redirectHandler = newValue }
    }

    // MARK: Cached Response Handling

    /// `CachedResponseHandler` set on the instance.
    public private(set) var cachedResponseHandler: CachedResponseHandler? {
        get { $mutableState.cachedResponseHandler }
        set { $mutableState.cachedResponseHandler = newValue }
    }

    // MARK: URLCredential

    /// `URLCredential` used for authentication challenges. Created by calling one of the `authenticate` methods.
    public private(set) var credential: URLCredential? {
        get { $mutableState.credential }
        set { $mutableState.credential = newValue }
    }

    // MARK: Validators

    /// `Validator` callback closures that store the validation calls enqueued.
    @Protected
    fileprivate var validators: [() -> Void] = []

    // MARK: URLRequests

    /// All `URLRequests` created on behalf of the `Request`, including original and adapted requests.
    public var requests: [URLRequest] { $mutableState.requests }
    /// First `URLRequest` created on behalf of the `Request`. May not be the first one actually executed.
    public var firstRequest: URLRequest? { requests.first }
    /// Last `URLRequest` created on behalf of the `Request`.
    public var lastRequest: URLRequest? { requests.last }
    /// Current `URLRequest` created on behalf of the `Request`.
    public var request: URLRequest? { lastRequest }

    /** ## 闭包和泛型
     compactMap 是 Swift 的高阶函数，用于对集合中的每个元素进行转换并过滤掉 nil 值。
     \.currentRequest 是 KeyPath 语法，表示从 URLSessionTask 中提取 currentRequest 属性。
     currentRequest 是 URLSessionTask 的一个属性，表示当前正在执行或已执行的 URLRequest。
     如果某个任务尚未开始执行（currentRequest 为 nil），则会被 compactMap 过滤掉。
     
     mutableState.requests：存储了所有生成的 URLRequest 对象（包括初始请求、重定向请求、适配后的请求等）。这些请求可能尚未执行。
     performedRequests：仅包含已执行的 URLRequest 对象（即 URLSessionTask.currentRequest）。这些请求已经由 URLSession 实际发送到服务器。
     
     完整写法如下
     public var performedRequests: [URLRequest] {
         $mutableState.read { mutableState in
             return mutableState.tasks.compactMap { task in
                 return task.currentRequest
             }
         }
     }
     
     解析 $mutableState.read { $0.tasks.compactMap(\.currentRequest) }
     这一行代码相当于：
     $mutableState.read { mutableState in
         mutableState.tasks.compactMap { task in
             task.currentRequest
         }
     }
     
     简化点：
     省略 return 关键字（单表达式闭包自动返回）。
     省略 mutableState in（Swift 自动推断 $0 代表 mutableState）。
     使用 KeyPath 语法 \.currentRequest 代替 { task in task.currentRequest }。
    
     这里使用了**尾随闭包（Trailing Closure）**的写法！
     在 Swift 中，当函数的最后一个参数是一个闭包时，可以将闭包移到括号外部，这就是尾随闭包。
    
     不使用尾随闭包，完整写法如下：
     public var performedRequests: [URLRequest] {
         $mutableState.read({ mutableState in
             return mutableState.tasks.compactMap { $0.currentRequest }
         })
     }
     该方法内部在执行闭包时将self.value传递出来，其类型就是Protected<T>中的T，在当前环境下就是MutableState这个结构体类型
     func read<U>(_ closure: (T) throws -> U) rethrows -> U {
         try lock.around { try closure(self.value) }
     }

     */
    /// `URLRequest`s from all of the `URLSessionTask`s executed on behalf of the `Request`. May be different from
    /// `requests` due to `URLSession` manipulation.
    public var performedRequests: [URLRequest] { $mutableState.read { $0.tasks.compactMap(\.currentRequest) } }

    // MARK: HTTPURLResponse

    /** ## 计算属性和尾随闭包
     不是 尾随闭包，而是 计算属性（computed property） 的简写形式。
     response 是一个计算属性，它的值是 lastTask?.response as? HTTPURLResponse，表示获取 lastTask 的 response 并尝试转换为 HTTPURLResponse。
     这里的 {} 并不是闭包，而是计算属性的 getter 省略了 return 的简写形式。
     
     如果不省略 return，完整写法如下：
     public var response: HTTPURLResponse? {
         return lastTask?.response as? HTTPURLResponse
     }
     
     如何区分计算属性和尾随闭包？
     1️⃣ 计算属性
     {} 代表 计算属性的 getter，并不会传递参数。
     return 关键字可以省略（Swift 允许单行表达式的计算属性省略 return）。
     本例中的 { lastTask?.response as? HTTPURLResponse } 不是闭包，而是计算属性的 getter。
     
     2️⃣ 尾随闭包
     尾随闭包必须传递给某个函数，并作为该函数的参数。
     如果 {} 里面的代码是一个闭包，通常会有 in 关键字（但如果是 $0 这种隐式参数的简写可能不会有 in）。

     */
    /// `HTTPURLResponse` received from the server, if any. If the `Request` was retried, this is the response of the
    /// last `URLSessionTask`.
    public var response: HTTPURLResponse? { lastTask?.response as? HTTPURLResponse }

    // MARK: Tasks

    /// All `URLSessionTask`s created on behalf of the `Request`.
    public var tasks: [URLSessionTask] { $mutableState.tasks }
    /// First `URLSessionTask` created on behalf of the `Request`.
    public var firstTask: URLSessionTask? { tasks.first }
    /// Last `URLSessionTask` crated on behalf of the `Request`.
    public var lastTask: URLSessionTask? { tasks.last }
    /// Current `URLSessionTask` created on behalf of the `Request`.
    public var task: URLSessionTask? { lastTask }

    // MARK: Metrics

    /// All `URLSessionTaskMetrics` gathered on behalf of the `Request`. Should correspond to the `tasks` created.
    public var allMetrics: [URLSessionTaskMetrics] { $mutableState.metrics }
    /// First `URLSessionTaskMetrics` gathered on behalf of the `Request`.
    public var firstMetrics: URLSessionTaskMetrics? { allMetrics.first }
    /// Last `URLSessionTaskMetrics` gathered on behalf of the `Request`.
    public var lastMetrics: URLSessionTaskMetrics? { allMetrics.last }
    /// Current `URLSessionTaskMetrics` gathered on behalf of the `Request`.
    public var metrics: URLSessionTaskMetrics? { lastMetrics }

    // MARK: Retry Count

    /// Number of times the `Request` has been retried.
    public var retryCount: Int { $mutableState.retryCount }

    // MARK: Error

    /// `Error` returned from Alamofire internally, from the network request directly, or any validators executed.
    public fileprivate(set) var error: AFError? {
        get { $mutableState.error }
        set { $mutableState.error = newValue }
    }

    /// Default initializer for the `Request` superclass.
    ///
    /// - Parameters:
    ///   - id:                 `UUID` used for the `Hashable` and `Equatable` implementations. `UUID()` by default.
    ///   - underlyingQueue:    `DispatchQueue` on which all internal `Request` work is performed.
    ///   - serializationQueue: `DispatchQueue` on which all serialization work is performed. By default targets
    ///                         `underlyingQueue`, but can be passed another queue from a `Session`.
    ///   - eventMonitor:       `EventMonitor` called for event callbacks from internal `Request` actions.
    ///   - interceptor:        `RequestInterceptor` used throughout the request lifecycle.
    ///   - delegate:           `RequestDelegate` that provides an interface to actions not performed by the `Request`.
    init(id: UUID = UUID(),
         underlyingQueue: DispatchQueue,
         serializationQueue: DispatchQueue,
         eventMonitor: EventMonitor?,
         interceptor: RequestInterceptor?,
         delegate: RequestDelegate) {
        self.id = id
        self.underlyingQueue = underlyingQueue
        self.serializationQueue = serializationQueue
        self.eventMonitor = eventMonitor
        self.interceptor = interceptor
        self.delegate = delegate
    }

    // MARK: - Internal Event API

    // All API must be called from underlyingQueue.

    /// Called when an initial `URLRequest` has been created on behalf of the instance. If a `RequestAdapter` is active,
    /// the `URLRequest` will be adapted before being issued.
    ///
    /// - Parameter request: The `URLRequest` created.
    func didCreateInitialURLRequest(_ request: URLRequest) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        $mutableState.write { $0.requests.append(request) }

        eventMonitor?.request(self, didCreateInitialURLRequest: request)
    }

    /// Called when initial `URLRequest` creation has failed, typically through a `URLRequestConvertible`.
    ///
    /// - Note: Triggers retry.
    ///
    /// - Parameter error: `AFError` thrown from the failed creation.
    func didFailToCreateURLRequest(with error: AFError) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        self.error = error

        eventMonitor?.request(self, didFailToCreateURLRequestWithError: error)

        callCURLHandlerIfNecessary()

        retryOrFinish(error: error)
    }

    /// Called when a `RequestAdapter` has successfully adapted a `URLRequest`.
    ///
    /// - Parameters:
    ///   - initialRequest: The `URLRequest` that was adapted.
    ///   - adaptedRequest: The `URLRequest` returned by the `RequestAdapter`.
    func didAdaptInitialRequest(_ initialRequest: URLRequest, to adaptedRequest: URLRequest) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        $mutableState.write { $0.requests.append(adaptedRequest) }

        eventMonitor?.request(self, didAdaptInitialRequest: initialRequest, to: adaptedRequest)
    }

    /// Called when a `RequestAdapter` fails to adapt a `URLRequest`.
    ///
    /// - Note: Triggers retry.
    ///
    /// - Parameters:
    ///   - request: The `URLRequest` the adapter was called with.
    ///   - error:   The `AFError` returned by the `RequestAdapter`.
    func didFailToAdaptURLRequest(_ request: URLRequest, withError error: AFError) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        self.error = error

        eventMonitor?.request(self, didFailToAdaptURLRequest: request, withError: error)

        callCURLHandlerIfNecessary()

        retryOrFinish(error: error)
    }

    /// Final `URLRequest` has been created for the instance.
    ///
    /// - Parameter request: The `URLRequest` created.
    func didCreateURLRequest(_ request: URLRequest) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        $mutableState.read { state in
            state.urlRequestHandler?.queue.async { state.urlRequestHandler?.handler(request) }
        }

        eventMonitor?.request(self, didCreateURLRequest: request)

        callCURLHandlerIfNecessary()
    }

    /// Asynchronously calls any stored `cURLHandler` and then removes it from `mutableState`.
    private func callCURLHandlerIfNecessary() {
        $mutableState.write { mutableState in
            guard let cURLHandler = mutableState.cURLHandler else { return }

            cURLHandler.queue.async { cURLHandler.handler(self.cURLDescription()) }

            mutableState.cURLHandler = nil
        }
    }

    /// Called when a `URLSessionTask` is created on behalf of the instance.
    ///
    /// - Parameter task: The `URLSessionTask` created.
    func didCreateTask(_ task: URLSessionTask) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        $mutableState.write { state in
            state.tasks.append(task) /// 保存task，在构建DataResponse是会用到task

            guard let urlSessionTaskHandler = state.urlSessionTaskHandler else { return }

            urlSessionTaskHandler.queue.async { urlSessionTaskHandler.handler(task) }
        }

        eventMonitor?.request(self, didCreateTask: task)
    }

    /// Called when resumption is completed.
    func didResume() {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        eventMonitor?.requestDidResume(self)
    }

    /// Called when a `URLSessionTask` is resumed on behalf of the instance.
    ///
    /// - Parameter task: The `URLSessionTask` resumed.
    func didResumeTask(_ task: URLSessionTask) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        eventMonitor?.request(self, didResumeTask: task)
    }

    /// Called when suspension is completed.
    func didSuspend() {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        eventMonitor?.requestDidSuspend(self)
    }

    /// Called when a `URLSessionTask` is suspended on behalf of the instance.
    ///
    /// - Parameter task: The `URLSessionTask` suspended.
    func didSuspendTask(_ task: URLSessionTask) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        eventMonitor?.request(self, didSuspendTask: task)
    }

    /// Called when cancellation is completed, sets `error` to `AFError.explicitlyCancelled`.
    func didCancel() {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        error = error ?? AFError.explicitlyCancelled

        eventMonitor?.requestDidCancel(self)
    }

    /// Called when a `URLSessionTask` is cancelled on behalf of the instance.
    ///
    /// - Parameter task: The `URLSessionTask` cancelled.
    func didCancelTask(_ task: URLSessionTask) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        eventMonitor?.request(self, didCancelTask: task)
    }

    /// Called when a `URLSessionTaskMetrics` value is gathered on behalf of the instance.
    ///
    /// - Parameter metrics: The `URLSessionTaskMetrics` gathered.
    func didGatherMetrics(_ metrics: URLSessionTaskMetrics) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        $mutableState.write { $0.metrics.append(metrics) }

        eventMonitor?.request(self, didGatherMetrics: metrics)
    }

    /// Called when a `URLSessionTask` fails before it is finished, typically during certificate pinning.
    ///
    /// - Parameters:
    ///   - task:  The `URLSessionTask` which failed.
    ///   - error: The early failure `AFError`.
    func didFailTask(_ task: URLSessionTask, earlyWithError error: AFError) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        self.error = error

        // Task will still complete, so didCompleteTask(_:with:) will handle retry.
        eventMonitor?.request(self, didFailTask: task, earlyWithError: error)
    }

    /// Called when a `URLSessionTask` completes. All tasks will eventually call this method.
    ///
    /// - Note: Response validation is synchronously triggered in this step.
    ///
    /// - Parameters:
    ///   - task:  The `URLSessionTask` which completed.
    ///   - error: The `AFError` `task` may have completed with. If `error` has already been set on the instance, this
    ///            value is ignored.
    func didCompleteTask(_ task: URLSessionTask, with error: AFError?) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        self.error = self.error ?? error

        validators.forEach { $0() }
        /// 这个监视器,是为了对外发送相关状态通知的, 外界可以监听相关的状态
        eventMonitor?.request(self, didCompleteTask: task, with: error)
        /// 执行完成Task的代码 - 如果是Finish则会执行Response的解析回调
        retryOrFinish(error: self.error)
    }

    /// Called when the `RequestDelegate` is going to retry this `Request`. Calls `reset()`.
    func prepareForRetry() {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        $mutableState.write { $0.retryCount += 1 }

        reset()

        eventMonitor?.requestIsRetrying(self)
    }

    /// Called to determine whether retry will be triggered for the particular error, or whether the instance should
    /// call `finish()`.
    ///
    /// - Parameter error: The possible `AFError` which may trigger retry.
    func retryOrFinish(error: AFError?) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        guard let error = error, let delegate = delegate else { finish(); return }

        delegate.retryResult(for: self, dueTo: error) { retryResult in
            switch retryResult {
            case .doNotRetry:
                self.finish()
            case let .doNotRetryWithError(retryError):
                self.finish(error: retryError.asAFError(orFailWith: "Received retryError was not already AFError"))
            case .retry, .retryWithDelay:
                delegate.retryRequest(self, withDelay: retryResult.delay)
            }
        }
    }

    /// Finishes this `Request` and starts the response serializers.
    ///
    /// - Parameter error: The possible `Error` with which the instance will finish.
    func finish(error: AFError? = nil) {
        dispatchPrecondition(condition: .onQueue(underlyingQueue))

        guard !$mutableState.isFinishing else { return }

        $mutableState.isFinishing = true

        if let error = error { self.error = error }

        // Start response handlers
        /// request完成，开始处理response相关工作
        processNextResponseSerializer()

        eventMonitor?.requestDidFinish(self)
    }

    /// Appends the response serialization closure to the instance.
    ///
    ///  - Note: This method will also `resume` the instance if `delegate.startImmediately` returns `true`.
    ///
    /// - Parameter closure: The closure containing the response serialization call.
    func appendResponseSerializer(_ closure: @escaping () -> Void) {
        $mutableState.write { mutableState in
            mutableState.responseSerializers.append(closure)
            
            if mutableState.state == .finished {
                mutableState.state = .resumed
            }

            if mutableState.responseSerializerProcessingFinished {
                underlyingQueue.async { self.processNextResponseSerializer() }
            }

            if mutableState.state.canTransitionTo(.resumed) {
                underlyingQueue.async { if self.delegate?.startImmediately == true { self.resume() } }
            }
        }
    }

    /// Returns the next response serializer closure to execute if there's one left.
    ///
    /// - Returns: The next response serialization closure, if there is one.
    func nextResponseSerializer() -> (() -> Void)? {
        var responseSerializer: (() -> Void)?

        $mutableState.write { mutableState in
            let responseSerializerIndex = mutableState.responseSerializerCompletions.count

            if responseSerializerIndex < mutableState.responseSerializers.count {
                responseSerializer = mutableState.responseSerializers[responseSerializerIndex]
            }
        }

        return responseSerializer
    }

    /// Processes the next response serializer and calls all completions if response serialization is complete.
    func processNextResponseSerializer() {
        guard let responseSerializer = nextResponseSerializer() else {
            // Execute all response serializer completions and clear them
            var completions: [() -> Void] = []

            $mutableState.write { mutableState in
                completions = mutableState.responseSerializerCompletions

                // Clear out all response serializers and response serializer completions in mutable state since the
                // request is complete. It's important to do this prior to calling the completion closures in case
                // the completions call back into the request triggering a re-processing of the response serializers.
                // An example of how this can happen is by calling cancel inside a response completion closure.
                mutableState.responseSerializers.removeAll()
                mutableState.responseSerializerCompletions.removeAll()

                if mutableState.state.canTransitionTo(.finished) {
                    mutableState.state = .finished
                }

                mutableState.responseSerializerProcessingFinished = true
                mutableState.isFinishing = false
            }
            /// 如果没有要处理的responseSerializer回调，就取出responseSerializerCompletions回调并依次执行
            completions.forEach { $0() }

            // Cleanup the request
            cleanup()

            return
        }

        serializationQueue.async { responseSerializer() }
    }

    /// Notifies the `Request` that the response serializer is complete.
    ///
    /// - Parameter completion: The completion handler provided with the response serializer, called when all serializers
    ///                         are complete.
    func responseSerializerDidComplete(completion: @escaping () -> Void) {
        $mutableState.write { $0.responseSerializerCompletions.append(completion) }
        processNextResponseSerializer()
    }

    /// Resets all task and response serializer related state for retry.
    func reset() {
        error = nil

        uploadProgress.totalUnitCount = 0
        uploadProgress.completedUnitCount = 0
        downloadProgress.totalUnitCount = 0
        downloadProgress.completedUnitCount = 0

        $mutableState.write { state in
            state.isFinishing = false
            state.responseSerializerCompletions = []
        }
    }

    /// Called when updating the upload progress.
    ///
    /// - Parameters:
    ///   - totalBytesSent: Total bytes sent so far.
    ///   - totalBytesExpectedToSend: Total bytes expected to send.
    func updateUploadProgress(totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        uploadProgress.totalUnitCount = totalBytesExpectedToSend
        uploadProgress.completedUnitCount = totalBytesSent
        uploadProgressHandler?.queue.async { self.uploadProgressHandler?.handler(self.uploadProgress) }
    }

    /// Perform a closure on the current `state` while locked.
    ///
    /// - Parameter perform: The closure to perform.
    func withState(perform: (State) -> Void) {
        $mutableState.withState(perform: perform)
    }

    // MARK: Task Creation

    /// Called when creating a `URLSessionTask` for this `Request`. Subclasses must override.
    ///
    /// - Parameters:
    ///   - request: `URLRequest` to use to create the `URLSessionTask`.
    ///   - session: `URLSession` which creates the `URLSessionTask`.
    ///
    /// - Returns:   The `URLSessionTask` created.
    func task(for request: URLRequest, using session: URLSession) -> URLSessionTask {
        fatalError("Subclasses must override.")
    }

    // MARK: - Public API

    // These APIs are callable from any queue.

    // MARK: State

    /// Cancels the instance. Once cancelled, a `Request` can no longer be resumed or suspended.
    ///
    /// - Returns: The instance.
    @discardableResult
    public func cancel() -> Self {
        $mutableState.write { mutableState in
            guard mutableState.state.canTransitionTo(.cancelled) else { return }

            mutableState.state = .cancelled

            underlyingQueue.async { self.didCancel() }

            guard let task = mutableState.tasks.last, task.state != .completed else {
                underlyingQueue.async { self.finish() }
                return
            }

            // Resume to ensure metrics are gathered.
            task.resume()
            task.cancel()
            underlyingQueue.async { self.didCancelTask(task) }
        }

        return self
    }

    /// Suspends the instance.
    ///
    /// - Returns: The instance.
    @discardableResult
    public func suspend() -> Self {
        $mutableState.write { mutableState in
            guard mutableState.state.canTransitionTo(.suspended) else { return }

            mutableState.state = .suspended

            underlyingQueue.async { self.didSuspend() }

            guard let task = mutableState.tasks.last, task.state != .completed else { return }

            task.suspend()
            underlyingQueue.async { self.didSuspendTask(task) }
        }

        return self
    }

    /// Resumes the instance.
    ///
    /// - Returns: The instance.
    @discardableResult
    public func resume() -> Self {
        $mutableState.write { mutableState in
            guard mutableState.state.canTransitionTo(.resumed) else { return }

            mutableState.state = .resumed

            underlyingQueue.async { self.didResume() }

            guard let task = mutableState.tasks.last, task.state != .completed else { return }

            task.resume()
            underlyingQueue.async { self.didResumeTask(task) }
        }

        return self
    }

    // MARK: - Closure API

    /// Associates a credential using the provided values with the instance.
    ///
    /// - Parameters:
    ///   - username:    The username.
    ///   - password:    The password.
    ///   - persistence: The `URLCredential.Persistence` for the created `URLCredential`. `.forSession` by default.
    ///
    /// - Returns:       The instance.
    @discardableResult
    public func authenticate(username: String, password: String, persistence: URLCredential.Persistence = .forSession) -> Self {
        let credential = URLCredential(user: username, password: password, persistence: persistence)
        /// Request可以直接使用点语法调用其他方法，因为Request的方法都返回了Self
        return authenticate(with: credential)
    }

    /// Associates the provided credential with the instance.
    ///
    /// - Parameter credential: The `URLCredential`.
    ///
    /// - Returns:              The instance.
    @discardableResult
    public func authenticate(with credential: URLCredential) -> Self {
        $mutableState.credential = credential

        return self
    }

    /// Sets a closure to be called periodically during the lifecycle of the instance as data is read from the server.
    ///
    /// - Note: Only the last closure provided is used.
    ///
    /// - Parameters:
    ///   - queue:   The `DispatchQueue` to execute the closure on. `.main` by default.
    ///   - closure: The closure to be executed periodically as data is read from the server.
    ///
    /// - Returns:   The instance.
    @discardableResult
    public func downloadProgress(queue: DispatchQueue = .main, closure: @escaping ProgressHandler) -> Self {
        $mutableState.downloadProgressHandler = (handler: closure, queue: queue)
        /// Request可以直接使用点语法调用downloadProgress方法，并设置好进度回调。因为Request的方法都返回了Self
        return self
    }

    /// Sets a closure to be called periodically during the lifecycle of the instance as data is sent to the server.
    ///
    /// - Note: Only the last closure provided is used.
    ///
    /// - Parameters:
    ///   - queue:   The `DispatchQueue` to execute the closure on. `.main` by default.
    ///   - closure: The closure to be executed periodically as data is sent to the server.
    ///
    /// - Returns:   The instance.
    @discardableResult
    public func uploadProgress(queue: DispatchQueue = .main, closure: @escaping ProgressHandler) -> Self {
        $mutableState.uploadProgressHandler = (handler: closure, queue: queue)

        return self
    }

    // MARK: Redirects

    /// Sets the redirect handler for the instance which will be used if a redirect response is encountered.
    ///
    /// - Note: Attempting to set the redirect handler more than once is a logic error and will crash.
    ///
    /// - Parameter handler: The `RedirectHandler`.
    ///
    /// - Returns:           The instance.
    @discardableResult
    public func redirect(using handler: RedirectHandler) -> Self {
        $mutableState.write { mutableState in
            precondition(mutableState.redirectHandler == nil, "Redirect handler has already been set.")
            mutableState.redirectHandler = handler
        }

        return self
    }

    // MARK: Cached Responses

    /// Sets the cached response handler for the `Request` which will be used when attempting to cache a response.
    ///
    /// - Note: Attempting to set the cache handler more than once is a logic error and will crash.
    ///
    /// - Parameter handler: The `CachedResponseHandler`.
    ///
    /// - Returns:           The instance.
    @discardableResult
    public func cacheResponse(using handler: CachedResponseHandler) -> Self {
        $mutableState.write { mutableState in
            precondition(mutableState.cachedResponseHandler == nil, "Cached response handler has already been set.")
            mutableState.cachedResponseHandler = handler
        }

        return self
    }

    // MARK: - Lifetime APIs

    
    /// Sets a handler to be called when the cURL description of the request is available.
    ///
    /// - Note: When waiting for a `Request`'s `URLRequest` to be created, only the last `handler` will be called.
    ///
    /// - Parameters:
    ///   - queue:   `DispatchQueue` on which `handler` will be called.
    ///   - handler: Closure to be called when the cURL description is available.
    ///
    /// - Returns:           The instance.
    @discardableResult
    public func cURLDescription(on queue: DispatchQueue, calling handler: @escaping (String) -> Void) -> Self {
        $mutableState.write { mutableState in
            if mutableState.requests.last != nil {
                queue.async { handler(self.cURLDescription()) }
            } else {
                mutableState.cURLHandler = (queue, handler)
            }
        }

        return self
    }
    
    /**
     cURLDescription(calling:) 方法的作用是，当 Request 可以提供 cURL 描述时，执行 handler 回调。
     mutableState.requests.last != nil 说明 Request 已经有 URLRequest，这时直接在 underlyingQueue 上调用 handler(self.cURLDescription())，立即执行回调。
     如果 Request 还没有 URLRequest，那么 mutableState.cURLHandler 会被赋值 (underlyingQueue, handler)，等待 URLRequest 生成后再执行。
     由于 mutableState.cURLHandler 只能存储一个 handler，如果在 URLRequest 生成前多次调用 cURLDescription(calling:)，那么 mutableState.cURLHandler 里的 handler 就会被后来的调用覆盖，只保留最后一个。
     */

    /// Sets a handler to be called when the cURL description of the request is available.
    ///
    /// - Note: When waiting for a `Request`'s `URLRequest` to be created, only the last `handler` will be called.
    ///
    /// - Parameter handler: Closure to be called when the cURL description is available. Called on the instance's
    ///                      `underlyingQueue` by default.
    ///
    /// - Returns:           The instance.
    @discardableResult
    public func cURLDescription(calling handler: @escaping (String) -> Void) -> Self {
        $mutableState.write { mutableState in
            if mutableState.requests.last != nil {
                underlyingQueue.async { handler(self.cURLDescription()) }
            } else {
                mutableState.cURLHandler = (underlyingQueue, handler)
            }
        }

        return self
    }

    /// Sets a closure to called whenever Alamofire creates a `URLRequest` for this instance.
    ///
    /// - Note: This closure will be called multiple times if the instance adapts incoming `URLRequest`s or is retried.
    ///
    /// - Parameters:
    ///   - queue:   `DispatchQueue` on which `handler` will be called. `.main` by default.
    ///   - handler: Closure to be called when a `URLRequest` is available.
    ///
    /// - Returns:   The instance.
    @discardableResult
    public func onURLRequestCreation(on queue: DispatchQueue = .main, perform handler: @escaping (URLRequest) -> Void) -> Self {
        $mutableState.write { state in
            if let request = state.requests.last { // Request在设置这个方法的回调时，URLRequest可能还没有创建
                queue.async { handler(request) }
            }
            // didCreateURLRequest方法中会调用urlRequestHandler
            state.urlRequestHandler = (queue, handler)
        }

        return self
    }

    /// Sets a closure to be called whenever the instance creates a `URLSessionTask`.
    ///
    /// - Note: This API should only be used to provide `URLSessionTask`s to existing API, like `NSFileProvider`. It
    ///         **SHOULD NOT** be used to interact with tasks directly, as that may be break Alamofire features.
    ///         Additionally, this closure may be called multiple times if the instance is retried.
    ///
    /// - Parameters:
    ///   - queue:   `DispatchQueue` on which `handler` will be called. `.main` by default.
    ///   - handler: Closure to be called when the `URLSessionTask` is available.
    ///
    /// - Returns:   The instance.
    @discardableResult
    public func onURLSessionTaskCreation(on queue: DispatchQueue = .main, perform handler: @escaping (URLSessionTask) -> Void) -> Self {
        $mutableState.write { state in
            if let task = state.tasks.last {
                queue.async { handler(task) }
            }
            /// didCreateTask中会调用urlSessionTaskHandler
            state.urlSessionTaskHandler = (queue, handler)
        }

        return self
    }

    // MARK: Cleanup

    /// Adds a `finishHandler` closure to be called when the request completes.
    ///
    /// - Parameter closure: Closure to be called when the request finishes.
    func onFinish(perform finishHandler: @escaping () -> Void) {
        guard !isFinished else { finishHandler(); return }

        $mutableState.write { state in
            state.finishHandlers.append(finishHandler)
        }
    }

    /// Final cleanup step executed when the instance finishes response serialization.
    func cleanup() {
        delegate?.cleanup(after: self)
        let handlers = $mutableState.finishHandlers
        handlers.forEach { $0() }
        $mutableState.write { state in
            state.finishHandlers.removeAll()
        }
    }
}

// MARK: - Protocol Conformances

extension Request: Equatable {
    public static func ==(lhs: Request, rhs: Request) -> Bool {
        lhs.id == rhs.id
    }
}

extension Request: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Request: CustomStringConvertible {
    /// A textual representation of this instance, including the `HTTPMethod` and `URL` if the `URLRequest` has been
    /// created, as well as the response status code, if a response has been received.
    public var description: String {
        guard let request = performedRequests.last ?? lastRequest,
              let url = request.url,
              let method = request.httpMethod else { return "No request created yet." }

        let requestDescription = "\(method) \(url.absoluteString)"

        return response.map { "\(requestDescription) (\($0.statusCode))" } ?? requestDescription
    }
}

extension Request {
    /// cURL representation of the instance.
    ///
    /// - Returns: The cURL equivalent of the instance.
    public func cURLDescription() -> String {
        guard
            let request = lastRequest,
            let url = request.url,
            let host = url.host,
            let method = request.httpMethod else { return "$ curl command could not be created" }

        var components = ["$ curl -v"]

        components.append("-X \(method)")

        if let credentialStorage = delegate?.sessionConfiguration.urlCredentialStorage {
            let protectionSpace = URLProtectionSpace(host: host,
                                                     port: url.port ?? 0,
                                                     protocol: url.scheme,
                                                     realm: host,
                                                     authenticationMethod: NSURLAuthenticationMethodHTTPBasic)

            if let credentials = credentialStorage.credentials(for: protectionSpace)?.values {
                for credential in credentials {
                    guard let user = credential.user, let password = credential.password else { continue }
                    components.append("-u \(user):\(password)")
                }
            } else {
                if let credential = credential, let user = credential.user, let password = credential.password {
                    components.append("-u \(user):\(password)")
                }
            }
        }

        if let configuration = delegate?.sessionConfiguration, configuration.httpShouldSetCookies {
            if
                let cookieStorage = configuration.httpCookieStorage,
                let cookies = cookieStorage.cookies(for: url), !cookies.isEmpty {
                let allCookies = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: ";")

                components.append("-b \"\(allCookies)\"")
            }
        }

        var headers = HTTPHeaders()

        if let sessionHeaders = delegate?.sessionConfiguration.headers {
            for header in sessionHeaders where header.name != "Cookie" {
                headers[header.name] = header.value
            }
        }

        for header in request.headers where header.name != "Cookie" {
            headers[header.name] = header.value
        }

        for header in headers {
            let escapedValue = header.value.replacingOccurrences(of: "\"", with: "\\\"")
            components.append("-H \"\(header.name): \(escapedValue)\"")
        }

        if let httpBodyData = request.httpBody {
            let httpBody = String(decoding: httpBodyData, as: UTF8.self)
            var escapedBody = httpBody.replacingOccurrences(of: "\\\"", with: "\\\\\"")
            escapedBody = escapedBody.replacingOccurrences(of: "\"", with: "\\\"")

            components.append("-d \"\(escapedBody)\"")
        }

        components.append("\"\(url.absoluteString)\"")

        return components.joined(separator: " \\\n\t")
    }
}

/// Protocol abstraction for `Request`'s communication back to the `SessionDelegate`.
public protocol RequestDelegate: AnyObject {
    /// `URLSessionConfiguration` used to create the underlying `URLSessionTask`s.
    var sessionConfiguration: URLSessionConfiguration { get }

    /// Determines whether the `Request` should automatically call `resume()` when adding the first response handler.
    var startImmediately: Bool { get }

    /// Notifies the delegate the `Request` has reached a point where it needs cleanup.
    ///
    /// - Parameter request: The `Request` to cleanup after.
    func cleanup(after request: Request)

    /// Asynchronously ask the delegate whether a `Request` will be retried.
    ///
    /// - Parameters:
    ///   - request:    `Request` which failed.
    ///   - error:      `Error` which produced the failure.
    ///   - completion: Closure taking the `RetryResult` for evaluation.
    func retryResult(for request: Request, dueTo error: AFError, completion: @escaping (RetryResult) -> Void)

    /// Asynchronously retry the `Request`.
    ///
    /// - Parameters:
    ///   - request:   `Request` which will be retried.
    ///   - timeDelay: `TimeInterval` after which the retry will be triggered.
    func retryRequest(_ request: Request, withDelay timeDelay: TimeInterval?)
}

// MARK: - Subclasses

// MARK: - DataRequest

/// `Request` subclass which handles in-memory `Data` download using `URLSessionDataTask`.
public class DataRequest: Request {
    /// `URLRequestConvertible` value used to create `URLRequest`s for this instance.
    public let convertible: URLRequestConvertible
    /// `Data` read from the server so far.
    public var data: Data? { mutableData }

    /// Protected storage for the `Data` read by the instance.
    @Protected
    private var mutableData: Data? = nil

    /// Creates a `DataRequest` using the provided parameters.
    ///
    /// - Parameters:
    ///   - id:                 `UUID` used for the `Hashable` and `Equatable` implementations. `UUID()` by default.
    ///   - convertible:        `URLRequestConvertible` value used to create `URLRequest`s for this instance.
    ///   - underlyingQueue:    `DispatchQueue` on which all internal `Request` work is performed.
    ///   - serializationQueue: `DispatchQueue` on which all serialization work is performed. By default targets
    ///                         `underlyingQueue`, but can be passed another queue from a `Session`.
    ///   - eventMonitor:       `EventMonitor` called for event callbacks from internal `Request` actions.
    ///   - interceptor:        `RequestInterceptor` used throughout the request lifecycle.
    ///   - delegate:           `RequestDelegate` that provides an interface to actions not performed by the `Request`.
    init(id: UUID = UUID(),
         convertible: URLRequestConvertible,
         underlyingQueue: DispatchQueue,
         serializationQueue: DispatchQueue,
         eventMonitor: EventMonitor?,
         interceptor: RequestInterceptor?,
         delegate: RequestDelegate) {
        self.convertible = convertible

        super.init(id: id,
                   underlyingQueue: underlyingQueue,
                   serializationQueue: serializationQueue,
                   eventMonitor: eventMonitor,
                   interceptor: interceptor,
                   delegate: delegate)
    }

    override func reset() {
        super.reset()

        mutableData = nil
    }

    /// Called when `Data` is received by this instance.
    ///
    /// - Note: Also calls `updateDownloadProgress`.
    ///
    /// - Parameter data: The `Data` received.
    func didReceive(data: Data) {
        if self.data == nil {
            mutableData = data
        } else {
            $mutableData.write { $0?.append(data) }
        }

        updateDownloadProgress()
    }

    override func task(for request: URLRequest, using session: URLSession) -> URLSessionTask {
        let copiedRequest = request
        return session.dataTask(with: copiedRequest)
    }

    /// Called to update the `downloadProgress` of the instance.
    func updateDownloadProgress() {
        let totalBytesReceived = Int64(data?.count ?? 0)
        let totalBytesExpected = task?.response?.expectedContentLength ?? NSURLSessionTransferSizeUnknown

        downloadProgress.totalUnitCount = totalBytesExpected
        downloadProgress.completedUnitCount = totalBytesReceived

        downloadProgressHandler?.queue.async { self.downloadProgressHandler?.handler(self.downloadProgress) }
    }

    /// Validates the request, using the specified closure.
    ///
    /// - Note: If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - Parameter validation: `Validation` closure used to validate the response.
    ///
    /// - Returns:              The instance.
    @discardableResult
    public func validate(_ validation: @escaping Validation) -> Self {
        let validator: () -> Void = { [unowned self] in
            guard self.error == nil, let response = self.response else { return }

            let result = validation(self.request, response, self.data)

            if case let .failure(error) = result { self.error = error.asAFError(or: .responseValidationFailed(reason: .customValidationFailed(error: error))) }

            self.eventMonitor?.request(self,
                                       didValidateRequest: self.request,
                                       response: response,
                                       data: self.data,
                                       withResult: result)
        }

        $validators.write { $0.append(validator) }

        return self
    }
}

// MARK: - DataStreamRequest

/// `Request` subclass which streams HTTP response `Data` through a `Handler` closure.
public final class DataStreamRequest: Request {
    /// Closure type handling `DataStreamRequest.Stream` values.
    public typealias Handler<Success, Failure: Error> = (Stream<Success, Failure>) throws -> Void

    /// Type encapsulating an `Event` as it flows through the stream, as well as a `CancellationToken` which can be used
    /// to stop the stream at any time.
    public struct Stream<Success, Failure: Error> {
        /// Latest `Event` from the stream.
        public let event: Event<Success, Failure>
        /// Token used to cancel the stream.
        public let token: CancellationToken

        /// Cancel the ongoing stream by canceling the underlying `DataStreamRequest`.
        public func cancel() {
            token.cancel()
        }
    }

    /// Type representing an event flowing through the stream. Contains either the `Result` of processing streamed
    /// `Data` or the completion of the stream.
    public enum Event<Success, Failure: Error> {
        /// Output produced every time the instance receives additional `Data`. The associated value contains the
        /// `Result` of processing the incoming `Data`.
        case stream(Result<Success, Failure>)
        /// Output produced when the instance has completed, whether due to stream end, cancellation, or an error.
        /// Associated `Completion` value contains the final state.
        case complete(Completion)
    }

    /// Value containing the state of a `DataStreamRequest` when the stream was completed.
    public struct Completion {
        /// Last `URLRequest` issued by the instance.
        public let request: URLRequest?
        /// Last `HTTPURLResponse` received by the instance.
        public let response: HTTPURLResponse?
        /// Last `URLSessionTaskMetrics` produced for the instance.
        public let metrics: URLSessionTaskMetrics?
        /// `AFError` produced for the instance, if any.
        public let error: AFError?
    }

    /// Type used to cancel an ongoing stream.
    public struct CancellationToken {
        weak var request: DataStreamRequest?

        init(_ request: DataStreamRequest) {
            self.request = request
        }

        /// Cancel the ongoing stream by canceling the underlying `DataStreamRequest`.
        public func cancel() {
            request?.cancel()
        }
    }

    /// `URLRequestConvertible` value used to create `URLRequest`s for this instance.
    public let convertible: URLRequestConvertible
    /// Whether or not the instance will be cancelled if stream parsing encounters an error.
    public let automaticallyCancelOnStreamError: Bool

    /// Internal mutable state specific to this type.
    struct StreamMutableState {
        /// `OutputStream` bound to the `InputStream` produced by `asInputStream`, if it has been called.
        var outputStream: OutputStream?
        /// Stream closures called as `Data` is received.
        var streams: [(_ data: Data) -> Void] = []
        /// Number of currently executing streams. Used to ensure completions are only fired after all streams are
        /// enqueued.
        var numberOfExecutingStreams = 0
        /// Completion calls enqueued while streams are still executing.
        var enqueuedCompletionEvents: [() -> Void] = []
    }

    @Protected
    var streamMutableState = StreamMutableState()

    /// Creates a `DataStreamRequest` using the provided parameters.
    ///
    /// - Parameters:
    ///   - id:                               `UUID` used for the `Hashable` and `Equatable` implementations. `UUID()`
    ///                                        by default.
    ///   - convertible:                      `URLRequestConvertible` value used to create `URLRequest`s for this
    ///                                        instance.
    ///   - automaticallyCancelOnStreamError: `Bool` indicating whether the instance will be cancelled when an `Error`
    ///                                       is thrown while serializing stream `Data`.
    ///   - underlyingQueue:                  `DispatchQueue` on which all internal `Request` work is performed.
    ///   - serializationQueue:               `DispatchQueue` on which all serialization work is performed. By default
    ///                                       targets
    ///                                       `underlyingQueue`, but can be passed another queue from a `Session`.
    ///   - eventMonitor:                     `EventMonitor` called for event callbacks from internal `Request` actions.
    ///   - interceptor:                      `RequestInterceptor` used throughout the request lifecycle.
    ///   - delegate:                         `RequestDelegate` that provides an interface to actions not performed by
    ///                                       the `Request`.
    init(id: UUID = UUID(),
         convertible: URLRequestConvertible,
         automaticallyCancelOnStreamError: Bool,
         underlyingQueue: DispatchQueue,
         serializationQueue: DispatchQueue,
         eventMonitor: EventMonitor?,
         interceptor: RequestInterceptor?,
         delegate: RequestDelegate) {
        self.convertible = convertible
        self.automaticallyCancelOnStreamError = automaticallyCancelOnStreamError

        super.init(id: id,
                   underlyingQueue: underlyingQueue,
                   serializationQueue: serializationQueue,
                   eventMonitor: eventMonitor,
                   interceptor: interceptor,
                   delegate: delegate)
    }

    override func task(for request: URLRequest, using session: URLSession) -> URLSessionTask {
        let copiedRequest = request
        return session.dataTask(with: copiedRequest)
    }

    override func finish(error: AFError? = nil) {
        $streamMutableState.write { state in
            state.outputStream?.close()
        }

        super.finish(error: error)
    }

    func didReceive(data: Data) {
        $streamMutableState.write { state in
            #if !(os(Linux) || os(Windows))
            if let stream = state.outputStream {
                underlyingQueue.async {
                    var bytes = Array(data)
                    stream.write(&bytes, maxLength: bytes.count)
                }
            }
            #endif
            state.numberOfExecutingStreams += state.streams.count
            let localState = state
            underlyingQueue.async { localState.streams.forEach { $0(data) } }
        }
    }

    /// Validates the `URLRequest` and `HTTPURLResponse` received for the instance using the provided `Validation` closure.
    ///
    /// - Parameter validation: `Validation` closure used to validate the request and response.
    ///
    /// - Returns:              The `DataStreamRequest`.
    @discardableResult
    public func validate(_ validation: @escaping Validation) -> Self {
        let validator: () -> Void = { [unowned self] in
            guard self.error == nil, let response = self.response else { return }

            let result = validation(self.request, response)

            if case let .failure(error) = result {
                self.error = error.asAFError(or: .responseValidationFailed(reason: .customValidationFailed(error: error)))
            }

            self.eventMonitor?.request(self,
                                       didValidateRequest: self.request,
                                       response: response,
                                       withResult: result)
        }

        $validators.write { $0.append(validator) }

        return self
    }

    #if !(os(Linux) || os(Windows))
    /// Produces an `InputStream` that receives the `Data` received by the instance.
    ///
    /// - Note: The `InputStream` produced by this method must have `open()` called before being able to read `Data`.
    ///         Additionally, this method will automatically call `resume()` on the instance, regardless of whether or
    ///         not the creating session has `startRequestsImmediately` set to `true`.
    ///
    /// - Parameter bufferSize: Size, in bytes, of the buffer between the `OutputStream` and `InputStream`.
    ///
    /// - Returns:              The `InputStream` bound to the internal `OutboundStream`.
    public func asInputStream(bufferSize: Int = 1024) -> InputStream? {
        defer { resume() }

        var inputStream: InputStream?
        $streamMutableState.write { state in
            Foundation.Stream.getBoundStreams(withBufferSize: bufferSize,
                                              inputStream: &inputStream,
                                              outputStream: &state.outputStream)
            state.outputStream?.open()
        }

        return inputStream
    }
    #endif

    func capturingError(from closure: () throws -> Void) {
        do {
            try closure()
        } catch {
            self.error = error.asAFError(or: .responseSerializationFailed(reason: .customSerializationFailed(error: error)))
            cancel()
        }
    }

    func appendStreamCompletion<Success, Failure>(on queue: DispatchQueue,
                                                  stream: @escaping Handler<Success, Failure>) {
        appendResponseSerializer {
            self.underlyingQueue.async {
                self.responseSerializerDidComplete {
                    self.$streamMutableState.write { state in
                        guard state.numberOfExecutingStreams == 0 else {
                            state.enqueuedCompletionEvents.append {
                                self.enqueueCompletion(on: queue, stream: stream)
                            }

                            return
                        }

                        self.enqueueCompletion(on: queue, stream: stream)
                    }
                }
            }
        }
    }

    func enqueueCompletion<Success, Failure>(on queue: DispatchQueue,
                                             stream: @escaping Handler<Success, Failure>) {
        queue.async {
            do {
                let completion = Completion(request: self.request,
                                            response: self.response,
                                            metrics: self.metrics,
                                            error: self.error)
                try stream(.init(event: .complete(completion), token: .init(self)))
            } catch {
                // Ignore error, as errors on Completion can't be handled anyway.
            }
        }
    }
}

extension DataStreamRequest.Stream {
    /// Incoming `Result` values from `Event.stream`.
    public var result: Result<Success, Failure>? {
        guard case let .stream(result) = event else { return nil }

        return result
    }

    /// `Success` value of the instance, if any.
    public var value: Success? {
        guard case let .success(value) = result else { return nil }

        return value
    }

    /// `Failure` value of the instance, if any.
    public var error: Failure? {
        guard case let .failure(error) = result else { return nil }

        return error
    }

    /// `Completion` value of the instance, if any.
    public var completion: DataStreamRequest.Completion? {
        guard case let .complete(completion) = event else { return nil }

        return completion
    }
}

// MARK: - DownloadRequest

/// `Request` subclass which downloads `Data` to a file on disk using `URLSessionDownloadTask`.
public class DownloadRequest: Request {
    /// A set of options to be executed prior to moving a downloaded file from the temporary `URL` to the destination
    /// `URL`.
    public struct Options: OptionSet {
        /// Specifies that intermediate directories for the destination URL should be created.
        public static let createIntermediateDirectories = Options(rawValue: 1 << 0)
        /// Specifies that any previous file at the destination `URL` should be removed.
        public static let removePreviousFile = Options(rawValue: 1 << 1)

        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
    }

    // MARK: Destination

    /// A closure executed once a `DownloadRequest` has successfully completed in order to determine where to move the
    /// temporary file written to during the download process. The closure takes two arguments: the temporary file URL
    /// and the `HTTPURLResponse`, and returns two values: the file URL where the temporary file should be moved and
    /// the options defining how the file should be moved.
    ///
    /// - Note: Downloads from a local `file://` `URL`s do not use the `Destination` closure, as those downloads do not
    ///         return an `HTTPURLResponse`. Instead the file is merely moved within the temporary directory.
    public typealias Destination = (_ temporaryURL: URL,
                                    _ response: HTTPURLResponse) -> (destinationURL: URL, options: Options)

    /// Creates a download file destination closure which uses the default file manager to move the temporary file to a
    /// file URL in the first available directory with the specified search path directory and search path domain mask.
    ///
    /// - Parameters:
    ///   - directory: The search path directory. `.documentDirectory` by default.
    ///   - domain:    The search path domain mask. `.userDomainMask` by default.
    ///   - options:   `DownloadRequest.Options` used when moving the downloaded file to its destination. None by
    ///                default.
    /// - Returns: The `Destination` closure.
    public class func suggestedDownloadDestination(for directory: FileManager.SearchPathDirectory = .documentDirectory,
                                                   in domain: FileManager.SearchPathDomainMask = .userDomainMask,
                                                   options: Options = []) -> Destination {
        { temporaryURL, response in
            let directoryURLs = FileManager.default.urls(for: directory, in: domain)
            let url = directoryURLs.first?.appendingPathComponent(response.suggestedFilename!) ?? temporaryURL

            return (url, options)
        }
    }

    /// Default `Destination` used by Alamofire to ensure all downloads persist. This `Destination` prepends
    /// `Alamofire_` to the automatically generated download name and moves it within the temporary directory. Files
    /// with this destination must be additionally moved if they should survive the system reclamation of temporary
    /// space.
    static let defaultDestination: Destination = { url, _ in
        (defaultDestinationURL(url), [])
    }

    /// Default `URL` creation closure. Creates a `URL` in the temporary directory with `Alamofire_` prepended to the
    /// provided file name.
    static let defaultDestinationURL: (URL) -> URL = { url in
        let filename = "Alamofire_\(url.lastPathComponent)"
        let destination = url.deletingLastPathComponent().appendingPathComponent(filename)

        return destination
    }

    // MARK: Downloadable

    /// Type describing the source used to create the underlying `URLSessionDownloadTask`.
    public enum Downloadable {
        /// Download should be started from the `URLRequest` produced by the associated `URLRequestConvertible` value.
        case request(URLRequestConvertible)
        /// Download should be started from the associated resume `Data` value.
        case resumeData(Data)
    }

    // MARK: Mutable State

    /// Type containing all mutable state for `DownloadRequest` instances.
    private struct DownloadRequestMutableState {
        /// Possible resume `Data` produced when cancelling the instance.
        var resumeData: Data?
        /// `URL` to which `Data` is being downloaded.
        var fileURL: URL?
    }

    /// Protected mutable state specific to `DownloadRequest`.
    @Protected
    private var mutableDownloadState = DownloadRequestMutableState()

    /// If the download is resumable and is eventually cancelled or fails, this value may be used to resume the download
    /// using the `download(resumingWith data:)` API.
    ///
    /// - Note: For more information about `resumeData`, see [Apple's documentation](https://developer.apple.com/documentation/foundation/urlsessiondownloadtask/1411634-cancel).
    public var resumeData: Data? {
        #if !(os(Linux) || os(Windows))
        return $mutableDownloadState.resumeData ?? error?.downloadResumeData
        #else
        return $mutableDownloadState.resumeData
        #endif
    }

    /// If the download is successful, the `URL` where the file was downloaded.
    public var fileURL: URL? { $mutableDownloadState.fileURL }

    // MARK: Initial State

    /// `Downloadable` value used for this instance.
    public let downloadable: Downloadable
    /// The `Destination` to which the downloaded file is moved.
    let destination: Destination

    /// Creates a `DownloadRequest` using the provided parameters.
    ///
    /// - Parameters:
    ///   - id:                 `UUID` used for the `Hashable` and `Equatable` implementations. `UUID()` by default.
    ///   - downloadable:       `Downloadable` value used to create `URLSessionDownloadTasks` for the instance.
    ///   - underlyingQueue:    `DispatchQueue` on which all internal `Request` work is performed.
    ///   - serializationQueue: `DispatchQueue` on which all serialization work is performed. By default targets
    ///                         `underlyingQueue`, but can be passed another queue from a `Session`.
    ///   - eventMonitor:       `EventMonitor` called for event callbacks from internal `Request` actions.
    ///   - interceptor:        `RequestInterceptor` used throughout the request lifecycle.
    ///   - delegate:           `RequestDelegate` that provides an interface to actions not performed by the `Request`
    ///   - destination:        `Destination` closure used to move the downloaded file to its final location.
    init(id: UUID = UUID(),
         downloadable: Downloadable,
         underlyingQueue: DispatchQueue,
         serializationQueue: DispatchQueue,
         eventMonitor: EventMonitor?,
         interceptor: RequestInterceptor?,
         delegate: RequestDelegate,
         destination: @escaping Destination) {
        self.downloadable = downloadable
        self.destination = destination

        super.init(id: id,
                   underlyingQueue: underlyingQueue,
                   serializationQueue: serializationQueue,
                   eventMonitor: eventMonitor,
                   interceptor: interceptor,
                   delegate: delegate)
    }

    override func reset() {
        super.reset()

        $mutableDownloadState.write {
            $0.resumeData = nil
            $0.fileURL = nil
        }
    }

    /// Called when a download has finished.
    ///
    /// - Parameters:
    ///   - task:   `URLSessionTask` that finished the download.
    ///   - result: `Result` of the automatic move to `destination`.
    func didFinishDownloading(using task: URLSessionTask, with result: Result<URL, AFError>) {
        eventMonitor?.request(self, didFinishDownloadingUsing: task, with: result)

        switch result {
        case let .success(url): $mutableDownloadState.fileURL = url
        case let .failure(error): self.error = error
        }
    }

    /// Updates the `downloadProgress` using the provided values.
    ///
    /// - Parameters:
    ///   - bytesWritten:              Total bytes written so far.
    ///   - totalBytesExpectedToWrite: Total bytes expected to write.
    func updateDownloadProgress(bytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        downloadProgress.totalUnitCount = totalBytesExpectedToWrite
        downloadProgress.completedUnitCount += bytesWritten

        downloadProgressHandler?.queue.async { self.downloadProgressHandler?.handler(self.downloadProgress) }
    }

    override func task(for request: URLRequest, using session: URLSession) -> URLSessionTask {
        session.downloadTask(with: request)
    }

    /// Creates a `URLSessionTask` from the provided resume data.
    ///
    /// - Parameters:
    ///   - data:    `Data` used to resume the download.
    ///   - session: `URLSession` used to create the `URLSessionTask`.
    ///
    /// - Returns:   The `URLSessionTask` created.
    public func task(forResumeData data: Data, using session: URLSession) -> URLSessionTask {
        session.downloadTask(withResumeData: data)
    }

    /// Cancels the instance. Once cancelled, a `DownloadRequest` can no longer be resumed or suspended.
    ///
    /// - Note: This method will NOT produce resume data. If you wish to cancel and produce resume data, use
    ///         `cancel(producingResumeData:)` or `cancel(byProducingResumeData:)`.
    ///
    /// - Returns: The instance.
    @discardableResult
    override public func cancel() -> Self {
        cancel(producingResumeData: false)
    }

    /// Cancels the instance, optionally producing resume data. Once cancelled, a `DownloadRequest` can no longer be
    /// resumed or suspended.
    ///
    /// - Note: If `producingResumeData` is `true`, the `resumeData` property will be populated with any resume data, if
    ///         available.
    ///
    /// - Returns: The instance.
    @discardableResult
    public func cancel(producingResumeData shouldProduceResumeData: Bool) -> Self {
        cancel(optionallyProducingResumeData: shouldProduceResumeData ? { _ in } : nil)
    }

    /// Cancels the instance while producing resume data. Once cancelled, a `DownloadRequest` can no longer be resumed
    /// or suspended.
    ///
    /// - Note: The resume data passed to the completion handler will also be available on the instance's `resumeData`
    ///         property.
    ///
    /// - Parameter completionHandler: The completion handler that is called when the download has been successfully
    ///                                cancelled. It is not guaranteed to be called on a particular queue, so you may
    ///                                want use an appropriate queue to perform your work.
    ///
    /// - Returns:                     The instance.
    @discardableResult
    public func cancel(byProducingResumeData completionHandler: @escaping (_ data: Data?) -> Void) -> Self {
        cancel(optionallyProducingResumeData: completionHandler)
    }

    /// Internal implementation of cancellation that optionally takes a resume data handler. If no handler is passed,
    /// cancellation is performed without producing resume data.
    ///
    /// - Parameter completionHandler: Optional resume data handler.
    ///
    /// - Returns:                     The instance.
    private func cancel(optionallyProducingResumeData completionHandler: ((_ resumeData: Data?) -> Void)?) -> Self {
        $mutableState.write { mutableState in
            guard mutableState.state.canTransitionTo(.cancelled) else { return }

            mutableState.state = .cancelled

            underlyingQueue.async { self.didCancel() }

            guard let task = mutableState.tasks.last as? URLSessionDownloadTask, task.state != .completed else {
                underlyingQueue.async { self.finish() }
                return
            }

            if let completionHandler = completionHandler {
                // Resume to ensure metrics are gathered.
                task.resume()
                task.cancel { resumeData in
                    self.$mutableDownloadState.resumeData = resumeData
                    self.underlyingQueue.async { self.didCancelTask(task) }
                    completionHandler(resumeData)
                }
            } else {
                // Resume to ensure metrics are gathered.
                task.resume()
                task.cancel()
                self.underlyingQueue.async { self.didCancelTask(task) }
            }
        }

        return self
    }

    /// Validates the request, using the specified closure.
    ///
    /// - Note: If validation fails, subsequent calls to response handlers will have an associated error.
    ///
    /// - Parameter validation: `Validation` closure to validate the response.
    ///
    /// - Returns:              The instance.
    @discardableResult
    public func validate(_ validation: @escaping Validation) -> Self {
        let validator: () -> Void = { [unowned self] in
            guard self.error == nil, let response = self.response else { return }

            let result = validation(self.request, response, self.fileURL)

            if case let .failure(error) = result {
                self.error = error.asAFError(or: .responseValidationFailed(reason: .customValidationFailed(error: error)))
            }

            self.eventMonitor?.request(self,
                                       didValidateRequest: self.request,
                                       response: response,
                                       fileURL: self.fileURL,
                                       withResult: result)
        }

        $validators.write { $0.append(validator) }

        return self
    }
}

// MARK: - UploadRequest

/// `DataRequest` subclass which handles `Data` upload from memory, file, or stream using `URLSessionUploadTask`.
public class UploadRequest: DataRequest {
    /// Type describing the origin of the upload, whether `Data`, file, or stream.
    public enum Uploadable {
        /// Upload from the provided `Data` value.
        case data(Data)
        /// Upload from the provided file `URL`, as well as a `Bool` determining whether the source file should be
        /// automatically removed once uploaded.
        case file(URL, shouldRemove: Bool)
        /// Upload from the provided `InputStream`.
        case stream(InputStream)
    }

    // MARK: Initial State

    /// The `UploadableConvertible` value used to produce the `Uploadable` value for this instance.
    public let upload: UploadableConvertible

    /// `FileManager` used to perform cleanup tasks, including the removal of multipart form encoded payloads written
    /// to disk.
    public let fileManager: FileManager

    // MARK: Mutable State

    /// `Uploadable` value used by the instance.
    public var uploadable: Uploadable?

    /// Creates an `UploadRequest` using the provided parameters.
    ///
    /// - Parameters:
    ///   - id:                 `UUID` used for the `Hashable` and `Equatable` implementations. `UUID()` by default.
    ///   - convertible:        `UploadConvertible` value used to determine the type of upload to be performed.
    ///   - underlyingQueue:    `DispatchQueue` on which all internal `Request` work is performed.
    ///   - serializationQueue: `DispatchQueue` on which all serialization work is performed. By default targets
    ///                         `underlyingQueue`, but can be passed another queue from a `Session`.
    ///   - eventMonitor:       `EventMonitor` called for event callbacks from internal `Request` actions.
    ///   - interceptor:        `RequestInterceptor` used throughout the request lifecycle.
    ///   - fileManager:        `FileManager` used to perform cleanup tasks, including the removal of multipart form
    ///                         encoded payloads written to disk.
    ///   - delegate:           `RequestDelegate` that provides an interface to actions not performed by the `Request`.
    init(id: UUID = UUID(),
         convertible: UploadConvertible,
         underlyingQueue: DispatchQueue,
         serializationQueue: DispatchQueue,
         eventMonitor: EventMonitor?,
         interceptor: RequestInterceptor?,
         fileManager: FileManager,
         delegate: RequestDelegate) {
        upload = convertible
        self.fileManager = fileManager

        super.init(id: id,
                   convertible: convertible,
                   underlyingQueue: underlyingQueue,
                   serializationQueue: serializationQueue,
                   eventMonitor: eventMonitor,
                   interceptor: interceptor,
                   delegate: delegate)
    }

    /// Called when the `Uploadable` value has been created from the `UploadConvertible`.
    ///
    /// - Parameter uploadable: The `Uploadable` that was created.
    func didCreateUploadable(_ uploadable: Uploadable) {
        self.uploadable = uploadable

        eventMonitor?.request(self, didCreateUploadable: uploadable)
    }

    /// Called when the `Uploadable` value could not be created.
    ///
    /// - Parameter error: `AFError` produced by the failure.
    func didFailToCreateUploadable(with error: AFError) {
        self.error = error

        eventMonitor?.request(self, didFailToCreateUploadableWithError: error)

        retryOrFinish(error: error)
    }

    override func task(for request: URLRequest, using session: URLSession) -> URLSessionTask {
        guard let uploadable = uploadable else {
            fatalError("Attempting to create a URLSessionUploadTask when Uploadable value doesn't exist.")
        }

        switch uploadable {
        case let .data(data): return session.uploadTask(with: request, from: data)
        case let .file(url, _): return session.uploadTask(with: request, fromFile: url)
        case .stream: return session.uploadTask(withStreamedRequest: request)
        }
    }

    override func reset() {
        // Uploadable must be recreated on every retry.
        uploadable = nil

        super.reset()
    }

    /// Produces the `InputStream` from `uploadable`, if it can.
    ///
    /// - Note: Calling this method with a non-`.stream` `Uploadable` is a logic error and will crash.
    ///
    /// - Returns: The `InputStream`.
    func inputStream() -> InputStream {
        guard let uploadable = uploadable else {
            fatalError("Attempting to access the input stream but the uploadable doesn't exist.")
        }

        guard case let .stream(stream) = uploadable else {
            fatalError("Attempted to access the stream of an UploadRequest that wasn't created with one.")
        }

        eventMonitor?.request(self, didProvideInputStream: stream)

        return stream
    }

    override public func cleanup() {
        defer { super.cleanup() }

        guard
            let uploadable = uploadable,
            case let .file(url, shouldRemove) = uploadable,
            shouldRemove
        else { return }

        try? fileManager.removeItem(at: url)
    }
}

/// A type that can produce an `UploadRequest.Uploadable` value.
public protocol UploadableConvertible {
    /// Produces an `UploadRequest.Uploadable` value from the instance.
    ///
    /// - Returns: The `UploadRequest.Uploadable`.
    /// - Throws:  Any `Error` produced during creation.
    func createUploadable() throws -> UploadRequest.Uploadable
}

extension UploadRequest.Uploadable: UploadableConvertible {
    public func createUploadable() throws -> UploadRequest.Uploadable {
        self
    }
}

/// A type that can be converted to an upload, whether from an `UploadRequest.Uploadable` or `URLRequestConvertible`.
public protocol UploadConvertible: UploadableConvertible & URLRequestConvertible {}
