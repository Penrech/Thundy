//
//  ViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 30/03/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import AVFoundation
import Photos

class ViewController: UIViewController {

    let normalLogoImage = UIImage(named: "Logo")
    let blinkLogoImage = UIImage(named: "parpadeando")
    let defaultText = "Let's catch some friends for Thundy"
    var images: [UIImage]?
    
    var imagesButton = UIBarButtonItem()
    var infoButton = UIBarButtonItem()
    
    var blinkTimer: Timer!
    var permissionError = false

    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var labelTexto: UILabel!
    @IBOutlet weak var labelTextoPortrait: UILabel!
    @IBOutlet weak var buttonStart: RoundButton!
    @IBAction func comenzarConLaApp(_ sender: Any) {
        askForPermissions()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        images = [blinkLogoImage!, normalLogoImage!]
        startTimer()
        navigationController?.addCustomTransitioning()
        imagesButton = UIBarButtonItem(image: UIImage(named: "info")!.escalarImagen(nuevaAnchura: 30), style: .plain, target: self, action: #selector(showInfo))
        infoButton = UIBarButtonItem(image: UIImage(named: "images")!.escalarImagen(nuevaAnchura: 30), style: .plain, target: self, action: #selector(goToImages))
        
        navigationItem.rightBarButtonItems = [imagesButton, infoButton]
        /*for item in navigationItem.rightBarButtonItems! {
            item.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }*/
    }
    
    /*override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }*/
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.backgroundColor = .clear
        
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = .clear

    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.barStyle = .blackTranslucent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.hidesBarsOnSwipe = false

    }

    func startTimer(){
        if let blinkTimer = blinkTimer {
            if !blinkTimer.isValid {
                self.blinkTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(startBlinking), userInfo: nil, repeats: true)
            }
        } else {
            blinkTimer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(startBlinking), userInfo: nil, repeats: true)
        }
    }
    
    @objc func startBlinking(){
        if logoImage.isAnimating {
            logoImage.stopAnimating()
        }
        logoImage.animationImages = images
        logoImage.animationDuration = 0.3
        logoImage.animationRepeatCount = 1
        logoImage.startAnimating()

    }
    
    func askForPermissions(){
        //Compruebo que el dispositivo tiene cámaras
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        guard let _ = deviceDiscoverySession.devices.first else {
            let alerta = UIAlertController(title: "Error", message: "This device does not have a camera", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (acccion) in
                self.showErrorIfNotPermission(error: .NoCamera)
            }))
            present(alerta, animated: true, completion: nil)
            return
        }
    
        
        let cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let savePhotosPermissionStatus = PHPhotoLibrary.authorizationStatus()
        
        if cameraPermissionStatus == .authorized && savePhotosPermissionStatus == .authorized{
            self.loadCameraView()
        }

        if cameraPermissionStatus == .denied {
            requestPermissionAgain(error: .Camera)
        } else if cameraPermissionStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (permitido) in
                if !permitido {
                    self.showErrorIfNotPermission(error: .NoCameraPermission)
                } else {
                    if savePhotosPermissionStatus == .authorized {
                        //Lanzar camara
                        self.loadCameraView()
                    }
                }
            }
        }

        if savePhotosPermissionStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == .authorized && cameraPermissionStatus == .authorized {
                    //Lanzar camara
                    self.loadCameraView()
                } else if status == .denied{
                    self.showErrorIfNotPermission(error: .NoLibraryPermission)
                }
            }
        } else if savePhotosPermissionStatus == .denied {
            self.requestPermissionAgain(error: .LibraryToSave)
        }
        
    }
    
   
    func loadCameraView(){
        reStoreInitialState()
        
        let preferences = UserDefaults.standard
        let key = (UIApplication.shared.delegate as! AppDelegate).isAppLoadBefore
        OperationQueue.main.addOperation {
            if preferences.object(forKey: key) == nil {
                if let tutorialViewControler = self.storyboard?.instantiateViewController(withIdentifier: "TutorialPager") as? TutorialPagerViewController {
                    tutorialViewControler.infoTab = false
                    self.navigationController?.pushViewController(tutorialViewControler, animated: true)
                }
            } else {
                if let cameraViewController = self.storyboard?.instantiateViewController(withIdentifier: "photoViewController") {
                    self.present(cameraViewController, animated: true, completion: nil)
                }
            }
            
        }
        
    }
    
    func reStoreInitialState(){
        DispatchQueue.main.async {
            if self.permissionError {
                self.permissionError = false
                self.labelTexto.numberOfLines = 1
                self.labelTextoPortrait.numberOfLines = 1
                self.labelTexto.text = self.defaultText
                self.labelTextoPortrait.text = self.defaultText
                self.logoImage.image = self.normalLogoImage
                
                self.startTimer()
            }
        }
    }
    
    func showErrorIfNotPermission(error: PermissionErrors){
        DispatchQueue.main.async {
            self.stopBlinking()
            
            self.logoImage.image = UIImage(named: "triste")
            self.labelTexto.numberOfLines = 2
            self.labelTextoPortrait.numberOfLines = 2
            self.permissionError = true
            
            self.labelTexto.text = error.rawValue
            self.labelTextoPortrait.text = error.rawValue
        }
    }
    
    func requestPermissionAgain(error: PermissionRequest){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Need Permission", message: error.rawValue, preferredStyle: .alert)
            let accionCancelar = UIAlertAction(title: "Cancel", style: .cancel, handler: {(completion) in
                switch error{
                case .Camera:
                    self.showErrorIfNotPermission(error: .NoCameraPermission)
                case .LibraryToSave:
                    self.showErrorIfNotPermission(error: .NoLibraryPermission)
                case .LibraryToShow:
                    self.showErrorIfNotPermission(error: .NoLibraryPermissionGallery)
                }
            })
            let accionSettings = UIAlertAction(title: "Go To Settings", style: .default) { (alert) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl){
                    UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
                }
            }
            
            alertController.addAction(accionCancelar)
            alertController.addAction(accionSettings)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func albumCreationError(){
        let alertController = UIAlertController(title: "Media Error", message:"Error while creating Thundy photo album, please try again" , preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
    
    func stopBlinking(){
        if logoImage.isAnimating {
            logoImage.stopAnimating()
        }
        blinkTimer.invalidate()
    }
    
    enum PermissionErrors : String{
        case NoCamera = "Thundy needs a device with camera to work properly"
        case NoLibraryPermission = "Thundy needs permission to access the library in order to save photos"
        case NoCameraPermission   = "Thundy needs permission to use the camera in order to take photos"
        case NoLibraryPermissionGallery = "Thundy needs permission to access the library in order to show photos"
    }
    enum PermissionRequest: String {
        case Camera = "You have denied camera use permission previously, but thundy needs that in order to take your thundy photos. Go to settings in order to give thundy permission, please."
        case LibraryToSave = "You have denied library use permission previously, but thundy needs that in order to save your thundy photos. Go to settings in order to give thundy permission, please."
        case LibraryToShow = "You have denied library use permission previously, but thundy needs that in order to show your thundy photos. Go to settings in order to give thundy permission, please."
    }
    

    @objc func goToImages(){
        let galleryViewController = self.storyboard?.instantiateViewController(withIdentifier: "galleryViewController")
        let galleryPermissionStatus = PHPhotoLibrary.authorizationStatus()
        
        if galleryPermissionStatus == .authorized {
            navigationController?.pushViewController(galleryViewController!, animated: true)
            return
        }
        
        PHPhotoLibrary.requestAuthorization { (status) in
            switch status {
            case .authorized:
                DispatchQueue.main.async {
                    self.navigationController?.pushViewController(galleryViewController!, animated: true)
                }
            case .denied, .restricted, .notDetermined:
                    self.requestPermissionAgain(error: .LibraryToShow)
            }
        }

    }
    
    @objc func showInfo(){
        let infoViewController = self.storyboard?.instantiateViewController(withIdentifier: "TutorialPager")
        self.navigationController?.pushViewController(infoViewController!, animated: true)
    }

}

