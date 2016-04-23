//
//  SwiftOCRTraining.swift
//  SwiftOCR
//
//  Created by Nicolas Camenisch on 19.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import GPUImage

public class SwiftOCRTraining {
    
    private let ocrInstance       = SwiftOCR()
    private let trainingFontNames = ["Arial Narrow", "Arial Narrow Bold"]
    
    public  init() {}
    
    /**
     Generates a training set for the neural network and uses that for training the neural network.
     */
    
    public  func trainWithCharSet() {
        let numberOfTrainImages  = 500
        let numberOfTestImages   = 100
        let errorThreshold:Float = 2
        
        while true {
            autoreleasepool({
                
                let trainData = generateRealisticCharSet(numberOfTrainImages/4)
                let testData  = generateRealisticCharSet(numberOfTestImages/4)
                
                let trainInputs  = trainData.map({return $0.0})
                let trainAnswers = trainData.map({return $0.1})
                let testInputs   =  testData.map({return $0.0})
                let testAnswers  =  testData.map({return $0.1})
                
                do {
                    try network.train(inputs: trainInputs, answers: trainAnswers, testInputs: testInputs, testAnswers: testAnswers, errorThreshold: errorThreshold)
                    saveOCR()
                } catch {
                    print(error)
                }
                
            })
        }
        
    }
    
    /**
     Generates realistic images OCR and converts them to a flot array.
     
     - Parameter size: The number of images to generate. This does **not** correspond to the the count of elements in the array that gets returned.
     - Returns:        An array containing the input and answers for the neural network.
     */
    
