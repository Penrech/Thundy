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

    // MARK: - variables
    
    /*let normalLogoImage = UIImage(named: "Logo")
    let blinkLogoImage = UIImage(named: "parpadeando")*/
    let defaultText = "Let's catch some lightnings"
    //var images: [UIImage]?
    
    var imagesButton = UIBarButtonItem()
    var infoButton = UIBarButtonItem()
    
    //var blinkTimer: Timer!
    var permissionError = false
    
    let toCameraTransition = TransitionPopAnimator()
    
    // MARK: - outlets

    @IBOutlet weak var downView: UIView!
    @IBOutlet weak var logoImage: UIImageView!
    @IBOutlet weak var labelTexto: UILabel!
    @IBOutlet weak var buttonStart: RoundButton!
    @IBAction func comenzarConLaApp(_ sender: Any) {
        askForPermissions()
    }
    
    //MARK: - métodos de la vista
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //images = [blinkLogoImage!, normalLogoImage!]
        
        //Esta línea es importante, ya que define el conjunto de animaciones de transición que utiliza la aplicación, salvo las de acceder a la cámara
        navigationController?.addCustomTransitioning()
 
        //imagesButton = UIBarButtonItem(image: UIImage(named: "info-1"), style: .plain, target: self, action: #selector(showInfo))
        imagesButton = UIBarButtonItem(image: UIImage(named: "info-1"), style: .plain, target: self, action: #selector(showInfo))
        infoButton = UIBarButtonItem(image: UIImage(named: "galeria"), style: .plain, target: self, action: #selector(goToImages))
        
        navigationItem.rightBarButtonItems = [imagesButton, infoButton]
        
        navigationController?.navigationBar.barTintColor = UIColor.white
    }
   
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.navigationBar.backgroundColor = .clear
        
        guard let statusBarView = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView else {
            return
        }
        statusBarView.backgroundColor = .clear

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barStyle = .blackTranslucent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
    
        navigationController?.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        navigationController?.toolbar.setShadowImage(UIImage(), forToolbarPosition: .any)
        navigationController?.hidesBarsOnSwipe = false
        if navigationController!.isNavigationBarHidden {
            navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        setNumberOfLines(numberOfLinesPortrait: 1)
        //startTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //stopBlinking()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        setNumberOfLines(numberOfLinesPortrait: 1)
    }
    
    private func setNumberOfLines(numberOfLinesPortrait: Int){
        if UIDevice.current.orientation.isLandscape {
            self.labelTexto.numberOfLines = 0
        } else {
            if self.permissionError {
                self.labelTexto.numberOfLines = 2
            } else {
                self.labelTexto.numberOfLines = numberOfLinesPortrait
            }
        }
    }
    
   /* override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if let backView = navigationController?.navigationBar.subviews.first {
            backView.alpha = 0.5
            backView.backgroundColor = UIColor.defaultBlue
        }
    }*/

    //MARK: - métodos para controlar la animación de parpadeo
    
    /*func startTimer(){
        if let blinkTimer = blinkTimer {
            if !blinkTimer.isValid {
                self.blinkTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] timer in
                    self?.startBlinking()
                }
            }
        } else {
            self.blinkTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] timer in
                self?.startBlinking()
            }
        }
    }*/
    
    /*func startBlinking(){
        if logoImage.isAnimating {
            logoImage.stopAnimating()
        }
        logoImage.animationImages = images
        logoImage.animationDuration = 0.3
        logoImage.animationRepeatCount = 1
        logoImage.startAnimating()

    }*/
    
    //MARK: - métodos de permisos y accesos a otros view controllers
    
    //Este método comprueba que el usuario ha dado permiso al uso de la cámara y de la librería de imagenes antes de lanzar el viewcontroller de la cámara
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
    
        var cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let savePhotosPermissionStatus = PHPhotoLibrary.authorizationStatus()
        
        if cameraPermissionStatus == .authorized && savePhotosPermissionStatus == .authorized{
            self.loadCameraView()
        }

        if cameraPermissionStatus == .denied {
            requestPermissionAgain(error: .Camera)
        } else if cameraPermissionStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { (permitido) in
        
                cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
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
    
   //En este método cargo la vista de la cámara
    //Compruebo si es la primera vez que el usuario ha utilizado la aplicación para lanzarle o no el tutorial
    func loadCameraView(){
        reStoreInitialState()
    
        DispatchQueue.main.async {
            let preferences = UserDefaults.standard
            let key = (UIApplication.shared.delegate as! AppDelegate).isAppLoadBefore
            
            if preferences.object(forKey: key) == nil {
                if let tutorialViewControler = self.storyboard?.instantiateViewController(withIdentifier: "TutorialPager") as? TutorialPagerViewController {
                    tutorialViewControler.infoTab = false
                    self.navigationController?.pushViewController(tutorialViewControler, animated: true)
                }
            } else {
                self.performSegue(withIdentifier: "showCamera", sender: nil)
            }
        }
        
    }
    
    //Reinicio la interfaz que ha podido ser modificada en caso de mostrar un mensaje de error.
    func reStoreInitialState(){
        DispatchQueue.main.async {
            if self.permissionError {
                self.permissionError = false
                self.setNumberOfLines(numberOfLinesPortrait: 1)
                self.labelTexto.text = self.defaultText
                //self.logoImage.image = self.normalLogoImage
                
                //self.startTimer()
            }
        }
    }
    
    //Este método cambia la interfaz (El logo y el texto de la app) para mostrar un mensaje de error
    func showErrorIfNotPermission(error: PermissionErrors){
        DispatchQueue.main.async {
            //self.stopBlinking()
            
            //self.logoImage.image = UIImage(named: "triste")
            self.setNumberOfLines(numberOfLinesPortrait: 2)
            self.permissionError = true
            
            self.labelTexto.text = error.rawValue
        }
    }
    
    //En el caso de que el usuario halla rechazado anteriormente dar permiso a la app, se le vuelve a pedir permiso si intenta volver a acceder
    //a alguna funcionalidad que lo necesite
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
    
   /* //Este método detiene la animación de parpadeo del logotipo
    func stopBlinking(){
        if logoImage.isAnimating {
            logoImage.stopAnimating()
        }
        blinkTimer.invalidate()
    }*/
   
    //Este método carga la libreria de la app, siempre y cuando el usuario halla dado permiso
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
    
    //Este método carga de nuevo el tutorial inicial
    @objc func showInfo(){
        let infoViewController = self.storyboard?.instantiateViewController(withIdentifier: "TutorialPager")
        self.navigationController?.pushViewController(infoViewController!, animated: true)
    }

    //Aqui se inicia finalmente el viewcontroller de la cámara
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showCamera"{
            let controller = segue.destination as! PhotoViewController
            controller.transitioningDelegate = self
            if UIDevice.current.orientation.isLandscape {
                controller.hideStatusBar = true
            }
        }
    }
    
    // MARK: - mensajes de error
    
    //Estos dos enumeradores funcionan como una librería para almacenar los diversos mensajes de error de este view controller
    
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
    
}
// MARK: - animaciones de transición customizadas para acceder a la cámara
extension ViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        toCameraTransition.transitionMode = .Present
        toCameraTransition.circleColor = self.buttonStart.backgroundColor
        let circleButtonRect = downView.convert(self.buttonStart.frame, to: downView.superview?.superview)
        toCameraTransition.origin = CGPoint(x: circleButtonRect.midX, y: circleButtonRect.midY)
        toCameraTransition.buttonRect = circleButtonRect
        
        return toCameraTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        toCameraTransition.transitionMode = .Dismiss
        let circleButtonRect = downView.convert(self.buttonStart.frame, to: downView.superview)
        toCameraTransition.origin = CGPoint(x: circleButtonRect.midX, y: circleButtonRect.midY)
        toCameraTransition.buttonRect = circleButtonRect
        toCameraTransition.circleColor = self.buttonStart.backgroundColor
        
        return toCameraTransition
    }
}
