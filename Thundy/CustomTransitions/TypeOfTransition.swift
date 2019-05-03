//
//  TypeOfTransition.swift
//  Thundy
//
//  Created by Pau Enrech on 19/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit
import Photos

class TypeOfTransition {
    
    static var shared = TypeOfTransition()
    
    var currentTransition: Types = .DefaultSlide
    
    private(set) var currentCellIndexPath: IndexPath?
    private(set) var curretnCellFrame: CGRect?
    private(set) var currentAsset: PHAsset?
    
    enum Types: Int {
        case DefaultSlide, UpDownSlide, ImageSlide
    }
    
    func setCellForAnimation(cellFrame: CGRect, indexPath: IndexPath, cellAsset: PHAsset){
        self.curretnCellFrame = cellFrame
        self.currentCellIndexPath = indexPath
        self.currentAsset = cellAsset
    }
}
