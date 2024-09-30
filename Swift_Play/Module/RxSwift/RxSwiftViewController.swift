//
//  RxSwiftViewController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/4/1.
//

import UIKit
import RxSwift
import RxCocoa

// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/first_app.html

class RxSwiftViewController: UIViewController {
    
    
    @IBOutlet weak var startBtn: UIButton!
    @IBOutlet weak var nameTF: UITextField!
    @IBOutlet weak var pwdTF: UITextField!
    @IBOutlet weak var contentLabel: UILabel!
    /// RxSwiftViewController 释放时，释放bag对象，同时将DisposeBag中的dispose销毁
    fileprivate lazy var bag : DisposeBag = DisposeBag()
    
    let disposeBag = DisposeBag()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "RxSwift"
    
//        testBtn()
//        testTF()
        
//        createObserableMethod()
        
//        debugObserable()
        
//        debugOperator()
    
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //MARK: Operations 操作符
//        rxCreate()
//        rxJust()
//        rxOf()
//        rxError()
//        rxEmpty()
//        rxNever()
        
//        rxTake()
//        rxTakeLast()
//        rxTakeUntil()
//        rxTakeWhile()
//        rxSkip()
//        rxSkipUntil()
//        rxSkipWhile()
//        rxStartWith()
//        rxElementAt()
        rxTimeout()
        
        
        

//        rxScheduler()
//        rxAmb()
//        rxCacheError()
//        rxBuffer()
//        rxCombineLatest()
//        rxContact()
//        rxContactMap()
//        rxConnect()
//        rxDebounce()
//        rxDelay()
//        rxDelaySubscription()
//        rxDeferred()
    }

}


// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree.html
extension RxSwiftViewController{
    struct TestError: Error {
        let msg: String
    }
    
    // MARK: Observable - Create相关操作符
    
    func rxJust() -> Void{
        /**
         创建 Observable 发出唯一的一个元素
         just 操作符将某一个元素转换为 Observable。
         
         just：
         just 用于创建一个只发出 单个值 的 Observable，随后立即完成。
         它只发出一个事件，并且这个事件是你传递给它的单一值。
         
         
         
         一个序列只有唯一的元素 0：
         let id = Observable.just(0)
                 
         它相当于：
         let id = Observable<Int>.create { observer in
             observer.onNext(0)
             observer.onCompleted()
             return Disposables.create()
         }
         
         
         just 只发出一个值，适合单个元素的序列。

         */
        
        let observable = Observable.just("Hello, RxSwift!")

        observable
            .subscribe(onNext: { value in
                print(value)
            })
            .disposed(by: disposeBag)
    }
    
    func rxOf() -> Void{
        /**
         of 用于创建一个可以发出 多个值 的 Observable，并且会依次发出所有传递给它的值，随后完成。
         它可以发出多个事件，并且这些事件是你传递给它的多个值。
         */
        
        let observable = Observable.of("🍎", "🍊", "🍇")

        observable
            .subscribe(onNext: { value in
                print(value)
            })
            .disposed(by: disposeBag)
    }
    
    func rxCreate() -> Void{
        // 创建一个自定义 Observable
        let customObservable = Observable<String>.create { observer in
            // 发出 "Hello"
            observer.onNext("Hello")
            
            // 发出 "RxSwift"
            observer.onNext("RxSwift")
            
            // 发出完成事件
            observer.onCompleted()
            
            // 返回一个 Disposable 来处理清理逻辑
            return Disposables.create()
        }

        // 订阅自定义 Observable
        customObservable
            .subscribe(
                onNext: { print("1" + $0) },
                onError: { print("Error: 1 \($0)") },
                onCompleted: { print("Completed") }
            )
            .disposed(by: disposeBag)
        
        
        customObservable
            .subscribe(
                onNext: { print("2" + $0) },
                onError: { print("Error: 2 \($0)") },
                onCompleted: { print("Completed") }
            )
            .disposed(by: disposeBag)
        
        /**
         1Hello
         1RxSwift
         Completed
         2Hello
         2RxSwift
         Completed
         */
    }

