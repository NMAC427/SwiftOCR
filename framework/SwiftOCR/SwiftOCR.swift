//
//  SwiftOCR.swift
//  SwiftOCR
//
//  Created by Nicolas Camenisch on 18.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import GPUImage

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l >= r
    default:
        return !(lhs < rhs)
    }
}

///The characters the globalNetwork can recognize.
///It **must** be in the **same order** as the network got trained
public var recognizableCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
///The FFNN network used for OCR
public var globalNetwork = FFNN.fromFile(Bundle(for: SwiftOCR.self).url(forResource: "OCR-Network", withExtension: nil)!)!

open class SwiftOCR {
    
    fileprivate     var network = globalNetwork
    
    //MARK: Setup
    
    ///SwiftOCR's delegate
    open weak var delegate: SwiftOCRDelegate?
    
    ///Radius in x axis for merging blobs
    open      var xMergeRadius:CGFloat = 1
    ///Radius in y axis for merging blobs
    open      var yMergeRadius:CGFloat = 3
    
    ///Only recognize characters on White List
    open      var characterWhiteList: String? = nil
    ///Don't recognize characters on Black List
    open      var characterBlackList: String? = nil
    
    ///Confidence must be bigger than the threshold
    open      var confidenceThreshold:Float = 0.1
    
    //MARK: Recognition data
    
    ///All SwiftOCRRecognizedBlob from the last recognition
    open      var currentOCRRecognizedBlobs = [SwiftOCRRecognizedBlob]()
    
    
    //MARK: Init
    public   init(){}
    
    public   init(image: OCRImage, delegate: SwiftOCRDelegate?, _ completionHandler: @escaping (String) -> Void){
        self.delegate = delegate
        self.recognize(image, completionHandler)
    }
    
    /**
     
     Performs ocr on the image.
     
     - Parameter image:             The image used for OCR
     - Parameter completionHandler: The completion handler that gets invoked after the ocr is finished.
     
     */
    
    open   func recognize(_ image: OCRImage, _ completionHandler: @escaping (String) -> Void){
        
        func indexToCharacter(_ index: Int) -> Character {
            return Array(recognizableCharacters.characters)[index]
        }
        
        func checkWhiteAndBlackListForCharacter(_ character: Character) -> Bool {
            let whiteList =   characterWhiteList?.characters.contains(character) ?? true
            let blackList = !(characterBlackList?.characters.contains(character) ?? false)
            
            return whiteList && blackList
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let preprocessedImage      = self.delegate?.preprocessImageForOCR(image) ?? self.preprocessImageForOCR(image)
            
            let blobs                  = self.extractBlobs(preprocessedImage)
            var recognizedString       = ""
            var ocrRecognizedBlobArray = [SwiftOCRRecognizedBlob]()
            
            for blob in blobs {
                do {
                    let blobData       = self.convertImageToFloatArray(blob.0, resize: true)
                    let networkResult  = try self.network.update(inputs: blobData)
                    
                    //Generate Output Character
                    if networkResult.max() >= self.confidenceThreshold {
                       
                        /*
                         let recognizedChar = Array(recognizableCharacters.characters)[networkResult.indexOf(networkResult.maxElement() ?? 0) ?? 0]
                         recognizedString.append(recognizedChar)
                         */
                        
                        for (networkIndex, _) in networkResult.enumerated().sorted(by: {$0.0.element > $0.1.element}) {
                            let character = indexToCharacter(networkIndex)
                            
                            guard checkWhiteAndBlackListForCharacter(character) else {
                                continue
                            }
                            
                            recognizedString.append(character)
                            break
                        }
                    }
                    
                    //Generate SwiftOCRRecognizedBlob
                    
                    var ocrRecognizedBlobCharactersWithConfidenceArray = [(character: Character, confidence: Float)]()
                    let ocrRecognizedBlobConfidenceThreshold = networkResult.reduce(0, +)/Float(networkResult.count)
                    
                    for networkResultIndex in 0..<networkResult.count {
                        let characterConfidence = networkResult[networkResultIndex]
                        let character           = indexToCharacter(networkResultIndex)
                        
                        guard characterConfidence >= ocrRecognizedBlobConfidenceThreshold && checkWhiteAndBlackListForCharacter(character) else {
                            continue
                        }
                        
                        ocrRecognizedBlobCharactersWithConfidenceArray.append((character: character, confidence: characterConfidence))
                    }
                    
                    let currentRecognizedBlob = SwiftOCRRecognizedBlob(charactersWithConfidence: ocrRecognizedBlobCharactersWithConfidenceArray, boundingBox: blob.1)
                    
                    ocrRecognizedBlobArray.append(currentRecognizedBlob)
                    
                } catch {
                    print(error)
                }
                
            }
            
            self.currentOCRRecognizedBlobs = ocrRecognizedBlobArray
            completionHandler(recognizedString)
        }
    }
    