    private func generateRealisticCharSet(size: Int) -> [([Float],[Float])] {
        
        var trainingSet = [([Float],[Float])]()
        
        let randomCode: () -> String = {
            let randomCharacter: () -> String = {
                let charArray = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".characters)
                let randomDouble = Double(arc4random())/(Double(UINT32_MAX) + 1)
                let randomIndex  = Int(floor(randomDouble * Double(charArray.count)))
                return String(charArray[randomIndex])
            }
            
            var code = ""
            
            for _ in 0..<6 {
                code += randomCharacter()
            }
            
            return code
        }
        
        let randomFloat: (CGFloat) -> CGFloat = { modi in
            return  (0 - modi) + CGFloat(arc4random()) / CGFloat(UINT32_MAX) * (modi * 2)
        }
        
        let randomFontName: () -> String = {
            let randomDouble = Double(arc4random())/(Double(UINT32_MAX) + 1)
            let randomIndex  = Int(floor(randomDouble * Double(trainingFontNames.count)))
            return trainingFontNames[randomIndex]
        }
        
        
        for _ in 0..<size {
            #if os(iOS)
                var currentImage = UIImage()
            #else
                var currentImage = NSImage()
            #endif
            let code = randomCode()
            
            #if os(iOS)
                
                switch Int(floor(Double(arc4random()) / (Double(UINT32_MAX) + 1) * 4 )) {
                case 0:
                    let customImage = UIImage(named: "TrainingBackground_1.png", inBundle: NSBundle(forClass: SwiftOCR.self), compatibleWithTraitCollection: nil)!.copy() as! UIImage
                    UIGraphicsBeginImageContext(customImage.size)
                    customImage.drawInRect(CGRect(origin: CGPoint.zero, size: customImage.size))
                    
                    let trainingFont = UIFont(name: randomFontName(), size: 49.3 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSTextAlignment.Center
                    let attributes = [NSFontAttributeName: trainingFont,
                                      NSKernAttributeName: CGFloat(8),
                                      NSForegroundColorAttributeName: UIColor(red: 27/255 + randomFloat(0.1), green: 16/255 + randomFloat(0.1), blue: 16/255 + randomFloat(0.1), alpha: 80/100 + randomFloat(0.1)),
                                      NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -15.5 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    currentImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                case 1:
                    
                    let customImage = UIImage(named: "TrainingBackground_2.png", inBundle: NSBundle(forClass: SwiftOCR.self), compatibleWithTraitCollection: nil)!.copy() as! UIImage
                    UIGraphicsBeginImageContext(customImage.size)
                    customImage.drawInRect(CGRect(origin: CGPoint.zero, size: customImage.size))
                    
                    let trainingFont = UIFont(name: randomFontName(), size: 47.9 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSTextAlignment.Center
                    let attributes = [NSFontAttributeName: trainingFont,
                                      NSKernAttributeName: CGFloat(8),
                                      NSForegroundColorAttributeName: UIColor(red: 56/255 + randomFloat(0.1), green: 36/255 + randomFloat(0.1), blue: 36/255 + randomFloat(0.1), alpha: 97/100 + randomFloat(0.1)),
                                      NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -14.7 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    currentImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                case 2:
                    
                    let customImage = UIImage(named: "TrainingBackground_3.png", inBundle: NSBundle(forClass: SwiftOCR.self), compatibleWithTraitCollection: nil)!.copy() as! UIImage
                    UIGraphicsBeginImageContext(customImage.size)
                    customImage.drawInRect(CGRect(origin: CGPoint.zero, size: customImage.size))
                    
                    let trainingFont = UIFont(name: randomFontName(), size: 47.7 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSTextAlignment.Center
                    let attributes = [NSFontAttributeName: trainingFont, NSKernAttributeName: CGFloat(8), NSForegroundColorAttributeName: UIColor(red: 76/255 + randomFloat(0.1), green: 47/255 + randomFloat(0.1), blue: 36/255 + randomFloat(0.1), alpha: 90/100 + randomFloat(0.1)), NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -15.1 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    currentImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                case 3:
                    
                    let customImage = UIImage(named: "TrainingBackground_4.png", inBundle: NSBundle(forClass: SwiftOCR.self), compatibleWithTraitCollection: nil)!.copy() as! UIImage
                    UIGraphicsBeginImageContext(customImage.size)
                    customImage.drawInRect(CGRect(origin: CGPoint.zero, size: customImage.size))
                    
                    let trainingFont = UIFont(name: randomFontName(), size: 47.9 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSTextAlignment.Center
                    let attributes = [NSFontAttributeName: trainingFont,
                                      NSKernAttributeName: CGFloat(8),
                                      NSForegroundColorAttributeName: UIColor(red: 24/255 + randomFloat(0.05), green: 16/255 + randomFloat(0.05), blue: 16/255 + randomFloat(0.05), alpha: 80/100 + randomFloat(0.1)),
                                      NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -14.7 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    currentImage = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                default: break
                    
                }
                
                
            #else
                
                switch Int(floor(Double(arc4random()) / (Double(UINT32_MAX) + 1) * 4 )) {
                case 0:
                    let customImage = NSImage(byReferencingURL: NSBundle(forClass: SwiftOCR.self).URLForResource("TrainingBackground_1.png", withExtension: nil, subdirectory: nil, localization: nil)!).copy() as! NSImage
                    customImage.lockFocus()
                    
                    let trainingFont = NSFont(name: randomFontName(), size: 49.3 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSCenterTextAlignment
                    let attributes = [NSFontAttributeName: trainingFont,
                                      NSKernAttributeName: CGFloat(8),
                                      NSForegroundColorAttributeName :NSColor(calibratedRed: 27/255 + randomFloat(0.1), green: 16/255 + randomFloat(0.1), blue: 16/255 + randomFloat(0.1), alpha: 80/100 + randomFloat(0.1)),
                                      NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -15.5 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    customImage.unlockFocus()
                    currentImage = customImage
                    
                case 1:
                    
                    let customImage = NSImage(byReferencingURL: NSBundle(forClass: SwiftOCR.self).URLForResource("TrainingBackground_2.png", withExtension: nil, subdirectory: nil, localization: nil)!).copy() as! NSImage
                    customImage.lockFocus()
                    
                    let trainingFont = NSFont(name: randomFontName(), size: 47.9 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSCenterTextAlignment
                    let attributes = [NSFontAttributeName: trainingFont,
                                      NSKernAttributeName: CGFloat(8),
                                      NSForegroundColorAttributeName :NSColor(calibratedRed: 56/255 + randomFloat(0.1), green: 36/255 + randomFloat(0.1), blue: 36/255 + randomFloat(0.1), alpha: 97/100 + randomFloat(0.1)),
                                      NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -14.7 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    customImage.unlockFocus()
                    currentImage = customImage
                    
                case 2:
                    let customImage = NSImage(byReferencingURL: NSBundle(forClass: SwiftOCR.self).URLForResource("TrainingBackground_3.png", withExtension: nil, subdirectory: nil, localization: nil)!).copy() as! NSImage
                    customImage.lockFocus()
                    
                    let trainingFont = NSFont(name: randomFontName(), size: 47.7 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSCenterTextAlignment
                    let attributes = [NSFontAttributeName: trainingFont, NSKernAttributeName: CGFloat(8), NSForegroundColorAttributeName :NSColor(calibratedRed: 76/255 + randomFloat(0.1), green: 47/255 + randomFloat(0.1), blue: 36/255 + randomFloat(0.1), alpha: 90/100 + randomFloat(0.1)), NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -15.1 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    customImage.unlockFocus()
                    currentImage = customImage
                    
                case 3:
                    
                    let customImage = NSImage(byReferencingURL: NSBundle(forClass: SwiftOCR.self).URLForResource("TrainingBackground_4.png", withExtension: nil, subdirectory: nil, localization: nil)!).copy() as! NSImage
                    customImage.lockFocus()
                    
                    let trainingFont = NSFont(name: randomFontName(), size: 47.9 + randomFloat(2))!
                    
                    let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
                    paragraphStyle.alignment = NSCenterTextAlignment
                    let attributes = [NSFontAttributeName: trainingFont,
                                      NSKernAttributeName: CGFloat(8),
                                      NSForegroundColorAttributeName :NSColor(calibratedRed: 24/255 + randomFloat(0.05), green: 16/255 + randomFloat(0.05), blue: 16/255 + randomFloat(0.05), alpha: 80/100 + randomFloat(0.1)),
                                      NSParagraphStyleAttributeName: paragraphStyle]
                    
                    NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -14.7 + randomFloat(5)), size: customImage.size), withAttributes: attributes)
                    
                    customImage.unlockFocus()
                    currentImage = customImage
                    
                default: break
                    
                }
                
                
            #endif
            
            //Distort Image
            
            let transformImage = GPUImagePicture(image: currentImage)
            let transformFilter = GPUImageTransformFilter()
            
            var affineTransform = CGAffineTransform()
            
            affineTransform.a  = 1.05 + (       CGFloat(arc4random())/CGFloat(UINT32_MAX) * 0.1 )
            affineTransform.b  = 0    + (0.01 - CGFloat(arc4random())/CGFloat(UINT32_MAX) * 0.02)
            affineTransform.c  = 0    + (0.03 - CGFloat(arc4random())/CGFloat(UINT32_MAX) * 0.06)
            affineTransform.d  = 1.05 + (       CGFloat(arc4random())/CGFloat(UINT32_MAX) * 0.1 )
            
            transformFilter.affineTransform = affineTransform
            transformImage.addTarget(transformFilter)
            
            transformFilter.useNextFrameForImageCapture()
            transformImage.processImage()
            
            #if os(iOS)
                var transformedImage:UIImage? = transformFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            #else
                var transformedImage:NSImage? = transformFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            #endif
            
            while transformedImage?.size == CGSize.zero {
                transformFilter.useNextFrameForImageCapture()
                transformImage.processImage()
                transformedImage = transformFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            }
            
            let preprocessedImage = ocrInstance.preprocessImageForOCR(transformedImage)
            
            //Generate Training set
            
            let blobs = ocrInstance.extractBlobs(preprocessedImage)
            
            if blobs.count == 6 {
                
                for blobIndex in 0..<blobs.count {
                    
                    let blob = blobs[blobIndex]
                    
                    let imageData = ocrInstance.convertImageToFloatArray(blob.0)
                    
                    var imageAnswer = [Float](count: 36, repeatedValue: 0)
                    if let index = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".characters).indexOf(Array(code.characters)[blobIndex]) {
                        imageAnswer[index] = 1
                    }
                    
                    trainingSet.append((imageData,imageAnswer))
                }
                
            }
            
            
        }
        
        return trainingSet
    }
    
    /**
     Saves the neural network to a file.
     */
    
    private func saveOCR() {
        //Set this path to the location of your OCR-Network file.
        network.writeToFile(NSURL(string: "file://~/Desktop/ImageFilter/ImageFilter/OCR-Network")!)
    }
    
    /**
     Use this methode to test the neural network.
     */
    
    private func testOCR() {
        let testData  = generateRealisticCharSet(25)
        
        for i in testData {
            do {
                let networkResult = try network.update(inputs: i.0)
                
                print(Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".characters)[i.1.indexOf(1)!],
                      Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".characters)[networkResult.indexOf(networkResult.maxElement()!)!])
                
            } catch {
                
            }
        }
    }
    
}