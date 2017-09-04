//
//  Settings manager.swift
//  SwiftOCR
//
//  Created by Serhii Londar on 5/21/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation


class SettingsManager {
    static let shared = SettingsManager()
    
    let frequencyKey = "frequencyKey"
    let arOnKey = "arOnKey"
    
    var arOn: Bool {
        get {
            if let isArOn = UserDefaults.standard.value(forKey: arOnKey) {
                return isArOn as! Bool
            } else {
                self.arOn = false
                return self.arOn
            }
        }
        set(newValue){
            UserDefaults.standard.set(newValue, forKey: arOnKey)
            UserDefaults.standard.synchronize()
        }
    }
    var frequency: Float {
        get {
            if let frequencyValue = UserDefaults.standard.value(forKey: frequencyKey) {
                return frequencyValue as! Float
            } else {
                self.frequency = 1.0
                return self.frequency
            }
        }
        set(newValue){
            UserDefaults.standard.set(newValue, forKey: frequencyKey)
            UserDefaults.standard.synchronize()
        }
    }
}
