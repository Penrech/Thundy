//
//  TutorialStepViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 10/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

//Esta clase está asociada al último view controller que se muestra y se encarga de gestionar el botón que envia al usuario a la vista de la cámara
class TutorialStepViewController: UIViewController {
    
     let toCameraTransition = TransitionPopAnimator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
  
    }
    
   
    @IBOutlet weak var downView: UIView!
    @IBOutlet weak var buttonStart: RoundButton!
    @IBAction func startCamera(_ sender: Any) {
       OperationQueue.main.addOperation {
        
            if let parentPager = self.parent as? UIPageViewController {
                self.saveDataToUserDefaults()
                self.performSegue(withIdentifier: "showCamera", sender: nil)
                self.removeFromParent()
                parentPager.navigationController?.popViewController(animated: true)
            }
            
        }
    }
    
    func saveDataToUserDefaults(){
        let preferences = UserDefaults.standard
        let key = (UIApplication.shared.delegate as! AppDelegate).isAppLoadBefore
        
        preferences.set(true, forKey: key)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCamera"{
            let controller = segue.destination as! PhotoViewController
            controller.transitioningDelegate = self
            if UIDevice.current.orientation.isLandscape {
                controller.hideStatusBar = true
            }
        }
    }
}
extension TutorialStepViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        toCameraTransition.transitionMode = .Present
        toCameraTransition.circleColor = self.buttonStart.backgroundColor
        let circleButtonRect = downView.convert(self.buttonStart.frame, to: downView.superview?.superview)
        
        toCameraTransition.origin = CGPoint(x: circleButtonRect.midX, y: circleButtonRect.midY)
        toCameraTransition.buttonRect = circleButtonRect
        
        return toCameraTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        toCameraTransition.transitionMode = .Dismiss
        let circleButtonRect = downView.convert(self.buttonStart.frame, to: downView.superview?.superview)
        toCameraTransition.origin = CGPoint(x: circleButtonRect.midX, y: circleButtonRect.midY)
        toCameraTransition.buttonRect = circleButtonRect
        toCameraTransition.circleColor = self.buttonStart.backgroundColor
        
        return toCameraTransition
    }
}
