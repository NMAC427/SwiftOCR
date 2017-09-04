//
//  SettingsPresenter.swift
//  SwiftOCRCamera
//
//  Created by Serhii Londar on 5/22/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation

class SettingsPresenter {
    var view: SettingsViewController
    var router: SettingsRouter
    
    init(view: SettingsViewController, router: SettingsRouter) {
        self.view = view
        self.router = router
    }
    
    func viewDidLoad() {
        self.view.updateUI()
    }
    
    func updateFrequency(_ value: Float) {
        SettingsManager.shared.frequency = value
        self.view.updateUI()
    }
    
    func updateArMode(_ value: Bool) {
        SettingsManager.shared.arOn = value
        self.view.updateUI()
    }
    
    func frequencyButtonPressed() {
        self.view.showAlert()
    }
    func closeButtonPressed() {
        self.router.close()
    }
}
