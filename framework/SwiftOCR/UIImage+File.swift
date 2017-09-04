//
//  UIImage+File.swift
//  SwiftOCR
//
//  Created by Serhii Londar on 5/21/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation


extension UIImage {
    var pngData: Data? {
        return UIImagePNGRepresentation(self)
    }
    
    
    func pngWrite(to url: URL, options: Data.WritingOptions = .atomic) -> Bool {
        do {
            try pngData?.write(to: url, options: options)
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
}
