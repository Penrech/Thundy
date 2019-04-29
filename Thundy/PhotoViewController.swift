//
//  PhotoViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 01/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import CoreMotion

class PhotoViewController: UIViewController {

    // MARK: - variables
    
    let isoKey = "isoKey"
    let exposureKey =  "exposureKey"
    let sensibilityKey = "sensibilityKey"
    let optionsViewShowHeight = 225
    
    let scanImage = UIImage(named: "scan")
    let pauseImage = UIImage(named: "pause")
    var scanning = false
    var lastValue: Double!
  /*  let maxGapBetweenPeaks = 500
    let minGapBetweenPeaks = 50*/
    
    var oldMaxBrightness: Double = 0
    var oldMinBrightness: Double = 0
    
    var referenceLuminosity: Double!
    var luminosityAverageOverTime : [Double] = []

    var steadyTimer: Timer!
    var controlLuxTimer: Timer!
    var scanningPauseBecauseDeviceMoved = false
    var scanningPauseBetweenPhotoGap = false
    var scanningPauseWhenIsTakingPhoto = false
    var settingsWindowOpen = false
    
    var hideStatusBar = false
    
    var referenceAttitude: CMAttitude?
    
    var rayCapturedNumber = 0 {
        didSet{
            thunderCountLabel.text = "\(rayCapturedNumber)"
        }
    }
    
    var motionManager: CMMotionManager!
    
    var customAlbumManager: CustomPhotoAlbum = (UIApplication.shared.delegate as! AppDelegate).customPhotosManager
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var captureOutput = AVCaptureVideoDataOutput()
    var captureDeviceRef: AVCaptureDevice?

    var stillImageOutput: AVCapturePhotoOutput?
    
    var supportedISO : [ListOfCameraOptions.ISOoption] = []
    var supportedExposure: [ListOfCameraOptions.ExposureOption] = []
    
    // MARK: - Outlets
    
    @IBOutlet weak var optionsViewHeightContraint: NSLayoutConstraint!
    @IBOutlet weak var isoSlider: UISlider!
    @IBOutlet weak var isoStackView: UIStackView!
    @IBOutlet weak var exposureSlider: UISlider!
    @IBOutlet weak var exposureStackView: UIStackView!
    @IBOutlet weak var sensibilitySlider: UISlider!
    @IBOutlet weak var optionsView: UIView! {
        didSet{
            optionsView.layer.cornerRadius = 24
            optionsView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        }
    }
    @IBOutlet weak var settingsButton: UIButton!
    
    //Aqui controlo los sliders de opciones
    @IBAction func isoOptionsChange(_ sender: Any) {
       isoSlider.value = round(self.isoSlider.value)
        setNewIso(value: Int(isoSlider!.value))
    }
    @IBAction func ExposureOptionsChange(_ sender: Any) {
       exposureSlider.value = round(self.exposureSlider.value)
        setNewExposure(value: Int(exposureSlider!.value))
    }
    @IBAction func SensibilityOptionsChange(_ sender: Any) {
        sensibilitySlider.value = round(self.sensibilitySlider.value)
        setNewSensibility(value: Int(sensibilitySlider!.value))
    }
    
    @IBOutlet weak var scanButton: UIButton!
    @IBOutlet weak var thunderCountLabel: UILabel!
    @IBOutlet weak var photoAlertView: UIView!
    @IBOutlet weak var thunderIcon: UIImageView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var AlertSteady: RoundedCard!
    
    @IBAction func startScanning(_ sender: Any) {
        if scanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @IBAction func openSettings(_ sender: Any) {
        if settingsWindowOpen {
            showOptionsView(show: false)
        } else {
            showOptionsView(show: true)
        }
    }
    @IBAction func restoreSettings(_ sender: Any) {
        restoreValues()
    }
    
    @IBAction func closeSettins(_ sender: Any) {
        showOptionsView(show: false)
    }
    
    @IBAction func closePhotoViewController(_ sender: Any) {
        let homeControlller = (UIApplication.shared.delegate as! AppDelegate).window?.rootViewController?.children[0] as! ViewController

        self.transitioningDelegate = homeControlller
        dismiss(animated: true, completion: nil)

    }
    
    // MARK: - view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setInitialExposureValues()
        
        closeButton.setImage(closeButton.image(for: .normal)!.addShadow(shadowHeight: 35), for: .normal)
        thunderIcon.image = thunderIcon.image?.addShadow(shadowHeight: 35)
        
        motionManager = CMMotionManager()
        
        //Inicio la configuración de la cámara de forma asíncrona para que el viewController cargue más rápidamente
        DispatchQueue.global(qos: .userInitiated).async {
            self.configureCamera()
        }
        
        thunderCountLabel.text = "\(rayCapturedNumber)"
    }
    
