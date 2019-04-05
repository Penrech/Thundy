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
        //setConstraints()
        

    }
    
    func setConstraints(){
        clipping = detailImageView.contentClippingRect
        
        let screenSize = view.frame
        var proportion: CGFloat = 1
        var scaledHeight = clipping.height
        var scaledWidth = clipping.width
        
        if clipping.width > clipping.height {
            proportion = scaledHeight / scaledWidth
            scaledWidth = screenSize.width
            scaledHeight = scaledWidth * proportion
        } else {
            proportion = scaledWidth / scaledHeight
            scaledHeight = screenSize.height
            scaledWidth = scaledHeight * proportion
        }
        
    
        let imageScaledSize = CGRect(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
        
        
        let leftConstraint = (screenSize.width - imageScaledSize.width) / 2
        let rightConstraint = leftConstraint
        let topConstraint = (screenSize.height - imageScaledSize.height) / 2
        let bottomConstraint = topConstraint
        
        LeftImageConstraint.constant = leftConstraint
        RightLeadingConstraint.constant = rightConstraint
        TopImageConstraint.constant = topConstraint
        BottomImageConstraint.constant = bottomConstraint
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
        navigationController?.navigationBar.backgroundColor = .clear
        viewFullyLoaded = true
        UIView.animate(withDuration: 0.15) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        
    }

    override func viewWillAppear(_ animated: Bool) {
        //navigationController?.navigationBar.backgroundColor = .clear
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
