//
//  ViewController.swift
//  SwiftOCR Camera
//
//  Created by Nicolas Camenisch on 04.05.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import UIKit
import SwiftOCR
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var viewFinder: UIView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var label: UILabel!
    
    var stillImageOutput: AVCaptureStillImageOutput!
    let captureSession = AVCaptureSession()
    let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            if(self.device != nil){
                self.beginSession()
            }
        })
        
    }
    
    // MARK: AVFoundation
    
    func beginSession() {
        
        self.stillImageOutput = AVCaptureStillImageOutput()
        
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone && max(UIScreen.mainScreen().bounds.size.width, UIScreen.mainScreen().bounds.size.height) < 568.0 {
            self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        } else {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        }
        
        self.captureSession.addOutput(self.stillImageOutput)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), {
            
            do{
                self.captureSession.addInput(try AVCaptureDeviceInput(device: self.device))
            } catch {
                print("AVCaptureDeviceInput Error")
            }
            
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
            previewLayer?.frame.size = self.cameraView.frame.size
            previewLayer?.frame.origin = CGPoint.zero
            previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            
            do {
                try self.device.lockForConfiguration()
                
                self.device.focusPointOfInterest = CGPointMake(0.5, 0.5)
                self.device.focusMode = .ContinuousAutoFocus
                
                self.device.unlockForConfiguration()
                
            } catch {
                print("captureDevice?.lockForConfiguration() denied")
            }
            
            //Set initial Zoom scale
            
            do {
                let device = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
                try device.lockForConfiguration()
                
                let zoomScale:CGFloat = 2.5
                
                if zoomScale <= device.activeFormat.videoMaxZoomFactor {
                    device.videoZoomFactor = zoomScale
                }
                
                device.unlockForConfiguration()
                
            } catch {
                print("captureDevice?.lockForConfiguration() denied")
            }
            
            
            dispatch_async(dispatch_get_main_queue(), {
                self.cameraView.layer.addSublayer(previewLayer)
                self.captureSession.startRunning()
            })
        })
        
    }
    
    @IBAction func takePhotoButtonPressed(sender: UIButton) {
        self.stillImageOutput.captureStillImageAsynchronouslyFromConnection(self.stillImageOutput.connectionWithMediaType(AVMediaTypeVideo)) { (buffer:CMSampleBuffer!, error:NSError!) -> Void in
            
            guard let buffer = buffer, imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), let image = UIImage(data: imageData) else {
                return
            }
            
            let croppedImage = self.cropImage(image)
            
            let ocrInstance = SwiftOCR()
            ocrInstance.image = croppedImage
            ocrInstance.recognize() { recognizedString in
                self.label.text = recognizedString
            }
            
        }
    }
    
    @IBAction func sliderValueDidChange(sender: UISlider) {
        do {
            try device!.lockForConfiguration()
            var zoomScale = CGFloat(slider.value * 10.0)
            
            if zoomScale < 1 {
                zoomScale = 1
            } else if zoomScale > device.activeFormat.videoMaxZoomFactor {
                zoomScale = device.activeFormat.videoMaxZoomFactor
            }
            
            device.videoZoomFactor = zoomScale
            device.unlockForConfiguration()
            
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
    }
    
    // MARK: Image Processing
    
    func cropImage(image: UIImage) -> UIImage {
        
        let cropSize = CGSizeMake(400, 110)
        
        //Downscale
        
        let cgImage = image.CGImage!
        
        let width = cropSize.width
        let height = image.size.height / image.size.width * cropSize.width
        
        let bitsPerComponent = 8
        let bytesPerRow = 0
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.NoneSkipLast.rawValue
        
        let context = CGBitmapContextCreate(nil, Int(width), Int(height), bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        
        CGContextSetInterpolationQuality(context, CGInterpolationQuality.None)
        
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), cgImage)
        
        
        let scaledCGImage = CGImageCreateWithImageInRect(CGBitmapContextCreateImage(context), CGRectMake(0, CGFloat((height - cropSize.height)/2.0), cropSize.width, cropSize.height))
        
        return UIImage(CGImage: scaledCGImage!)
        
    }
    
}

