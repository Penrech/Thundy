//
//  UINavigationController+customTransition.swift
//  Thundy
//
//  Created by Pau Enrech on 19/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    
    static private var coordinatorHelperKey = "UINavigationController.TransitionCoordinatorHelper"
    
    var transitionCoordinatorHelper: TransitionCoordinator? {
        return objc_getAssociatedObject(self, &UINavigationController.coordinatorHelperKey) as? TransitionCoordinator
    }
    
    func addCustomTransitioning() {
    
        var object = objc_getAssociatedObject(self, &UINavigationController.coordinatorHelperKey)
        
        guard object == nil else {
            return
        }
        
        object = TransitionCoordinator()
        let nonatomic = objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
        objc_setAssociatedObject(self, &UINavigationController.coordinatorHelperKey, object, nonatomic)
        

        delegate = object as? TransitionCoordinator
        
        
 
        let edgeSwipeGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        edgeSwipeGestureRecognizer.edges = .left
        view.addGestureRecognizer(edgeSwipeGestureRecognizer)
    }
    

    @objc func handleSwipe(_ gestureRecognizer: UIScreenEdgePanGestureRecognizer) {
        guard let gestureRecognizerView = gestureRecognizer.view else {
            transitionCoordinatorHelper?.interactionController = nil
            return
        }
        
        let percent = gestureRecognizer.translation(in: gestureRecognizerView).x / gestureRecognizerView.bounds.size.width
        
        if gestureRecognizer.state == .began {
            transitionCoordinatorHelper?.interactionController = UIPercentDrivenInteractiveTransition()
            popViewController(animated: true)
        } else if gestureRecognizer.state == .changed {
            transitionCoordinatorHelper?.interactionController?.update(percent)
        } else if gestureRecognizer.state == .ended {
            if percent > 0.5 && gestureRecognizer.state != .cancelled {
                transitionCoordinatorHelper?.interactionController?.finish()
            } else {
                transitionCoordinatorHelper?.interactionController?.cancel()
            }
            transitionCoordinatorHelper?.interactionController = nil
        }
    }
}