    /**
     
     Performs ocr on the image in a specified rect.
     
     - Parameter image:             The image used for OCR
     - Parameter rect:              The rect in which recognition should take place.
     - Parameter completionHandler: The completion handler that gets invoked after the ocr is finished.
     
     */
    
    open   func recognizeInRect(_ image: OCRImage, rect: CGRect, completionHandler: @escaping (String) -> Void){
        DispatchQueue.global(qos: .userInitiated).async {
            #if os(iOS)
                let cgImage        = image.cgImage
                let croppedCGImage = cgImage?.cropping(to: rect)!
                let croppedImage   = OCRImage(cgImage: croppedCGImage!)
            #else
                let cgImage        = image.cgImage(forProposedRect: nil, context: nil, hints: nil)!
                let croppedCGImage = cgImage.cropping(to: rect)!
                let croppedImage   = OCRImage(cgImage: croppedCGImage, size: rect.size)
            #endif
            
            self.recognize(croppedImage, completionHandler)
            
        }
    }
    
    /**
     
     Extracts the characters using [Connected-component labeling](https://en.wikipedia.org/wiki/Connected-component_labeling).
     
     - Parameter image: The image which will be used for the connected-component labeling. If you pass in nil, the `SwiftOCR().image` will be used.
     - Returns:         An array containing the extracted and cropped Blobs and their bounding box.
     
     */
    
