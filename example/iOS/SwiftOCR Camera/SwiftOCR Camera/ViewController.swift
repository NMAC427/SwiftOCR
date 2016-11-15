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
    let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: {
            if(self.device != nil){
                self.beginSession()
            }
        })
        
    }
    
    // MARK: AVFoundation
    
    func beginSession() {
        
        self.stillImageOutput = AVCaptureStillImageOutput()
        
        if UIDevice.current.userInterfaceIdiom == .phone && max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) < 568.0 {
            self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        } else {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        }
        
        self.captureSession.addOutput(self.stillImageOutput)
        
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.high).async(execute: {
            
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
                try self.device?.lockForConfiguration()
                
                self.device?.focusPointOfInterest = CGPoint(x: 0.5, y: 0.5)
                self.device?.focusMode = .continuousAutoFocus
                
                self.device?.unlockForConfiguration()
                
            } catch {
                print("captureDevice?.lockForConfiguration() denied")
            }
            
            //Set initial Zoom scale
            
            do {
                let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
                try device?.lockForConfiguration()
                
                let zoomScale:CGFloat = 2.5
                
                if zoomScale <= (device?.activeFormat.videoMaxZoomFactor)! {
                    device?.videoZoomFactor = zoomScale
                }
                
                device?.unlockForConfiguration()
                
            } catch {
                print("captureDevice?.lockForConfiguration() denied")
            }
            
            
            DispatchQueue.main.async(execute: {
                self.cameraView.layer.addSublayer(previewLayer!)
                self.captureSession.startRunning()
            })
        })
        
    }
    
    @IBAction func takePhotoButtonPressed(_ sender: UIButton) {
        self.stillImageOutput.captureStillImageAsynchronously(from: self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo)) { buffer, error -> Void in
            
            guard let buffer = buffer, let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer), let image = UIImage(data: imageData) else {
                return
            }
            
            let croppedImage = self.cropImage(image)

            let ocrInstance = SwiftOCR()
            ocrInstance.recognize(croppedImage) { recognizedString in
                DispatchQueue.main.async(execute: {
                    self.label.text = recognizedString
                    print(ocrInstance.currentOCRRecognizedBlobs)
                })
            }
            
        }
    }
    
    @IBAction func sliderValueDidChange(_ sender: UISlider) {
        do {
            try device!.lockForConfiguration()
            var zoomScale = CGFloat(slider.value * 10.0)
            
            if zoomScale < 1 {
                zoomScale = 1
            } else if zoomScale > (device?.activeFormat.videoMaxZoomFactor)! {
                zoomScale = (device?.activeFormat.videoMaxZoomFactor)!
            }
            
            device?.videoZoomFactor = zoomScale
            device?.unlockForConfiguration()
            
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
    }
    
    // MARK: Image Processing
    
    func cropImage(_ image: UIImage) -> UIImage {
        
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        let imageOrientation = image.imageOrientation
        
        var degree:CGFloat
        
        switch imageOrientation {
        case .right, .rightMirrored:    degree = 90
        case .left, .leftMirrored:      degree = -90
        case .up, .upMirrored:          degree = 180
        case .down, .downMirrored:      degree = 0
        }
        
        let cropSize = CGSize(width: 400, height: 110)
        
        //Downscale
        
        let cgImage = image.cgImage!
        
        let width = cropSize.width
        let height = image.size.height / image.size.width * cropSize.width
        
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        let bitmapInfo = cgImage.bitmapInfo
        
        let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace!, bitmapInfo: bitmapInfo.rawValue)
        
        context!.interpolationQuality = CGInterpolationQuality.none
        
        // Rotate the image context
        context?.rotate(by: degreesToRadians(degree));
        
        // Now, draw the rotated/scaled image into the context
        context?.scaleBy(x: -1.0, y: -1.0)
        
        //Crop
        
        switch imageOrientation {
        case .right, .rightMirrored:
            context?.draw(cgImage, in: CGRect(x: -height, y: 0, width: height, height: width))
        case .left, .leftMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: -width, width: height, height: width))
        case .up, .upMirrored:
            context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        case .down, .downMirrored:
            context?.draw(cgImage, in: CGRect(x: -width, y: -height, width: width, height: height))
        }
        
        let scaledCGImage = context?.makeImage()?.cropping(to: CGRect(x: 0, y: CGFloat((height - cropSize.height)/2.0), width: cropSize.width, height: cropSize.height))
        
        return UIImage(cgImage: scaledCGImage!)
        
    }
    
}

