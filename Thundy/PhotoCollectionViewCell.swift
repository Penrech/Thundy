//
//  PhotoCollectionViewCell.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

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
    
    override func willTransition(from oldLayout: UICollectionViewLayout, to newLayout: UICollectionViewLayout) {
        print("transiciona a nuevo layout")
    }
    
    func setImage(asset: PHAsset){
        let cellHeight = self.frame.height
        let cellWidth = self.frame.width
        //self.libraryImage.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellHeight)
        self.libraryImage.fetchImage(asset: asset, contentMode: .aspectFill, targetSize: self.frame.size)
    }
    
    func setImageDetail(asset: PHAsset){
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        let deviceHeight = UIScreen.main.bounds.height
        let deviceWidth = UIScreen.main.bounds.width
        var newHeight: CGFloat = CGFloat(height)
        var newWidth: CGFloat = CGFloat(width)
        
        let proportion = CGFloat(height) / CGFloat(width)
        newWidth = deviceWidth
        newHeight = deviceWidth * proportion
        let positionY = (deviceHeight - newHeight) / 2
        self.libraryImage.frame = CGRect(x: 0, y: positionY, width: newWidth, height: newHeight)
        self.libraryImage.fetchImage(asset: asset, contentMode: .aspectFill)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        print("Class: \(self.hash) - layoutSubViews")
    }
}

extension PhotoCollectionViewCell {
    //MARK :- new Methods
}
