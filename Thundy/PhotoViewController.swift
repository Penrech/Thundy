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
    var scanningPauseCauseTakingPhoto = false
    
    var referenceAttitude: CMAttitude?
    
    var rayCapturedNumber = 0 {
        didSet{
            thunderCountLabel.text = "\(rayCapturedNumber)"
        }
    }
    
    var motionManager: CMMotionManager!
    
    var customAlbumManager: CustomPhotoAlbum = (UIApplication.shared.delegate as! AppDelegate).customPhotosManager
    
    //Variables
    var captureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var qrCodeFrameView: UIView?
    var captureOutput = AVCaptureVideoDataOutput()
    var captureDeviceRef: AVCaptureDevice?

    var stillImageOutput: AVCapturePhotoOutput?
    
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
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        motionManager = CMMotionManager()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.configureCamera()
        }
        
        thunderCountLabel.text = "\(rayCapturedNumber)"
    }
    
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        UIView.setAnimationsEnabled(false)
       coordinator.animate(alongsideTransition: nil, completion: { [weak self] (context) in
            DispatchQueue.main.async(execute: {
                self?.updateVideoOrientation()
            })
            UIView.setAnimationsEnabled(true)
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        stopScanning()
        AppDelegate.AppUtility.lockOrientation(UIInterfaceOrientationMask.portrait, andRotateTo: UIInterfaceOrientation.portrait)
    }
    
    
    func configureCamera(){
        //Obtenemos la cámara trasera para capturar video
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.back)
        
        guard let captureDevice = deviceDiscoverySession.devices.first else {
            return
        }
      
        var cmTime = CMTime(value: 1, timescale: 500)
        var iso = 50
        if cmTime < captureDevice.activeFormat.minExposureDuration {
            cmTime = captureDevice.activeFormat.minExposureDuration
        }
        if iso < captureDevice.activeFormat.minISO {
            iso = captureDevice.activeFormat.minISO
        }
        captureDeviceRef = captureDevice
        
        if captureDevice.isExposureModeSupported(.custom) {
            do {
                try captureDevice.lockForConfiguration()
                //self.configureAndStartSesion(captureDevice: captureDevice)
                captureDevice.setExposureModeCustom(duration: cmTime, iso: 50, completionHandler: nil)
                self.configureAndStartSesion(captureDevice: captureDevice)
            } catch {
                print("Error de configuración : \(error)")
            }
            captureDevice.unlockForConfiguration()
        } else {
            configureAndStartSesion(captureDevice: captureDevice)
        }
    
    }
    
    func configureAndStartSesion(captureDevice: AVCaptureDevice){
        //Arrancamos la sesión
        do {
            //Convertimos el device (La camara) a un input
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main )
            stillImageOutput = AVCapturePhotoOutput()
            //Añadimos el input a la sesión
            
            captureSession.addInput(input)
            captureSession.addOutput(stillImageOutput!)
            captureSession.addOutput(captureOutput)
            
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
    
    func changeConfigBeforeTakingPhoto(settings: AVCapturePhotoSettings, exposureFromDetection: Double, isoFromDetection: Double){
        
        var iso: Float = 50
        guard let captureDevice = captureDeviceRef else {
            return
        }
        
        if captureDevice.isExposureModeSupported(.custom) {
            do {
                self.scanningPauseCauseTakingPhoto = true
                try captureDevice.lockForConfiguration()
                let secondsOfExposure = (Double(iso) * exposureFromDetection) / isoFromDetection
                /*print("Valor superior: \((Double(iso) * exposureFromDetection))")
                print("Maxima iso: \(captureDevice.activeFormat.maxISO)")
                print("Minima iso: \(captureDevice.activeFormat.minISO)")
                print("Valor inferior: \(isoFromDetection)")*/
                var cmTime = CMTime(value: 10, timescale: 100)/*
                print("valor maxima exposicion \(captureDevice.activeFormat.maxExposureDuration.seconds)")
                print("Valor de segundos de exposicion: \(secondsOfExposure)")
                print("Valor de segundos segun cmtime: \(cmTime.seconds)")
                print("Valor de segundos minimos dispositivo: \(captureDevice.activeFormat.minExposureDuration.seconds)")*/
                if cmTime > captureDevice.activeFormat.maxExposureDuration {
                    cmTime = captureDevice.activeFormat.maxExposureDuration
                }
                if iso > captureDevice.activeFormat.maxISO {
                    iso = captureDevice.activeFormat.maxISO
                }
                //captureDevice.setExposureModeCustom(duration: AVCaptureDevice.currentExposureDuration, iso: 100, completionHandler: nil)
                captureDevice.setExposureModeCustom(duration: cmTime, iso: iso) { (time) in
                    self.stillImageOutput?.capturePhoto(with: settings, delegate: self)
                }
            } catch {
                print("Error de configuración : \(error)")
            }
        } else {
            stillImageOutput?.capturePhoto(with: settings, delegate: self)
        }

    }
    
    func changeConfigAfterTakingPhoto(){
        
        guard let captureDevice = captureDeviceRef else {
            return
        }
        do {
            try captureDevice.lockForConfiguration()
            captureDevice.exposureMode = .continuousAutoExposure
            self.scanningPauseCauseTakingPhoto = false
        } catch {
            print("Error de configuración : \(error)")
        }
        
        
    }
   
    
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
        
        videoPreviewLayer.frame = view.bounds
        videoPreviewLayer.connection!.videoOrientation = videoOrientation
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
    
    func startScanning(){
        scanning = true
        motionManager.startDeviceMotionUpdates()
        
        scanButton.setImage(pauseImage, for: .normal)
        print("Scanning...")
    }
    
    func stopScanning(){
        scanning = false
        motionManager.stopDeviceMotionUpdates()
        scanningPauseBecauseDeviceMoved = false
        scanningPauseBetweenPhotoGap = false
        showAlertToUser(show: false)
        
        setTimer(active: false)
        setControlLuminosityTimer(active: false)
        
        scanButton.setImage(scanImage, for: .normal)
        print("Stop scanning.")
    
    }
    
    func restoreVariables(){
        referenceLuminosity = nil
        referenceAttitude = nil
        lastValue = nil
    }
    
    func photoTaken(exposure: Double, iso: Double){
        let photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
        photoSettings.isAutoStillImageStabilizationEnabled = true
        photoSettings.isHighResolutionPhotoEnabled = true
        photoSettings.flashMode = .off
        
        stillImageOutput?.isHighResolutionCaptureEnabled = true
        changeConfigBeforeTakingPhoto(settings: photoSettings, exposureFromDetection: exposure, isoFromDetection: iso)
        
        
        showAlertView()
    }
    
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
extension PhotoViewController: AVCaptureMetadataOutputObjectsDelegate , AVCaptureVideoDataOutputSampleBufferDelegate{
   
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    
        if scanningPauseCauseTakingPhoto || scanningPauseBetweenPhotoGap || scanningPauseBecauseDeviceMoved || !scanning || deviceMoved(){
            return
        }
        
        //Retrieving EXIF data of camara frame buffer
        let rawMetadata = CMCopyDictionaryOfAttachments(allocator: nil, target: sampleBuffer, attachmentMode: CMAttachmentMode(kCMAttachmentMode_ShouldPropagate))
        let metadata = CFDictionaryCreateMutableCopy(nil, 0, rawMetadata) as NSMutableDictionary
        let exifData = metadata.value(forKey: "{Exif}") as? NSMutableDictionary
    
        let BrightnessValue: Double = exifData?["BrightnessValue"] as!Double

        print("Brillo: \(BrightnessValue)")
/*
        print("Exposición: \(ExposureTime)")
        print("IsoSpeedRatings: \(ISOSpeedRatings)")
        //Calculating the luminosity
        let luminosity : Double = (CalibrationConstant * FNumber * FNumber ) / ( ExposureTime * ISOSpeedRatings )
        print("Luminosidad: \(luminosity)")
        if scanningPauseBecauseDeviceMoved {
            return
        }
        
        if deviceMoved() {
            setTimer(active: true)
            return
        }
        
        detectIfRayIsShown(luminosity: luminosity, exposure: ExposureTime, iso: ISOSpeedRatings)
    */
    }
    
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
    
    
    func detectIfRayIsShown(luminosity: Double, exposure: Double, iso: Double){

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
        
        let porcentajeAumentoLuminosidad = 0.25

        if luminosity > lastValue + lastValue * porcentajeAumentoLuminosidad {
            rayCapturedNumber += 1
            print("Rayo \(rayCapturedNumber))")
            referenceLuminosity = lastValue
            
            print("Inicializo valor de refencia al detectar rayo en \(referenceLuminosity)")
            scanningPauseBetweenPhotoGap = true
            setControlLuminosityTimer(active: true)
            
            photoTaken(exposure: exposure, iso: iso)
            
        }
        
    }
 
    
}
extension PhotoViewController: AVCapturePhotoCaptureDelegate{
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil else {
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            return
        }
        
        let stillImage = UIImage(data: imageData)
        customAlbumManager.save(photo: stillImage!, toAlbum: customAlbumManager.photoAlbumName) { (success, error) in
            if !success{
                print("Error guardando foto")
            }
            self.changeConfigAfterTakingPhoto()
        }
    }
}
