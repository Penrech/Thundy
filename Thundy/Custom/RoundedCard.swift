//
//  RoundedCard.swift
//  Thundy
//
//  Created by Pau Enrech on 08/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import UIKit

@IBDesignable
class RoundedCard: UIView {
    
    @IBInspectable var proportionCornerRadiusVariable: CGFloat = 5

    override func layoutSubviews() {
        super.layoutSubviews()
        
        var cornerRadiusVariable: CGFloat = 0
        if frame.height > frame.width {
            cornerRadiusVariable = frame.width / proportionCornerRadiusVariable
        } else{
            cornerRadiusVariable = frame.height / proportionCornerRadiusVariable
        }
        layer.cornerRadius = cornerRadiusVariable
        layer.masksToBounds = true
    }
}
