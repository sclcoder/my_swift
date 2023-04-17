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

//: [Next](@next)
