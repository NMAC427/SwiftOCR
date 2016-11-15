//
//  ViewController.swift
//  SwiftOCR Debug OS X
//
//  Created by Nicolas Camenisch on 24.05.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    //Image View

    @IBOutlet weak var mainImageView: NSImageView!
    @IBOutlet weak var secondImageView: NSImageView!
    @IBOutlet weak var thirdImageView: NSImageView!
    @IBOutlet weak var fourthImageView: NSImageView!
    
    //Text
    
    @IBOutlet weak var helperLabel: NSTextField!
    @IBOutlet weak var xMergeRadiusLabel: NSTextField!
    @IBOutlet weak var yMergeRadiusLabel: NSTextField!
    @IBOutlet weak var recognizedStringLabel: NSTextField!
    @IBOutlet var recognizedBlobsTextView: NSTextView!
    
    //Sliders
    
    @IBOutlet weak var xMergeRadiusSlider: NSSlider!
    @IBOutlet weak var yMergeRadiusSlider: NSSlider!
    
    //OCR
    
    var inputImage: NSImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        updateMergeRadiusLabels()
    }
    
    @IBAction func imageDidChange(_ sender: NSImageView) {
        helperLabel.isHidden = true
        inputImage = sender.image
        ocr()
    }

    @IBAction func sliderDidChange(_ sender: NSSlider) {
        updateMergeRadiusLabels()
    }
    
    func updateMergeRadiusLabels() {
        xMergeRadiusLabel.stringValue = "\(round(xMergeRadiusSlider.doubleValue*10)/10) px"
        yMergeRadiusLabel.stringValue = "\(round(yMergeRadiusSlider.doubleValue*10)/10) px"
        ocr()
    }
    
    func ocr() {
        guard let image = inputImage else {return}

        let ocrInstance = SwiftOCR()
        
        ocrInstance.xMergeRadius = CGFloat(xMergeRadiusSlider.floatValue)
        ocrInstance.yMergeRadius = CGFloat(yMergeRadiusSlider.floatValue)
        
        ocrInstance.recognize(image) {recognizedString in
            DispatchQueue.main.async {

                self.recognizedStringLabel.stringValue = recognizedString
                self.thirdImageView.image              = self.drawBoundingBoxesInImage(image: image, blobs: ocrInstance.currentOCRRecognizedBlobs)
                self.recognizedBlobsTextView.string    = ocrInstance.currentOCRRecognizedBlobs.description
            }
        }
        
        secondImageView.image = ocrInstance.preprocessImageForOCR(image)
        
    }
    
    func drawBoundingBoxesInImage(image: NSImage, blobs: [SwiftOCRRecognizedBlob]) -> NSImage {
        let image = image.copy() as! NSImage
        
        image.lockFocus()
        
        for blob in blobs {
            let rect     = blob.boundingBox
            let flipRect = CGRect(x:(rect?.origin.x)!, y:image.size.height - (rect?.origin.y)! - (rect?.size.height)!, width: (rect?.size.width)!, height: (rect?.size.height)!)
            let path     = NSBezierPath(rect: flipRect)
            
            NSColor.red.setStroke()
            
            path.lineWidth = 2
            path.stroke()
        }
        
        image.unlockFocus()
        
        return image
    }

}

