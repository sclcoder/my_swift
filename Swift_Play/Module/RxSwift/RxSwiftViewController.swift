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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "RxSwift"
        
//        testBtn()
//        testTF()
        
//        createObserableMethod()
        
        debugObserable()
    }
    
    
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
