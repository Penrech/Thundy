//
//  cameraSettingsViewController.swift
//  Thundy
//
//  Created by Pau Enrech on 03/05/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit
import AVFoundation

protocol cameraSettingsDelegate: class {
    func setNewSensibility(value: Int)
    func setNewIso(value: ListOfCameraOptions.ISOoption)
    func setNewExposure(value: ListOfCameraOptions.ExposureOption)
    func showSettings(show: Bool)
}

class cameraSettingsViewController: UIViewController {

    let isoKey = ListOfCameraOptions.shared.isoKey
    let exposureKey =  ListOfCameraOptions.shared.exposureKey
    let sensibilityKey = ListOfCameraOptions.shared.sensibilityKey
    
    var supportedISO : [ListOfCameraOptions.ISOoption] = []
    var supportedExposure: [ListOfCameraOptions.ExposureOption] = []
    
    weak var delegate: cameraSettingsDelegate?
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var isoSlider: UISlider!
    @IBOutlet weak var isoStackView: UIStackView!
    @IBOutlet weak var exposureSlider: UISlider!
    @IBOutlet weak var exposureStackView: UIStackView!
    @IBOutlet weak var sensibilitySlider: UISlider!
    @IBOutlet weak var closeSettings: UIButton!
    
    @IBAction func closeSettingsAction(_ sender: Any) {
        if let delegate = delegate {
            delegate.showSettings(show: false)
        }
    }
    @IBAction func restoreSettingsAction(_ sender: Any) {
        restoreValues()
    }
    @IBAction func isoOptionsChange(_ sender: Any) {
        isoSlider.value = round(self.isoSlider.value)
        if let delegate = delegate {
            let newValue = supportedISO[Int(isoSlider!.value)]
            delegate.setNewIso(value: newValue)
        }
    }
    @IBAction func exposureOptionsChange(_ sender: Any) {
        exposureSlider.value = round(self.exposureSlider.value)
        if let delegate = delegate {
            let newValue = supportedExposure[Int(exposureSlider!.value)]
            delegate.setNewExposure(value: newValue)
        }
    }
    @IBAction func sensibilityOptionsChange(_ sender: Any) {
        sensibilitySlider.value = round(self.sensibilitySlider.value)
        if let delegate = delegate {
            delegate.setNewSensibility(value: Int(sensibilitySlider!.value))
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
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
        guard let delegate = delegate,
            let initialIso = ListOfCameraOptions.shared.initialISOoption,
            let initialExposure = ListOfCameraOptions.shared.initialExposureOption else { return }
        
        let initialSensibility = ListOfCameraOptions.shared.initialSensibilityOption
        if let isoSupported = supportedISO.firstIndex(where: {$0.id == initialIso.id}){
            isoSlider.value = Float(isoSupported)
            let newISO = supportedISO[isoSupported]
            delegate.setNewIso(value: newISO)
        } else {
            isoSlider.value = 0
            delegate.setNewIso(value: supportedISO[0])
        }
        if let exposureSupporte = supportedExposure.firstIndex(where: {$0.id == initialExposure.id}) {
            exposureSlider.value = Float(exposureSupporte)
            let newExposure = supportedExposure[exposureSupporte]
            delegate.setNewExposure(value: newExposure)
        } else {
            exposureSlider.value = 0
            delegate.setNewExposure(value: supportedExposure[0])
        }
        sensibilitySlider.value = Float(initialSensibility)
        delegate.setNewSensibility(value: initialSensibility)
        
    }
    
    func getSensibility() -> Double{
        let sensibility = ListOfCameraOptions.shared.SensitibilityOptions[Int(sensibilitySlider.value)]
        return sensibility
    }
    
    func resetScrollFromTable(){
        scrollView.setContentOffset(CGPoint.zero, animated: true)
    }
    
    
}
