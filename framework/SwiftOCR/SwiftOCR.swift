//
//  SwiftOCR.swift
//  SwiftOCR
//
//  Created by Nicolas Camenisch on 18.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

import CoreGraphics

import GPUImage

#if os(iOS)
    public typealias OCRImage = UIImage
#else
    public typealias OCRImage = NSImage
#endif

internal var recognizableCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

internal var globalNetwork = FFNN.fromFile(NSBundle(forClass: SwiftOCR.self).URLForResource("OCR-Network", withExtension: nil, subdirectory: nil, localization: nil)!) ?? FFNN(inputs: 321, hidden: 100, outputs: recognizableCharacters.characters.count, learningRate: 0.7, momentum: 0.4, weights: nil, activationFunction: .Sigmoid, errorFunction: .CrossEntropy(average: false))

public class SwiftOCR {
    
    ///The image used for OCR
    public var image:OCRImage?

    private  let network = globalNetwork.copy()
    
    public   var delegate:SwiftOCRDelegate?
    public   var currentOCRRecognizedBlobs = [SwiftOCRRecognizedBlob]()
    
    public   init(){}
    
    /**
     
     Performs ocr on `SwiftOCR().image`.
     
     - Parameter completionHandler: The completion handler that gets invoked after the ocr is finished.
     
     */
    
