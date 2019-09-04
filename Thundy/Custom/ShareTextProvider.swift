//
//  ShareTextProvider.swift
//  Thundy
//
//  Created by Pau Enrech on 04/09/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

class ShareTextProvider: NSObject, UIActivityItemSource {
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return NSObject()
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        if activityType == .postToTwitter || activityType == .postToFacebook {
            return "#Thundy"
        }
        return nil
    }
}