    //Oculto el botón de escaneo hasta que la cámara halla sido configurada
    //Cargo el album de Thundy, en principio debería estar ya creado, pero si no está el método lo creará
    override func viewWillAppear(_ animated: Bool) {
        optionsView.isHidden = true
        customAlbumManager.getAlbum(title: customAlbumManager.photoAlbumName) { (album) in
            if let _ = album {
                OperationQueue.main.addOperation {
                    if !self.scanButton.isEnabled && self.captureSession.isRunning {
                        self.scanButton.isEnabled = true
                        self.settingsButton.isEnabled = true
                    }
                }
            } else {
                let alerta = UIAlertController(title: "Unspected Error", message: "Thundy couldn't load it's photo album and unspected error occured. Please, try start it again.", preferredStyle: .alert)
                alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (alerta) in
                    self.dismiss(animated: true, completion: nil)
                }))
                }
            }
        
        scanButton.isEnabled = false
        settingsButton.isEnabled = false
    }
    
    //Para mejorar la apariencia de la animación de entrada, oculto en un principio el menú de opciones, aquí lo activo de nuevo
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        optionsView.isHidden = false
    }
    
    //Gestiono el cambio de portrait a landscape, desactivo las animaciones para evitar efectos extraños
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        UIView.setAnimationsEnabled(false)
       coordinator.animate(alongsideTransition: { (contexto) in
     
            DispatchQueue.main.async(execute: {
                self.updateVideoOrientation()
                UIView.setAnimationsEnabled(true)
            })
            
            
        }) { (contextoFinal) in
            
        }

    }
    
    //Cuando la vista desaparece desactivo el escaneo en caso de que aun esté activo
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopScanning()
    }
    
    // MARK: - configuración de la cámara
    
    //Configuro la cámara, su preview y sus outputs.
    //1. para analizar los cambios de luminosidad
    //2. el otro para capturar fotos
    func configureCamera(){
        //Obtenemos la cámara trasera para capturar video
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            return
        }
        
        captureDeviceRef = captureDevice
        
        //Arrancamos la sesión
        do {
            //Convertimos el device (La camara) a un input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            stillImageOutput = AVCapturePhotoOutput()
            //Añadimos el input a la sesión
            captureSession.addInput(input)
            captureSession.addOutput(stillImageOutput!)
            
            captureSession.sessionPreset = .photo
         
           do {
                try captureDevice.lockForConfiguration()
                if captureDevice.isLowLightBoostSupported {
                    captureDevice.automaticallyEnablesLowLightBoostWhenAvailable = true
                }
            // Si el dispositivo lo permite, introduzco una exposición e iso customizadas
            // Si el dispositivo no lo permite, mantengo las que hay por defecto y desactivo la opción de poder utilizar ajustes avanzados
                if captureDevice.isExposureModeSupported(.custom){
                    let preferences = UserDefaults.standard
                    
                    var exposureTime = CMTime(value: 1, timescale: 250)
                    var iso: Float = 100
                    
                    if let defaultId = preferences.value(forKey: isoKey) as? Int {
                        if let isoElement = supportedISO.first(where: {$0.id == defaultId}){
                            iso = isoElement.option
                        }
                    }
                    if let defaultExposure = preferences.value(forKey: exposureKey) as? Int {
                        if let exposureElement = supportedExposure.first(where: {$0.id == defaultExposure}){
                            exposureTime = exposureElement.option
                        }
                    }
                    if exposureTime < captureDevice.activeFormat.minExposureDuration {
                        exposureTime = captureDevice.activeFormat.minExposureDuration
                    }
                    if iso < captureDevice.activeFormat.minISO {
                        iso = captureDevice.activeFormat.minISO
                    }
                    captureDevice.setExposureModeCustom(duration: exposureTime, iso: iso, completionHandler: nil)
                    initializeOptionsMenu(device: captureDevice)
                } else {
                    settingsButton.isHidden = true
                }
            } catch {
                print(error)
                settingsButton.isHidden = true
            }
            captureDevice.unlockForConfiguration()
            
            //Mostramos en el VideoPreviewLayer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            //Finalmente, empezamos a "Capturar"
            captureSession.startRunning()
            
            OperationQueue.main.addOperation {
                self.videoPreviewLayer?.frame = self.view.layer.frame
            
                self.view.layer.addSublayer(self.videoPreviewLayer!)
                
                self.updateVideoOrientation()
                
                //Colocamos los objetos encima
                self.view.bringSubviewToFront(self.scanButton)
                self.view.bringSubviewToFront(self.thunderCountLabel)
                self.view.bringSubviewToFront(self.thunderIcon)
                self.view.bringSubviewToFront(self.closeButton)
                self.view.bringSubviewToFront(self.photoAlertView)
                self.view.bringSubviewToFront(self.AlertSteady)
                self.view.bringSubviewToFront(self.optionsView)
                self.view.bringSubviewToFront(self.settingsButton)
                
                if !self.scanButton.isEnabled && self.customAlbumManager.albumReference != nil {
                    self.scanButton.isEnabled = true
                    self.settingsButton.isEnabled = true
                }
            }
            
        } catch {
            print(error)
            let alerta = UIAlertController(title: "Unspected Error", message: "Thundy couldn't load the camera and unspected error occured. Please, try start it again.", preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (alerta) in
                self.dismiss(animated: true, completion: nil)}))
            return
        }
    
    }
    
    // MARK: - gestión de la rotación
    
    //Roto la capa de video preview, este método es llamado cuando el terminal cambia de orientación
    func updateVideoOrientation() {
    
        guard let videoPreviewLayer = self.videoPreviewLayer else {
            return
        }
        guard videoPreviewLayer.connection!.isVideoOrientationSupported else {
            return
        }
        
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
       
        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation.videoOrientation ?? .portrait
        
        if videoPreviewLayer.connection!.videoOrientation == videoOrientation {
            return
        }
        
        if let imageOutputConnection = stillImageOutput?.connection(with: AVMediaType.video) {
            imageOutputConnection.videoOrientation = videoOrientation
        }
        
        videoPreviewLayer.frame = view.bounds
        videoPreviewLayer.connection!.videoOrientation = videoOrientation
       
        videoPreviewLayer.removeAllAnimations()
        
    }
    
    // MARK: - métodos de cambio de elementos de la interfaz
   override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool{
        return hideStatusBar
    }
    
    // MARK: - métodos de escaneo
    
    // este método se llama al pulsar en iniciar el escaneo, crea el método para capturar fotografias e inicia la detección de movimiento del terminal
    func startScanning(){
        //Generamos un Output
        captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main )
        captureSession.addOutput(captureOutput)
        
        motionManager.startDeviceMotionUpdates()
    
        scanButton.setImage(pauseImage, for: .normal)
        scanning = true
        print("Scanning...")
    }
    
    // este método detiene el escaneo y vuelve a todas las variables a su estado inicial
    func stopScanning(){
        captureSession.removeOutput(captureOutput)
        
        motionManager.stopDeviceMotionUpdates()
        scanningPauseBecauseDeviceMoved = false
        scanningPauseBetweenPhotoGap = false
        scanningPauseWhenIsTakingPhoto = false
        showAlertToUser(show: false)
        restoreVariables()
        
        setTimer(active: false)
        setControlLuminosityTimer(active: false)
        
        scanButton.setImage(scanImage, for: .normal)
        scanning = false
        print("Stop scanning.")
    
    }
    
    //Esta función restaura ciertas variables a su estado inicial
    func restoreVariables(){
        referenceLuminosity = nil
        referenceAttitude = nil
        lastValue = nil
    }
    
    // MARK: - Metodos para tomar fotos
    
    //Este método inicia la captura de una fotografía, se llama cuando un rayo es detectado
    func photoTaken(luminosityWhenDetected: Double){
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .off
        
        stillImageOutput?.isHighResolutionCaptureEnabled = true
    
        scanningPauseWhenIsTakingPhoto = true
        DispatchQueue.global(qos: .userInitiated).async {
            self.stillImageOutput?.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    // Este método muestra una animación similar a un flash para indicar de forma visual que un rayo ha sido capturado
    func showAlertView(){
        print(photoAlertView.isHidden)
        if photoAlertView.isHidden {
            photoAlertView.isHidden = false
            photoAlertView.alpha = 0
            UIView.animateKeyframes(withDuration: 0.1, delay: 0.0, options: [.autoreverse], animations: {
                self.photoAlertView.alpha = 0.5
            }) { (completado) in
                self.photoAlertView.isHidden = true
            }
        }
    }

}

// MARK: - Extensión para gestionar la detección de rayos

extension PhotoViewController: AVCaptureMetadataOutputObjectsDelegate , AVCaptureVideoDataOutputSampleBufferDelegate{
   
    // Esta función analiza continuamente la luminosidad de la escena que está captando la cámara.
    // Para ello utilizo el valor del brillo de la escena para calcular cambios repentinos en de luminosidad
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let luminosity : Double = calcularLuminosidad(sampleBuffer: sampleBuffer)
        
        // Si la ventana de ajustes está abierta, se paraliza el proceso de escaneo para evitar errores.
        if settingsWindowOpen {
            return
        }
    
        //Si una foto está siendo tomada, se paraliza el proceso de escaneo. Con esto se evitan errores de sincronización
        if scanningPauseWhenIsTakingPhoto {
            return
        }
        
        //Si el dispositivo se ha movido, la app espera unos segundos para que el terminal vuelva a ser sostenido firmemente
        if scanningPauseBecauseDeviceMoved {
            return
        }
        
        //Si el terminal se mueve, se detiene también el escaneo
        if deviceMoved() {
            setTimer(active: true)
            return
        }
        
        //Está función será la encargada de detectar si se ha detectado o no un rayo
        detectIfRayIsShown(luminosity: luminosity, buffer: sampleBuffer)
    
    }
    
    //Esta función devuelve el valor de luminosidad de la escena y calcula el mínimo de brillo
    //Ya que no hay forma de obtener cual es el brillo mínimo que puede tener una escena, se guarda una variable en la que
    //Se almacena el brillo más bajo detectado, este valor está en constante actualización y se utiliza para normalizar todos
    //los valores relacionados con la luminosidad con el fin de que su valor sea siempre mayor que 0
    func calcularLuminosidad(sampleBuffer: CMSampleBuffer) -> Double {
        //Se extraen datos EXIF del buffer de datos
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
    
        let brightness : Double = exifData?["BrightnessValue"] as! Double
        if -self.oldMinBrightness < brightness {
            self.oldMinBrightness = abs(brightness)
        }
        print("Brillo en bruto: \(brightness)")
        print("Constante compensacion: \(oldMinBrightness)")
        return brightness
    }
    
    //Aquí se calcula la luminosidad de una foto ya tomada
    func calcularLuminosidad(capturedImage: AVCapturePhoto) -> Double {
        
        let exifData = capturedImage.metadata["{Exif}"] as? NSMutableDictionary
        let brightness : Double = exifData?["BrightnessValue"] as! Double
        
        return brightness
    }
    
    //Esta función utiliza los sensores del dispositivo para determinar si esta estable o si se mueve.
    //Es importante que el dispositivo esté lo más estable posible, ya que si no, puede producir cambios de iluminación
    //Que podrían interpretarse como rayos. Además, ya que los rayos ocurren muy deprisa y la app tiene poco tiempo para enfocar, un ligero movimiento
    //Puede resultar en una imagen no enfocada
    func deviceMoved() -> Bool{
        
        if referenceAttitude == nil {
            if let attitude = motionManager.deviceMotion?.attitude{
                referenceAttitude = attitude
            } else {
                return false
            }
        }
      
        let constantOfMargin = 1.0
        let currentAttitude = motionManager.deviceMotion?.attitude
    
        currentAttitude?.multiply(byInverseOf: referenceAttitude!)
        
        let pitchMovido = abs(currentAttitude!.pitch) * 10
        let rollMovido = abs(currentAttitude!.roll) * 10
        
        let movedUpDown = pitchMovido > constantOfMargin
        let movedLeftRight = rollMovido > constantOfMargin
        
        if movedUpDown {
              print("movido verticalmente")
            return true
        }
        
        if movedLeftRight {
            print("movido lateralmente")
            return true
        }
        
        return false
        
    }
    
    //Aquí se configura un contador que mantiene el escaneo parado durante 1,5 segundos a la espera que el usuario vuelva
    // a sujetar de forma estable el dispositivo
    func setTimer(active: Bool){
        if steadyTimer != nil {
            steadyTimer.invalidate()
        }
        if active {
            showAlertToUser(show: true)
            steadyTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { (timer) in
                self.showAlertToUser(show: false)
            })
        }
    }
    
    //Esta función es util para detectar cambios de luminosidad en directo.
    //En determinados casos, la iluminación puede pasar de estar más oscura a más clara, una nube se mueve, se enciende un foco.
    //Inicialmente ese estimulo luminico podría ser interpretado como un rayo dependiendo de la velocidad a la que se encienda o ocurra
    //Si esta luz se mantiene en el tiempo, podría dar lugar a multiples capturas erroneas de rayos
    //Por esto, esta función espera a que el pico de luz tras un rayo vuelva a la cantidad de luz anterior. Si este no vuelve en dos segundos
    //Reinicia el valor de referencia para adaptarse a la nueva luminosidad
    func setControlLuminosityTimer(active: Bool){
        if controlLuxTimer != nil {
            controlLuxTimer.invalidate()
        }
        if active {
            print("Inició espera de 2 segundos por si la luminosidad se mantiene")
            controlLuxTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false, block: { (timer) in
     
                if self.scanningPauseBetweenPhotoGap {
                    print("La luminosidad ha cambiado, ajustando...")
                    self.lastValue = nil
                    self.scanningPauseBetweenPhotoGap = false
                }
            })
        }
    }
    
    //Esta función se encarga de mostrar visualmente una alerta al usuario cuando mueve el dispositivo mientras el escaneo está activo
    func showAlertToUser(show: Bool){
        if show {
            print("Device moved")
            UIView.animate(withDuration: 0.3) {
                self.AlertSteady.isHidden = false
            }
            scanningPauseBecauseDeviceMoved = true
        } else {
            print("Steady Alert just dissapear")
            UIView.animate(withDuration: 0.3) {
                self.AlertSteady.isHidden = true
            }
            scanningPauseBecauseDeviceMoved = false
            restoreVariables()
        }
    }
    
    //Esta es la función principal encargada de detectar si se da un rayo o no.
    func detectIfRayIsShown(luminosity: Double, buffer: CMSampleBuffer){
        
        //Con el valor de mínima luminosidad, se normalizan todos los valores
        let normalizedLuminosity = max(luminosity + oldMinBrightness, 0)
        let normalizedReferenceLuminosity = max(referenceLuminosity ?? 0 + oldMinBrightness, 0)

        //Aqui se detecta si tras un rayo la luz a vuelto a su luminosidad original o no
        if scanningPauseBetweenPhotoGap {
            if normalizedLuminosity > (normalizedReferenceLuminosity - normalizedReferenceLuminosity * 0.1 ) && (normalizedLuminosity < normalizedReferenceLuminosity + normalizedReferenceLuminosity * 0.1) {
                scanningPauseBetweenPhotoGap = false
                print("La iluminación se ha restablecido")
            } else {
                return
            }
        }
        
        if lastValue == nil{
            self.lastValue = luminosity
            print("Inicializó lastValue la primera vez o tras cambios")
        }
        
        let normalizedLastValue = max(lastValue + oldMinBrightness, 0)
        
        //Este porcentaje determina la sensibilidad a la que se detectan los rayos
        let porcentajeAumentoLuminosidad = getSensibility()
        
        if normalizedLuminosity > normalizedLastValue + normalizedLastValue * porcentajeAumentoLuminosidad {

            referenceLuminosity = luminosity
        
            print("Inicializo valor de refencia al detectar rayo en \(referenceLuminosity + oldMinBrightness)")
            
            scanningPauseBetweenPhotoGap = true
            setControlLuminosityTimer(active: true)
            photoTaken(luminosityWhenDetected: luminosity)
            
        }
        self.lastValue = luminosity
    }
 
    
}
// MARK: - Extension encargada de gestionar las fotos realizadas
extension PhotoViewController: AVCapturePhotoCaptureDelegate{
    //Esta función es llamada una vez la foto es tomada, y llama a otra función del gestor del album para guardarla
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard error == nil else {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        //Aqui compruebo que la imagen resultante tenga una luminosidad similar al momento exacto donde se ha detectado el rayo
        //Pasa cierto tiempo , muy poco pero suficiente para perder un rayo en algunos casos, entre que la detección se realiza y la foto finalmente se procesa. Esto puede resultar en que el rayo ya no esté visible cuando la foto está procesada
        //Para evitar en la medida de lo posible fotos en negro, se realiza la siguiente comprobación
        if let luminosidadInicial = referenceLuminosity {
            let luminosidadInicialNormalizada = luminosidadInicial + oldMinBrightness
            let luminosidadFinal = calcularLuminosidad(capturedImage: photo) + oldMinBrightness
       
            if luminosidadFinal >= luminosidadInicialNormalizada {
                print("Rayo detectado y guardado...")
                self.saveAndSetPhoto(imageData: imageData)
            }
        }
        scanningPauseWhenIsTakingPhoto = false
    }
    