    internal func extractBlobs(_ image: OCRImage) -> [(OCRImage, CGRect)] {
        
        #if os(iOS)
            let pixelData = image.cgImage?.dataProvider?.data
            let bitmapData: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            let cgImage   = image.cgImage
        #else
            let bitmapRep = NSBitmapImageRep(data: image.tiffRepresentation!)!
            let bitmapData: UnsafeMutablePointer<UInt8> = bitmapRep.bitmapData!
            let cgImage   = bitmapRep.cgImage
        #endif
        
        //data <- bitmapData
        
        let numberOfComponents = (cgImage?.bitsPerPixel)! / (cgImage?.bitsPerComponent)!
        let bytesPerRow        = cgImage?.bytesPerRow
        let imageHeight        = cgImage?.height
        let imageWidth         = bytesPerRow! / numberOfComponents
        
        var data = [[UInt16]](repeating: [UInt16](repeating: 0, count: Int(imageWidth)), count: Int(imageHeight!))
        
        let yBitmapDataIndexStride = Array(stride(from: 0, to: imageHeight!*bytesPerRow!, by: bytesPerRow!)).enumerated()
        let xBitmapDataIndexStride = Array(stride(from: 0, to: imageWidth*numberOfComponents, by: numberOfComponents)).enumerated()
        
        for (y, yBitmapDataIndex) in yBitmapDataIndexStride {
            for (x, xBitmapDataIndex) in xBitmapDataIndexStride {
                let bitmapDataIndex = yBitmapDataIndex + xBitmapDataIndex
                data[y][x] = bitmapData[bitmapDataIndex] < 127 ? 0 : 255
            }
        }
        
        //MARK: First Pass
        
        var currentLabel:UInt16 = 0 {
            didSet {
                if currentLabel == 255 {
                    currentLabel = 256
                }
            }
        }
        var labelsUnion = UnionFind<UInt16>()
        
        for y in 0..<Int(imageHeight!) {
            for x in 0..<Int(imageWidth) {
                
                if data[y][x] == 0 { //Is Black
                    if x == 0 { //Left no pixel
                        if y == 0 { //Top no pixel
                            currentLabel += 1
                            labelsUnion.addSetWith(currentLabel)
                            data[y][x] = currentLabel
                        } else if y > 0 { //Top pixel
                            if data[y - 1][x] != 255 { //Top Label
                                data[y][x] = data[y - 1][x]
                            } else { //Top no Label
                                currentLabel += 1
                                labelsUnion.addSetWith(currentLabel)
                                data[y][x] = currentLabel
                            }
                        }
                    } else { //Left pixel
                        if y == 0 { //Top no pixel
                            if data[y][x - 1] != 255 { //Left Label
                                data[y][x] = data[y][x - 1]
                            } else { //Left no Label
                                currentLabel += 1
                                labelsUnion.addSetWith(currentLabel)
                                data[y][x] = currentLabel
                            }
                        } else if y > 0 { //Top pixel
                            if data[y][x - 1] != 255 { //Left Label
                                if data[y - 1][x] != 255 { //Top Label
                                    
                                    if data[y - 1][x] != data[y][x - 1] {
                                        labelsUnion.unionSetsContaining(data[y - 1][x], and: data[y][x - 1])
                                    }
                                    
                                    data[y][x] = data[y - 1][x]
                                } else { //Top no Label
                                    data[y][x] = data[y][x - 1]
                                }
                            } else { //Left no Label
                                if data[y - 1][x] != 255 { //Top Label
                                    data[y][x] = data[y - 1][x]
                                } else { //Top no Label
                                    currentLabel += 1
                                    labelsUnion.addSetWith(currentLabel)
                                    data[y][x] = currentLabel
                                }
                            }
                        }
                    }
                }
                
            }
        }
        
        //MARK: Second Pass
        
        let parentArray = Array(Set(labelsUnion.parent))
        
        var labelUnionSetOfXArray = Dictionary<UInt16, Int>()
        
        for label in 0...currentLabel {
            if label != 255 {
                labelUnionSetOfXArray[label] = parentArray.index(of: labelsUnion.setOf(label) ?? 255)
            }
        }
        
        for y in 0..<Int(imageHeight!) {
            for x in 0..<Int(imageWidth) {
                
                let luminosity = data[y][x]
                
                if luminosity != 255 {
                    data[y][x] = UInt16(labelUnionSetOfXArray[luminosity] ?? 255)
                }
                
            }
        }
        
        //MARK: MinX, MaxX, MinY, MaxY
        
        var minMaxXYLabelDict = Dictionary<UInt16, (minX: Int, maxX: Int, minY: Int, maxY: Int)>()
        
        for label in 0..<parentArray.count {
            minMaxXYLabelDict[UInt16(label)] = (minX: Int(imageWidth), maxX: 0, minY: Int(imageHeight!), maxY: 0)
        }
        
        for y in 0..<Int(imageHeight!) {
            for x in 0..<Int(imageWidth) {
                
                let luminosity = data[y][x]
                
                if luminosity != 255 {
                    
                    var value = minMaxXYLabelDict[luminosity]!
                    
                    value.minX = min(value.minX, x)
                    value.maxX = max(value.maxX, x)
                    value.minY = min(value.minY, y)
                    value.maxY = max(value.maxY, y)
                    
                    minMaxXYLabelDict[luminosity] = value
                    
                }
                
            }
        }
        
        //MARK: Merge labels
        
        var mergeLabelRects = [CGRect]()
        
        for label in minMaxXYLabelDict.keys {
            let value = minMaxXYLabelDict[label]!
            
            let minX = value.minX
            let maxX = value.maxX
            let minY = value.minY
            let maxY = value.maxY
            
            //Filter blobs
            
            let minMaxCorrect = (minX < maxX && minY < maxY)
            
            let notToTall    = Double(maxY - minY) < Double(imageHeight!) * 0.75
            let notToWide    = Double(maxX - minX) < Double(imageWidth ) * 0.25
            let notToShort   = Double(maxY - minY) > Double(imageHeight!) * 0.08
            let notToThin    = Double(maxX - minX) > Double(imageWidth ) * 0.01
            
            let notToSmall   = (maxX - minX)*(maxY - minY) > 100
            let positionIsOK = minY != 0 && minX != 0 && maxY != Int(imageHeight! - 1) && maxX != Int(imageWidth - 1)
            let aspectRatio  = Double(maxX - minX) / Double(maxY - minY)
            
            if minMaxCorrect && notToTall && notToWide && notToShort && notToThin && notToSmall && positionIsOK &&
                aspectRatio < 1 {
                let labelRect = CGRect(x: CGFloat(CGFloat(minX) - xMergeRadius), y: CGFloat(CGFloat(minY) - yMergeRadius), width: CGFloat(CGFloat(maxX - minX) + 2*xMergeRadius + 1), height: CGFloat(CGFloat(maxY - minY) + 2*yMergeRadius + 1))
                mergeLabelRects.append(labelRect)
            } else if minMaxCorrect && notToTall && notToShort && notToThin && notToSmall && positionIsOK && aspectRatio <= 2.5 && aspectRatio >= 1 {
                
                // MARK: Connected components: Find thinnest part of connected components
                
                guard minX + 2 < maxX - 2 else {
                    continue
                }
                
                let transposedData = Array(data[minY...maxY].map({return $0[(minX + 2)...(maxX - 2)]})).transpose() // [y][x] -> [x][y]
                let reducedMaxIndexArray = transposedData.map({return $0.reduce(0, {return UInt32($0.0) + UInt32($0.1)})}) //Covert to UInt32 to prevent overflow
                let maxIndex = reducedMaxIndexArray.enumerated().max(by: {return $0.1 < $1.1})?.0 ?? 0
                
                
                let cutXPosition   = minX + 2 + maxIndex
                
                let firstLabelRect = CGRect(x: CGFloat(CGFloat(minX) - xMergeRadius), y: CGFloat(CGFloat(minY) - yMergeRadius), width: CGFloat(CGFloat(maxIndex) + 2 * xMergeRadius), height: CGFloat(CGFloat(maxY - minY) + 2 * yMergeRadius))
                
                let secondLabelRect = CGRect(x: CGFloat(CGFloat(cutXPosition) - xMergeRadius), y: CGFloat(CGFloat(minY) - yMergeRadius), width: CGFloat(CGFloat(Int(maxX - minX) - maxIndex) + 2 * xMergeRadius), height: CGFloat(CGFloat(maxY - minY) + 2 * yMergeRadius))
                
                if firstLabelRect.width >= 5 + (2 * xMergeRadius) && secondLabelRect.width >= 5 + (2 * xMergeRadius) {
                    mergeLabelRects.append(firstLabelRect)
                    mergeLabelRects.append(secondLabelRect)
                } else {
                    let labelRect = CGRect(x: CGFloat(CGFloat(minX) - xMergeRadius), y: CGFloat(CGFloat(minY) - yMergeRadius), width: CGFloat(CGFloat(maxX - minX) + 2*xMergeRadius + 1), height: CGFloat(CGFloat(maxY - minY) + 2*yMergeRadius + 1))
                    mergeLabelRects.append(labelRect)
                }
                
            }
            
        }
        
        //Merge rects
        
        var filteredMergeLabelRects = [CGRect]()
        
        for rect in mergeLabelRects {
            
            var intersectCount = 0
            
            for (filteredRectIndex, filteredRect) in filteredMergeLabelRects.enumerated() {
                if rect.intersects(filteredRect) {
                    intersectCount += 1
                    filteredMergeLabelRects[filteredRectIndex] = filteredRect.union(rect)
                }
            }
            
            if intersectCount == 0 {
                filteredMergeLabelRects.append(rect)
            }
        }
        
        mergeLabelRects = filteredMergeLabelRects
        
        //Filter rects: - Not to small
        
        let insetMergeLabelRects = mergeLabelRects.map({return $0.insetBy(dx: CGFloat(xMergeRadius), dy: CGFloat(yMergeRadius))})
        filteredMergeLabelRects.removeAll()
        
        for rect in insetMergeLabelRects {
            let widthOK  = rect.size.width  >= 7
            let heightOK = rect.size.height >= 14
            
            if widthOK && heightOK {
                filteredMergeLabelRects.append(rect)
            }
        }
        
        mergeLabelRects = filteredMergeLabelRects
        
        var outputImages = [(OCRImage, CGRect)]()
        
        //MARK: Crop image to blob
        
        for rect in mergeLabelRects {
            
            if let croppedCGImage = cgImage?.cropping(to: rect) {
                
                #if os(iOS)
                    let croppedImage = UIImage(cgImage: croppedCGImage)
                #else
                    let croppedImage = NSImage(cgImage: croppedCGImage, size: rect.size)
                #endif
                
                outputImages.append((croppedImage, rect))
            }
        }
        
        outputImages.sort(by: {return $0.0.1.origin.x < $0.1.1.origin.x})
        return outputImages
        
    }
    
