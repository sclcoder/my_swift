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
 - 属性包装器中 projected value是它可以用来暴露额外功能的第二个值。
 - 属性包装器的作者负责确认其映射值的含义并定义公开映射值的接口。若要通过属性包装器来映射值，请在包装器的类型上定义 projectedValue 实例属性。
 - 编译器通过在包装属性的名称前面加上美元符号（$）来合成映射值的标识符。例如，someProperty 的映射值是 $someProperty。映射值具有与原始包装属性相同的访问控制级别。
 
 ## Deepseek
 projectedValue（可选）,通过 $ 符号访问，提供额外的功能

*/

/// #关于 @dynamicMemberLookup的说明
/**
 ## 官方翻译文档 https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#dynamicmemberlookup
 
 - 该特性用于类、结构体、枚举或协议，让其能在运行时查找成员。该类型必须实现 subscript(dynamicMember:) 下标。
 
 - 在显式成员表达式中，如果指定成员没有相应的声明，则该表达式被理解为对该类型的 subscript(dynamicMember:)
 下标调用，将有关该成员的信息作为参数传递。下标接收参数既可以是键路径，也可以是成员名称字符串；如果你同时实现这两种方式的下标调用，那么以键路径参数方式为准。
 
 - subscript(dynamicMember:) 实现允许接收 KeyPath，WritableKeyPath 或 ReferenceWritableKeyPath 类型的键路径参数。它可以使用遵循 ExpressibleByStringLiteral 协议的类型作为参数来接受成员名 -- 通常情况下是 String。下标返回值类型可以为任意类型。
 
 - 按成员名进行的动态成员查找可用于围绕编译时无法进行类型检查的数据创建包装类型，例如在将其他语言的数据桥接到 Swift 时
 
## DeepSeek 解析案例
 struct Point { var x, y: Int }
 
 @dynamicMemberLookup
 struct PassthroughWrapper<Value> {
     var value: Value
     subscript<T>(dynamicMember member: KeyPath<Value, T>) -> T {
         get { return value[keyPath: member] }
     }
 }

 let point = Point(x: 381, y: 431)
 let wrapper = PassthroughWrapper(value: point)
 print(wrapper.x)
 
 
 - PassthroughWrapper 是一个泛型结构体，包装了一个任意类型的值 value。
 - 使用 @dynamicMemberLookup 标记，表示支持动态成员访问。
 - 实现 subscript(dynamicMember:) 方法，参数类型为 KeyPath<Value, T>，表示通过 KeyPath 动态访问 value 的属性。
 - 在 get 方法中，使用 value[keyPath: member] 返回 value 的对应属性值。

 当访问 wrapper.x 时，编译器会将其转换为对 subscript(dynamicMember:) 方法的调用。
 - dynamicMember 参数是一个 KeyPath，指向 Point 的 x 属性。
 -value[keyPath: member] 会从 value（即 point）中获取 x 的值。
 
 关键点
 KeyPath 的使用： KeyPath 是 Swift 中用于类型安全地访问属性的一种方式。在这里，KeyPath 用于动态访问 value 的属性。
 */

/// #关于keyPath类和key-path表达式的说明
/**
 ## deepseek对KeyPath类的说明
 在 Swift 中，KeyPath 是一种类型安全的引用类型，用于表示对某个类型的属性或下标（subscript）的引用。它允许你在编译时捕获属性的路径，并在运行时动态访问或修改这些属性。
 KeyPath 是 Swift 强大的元编程工具之一，广泛用于数据绑定、KVO（键值观察）、动态属性访问等场景。
 
 核心概念
 类型安全：KeyPath 是类型安全的，编译器会检查路径的有效性，确保引用的属性确实存在于目标类型中。
 路径表示：KeyPath 可以表示一个属性链（例如 \Person.address.street），允许你通过一个路径访问嵌套属性。
 类型（包括不可变与可变）： 1.KeyPath：只读访问。2.WritableKeyPath：支持读写访问。3.ReferenceWritableKeyPath：专门用于类（引用类型）的可读写访问。
 
 基本用法
 定义 KeyPath,使用反斜杠 \ 定义 KeyPath：
 struct Person {
     var name: String
     var age: Int
     var address: Address
 }

 struct Address {
     var street: String
     var city: String
 }

 let nameKeyPath: KeyPath<Person, String> = \Person.name
 let streetKeyPath: KeyPath<Person, String> = \Person.address.street
 
 通过 keyPath 访问实例的属性：
 let person = Person(name: "Alice", age: 30, address: Address(street: "123 Main St", city: "New York"))
 print(person[keyPath: nameKeyPath]) // 输出 "Alice"
 print(person[keyPath: streetKeyPath]) // 输出 "123 Main St"
 
 修改属性（使用 WritableKeyPath）
 如果属性是可写的，可以使用 WritableKeyPath 修改值：
 var person = Person(name: "Alice", age: 30, address: Address(street: "123 Main St", city: "New York"))
 let ageKeyPath: WritableKeyPath<Person, Int> = \Person.age
 person[keyPath: ageKeyPath] = 31
 print(person.age) // 输出 31
 
 
 ## 官方翻译文档 key-path表达式  https://gitbook.swiftgg.team/swift/yu-yan-can-kao/04_expressions#key-path-expression
 ## Key-path 表达式引用一个类型的属性或下标。在动态语言中使场景可以使用 Key-path 表达式，例如观察键值对。
 ## 格式为：  \类型名.路径
 
 - 类型名是一个具体类型的名称，包含任何泛型参数，例如 String、[Int] 或 Set<Int>。
 路径可由属性名称、下标、可选链表达式或者强制解包表达式组成。以上任意 key-path 组件可以以任何顺序重复多次。
 - 在编译期，key-path 表达式会被一个 KeyPath 类的实例替换。
 - 对于所有类型，都可以通过传递 key-path 参数到下标方法 subscript(keyPath:) 来访问它的值
 
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

    subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        // keyPath = \MutableState.state  具体值是个Key-path表达式
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