    // En este método guardo finalmente la imagen tomada haciendo uso de mi clase destinada a gestionar las fotos
    func saveAndSetPhoto(imageData: Data){
        
        let stillImage = UIImage(data: imageData)
        customAlbumManager.save(photo: stillImage!, toAlbum: customAlbumManager.photoAlbumName) { (success, error) in
            if success{
                OperationQueue.main.addOperation {
                    self.rayCapturedNumber += 1
                    self.showAlertView()
                }
            }
        }
    }
    
}
// MARK: - options view over

extension PhotoViewController {
    //En este método inicializo los valores por defecto de las opciones de ajustes. Si están guardados en preferences inicializo con los guardados
    //Sino, guardo los que hay por defecto en preferences
    func setInitialExposureValues(){
        let preferences = UserDefaults.standard
        if let defaultIso = ListOfCameraOptions.shared.defaultISOoption, let defaultExposure = ListOfCameraOptions.shared.defaultExposureOption {
   
            if let ISOId = preferences.value(forKey: isoKey) as? Int {
                ListOfCameraOptions.shared.defaultISOoption = ListOfCameraOptions.shared.ISOoptions.first(where: {$0.id == ISOId})
            } else {
                preferences.set(defaultIso.id, forKey: isoKey)
            }
            if let exposureId = preferences.value(forKey: exposureKey) as? Int {
                ListOfCameraOptions.shared.defaultExposureOption = ListOfCameraOptions.shared.ExposureOptions.first(where: {$0.id == exposureId})
            } else {
                preferences.set(defaultExposure.id, forKey: exposureKey)
            }
            if let sensibilityValue = preferences.value(forKey: sensibilityKey) as? Int {
                sensibilitySlider.value = Float(sensibilityValue)
            } else {
                preferences.set(ListOfCameraOptions.shared.initialSensibilityOption, forKey: sensibilityKey)
            }
        }
    }
    
