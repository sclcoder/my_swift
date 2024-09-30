//
//  NetworkViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/4/1.
//

import UIKit
import Toast_Swift
import PKHUD
import ProgressHUD

import Moya
import Alamofire

class NetworkViewController: UIViewController {
    /**
     使用说明
     https://github.com/Alamofire/Alamofire/blob/master/Documentation/Usage.md#introduction
     高级
     https://github.com/Alamofire/Alamofire/blob/master/Documentation/AdvancedUsage.md#using-alamofire-with-swift-concurrency
     */
    
    /// parameters \ encoding
    struct Login: Encodable{
        let email:String
        let password:String
    }
    
    /// Codable 协议 https://juejin.cn/post/6971997599725256734
    struct Person: Codable {
        let name: String
        let age: Int
    }
    
    
    let url = "http://www.weather.com.cn/data/sk/101190408.html"
    let login:Login = Login(email: "sclcoder@163.com", password: "123456")


    // MARK: Actions
    @IBAction func afRequest(_ sender: Any) {
        testRequest()

//        _Concurrency.Task { @MainActor in
//            print("-----before testAsync-----")
//            try await testAsync()
//            print("-----after testAsync-----")
//        }
        
//        testQueue()
        
//        testCoding()
    }
    @IBAction func moyaReqeust(_ sender: Any) {
        
    }

    func testRequest(){
        
        
        AF.request(url) { request in
            request.timeoutInterval = 30
        }.response { response in
//            ProgressHUD.remove()
            print(response)
        }
        
        //        self.showHUD()
                
//                /// URLRequest系统写法
//                var request = URLRequest(url: URL(string: url)!)
//                request.httpMethod = "GET"
//                /// AF添加的extension属性
//                request.method = .post;
                
//
//                AF.request(url) { request in
//                    request.timeoutInterval = 30
//                }.response { response in
//        //            ProgressHUD.remove()
//                    print(response)
//                }
                
        //        let rt = AF.request(url)
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        //            rt.response { data in
        //                print(data)
        //            }
        //        }
        //        print(rt)

                
        //        AF.request(url,
        //                   method: .post,
        //                   parameters: login,
        //                   encoder: URLEncodedFormParameterEncoder.default).response(
        //                    completionHandler:{
        //                        response in
        //                        print(response)
        //                    })
                
        //        AF.request(url,
        //                   method: .post,
        //                   parameters: login,
        //                   encoder: URLEncodedFormParameterEncoder.default).response(
        //                    completionHandler:{
        //                        afDataResponse in
        //                        print(afDataResponse.response!)
        //                        print(afDataResponse.request!.timeoutInterval)
        ////                        print(afDataResponse.data!)
        ////                        print(afDataResponse.result)
        //                    })
                
                
        //        AF.request(url,method: .get).responseData { response in
        //            switch response.result {
        //            case let .success(dataInfo):
        //                print(dataInfo)
        //            case let .failure(error):
        //                print(error)
        //            }
        //        }.responseString { response in
        //            switch response.result{
        //            case let .success(stringInfo):
        //                print(stringInfo)
        //            case let .failure(error):
        //                print(error)
        //            }
        //        }.responseJSON { response in
        //            print(response.value!)
        //        }
        //
        //
        //        struct WeatherInfo: Decodable { let weatherinfo: Dictionary<String, String> }
        //
        //        AF.request(url,method: .get).responseDecodable(of: WeatherInfo.self ,decoder: JSONDecoder(), completionHandler: { response in
        //            switch response.result{
        //            case let .success(dic):
        //                print(dic)
        //            case let .failure(error):
        //                print(error)
        //            }
        //        })
    }
    
