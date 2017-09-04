//
//  NSImage+File.swift
//  SwiftOCR Training
//
//  Created by Serhii Londar on 5/9/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation
import Cocoa

extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation = tiffRepresentation, let bitmapImage = NSBitmapImageRep(data: tiffRepresentation) else { return nil }
        return bitmapImage.representation(using: .PNG, properties: [:])
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
