//
//  optionsTableViewCell.swift
//  Thundy
//
//  Created by Pau Enrech on 24/04/2019.
//  Copyright © 2019 Pau Enrech. All rights reserved.
//

import UIKit

class optionsTableViewCell: UITableViewCell {

    @IBOutlet weak var optionTitle: UILabel!
    @IBOutlet weak var optionSlider: UISlider!
    @IBOutlet weak var optionLabelsStackView: UIStackView!
    override func awakeFromNib() {
        super.awakeFromNib()
        optionSlider.addTarget(self, action: #selector(sliderValueChange(sender:)), for: .valueChanged)
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureOption(title: String, options: [ListOfCameraOptions.ISOoption]){
        optionTitle.text = title
        optionSlider.maximumValue = Float(options.count - 1)
        optionSlider.minimumValue = 0
        optionLabelsStackView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        for iso in options {
            let label = UILabel()
            label.text = "\(iso.option)"
            optionLabelsStackView.addSubview(label)
        }
        
    }
    
    func configureOption(title: String, options: [ListOfCameraOptions.ExposureOption]){
        optionTitle.text = title
        optionSlider.maximumValue = Float(options.count - 1)
        optionSlider.minimumValue = 0
        optionLabelsStackView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        for iso in options {
            let label = UILabel()
            label.text = "\(iso.option)"
            optionLabelsStackView.addSubview(label)
        }
    }
    
    @objc func sliderValueChange(sender: UISlider!){
        sender.value = round(sender.value)
    }

    
}

