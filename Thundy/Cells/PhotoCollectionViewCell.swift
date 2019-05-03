//
//  PhotoCollectionViewCell.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

//Esta clase es la de las celdas de la libreria
class PhotoCollectionViewCell: UICollectionViewCell {
    
    //MARK: - outlets
    @IBOutlet weak var libraryImage: UIImageView!
    @IBOutlet weak var selectedTint: UIView!
    @IBOutlet weak var checkSelectedIndicator: UIImageView!
    
    // Esta variable permite cambiar la apariencia de una celda cuando está seleccionada
    override var isSelected: Bool{
        didSet{
            if self.isSelected
            {
                self.selectedTint.isHidden = false
                self.checkSelectedIndicator.isHidden = false
            }
            else
            {
                self.selectedTint.isHidden = true
                self.checkSelectedIndicator.isHidden = true
            }
        }
    }
    
    //Con esta función se inicializa la imagen de la celda
    func setImage(asset: PHAsset){
        self.libraryImage.fetchImage(asset: asset, contentMode: .aspectFill, targetSize: self.frame.size)
    }

}

