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
                           encoding: ParameterEncoding = URLEncoding.default,
                           headers: HTTPHeaders? = nil,
                           interceptor: RequestInterceptor? = nil,
                           requestModifier: RequestModifier? = nil) -> DataRequest
         */
        /// requestModifier
//        AF.request(url) { request in
//            request.timeoutInterval = 30
//        }.response { response in
//            print(response)
//        }
        
        
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
        
        
        AF.request(url,method: .get).responseData { response in
            switch response.result {
            case let .success(dataInfo):
                print(dataInfo)
            case let .failure(error):
                print(error)
            }
        }.responseString { response in
            switch response.result{
            case let .success(stringInfo):
                print(stringInfo)
            case let .failure(error):
                print(error)
            }
        }.responseJSON { response in
            print(response.value!)
        }
        
        
        struct WeatherInfo: Decodable { let weatherinfo: Dictionary<String, String> }

        AF.request(url,method: .get).responseDecodable(of: WeatherInfo.self ,decoder: JSONDecoder(), completionHandler: { response in
            switch response.result{
            case let .success(dic):
                print(dic)
            case let .failure(error):
                print(error)
            }
        })
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



extension NetworkViewController{
    
    override func viewDidLoad() {
        self.navigationItem.title = "Network"
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
