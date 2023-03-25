//
//  PushPopAnimationController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/3/25.
//

import UIKit

class SlideAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    let operation :UINavigationController.Operation
    init(operation: UINavigationController.Operation = .none) {
        self.operation = operation
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 2
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromView = transitionContext.view(forKey: .from)!
        let toView   = transitionContext.view(forKey: .to)!
        
        

        
        let containerView = transitionContext.containerView
        
        /// add toView
        containerView.addSubview(toView)
        
        let tanslation = containerView.frame.size.width
        
        
        var toTransform = CGAffineTransformIdentity
        var fromTransform = CGAffineTransformIdentity
        


        
        switch operation {
        case .push:
            toTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, tanslation * 0.4, 0)
            fromTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, -tanslation * 0.8, 0)
            
        case .pop:
            toTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, -tanslation * 0.8, 0)
            fromTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, tanslation * 0.4, 0)
        default:
            break
        }
        

        
        toView.transform = toTransform
        fromView.transform = CGAffineTransformIdentity
        
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext),
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: {
                            fromView.transform = fromTransform
                            toView.transform = CGAffineTransformIdentity
        } ,
                       completion: {
                            _ in
                            fromView.transform = CGAffineTransformIdentity
                            toView.transform = CGAffineTransformIdentity
                            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })

    }
}