    //Aquí compruebo cuales de las opciones de iso y exposición definidas son compatibles con la cámara del dispositivo.
    //En un principio el rango especificado es bastante común y todos los dispositivos deberían poder hacer uso de todas las opciones
    func initializeOptionsMenu(device: AVCaptureDevice){
    
        for iso in ListOfCameraOptions.shared.ISOoptions {
            if iso.option > device.activeFormat.minISO && iso.option < device.activeFormat.maxISO {
                supportedISO.append(iso)
            }
        }
        for exposure in ListOfCameraOptions.shared.ExposureOptions {
            if exposure.option > device.activeFormat.minExposureDuration && exposure.option < device.activeFormat.maxExposureDuration {
                supportedExposure.append(exposure)
            }
        }
        
        DispatchQueue.main.async {
            self.isoStackView.subviews.forEach({$0.removeFromSuperview()})
            self.exposureStackView.subviews.forEach({$0.removeFromSuperview()})
            
            self.isoSlider.maximumValue = Float(self.supportedISO.count - 1)
            self.isoSlider.minimumValue = 0
            self.exposureSlider.maximumValue = Float(self.supportedExposure.count - 1)
            self.exposureSlider.minimumValue = 0
            
            for (index,iso) in self.supportedISO.enumerated() {
                let label = UILabel()
                label.font = UIFont(name: "Comfortaa-Regular", size: 12)
                label.minimumScaleFactor = 0.5
                label.text = "\(Int(iso.option))"
                self.isoStackView.addArrangedSubview(label)
                if iso.id == ListOfCameraOptions.shared.defaultISOoption?.id {
                    self.isoSlider.value = Float(index)
                }
            }
            
            for (index,exposure) in self.supportedExposure.enumerated(){
                let label = UILabel()
                label.font = UIFont(name: "Comfortaa-Regular", size: 12)
                label.minimumScaleFactor = 0.5
                label.text = exposure.name
                self.exposureStackView.addArrangedSubview(label)
                if exposure.id == ListOfCameraOptions.shared.defaultExposureOption?.id {
                    self.exposureSlider.value = Float(index)
                }
            }
       
        }
   
    }
 
