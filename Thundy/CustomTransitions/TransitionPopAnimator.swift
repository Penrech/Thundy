//
//  TransitionPopAnimator.swift
//  Thundy
//
//  Created by Pau Enrech on 25/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

class TransitionPopAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    

    enum PopTransitionMode: Int {
        case Present, Dismiss
    }
    
    var transitionMode: PopTransitionMode = .Present
    
    var circle: UIView?
    var circleColor: UIColor?
    var buttonRect: CGRect?
    
    var origin = CGPoint.zero
    
    var presentDuration = 0.3
    var dismissDuration = 0.2
    
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if transitionMode == .Present {
            return presentDuration
        } else {
            return dismissDuration
        }
    }
    
    func frameForCircle(center: CGPoint, size: CGSize, start: CGPoint) -> CGRect{
        
        let lengthX = fmax(start.x, size.width - start.x)
        let lengthY = fmax(start.y, size.height - start.y)
        let offset = sqrt(lengthX * lengthX + lengthY * lengthY) * 2
        let size = CGSize(width: offset, height: offset)
        
        return CGRect(origin: CGPoint.zero, size: size)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        
        if transitionMode == .Present {
            

            guard let presentedView = transitionContext.view(forKey: .to) else { return }
            guard let presentedViewController = transitionContext.viewController(forKey: .to) as? PhotoViewController else { return }
            let originalCenter = presentedView.center
            let originalSize = presentedView.frame.size
            let originalBackgroundColor = presentedView.backgroundColor
            
      
            circle = UIView(frame: frameForCircle(center: originalCenter, size: originalSize, start: origin))
            circle?.layer.cornerRadius = circle!.frame.size.height / 2
            circle?.clipsToBounds = true
            circle?.center = origin

            circle?.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            
            circle?.backgroundColor = circleColor
            
            containerView.addSubview(circle!)
            
            presentedView.center = origin
            presentedView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
            
            presentedView.backgroundColor = circleColor
            
            containerView.addSubview(presentedView)
           
            UIView.animate(withDuration: presentDuration, animations: {
                self.circle?.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                presentedView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                presentedView.center = originalCenter
                self.circle?.backgroundColor = originalBackgroundColor
                presentedView.backgroundColor = originalBackgroundColor
                if !presentedViewController.hideStatusBar {
                    presentedViewController.hideStatusBar = true
                    presentedViewController.setNeedsStatusBarAppearanceUpdate()
                }
                
            }) { (finished) in
                self.circle?.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
        } else {
            
            guard let toView = transitionContext.view(forKey: .to) else { return }
            
            guard let returningControllerView = transitionContext.view(forKey: .from) else { return }
   
            let originalCenter = returningControllerView.center
            let originalSize = returningControllerView.frame.size
            let originalColor = returningControllerView.backgroundColor
            
            circle = UIView(frame: frameForCircle(center: originalCenter, size: originalSize, start: origin))
            circle?.layer.cornerRadius = circle!.frame.size.height / 2
            circle?.clipsToBounds = true
            circle?.center = origin
       
            let xWidthPercentage = origin.x / toView.frame.width
            let yHeightPercentage = origin.y / toView.frame.height
            let newXPosition = returningControllerView.frame.width * xWidthPercentage
            let newYPosition = returningControllerView.frame.height * yHeightPercentage
            let newOrigin = CGPoint(x: newXPosition, y: newYPosition + checkIfCorrectionIsNeeded(toView: toView, fromView: returningControllerView))
  
            origin = newOrigin
            toView.frame = returningControllerView.frame
            
            circle?.frame = frameForCircle(center: originalCenter, size: toView.frame.size, start: origin)
            circle?.backgroundColor = originalColor
            circle?.layer.cornerRadius = circle!.frame.size.height / 2
            circle?.clipsToBounds = true
            circle?.center = origin
            
            containerView.addSubview(toView)
            containerView.addSubview(circle!)
            
            UIView.animate(withDuration: dismissDuration, animations: {
                self.circle?.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                self.circle?.backgroundColor = self.circleColor
                returningControllerView.backgroundColor = self.circleColor
                returningControllerView.transform = CGAffineTransform(scaleX: 0.001, y: 0.001)
                returningControllerView.center = self.origin
 
            }) { (finished) in
                returningControllerView.removeFromSuperview()
                self.circle?.removeFromSuperview()
                toView.removeFromSuperview()
                transitionContext.completeTransition(finished)
            }
            
        }
    }
    
    func checkIfCorrectionIsNeeded(toView: UIView, fromView: UIView) -> CGFloat {
        if toView.frame == fromView.frame { return 0 }
        if fromView.frame.height < fromView.frame.width { return 0 }
        
        let heightToBeAdded = buttonRect!.height / 2
        
        return heightToBeAdded
    }
    
}
