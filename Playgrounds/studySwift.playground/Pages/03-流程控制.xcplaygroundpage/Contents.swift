

//: if-else
//: > if后面的条件只能是Bool类 、 可省略() 、不能省略{}

let age = 4
if age >= 22 {
    print("get married")
} else if age >= 18 {
    print("being a adult")
} else if age >=  7 {
    print("go to school")
} else{
    print("just a child")
}

// while
var num1 = 5
while num1 > 0 {
    print("The num is \(num1)")
    num1 -= 1
}
// repeat-while  和do while一样
var num2 = -1
repeat {
    print("The num is \(num2)")
} while num2 > 0



// --------------- 区间运算符 --------------

// 区间运算符
// a...b : [a,b] 、 a..<b : [a,b)
// for 循环
for i in 1...3{
    print(i)
}

for i in 1..<3{
    print(i)
}

let range = 1...3
for i in range{
    print(i)
}

for _ in 1...5{
    print("for each")
}

// 用在数组中
let names = ["aaa","bbb","ccc","ddd"]
for name in names[0...3]{
    print(name)
}
print("----------")

// 单侧区间: 让区间朝一个方向尽可能的远
for name in names[...2]{
    print(name)
}
print("----------")

for name in names[2...]{
    print(name)
}
print("----------")

let range1 = ...5
range1.contains(6)
range1.contains(3)
range1.contains(-10)

// 区间类型
let rangeC: ClosedRange<Int> = 1...5
let range2: Range<Int> = 1..<3
let range3: PartialRangeThrough<Int> = ...10

// 字符和字符串也能使用区间运算符，但默认不能用于 for-in 中
let stringRange1 = "a"..."f" // ClosedRange<String>
stringRange1.contains("d") //
stringRange1.contains("h")

let stringRange2 = "cc"..."ff" // ClosedRange<String>
stringRange2.contains("cb") // false
stringRange2.contains("cg") // ture
stringRange2.contains("cz") // ture
stringRange2.contains("dz") // ture
stringRange2.contains("fg") // false

// \0到~包含了所有可能要用的ASCII字符
let characterRange: ClosedRange<Character> = "0"..."~"
characterRange.contains("Q")

// 带间隔的区间值

let hours = 11
let hourInterval = 2
for tickMark in stride(from: 4, through: hours, by: hourInterval) {
    print(tickMark)
}
print("----------")
// --------------- 区间运算符 --------------




// --------------- switch --------------
//: > case、default 后不能写{}  默认可以不写break,并不会贯穿到后面的条件
var number = 1

switch number{
case 1:
    print("number is 1")
//    break
case 2:
    print("number is 2")
//    break
default:
    print("number is other")
//    break
}
//: fallthrough 实现贯穿效果
switch number{
case 1:
    print("number is 1")
    fallthrough
case 2:
    print("number is 2")
//    break
default:
    print("number is other")
//    break
}

/*:
 > switch 必须保证处理所有的情况。如果可能保证处理所有的情况，可以不使用default
 > case、default后面至少要有一条语句
 */
switch number{
case 1:
    print("number is 1")
case 2:
    print("number is 2")
default:
    break //
}

// 如果可能保证处理所有的情况，可以不使用default
enum Answer { case A, B }
let answer = Answer.A

switch answer{
case Answer.A:
    print("A")
case Answer.B:
    print("B")
}
print("--------------")

// 由于已确定answer是Answer类型，因此可以省略Answer
switch answer{
case .A:
    print("A")
case .B:
    print("B")
}
print("--------------")

// 复合条件: 多种case都执行的情况，就是复合条件 实现方式 fallthrough 、case条件合并
// switch 也支持Character和String类型
let string = "Jack"
switch string{
case "Jack":
    fallthrough
case "Rose":
    print("Right Person")
default:
    break
}
print("--------------")


switch string {
case "Jack" ,"Rose":
    print("Right Person")
default:
    break
}
print("--------------")

let character: Character = "a"
switch character {
case "A","a":
    print("The letter is A")
default:
    print("The letter is not A")
}
print("--------------")



// 区间匹配
let count = 62
switch count {
case 0:
    print("none")
case 1...6:
    print("a few")
case 5...12:
    print("several")
case 12...100:
    print("dozens of")
default:
    print("many")
}

// 元组匹配
let point = (1,1)
switch point{
case (0,0):
    print("the origin")
case (_,0):
    print("on the x-axis")
case (0,_):
    print("on the y-axis")
case(-2...2,-2...2):
    print("inside the box")
default:
    print("outside of the box")
}
//
//: 可以使用_忽略某个值。关于case匹配问题，属于模式匹配（Pattern Matching）的范畴


// 值绑定 :  要用到某个值的时候，可以将这个值绑定
let point2 = (2,0)
switch point2{
case (let x, 0):
    print("on the x-axis with an x value of \(x)")
case (0, let y):
    print("on the y-axis with an y value of \(y)")
case let (x,y):
    print("somewhere else at \(x), \(y)")
}

// where
let point3 = (1, -1)
switch point3{
case let(x, y) where x == y:
    print("on the line x == y")
case let(x, y) where x == -y:
    print("on the line x== -y")
case let (x,y):
    print("jsut print \(x), \(y)")
}

// 求数组中所有整数的和
var nums2 = [10,20,-20,-30,-99]
var sum = 0
for num in nums2 where num > 0 {
    sum += num
}
print(sum)

// --------------- switch --------------


// --------------- 标签语句 -------------
print("-------------标签语句---------------")

outer1: for i in 1...4{
    for k in 1...4{
        if k == 3 {
            continue outer1
        }
        if i == 3{
            break outer1
        }
        print("i==\(k), k == \(k)")
    }
}


print("-------------标签语句---------------")

// --------------- 标签语句 -------------


//: [Previous](@previous)
//: [Next](@next)
