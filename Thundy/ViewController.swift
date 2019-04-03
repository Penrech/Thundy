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
    let albumName = "Thundy"
    var images: [UIImage]?
    
    var blinkTimer: Timer!
    var permissionError = false

    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var labelTexto: UILabel!
    @IBOutlet weak var buttonStart: RoundButton!
    @IBAction func comenzarConLaApp(_ sender: Any) {
        buttonStart.clickAnimation()
        askForPermissions()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        images = [blinkLogoImage!, normalLogoImage!]
        startTimer()

        let imagesButton = UIBarButtonItem(image: UIImage(named: "info")!.escalarImagen(nuevaAnchura: 36), style: .plain, target: self, action: #selector(showInfo))
        let infoButton = UIBarButtonItem(image: UIImage(named: "images")!.escalarImagen(nuevaAnchura: 36), style: .plain, target: self, action: #selector(goToImages))
        
        navigationItem.rightBarButtonItems = [imagesButton, infoButton]
        for item in navigationItem.rightBarButtonItems! {
            item.imageInsets = UIEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        navigationController?.navigationBar.backgroundColor = .clear
        
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let value = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        navigationController?.navigationBar.barStyle = .blackTranslucent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
       
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
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera], mediaType: AVMediaType.video, position: .unspecified)
        guard let _ = deviceDiscoverySession.devices.first else {
            let alerta = UIAlertController(title: "Error", message: "This device does not have a camera", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (acccion) in
                //self.showErrorIfNotPermission(error: .NoCamera)
                //TODO: quitar luego
                self.loadCameraView()
            }))
            present(alerta, animated: true, completion: nil)
            return
        }
        
        let cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let savePhotosPermissionStatus = PHPhotoLibrary.authorizationStatus()

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
    
        if let cameraViewController = self.storyboard?.instantiateViewController(withIdentifier: "photoViewController") {
            present(cameraViewController, animated: true, completion: nil)
        }
    }
    
    func reStoreInitialState(){
        if permissionError {
            permissionError = false
            self.labelTexto.numberOfLines = 1
            self.labelTexto.text = defaultText
            self.logoImage.image = normalLogoImage
            
            startTimer()
            
        }
    }
    
    func showErrorIfNotPermission(error: PermissionErrors){
        DispatchQueue.main.async {
            self.stopBlinking()
            
            self.logoImage.image = UIImage(named: "triste")
            self.labelTexto.numberOfLines = 2
            self.permissionError = true
            
            self.labelTexto.text = error.rawValue
        }
    }
    
    func requestPermissionAgain(error: PermissionRequest){
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
    
    /*func checkIfAlbumIsCreated(){
        let albumList = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        //print(albumList)
        albumList.enumerateObjects { (colection, _, _) in
            print(colection.localizedTitle)
        }
    }*/
    
    func crearAlbumConNombre(name: String){
        var albumPlaceholder: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            // Request creating an album with parameter name
            let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
            // Get a placeholder for the new album
            albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
        }, completionHandler: { success, error in
            if success {
                guard let placeholder = albumPlaceholder else {
                    fatalError("Album placeholder is nil")
                }
                
                let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                guard let album: PHAssetCollection = fetchResult.firstObject else {
                    // FetchResult has no PHAssetCollection
                    return
                }
                
                // Saved successfully!
                print(album.assetCollectionType)
            }
            else if let e = error {
                // Save album failed with error
            }
            else {
                // Save album failed with no error
            }
        })
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
                self.navigationController?.pushViewController(galleryViewController!, animated: true)
            case .denied, .restricted, .notDetermined:
                    self.requestPermissionAgain(error: .LibraryToShow)
            }
        }

    }
    
    @objc func showInfo(){
        print("Show Info")
    }

}

