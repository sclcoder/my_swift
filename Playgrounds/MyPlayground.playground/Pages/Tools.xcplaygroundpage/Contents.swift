//: [Previous](@previous)

import Foundation

var greeting = "Hello, Scripts"

/// 生成表情包配置文件 plist
let emojiString: String = "🙂 😀 😁😃😄😳😅 😥😪😭😂😊😐😑😏😎😣😶😴😛😔😠😨🌚😱👽🤦😇😈👿💪👈👉👆👇✌✋👌👍👎✊👊👋👏🤟👐🔥 💔💕💖💗💓💙💚💛💜💝💞🏠🏡🏢🏨🏦🏥🏪🏫🏬🌇🌆💵💵💷💴💰💳🐟🍰❄️💣".replacingOccurrences(of: " ", with: "")
let dataSource : NSArray = emojiString.split(separator: "").enumerated().map { (index,emoji) in
    var item : Dictionary = [String:String]()
    item.updateValue("emoji_icon_\(index)" , forKey:"id")
    item.updateValue(String(emoji), forKey: "tag")
    item.updateValue(String(emoji), forKey: "unicode")
    return item
} as NSArray

 
// 创建plist
var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
var plistPath = path.strings(byAppendingPaths: ["emoji.plist"])[0]
 
try dataSource.write(to: URL(fileURLWithPath: plistPath))

print(plistPath)



/// email正则表达式  - chatGPT

let emailString = "eric.thornley+testinglofty@chimeinc.com"
let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegex)
let isValidEmail = emailTest.evaluate(with: emailString)
if isValidEmail {
    print("\(emailString) 是一个有效的 email 地址。")
} else {
    print("\(emailString) 不是一个有效的 email 地址。")
}



//: [Next](@next)



