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
    @IBOutlet weak var selectedTint: UIView!
    @IBOutlet weak var checkSelectedIndicator: UIImageView!
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
}
