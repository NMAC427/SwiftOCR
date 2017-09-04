//
//  SettingsViewController.swift
//  SwiftOCRCamera
//
//  Created by Serhii Londar on 5/21/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    @IBOutlet var frequencyButton: UIButton!
    @IBOutlet var arSwitch: UISwitch!
    
    var presenter: SettingsPresenter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Settings"
        presenter?.viewDidLoad()
    }
    
    func updateUI() {
        if SettingsManager.shared.frequency > 0 {
            frequencyButton.setTitle("\(SettingsManager.shared.frequency) s", for: .normal)
        } else {
            frequencyButton.setTitle("Custom", for: .normal)
        }
        arSwitch.isOn = SettingsManager.shared.arOn
    }
    
    @IBAction func frequencyButtonPressed(_ sender: AnyObject) {
        presenter?.frequencyButtonPressed()
    }
    
    func showAlert() {
        let alert = UIAlertController(title: "Select frequency", message: "", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "1 s", style: .default, handler: { (action) in
            self.presenter?.updateFrequency(1.0)
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "2 s", style: .default, handler: { (action) in
            self.presenter?.updateFrequency(2.0)
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "3 s", style: .default, handler: { (action) in
            self.presenter?.updateFrequency(3.0)
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Custom", style: .default, handler: { (action) in
            self.presenter?.updateFrequency(0.0)
            alert.dismiss(animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            alert.dismiss(animated: true, completion: nil)
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @IBAction func arSwitchValueChanged(_ sender: AnyObject) {
        self.presenter?.updateArMode((sender as! UISwitch).isOn)
    }
    
    @IBAction func closeButtonPressed(_ sender: AnyObject) {
        self.presenter?.closeButtonPressed()
    }
}