    func testCoding() {
        
        /// 详解 Codable 的用法和原理 https://juejin.cn/post/7142499077417074696
        
        struct User: Codable {
            var name: String
            var age: Int
            var birthday: Date?
            
            enum CodingKeys: String, CodingKey {
                case name = "userName"
                case age = "userAge"
                case birthday = "BT"

            }
        }
        
        
        let user = User(name: "tiny", age: 33, birthday: Date(timeIntervalSince1970: 0))
        do {
            let jsonEncoder = JSONEncoder()
            jsonEncoder.dateEncodingStrategy = .iso8601
            let data = try jsonEncoder.encode(user)
            let dataObject = try JSONSerialization.jsonObject(with: data, options: [])
            print(dataObject)
        } catch {
            print(error)
        }

        
        let json = """
            {
                "name": "zhangsan",
                "age": 25,
                "birthday": "2022-09-12T10:25:41+00:00"
            }
            """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            let user = try decoder.decode(User.self, from: json)
            print(user)
        } catch {
            print(error)
        }
        
        
        
//        //解码 JSON 数据
//        let json2 = #" {"name":"Tom", "age": 2} "#
//        let person = try? JSONDecoder().decode(Person.self, from: json2.data(using: .utf8)!)
//        print(person!) // Person(name: "Tom", age: 2)
//
//
//        //编码导出为 JSON 数据
//        let data0 = try? JSONEncoder().encode(person)
//        let dataObject = try? JSONSerialization.jsonObject(with: data0!, options: [])
//        print(dataObject ?? "nil") // { age = 2; name = Tom; }
//
//        let data1 = try? JSONSerialization.data(withJSONObject: ["name": person!.name, "age": person!.age], options: [])
//        print(String(data: data1!, encoding: .utf8)!) //{"name":"Tom","age":2}
        
        
    }
    /**
     并发 https://gitbook.swiftgg.team/swift/swift-jiao-cheng/28_concurrency
     async
     await
     Task : 任务和任务组 - 非结构化并发\任务取消
     actor
     可发送类型
     */
    func testAsync() async throws -> Void{
        func listPhotos(inGallery name: String) async throws -> [String] {
            // try await Task.sleep(until: .now + .seconds(2), clock: .continuous)
            // 默认找的是Moya中的Task，所以这里改为_Concurrency.Task
            try await _Concurrency.Task.sleep(until: .now + .seconds(2), clock: .continuous)
            return ["IMG001", "IMG99", "IMG0404"]
        }
        
        @Sendable func downloadPhoto(named: String) async throws -> String{
            try await _Concurrency.Task.sleep(until: .now + .seconds(2), clock: .continuous)
            return "Image - " + named
        }
        
        /// 串行调用异步方法
        print("-----串行执行开始-----")
        print("-----before listPhotos-----")
        let photoNames = try await listPhotos(inGallery: "Summer Vacation")
        print("-----after listPhotos-----")
        
        let sortedNames = photoNames.sorted()
        print(sortedNames)
        let name = sortedNames[0]
        
        print("-----before downloadPhoto-----")
        let photo = try await downloadPhoto(named: name)
        print("-----after downloadPhoto-----")
        print(photo)

        print("-----串行执行结束-----")

        
        /// 并行的调用异步方法 : 为了在调用异步函数的时候让它附近的代码并发执行，定义一个常量时，在 let 前添加 async 关键字，然后在每次使用这个常量时添加 await 标记。
        print("-----并行执行开始-----")

        print("-----before downloadPhoto firstPhoto-----")
        async let firstPhoto  = try await downloadPhoto(named: sortedNames[0])
        print("-----before downloadPhoto secondPhoto-----")
        async let secondPhoto = try await downloadPhoto(named: sortedNames[1])
        print("-----before downloadPhoto thirdPhoto-----")
        async let thirdPhoto  = try await downloadPhoto(named: sortedNames[2])
        print("-----after downloadPhoto -----")
        let photos = try await [firstPhoto, secondPhoto, thirdPhoto]
        print(photos)
        print("-----并行执行结束-----")
    }
    
    func testQueue(){
    /** 目标队列
        https://www.humancode.us/2014/08/14/target-queues.html
        https://juejin.cn/post/6844903588930519047#heading-0
     */
        let serialQueue     = DispatchQueue(label: "com.example.serialQueue")
        let concurrentQueue = DispatchQueue(label: "com.example.concurrentQueue",attributes: .concurrent)
//        let concurrentQueue = DispatchQueue(label: "com.example.concurrentQueue",attributes: .concurrent,target: serialQueue)
        
        // 将任务添加到串行队列 serialQueue1，并且指定 serialQueue2 作为目标队列
        concurrentQueue.async {
            print("Task 1 is executing on \(Thread.current)")
            for index in 1...10{
                print("Task 1 is executing on \(Thread.current)" + "index \(index)")
            }
        }
        
        concurrentQueue.async {
            print("Task 2 is executing on \(Thread.current)")
            for index in 1...10{
                print("Task 2 is executing on \(Thread.current)" + "index \(index)")
            }
        }
        
        concurrentQueue.async {
            print("Task 3 is executing on \(Thread.current)")
            for index in 1...10{
                print("Task 3 is executing on \(Thread.current)" + "index \(index)")
            }
        }
        
    }
}




