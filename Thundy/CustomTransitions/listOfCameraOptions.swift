//
//  listOfCameraOptions.swift
//  Thundy
//
//  Created by Pau Enrech on 24/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class ListOfCameraOptions {
    
    static let shared = ListOfCameraOptions()
    
    let initialISOoption: ISOoption?
    let initialExposureOption: ExposureOption?
    let initialSensibilityOption = 1
    
    let isoKey = "isoKey"
    let exposureKey =  "exposureKey"
    let sensibilityKey = "sensibilityKey"
    
    var defaultISOoption: ISOoption? = nil
    var defaultExposureOption: ExposureOption? = nil
    
    var ISOoptions: [ISOoption] = [ISOoption(id: 0, option: 50),
                                   ISOoption(id: 1, option: 100),
                                   ISOoption(id: 2, option: 200),
                                   ISOoption(id: 3, option: 300),
                                   ISOoption(id: 4, option: 400),
                                   ISOoption(id: 5, option: 500),
                                   ISOoption(id: 6, option: 600),
                                   ISOoption(id: 7, option: 700),
                                   ISOoption(id: 8, option: 800)]
    
    var ExposureOptions: [ExposureOption] = [ExposureOption(id: 0, option: CMTime(value: 1, timescale: 10), name: "1/10"),
                                             ExposureOption(id: 1, option: CMTime(value: 1, timescale: 50), name: "1/50"),
                                             ExposureOption(id: 2, option: CMTime(value: 1, timescale: 250), name: "1/250"),
                                             ExposureOption(id: 3, option: CMTime(value: 1, timescale: 500), name: "1/500"),
                                             ExposureOption(id: 4, option: CMTime(value: 1, timescale: 800), name: "1/800"),
                                             ExposureOption(id: 5, option: CMTime(value: 1, timescale: 1000), name: "1/1000")]
    
    var SensitibilityOptions : [Double] = [0.4, 0.25, 0.1]
    
    init() {
        defaultISOoption = ISOoptions[2]
        defaultExposureOption = ExposureOptions[2]
        initialISOoption = ISOoptions[2]
        initialExposureOption = ExposureOptions[2]
    }

    class ISOoption {
        var id: Int
        var option: Float
        
        init(id: Int, option: Float) {
            self.id = id
            self.option = option
        }
    }
    
    class ExposureOption {
        var id: Int
        var option: CMTime
        var name: String
        
        init(id: Int, option: CMTime, name: String) {
            self.id = id
            self.option = option
            self.name = name
        }
    }
}
