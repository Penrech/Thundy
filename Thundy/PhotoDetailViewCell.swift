//
//  PhotoDetailViewCell.swift
//  Thundy
//
//  Created by Pau Enrech on 16/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

//Este protocolo sirve para notificar a la vista padre de la celdad que se ha hecho zoom en ella
protocol cellZoomDelegate: class {
    func cellDidZoom(toDefaultZoom: Bool)
}

//Esta clase es la de las celdas en vista detalle
class PhotoDetailViewCell: UICollectionViewCell {
    
    //MARK: - outlets
    
    @IBOutlet weak var detailImageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    //MARK: - variables
    
    var delegate : cellZoomDelegate?
    
    var positionY: CGFloat = 0
    var positionX: CGFloat = 0
    var initialWidth: CGFloat = 0
    var initialHeight: CGFloat = 0
    
    var asset: PHAsset?

    //Esta función gestiona el doble tap en una celda, amplia la celda al máximo si esta en el zoom inicial, o la devuelve
    // Al zoom inicial si está con un zoom distinto al estado inicial
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
            
        }
    }
    
    //
    func recieveDataFromDoubleTap(recognizer: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: detailImageView)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
            
        }
    }
    
    func setImageDetail(asset: PHAsset){
        setUPScrollView()
        restoreVariables()
        print("Self asset: \(self.asset)")
        self.asset = asset

        let longSide = UIScreen.main.bounds.height
        let shortSide = UIScreen.main.bounds.width
        
        setSizeOfImage(screenLongSide: longSide, screenShortSide: shortSide)
        
        self.detailImageView.fetchImage(asset: asset, contentMode: .aspectFit)
        
        self.detailImageView.target(forAction: #selector(clickEnImagen), withSender: self)
        
    }
    
    @objc func clickEnImagen(){
        print("Imagen clickada")
    }
    
    func setUPScrollView(){
        scrollView.isScrollEnabled = true
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.5
        scrollView.delegate = self
        scrollView.clipsToBounds = true
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView))
        doubleTapRecognizer.numberOfTapsRequired = 2
        detailImageView.addGestureRecognizer(doubleTapRecognizer)
    }
    
    func restoreVariables(){
        initialWidth = 0
        initialHeight = 0
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }
    
    func restoreZoom(){
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.zoomScale = scrollView.minimumZoomScale
        }
    }
    
    func setSizeOfImage(screenLongSide: CGFloat, screenShortSide: CGFloat){
        let width:CGFloat = CGFloat(asset!.pixelWidth)
        let height:CGFloat = CGFloat(asset!.pixelHeight)
        positionX = 0
        positionY = 0
        
        var proportion = height / width
        var newShortSide = screenShortSide
        var newLongSide = screenShortSide * proportion
        
        if newLongSide > screenLongSide {
            proportion = pow(proportion, -1)
            newLongSide = screenLongSide
            newShortSide = screenLongSide * proportion
            positionX = ( screenShortSide - newShortSide) / 2
        } else {
            positionY = (screenLongSide - newLongSide) / 2
        }
        
        initialWidth = newShortSide
        initialHeight = newLongSide
        
        print("PositionX : \(positionX)")
        print("PositionY: \(positionY)")
        self.detailImageView.frame = CGRect(x: positionX, y: positionY, width: newShortSide, height: newLongSide)
        
    }
    
    
}
extension PhotoDetailViewCell: UIScrollViewDelegate {
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
       
        if scrollView.zoomScale < scrollView.minimumZoomScale {
            return
        }
        
        if scrollView.zoomScale == scrollView.minimumZoomScale{
            delegate?.cellDidZoom(toDefaultZoom: true)
        } else {
            delegate?.cellDidZoom(toDefaultZoom: false)
        }
        
        let deviceHeight = UIScreen.main.bounds.height
        let deviceWidth = UIScreen.main.bounds.width
        let actualFrame = detailImageView.frame
        
        let newHeight = actualFrame.height
        let newWidth = actualFrame.width
        var position: CGFloat = 0
        var positionNormalized = max(position , 0)
        
        let actualX = actualFrame.minX
        let actualY = actualFrame.minY
        