    //Esta función es llamada cuando el usuario utiliza el botón de restaurar opciones a opciones por defecto
    func restoreValues(){
        let initialIso = ListOfCameraOptions.shared.initialISOoption
        let initialExposure = ListOfCameraOptions.shared.initialExposureOption
        let initialSensibility = ListOfCameraOptions.shared.initialSensibilityOption
        if let isoSupported = supportedISO.firstIndex(where: {$0.id == initialIso?.id}){
            isoSlider.value = Float(isoSupported)
            setNewIso(value: isoSupported)
        } else {
            isoSlider.value = 0
            setNewIso(value: 0)
        }
        if let exposureSupporte = supportedExposure.firstIndex(where: {$0.id == initialExposure?.id}) {
            exposureSlider.value = Float(exposureSupporte)
            setNewExposure(value: exposureSupporte)
        } else {
            exposureSlider.value = 0
            setNewExposure(value: 0)
        }
        sensibilitySlider.value = Float(initialSensibility)
        setNewSensibility(value: initialSensibility)
    }
    
    // MARK: - métodos set
    //Los siguientes métodos cambian el valor de alguno de los ajustes al valor especificado por el usuario
    
    func setNewSensibility(value: Int){
        if !captureSession.isRunning {
            return
        }
        
        let preferences = UserDefaults.standard
        preferences.set(value, forKey: sensibilityKey)
    
    }
    
