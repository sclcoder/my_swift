var a = 10
var b = 20
var c = a + b
print(c)


import UIKit
import PlaygroundSupport

let view = UIView()
view.frame = CGRect(x: 0, y: 0, width: 100, height: 200)
view.backgroundColor = UIColor.red
PlaygroundPage.current.liveView = view
 
let logoView = UIImageView(image: UIImage(named: "swift_logo"))
PlaygroundPage.current.liveView = logoView

let vc = UITableViewController()
vc.view.backgroundColor = UIColor.systemYellow
PlaygroundPage.current.liveView = vc

//: [上一页](@previous)
//: [下一页](@next)
