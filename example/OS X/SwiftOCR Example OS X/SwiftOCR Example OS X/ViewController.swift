//
//  ViewController.swift
//  SwiftOCR Example OS X
//
//  Created by Nicolas Camenisch on 23.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import Cocoa
import SwiftOCR

class ViewController: NSViewController {
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var recognizedLabel: NSTextFieldCell!
    @IBOutlet weak var helperLabel: NSTextFieldCell!
    
    var inputImage:NSImage?
    
    let swiftOCRInstance = SwiftOCR()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func imageDidChange(_ sender: NSImageView) {
        helperLabel.textColor = NSColor.clear
        inputImage = sender.image
        ocr()
    }
    
    func ocr() {
        
        guard let image = inputImage else {
            print("invalid image...")
            return
        }
        
        swiftOCRInstance.recognize(image, {recognizedString in
            DispatchQueue.main.async(execute: {
                self.recognizedLabel.title = recognizedString
            })
        })
    }
    
    
}

