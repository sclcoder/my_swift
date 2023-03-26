//
//  PushPopAnimationController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/3/25.
//

import UIKit

class FlipAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
    
    let operation :UINavigationController.Operation
    var tabBar: UITabBar?
    
    init(operation: UINavigationController.Operation = .none) {
        self.operation = operation
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.6
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromView = transitionContext.view(forKey: .from)!
        let toView   = transitionContext.view(forKey: .to)!
        
        let toVC:UIViewController = transitionContext.viewController(forKey: .to)!
        let fromVC:UIViewController = transitionContext.viewController(forKey: .from)!

        let containerView = transitionContext.containerView
        
        
        let tanslation = containerView.frame.size.width
        
        
        var toTransform = CGAffineTransformIdentity
        var fromTransform = CGAffineTransformIdentity
        
        
        tabBar = fromVC.tabBarController?.tabBar
        

//        tabBar!.layer.zPosition = -1

        
//        /// 问题: Tabbar 转场的问题 没解决
//        // Now handle the TabBar.
//         if
//             toVC.hidesBottomBarWhenPushed,
//             !fromVC.hidesBottomBarWhenPushed,
//             let tabBar = fromVC.tabBarController?.tabBar
//         {
//             // TabBar is going away.
//
//             UIView.animate(withDuration: 0.25, animations: {
//                 // Counteract default animation by animating x in opposite direction.
//                 tabBar.center.x += tabBar.bounds.width
//
//                 // Animate TabBar down.
//                 tabBar.center.y += tabBar.bounds.height
//
//                 // Or alternatively animate opacity.
//                 // tabBar.alpha = 0
//             })
//         }
//         else if
//             !toVC.hidesBottomBarWhenPushed,
//             fromVC.hidesBottomBarWhenPushed,
//             let tabBar = toVC.tabBarController?.tabBar
//         {
//             // TabBar is coming back.
//
//             // TabBar by default will be animated toward default position.
//             // Make sure it's already there on x so default animation does nothing for x.
//             tabBar.center.x = tabBar.bounds.width / 2
//
//             // Move y down, so default animation will move TabBar up to default position.
//             tabBar.center.y += tabBar.bounds.height
//
//             // Or alternatively animate opacity.
//             // tabBar.alpha = 0
//             // animator.addAnimations {
//             //    tabBar.alpha = 1
//             //}
//         }
        

        
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
