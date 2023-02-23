//
//  NetworkReachabilityManager.swift
//  my_swift
//
//  Created by sunchunlei on 2022/11/6.
//
#if !(os(watchOS) || os(Linux) || os(Windows))
import Foundation
import SystemConfiguration



/**
 * 枚举的详细分析 https://www.jianshu.com/p/d25860cf8757
 */
open class NetworkReachabilityManager{
    
    public enum NetworkReachabilityStatus{
        
        case unknown
        
        case notReachable
        // 设置关联值
        case reachable(ConnectionType)
        
        // 枚举的初始化器
        init(_ flags:SCNetworkReachabilityFlags){
            
            /**
             * 枚举语法
             * https://swiftgg.gitbook.io/swift/swift-jiao-cheng/08_enumerations#enumeration-syntax
             * 当枚举变量的类型已知时，为其赋值可以省略枚举类型名。在使用具有显式类型的枚举值时，这种写法让代码具有更好的可读性
             *
             * 如 self = .notReachable
             * self 的类型肯定是NetworkReachabilityStatus类型，所以可以 .notReachable
             * 如 .reachable(.ethernetOrWiFi)
             * 因为 reachable(ConnectionType)设置的关联类型是ConnectionType，所以也可 .ethernetOrWiFi
             */
            guard flags.isActuallyReachable else { self = .notReachable; return }

            /**
             *  因为 reachable(ConnectionType)设置的关联类型是ConnectionType，所以也可 .ethernetOrWiFi
             */
            var networkStatus: NetworkReachabilityStatus = .reachable(.ethernetOrWiFi)

//            var networkStatus: NetworkReachabilityStatus = .reachable(ConnectionType.ethernetOrWiFi)
            
            if flags.isCellular {networkStatus = .reachable(.cellular)}
            
            /// self 可以是.reachable(.cellular) 即case是.reachable，只不过.reachable有个关联值
            self = networkStatus
            
        }
    
        
        /**
         * 嵌套类型
         * https://swiftgg.gitbook.io/swift/swift-jiao-cheng/19_nested_types#nested-types-in-action
         * https://swiftgg.gitbook.io/swift/swift-jiao-cheng/26_access_control#nested-types
         */
        public enum ConnectionType {
            case ethernetOrWiFi
            case cellular
        }
    }
    
    //
    public typealias Listener = (NetworkReachabilityStatus) -> Void
    
    public static let `default` = NetworkReachabilityManager()
    
    // MARK: - Properties
    /**
     * 计算属性
     * - 只读计算属性
     * https://swiftgg.gitbook.io/swift/swift-jiao-cheng/10_properties#readonly-computed-properties
     */
    open var isReachable: Bool {isReachableCellular || isReachableOnEthernetOrWiFi}
    
    open var isReachableCellular : Bool {status == .reachable(.cellular)}
    
    open var isReachableOnEthernetOrWiFi : Bool { status == .reachable(.ethernetOrWiFi)}
    
    public let reachabilityQueue =  DispatchQueue(label: "com.sclcoder.learn.swift")
    
    
    open var flags : SCNetworkReachabilityFlags?{
        var flags = SCNetworkReachabilityFlags()
        return SCNetworkReachabilityGetFlags(reachability, &flags) ? flags : nil
    }
    
    open var status : NetworkReachabilityStatus {
        // 闭包表达式
        flags.map(NetworkReachabilityStatus.init) ?? .unknown
        // 完整写法
//        flags.map { (flag: SCNetworkReachabilityFlags) -> NetworkReachabilityStatus in
//            return NetworkReachabilityStatus(flag)
//        } ?? .unknown
    }
    
    struct MutableState {
        /// A closure executed when the network reachability status changes.
        var listener: Listener?
        /// `DispatchQueue` on which listeners will be called.
        var listenerQueue: DispatchQueue?
        /// Previously calculated status.
        var previousStatus: NetworkReachabilityStatus?
    }
    
    private let reachability : SCNetworkReachability
    
    /// Protected storage for mutable state.
//    @Protected
    private var mutableState = MutableState()

    // MARK: - Initialization
    public convenience init?(host: String){
        guard let reachability = SCNetworkReachabilityCreateWithName(nil, host) else { return nil }
        self.init(reachability: reachability)
    }
    
    public convenience init?(){
        var zero = sockaddr()
        zero.sa_len = UInt8(MemoryLayout<sockaddr>.size)
        zero.sa_family = sa_family_t(AF_INET)

        guard let reachability = SCNetworkReachabilityCreateWithAddress(nil, &zero) else { return nil }
        
        self.init(reachability: reachability)
    }

