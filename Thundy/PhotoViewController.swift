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
    
    let scanImage = UIImage(named: "scan")
    let pauseImage = UIImage(named: "pause")
    var scanning = false
    var lastValue: Double!
    let maxGapBetweenPeaks = 500
    let minGapBetweenPeaks = 50
    
    var referenceLuminosity: Double!
    var luminosityAverageOverTime : [Double] = []

    var steadyTimer: Timer!
    var controlLuxTimer: Timer!
    var scanningPauseBecauseDeviceMoved = false
    var scanningPauseBetweenPhotoGap = false
    var scanningPauseWhenIsTakingPhoto = false
    
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

    var stillImageOutput: AVCapturePhotoOutput?
    
    var shouldCloseViewController = false
    
    // MARK: - Outlets
    
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
    @IBAction func closePhotoViewController(_ sender: Any) {
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        if statusBarOrientation != .portrait {
            shouldCloseViewController = true
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        } else {
            dismiss(animated: true, completion: nil)
        }
        
    }
    
    // MARK: - view functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        customAlbumManager.getAlbum(title: customAlbumManager.photoAlbumName) { (album) in
            if let _ = album {
                OperationQueue.main.addOperation {
                    if !self.scanButton.isEnabled && self.captureSession.isRunning {
                        self.scanButton.isEnabled = true
                    }
                }
            } else {
                let alerta = UIAlertController(title: "Unspected Error", message: "Thundy can't load it's photo album and unspected error occur. Please, try start it again.", preferredStyle: .alert)
                alerta.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (alerta) in
                    self.dismiss(animated: true, completion: nil)
                }))
                }
            }
        
        scanButton.isEnabled = false
    }
    
    //Gestiono el cambio de portrait a landscape, desactivo las animaciones para evitar efectos extraños
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        UIView.setAnimationsEnabled(false)
       coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
            DispatchQueue.main.async(execute: {
                self?.updateVideoOrientation()
            })
            UIView.setAnimationsEnabled(true)
            if self!.shouldCloseViewController {
                self!.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    //Vuelvo a colocar el dispositivo en modo portrait
    override func viewWillDisappear(_ animated: Bool) {
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
        
        //Arrancamos la sesión
        do {
            //Convertimos el device (La camara) a un input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            stillImageOutput = AVCapturePhotoOutput()
            //Añadimos el input a la sesión
            captureSession.addInput(input)
            captureSession.addOutput(stillImageOutput!)
            
            captureSession.sessionPreset = .photo
         
            //Mostramos en el VideoPreviewLayer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            
            //Finalmente, empezamos a "Capturar"
            captureSession.startRunning()
            
            OperationQueue.main.addOperation {
                self.videoPreviewLayer?.frame = self.view.layer.frame
                self.view.layer.addSublayer(self.videoPreviewLayer!)
                
                //Colocamos los objetos encima
                self.view.bringSubviewToFront(self.scanButton)
                self.view.bringSubviewToFront(self.thunderCountLabel)
                self.view.bringSubviewToFront(self.thunderIcon)
                self.view.bringSubviewToFront(self.closeButton)
                self.view.bringSubviewToFront(self.photoAlertView)
                self.view.bringSubviewToFront(self.AlertSteady)
                
                if !self.scanButton.isEnabled && self.customAlbumManager.albumReference != nil {
                    self.scanButton.isEnabled = true
                }
                
            }
            
        } catch {
            print(error)
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
        print("##StatusBar Orientation: \(statusBarOrientation.rawValue)")
        let videoOrientation: AVCaptureVideoOrientation = statusBarOrientation.videoOrientation ?? .portrait
        
        if videoPreviewLayer.connection!.videoOrientation == videoOrientation {
            return
        }
        
        if let imageOutputConnection = stillImageOutput?.connection(with: AVMediaType.video) {
            imageOutputConnection.videoOrientation = videoOrientation
        }
        
        videoPreviewLayer.frame = view.bounds
        videoPreviewLayer.connection!.videoOrientation = videoOrientation
        print("##Orientacion video : \(videoPreviewLayer.connection?.videoOrientation.rawValue)")
        videoPreviewLayer.removeAllAnimations()
    }
    
   override var shouldAutorotate: Bool {
        return true
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation{
        return .slide
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
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
        //showAlertView()
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
    //Para ello podría hacerse con el valor de brillo o calculando la luminosidad
    //El valor de brillo incluye números negativos y es menos fiable, así que se ha decidido por la luminosidad
    //La luminosidad se puede calcular, básicamente, debido a que el dispositivo está continuamente recalculando su exposición variando su ISO.
    //Estos cambios de iso son el factor que hace que la luminosidad varie. Si el dispositivo no pudiera auto ajustar su exposición, este método no funcionaría
    //En caso de que eso ocurra no se configura la cámara y la app no puede funcionar correctamente, pero todos los iphone actuales pueden hacerlo.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let luminosity : Double = calcularLuminosidad(sampleBuffer: sampleBuffer)
        
        print("luminosidad: \(luminosity)")
    
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
        detectIfRayIsShown(luminosity: luminosity)
    
    }
    
    func calcularLuminosidad(sampleBuffer: CMSampleBuffer) -> Double{
        //Se extraen datos EXIF del buffer de datos
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
        
        let FNumber : Double = exifData?["FNumber"] as! Double
        let ExposureTime : Double = exifData?["ExposureTime"] as! Double
        let ISOSpeedRatingsArray = exifData!["ISOSpeedRatings"] as? NSArray
        let ISOSpeedRatings : Double = ISOSpeedRatingsArray![0] as! Double
        let CalibrationConstant : Double = 50
        
        let luminosity : Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings )
        return luminosity
    }
    
    func calcularLuminosidad(capturedImage: AVCapturePhoto) -> Double{
        
        let exifData = capturedImage.metadata["{Exif}"] as? NSMutableDictionary
        
        let FNumber : Double = exifData?["FNumber"] as! Double
        let ExposureTime : Double = exifData?["ExposureTime"] as! Double
        let ISOSpeedRatingsArray = exifData!["ISOSpeedRatings"] as? NSArray
        let ISOSpeedRatings : Double = ISOSpeedRatingsArray![0] as! Double
        let CalibrationConstant : Double = 50
        
        let luminosity : Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings )
        return luminosity
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
    func detectIfRayIsShown(luminosity: Double){

        //Aqui se detecta si tras un rayo la luz a vuelto a su luminosidad original o no
        if scanningPauseBetweenPhotoGap {
            if luminosity > (referenceLuminosity - referenceLuminosity * 0.1 ) && (luminosity < referenceLuminosity + referenceLuminosity * 0.1) {
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
        
        //Este porcentaje determina la sensibilidad a la que se detectan los rayos
        let porcentajeAumentoLuminosidad = 0.25

        if luminosity > lastValue + lastValue * porcentajeAumentoLuminosidad {
            //rayCapturedNumber += 1
            print("Rayo \(rayCapturedNumber))")
            referenceLuminosity = luminosity
            
            print("Inicializo valor de refencia al detectar rayo en \(referenceLuminosity)")
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
        //Pasa cierto tiempo entre que la detección se realiza y la foto finalmente se procesa. Esto puede resultar en que el rayo ya no esté visible
        //cuando la foto está procesada
        //Para evitar en la medida de lo posible fotos en negro, se realiza la siguiente comprobación
        if let luminosidadInicial = referenceLuminosity {
            let luminosidadFinal = calcularLuminosidad(capturedImage: photo)
            let luminosidadInicialMásConstante = luminosidadInicial + luminosidadInicial * 0.05
       
            if luminosidadFinal >= luminosidadInicialMásConstante {
                print("@@Luminosidad Inicial: \(luminosidadInicial)")
                print("@@Luminosidad Final: \(luminosidadFinal)")
                print("@@La foto tiene rayo")
                self.saveAndSetPhoto(imageData: imageData)
            }
        }
        scanningPauseWhenIsTakingPhoto = false
    }
    
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