    /**
     
     Takes an array of images and then resized them to **16x20px**. This is the standard size for the input for the neural network.
     
     - Parameter blobImages: The array of images that should get resized.
     - Returns:              An array containing the resized images.
     
     */
    
    internal func resizeBlobs(_ blobImages: [OCRImage]) -> [OCRImage] {
        
        var resizedBlobs = [OCRImage]()
        
        for blobImage in blobImages {
            let cropSize = CGSize(width: 16, height: 20)
            
            //Downscale
            #if os(iOS)
                let cgImage   = blobImage.cgImage
            #else
                let bitmapRep = NSBitmapImageRep(data: blobImage.tiffRepresentation!)!
                let cgImage   = bitmapRep.cgImage
            #endif
            
            let width = cropSize.width
            let height = cropSize.height
            let bitsPerComponent = 8
            let bytesPerRow = 0
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let bitmapInfo = CGImageAlphaInfo.noneSkipLast.rawValue
            
            let context = CGContext(data: nil, width: Int(width), height: Int(height), bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
            
            context!.interpolationQuality = CGInterpolationQuality.none
            
            context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: cropSize.width, height: cropSize.height))
            
            let resizedCGImage = context?.makeImage()?.cropping(to: CGRect(x: 0, y: 0, width: cropSize.width, height: cropSize.height))!
            
            #if os(iOS)
                let resizedOCRImage = UIImage(cgImage: resizedCGImage!)
            #else
                let resizedOCRImage = NSImage(cgImage: resizedCGImage!, size: cropSize)
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
    
    open func preprocessImageForOCR(_ image:OCRImage) -> OCRImage {
        
        func getDodgeBlendImage(_ inputImage: OCRImage) -> OCRImage {
            let image  = GPUImagePicture(image: inputImage)
            let image2 = GPUImagePicture(image: inputImage)
            
            //First image
            
            let grayFilter      = GPUImageGrayscaleFilter()
            let invertFilter    = GPUImageColorInvertFilter()
            let blurFilter      = GPUImageBoxBlurFilter()
            let opacityFilter   = GPUImageOpacityFilter()
            
            blurFilter.blurRadiusInPixels = 9
            opacityFilter.opacity         = 0.93
            
            image?       .addTarget(grayFilter)
            grayFilter  .addTarget(invertFilter)
            invertFilter.addTarget(blurFilter)
            blurFilter  .addTarget(opacityFilter)
            
            opacityFilter.useNextFrameForImageCapture()
            
            //Second image
            
            let grayFilter2 = GPUImageGrayscaleFilter()
            
            image2?.addTarget(grayFilter2)
            
            grayFilter2.useNextFrameForImageCapture()
            
            //Blend
            
            let dodgeBlendFilter = GPUImageColorDodgeBlendFilter()
            
            grayFilter2.addTarget(dodgeBlendFilter)
            image2?.processImage()
            
            opacityFilter.addTarget(dodgeBlendFilter)
            
            dodgeBlendFilter.useNextFrameForImageCapture()
            image?.processImage()
            
            var processedImage:OCRImage? = dodgeBlendFilter.imageFromCurrentFramebuffer(with: UIImageOrientation.up)
            
            while processedImage?.size == CGSize.zero || processedImage == nil {
                dodgeBlendFilter.useNextFrameForImageCapture()
                image?.processImage()
                processedImage = dodgeBlendFilter.imageFromCurrentFramebuffer(with: .up)
            }
            
            return processedImage!
        }
        
        let dodgeBlendImage        = getDodgeBlendImage(image)
        let picture                = GPUImagePicture(image: dodgeBlendImage)
        
        let medianFilter           = GPUImageMedianFilter()
        let openingFilter          = GPUImageOpeningFilter()
        let biliteralFilter        = GPUImageBilateralFilter()
        let firstBrightnessFilter  = GPUImageBrightnessFilter()
        let contrastFilter         = GPUImageContrastFilter()
        let secondBrightnessFilter = GPUImageBrightnessFilter()
        let thresholdFilter        = GPUImageLuminanceThresholdFilter()
        
        biliteralFilter.texelSpacingMultiplier      = 0.8
        biliteralFilter.distanceNormalizationFactor = 1.6
        firstBrightnessFilter.brightness            = -0.28
        contrastFilter.contrast                     = 2.35
        secondBrightnessFilter.brightness           = -0.08
        biliteralFilter.texelSpacingMultiplier      = 0.8
        biliteralFilter.distanceNormalizationFactor = 1.6
        thresholdFilter.threshold                   = 0.7
        
        picture?               .addTarget(medianFilter)
        medianFilter          .addTarget(openingFilter)
        openingFilter         .addTarget(biliteralFilter)
        biliteralFilter       .addTarget(firstBrightnessFilter)
        firstBrightnessFilter .addTarget(contrastFilter)
        contrastFilter        .addTarget(secondBrightnessFilter)
        secondBrightnessFilter.addTarget(thresholdFilter)
        
        thresholdFilter.useNextFrameForImageCapture()
        picture?.processImage()
        
        var processedImage:OCRImage? = thresholdFilter.imageFromCurrentFramebuffer(with: UIImageOrientation.up)
        
        while processedImage == nil || processedImage?.size == CGSize.zero {
            thresholdFilter.useNextFrameForImageCapture()
            picture?.processImage()
            processedImage = thresholdFilter.imageFromCurrentFramebuffer(with: .up)
        }
        
        return processedImage!
        
    }
    
    /**
     
     Takes an image and converts it to an array of floats. The array gets generated by taking the pixel-data of the red channel and then converting it into floats. This array can be used as input for the neural network.
     
     - Parameter image:  The image which should get converted to the float array.
     - Parameter resize: If you set this to true, the image firsts gets resized. The default value is `true`.
     - Returns:          The array containing the pixel-data of the red channel.
     
     */
    
    internal func convertImageToFloatArray(_ image: OCRImage, resize: Bool = true) -> [Float] {
        
        let resizedBlob: OCRImage = {
            if resize {
                return resizeBlobs([image]).first!
            } else {
                return image
            }
        }()
        
        #if os(iOS)
            let pixelData  = resizedBlob.cgImage?.dataProvider?.data
            let bitmapData: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
            let cgImage    = resizedBlob.cgImage
        #else
            let bitmapRep  = NSBitmapImageRep(data: resizedBlob.tiffRepresentation!)!
            let bitmapData = bitmapRep.bitmapData!
            let cgImage    = bitmapRep.cgImage
        #endif
        
        let numberOfComponents = (cgImage?.bitsPerPixel)! / (cgImage?.bitsPerComponent)!
        
        var imageData = [Float]()
        
        let height = Int(resizedBlob.size.height)
        let width  = Int(resizedBlob.size.width)
        
        for yPixelInfo in stride(from: 0, to: height*width*numberOfComponents, by: width*numberOfComponents) {
            for xPixelInfo in stride(from: 0, to: width*numberOfComponents, by: numberOfComponents) {
                let pixelInfo: Int = yPixelInfo + xPixelInfo
                
                imageData.append(bitmapData[pixelInfo] < 127 ? 0 : 1)
                
            }
        }
        
        let aspectRatio = Float(image.size.width / image.size.height)
        
        imageData.append(aspectRatio)
        
        return imageData
    }
    
}

// MARK: SwiftOCRDelegate

public protocol SwiftOCRDelegate: class {
    
    /**
     
     Implement this method for a custom image preprocessing algorithm. Only return a binary image.
     
     - Parameter inputImage: The image to preprocess.
     - Returns:              The preprocessed, binarized image that SwiftOCR should use for OCR. If you return nil SwiftOCR will use its default preprocessing algorithm.
     
     */
    
    func preprocessImageForOCR(_ inputImage: OCRImage) -> OCRImage?
    
}

extension SwiftOCRDelegate {
    func preprocessImageForOCR(_ inputImage: OCRImage) -> OCRImage? {
        return nil
    }
}

// MARK: SwiftOCRRecognizedBlob

public struct SwiftOCRRecognizedBlob {
    
    public let charactersWithConfidence: [(character: Character, confidence: Float)]!
    public let boundingBox:              CGRect!
    
    init(charactersWithConfidence: [(character: Character, confidence: Float)]!, boundingBox: CGRect) {
        self.charactersWithConfidence = charactersWithConfidence.sorted(by: {return $0.0.confidence > $0.1.confidence})
        self.boundingBox = boundingBox
    }
    
}
