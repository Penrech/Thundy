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
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailImageView: UIImageView!
  
    @IBAction func closeDetail(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView))
        doubleTapRecognizer.numberOfTapsRequired = 2
        detailImageView.addGestureRecognizer(doubleTapRecognizer)
        
        setImageDetail(asset: asset)
    }
    
    func manageChangeOfOrientation(portrait: Bool){
        if portrait{
            
        } else {
            
        }
    }
    
    @IBAction func handleDoubleTapScrollView(recognizer: UITapGestureRecognizer) {
      /*  if scrollView.zoomScale == 1 {
            scrollView.zoom(to: zoomRectForScale(scale: scrollView.maximumZoomScale, center: recognizer.location(in: recognizer.view)), animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)

        }*/
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        print("ContentOffset: \(scrollView.contentOffset)")
        let deviceHeight = UIScreen.main.bounds.height
        let actualFrame = detailImageView.frame
        let newHeight = actualFrame.height
        let position = (deviceHeight - newHeight) / 2
        let actualX = actualFrame.minX
        let actualY = actualFrame.minY
        print("Position y: \(position) ")
        let positionNormalized = max(position, 0)
        print("Posicion Normalizada: \(positionNormalized)")
        let newFrame = CGRect(x: actualX, y: positionNormalized , width: actualFrame.width, height: actualFrame.height)
        
        detailImageView.frame = newFrame
 
    }
    
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = detailImageView.frame.size.height / scale
        zoomRect.size.width  = detailImageView.frame.size.width  / scale
        let newCenter = scrollView.convert(center, from: detailImageView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
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
        
    }

    override func viewWillAppear(_ animated: Bool) {
        //navigationController?.navigationBar.backgroundColor = .clear
        //navigationController?.setToolbarHidden(false, animated: true)
        navigationItem.title = " "
        navigationController?.hidesBarsOnSwipe = false
        
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        print("hola")
        super.viewWillTransition(to: size, with: coordinator)
        if UIDevice.current.orientation.isLandscape {
           
        } else {
           
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    override var prefersStatusBarHidden: Bool{
        return true
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
        positionY = (deviceHeight - newHeight) / 2
        self.detailImageView.frame = CGRect(x: 0, y: positionY, width: newWidth, height: newHeight)
        self.detailImageView.fetchImage(asset: asset, contentMode: .aspectFit)
        self.detailImageView.layer.anchorPoint = self.view.layer.anchorPoint
        
    }


}
