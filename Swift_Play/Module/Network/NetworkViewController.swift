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
        
        self.showHUD()
        
        /// URLRequest系统写法
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        /// AF添加的extension属性
        request.method = .post;
        
        /// method
//        AF.request(url,method: .get).response{
//            response in
//                print(response)
//        }
        /**
         open func request(_ convertible: URLConvertible,
                           method: HTTPMethod = .get,
                           parameters: Parameters? = nil,
                           encoding: ParameterEncoding = URLEncodedFormParameterEncoder.default,
                           headers: HTTPHeaders? = nil,
                           interceptor: RequestInterceptor? = nil,
                           requestModifier: RequestModifier? = nil) -> DataRequest
         */
        /// requestModifier
        AF.request(url) { request in
            request.timeoutInterval = 30
        }.response { response in
            ProgressHUD.remove()
            print(response)
        }
        
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
    
    
    
    
    
    
    @IBAction func moyaReqeust(_ sender: Any) {
        
        
        
    }

    func testCoding() {
        //解码 JSON 数据
        let json = #" {"name":"Tom", "age": 2} "#
        let person = try? JSONDecoder().decode(Person.self, from: json.data(using: .utf8)!)
        print(person!) // Person(name: "Tom", age: 2)
     
        
        //编码导出为 JSON 数据
        let data0 = try? JSONEncoder().encode(person)
        let dataObject = try? JSONSerialization.jsonObject(with: data0!, options: [])
        print(dataObject ?? "nil") // { age = 2; name = Tom; }

        let data1 = try? JSONSerialization.data(withJSONObject: ["name": person!.name, "age": person!.age], options: [])
        print(String(data: data1!, encoding: .utf8)!) //{"name":"Tom","age":2}
    }
}




/**
 @dynamicMemberLookup  https://gitbook.swiftgg.team/swift/yu-yan-can-kao/07_attributes#dynamicmemberlookup
 该特性用于类、结构体、枚举或协议，让其能在运行时查找成员。该类型必须实现 subscript(dynamicMember:) 下标。

 在显式成员表达式中，如果指定成员没有相应的声明，则该表达式被理解为对该类型的 subscript(dynamicMember:) 下标调用，将有关该成员的信息作为参数传递。下标接收参数既可以是键路径，也可以是成员名称字符串；如果你同时实现这两种方式的下标调用，那么以键路径参数方式为准。

 subscript(dynamicMember:) 实现允许接收 KeyPath，WritableKeyPath 或 ReferenceWritableKeyPath 类型的键路径参数。它可以使用遵循 ExpressibleByStringLiteral 协议的类型作为参数来接受成员名 -- 通常情况下是 String。下标返回值类型可以为任意类型。
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