    func rxDeferred() -> Void{
        /**
         在 RxSwift 中，deferred 操作符用于创建一个新的 Observable，该 Observable 的实际创建过程会被延迟，直到有订阅者订阅它时才执行。换句话说，deferred 允许你为每个订阅者创建一个独立的 Observable，以便在每次订阅时执行特定的逻辑。

         deferred 的作用
         延迟创建：deferred 延迟了 Observable 的创建，直到有订阅者订阅它时才执行。每次订阅都会执行新的创建逻辑。
         独立创建：每次订阅时都会生成一个新的 Observable 实例，而不是共享同一个实例。
         这在处理动态或依赖于外部条件的数据源时非常有用，比如生成一个依赖外部变量或状态的 Observable。
         */

        
        // 创建一个 deferred Observable，每次订阅时生成当前时间
        let deferredObservable = Observable<Date>.deferred {
            return Observable.just(Date())  // 每次订阅都会生成当前时间
        }

        deferredObservable
            .subscribe(onNext: { date in
                print("First subscription:", date)
            })
            .disposed(by: disposeBag)

        deferredObservable.delay(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { date in
                print("Second subscription:", date)
            })
            .disposed(by: disposeBag)
        /**
         First subscription: 2024-09-30 06:15:24 +0000
         Second subscription: 2024-09-30 06:15:24 +0000
         
         deferredObservable 使用了 Observable.just(Date())，这意味着 Date() 会在每次创建 Observable 的时候执行，而不是在延时后的订阅时才执行。这是因为 Observable.just 会立即生成事件，不会等待或延迟，虽然你使用了 delay 操作符，延时的是事件的发出时间，但事件的创建时间还是早于延时的。

         */



        // 第一次订阅
        deferredObservable
            .subscribe(onNext: { date in
                print("First subscription:", date)
            })
            .disposed(by: disposeBag)

        // 添加延迟后再进行第二次订阅
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            deferredObservable
                .subscribe(onNext: { date in
                    print("Second subscription:", date)
                })
                .disposed(by: self.disposeBag)
        }
        /**
         First subscription: 2024-09-30 06:15:24 +0000
         Second subscription: 2024-09-30 06:15:25 +0000
         */
    }
    
    func rxError() -> Void{
        /**
         error
         创建一个只有 error 事件的 Observable
         
         error 操作符将创建一个 Observable，这个 Observable 只会产生一个 error 事件。
         
         error 操作符用于创建一个立即抛出错误并终止序列的 Observable。
         它常用于模拟错误或在遇到错误的情况下终止序列。
         可以结合其他操作符来处理错误并恢复序列。
         
         演示
         创建一个只有 error 事件的 Observable：

         let error: Error = ...
         let id = Observable<Int>.error(error)
         它相当于：

         let error: Error = ...
         let id = Observable<Int>.create { observer in
             observer.onError(error)
             return Disposables.create()
         }
         */
        

        // 创建一个立即发出错误的 Observable
        let observable = Observable<String>.error(TestError(msg: "error"))

        observable
            .subscribe(
                onNext: { value in print("Received value: \(value)") },
                onError: { error in print("Received error: \(error)") }
            )
            .disposed(by: disposeBag)

    }
    
    func rxEmpty() -> Void{
        /**
         empty创建一个空 Observable
         empty 操作符将创建一个 Observable，这个 Observable 只有一个完成事件。
         
         在 RxSwift 中，empty 操作符用于创建一个不会发出任何元素（onNext 事件），但会立即发出完成（onCompleted 事件）并终止的 Observable。这个 Observable 序列是空的，不包含任何数据，但它会发送完成信号。

         基本概念：
         empty：创建一个不会发出任何元素，只会发出 onCompleted 的 Observable。
         一旦创建，empty 会立即完成，不会发出 onNext。

         演示
         创建一个空 Observable：

         let id = Observable<Int>.empty()
         它相当于：

         let id = Observable<Int>.create { observer in
             observer.onCompleted()
             return Disposables.create()
         }
         */
    
        // 创建一个空的 Observable，不会发出任何数据，只会发出完成事件
        let observable = Observable<String>.empty()

        observable
            .subscribe(
                onNext: { value in
                    print("Received value: \(value)")
                },
                onCompleted: {
                    print("Sequence completed")
                }
            )
            .disposed(by: disposeBag)

        
        
        /**
         使用场景：
         占位符：当需要返回一个空的 Observable 占位符时，通常在某些逻辑中用作默认的空序列返回。
         条件流控制：可以在特定条件下返回一个不执行任何操作的 Observable，但是确保序列结束。
         组合操作符：在使用 switchIfEmpty 等操作符时，empty 可以用于返回一个空的 Observable，让序列及时结束。
         结合其他操作符：
         empty 操作符经常与 concat, merge 等组合操作符一起使用，在不发出任何事件的情况下终止序列。例如，以下代码演示了如何与 concat 一起使用
         
         示例：与 concat 结合:
         */
        
        let firstObservable = Observable.of("🚀", "🎉")
        let secondObservable = Observable<String>.empty()

        Observable.concat([firstObservable, secondObservable])
            .subscribe(
                onNext: { print($0) },
                onCompleted: { print("All sequences completed") }
            )
            .disposed(by: disposeBag)
        /**
         🚀
         🎉
         All sequences completed
         */
    }
    
    func rxNever() -> Void{
        /**
         never
         创建一个永远不会发出元素的 Observable
         never 操作符将创建一个 Observable，这个 Observable 不会产生任何事件。
         
         在 RxSwift 中，never 操作符用于创建一个永远不会发出任何事件（既不会发出 onNext、onError，也不会发出 onCompleted）的 Observable。它创建的序列将永远保持 "沉默" 状态，既不会终止也不会触发任何事件
         因为 never 不会发出 onCompleted，所以订阅不会结束。

         let id = Observable<Int>.never()
         它相当于：

         let id = Observable<Int>.create { observer in
             return Disposables.create()
         }
         
         使用场景：
         调试和测试：在某些情况下，你可能需要创建一个不会终止的 Observable，例如测试超时或用于调试时查看序列是否正常工作。
         默认或占位符：可以用作某些场景的默认 Observable，表示没有事件发生，通常在条件判断中使用。
         示例：条件判断
         假设你需要在某种条件下返回一个 "无操作" 的 Observable：
  
         */
        
        let shouldEmitValues = false

        let observable: Observable<String> = shouldEmitValues ? Observable.of("Hello") : Observable.never()

        observable
            .subscribe(
                onNext: { print($0) },
                onCompleted: { print("Completed") }
            )
            .disposed(by: disposeBag)
        
        /**
         结合其他操作符：
         在 Rx 中，never 可以与操作符（如 amb）一起使用，来处理竞争条件，或与 timeout 操作符结合使用来测试订阅是否超时。

         示例：结合 timeout
         */
        
        let observable1 = Observable<String>.never()

        observable1
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(
                onNext: { print($0) },
                onError: { print("Error: \($0)") },
                onCompleted: { print("Completed") }
            )
            .disposed(by: disposeBag)
        /**
         Error: Sequence timeout.
         */
    }
    


    // MARK: Observable - 操作元素相关-增删改查
    func rxStartWith() -> Void{
    /**
     startWith
     将一些元素插入到序列的头部
     startWith 操作符会在 Observable 头部插入一些元素。（如果你想在尾部加入一些元素可以用concat）
     */
        
    Observable.of("🐶", "🐱", "🐭", "🐹")
        .startWith("1")
        .startWith("2")
        .startWith("3", "🅰️", "🅱️")
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)

    }
    
    func rxElementAt() -> Void{
        /**
         elementAt
         只发出 Observable 中的第 n 个元素
         elementAt 操作符将拉取 Observable 序列中指定索引数的元素，然后将它作为唯一的元素发出。
         */
        Observable.of("🐱", "🐰", "🐶", "🐸", "🐷", "🐵")
            .element(at: 3)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }

    func rxTake() -> Void{
        /**
         仅仅从 Observable 中发出头 n 个元素
         通过 take 操作符你可以只发出头 n 个元素。并且忽略掉后面的元素，直接结束序列。
         */
        
        Observable.of("🐱", "🐰", "🐶", "🐸", "🐷", "🐵")
            .take(3)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }

    func rxTakeLast() -> Void{
        /**
         仅仅从 Observable 中发出尾部 n 个元素
         通过 takeLast 操作符你可以只发出尾部 n 个元素。并且忽略掉前面的元素。
         */
        Observable.of("🐱", "🐰", "🐶", "🐸", "🐷", "🐵")
            .takeLast(3)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }
    
    func rxTakeUntil() -> Void{
        /**
         takeUntil
         忽略掉在第二个 Observable 产生事件后发出的那部分元素
         takeUntil 操作符将镜像源 Observable，它同时观测第二个 Observable。一旦第二个 Observable 发出一个元素或者产生一个终止事件，那个镜像的 Observable 将立即终止。
         */
        

        let sourceSequence    = PublishSubject<String>()
        let referenceSequence = PublishSubject<String>()

        sourceSequence
            .take(until: referenceSequence)
            .subscribe { print($0) }
            .disposed(by: disposeBag)

        sourceSequence.onNext("🐱")
        sourceSequence.onNext("🐰")
        sourceSequence.onNext("🐶")

        referenceSequence.onNext("🔴")

        sourceSequence.onNext("🐸")
        sourceSequence.onNext("🐷")
        sourceSequence.onNext("🐵")
        /**
         next(🐱)
         next(🐰)
         next(🐶)
         completed
         */
    }
    
    func rxTakeWhile() -> Void{
        /**
         takeWhile
         镜像一个 Observable 直到某个元素的判定为 false

         takeWhile 操作符将镜像源 Observable 直到某个元素的判定为 false。此时，这个镜像的 Observable 将立即终止。
         */
        
        Observable.of(1, 2, 3, 4, 3, 2, 1)
            .take(while: {$0 < 4})
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    }
    
    func rxSkip() -> Void{
    /**
        skip
        跳过 Observable 中头 n 个元素
        skip 操作符可以让你跳过 Observable 中头 n 个元素，只关注后面的元素。
        */
    
    Observable.of("🐱", "🐰", "🐶", "🐸", "🐷", "🐵")
        .skip(2)
        .subscribe(onNext: { print($0) })
        .disposed(by: disposeBag)
}
    
    func rxSkipUntil() -> Void{
    /**
     skipUntil
     跳过 Observable 中头几个元素，直到另一个 Observable 发出一个元素
     skipUntil 操作符可以让你忽略源 Observable 中头几个元素，直到另一个 Observable 发出一个元素后，它才镜像源 Observable。
     */

        let sourceSequence = PublishSubject<String>()
        let referenceSequence = PublishSubject<String>()

        sourceSequence
            .skip(until: referenceSequence)
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        sourceSequence.onNext("🐱")
        sourceSequence.onNext("🐰")
        sourceSequence.onNext("🐶")

        referenceSequence.onNext("🔴")

        sourceSequence.onNext("🐸")
        sourceSequence.onNext("🐷")
        sourceSequence.onNext("🐵")
    
        /**
         🐸
         🐷
         🐵*/

}

    func rxSkipWhile() -> Void{
        /**
         takeWhile
         镜像一个 Observable 直到某个元素的判定为 false

         takeWhile 操作符将镜像源 Observable 直到某个元素的判定为 false。此时，这个镜像的 Observable 将立即终止。
         */
        
        Observable.of(1, 2, 3, 4, 3, 2, 1)
            .skip(while:{ $0 < 4 })
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        
        /**
         4
         3
         2
         1
         */
    }
    
    func rxTimeout() -> Void{
        /**
         timeout
         如果源 Observable 在规定时间内没有发出任何元素，就产生一个超时的 error 事件
         如果 Observable 在一段时间内没有产生元素，timeout 操作符将使它发出一个 error 事件。
         
         在 RxSwift 中，timeout 操作符用于设置一个时间限制，以确保在指定的时间内必须收到事件。若在该时间限制内没有收到任何事件，则会触发 onError 事件。这个操作符常用于处理网络请求、长时间等待或其他可能存在延迟的操作。

         基本概念：
         timeout：用于为 Observable 设置一个时间限制。如果在该时间内未发出任何事件，序列将发出 onError 事件，表示超时。
         可以指定超时的时间间隔和调度程序（scheduler）。
         */
        
        let observable = Observable<Int>.create { observer in
            // 模拟一个没有及时发出事件的情况
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                observer.onNext(1)
                observer.onCompleted()
            }
            return Disposables.create()
        }

        // 设置超时为 2 秒
        observable
            .timeout(.seconds(2), scheduler: MainScheduler.instance)
            .subscribe(
                onNext: { value in
                    print("Received value: \(value)")
                },
                onError: { error in
                    print("Error: \(error)")
                },
                onCompleted: {
                    print("Completed")
                }
            )
            .disposed(by: disposeBag)
        //Error: Sequence timeout.

        
    }
    // MARK: Observable - 元素变换



    func rxScheduler() -> Void {
        /**
         subscribeOn
         subscribeOn 用于指定订阅（subscription）操作在哪个线程执行。它影响的是整个数据流的上游，决定数据流最开始的代码（通常是创建 Observable 或网络请求等）在哪个线程上执行。

         影响的范围：影响从源头开始的所有操作，通常是 Observable 的创建和订阅部分。
         使用场景：当你希望 Observable 的创建、操作或网络请求等在后台线程执行时，可以使用 subscribeOn。
         
         observeOn
         observeOn 用于指定观察者（Observer）在哪个线程上接收和处理事件。它影响的是数据流的下游，决定之后的操作符（如 map、filter）和最终的订阅（如 onNext）在哪个线程上执行。

         影响的范围：影响从调用 observeOn 开始的所有下游操作。
         使用场景：当你希望处理事件的代码在特定的线程（比如主线程）上执行时，可以使用 observeOn。
         */

        let _ = Observable.create { observer in
            print("Creating Observable on thread: \(Thread.current)")
            observer.onNext("Hello")
            observer.onCompleted()
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background)) // 订阅操作将在后台线程
        .subscribe(onNext: {
            print("Received \($0) on thread: \(Thread.current)")
        })
        /**
         Creating Observable on thread: <NSThread: 0x60000172b880>{number = 5, name = (null)}
         Received Hello on thread: <NSThread: 0x60000172b880>{number = 5, name = (null)}
         */
        
        
        
        
        let _ = Observable.create { observer in
            print("Creating Observable on thread: \(Thread.current)")
            observer.onNext("Hello")
            observer.onCompleted()
            return Disposables.create()
        }
        .subscribe(on: ConcurrentDispatchQueueScheduler(qos: .background)) // 订阅操作在后台线程
        .map({ string in
            print("Received \(string) on thread: \(Thread.current)")
            return "map" + string
        })
        .observe(on: MainScheduler.instance) // 观察操作在主线程
        .map({ string in
            print("Received \(string) on thread: \(Thread.current)")
            return "map" + string
        })
        .subscribe(onNext: {
            print("Received \($0) on thread: \(Thread.current)")
        })
        /**
         Creating Observable on thread: <NSThread: 0x600001747180>{number = 3, name = (null)}
         Received Hello on thread: <NSThread: 0x600001747180>{number = 3, name = (null)}
         Received mapHello on thread: <_NSMainThread: 0x600001708140>{number = 1, name = main}
         Received mapmapHello on thread: <_NSMainThread: 0x600001708140>{number = 1, name = main}
         */

    }
    
    func rxAmb() -> Void {
        /**
         在 RxSwift 中，amb 操作符（amb 是 "ambiguous" 的缩写）会比较多个 Observable，并只发出首先发出事件的那个 Observable 的事件。其他的 Observable 将被忽略。
         也就是说，amb 会等待两个或多个 Observable 中的第一个发出事件，然后丢弃其余的 Observable。
         
         用法场景
         amb 操作符常用于以下场景：
         你有多个数据源，想选择最先提供数据的那个。
         在网络请求中，可以发送多个请求，选择最快返回的那个。
         */

        let observable1 = Observable<Int>.create { observer in
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                observer.onNext(1)
                observer.onCompleted()
            }
            return Disposables.create()
        }

        let observable2 = Observable<Int>.create { observer in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                observer.onNext(2)
                observer.onCompleted()
            }
            return Disposables.create()
        }

        Observable.amb([observable1, observable2])
            .subscribe(onNext: {
                print("Received \($0)")
            })
            .disposed(by: disposeBag)
        /**
         Received 2
         */
    }
    
    func rxBuffer() -> Void{
        /**
         buffer 操作符用于将一定时间或数量内的事件收集到一起，然后作为一个数组发出。它可以用来控制发出事件的频率，适用于需要批量处理事件的场景。

         buffer 的两个参数：
         timeSpan：每个缓冲区的时间窗口。
         count：每个缓冲区的最大事件数。
         工作原理：
         当收集到指定数量的事件（count）或超过了指定的时间窗口（timeSpan）时，buffer 会将这些事件作为一个数组发出。
         如果在时间窗口结束时，收集到的事件数量不足指定的 count，它仍然会发出当前收集到的事件。
         */
    
        // 创建一个 Observable，1秒间隔发出一个数字
        let observable = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)

        // 使用 buffer 操作符，2秒的时间窗口或每次最多收集3个事件
        observable
            .buffer(timeSpan: .seconds(2), count: 3, scheduler: MainScheduler.instance)
            .subscribe(onNext: { bufferedItems in
                print("Buffered items: \(bufferedItems)")
            })
            .disposed(by: disposeBag)
        /**
         Buffered items: [0]
         Buffered items: [1, 2, 3]
         Buffered items: [4, 5]
         Buffered items: [6, 7]
         Buffered items: [8, 9]
         Buffered items: [10, 11]
         */

    }
    
    func rxCacheError() -> Void {
        /**
         从一个错误事件中恢复，将错误事件替换成一个备选序列
         
         - catchError 操作符将会拦截一个 error 事件，将它替换成其他的元素或者一组元素，然后传递给观察者。这样可以使得 Observable 正常结束，或者根本都不需要结束。
         - catchAndReturn 操作符会将error 事件替换成其他的一个元素，然后结束该序列。

         */
        
        let sequenceThatFails = PublishSubject<String>()
        let recoverySequence = PublishSubject<String>()

//        sequenceThatFails
//            .catchError {
//                print("Error:", $0)
//                return recoverySequence
//            }
//            .subscribe { print($0) }
//            .disposed(by: disposeBag)
        /**
         next(😬)
         next(😨)
         next(😡)
         next(🔴)
         Error: TestError(msg: "Error - Test")
         next(😊)
         */

        sequenceThatFails
            .catchAndReturn("😄")
            .subscribe { print($0) }
            .disposed(by: disposeBag)
        /**
         next(😬)
         next(😨)
         next(😡)
         next(🔴)
         next(😄)
         completed
         */
        
        sequenceThatFails.onNext("😬")
        sequenceThatFails.onNext("😨")
        sequenceThatFails.onNext("😡")
        sequenceThatFails.onNext("🔴")
        
        sequenceThatFails.onError(TestError(msg: "Error - Test"))

        recoverySequence.onNext("😊")
    }
    
    func rxCombineLatest() -> Void{
        
        let first = PublishSubject<String>()
        let second = PublishSubject<String>()

        Observable.combineLatest(first, second) { $0 + $1 }
                  .subscribe(onNext: { print($0) })
                  .disposed(by: disposeBag)

        print("will first 1")
        first.onNext("1")
        print("will second A")
        second.onNext("A")
        print("will first 2")
        first.onNext("2")
        print("will second B")
        second.onNext("B")
        print("will second C")
        second.onNext("C")
        print("will second D")
        second.onNext("D")
        print("will first 3")
        first.onNext("3")
        print("will first 4")
        first.onNext("4")
        /**
         will first 1
         will second A
         1A
         will first 2
         2A
         will second B
         2B
         will second C
         2C
         will second D
         2D
         will first 3
         3D
         will first 4
         4D
         */

    }

    func rxContact() -> Void{
        /**
         concat
         让两个或多个 Observables 按顺序串连起来
         
         concat 操作符将多个 Observables 按顺序串联起来，当前一个 Observable 元素发送完毕后，后一个 Observable 才可以开始发出元素。
         concat 将等待前一个 Observable 产生完成事件后，才对后一个 Observable 进行订阅。如果后一个是“热” Observable ，在它前一个 Observable 产生完成事件前，所产生的元素将不会被发送出来。
         startWith 和它十分相似。但是 startWith 不是在后面添加元素，而是在前面插入元素。
         merge 和它也是十分相似。merge 并不是将多个 Observables 按顺序串联起来，而是将他们合并到一起，不需要 Observables 按先后顺序发出元素。
         */
        
        
        // 第一个 Observable，发出 "A", "B" 然后完成
        let observable1 = Observable.of("A", "B")

        // 第二个 Observable，发出 "1", "2" 然后完成
        let observable2 = Observable.of("1", "2")

        // 使用 concat 连接两个 Observable
        Observable.concat([observable1, observable2])
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        /**
         A
         B
         1
         2
         */
        
        let task1 = Observable<String>.create { observer in
            DispatchQueue.global().async {
                observer.onNext("Task 1 started")
                Thread.sleep(forTimeInterval: 2) // 模拟异步任务执行
                observer.onNext("Task 1 completed")
                observer.onCompleted()
            }
            return Disposables.create()
        }

        let task2 = Observable<String>.create { observer in
            DispatchQueue.global().async {
                observer.onNext("Task 2 started")
                Thread.sleep(forTimeInterval: 1) // 模拟异步任务执行
                observer.onNext("Task 2 completed")
                observer.onCompleted()
            }
            return Disposables.create()
        }

        Observable.concat([task1, task2])
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        
        /**
         Task 1 started
         Task 1 completed
         Task 2 started
         Task 2 completed
         */
        
        
        let subject1 = BehaviorSubject(value: "🍎")
        let subject2 = BehaviorSubject(value: "🐶")
        

        let subject = BehaviorSubject(value: subject1)

        subject
            .asObservable()
            .concat()
            .subscribe { print($0) }
            .disposed(by: disposeBag)

        subject1.onNext("🍐")
        subject1.onNext("🍊")

        subject.onNext(subject2)

        subject2.onNext("I would be ignored")
        subject2.onNext("🐱")
        
        subject2.onNext("😯")

        subject1.onCompleted()
        
        subject2.onNext("🐭")
        
        /**
         行为分析：
         subject1 和 subject2 初始化

         subject1 初始化时带有初始值 "🍎"，subject2 初始化时带有初始值 "🐶"。
         subject 的初始值是 subject1，因此 subject 持有的是 subject1 的 BehaviorSubject。
         concat 行为

         subject 当前的值是 subject1，并且 concat 确保当前 Observable (subject1) 完成后才会处理下一个 Observable。
         此时，concat 订阅了 subject1，所以 subject1 发出的事件会直接被订阅者接收。
         发出事件：subject1.onNext("🍐") 和 subject1.onNext("🍊")

         由于 concat 当前在处理的是 subject1，subject1 发出的 "🍐" 和 "🍊" 都会被发出。因此输出：
         next(🍎)
         next(🍐)
         next(🍊)
         
         subject.onNext(subject2)

         这一行代码将 subject 的值切换为 subject2，但由于 concat 操作符的规则，subject2 不会立即被订阅。concat 仍然在等待 subject1 完成。
         subject2.onNext("I would be ignored") 和 subject2.onNext("🐱")

         尽管 subject2 现在已经成为 subject 的新值，由于 subject1 还没有完成，concat 仍然关注 subject1，所以 subject2 发出的 "I would be ignored" 会被忽略。
         然而，当 subject1 完成后，subject2 会开始被监听。这意味着 subject2 发出的 "🐱" 会在 subject1 完成后被接收到。
         subject1.onCompleted()

         subject1 发出 completed，concat 开始处理下一个 Observable，也就是 subject2。
         因为 subject2 在 subject1 完成后才会被监听，所以 subject2 发出的 "🐱" 会被接收并打印出来：
         subject2.onNext("🐭")

         现在 subject2 已经被监听，所以发出的 "🐭" 也会被接收到并打印：
         text
         Copy code
         next(🐭)

         
         */
    }
    
    func rxContactMap() -> Void{
        /**
         concatMap
         将 Observable 的元素转换成其他的 Observable，然后将这些 Observables 串连起来
         
         concatMap 操作符将源 Observable 的每一个元素应用一个转换方法，将他们转换成 Observables。然后让这些 Observables 按顺序的发出元素，当前一个 Observable 元素发送完毕后，后一个 Observable 才可以开始发出元素。等待前一个 Observable 产生完成事件后，才对后一个 Observable 进行订阅。
         */
    
        // 模拟的网络请求，返回一个 Observable
        func makeRequest(id: Int) -> Observable<String> {
            return Observable<String>.create { observer in
                print("Request \(id) started")
                DispatchQueue.global().asyncAfter(deadline: .now() + Double(id)) {
                    observer.onNext("Response from request \(id)")
                    observer.onCompleted()
                }
                return Disposables.create()
            }
        }

        // 创建源 Observable，发出 1, 2, 3
        let requestIDs = Observable.of(1, 2, 3)

        // 使用 concatMap 将每个 ID 映射为一个网络请求，按顺序执行
        requestIDs
            .concatMap { id in
                return makeRequest(id: id)
            }
            .subscribe(onNext: { response in
                print(response)
            })
            .disposed(by: disposeBag)

        
        /**


         
         */
    }

    func rxConnect() -> Void{
        /**
         ConnectableObservable 和普通的 Observable 十分相似，不过在被订阅后不会发出元素，直到 connect 操作符被应用为止。这样一来你可以等所有观察者全部订阅完成后，才发出元素。
         
         
         connect 是用于操作“冷”可连接的 Observable（ConnectableObservable）的一个方法。通过调用 connect，可以开始向订阅者发送事件。

         什么是 ConnectableObservable
         在 RxSwift 中，Observable 可以分为两种：

         “冷”Observable（Cold Observable）：每个订阅者会从头开始接收事件。无论什么时候订阅，它都会从头重新发送数据。
         “热”Observable（Hot Observable）：它不会等待订阅者，而是持续发送事件，所有订阅者会共享同一个数据流。
         ConnectableObservable 是一种特殊的“冷”Observable，但它具有某些“热”Observable的行为。具体来说，ConnectableObservable 在调用 connect() 方法之前是“冷”的，它不会自动发送数据，只有在 connect() 被调用后才开始发送事件。

         connect 的作用
         connect() 的作用是 启动 ConnectableObservable 的事件发送。在 connect 被调用之前，即使有订阅者，ConnectableObservable 也不会发送任何事件。调用 connect() 后，它会开始广播事件给所有当前的订阅者。

         创建 ConnectableObservable
         通过调用 publish() 方法，可以将一个“冷”Observable 转换为 ConnectableObservable。这种 Observable 不会立即发送事件，而是等待 connect 的调用。
         
         
         
         为什么使用 connect 和 ConnectableObservable？
         ConnectableObservable 的主要用途是 控制事件流的开始时间，并且允许多个订阅者共享同一数据源。例如：

         在启动前等待多个订阅者就绪。
         多个订阅者同时接收相同的事件，而不需要重新触发数据源。
         */
        
        // 创建一个冷的 Observable，它会从头开始发送事件
        let coldObservable = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .take(5)

        // 将冷的 Observable 转换为 ConnectableObservable
        let connectableObservable = coldObservable.publish()

        // 订阅第一个订阅者
        connectableObservable
            .subscribe(onNext: { print("Subscriber 1: \($0)") })
            .disposed(by: disposeBag)

        // 此时没有调用 connect，所以没有事件发出
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 订阅第二个订阅者
            connectableObservable
                .subscribe(onNext: { print("Subscriber 2: \($0)") })
                .disposed(by: self.disposeBag)
            
            // 现在调用 connect，开始发送事件
            let _ = connectableObservable.connect()
        }
        
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            // 订阅第三个订阅者
            connectableObservable
                .subscribe(onNext: { print("Subscriber 3: \($0)") })
                .disposed(by: self.disposeBag)
        }
        /**
         Subscriber 1: 0
         Subscriber 2: 0
         Subscriber 1: 1
         Subscriber 2: 1
         Subscriber 1: 2
         Subscriber 2: 2
         Subscriber 3: 2
         Subscriber 1: 3
         Subscriber 2: 3
         Subscriber 3: 3
         Subscriber 1: 4
         Subscriber 2: 4
         Subscriber 3: 4
         */

    }
    
    func rxDebounce() -> Void{
        /**
         过滤掉高频产生的元素
         debounce 操作符将发出这种元素，在 Observable 产生这种元素后，一段时间内没有新元素产生。
         
         在 RxSwift 中，debounce 操作符是用于处理快速连续发出的事件流，并且只允许在指定的时间间隔后没有新事件发出的情况下才发出最近的事件。这个操作符通常用于处理 抖动（debouncing）场景，例如防止按钮被频繁点击或者限制文本输入的频繁搜索请求。

         debounce 的作用
         debounce 的主要功能是：当事件停止发出指定时间间隔后，发出最后一个事件。如果在这个间隔内继续有新的事件发出，计时器会重置，直到没有新的事件产生。

         适合用于处理用户输入、点击等高频事件，避免不必要的操作或请求。
         如果事件持续不断，可能永远不会发出任何事件，因为计时器会不断重置
         */

        // 创建一个模拟的用户输入序列
        let inputText = PublishSubject<String>()

        // 使用 debounce 来忽略快速输入
        inputText
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { print("User input: \($0)") })
            .disposed(by: disposeBag)

        // 模拟用户快速输入
        inputText.onNext("H")
        inputText.onNext("He")
        inputText.onNext("Hel")
        inputText.onNext("Hell")
        inputText.onNext("Hello")

        // 延迟后模拟输入停止
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            inputText.onNext("Hello, RxSwift!")
        }
    }
    
    func rxDelay() -> Void{
        /**
         将 Observable 的每一个元素拖延一段时间后发出
         delay 操作符将修改一个 Observable，它会将 Observable 的所有元素都拖延一段设定好的时间， 然后才将它们发送出来。
         
         在 RxSwift 中，delay 操作符用于延迟 Observable 中事件的发出时间。它不会影响事件的创建时机，只是将事件延迟一段时间后再发给订阅者。
         基本概念：
         delay：将 Observable 产生的事件延迟指定的时间后发出。
         事件的创建：尽管 delay 延迟了事件的发出时间，但事件本身是立即创建的。延迟仅影响订阅者何时收到这些事件。

         delay 操作符只会延迟 正常的事件（onNext 和 onCompleted），但是 不会延迟 Error 事件。这是为了确保错误能够及时被捕获和处理。
         */
        
        // 创建一个 Observable 发出多个元素
        let observable = Observable.of("🍎", "🍊", "🍇")

        observable
            .delay(.seconds(2), scheduler: MainScheduler.instance)  // 延迟 2 秒发出所有事件
            .subscribe(onNext: { value in
                print(value)
            })
            .disposed(by: disposeBag)


    }
    
    func rxDelaySubscription() -> Void{
        /**
         进行延时订阅
         delaySubscription 操作符将在经过所设定的时间后，才对 Observable 进行订阅操作。
         
         */

        // 创建一个发出多个事件的 Observable
        let observable = Observable.of("🍎", "🍊", "🍇")

        observable
            .delaySubscription(.seconds(2), scheduler: MainScheduler.instance)  // 延迟 2 秒后订阅
            .subscribe(onNext: { value in
                print(value)
            })
            .disposed(by: disposeBag)

    }
    
}