/**
 @dynamicMemberLookup  https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#dynamicmemberlookup
 该特性用于类、结构体、枚举或协议，让其能在运行时查找成员。该类型必须实现 subscript(dynamicMember:) 下标。

 在显式成员表达式中，如果指定成员没有相应的声明，则该表达式被理解为对该类型的 subscript(dynamicMember:) 下标调用，将有关该成员的信息作为参数传递。下标接收参数既可以是键路径，也可以是成员名称字符串；如果你同时实现这两种方式的下标调用，那么以键路径参数方式为准。

 subscript(dynamicMember:) 实现允许接收 KeyPath，WritableKeyPath 或 ReferenceWritableKeyPath 类型的键路径参数。它可以使用遵循 ExpressibleByStringLiteral 协议的类型作为参数来接受成员名 -- 通常情况下是 String。下标返回值类型可以为任意类型。
 
 
 Key-path 表达式
 https://gitbook.swiftgg.team/swift/yu-yan-can-kao/04_expressions#key-path-expression
 Key-path 表达式引用一个类型的属性或下标。在动态语言中使场景可以使用 Key-path 表达式，例如观察键值对。格式为：

 \类型名.路径

 类型名是一个具体类型的名称，包含任何泛型参数，例如 String、[Int] 或 Set<Int>。

 路径可由属性名称、下标、可选链表达式或者强制解包表达式组成。以上任意 key-path 组件可以以任何顺序重复多次。

 在编译期，key-path 表达式会被一个 KeyPath 类的实例替换。

 对于所有类型，都可以通过传递 key-path 参数到下标方法 subscript(keyPath:) 来访问它的值。例如：
 
 struct SomeStructure {
     var someValue: Int
 }

 let s = SomeStructure(someValue: 12)
 let pathToProperty = \SomeStructure.someValue

 let value = s[keyPath: pathToProperty]
 // 值为 12
 
 */

/// 按成员名进行的动态成员查找可用于围绕编译时无法进行类型检查的数据创建包装类型，例如在将其他语言的数据桥接到 Swift 时。例如：
@dynamicMemberLookup
struct DynamicStruct {
    let dictionary = ["someDynamicMember": 325,
                      "someOtherMember": 787]
    subscript(dynamicMember member: String) -> Int { // member = "someDynamicMember"
        return dictionary[member] ?? 1054
    }
}


struct DynamicStruct2 {
    let dictionary = ["someDynamicMember": 325,
                      "someOtherMember": 787]
}

/// 根据键路径来动态地查找成员，可用于创建一个包裹数据的包装类型，该类型支持在编译时期进行类型检查。例如：
struct Point { var x: Double, y: Int }
@dynamicMemberLookup
struct PassthroughWrapper<Value> {
    var value: Value
    subscript<T>(dynamicMember member: KeyPath<Value, T>) -> T { // member = \Point.y
        get { return value[keyPath: member] }
    }
}


extension NetworkViewController{
    
    override func viewDidLoad() {
        self.navigationItem.title = "Network"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        
        let s = DynamicStruct()
        // 使用动态成员查找
        let dynamic = s.someDynamicMember
        print(dynamic)
        // 打印“325”

        // 直接调用底层下标
        let equivalent = s[dynamicMember: "someDynamicMember"]
        print(dynamic == equivalent)
        // 打印“true”
        
        
        let point = Point(x: 381.0, y: 431)
        let wrapper = PassthroughWrapper(value: point)
        print(wrapper.y)
        
        testKeyPath()
        
        testClosure()
    }
    
    
    func testKeyPath(){
        let greetings = ["hello", "hola", "bonjour", "안녕"]
        let myGreeting = greetings[keyPath: \[String].[1]]
        
        
        var index = 2
        let path = \[String].[index]
        let fn: ([String]) -> String = { strings in strings[index] }

        print(greetings[keyPath: path])
        // 打印 "bonjour"
        print(fn(greetings))
        // 打印 "bonjour"

        // 将 'index' 设置为一个新的值不会影响到 'path'
        index += 1
        print(greetings[keyPath: path])
        // 打印 "bonjour"

        // 'fn' 闭包使用了新值。
        print(fn(greetings))
        // 打印 "안녕"
    }
    /**
     https://gitbook.swiftgg.team/swift/yu-yan-can-kao/04_expressions#capture-lists
     默认情况下，闭包会捕获附近作用域中的常量和变量，并使用强引用指向它们。你可以通过一个捕获列表来显式指定它的捕获行为。

     捕获列表在参数列表之前，由中括号括起来，里面是由逗号分隔的一系列表达式。一旦使用了捕获列表，就必须使用 in 关键字，即使省略了参数名、参数类型和返回类型。

     捕获列表中的项会在闭包创建时被初始化。每一项都会用闭包附近作用域中的同名常量或者变量的值初始化。例如下面的代码示例中，捕获列表包含 a 而不包含 b，这将导致这两个变量具有不同的行为。
     */
    func testClosure(){
        var a = 0
        var b = 0
        /// 捕获列表中的项会在闭包创建时被初始化
        let closure = { [a] in
            print(a, b)
        }
        
        a = 10
        b = 10
        closure()
    }
    
    
    func showHUD() {
//        view.makeToast("Toast_Swift")
//        ProgressHUD.show(icon: .heart)
//        ProgressHUD.showProgress("Loading", 0.4)
        ProgressHUD.colorAnimation = .systemYellow
        ProgressHUD.colorProgress = .blue
        ProgressHUD.colorStatus   = .red
        ProgressHUD.animationType = .multipleCirclePulse
        ProgressHUD.show("Loading...")
    }

    
    @IBAction func removeHUD(_ sender: Any) {
        ProgressHUD.remove()

    }

}