    private init(reachability: SCNetworkReachability) {
        self.reachability = reachability
    }
    
    deinit {
        stopListening()
    }

    // MARK: - Listening

    /// Starts listening for changes in network reachability status.
    ///
    /// - Note: Stops and removes any existing listener.
    ///
    /// - Parameters:
    ///   - queue:    `DispatchQueue` on which to call the `listener` closure. `.main` by default.
    ///   - listener: `Listener` closure called when reachability changes.
    ///
    /// - Returns: `true` if listening was started successfully, `false` otherwise.
    @discardableResult
    open func startListening(onQueue queue: DispatchQueue = .main,
                             onUpdatePerforming listener: @escaping Listener) -> Bool {
        stopListening()

//        $mutableState.write { state in
//            state.listenerQueue = queue
//            state.listener = listener
//        }

        var context = SCNetworkReachabilityContext(version: 0,
                                                   info: Unmanaged.passUnretained(self).toOpaque(),
                                                   retain: nil,
                                                   release: nil,
                                                   copyDescription: nil)
        let callback: SCNetworkReachabilityCallBack = { _, flags, info in
            guard let info = info else { return }

            let instance = Unmanaged<NetworkReachabilityManager>.fromOpaque(info).takeUnretainedValue()
            instance.notifyListener(flags)
        }

        let queueAdded = SCNetworkReachabilitySetDispatchQueue(reachability, reachabilityQueue)
        let callbackAdded = SCNetworkReachabilitySetCallback(reachability, callback, &context)

        // Manually call listener to give initial state, since the framework may not.
        if let currentFlags = flags {
            reachabilityQueue.async {
                self.notifyListener(currentFlags)
            }
        }

        return callbackAdded && queueAdded
    }



    /// Stops listening for changes in network reachability status.
    open func stopListening() {
//        SCNetworkReachabilitySetCallback(reachability, nil, nil)
//        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
//        $mutableState.write { state in
//            state.listener = nil
//            state.listenerQueue = nil
//            state.previousStatus = nil
//        }
    }
    
    
    // MARK: - Internal - Listener Notification

    /// Calls the `listener` closure of the `listenerQueue` if the computed status hasn't changed.
    ///
    /// - Note: Should only be called from the `reachabilityQueue`.
    ///
    /// - Parameter flags: `SCNetworkReachabilityFlags` to use to calculate the status.
    func notifyListener(_ flags: SCNetworkReachabilityFlags) {
        let newStatus = NetworkReachabilityStatus(flags)

//        $mutableState.write { state in
//            guard state.previousStatus != newStatus else { return }
//
//            state.previousStatus = newStatus
//
//            let listener = state.listener
//            state.listenerQueue?.async { listener?(newStatus) }
//        }
    }

}




extension NetworkReachabilityManager.NetworkReachabilityStatus: Equatable{}

extension SCNetworkReachabilityFlags {
    
    var isReachable: Bool { contains(.reachable) }
    var isConnectionRequired: Bool { contains(.connectionRequired) }
    var canConnectAutomatically: Bool { contains(.connectionOnDemand) || contains(.connectionOnTraffic) }
    var canConnectWithoutUserInteraction: Bool { canConnectAutomatically && !contains(.interventionRequired) }
    var isActuallyReachable: Bool { isReachable && (!isConnectionRequired || canConnectWithoutUserInteraction) }
    var isCellular: Bool {
        #if os(iOS) || os(tvOS)
        return contains(.isWWAN)
        #else
        return false
        #endif
    }

    /// Human readable `String` for all states, to help with debugging.
    var readableDescription: String {
        let W = isCellular ? "W" : "-"
        let R = isReachable ? "R" : "-"
        let c = isConnectionRequired ? "c" : "-"
        let t = contains(.transientConnection) ? "t" : "-"
        let i = contains(.interventionRequired) ? "i" : "-"
        let C = contains(.connectionOnTraffic) ? "C" : "-"
        let D = contains(.connectionOnDemand) ? "D" : "-"
        let l = contains(.isLocalAddress) ? "l" : "-"
        let d = contains(.isDirect) ? "d" : "-"
        let a = contains(.connectionAutomatic) ? "a" : "-"

        return "\(W)\(R) \(c)\(t)\(i)\(C)\(D)\(l)\(d)\(a)"
    }
}
#endif