// MARK: 非我自己写的

extension RxSwiftViewController{
    func testSubject() {
        print("----------------Subject----------------")
/************************** Subject *************************************/

/// Subject: Obserable和Observer之间的桥梁，即可被订阅也可发送事件

        // 1.PublishSubject,订阅者只能接收订阅之后发送的事件
        let publistSub = PublishSubject<String>()
        
        publistSub.onNext("123")
        
        publistSub.subscribe { event in
            print(event) // next(456)
        }.disposed(by: bag)
        
        publistSub.onNext("456")
        
        
        print("--------------------------------")
        
        
        // 2.ReplaySubject: 可以接收到订阅他之后的事件，但也可以接收到订阅他之发出的事件，接受几个事件取决于bufferSize的大小
        let replaySub = ReplaySubject<String>.create(bufferSize: 2)
//        let replaySub = ReplaySubject<String>.createUnbounded()

        replaySub.onNext("a")
        replaySub.onNext("b")
        replaySub.onNext("c")
        replaySub.subscribe { event in
            print(event)
            /**
             next(b)
             next(c)
             next(d)
             next(e)
             */
        }.disposed(by: bag)
        replaySub.onNext("d")
        replaySub.onNext("e")

        print("--------------------------------")

        
        // 3. BehavioreSubject,订阅者可以接收订阅之前的最后一个事件
        let behavioreSub = BehaviorSubject(value: "a")

        behavioreSub.onNext("b")
        behavioreSub.onNext("c")
        behavioreSub.subscribe { event in
            print(event)
            /**
             next(c)
             next(d)
             next(e)
             */
        }.disposed(by: bag)
        behavioreSub.onNext("d")
        behavioreSub.onNext("e")

     
        
        print("--------------变换操作------------------")

        /***************** 变换操作 *******************/

        // 1.swift中如何使用map
        let array = [1,2,3,4]
        var tempArray = [Int]()
        for num in array{
            tempArray.append(num * num)
        }
        print(tempArray) // [1, 4, 9, 16]

        
        print("--------------------------------")
        
        /// 函数式编程
        let array2 = array.map { num in
            return num * 100
        }
        print(array2) // [100, 200, 300, 400]
        print("--------------------------------")

        // 2. 在RxSwift中map函数的使用
        
        Observable.of(1,2,3,4).map { num in
            return num * num
        }.subscribe { event in
            print(event.element)
            /**
             Optional(1)
             Optional(4)
             Optional(9)
             Optional(16)
             nil
             */
        }

        print("--------------------------------")
        // http://t.swift.gg/d/19-007
        // 3.flatMap使用 : 将一个序列发射的值转换成序列，然后将他们压平到一个序列
        
        let sequenceInt = Observable.of(1, 2, 3)

        let sequenceString = Observable.of("A", "B", "C", "D", "E", "F", "--")

        sequenceInt.flatMap { x in
            print("from sequenceInt \(x)")
            return sequenceString
        }.subscribe { event in
            print(event.element)
            /**
             from sequenceInt 1
             Optional("A")
             from sequenceInt 2
             Optional("B")
             Optional("A")
             from sequenceInt 3
             Optional("C")
             Optional("B")
             Optional("A")
             Optional("D")
             Optional("C")
             Optional("B")
             Optional("E")
             Optional("D")
             Optional("C")
             Optional("F")
             Optional("E")
             Optional("D")
             Optional("--")
             Optional("F")
             Optional("E")
             Optional("--")
             Optional("F")
             Optional("--")
             nil
             */
        }
        print("--------------------------------")

        // flatMapLatest : 当进行 flatMapLatest 转换时有新的值发射过来时就丢弃旧的值，取flatMapLatest新的值。
        
        sequenceInt.flatMapLatest { x in
            print("from sequenceInt \(x)")
            return sequenceString
        }.subscribe { event in
            print(event.element)
            /**
             from sequenceInt 1
             Optional("A")
             from sequenceInt 2
             Optional("A")
             from sequenceInt 3
             Optional("A")
             Optional("B")
             Optional("C")
             Optional("D")
             Optional("E")
             Optional("F")
             Optional("--")
             nil
             */
        }
        
        print("--------------------------------")

        
        // flatMapFirst : flatMapFirst 和 flatMapLatest 不同就是 flatMapFisrt 会选择旧的值，抛弃新的。
        
        sequenceInt.flatMapFirst { x in
            print("from sequenceInt \(x)")
            return sequenceString
        }.subscribe { event in
            print(event.element)
            /**
             from sequenceInt 1
             Optional("A")
             Optional("B")
             Optional("C")
             Optional("D")
             Optional("E")
             Optional("F")
             Optional("--")
             nil
             */
        }
    }
}

