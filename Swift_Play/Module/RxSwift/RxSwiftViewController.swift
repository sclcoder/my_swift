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
//        rxRepeatElement()
//        rxError()
//        rxEmpty()
//        rxNever()
//        rxDeferred()
//        rxFrom()
//        rxUsing()

        
//        rxTake()
//        rxTakeLast()
//        rxTakeUntil()
//        rxTakeWhile()
//        rxSkip()
//        rxSkipUntil()
//        rxSkipWhile()
//        rxStartWith()
//        rxElementAt()
//        rxSingle()
        
//        rxIgnoreElements()
//        rxDistinctUntilChanged()
//        rxDebounce()
//        rxCacheError()
//        rxBuffer()
        
//        rxInterval()


//        rxScheduler()
//        rxDo()
//        rxDebug()
    
//        rxTimeout()
//        rxTimer()
//        rxDelay()
//        rxDelaySubscription()
    
//        rxAmb()
//        rxMerge()
//        rxZip()
//        rxCombineLatest()
//        rxContact()
//        rxContactMap()
//        rxConnect()
//        rxSample()
        
//        rxGroupBy()
        
//        rxFilter()
//        rxMap()
//        rxFlatMap()
        rxFlatMapLatest()
//        rxReduce()
//        rxScan()
        
//        rxRetry()
        
//        rxReplay()
//        rxShareReplay()

    }

}


// https://beeth0ven.github.io/RxSwift-Chinese-Documentation/content/decision_tree.html
extension RxSwiftViewController{
    struct TestError: Error {
        let msg: String
    }
    
    // MARK: Observable - 多线程
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
    
    // MARK: 副作用
    func rxDo() -> Void{
        /**
         do
         当 Observable 产生某些事件时，执行某个操作
         当 Observable 的某些事件产生时，你可以使用 do 操作符来注册一些回调操作。这些回调会被单独调用，它们会和 Observable 原本的回调分离。
         
         
         在 RxSwift 中，do 操作符用于在 Observable 发出的事件流中执行副作用操作，但不会改变事件流的值或结构。它通常用于调试、日志记录、状态更新等场景，允许你观察事件的生命周期或执行其他操作，而不会对实际的数据流产生影响。

         do 操作符的作用
         执行副作用：do 可以在事件生命周期的不同阶段执行自定义操作，如在 onNext、onError 或 onCompleted 等事件发生时执行额外的操作。
         不改变数据流：do 只用于观察或执行副作用，不会改变数据的传递。它类似于拦截器，可以在事件发出前或发出后做一些额外的处理。
         常见用途
         日志记录：可以记录数据的流动情况、错误信息或完成状态。
         调试：在不同阶段插入调试信息，方便排查问题。
         更新状态：在收到某些事件时更新 UI 状态或触发其他非数据操作。
         do 的使用方法
         do 提供多个可选的回调函数来处理不同的事件：

         onNext: 在每次发出下一个事件时执行。
         onError: 在发出错误事件时执行。
         onCompleted: 在完成事件时执行。
         onSubscribe: 当有订阅时执行。
         onDispose: 当订阅被清理（disposed）时执行。
         
         do(onNext: ((Element) -> Void)? = nil,
            onError: ((Swift.Error) -> Void)? = nil,
            onCompleted: (() -> Void)? = nil,
            onSubscribe: (() -> Void)? = nil,
            onDispose: (() -> Void)? = nil)
         */
        

        let observable = Observable.of(1, 2, 3, 4, 5)

        observable
            .do(onNext: { value in
                print("Intercepted value: \(value)") // 每次发出下一个事件时打印
            }, onError: { error in
                print("Intercepted error: \(error)") // 发生错误时打印
            }, onCompleted: {
                print("Sequence completed") // 完成时打印
            }, onDispose: {
                print("Disposed") // 订阅清理时打印
            })
            .subscribe(
                onNext: { value in
                    print("Received value: \(value)")
                },
                onCompleted: {
                    print("Subscription completed")
                }
            )
            .disposed(by: disposeBag)

        /**
         Intercepted value: 1
         Received value: 1
         Intercepted value: 2
         Received value: 2
         Intercepted value: 3
         Received value: 3
         Intercepted value: 4
         Received value: 4
         Intercepted value: 5
         Received value: 5
         Sequence completed
         Subscription completed
         Disposed
         
         解释：
         do 在每个事件的生命周期中添加了额外的操作，但不改变事件流。
         onNext 触发时，do 打印拦截到的值，同时订阅者接收到并打印值。
         完成时，do 打印了 "Sequence completed"，同时订阅者也接收到完成事件并打印。
         在订阅被释放时，do 的 onDispose 也会被调用，表示清理了订阅。
         */
        
        
        /**
         使用场景
         调试和日志：

         do 操作符非常适合用来记录事件的生命周期，帮助在调试时跟踪数据流动的情况。
         UI 状态更新：

         当收到某个事件时，可以使用 do 来更新 UI 的状态，比如加载动画的显示或隐藏。
         副作用操作：

         可以在事件流的过程中插入一些非数据的操作，比如更新某些全局状态或记录分析数据。
         
         
         
         import RxSwift
         import Moya

         let disposeBag = DisposeBag()

         let provider = MoyaProvider<SomeService>()

         provider.rx.request(.someRequest)
             .do(onSubscribe: {
                 print("Network request started")
             }, onDispose: {
                 print("Network request disposed")
             })
             .subscribe(onSuccess: { response in
                 print("Received response: \(response)")
             }, onError: { error in
                 print("Error occurred: \(error)")
             })
             .disposed(by: disposeBag)

         */
        
        
        
    }

