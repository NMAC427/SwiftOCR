//
//  SettingsRouter.swift
//  SwiftOCRCamera
//
//  Created by Serhii Londar on 5/22/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation

class SettingsRouter {
    var view: SettingsViewController
    
    init(view: SettingsViewController) {
        self.view = view
    }
    
    func close() {
        self.view.dismiss(animated: true, completion: nil)
    }
}