extension RxSwiftViewController{
    /// 断点调试Obserable(其实就是RAC中的Signal 、CreateSignal)
    func debugObserable() {
        let create0 = creteObservable()
        create0.subscribe { event in
            print(event.element)
            /**
             Optional("sclcoder")
             Optional("30")
             nil
             */
        }
    }
}


extension RxSwiftViewController{
    func creteObservable() -> Observable<Any> {
        // 6.create : 自定义可观察的sequence
        return Observable.create { (observer : AnyObserver<Any>) -> Disposable in
            observer.onNext("sclcoder")
            observer.onNext("30")
            observer.onCompleted()
            
            return Disposables.create()
        }
    }
    
    
    func myJustObserable(element: String) -> Observable<String> {
        return Observable.create { (observer : AnyObserver<String>) -> Disposable in
            observer.onNext(element)
            observer.onCompleted()
            return Disposables.create()
        }
    }
}

/// 创建Obserable的常见操作
extension RxSwiftViewController{
    func createObserableMethod() {
        
        // 1.never是创建一个sequence不能发出任何事件
        let never0 = Observable<String>.never()
        never0.subscribe { event in
            print(event) /// 啥也没有
        }
        print("-------------------------------")

        // 2.empty是创建一个sequence只会发送completed事件
        let empty = Observable<String>.empty()
        empty.subscribe { event in
            print(event) /// completed
        }
        empty.subscribe(onCompleted: {
            print("done")  // done
        })
       
        print("-------------------------------")

        // 3.just是创建一个sequence只能发出一种特定的事件，能正常结束
        let just0 = Observable.just("coder")
        just0.subscribe { event in
            print(event) //  next(coder)、 completed
        }
        
        print("-------------------------------")

        // 4.of是创建一个sequence只能发出一种特定的事件，能正常结束
        let of0 = Observable.of("a","b","c")
        
        of0.subscribe { Event in
            print(Event) // next(a) 、next(b)、next(c)、completed
        }
        
        of0.subscribe { Event in
            print(Event.event) // next(a) 、next(b)、next(c)、completed
        }
        
        of0.subscribe { Event in
            print(Event.event.element) // Optional("a") 、Optional("b")、Optional("c")、nil
        }
        
        print("-------------------------------")
        // 5.from是从数组中创建sequence
        let array = [1,2,3]
        let from0 = Observable.from(array)
        from0.subscribe { Event in
            print(Event.event.element) // Optional(1) 、Optional(2)、Optional(3)、nil
        }
        print("-------------------------------")

        /// 6.create: 自定义
        let create0 = creteObservable()
        create0.subscribe { event in
            print(event.element)
            /**
             Optional("sclcoder")
             Optional("30")
             nil
             */
        }
        
        print("-------------------------------")

        /// 7.通过create自定义just
        let myJust0 = myJustObserable(element: "myJustObserable")
        myJust0.subscribe { event in
            print(event.element)
            /**
             Optional("myJustObserable")
             nil
             */
        }
        print("-------------------------------")

        /// 8.range: 创建一个sequence,他会发出这个范围中的从开始到结束的所有事件
        
        let range0 = Observable.range(start: 10, count: 5)
        range0.subscribe { event in
            print(event.element)
            /**
             Optional(10)
             Optional(11)
             Optional(12)
             Optional(13)
             Optional(14)
             nil
             */
        }
        
        print("-------------------------------")

        /// 9. repeatElement: 创建一个sequence，发出特定的事件n次，如不指定次数会一直发送
        let repeat0 = Observable.repeatElement("repeatElement")
        repeat0
            .take(2)
            .subscribe { (Event) in
                 print(Event)
                /**
                 next(repeatElement)
                 next(repeatElement)
                 completed
                 */
        }
        
        print("-------------------------------")

    }
}



