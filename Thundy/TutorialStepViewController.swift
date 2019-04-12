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
    override func viewDidLoad() {
        super.viewDidLoad()
  
    }
    
    @IBAction func startCamera(_ sender: Any) {
       OperationQueue.main.addOperation {
            if let cameraViewController = self.storyboard?.instantiateViewController(withIdentifier: "photoViewController") {
                if let parentPager = self.parent as? UIPageViewController {
                    self.saveDataToUserDefaults()
                    self.present(cameraViewController, animated: true, completion: nil)
                    self.removeFromParent()
                    parentPager.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func saveDataToUserDefaults(){
        let preferences = UserDefaults.standard
        let key = (UIApplication.shared.delegate as! AppDelegate).isAppLoadBefore
        
        preferences.set(true, forKey: key)
    }
}
