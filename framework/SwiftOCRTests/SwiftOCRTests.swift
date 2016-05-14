//
//  SwiftOCRTests.swift
//  SwiftOCRTests
//
//  Created by Nicolas Camenisch on 21.04.16.
//  Copyright © 2016 Nicolas Camenisch. All rights reserved.
//

import XCTest
@testable import SwiftOCR

class SwiftOCRTests: XCTestCase {
    
    #if os(iOS)
    let testImageOne   = OCRImage(contentsOfFile: NSBundle(forClass: SwiftOCR.self).pathForResource("Test 1", ofType: "png")!)!
    let testImageTwo   = OCRImage(contentsOfFile: NSBundle(forClass: SwiftOCR.self).pathForResource("Test 2", ofType: "png")!)!
    let testImageThree = OCRImage(contentsOfFile: NSBundle(forClass: SwiftOCR.self).pathForResource("Test 3", ofType: "png")!)!
    #else
    let testImageOne   = OCRImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 1.png")!)!
    let testImageTwo   = OCRImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 2.png")!)!
    let testImageThree = OCRImage(byReferencingFile: NSBundle(forClass: SwiftOCR.self).pathForImageResource("Test 3.png")!)!
    #endif
    
    override class func setUp() {
        super.setUp()
        // Called once before all tests are run
        let _ = globalNetwork //Load network from file
    }

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBigImageSwiftOCR() {

        self.measureBlock({
            let expection = self.expectationWithDescription("testSingleSwiftOCR Expection")
            
            let _ = SwiftOCR(image: self.testImageThree, delegate: nil, { recognizedString in
                expection.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(50, handler: nil)
        })
        
    }
    
    func testSingleSwiftOCR() {

        self.measureBlock({
            let expection = self.expectationWithDescription("testSingleSwiftOCR Expection")
            
            let _ = SwiftOCR(image: self.testImageTwo, delegate: nil, { recognizedString in
                XCTAssertEqual(recognizedString, "AB84ENS91")
                expection.fulfill()
            })
            
            self.waitForExpectationsWithTimeout(10, handler: nil)
        })
        
    }
    
    func testMultipleSwiftOCR() {

        self.measureBlock({
            let expectionOne = self.expectationWithDescription("testMultipleSwiftOCR Expection One")
            let expectionTwo = self.expectationWithDescription("testMultipleSwiftOCR Expection Two")
            
            let _ = SwiftOCR(image: self.testImageOne, delegate: nil, { recognizedString in
                XCTAssertEqual(recognizedString, "GSYCNP")
                expectionOne.fulfill()
            })
            
            let _ = SwiftOCR(image: self.testImageTwo, delegate: nil, { recognizedString in
                XCTAssertEqual(recognizedString, "AB84ENS91")
                expectionTwo.fulfill()
            })

            self.waitForExpectationsWithTimeout(20, handler: nil)
        })
        
    }
    
    func testExtractBlobs() {
        let ocrInstance = SwiftOCR()
        let preprocessedImage = ocrInstance.preprocessImageForOCR(self.testImageOne)
        
        measureBlock({
            let extractedBlobs = ocrInstance.extractBlobs(preprocessedImage)
            XCTAssertEqual(extractedBlobs.count, 6)
        })
    }
    
    func testConvertImageToFloatArray() {
        let ocrInstance = SwiftOCR()
        
        measureBlock({
            let _ = ocrInstance.convertImageToFloatArray(self.testImageOne, resize: false)
        })
    }
    
    func testConvertImageToFloatArrayWithResize() {
        let ocrInstance = SwiftOCR()
        
        measureBlock({
            let _ = ocrInstance.convertImageToFloatArray(self.testImageOne, resize: true)
        })
    }
    
    func testPreprocessImageForOCR() {
        let ocrInstance = SwiftOCR()
        
        measureBlock({
            let _ = ocrInstance.preprocessImageForOCR(self.testImageOne)
        })
    }

}
