//
//  PhotoCollectionViewCell.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    

    @IBOutlet weak var libraryImage: UIImageView!
    
    @objc func prueba(_ : Any){
        print("JAJAS")
    }
    
    override var isSelected: Bool{
        didSet{
            if self.isSelected
            {
                self.libraryImage.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
                self.contentView.backgroundColor = UIColor.init(red: 102/255, green: 230/255, blue: 1, alpha: 1)
            }
            else
            {
                self.libraryImage.transform = CGAffineTransform.identity
                self.contentView.backgroundColor = .clear
            }
        }
    }
}
