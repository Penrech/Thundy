//
//  UIImage+scale.swift
//  Thundy
//
//  Created by Pau Enrech on 30/03/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit
import Photos

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
    func getAssetImage(asset: PHAsset) -> UIImage{
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var image = UIImage()
        option.isSynchronous = true
        option.version = .original
        manager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, options: option) { (resultImage, info) in
            if resultImage != nil {
                image = resultImage!
            }
        }
        return image
    }
   
    func shareImage(asset: PHAsset) -> URL? {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var imageUrl: URL?
        option.isSynchronous = true
        option.deliveryMode = .highQualityFormat
        option.resizeMode = .none
        option.version = .original
      
        manager.requestImageData(for: asset, options: option) { (imageDataRaw, title, orientation, info) in
     
            if let data = imageDataRaw, let info = info {
                let path = FileManager.default.temporaryDirectory
                let assetUrl = info["PHImageFileURLKey"] as! URL
                let assetUrlArray = assetUrl.absoluteString.split(separator: "/")
                let assetName = String(assetUrlArray[assetUrlArray.count - 1])
                let saveImageUrl = path.appendingPathComponent(assetName)
                do {
                    try data.write(to: saveImageUrl)
                    imageUrl = saveImageUrl
                } catch {
                    print(error)
                }
            }
            
        }

        return imageUrl
    }
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}
