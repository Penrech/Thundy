//
//  ExpandAnimator.swift
//  Thundy
//
//  Created by Pau Enrech on 18/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit

class ExpandAnimator: NSObject {
    
    static var animator = ExpandAnimator()
    
    enum ExpandTransitionMode: Int {
        case Present, Dismiss
    }
    
    let presentDuration = 0.4
    let dismissDuration = 0.15
    
    var openingFrame: CGRect?
    var transitionMode: ExpandTransitionMode = .Present
    
    var topView: UIView!
    var bottomView: UIView!
    
    func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> TimeInterval {
        if transitionMode == .Present {
            return presentDuration
        } else {
            return dismissDuration
        }
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        //From view controller
        let fromViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let fromViewFrame = fromViewController.view.frame
        
        //To view controller
        let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        // Container view
        let containerView = transitionContext.containerView
        
        if transitionMode == .Present{
            
            //Get top view using resizableSnapshotViewFromRect
            topView = fromViewController.view.resizableSnapshotView(from: fromViewFrame, afterScreenUpdates: true, withCapInsets: UIEdgeInsets(top: openingFrame!.origin.y, left: 0, bottom: 0, right: 0))
            topView.frame = CGRect(x: 0, y: 0, width: fromViewFrame.width, height: openingFrame!.origin.y)
            
            // Add top view to controller
            containerView.addSubview(topView)
            
            // Get Bottom view using resizableSnapshotViewFromRect
            bottomView = fromViewController.view.resizableSnapshotView(from: fromViewFrame, afterScreenUpdates: true, withCapInsets: UIEdgeInsets(top: 0, left: 0, bottom: fromViewFrame.height - openingFrame!.origin.y - openingFrame!.height, right: 0))
            bottomView.frame = CGRect(x: 0, y: openingFrame!.origin.y + openingFrame!.height, width: fromViewFrame.width, height: fromViewFrame.height - openingFrame!.origin.y - openingFrame!.height)
            
            //Add bottom view to container
            containerView.addSubview(bottomView)
            
            //Take a snapshot of the view controller and change its frame to opening frame
            let snapshopView = toViewController.view.resizableSnapshotView(from: fromViewFrame, afterScreenUpdates: true, withCapInsets: .zero)
            snapshopView?.frame = openingFrame!
            containerView.addSubview(snapshopView!)
            
            toViewController.view.alpha = 0.0
            containerView.addSubview(toViewController.view)
            
            UIView.animate(withDuration: presentDuration, animations: {
                //Move top and bottom views out of the screen
                self.topView.frame = CGRect(x: 0, y: -self.topView.frame.height, width: self.topView.frame.width, height: self.topView.frame.height)
                self.bottomView.frame = CGRect(x: 0, y: fromViewFrame.height, width: self.bottomView.frame.width, height: self.bottomView.frame.height)
                
                //Expand snapshot view to fill entire frame
                snapshopView?.frame = toViewController.view.frame
                
            }) { (finished) in
                
                // Remove snapshot view from container view
                snapshopView?.removeFromSuperview()
                
                //Make to view controller visible
                toViewController.view.alpha = 1.0
                
                //Complete transition
                transitionContext.completeTransition(finished)
            }
        
            
        } else {
            
            let snapshotView = fromViewController.view.resizableSnapshotView(from: fromViewController.view.bounds, afterScreenUpdates: true, withCapInsets: .zero)
            containerView.addSubview(snapshotView!)
            
            fromViewController.view.alpha = 0.0
            
            UIView.animate(withDuration: dismissDuration, delay: 0, options: .curveEaseIn, animations: {
                self.topView.frame = CGRect(x: 0, y: 0, width: self.topView.frame.width, height: self.topView.frame.height)
                self.bottomView.frame = CGRect(x: 0, y: fromViewController.view.frame.height - self.bottomView.frame.height, width: self.bottomView.frame.width, height: self.bottomView.frame.height)
                snapshotView?.frame = self.openingFrame!
            }) { (finished) in
                snapshotView?.removeFromSuperview()
                
                fromViewController.view.alpha = 1.0
                
                transitionContext.completeTransition(finished)
                
            }
            
        }
    }

}
