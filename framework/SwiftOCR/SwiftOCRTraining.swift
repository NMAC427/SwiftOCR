//
//  SwiftOCRTraining.swift
//  SwiftOCR
//
//  Created by Nicolas Camenisch on 19.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import GPUImage

public class SwiftOCRTraining {
    
    public  var shouldStopTraining = false
    
    private let ocrInstance        = SwiftOCR()
    
    //Training Variables
    private let trainingImageNames = ["TrainingBackground_1.png", "TrainingBackground_2.png", "TrainingBackground_3.png", "TrainingBackground_4.png"]
    private let trainingFontNames  = ["Arial Narrow", "Arial Narrow Bold"]

    public  init() {}
    
    /**
     Generates a training set for the neural network and uses that for training the neural network.
     */
    
    public  func trainWithCharSet() {
        let numberOfTrainImages  = 500
        let numberOfTestImages   = 100
        let errorThreshold:Float = 2
        
        let trainData = generateRealisticCharSet(numberOfTrainImages/4)
        let testData  = generateRealisticCharSet(numberOfTestImages/4)
        
        let trainInputs  = trainData.map({return $0.0})
        let trainAnswers = trainData.map({return $0.1})
        let testInputs   =  testData.map({return $0.0})
        let testAnswers  =  testData.map({return $0.1})
        
        print(globalNetwork.getWeights().reduce(0, combine: +))
        
        do {
            try globalNetwork.train(inputs: trainInputs, answers: trainAnswers, testInputs: testInputs, testAnswers: testAnswers, errorThreshold: errorThreshold, shouldContinue: {_ in return !self.shouldStopTraining})
            saveOCR()
        } catch {
            print(error)
        }
        
        print(globalNetwork.getWeights().reduce(0, combine: +))
        
    }
    
    /**
     Generates realistic images OCR and converts them to a float array.
     
     - Parameter size: The number of images to generate. This does **not** correspond to the the count of elements in the array that gets returned.
     - Returns:        An array containing the input and answers for the neural network.
     */
    
    private func generateRealisticCharSet(size: Int) -> [([Float],[Float])] {
        
        var trainingSet = [([Float],[Float])]()
        
        let randomCode: () -> String = {
            let randomCharacter: () -> String = {
                let charArray = Array(recognizableCharacters.characters)
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
        
        //Font
        
        let randomFontName: () -> String = {
            let randomDouble = Double(arc4random())/(Double(UINT32_MAX) + 1)
            let randomIndex  = Int(floor(randomDouble * Double(self.trainingFontNames.count)))
            return self.trainingFontNames[randomIndex]
        }
        
        let randomFont: () -> OCRFont = {
            return OCRFont(name: randomFontName(), size: 45 + randomFloat(5))!
        }
    
        let randomFontAttributes: () -> [String:NSObject] = {
            let paragraphStyle = NSParagraphStyle.defaultParagraphStyle().mutableCopy() as! NSMutableParagraphStyle
            paragraphStyle.alignment = NSTextAlignment.Center
            
            return [NSFontAttributeName: randomFont(),
                    NSKernAttributeName: CGFloat(8),
                    NSForegroundColorAttributeName: OCRColor(red: 27/255 + randomFloat(0.2), green: 16/255 + randomFloat(0.2), blue: 16/255 + randomFloat(0.2), alpha: 80/100 + randomFloat(0.2)),
                    NSParagraphStyleAttributeName: paragraphStyle]
        }
        
        //Image
        
        let randomImageName: () -> String = {
            let randomDouble = Double(arc4random())/(Double(UINT32_MAX) + 1)
            let randomIndex  = Int(floor(randomDouble * Double(self.trainingImageNames.count)))
            return self.trainingImageNames[randomIndex]
        }
        
        let randomImage: () -> OCRImage = {
            #if os(iOS)
                return OCRImage(named: randomImageName(), inBundle: NSBundle(forClass: SwiftOCR.self), compatibleWithTraitCollection: nil)!.copy() as! OCRImage
            #else
                return OCRImage(byReferencingURL: NSBundle(forClass: SwiftOCR.self).URLForResource(randomImageName(), withExtension: nil, subdirectory: nil, localization: nil)!).copy() as! OCRImage
            #endif
        }
        
        #if os(iOS)
            let customImage: (String) -> OCRImage = { code in
                let randomImg = randomImage()
                
                UIGraphicsBeginImageContext(randomImg.size)
                randomImg.drawInRect(CGRect(origin: CGPoint.zero, size: randomImg.size))
                
                NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -15.5 + randomFloat(5)), size: randomImg.size), withAttributes: randomFontAttributes())
                
                let customImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return customImage
            }
        #else
            let customImage: (String) -> OCRImage = { code in
                let randomImg = randomImage()
                randomImg.lockFocus()
                
                randomImg.drawInRect(CGRect(origin: CGPoint.zero, size: randomImg.size))
                
                NSString(string: code).drawInRect(CGRect(origin: CGPointMake(0 + randomFloat(5), -15.5 + randomFloat(5)), size: randomImg.size), withAttributes: randomFontAttributes())
                
                randomImg.unlockFocus()

                return randomImg
            }
        #endif

        
        
        
        for _ in 0..<size {

            let code               = randomCode()
            let currentCustomImage = customImage(code)
            
            //Distort Image
            
            let transformImage  = GPUImagePicture(image: currentCustomImage)
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
            
            var transformedImage:OCRImage? = transformFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            
            while transformedImage?.size == CGSize.zero {
                transformFilter.useNextFrameForImageCapture()
                transformImage.processImage()
                transformedImage = transformFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            }
            
            let distortedImage = ocrInstance.preprocessImageForOCR(transformedImage)
            
            //Generate Training set
            
            let blobs = ocrInstance.extractBlobs(distortedImage)
            
            if blobs.count == 6 {
                
                for blobIndex in 0..<blobs.count {
                    
                    let blob = blobs[blobIndex]
                    
                    let imageData = ocrInstance.convertImageToFloatArray(blob.0)
                    
                    var imageAnswer = [Float](count: recognizableCharacters.characters.count, repeatedValue: 0)
                    if let index = Array(recognizableCharacters.characters).indexOf(Array(code.characters)[blobIndex]) {
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
    
    public   func saveOCR() {
        //Set this path to the location of your OCR-Network file.
        let path = NSString(string:"~/Desktop/OCR-Network").stringByExpandingTildeInPath
        globalNetwork.writeToFile(NSURL(string: "file://\(path)")!)
    }
    
    /**
     Use this method to test the neural network.
     */
    
    public   func testOCR(completionHandler: (Double) -> Void) {
        let testData  = generateRealisticCharSet(25)
        
        var correctCount = 0
        var totalCount   = 0
        
        for i in testData {
            totalCount += 1
            do {
                let networkResult = try globalNetwork.update(inputs: i.0)
                
                let input      = Array(recognizableCharacters.characters)[i.1.indexOf(1)!]
                let recognized = Array(recognizableCharacters.characters)[networkResult.indexOf(networkResult.maxElement() ?? 0) ?? 0]
                
                print(input, recognized)
                
                if input == recognized {
                    correctCount += 1
                }
                
            } catch {
                
            }
        }
        
        completionHandler(Double(correctCount) / Double(totalCount))
        
    }
    
}