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
        scrollView.maximumZoomScale = 6.0
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
        let position = (deviceHeight - newHeight) / 2
        let actualX = actualFrame.minX
        
        print("Position y: \(position) ")
        let positionNormalized = max(position, 0)
        print("Posicion Normalizada: \(positionNormalized)")
        let newFrame = CGRect(x: actualX, y: positionNormalized , width: actualFrame.width, height: actualFrame.height)
        
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
        print("Landscape: \(UIDevice.current.orientation.isLandscape)")
        setImageWhenRotate(landscape: UIDevice.current.orientation.isLandscape)
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
    
    override var prefersStatusBarHidden: Bool{
        return false
    }
    
    func setImageDetail(asset: PHAsset){
        let width = asset.pixelWidth
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
        
        
       
        //self.detailImageView.frame = CGRect(x: 0, y: positionY, width: newWidth, height: newHeight)
        self.detailImageView.fetchImage(asset: asset, contentMode: .aspectFit)
        self.detailImageView.layer.anchorPoint = self.view.layer.anchorPoint
        
    }
    
    func setImageWhenRotate(landscape: Bool){
        var deviceHeight = UIScreen.main.bounds.height
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
        
        //self.detailImageView.layer.anchorPoint = self.view.layer.anchorPoint
        
    }


}
