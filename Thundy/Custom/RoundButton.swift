//
//  RoundButton.swift
//  Thundy
//
//  Created by Pau Enrech on 30/03/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit

@IBDesignable
class RoundButton: UIButton {
    
    let defaultFont = UIFont(name: "Comfortaa-Bold", size: 17.0)
    let defaultFontString = "Comfortaa-Bold"
    
    let buttonSet = false
    var justInit = 0
    
    /*
    @IBInspectable var cornerRadius: Double = 0.0 {
        didSet {
            layer.cornerRadius = CGFloat(cornerRadius)
            layer.masksToBounds = true
        }
    }*/
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("Entro en subviews")

        if justInit < 2 {
            titleLabel?.font = titleLabel?.font.withSize(frame.height / 5)
            layer.cornerRadius = frame.height / 2
            layer.masksToBounds = true
            
            justInit += 1
        }
    }
    
}
