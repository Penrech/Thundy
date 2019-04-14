//
//  ButtonForToolbar.swift
//  Thundy
//
//  Created by Pau Enrech on 13/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

@IBDesignable class ButtonForToolbar: UIBarButtonItem {

    @IBInspectable var sizeOfImage: CGFloat = 36.0 {
        didSet{
            let image = self.image?.escalarImagen(nuevaAnchura: sizeOfImage)
            self.setBackgroundImage(image, for: .normal, barMetrics: .default)
        }
    }
    
    @IBInspectable var sizeOfButton: CGFloat = 36.0 {
        didSet{
            self.width = sizeOfButton
        }
    }
    
}