    func rxDebug() -> Void{
        /**
         打印所有的订阅，事件以及销毁信息
         */
        
        let sequence = Observable<String>.create { observer in
            observer.onNext("🍎")
            observer.onNext("🍐")
            observer.onCompleted()
            return Disposables.create()
        }

        sequence
            .debug("Fruit")
            .subscribe()
            .disposed(by: disposeBag)
        
        /**
         2024-09-30 17:39:32.353: Fruit -> subscribed
         2024-09-30 17:39:32.356: Fruit -> Event next(🍎)
         2024-09-30 17:39:32.356: Fruit -> Event next(🍐)
         2024-09-30 17:39:32.356: Fruit -> Event completed
         2024-09-30 17:39:32.356: Fruit -> isDisposed
         */
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
    
    func rxRepeatElement() -> Void {
        /**
         repeatElement
         创建重复发出某个元素的 Observable
         repeatElement 操作符将创建一个 Observable，这个 Observable 将无止尽地发出同一个元素。
         */
        
//        创建重复发出 0 的 Observable
        let id = Observable.repeatElement(0)
        id.subscribe(onNext: { value in
                print(value)
        })
        .disposed(by: disposeBag)
        
//        它相当于：
//        let id = Observable<Int>.create { observer in
//            observer.onNext(0)
//            observer.onNext(0)
//            observer.onNext(0)
//            observer.onNext(0)
//            ... // 无数次
//            return Disposables.create()
//        }
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
    
    func rxFrom() -> Void {
      /**
       from
       将其他类型或者数据结构转换为 Observable
       当你在使用 Observable 时，如果能够直接将其他类型转换为 Observable，这将是非常省事的。from 操作符就提供了这种功能。
       
       
       在 RxSwift 中，from 操作符用于将一个序列（如数组、集合等）转换为一个 Observable。该 Observable 会依次发出序列中的每个元素，并在所有元素发出完毕后发送完成事件 (onCompleted)。from 操作符非常适合用于将现有的集合类型数据转换为响应式的事件流，以便在 RxSwift 的链式操作中进行处理。

       基本概念
       from：接受一个符合 Sequence 协议的集合（如数组、集合等），并将集合中的每个元素依次作为 onNext 事件发出，最后发送 onCompleted 事件。
       适用场景：将现有的集合数据转换为 Observable，以便在响应式编程中进行进一步的操作，如过滤、映射、合并等。
       */
    
    /**
     将一个数组转换为 Observable：
             let numbers = Observable.from([0, 1, 2])
     它相当于：
     let numbers = Observable<Int>.create { observer in
         observer.onNext(0)
         observer.onNext(1)
         observer.onNext(2)
         observer.onCompleted()
         return Disposables.create()
     }
     */
    
        let numbers = [1, 2, 3, 4, 5]

        // 使用 from 操作符将数组转换为 Observable
        Observable.from(numbers)
            .subscribe(
                onNext: { value in
                    print("Value: \(value)")
                },
                onCompleted: {
                    print("Sequence completed")
                }
            )
            .disposed(by: disposeBag)
        
        /**
         Value: 1
         Value: 2
         Value: 3
         Value: 4
         Value: 5
         */
        
    }
    
    func rxUsing() -> Void {
        /**
         using
         创建一个可被清除的资源，它和 Observable 具有相同的寿命
         通过使用 using 操作符创建 Observable 时，同时创建一个可被清除的资源，一旦 Observable 终止了，那么这个资源就会被清除掉了。

         
         
         
         在 RxSwift 中，using 操作符用于创建一个 Observable，并同时管理一个资源的生命周期。它允许你在创建 Observable 时使用某种资源，并确保该资源在 Observable 的生命周期结束时（即当 Observable 发出 onCompleted 或 onError 后）被正确地释放或清理。通常用于需要在 Observable 生命周期中绑定资源的场景，例如打开文件、数据库连接等需要明确关闭或释放的资源。

         基本概念：
         using：用于在 Observable 的生命周期内绑定并管理资源。
         该操作符接收一个工厂方法来创建 Observable，同时接收另一个工厂方法来创建与之关联的资源。资源的释放与 Observable 的结束紧密关联，确保不发生资源泄漏。
         
         语法：
         func using<Resource: Disposable>(
             _ resourceFactory: @escaping () throws -> Resource,
             observableFactory: @escaping (Resource) throws -> Observable<Element>
         ) -> Observable<Element>
         resourceFactory：用于创建资源的工厂函数。该资源需要遵循 Disposable 协议。
         observableFactory：用于创建 Observable 的工厂函数，它接受一个资源作为参数，返回一个 Observable。
         
         
         工作原理：
         创建资源：using 首先通过 resourceFactory 创建资源。
         创建 Observable：然后通过 observableFactory 生成与该资源相关联的 Observable。
         管理资源生命周期：当 Observable 终止时，using 操作符确保资源被正确地释放。
         
         
         使用场景：
         管理外部资源：特别是在与外部资源交互（如文件句柄、数据库连接、网络连接等）的场景下，确保资源在 Observable 的生命周期结束时正确释放。
         自动释放资源：避免手动管理资源的释放，减少资源泄漏的风险。
         绑定资源与 Observable：适合将资源与数据流绑定的场景，确保资源的生命周期与数据流一致。
         总结：
         using 操作符在 RxSwift 中提供了一种方便的方法，用于创建与 Observable 关联的资源，并在 Observable 终止时自动清理这些资源。
         适用于需要确保资源在数据流结束时释放的场景，比如文件操作、数据库连接等。
         通过 using，你可以轻松地确保资源的创建与销毁与 Observable 的生命周期保持一致，避免资源泄漏。
         */
        
        
        /**
         示例 1：使用 using 管理资源
         假设我们需要使用一个资源（比如文件句柄）来读取数据，并确保在读取完成后文件句柄被正确关闭。
         */
        
        // 模拟的文件资源类
        class FileHandle: Disposable {
            let fileName: String
            
            init(fileName: String) {
                self.fileName = fileName
                print("Opened file: \(fileName)")
            }
            
            func dispose() {
                print("Closed file: \(fileName)")
            }
        }

        // 使用 using 操作符管理文件资源
        let observable = Observable<String>.using(
            { () -> FileHandle in
                return FileHandle(fileName: "example.txt")
            },
            observableFactory: { fileHandle in
                return Observable.of("Line 1", "Line 2", "Line 3")
            }
        )

        observable
            .subscribe(
                onNext: { line in
                    print("Read: \(line)")
                },
                onCompleted: {
                    print("Completed reading")
                }
            )
            .disposed(by: disposeBag)
        
        /**
         Opened file: example.txt
         Read: Line 1
         Read: Line 2
         Read: Line 3
         Completed reading
         Closed file: example.txt
         解释：
         using 操作符首先通过 resourceFactory 打开文件句柄。
         observableFactory 返回一个 Observable，用于读取文件中的每一行。
         当 Observable 终止时（发出 onCompleted），文件句柄会自动关闭，确保资源被正确释放。
         */
        
    }
    
    // MARK: Observable - 元素发送相关-增删查
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

    func rxDistinctUntilChanged() -> Void{
        /**
         distinctUntilChanged 阻止 Observable 发出相同的元素
         distinctUntilChanged 操作符将阻止 Observable 发出相同的元素。如果后一个元素和前一个元素是相同的，那么这个元素将不会被发出来。如果后一个元素和前一个元素不相同，那么这个元素才会被发出来。
         */
        
        Observable.of("🐱", "🐷", "🐱", "🐱", "🐱", "🐵", "🐱")
            .distinctUntilChanged()
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        /**
         🐱
         🐷
         🐱
         🐵
         🐱
         */
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
    
    func rxIgnoreElements() -> Void {
        /**
         ignoreElements
         忽略掉所有的元素，只发出 error 或 completed 事件
         ignoreElements 操作符将阻止 Observable 发出 next 事件，但是允许他发出 error 或 completed 事件。
         如果你并不关心 Observable 的任何元素，你只想知道 Observable 在什么时候终止，那就可以使用 ignoreElements 操作符。
         
         
         
         在 RxSwift 中，ignoreElements 操作符用于忽略 Observable 中发出的所有 onNext 事件，只接收 onError 和 onCompleted 事件。这意味着订阅者将不会接收到任何元素（即不会收到值），而只会响应错误或完成事件。

         基本概念：
         ignoreElements：将 Observable 的 onNext 事件忽略，只有 onError 和 onCompleted 会被触发。
         适用于需要对某个 Observable 的完成或错误状态感兴趣，但不关心其发出的值的场景。
         */

        let observable = Observable<String>.create { observer in
            observer.onNext("Hello")
            observer.onNext("World")
            observer.onCompleted()
            return Disposables.create()
        }

        // 使用 ignoreElements
        observable
            .ignoreElements()
            .subscribe(
                onError: { error in
                    print("Error: \(error)")
                },
                onCompleted: {
                    print("Completed")
                }
            )
            .disposed(by: disposeBag)
        /**
         Completed

         解释：
         在这个示例中，observable 发出了两个值 "Hello" 和 "World"，然后完成。
         使用 ignoreElements 后，订阅者不会收到这两个值，只会在完成时打印 "Completed"。
         
         使用场景：
         只关心完成或错误：当你只关心某个操作是否成功完成或是否发生错误，而不关心其具体发出的值时，可以使用 ignoreElements。
         简化处理：在链式操作中，使用 ignoreElements 可以简化对值的处理，专注于状态的变化。
         */

        
    }

    func rxSingle() -> Void {
        /**
         single
         限制 Observable 只有一个元素，否出发出一个 error 事件
         
         single 操作符将限制 Observable 只产生一个元素。如果 Observable 只有一个元素，它将镜像这个 Observable 。如果 Observable 没有元素或者元素数量大于一，它将产生一个 error 事件。
         
         
         在 RxSwift 中，single 操作符用于从 Observable 中只发出一个满足条件的元素。如果该条件满足的元素有多个，或者没有任何元素满足条件，single 操作符会发出一个错误事件。

         single 有两种常见的使用方式：

         发出 Observable 中的唯一一个元素（该 Observable 必须只包含一个元素，否则会抛出错误）。
         发出 Observable 中满足给定条件的唯一一个元素。如果有多个元素满足条件或没有满足条件的元素，都会抛出错误。
         基本概念：
         single：如果 Observable 发出多个元素或者没有元素，single 操作符会报错。如果只发出一个元素或者一个满足条件的元素，则顺利发出该元素并结束序列。
         它非常适用于期望 Observable 只发出一个元素的场景。
         */
        
//        示例 1：single() 无条件版本
        let numbers = Observable.just(42)
        // 使用 single 操作符确保只发出一个元素
        numbers
            .single()
            .subscribe(onNext: { value in
                print("Single value: \(value)")
            })
            .disposed(by: disposeBag)
/**
 Single value: 42
 解释：
 numbers 只发出一个值 42，然后结束。
 single() 操作符确保 Observable 中只发出一个元素，因此正常发出 42。
 */
        
//        示例 2：single() 带条件版本
        let numbers2 = Observable.from([1, 2, 3, 4, 5])
        // 使用 single 操作符查找唯一一个偶数
        numbers2
            .single { $0 % 2 == 0 }
            .subscribe(
                onNext: { value in
                    print("Single even number: \(value)")
                },
                onError: { error in
                    print("Error:", error)
                }
            )
            .disposed(by: disposeBag)
/**
 输出：
 Single even number: 2
 Error: Sequence contains more than one element.
 */
        
    }
    
    // MARK: Observable - 元素变换 - 改
    func rxInterval() -> Void {
        /**
         interval
         创建一个 Observable 每隔一段时间，发出一个索引数
         interval 操作符将创建一个 Observable，它每隔一段设定的时间，发出一个索引数的元素。它将发出无数个元素。
         
         
         
         在 RxSwift 中，interval 操作符用于创建一个可观察的序列，它会以固定的时间间隔发出递增的整数值。这个操作符非常适合用于实现定时器、周期性任务或任何需要定期发出事件的场景。

         基本概念：
         interval：生成一个 Observable，它将在指定的时间间隔内发出递增的整数值，开始时从 0 开始。
         你可以指定发出事件的时间间隔，以及使用的调度程序（scheduler），通常使用 MainScheduler 或 SerialDispatchQueueScheduler。
         */
   
        // 创建一个每秒发出递增整数的 Observable
        let intervalObservable = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)

        intervalObservable
            .subscribe(onNext: { value in
                print("Interval emitted value: \(value)")
            })
            .disposed(by: disposeBag)
/**
 Interval emitted value: 0
 Interval emitted value: 1
 Interval emitted value: 2
 ...
 解释：
 intervalObservable 每秒发出一个递增的整数，从 0 开始。
 每当新的整数被发出时，subscribe 的 onNext 闭包就会被调用，打印出相应的值。
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
    
    func rxFilter() -> Void{
        /**
         filter
         仅仅发出 Observable 中通过判定的元素
         filter 操作符将通过你提供的判定方法过滤一个 Observable。
         */
        
        Observable.of(2, 30, 22, 5, 60, 1)
                  .filter { $0 > 10 }
                  .subscribe(onNext: { print($0) })
                  .disposed(by: disposeBag)
        
    }
    
    func rxMap() -> Void {
        /**
         map
         通过一个转换函数，将 Observable 的每个元素转换一遍
         map 操作符将源 Observable 的每个元素应用你提供的转换方法，然后返回含有转换结果的 Observable。
         
         map：将每个源事件映射为另一个事件，但是结果是直接返回值，而不是 Observable。

         */
        
        Observable.of(1, 2, 3)
            .map { $0 * 10 }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

    }
    
    func rxFlatMap() -> Void {
        /**
         flatMap
         将 Observable 的元素转换成其他的 Observable，然后将这些 Observables 合并
         
         flatMap 操作符将源 Observable 的每一个元素应用一个转换方法，将他们转换成 Observables。 然后将这些 Observables 的元素合并之后再发送出来。
         这个操作符是非常有用的，例如，当 Observable 的元素本身拥有其他的 Observable 时，你可以将所有子 Observables 的元素发送出来。
         
         
         
         
         在 RxSwift 中，flatMap 是一个非常常用的操作符，用于将每个源事件转换为一个新的 Observable，并将这些新的 Observable 的事件合并（flatten）到一个统一的事件流中。通过 flatMap，你可以处理异步任务、链式请求或从事件中获取新的 Observable。

         flatMap 的核心概念
         转换与合并：flatMap 可以把源 Observable 的每个事件转换为一个新的 Observable，然后将所有这些 Observable 的事件流合并成一个单一的 Observable。
         并发：flatMap 会并发处理转换后的多个 Observable，即这些新的 Observable 会同时被订阅并发出事件。
         使用场景
         异步任务链式处理：比如将用户输入的内容映射到网络请求，并将结果作为新的事件发出。
         事件转换：将某个事件映射为另一个事件序列，可以用于复杂的转换逻辑。
        
         */
        
        // 创建一个基础的源 Observable
        let numbers = Observable.of(1, 2, 3)

        // 使用 flatMap 将每个数字转换为一个新的 Observable
        numbers
            .flatMap { number -> Observable<String> in
                return Observable.just("Number: \(number)")
            }.debug("flatMap")
            .subscribe(onNext: { result in
                print(result)
            })
            .disposed(by: disposeBag)
        /**
         Number: 1
         Number: 2
         Number: 3
         解释：
         numbers 是一个包含 1, 2, 3 的源 Observable。
         使用 flatMap 将每个数字映射为一个新的 Observable，即一个包含字符串 "Number: \(number)" 的 Observable。
         所有这些新的 Observable 的事件被合并到单一的流中并发出，结果是依次打印出每个映射后的字符串。
         
         
         2024-09-30 18:04:07.910: flatMap -> subscribed
         2024-09-30 18:04:07.913: flatMap -> Event next(Number: 1)
         Number: 1
         2024-09-30 18:04:07.914: flatMap -> Event next(Number: 2)
         Number: 2
         2024-09-30 18:04:07.914: flatMap -> Event next(Number: 3)
         Number: 3
         2024-09-30 18:04:07.914: flatMap -> Event completed
         2024-09-30 18:04:07.914: flatMap -> isDisposed
         */
        
        let first = BehaviorSubject(value: "👦🏻")
        let second = BehaviorSubject(value: "🅰️")
        let subject = BehaviorSubject(value: first)

        subject.asObservable()
                .debug("subject")
                .flatMap { $0 }
                .debug("innerSubject")
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)

        first.onNext("🐱")
        subject.onNext(second)
        first.onNext("🐶")
        second.onNext("🅱️")

        /**
         2025-01-14 17:38:41.726: innerSubject -> subscribed
         2025-01-14 17:38:41.726: subject -> subscribed
         2025-01-14 17:38:41.732: subject -> Event next(RxSwift.BehaviorSubject<Swift.String>)
         2025-01-14 17:38:41.732: innerSubject -> Event next(👦🏻)
         👦🏻
         2025-01-14 17:38:41.732: innerSubject -> Event next(🐱)
         🐱
         2025-01-14 17:38:41.732: subject -> Event next(RxSwift.BehaviorSubject<Swift.String>)
         2025-01-14 17:38:41.732: innerSubject -> Event next(🅰️)
         🅰️
         2025-01-14 17:38:41.732: innerSubject -> Event next(🐶)
         🐶
         2025-01-14 17:38:41.732: innerSubject -> Event next(🅱️)
         🅱️
         */
    }
    
    func rxFlatMapLatest() -> Void {
        /**
         flatMapLatest
         将 Observable 的元素转换成其他的 Observable，然后取这些 Observables 中最新的一个
         flatMapLatest 操作符将源 Observable 的每一个元素应用一个转换方法，将他们转换成 Observables。一旦转换出一个新的 Observable，就只发出它的元素，旧的 Observables 的元素将被忽略掉。

         
         flatMapLatest 与 flatMap 的区别
         flatMap：会并行处理所有的事件，无论新的事件是否到达，所有的 Observable 都会继续发出事件。
         flatMapLatest：只保留最近的 Observable，如果源 Observable 发出新的事件，会取消之前的 Observable，只处理最新的。

         */
        
        let first = BehaviorSubject(value: "👦🏻")
        let second = BehaviorSubject(value: "🅰️")
        let subject = BehaviorSubject(value: first)

        subject.asObservable()
                .debug("subject")
                .flatMapLatest { $0 }
                .debug("innerSubject")
                .subscribe(onNext: { print($0) })
                .disposed(by: disposeBag)

        first.onNext("🐱")
        subject.onNext(second)
        first.onNext("🐶")
        second.onNext("🅱️")

        /**
         👦🏻
         🐱
         🅰️ /// subject.onNext(second) 后，就不再处理first中的事件了
         🅱️
         
         debug:
         2025-01-14 17:39:42.432: innerSubject -> subscribed
         2025-01-14 17:39:42.434: subject -> subscribed
         2025-01-14 17:39:42.437: subject -> Event next(RxSwift.BehaviorSubject<Swift.String>)
         2025-01-14 17:39:42.438: innerSubject -> Event next(👦🏻)
         👦🏻
         2025-01-14 17:39:42.439: innerSubject -> Event next(🐱)
         🐱
         2025-01-14 17:39:42.439: subject -> Event next(RxSwift.BehaviorSubject<Swift.String>)
         2025-01-14 17:39:42.439: innerSubject -> Event next(🅰️)
         🅰️
         2025-01-14 17:39:42.439: innerSubject -> Event next(🅱️)
         🅱️
         */
    }
    
    func rxReduce() -> Void {
        /**
         reduce
         持续的将 Observable 的每一个元素应用一个函数，然后发出最终结果
         reduce 操作符将对第一个元素应用一个函数。然后，将结果作为参数填入到第二个元素的应用函数中。以此类推，直到遍历完全部的元素后发出最终结果。
         这种操作符在其他地方有时候被称作是 accumulator，aggregate，compress，fold 或者 inject。
         
         
         
         在 RxSwift 中，reduce 操作符用于将一个 Observable 中发出的多个值聚合为一个值。它通过一个初始值和一个聚合函数，依次处理序列中的每个元素，并返回一个最终结果。这使得 reduce 非常适合用于累积计算或汇总数据的场景。

         基本概念：
         reduce：接收一个初始值和一个聚合函数，依次将 Observable 中的每个元素与累积值进行合并，最终返回一个单一的值。
         该操作符的返回值是一个 Observable，其发出的值是聚合后的结果。
         语法：
         swift
         Copy code
         func reduce<Result>(_ initial: Result, accumulator: @escaping (Result, Element) throws -> Result) -> Observable<Result>
         initial: 初始值，用于开始累积。
         accumulator: 聚合函数，接收当前累积值和当前元素，返回新的累积值。
         */


//        示例 1：基本用法
//        在这个例子中，我们创建一个 Observable，并使用 reduce 来计算数组中所有数字的总和。
        
        let numbers = Observable.from([1, 2, 3, 4, 5])

        // 使用 reduce 计算总和
        numbers
            .reduce(0) { accumulator, value in
                accumulator + value
            }
            .subscribe(onNext: { total in
                print("Total sum: \(total)")
            })
            .disposed(by: disposeBag)
//        输出：
//        Total sum: 15
//        解释：
//        numbers 是一个发出数字的 Observable。
//        使用 reduce(0)，从 0 开始，依次将每个数字与累积值相加。
//        最终结果是 15，表示数组中所有数字的总和。
        
        
        /**
         reduce 操作符在 RxSwift 中用于将多个发出的值聚合为一个值，非常适合进行累积计算或数据汇总。
         它通过初始值和聚合函数来处理每个元素，最终返回单一结果。
         可以与其他操作符结合使用，以实现更复杂的逻辑和处理。
         */
    }
    
    func rxScan() -> Void {
        /**
         scan
         持续的将 Observable 的每一个元素应用一个函数，然后发出每一次函数返回的结果
         scan 操作符将对第一个元素应用一个函数，将结果作为第一个元素发出。然后，将结果作为参数填入到第二个元素的应用函数中，创建第二个元素。以此类推，直到遍历完全部的元素
         这种操作符在其他地方有时候被称作是 accumulator。
         
         
         在 RxSwift 中，scan 操作符是一个聚合操作符，它会从第一个元素开始，依次应用一个累加器闭包对序列中的元素进行处理，并将每一次处理的中间结果作为新的 Observable 发出。换句话说，scan 可以看作是一个可以逐步积累的操作，它类似于标准集合中的 reduce，但不同的是，scan 会在每一步都发出累加的结果，而不是只在最后发出一次。

         基本概念：
         scan 会对序列中的元素应用一个累加器闭包，并发出每一次的累积结果。
         你可以指定一个初始值，并将该初始值与序列的第一个元素结合起来应用累加器。
         语法：
         swift
         Copy code
         func scan<A>(
             _ seed: A,
             accumulator: @escaping (A, Element) throws -> A
         ) -> Observable<A>
         seed：累加的初始值。
         accumulator：一个累加器闭包，接收两个参数：上一个累加的结果（或初始值）和当前元素，返回累加后的新值。
         返回值：返回一个新的 Observable，它会发出每一次累加后的结果。
         
         
         */
        
//        示例 1：计算累加和
//        我们可以使用 scan 来累加序列中的值，并在每次计算后发出当前的累加结果。

        let numbers = Observable.of(1, 2, 3, 4, 5)

        numbers
            .scan(0) { accumulatedValue, newValue in
                return accumulatedValue + newValue
            }
            .subscribe(onNext: { result in
                print("Accumulated result: \(result)")
            })
            .disposed(by: disposeBag)
  /**
   Accumulated result: 1
   Accumulated result: 3
   Accumulated result: 6
   Accumulated result: 10
   Accumulated result: 15
   解释：
   我们使用 scan(0) 指定初始值为 0。
   每次通过累加器闭包，将当前值与之前的累积值相加，累加结果会在每一步都被发出。
   */
        
        
//        示例 2：统计字符串长度
//        可以使用 scan 操作符来累积字符串的长度，并在每一步都输出累计长度。

        let words = Observable.of("Hello", "RxSwift", "is", "awesome")

        words
            .scan(0) { totalLength, word in
                return totalLength + word.count
            }
            .subscribe(onNext: { result in
                print("Total length so far: \(result)")
            })
            .disposed(by: disposeBag)
 
  /**
   Total length so far: 5
   Total length so far: 12
   Total length so far: 14
   Total length so far: 21
   */
    }
    
    // MARK: Observable - 延时
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
    
    func rxTimer() -> Void{
        /**
         在 RxSwift 中，timer 操作符用于创建一个定时器 Observable，它会在指定的时间延迟后发出一个事件，并可以选择重复发出后续事件。这个操作符非常适合用于定时任务或周期性事件的处理。

         基本概念：
         timer：创建一个 Observable，它在指定的时间后发出一个值，之后可以选择性地按照指定的时间间隔重复发出值。
         timer 的返回值是一个可观察的 Observable，它会在规定的时间间隔内发出事件。
         
         static func timer(_ dueTime: RxTimeInterval, scheduler: SchedulerType) -> Observable<Int>
         static func timer(_ dueTime: RxTimeInterval, period: RxTimeInterval, scheduler: SchedulerType) -> Observable<Int>
         dueTime: 第一个事件发出的延迟时间。
         period: 可选参数，表示之后发出事件的时间间隔。
         scheduler: 用于调度定时器的调度程序，通常是 MainScheduler 或 SerialDispatchQueueScheduler。
         */
        
        
//        let periodicTimer = Observable<Int>.timer(.seconds(1), period: .seconds(1), scheduler: MainScheduler.instance)
//        periodicTimer
//            .subscribe(onNext: { value in
//                print("Timer fired with value: \(value)")
//            })
//            .disposed(by: disposeBag)
        
        
        let timerWithCompletion = Observable<Int>.timer(.seconds(2), period: .seconds(1), scheduler: MainScheduler.instance)
            .do(onNext: { value in
                print("Timer fired with value: \(value)")
            })
            .take(2) // 只取第一个事件

        timerWithCompletion
            .debug("Timer")
            .subscribe(onCompleted: {
                print("Timer completed")
            })
            .disposed(by: disposeBag)
/**
 Timer fired with value: 0
 Timer fired with value: 1
 Timer completed
 
 加入debug后:
 
 2024-09-30 17:42:01.272: Timer -> subscribed
 Timer fired with value: 0
 2024-09-30 17:42:03.274: Timer -> Event next(0)
 Timer fired with value: 1
 2024-09-30 17:42:04.273: Timer -> Event next(1)
 2024-09-30 17:42:04.273: Timer -> Event completed
 Timer completed
 2024-09-30 17:42:04.273: Timer -> isDisposed
 */

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


    // MARK: Observable - 多个Observable
    
    func rxMerge() -> Void {
        /**
         merge
         将多个 Observables 合并成一个
         
         通过使用 merge 操作符你可以将多个 Observables 合并成一个，当某一个 Observable 发出一个元素时，他就将这个元素发出。
         如果，某一个 Observable 发出一个 onError 事件，那么被合并的 Observable 也会将它发出，并且立即终止序列。
         */
    
        let subject1 = PublishSubject<String>()
        let subject2 = PublishSubject<String>()

        Observable.of(subject1, subject2)
            .merge()
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)

        subject1.onNext("🅰️")

        subject1.onNext("🅱️")

        subject2.onNext("①")

        subject2.onNext("②")

        subject1.onNext("🆎")

        subject2.onNext("③")
        
        /**
         🅰️
         🅱️
         ①
         ②
         🆎
         ③
         */
    }
    
    func rxZip() -> Void {
        /**
         zip
         通过一个函数将多个 Observables 的元素组合起来，然后将每一个组合的结果发出来
         
         zip 操作符将多个(最多不超过8个) Observables 的元素通过一个函数组合起来，然后将这个组合的结果发出来。它会严格的按照序列的索引数进行组合。例如，返回的 Observable 的第一个元素，是由每一个源 Observables 的第一个元素组合出来的。它的第二个元素 ，是由每一个源 Observables 的第二个元素组合出来的。它的第三个元素 ，是由每一个源 Observables 的第三个元素组合出来的，以此类推。它的元素数量等于源 Observables 中元素数量最少的那个。
         */
        
        let first = PublishSubject<String>()
        let second = PublishSubject<String>()

        Observable.zip(first, second) { $0 + $1 }
                  .subscribe(onNext: { print($0) })
                  .disposed(by: disposeBag)

        first.onNext("1")
        second.onNext("A")
        first.onNext("2")
        second.onNext("B")
        second.onNext("C")
        second.onNext("D")
        first.onNext("3")
        first.onNext("4")
        /**
         1A
         2B
         3C
         4D
         */
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
    
    func rxSample() -> Void {
        /**
         sample
         不定期的对 Observable 取样
         
         sample 操作符将不定期的对源 Observable 进行取样操作。通过第二个 Observable 来控制取样时机。一旦第二个 Observable 发出一个元素，就从源 Observable 中取出最后产生的元素。
         
         
         在 RxSwift 中，sample 操作符用于从源 Observable 中取样，在另一个 Observable 发出值时，取源 Observable 最近的一个值并发出。这个操作符特别适用于需要从源序列中获取最新数据，但只在另一个序列触发时发出数据的场景。

         基本概念：
         sample：监听一个触发 Observable（称为“采样器”），每当采样器发出事件时，sample 会从源 Observable 中取出最近的一个值并发出。如果在采样器发出事件时，源 Observable 没有新值，则不发出任何值。
         sample 只在采样器发出 onNext 事件时发出值，并且只发出源 Observable 的最新值。
         */
        
        
        let source = PublishSubject<String>()
        let trigger = PublishSubject<Void>()

        // 使用 sample 操作符
        source
            .sample(trigger)
            .subscribe(onNext: { value in
                print("Sampled value: \(value)")
            })
            .disposed(by: disposeBag)

        // 模拟源 Observable 发出值
        source.onNext("🍎")
        source.onNext("🍐")

        // 模拟触发 Observable 发出事件，采样最近的值
        trigger.onNext(())
        // 输出: Sampled value: 🍐

        source.onNext("🍊")
        source.onNext("🍉")

        // 再次触发采样
        trigger.onNext(())
        // 输出: Sampled value: 🍉
        
        source.onNext("🍎")
        
        trigger.onNext(()) // 输出: Sampled value: 🍎
        
        // 没有新值时触发
        trigger.onNext(()) // 不会有任何输出

        
        /**
         Sampled value: 🍐
         Sampled value: 🍉
         Sampled value: 🍎
         解释：
         source 是源 Observable，它发出了几个水果符号的值。
         trigger 是采样器 Observable，它决定何时从 source 取样并发出最近的一个值。
         每次 trigger.onNext(()) 被调用时，sample 操作符会取 source 的最新值并发出。
         如果 trigger 触发时 source 没有新值，那么不会发出任何值。
         */

    }
    
    func rxGroupBy() -> Void {
        /**
         在 RxSwift 中，groupBy 操作符用于将一个 Observable 序列中的元素按照某个条件进行分组，并为每一个组返回一个新的 Observable。每个组中的元素都是符合该组条件的值。分组后的每个 Observable 会发出属于该组的元素。

         基本概念：
         groupBy：将 Observable 中的元素按某个分类键进行分组，并返回一个 Observable，这个 Observable 发出分组后的 GroupedObservable 对象。每个 GroupedObservable 代表一个分组，其中包含所有属于该组的元素。
         可以根据元素的某些属性进行分组，比如根据类型、值的范围等。
         
         语法：
         swift
         Copy code
         func groupBy<Key>(
             _ keySelector: @escaping (Element) throws -> Key
         ) -> Observable<GroupedObservable<Key, Element>>
         keySelector：一个闭包，用于根据元素生成分组的键。
         返回值是一个 Observable，它会发出 GroupedObservable，每个 GroupedObservable 是属于该组的元素流。
         */
        
//        示例 1：根据奇偶性分组
        let numbers = Observable.from([1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
        numbers
            .groupBy { $0 % 2 == 0 ? "Even" : "Odd" } // 按奇偶性分组
            .flatMap { group -> Observable<String> in
                group.map { number in
                    return "\(group.key): \(number)"
                }
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
    /**
     输出：
     Odd: 1
     Even: 2
     Odd: 3
     Even: 4
     Odd: 5
     Even: 6
     Odd: 7
     Even: 8
     Odd: 9
     Even: 10
     解释：
     groupBy { $0 % 2 == 0 ? "Even" : "Odd" } 根据奇偶性将序列中的数字分为两组：偶数和奇数。
     每个 GroupedObservable 持有属于该组的所有元素。
     使用 flatMap 将每个分组的元素映射为字符串形式，并发出结果。
     */
        
        
        
//        示例 2：根据字符串长度分组
  
        let strings = Observable.from(["Swift", "RxSwift", "Objective-C", "Kotlin", "Java"])

        strings
            .groupBy { $0.count } // 按字符串长度分组
            .flatMap { group -> Observable<String> in
                group.map { element in
                    return "Length \(group.key): \(element)"
                }
            }
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
/**
 Length 5: Swift
 Length 7: RxSwift
 Length 11: Objective-C
 Length 6: Kotlin
 Length 4: Java
 解释：
 groupBy { $0.count } 根据字符串的长度将字符串分组。
 每个 GroupedObservable 代表长度相同的字符串。
 */
    
        
        /**
         使用场景：
         分类处理：当需要对流中的元素按照某种规则进行分类处理时，groupBy 是一个有用的操作符。
         分离不同类型的数据：可以根据某个属性将不同类型的数据分开处理。
         流式聚合：适用于对流中的元素进行动态聚合或分组处理的场景。
         总结：
         groupBy 是一种将 Observable 序列按某个键进行分组的操作符，它为每个组创建一个独立的 Observable。
         每个 GroupedObservable 都会发出属于该组的元素，允许对分组后的元素进行单独处理。
         常用于对数据按某个规则进行分类、过滤或分离处理。
         */
    }
    
    

    // MARK: Observable - 暂未分组
    
    func rxRetry() -> Void {
        /**
         retry
         如果源 Observable 产生一个错误事件，重新对它进行订阅，希望它不会再次产生错误
         
         retry 操作符将不会将 error 事件，传递给观察者，然而，它会从新订阅源 Observable，给这个 Observable 一个重试的机会，让它有机会不产生 error 事件。retry 总是对观察者发出 next 事件，即便源序列产生了一个 error 事件，所以这样可能会产生重复的元素（如上图所示）。
         
         
         */
        var count = 1

        let sequenceThatErrors = Observable<String>.create { observer in
            observer.onNext("🍎")
            observer.onNext("🍐")
            observer.onNext("🍊")

            if count == 1 {
                observer.onError(TestError(msg: "rxRetry"))
                print("Error encountered")
                count += 1
            }

            observer.onNext("🐶")
            observer.onNext("🐱")
            observer.onNext("🐭")
            observer.onCompleted()

            return Disposables.create()
        }

        sequenceThatErrors
            .retry()
            .subscribe(onNext: { print($0) })
            .disposed(by: disposeBag)
        
        /**
         🍎
         🍐
         🍊
         Error encountered
         🍎
         🍐
         🍊
         🐶
         🐱
         🐭
         */
    }

    func rxReplay() -> Void {
        /**
         replay
         确保观察者接收到同样的序列，即使是在 Observable 发出元素后才订阅
         
         可被连接的 Observable 和普通的 Observable 十分相似，不过在被订阅后不会发出元素，直到 connect 操作符被应用为止。这样一来你可以控制 Observable 在什么时候开始发出元素。

         replay 操作符将 Observable 转换为可被连接的 Observable，并且这个可被连接的 Observable 将缓存最新的 n 个元素。当有新的观察者对它进行订阅时，它就把这些被缓存的元素发送给观察者。
         */
        
        let intSequence = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .replay(5)

        _ = intSequence
            .subscribe(onNext: { print("Subscription 1:, Event: \($0)") })

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            _ = intSequence.connect()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
          _ = intSequence
              .subscribe(onNext: { print("Subscription 2:, Event: \($0)") })
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
          _ = intSequence
              .subscribe(onNext: { print("Subscription 3:, Event: \($0)") })
        }
        /**
         Subscription 1:, Event: 0
         Subscription 2:, Event: 0
         Subscription 1:, Event: 1
         Subscription 2:, Event: 1
         Subscription 1:, Event: 2
         Subscription 2:, Event: 2
         Subscription 1:, Event: 3
         Subscription 2:, Event: 3
         Subscription 1:, Event: 4
         Subscription 2:, Event: 4
         Subscription 3:, Event: 0
         Subscription 3:, Event: 1
         Subscription 3:, Event: 2
         Subscription 3:, Event: 3
         Subscription 3:, Event: 4
         Subscription 1:, Event: 5
         Subscription 2:, Event: 5
         Subscription 3:, Event: 5
         Subscription 1:, Event: 6
         Subscription 2:, Event: 6
         Subscription 3:, Event: 6
         */
        
      

    }
    
    func rxShareReplay() -> Void {
        /**
         shareReplay
         使观察者共享 Observable，观察者会立即收到最新的元素，即使这些元素是在订阅前产生的
         shareReplay 操作符将使得观察者共享源 Observable，并且缓存最新的 n 个元素，将这些元素直接发送给新的观察者。


         
         在 RxSwift 中，shareReplay 是一个帮助操作符，通常用于多个订阅者共享同一个 Observable 的元素并对这些元素进行缓存。它的作用类似于 share 操作符，但带有缓存功能，会缓存最近发出的元素，并在新订阅者订阅时重播这些元素。

         基本概念：
         shareReplay：共享 Observable 的数据流，并为新订阅者重播最近的 N 个元素。
         通过重放机制，多个订阅者可以避免重新执行昂贵的操作（例如网络请求、计算等），而直接获取之前发出的数据。
         它会缓存最新发出的 N 个元素，并在新订阅者订阅时重新发送这些缓存的值。
         为什么使用 shareReplay？
         如果你有一个会产生副作用的 Observable，例如网络请求或复杂计算，你可能希望多个订阅者共享同一个数据流，而不必重复执行副作用。shareReplay 允许你做到这一点。
         你还可以指定缓存多少个最近的值，并确保当新订阅者加入时，他们能收到最近缓存的值。
         
         语法：

         observable.shareReplay(_ bufferSize: Int)
         bufferSize：指定缓存的最近元素个数，也就是当新订阅者订阅时，最多能重播多少个上次发出的值。
         
         
         使用场景：
         网络请求共享：避免同一个网络请求被多次执行，多个订阅者可以共享同一个请求的结果。
         重放最新值：你希望新订阅者能够立即获取到最近的值，而不是等待 Observable 发出新的值。
         昂贵计算的结果共享：如果 Observable 代表一个昂贵的计算过程，使用 shareReplay 可以避免重复计算。
         缓冲数据：当你希望在多个订阅者之间共享一个 Observable，并且这些订阅者需要接收到最近发出的数据时，可以使用 shareReplay。
         总结：
         shareReplay 是 RxSwift 中一个强大的操作符，它允许你将 Observable 的数据流共享给多个订阅者，同时缓存最近发出的 N 个元素，以便新订阅者可以接收到之前的值。
         它常用于避免重复执行副作用（如网络请求、复杂计算），并确保数据能够在多个订阅者之间重用。
         
         */

        
//        示例 1：基本用法
//        假设我们有一个 Observable，它会每隔 1 秒钟发出一个递增的整数，使用 shareReplay(2) 可以缓存最近的两个值，并重播给新订阅者。


//        let source = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance).share(replay: 2)
//
//        source
//            .subscribe(onNext: { print("Subscription 1: \($0)") })
//            .disposed(by: disposeBag)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
//            source
//                .subscribe(onNext: { print("Subscription 2: \($0)") })
//                .disposed(by: self.disposeBag)
//        }
//
        /**
         Subscription 1: 0
         Subscription 1: 1
         Subscription 1: 2
         Subscription 1: 3
         Subscription 1: 4
         Subscription 2: 3
         Subscription 2: 4
         Subscription 2: 5
         解释：
         Subscription 1 开始订阅时，每隔 1 秒钟收到一个递增的整数。
         在 5 秒后，Subscription 2 开始订阅时，由于使用了 shareReplay(2)，它会收到最近缓存的两个值（即 3 和 4），并且继续接收后续发出的值。
         */
        
    
//        示例 2：共享网络请求
//        使用 shareReplay 可以共享一次网络请求的结果，避免多次发起同样的请求
//        func fetchData() -> Observable<String> {
//            return Observable<String>.create { observer in
//                print("Fetching data from network...")
//                observer.onNext("Server response")
//                observer.onCompleted()
//                return Disposables.create()
//            }
//        }
//
//        let sharedRequest = fetchData()
//            .share(replay: 1, scope: .forever) // 缓存最近1个网络请求结果
//        // 测试发现 scope使用 .whileConnected, 每次订阅都会触发Observable的创建
//
//        sharedRequest
//            .subscribe(onNext: { print("Subscriber 1 received: \($0)") })
//            .disposed(by: disposeBag)
//
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
//            sharedRequest
//                .subscribe(onNext: { print("Subscriber 3 received: \($0)") })
//                .disposed(by: self.disposeBag)
//        }
//
//        sharedRequest
//            .subscribe(onNext: { print("Subscriber 2 received: \($0)") })
//            .disposed(by: self.disposeBag)
        /**
         
         
         Fetching data from network...
         Subscriber 1 received: Server response
         Subscriber 2 received: Server response
         Subscriber 3 received: Server response
         
         */
        

        // 创建一个每秒发出一个整数的 Observable
        let source = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
//
//        // 示例 1: 使用 share(replay: 1, scope: .forever)
//        let foreverShared = source.share(replay: 1, scope: .forever)
//
//        print("Example 1: share(replay: 1, scope: .forever)")
//
//        // 第一个订阅
//        let firstSubscription = foreverShared.subscribe(onNext: { value in
//            print("First subscriber: \(value)")
//        })
//
//        // 2 秒后取消第一个订阅
//        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//            // 实际取消订阅
//            print("First subscriber disposed")
//            firstSubscription.dispose()
//        }
//
//        // 4 秒后，新的订阅
//        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
//            foreverShared.subscribe(onNext: { value in
//                print("Second subscriber: \(value)")
//            }).disposed(by: self.disposeBag)
//        }
        
        /**
         Example 1: share(replay: 1, scope: .forever)
         First subscriber: 0
         First subscriber: 1
         First subscriber disposed
         Second subscriber: 1
         Second subscriber: 0
         Second subscriber: 1
         Second subscriber: 2
         Second subscriber: 3
         ...
         */

        // 示例 2: 使用 share(replay: 1, scope: .whileConnected)
        let whileConnectedShared = source.share(replay: 1, scope: .whileConnected)

        print("\nExample 2: share(replay: 1, scope: .whileConnected)")

        // 第一个订阅
        let firstSubscriptionWhileConnected = whileConnectedShared.subscribe(onNext: { value in
            print("First subscriber: \(value)")
        })

        // 2 秒后取消第一个订阅
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // 实际取消订阅
            print("First subscriber disposed")
            firstSubscriptionWhileConnected.dispose()
        }

        // 4 秒后，新的订阅
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            whileConnectedShared.subscribe(onNext: { value in
                print("Second subscriber: \(value)")
            }).disposed(by: self.disposeBag)
        }

        /**
         
         Example 2: share(replay: 1, scope: .whileConnected)
         First subscriber: 0
         First subscriber: 1
         First subscriber disposed
         Second subscriber: 0
         Second subscriber: 1
         Second subscriber: 2
         Second subscriber: 3
         Second subscriber: 4
         ...
         */

    }
    
    func rxPublish() -> Void {
        /**
         publish
         将 Observable 转换为可被连接的 Observable

         publish 会将 Observable 转换为可被连接的 Observable。可被连接的 Observable 和普通的 Observable 十分相似，不过在被订阅后不会发出元素，直到 connect 操作符被应用为止。这样一来你可以控制 Observable 在什么时候开始发出元素。
         */
        
        let intSequence = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
            .publish()

        _ = intSequence
            .subscribe(onNext: { print("Subscription 1:, Event: \($0)") })

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            _ = intSequence.connect()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
          _ = intSequence
              .subscribe(onNext: { print("Subscription 2:, Event: \($0)") })
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
          _ = intSequence
              .subscribe(onNext: { print("Subscription 3:, Event: \($0)") })
        }
        /**
         Subscription 1:, Event: 0
         Subscription 1:, Event: 1
         Subscription 2:, Event: 1
         Subscription 1:, Event: 2
         Subscription 2:, Event: 2
         Subscription 1:, Event: 3
         Subscription 2:, Event: 3
         Subscription 3:, Event: 3
         Subscription 1:, Event: 4
         Subscription 2:, Event: 4
         Subscription 3:, Event: 4
         Subscription 1:, Event: 5
         Subscription 2:, Event: 5
         Subscription 3:, Event: 5
         Subscription 1:, Event: 6
         Subscription 2:, Event: 6
         Subscription 3:, Event: 6
         ...
         */
    }
    
    func rxRefCount() -> Void {
        /**
         refCount
         将可被连接的 Observable 转换为普通 Observable

         可被连接的 Observable 和普通的 Observable 十分相似，不过在被订阅后不会发出元素，直到 connect 操作符被应用为止。这样一来你可以控制 Observable 在什么时候开始发出元素。

         refCount 操作符将自动连接和断开可被连接的 Observable。它将可被连接的 Observable 转换为普通 Observable。当第一个观察者对它订阅时，那么底层的 Observable 将被连接。当最后一个观察者离开时，那么底层的 Observable 将被断开连接。
         */
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
