import Darwin

//: 数据类型

//: 一、常量
//: >常量值不要求在编译期间确定，但要求在使用前必须赋值一次

let age: Int
age = 10
let name = "chunlei.sun"

let height: Double
let h1 = 180.0
let h2 = 178.5
height = h1 + h2

//: 二、标识符
func test(){
    print("支持很多字符, 如 emoji😈")
}

func 🐂🍺(){
    print("swift so niubi")

}
test()


/*:
 三、常见数据类型
 > 1. 值类型
 > 枚举(enum) : Optional
 > 结构体(struct)
 >  - Bool、Int、Float、Double、Character
 >  - String、Array、Dictionary、Set
 > 2. 引用类型(reference Type)
 
 ---
 1. 整数类型: Int8 Int16 Int32 Int64 UInt8 ...
 2. 浮点类型: Float,32位,精度只有6位；Double，64位，精度至少15位。如果是浮点型默认为Double，如果是Float需要指定
 */
let letFloat: Float = 30.0
let letDouble = 30.0

//: 字面量
// 布尔
let isTrue = true
// 字符串
let string = "slcoder"
// 字符
let character: Character = "🐶"

//: 整数
let intDecimal = 17 // 十进制
let intBinary = 0b10001 // 二进制
let intOctal  = 0o21   // 八进制
let intHexdeciaml = 0x11 // 十六进制

//: 浮点数
let doubleDecimal = 125.0 // 等价于 1.25e2  e2代表 10^2
let d1 = 1.25e2
let d2 = 1.25e-2  // 1.25e-2 等价于0.0125   e-2代表 10^-2

let doubleHexdecimal1 = 0xFp2 // 十六进制,15*2^2      p2代表 2^2
let doubleHexdecimal2 = 0xFp-2 // 十六进制,15*2^-2    p-2代表 2^-2

// 一下都表示12.1875
// 十进制 12.1875 、1.21875e1
// 十六进制 0xC.3p0
let d3 = 0xC.3p0

//: >整数和浮点数可以添加额外的0或下划线增加可读性  100_0000 000123.4456

//: 数组
let array = [1,2,3.5,6,9]
//: 字典
let dic = ["age":20, "height":190, "wegith":120]

//: 类型转换
// 整数转换
let int1: UInt16 = 2_00
let int2: UInt8  = 1
let int3 = int1 + UInt16(int2)

// 整数和浮点数
let int = 3
let double = 0.1415926
let pi = Double(int) + double
let intPi = Int(pi)

// 字面量可以直接相加
let result = 3 +  0.1415926

//: 元组
let http404Error = (404,"Not Found")
print("The status code is \(http404Error.0)")

let (statusCode, statusMessage) = http404Error
print("The status code is \(statusCode)")

let (justCode, _) = http404Error

let http200Status = (statusCode:200, desc:"OK")
print("The status code is \(http200Status.statusCode)")

//: [Previous](@previous)
//: [Next](@next)
