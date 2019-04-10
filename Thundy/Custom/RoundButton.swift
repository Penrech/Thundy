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


    override func layoutSubviews() {
        super.layoutSubviews()

        titleLabel?.font = titleLabel?.font.withSize(frame.height / 5)
        layer.cornerRadius = frame.height / 2
        layer.masksToBounds = true
        
    }
    
}