    public   func recognize(completionHandler: (String) -> Void){
        
        let confidenceThreshold:Float = 0.1 //Confidence must be bigger than the threshold
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            if let imageToRecognize = self.image {
                
                var preprocessedImage = OCRImage()
                
                if let preprocessFunc = self.delegate?.preprocessImageForOCR, let processedImage = preprocessFunc(imageToRecognize){
                    preprocessedImage = processedImage
                } else {
                    preprocessedImage = self.preprocessImageForOCR(self.image)!
                }
                
                let blobs                  = self.extractBlobs(preprocessedImage)
                var recognizedString       = ""
                var ocrRecognizedBlobArray = [SwiftOCRRecognizedBlob]()
                
                for blob in blobs {
                    
                    do {
                        let blobData       = self.convertImageToFloatArray(blob.0, resize: true)
                        let networkResult  = try self.network.update(inputs: blobData)
                        
                        if networkResult.maxElement() >= confidenceThreshold {
                            let recognizedChar = Array(recognizableCharacters.characters)[networkResult.indexOf(networkResult.maxElement() ?? 0) ?? 0]
                            recognizedString.append(recognizedChar)
                        }
                        
                        //Generate SwiftOCRRecognizedBlob
                        
                        var ocrRecognizedBlobCharactersWithConfidenceArray = [(character: Character, confidence: Float)]()
                        let ocrRecognizedBlobConfidenceThreshold = networkResult.reduce(0, combine: +)/Float(networkResult.count)
                        
                        for networkResultIndex in 0..<networkResult.count {
                            let characterConfidence = networkResult[networkResultIndex]
                            let character           = Array(recognizableCharacters.characters)[networkResultIndex]
                            
                            if characterConfidence >= ocrRecognizedBlobConfidenceThreshold {
                                ocrRecognizedBlobCharactersWithConfidenceArray.append((character: character, confidence: characterConfidence))
                            }
                            
                        }
                        
                        let currentRecognizedBlob = SwiftOCRRecognizedBlob(charactersWithConfidence: ocrRecognizedBlobCharactersWithConfidenceArray, boundingBox: blob.1)
                        
                        ocrRecognizedBlobArray.append(currentRecognizedBlob)
                        
                    } catch {
                        print(error)
                    }
                    
                }
                
                self.currentOCRRecognizedBlobs = ocrRecognizedBlobArray
                completionHandler(recognizedString)
                
            } else {
                print("You first have to set a SwiftOCR().image")
                completionHandler(String())
            }
        })
        
    }
    
    /**
     
     Extracts the characters using [Connected-component labeling](https://en.wikipedia.org/wiki/Connected-component_labeling).
     
     - Parameter image: The image which will be used for the connected-component labeling. If you pass in nil, the `SwiftOCR().image` will be used.
     - Returns:         An array containing the extracted and cropped Blobs and their bounding box.
     
     */
    
    internal func extractBlobs(image:OCRImage?) -> [(OCRImage, CGRect)] {
        if let inputImage = image ?? self.image {
            
            #if os(iOS)
                let pixelData = CGDataProviderCopyData(CGImageGetDataProvider(inputImage.CGImage))
                let bitmapData: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
                let cgImage   = inputImage.CGImage
            #else
                let bitmapRep = NSBitmapImageRep(data: inputImage.TIFFRepresentation!)!
                let bitmapData: UnsafeMutablePointer<UInt8> = bitmapRep.bitmapData
                let cgImage   = bitmapRep.CGImage
            #endif
            
            let numberOfComponents = CGImageGetBitsPerPixel(cgImage) / CGImageGetBitsPerComponent(cgImage)
            
            //data <- bitmapData
            
            let inputImageHeight = inputImage.size.height
            let inputImageWidth  = inputImage.size.width
            
            var data = [UInt16](count: (Int(inputImageWidth) * Int(inputImageHeight)) * numberOfComponents, repeatedValue: 0)
            
            for dataIndex in 0..<data.count {
                data[dataIndex] = UInt16(bitmapData[dataIndex])
            }
            
            //First Pass
            
            var currentLabel:UInt16 = 0 {
                didSet {
                    if currentLabel == 255 {
                        currentLabel = 256
                    }
                }
            }
            var labelsUnion = UnionFind<UInt16>()
            
            for y in 0..<Int(inputImageHeight) {
                for x in 0..<Int(inputImageWidth) {
                    let pixelInfo: Int = ((Int(inputImageWidth) * Int(y)) + Int(x)) * numberOfComponents
                    let pixelIndex:(Int, Int) -> Int = {x, y in
                        return ((Int(inputImageWidth) * Int(y)) + Int(x))  * numberOfComponents
                    }
                    
                    if data[pixelInfo] == 0 { //Is Black
                        if x == 0 { //Left no pixel
                            if y == 0 { //Top no pixel
                                currentLabel += 1
                                labelsUnion.addSetWith(currentLabel)
                                data[pixelInfo] = currentLabel
                            } else if y > 0 { //Top pixel
                                if data[pixelIndex(x, y-1)] != 255 { //Top Label
                                    data[pixelInfo] = data[pixelIndex(x, y-1)]
                                } else { //Top no Label
                                    currentLabel += 1
                                    labelsUnion.addSetWith(currentLabel)
                                    data[pixelInfo] = currentLabel
                                }
                            }
                        } else { //Left pixel
                            if y == 0 { //Top no pixel
                                if data[pixelIndex(x-1,y)] != 255 { //Left Label
                                    data[pixelInfo] = data[pixelIndex(x-1,y)]
                                } else { //Left no Label
                                    currentLabel += 1
                                    labelsUnion.addSetWith(currentLabel)
                                    data[pixelInfo] = currentLabel
                                }
                            } else if y > 0 { //Top pixel
                                if data[pixelIndex(x-1,y)] != 255 { //Left Label
                                    if data[pixelIndex(x,y-1)] != 255 { //Top Label
    
                                        if data[pixelIndex(x,y-1)] != data[pixelIndex(x-1,y)] {
                                            labelsUnion.unionSetsContaining(data[pixelIndex(x,y-1)], and: data[pixelIndex(x-1,y)])
                                        }
    
                                        data[pixelInfo] = data[pixelIndex(x,y-1)]
                                    } else { //Top no Label
                                        data[pixelInfo] = data[pixelIndex(x-1,y)]
                                    }
                                } else { //Left no Label
                                    if data[pixelIndex(x,y-1)] != 255 { //Top Label
                                        data[pixelInfo] = data[pixelIndex(x,y-1)]
                                    } else { //Top no Label
                                        currentLabel += 1
                                        labelsUnion.addSetWith(currentLabel)
                                        data[pixelInfo] = currentLabel
                                    }
                                }
                            }
                        }
                    }
                    
                }
            }
            
            //Second Pass
            
            let parentArray = Array(labelsUnion.parent.uniq())
            
            for y in 0..<Int(inputImageHeight) {
                for x in 0..<Int(inputImageWidth) {
                    let pixelInfo: Int = ((Int(inputImageWidth) * Int(y)) + Int(x)) * numberOfComponents
                    
                    if data[pixelInfo] != 255 {
                        data[pixelInfo] = UInt16(parentArray.indexOf(labelsUnion.setOf(data[pixelInfo]) ?? 0) ?? 0)
                    }
                    
                }
            }
            
            //Extract Images
            
            //Merge rects
            
            var mergeUnion = UnionFind<UInt16>()
            var mergeLabelRects = [CGRect]()
            
            let xMergeRadius:CGFloat = 1
            let yMergeRadius:CGFloat = 3
            
            for label in 0..<parentArray.count {
                var minX = Int(inputImageWidth)
                var maxX = 0
                var minY = Int(inputImageHeight)
                var maxY = 0
                
                for y in 0..<Int(inputImageHeight) {
                    for x in 0..<Int(inputImageWidth) {
                        let pixelInfo: Int = ((Int(inputImageWidth) * Int(y)) + Int(x)) * numberOfComponents
                        
                        if data[pixelInfo] == UInt16(label) {
                            minX = min(minX, x)
                            maxX = max(maxX, x)
                            minY = min(minY, y)
                            maxY = max(maxY, y)
                        }
                        
                    }
                }
                
                //Filter blobs
                
                let minMaxCorrect = (minX < maxX && minY < maxY)
                let correctFormat:Bool = {
                    if (maxY - minY) != 0 {
                        return Double(maxX - minX)/Double(maxY - minY) < 1.6
                    } else {
                        return false
                    }
                }()
                
                let notToTall    = Double(maxY - minY) < Double(inputImage.size.height) * 0.75
                let notToWide    = Double(maxX - minX) < Double(inputImage.size.width ) * 0.25
                let notToShort   = Double(maxY - minY) > Double(inputImage.size.height) * 0.25
                let notToThin    = Double(maxX - minX) > Double(inputImage.size.width ) * 0.01
                
                let notToSmall   = (maxX - minX)*(maxY - minY) > 100
                
                let positionIsOK = minY != 0 && minX != 0 && maxY != Int(inputImageHeight - 1) && maxX != Int(inputImageWidth - 1)
                
                if minMaxCorrect && correctFormat && notToTall && notToWide && notToShort && notToThin && notToSmall && positionIsOK{
                    let labelRect = CGRectMake(CGFloat(CGFloat(minX) - xMergeRadius), CGFloat(CGFloat(minY) - yMergeRadius), CGFloat(CGFloat(maxX - minX) + 2*xMergeRadius + 1), CGFloat(CGFloat(maxY - minY) + 2*yMergeRadius + 1))
                    mergeUnion.addSetWith(UInt16(label))
                    mergeLabelRects.append(labelRect)
                }
            }
            
            for rectOneIndex in 0..<mergeLabelRects.count {
                for rectTwoIndex in 0..<mergeLabelRects.count {
                    if mergeLabelRects[rectOneIndex].intersects(mergeLabelRects[rectTwoIndex]) && rectOneIndex != rectTwoIndex{
                        mergeUnion.unionSetsContaining(UInt16(rectOneIndex), and: UInt16(rectTwoIndex))
                        mergeLabelRects[rectOneIndex].unionInPlace(mergeLabelRects[rectTwoIndex])
                    }
                }
            }
            
            var outputImages = [(OCRImage, CGRect)]()
            
            mergeLabelRects.uniqInPlace()
            
            //Extract images
            
            for rect in mergeLabelRects {
                let cropRect = rect.insetBy(dx: CGFloat(xMergeRadius), dy: CGFloat(yMergeRadius))
                
                if let croppedCGImage = CGImageCreateWithImageInRect(cgImage, cropRect) {
                    
                    #if os(iOS)
                        let croppedImage = UIImage(CGImage: croppedCGImage)
                    #else
                        let croppedImage = NSImage(CGImage: croppedCGImage, size: cropRect.size)
                    #endif
                    
                    outputImages.append((croppedImage, cropRect))
                }
            }
            
            outputImages.sortInPlace({return $0.0.1.origin.x < $0.1.1.origin.x})
            return outputImages
        } else {
            return []
        }
    }
    
    /**
     
     Takes an array of images and then resized them to **16x20px**. This is the standard size for the input for the neural network.
     
     - Parameter blobImages: The array of images that should get resized.
     - Returns:              An array containing the resized images.
     
     */
    
    internal func resizeBlobs(blobImages: [OCRImage]) -> [OCRImage] {
        
        var resizedBlobs = [OCRImage]()
        
        for blobImage in blobImages {
            let cropSize = CGSizeMake(16, 20)
            
            //Downscale
            #if os(iOS)
                let cgImage   = blobImage.CGImage
            #else
                let bitmapRep = NSBitmapImageRep(data: blobImage.TIFFRepresentation!)!
                let cgImage   = bitmapRep.CGImage
            #endif
            
            let width = cropSize.width
            let height = cropSize.height
            let bitsPerComponent = 8
            let bytesPerRow = 0
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.NoneSkipLast.rawValue
            
            let context = CGBitmapContextCreate(nil, Int(width), Int(height), bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
            
            CGContextSetInterpolationQuality(context, CGInterpolationQuality.None)
            
            CGContextDrawImage(context, CGRectMake(0, 0, cropSize.width, cropSize.height), cgImage)
            
            let resizedCGImage = CGImageCreateWithImageInRect(CGBitmapContextCreateImage(context), CGRectMake(0, 0, cropSize.width, cropSize.height))!
            
            #if os(iOS)
                let resizedOCRImage = UIImage(CGImage: resizedCGImage)
            #else
                let resizedOCRImage = NSImage(CGImage: resizedCGImage, size: cropSize)
            #endif
            
            resizedBlobs.append(resizedOCRImage)
        }
        
        return resizedBlobs
        
    }
    
    /**
     
     Uses the default preprocessing algorithm to binarize the image. It uses the [GPUImage framework](https://github.com/BradLarson/GPUImage).
     
     - Parameter image: The image which should be binarized. If you pass in nil, the `SwiftOCR().image` will be used.
     - Returns:         The binarized image.
     
     */
    
    public func preprocessImageForOCR(image:OCRImage?) -> OCRImage? {
        
        func getDodgeBlendImage(inputImage: OCRImage) -> OCRImage {
            let image = GPUImagePicture(image: inputImage)
            let image2 = GPUImagePicture(image: inputImage)
            
            //Img 1
            
            let grayFilter = GPUImageGrayscaleFilter()
            image.addTarget(grayFilter)
            
            let invertFilter = GPUImageColorInvertFilter()
            grayFilter.addTarget(invertFilter)
            
            let blurFilter = GPUImageGaussianBlurFilter()
            blurFilter.blurRadiusInPixels = 10
            invertFilter.addTarget(blurFilter)
            
            let opacityFilter = GPUImageOpacityFilter()
            opacityFilter.opacity = 0.93
            blurFilter.addTarget(opacityFilter)
            
            opacityFilter.useNextFrameForImageCapture()
            
            //Img 2
            
            let grayFilter2 = GPUImageGrayscaleFilter()
            image2.addTarget(grayFilter2)
            
            grayFilter2.useNextFrameForImageCapture()
            
            //Blend
            
            let dodgeBlendFilter = GPUImageColorDodgeBlendFilter()
            
            grayFilter2.addTarget(dodgeBlendFilter)
            image2.processImage()
            
            opacityFilter.addTarget(dodgeBlendFilter)
            
            dodgeBlendFilter.useNextFrameForImageCapture()
            image.processImage()
            
            var processedImage:OCRImage? = dodgeBlendFilter.imageFromCurrentFramebufferWithOrientation(UIImageOrientation.Up)
            
            while processedImage?.size == CGSize.zero {
                dodgeBlendFilter.useNextFrameForImageCapture()
                image.processImage()
                processedImage = dodgeBlendFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            }
            
            return processedImage!
        }
        
        if let image = image ?? self.image {
            let dodgeBlendImage        = getDodgeBlendImage(image)
            let picture                = GPUImagePicture(image: dodgeBlendImage)
            
            let medianFilter           = GPUImageMedianFilter()
            
            let openingFilter          = GPUImageOpeningFilter()
            
            let biliteralFilter        = GPUImageBilateralFilter()
            biliteralFilter.texelSpacingMultiplier      = 0.8
            biliteralFilter.distanceNormalizationFactor = 1.6
            
            let firstBrightnessFilter  = GPUImageBrightnessFilter()
            firstBrightnessFilter.brightness            = -0.28
            
            let contrastFilter         = GPUImageContrastFilter()
            contrastFilter.contrast                     = 2.35
            
            let secondBrightnessFilter = GPUImageBrightnessFilter()
            secondBrightnessFilter.brightness           = -0.08
            
            let thresholdFilter        = GPUImageLuminanceThresholdFilter()
            thresholdFilter.threshold                   = 0.5
            
            picture               .addTarget(medianFilter)
            medianFilter          .addTarget(openingFilter)
            openingFilter         .addTarget(biliteralFilter)
            biliteralFilter       .addTarget(firstBrightnessFilter)
            firstBrightnessFilter .addTarget(contrastFilter)
            contrastFilter        .addTarget(secondBrightnessFilter)
            secondBrightnessFilter.addTarget(thresholdFilter)
            
            thresholdFilter.useNextFrameForImageCapture()
            picture.processImage()
            
            var processedImage:OCRImage? = thresholdFilter.imageFromCurrentFramebufferWithOrientation(UIImageOrientation.Up)
            
            while processedImage?.size == CGSize.zero {
                thresholdFilter.useNextFrameForImageCapture()
                picture.processImage()
                processedImage = thresholdFilter.imageFromCurrentFramebufferWithOrientation(.Up)
            }
            
            return processedImage!
        } else {
            return nil
        }
        
    }
    
    /**
     
     Takes an image and converts it to an array of floats. The array gets generated by taking the pixel-data of the red channel and then converting it into floats. This array can be used as input for the neural network.
     
     - Parameter image:  The image which should get converted to the float array.
     - Parameter resize: If you set this to true, the image firsts gets resized. The default value is `true`.
     - Returns:          The array containing the pixel-data of the red channel.
     
     */
    
    internal func convertImageToFloatArray(image: OCRImage, resize: Bool = true) -> [Float] {
        
        let resizedBlob: OCRImage = {
            if resize {
                return resizeBlobs([image]).first!
            } else {
                return image
            }
        }()
        
        #if os(iOS)
            let pixelData  = CGDataProviderCopyData(CGImageGetDataProvider(resizedBlob.CGImage))
            let bitmapData: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            let cgImage    = resizedBlob.CGImage
        #else
            let bitmapRep  = NSBitmapImageRep(data: resizedBlob.TIFFRepresentation!)!
            let bitmapData = bitmapRep.bitmapData
            let cgImage    = bitmapRep.CGImage
        #endif
        
        let numberOfComponents = CGImageGetBitsPerPixel(cgImage) / CGImageGetBitsPerComponent(cgImage)
        
        var imageData = [Float]()
        
        for y in 0..<Int(resizedBlob.size.height) {
            for x in 0..<Int(resizedBlob.size.width) {
                let pixelInfo: Int = ((Int(resizedBlob.size.width) * Int(y)) + Int(x)) * numberOfComponents
                imageData.append(Float(bitmapData[pixelInfo])/255)
            }
        }
        
        let aspectRatio = Float(image.size.width / image.size.height)
        
        imageData.append(aspectRatio)
        
        return imageData
    }
    
}

