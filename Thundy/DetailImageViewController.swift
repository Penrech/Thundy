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
        //navigationController?.navigationBar.backgroundColor = .clear
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
        print("hola")
        super.viewWillTransition(to: size, with: coordinator)
        /*if UIDevice.current.orientation.isLandscape {
           
        } else {
           
        }*/
        coordinator.animate(alongsideTransition: { (transitionContext) in
             self.setImageWhenRotate(landscape: UIDevice.current.orientation.isLandscape)
        }) { (completion) in
            
        }
        /*coordinator.animate(alongsideTransition: nil, completion: {
            _ in
            
            // Your code here
            //self.setImageWhenRotate(landscape: UIDevice.current.orientation.isLandscape)
        })*/
        print("Landscape: \(UIDevice.current.orientation.isLandscape)")
       
    }
    
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override var prefersStatusBarHidden: Bool{
        return false
    }
    
    func setImageDetail(asset: PHAsset){
        /*let width = asset.pixelWidth
        let height = asset.pixelHeight
        let deviceHeight = UIScreen.main.bounds.height
        let deviceWidth = UIScreen.main.bounds.width
       
        
        
        var newHeight: CGFloat = CGFloat(height)
        var newWidth: CGFloat = CGFloat(width)
        
        var proportion = CGFloat(height) / CGFloat(width)
        newWidth = deviceWidth
        newHeight = deviceWidth * proportion
        
        if newHeight >= deviceHeight {
            proportion = CGFloat(width) / CGFloat(height)
            newHeight = deviceHeight
            newWidth = deviceHeight * proportion
            positionX = (deviceWidth - newWidth) / 2
            biggerThanProportion = true
        } else {
            positionY = (deviceHeight - newHeight) / 2
        }
        
        self.detailImageView.frame = CGRect(x: positionX, y: positionY, width: newWidth, height: newHeight)
        print("positionX: \(positionX)")
        print("positionY: \(positionY)")
        */
        let longSide = UIScreen.main.bounds.height
        let shortSide = UIScreen.main.bounds.width
        
        setSizeOfImage(screenLongSide: longSide, screenShortSide: shortSide)
       
        //self.detailImageView.frame = CGRect(x: 0, y: positionY, width: newWidth, height: newHeight)
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
        print("ContentOffset: \(scrollView.contentOffset)")
    }
    
    func setImageWhenRotate(landscape: Bool){
        let currentZoom = scrollView.zoomScale
        let currentOffset = scrollView.contentOffset
        let lastScreenWidth = UIScreen.main.bounds.height
        let lastScreenHeight = UIScreen.main.bounds.width
        print("ContentOffser antes de girar: \(currentOffset)")
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        
        /*let width = asset.pixelWidth
        let height = asset.pixelHeight
        let deviceHeight = UIScreen.main.bounds.width
        let deviceWidth = UIScreen.main.bounds.height
        var newHeight: CGFloat = CGFloat(height)
        var newWidth: CGFloat = CGFloat(width)
        
        var proportion = CGFloat(height) / CGFloat(width)
        newWidth = deviceWidth
        newHeight = deviceWidth * proportion
        
        if newHeight >= deviceHeight {
            proportion = CGFloat(width) / CGFloat(height)
            newHeight = deviceHeight
            newWidth = deviceHeight * proportion
            positionX = (deviceWidth - newWidth) / 2
            biggerThanProportion = true
        } else {
            positionY = (deviceHeight - newHeight) / 2
        }
        
        self.detailImageView.frame = CGRect(x: positionX, y: positionY, width: newWidth, height: newHeight)*/
        
        let longSide = UIDevice.current.orientation.isPortrait ? UIScreen.main.bounds.width : UIScreen.main.bounds.height
        let shortSide = UIDevice.current.orientation.isPortrait ? UIScreen.main.bounds.height : UIScreen.main.bounds.width
        
        let lastWidth = detailImageView.bounds.width * currentZoom
        let lastHeight = detailImageView.bounds.height * currentZoom
        print("Last width = \(lastWidth)")
        print("Last Height = \(lastHeight)")
        
        setSizeOfImage(screenLongSide: UIScreen.main.bounds.height , screenShortSide: UIScreen.main.bounds.width)
        
        print("New width: \(detailImageView.bounds.width * currentZoom)")
        print("New Height: \(detailImageView.bounds.height * currentZoom)")
        /*let newCenter = convertCenter(lastWidth: lastWidth, lastHeight: lastHeight, newWidth: detailImageView.frame.width, newHeight: detailImageView.frame.height, center: currentCenter)
        print("LastCenter: \(currentCenter)")
        print("NewCenter: \(newCenter)")
        scrollView.zoom(to: zoomRectForScale(scale: currentZoom, center: newCenter ), animated: false)*/
        scrollView.setZoomScale(currentZoom, animated: false)
        print("ContentOffset despues de girar: \(scrollView.contentOffset)")
        scrollView.contentOffset = convertOffset(lastScreenWidth: lastScreenWidth, lastScreenHeight: lastScreenHeight, newScreenWidth: UIScreen.main.bounds.width, newScreenHeight: UIScreen.main.bounds.height, lastWidth: lastWidth, lastHeight: lastHeight, newWidth: detailImageView.bounds.width * currentZoom, newHeight: detailImageView.bounds.height * currentZoom, oldContentOffset: currentOffset)
        print("ContentOffset despues de corregirlo: \(scrollView.contentOffset)")
        //scrollView.contentOffset = convertOffset(lastWidth: lastWidth, lastHeight: lastHeight, newWidth: detailImageView.frame.height, newHeight: detailImageView.frame.width, center: currentOffset)
      
        /*let newWidth = UIScreen.main.bounds.height
        let newHeight = UIScreen.main.bounds.width
        let currentZoom = scrollView.zoomScale
        scrollView.setZoomScale(scrollView.minimumZoomScale, animated: false)
        let newFrame = CGRect(x: detailImageView.frame.minY, y: detailImageView.frame.minX, width: detailImageView.frame.height, height: detailImageView.frame.width)
        detailImageView.frame = newFrame
        scrollView.setZoomScale(currentZoom, animated: false)
        /*var deviceHeight = UIScreen.main.bounds.height
        var deviceWidth = UIScreen.main.bounds.width
        if landscape{
        var deviceWidth = UIScreen.main.bounds.height
        var deviceHeight = UIScreen.main.bounds.width
        }
        print("Width: \(deviceWidth)")
        print("Height: \(deviceHeight)")
        let width = asset.pixelWidth
        let height = asset.pixelHeight
        var newHeight: CGFloat = CGFloat(height)
        var newWidth: CGFloat = CGFloat(width)
        
        var proportion = CGFloat(height) / CGFloat(width)
        newWidth = deviceWidth
        newHeight = deviceWidth * proportion
        positionY = (deviceHeight - newHeight) / 2
        
        if newHeight >= deviceHeight {
            proportion = CGFloat(width) / CGFloat(height)
            newHeight = deviceHeight
            newWidth = deviceHeight * proportion
            positionY = (deviceWidth - newWidth) / 2
            self.detailImageView.frame = CGRect(x: positionY, y: 0, width: newWidth, height: newHeight)
            biggerThanProportion = true
        } else {
            self.detailImageView.frame = CGRect(x: 0, y: positionY, width: newWidth, height: newHeight)
        }
        
        //self.detailImageView.layer.anchorPoint = self.view.layer.anchorPoint*/
        */
    }
    
    func convertOffset(lastScreenWidth: CGFloat, lastScreenHeight: CGFloat, newScreenWidth: CGFloat, newScreenHeight: CGFloat, lastWidth: CGFloat, lastHeight: CGFloat, newWidth: CGFloat, newHeight: CGFloat, oldContentOffset: CGPoint) -> CGPoint{

        let offsetX = oldContentOffset.x * (newHeight / lastWidth)
        let offsetY = oldContentOffset.y * (newWidth / lastHeight)
        //let newXContentOffset = max(min((newWidth / (lastWidth / (oldContentOffset.x  * offsetX))), newWidth - scrollView.frame.width) , 0)
        //let newYContentOffset = max(min((newHeight / (lastHeight / (oldContentOffset.y * offsetY))), newHeight - scrollView.frame.height), 0)
        //let newXContentOffset = max(min(offsetX, newWidth - scrollView.frame.width) , 0)
        //let newYContentOffset = max(min(offsetY, newHeight - scrollView.frame.height), 0)
        
       
        let viewWidth = self.view.frame.width
        let viewHeight = self.view.frame.height
        let maxWidthContent = lastWidth - lastScreenWidth
        let maxHeightContent = lastHeight - lastScreenHeight
        
        let xPercentage = (oldContentOffset.x * 100) / maxWidthContent
        let yPercentage = (oldContentOffset.y * 100) / maxHeightContent
        
        let newMaxWidthContent = newWidth - newScreenWidth
        let newMaxHeightContent = newHeight - newScreenHeight
        
        let newPositionX = (newMaxWidthContent * xPercentage) / 100
        let newPositionY = (newMaxHeightContent * yPercentage) / 100
        
        let newXContentOffset = max(min(newPositionX, newWidth - scrollView.frame.width) , 0)
        let newYContentOffset = max(min(newPositionY, newHeight - scrollView.frame.height), 0)
        
        return CGPoint(x: newPositionX, y: newPositionY)
    }


}
