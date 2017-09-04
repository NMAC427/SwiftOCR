//
//  MainPresenter.swift
//  SwiftOCRCamera
//
//  Created by Serhii Londar on 5/22/17.
//  Copyright © 2017 Nicolas Camenisch. All rights reserved.
//

import Foundation
import SwiftOCR
import AVFoundation

class MainPresenter {
    var view: MainViewController?
    var router: MainRouter?
    
    
    init(view: MainViewController, router: MainRouter) {
        self.view = view
        self.router = router
    }
    
    var stillImageOutput: AVCaptureStillImageOutput!
    let captureSession = AVCaptureSession()
    let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    let ocrInstance = SwiftOCR()
    
    var timer: Timer?
    var working = false
    
    func startTimer() {
        self.stopTimer()
        self.timer = Timer.scheduledTimer(timeInterval: TimeInterval(SettingsManager.shared.frequency), target: self, selector: #selector(scanImage), userInfo: nil, repeats: true)
    }
    
    func stopTimer() {
        if self.timer != nil {
            self.timer?.invalidate()
            self.timer = nil
        }
    }
    
    func viewDidLoad() {
        DispatchQueue.global(qos: .userInitiated).async {
            if self.device != nil {
                self.configureCameraForUse()
            }
        }
    }
    
    func viewWillDisappear(_ animated: Bool) {
        self.stopTimer()
    }
    
    func takePhoto() {
        if SettingsManager.shared.frequency > 0 {
            if working {
                working = false
                self.stopTimer()
            } else {
                working = true
                self.startTimer()
            }
        } else {
            self.scanImage()
        }
    }
    
    func openSettings() {
        self.router?.openSettings()
    }
    
    @objc func scanImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            let capturedType = self.stillImageOutput.connection(withMediaType: AVMediaTypeVideo)
            self.stillImageOutput.captureStillImageAsynchronously(from: capturedType) { [weak self] buffer, error -> Void in
                if buffer != nil {
                    let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(buffer)
                    let image = UIImage(data: imageData!)
                    
                    let croppedImage = self?.prepareImageForCrop(using: image!)
                    self?.ocrInstance.recognize(croppedImage!) { [weak self] recognizedString, rect in
                        DispatchQueue.main.async {
                            do {
                                let result = try Expression(recognizedString).evaluate()
                                
                                self?.view?.updateLabelWithResult(recognizedString, result: result, rect: rect)
                            } catch {
                                self?.view?.updateLabelWithError("\(error)")
                            }
                        }
                    }
                } else {
                    return
                }
            }
        }
    }
    
    func sliderValueDidChange(_ value: CGFloat) {
        do {
            try device!.lockForConfiguration()
            var zoomScale = value
            let zoomFactor = device?.activeFormat.videoMaxZoomFactor
            
            if zoomScale < 1 {
                zoomScale = 1
            } else if zoomScale > zoomFactor! {
                zoomScale = zoomFactor!
            }
            
            device?.videoZoomFactor = zoomScale
            device?.unlockForConfiguration()
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
    }
    
    func configureCameraForUse () {
        self.stillImageOutput = AVCaptureStillImageOutput()
        let fullResolution = UIDevice.current.userInterfaceIdiom == .phone && max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height) < 568.0
        
        if fullResolution {
            self.captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        } else {
            self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720
        }
        
        self.captureSession.addOutput(self.stillImageOutput)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.prepareCaptureSession()
        }
    }
    
    func prepareCaptureSession () {
        do {
            self.captureSession.addInput(try AVCaptureDeviceInput(device: self.device))
        } catch {
            print("AVCaptureDeviceInput Error")
        }
        
        // layer customization
        let previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        previewLayer?.frame.size = (self.view?.cameraView.frame.size)!
        previewLayer?.frame.origin = CGPoint.zero
        previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        // device lock is important to grab data correctly from image
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
            
            let zoomScale: CGFloat = 2.5
            
            if zoomScale <= (device?.activeFormat.videoMaxZoomFactor)! {
                device?.videoZoomFactor = zoomScale
            }
            
            device?.unlockForConfiguration()
        } catch {
            print("captureDevice?.lockForConfiguration() denied")
        }
        
        DispatchQueue.main.async(execute: {
            self.view?.cameraView.layer.addSublayer(previewLayer!)
            self.captureSession.startRunning()
        })
    }
    
    // MARK: Image Processing
    fileprivate func prepareImageForCrop (using image: UIImage) -> UIImage {
        let degreesToRadians: (CGFloat) -> CGFloat = {
            return $0 / 180.0 * CGFloat(M_PI)
        }
        
        let imageOrientation = image.imageOrientation
        let degree = image.detectOrientationDegree()
        let cropSize = CGSize(width: 400, height: 110)
        
        //Downscale
        let cgImage = image.cgImage!
        
        let width = cropSize.width
        let height = image.size.height / image.size.width * cropSize.width
        
        let bitsPerComponent = cgImage.bitsPerComponent
        let bytesPerRow = cgImage.bytesPerRow
        let colorSpace = cgImage.colorSpace
        let bitmapInfo = cgImage.bitmapInfo
        
        let context = CGContext(data: nil,
                                width: Int(width),
                                height: Int(height),
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace!,
                                bitmapInfo: bitmapInfo.rawValue)
        
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
        
        let calculatedFrame = CGRect(x: 0, y: CGFloat((height - cropSize.height)/2.0), width: cropSize.width, height: cropSize.height)
        let scaledCGImage = context?.makeImage()?.cropping(to: calculatedFrame)
        
        
        return UIImage(cgImage: scaledCGImage!)
    }
}