    func getSensibility() -> Double{
        let sensibility = ListOfCameraOptions.shared.SensitibilityOptions[Int(sensibilitySlider.value)]
        return sensibility
    }
    
    func setNewIso(value: Int){
        if !captureSession.isRunning{
            return
        }
        
        let newValue = supportedISO[value]
        
        guard let captureDevice = captureDeviceRef else { return }
   
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isExposureModeSupported(.custom){
                
                captureDevice.setExposureModeCustom(duration: captureDevice.exposureDuration, iso: newValue.option) { (time) in
                    let preferences = UserDefaults.standard
                    preferences.set(newValue.id, forKey: self.isoKey)
                }
            }
            
        } catch {
            print("Error")
            DispatchQueue.main.async {
                let alertaError = UIAlertController(title: "Error", message: "Error setting ISO", preferredStyle: .alert)
                alertaError.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alertaError, animated: true, completion: nil)
            }
        }
        captureDevice.unlockForConfiguration()
    }
    
    func setNewExposure(value: Int){
        if !captureSession.isRunning{
            return
        }
        
        let newValue = supportedExposure[value]
        
        guard let captureDevice = captureDeviceRef else { return }
     
        do {
            try captureDevice.lockForConfiguration()
            if captureDevice.isExposureModeSupported(.custom){
              
                captureDevice.setExposureModeCustom(duration: newValue.option, iso: captureDevice.iso) { (time) in
                  let preferences = UserDefaults.standard
                  
                  preferences.set(newValue.id, forKey: self.exposureKey)
                }
            }
        } catch {
            print("Error")
            DispatchQueue.main.async {
                let alertaError = UIAlertController(title: "Error", message: "Error setting Exposure time", preferredStyle: .alert)
                alertaError.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alertaError, animated: true, completion: nil)
            }
        }
        captureDevice.unlockForConfiguration()
    }
    
    //En este método se gestiona cuando se debe mostrar o ocultar la ventana de ajustes
    func showOptionsView(show: Bool){
        if show {
            settingsWindowOpen = true
            scanButton.isEnabled = false
            self.optionsViewHeightContraint.constant = CGFloat(self.optionsViewShowHeight)
            UIView.animate(withDuration: 0.3) {
                self.view.layoutIfNeeded()
            }
        } else {
            scanButton.isEnabled = true
            self.optionsViewHeightContraint.constant = 0
            UIView.animate(withDuration: 0.15) {
                self.view.layoutIfNeeded()
            }
            settingsWindowOpen = false
        }
    }
}
