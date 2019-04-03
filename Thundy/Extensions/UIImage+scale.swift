//
//  UIImage+scale.swift
//  Thundy
//
//  Created by Pau Enrech on 30/03/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit

extension UIImage {
    func escalarImagen(nuevaAnchura: CGFloat) -> UIImage {

        if self.size.width == nuevaAnchura {
            return self
        }
        
        let factorEscala = nuevaAnchura / self.size.width
        let nuevaAltura = self.size.height * factorEscala
        let nuevoTamañoImagen = CGSize(width: nuevaAnchura, height: nuevaAltura)
        
        UIGraphicsBeginImageContextWithOptions(nuevoTamañoImagen, false, 0.0)
        self.draw(in: CGRect(x: 0, y: 0, width: nuevaAnchura, height: nuevaAltura))
        
        let nuevaImagen: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return nuevaImagen ?? self
    }
}
