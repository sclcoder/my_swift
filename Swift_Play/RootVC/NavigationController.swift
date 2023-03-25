//
//  NavigationController.swift
//  my_swift
//
//  Created by sunchunlei on 2023/2/16.
//

import UIKit

class NavigationController: UINavigationController {

    var inInteraction = false
    var swipeGesture: UIPanGestureRecognizer!
    let interactionController: UIPercentDrivenInteractiveTransition = UIPercentDrivenInteractiveTransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupAppearance()
        
        self.delegate = self
        
        swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(onPan(gesture:)))
//        swipeGesture.edges = .left
        
        self.view.addGestureRecognizer(swipeGesture)
    }

    
    private func setupAppearance() -> Void {
        let appearance: UINavigationBarAppearance = UINavigationBarAppearance()
        
        appearance.backgroundColor = .yellow
        
        appearance.titleTextAttributes = [
            NSAttributedString.Key.font : UIFont.systemFont(ofSize: 20),
            NSAttributedString.Key.foregroundColor : UIColor.white
        ]
        
        self.navigationBar.standardAppearance = appearance
        
        self.navigationBar.isTranslucent = true
        
        self.navigationBar.backgroundColor = .systemYellow

    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if(self.children.count != 0){
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}


extension NavigationController: UINavigationControllerDelegate{
    
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor
                              operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        return FlipAnimationController(operation: operation)
    }
    
    
    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if(inInteraction){
            return interactionController
        } else {
            return nil
        }
    }
}

extension NavigationController{
    @objc func onPan(gesture:UIScreenEdgePanGestureRecognizer) -> Void{
        
        let targetView = gesture.view!
        
        let translation:CGPoint = gesture.translation(in: targetView)
        
        var progress = translation.x / targetView.bounds.size.width
        
        progress = fmin(fmax(progress, 0.0), 1.0)
        
        switch gesture.state {
        case .began:
            inInteraction = true
            self.popViewController(animated: true)
        case .changed:
//            inInteraction = true
            interactionController.update(progress)
        case .cancelled:
            inInteraction = false
            interactionController.cancel()
            
        case .ended:
            inInteraction = false
            if (progress > 0.4){
                interactionController.finish()
            } else {
                interactionController.cancel()
            }
        default:
            break
        }
    }
}
