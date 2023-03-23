//
//  SwipeInteractionController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/3/23.
//

import UIKit

class SwipeInteractionController: UIPercentDrivenInteractiveTransition {
    
    var interactionInProgress = false
    
    private var shouldCompleteTransition = false
    
    private weak var viewController : UIViewController!
    
    init(viewController: UIViewController) {
        super.init()
        self.viewController = viewController
        self.prepareGestureRecognizer(in: viewController.view)
    }

    
    private func prepareGestureRecognizer(in view: UIView){
        let gesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleGesture(_:)))
        gesture.edges = .left
        view.addGestureRecognizer(gesture)
        
    }
    
    @objc func handleGesture(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer){
     
        let translation = gestureRecognizer.translation(in: gestureRecognizer.view!.superview!)
        
        var progress    = translation.x / 200
        progress = CGFloat(fminf(fmax(Float(progress), 0.0), 1.0))
        print(progress)
        switch gestureRecognizer.state {
            
        case .began:
            interactionInProgress = true
            /// 这句代码有问题: 一上来就dismiss, 如果进度还不足以完成，那么cancel后，viewController被dismiss了，这是错误了
            viewController.dismiss(animated: true, completion: nil)
        case .changed:
            shouldCompleteTransition = progress > 0.5
            update(progress)
            
        case .cancelled:
            interactionInProgress = false
            cancel()
          
        case .ended:
            interactionInProgress = false
            if shouldCompleteTransition{
                finish()
            } else {
                cancel()
            }
        default:
            break
        }
    }
}
