//
//  UIButton+Animation.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit

extension UIButton{
    
    func clickAnimation(){
        if self.transform.isIdentity {
            UIView.animate(withDuration: 0.15, delay: 0.0, options: [.autoreverse], animations: {
                self.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            }) { (completado) in
                self.transform = .identity
            }
        }
    }
    
    func adjustButton(){
        titleLabel?.font = titleLabel?.font.withSize(frame.height / 5)
        layer.cornerRadius = frame.height / 2
        layer.masksToBounds = true
    }
}
