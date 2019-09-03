//
//  TransitionCoordinator.swift
//  Thundy
//
//  Created by Pau Enrech on 19/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

final class TransitionCoordinator: NSObject, UINavigationControllerDelegate {

    var interactionController: UIPercentDrivenInteractiveTransition?
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return TransitionAnimator(presenting: true)
        case .pop:
            return TransitionAnimator(presenting: false)
        default:
            return nil
        }
    }

    func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactionController
    }
}
