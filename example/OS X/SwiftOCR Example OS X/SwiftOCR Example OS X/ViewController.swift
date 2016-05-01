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

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func imageDidChange(sender: NSImageView) {
        helperLabel.textColor = NSColor.clearColor()
        inputImage = sender.image
        ocr()
    }

    func ocr() {
        self.swiftOCRInstance.image = self.inputImage
        self.swiftOCRInstance.recognize({recognizedString in
            dispatch_async(dispatch_get_main_queue(), {
                self.recognizedLabel.title = recognizedString
            })
        })
    }


}