@objc public protocol SwiftOCRDelegate {
    
    #if os(iOS)
    
    /**
     
     Implement this method for a custom image preprocessing algorithm. Only return a binary image.
     
     - Parameter inputImage: The image to preprocess.
     - Returns:              The preprocessed, binarized image that SwiftOCR should use for OCR. If you return nil SwiftOCR will use its default preprocessing algorithm.
     
     */
    
    optional func preprocessImageForOCR(inputImage: UIImage) -> UIImage?
    
    #else
    
    /**
     
     Implement this method for a custom image preprocessing algorithm. Only return a binary image.
     
     - Parameter inputImage: The image to preprocess.
     - Returns:              The preprocessed, binarized image that SwiftOCR should use for OCR. If you return nil SwiftOCR will use its standard preprocessing algorithm.
     
     */
    
    
    optional func preprocessImageForOCR(inputImage: NSImage) -> NSImage?
    
    #endif
}

public struct SwiftOCRRecognizedBlob {
    
    let charactersWithConfidence: [(character: Character, confidence: Float)]!
    let boundingBox:              CGRect!
    
    init(charactersWithConfidence: [(character: Character, confidence: Float)]!, boundingBox: CGRect) {
        self.charactersWithConfidence = charactersWithConfidence.sort({return $0.0.confidence > $0.1.confidence})
        self.boundingBox = boundingBox
    }
    
}
