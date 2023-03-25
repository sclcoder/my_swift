//
//  PushPopAnimationController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/3/25.
//

import UIKit

class FlipAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    let operation :UINavigationController.Operation
    init(operation: UINavigationController.Operation = .none) {
        self.operation = operation
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromView = transitionContext.view(forKey: .from)!
        let toView   = transitionContext.view(forKey: .to)!
        
        

        
        let containerView = transitionContext.containerView
        
 
        
        let tanslation = containerView.frame.size.width
        
        
        var toTransform = CGAffineTransformIdentity
        var fromTransform = CGAffineTransformIdentity
        


        
        switch operation {
        case .push:
            toTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, tanslation, 0)
            fromTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, -tanslation * 0.5, 0)
            /// add toView
            containerView.insertSubview(toView, aboveSubview: fromView)
        case .pop:
            toTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, -tanslation * 0.5, 0)
            fromTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, tanslation, 0)
            /// add toView
            containerView.insertSubview(toView, belowSubview: fromView)
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
