//
//  Protected.swift
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

private protocol Lock {
    func lock()
    func unlock()
}

extension Lock {
    /// Executes a closure returning a value while acquiring the lock.
    ///
    /// - Parameter closure: The closure to run.
    ///
    /// - Returns:           The value the closure generated.
    func around<T>(_ closure: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try closure()
    }

    /// Execute a closure while acquiring the lock.
    ///
    /// - Parameter closure: The closure to run.
    func around(_ closure: () throws -> Void) rethrows {
        lock(); defer { unlock() }
        try closure()
    }
}

#if os(Linux) || os(Windows)

extension NSLock: Lock {}

#endif

#if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
/// An `os_unfair_lock` wrapper.
final class UnfairLock: Lock {
    private let unfairLock: os_unfair_lock_t

    init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock())
    }

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    fileprivate func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    fileprivate func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}
#endif
/// #关于 @propertyWrapper的说明 - wrappedValue
/**
##官方翻译文档 https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#propertywrapper
## DeepSeek解释
一个简单的案例
 @propertyWrapper
 struct Trimmed {
     private var value: String = ""
     
     var wrappedValue: String {
         get { value }
         set { value = newValue.trimmingCharacters(in: .whitespacesAndNewlines) }
     }
     
     init(wrappedValue: String) {
         self.wrappedValue = wrappedValue
     }
 }
 struct User {
     @Trimmed var name: String
 }

 let user = User(name: "  Alice  ")
 print(user.name) // 输出 "Alice"（自动去除了前后空格）
 
 
 编译器会将其展开为类似以下的代码：
 
 struct User {
     // 编译器生成的存储属性
     private var _name: Trimmed
     
     // 编译器生成的访问逻辑
     var name: String {
         get { _name.wrappedValue }
         set { _name.wrappedValue = newValue }
     }
     
     // 编译器生成的初始化方法
     init(name: String) {
         self._name = Trimmed(wrappedValue: name)
     }
 }

 // 使用
 let user = User(name: "  Alice  ")
 print(user.name) // 输出 "Alice"（自动去除了前后空格）
 
 具体展开逻辑
 存储属性：编译器会生成一个私有属性 _name，类型为 Trimmed，用于存储实际的包装器实例。
 访问逻辑：编译器会生成一个计算属性 name，其 get 和 set 方法分别调用 _name.wrappedValue 的 get 和 set。
 初始化方法：编译器会生成一个初始化方法，将传入的值传递给 Trimmed 的初始化方法。

 展开后的调用过程：
 - 当调用 User(name: " Alice ") 时：编译器会调用 User 的初始化方法，将 " Alice " 传递给 Trimmed 的初始化方法。Trimmed 的初始化方法会调用 wrappedValue 的 set 方法，去除空格并存储值。
 - 当访问 user.name 时：编译器会调用 name 的 get 方法，返回 _name.wrappedValue 的值（即去除空格后的字符串）。

 总结
 @propertyWrapper 的本质：编译器通过生成额外的存储属性和计算属性，将包装器的逻辑嵌入到属性访问中。
 代码展开后的结构：
 一个私有存储属性（_name）。
 一个计算属性（name），用于访问包装器的 wrappedValue。
 一个初始化方法，用于初始化包装器。
 这种展开方式使得 @propertyWrapper 的使用更加直观，同时保持了代码的简洁性和可读性。
 */

/// #关于 @propertyWrapper的说明 - projectedValue
/**
 ##官方翻译文档 https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#propertywrapper

*/

/// #关于 @dynamicMemberLookup的说明
/**
 ## 官方翻译文档 https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#dynamicmemberlookup
  - 该特性用于类、结构体、枚举或协议，让其能在运行时查找成员。
  

*/

