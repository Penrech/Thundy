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
    
    var startOrientation = UIDevice.current.orientation
    
    var initialWidth: CGFloat = 0
    var initialHeight: CGFloat = 0
    
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
        print("ScrollView ancla: \(scrollView.layer.anchorPoint)")
        print("ScrollView centro: \(scrollView.center)")
    
        
        self.extendedLayoutIncludesOpaqueBars = true
        //self.edgesForExtendedLayout = .bottom
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView))
        doubleTapRecognizer.numberOfTapsRequired = 2
        detailImageView.addGestureRecognizer(doubleTapRecognizer)
        
        setImageDetail(asset: asset)
       
    
    }
    
    func initBarsButtons(){
       closeViewControllerButton = UIBarButtonItem(image: UIImage(named: "close")?.escalarImagen(nuevaAnchura: 35), style: .plain, target: self, action: #selector(closeDetail2(_:)))
        navigationItem.leftBarButtonItem = closeViewControllerButton
    
    }

    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
      if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)

        }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        if scrollView.zoomScale < scrollView.minimumZoomScale {
            return
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
    
    override func viewDidAppear(_ animated: Bool) {
        
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
        
        initialWidth = newShortSide
        initialHeight = newLongSide
        
        self.detailImageView.frame = CGRect(x: positionX, y: positionY, width: newShortSide, height: newLongSide)
        
    }
  
    func setImageWhenRotate(landscape: Bool){
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

    func handleOrientation() -> CGFloat{
        var multiplier: CGFloat = 1
        switch startOrientation {
        case .landscapeRight:
            if UIDevice.current.orientation == UIDeviceOrientation.portrait{
                multiplier = -1
            }
        case .portrait:
            if UIDevice.current.orientation == UIDeviceOrientation.landscapeLeft{
                multiplier = -1
            }
        default: break
        }
        
        return multiplier
    }

}
