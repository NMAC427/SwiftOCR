//
//  MainRouter.swift
//  SwiftOCRCamera
//
//  Created by Serhii Londar on 5/22/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation
import UIKit

class MainRouter {
    var view: MainViewController
    
    init(view: MainViewController) {
        self.view = view
    }
    
    func openSettings() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let settingsVC = storyboard.instantiateViewController(withIdentifier: "SettingsViewController") as! SettingsViewController
        
        let router = SettingsRouter(view: settingsVC)
        settingsVC.presenter = SettingsPresenter(view: settingsVC, router: router)
        
        self.view.present(settingsVC, animated: true, completion: nil)
    }
}