        var newFrame = CGRect.zero
        
        
        if UIDevice.current.orientation.isLandscape {
            if initialWidth == deviceWidth {
                positionY = (deviceHeight - newHeight) / 2
                position = positionY
                positionNormalized = max(position , 0)
                
                newFrame = CGRect(x: actualX, y: positionNormalized , width: actualFrame.width, height: actualFrame.height)
                
            } else {
                positionX = (deviceWidth - newWidth) / 2
                position = positionX
                positionNormalized = max(position , 0)
                
                newFrame = CGRect(x: positionNormalized, y: actualY , width: actualFrame.width, height: actualFrame.height)
            }
            
        } else {
            if initialHeight == deviceHeight {
                positionX = (deviceWidth - newWidth) / 2
                position = positionX
                positionNormalized = max(position , 0)
                
                newFrame = CGRect(x: positionNormalized, y: actualY , width: actualFrame.width, height: actualFrame.height)
                
            } else {
                positionY = (deviceHeight - newHeight) / 2
                position = positionY
                positionNormalized = max(position , 0)
                
                newFrame = CGRect(x: actualX, y: positionNormalized , width: actualFrame.width, height: actualFrame.height)
            }
        }
        
        detailImageView.frame = newFrame
        
    }
    
    func newYPosition() -> CGFloat {
        let deviceHeight = UIScreen.main.bounds.height
        let actualFrame = detailImageView.frame
        let newHeight = actualFrame.height
        let position = (deviceHeight - newHeight) / 2
        
        let positionNormalized = max(position, 0)
        
        return positionNormalized
    }
    
    func newXPosition() -> CGFloat {
        let deviceWidth = UIScreen.main.bounds.width
        let actualFrame = detailImageView.frame
        let newWidth = actualFrame.width
        let position = (deviceWidth - newWidth) / 2
        
        let positionNormalized = max(position, 0)
        
        return positionNormalized
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = detailImageView.frame.size.height / scale
        zoomRect.size.width  = detailImageView.frame.size.width  / scale
        let newCenter = scrollView.convert(center, from: detailImageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0) - newXPosition()
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0) - newYPosition()
        
        return zoomRect
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return detailImageView
    }
    
    func setImageWhenRotate(){
        let currentZoom = scrollView.zoomScale
        let currentOffset = scrollView.contentOffset
        let lastScreenWidth = UIScreen.main.bounds.height
        let lastScreenHeight = UIScreen.main.bounds.width
        
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        
        let lastWidth = detailImageView.bounds.width * currentZoom
        let lastHeight = detailImageView.bounds.height * currentZoom
        
        setSizeOfImage(screenLongSide: UIScreen.main.bounds.height , screenShortSide: UIScreen.main.bounds.width)
        
        scrollView.setZoomScale(currentZoom, animated: false)
        
        scrollView.contentOffset = convertOffset(lastScreenWidth: lastScreenWidth, lastScreenHeight: lastScreenHeight, newScreenWidth: UIScreen.main.bounds.width, newScreenHeight: UIScreen.main.bounds.height, lastWidth: lastWidth, lastHeight: lastHeight, newWidth: detailImageView.bounds.width * currentZoom, newHeight: detailImageView.bounds.height * currentZoom, oldContentOffset: currentOffset)
        
    }
    
    func convertOffset(lastScreenWidth: CGFloat, lastScreenHeight: CGFloat, newScreenWidth: CGFloat, newScreenHeight: CGFloat, lastWidth: CGFloat, lastHeight: CGFloat, newWidth: CGFloat, newHeight: CGFloat, oldContentOffset: CGPoint) -> CGPoint{
        
        var posisicionX = oldContentOffset.x
        var posicionY = oldContentOffset.y
        
        switch oldContentOffset.x {
        case oldContentOffset.x where oldContentOffset.x <= 0:
            posisicionX = 0
        case oldContentOffset.x where oldContentOffset.x + lastScreenWidth >= lastWidth :
            posisicionX = newWidth - newScreenWidth
        case oldContentOffset.x where oldContentOffset.x + lastScreenHeight >= lastWidth:
            posisicionX = newWidth - newScreenWidth
        default:
            let centerOfViewX = oldContentOffset.x + lastScreenWidth / 2
            let proportionX = centerOfViewX / lastWidth
            posisicionX = newWidth * proportionX - (newScreenWidth / 2)
        }
        
        switch oldContentOffset.y {
        case oldContentOffset.y where oldContentOffset.y <= 0:
            posicionY = 0
        case oldContentOffset.y where oldContentOffset.y + lastScreenHeight >= lastHeight:
            posicionY = newHeight - newScreenHeight
        case oldContentOffset.y where oldContentOffset.y + lastScreenWidth >= lastHeight:
            posicionY = newHeight - newScreenHeight
        default:
            let centerOfViewY = oldContentOffset.y + lastScreenHeight / 2
            let proportionY = centerOfViewY / lastHeight
            posicionY = newHeight * proportionY - (newScreenHeight / 2)
        }
        
        return CGPoint(x: min(max(posisicionX , 0) , max(newWidth - newScreenWidth, 0) ), y: min(max(posicionY , 0), max(newHeight - newScreenHeight , 0)))
    }

    
}
