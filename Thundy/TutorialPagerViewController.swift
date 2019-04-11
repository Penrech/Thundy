//
//  TutorialPagerViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 10/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

class TutorialPagerViewController: UIPageViewController, UIPageViewControllerDataSource {

    var viewControllerList:[UIViewController] = []
    
    var infoTab: Bool = true
    
    var customAlbumManager: CustomPhotoAlbum = (UIApplication.shared.delegate as! AppDelegate).customPhotosManager
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataSource = self
        
        let bgView = UIView(frame: UIScreen.main.bounds)
        bgView.backgroundColor = UIColor.defaultBlue
        view.insertSubview(bgView, at: 0)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.topItem?.title = ""
        setUpViewControllers(infoTab: infoTab)
        loadAlbum(infoTab: infoTab)
    }
    
    func loadAlbum(infoTab: Bool){
        if !infoTab{
            customAlbumManager.getAlbum(title: customAlbumManager.photoAlbumName) { (album) in
                if let _ = album {
                   
                } else {
                    let alerta = UIAlertController(title: "Unspected Error", message: "Thundy can't load it's photo album and unspected error occur. Please, try start it again.", preferredStyle: .alert)
                    alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (alerta) in
                        self.dismiss(animated: true, completion: nil)
                    }))
                }
            }
        }
    }
    
    func setUpViewControllers(infoTab: Bool){
        let vc1 = self.storyboard?.instantiateViewController(withIdentifier: "Step1")
        let vc2 = self.storyboard?.instantiateViewController(withIdentifier: "Step2")
        let vc3 = self.storyboard?.instantiateViewController(withIdentifier: "Step3")
        
        if infoTab{
            viewControllerList = [vc1!, vc2!, vc3!]
        } else {
            let vc4 = self.storyboard?.instantiateViewController(withIdentifier: "Step4")
            viewControllerList = [vc1!, vc2!, vc3!, vc4!]
        }
        
        if let firstViewController = viewControllerList.first {
            self.setViewControllers([firstViewController], direction: .forward, animated: true, completion: nil)
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        
        guard let vcIndex = viewControllerList.firstIndex(of: viewController) else { return nil }
         
         let previousIndex = vcIndex - 1
         
         guard previousIndex >= 0 else {return nil}
         
         guard viewControllerList.count > previousIndex else {return nil}
         
         return viewControllerList[previousIndex]

    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        
        guard let vcIndex = viewControllerList.firstIndex(of: viewController) else {return nil}
         
         let nextIndex = vcIndex + 1
         
         guard viewControllerList.count != nextIndex else {return nil}
         
         guard viewControllerList.count > nextIndex else { return nil }
         
         return viewControllerList[nextIndex]

    }

}
