
//: 函数
//: > 函数的参数是默认常量类型 let v1, let v2
// 一下为没有返回值的写法
func sum1(v1:Int , v2:Int){
    v1 + v2
}
// 返回值为Void
func sum2(v1:Int , v2:Int) -> Void{
    v1 + v2
}
// 返回个空元组 : ()是空元组
func sum3(v1:Int , v2:Int) -> (){
    v1 + v2
}

// 通过元组实现多返回值
func calculate(v1:Int , v2:Int) -> (sum: Int , diff: Int, average: Int){
    let sum = v1 + v2
    return(sum,v1 - v2, sum >> 1)
}
let result = calculate(v1: 10, v2: 20)
result.sum
result.diff
result.average


//: 函数的文档注释

/// 求和【概述】
///
/// - Parameter v1: 第一个整数
/// - Parameter v2: 第二个整数
/// - Returns:  2个整数的和
///
/// - Note: 传入两个整数即可【批注】
/// - Note: 隐式返回 - 如果整个函数是个单一表达式，那么函数会隐式返回这个表达
func sum4(v1:Int , v2:Int) -> Int {
    v1 + v2
}


//: 参数标签(Argument Label) : 默认生成的参数标签就是形参名称，可以自定义参数标签 如 sum4(v1: <#T##Int#>, v2: <#T##Int#>)

// - at time 属于参数标签 : time是形参，在函数体内用，at是参数标签，调用时使用
func goToWork(at time: String){
    print("go to work at \(time)")
}

goToWork(at: "10:00")

// - 可以使用 _ 省略参数标签
func sum5(_ v1:Int , _ v2:Int) -> Int {
    v1 + v2
}


sum5(100,200)

sum1(v1: 100, v2: 300)

//: 默认参数值 Default Parameter Value
func check(name: String = "nobody", age: Int, job: String = "none"){
    print("name=\(name), age=\(age), job=\(job)")
}

check(age: 15)
check(name: "chunlei.sun", age: 31, job: "iOS Developer")
check(name: "xiaodan.dai", age: 30, job: "nerse")
check(name: "yeye", age: 83)

//: 可变参数 Variable Parameter
func sum11(_ numbers: Int...) -> Int{
    var sum = 0
    for num in numbers{
        sum += num
    }
    return sum
}
print(sum11(1,2,3,4,5,6,7,8,9))

// - 一个函数做多有一个可变参数，紧跟可变参数后边的参数不能省略参数标签

// 参数string不能省略参数标签
func test(_ numbers:Int..., string: String, _ other:String){}
test(10, 20, 30, string: "jack", "rose")


//: Swift自带print函数分析
// public func print(_ items: Any..., separator: String = " ", terminator: String = "\n")

print("1","2","3",separator: "-",terminator: "\n")
print("123")

//:
/*:
 输入输出参数 In-Out Paramer
 - 使用inout定义一个输入输出参数: 可以在函数参数内部修改外部实参的值;
 - 可变参数不能标记为inout
 - inout参数不能有默认值
 - inout参数的本质是地址传递
 - inout参数只能传入可被多次赋值的。
   如：var num = 10;
      
      var numbers = [10,20,30]
      numbers[0] = 20
      numbers[0] = 0
 */

var testNum = 10
func add(_ num: inout Int){
    num += 1000
}
add(&testNum)

print(testNum)

func swapValues(_ v1: inout Int, _ v2: inout Int){
    (v1 , v2) = (v2, v1)
}

var v1 = 10, v2 = 20

swapValues(&v1, &v2)
print(v1,v2)


/*:
 函数重载 Function Overload
 规则
 - 函数名相同
 - 参数个数不同 || 参数类型不同 || 参数标签不同
 - 避免造成歧义即可
 > 重载和返回值类型无关

 */
func overLoad(v1:Int ,v2:Int) -> Int{
    v1 + v2
}

func overLoad(v1:Int ,v2:Int , v3: Int) -> Int{
    v1 + v2 + v3
}
func overLoad(v1:Int ,v2:Double) -> Double{
     Double(v1) + v2
}

func overLoad(a1:Int ,a2:Int) -> Int{
    a1 + a2
}

overLoad(a1: 10, a2: 20)
overLoad(v1: 10, v2: 20)
overLoad(v1: 10, v2: 20, v3: 30)
overLoad(v1: 10, v2: 20.0)


/*:
 内联函数 Inline Function
 - @inline
 - 将函数调用展开为函数体，开启编译器优化，编译器会自动将某些函数展开为内联函数
 */

// 永远不会被内联，即使开启优化
@inline(never) func test(){
    print("never inline func")
}
// 开启优化后，即使函数体很长也会内联。（递归调用函数和动态派发函数除外）
@inline(__always) func test1() -> () {
    print("__always inline func")
}



/*:
 函数类型: 由形式参数类型和返回值类型组成
 */

// ()->Void 或 () -> ()
func test10(){}

// (Int,Int) -> Int
func test10(v1:Int ,v2:Int) -> Int{
    v1 + v2
}

// 定义变量
let fn: (Int,Int) -> Int = test10
fn(10,20) // 调用时不需要参数标签

// 作为函数参数
func sum(v1:Int ,v2:Int) -> Int{
    v1 + v2
}
func difference(v1:Int ,v2:Int) -> Int{
    v1 - v2
}

func printResult(_ mathFn:(Int,Int) -> Int, _ a: Int, _ b: Int){
    print("result is \(mathFn(a,b))")
}
printResult(sum(v1:v2:), 10, 20)
printResult(difference(v1:v2:), 10, 20)

// 函数类型作为返回值: 高阶函数 Higher-Order Function
func next(_ input: Int) -> Int{
    input + 1
}
func previous(_ input: Int) -> Int{
    input - 1
}
func forward(_ forward:Bool) -> (Int)->Int{
    forward ? next(_:) : previous(_:)
}
forward(true)(3)
forward(false)(10)

// typealias: 用来给类型其别名
// 基本类型
typealias Byte  = Int8
typealias Short = Int32
typealias Long  = Int64

// 元组
typealias Date = (year: Int, month: Int, day: Int)
func printDate(date: Date){
    print(date.year)
    print(date.month)
    print(date.day)
}
printDate(date: (2022,4,5))

// 函数
typealias IntFn = (Int,Int) -> Int
let testFn : IntFn = difference(v1:v2:)
testFn(10,20)

func setFn(fn:IntFn){}
setFn(fn: difference(v1:v2:))
func getFn() -> IntFn{
    difference(v1:v2:)
}
getFn()

// swift标准库的定义 Void就是空元组
public typealias Void = ()

// 函数嵌套: 将函数定义在函数内部

func forward2(_ forward:Bool) -> (Int)->Int{
    func next(_ input: Int) -> Int{
        input + 1
    }
    func previous(_ input: Int) -> Int{
        input - 1
    }
    // 整个函数是个单一表达式，那么函数会隐式返回这个表达
    // 很明显该函数不是单一表达式，所以要写return
    return forward ? next(_:) : previous(_:)
}


forward(true)(3)
forward(false)(10)

//: [Previous](@previous)
//: [Next](@next)
