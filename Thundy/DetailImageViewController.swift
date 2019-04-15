//
//  DetailImageViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import Photos

class DetailImageViewController: UIViewController, UIScrollViewDelegate {

    var asset = PHAsset()

    var positionY: CGFloat = 0
    var positionX: CGFloat = 0
    var closeViewControllerButton = UIBarButtonItem()
    
    var biggerThanProportion = false
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailImageView: UIImageView!
   
    @objc func closeDetail2(_ sender: Any){
        navigationController?.popViewController(animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.5
        scrollView.delegate = self
        scrollView.clipsToBounds = true
        
        self.extendedLayoutIncludesOpaqueBars = true
        //self.edgesForExtendedLayout = .bottom
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView))
        doubleTapRecognizer.numberOfTapsRequired = 2
        detailImageView.addGestureRecognizer(doubleTapRecognizer)
        
        setImageDetail(asset: asset)
       
    
    }
    
    func initBarsButtons(){
       closeViewControllerButton = UIBarButtonItem(image: UIImage(named: "close")?.escalarImagen(nuevaAnchura: 46), style: .plain, target: self, action: #selector(closeDetail2(_:)))
        navigationItem.leftBarButtonItem = closeViewControllerButton
    
    }
    
    func manageChangeOfOrientation(portrait: Bool){
        if portrait{
            
        } else {
            
        }
    }
    
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
      if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)

        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        print("ContentOffset: \(scrollView.contentOffset)")
        let deviceHeight = UIScreen.main.bounds.height
        let deviceWidth = UIScreen.main.bounds.width
        let actualFrame = detailImageView.frame
       
        let newHeight = actualFrame.height
        let newWidth = actualFrame.width
        let position = UIDevice.current.orientation.isLandscape ? (deviceWidth - newWidth) / 2 : (deviceHeight - newHeight) / 2
        let actualX = actualFrame.minX
        let actualY = actualFrame.minY
        let positionNormalized = max(position, 0)
        
        let newFrame = UIDevice.current.orientation.isLandscape ? CGRect(x: positionNormalized, y: actualY , width: actualFrame.width, height: actualFrame.height) : CGRect(x: actualX, y: positionNormalized , width: actualFrame.width, height: actualFrame.height)
        
        detailImageView.frame = newFrame
        print("Tamaño: X : \(detailImageView.frame.width) , Y: \(detailImageView.frame.height)")
        
 
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
        print("Pulsado en: \(zoomRect)")
        return zoomRect
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return detailImageView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //navigationController?.navigationBar.backgroundColor = .clear
        /*viewFullyLoaded = true
        UIView.animate(withDuration: 0.15) {
            self.setNeedsStatusBarAppearanceUpdate()
        }*/
        UIView.animate(withDuration: 0.3) {
            if let date = self.asset.creationDate {
                let dateFormater = DateFormatter()
                dateFormater.dateStyle = .medium
                self.navigationController?.navigationBar.topItem?.title = ""
                self.navigationItem.title = dateFormater.string(from: date)
            }
            
            self.initBarsButtons()
            self.navigationController?.navigationBar.backgroundColor = UIColor.defaultBlueTranslucent
            guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
                return
            }
            statusBarView.backgroundColor = UIColor.defaultBlueTranslucent
        }
        
        navigationController?.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        navigationController?.toolbar.isTranslucent = true
        navigationController?.toolbar.backgroundColor = UIColor.defaultBlueTranslucent
        
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setToolbarHidden(false, animated: true)
        navigationController?.hidesBarsOnSwipe = false
    
       
       /* if let date = asset.creationDate {
            let dateFormater = DateFormatter()
            dateFormater.dateStyle = .medium
            navigationController?.navigationBar.topItem?.title = ""
            navigationItem.title = dateFormater.string(from: date)
        }
        
        initBarsButtons()
        navigationController?.navigationBar.backgroundColor = UIColor.defaultBlueTranslucent
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = UIColor.defaultBlueTranslucent*/
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
       
        coordinator.animate(alongsideTransition: { (transitionContext) in
             self.setImageWhenRotate(landscape: UIDevice.current.orientation.isLandscape)
        }) { (completion) in
            
        }
        
    }
    
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override var prefersStatusBarHidden: Bool{
        return false
    }
    
    func setImageDetail(asset: PHAsset){
        
        let longSide = UIScreen.main.bounds.height
        let shortSide = UIScreen.main.bounds.width
        
        setSizeOfImage(screenLongSide: longSide, screenShortSide: shortSide)
    
        self.detailImageView.fetchImage(asset: asset, contentMode: .aspectFit)
     
    }
    
    func setSizeOfImage(screenLongSide: CGFloat, screenShortSide: CGFloat){
        let width:CGFloat = CGFloat(asset.pixelWidth)
        let height:CGFloat = CGFloat(asset.pixelHeight)
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
        
        self.detailImageView.frame = CGRect(x: positionX, y: positionY, width: newShortSide, height: newLongSide)
        
    }
  
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("ScrollView: \(scrollView.contentOffset)")
    }
    
    func setImageWhenRotate(landscape: Bool){
        let currentZoom = scrollView.zoomScale
        let currentOffset = scrollView.contentOffset
        let lastScreenWidth = UIScreen.main.bounds.height
        let lastScreenHeight = UIScreen.main.bounds.width
       
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        
        let lastWidth = detailImageView.bounds.width * currentZoom
        let lastHeight = detailImageView.bounds.height * currentZoom
        print("Last width = \(lastWidth)")
        print("Last Height = \(lastHeight)")
        
        setSizeOfImage(screenLongSide: UIScreen.main.bounds.height , screenShortSide: UIScreen.main.bounds.width)

        scrollView.setZoomScale(currentZoom, animated: false)

        scrollView.contentOffset = convertOffset(lastScreenWidth: lastScreenWidth, lastScreenHeight: lastScreenHeight, newScreenWidth: UIScreen.main.bounds.width, newScreenHeight: UIScreen.main.bounds.height, lastWidth: lastWidth, lastHeight: lastHeight, newWidth: detailImageView.bounds.width * currentZoom, newHeight: detailImageView.bounds.height * currentZoom, oldContentOffset: currentOffset)
       
    }
    
    func convertOffset(lastScreenWidth: CGFloat, lastScreenHeight: CGFloat, newScreenWidth: CGFloat, newScreenHeight: CGFloat, lastWidth: CGFloat, lastHeight: CGFloat, newWidth: CGFloat, newHeight: CGFloat, oldContentOffset: CGPoint) -> CGPoint{

        print("OldOffet.x \(oldContentOffset.x)")
        print("OldOffset.y \(oldContentOffset.y)")
        if oldContentOffset.x <= 0.0 && oldContentOffset.y <= 0.0 {
            return oldContentOffset
        }
        
        var newPositionX = oldContentOffset.x + lastScreenWidth / 2
        var newPositionY = oldContentOffset.y + lastScreenHeight / 2
        
        let maxWidthContent = max(lastWidth - lastScreenWidth, lastScreenWidth)
        let xPercentage = (oldContentOffset.x * 100) / maxWidthContent
        let newMaxWidthContent = newWidth - newScreenWidth
        
        newPositionX = (newMaxWidthContent * xPercentage) / 100
    
        let maxHeightContent = max(lastHeight - lastScreenHeight, lastScreenWidth)
        let yPercentage = (oldContentOffset.y * 100) / maxHeightContent
        let newMaxHeightContent = newHeight - newScreenHeight
        
        newPositionY = (newMaxHeightContent * yPercentage) / 100
        
        let minOffsetX = max(newMaxWidthContent / 2, 0)
        let minOffsetY = max(newMaxHeightContent / 2, 0)
    
        //return CGPoint(x: max(min(newPositionX, newWidth - newScreenWidth) , minOffsetX), y: max(min( newPositionY, newHeight - newScreenHeight), minOffsetY))
        //return CGPoint(x: max(newPositionX, minOffsetX), y: max(newPositionY, minOffsetY))
        return CGPoint(x: newPositionX, y: newPositionY)
    }


}