/// A thread-safe wrapper around a value.
@propertyWrapper
@dynamicMemberLookup
final class Protected<T> {
    #if os(macOS) || os(iOS) || os(watchOS) || os(tvOS)
    private let lock = UnfairLock()
    #elseif os(Linux) || os(Windows)
    private let lock = NSLock()
    #endif
    private var value: T

    init(_ value: T) {
        self.value = value
    }

    /// The contained value. Unsafe for anything more than direct read or write.
    var wrappedValue: T {
        get { lock.around { value } }
        set { lock.around { value = newValue } }
    }

    var projectedValue: Protected<T> { self }

    init(wrappedValue: T) {
        value = wrappedValue
    }

    /// Synchronously read or transform the contained value.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Returns:           The return value of the closure passed.
    func read<U>(_ closure: (T) throws -> U) rethrows -> U {
        try lock.around { try closure(self.value) }
    }

    /// Synchronously modify the protected value.
    ///
    /// - Parameter closure: The closure to execute.
    ///
    /// - Returns:           The modified value.
    @discardableResult
    func write<U>(_ closure: (inout T) throws -> U) rethrows -> U {
        try lock.around { try closure(&self.value) }
    }
    /**
    
     # @dynamicMemberLookup 该特性用于类、结构体、枚举或协议，让其能在运行时查找成员。 
      https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#dynamicmemberlookup
     
     - 该特性用于类、结构体、枚举或协议，让其能在运行时查找成员。该类型必须实现 subscript(dynamicMember:) 下标。
     
     - 在显式成员表达式中，如果指定成员没有相应的声明，则该表达式被理解为对该类型的 subscript(dynamicMember:) 下标调用，将有关该成员的信息作为参数传递。下标接收参数既可以是键路径，也可以是成员名称字符串；如果你同时实现这两种方式的下标调用，那么以键路径参数方式为准。
     
     - subscript(dynamicMember:) 实现允许接收 KeyPath，WritableKeyPath 或 ReferenceWritableKeyPath 类型的键路径参数。它可以使用遵循 ExpressibleByStringLiteral 协议的类型作为参数来接受成员名 -- 通常情况下是 String。下标返回值类型可以为任意类型。
     
     - 按成员名进行的动态成员查找可用于围绕编译时无法进行类型检查的数据创建包装类型，例如在将其他语言的数据桥接到 Swift 时
     
     
     # keyPath
       https://gitbook.swiftgg.team/swift/yu-yan-can-kao/04_expressions#key-path-expression
      -  Key-path 表达式引用一个类型的属性或下标。在动态语言中使场景可以使用 Key-path 表达式，例如观察键值对。格式为：  \类型名.路径
     类型名是一个具体类型的名称，包含任何泛型参数，例如 String、[Int] 或 Set<Int>。
     路径可由属性名称、下标、可选链表达式或者强制解包表达式组成。以上任意 key-path 组件可以以任何顺序重复多次。
     在编译期，key-path 表达式会被一个 KeyPath 类的实例替换。
     对于所有类型，都可以通过传递 key-path 参数到下标方法 subscript(keyPath:) 来访问它的值
     */
    subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property { //   keyPath = \MutableState.state  具体值是个Key-path表达式
        get { lock.around { value[keyPath: keyPath] } }
        set { lock.around { value[keyPath: keyPath] = newValue } }
    }

    subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        lock.around { value[keyPath: keyPath] }
    }
}

extension Protected where T == Request.MutableState {
    /// Attempts to transition to the passed `State`.
    ///
    /// - Parameter state: The `State` to attempt transition to.
    ///
    /// - Returns:         Whether the transition occurred.
    func attemptToTransitionTo(_ state: Request.State) -> Bool {
        lock.around {
            guard value.state.canTransitionTo(state) else { return false }

            value.state = state

            return true
        }
    }

    /// Perform a closure while locked with the provided `Request.State`.
    ///
    /// - Parameter perform: The closure to perform while locked.
    func withState(perform: (Request.State) -> Void) {
        lock.around { perform(value.state) }
    }
}
