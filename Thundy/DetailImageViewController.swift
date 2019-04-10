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
    
    var viewFullyLoaded = false
    var clipping: CGRect!
    var screenSize: CGRect!
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailImageView: UIImageView!
    @IBOutlet weak var LeftImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var RightLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var TopImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var BottomImageConstraint: NSLayoutConstraint!
    
    @IBAction func closeDetail(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        scrollView.delegate = self
    
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTapScrollView))
        doubleTapRecognizer.numberOfTapsRequired = 2
        detailImageView.addGestureRecognizer(doubleTapRecognizer)
        
        detailImageView.fetchImage(asset: asset, contentMode: .aspectFit)
        clipping = detailImageView.contentClippingRect
        screenSize = UIScreen.main.bounds
        setConstraints(element: screenSize.width)
        

    }
    
    func setConstraints(element: CGFloat){
     
        var proportion: CGFloat = 1
        var scaledHeight = clipping.height
        var scaledWidth = clipping.width
        
        proportion = scaledHeight / scaledWidth
        scaledWidth = element
        scaledHeight = scaledWidth * proportion
        
        print(screenSize)
        print(scaledWidth)
        print(scaledHeight)
        let imageScaledSize = CGRect(x: 0, y: 0.5, width: scaledWidth  , height: scaledHeight)
        
        detailImageView.frame = imageScaledSize
        //detailImageView.contentMode = .scaleAspectFill
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
        /*let tamañoImagen = detailImageView.contentClippingRect
        print("tamaño")
        print(tamañoImagen)*/
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
            setConstraints(element: size.height)
        } else {
            setConstraints(element: size.width)
        }
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    override var prefersStatusBarHidden: Bool{
        return viewFullyLoaded
    }
 
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