/// UIButton
extension RxSwiftViewController{
    
    func testBtn() -> Void {
        
        let _ = startBtn.rx.tap.subscribe({event in
                    print("tap",event)
                })

        
        /// 默认是.touchUpInside
        let _ = startBtn.rx.tap.subscribe(onNext:{
                    print("touchUpInside")
                },onError:{ error in
                    print("onError", error)
                },onCompleted: {
                    print("onCompleted")
                },onDisposed: {
                    print("onDisposed")
                })
        
        let _ = startBtn.rx.tap.subscribe(onNext: {_ in  print("tap")}, onDisposed: {})

        
        let _ = startBtn.rx.controlEvent(.touchDown).subscribe { (event: ControlEvent<()>.Element) in
                print("touchDown",event)
                } onDisposed: {
                    print("onDisposed")
                }
        
    }
}

/// UITextField
extension RxSwiftViewController{
    
    func testTF() -> Void {
        
        
//        let _ = nameTF.rx.text.subscribe { event in
//                    print(event)
//                }
        
//        let _ = nameTF.rx.text.subscribe { (text : String?) in
//            print(text!)
//        }
        
        
        let _ = nameTF.rx.text.bind(to: contentLabel.rx.text)
        
        /// KVO
        let _ = contentLabel.rx.observe(String.self, "text").subscribe { text in
                    print(text! + "KVO")
                }
        
        
        //        let _ = nameTF.rx.text.orEmpty.map {
        //            return "\($0)" + "😯"
        //        }.subscribe { text in
        //            self.contentLabel.text = text
        //        }
                
//        let _ = nameTF.rx.text.orEmpty.scan("0") { a,b in
//                    return a+b
//                }.subscribe { text in
//                    self.contentLabel.text = text
//                }
//
//
//        let _ = pwdTF.rx.text.subscribe { text in
//                    self.contentLabel.text = nil
//                }
    }
}
